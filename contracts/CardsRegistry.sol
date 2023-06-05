pragma ever-solidity >= 0.61.2;

import "./BaseCard.sol";
// import "./utils/RandomNonce.sol";

// TODO: add random nonce where it's needed
// TODO: add static variables for all contracts where it's needed

contract CardsRegistry {
    uint128 public initialDeposit = 0.1 ever;

    mapping(uint128 => TvmCell) public cardsCode;

    constructor() public {
        tvm.accept();
    }

    function deployCard(
        uint128 _cardTypeId,
        TvmCell _cardDetails)
        public responsible
        returns (address tokenWallet)
    {
        // TODO: ensure called from account
        tvm.accept();
        TvmCell cardCode = cardsCode[_cardTypeId];
        // TODO: update to make it work & make contract upgradable
        address newCard = new BaseCard{value: initialDeposit, code: cardCode}(_cardDetails);

        return { value: 0, flag: 64, bounce: false } newCard;
    }
}