pragma ton-solidity >= 0.61.2;

interface ITokenBurned {
    function onTokenBurned(uint256 id, address owner, address manager) external;
}