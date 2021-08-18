import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "solidity-coverage";

if (!process.env.SKIP_LOAD) {
  require("./tasks/accounts");
  require("./tasks/clean");
  require("./tasks/deployers");
}

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

// Ensure that we have mnemonic phrase set as an environment variable
const mnemonic: string | undefined = process.env.MNEMONIC;
if (!mnemonic) {
  throw new Error("Please set your MNEMONIC in a .env file");
}
// Ensure that we have archive mainnet node URL set as an environment variable
const archiveMainnetNodeURL: string | undefined = process.env.ARCHIVE_MAINNET_NODE_URL;
if (!archiveMainnetNodeURL) {
  throw new Error("Please set your ARCHIVE_MAINNET_NODE_URL in a .env file");
}

////////////////////////////////////////////////////////////
/// HARDHAT NETWORK CONFIGURATION FOR THE FORKED MAINNET ///
////////////////////////////////////////////////////////////
const config: HardhatUserConfig = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      initialBaseFeePerGas: 1_000_000_000,
      accounts: {
        initialIndex: 0,
        count: 20,
        mnemonic,
        path: "m/44'/60'/0'/0",
      },
      forking: {
        url: archiveMainnetNodeURL,
        blockNumber: 12600000,
      },
      chainId: chainIds.hardhat,
      hardfork: "london",
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
