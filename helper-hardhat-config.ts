import { HardhatNetworkForkingUserConfig } from "hardhat/types";
import { resolve } from "path";
import { config as dotenvConfig } from "dotenv";
import {
  eEthereumNetwork,
  ePolygonNetwork,
  eXDaiNetwork,
  eAvalancheNetwork,
  eArbitrumNetwork,
  eFantomNetwork,
  eBinanceSmartChainNetwork,
} from "./helpers/types";

dotenvConfig({ path: resolve(__dirname, "./.env") });

const KOVAN_RPC_URL = process.env.KOVAN_RPC_URL || "";
const ROPSTEN_RPC_URL = process.env.ROPSTEN_RPC_URL || "";
const MAIN_RPC_URL = process.env.MAIN_RPC_URL || "";
const MUMBAI_RPC_URL = process.env.MUMBAI_RPC_URL || "";
const MATIC_RPC_URL = process.env.MATIC_RPC_URL || "";
const XDAI_RPC_URL = process.env.XDAI_RPC_URL || "";
const AVALANCHE_RPC_URL = process.env.AVALANCHE_RPC_URL || "";
const FUJI_RPC_URL = process.env.FUJI_RPC_URL || "";
const ARBITRUM1_RPC_URL = process.env.ARBITRUM1_RPC_URL || "";
const RINKARBY_RPC_URL = process.env.RINKARBY_RPC_URL || "";
const FANTOM_RPC_URL = process.env.FANTOM_RPC_URL || "";
const FANTOM_TEST_RPC_URL = process.env.FANTOM_TEST_RPC_URL || "";
const BSC_RPC_URL = process.env.BSC_RPC_URL || "";
const BSC_TEST_RPC_URL = process.env.BSC_TEST_RPC_URL || "";
const FORK = process.env.FORK || "";
const FORK_BLOCK_NUMBER = process.env.FORK_BLOCK_NUMBER ? parseInt(process.env.FORK_BLOCK_NUMBER) : 0;

const GWEI = 1000 * 1000 * 1000;

export const NETWORKS_RPC_URL = {
  kovan: KOVAN_RPC_URL,
  ropsten: ROPSTEN_RPC_URL,
  main: MAIN_RPC_URL,
  hardhat: "http://localhost:8545",
  mumbai: MUMBAI_RPC_URL,
  matic: MATIC_RPC_URL,
  xdai: XDAI_RPC_URL,
  avalanche: AVALANCHE_RPC_URL,
  eAvalancheNetwork: FUJI_RPC_URL,
  arbitrum1: ARBITRUM1_RPC_URL,
  rinkarby: RINKARBY_RPC_URL,
  fantom: FANTOM_RPC_URL,
  fantom_test: FANTOM_TEST_RPC_URL,
  bsc: BSC_RPC_URL,
  bsc_test: BSC_TEST_RPC_URL,
};

export const NETWORKS_DEFAULT_GAS = {
  [eEthereumNetwork.kovan]: 1 * GWEI,
  [eEthereumNetwork.ropsten]: 65 * GWEI,
  [eEthereumNetwork.main]: "auto",
  [eEthereumNetwork.hardhat]: 65 * GWEI,
  [ePolygonNetwork.mumbai]: 1 * GWEI,
  [ePolygonNetwork.matic]: "auto",
  [eXDaiNetwork.xdai]: 1 * GWEI,
  [eAvalancheNetwork.avalanche]: 225 * GWEI,
  [eAvalancheNetwork.fuji]: 85 * GWEI,
  [eArbitrumNetwork.arbitrum1]: 1 * GWEI,
  [eArbitrumNetwork.rinkarby]: 1 * GWEI,
  [eFantomNetwork.fantom]: 1 * GWEI,
  [eFantomNetwork.fantom_test]: 1 * GWEI,
  [eBinanceSmartChainNetwork.bsc]: 1 * GWEI,
  [eBinanceSmartChainNetwork.bsc_test]: 1 * GWEI,
};

export const NETWORKS_CHAIN_ID = {
  kovan: 42,
  ropsten: 3,
  main: 1,
  hardhat: 31337,
  mumbai: 80001,
  matic: 137,
  xdai: 100,
  avalanche: 43114,
  fuji: 43113,
  arbitrum1: 42161,
  rinkarby: 421611,
  fantom: 250,
  fantom_test: 4002,
  bsc: 56,
  bsc_test: 97,
};

export const BLOCK_TO_FORK = {
  main: 13270269,
  kovan: undefined,
  ropsten: undefined,
  hardhat: undefined,
  mumbai: undefined,
  matic: 19416260,
  xdai: undefined,
  avalanche: undefined,
  fuji: undefined,
};

export const buildForkConfig = (): HardhatNetworkForkingUserConfig | undefined => {
  if (FORK) {
    const forkMode: HardhatNetworkForkingUserConfig = {
      url: NETWORKS_RPC_URL[FORK],
    };
    if (FORK_BLOCK_NUMBER || BLOCK_TO_FORK[FORK]) {
      forkMode.blockNumber = FORK_BLOCK_NUMBER || BLOCK_TO_FORK[FORK];
    }

    return forkMode;
  }
  return undefined;
};
