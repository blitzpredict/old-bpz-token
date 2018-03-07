pragma solidity 0.4.19;

interface IOldTokenSale { 
    function whitelist(address)
        public view
        returns (uint256);
}
