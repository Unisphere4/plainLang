pragma solidity ^0.6.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; 
import "@openzeppelin/contracts/access/Ownable.sol";

// contract PriceConsumerV3 {}
//  Will deploy price feed contract first. As a result, we need to stub functions from contract
// Include priceConsumerV3 interface
// Include appropriate events

contract plainLang is Ownable 
{
    // State variable
    address PLAIN_token=0x0;            // The token used for fees. Need to deploy and then insert initial address.
                                        //  address can be updated using updatePlain() 
    int PLAIN_fee = 1 * PLAIN;          // Initial fee for using plainLang
    address PC_addr=0x0;                // Address of the PriceConsumerV3 contract    

    // Tokens permitted for staking, premiums, and payouts. Future iteration, all 3 can be different.             
    mapping(address => bool) public agreement_tokens;  // Default for each value is 0, so 

    // Primary transaction struct on which all business is conducted
    struct Agreement 
    {
        address originator;         // Party creating the agreement
        address counterparty;       // Party accepting agreement

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
    
    Agreement[] agreements; // Each element in the array is an agreement. Starting with agreement 0

    //uint8 premiumCost = 5;                      // Percentage, starting with 5% in this contract. Allowing originator to specify
    uint256 fee = 1 * 10 ** 18;                 // 1 LINK, # of tokens to pay fee
    //address feeToken = PLAIN_KOVAN;           // Token used to pay fees
    
    // Private variables
    uint256 private agreements_counter;     // Keeps track of how many agreements have been created
                                            // Starts with agreement #0 and increments by 1 for every 
                                            // agreement created by the plainLang contract
    // Private constants
    address private constant LINK_MAINNLINKET = 0x514910771af9ca656af840dff83e8264ecf986ca;
    address private constant LINK_KOVAN = 0xa36085F69e2889c224210F603D836748e7dC0088;
    address private constant PLAIN_KOVAN = 0x0;
    address private constant PRICE_CONTRACT = 0x0;  // Fill in price contract address after deploying

    uint256 private constant PLAIN = 10**18;        

    uint private constant DAY = 24*60*60;   // One day in seconds. Used because contract and Ethereum use Epoch time

    constructor() public 
    {        
        //token = LINK_KOVAN;
        agreements_counter = 0;
        agreement_tokens[LINK_KOVAN]=true;  // Start with LINK
    }

    // createAgreement allows any address to create an agreement
    // Only whole numbers of tokens may be staked
    // Staked tokens are held until the agreement is closed, at which time the staked tokens are
    // first used to pay the counter_party, if required, and the remainder are returned to staker. 
    function createAgreement(uint256 number_staked, uint256 _premium, uint days) 
        public 
    {
        Agreement private current_agreement;
        
        // Need to first get staked tokens from originator
        // Correct tokens, proceed
        PriceConsumerV3 getPrice = PriceConsumerV3(PRICE_CONTRACT);

        // Verify agreement and stake before making any changes to state
        IERC20(token).transferFrom(msg.sender, address(this), number_staked + fee); // Reverts due to SafeMath subtraction if allowance is insufficient

        // Create Agreement and fill in struct variable
        current_agreement.originator = msg.sender;
        current_agreement.price_at_agreement = getPrice.getLINKPrice();
        current_agreement.agreement_date = setAgreementDate();
        current_agreement.close_date = now + (DAY*days);
        current_agreement.multiplier = number_staked;
        current_agreement.amount_staked = number_staked;
        current_agreement.premium = _premium;   // Premium in wei
        // (1 * 10 ** 18) * multiplier / 20;    // premium, measured in tokens = 5% of staked amount
        current_agreement.closed = false;

        getPLAINFee(msg.sender);

        agreements.push(current_agreement);     // Add current agreement to array of agreements
        agreements_counter += 1;                // Increment the agreement counter for next agreement
    }

    // getPLAINFee transfers the PLAIN token fee from the originator to the contract
    function getPLAINFee(address payor) 
        private 
        returns bool 
    {
        IERC20(PLAIN_token).transferFrom(payor, address(this), fee);
    }

    // Receive premium from the counterparty
    function acceptPremium(uint256 agreement_number) 
        private 
    {
        // Verify the agreement before saving to array of Agreements
        //  First, agreement must not be closed
        require(agreements[agreement_number].closed == false, "Agreement has already closed");

        // Second, can't have a counter party yet
        require(agreements[agreement_number].counter_party == 0, "Agreement already has counter party"); 

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
        IERC20(agreements[agreement_number].token).transferFrom(agreements[agreement_number].counter_party, address(this), agreements[agreement_number].premium); // Reverts due to SafeMath subtraction if allowance is insufficient
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

        if (agreements[agreement_number].counterparty == 0) {
            // Sendvvvvv back stake
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
        PLAIN_token = plain;                // New address of the PLAIN token. Allows upgrade of the token without breaking PlainLang
    }

    function upgradePriceConsumer(address pc)
        public
        onlyOwner
    {
        PC_addr = pc;                       // New address of the priceConsumer contract, used to get price of tokens used in agreement.
    }
    // getDate simply returns the current date in ???? format. Because of the expense of calling Chainlink API, may want to use a different method for getting date.
    // getDate is only called when attempting to close agreement. Make agreementClosed the callback function. Then the agreement can't close until the callback function is called.
    // Or use "now", which is the current block timestamp as seconds since unix epoch
    // .: 30 days = 30*24*60*60 = 2592000
    /*function getDate() 
        private 
        returns(uint256)
    {
        uint256 filedate;       // Number of 1/10 microseconds since Jan. 1, 1601
        
        // Call Chainlink to get date
        filedate = 
        return filedate;
    }*/
}