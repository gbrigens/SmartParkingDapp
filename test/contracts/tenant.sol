// pragma solidity >=0.4.24 <0.7.0;
pragma solidity >=0.4.22 <0.8.0;

import {Utils as u} from './utils.sol';
import './renting_contract.sol';
import './parking_service_provider.sol';
import './parking_lot.sol';


contract Tenant is ParkingProvider {

    //____________________VARS__________________________
    uint parkingLotRentRate;
    uint startRentDate;
    uint endRentDate;
    string name;
    uint rate;
    uint[] spotsArray;
    ParkingLot parkingLot;
    RentingContract rentingContract;

    //_________________MODIFIERS_________________________
    modifier isLandlord(address candidate) {
        require(candidate == address(parkingLot), "only the landlord has access to this function");
        _;
    }

    //__________________EVENTS___________________________


    constructor(
        address payable _owner,
        uint _spotsTotalNumber,
        uint _parkingLotRentRate,
        uint[] memory _spotsArray,
        string memory _name,
        uint _rate,
        uint _endRentDate,
        address _parkingSystem,
        address _paymentPolicy
    ) ParkingProvider(_owner, _spotsTotalNumber, _parkingSystem, _paymentPolicy) public {
        for (uint i = 0; i < _spotsArray.length; i++) {
            parkingSpots[i] = true;
        }
        spotsArray = _spotsArray;
        parkingLotRentRate = _parkingLotRentRate;
        startRentDate = now;
        endRentDate = _endRentDate;
        name = _name;
        rate = _rate;
        parkingLot = ParkingLot(msg.sender);
    }

    //_________________METHODS_________________________
    function approve(address _rentingContract) public isLandlord(msg.sender){
        rentingContract = RentingContract(_rentingContract);
        ParkingProvider.approve();
    }


}
