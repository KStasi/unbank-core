pragma ever-solidity >= 0.61.2;

pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "@broxus/contracts/contracts/access/ExternalOwner.tsol";
import "@broxus/contracts/contracts/utils/RandomNonce.tsol";
import "@broxus/contracts/contracts/utils/CheckPubKey.tsol";
import "./ErrorCodes.sol";
import "./CardsRegistry.sol";
import "./BaseCard.sol";

contract RetailAccount is
    ExternalOwner,
    RandomNonce,
    CheckPubKey {

    uint8 constant MAX_CARDS_COUNT = 10;
    mapping(address => bool) public cards;
    bool public isActive;
    address public cardsRegistry;
    address public bank;

    // modifier onlyRegularManager() {
    //     require(msg.pubkey() == owner, ErrorCodes.NOT_REGULAR_MANAGER);
    //     _;
    // }

    modifier onlyActive() {
        require(isActive, ErrorCodes.NOT_ACTIVE_ACCOUNT);
        _;
    }

    modifier onlyBank() {
        require(msg.sender == bank, ErrorCodes.NOT_REGULAR_MANAGER);
        _;
    }

    modifier onlyCardsRegistry() {
        require(msg.sender == cardsRegistry, ErrorCodes.NOT_REGULAR_MANAGER);
        _;
    }

    constructor(address _cardsRegistry, address _bank) public checkPubKey {
        tvm.accept();

        cardsRegistry = _cardsRegistry;
        bank = _bank;

        setOwnership(msg.pubkey());
    }

    function addCard(
        uint128 _cardTypeId,
        address _currency,
        TvmCell _otherCardDetails
    )
        public
        view
        onlyBank
    {
        tvm.accept();

        // TODO: check cards amount limit

        // dev: owner + bank address + currency + other card details
        TvmBuilder builder;
        builder.store(address(this), bank, _currency, _otherCardDetails);

        CardsRegistry(cardsRegistry).deployCard{value: 0, bounce: false, flag: 64, callback: RetailAccount.onCardAdded}(
            _cardTypeId,
            builder.toCell()
        );
    }

    function onCardAdded(
        address _newCard
    )
        public
        onlyCardsRegistry
    {
        tvm.accept();
        cards[_newCard] = true;
    }

    // TODO: should we allow access to cards only via accounts or directly?
    // function setCardActivation(
    //     address _card,
    //     bool _isActive
    // )
    //     public
    //     view
    //     onlyBank
    // {
    //     tvm.accept();
    //     require(cards.exists(_card), ErrorCodes.NOT_CARD_OF_ACCOUNT);

    //     BaseCard(_card).setCardActivation(_isActive);
    // }

    // function setSpendingLimits(
    //     address _card,
    //     uint128 _dailyLimit,
    //     uint128 _monthlyLimit
    // )
    //     public
    //     view
    //     onlyBank
    // {
    //     tvm.accept();
    //     require(cards.exists(_card), ErrorCodes.NOT_CARD_OF_ACCOUNT);

    //     BaseCard(_card).updateSpendingLimit(_dailyLimit, _monthlyLimit);
    // }

    // TODO: add transfer to bank
    // TODO: remove transfer to bank; >>>> move to banks level
    // -------------------------------------------------------------

    // TODO: create autopayments
    // TODO: cancel autopayments

    function setAccountActivation(
        bool _isActive
    )
        public
        onlyBank
    {
        tvm.accept();
        isActive = _isActive;
    }

    // TODO: emergency withdrawal


    function sendTransaction(
        address dest,
        uint128 value,
        bool bounce,
        uint8 flags,
        TvmCell payload
    )
        public
        view
        onlyOwner
    {
        tvm.accept();
        dest.transfer(value, bounce, flags, payload);
    }

    struct Transaction {
        address dest;
        uint128 value;
        bool bounce;
        uint16 flags;
        TvmCell payload;
    }

    function sendBatch(
        Transaction[] transactions
    )
        public
        view
        onlyOwner
    {
        tvm.accept();
        for (uint i = 0; i < transactions.length; i++) {
            Transaction transaction = transactions[i];
            transaction.dest.transfer(transaction.value, transaction.bounce, transaction.flags, transaction.payload);
        }
    }
}
