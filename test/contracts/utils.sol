// pragma solidity >=0.4.24 <0.7.0;
pragma solidity >=0.4.22 <0.8.0;

library Utils {

    function NO_ADDRESS() public pure returns(address){
        return 0x0000000000000000000000000000000000000000;
    }

    struct Location {
        string latitude;
        string longitude;
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }
}
