// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./TokenA.sol";
import "./TokenB.sol";
import "./LPToken.sol";

contract AMM {
    TokenA public tokenA;
    TokenB public tokenB;
    LPToken public lpToken;

    uint256 public reserveA;
    uint256 public reserveB;

    uint256 public constant FEE_NUMERATOR = 997; // 0.3% fee
    uint256 public constant FEE_DENOMINATOR = 1000;

    event LiquidityAdded(address indexed user, uint256 amountA, uint256 amountB, uint256 lpMinted);
    event LiquidityRemoved(address indexed user, uint256 amountA, uint256 amountB, uint256 lpBurned);
    event Swap(address indexed user, address tokenIn, uint256 amountIn, address tokenOut, uint256 amountOut);

    constructor(address _tokenA, address _tokenB) {
        tokenA = TokenA(_tokenA);
        tokenB = TokenB(_tokenB);
        lpToken = new LPToken();
    }

    function addLiquidity(uint256 amountA, uint256 amountB, uint256 minLP, uint256 maxLP) external returns (uint256) {
        require(amountA > 0 && amountB > 0, "Amounts must be > 0");

        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);

        uint256 lpMinted;
        if (lpToken.totalSupply() == 0) {
            lpMinted = sqrt(amountA * amountB);
        } else {
            lpMinted = min((amountA * lpToken.totalSupply()) / reserveA,
                           (amountB * lpToken.totalSupply()) / reserveB);
        }

        require(lpMinted >= minLP, "Slippage too high");
        require(lpMinted <= maxLP, "Slippage too high");

        reserveA += amountA;
        reserveB += amountB;

        lpToken.mint(msg.sender, lpMinted);
        emit LiquidityAdded(msg.sender, amountA, amountB, lpMinted);
        return lpMinted;
    }

    function removeLiquidity(uint256 lpAmount) external returns (uint256, uint256) {
        uint256 totalLP = lpToken.totalSupply();
        uint256 amountA = (lpAmount * reserveA) / totalLP;
        uint256 amountB = (lpAmount * reserveB) / totalLP;

        lpToken.burn(msg.sender, lpAmount);
        reserveA -= amountA;
        reserveB -= amountB;

        tokenA.transfer(msg.sender, amountA);
        tokenB.transfer(msg.sender, amountB);

        emit LiquidityRemoved(msg.sender, amountA, amountB, lpAmount);
        return (amountA, amountB);
    }

    function getAmountOut(uint256 amountIn, bool isAToB) public view returns (uint256) {
        uint256 inputReserve = isAToB ? reserveA : reserveB;
        uint256 outputReserve = isAToB ? reserveB : reserveA;

        uint256 amountInWithFee = amountIn * FEE_NUMERATOR / FEE_DENOMINATOR;
        uint256 numerator = amountInWithFee * outputReserve;
        uint256 denominator = inputReserve + amountInWithFee;
        return numerator / denominator;
    }

    function swap(uint256 amountIn, uint256 minOut, bool isAToB) external returns (uint256) {
        require(amountIn > 0, "AmountIn must be > 0");

        uint256 amountOut = getAmountOut(amountIn, isAToB);
        require(amountOut >= minOut, "Slippage too high");

        if (isAToB) {
            tokenA.transferFrom(msg.sender, address(this), amountIn);
            tokenB.transfer(msg.sender, amountOut);
            reserveA += amountIn;
            reserveB -= amountOut;
        } else {
            tokenB.transferFrom(msg.sender, address(this), amountIn);
            tokenA.transfer(msg.sender, amountOut);
            reserveB += amountIn;
            reserveA -= amountOut;
        }

        emit Swap(msg.sender, isAToB ? address(tokenA) : address(tokenB), amountIn,
                    isAToB ? address(tokenB) : address(tokenA), amountOut);
        return amountOut;
    }

    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function min(uint x, uint y) internal pure returns (uint) {
        return x <= y ? x : y;
    }
}