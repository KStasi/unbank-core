pragma ever-solidity >= 0.61.2;

pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "@broxus/contracts/contracts/access/InternalOwner.tsol";
import "@broxus/contracts/contracts/utils/RandomNonce.tsol";
import "tip3/contracts/interfaces/ITokenRoot.sol";
import "tip3/contracts/interfaces/ITokenWallet.sol";
import "./ErrorCodes.sol";
import "./interfaces/IBank.sol";
import "./BaseCard.sol";

contract SavingCard is BaseCard {
    uint128 public targetAmount = 0;
    uint128 public cachedBalance = 0;
    uint128 public cacheTimestamp = 0;
    uint128 public cacheValidity = 30 minutes;

    constructor(TvmCell _cardDetails, uint128 _targetAmount) BaseCard(_cardDetails) public {
        cardType = CardType.SAVINGS;

        TvmSlice cardDetails = _cardDetails.toSlice();
        (address _currency, address _owner, address _bank, uint128 _targetAmount) = cardDetails.decode(address, address, address, uint128);

        targetAmount = _targetAmount;
    }

    // TODO: withdraw

    function setTargetAmount(
        uint128 _targetAmount
    )
        public
        onlyBank
    {
        tvm.accept();
        targetAmount = _targetAmount;
    }

    function updateCachedBalance(
        uint128 _dailyLimit,
        uint128 _monthlyLimit
    )
        public
        view
        onlyOwner
    {
        ITokenWallet(wallet).balance{callback: SavingCard.onBalanceUpdate}();
    }

    function onBalanceUpdate(
        uint128 _balance
    )
        public
        onlyWallet
    {
        cachedBalance = _balance;
        cacheTimestamp = now;
    }

    // INTERNAL

    function _validateTransfer(
        uint128 _amount,
        TvmCell _payload)
        internal
        override
    {
        BaseCard._validateTransfer(_amount, _payload);
        // TODO: should we ensure that the receiver is another card or just spend?
        require(now - cacheTimestamp <= cacheValidity, ErrorCodes.CACHE_TIMESTAMP_TOO_OLD);
        require(cachedBalance >= targetAmount, ErrorCodes.GOAL_NOT_REACHED);
    }
}
