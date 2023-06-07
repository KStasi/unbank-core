pragma ever-solidity >= 0.61.2;

import "./BaseCard.sol";
import "@broxus/contracts/contracts/utils/RandomNonce.tsol";

// TODO: add random nonce where it's needed
// TODO: add static variables for all contracts where it's needed

contract CardsRegistry is RandomNonce {
    struct CardInfo {
        uint128 id;
        TvmCell code;
    }

    uint128 public _initialDeposit = 0.1 ever;

    mapping(uint128 => TvmCell) public _cardsCode;

    constructor(CardInfo[] initialCards) public {
        tvm.accept();
        for ( CardInfo cardInfo : initialCards ) {
            _cardsCode[cardInfo.id] = cardInfo.code;
        }
    }

    function addCardCode(uint128 cardTypeId, TvmCell cardCode) public  {
        tvm.accept();
        _cardsCode[cardTypeId] = cardCode;
    }

    function deployCard(
        uint128 cardTypeId,
        TvmCell cardDetails)
        public responsible
        returns (address tokenWallet)
    {
        // TODO: ensure called from account
        tvm.accept();
        TvmCell cardCode = _cardsCode[cardTypeId];
        // TODO: update to make it work & make contract upgradable
        address newCard = new BaseCard{value: _initialDeposit, code: cardCode}(cardDetails);

        return { value: 0, flag: 64, bounce: false } newCard;
    }
}