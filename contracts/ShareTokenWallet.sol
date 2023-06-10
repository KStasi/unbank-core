pragma ever-solidity >= 0.61.2;

pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "@broxus/contracts/contracts/access/InternalOwner.tsol";
import "@broxus/contracts/contracts/utils/RandomNonce.tsol";
import "tip3/contracts/TokenRoot.sol";
import "tip3/contracts/TokenWallet.sol";
import "./ErrorCodes.sol";
import "./interfaces/IBank.sol";
import "./interfaces/IShareTokenRoot.sol";
import "./interfaces/IShareTokenWallet.sol";

/**
 * @title ShareTokenWallet
 * @author KStasi
 * @notice This contract is an implementation of the TokenWallet and IShareTokenWallet.
 * @notice It represents a token wallet with the feature to freeze the tokens until the end of the voting to vote for a proposal.
 * @dev The contract has two main state variables: a _frozenBalance and a mapping of castedVotes.
 * @dev The _frozenBalance tracks the total number of owner's tokens currently participated in voting for some proposals.
 * @dev The castedVotes maps a proposal ID to the number of unclaimed votes used in voting for specific proposal.
 */
contract ShareTokenWallet is TokenWallet, IShareTokenWallet {
    uint128 public _frozenBalance = 0;
    mapping(uint64 /*proposal_id*/ => uint128 /*locked_value*/) public castedVotes;

    /**
     * @dev Constructor: Initializes the TokenWallet contract.
     * @notice Should be called once on deployment.
     */
    constructor()
        public
        TokenWallet()
    {
        tvm.accept();
    }

    /**
     * @notice Submits a proposal.
     * @dev Can only be called by the contract owner.
     * @dev Requires non zero liquid balance.
     * @param dest The destination address for the proposed transaction.
     * @param value The amount of value to be sent.
     * @param bounce If true, the transfer fails if the destination address does not exist.
     * @param allBalance If true, sends the entire remaining balance.
     * @param payload The payload to be delivered to the destination address.
     * @param stateInit Optional initial state for the destination account.
     */
    function submitProposal(
        address dest,
        uint128 value,
        bool bounce,
        bool allBalance,
        TvmCell payload,
        optional(TvmCell) stateInit
    ) public view onlyOwner override {
        require(balance_ - _frozenBalance >= 0, ErrorCodes.NOT_ENOUGH_VOTES);
        IShareTokenRoot(root_).submitTransaction(
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

    /**
     * @notice Casts votes for a proposal.
     * @dev Can only be called by the contract owner.
     * @dev Requires that the proposal hasn't been voted for and liquid balance is greater than or equal to the votes.
     * @param trId The ID of the proposal to vote for.
     * @param votes The number of votes to cast.
     */
    function vote(uint64 trId, uint128 votes) public onlyOwner override {
        tvm.accept();
        require(!castedVotes.exists(trId), ErrorCodes.ALREADY_VOTED);
        require(balance_ - _frozenBalance >= votes, ErrorCodes.NOT_ENOUGH_VOTES);
        castedVotes[trId] = votes;
        _frozenBalance += votes;
        IShareTokenRoot(root_).confirmTransaction(trId, votes);
    }

    /**
     * @notice Claims unfrozen votes for a proposal after it was accepted or declined.
     * @dev Can only be called by the contract owner.
     * @dev Requires that the proposal has been voted for.
     * @param trId The ID of the proposal to claim votes for.
     */
    function claimVotes(uint64 trId) public onlyOwner override {
        tvm.accept();
        require(castedVotes.exists(trId), ErrorCodes.NOT_VOTED);
        uint128 votes = castedVotes[trId];
        _frozenBalance -= votes;
        delete castedVotes[trId];
    }

    /**
     * @notice Overrides the transfer function to make tokens non-transferable.
     * @dev Always reverts with the "NOT_TRANSFERABLE" error code.
     * @dev WTF? Why TIP3 ref implementation doesn't have virtual before/after hooks?
     * @param amount The amount to transfer.
     * @param recipient The recipient of the transfer.
     * @param deployWalletValue The amount of value to deploy a wallet if the recipient doesn't exist.
     * @param remainingGasTo The address to send the remaining gas to.
     * @param notify If true, a notification is sent to the recipient.
     * @param payload The payload to be delivered to the recipient address.
     */
    function transfer(
        uint128 amount,
        address recipient,
        uint128 deployWalletValue,
        address remainingGasTo,
        bool notify,
        TvmCell payload
    )
        override
        external
        onlyOwner
    {
        require(false, ErrorCodes.NOT_TRANSFERABLE);
    }
}