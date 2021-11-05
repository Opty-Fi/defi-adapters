// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

// https://github.com/convex-eth/platform/blob/main/contracts/contracts/Booster.sol
interface IConvexDeposit {
    struct PoolInfo {
        address lptoken;
        address token;
        address gauge;
        address crvRewards;
        address stash;
        bool shutdown;
    }

    function deposit(
        uint256 _pid,
        uint256 _amount,
        bool _stake
    ) external returns (bool);

    function poolInfo(uint256 _pid) external view returns (PoolInfo memory);

    function staker() external view returns (address);

    function withdraw(uint256 _pid, uint256 _amount) external returns (bool);
}
