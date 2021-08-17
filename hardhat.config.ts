import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "hardhat-gas-reporter";
import "solidity-coverage";

import "./tasks/accounts";
import "./tasks/clean";
import "./tasks/deployers";

import { resolve } from "path";

import { config as dotenvConfig } from "dotenv";
import { HardhatUserConfig } from "hardhat/config";

dotenvConfig({ path: resolve(__dirname, "./.env") });

const chainIds = {
  hardhat: 31337,
};

/////////////////////////////////////////////////////////////////
/// Ensure that we have all the environment variables we need.///
/////////////////////////////////////////////////////////////////

// Ensure that we have mnemonic phrase set an environment variable
const mnemonic: string | undefined = process.env.MNEMONIC;
if (!mnemonic) {
  throw new Error("Please set your MNEMONIC in a .env file");
}
// Ensure that we have archive mainnet node URL set an environment variable
//
const archiveMainnetNodeURL: string | undefined = process.env.ARCHIVE_MAINNET_NODE_URL;
if (!archiveMainnetNodeURL) {
  throw new Error("Please set your ARCHIVE_MAINNET_NODE_URL in a .env file");
}

////////////////////////////////////////////////////
/// Hardhat network configuration for the forked mainnet.///
////////////////////////////////////////////////////
const config: HardhatUserConfig = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      accounts: {
        initialIndex: 0,
        count: 20,
        mnemonic,
        path: "m/44'/60'/0'/0",
      },
      forking: {
        url: archiveMainnetNodeURL,
        blockNumber: 13043833,
      },
      chainId: chainIds.hardhat,
      // See https://github.com/sc-forks/solidity-coverage/issues/652
      hardfork: process.env.CODE_COVERAGE ? "berlin" : "london",
    },
  },
  paths: {
    artifacts: "./artifacts",
    cache: "./cache",
    sources: "./contracts",
    tests: "./test",
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
        runs: 800,
      },
    },
  },
  typechain: {
    outDir: "typechain",
    target: "ethers-v5",
  },
};

export default config;
