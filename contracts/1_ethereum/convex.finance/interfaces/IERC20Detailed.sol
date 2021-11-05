// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract IERC20Detailed is IERC20 {
    function decimals() public view virtual returns (uint256);
}
