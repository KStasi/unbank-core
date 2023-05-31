pragma ever-solidity >= 0.61.2;

pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import '@itgold/everscale-tip/contracts/TIP4_2/TIP4_2Collection.sol';
import '@itgold/everscale-tip/contracts/TIP4_3/TIP4_3Collection.sol';
import './ManagerNftBase.sol';
import './ErrorCodes.sol';

contract ManagerCollectionBase is TIP4_2Collection, TIP4_3Collection {

    uint128 _remainOnNft = 0.3 ton;
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
        require(msg.value > _remainOnNft + 0.1 ton, ErrorCodes.NOT_ENOUGH_RESERVE);
        tvm.rawReserve(0, 4); // TODO: stop panic and decide what to do with it

        (int8 _wid, uint addr) = owner.unpack();
        uint256 id = uint256(addr);
        _totalSupply++;

        TvmCell codeNft = _buildNftCode(address(this));
        TvmCell stateNft = _buildNftState(codeNft, id);

        address nftAddr = new ManagerNftBase{
            stateInit: stateNft,
            value: 0,
            flag: 128
        }(
            owner,
            manager,
            _remainOnNft,
            json,
            _codeIndex,
            _indexDeployValue,
            _indexDestroyValue,
            msg.sender
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
        (int8 _wid, uint addr) = owner.unpack();
        require(msg.sender == _resolveNft(addr));
        tvm.accept();

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

