// pragma solidity >=0.4.24 <0.7.0;
pragma solidity >=0.4.22 <0.8.0;

import {Utils as u} from './utils.sol';
import './renting_contract.sol';
import './parking_service_provider.sol';
import './tenant.sol';
import './payment_policy.sol';

contract ParkingLotFactory {
    function create(
        address payable owner,
        uint spotsTotalNumber,
        string memory latitude,
        string memory longitude,
        string memory textAddress,
        uint _taxRate,
        bool isRentAllowed,
        uint frequency,
        uint penalty,
        uint penaltyPeriod,
        address _paymentpolicy
    ) public returns(ParkingLot) {
        return new ParkingLot(owner, spotsTotalNumber, latitude, longitude, textAddress,
            _taxRate, isRentAllowed, frequency, penalty, penaltyPeriod, msg.sender, _paymentpolicy);
    }
}
contract ParkingLot is ParkingProvider {


    //the location of the parking lot
    u.Location location;

    string textAddress;

    uint rating;
    uint ratePerHour;




    //////// Rent data //////////////
    mapping(address => Tenant) tenants;
    bool isRentAllowed;
    mapping(uint => bool) isSpotRented;  // whether each parking stall is rented or not
    mapping(address => uint) rentingFees; // stores renting fees for each tenant
    mapping(address => bool) existingTenants;
    uint parkingLotRentRate; //How much a tenant is charged. TODO chang to pricing policy
    mapping (address => RentingContract) rentingContracts;
    uint frequency; //TODO define frequency
    uint penalty;
    uint penaltyPeriod;


    constructor(
        address payable _owner,
        uint _spotsTotalNumber,
        string memory latitude,
        string memory longitude,
        string memory _textAddress,
        uint _taxRate,
        bool _isRentAllowed,
        uint _frequency,
        uint _penalty,
        uint _penaltyPeriod,
        address _parkingSystem,
        address _paymentPolicy
    ) ParkingProvider(_owner, _spotsTotalNumber, _parkingSystem, _paymentPolicy) public {
        location = u.Location({latitude: latitude, longitude: longitude});
        textAddress = _textAddress;
        isRentAllowed = _isRentAllowed;
        rating = 0; //TODO decide how to set rating
        parkingLotRentRate = _taxRate;
        frequency = _frequency;
        penalty = _penalty;
        penaltyPeriod = _penaltyPeriod;
        for (uint i = 1; i <= _spotsTotalNumber; i++) {
            parkingSpots[i] = true;
        }
    }

    /////////////////// Tenant /////////////////////////

    function requestTenantRegistration(address payable tenant,
        uint spotsTotalNumber,
        uint[] memory spotsArray,
        string memory name,
        uint rate,
        uint endRentDate,
        address _paymentPolicy) public {
        tenants[tenant] = new Tenant(tenant, spotsTotalNumber, parkingLotRentRate, spotsArray, name, rate, endRentDate, address(system), _paymentPolicy);
        rentingContracts[tenant] = system.rentingContractFactory().create(parkingLotRentRate, frequency, endRentDate, tenant, penalty, penaltyPeriod);
        existingTenants[tenant] = true;
        emit RequestTenantRegistration(tenant);
    }

    function approveTenant (address tenant) public isOwner(msg.sender) tenantExists(tenant) isTenantPending(tenant) {
        tenants[tenant].approve(address(rentingContracts[tenant]));
        emit DecideTenantRegistration(tenant, true, "");
    }

    function declineTenant (address tenant, string memory reason) public isOwner(msg.sender) tenantExists(tenant) isTenantPending(tenant) {
        delete tenants[tenant];
        delete rentingContracts[tenant];
        existingTenants[tenant] = false;
        emit DecideTenantRegistration(tenant, false, reason);
    }



    event RequestTenantRegistration(address indexed tenant);

    event DecideTenantRegistration(
        address indexed tenant,
        bool decision,
        string reason
    );

    function approve() public isSystem(msg.sender){
        ParkingProvider.approve();
    }





    function setIsRentAllowed (bool _isRentAllowed) private isSystem(msg.sender) {
        isRentAllowed = _isRentAllowed;
    }

    modifier isTenantPending(address tenant) {
        _;
        require(tenants[tenant].getState() == ParkingProvider.ParkingProviderState.Pending);
    }

    modifier tenantExists(address tenant) {
        _;
        require(existingTenants[tenant], "This tenant doesn't exist");
    }

}



