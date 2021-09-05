// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface ICurvePoolInfo {
    /* solhint-disable func-name-mixedcase, var-name-mixedcase */
    struct PoolCoins {
        address[8] coins;
        address[8] underlying_coins;
        uint256[8] decimals;
        uint256[8] underlying_decimals;
    }

    /**
     * @notice Get information about the coins in a pool.
     * @dev https://curve.readthedocs.io/registry-pool-info.html?highlight=get_pool_coins#PoolInfo.get_pool_coins
     */
    function get_pool_coins(address _pool) external view returns (PoolCoins memory);
    /* solhint-enable func-name-mixedcase, var-name-mixedcase */
}
