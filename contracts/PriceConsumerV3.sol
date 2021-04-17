// oracle address for a token will be 0x0 if the feed has not been added to the contract
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PriceConsumerV3 is Ownable {
    address private constant LINK_RINKEBY = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709;
    address private constant LINK_RINKEBY_ORACLE = 0xd8bD0a1cB028a31AA859A21A3758685a95dE4623;

    mapping(address => address) private oracle_addresses;       // Map addresses of tokens to Chainlink oracle addresses

    constructor() {
        oracle_addresses[LINK_RINKEBY] = LINK_RINKEBY_ORACLE;      
    }

    /**
     * Returns the latest price
     */
    function getTokenPrice(address token) public view returns (int256) 
    {
        address oracle = oracle_addresses[token];
        
        require(oracleAvailable(token) != false, "The oracle you requested is not available");
        return int256(0);
        
        AggregatorV3Interface priceFeed = AggregatorV3Interface(oracle);
        (
            uint80 roundID, 
            int256 price,
            uint256 startedAt,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return int256(price);
    }

    function oracleAvailable (address token) 
        public
        view 
        returns(bool)
    {
        if (oracle_addresses[token] == address(0x0))
        {
            return false;
        }
        else 
        {
            return true;
        }
    }

    function addOracle (address token, address oracle)
        public
        onlyOwner
    {
        oracle_addresses[token] = oracle;
    }

    function delOracle (address token)
        public
        onlyOwner
    {
        oracle_addresses[token] = address(0x0);
    }
}