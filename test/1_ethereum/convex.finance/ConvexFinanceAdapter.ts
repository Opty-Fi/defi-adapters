import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";
import { getAddress } from "ethers/lib/utils";
import hre from "hardhat";
import { Artifact } from "hardhat/types";
import { IUniswapV2Router02 } from "../../../typechain";
import { ConvexFinanceAdapter } from "../../../typechain/ConvexFinanceAdapter";
import { TestDeFiAdapter } from "../../../typechain/TestDeFiAdapter";
import { default as ConvexFinancePools } from "./convex.finance-pools.json";
import { LiquidityPool, Signers } from "../types";
import { getOverrideOptions } from "../../utils";
import { shouldBehaveLikeConvexFinanceAdapter } from "./ConvexFinanceAdapter.behavior";
import { IAdapterRegistryBase } from "../../../typechain/IAdapterRegistryBase";

const { deployContract } = hre.waffle;

const skiplist: string[] = [
  "ypool", // DepositZap.calc_token_amount missing + swap not possible
  "busd", // DepositZap.calc_token_amount missing + swap not possible
  "pax", // DepositZap.calc_token_amount missing + swap not possible
  "tricrypto2", // no coins
];

const shouldSkip = (name: string): boolean => {
  return skiplist.indexOf(name) !== -1;
};

const registryAddress = "0x9ff914d0005564a941429d1685477851d1836672";

describe("Unit tests", function () {
  before(async function () {
    console.log("ConvexFinanceAdapter");
    this.signers = {} as Signers;
    const signers: SignerWithAddress[] = await hre.ethers.getSigners();
    this.signers.admin = signers[0];
    this.signers.owner = signers[1];
    this.signers.deployer = signers[2];
    this.signers.alice = signers[3];

    // get the UniswapV2Router contract instance
    this.uniswapV2Router02 = <IUniswapV2Router02>(
      await hre.ethers.getContractAt("IUniswapV2Router02", "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D")
    );

    // deploy Convex Finance Adapter
    const convexFinanceAdapterArtifact: Artifact = await hre.artifacts.readArtifact("ConvexFinanceAdapter");
    this.convexFinanceAdapter = <ConvexFinanceAdapter>(
      await deployContract(this.signers.deployer, convexFinanceAdapterArtifact, [registryAddress], getOverrideOptions())
    );

    // deploy TestDeFiAdapter Contract
    const testDeFiAdapterArtifact: Artifact = await hre.artifacts.readArtifact("TestDeFiAdapter");
    this.testDeFiAdapter = <TestDeFiAdapter>await deployContract(this.signers.deployer, testDeFiAdapterArtifact, []);

    const registryInstance = <IAdapterRegistryBase>(
      await hre.ethers.getContractAt("IAdapterRegistryBase", registryAddress)
    );
    const operator = await registryInstance.getOperator();
    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [operator],
    });

    for (const [name, pool] of Object.entries(ConvexFinancePools)) {
      if (shouldSkip(name)) {
        continue;
      }

      console.log(name);

      if (!pool.whale) {
        throw new Error(`Whale is missing for ${pool.pool}`);
      }

      const WHALE: string = getAddress(String(pool.whale));

      await hre.network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [WHALE],
      });

      const WHALE_SIGNER = await hre.ethers.getSigner(WHALE);
      const POOL_TOKEN_CONTRACT = await hre.ethers.getContractAt(
        "@openzeppelin/contracts-0.8.x/token/ERC20/IERC20.sol:IERC20",
        pool.tokens[0],
        WHALE_SIGNER,
      );

      // fund the whale's wallet with gas
      await this.signers.admin.sendTransaction({
        to: WHALE,
        value: hre.ethers.utils.parseEther("1000"),
        ...getOverrideOptions(),
      });

      if (
        POOL_TOKEN_CONTRACT.address == getAddress("0xb19059ebb43466c323583928285a49f558e572fd") || // hbtc
        POOL_TOKEN_CONTRACT.address == getAddress("0xde5331ac4b3630f94853ff322b66407e0d6331e8") || // pbtc
        POOL_TOKEN_CONTRACT.address == getAddress("0x410e3e86ef427e30b9235497143881f717d93c2a") || // bbtc
        POOL_TOKEN_CONTRACT.address == getAddress("0x2fe94ea3d5d4a175184081439753de15aef9d614") // obtc
      ) {
        await POOL_TOKEN_CONTRACT.transfer(
          this.testDeFiAdapter.address,
          hre.ethers.utils.parseEther("0.01"),
          getOverrideOptions(),
        );
      } else {
        // fund TestDeFiAdapter with 10 tokens each
        await POOL_TOKEN_CONTRACT.transfer(
          this.testDeFiAdapter.address,
          hre.ethers.utils.parseEther("10"),
          getOverrideOptions(),
        );
      }
    }
  });

  describe("ConvexFinanceAdapter", function () {
    Object.keys(ConvexFinancePools).map(async (name: string) => {
      if (!shouldSkip(name)) {
        shouldBehaveLikeConvexFinanceAdapter(name, (ConvexFinancePools as LiquidityPool)[name]);
      }
    });
  });
});
