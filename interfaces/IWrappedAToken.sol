// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IWrappedAToken {
    function enterWithUnderlying(uint256 assets) external returns (uint256);
}
