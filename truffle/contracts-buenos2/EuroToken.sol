pragma solidity ^0.4.17;

import "./Owned.sol";
import "./ERC20Interface.sol";
import "./SafeMath.sol";

/// @title A Token representative of the Euro currency.
/// @author Elias Torvisco
/// @notice This contract is used to transfer Euro Tokens between Ethereum accounts. 
///         it is controlled by a EuroTokenBanking
/// @dev All function calls are currently implement without side effects
contract EuroToken is ERC20Interface, Owned {
 
    using SafeMath for uint;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;

    function EuroToken() public {
        symbol = "EUR";
        name = "Euro Token";
        decimals = 4;
        _totalSupply = 0;
    }

    /// @dev This should be the documentation of the function for the developer docs
    /// @return the total amount of tokens currently available. 
    function totalSupply() public constant returns (uint) {
        return _totalSupply;
    }
    
    /// @param newTotalSupply The new total supply of tokens. Fixed by the owner.
    function setTotalSupply(uint newTotalSupply) public onlyOwner {
        _totalSupply = newTotalSupply;
    }
 
    /// @param tokenOwner The address from which we want to check the balance
    /// @return balance The token balance of the address consulted
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }
    /// @param to The address to which we want to change the balance
    /// @param tokens The number of tokens we want to assign
    /// @dev Only the owner of the contract can call this function
    function setBalance(address to, uint tokens) public onlyOwner {
        balances[to] = tokens;
        Transfer(this, to, tokens);
    }
    
    /// @notice Returns the amount of tokens approved by the owner that can be
    ///         transferred to the spender's account
    /// @param tokenOwner The address of the owner whose approval we want to check
    /// @param spender The address of the account that can use the tokens
    /// @return remaining The number of tokens approved
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
 
    /// @notice Transfer the balance from owner's account to another account
    /// @param to The address to which you want to transfer tokens
    /// @param tokens The number of tokens to be transferred
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }
 
    /// @notice Send `tokens` amount of tokens from address `from` to address `to`
    /// The transferFrom method is used for a withdraw workflow, allowing contracts to send
    /// tokens on your behalf, for example to "deposit" to a contract address and/or to charge
    /// fees in sub-currencies; the command should fail unless the _from account has
    /// deliberately authorized the sender of the message via some mechanism; 
    /// @param from The address from which the tokens will be sent
    /// @param to The address where the tokens will be sent
    /// @return success Returns 'true' if the transfer was successful
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(from, to, tokens);
        return true;
    }
 
    /// @notice Allow `spender` to withdraw from your account, multiple times, up to the `tokens` amount.
    /// @dev If this function is called again it overwrites the current allowance with _value.
    /// @param spender The address to which the use of tokens is approved
    /// @param tokens The number of tokens approved
    /// @return success Returns 'true' if the approval was successful
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }
}