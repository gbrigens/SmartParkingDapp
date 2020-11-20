// pragma solidity >=0.4.24 <0.7.0;
pragma solidity >=0.4.22 <0.8.0;

contract RentingContractFactory {
    function create(uint _rentAmount,
        uint _frequency,
        uint _endRentDate,
        address _tenant,
        uint _penalty,
        uint _penaltyPeriod
    ) public returns(RentingContract) {
        return new RentingContract(_rentAmount, _frequency, _endRentDate, _tenant, _penalty, _penaltyPeriod, msg.sender);
    }

    function createTest() public returns(RentingContract) {
        return new RentingContract(1 ether, 30, now + 1 days, 0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C, 100 wei, 1 minutes, msg.sender);
    }
}

contract RentingContract {
    address payable public landlord;
    address public tenant;

    uint startRentDate;
    uint endRentDate;
    RentingContractState state;

    uint rentAmount;
    uint frequency;

    // The total penalty is calculated as penalty * (delay/penaltyPeriod)
    uint penalty;
    uint penaltyPeriod;

    struct RentEntry {
        uint time;
        uint deadline;
        uint value;
    }

    struct Amendment {
        uint endDate;
        uint rentAmount;
        uint frequency;
        uint penalty;
        uint penaltyPeriod;
    }

    uint amendmentIdCounter;

    struct ProposedAmendment {
        bool pending;
        bool landlordAgrees;
        bool tenantAgrees;
        Amendment amendment;
    }

    RentEntry[] public historyOfPayment;
    Amendment[] historyOfAmedments;
    ProposedAmendment proposedAmendment;


    enum RentingContractState { Created, Confirmed, Declined, Suspended, Expired }


    event ContractConfirmed();
    event ContractDeclined(string reason);
    event RentPaid(uint time, uint amount);
    event ContractTerminated(string reason);

    /*To this even both the tenant and the landlord can subscibe and both can emit it in order to accept any
     amendents to the contract*/
    event AmendmentRequested(uint indexed id, uint endDate, uint rentAmount, uint frequency, uint penalty, uint penaltyPeriod, string reason);
    event AmendmentApproved(uint indexed id);
    event AmendmentDeclined(uint indexed id, string reason);
    event AmendmentWithdrawn(uint indexed id, string reason);

    modifier inState(RentingContractState _state)  {
        if (now > endRentDate) {
            state = RentingContractState.Expired;
            emit ContractTerminated("contract has expired");
        }
        require(state == _state, "Function cannot operate with the contract in this state");
        _;
    }

    modifier isLandLord(address candidate) {
        require(candidate == landlord, "Only landlord can access this function");
        _;
    }

    modifier isTenant(address candidate) {
        require(candidate == tenant, "Only tenant can access this function");
        _;
    }

    modifier isLandlordOrTenant(address candidate) {
        require(candidate == landlord || candidate == tenant, "Only enant or landlord can access this function");
        _;
    }

    modifier isTheOtherParty(address candidate) {
        if (proposedAmendment.landlordAgrees)
            require(candidate == tenant, "The amendment was proposed by the landlord, only the tenant can do this action");
        else
            require(candidate == landlord, "The amendment was proposed by the tenant, only the landlord can do this action");
        _;
    }

    modifier isTheSameParty(address candidate) {
        if (proposedAmendment.landlordAgrees)
            require(candidate == landlord, "The amendment was proposed by the landlord, only the landlord can do this action");
        else
            require(candidate == tenant, "The amendment was proposed by the tenant, only the tenant can do this action");
        _;
    }

    modifier amendmentPending(){
        require(proposedAmendment.pending, "There is no amendment to approve");
        _;
    }

    modifier noAmendmentPending(){
        require (!proposedAmendment.pending, "There is a pending amendment. The pending amendment has to be approved, declined or withdrawn before a new reqesting a new amendment");
        _;
    }


    /// @param _rentAmount how much one prediod costs
    /// @param _frequency how long one period lasts
    /// @param _endRentDate expiry date-time of the contract
    /// @param _tenant address of tenant
    constructor(
        uint _rentAmount,
        uint _frequency,
        uint _endRentDate,
        address _tenant,
        uint _penalty,
        uint _penaltyPeriod,
        address payable _landlord
    ) public {
        rentAmount = _rentAmount;
        frequency = _frequency;
        landlord = _landlord;
        endRentDate =_endRentDate;
        state = RentingContractState.Created;
        tenant = _tenant;
        penalty = _penalty;
        penaltyPeriod = _penaltyPeriod;
    }

    function confirmAgreement() public inState(RentingContractState.Created) isTenant(msg.sender) {
        emit ContractConfirmed();
        state = RentingContractState.Confirmed;
        startRentDate = now;
    }

    function pay() payable public isTenant(msg.sender) inState(RentingContractState.Confirmed) {
        uint previousDeadline = startRentDate + frequency;
        if (historyOfPayment.length != 0){
            RentEntry memory lastEntry = historyOfPayment[historyOfPayment.length - 1];
            previousDeadline = lastEntry.deadline;
            require(lastEntry.deadline < now, "the rent has already been payed for this period");
        }

        (uint currentPenalty, uint delay) = calculateCurrentPenalty();
        uint numberOfPeriods = calculateNumberOfPeriods(delay);
        uint debt = calculateTotalDebt(numberOfPeriods, currentPenalty);
        require(msg.value >= debt, "amount sent for rent is wrong");
        landlord.transfer(debt);
        historyOfPayment.push(RentEntry({
            time: now,
            deadline: previousDeadline + frequency * numberOfPeriods,
            value: msg.value
            }));
        emit RentPaid(now, msg.value);
    }

    function getTotalDebt() public returns(uint debt) {
        (uint currentPenalty, uint delay) = calculateCurrentPenalty();
        uint numberOfPeriods = calculateNumberOfPeriods(delay);
        debt = calculateTotalDebt(numberOfPeriods, currentPenalty);
    }

    function calculateTotalDebt(uint numberOfPeriods, uint currentPenalty) public view returns(uint debt) {
        debt = rentAmount * numberOfPeriods + currentPenalty;
    }

    function calculateNumberOfPeriods(uint delay) public view returns(uint) {
        return 1 + delay / frequency;
    }

    function terminateContract(string memory reason) public {
        //TODO complete this function so that either landlord or tenant could terminate it
    }

    function calculateCurrentPenalty() public inState(RentingContractState.Confirmed) returns(uint penaltyAmount, uint delay){
        uint previousPaymentTime = startRentDate;
        if (historyOfPayment.length != 0){
            previousPaymentTime = historyOfPayment[historyOfPayment.length - 1].time;
        }
        if (now-previousPaymentTime < frequency) {
            return (0, 0);
        }

        delay = now - previousPaymentTime - frequency;
        penaltyAmount = calculatePenalty(delay, penalty, penaltyPeriod);
    }

    function requestAmendment(uint _endDate,
        uint _rentAmount,
        uint _frequency,
        uint _penalty,
        uint _penaltyPeriod,
        string memory reason) public isLandlordOrTenant(msg.sender) noAmendmentPending(){
        bool _landlordAgrees;
        bool _tenantAgrees;
        if (msg.sender == landlord)
            _landlordAgrees = true;
        else
            _tenantAgrees = true;
        Amendment memory amendment = Amendment({
            endDate: _endDate,
            rentAmount: _rentAmount,
            frequency: _frequency,
            penalty: _penalty,
            penaltyPeriod: _penaltyPeriod
            });

        proposedAmendment = ProposedAmendment({
            pending: true,
            landlordAgrees: _landlordAgrees,
            tenantAgrees: _tenantAgrees,
            amendment: amendment
            });
        emit AmendmentRequested(getNewAmendmentId(), _endDate, _rentAmount, _frequency, _penalty, _penaltyPeriod, reason);

    }

    function approveAmendment() public isLandlordOrTenant(msg.sender) amendmentPending() isTheOtherParty(msg.sender){
        applyProposedAmendment();
        historyOfAmedments.push(proposedAmendment.amendment);
        proposedAmendment.pending = false;
        emit AmendmentApproved(amendmentIdCounter);
    }

    function declineAmendment(string memory reason) public isLandlordOrTenant(msg.sender) amendmentPending() isTheOtherParty(msg.sender){
        proposedAmendment.pending = false;
        emit AmendmentDeclined(amendmentIdCounter, reason);
    }

    function withdrawAmendment(string memory reason) public isLandlordOrTenant(msg.sender) amendmentPending() isTheSameParty(msg.sender){
        proposedAmendment.pending = false;
        emit AmendmentWithdrawn(amendmentIdCounter, reason);
    }

    ////////////////////////// Auxiliary functions ///////////////////////////////

    function getNewAmendmentId() private returns(uint){
        uint id = amendmentIdCounter;
        amendmentIdCounter++;
        return id;
    }

    function calculatePenalty(uint delay,
        uint _penalty,
        uint _penaltyPeriod) private pure returns(uint){
        return _penalty * (delay / _penaltyPeriod);
    }

    function applyProposedAmendment() private amendmentPending(){
        Amendment memory amendment = proposedAmendment.amendment;
        updateContractDetails(amendment.endDate, amendment.rentAmount, amendment.frequency, amendment.penalty, amendment.penaltyPeriod);
    }

    function updateContractDetails(uint _endDate,
        uint _rentAmount,
        uint _frequency,
        uint _penalty,
        uint _penaltyPeriod) private{
        require(_endDate > now);
        endRentDate = _endDate;
        rentAmount = _rentAmount;
        frequency = _frequency;
        penalty = _penalty;
        penaltyPeriod = _penaltyPeriod;
    }
}
