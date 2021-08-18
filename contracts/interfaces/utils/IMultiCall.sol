// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/**
 * @title Interface for MultiCall Contract
 * @author Opty.fi
 * @dev Interface for functions to batch together multi calls
 */
interface IMultiCall {
    /**
     * @notice Executes any functionlaity and check if it is working or not
     * @dev Execute the code and revert with error message if code provided is incorrect
     * @param _code Encoded data in bytes which acts as code to execute
     * @param _errorMsg Error message to throw when code execution call fails
     */
    function executeCode(bytes calldata _code, string calldata _errorMsg) external;

    /**
     * @notice Executes bunch of functionlaities and check if they are working or not
     * @dev Execute the codes array and revert with error message if code provided is incorrect
     * @param _codes Array of encoded data in bytes which acts as code to execute
     * @param _errorMsg Error message to throw when code execution call fails
     */
    function executeCodes(bytes[] calldata _codes, string calldata _errorMsg) external;
}
