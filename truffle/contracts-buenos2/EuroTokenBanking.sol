pragma solidity ^0.4.17;

import "./Owned.sol";
import "./EuroToken.sol";
import "./SafeMath.sol";

/// @title An EuroToken administrator. 
/// @author Elias Torvisco
/// @notice This contract allows users to cash in money to get euro tokens.
/// @dev All function calls are currently implement without side effects
contract EuroTokenBanking  is Owned {

    using SafeMath for uint;

    event CashIn(address indexed receiver, uint256 amount);
    event CashOut(address indexed receiver, uint256 amount, string bankAccount);

    EuroToken public euroToken;
    

    function EuroTokenBanking() public {
        euroToken = new EuroToken();
    }

    /// @param to The address to which tokens will be given
    /// @param tokens The number of tokens to deposit
    /// @dev Only the owner of the contract can call this function
    function cashIn(address to, uint tokens) public onlyOwner {
        euroToken.setBalance(to, euroToken.balanceOf(to).add(tokens));
        euroToken.setTotalSupply(euroToken.totalSupply().add(tokens));
        CashIn(to, tokens);
        
    }

    /// @param tokens The number of tokens to cash out
    /// @param The bank account to which the money equivalent of the 
    /// tokens must be deposited
    function cashOut(uint tokens, string bankAccount) public {
        euroToken.setBalance(msg.sender, euroToken.balanceOf(msg.sender).sub(tokens));
        euroToken.setTotalSupply(euroToken.totalSupply().sub(tokens));
        CashOut(msg.sender, tokens, bankAccount);
    }
}