pragma ever-solidity >= 0.61.2;

pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "@broxus/contracts/contracts/access/InternalOwner.tsol";
import "@broxus/contracts/contracts/utils/RandomNonce.tsol";
import "@broxus/contracts/contracts/utils/CheckPubKey.tsol";
import "tip3/contracts/interfaces/ITokenRoot.sol";
import "./interfaces/IBank.sol";
import "./ErrorCodes.sol";

contract Bank is
    InternalOwner,
    RandomNonce,
    IBank {

    uint8 constant MAX_CBDC_COUNT = 10;
    mapping(address => CbdcInfo) public _supportedCbdc;
    mapping(address => address) public _walletAddresses; // currency => wallet

    constructor(address owner) public {
        tvm.accept();
        setOwnership(owner);
    }

    // TODO: request transfers from wallet to bank
    // TODO: request transfers back from bank to wallet

    function addWallet(address currencyRoot, uint128 deployWalletValue) public onlyOwner {
        require(!_walletAddresses.exists(currencyRoot), ErrorCodes.WALLET_ALREADY_CREATED);
        tvm.accept();
        ITokenRoot root = ITokenRoot(currencyRoot);
        root.deployWallet{callback: onWalletCreated}(
            address(this),
            deployWalletValue
        );
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
            if (_supportedCbdc.exists(cbdcAddress)) {
                _supportedCbdc.replace(cbdcAddress, cbdcInfo);
                // TODO: consider mechanics to remove support of CBDC. How to ensure,
                // it still will be withdrawable or accessable?
            } else {
                _supportedCbdc.add(cbdcAddress, cbdcInfo);
            }
        }

    }

}
