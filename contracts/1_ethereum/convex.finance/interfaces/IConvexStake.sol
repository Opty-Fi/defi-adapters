// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

// https://github.com/convex-eth/platform/blob/main/contracts/contracts/BaseRewardPool.sol
interface IConvexStake {
    function balanceOf(address _holder) external view returns (uint256);

    function earned(address _holder) external view returns (uint256);

    function extraRewards(uint256 _index) external view returns (address);

    function extraRewardsLength() external view returns (uint256);

    function pid() external view returns (uint256);

    function rewardToken() external view returns (address);

    function stake(uint256 _amount) external returns (bool);
}
