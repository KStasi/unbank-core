pragma ever-solidity >= 0.61.2;

pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "@broxus/contracts/contracts/access/InternalOwner.tsol";
import "@broxus/contracts/contracts/utils/RandomNonce.tsol";
import "tip3/contracts/TokenRoot.sol";
import "tip3/contracts/TokenWallet.sol";
import "./ErrorCodes.sol";
import "./interfaces/IBank.sol";
import "./ShareTokenRoot.sol";

contract ShareTokenWallet is TokenWallet {
    uint128 public _frozenBalance;
    mapping(uint64 /*proposal_id*/ => uint128 /*locked_value*/) public castedVotes;

    constructor()
        public
        TokenWallet()
    {}

    function submitProposal(
        address dest,
        uint128 value,
        bool bounce,
        bool allBalance,
        TvmCell payload,
        optional(TvmCell) stateInit
    ) public view onlyOwner {
        require(balance_ - _frozenBalance >= 0, ErrorCodes.NOT_ENOUGH_VOTES);
        ShareTokenRoot(root_).submitTransaction(
            address(this),
            balance_,
            dest,
            value,
            bounce,
            allBalance,
            payload,
            stateInit
        );
    }

    function vote(uint64 trId, uint128 votes) public onlyOwner {
        tvm.accept();
        require(!castedVotes.exists(trId), ErrorCodes.ALREADY_VOTED);
        require(balance_ - _frozenBalance >= votes, ErrorCodes.NOT_ENOUGH_VOTES);
        castedVotes[trId] = votes;
        _frozenBalance += votes;
        ShareTokenRoot(root_).confirmTransaction(trId, votes);
    }

    function claimVotes(uint64 trId) public onlyOwner {
        tvm.accept();
        require(castedVotes.exists(trId), ErrorCodes.NOT_VOTED);
        uint128 votes = castedVotes[trId];
        _frozenBalance -= votes;
        delete castedVotes[trId];
    }

    // TODO: make shares non transferable.
    // dev: WTF? Why TIP3 ref implementation doesn't have virtual before/after hooks?
    // function transfer(
    //     uint128 amount,
    //     address recipient,
    //     uint128 deployWalletValue,
    //     address remainingGasTo,
    //     bool notify,
    //     TvmCell payload
    // )
    //     override
    //     external
    //     onlyOwner
    // {
    //     require(false, ErrorCodes.NOT_TRANSFERABLE);
    // }
}