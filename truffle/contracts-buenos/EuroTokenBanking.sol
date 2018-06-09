pragma solidity ^0.4.17;

import "./Owned.sol";
import "./EuroToken.sol";
import "./SafeMath.sol";

contract EuroTokenBanking  is Owned {

    using SafeMath for uint;

    EuroToken public euroToken;

    event CashIn(address indexed receiver, uint256 amount);
    event CashOut(address indexed receiver, uint256 amount, string bankAccount);

    function EuroTokenBanking() public {
        euroToken = new EuroToken();
    }

    function cashIn(address to, uint tokens) public onlyOwner {
        euroToken.setBalance(to, euroToken.balanceOf(to).add(tokens));
        euroToken.setTotalSupply(euroToken.totalSupply().add(tokens));
        CashIn(to, tokens);
        
    }

    function cashOut(uint tokens, string bankAccount) public {
        euroToken.setBalance(msg.sender, euroToken.balanceOf(msg.sender).sub(tokens));
        euroToken.setTotalSupply(euroToken.totalSupply().sub(tokens));
        CashOut(msg.sender, tokens, bankAccount);
    }
}