pragma ever-solidity >= 0.61.2;

pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import './ManagerCollectionBase.sol';
import './ManagerNftBase.sol';
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

    function mintNft(
        string json,
        address owner,
        address _manager
    ) external virtual override onlyAdmin {
        _mintNft(json, owner, msg.sender);
    }

}

