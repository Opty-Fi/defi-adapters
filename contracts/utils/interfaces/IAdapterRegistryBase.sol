// SPDX-License-Identifier: MIT

pragma solidity >0.6.0 <0.9.0;

/**
 * @title Interface for AdapterRegistryBase Contract
 * @author Opty.fi
 * @notice Interface for
 */
interface IAdapterRegistryBase {
    /**
     * @notice Retrieve the RiskOperator address
     * @return Returns the RiskOperator address
     */
    function getRiskOperator() external view returns (address);

    /**
     * @notice Retrieve the Operator address
     * @return Returns the Operator address
     */
    function getOperator() external view returns (address);
}
