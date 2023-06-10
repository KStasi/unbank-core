pragma ever-solidity >= 0.61.2;

interface IShareTokenRoot {
    function addWallet(address currencyRoot) external;
    function onWalletCreated(address _wallet) external;
    function submitTransaction(address sender, uint128 senderBalance, address dest, uint128 value, bool bounce, bool allBalance, TvmCell payload, optional(TvmCell) stateInit) external returns (uint64 transId);
    function mintForDeposit(uint64 depositId, uint128 amount, uint128 deployWalletValue, address remainingGasTo, bool notify, TvmCell payload) external;
    function confirmTransaction(uint64 trId, uint128 votes) external;
    function setDefaultQuorumRate(uint32 newRate) external;
    function setLifetime(uint32 newLifetime) external;
    function setMinProposerBalance(uint128 newBalance) external;
    function setDepositLock(uint32 newLock) external;
    function setDeployWalletValue(uint128 newValue) external;
    function unlockValue(uint64 depositId) external;
}
