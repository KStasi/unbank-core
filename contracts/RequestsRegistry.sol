pragma ever-solidity >= 0.61.2;

pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "./ErrorCodes.sol";
import "./Proposal.sol";

contract RequestsRegistry {
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

    function deployProposal(address chiefManager, TvmCell callPayload, uint128 value, uint8 flags) public onlyManagerCollection returns (address) {
        tvm.accept();
        address newProposal = new Proposal{
            value: 1 ton,
            code: _proposalCode,
            varInit: {_id: _proposalsCount, _callPayload: callPayload, _value: value, _flags: flags, _requestsRegistry: address(this)}
        }(chiefManager);

        _proposalsCount++;
        return newProposal;
    }

    function execute(uint64 id, address dest, uint128 value, uint8 flags, TvmCell payload) public {
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
