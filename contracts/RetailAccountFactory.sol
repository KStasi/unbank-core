pragma ever-solidity >= 0.61.2;

pragma AbiHeader expire;

import "@broxus/contracts/contracts/access/ExternalOwner.tsol";
import "@broxus/contracts/contracts/utils/RandomNonce.tsol";
import "./ErrorCodes.sol";
import "./CardsRegistry.sol";
import "./BaseCard.sol";
import "./RetailAccount.sol";

// TODO: add index for all accounts
contract RetailAccountFactory {

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

    function deployRetailAccount(
        optional(uint128) pubkey,
        optional(address) owner
    ) public onlyManagerCollection returns (address) {
        tvm.accept();

        TvmCell code = _buildCode(address(this));
        TvmCell state = _buildState(code, pubkey, owner);

        address newRetailAccount = new RetailAccount{
            value: _initialAmount,
            flag: 0,
            stateInit: state
        }(_cardsRegistry, _bank, _requestsRegistry, _managerCollection);
        return newRetailAccount;
    }

    function setCardsRegistry(address cardsRegistry) public onlyBank {
        _cardsRegistry = cardsRegistry;
    }

    function setBank(address bank) public onlyBank {
        _bank = bank;
    }

    function setManagerCollection(address managerCollection) public onlyBank {
        _managerCollection = managerCollection;
    }

    function setInitialAmount(uint128 initialAmount) public onlyBank {
        _initialAmount = initialAmount;
    }

    function setAccountCode(TvmCell accountCode) public onlyBank {
        _accountCode = accountCode;
    }

    function retailAccountAddress(optional(uint128) pubkey, optional(address) owner) external view virtual responsible returns (address retailAccount) {
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
