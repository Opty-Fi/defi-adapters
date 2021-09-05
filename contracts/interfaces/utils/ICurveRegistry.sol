// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

interface ICurveRegistry {
    /* solhint-disable func-name-mixedcase */
    /**
     * @notice Get the number of coins and underlying coins within a pool.
     * @dev https://curve.readthedocs.io/registry-registry.html#Registry.get_n_coins
     */
    function get_n_coins(address _pool) external view returns (uint256[2] memory);

    /**
     * @notice Get a list of the swappable underlying coins within a pool.
     * @dev https://curve.readthedocs.io/registry-registry.html#Registry.get_underlying_coins
     */
    function get_underlying_coins(address _pool) external view returns (address[8] memory);
    /* solhint-enable func-name-mixedcase */
}
