// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IMasterChef {
    
    struct UserInfo {
      uint256 amount; // How many LP tokens the user has provided.
      uint256 rewardDebt; // Reward debt.
    }

    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function harvest(uint256 _pid) external;
    function batchHarvest(uint256[] memory _pids) external;
    function userInfo(uint256 _pid, address _user)
        external
        view
        returns
    (
        UserInfo memory ui
    );
    
}
