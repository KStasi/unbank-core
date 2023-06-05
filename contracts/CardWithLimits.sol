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
    uint128 public _dailyLimit = 0;
    uint128 public _monthlyLimit = 0;

    uint256 public _dailySpent;
    uint256 public _monthlySpent;

    // Limit resets every 24 hours
    uint256 public _nextDay;

    // Limit resets every 30 days
    uint256 public _nextMonth;

    constructor(TvmCell cardDetails) BaseCard(cardDetails) public {
        tvm.accept();
        _cardType = CardType.DEBIT;

        TvmSlice cardDetailsSlice = cardDetails.toSlice();
        (address currency) = cardDetailsSlice.decode(address);

        IBank(_bank).getDefaultSpending{callback : CardWithLimits.setDefaultSpendingLimitsOnInit}(currency);
    }

    function setDefaultSpendingLimitsOnInit(
        address currency,
        uint128 dailyLimit,
        uint128 monthlyLimit
    )
        public
        onlyBank
    {
        tvm.accept();
        require(_currency == currency, ErrorCodes.NOT_CURRENCY);
        require(_dailyLimit == 0, ErrorCodes.NON_ZERO_DAILY_LIMIT);
        require(_monthlyLimit == 0, ErrorCodes.NON_ZERO_MONTHLY_LIMIT);

        _updateSpendingLimit(dailyLimit, monthlyLimit);
    }

    function updateSpendingLimit(
        uint128 dailyLimit,
        uint128 monthlyLimit
    )
        public
        onlyOwner
    {
        tvm.accept();
        _updateSpendingLimit(dailyLimit, monthlyLimit);
    }

    function updateCrusialParams()
        public
        override
        onlyOwner
    {
        super.updateCrusialParams();
        IBank(_bank).getWalletAddress{callback : BaseCard.onBankWalletAddressUpdated}(_currency);
    }

    // INTERNAL

    function _validateTransfer(
        uint128 amount,
        TvmCell payload)
        internal
        override
    {
        super._validateTransfer(amount, payload);
        _validate(amount);
    }

    function _validate(
        uint128 amount
    )
        internal
    {
        while(block.timestamp >= _nextDay) {
            _nextDay += 1 days;
            _dailySpent = 0;
        }

        while(block.timestamp >= _nextMonth) {
            _nextMonth += 30 days;
            _monthlySpent = 0;
        }

        require(_dailySpent + amount <= _dailyLimit, ErrorCodes.DAILY_LIMIT_REACHED);
        require(_monthlySpent + amount <= _monthlyLimit, ErrorCodes.MONTHLY_LIMIT_REACHED);

        _dailySpent += amount;
        _monthlySpent += amount;
    }

    function _updateSpendingLimit(
        uint128 dailyLimit,
        uint128 monthlyLimit
    )
        internal
    {
        require(dailyLimit > 0, ErrorCodes.ZERO_DAILY_LIMIT);
        require(monthlyLimit > 0, ErrorCodes.ZERO_MONTHLY_LIMIT);

        _dailyLimit = dailyLimit;
        _monthlyLimit = monthlyLimit;
    }
}
