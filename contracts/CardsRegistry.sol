pragma ever-solidity >= 0.61.2;

import "./BaseCard.sol";

contract CardsRegistry {
    uint128 public initialDeposit = 0.1 ever;

    mapping(uint128 => TvmCell) public cardsCode;

    constructor() public {
    }

    function deployCard(
        uint128 _cardTypeId,
        TvmCell _cardDetails)
        public responsible
        returns (address tokenWallet)
    {
        tvm.accept();
        TvmCell cardCode = cardsCode[_cardTypeId];
        // TODO: update to make it work & make contract upgradable
        address newCard = new BaseCard{value: initialDeposit, code: cardCode}(_cardDetails);

        // TODO: should we replace callback with specific call to sender for security?
        return { value: 0, flag: 64, bounce: false } newCard;
    }
}