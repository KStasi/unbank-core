pragma ever-solidity >= 0.61.2;

pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "@broxus/contracts/contracts/access/ExternalOwner.tsol";
import "@broxus/contracts/contracts/utils/RandomNonce.tsol";
import "@broxus/contracts/contracts/utils/CheckPubKey.tsol";
import "./ErrorCodes.sol";
import "./CardsRegistry.sol";
import "./BaseCard.sol";
import "./CardWithLimits.sol";

contract RetailAccount is
    ExternalOwner,
    RandomNonce,
    CheckPubKey {

    uint8 constant MAX_CARDS_COUNT = 10;
    mapping(address => bool) public cards;
    bool public isActive;
    address public cardsRegistry;
    address public _requestsRegistry;
    address public _managerCollection;
    address public bank;

    modifier onlyActive() {
        require(isActive, ErrorCodes.NOT_ACTIVE_ACCOUNT);
        _;
    }

    modifier onlyBank() {
        require(msg.sender == bank, ErrorCodes.NOT_BANK);
        _;
    }

    modifier onlyCardsRegistry() {
        require(msg.sender == cardsRegistry, ErrorCodes.NOT_CARD_REGISTRY);
        _;
    }

    modifier onlyRequestsRegistry() {
        require(msg.sender == _requestsRegistry, ErrorCodes.NOT_REQUESTS_REGISTRY);
        _;
    }

    modifier onlyManagerCollection() {
        require(msg.sender == _managerCollection, ErrorCodes.NOT_MANAGER_COLLECTION);
        _;
    }

    constructor(address _cardsRegistry, address _bank, address requestsRegistry, address managerCollection) public checkPubKey {
        tvm.accept();

        cardsRegistry = _cardsRegistry;
        bank = _bank;
        _requestsRegistry = requestsRegistry;
        _managerCollection = managerCollection;

        setOwnership(msg.pubkey());
    }

    function addCard(
        uint128 _cardTypeId,
        address _currency,
        TvmCell _otherCardDetails
    )
        public
        view
        onlyManagerCollection
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

    function setCardActivation(
        address _card,
        bool _isActive
    )
        public
        view
        onlyManagerCollection
    {
        tvm.accept();
        require(cards.exists(_card), ErrorCodes.NOT_CARD_OF_ACCOUNT);

        BaseCard(_card).setCardActivation(_isActive);
    }

    function setSpendingLimits(
        address _card,
        uint128 _dailyLimit,
        uint128 _monthlyLimit
    )
        public
        view
        onlyRequestsRegistry
    {
        tvm.accept();
        require(cards.exists(_card), ErrorCodes.NOT_CARD_OF_ACCOUNT);

        CardWithLimits(_card).updateSpendingLimit(_dailyLimit, _monthlyLimit);
    }

    function transferToBank(
        address _card,
        uint128 _amount,
        TvmCell _payload
    )
        public
        view
        onlyManagerCollection
    {
        tvm.accept();
        require(cards.exists(_card), ErrorCodes.NOT_CARD_OF_ACCOUNT);
        BaseCard(_card).transferToBank(_amount, _payload);
    }

    // TODO: remove transfer to bank; >>>> move to banks level

    // TODO: create autopayments
    // TODO: cancel autopayments

    function setAccountActivation(
        bool _isActive
    )
        public
        onlyManagerCollection
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
        require(isActive, ErrorCodes.NOT_ACTIVE_ACCOUNT);
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
        require(isActive, ErrorCodes.NOT_ACTIVE_ACCOUNT);
        for (uint i = 0; i < transactions.length; i++) {
            Transaction transaction = transactions[i];
            transaction.dest.transfer(transaction.value, transaction.bounce, transaction.flags, transaction.payload);
        }
    }
}
