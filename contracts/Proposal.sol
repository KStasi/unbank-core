pragma ever-solidity >= 0.61.2;

pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "./ErrorCodes.sol";
import "./RequestsRegistry.sol";
import "./interfaces/IProposal.sol";
contract Proposal is IProposal {
    address _chiefManager;

    uint64 static _id;
    TvmCell static _callPayload;
    uint128 static _value;
    uint8 static _flags;
    address static _requestsRegistry;
    bool _isApproved = false;

    modifier onlyChiefManager() {
        require(msg.sender == _chiefManager, ErrorCodes.NOT_REGULAR_MANAGER);
        _;
    }

    constructor(address chiefManager) public {
        tvm.accept();
        _chiefManager = chiefManager;
    }

    /**
     * @notice Approves the proposal.
     * @dev This function is only callable by the chief manager.
     * @dev This function accepts the function call, hence any message attached to it will be consumed.
     * @dev Executes the request specified in the proposal.
     */
    function approve() public onlyChiefManager override {
        tvm.accept();
        _isApproved = true;
        RequestsRegistry(_requestsRegistry).execute(_id, address(this), _value, _flags, _callPayload);
    }
}
