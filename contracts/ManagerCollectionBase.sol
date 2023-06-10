pragma ever-solidity >= 0.61.2;

pragma AbiHeader expire;
pragma AbiHeader time;

import "@broxus/contracts/contracts/utils/RandomNonce.tsol";
import '@itgold/everscale-tip/contracts/TIP4_2/TIP4_2Collection.sol';
import '@itgold/everscale-tip/contracts/TIP4_3/TIP4_3Collection.sol';
import 'tip3/contracts/libraries/TokenMsgFlag.sol';
import './ManagerNftBase.sol';
import './ErrorCodes.sol';

contract ManagerCollectionBase is TIP4_2Collection, TIP4_3Collection, RandomNonce {

    uint128 _remainOnNft = 0.3 ton;
    uint128 _deployValue = 0.9 ton;
    address _admin;

    modifier onlyAdmin() {
        require(msg.sender == _admin, ErrorCodes.NOT_OWNER);
        _;
    }

    constructor(
        TvmCell codeNft,
        string json,
        TvmCell codeIndex,
        TvmCell codeIndexBasis,
        address admin
    ) TIP4_1Collection (
        codeNft
    ) TIP4_2Collection (
        json
    ) TIP4_3Collection (
        codeIndex,
        codeIndexBasis
    )
    public {
        tvm.accept();
        _admin = admin;
    }


    function mintNft(
        string json,
        address owner,
        address manager
    ) external virtual onlyAdmin {
        _mintNft(json, owner, manager);
    }

    function _mintNft(
        string json,
        address owner,
        address manager
    ) internal virtual {
        (int8 _wid, uint addr) = owner.unpack();
        uint256 id = uint256(addr);
        _totalSupply++;

        TvmCell codeNft = _buildNftCode(address(this));
        TvmCell stateNft = _buildNftState(codeNft, id);

        address nftAddr = new ManagerNftBase{
            stateInit: stateNft,
            value: _deployValue,
            flag: TokenMsgFlag.SENDER_PAYS_FEES
        }(
            owner,
            address(this),
            _remainOnNft,
            json,
            _codeIndex,
            _indexDeployValue,
            _indexDestroyValue,
            manager
        );

        emit NftCreated(
            id,
            nftAddr,
            owner,
            manager,
            msg.sender
        );
    }

    function onTokenBurned(uint256 id, address owner, address manager) external  {
        require(msg.sender == _resolveNft(id));
        emit NftBurned(id, msg.sender, owner, manager);
        _totalSupply--;
    }

    function callAsAnyManager(
        address owner,
        address dest,
        uint128 value,
        bool bounce,
        uint8 flags,
        TvmCell payload
    ) public view {
        tvm.accept();
        // TODO: do before accept
        (int8 _wid, uint addr) = owner.unpack();
        bool eqa = msg.sender == _resolveNft(addr);
        require(eqa, ErrorCodes.NOT_NFT);

        dest.transfer(value, bounce, flags, payload);
    }


    function _buildNftState(TvmCell code, uint256 id)
		internal
		pure
		virtual
		override (TIP4_2Collection, TIP4_3Collection)
		returns (TvmCell)
	{
		return tvm.buildStateInit({contr: ManagerNftBase, varInit: {_id: id}, code: code});
	}
}

