// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IHarvestFarm {
    function stake(uint256 _value) external;

    function exit() external;

    function earned(address _holder) external view returns (uint256);

    function balanceOf(address _holder) external view returns (uint256);
}
