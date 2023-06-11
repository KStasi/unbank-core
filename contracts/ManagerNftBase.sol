pragma ever-solidity >= 0.61.2;
pragma AbiHeader expire;
pragma AbiHeader pubkey;

// importing all standards bases
import '@itgold/everscale-tip/contracts/TIP4_1/TIP4_1Nft.sol';
import '@itgold/everscale-tip/contracts/TIP4_2/TIP4_2Nft.sol';
import '@itgold/everscale-tip/contracts/TIP4_3/TIP4_3Nft.sol';
import "./ErrorCodes.sol";
import './interfaces/ITokenBurned.sol';
import './interfaces/IManagerNftBase.sol';
import './ManagerCollectionBase.sol';

/**
 * @title ManagerNftBase
 * @notice This contract is a base for managing role NFTs and extends TIP4_1Nft, TIP4_2Nft, and TIP4_3Nft.
 * @notice It includes additional functionality for burning tokens and sending transactions.
 * @dev The contract uses an 'onlyOwner' modifier to restrict certain functions to the owner of the contract.
 * @dev The contract defines additional behavior before and after token transfer or owner change events.
 * @dev The _beforeTransfer, _afterTransfer, _beforeChangeOwner, and _afterChangeOwner functions are overriden from the TIP4_1Nft and TIP4_3Nft contracts.
 * @dev These functions ensure the token is non-transferable.
 * @dev The contract includes a burn function to destroy the contract and send remaining funds to a specified address.
 * @dev A sendTransaction function is also defined to allow the contract owner to send a transaction to a specified address with a certain value and payload.
 */
contract ManagerNftBase is TIP4_1Nft, TIP4_2Nft, TIP4_3Nft, IManagerNftBase {
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

    /**
     * @notice Burn the NFT
     * @param dest The address to receive any remaining funds after self-destruction
     */
    function burn(address dest) external virtual onlyManager override {
        tvm.accept();
        ITokenBurned(_collection).onTokenBurned(_id, _owner, _manager);
        selfdestruct(dest);
    }

    /**
     * @notice Send a transaction to a given destination with a specified value and payload.
     * @param dest The destination address of the transaction.
     * @param value The value in tokens to be sent.
     * @param bounce Whether the transaction should fail if the recipient doesn't exist.
     * @param flags Transfer flags to specify transaction details.
     * @param payload Optional payload to be sent with the transaction.
     */
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
        override
    {
        tvm.accept();
        dest.transfer(value, bounce, flags, payload);
        // ManagerCollectionBase(_collection).callAsAnyManager(_owner, dest, value, bounce, flags, payload);
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