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
  eOptimisticEthereumNetwork,
  iParamsPerNetwork,
} from "./helpers/types";

dotenvConfig({ path: resolve(__dirname, "./.env") });

const KOVAN_RPC_URL = process.env.KOVAN_RPC_URL || "";
const ROPSTEN_RPC_URL = process.env.ROPSTEN_RPC_URL || "";
const MAIN_RPC_URL = process.env.MAIN_RPC_URL || "";
const RINKEBY_RPC_URL = process.env.RINKEBY_RPC_URL || "";
const GOERLI_RPC_URL = process.env.GOERLI_RPC_URL || "";
const MUMBAI_RPC_URL = process.env.MUMBAI_RPC_URL || "";
const MATIC_RPC_URL = process.env.MATIC_RPC_URL || "";
const XDAI_RPC_URL = process.env.XDAI_RPC_URL || "";
const AVALANCHE_RPC_URL = process.env.AVALANCHE_RPC_URL || "";
const FUJI_RPC_URL = process.env.FUJI_RPC_URL || "";
const ARBITRUM1_RPC_URL = process.env.ARBITRUM1_RPC_URL || "";
const RINKEBY_ARBITRUM1_RPC_URL = process.env.RINKEBY_ARBITRUM1_RPC_URL || "";
const FANTOM_RPC_URL = process.env.FANTOM_RPC_URL || "";
const FANTOM_TEST_RPC_URL = process.env.FANTOM_TEST_RPC_URL || "";
const BSC_RPC_URL = process.env.BSC_RPC_URL || "";
const BSC_TEST_RPC_URL = process.env.BSC_TEST_RPC_URL || "";
const OETHEREUM_RPC_URL = process.env.OETHEREUM_RPC_URL || "";
const KOVAN_OETHEREUM_RPC_URL = process.env.KOVAN_OETHEREUM_RPC_URL || "";
const GOERLI_OETHEREUM_RPC_URL = process.env.GOERLI_OETHEREUM_RPC_URL || "";
const FORK = process.env.FORK || "";
const FORK_BLOCK_NUMBER = process.env.FORK_BLOCK_NUMBER ? parseInt(process.env.FORK_BLOCK_NUMBER) : 0;

const GWEI = 1000 * 1000 * 1000;

export const NETWORKS_RPC_URL: iParamsPerNetwork<string> = {
  [eEthereumNetwork.kovan]: KOVAN_RPC_URL,
  [eEthereumNetwork.ropsten]: ROPSTEN_RPC_URL,
  [eEthereumNetwork.main]: MAIN_RPC_URL,
  [eEthereumNetwork.rinkeby]: RINKEBY_RPC_URL,
  [eEthereumNetwork.goerli]: GOERLI_RPC_URL,
  [eEthereumNetwork.hardhat]: "http://localhost:8545",
  [ePolygonNetwork.mumbai]: MUMBAI_RPC_URL,
  [ePolygonNetwork.matic]: MATIC_RPC_URL,
  [eXDaiNetwork.xdai]: XDAI_RPC_URL,
  [eAvalancheNetwork.avalanche]: AVALANCHE_RPC_URL,
  [eAvalancheNetwork.fuji]: FUJI_RPC_URL,
  [eArbitrumNetwork.arbitrum1]: ARBITRUM1_RPC_URL,
  [eArbitrumNetwork.rinkeby_arbitrum1]: RINKEBY_ARBITRUM1_RPC_URL,
  [eFantomNetwork.fantom]: FANTOM_RPC_URL,
  [eFantomNetwork.fantom_test]: FANTOM_TEST_RPC_URL,
  [eBinanceSmartChainNetwork.bsc]: BSC_RPC_URL,
  [eBinanceSmartChainNetwork.bsc_test]: BSC_TEST_RPC_URL,
  [eOptimisticEthereumNetwork.oethereum]: OETHEREUM_RPC_URL,
  [eOptimisticEthereumNetwork.kovan_oethereum]: KOVAN_OETHEREUM_RPC_URL,
  [eOptimisticEthereumNetwork.goerli_oethereum]: GOERLI_OETHEREUM_RPC_URL,
};

