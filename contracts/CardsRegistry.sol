pragma ever-solidity >= 0.61.2;

import "./BaseCard.sol";
import "@broxus/contracts/contracts/utils/RandomNonce.tsol";
import "@broxus/contracts/contracts/access/InternalOwner.tsol";
import "./interfaces/ICardsRegistry.sol";

contract CardsRegistry is RandomNonce, ICardsRegistry, InternalOwner {
    struct CardInfo {
        uint8 id;
        TvmCell code;
    }

    uint128 public _initialDeposit = 0.8 ever;

    mapping(uint8 => TvmCell) public _cardsCode;

    constructor(CardInfo[] initialCards, address owner) public {
        tvm.accept();
        setOwnership(owner);
        for ( CardInfo cardInfo : initialCards ) {
            _cardsCode[cardInfo.id] = cardInfo.code;
        }
    }

    /**
     * @notice Add a card code associated with a given card type ID.
     * @dev This function can only be called by the owner.
     * @param cardTypeId The ID representing the card type.
     * @param cardCode The code of the card associated with the card type ID.
     */
    function addCardCode(uint8 cardTypeId, TvmCell cardCode) public override onlyOwner() {
        tvm.accept();
        _cardsCode[cardTypeId] = cardCode;
    }

    /**
     * @notice Deploys a new card of the specified card type with the given details.
     * @dev This function is responsible which means that it will not run out of gas during its execution.
     * @param currency The currency of the card.
     * @param owner The owner of the card.
     * @param bank The bank associated with the card.
     * @param cardTypeId The ID representing the card type.
     * @param cardType The type of the card.
     * @param cardDetails The details of the card.
     * @return tokenWallet The address of the token wallet.
     */
    function deployCard(
        address currency,
        address owner,
        address bank,
        uint8 cardTypeId,
        BaseCard.CardType cardType,
        TvmCell cardDetails)
        public responsible override
        returns (address tokenWallet)
    {
        // TODO: ensure called from account
        tvm.accept();
        TvmCell cardCode = _cardsCode[cardTypeId];

        address newCard = new BaseCard{
            value: _initialDeposit,
            code: cardCode,
            varInit: {_owner: owner, _currency: currency, _bank: bank, _cardType: cardType },
            flag: 1
            }(cardDetails);
        return { value: 0.1 ever, flag: 1, bounce: false } newCard;
    }
}