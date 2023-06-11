pragma ever-solidity >= 0.61.2;

interface IRetailAccountFactory {

    function deployRetailAccount(optional(uint128) pubkey, optional(address) owner) external returns (address);

    function setCardsRegistry(address cardsRegistry) external;

    function setBank(address bank) external;

    function setManagerCollection(address managerCollection) external;

    function setInitialAmount(uint128 initialAmount) external;

    function setAccountCode(TvmCell accountCode) external;

    function retailAccountAddress(optional(uint128) pubkey, optional(address) owner) external view responsible returns (address);
}
