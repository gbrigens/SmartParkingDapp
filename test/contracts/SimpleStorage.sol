// pragma solidity >=0.4.22 <0.8.0;
pragma solidity >=0.4.22 <0.8.0;

contract SimpleStorage {
    uint storageData;
    
    event Change(string message, uint newVal);
    
    constructor(uint x) payable public {
        emit Change("initialize",x);
        storageData = x;
    }
    
    function set(uint x) public {
        emit Change("set", x);
        storageData = x;
    }
    
    function get() view public returns (uint retVal) {
        return storageData;
    }
}


//https://www.ludu.co/course/ethereum/what-is-ethereum