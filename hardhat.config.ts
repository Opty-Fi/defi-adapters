// eslint-disable-next-line @typescript-eslint/ban-ts-comment
// @ts-ignore
import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "solidity-coverage";
import { resolve } from "path";
import { config as dotenvConfig } from "dotenv";
import { HardhatUserConfig, NetworkUserConfig } from "hardhat/types";
import {
  eArbitrumNetwork,
  eAvalancheNetwork,
  eBinanceSmartChainNetwork,
  eEthereumNetwork,
  eFantomNetwork,
  ePolygonNetwork,
  eXDaiNetwork,
} from "./helpers/types";
import { NETWORKS_RPC_URL, buildForkConfig, NETWORKS_CHAIN_ID, NETWORKS_DEFAULT_GAS } from "./helper-hardhat-config";

dotenvConfig({ path: resolve(__dirname, "./.env") });

const SKIP_LOAD = process.env.SKIP_LOAD === "true";
const HARDFORK = "london";
const MNEMONIC_PATH = "m/44'/60'/0'/0";
const MNEMONIC = process.env.MNEMONIC || "";
const NETWORK = process.env.NETWORK || "";

// Prevent to load scripts before compilation and typechain
if (!SKIP_LOAD) {
  require("./tasks/accounts");
  require("./tasks/clean");
  require("./tasks/deployers");
}

const getCommonNetworkConfig = (networkName: string, networkId: number): NetworkUserConfig | undefined => ({
  url: NETWORKS_RPC_URL[networkName],
  hardfork: HARDFORK,
  gasPrice: "auto",
  chainId: networkId,
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
    kovan: getCommonNetworkConfig(eEthereumNetwork.kovan, NETWORKS_CHAIN_ID[eEthereumNetwork.kovan]),
    ropsten: getCommonNetworkConfig(eEthereumNetwork.ropsten, NETWORKS_CHAIN_ID[eEthereumNetwork.ropsten]),
    main: getCommonNetworkConfig(eEthereumNetwork.main, NETWORKS_CHAIN_ID[eEthereumNetwork.main]),
    matic: getCommonNetworkConfig(ePolygonNetwork.matic, NETWORKS_CHAIN_ID[ePolygonNetwork.matic]),
    mumbai: getCommonNetworkConfig(ePolygonNetwork.mumbai, NETWORKS_CHAIN_ID[ePolygonNetwork.mumbai]),
    xdai: getCommonNetworkConfig(eXDaiNetwork.xdai, NETWORKS_CHAIN_ID[eXDaiNetwork.xdai]),
    avalanche: getCommonNetworkConfig(eAvalancheNetwork.avalanche, NETWORKS_CHAIN_ID[eAvalancheNetwork.avalanche]),
    fuji: getCommonNetworkConfig(eAvalancheNetwork.fuji, NETWORKS_CHAIN_ID[eAvalancheNetwork.fuji]),
    arbitrum1: getCommonNetworkConfig(eArbitrumNetwork.arbitrum1, NETWORKS_CHAIN_ID[eArbitrumNetwork.arbitrum1]),
    rinkarby: getCommonNetworkConfig(eArbitrumNetwork.rinkarby, NETWORKS_CHAIN_ID[eArbitrumNetwork.rinkarby]),
    fantom: getCommonNetworkConfig(eFantomNetwork.fantom, NETWORKS_CHAIN_ID[eFantomNetwork.fantom]),
    fantom_test: getCommonNetworkConfig(eFantomNetwork.fantom_test, NETWORKS_CHAIN_ID[eFantomNetwork.fantom_test]),
    bsc: getCommonNetworkConfig(eBinanceSmartChainNetwork.bsc, NETWORKS_CHAIN_ID[eBinanceSmartChainNetwork.bsc]),
    bsc_test: getCommonNetworkConfig(
      eBinanceSmartChainNetwork.bsc_test,
      NETWORKS_CHAIN_ID[eBinanceSmartChainNetwork.bsc_test],
    ),
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
        accountsBalance: "10000000000000000000000",
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
