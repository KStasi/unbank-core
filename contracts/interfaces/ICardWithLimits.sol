pragma ever-solidity >= 0.61.2;

interface ICardWithLimits {
    function updateSpendingLimit(uint128 dailyLimit, uint128 monthlyLimit) external;
}
