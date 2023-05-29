pragma ever-solidity >= 0.61.2;

pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "@broxus/contracts/contracts/access/InternalOwner.tsol";
import "@broxus/contracts/contracts/utils/RandomNonce.tsol";
import "tip3/contracts/interfaces/ITokenRoot.sol";
import "tip3/contracts/interfaces/ITokenWallet.sol";
import "./ErrorCodes.sol";
import "./interfaces/IBank.sol";

enum CardType {
    DEBIT,
    CREDIT,
    SAVINGS
}
// TODO: add events

contract BaseCard is
    InternalOwner,
    RandomNonce {

    address public bank;
    address public bankWallet;
    address public currency;
    address public wallet;

    // dev: not needed since we have wallet.balance
    // uint128 public totalBalance = 0;
    uint128 public delegatedBalance = 0; // transfered for bank's direct management
    uint128 public frozenBalance = 0;

    bool public isActive = true;

    uint128 public daylyLimit = 0;
    uint128 public monthlyLimit = 0;

    CardType public cardType = CardType.DEBIT;
    uint128 constant DEPLOY_WALLET_VALUE = 1000000;

    modifier onlyAllowedTokenRoot(address _tokenRoot) {
        require(_tokenRoot == currency, ErrorCodes.NOT_TOKEN_ROOT);
        _;
    }
    modifier onlyCurrency() {
        require(msg.sender == currency && msg.sender.value != 0, ErrorCodes.NOT_CURRENCY);
        _;
    }

    modifier onlyBank() {
        require(msg.sender == bank && msg.sender.value != 0, ErrorCodes.NOT_BANK);
        _;
    }

    constructor(address _currency, address _bank) public {
        tvm.accept();

        setOwnership(msg.sender);
        currency = _currency;
        bank =  _bank;

        // TODO: request default spending limit from bank
        // IBank(bank).getDefaultSpending{callback : BaseCard.updateSpendingLimit}(currency);

        ITokenRoot(_currency).deployWallet{callback: BaseCard.onWalletCreated}(address(this), DEPLOY_WALLET_VALUE);
    }

    function updateCrusialParams()
        public
        onlyOwner
    {
        IBank(bank).getWalletAddress{callback : BaseCard.onBankWalletAddressUpdated}(currency);
    }

    function updateSpendingLimit(
        uint128 _daylyLimit,
        uint128 _monthlyLimit
    )
        public
        onlyBank
    {
        require(_daylyLimit > 0, ErrorCodes.ZERO_DAILY_LIMIT);
        require(_monthlyLimit > 0, ErrorCodes.ZERO_MONTHLY_LIMIT);

        daylyLimit = _daylyLimit;
        monthlyLimit = _monthlyLimit;
    }

    // dev: must be approved by bank's managers
    function transferToBank(
        uint128 _amount,
        TvmCell _payload
    )
        public
        onlyBank
    {
        require(_amount > 0, ErrorCodes.ZERO_AMOUNT);

        ITokenWallet(wallet).transferToWallet(
            _amount,
            bankWallet,
            address(this),
            true,
            _payload);

        delegatedBalance += _amount;
    }

    function setAccountActivation(
        bool _isActive
    )
        public
        onlyBank
    {
        isActive = _isActive;
    }

    // TODO: emergency withdrawal

    function onBankWalletAddressUpdated(
        address _wallet
    )
        public
        onlyBank
    {
        bankWallet = _wallet;
    }
    function onAcceptTokensMint(
        address _wallet
    )
        public
        onlyCurrency
    {
        // TODO: do something on deposit
    }

    function onAcceptTokensBurn(
        address _wallet
    )
        public
        onlyCurrency
    {
        // TODO: do something on withdrawal
    }

    function onAcceptTokensTransfer(
        address _tokenRoot,
        uint128 _amount,
        address _sender,
        address _senderWallet,
        address _remainingGasTo,
        TvmCell _payload)
        public
        onlyAllowedTokenRoot(_tokenRoot)
    {
        if (_senderWallet == bankWallet) {
            // TODO: parse payload to ensure it's a transfer to return funds from the bank
            delegatedBalance -= _amount;
        }
        // TODO: do something on transfer to the wallet
    }


    function onWalletCreated(
        address _wallet
    )
        public
        onlyCurrency
    {
        require(wallet == address(0), ErrorCodes.WALLET_ALREADY_CREATED);
        wallet = _wallet;
    }

      function transferToWallet(
        uint128 _amount,
        address _recipientTokenWallet,
        address _remainingGasTo,
        bool _notify,
        TvmCell _payload
    )

        public
        view
        onlyOwner
    {
        tvm.accept();

        // TODO: check limits
        ITokenWallet(wallet).transferToWallet(
            _amount,
            _recipientTokenWallet,
            _remainingGasTo,
            _notify,
            _payload);
    }
}
