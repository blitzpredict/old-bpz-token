pragma solidity 0.4.19;

import "./BaseContract.sol";
import "./TokenRetriever.sol";
import "./ERC20Token.sol";
import "./Owned.sol";

contract SmartToken is BaseContract, Owned, TokenRetriever, ERC20Token {
    using SafeMath for uint256;

    bool public issuanceEnabled = true;

    // triggered when a smart token is deployed
    // the _token address is defined for forward compatibility,
    // in case we want to trigger the event from a factory
    event NewSmartToken(address indexed _token);

    // triggered when the total supply is increased
    event Issuance(uint256 _amount);

    /// @dev constructor
    /// @param _name       token name
    /// @param _symbol     token short symbol, minimum 1 character
    /// @param _decimals   for display purposes only
    function SmartToken(string _name, string _symbol, uint8 _decimals)
        internal
        ERC20Token(_name, _symbol, _decimals)
    {
        NewSmartToken(address(this));
    }

    /// @dev disables/enables token issuance
    /// can only be called by the contract owner
    function disableIssuance()
        public
        onlyOwner
        onlyIf(issuanceEnabled)
    {
        issuanceEnabled = false;
    }

    /// @dev increases the token supply and sends the new tokens to an account
    /// can only be called by the contract owner
    /// @param _to         account to receive the new amount
    /// @param _amount     amount to increase the supply by
    function issue(address _to, uint256 _amount)
        public
        onlyOwner
        validParamData(2)
        validAddress(_to)
        onlyIf(issuanceEnabled)
        notThis(_to)
    {
        totalSupply = totalSupply.add(_amount);
        balanceOf[_to] = balanceOf[_to].add(_amount);

        Issuance(_amount);
        Transfer(this, _to, _amount);
    }

    ////////////////////////////////////////////////////////////////
    // ERC20 standard method overrides with some extra functionality
    ////////////////////////////////////////////////////////////////

    /// @dev send coins
    /// throws on any error rather then return a false flag to minimize user errors
    /// @param _to      target address
    /// @param _value   transfer amount
    /// @return true if the transfer was successful, false if it wasn't
    function transfer(address _to, uint256 _value)
        public
        validParamData(2)
        returns (bool success)
    {
        assert(super.transfer(_to, _value));
        return true;
    }

    /// @dev an account/contract attempts to get the coins
    /// throws on any error rather then return a false flag to minimize user errors
    /// @param _from    source address
    /// @param _to      target address
    /// @param _value   transfer amount
    /// @return true if the transfer was successful, false if it wasn't
    function transferFrom(address _from, address _to, uint256 _value)
        public
        validParamData(3)
        returns (bool success)
    {
        assert(super.transferFrom(_from, _to, _value));
        return true;
    }
}
