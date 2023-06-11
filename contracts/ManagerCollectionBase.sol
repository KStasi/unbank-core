pragma ever-solidity >= 0.61.2;

pragma AbiHeader expire;
pragma AbiHeader time;

import "@broxus/contracts/contracts/utils/RandomNonce.tsol";
import '@itgold/everscale-tip/contracts/TIP4_2/TIP4_2Collection.sol';
import '@itgold/everscale-tip/contracts/TIP4_3/TIP4_3Collection.sol';
import 'tip3/contracts/libraries/TokenMsgFlag.sol';
import './interfaces/IManagerCollectionBase.sol';
import './ManagerNftBase.sol';
import './ErrorCodes.sol';

contract ManagerCollectionBase is TIP4_2Collection, TIP4_3Collection, RandomNonce, IManagerCollectionBase {

    uint128 _remainOnNft = 0.3 ton;
    uint128 _deployValue = 0.9 ton;
    address _admin;

    /**
     * @notice Modifier to allow only the admin to call a function.
     * @dev Checks if the msg.sender is the admin address. If not, it throws an error.
     */
    modifier onlyAdmin() {
        require(msg.sender == _admin, ErrorCodes.NOT_OWNER);
        _;
    }

    /**
     * @notice Constructor for ManagerCollectionBase, inherits from TIP4_2Collection and TIP4_3Collection.
     * @dev Sets up the contract with the specified parameters.
     * @param codeNft The TVM cell code for the NFT.
     * @param json The JSON metadata for the NFT.
     * @param codeIndex The TVM cell code for the index.
     * @param codeIndexBasis The TVM cell code for the index basis.
     * @param admin The admin address for the contract.
     */
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

    /**
     * @notice Mints a new NFT.
     * @dev Can only be called by the contract admin.
     * @param json The JSON metadata for the NFT.
     * @param owner The owner address for the NFT.
     * @param manager The manager address for the NFT.
     */
    function mintNft(
        string json,
        address owner,
        address manager
    ) external virtual onlyAdmin override {
        _mintNft(json, owner, manager);
    }

    /**
     * @notice Handles the event of an NFT being burned.
     * @dev Requires that the sender is the NFT in question.
     * @param id The ID of the NFT being burned.
     * @param owner The owner address of the NFT.
     * @param manager The manager address of the NFT.
     */
    function onTokenBurned(uint256 id, address owner, address manager) external  override {
        require(msg.sender == _resolveNft(id));
        emit NftBurned(id, msg.sender, owner, manager);
        _totalSupply--;
    }

    /**
     * @notice Sends a transaction from the NFT to a specified destination. Cab be used to prove the user owns NFT.
     * @dev Requires that the sender is any NFT.
     * @param owner The owner address of the NFT.
     * @param dest The destination address of the transaction.
     * @param value The value of the transaction.
     * @param bounce Whether to bounce the transaction.
     * @param flags Flags for the transaction.
     * @param payload The payload of the transaction.
     */
    function callAsAnyManager(
        address owner,
        address dest,
        uint128 value,
        bool bounce,
        uint8 flags,
        TvmCell payload
    ) public view override {
        tvm.accept();
        // TODO: do before accept
        (int8 _wid, uint addr) = owner.unpack();
        bool eqa = msg.sender == _resolveNft(addr);
        require(eqa, ErrorCodes.NOT_NFT);

        dest.transfer(value, bounce, flags, payload);
    }

    /**
     * @notice Internal function to mint a new NFT.
     * @dev Constructs the state of the NFT and deploys a new ManagerNftBase contract.
     * @param json The JSON metadata for the NFT.
     * @param owner The owner address for the NFT.
     * @param manager The manager address for the NFT.
     */
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

    /**
     * @notice Builds the state of the NFT.
     * @dev Overrides the corresponding function in TIP4_2Collection and TIP4_3Collection.
     * @param code The TVM cell code for the NFT.
     * @param id The ID of the NFT.
     * @return The state of the NFT as a TVM cell.
     */
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

