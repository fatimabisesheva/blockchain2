// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {MyToken} from "../src/MyToken.sol";

contract MyTokenTest is Test {
    MyToken token;

    function setUp() public {
        token = new MyToken();
    }

    function testMint() public {
        token.mint(address(this), 100);
        assertEq(token.balanceOf(address(this)), 100);
    }

    function testTransfer() public {
        token.mint(address(this), 100);
        assertTrue(token.transfer(address(1), 50));
        assertEq(token.balanceOf(address(1)), 50);
    }

    function testTransferFail() public {
        vm.expectRevert();
        token.transfer(address(1), 50);
    }

    function testApprove() public {
        token.approve(address(1), 100);
        assertEq(token.allowance(address(this), address(1)), 100);
    }

    function testTransferFrom() public {
        token.mint(address(this), 100);
        token.approve(address(1), 50);

        vm.prank(address(1));
        assertTrue(token.transferFrom(address(this), address(2), 50));

        assertEq(token.balanceOf(address(2)), 50);
    }

    function testFuzzTransfer(address to, uint256 amount) public {
        // игнорируем нулевой адрес
        vm.assume(to != address(0));
        // выдаём токены
        token.mint(address(this), amount);
        // переводим токены
        assertTrue(token.transfer(to, amount));
        // проверяем баланс
        assertEq(token.balanceOf(to), amount);
    }

    function invariantTotalSupply() public view {
        uint256 sum = 0;
        sum += token.balanceOf(address(this));
        sum += token.balanceOf(address(1));
        sum += token.balanceOf(address(2));
        // сумма балансов ≤ totalSupply
        assertLe(sum, token.totalSupply());
    }

    function invariantNoBalanceExceedsTotal() public view {
        assertLe(token.balanceOf(address(this)), token.totalSupply());
        assertLe(token.balanceOf(address(1)), token.totalSupply());
        assertLe(token.balanceOf(address(2)), token.totalSupply());
    }
}