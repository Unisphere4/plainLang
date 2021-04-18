// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DEX is Ownable
{
    uint256 public exchange_rate;                     // Ratio of ETH/PLAIN    
    
    address theOwner;

    event Bought(uint256 amount);
    event Sold(uint256 amount);
    IERC20 public token;    // = new PLAINToken(); // This is used when token is being deployed. Token already deployed.

    constructor(address _token, uint256 _exchange_rate) 
    {
        token = IERC20(_token);
        exchange_rate = _exchange_rate;
        theOwner = address(msg.sender);
    }

    function buy() 
        payable 
        public 
    {
        uint256 amountTobuy = msg.value*exchange_rate;
        uint256 PLAINBalance = token.balanceOf(address(this));
        uint256 transferredTokens;

        require(amountTobuy > 0, "You need to send some Ether");
        require(amountTobuy <= PLAINBalance, "Not enough tokens in the reserve");
        
        token.transfer(msg.sender, amountTobuy);
        transferredTokens = token.totalSupply() - token.balanceOf(address(this));
        
        if ((transferredTokens/32320000000000000000000) <= 2700)
        {
            exchange_rate = 2700 - (transferredTokens/32320000000000000000000);
        }
        else
        {
            exchange_rate = 70;
        }
        emit Bought(amountTobuy);
    }
    
    function setExchangeRate(uint new_rate) public onlyOwner
    {
        exchange_rate = new_rate;
    }

    function transferFees (uint256 amount) public onlyOwner
    {
        if (amount == 0)
        {
            payable(msg.sender).transfer(address(this).balance);
        }
        else if (amount > 0)
        {
            require(amount <= address(this).balance);
            payable(msg.sender).transfer(amount);
        }
    }
}