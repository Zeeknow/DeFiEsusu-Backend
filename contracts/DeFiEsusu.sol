// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract DeFiEsusu {
    using SafeERC20 for IERC20;

    IERC20 public usdcToken;
    address public feeCollector;
    uint256 public constant PENALTY_BASIS_POINTS = 200; // 2%

    struct Circle {
        uint256 id;
        uint256 contributionAmount;
        uint256 maxMembers;        // Maximum slots (e.g., 5)
        address[] payoutOrder;     // List of members
        uint256 currentRound;
        bool isActive;             // True only when circle is FULL
        mapping(uint256 => mapping(address => bool)) hasContributed;
        uint256 roundBalance;
    }

    struct PersonalVault {
        uint256 balance;
        uint256 unlockTime;
        bool exists;
    }

    uint256 public nextCircleId;
    mapping(uint256 => Circle) public circles;
    mapping(address => PersonalVault) public personalVaults;

    event CircleCreated(uint256 indexed circleId, uint256 amount, uint256 maxMembers);
    event MemberJoined(uint256 indexed circleId, address member, uint256 currentCount);
    event CircleStarted(uint256 indexed circleId); // Emitted when full
    event ContributionMade(uint256 indexed circleId, address contributor, uint256 round);
    event CirclePayout(uint256 indexed circleId, address recipient, uint256 amount);
    event PersonalDeposit(address indexed user, uint256 amount, uint256 unlockTime);
    event PersonalWithdrawal(address indexed user, uint256 amount, uint256 penalty);

    constructor(address _usdcToken, address _feeCollector) {
        usdcToken = IERC20(_usdcToken);
        feeCollector = _feeCollector;
    }

    // --- FEATURE 1: ESUSU (Create & Join) ---

    // 1. Create: Define rules, become member #1
    function createCircle(uint256 _amount, uint256 _maxMembers) external {
        require(_maxMembers > 1, "Min 2 members");
        
        Circle storage c = circles[nextCircleId];
        c.id = nextCircleId;
        c.contributionAmount = _amount;
        c.maxMembers = _maxMembers;
        
        // Creator joins automatically
        c.payoutOrder.push(msg.sender); 

        emit CircleCreated(nextCircleId, _amount, _maxMembers);
        emit MemberJoined(nextCircleId, msg.sender, 1);
        
        nextCircleId++;
    }

    // 2. Join: Friends use ID to join
    function joinCircle(uint256 _circleId) external {
        Circle storage c = circles[_circleId];
        require(c.contributionAmount > 0, "Circle doesn't exist");
        require(c.payoutOrder.length < c.maxMembers, "Circle is full");
        require(!c.isActive, "Circle already started");

        // Check for duplicates
        for(uint i=0; i < c.payoutOrder.length; i++){
            require(c.payoutOrder[i] != msg.sender, "Already joined");
        }

        c.payoutOrder.push(msg.sender);
        emit MemberJoined(_circleId, msg.sender, c.payoutOrder.length);

        // If full, start the circle!
        if(c.payoutOrder.length == c.maxMembers) {
            c.isActive = true;
            emit CircleStarted(_circleId);
        }
    }

    function contributeToCircle(uint256 _circleId) external {
        Circle storage c = circles[_circleId];
        require(c.isActive, "Circle not active (waiting for members)");
        require(!c.hasContributed[c.currentRound][msg.sender], "Paid this round");
        
        // Verify Membership
        bool isMember = false;
        for(uint i=0; i < c.payoutOrder.length; i++) {
            if (c.payoutOrder[i] == msg.sender) isMember = true;
        }
        require(isMember, "Not a member");

        usdcToken.safeTransferFrom(msg.sender, address(this), c.contributionAmount);
        
        c.hasContributed[c.currentRound][msg.sender] = true;
        c.roundBalance += c.contributionAmount;

        emit ContributionMade(_circleId, msg.sender, c.currentRound);

        // Payout if round complete
        if (c.roundBalance >= (c.contributionAmount * c.maxMembers)) {
            _distributePot(_circleId);
        }
    }

    function _distributePot(uint256 _circleId) internal {
        Circle storage c = circles[_circleId];
        address recipient = c.payoutOrder[c.currentRound];
        uint256 amount = c.roundBalance;

        c.roundBalance = 0;
        c.currentRound++;

        usdcToken.safeTransfer(recipient, amount);
        emit CirclePayout(_circleId, recipient, amount);

        if (c.currentRound >= c.maxMembers) {
            c.isActive = false; // Finished
        }
    }

    // --- FEATURE 2: VAULT (Same as before) ---

    function depositPersonal(uint256 _amount, uint256 _lockDurationSeconds) external {
        require(_amount > 0, "Amount > 0");
        PersonalVault storage v = personalVaults[msg.sender];
        usdcToken.safeTransferFrom(msg.sender, address(this), _amount);
        v.balance += _amount;
        v.exists = true;
        uint256 newUnlock = block.timestamp + _lockDurationSeconds;
        if (newUnlock > v.unlockTime) v.unlockTime = newUnlock;
        emit PersonalDeposit(msg.sender, _amount, v.unlockTime);
    }

    function withdrawPersonal(uint256 _amount) external {
        PersonalVault storage v = personalVaults[msg.sender];
        require(v.balance >= _amount, "Insufficient funds");
        uint256 amountToSend = _amount;
        uint256 penalty = 0;
        if (block.timestamp < v.unlockTime) {
            penalty = (_amount * PENALTY_BASIS_POINTS) / 10000;
            amountToSend = _amount - penalty;
            if (penalty > 0) usdcToken.safeTransfer(feeCollector, penalty);
        }
        v.balance -= _amount;
        usdcToken.safeTransfer(msg.sender, amountToSend);
        emit PersonalWithdrawal(msg.sender, amountToSend, penalty);
    }

    // --- View Helpers ---
    // Returns basic details + number of members currently joined
    function getCircleDetails(uint256 _circleId) external view returns (
        uint256 id, uint256 amount, uint256 max, uint256 currentCount, bool active, uint256 round
    ) {
        Circle storage c = circles[_circleId];
        return (c.id, c.contributionAmount, c.maxMembers, c.payoutOrder.length, c.isActive, c.currentRound);
    }
}