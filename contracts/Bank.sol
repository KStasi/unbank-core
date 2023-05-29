pragma ever-solidity >= 0.61.2;

pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "@broxus/contracts/contracts/access/InternalOwner.tsol";
import "@broxus/contracts/contracts/utils/RandomNonce.tsol";
import "@broxus/contracts/contracts/utils/CheckPubKey.tsol";
import "./interfaces/IBank.sol";

contract Bank is
    InternalOwner,
    RandomNonce,
    IBank {

    uint8 constant MAX_CBDC_COUNT = 10;
    mapping(address => CbdcInfo) public supportedCbdc;
    mapping(address => address) public walletAddresses; // currency => wallet

    constructor(address owner) public {
        tvm.accept();
        setOwnership(owner);
    }

    // TODO: deploy wallet
    // TODO: request transfers from wallet to bank
    // TODO: request transfers back from bank to wallet

    function getWalletAddress(address currency) override external responsible view returns (address) {
        return{value: 0, bounce: false, flag: 64} walletAddresses.at(currency);
    }

    function getDefaultSpending(address currency) override external responsible view returns (address, uint128, uint128) {
        CbdcInfo cbdcInfo = supportedCbdc.at(currency);
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
            if (supportedCbdc.exists(cbdcAddress)) {
                supportedCbdc.replace(cbdcAddress, cbdcInfo);
                // TODO: consider mechanics to remove support of CBDC. How to ensure,
                // it still will be withdrawable or accessable?
            } else {
                supportedCbdc.add(cbdcAddress, cbdcInfo);
            }
        }

    }

}
