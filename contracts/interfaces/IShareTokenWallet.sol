pragma ever-solidity >= 0.61.2;
interface IShareTokenWallet {
    function submitProposal(
        address dest,
        uint128 value,
        bool bounce,
        bool allBalance,
        TvmCell payload,
        optional(TvmCell) stateInit
    ) external view;

    function vote(uint64 trId, uint128 votes) external;

    function claimVotes(uint64 trId) external;
}
