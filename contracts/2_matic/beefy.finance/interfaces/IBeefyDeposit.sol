// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IBeefyDeposit {
    function deposit(uint256 _amount) external; //fine

    function withdraw(uint256 _shares) external; //fine

    function getPricePerFullShare() external view returns (uint256); //fine

    function want() external view returns (address); //want() replaces underlying() from Harvest

    function decimals() external view returns (uint256); //fine

    function balance() external view returns (uint256); //replaces underlyingBalanceWithInvestment()

    function balanceOf(address account) external view returns (uint256); //fine
}
