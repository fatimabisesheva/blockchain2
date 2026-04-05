// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/LendingPool.sol";
import "../src/TokenA.sol";

contract LendingPoolTest is Test {
    LendingPool pool;
    TokenA token;

    address user = address(1);

    function setUp() public {
        token = new TokenA();
        pool = new LendingPool(address(token));

        token.mint(user, 1e21);

        vm.startPrank(user);
        token.approve(address(pool), type(uint256).max);
        vm.stopPrank();
    }

    function testDeposit() public {
        vm.prank(user);
        pool.deposit(1e20);
    }

    function testWithdraw() public {
        vm.startPrank(user);
        pool.deposit(1e20);
        pool.withdraw(5e19);
        vm.stopPrank();
    }

    function testBorrowWithinLimit() public {
        vm.startPrank(user);
        pool.deposit(1e20);
        pool.borrow(7e19); // 70%
        vm.stopPrank();
    }

    function testBorrowExceedsLimit() public {
        vm.startPrank(user);
        pool.deposit(1e20);

        vm.expectRevert("Exceeds LTV");
        pool.borrow(8e19); // 80%
        vm.stopPrank();
    }

    function testRepayPartial() public {
        vm.startPrank(user);
        pool.deposit(1e20);
        pool.borrow(5e19);
        pool.repay(2e19);
        vm.stopPrank();
    }

    function testRepayFull() public {
        vm.startPrank(user);
        pool.deposit(1e20);
        pool.borrow(5e19);
        pool.repay(5e19);
        vm.stopPrank();
    }

    function testCannotBorrowWithoutCollateral() public {
        vm.prank(user);
        vm.expectRevert("No collateral");
        pool.borrow(1e18);
    }

    function testWithdrawWithDebtFail() public {
        vm.startPrank(user);
        pool.deposit(1e20);
        pool.borrow(7e19);

        vm.expectRevert("Health factor < 1");
        pool.withdraw(5e19);
        vm.stopPrank();
    }

    function testLiquidation() public {
    token.mint(address(this), 100 ether);
    token.approve(address(pool), 100 ether);

    pool.deposit(100 ether);

    // 👇 делаем позицию плохой
    pool.borrow(80 ether);

    pool.liquidate(address(this));

    uint256 health = pool.healthFactor(address(this));
    assertTrue(health >= 1);
}
    function testHealthFactor() public {
        vm.startPrank(user);
        pool.deposit(1e20);
        pool.borrow(5e19);

        uint256 hf = pool.healthFactor(user);
        assertGt(hf, 100);
        vm.stopPrank();
    }
}