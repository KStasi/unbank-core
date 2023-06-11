pragma ever-solidity >= 0.61.2;

interface IRequestsRegistry {

    function deployProposal(address chiefManager, TvmCell callPayload, uint128 value, uint8 flags) external returns (address);

    function execute(uint64 id, address dest, uint128 value, uint8 flags, TvmCell payload) external;
}
