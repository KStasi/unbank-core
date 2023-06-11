pragma ever-solidity >= 0.61.2;

interface IManagerCollectionBase {
    function mintNft(
        string memory json,
        address owner,
        address manager
    ) external;

    function onTokenBurned(
        uint256 id,
        address owner,
        address manager
    ) external;

    function callAsAnyManager(
        address owner,
        address dest,
        uint128 value,
        bool bounce,
        uint8 flags,
        TvmCell payload
    ) external view;
}
