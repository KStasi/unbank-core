pragma ever-solidity >= 0.61.2;

interface IManagerNftBase {
    function burn(address dest) external;

    function sendTransaction(
        address dest,
        uint128 value,
        bool bounce,
        uint8 flags,
        TvmCell payload
    ) external view;
}
