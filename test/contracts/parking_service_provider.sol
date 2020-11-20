// pragma solidity >=0.4.24 <0.7.0;
pragma solidity >=0.4.22 <0.8.0;

import './car.sol';
import './parking_system.sol';
import './payment_channel.sol';
import {Utils as u} from './utils.sol';
import './payment_policy.sol';

contract ParkingProvider {

    enum ParkingProviderState {
        Pending, Approved, Working, Closed
    }

    PaymentPolicy public paymentPolicy;

    ParkingSystem public system;
    address payable owner;

    ParkingProviderState public state;

    //////// Parking Stalls //////////
    uint public spotsTotalNumber;
    uint availableSpotsNumber;


    //Payiment policy
    // uint ratePerHour; //TODO make the policy more complex


    //numbers of parking spots
    mapping(uint => bool) parkingSpots;

    //addresses of cars parked at parking spots (by number)
    mapping(uint => Car) public parkingSpotsOccupation;

    //parking spot's numbers of parked cars (by address)
    mapping(address => uint) public carsSpots;

    //keeps tracks of all currently open payment channels (car address => payment channel)
    mapping(address => PaymentChannel) public paymentChannels;

    constructor(
        address payable _owner,
        uint _spotsTotalNumber,
        address _parkingSystem,
        address _paymentPolicy
    ) public payable {
        system = ParkingSystem(_parkingSystem);
        owner = _owner;
        spotsTotalNumber = _spotsTotalNumber;
        availableSpotsNumber = _spotsTotalNumber;
        state = ParkingProviderState.Pending;
        paymentPolicy = PaymentPolicy(_paymentPolicy);
    }

    modifier isValidParkingSpot(uint parkingSpotNumber){
        require(parkingSpots[parkingSpotNumber], "Parking spot does not belong to this parking provider");
        _;
    }

    modifier isOwner(address candidate){
        require(candidate == owner, "Only the owner of this parking provider can acceess this function");
        _;
    }

    modifier isSystem(address candidate){
        require(candidate == address(system), "Only the the system can acceess this function");
        _;
    }


    function() external payable {
    }

    function calculatePaymentForParkingFromNow(uint endTime) public view returns(uint){
        require(now < endTime);
        return paymentPolicy.calculatePrice(now, endTime);
    }

    function calculatePaymentForParking(uint startTime, uint endTime) public view returns(uint){
        require(startTime < endTime);
        require(startTime >= now);
        require(endTime > now);
        return paymentPolicy.calculatePrice(startTime, endTime);
    }

    event X(uint needed, uint received);

    function park(
        uint parkingSpotNumber,
        address payable carAddress,
        uint endTime
    )
    public
    payable
    {
        //TODO set parking provider
        Car car = Car(carAddress);
        require(availableSpotsNumber > 0, "There are no parking spots available");
        require(!car.isParked(), "Car is already parked");
        require(address(parkingSpotsOccupation[parkingSpotNumber]) == u.NO_ADDRESS(), "Chosen parking spot is taken");
        require(carsSpots[carAddress] == 0, "The car is parked here already");
        uint requiredValue = calculatePaymentForParking(now, endTime);
        if (msg.value < requiredValue) {
            emit X(requiredValue, msg.value);
            return;
        }
        require(msg.value >= requiredValue, "insufficient funding");
        // require(msg.value >= requiredValue, string(abi.encodePacked("insufficient funding, needed ", u.uint2str(requiredValue), " but received ", u.uint2str(msg.value))));
        PaymentChannel paymentChannel  = system.paymentChannelFactory().create.value(msg.value)(msg.sender, owner, endTime);
        require(address(paymentChannel).balance == msg.value, "Contract was not initialized correctly");
        car.park(address(paymentChannel));
        paymentChannels[address(car)] = paymentChannel;
        parkingSpotsOccupation[parkingSpotNumber] = car;
        carsSpots[carAddress] = parkingSpotNumber;
        availableSpotsNumber -= 1;
    }

    function completeParking(address carAddress, uint256 amount, bytes memory signature)
    public
        // isCar(msg.sender)
    isOwner(msg.sender)
    {
        uint parkingSpotNumber = carsSpots[carAddress];
        Car car = parkingSpotsOccupation[parkingSpotNumber];
        require(car.isParked(), "Car is not parked");

        PaymentChannel paymentChannel = paymentChannels[carAddress];

        require(car.parkingProvider() == address(this), "Car is not parked on the parking lot with the provided address");

        paymentChannel.close(amount, signature);

        car.finishParking();
        delete paymentChannels[carAddress];
        delete parkingSpotsOccupation[parkingSpotNumber];
        carsSpots[carAddress] = 0;
        availableSpotsNumber += 1;
    }

    function approve() public {
        state = ParkingProviderState.Approved;
    }

    function getState() public view returns(ParkingProviderState){
        return state;
    }
}
