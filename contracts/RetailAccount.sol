pragma ever-solidity >= 0.61.2;

pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "@broxus/contracts/contracts/access/ExternalOwner.tsol";
import "@broxus/contracts/contracts/utils/RandomNonce.tsol";
import "@broxus/contracts/contracts/utils/CheckPubKey.tsol";
import "./ErrorCodes.sol";

contract RetailAccount is
    ExternalOwner,
    RandomNonce,
    CheckPubKey {

    uint8 constant MAX_CARDS_COUNT = 3;
    mapping(address => bool) public cards;
    bool public isBlocked;

    modifier onlyRegularManager() {
        require(msg.pubkey() == owner, ErrorCodes.NOT_REGULAR_MANAGER);
        _;
    }

    constructor() public checkPubKey {
        tvm.accept();

        setOwnership(msg.pubkey());
    }

    // TODO: add card
    function addCurrencySupport(
        address currency
    )
        public
        view
        onlyRegularManager
    {
        tvm.accept();
    }

    // TODO: deactivate card

    // TODO: configure spending limit

    // TODO: add deposit
    // TODO: add withdrawal

    // TODO: add transfer to bank
    // TODO: remove transfer to bank

    // TODO: configure withdrawal limit

    // TODO: create savings with goal; w/ managers stop
    // TODO: create savings with time; w/ managers stop

    // TODO: create autopayments
    // TODO: cancel autopayments

    // TODO: block account
    // TODO: emergency withdrawal

    /*
        @notice Send transaction to another contract
        @param dest Destination address
        @param value Amount of attached TONs
        @param bounce Message bounce
        @param flags Message flags
        @param payload Tvm cell encoded payload, such as method call
    */
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

        // For VENOM transfers

        // For token transfers

        dest.transfer(value, bounce, flags, payload);
    }
}
