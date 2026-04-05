// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./TokenA.sol";

contract LendingPool {
    TokenA public token;

    uint256 public constant LTV = 75; // 75%
    uint256 public constant LIQ_THRESHOLD = 80; // liquidation threshold
    uint256 public interestRate = 5; // 5% simple interest

    struct User {
        uint256 deposited;
        uint256 borrowed;
        uint256 lastUpdate;
    }

    mapping(address => User) public users;

    event Deposit(address user, uint256 amount);
    event Borrow(address user, uint256 amount);
    event Repay(address user, uint256 amount);
    event Withdraw(address user, uint256 amount);
    event Liquidate(address user, address liquidator);

    constructor(address _token) {
        token = TokenA(_token);
    }

    // --- Deposit ---
    function deposit(uint256 amount) external {
        require(amount > 0, "Amount must be > 0");

        token.transferFrom(msg.sender, address(this), amount);

        users[msg.sender].deposited += amount;
        users[msg.sender].lastUpdate = block.timestamp;

        emit Deposit(msg.sender, amount);
    }

    // --- Borrow ---
    function borrow(uint256 amount) external {
        User storage user = users[msg.sender];

        require(user.deposited > 0, "No collateral");

        uint256 maxBorrow = (user.deposited * LTV) / 100;
        require(user.borrowed + amount <= maxBorrow, "Exceeds LTV");

        user.borrowed += amount;
        token.transfer(msg.sender, amount);

        emit Borrow(msg.sender, amount);
    }

    // --- Repay ---
    function repay(uint256 amount) external {
        User storage user = users[msg.sender];

        require(user.borrowed > 0, "No debt");

        token.transferFrom(msg.sender, address(this), amount);

        if (amount >= user.borrowed) {
            user.borrowed = 0;
        } else {
            user.borrowed -= amount;
        }

        emit Repay(msg.sender, amount);
    }

    // --- Withdraw ---
    function withdraw(uint256 amount) external {
        User storage user = users[msg.sender];

        require(user.deposited >= amount, "Not enough collateral");

        uint256 remaining = user.deposited - amount;

        uint256 maxBorrow = (remaining * LTV) / 100;
        require(user.borrowed <= maxBorrow, "Health factor < 1");

        user.deposited -= amount;
        token.transfer(msg.sender, amount);

        emit Withdraw(msg.sender, amount);
    }

    // --- Liquidate ---
    function liquidate(address userAddr) external {
        User storage user = users[userAddr];

        uint256 maxBorrow = (user.deposited * LIQ_THRESHOLD) / 100;

        require(user.borrowed > maxBorrow, "Position healthy");

        token.transferFrom(msg.sender, address(this), user.borrowed);

        user.borrowed = 0;
        user.deposited = 0;

        emit Liquidate(userAddr, msg.sender);
    }

    // --- Health Factor ---
    function healthFactor(address userAddr) public view returns (uint256) {
        User memory user = users[userAddr];

        if (user.borrowed == 0) return type(uint256).max;

        return (user.deposited * 100) / user.borrowed;
    }
}