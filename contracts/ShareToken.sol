pragma ever-solidity >= 0.61.2;

pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "@broxus/contracts/contracts/access/InternalOwner.tsol";
import "@broxus/contracts/contracts/utils/RandomNonce.tsol";
import "tip3/contracts/TokenRoot.sol";
import "tip3/contracts/TokenWallet.sol";
import "./ErrorCodes.sol";
import "./interfaces/IBank.sol";

// TODO: think what things should be comminted before continue?
// TODO: comprehend permisions system
contract ShareTokenRoot is TokenRoot {
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

    // Binary mask with custodian requests (max 32 custodians).
    uint256 _requestsMask;
    // Dictionary of queued transactions waiting for confirmations.
    mapping(uint64 => Transaction) _transactions;
    // Minimal number of confirmations needed to execute transaction.
    uint32 _defaultQuorumRate;
    // Unconfirmed transaction lifetime, in seconds.
    uint32 _lifetime;
    uint128 _minProposerBalance;

    function _initialize(
        uint128 minProposerBalance,
        uint8 defaultQuorumRate,
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
        uint8 defaultQuorumRate,
        uint32 lifetime
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
        rootOwner_ = address(this);
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

        // dev: we can't confirm it here since we weren't sure about trId when call this method from wallet
        // _confirmTransaction(txn, senderBalance);
        return trId;
    }

    function confirmTransaction(uint64 trId) public {
        Transaction txn = _transactions[trId];
        require(txn.id == trId, ErrorCodes.INVALID_TRANSACTION_ID);
        require(txn.votesReceived < txn.votesRequired, ErrorCodes.TRANSACTION_ALREADY_CONFIRMED);
        require(_requestsMask & (1 << uint256(msg.sender)) != 0, ErrorCodes.SENDER_IS_NOT_CUSTODIAN);
        require(txn.votesReceived < MAX_CUSTODIAN_COUNT, ErrorCodes.TOO_MANY_CONFIRMATIONS);

        tvm.accept();
        _confirmTransaction(txn, 0);
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



    // TODO: ensure support minting by root
    // TODO: ensure support burning by root
    // TODO: proposals infastructure
    // TODO: add ability to call anything from multisig
}