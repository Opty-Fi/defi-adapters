import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";
import { Fixture } from "ethereum-waffle";
import { IUniswapV2Router02 } from "../typechain";
import { HarvestFinanceAdapter } from "../typechain/HarvestFinanceAdapter";
import { BeefyFinanceAdapter } from "../typechain/BeefyFinanceAdapter";
import { TestDeFiAdapter } from "../typechain/TestDeFiAdapter";

export interface Signers {
  admin: SignerWithAddress;
  owner: SignerWithAddress;
  deployer: SignerWithAddress;
  alice: SignerWithAddress;
  bob: SignerWithAddress;
  charlie: SignerWithAddress;
  dave: SignerWithAddress;
  eve: SignerWithAddress;
}

export interface PoolItem {
  wantToken: string;
  beefyVault: string;
  tokens: string[];
  platform: string;
}

export interface StakingPoolItem {
  tokens: string[];
  stakingPool: string;
  rewardTokens: string[];
  pool: string;
  lpToken: string;
  whale: string;
}

export interface StakingPool {
  [name: string]: StakingPoolItem;
}

export interface LiquidityPool {
  [name: string]: PoolItem;
}

declare module "mocha" {
  export interface Context {
    harvestFinanceAdapter: HarvestFinanceAdapter;
    beefyFinanceAdapter: BeefyFinanceAdapter;
    testDeFiAdapter: TestDeFiAdapter;
    uniswapV2Router02: IUniswapV2Router02;
    loadFixture: <T>(fixture: Fixture<T>) => Promise<T>;
    signers: Signers;
  }
}
