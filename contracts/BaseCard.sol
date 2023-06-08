pragma ever-solidity >= 0.61.2;

pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "@broxus/contracts/contracts/access/InternalOwner.tsol";
import "@broxus/contracts/contracts/utils/RandomNonce.tsol";
import "tip3/contracts/interfaces/ITokenRoot.sol";
import "tip3/contracts/interfaces/ITokenWallet.sol";
import "./ErrorCodes.sol";
import "./interfaces/IBank.sol";

// TODO: add events
// TODO: does it make sense to make BaseCard TIP3 compatible?

contract BaseCard is
    RandomNonce {

    enum CardType {
        DEBIT,
        CREDIT,
        SAVINGS
    }

    address static public _bank;
    address static public _currency;
    address static public _owner;

    address public _bankWallet;
    address public _wallet;

    // dev: not needed since we have wallet.balance
    // uint128 public totalBalance = 0;
    uint128 public _delegatedBalance = 0; // transfered for bank's direct management
    uint128 public _frozenBalance = 0;

    bool public _isActive = true;

    CardType static public _cardType;
    uint128 constant DEPLOY_WALLET_VALUE = 0.3 ever; // TODO: make upgradable
    uint128 constant DEPLOY_WALLET_EXECUTION_FEE = 0.1 ever; // TODO: make upgradable

    modifier onlyOwner() {
        require(msg.sender == _owner && msg.sender.value != 0, _ErrorCodes.NOT_OWNER);
        _;
    }

    modifier onlyAllowedTokenRoot(address tokenRoot) {
        require(tokenRoot == _currency, ErrorCodes.NOT_TOKEN_ROOT);
        _;
    }

    modifier onlyCurrency() {
        require(msg.sender == _currency && msg.sender.value != 0, ErrorCodes.NOT_CURRENCY);
        _;
    }

    modifier onlyBank() {
        require(msg.sender == _bank && msg.sender.value != 0, ErrorCodes.NOT_BANK);
        _;
    }

    modifier onlyWallet() {
        require(msg.sender == _wallet && msg.sender.value != 0, ErrorCodes.NOT_WALLET);
        _;
    }

    constructor(TvmCell cardDetails) public {
        tvm.accept();

        ITokenRoot(_currency).deployWallet{callback: BaseCard.onWalletCreated, value: DEPLOY_WALLET_VALUE+DEPLOY_WALLET_EXECUTION_FEE, flag: 1}(address(this), DEPLOY_WALLET_VALUE);
    }

    function updateCrusialParams()
        public
        virtual
        onlyOwner
    {
        tvm.accept();
    }

    function getCode () public responsible returns (TvmCell) {
        return{value: 0, bounce: false, flag: 64} tvm.code();
    }

    // dev: must be approved by bank's managers
    function transferToBank(
        uint128 amount,
        TvmCell payload
    )
        public
        onlyOwner
    {
        tvm.accept();
        require(amount > 0, ErrorCodes.ZERO_AMOUNT);

        // dev: use bank's wallet instead of bank as a receiver to be able to
        // replace the address in case the logic of assets management is changed.
        ITokenWallet(_wallet).transferToWallet(
            amount,
            _bankWallet,
            address(this),
            true,
            payload);

        _delegatedBalance += amount;
        _frozenBalance += amount;
    }

    function setCardActivation(
        bool isActive
    )
        public
        onlyOwner
    {
        tvm.accept();
        _isActive = isActive;
    }

    // TODO: emergency withdrawal

    function onBankWalletAddressUpdated(
        address wallet
    )
        public
        onlyBank
    {
        _bankWallet = wallet;
    }

    function onAcceptTokensMint(
        address wallet
    )
        public
        onlyCurrency
    {
        // TODO: do something on deposit
    }

    function onAcceptTokensBurn(
        address wallet
    )
        public
        onlyCurrency
    {
        // TODO: do something on withdrawal
    }

    function onAcceptTokensTransfer(
        address tokenRoot,
        uint128 amount,
        address sender,
        address senderWallet,
        address remainingGasTo,
        TvmCell payload)
        public
        onlyAllowedTokenRoot(tokenRoot)
    {
        tvm.accept();
        if (senderWallet == _bankWallet) {
            // TODO: parse payload to ensure it's a transfer to return funds from the bank
            _delegatedBalance -= amount;
            _frozenBalance -= amount;
        }
        // TODO: do something on transfer to the wallet
    }


    function onWalletCreated(
        address wallet
    )
        public
        onlyCurrency
    {
        tvm.accept();
        require(_wallet == address(0), ErrorCodes.WALLET_ALREADY_CREATED);
        _wallet = wallet;
    }

    function transferToWallet(
        uint128 amount,
        address recipientTokenWallet,
        address remainingGasTo,
        bool notify,
        TvmCell payload
    )

        public
        onlyOwner
    {
        tvm.accept();
        _validateTransfer(amount, payload);

        ITokenWallet(_wallet).transferToWallet(
            amount,
            recipientTokenWallet,
            remainingGasTo,
            notify,
            payload);
    }

    function transfer(
        uint128 amount,
        address recipient,
        uint128 deployWalletValue,
        address remainingGasTo,
        bool notify,
        TvmCell payload
    )

        public
        onlyOwner
    {
        tvm.accept();
        _validateTransfer(amount, payload);

        ITokenWallet(_wallet).transfer(
            amount,
            recipient,
            deployWalletValue,
            remainingGasTo,
            notify,
            payload);
    }

    // INTERNAL

    function _validateTransfer(
        uint128 amount,
        TvmCell payload)
        internal virtual
    {
        require(amount > 0, ErrorCodes.ZERO_AMOUNT);
        require(_isActive, ErrorCodes.CARD_NOT_ACTIVE);
    }
}
