pragma ever-solidity >= 0.61.2;

pragma AbiHeader expire;
pragma AbiHeader time;

import './ManagerCollectionBase.sol';
import './ErrorCodes.sol';

contract ManagerCollection is ManagerCollectionBase {
    struct Manager {
        address owner;
        address manager;
        string json;
    }

    constructor(
        TvmCell codeNft,
        string json,
        TvmCell codeIndex,
        TvmCell codeIndexBasis,
        address admin,
        Manager[] initialManagers
    ) ManagerCollectionBase (
        codeNft,
        json,
        codeIndex,
        codeIndexBasis,
        admin
    )
    public {
        tvm.accept();
        for (Manager manager : initialManagers) {
            _mintNft(manager.json, manager.owner, manager.manager);
        }
    }

    /**
     * @notice Mints a new non-fungible token (NFT) and assigns it to an owner
     * @dev Can only be called by the contract administrator.
     * @param json The metadata of the NFT in the form of a JSON string.
     * @param owner The address of the owner to whom the NFT will be assigned.
     * @param manager The address of the manager responsible for managing the NFT.
     */
    function mintNft(
        string json,
        address owner,
        address manager
    ) external virtual override onlyAdmin {
        _mintNft(json, owner, manager);
    }

}

