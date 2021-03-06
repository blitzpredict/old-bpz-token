pragma solidity 0.4.19;

import "./IToken.sol";
import "./Owned.sol";

contract TokenRetriever is Owned {
    function TokenRetriever()
        internal
    {
    }

    /// @dev Failsafe mechanism - Allows owner to retrieve tokens from the contract
    /// @param _tokenContract The address of ERC20 compatible token
    function retrieveTokens(address _tokenContract)
        public
        onlyOwner
    {
        IToken tokenInstance = IToken(_tokenContract);
        uint tokenBalance = tokenInstance.balanceOf(this);
        if (tokenBalance > 0) {
            tokenInstance.transfer(owner, tokenBalance);
        }
    }
}
