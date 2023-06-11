pragma ever-solidity >= 0.61.2;

interface IBaseCard {
    function updateCrusialParams() external;

    function transferToBank(uint128 amount, TvmCell payload) external;

    function setCardActivation(bool isActive) external;

    function onBankWalletAddressUpdated(address wallet) external;

    function onAcceptTokensMint(address wallet) external;

    function onAcceptTokensBurn(address wallet) external;

    function onAcceptTokensTransfer(address tokenRoot, uint128 amount, address sender, address senderWallet, address remainingGasTo, TvmCell payload) external;

    function onWalletCreated(address wallet) external;

    function transferToWallet(uint128 amount, address recipientTokenWallet, address remainingGasTo, bool notify, TvmCell payload) external;

    function transfer(uint128 amount, address recipient, uint128 deployWalletValue, address remainingGasTo, bool notify, TvmCell payload) external;
}
