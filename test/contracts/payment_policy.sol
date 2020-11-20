// pragma solidity >=0.4.24 <0.7.0;
pragma solidity >=0.4.22 <0.8.0;
import './date_time.sol';

interface PaymentPolicy {
    function calculatePrice(uint startTime, uint endTime) external view returns(uint price);
    function calculatePriceUptoNow(uint startTime) external view returns(uint price);
    function calculatePriceFromNow(uint endTime) external view returns(uint price);

    function getPriceAt(uint timeStamp) external view returns(uint price);
}

contract MyPaymentPolicyFactory {
    function createTest() public returns(MyPaymentPolicy) {
        uint[24] memory testRates;
        for (uint i = 0; i < 24; i++) {
            testRates[i] = 100 + i;
        }
        MyPaymentPolicy x = new MyPaymentPolicy(testRates, testRates, testRates, testRates, testRates, testRates, testRates);
        emit X(address(x));
        return x;
    }

    event X(
        address indexed policy
    );
}

contract MyPaymentPolicy is PaymentPolicy {

    address owner;

    modifier isOwner(address candidate){
        require(candidate == owner, "Only the owner of this parking provider can acceess this function");
        _;
    }

    enum WeekDays { Mon, Tue, Wed, Thu, Fri, Sat, Sun }

    //7 days, 24 hours in each
    uint[24][7] weekRates;

    constructor(uint[24] memory _mon,
        uint[24] memory _tue,
        uint[24] memory _wed,
        uint[24] memory _thu,
        uint[24] memory _fri,
        uint[24] memory _sat,
        uint[24] memory _sun) public {
        weekRates[0] = _mon;
        weekRates[1] = _tue;
        weekRates[2] = _wed;
        weekRates[3] = _thu;
        weekRates[4] = _fri;
        weekRates[5] = _sat;
        weekRates[6] = _sun;
        owner = msg.sender;
    }

    function calculatePriceFromNow(uint endTime) external view returns(uint price) {
        require(now < endTime);
        return this.calculatePrice(now, endTime);
    }

    function calculatePriceUptoNow(uint startTime) external view returns(uint price) {
        require(startTime <= now, "start time must be less than now");
        return this.calculatePrice(startTime, now);
    }

    function calculatePrice(uint startTime, uint endTime) external view returns(uint price) {
        require(endTime > startTime, "Start time must be less that endTime");
        price = 0;
        if (endTime - startTime < 60 * 60) {
            uint _week = DateTimeLibrary.getDayOfWeek(startTime) - 1;
            uint _hour = DateTimeLibrary.getHour(startTime);
            return weekRates[_week][_hour] * (endTime - startTime);
        }
        (uint year, uint month, uint day, uint hour, uint minute, uint second) = DateTimeLibrary.timestampToDateTime(startTime);
        if (!(minute == 0 && second == 0)) {
            uint _week = DateTimeLibrary.getDayOfWeek(startTime) - 1;
            uint _hour = DateTimeLibrary.getHour(startTime);
            uint newStartTime = DateTimeLibrary.timestampFromDateTime(year, month, day, hour + 1, 0, 0);
            price = weekRates[_week][_hour] * (newStartTime - startTime);
            startTime = newStartTime;
        }
        uint i;
        for (i = startTime; i < endTime - 60 * 60; i = i + 60 * 60) {
            uint _week = DateTimeLibrary.getDayOfWeek(i) - 1;
            uint _hour = DateTimeLibrary.getHour(i);
            price += weekRates[_week][_hour] * 60 * 60;
        }
        uint week = DateTimeLibrary.getDayOfWeek(i) - 1;
        hour = DateTimeLibrary.getHour(i);
        price += (endTime - i) * weekRates[week][hour];
    }

    function getPriceAt(uint timeStamp) external view returns(uint price) {
        uint week = DateTimeLibrary.getDayOfWeek(timeStamp) - 1;
        uint hour = DateTimeLibrary.getHour(timeStamp);
        price = weekRates[week][hour];
    }

    function setNewWeekRates(uint[24][7] memory newWeekRates) public isOwner(msg.sender) {
        weekRates = newWeekRates;
    }

    // day can be 0 - 6, where 0 is Monday and 6 is Sunday
    function setDayRates(uint[24] memory newDayRates, uint day) public isOwner(msg.sender) {
        weekRates[day] = newDayRates;
    }

    // day can be 0 - 6, where 0 is Monday and 6 is Sunday
    function setHourRates(uint newRate, uint day, uint hour) public isOwner(msg.sender) {
        weekRates[day][hour] = newRate;
    }
}
