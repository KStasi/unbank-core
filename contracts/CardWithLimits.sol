pragma ever-solidity >= 0.61.2;

pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "@broxus/contracts/contracts/access/InternalOwner.tsol";
import "@broxus/contracts/contracts/utils/RandomNonce.tsol";
import "tip3/contracts/interfaces/ITokenRoot.sol";
import "tip3/contracts/interfaces/ITokenWallet.sol";
import "./ErrorCodes.sol";
import "./interfaces/IBank.sol";
import "./BaseCard.sol";

contract CardWithLimits is BaseCard {
    uint128 public dailyLimit = 0;
    uint128 public monthlyLimit = 0;

    uint256 public dailySpent;
    uint256 public monthlySpent;

    // Limit resets every 24 hours
    uint256 public nextDay;

    // Limit resets every 30 days
    uint256 public nextMonth;

    constructor(address _currency, address _bank) BaseCard(_currency, _bank) public {
        cardType = CardType.DEBIT;
        IBank(bank).getDefaultSpending{callback : CardWithLimits.setDefaultSpendingLimitsOnInit}(currency);
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

    // INTERNAL

    function _validateTransfer(
        uint128 _amount,
        TvmCell _payload)
        internal
        override
    {
        BaseCard._validateTransfer(_amount, _payload);
        _validate(_amount);
    }

    function _validate(
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
