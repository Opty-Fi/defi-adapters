// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-ignore
import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import { config as dotenvConfig } from "dotenv";
import { HardhatUserConfig } from "hardhat/config";
import { resolve } from "path";
import "solidity-coverage";
import { resolve, join } from "path";
import fs from "fs";
import { config as dotenvConfig } from "dotenv";
import { HardhatUserConfig, NetworkUserConfig } from "hardhat/types";
import {
  eArbitrumNetwork,
  eAvalancheNetwork,
  eBinanceSmartChainNetwork,
  eEthereumNetwork,
  eFantomNetwork,
  eNetwork,
  eOptimisticEthereumNetwork,
  ePolygonNetwork,
  eXDaiNetwork,
} from "./helpers/types";
import { NETWORKS_RPC_URL, buildForkConfig, NETWORKS_CHAIN_ID, NETWORKS_DEFAULT_GAS } from "./helper-hardhat-config";

dotenvConfig({ path: resolve(__dirname, "./.env") });

const SKIP_LOAD = process.env.SKIP_LOAD === "true";
const HARDFORK = "london";
const MNEMONIC_PATH = "m/44'/60'/0'/0";
const MNEMONIC = process.env.MNEMONIC || "";
const NETWORK = process.env.NETWORK || "hardhat";

// Prevent to load scripts before compilation and typechain
if (!SKIP_LOAD) {
  ["1_ethereum", "2_matic", "3_avalanche", "4_arbitrum", "5_xdai", "6_fantom", "7_bsc", "8_oethereum"].forEach(
    folder => {
      const tasksPath = join(__dirname, "tasks", folder);
      fs.readdirSync(tasksPath)
        .filter(pth => pth.includes(".ts"))
        .forEach(task => {
          require(`${tasksPath}/${task}`);
        });
    },
  );
  require("./tasks/accounts");
  require("./tasks/clean");
}

const getCommonNetworkConfig = (networkName: eNetwork): NetworkUserConfig | undefined => ({
  url: NETWORKS_RPC_URL[networkName],
  hardfork: HARDFORK,
  gasPrice: "auto",
  chainId: NETWORKS_CHAIN_ID[networkName],
  initialBaseFeePerGas: 1_00_000_000,
  accounts: {
    mnemonic: MNEMONIC,
    path: MNEMONIC_PATH,
    initialIndex: 0,
    count: 20,
    accountsBalance: "10000000000000000000000",
  },
});

const config: HardhatUserConfig = {
  networks: {
    kovan: getCommonNetworkConfig(eEthereumNetwork.kovan),
    ropsten: getCommonNetworkConfig(eEthereumNetwork.ropsten),
    main: getCommonNetworkConfig(eEthereumNetwork.main),
    rinkeby: getCommonNetworkConfig(eEthereumNetwork.main),
    goerli: getCommonNetworkConfig(eEthereumNetwork.main),
    matic: getCommonNetworkConfig(ePolygonNetwork.matic),
    mumbai: getCommonNetworkConfig(ePolygonNetwork.mumbai),
    xdai: getCommonNetworkConfig(eXDaiNetwork.xdai),
    avalanche: getCommonNetworkConfig(eAvalancheNetwork.avalanche),
    fuji: getCommonNetworkConfig(eAvalancheNetwork.fuji),
    arbitrum1: getCommonNetworkConfig(eArbitrumNetwork.arbitrum1),
    rinkeby_arbitrum1: getCommonNetworkConfig(eArbitrumNetwork.rinkeby_arbitrum1),
    fantom: getCommonNetworkConfig(eFantomNetwork.fantom),
    fantom_test: getCommonNetworkConfig(eFantomNetwork.fantom_test),
    bsc: getCommonNetworkConfig(eBinanceSmartChainNetwork.bsc),
    bsc_test: getCommonNetworkConfig(eBinanceSmartChainNetwork.bsc_test),
    oethereum: getCommonNetworkConfig(eOptimisticEthereumNetwork.oethereum),
    kovan_oethereum: getCommonNetworkConfig(eOptimisticEthereumNetwork.kovan_oethereum),
    goerli_oethereum: getCommonNetworkConfig(eOptimisticEthereumNetwork.goerli_oethereum),
    hardhat: {
      hardfork: "london",
      gasPrice: NETWORKS_DEFAULT_GAS[NETWORK],
      chainId: NETWORKS_CHAIN_ID[NETWORK],
      initialBaseFeePerGas: 1_00_000_000,
      accounts: {
        initialIndex: 0,
        count: 20,
        mnemonic: MNEMONIC,
        path: MNEMONIC_PATH,
        accountsBalance: "100000000000000000000000",
      },
      forking: buildForkConfig(),
    },
  },
  solidity: {
    version: "0.6.12",
    settings: {
      metadata: {
        // Not including the metadata hash
        // https://github.com/paulrberg/solidity-template/issues/31
        bytecodeHash: "none",
      },
      // Disable the optimizer when debugging
      // https://hardhat.org/hardhat-network/#solidity-optimizer-support
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  paths: {
    artifacts: "./artifacts",
    cache: "./cache",
    sources: "./contracts",
    tests: "./test",
  },
  typechain: {
    outDir: "typechain",
    target: "ethers-v5",
  },
  mocha: {
    timeout: 0,
  },
};

export default config;
