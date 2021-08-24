// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface IHarvestVault {
    function governance() external view returns (address);

    function controller() external view returns (address);
}
