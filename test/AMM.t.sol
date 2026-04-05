// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/AMM.sol";
import "../src/TokenA.sol";
import "../src/TokenB.sol";
import "../src/LPToken.sol";

contract AMMTest is Test {
    TokenA tokenA;
    TokenB tokenB;
    LPToken lp;
    AMM amm;

    address user1 = address(0x1);
    address user2 = address(0x2);

    function setUp() public {
        // Deploy tokens
        tokenA = new TokenA();
        tokenB = new TokenB();
        lp = new LPToken();

        // Deploy AMM
        amm = new AMM(address(tokenA), address(tokenB));

        // Mint tokens to users
        tokenA.mint(user1, 1e21); // 1000 tokenA
        tokenB.mint(user1, 1e21); // 1000 tokenB
        tokenA.mint(user2, 1e21);
        tokenB.mint(user2, 1e21);

        // Approve AMM to spend tokens
        vm.startPrank(user1);
        tokenA.approve(address(amm), type(uint256).max);
        tokenB.approve(address(amm), type(uint256).max);
        vm.stopPrank();

        vm.startPrank(user2);
        tokenA.approve(address(amm), type(uint256).max);
        tokenB.approve(address(amm), type(uint256).max);
        vm.stopPrank();
    }

    function testAddLiquidity() public {
        vm.startPrank(user1);
        uint256 lpMinted = amm.addLiquidity(1e20, 1e20, 0, type(uint256).max);
        assertGt(lpMinted, 0);
        vm.stopPrank();
    }

    function testRemoveLiquidity() public {
        vm.startPrank(user1);
        uint256 lpMinted = amm.addLiquidity(1e20, 1e20, 0, type(uint256).max);
        (uint256 aOut, uint256 bOut) = amm.removeLiquidity(lpMinted / 2);
        assertEq(aOut, 5e19);
        assertEq(bOut, 5e19);
        vm.stopPrank();
    }

    function testSwapAToB() public {
        vm.startPrank(user1);
        amm.addLiquidity(1e20, 1e20, 0, type(uint256).max);

        uint256 amountOut = amm.getAmountOut(1e19, true);
        uint256 out = amm.swap(1e19, amountOut, true);

        assertEq(out, amountOut);
        vm.stopPrank();
    }

    function testSwapBToA() public {
        vm.startPrank(user1);
        amm.addLiquidity(1e20, 1e20, 0, type(uint256).max);

        uint256 amountOut = amm.getAmountOut(1e19, false);
        uint256 out = amm.swap(1e19, amountOut, false);

        assertEq(out, amountOut);
        vm.stopPrank();
    }

    function testSlippageRevert() public {
        vm.startPrank(user1);
        amm.addLiquidity(1e20, 1e20, 0, type(uint256).max);

        uint256 tooHighMin = 2e20; // заведомо высокая сумма
        vm.expectRevert("Slippage too high");
        amm.swap(1e19, tooHighMin, true);
        vm.stopPrank();
    }
}