pragma solidity >=0.4.22 <0.8.0;

import {Utils as u} from './utils.sol';
import './parking_lot.sol';
import './car.sol';
import './parking_service_provider.sol';
import './renting_contract.sol';
import './payment_channel.sol';
import './payment_policy.sol';



contract ParkingSystem {


    constructor (uint _taxRate, RentingContractFactory _rentingContractFactory, ParkingLotFactory _parkingLotFactory, PaymentChannelFactory _paymentChannelFactory)
    isRate(_taxRate)
    public
    payable
    {
        taxCollector = msg.sender;
        rentingContractFactory = _rentingContractFactory;
        parkingLotFactory = _parkingLotFactory;
        paymentChannelFactory = _paymentChannelFactory;
    }

    RentingContractFactory public rentingContractFactory;
    ParkingLotFactory public parkingLotFactory;
    PaymentChannelFactory public paymentChannelFactory;

    //////////////// Modifiers /////////////////////////


    modifier isRate(uint rate) {
        require(rate >= 0 && rate <= 100, "Tax rate must within the interval 0..100");
        _;
    }


    modifier isNewParkingLot(address parkingLotAddress){
        require(address(parkingLots[parkingLotAddress]) == u.NO_ADDRESS(), "A parking lot with this address has already been registered");
        _;
    }

    modifier isNewCar(address carAddress){
        require(address(cars[carAddress]) == u.NO_ADDRESS(), "A car with this address has already been registered");
        _;
    }

    modifier isParkingLot(address parkingLotAddress){
        require(address(parkingLots[parkingLotAddress]) != u.NO_ADDRESS(), "There is no such parking lot");
        _;
    }

    modifier isCar(address carAddress){
        require(address(cars[carAddress]) != u.NO_ADDRESS(), "There is no such car");
        _;
    }

    modifier isTaxCollector(address payable candidate) {
        require(candidate == taxCollector, "only tax collector can change the rate");
        _;
    }

    modifier isParkingLotPending(address parkingLot) {
        require(parkingLots[parkingLot].state() == ParkingProvider.ParkingProviderState.Pending, "");
        _;
    }

    ////////////////////////////////////////////////////


    //////////////// City Hall /////////////////////////

    address payable public taxCollector;

    //tax amount (in procentage e.g. 10 means 10%)
    uint public taxRate;

    //agreed Tax Rates for parkingLots
    mapping(address => uint) taxRates;


    function changeTaxRate(uint newTaxRate) public isTaxCollector(msg.sender){
        taxRate = newTaxRate;
    }

    ////////////////////////////////////////////////////


    //////////////// Parking Lot ///////////////////////

    //____________________EVENTS________________________
    event RequestParkingLotRegistration(address indexed parkingLot);

    event DecideParkingLotRegistration(
        address indexed parkingLot,
        bool decision,
        string reason
    );

    event DecideCarRegistration(
        address indexed carAddress,
        bool decision,
        string reason
    );

    //____________________VARS__________________________
    mapping(address => ParkingLot) public parkingLots;
    mapping(address => bool) existingParkingLots;

    //__________________FUNCTIONS_______________________

    //_____Registration_____
    function requestParkingLotRegistration(
        uint spotsTotalNumber,
        string memory latitude,
        string memory longitude,
        string memory textAddress,
        uint _taxRate,
        bool isRentAllowed,
        uint frequency,
        uint penalty,
        uint penaltyPeriod, //TODO add PaymentPolicy here
        address paymentPolicy
    )
    public payable
    isNewParkingLot(msg.sender) {
        require(_taxRate >= taxRate, "Disagreement on the city tax while regestering a new parking lot");
        taxRates[msg.sender] = _taxRate;
        parkingLots[msg.sender] = parkingLotFactory.create(
            msg.sender,
            spotsTotalNumber,
            latitude,
            longitude,
            textAddress,
            _taxRate,
            isRentAllowed,
            frequency,
            penalty,
            penaltyPeriod,
            paymentPolicy
        );

        existingParkingLots[msg.sender] = true;
        emit RequestParkingLotRegistration(address(parkingLots[msg.sender]));
    }

    // function testRegisterLot() public payable {
    //     requestParkingLotRegistration(100, "11", "22", "address", taxRate, true, 1 days, 100 wei, 1 days);
    // }

    function approveParkingLot (address parkingLot) public isTaxCollector(msg.sender) isParkingLotPending(parkingLot){
        parkingLots[parkingLot].approve();
        emit DecideParkingLotRegistration(parkingLot, true, "");
    }


    function declineParkingLot (address parkingLot, string memory reason) public isTaxCollector(msg.sender) isParkingLotPending(parkingLot) {
        delete parkingLots[parkingLot];
        existingParkingLots[parkingLot] = false;
        emit DecideParkingLotRegistration(parkingLot, false, reason);
    }




    // function allowRent(address parkingLot) public isParkingLot(msg.sender) {
    //     setIsRentAllowed(true);
    // }

    // function forbidRent() public isParkingLot(msg.sender) {
    //     setIsRentAllowed(false);
    // }

    // function completeParking(address parkingProvider, uint256 amount, bytes memory signature)
    //     public
    //     isCar(msg.sender)
    //     // isParkingLot(parkingLotAddress) //TODO consider tenants
    //     {
    //     Car car = cars[msg.sender];
    //     ParkingProvider parkingProvider = parkingLots[parkingLotAddress];
    //     require(car.isParked(), "Car is not parked");
    //     require(car.parkingProvider() == parkingLotAddress, "Car is not parked on the parking lot with the provided address");

    //     PaymentChannel paymentChannel = PaymentChannel(car.paymentChannel);
    //     paymentChannel.close(amount, signature);

    //     car.isParked = false;
    //     car.parkingLotAddress = u.NO_ADDRESS();
    //     parkingLot.paymentChannel = u.NO_ADDRESS();
    //     car.paymentChannel = u.NO_ADDRESS();
    //     uint parkingSpotNumber = parkingLot.carsSpots[msg.sender];
    //     parkingLot.parkingSpotsOccupation[parkingSpotNumber] = u.NO_ADDRESS();
    //     parkingLot.carsSpots[msg.sender] = 0;
    //     parkingLot.availableSpotsNumber += 1;
    // }






    ////////////////////////////////////////////////////


    ///////////////////// Car //////////////////////////

    mapping(address => Car) public cars;

    function registerCar(string memory plate) public isNewCar(msg.sender){
        cars[msg.sender] = new Car(msg.sender, plate);
        emit DecideCarRegistration(address(cars[msg.sender]), true, "");
    }

    function getPlate(address car) public view returns(string memory){
        return cars[car].getPlate();
    }

    function getContractAddress(address car) public view returns(address){
        return address(cars[car]);
    }
    ////////////////////////////////////////////////////




    // function initializePaymentChannel(address payable _recipient, uint256 duration) public returns(PaymentChannel) {
    //     PaymentChannel paymentChannel = new PaymentChannel(_recipient, duration);
    //     return paymentChannel;
    // }

}
