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
import "./interfaces/IShareTokenRoot.sol";

contract ShareTokenRoot is TokenRoot, IAcceptTokensTransferCallback, IAcceptTokensBurnCallback, IShareTokenRoot {
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

    // Minimal number of confirmations needed to execute transaction.
    uint32 _defaultQuorumRate;
    // Unconfirmed transaction lifetime, in seconds.
    uint32 _lifetime;
    uint128 _minProposerBalance;
    uint32 _depositLock = 30 * 24 * 3600;
    uint128 _deployWalletValue = 0.3 ever;

    /**
     * @notice Initialize the contract.
     * @dev This function is called in the constructor to set the initial contract state.
     * @param minProposerBalance The minimum balance for a proposer.
     * @param defaultQuorumRate The default rate of quorum for transaction approval.
     * @param lifetime The lifetime of unconfirmed transactions.
     */
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

    /**
     * @notice Contract constructor.
     * @param defaultQuorumRate The default rate of quorum for transaction approval.
     * @param lifetime The lifetime of unconfirmed transactions.
     * @param initialShares Array of initial shares distribution.
     */
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

    /**
     * @notice Request deployment of a wallet for a new currency.
     * @dev Can only be called by the root owner.
     * @param currencyRoot The root address of the currency.
     */
    function addWallet(address currencyRoot) public onlyRootOwner override {
        require(!_walletAddresses.exists(currencyRoot), ErrorCodes.WALLET_ALREADY_CREATED);
        tvm.accept();
        ITokenRoot root = ITokenRoot(currencyRoot);
        root.deployWallet{callback: onWalletCreated}(
            address(this),
            _deployWalletValue
        );
    }

    /**
     * @notice Callback for when a wallet is created.
     * @param _wallet The address of the wallet that was created.
     */
    function onWalletCreated(
        address _wallet
    )
        public override
    {
        require(!_walletAddresses.exists(msg.sender), ErrorCodes.WALLET_ALREADY_CREATED);
        tvm.accept();
        _walletAddresses[msg.sender] = _wallet;
    }

    /**
     * @notice Submit a transaction.
     * @param sender The address of the wallet owner. Used to verify that the sender is a wallet with valid code.
     * @param senderBalance The balance of the sender's wallet.
     * @param dest The destination address for the transaction.
     * @param value The value to be transferred.
     * @param bounce If true, the transfer fails if the destination address does not exist.
     * @param allBalance If true, sends the entire remaining balance.
     * @param payload The payload to be delivered to the destination address.
     * @param stateInit Optional initial state for the destination account.
     * @return transId The ID of the submitted transaction.
     */
    function submitTransaction(
        address sender,
        uint128 senderBalance,
        address dest,
        uint128 value,
        bool bounce,
        bool allBalance,
        TvmCell payload,
        optional(TvmCell) stateInit
    ) public override returns (uint64 transId) {
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

    /**
     * @notice Mints tokens in exchange for a specified deposit.
     * @dev Only callable by the root owner.
     * @dev Requires the deposit to exist. The deposit becomes unclaimable and start belonging to DAO.
     * @param depositId The ID of the deposit for which tokens are being minted.
     * @param amount The amount of tokens to be minted.
     * @param deployWalletValue The value to be sent to the wallet on deployment.
     * @param remainingGasTo The address to which remaining gas should be sent.
     * @param notify Whether the receiver should be notified.
     * @param payload The payload for the minting transaction.
     */
    function mintForDeposit(
        uint64 depositId,
        uint128 amount,
        uint128 deployWalletValue,
        address remainingGasTo,
        bool notify,
        TvmCell payload
    ) public onlyRootOwner override {
        require(_lockedDeposits.exists(depositId), ErrorCodes.DEPOSIT_DOES_NOT_EXIST);
        Deposit deposit = _lockedDeposits[depositId];
        tvm.accept();

        delete _lockedDeposits[depositId];
        tvm.rawReserve(_reserve(), 0);
        _mint(amount, deposit.owner, deployWalletValue, remainingGasTo, notify, payload);
    }


    /**
     * @notice Vote for a proposed transaction.
     * @dev Removes expired transactions.
     * @param trId The ID of the transaction to be confirmed.
     * @param votes The number of votes to be added to the transaction.
     */
    function confirmTransaction(uint64 trId, uint128 votes) public override {
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

    /**
     * @notice Sets the default quorum rate.
     * @dev Only callable by the root owner.
     * @dev Requires a valid quorum rate.
     * @param newRate The new default quorum rate.
     */
    function setDefaultQuorumRate(uint32 newRate) public onlyRootOwner override {
        require(newRate > 0 && newRate <= QUORUM_BASE, ErrorCodes.INVALID_QUORUM_RATE);
        _defaultQuorumRate = newRate;
    }

    /**
     * @notice Sets the lifetime of the contract.
     * @dev Only callable by the root owner.
     * @param newLifetime The new lifetime of the contract.
     */
    function setLifetime(uint32 newLifetime) public onlyRootOwner override{
        _lifetime = math.max(MIN_LIFETIME, math.min(newLifetime, uint32(now & 0xFFFFFFFF)));
    }

    /**
     * @notice Sets the minimum balance required for a proposer.
     * @dev Only callable by the root owner.
     * @param newBalance The new minimum proposer balance.
     */
    function setMinProposerBalance(uint128 newBalance) public onlyRootOwner override{
        _minProposerBalance = newBalance;
    }

    /**
     * @notice Sets the deposit lock period.
     * @dev Only callable by the root owner.
     * @param newLock The new deposit lock period.
     */
    function setDepositLock(uint32 newLock) public onlyRootOwner override{
        _depositLock = newLock;
    }

    /**
     * @notice Sets the deploy wallet value.
     * @dev Only callable by the root owner.
     * @param newValue The new deploy wallet value.
     */
    function setDeployWalletValue(uint128 newValue) public onlyRootOwner override {
        _deployWalletValue = newValue;
    }

    /**
     * @notice Handles token transfers for deposit locks.
     * @dev Requires a positive amount and accepts only supported currencies.
     * @param tokenRoot The root of the token being transferred.
     * @param amount The amount of tokens being transferred.
     * @param sender The sender of the tokens.
     * @param senderWallet The wallet of the sender.
     * @param remainingGasTo The address to which remaining gas should be sent.
     * @param payload The payload for the transfer.
     */
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


    /**
     * @notice Unlocks a specified deposit.
     * @dev Requires the deposit to exist, be unlocked, and the sender to be the owner. Normally is called if the mintForDeposit proposal was denied.
     * @param depositId The ID of the deposit to be unlocked.
     */
    function unlockValue(uint64 depositId) public override {
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

    /**
     * @notice Handles token burning. Burning normally happens when someone sells shares in exchange for cash.
     * @dev Only callable by the root owner.
     * @param amount The amount of tokens to be burned.
     * @param walletOwner The owner of the wallet from which tokens are being burned.
     * @param wallet The wallet from which tokens are being burned.
     * @param remainingGasTo The address to which remaining gas should be sent.
     * @param payload The payload for the burn.
     */
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


}