import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";
import { Fixture } from "ethereum-waffle";
import { IUniswapV2Router02, BeefyFinanceAdapter } from "../../typechain";
import { TestDeFiAdapter } from "../../typechain/TestDeFiAdapter";

export interface Signers {
  admin: SignerWithAddress;
  owner: SignerWithAddress;
  operator: SignerWithAddress;
  riskOperator: SignerWithAddress;
  deployer: SignerWithAddress;
  alice: SignerWithAddress;
  bob: SignerWithAddress;
  charlie: SignerWithAddress;
  dave: SignerWithAddress;
  eve: SignerWithAddress;
  tokenWhale: SignerWithAddress;
  daiWhale: SignerWithAddress;
  usdtWhale: SignerWithAddress;
  wethWhale: SignerWithAddress;
}

export interface PoolItem {
  wantToken: string;
  beefyVault: string;
  tokens: string[];
  platform: string;
  whale0?: string;
  whale1?: string;
  whaleLP?: string;
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
    beefyFinanceAdapter: BeefyFinanceAdapter;
    testDeFiAdapter: TestDeFiAdapter;
    uniswapV2Router02: IUniswapV2Router02;
    loadFixture: <T>(fixture: Fixture<T>) => Promise<T>;
    signers: Signers;
  }
}
