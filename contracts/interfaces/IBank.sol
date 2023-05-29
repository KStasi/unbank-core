pragma ton-solidity >= 0.61.2;

interface IBank {

    struct SuportCbdcParams {
      address cbdc;
      bool isActive;
    }

    struct CbdcInfo {
      bool isActive;
      uint128 defaultDailyLimit;
      uint128 defaultMonthlyLimit;
    }

    function updateSupportedCbdc(mapping(address => CbdcInfo) supportedCbdc) external;

    function getWalletAddress(address currency) external responsible view returns (address);

    function getDefaultSpending(address currency) external responsible view returns (address, uint128, uint128);
}