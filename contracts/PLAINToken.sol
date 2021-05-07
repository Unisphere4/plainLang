// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PLAINToken is IERC20 
{
    string public constant NAME = "PLAINToken";
    string public constant SYMBOL = "PLAIN";
    uint8 public constant DECIMALS = 18;

    mapping(address => uint256) public balances;

    mapping(address => mapping (address => uint256)) allowed;

    uint256 public totalSupply_ = 100000000 * (10**DECIMALS); 

   constructor() 
    {
        balances[msg.sender] = totalSupply_;
    }

    function name() 
        public
        pure 
        returns (string memory)
    {
        return NAME;
    }
    
    function symbol() 
        public
        pure 
        returns (string memory)
    {
        return SYMBOL;
    }
    
    function decimals() 
        public 
        pure 
        returns (uint8)
    {
        return DECIMALS;
    }
    
    function totalSupply() 
        public 
        view 
        override
        returns (uint256) 
    {
        return totalSupply_;
    }

    function balanceOf(address tokenOwner) 
        public 
        view 
        override
        returns (uint256) 
    {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens) 
        public  
        override
        returns (bool) 
    {
        require(numTokens <= balances[msg.sender], "Cannot transfer more tokens than sender owns");
        balances[msg.sender] = balances[msg.sender] - (numTokens);
        balances[receiver] = balances[receiver] + numTokens;
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint256 numTokens) 
        public 
        override
        returns (bool) 
    {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) 
        public 
        view 
        override
        returns (uint) 
    {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) 
        public 
        override
        returns (bool) 
    {
        require(numTokens <= balances[owner], "Can't transfer more tokens than the owner owns");
        require(numTokens <= allowed[owner][msg.sender], "Can't transfer more tokens than permitted by owner");

        balances[owner] = balances[owner] - (numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender] - numTokens;
        balances[buyer] = balances[buyer] + (numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
}