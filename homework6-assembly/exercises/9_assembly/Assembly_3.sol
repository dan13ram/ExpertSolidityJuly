pragma solidity ^0.8.4;
contract SubOverflow {

    // Modify this function so on overflow it sets value to 0
    function subtract(uint x, uint y) public pure returns (uint) {        

        // Write assembly code that handles overflows        
        assembly {                        
            if lt(x, y)  {
               mstore(0x00, 0x00)
               return(0x00, 0x20)
            }
            let result := sub(x, y)
            mstore(0x80, result)
            return(0x80, 0x20)
         
        }
    }    
}

