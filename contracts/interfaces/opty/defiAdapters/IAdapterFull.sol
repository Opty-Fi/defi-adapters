// SPDX-License-Identifier: agpl-3.0

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import { IAdapter } from "./IAdapter.sol";
import { IAdapterBorrow } from "./IAdapterBorrow.sol";
import { IAdapterHarvestReward } from "./IAdapterHarvestReward.sol";
import { IAdapterStaking } from "./IAdapterStaking.sol";
import { IAdapterInvestLimit } from "./IAdapterInvestLimit.sol";

/**
 * @title Interface containing all functions from different DeFi adapter interfaces
 * @author Opty.fi
 * @notice Interface of the DeFi protocol adapter to be used where all DeFi adapter features are required
 * @dev Abstraction layer to different tokenization contracts like StrategyManager etc.
 * It can also be used as an interface layer for any new DeFi protocol. It contains all the
 * functions being used in all the DeFi adapters from different interfaces
 */

/* solhint-disable no-empty-blocks */
interface IAdapterFull is IAdapter, IAdapterBorrow, IAdapterHarvestReward, IAdapterStaking, IAdapterInvestLimit {

}
/* solhint-disable no-empty-blocks */
