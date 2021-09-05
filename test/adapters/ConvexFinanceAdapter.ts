import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";
import { getAddress } from "ethers/lib/utils";
import hre from "hardhat";
import { Artifact } from "hardhat/types";
import { IUniswapV2Router02 } from "../../typechain";
import { ConvexFinanceAdapter } from "../../typechain/ConvexFinanceAdapter";
import { TestDeFiAdapter } from "../../typechain/TestDeFiAdapter";
import { default as ConvexFinancePools } from "../convex.finance-pools.json";
import { LiquidityPool, Signers } from "../types";
import { getOverrideOptions } from "../utils";
import { shouldBehaveLikeConvexFinanceAdapter } from "./ConvexFinanceAdapter.behavior";

const { deployContract } = hre.waffle;

describe("Unit tests", function () {
  before(async function () {
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
      await deployContract(this.signers.deployer, convexFinanceAdapterArtifact, [], getOverrideOptions())
    );

    // deploy TestDeFiAdapter Contract
    const testDeFiAdapterArtifact: Artifact = await hre.artifacts.readArtifact("TestDeFiAdapter");
    this.testDeFiAdapter = <TestDeFiAdapter>(
      await deployContract(this.signers.deployer, testDeFiAdapterArtifact, [], getOverrideOptions())
    );

    for (const pool of Object.values(ConvexFinancePools)) {
      if (!pool.whale) {
        throw new Error(`Whale is missing for ${pool.pool}`);
      }

      const WHALE: string = getAddress(String(pool.whale));

      await hre.network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [WHALE],
      });

      const WHALE_SIGNER = await hre.ethers.getSigner(WHALE);
      const POOL_TOKEN_CONTRACT = await hre.ethers.getContractAt("IERC20", pool.tokens[0], WHALE_SIGNER);

      // fund the whale's wallet with gas
      await this.signers.admin.sendTransaction({
        to: WHALE,
        value: hre.ethers.utils.parseEther("1000"),
        ...getOverrideOptions(),
      });

      // fund TestDeFiAdapter with 1000 tokens each
      await POOL_TOKEN_CONTRACT.transfer(
        this.testDeFiAdapter.address,
        hre.ethers.utils.parseEther("1000"),
        getOverrideOptions(),
      );
    }
  });

  describe("ConvexFinanceAdapter", function () {
    Object.keys(ConvexFinancePools).map(async (token: string) => {
      shouldBehaveLikeConvexFinanceAdapter(token, (ConvexFinancePools as LiquidityPool)[token]);
    });
  });
});
