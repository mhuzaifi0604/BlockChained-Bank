// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

 struct loan_status {
    uint256 amount;
    uint256 time;
}

struct user {
    uint256 joining_date;
    uint256 balance;
    bool exists;
    loan_status status;
}

contract Bank {
    mapping(address => user) private users;
    address owner;

    constructor() payable {
        require(msg.value >= 50 ether, "You can not open a bank with less than 50 ether!");

        owner = msg.sender;
        users[address(this)].exists = true;
        users[address(this)].balance = msg.value;
    }

    receive() external payable {}

    modifier isOwner {
        require(msg.sender == owner, "You must be the owner to be able to access this function!");
        _;
    }

    function invest() public payable isOwner {
        users[address(this)].balance += msg.value;
    }

    function getBankFunds() public view isOwner returns(uint256){
        return users[address(this)].balance;
    }

    function register() public payable{
        require(!users[msg.sender].exists, "You're already registered");
        require(msg.value >= 1 ether, "You need atleast 1 ether to open up an account!");

        uint256 rest = msg.value - 1 ether;
        users[address(this)].balance += 1;
        users[msg.sender].exists = true;
        users[msg.sender].balance = rest;
        users[msg.sender].joining_date = block.timestamp;
        users[msg.sender].status.amount = 0;
        users[msg.sender].status.time = 0;
    }

    modifier isAccountOwner {
        require(users[msg.sender].exists, "You must be registered with the bank to be able to perform this function!");
        _;
    }

    function deposit() public payable isAccountOwner {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        users[msg.sender].balance += msg.value;
    }

    function withdraw(uint256 amount) public payable isAccountOwner{
        require(amount > 0, "Withdrawal amount must be greater than 0");
        require(users[msg.sender].balance >= amount, "Insufficient funds");
        payable(msg.sender).transfer(amount);
        users[msg.sender].balance -= amount;
    }

    function getBalance() public view isAccountOwner returns (uint256) {
        return users[msg.sender].balance;
    }

    modifier canGetLoan {
        require(block.timestamp-users[msg.sender].joining_date > 10 seconds, "You need to be registered with the bank for atleast 1 minute to be able to apply for a loan!");
        require(users[msg.sender].status.amount == 0, "You need to repay your previous loan to be able to apply for another!");
        _;
    }

    function getLoanStatus() public view returns (
        uint256, // amount to be paid
        uint256  // time elapsed
    ){
        require(users[msg.sender].status.amount != 0, "You don't have an active loan!");

        uint256 interestRate = 2; // Assuming a 2% interest rate per year

        // Calculate the interest accrued
        uint256 interestAccrued = (users[msg.sender].status.amount * interestRate * (block.timestamp - users[msg.sender].status.time)) / (365 days * 100);

        // Calculate the total amount to be paid
        uint256 totalAmountToBePaid = users[msg.sender].status.amount + interestAccrued;

        // Calculate the time elapsed in years
        uint256 timeElapsedInYears = (block.timestamp - users[msg.sender].status.time) / 365 days;

        return (totalAmountToBePaid, timeElapsedInYears);
    }

    function getLoan(uint256 amount) public payable canGetLoan {
        require(users[address(this)].balance > amount && amount < 50 ether, "Too much to ask for!");

        payable(msg.sender).transfer(amount);
        users[msg.sender].status.amount = amount;
        users[msg.sender].status.time = block.timestamp;

        users[address(this)].balance -= amount;
    }

    function returnLoan() public {
        uint256 interestRate = 2; // Assuming a 2% interest rate per year

        // Calculate the interest accrued
        uint256 interestAccrued = (users[msg.sender].status.amount * interestRate * (block.timestamp - users[msg.sender].status.time)) / (365 days * 100);

        // Calculate the total amount to be paid
        uint256 totalAmountToBePaid = users[msg.sender].status.amount + interestAccrued;

        require(users[msg.sender].balance >= totalAmountToBePaid, "You do not have enough funds to repay your loan!");

        users[msg.sender].balance -= totalAmountToBePaid;
        users[address(this)].balance += totalAmountToBePaid;

        users[msg.sender].status.amount = 0;
        users[msg.sender].status.time = 0;
    }
}