pragma ever-solidity >= 0.61.2;

pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "@broxus/contracts/contracts/access/InternalOwner.tsol";
import "@broxus/contracts/contracts/utils/RandomNonce.tsol";
import "tip3/contracts/TokenRoot.sol";
import "tip3/contracts/TokenWallet.sol";
import "./ErrorCodes.sol";
import "./interfaces/IBank.sol";

contract ShareTokenWallet is TokenWallet {
    uint128 public _frozenBalance;
    mapping(uint32 /*proposal_id*/ => uint128 /*locked_value*/) public castedVotes;

    constructor()
        public
        TokenWallet()
    {}

    function submitProposal() public view onlyOwner {

    }

    function vote(uint64 trId, uint128 votes) public view onlyOwner {

    }
    function claimVotes(uint64 trId) public view onlyOwner {

    }

    // TODO: add vote on wallet
    // TODO: add claimVotes on wallet
    // TODO: add voted proposal mark on wallet
    // TODO: make non transferable
}