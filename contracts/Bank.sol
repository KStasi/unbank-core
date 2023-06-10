pragma ever-solidity >= 0.61.2;

pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "@broxus/contracts/contracts/access/InternalOwner.tsol";
import "@broxus/contracts/contracts/utils/RandomNonce.tsol";
import "@broxus/contracts/contracts/utils/CheckPubKey.tsol";
import "tip3/contracts/interfaces/ITokenRoot.sol";
import "tip3/contracts/interfaces/ITokenWallet.sol";
import 'tip3/contracts/libraries/TokenMsgFlag.sol';
import "./interfaces/IBank.sol";
import "./ErrorCodes.sol";


contract Bank is
    InternalOwner,
    RandomNonce,
    IBank {

    uint8 constant MAX_CBDC_COUNT = 10;
    mapping(address => CbdcInfo) public _supportedCbdc;
    mapping(address => address) public _walletAddresses; // currency => wallet
    address public _chiefManagerCollection;
    uint128 public _defaultDeployWalletValue = 0.4 ton;
    uint128 public _defaultDeployWalletExecutionValue = 0.1 ton;

    modifier onlyChiefManagerCollection() {
        require(msg.sender == _chiefManagerCollection, ErrorCodes.NOT_CHIEF_MANAGER_COLLECTION);
        _;
    }

    constructor(address owner, address chiefManagerCollection, mapping(address => CbdcInfo) cbdcDetails) public {
        tvm.accept();
        _chiefManagerCollection = chiefManagerCollection;
        setOwnership(owner);

        for ((address cbdcAddress, CbdcInfo cbdcInfo) : cbdcDetails) {
           _updateSupportedCbdc(cbdcAddress, cbdcInfo);
           _addWallet(cbdcAddress, _defaultDeployWalletValue);
        }
    }

    function addWallet(address currencyRoot, uint128 deployWalletValue) public onlyOwner {
        tvm.accept();
        _addWallet(currencyRoot, deployWalletValue);
    }

    function onWalletCreated(
        address wallet
    )
        public
    {
        require(!_walletAddresses.exists(msg.sender), ErrorCodes.WALLET_ALREADY_CREATED);
        tvm.accept();
        _walletAddresses[msg.sender] = wallet;
    }

    function getWalletAddress(address currency) override external responsible view returns (address) {
        return{value: 0, bounce: false, flag: 64} _walletAddresses.at(currency);
    }

    function getDefaultSpending(address currency) override external responsible view returns (address, uint128, uint128) {
        CbdcInfo cbdcInfo = _supportedCbdc.at(currency);
        return{value: 0, bounce: false, flag: 64} (currency, cbdcInfo.defaultDailyLimit , cbdcInfo.defaultMonthlyLimit);
    }

    function updateSupportedCbdc(
        mapping(address => CbdcInfo) cbdcDetails
    )
        public
        override
        onlyOwner
    {
        tvm.accept();

        for ((address cbdcAddress, CbdcInfo cbdcInfo) : cbdcDetails) {
           _updateSupportedCbdc(cbdcAddress, cbdcInfo);
        }
    }

    // TODO: add logic on receiving currencies

    function transferToCard(
        address currency,
        uint128 amount,
        address cardAddress,
        uint128 deployWalletValue,
        address remainingGasTo,
        bool notify,
        TvmCell payload
    )
        public
        view
        onlyChiefManagerCollection
    {
        require(_walletAddresses.exists(currency), ErrorCodes.CBDC_NOT_SUPPORTED);
        tvm.accept();

        address wallet = _walletAddresses.at(currency);

        ITokenWallet(wallet).transfer(
            amount,
            cardAddress,
            deployWalletValue,
            remainingGasTo,
            notify,
            payload);

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
        dest.transfer(value, bounce, flags, payload);
    }

    function _addWallet(address currencyRoot, uint128 deployWalletValue) internal {
        require(!_walletAddresses.exists(currencyRoot), ErrorCodes.WALLET_ALREADY_CREATED);
        ITokenRoot root = ITokenRoot(currencyRoot);
        root.deployWallet{callback: onWalletCreated, value: deployWalletValue+_defaultDeployWalletExecutionValue, flag: TokenMsgFlag.SENDER_PAYS_FEES}(
            address(this),
            deployWalletValue
        );
    }

    function _updateSupportedCbdc(address cbdcAddress, CbdcInfo cbdcInfo) internal {
        if (_supportedCbdc.exists(cbdcAddress)) {
            _supportedCbdc.replace(cbdcAddress, cbdcInfo);
        } else {
            _supportedCbdc.add(cbdcAddress, cbdcInfo);
        }
    }

}
