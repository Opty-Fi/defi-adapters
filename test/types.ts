import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";
import { Fixture } from "ethereum-waffle";
import { HarvestFinanceAdapter } from "../typechain/HarvestFinanceAdapter";
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
  usdtWhale: SignerWithAddress;
}

export interface PoolItem {
  pool: string;
  lpToken: string;
  tokens: string[];
}

export interface LiquidityPool {
  [name: string]: PoolItem;
}

declare module "mocha" {
  export interface Context {
    harvestFinanceAdapter: HarvestFinanceAdapter;
    testDeFiAdapter: TestDeFiAdapter;
    loadFixture: <T>(fixture: Fixture<T>) => Promise<T>;
    signers: Signers;
  }
}
