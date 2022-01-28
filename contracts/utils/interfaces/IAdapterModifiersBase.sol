// SPDX-License-Identifier: MIT

pragma solidity >0.6.0 <0.9.0;

/**
 * @title Interface for AdapterModifiersBase Contract
 * @author Opty.fi
 * @notice Interface used to set the registry contract address
 */
interface IAdapterModifiersBase {
    /**
     * @notice Sets the regsitry contract address
     * @param _registry address of registry contract
     */
    function setRegistry(address _registry) external;
}
