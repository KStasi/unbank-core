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
    uint128 public _targetAmount = 0;
    uint128 public _cachedBalance = 0;
    uint128 public _cacheTimestamp = 0;
    uint128 public _cacheValidity = 30 minutes;

    constructor(TvmCell cardDetails) BaseCard(cardDetails) public {
        tvm.accept();

        TvmSlice cardDetailsSlice = cardDetails.toSlice();
        (uint128 targetAmount) = cardDetailsSlice.decode(uint128);

        _targetAmount = targetAmount;
    }

    // TODO: withdraw

    function setTargetAmount(
        uint128 targetAmount
    )
        public
        onlyBank
    {
        tvm.accept();
        _targetAmount = targetAmount;
    }

    function updateCachedBalance()
        public
        view
        onlyOwner
    {
        ITokenWallet(_wallet).balance{callback: SavingCard.onBalanceUpdate}();
    }

    function onBalanceUpdate(
        uint128 balance
    )
        public
        onlyWallet
    {
        _cachedBalance = balance;
        _cacheTimestamp = now;
    }

    // INTERNAL

    function _validateTransfer(
        uint128 amount,
        TvmCell payload)
        internal
        override
    {
        BaseCard._validateTransfer(amount, payload);
        // TODO: should we ensure that the receiver is another card or just spend?
        require(now - _cacheTimestamp <= _cacheValidity, ErrorCodes.CACHE_TIMESTAMP_TOO_OLD);
        require(_cachedBalance >= _targetAmount, ErrorCodes.GOAL_NOT_REACHED);
    }
}
