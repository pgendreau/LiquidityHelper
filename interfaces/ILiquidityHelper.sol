// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface ILiquidityHelper {

//  struct UserInfo {
//    uint256 amount; // How many LP tokens the user has provided.
//    uint256 rewardDebt; // Reward debt.
//  }

  struct StakePoolTokenArgs {
    uint256 _poolId;
    uint256 _amount;
  }

  struct UnstakePoolTokenArgs {
    uint256 _poolId;
    uint256 _amount;
  }

  struct SwapTokenForGHSTArgs {
    address _token;
    uint256 _amount;
    uint256 _amountMin;
  }

  struct AddLiquidityArgs {
    address _tokenA;
    address _tokenB;
    uint256 _amountADesired;
    uint256 _amountBDesired;
    uint256 _amountAMin;
    uint256 _amountBMin;
    // bool _legacy;
  }

  struct RemoveLiquidityArgs {
    address _tokenA;
    address _tokenB;
    uint256 _liquidity;
    uint256 _amountAMin;
    uint256 _amountBMin;
    // bool _legacy;
  }
}
