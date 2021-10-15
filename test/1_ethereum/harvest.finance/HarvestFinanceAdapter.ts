import hre from "hardhat";
import { Artifact } from "hardhat/types";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";
import { getAddress } from "ethers/lib/utils";
import { HarvestFinanceAdapter } from "../../../typechain/HarvestFinanceAdapter";
import { TestDeFiAdapter } from "../../../typechain/TestDeFiAdapter";
import { LiquidityPool, Signers } from "../types";
import { shouldBehaveLikeHarvestFinanceAdapter } from "./HarvestFinanceAdapter.behavior";
import { default as HarvestFinancePools } from "./harvest.finance-pools.json";
import { IUniswapV2Router02 } from "../../../typechain";
import { getOverrideOptions } from "../../utils";

const { deployContract } = hre.waffle;

describe("Unit tests", function () {
  before(async function () {
    this.signers = {} as Signers;
    const DAI_ADDRESS: string = getAddress("0x6b175474e89094c44da98b954eedeac495271d0f");
    const USDT_ADDRESS: string = getAddress("0xdac17f958d2ee523a2206206994597c13d831ec7");
    const DAI_WHALE: string = getAddress("0x47ac0fb4f2d84898e4d9e7b4dab3c24507a6d503");
    const USDT_WHALE: string = getAddress("0x47ac0Fb4F2D84898e4D9E7b4DaB3C24507a6D503");
    const signers: SignerWithAddress[] = await hre.ethers.getSigners();
    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [DAI_WHALE],
    });
    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [USDT_WHALE],
    });
    this.signers.admin = signers[0];
    this.signers.owner = signers[1];
    this.signers.deployer = signers[2];
    this.signers.alice = signers[3];
    this.signers.daiWhale = await hre.ethers.getSigner(DAI_WHALE);
    this.signers.usdtWhale = await hre.ethers.getSigner(USDT_WHALE);
    const dai = await hre.ethers.getContractAt("IERC20", DAI_ADDRESS, this.signers.daiWhale);
    const usdt = await hre.ethers.getContractAt("IERC20", USDT_ADDRESS, this.signers.usdtWhale);

    // get the UniswapV2Router contract instance
    this.uniswapV2Router02 = <IUniswapV2Router02>(
      await hre.ethers.getContractAt("IUniswapV2Router02", "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D")
    );

    // deploy Harvest Finance Adapter
    const harvestFinanceAdapterArtifact: Artifact = await hre.artifacts.readArtifact("HarvestFinanceAdapter");
    this.harvestFinanceAdapter = <HarvestFinanceAdapter>(
      await deployContract(this.signers.deployer, harvestFinanceAdapterArtifact, [], getOverrideOptions())
    );

    // deploy TestDeFiAdapter Contract
    const testDeFiAdapterArtifact: Artifact = await hre.artifacts.readArtifact("TestDeFiAdapter");
    this.testDeFiAdapter = <TestDeFiAdapter>(
      await deployContract(this.signers.deployer, testDeFiAdapterArtifact, [], getOverrideOptions())
    );

    // fund the whale's wallet with gas
    await this.signers.admin.sendTransaction({
      to: DAI_WHALE,
      value: hre.ethers.utils.parseEther("100"),
      ...getOverrideOptions(),
    });
    await this.signers.admin.sendTransaction({
      to: USDT_WHALE,
      value: hre.ethers.utils.parseEther("100"),
      ...getOverrideOptions(),
    });

    // fund TestDeFiAdapter with 10000 tokens each
    await dai.transfer(this.testDeFiAdapter.address, hre.ethers.utils.parseEther("10000"), getOverrideOptions());
    await usdt.transfer(this.testDeFiAdapter.address, hre.ethers.utils.parseUnits("10000", 6), getOverrideOptions());

    // whitelist TestDeFiAdapter contract into HarvestFinance's Vaults
    // by impersonating the governance's address
    const tokenNames = Object.keys(HarvestFinancePools);
    for (const tokenName of tokenNames) {
      const { pool } = (HarvestFinancePools as LiquidityPool)[tokenName];
      const harvestVault = await hre.ethers.getContractAt("IHarvestDeposit", pool);
      const governance = await harvestVault.governance();
      await hre.network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [governance],
      });
      const harvestController = await hre.ethers.getContractAt(
        "IHarvestController",
        await harvestVault.controller(),
        await hre.ethers.getSigner(governance),
      );
      await this.signers.admin.sendTransaction({
        to: governance,
        value: hre.ethers.utils.parseEther("1000"),
        ...getOverrideOptions(),
      });
      await harvestController.addToWhitelist(this.testDeFiAdapter.address, getOverrideOptions());
      await harvestController.addCodeToWhitelist(this.testDeFiAdapter.address, getOverrideOptions());
    }
  });

  describe("HarvestFinanceAdapter", function () {
    Object.keys(HarvestFinancePools).map((token: string) => {
      shouldBehaveLikeHarvestFinanceAdapter(token, (HarvestFinancePools as LiquidityPool)[token]);
    });
  });
});
