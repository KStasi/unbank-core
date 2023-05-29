pragma ton-solidity >= 0.61.2;

interface IBank {

    struct SuportCbdcParams {
      address cbdc;
      bool isActive;
    }

    function updateSupportedCbdc(SuportCbdcParams[] cbdcDetails) external;

    function getWalletAddress(address currency) external responsible view returns (address);
}