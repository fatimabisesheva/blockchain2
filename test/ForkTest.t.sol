// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
}

contract ForkTest is Test {
    string RPC = "https://eth-mainnet.g.alchemy.com/v2/7Thqr3j-T5vLJ9wKAPZ6Y"; // твой URL

    function setUp() public {
        // Создаём fork Ethereum mainnet
        vm.createSelectFork(RPC);  // теперь не сохраняем в forkId
        vm.rollFork(block.number);  // ставим текущий блок
    }

    function testReadUSDC() public {
        address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        uint256 total = IERC20(USDC).totalSupply();
        emit log_uint(total); // выведет totalSupply USDC
    }

    function testReadWETHBalance() public {
        address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        uint256 balance = IERC20(WETH).balanceOf(address(this));
        emit log_uint(balance); // выведет баланс WETH текущего контракта
    }
}