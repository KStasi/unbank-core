pragma ever-solidity >= 0.61.2;

pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "@broxus/contracts/contracts/utils/RandomNonce.tsol";
import "./ErrorCodes.sol";
import "./CardsRegistry.sol";
import "./BaseCard.sol";
import "./CardWithLimits.sol";


contract RetailAccount is
    RandomNonce
    {
    optional(uint) static public _ownerPublicKey;
    optional(address) static public _ownerAddress;
    mapping(address => bool) public _cards;
    bool public _isActive;
    address public _cardsRegistry;
    address public _requestsRegistry;
    address public _managerCollection;
    address public _bank;

    modifier onlyOwner() {
        require(_ownerPublicKey.hasValue() && msg.pubkey() == _ownerPublicKey.get()||
            _ownerAddress.hasValue() && _ownerAddress.get() == msg.sender, ErrorCodes.NOT_OWNER);
        _;
    }

    modifier onlyActive() {
        require(_isActive, ErrorCodes.NOT_ACTIVE_ACCOUNT);
        _;
    }

    modifier onlyBank() {
        require(msg.sender == _bank, ErrorCodes.NOT_BANK);
        _;
    }

    modifier onlyCardsRegistry() {
        require(msg.sender == _cardsRegistry, ErrorCodes.NOT_CARD_REGISTRY);
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

    constructor(address cardsRegistry, address bank, address requestsRegistry, address managerCollection) public {
        if (msg.pubkey() != 0) {
            require(msg.pubkey() == tvm.pubkey() && !_ownerAddress.hasValue(), ErrorCodes.WRONG_OWNER);
        } else {
            require(_ownerAddress.hasValue(), ErrorCodes.WRONG_OWNER);
        }
        tvm.accept();

        _cardsRegistry = cardsRegistry;
        _bank = bank;
        _requestsRegistry = requestsRegistry;
        _managerCollection = managerCollection;
    }

    function addCard(
        uint128 cardTypeId,
        address currency,
        TvmCell otherCardDetails
    )
        public
        view
        onlyManagerCollection
    {
        tvm.accept();

        // dev: owner + bank address + currency + other card details
        TvmBuilder builder;
        builder.store(address(this), _bank, currency, otherCardDetails);

        CardsRegistry(_cardsRegistry).deployCard{value: 0, bounce: false, flag: 64, callback: RetailAccount.onCardAdded}(
            cardTypeId,
            builder.toCell()
        );
    }

    function onCardAdded(
        address newCard
    )
        public
        onlyCardsRegistry
    {
        tvm.accept();
        _cards[newCard] = true;
    }

    function setCardActivation(
        address card,
        bool isActive
    )
        public
        view
        onlyManagerCollection
    {
        tvm.accept();
        require(_cards.exists(card), ErrorCodes.NOT_CARD_OF_ACCOUNT);

        BaseCard(card).setCardActivation(isActive);
    }

    function setSpendingLimits(
        address card,
        uint128 dailyLimit,
        uint128 monthlyLimit
    )
        public
        view
        onlyRequestsRegistry
    {
        tvm.accept();
        require(_cards.exists(card), ErrorCodes.NOT_CARD_OF_ACCOUNT);

        CardWithLimits(card).updateSpendingLimit(dailyLimit, monthlyLimit);
    }

    function transferToBank(
        address card,
        uint128 amount,
        TvmCell payload
    )
        public
        view
        onlyManagerCollection
    {
        tvm.accept();
        require(_cards.exists(card), ErrorCodes.NOT_CARD_OF_ACCOUNT);
        BaseCard(card).transferToBank(amount, payload);
    }

    // TODO: remove transfer to bank; >>>> move to banks level

    // TODO: create autopayments
    // TODO: cancel autopayments

    function setAccountActivation(
        bool isActive
    )
        public
        onlyManagerCollection
    {
        tvm.accept();
        _isActive = isActive;
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
        onlyActive
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
        onlyActive
    {
        tvm.accept();
        for (uint i = 0; i < transactions.length; i++) {
            Transaction transaction = transactions[i];
            transaction.dest.transfer(transaction.value, transaction.bounce, transaction.flags, transaction.payload);
        }
    }
}
