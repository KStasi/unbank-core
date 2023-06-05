pragma ever-solidity >= 0.61.2;
pragma AbiHeader expire;
pragma AbiHeader pubkey;

// importing all standards bases
import '@itgold/everscale-tip/contracts/TIP4_1/TIP4_1Nft.sol';
import '@itgold/everscale-tip/contracts/TIP4_2/TIP4_2Nft.sol';
import '@itgold/everscale-tip/contracts/TIP4_3/TIP4_3Nft.sol';
import "./ErrorCodes.sol";
import './interfaces/ITokenBurned.sol';
import './ManagerCollectionBase.sol';

contract ManagerNftBase is TIP4_1Nft, TIP4_2Nft, TIP4_3Nft {
    modifier onlyOwner() {
        require(msg.sender == _owner, ErrorCodes.NOT_OWNER);
        _;
    }
    constructor(
        address owner,
        address sendGasTo,
        uint128 remainOnNft,
        string json,
        TvmCell codeIndex,
        uint128 indexDeployValue,
		uint128 indexDestroyValue,
        address manager
    ) TIP4_1Nft(
        owner,
        sendGasTo,
        remainOnNft
    ) TIP4_2Nft (
        json
    ) TIP4_3Nft (
        indexDeployValue,
        indexDestroyValue,
        codeIndex
    )
    public {
        tvm.accept();
        _manager = manager;
    }

    function burn(address dest) external virtual onlyManager {
        tvm.accept();
        ITokenBurned(_collection).onTokenBurned(_id, _owner, _manager);
        selfdestruct(dest);
    }

    function sendTransaction(
        address dest,
        uint128 value,
        bool bounce,
        uint8 flags,
        TvmCell payload
    )
        public
        view
        onlyOwner
    {
        tvm.accept();
        ManagerCollectionBase(_collection).callAsAnyManager(_owner, dest, value, bounce, flags, payload);
    }

    function _beforeTransfer(
        address to,
        address sendGasTo,
        mapping(address => CallbackParams) callbacks
    ) internal virtual override(TIP4_1Nft, TIP4_3Nft) {
        require(false, ErrorCodes.NFT_NON_TRANSFERABLE);
        TIP4_3Nft._destructIndex(sendGasTo);
    }

    function _afterTransfer(
        address to,
        address sendGasTo,
        mapping(address => CallbackParams) callbacks
    ) internal virtual override(TIP4_1Nft, TIP4_3Nft) {
        TIP4_3Nft._deployIndex();
    }

    function _beforeChangeOwner(
        address oldOwner,
        address newOwner,
        address sendGasTo,
        mapping(address => CallbackParams) callbacks
    ) internal virtual override(TIP4_1Nft, TIP4_3Nft) {
        require(false, ErrorCodes.NFT_NON_TRANSFERABLE);
        TIP4_3Nft._destructIndex(sendGasTo);
    }

    function _afterChangeOwner(
        address oldOwner,
        address newOwner,
        address sendGasTo,
        mapping(address => CallbackParams) callbacks
    ) internal virtual override(TIP4_1Nft, TIP4_3Nft) {
        TIP4_3Nft._deployIndex();
    }

}