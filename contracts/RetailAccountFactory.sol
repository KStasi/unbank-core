pragma ever-solidity >= 0.61.2;

pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "@broxus/contracts/contracts/access/ExternalOwner.tsol";
import "@broxus/contracts/contracts/utils/RandomNonce.tsol";
import "@broxus/contracts/contracts/utils/CheckPubKey.tsol";
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

    function deployRetailAccount(uint128 pubkey) public onlyManagerCollection returns (address) {
        address newRetailAccount = new RetailAccount{
            value: _initialAmount,
            flag: 0,
            pubkey: pubkey,
            code: _accountCode
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
}
