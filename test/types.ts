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
  daiWhale: SignerWithAddress;
  usdcWhale: SignerWithAddress;
  usdtWhale: SignerWithAddress;
  wethWhale: SignerWithAddress;
  wbtcWhale: SignerWithAddress;
  bifiWhale: SignerWithAddress;
}

export interface PoolItem {
  pool: string;
  lpToken: string;
  stakingPool?: string;
  rewardTokens?: string[];
  tokens: string[];
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
