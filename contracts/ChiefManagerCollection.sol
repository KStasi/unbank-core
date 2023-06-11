pragma ever-solidity >= 0.61.2;

pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import './ManagerCollectionBase.sol';
import './ErrorCodes.sol';

contract ChiefManagerCollection is ManagerCollectionBase {
    struct ChiefManager {
        address owner;
        string json;
    }
    constructor(
        TvmCell codeNft,
        string json,
        TvmCell codeIndex,
        TvmCell codeIndexBasis,
        address admin,
        ChiefManager[] initialChiefManagers
    ) ManagerCollectionBase (
        codeNft,
        json,
        codeIndex,
        codeIndexBasis,
        admin
    )
    public {
        tvm.accept();
        for (ChiefManager chiefManager : initialChiefManagers) {
            _mintNft(chiefManager.json, chiefManager.owner, admin);
        }
    }
    /**
     * @notice Mints a new non-fungible token (NFT) and assigns it to an owner
     * @dev Can only be called by the contract administrator.
     * @param json The metadata of the NFT in the form of a JSON string.
     * @param owner The address of the owner to whom the NFT will be assigned.
     * @param _manager The address is always set to the Share Token Root.
     */
    function mintNft(
        string json,
        address owner,
        address _manager
    ) external virtual override onlyAdmin {
        _mintNft(json, owner, msg.sender);
    }

}

