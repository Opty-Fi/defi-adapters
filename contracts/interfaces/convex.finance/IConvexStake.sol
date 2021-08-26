// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

// https://github.com/convex-eth/platform/blob/main/contracts/contracts/BaseRewardPool.sol
interface IConvexStake {
    function stake(uint256 _amount) external returns (bool);

    function earned(address _holder) external view returns (uint256);

    function balanceOf(address _holder) external view returns (uint256);

    function pid() external view returns (uint256);

    function rewardToken() external view returns (address);
}
