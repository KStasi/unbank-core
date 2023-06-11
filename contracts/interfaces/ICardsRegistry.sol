pragma ever-solidity >= 0.61.2;

import "../BaseCard.sol";
interface ICardsRegistry {
    function addCardCode(uint8 cardTypeId, TvmCell cardCode) external;

    function deployCard(
        address currency,
        address owner,
        address bank,
        uint8 cardTypeId,
        BaseCard.CardType cardType,
        TvmCell cardDetails
    ) external responsible returns (address tokenWallet);
}