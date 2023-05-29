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
// TODO: does it make sense to make BaseCard TIP3 compatible?

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

    uint128 public dailyLimit = 0;
    uint128 public monthlyLimit = 0;

    uint256 public dailySpent;
    uint256 public monthlySpent;

    // Limit resets every 24 hours
    uint256 public nextDay;

    // Limit resets every 30 days
    uint256 public nextMonth;


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
        IBank(bank).getDefaultSpending{callback : BaseCard.setDefaultSpendingLimitsOnInit}(currency);

        ITokenRoot(_currency).deployWallet{callback: BaseCard.onWalletCreated}(address(this), DEPLOY_WALLET_VALUE);
    }

    function updateCrusialParams()
        public
        onlyOwner
    {
        tvm.accept();
        IBank(bank).getWalletAddress{callback : BaseCard.onBankWalletAddressUpdated}(currency);
    }

    function setDefaultSpendingLimitsOnInit(
        address _currency,
        uint128 _dailyLimit,
        uint128 _monthlyLimit
    )
        public
        onlyBank
    {
        tvm.accept();
        require(_currency == currency, ErrorCodes.NOT_CURRENCY);
        require(dailyLimit == 0, ErrorCodes.NON_ZERO_DAILY_LIMIT);
        require(monthlyLimit == 0, ErrorCodes.NON_ZERO_MONTHLY_LIMIT);

        _updateSpendingLimit(_dailyLimit, _monthlyLimit);
    }

    function updateSpendingLimit(
        uint128 _dailyLimit,
        uint128 _monthlyLimit
    )
        public
        onlyBank
    {
        tvm.accept();
        _updateSpendingLimit(_dailyLimit, _monthlyLimit);
    }


    // dev: must be approved by bank's managers
    function transferToBank(
        uint128 _amount,
        TvmCell _payload
    )
        public
        onlyBank
    {
        tvm.accept();
        require(_amount > 0, ErrorCodes.ZERO_AMOUNT);

        // dev: use bank's wallet instead of bank as a receiver to be able to
        // replace the address in case the logic of assets management is changed.
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
        tvm.accept();
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
        tvm.accept();
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
        tvm.accept();
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
        onlyOwner
    {
        tvm.accept();
        _validateLimits(_amount);

        ITokenWallet(wallet).transferToWallet(
            _amount,
            _recipientTokenWallet,
            _remainingGasTo,
            _notify,
            _payload);
    }

      function transfer(
        uint128 _amount,
        address _recipient,
        uint128 _deployWalletValue,
        address _remainingGasTo,
        bool _notify,
        TvmCell _payload
    )

        public
        onlyOwner
    {
        tvm.accept();
        _validateLimits(_amount);

        ITokenWallet(wallet).transfer(
            _amount,
            _recipient,
            _deployWalletValue,
            _remainingGasTo,
            _notify,
            _payload);
    }

    // INTERNAL

    function _validateLimits(
        uint128 _amount
    )
        internal
    {
        while(block.timestamp >= nextDay) {
            nextDay += 1 days;
            dailySpent = 0;
        }

        while(block.timestamp >= nextMonth) {
            nextMonth += 30 days;
            monthlySpent = 0;
        }

        require(dailySpent + _amount <= dailyLimit, ErrorCodes.DAILY_LIMIT_REACHED);
        require(monthlySpent + _amount <= monthlyLimit, ErrorCodes.MONTHLY_LIMIT_REACHED);

        dailySpent += _amount;
        monthlySpent += _amount;
    }

    function _updateSpendingLimit(
        uint128 _dailyLimit,
        uint128 _monthlyLimit
    )
        internal
    {
        require(_dailyLimit > 0, ErrorCodes.ZERO_DAILY_LIMIT);
        require(_monthlyLimit > 0, ErrorCodes.ZERO_MONTHLY_LIMIT);

        dailyLimit = _dailyLimit;
        monthlyLimit = _monthlyLimit;
    }
}
