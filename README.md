<img src="https://avatars.githubusercontent.com/u/71294241?s=400&u=0b62a061c11a7536c27b1d53760152b5e9bd40f5&v=4" alt="Header" style="width:200px;align=center;float: right;" />

## DeFi Adapters

Collection of defi adapters compatible with opty.fi's yield protocol - earn-protocol

### Prerequisites

- Install [Node JS](https://nodejs.org/en/download/) >= v12.0.0
- Learn [Javascript](https://developer.mozilla.org/en-US/docs/Web/JavaScript) and [Typescript](https://www.typescriptlang.org/)
- Learn [Solidity](https://docs.soliditylang.org/en/latest/) >=v0.6.12.
- Learn smart contract development environment like [Hardhat](https://hardhat.org/getting-started/)
- Learn testing framework like [mocha](https://mochajs.org/)
- Learn assertion library like [chai](https://www.chaijs.com/)

And passion for financial freedom...

## Getting started

### Development Setup

- Create a `.env` file and set a BIP-39 compatible mnemonic as an environment variable. Follow the example in `.env.example`. If you don't already have a mnemonic, use this [website](https://iancoleman.io/bip39/) to generate one.
- You are only required to get the archive node URL of the network which is being used for developing/testing of defi Adapters.

Proceed with installing dependencies:

```sh
yarn install
```

### What is a DeFiAdapter

- DeFi adapter is a vital building block for executing [opty.fi](https://opty.fi)'s network of strategies.
- Specifications for DeFi adapter help perform :
  - transactions like deposit, withdraw, staking, un-staking, adding liquidity, claim reward and harvesting of the reward.
  - read calls for liquidity pool token contract address, liquidity pool token balance, staked token balance, balance in underlying token of both staked and non-staked liquidity pool token, unclaimed reward tokens and reward token contract address
- A DeFi Adapter smart contract requires implementation of following interfaces :
  - [IAdapter.sol](./contracts/opty/interfaces/defiAdapters/IAdapter.sol) **(Mandatory)**
  - [IAdapterHarvestReward.sol](./contracts/opty/interfaces/defiAdapters/IAdapterHarvestReward.sol) **(Optional)**
  - [IAdapterStaking.sol](./contracts/opty/interfaces/defiAdapters/IAdapterStaking.sol) **(Optional)**
  - [IAdapterBorrow.sol](./contracts/opty/interfaces/defiAdapters/IAdapterBorrow.sol) **(Optional)**
  - [IAdapterInvestmentLimit.sol](./contracts/opty/interfaces/defiAdapters/IAdapterInvestmentLimit.sol) **(Optional)**

> Pro Tip : Inherit IAdapterFull interface from [IAdapterFull.sol](./contracts/opty/interfaces/defiAdapters/IAdapterFull.sol) to Adapter Contract if the protocol you choose required implementation of all the above interfaces.

#### Implementing `IAdapter` interface

- Implement an adapter contract using above interface(s) similar to [HarvestFinanceAdapter.sol](./contracts/1_ethereum/harvest.finance/HarvestFinanceAdapter.sol)

#### Unit Tests

- Write unit tests for all the functions across all the pool contracts gathered in Step 1.
- You might want to use a test utility contract like [TestDeFiAdapter](./contracts/mock/TestDeFiAdapter.sol) for creating a sandbox environment to execute the transaction based on function signature and target address returned from `getCodes()`-style functions from DeFiAdapter.
- All other functions can be directly tested from the DeFiAdapter contract.
- The unit test for `HarvestFinanceAdapter.sol` can be found in [HarvestFinanceAdapter.ts](./test/1_ethereum/harvest.finance/HarvestFinanceAdapter.ts)

#### Useful commands

| Usage                                                                           | Command                      |
| ------------------------------------------------------------------------------- | ---------------------------- |
| Compile the smart contracts with Hardhat                                        | `$ yarn compile`             |
| Compile the smart contracts and generate TypeChain artifacts                    | `$ yarn typechain`           |
| Lint the Solidity Code                                                          | `$ yarn lint:sol`            |
| Lint the TypeScript Code                                                        | `$ yarn lint:ts`             |
| Run the Mocha tests                                                             | `$ yarn test:{network}:fork` |
| Generate the code coverage report                                               | `$ yarn coverage:{network}`  |
| Delete the smart contract artifacts, the coverage reports and the Hardhat cache | `$ yarn clean`               |

#### Syntax Highlighting

If you use VSCode, you can enjoy syntax highlighting for your Solidity code via the
[vscode-solidity](https://github.com/juanfranblanco/vscode-solidity) extension. The recommended approach to set the
compiler version is to add the following fields to your VSCode user settings:

```json
{
  "solidity.compileUsingRemoteVersion": "v0.6.12+commit.27d51765",
  "solidity.defaultCompiler": "remote"
}
```

Where of course `v0.6.12+commit.27d51765` can be replaced with any other version.

### References

- [Hardhat](https://hardhat.org/getting-started/)
- [Ethereum Development Documentation](https://ethereum.org/en/developers/docs/)
- [Harvest Finance Docs](https://harvest-finance.gitbook.io/harvest-finance/)
