pragma ever-solidity >= 0.61.2;

pragma AbiHeader expire;
// pragma AbiHeader pubkey;

import "tip3/contracts/interfaces/IBurnableByRootTokenWallet.sol";
import "tip3/contracts/interfaces/IAcceptTokensTransferCallback.sol";
import "tip3/contracts/interfaces/IAcceptTokensBurnCallback.sol";
import "tip3/contracts/interfaces/ITokenRoot.sol";
import "tip3/contracts/interfaces/ITokenWallet.sol";
import "tip3/contracts/TokenRoot.sol";
import "tip3/contracts/TokenWallet.sol";
import "./ErrorCodes.sol";
import "./interfaces/IBank.sol";

// TODO: think what things should be comminted before continue?
// TODO: comprehend permisions system
contract ShareTokenRoot is TokenRoot, IAcceptTokensTransferCallback, IAcceptTokensBurnCallback {
    struct Transaction {
        // Transaction Id.
        uint64 id;
        // Number of required confirmations.
        uint128 votesRequired;
        // Number of confirmations already received.
        uint128 votesReceived;
        // Recipient address.
        address dest;
        // Amount of nanoevers to transfer.
        uint128 value;
        // Flags for sending internal message (see SENDRAWMSG in TVM spec).
        uint16 sendFlags;
        // Payload used as body of outbound internal message.
        TvmCell payload;
        // Bounce flag for header of outbound internal message.
        bool bounce;
        // Smart contract image to deploy with internal message.
        optional(TvmCell) stateInit;
    }

    struct Deposit{
        uint128 amount;
        uint32  lockedUntil;
        address assetRoot;
        address owner;
    }


    struct Shares{
        uint128 amount;
        address owner;
    }

    uint8   constant MAX_QUEUED_REQUESTS = 5;
    uint32  constant DEFAULT_LIFETIME = 3600; // lifetime is 1 hour
    uint32  constant MIN_LIFETIME = 10; // 10 secs
    uint8   constant MAX_CUSTODIAN_COUNT = 32;
    uint    constant MAX_CLEANUP_TXNS = 40;

    // Send flags.
    // Forward fees for message will be paid from contract balance.
    uint8 constant FLAG_PAY_FWD_FEE_FROM_BALANCE = 1;
    // Ignore errors in action phase to avoid errors if balance is less than sending value.
    uint8 constant FLAG_IGNORE_ERRORS = 2;
    // Send all remaining balance.
    uint8 constant FLAG_SEND_ALL_REMAINING = 128;
    uint32 constant QUORUM_BASE = 10000;

    // Dictionary of queued transactions waiting for confirmations.
    mapping(uint64 => Transaction) _transactions;
    mapping(uint64 => Deposit) _lockedDeposits;
    mapping(address => address) public _walletAddresses; // currency => wallet

    // TODO: add methods to update params
    // Minimal number of confirmations needed to execute transaction.
    uint32 _defaultQuorumRate;
    // Unconfirmed transaction lifetime, in seconds.
    uint32 _lifetime;
    uint128 _minProposerBalance;
    uint32 _depositLock = 30 * 24 * 3600;
    uint128 _deployWalletValue = 0.3 ever;

    function _initialize(
        uint128 minProposerBalance,
        uint32 defaultQuorumRate,
        uint32 lifetime
    ) inline private {
        require(defaultQuorumRate > 0 && defaultQuorumRate <= QUORUM_BASE, ErrorCodes.INVALID_QUORUM_RATE);
        _defaultQuorumRate = defaultQuorumRate;
        _minProposerBalance = minProposerBalance;

        if (lifetime == 0) {
            _lifetime = DEFAULT_LIFETIME;
        } else {
            _lifetime = math.max(MIN_LIFETIME, math.min(lifetime, uint32(now & 0xFFFFFFFF)));
        }
    }


    constructor(
        uint32 defaultQuorumRate,
        uint32 lifetime,
        Shares[] initialShares

    )
        public
        TokenRoot (
            address(0),
            0,
            0,
            false,
            false,
            false,
            msg.sender
        )
    {
        tvm.accept();
        rootOwner_ = address(this);

        TvmCell empty;
        for (Shares shares : initialShares) {
            _mint(shares.amount, shares.owner, _deployWalletValue, msg.sender, false, empty);
        }
    }

    function addWallet(address currencyRoot) public onlyRootOwner {
        require(!_walletAddresses.exists(currencyRoot), ErrorCodes.WALLET_ALREADY_CREATED);
        tvm.accept();
        ITokenRoot root = ITokenRoot(currencyRoot);
        root.deployWallet{callback: onWalletCreated}(
            address(this),
            _deployWalletValue
        );
    }

    function onWalletCreated(
        address _wallet
    )
        public
    {
        require(!_walletAddresses.exists(msg.sender), ErrorCodes.WALLET_ALREADY_CREATED);
        tvm.accept();
        _walletAddresses[msg.sender] = _wallet;
    }
    function submitTransaction(
        address sender,
        uint128 senderBalance,
        address dest,
        uint128 value,
        bool bounce,
        bool allBalance,
        TvmCell payload,
        optional(TvmCell) stateInit
    ) public returns (uint64 transId) {
        require(msg.sender == address(tvm.hash(_buildWalletInitData(sender))), ErrorCodes.SENDER_IS_NOT_VALID_WALLET);
        require(senderBalance > _minProposerBalance, ErrorCodes.LOW_PROPOSER_BALANCE);
        _removeExpiredTransactions();
        // TODO: consider protection from many proposals
        tvm.accept();

        (uint8 flags, uint128 realValue) = _getSendFlags(value, allBalance);

        uint64 trId = _generateId();
        Transaction txn = Transaction({
            id: trId,
            votesRequired: _defaultQuorumRate * totalSupply_ / QUORUM_BASE + 1,
            votesReceived: 0,
            dest: dest,
            value: realValue,
            sendFlags: flags,
            payload: payload,
            bounce: bounce,
            stateInit: stateInit
        });
        _transactions[trId] = txn;
        // dev: we can't confirm it here since we weren't sure about trId when call this method from wallet
        // _confirmTransaction(txn, senderBalance);
        return trId;
    }

    function mintForDeposit(
        uint64 depositId,
        uint128 amount,
        uint128 deployWalletValue,
        address remainingGasTo,
        bool notify,
        TvmCell payload
    ) public onlyRootOwner {
        require(_lockedDeposits.exists(depositId), ErrorCodes.DEPOSIT_DOES_NOT_EXIST);
        Deposit deposit = _lockedDeposits[depositId];
        tvm.accept();

        delete _lockedDeposits[depositId];
        tvm.rawReserve(_reserve(), 0);
        _mint(amount, deposit.owner, deployWalletValue, remainingGasTo, notify, payload);
    }


    function confirmTransaction(uint64 trId, uint128 votes) public {
        _removeExpiredTransactions();
        Transaction txn = _transactions[trId];
        tvm.accept();

        if ((txn.votesReceived + votes) >= txn.votesRequired) {
            if (txn.stateInit.hasValue()) {
                txn.dest.transfer({
                    value: txn.value,
                    bounce: txn.bounce,
                    flag: txn.sendFlags,
                    body: txn.payload,
                    stateInit: txn.stateInit.get()
                });
            } else {
                txn.dest.transfer({
                    value: txn.value,
                    bounce: txn.bounce,
                    flag: txn.sendFlags,
                    body: txn.payload
                });
            }
            delete _transactions[txn.id];
        } else {
            txn.votesReceived += votes;
            _transactions[txn.id] = txn;
        }
    }

    function _getExpirationBound() inline private view returns (uint64) {
        return (uint64(now) - uint64(_lifetime)) << 32;
    }

    function _generateId() inline private pure returns (uint64) {
        return (uint64(now) << 32) | (tx.timestamp & 0xFFFFFFFF);
    }

    function _getSendFlags(uint128 value, bool allBalance) inline private pure returns (uint8, uint128) {
        uint8 flags = FLAG_IGNORE_ERRORS | FLAG_PAY_FWD_FEE_FROM_BALANCE;
        if (allBalance) {
            flags = FLAG_IGNORE_ERRORS | FLAG_SEND_ALL_REMAINING;
            value = 0;
        }
        return (flags, value);
    }

    function _removeExpiredTransactions() private {
        uint64 marker = _getExpirationBound();
        if (_transactions.empty()) return;

        (uint64 trId, Transaction txn) = _transactions.min().get();
        bool needCleanup = trId <= marker;

        if (needCleanup) {
            tvm.accept();
            uint i = 0;
            while (needCleanup && i < MAX_CLEANUP_TXNS) {
                i++;
                // transaction is expired, remove it
                delete _transactions[trId];
                optional(uint64, Transaction) nextTxn = _transactions.next(trId);
                if (nextTxn.hasValue()) {
                    (trId, txn) = nextTxn.get();
                    needCleanup = trId <= marker;
                } else {
                    needCleanup = false;
                }
            }
            tvm.commit();
        }
    }

    function onAcceptTokensTransfer(
        address tokenRoot,
        uint128 amount,
        address sender,
        address senderWallet,
        address remainingGasTo,
        TvmCell payload
    ) public override {
        require(amount > 0, ErrorCodes.INVALID_DEPOSIT_VALUE);
        require(_walletAddresses.exists(tokenRoot), ErrorCodes.INVALED_CURREMCY_ROOT);
        // TODO: add infastructure to ensure deposit was allowed
        tvm.accept();

        uint64 depositId = _generateId();
        Deposit deposit = Deposit({
            amount: amount,
            lockedUntil: now + _depositLock,
            assetRoot: tokenRoot,
            owner: sender
        });
        _lockedDeposits[depositId] = deposit;
    }

    function unlockValue(uint64 depositId) public {
        require(_lockedDeposits.exists(depositId), ErrorCodes.DEPOSIT_DOES_NOT_EXIST);
        Deposit deposit = _lockedDeposits[depositId];
        require(deposit.lockedUntil < now, ErrorCodes.DEPOSIT_IS_LOCKED);
        require(deposit.owner == msg.sender || msg.sender == address(this), ErrorCodes.DEPOSIT_OWNER_MISMATCH);
        tvm.accept();

        delete _lockedDeposits[depositId];
        TvmCell emptyCell;
        ITokenWallet(_walletAddresses[deposit.assetRoot]).transfer(
            deposit.amount,
            deposit.owner,
            0,
            address(this),
            false,
            emptyCell
        );
    }

    function onAcceptTokensBurn(
        uint128 amount,
        address walletOwner,
        address wallet,
        address remainingGasTo,
        TvmCell payload
    ) external onlyRootOwner override {
        tvm.accept();
        TvmSlice slice = payload.toSlice();
        if (!slice.empty()) {
            (address cbdcRoot, uint128 cbdcAmount, address receiver) = slice.decode(address, uint128, address);
            require(_walletAddresses.exists(cbdcRoot), ErrorCodes.CURRENCY_NOT_SUPPORTED);
            TvmCell emptyCell;
            ITokenWallet(_walletAddresses[cbdcRoot]).transfer(
                cbdcAmount,
                receiver,
                0,
                remainingGasTo,
                false,
                emptyCell
            );
        }
    }
}