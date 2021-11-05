// SPDX-License-Identifier: gpl-3.0
// Source: https://github.com/curvefi/curve-contract/blob/master/contracts/pools/steth/StableSwapSTETH.vy

pragma solidity ^0.6.12;

interface ICurveStableSwapStEth {
    /**
     * @notice Perform an exchange between two coins
     * @dev Index values can be found via the `coins` public getter method
     * Source: https://github.com/curvefi/curve-contract/blob/master/contracts/pools/steth/StableSwapSTETH.vy#L431
     * @param i Index value for the coin to send
     * @param j Index valie of the coin to recieve
     * @param dx Amount of `i` being exchanged
     * @param min_dy Minimum amount of `j` to receive
     * @return Actual amount of `j` received
     */
    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        // solhint-disable-next-line var-name-mixedcase
        uint256 min_dy
    ) external returns (uint256);
}
