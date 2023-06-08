pragma ever-solidity >= 0.61.2;

import "./BaseCard.sol";
import "@broxus/contracts/contracts/utils/RandomNonce.tsol";

// TODO: add random nonce where it's needed
// TODO: add static variables for all contracts where it's needed

contract CardsRegistry is RandomNonce {
    struct CardInfo {
        uint8 id;
        TvmCell code;
    }

    uint128 public _initialDeposit = 1.5 ever;

    mapping(uint8 => TvmCell) public _cardsCode;

    constructor(CardInfo[] initialCards) public {
        tvm.accept();
        for ( CardInfo cardInfo : initialCards ) {
            _cardsCode[cardInfo.id] = cardInfo.code;
        }
    }

    function addCardCode(uint8 cardTypeId, TvmCell cardCode) public  {
        tvm.accept();
        _cardsCode[cardTypeId] = cardCode;
    }

    function deployCard(
        address currency,
        address owner,
        address bank,
        uint8 cardTypeId,
        BaseCard.CardType cardType,
        TvmCell cardDetails)
        public responsible
        returns (address tokenWallet)
    {
        // TODO: ensure called from account
        tvm.accept();
        TvmCell cardCode = _cardsCode[cardTypeId];

        // TODO: update to make it work & make contract upgradable
        address newCard = new BaseCard{
            value: _initialDeposit,
            // value: 0,
            code: cardCode,
            varInit: {_owner: owner, _currency: currency, _bank: bank, _cardType: cardType },
            flag: 1
            }(cardDetails);

        return { value: 0.1 ever, flag: 1, bounce: false } newCard;
    }
}