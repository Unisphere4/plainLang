pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; 
import "@openzeppelin/contracts/access/Ownable.sol";

// contract PriceConsumerV3 {}
//  Will deploy price feed contract first. As a result, we need to stub functions from contract
// Include priceConsumerV3 interface
// Include appropriate events
// Place in another .sol and import
contract PriceConsumerV3
{
    function getTokenPrice(address token) public view returns (int);
    function oracleAvailable (address token) private returns(bool);
    function addOracle (address token) public OnlyOwner;
    function delOracle (address token) public OnlyOwner;
}

contract plainLang is Ownable 
{
    // VARIABLES
    // Public state variables
    uint256 public fee = 1 * 10 ** 18;      // Initial fee of 1 LINK (# of tokens to pay fee)
    // Tokens permitted for staking, premiums, and payouts. Future iteration, all 3 can be different.             
    mapping(address => bool) public agreement_tokens;  // Default for each value is false 

    //Private state variables
    int PLAIN_fee = 1 * PLAIN;          // Initial fee for using plainLang
    address priceConsumer=0x0;                // Address of the PriceConsumerV3 contract    
    Agreement[] agreements; // Each element in the array is an agreement. Starting with agreement 0
    address private priceContract;          // Fill in initial price contract address after deploying
    address private plainToken;             // PLAIN token address
       
    // Private constants
    address private constant LINK_MAINNETLINK = 0x514910771af9ca656af840dff83e8264ecf986ca;
    address private constant LINK_RINKEBY = 0xa36085F69e2889c224210F603D836748e7dC0088;
    uint256 private constant PLAIN = 10**18;        
    uint private constant DAY = 24*60*60;   // One day in seconds. Used because contract and Ethereum use Epoch time

    // Primary transaction struct on which all business is conducted
    struct Agreement 
    {
        address originator;         // Party creating the agreement
        address counterparty;       // Party accepting agreement
        address requiredParty;      // If this agreement is intended for only a specified counter-party, this is their address. Otherwise, 0x0

        address token;              // Token being transacted upon
        
        uint agreement_date;        // Will be set when the originator creates the agreement
        uint close_date;            // Date when the agreement is closed and either party may trigger closeAgreement 

        int price_at_agreement;     // Price when agreement is created by originator
        uint256 multiplier;         // Multiplier against price difference. In this version, multiplier = amount_staked

        uint256 premium;            // Premium for agreement to cover losses
        uint256 payment;
        uint256 amount_staked;      // Number of tokens staked by counter_party
        bool closed;                // True if agreement has already been closed. Default=false, which is correct.
    }

    // EVENTS
    event AgreementCreated(uint256 agreementNumber, address originator, address token, uint close_date, uint price_at_agreemnet, 
                            uint256 int multiplier, uint256 premium, uint256 amountStaked);
    event CounterpartyAccepted(uint256 agreementNumber, address counterparty);

    // Constructor takes addresses of PLAIN contract and PriceConsumerV3 as arguments
    constructor(address _plainToken, address _priceContract) 
        public 
    {        
        //token = LINK_RINKEBY;
        agreement_tokens[LINK_RINKEBY]=true;  // Start with LINK

        plainToken = _plainToken;
        priceContract = _priceContract;
    }

    // createAgreement allows any address to create an agreement
    // Only whole numbers of tokens may be staked
    // Staked tokens are held until the agreement is closed, at which time the staked tokens are
    // first used to pay the counter_party, if required, and the remainder are returned to staker. 
    function createAgreement(uint256 _amount_staked, uint256 _premium, uint days, address _requiredParty) 
        public 
    {
        Agreement private current_agreement;
        
        // Need to first get staked tokens from originator
        // Correct tokens, proceed
        PriceConsumerV3 getPrice = PriceConsumerV3(PRICE_CONTRACT);

        // Verify agreement and stake before making any changes to state
        IERC20(token).transferFrom(msg.sender, address(this), number_staked + fee); // Reverts due to SafeMath subtraction if allowance is insufficient

        // Create Agreement and fill in struct variable
        // Verify the agreement before saving to array of Agreements below
        current_agreement.price_at_agreement = getPrice.getLINKPrice(); // Set first because originator's intent is to use current price
        current_agreement.agreement_date = setAgreementDate();          // Set second because the same
        current_agreement.originator = msg.sender;
        current_agreement.requiredParty = _requiredParty;
        current_agreement.counterparty = address(0x0);
        current_agreement.close_date = now + (DAY*days);
        current_agreement.multiplier = number_staked;
        current_agreement.amount_staked = _amount_staked;
        current_agreement.premium = _premium;                           // Premium in wei
        current_agreement.closed = false;                               // Set to true when agreement date has passed and party calls closeAgreement()

        getPLAINFee(msg.sender);

        agreements.push(current_agreement);     // Add current agreement to array of agreements
    }

    // getPLAINFee transfers the PLAIN token fee from the originator to the contract
    function getPLAINFee(address payor) 
        private 
        returns bool 
    {
        IERC20(plainToken).transferFrom(payor, address(this), fee);
    }

    // Receive premium from the counterparty
    function acceptPremium(uint256 agreement_number) 
        private 
    {
        //  First, agreement must not be closed
        require(agreements[agreement_number].closed == false, "Agreement has already closed");

        // Second, can't have a counter-party yet
        require(agreements[agreement_number].counter_party == address(0x0), "Agreement already has counter party"); 

        if (agreements[agreement_number].requiredParty != address(0x0))
        {
            require(agreements[agreement_number].requiredParty==address(msg.sender), "This agreement has a required counterparty");
        }

        transferPremium(agreement_number);  // Get premium from counter party
        
        // After agreement verified and premium received, memorialize agreement
        agreements[agreement_number].counter_party = msg.sender;
    }

    // Use Chainlink API to query date and set date of agreement
    function setAgreementDate(uint256 agreement_number) 
        private 
    {
        agreements[agreement_number].agreement_date = block.timestamp;          // Agreement date is set to current block timestamp 
    }

    // Transfer premium to originator after contract ensures that correct amount transferred to 
    //      contract and agreement date set
    function transferPremium(uint256 agreement_number) 
        private 
    {
        //Transfer premium tokens into the contract to be transferred to originator when agreement is finalized
        // Emits a "Transfer" event. May not be needed
        IERC20(agreements[agreement_number].token).transferFrom(agreements[agreement_number].counter_party, agreements[agreement_number].originator, agreements[agreement_number].premium); // Reverts due to SafeMath subtraction if allowance is insufficient
    }

    // Called by either originator or counter_party.
    // Evaluates whether current date is after end_date. If so:
    //      If value of token on contract_date > value of token on date agreement is closed--
    //          Transfer [(value of token on contract date)-(value of token on close date)]*multiplier
    function closeAgreement(uint256 agreement_number) 
        public 
    {
        uint256 payment; // Amount of payment to counterparty
        
        require(msg.sender == agreements[agreement_number].originator || msg.sender == agreements[agreement_number].counter_party, "Agreement can only be closed by the agreement originator or counter party");

        if (agreements[agreement_number].counterparty == address(0x0)) 
        {
            // Send back stake, if any remains
            IERC20(token).transfer(address(this), agreements[agreement_number].originator, agreements[agreement_number].amount_staked); // Reverts due to SafeMath subtraction if allowance is insufficient
            agreements[agreement_number].amount_staked = 0;
            agreements[agreement_number].closed = true;
        }
        
        if (agreementClosed(agreement_number)) {
            agreements[agreement_number].payment = calculatePayment();
            if (payment > 0) {
                makePayment(agreement_number);
        }
    
        agreements[agreement_number].closed = true;         // Close the agreement. Can't be resurrected
    }

    // Calculate the number of tokens (may be fractional) to be transferred to counterparty
    function calculatePayment(uint256 agreement_number)
        private 
        returns(uint256) // Returns amount of payment  
    {
        // Call Chainlink oracle to get the current price
        PriceConsumerV3 p = PriceConsumerV3(PC_addr);
        uint256 current_price;
        uint256 payment;
        
        current_price = p.getTokenPrice(agreements[agreement_number].token);
        if (current_price >= agreements[agreement_number])
        {
            payment = 0;
        }
        else
        {
            payment = (current_price - agreements[agreement_number].price_at_agreement)*agreements[agreement_number].multiplier;
        }

        return payment;
    }

    // Send calculated payment to counterparty
    function makePayment (uint256 agreement_number)
        private 
    {
        IERC20(agreements[agreement_number].token).transfer(address(this), agreements[agreement_number].originator, agreements[agreement_number].payment);
    }

    // agreementClosed Changes agreemend to "closed" and returns true if the current date is on or after the closte_date
    function agreementClosed(uint256 agreement_number) 
        private 
        returns(bool)
    {
        require(now >= close_date, "Agreement is not yet closed. Try again later.");    // Unix Epoch time
        agreement[agreement_number].closed = true;                                      // Agreement is closed
        return true;
    }

    // transferFees() transfers accumulated fees to the contract's owner
    // Because fees are being paid in PLAIN. No need to transfer fees to owner. Could transfer them back to the token store, however, so they can be re-sold
    /*function transferFees () 
        public 
        onlyOwner
    {
        
    }*/

    function setFee(uint256 _PLAIN_fee)
        public
        onlyOwner
    {
        PLAIN_fee = _PLAIN_fee;
    }

    function addToken(address token) 
        public
        onlyOwner
    {
        agreement_tokens[token]=true;
    }

    function removeToken(address token)
        public
        onlyOwner
    {
        agreement_tokens[token]=false;
    }

    function upgradePLAIN(address plain)
        public
        onlyOwner
    {
        plainToken = plain;                // New address of the PLAIN token. Allows upgrade of the token without breaking PlainLang
    }

    function upgradePriceConsumer(address pc)
        public
        onlyOwner
    {
        PC_addr = pc;                       // New address of the priceConsumer contract, used to get price of tokens used in agreement.
    }
}