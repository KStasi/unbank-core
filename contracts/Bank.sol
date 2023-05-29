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
    mapping(address => bool) public supportedCbdc;
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

    function updateSupportedCbdc(
        SuportCbdcParams[] cbdcDetails
    )
        public
        override
        onlyOwner
    {
        tvm.accept();

        for (SuportCbdcParams cbdcDetail : cbdcDetails) {
            if (supportedCbdc.exists(cbdcDetail.cbdc)) {
                supportedCbdc.replace(cbdcDetail.cbdc, cbdcDetail.isActive);
                // TODO: consider mechanics to remove support of CBDC. How to ensure,
                // it still will be withdrawable or accessable?
            } else {
                supportedCbdc.add(cbdcDetail.cbdc, cbdcDetail.isActive);
            }
        }

    }
}
