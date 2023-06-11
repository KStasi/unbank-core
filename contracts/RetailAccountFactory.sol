pragma ever-solidity >= 0.61.2;

pragma AbiHeader expire;

import "@broxus/contracts/contracts/utils/RandomNonce.tsol";
import "./interfaces/IRetailAccountFactory.sol";
import "./ErrorCodes.sol";
import "./BaseCard.sol";
import "./RetailAccount.sol";

// TODO: add index for all accounts
contract RetailAccountFactory is RandomNonce, IRetailAccountFactory {

    TvmCell public _accountCode;
    address public _cardsRegistry;
    address public _bank;
    address public _managerCollection;
    uint128 public _initialAmount;
    address public _requestsRegistry;

    modifier onlyManagerCollection() {
        require(msg.sender == _managerCollection, ErrorCodes.NOT_REGULAR_MANAGER);
        _;
    }

    modifier onlyBank() {
        require(msg.sender == _bank, ErrorCodes.NOT_REGULAR_MANAGER);
        _;
    }

    constructor(
        TvmCell code,
        address cardsRegistry,
        address bank,
        address requestsRegistry,
        address managerCollection,
        uint128 initialAmount
    ) public {
        tvm.accept();
        _accountCode = code;
        _cardsRegistry = cardsRegistry;
        _bank = bank;
        _managerCollection = managerCollection;
        _initialAmount = initialAmount;
        _requestsRegistry = requestsRegistry;
    }

    /**
     * @notice Deploy a new retail account with optional public key and owner address.
     * @dev This function is only callable by the manager collection.
     * @dev This function accepts the function call, hence any message attached to it will be consumed.
     * @param pubkey The optional public key.
     * @param owner The optional owner address.
     * @return The address of the newly deployed retail account.
     */
    function deployRetailAccount(
        optional(uint128) pubkey,
        optional(address) owner
    ) public onlyManagerCollection override returns (address) {
        tvm.accept();

        TvmCell code = _buildCode(address(this));
        TvmCell state = _buildState(code, pubkey, owner);

        address newRetailAccount = new RetailAccount{
            value: _initialAmount,
            stateInit: state
        }(_cardsRegistry, _bank, _requestsRegistry, _managerCollection);
        return newRetailAccount;
    }

    /**
     * @notice Set the cards registry address.
     * @dev This function is only callable by the bank.
     * @param cardsRegistry The address of the cards registry.
     */
    function setCardsRegistry(address cardsRegistry) override public onlyBank {
        _cardsRegistry = cardsRegistry;
    }

    /**
     * @notice Set the bank address.
     * @dev This function is only callable by the bank.
     * @param bank The address of the bank.
     */
    function setBank(address bank) override public onlyBank {
        _bank = bank;
    }

    /**
     * @notice Set the manager collection address.
     * @dev This function is only callable by the bank.
     * @param managerCollection The address of the manager collection.
     */
    function setManagerCollection(address managerCollection) override public onlyBank {
        _managerCollection = managerCollection;
    }

    /**
     * @notice Set the initial amount for retail accounts.
     * @dev This function is only callable by the bank.
     * @param initialAmount The initial amount for retail accounts.
     */
    function setInitialAmount(uint128 initialAmount) override public onlyBank {
        _initialAmount = initialAmount;
    }

    /**
     * @notice Set the account code.
     * @dev This function is only callable by the bank.
     * @param accountCode The code of the account.
     */
    function setAccountCode(TvmCell accountCode) override public onlyBank {
        _accountCode = accountCode;
    }

    /**
     * @notice Get the address of a retail account based on the optional public key and owner address.
     * @dev This function is responsible which means that it will not run out of gas during its execution.
     * @param pubkey The optional public key.
     * @param owner The optional owner address.
     * @return retailAccount The address of the retail account.
     */
    function retailAccountAddress(optional(uint128) pubkey, optional(address) owner) override external view virtual responsible returns (address retailAccount) {
        return {value: 0, flag: 64, bounce: false} (_resolveAccount(pubkey, owner));
    }

    function _resolveAccount(
        optional(uint128) pubkey,
        optional(address) owner
    ) internal virtual view returns (address nft) {
        TvmCell code = _buildCode(address(this));
        TvmCell state = _buildState(code, pubkey, owner);
        uint256 hashState = tvm.hash(state);
        nft = address.makeAddrStd(address(this).wid, hashState);
    }

    function _buildCode(address factory) internal virtual view returns (TvmCell) {
        TvmBuilder salt;
        salt.store(factory);
        return tvm.setCodeSalt(_accountCode, salt.toCell());
    }

    function _buildState(
        TvmCell code,
        optional(uint128) pubkey,
        optional(address) owner
    ) internal virtual pure returns (TvmCell) {
        return tvm.buildStateInit({
            contr: RetailAccount,
            pubkey: pubkey.hasValue() ? pubkey.get() : 0,
            varInit: {
                _ownerPublicKey: pubkey,
                _ownerAddress: owner
            },
            code: code
        });
    }

}
