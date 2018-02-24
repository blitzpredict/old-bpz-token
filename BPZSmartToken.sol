pragma solidity 0.4.19;

import "./common/SmartToken.sol";

contract BPZSmartToken is SmartToken {
    function BPZSmartToken()
        public
        SmartToken("BlitzPredict", "BPZ", 18)
    {
    }
}
