// Convert to get the price from any Chainlink price feed
// oracle address for a token will be 0x0 if the feed has not been added to the contract
pragma solidity ^0.6.7;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PriceConsumerV3 {
    AggregatorV3Interface internal priceFeed;
    
    address private constant LINK_KOVAN = 0xa36085F69e2889c224210F603D836748e7dC0088;
    address private constant LINK_KOVAN_ORACLE = 0x2c1d072e956AFFC0D435Cb7AC38EF18d24d9127c;
    
    /**
     * Network:     Kovan
     * Aggregator:  LINK/USD
     * Decimals:    8
     * Address:     0x2c1d072e956AFFC0D435Cb7AC38EF18d24d9127c
     */
    
    /*struct Oracle                 // Originally intended to allow tokens with > or M 18 decimals to be used. Instead, mandate that only 18 decimlal tokens be used
    {
        address oracle_address;
        uint8 decimal;              // Decimals used by token
    }*/

    mapping(address => address) private oracle_addresses;       // Map addresses of tokens to Chainlink oracle addresses

    constructor() public {
        //priceFeed = AggregatorV3Interface(oracle);
        oracle_address[LINK_KOVAN] = LINK_KOVAN_ORACLE;      
        //oracle_address[DAI_RINKEBY] = DAI_RINKEBY_ORACLE; // Need to change all Kovan addresses to Rinkeby, since we're planning on using Compound protocol
    }

    /**
     * Returns the latest price
     */
    function getTokenPrice(address token) public view returns (int) 
    {
        if (!oracleAvailable(token))
        {
            return 0;
        }

        require(ERC20(token).decimals() == 18, "Only ERC20 tokens with 18 decimals may be used"); // Going to have to use old version of IERC20 since Chainlink is 0.6.7
        oracle = oracle_address[token];
        priceFeed = AggregatorV3Interface(oracle);
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }

    // oracleAvailable returns 'true' if the token's oracle has been added to the mapping. 'false' if not.
    function oracleAvailable (address token) 
        private 
        returns(bool)
    {
        if (oracle_addresses[token] == 0x0)
        {
            return false;
        }
        else if (oracle_addresses[token] != 0x0)
        {
            return true;
        }
    }

    function addOracle (address token)
        public
        OnlyOwner
    {
        oracle_addresses[token] == true;
    }

    function delOracle (address token)
        public
        OnlyOwner
    {
        oracle_addresses[token] == false;
    }
}