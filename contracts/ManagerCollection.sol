pragma ever-solidity >= 0.61.2;

pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import './ManagerCollectionBase.sol';
import './ManagerNftBase.sol';
import './ErrorCodes.sol';

contract ManagerCollection is ManagerCollectionBase {
    constructor(
        TvmCell codeNft,
        string json,
        TvmCell codeIndex,
        TvmCell codeIndexBasis,
        address admin
    ) ManagerCollectionBase (
        codeNft,
        json,
        codeIndex,
        codeIndexBasis,
        admin
    )
    public {
        tvm.accept();
    }

    function mintNft(
        string json,
        address owner,
        address manager
    ) external virtual override onlyAdmin {
        _mintNft(json, owner, manager);
    }

}

