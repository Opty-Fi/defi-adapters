import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";
import { getAddress } from "ethers/lib/utils";
import hre from "hardhat";
import { Artifact } from "hardhat/types";
import { IUniswapV2Router02 } from "../../typechain";
import { ConvexFinanceAdapter } from "../../typechain/ConvexFinanceAdapter";
import { TestDeFiAdapter } from "../../typechain/TestDeFiAdapter";
import { default as ConvexFinancePools } from "../convex.finance-pools.json";
import { LiquidityPool, Signers } from "../types";
import { shouldBehaveLikeConvexFinanceAdapter } from "./ConvexFinanceAdapter.behavior";

const { deployContract } = hre.waffle;

describe("Unit tests", function () {
  before(async function () {
    this.signers = {} as Signers;
    const THREE_CRV_ADDRESS: string = getAddress("0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490");
    // https://etherscan.io/token/tokenholderchart/0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490
    const THREE_CRV_WHALE: string = getAddress("0xb60f193affff1c87f8128b2faef3768aee64cca5");
    const signers: SignerWithAddress[] = await hre.ethers.getSigners();
    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [THREE_CRV_WHALE],
    });
    this.signers.admin = signers[0];
    this.signers.owner = signers[1];
    this.signers.deployer = signers[2];
    this.signers.alice = signers[3];
    const THREE_CRV_WHALE_SIGNER = await hre.ethers.getSigner(THREE_CRV_WHALE);
    const crv = await hre.ethers.getContractAt("IERC20", THREE_CRV_ADDRESS, THREE_CRV_WHALE_SIGNER);

    // get the UniswapV2Router contract instance
    this.uniswapV2Router02 = <IUniswapV2Router02>(
      await hre.ethers.getContractAt("IUniswapV2Router02", "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D")
    );

    // deploy Convex Finance Adapter
    const convexFinanceAdapterArtifact: Artifact = await hre.artifacts.readArtifact("ConvexFinanceAdapter");
    this.convexFinanceAdapter = <ConvexFinanceAdapter>(
      await deployContract(this.signers.deployer, convexFinanceAdapterArtifact)
    );

    // deploy TestDeFiAdapter Contract
    const testDeFiAdapterArtifact: Artifact = await hre.artifacts.readArtifact("TestDeFiAdapter");
    this.testDeFiAdapter = <TestDeFiAdapter>await deployContract(this.signers.deployer, testDeFiAdapterArtifact);

    // fund the whale's wallet with gas
    await this.signers.admin.sendTransaction({ to: THREE_CRV_WHALE, value: hre.ethers.utils.parseEther("10") });

    // fund TestDeFiAdapter with 10000 tokens each
    await crv.transfer(this.testDeFiAdapter.address, hre.ethers.utils.parseEther("10000"));
  });

  describe("ConvexFinanceAdapter", function () {
    Object.keys(ConvexFinancePools).map((token: string) => {
      shouldBehaveLikeConvexFinanceAdapter(token, (ConvexFinancePools as LiquidityPool)[token]);
    });
  });
});
