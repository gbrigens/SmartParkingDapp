// pragma solidity >=0.4.24 <0.7.0;
pragma solidity >=0.4.22 <0.8.0;
import {Utils as u} from './utils.sol';
contract Car {

    address system;
    address payable owner;
    string public plate;
    bool public isParked;
    uint rating;
    address public paymentChannel;
    address public parkingProvider;


    constructor(address payable _owner, string memory _plate) payable public {
        system = msg.sender;
        owner = _owner;
        plate = _plate;
        rating = 0; //TODO decide for rationg
    }


    function setParkingProvider(address _parkingProvider) public {
        parkingProvider = _parkingProvider;
    }

    modifier isOwner(address candidate){
        require(candidate == owner, "Only the owner of this parking provider can acceess this function");
        _;
    }

    modifier isSystem(address candidate){
        require(candidate == address(system), "Only the the system can acceess this function");
        _;
    }

    function park(address _paymentChannel) public {
        // require(parkingProvider == msg.sender, "Only parking provide can supply the payment channel");
        setParkingProvider(msg.sender);
        paymentChannel = _paymentChannel;
        isParked = true;
    }


    function finishParking() public {
        require(parkingProvider == msg.sender, "Only parking provide can supply the payment channel");
        isParked = false;
        parkingProvider = u.NO_ADDRESS();
        paymentChannel = u.NO_ADDRESS();
    }

    function getPlate() public view isSystem(msg.sender) returns(string memory) {
        return plate;
    }

    // function() external payable {

    // }
}