export const NETWORKS_DEFAULT_GAS: iParamsPerNetwork<number | "auto"> = {
  [eEthereumNetwork.kovan]: 1 * GWEI,
  [eEthereumNetwork.ropsten]: 65 * GWEI,
  [eEthereumNetwork.main]: "auto",
  [eEthereumNetwork.hardhat]: 65 * GWEI,
  [eEthereumNetwork.rinkeby]: 65 * GWEI,
  [eEthereumNetwork.goerli]: 65 * GWEI,
  [ePolygonNetwork.mumbai]: 1 * GWEI,
  [ePolygonNetwork.matic]: "auto",
  [eXDaiNetwork.xdai]: 1 * GWEI,
  [eAvalancheNetwork.avalanche]: 225 * GWEI,
  [eAvalancheNetwork.fuji]: 85 * GWEI,
  [eArbitrumNetwork.arbitrum1]: 1 * GWEI,
  [eArbitrumNetwork.rinkeby_arbitrum1]: 1 * GWEI,
  [eFantomNetwork.fantom]: 1 * GWEI,
  [eFantomNetwork.fantom_test]: 1 * GWEI,
  [eBinanceSmartChainNetwork.bsc]: 1 * GWEI,
  [eBinanceSmartChainNetwork.bsc_test]: 1 * GWEI,
  [eOptimisticEthereumNetwork.oethereum]: 1 * GWEI,
  [eOptimisticEthereumNetwork.kovan_oethereum]: 1 * GWEI,
  [eOptimisticEthereumNetwork.goerli_oethereum]: 1 * GWEI,
};

export const NETWORKS_CHAIN_ID: iParamsPerNetwork<number | "auto"> = {
  [eEthereumNetwork.kovan]: 42,
  [eEthereumNetwork.ropsten]: 3,
  [eEthereumNetwork.main]: 1,
  [eEthereumNetwork.rinkeby]: 4,
  [eEthereumNetwork.goerli]: 5,
  [eEthereumNetwork.hardhat]: 31337,
  [ePolygonNetwork.mumbai]: 80001,
  [ePolygonNetwork.matic]: 137,
  [eXDaiNetwork.xdai]: 100,
  [eAvalancheNetwork.avalanche]: 43114,
  [eAvalancheNetwork.fuji]: 43113,
  [eArbitrumNetwork.arbitrum1]: 42161,
  [eArbitrumNetwork.rinkeby_arbitrum1]: 421611,
  [eFantomNetwork.fantom]: 250,
  [eFantomNetwork.fantom_test]: 4002,
  [eBinanceSmartChainNetwork.bsc]: 56,
  [eBinanceSmartChainNetwork.bsc_test]: 97,
  [eOptimisticEthereumNetwork.oethereum]: 10,
  [eOptimisticEthereumNetwork.kovan_oethereum]: 69,
  [eOptimisticEthereumNetwork.goerli_oethereum]: 420,
};

export const BLOCK_TO_FORK = {
  [eEthereumNetwork.main]: 13703745,
  [eEthereumNetwork.kovan]: undefined,
  [eEthereumNetwork.ropsten]: undefined,
  [eEthereumNetwork.rinkeby]: undefined,
  [eEthereumNetwork.goerli]: undefined,
  [eEthereumNetwork.hardhat]: undefined,
  [ePolygonNetwork.mumbai]: undefined,
  [ePolygonNetwork.matic]: 21435710,
  [eXDaiNetwork.xdai]: undefined,
  [eAvalancheNetwork.avalanche]: undefined,
  [eAvalancheNetwork.fuji]: undefined,
  [eArbitrumNetwork.arbitrum1]: undefined,
  [eArbitrumNetwork.rinkeby_arbitrum1]: undefined,
  [eFantomNetwork.fantom]: undefined,
  [eFantomNetwork.fantom_test]: undefined,
  [eBinanceSmartChainNetwork.bsc]: undefined,
  [eBinanceSmartChainNetwork.bsc_test]: undefined,
  [eOptimisticEthereumNetwork.oethereum]: undefined,
  [eOptimisticEthereumNetwork.kovan_oethereum]: undefined,
  [eOptimisticEthereumNetwork.goerli_oethereum]: undefined,
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
