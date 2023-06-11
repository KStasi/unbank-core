pragma ever-solidity >= 0.61.2;

pragma AbiHeader expire;

import "./ErrorCodes.sol";
import "./Proposal.sol";
import "@broxus/contracts/contracts/utils/RandomNonce.tsol";
import "./interfaces/IRequestsRegistry.sol";

contract RequestsRegistry is RandomNonce, IRequestsRegistry {
    address public _managerCollection;
    TvmCell public _proposalCode;
    uint64 public _proposalsCount = 0;

    modifier onlyManagerCollection() {
        require(msg.sender == _managerCollection, ErrorCodes.NOT_REGULAR_MANAGER);
        _;
    }

    constructor(address managerCollection, TvmCell proposalCode) public {
        tvm.accept();
        _managerCollection = managerCollection;
        _proposalCode = proposalCode;
    }

    /**
     * @notice Deploys a new proposal.
     * @dev This function is only callable by the manager collection.
     * @param chiefManager The address of the chief manager for the proposal.
     * @param callPayload The payload of the function call to be executed in the proposal.
     * @param value The amount of value to be transferred in the proposal.
     * @param flags The flags to be used in the transfer operation.
     * @return The address of the deployed proposal.
     */
    function deployProposal(address chiefManager, TvmCell callPayload, uint128 value, uint8 flags) public override onlyManagerCollection returns (address) {
        tvm.accept();
        address newProposal = new Proposal{
            value: 1 ton,
            code: _proposalCode,
            varInit: {_id: _proposalsCount, _callPayload: callPayload, _value: value, _flags: flags, _requestsRegistry: address(this)}
        }(chiefManager);

        _proposalsCount++;
        return newProposal;
    }

    /**
     * @notice Executes a proposal.
     * @dev This function is called by the proposal itself to execute the specified request.
     * @dev Requires that the function is called by the proposal address.
     * @param id The ID of the proposal.
     * @param dest The destination address for the transfer operation.
     * @param value The amount of value to be transferred.
     * @param flags The flags to be used in the transfer operation.
     * @param payload The payload to be included in the transfer operation.
     */
    function execute(uint64 id, address dest, uint128 value, uint8 flags, TvmCell payload) public override {
        require(msg.sender == address(tvm.hash(_buildProposalInitData(id, dest, value, flags, payload))), ErrorCodes.SENDER_IS_NOT_PROPOSAL);
        tvm.accept();

        dest.transfer(value, false, flags, payload);
    }

    function _buildProposalInitData(
        uint64 id,
        address dest,
        uint128 value,
        uint8 flags,
        TvmCell payload
    ) internal view returns (TvmCell) {
        return tvm.buildStateInit({
            contr: Proposal,
            varInit: {
                _id: id,
                _callPayload: payload,
                _value: value,
                _flags: flags,
                _requestsRegistry: address(this)
            },
            pubkey: 0,
            code: _proposalCode
        });
    }

}
