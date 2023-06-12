pragma ever-solidity >= 0.61.2;

pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "@broxus/contracts/contracts/access/InternalOwner.tsol";
import "@broxus/contracts/contracts/utils/RandomNonce.tsol";
import "tip3/contracts/interfaces/ITokenRoot.sol";
import "tip3/contracts/interfaces/ITokenWallet.sol";
import "./ErrorCodes.sol";
import "./interfaces/IBank.sol";
import "./interfaces/IBaseCard.sol";

// TODO: does it make sense to make BaseCard TIP4 compatible?
contract BaseCard is RandomNonce, IBaseCard {
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

    /**
     * @notice Updates the crucial parameters of the card.
     * @dev Can only be called by the contract owner.
     */
    function updateCrusialParams()
        public
        virtual
        override
        onlyOwner
    {
        tvm.accept();
    }

    function getCode () public responsible returns (TvmCell) {
        return{value: 0, bounce: false, flag: 64} tvm.code();
    }

    /**
     * @notice Transfers the specified amount of tokens to the bank.
     * @dev Can only be called by the contract owner.
     * @param amount The amount of tokens to transfer.
     * @param payload The payload to include in the transfer operation.
     */
    function transferToBank(
        uint128 amount,
        TvmCell payload
    )
        public
        override
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

    /**
     * @notice Sets the activation status of the card.
     * @dev Can only be called by the contract owner.
     * @param isActive The activation status to set.
     */
    function setCardActivation(
        bool isActive
    )
        public
        override
        onlyOwner
    {
        tvm.accept();
        _isActive = isActive;
    }

    // TODO: emergency withdrawal

    /**
     * @notice Handles the update of the bank wallet address.
     * @dev Can only be called by the bank.
     * @param wallet The new bank wallet address.
     */
    function onBankWalletAddressUpdated(
        address wallet
    )
        public
        override
        onlyBank
    {
        _bankWallet = wallet;
    }

    /**
     * @notice Handles the acceptance of minted tokens.
     * @dev Can only be called by the currency.
     * @param wallet The wallet address to accept tokens to.
     */
    function onAcceptTokensMint(
        address wallet
    )
        public
        override
        onlyCurrency
    {
        // TODO: do something on deposit
    }

    /**
     * @notice Handles the acceptance of burned tokens.
     * @dev Can only be called by the currency.
     * @param wallet The wallet address to accept tokens from.
     */
    function onAcceptTokensBurn(
        address wallet
    )
        public
        override
        onlyCurrency
    {
        // TODO: do something on withdrawal
    }

    /**
     * @notice Handles the acceptance of transferred tokens.
     * @dev Can only be called by the allowed token root.
     * @param tokenRoot The token root address of the transferred tokens.
     * @param amount The amount of tokens transferred.
     * @param sender The address of the sender of the tokens.
     * @param senderWallet The wallet address of the sender.
     * @param remainingGasTo The address to send the remaining gas to.
     * @param payload The payload of the transfer operation.
     */
    function onAcceptTokensTransfer(
        address tokenRoot,
        uint128 amount,
        address sender,
        address senderWallet,
        address remainingGasTo,
        TvmCell payload)
        public
        override
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


    /**
     * @notice Handles the creation of the wallet for the card.
     * @dev Can only be called by the currency.
     * @param wallet The address of the created wallet.
     */
    function onWalletCreated(
        address wallet
    )
        public
        override
        onlyCurrency
    {
        tvm.accept();
        require(_wallet == address(0), ErrorCodes.WALLET_ALREADY_CREATED);
        _wallet = wallet;
    }

    /**
     * @notice Transfers the specified amount of tokens to the recipient wallet.
     * @dev Can only be called by the contract owner.
     * @param amount The amount of tokens to transfer.
     * @param recipientTokenWallet The address of the recipient token wallet.
     * @param remainingGasTo The address to send the remaining gas to.
     * @param notify Flag to indicate whether to notify the recipient wallet.
     * @param payload The payload to include in the transfer operation.
     */
    function transferToWallet(
        uint128 amount,
        address recipientTokenWallet,
        address remainingGasTo,
        bool notify,
        TvmCell payload
    )

        public
        override
        onlyOwner
    {
        tvm.accept();
        _validateTransfer(amount, payload);

        ITokenWallet(_wallet).transferToWallet{
            flag: 64
        }(
            amount,
            recipientTokenWallet,
            remainingGasTo,
            notify,
            payload);
    }

    /**
     * @notice Transfers the specified amount of tokens to the recipient.
     * @dev Can only be called by the contract owner.
     * @param amount The amount of tokens to transfer.
     * @param recipient The address of the recipient.
     * @param deployWalletValue The value to deploy the wallet.
     * @param remainingGasTo The address to send the remaining gas to.
     * @param notify Flag to indicate whether to notify the recipient.
     * @param payload The payload to include in the transfer operation.
     */
    function transfer(
        uint128 amount,
        address recipient,
        uint128 deployWalletValue,
        address remainingGasTo,
        bool notify,
        TvmCell payload
    )

        public
        override
        onlyOwner
    {
        tvm.accept();
        _validateTransfer(amount, payload);

        ITokenWallet(_wallet).transfer{
            flag: 64
        }(
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
