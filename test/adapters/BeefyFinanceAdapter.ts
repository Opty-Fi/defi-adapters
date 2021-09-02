import hre from "hardhat";
import { Artifact } from "hardhat/types";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";
import { getAddress } from "ethers/lib/utils";
import { BeefyFinanceAdapter } from "../../typechain/BeefyFinanceAdapter";
import { TestDeFiAdapter } from "../../typechain/TestDeFiAdapter";
import { LiquidityPool, Signers } from "../types";
import { shouldBehaveLikeBeefyFinanceAdapter } from "./BeefyFinanceAdapter.behavior";
import { shouldStakeLikeBeefyFinanceAdapter } from "./BeefyFinanceAdapter.behavior";
import { default as BeefyFinancePools } from "../beefy.finance-pools.json";
import { default as BeefyStakingPools } from "../beefy.staking-pools.json";
import { IUniswapV2Router02 } from "../../typechain";
import { getOverrideOptions } from "../utils";

const { deployContract } = hre.waffle;

describe("Unit tests", function () {
  before(async function () {
    this.signers = {} as Signers;
    const DAI_ADDRESS: string = getAddress("0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063");
    const USDC_ADDRESS: string = getAddress("0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174");
    const WETH_ADDRESS: string = getAddress("0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619");
    const WBTC_ADDRESS: string = getAddress("0x1BFD67037B42Cf73acF2047067bd4F2C47D9BfD6");
    const BIFI_ADDRESS: string = getAddress("0xFbdd194376de19a88118e84E279b977f165d01b8");

    const DAI_WHALE: string = getAddress("0x7f625b1C8276AaF3B302e3915a47edc51458164f");
    const USDC_WHALE: string = getAddress("0x986a2fCa9eDa0e06fBf7839B89BfC006eE2a23Dd");
    const WETH_WHALE: string = getAddress("0x3EDC6fE5e041B9ED01e35CD644b395f6419A2f8a");
    const WBTC_WHALE: string = getAddress("0x082A5a5d287Ed0063100c186f0F09cAe7bAa677c");
    const BIFI_WHALE: string = getAddress("0xAD32Bc446Cc906BfD5f74914F5Bd9cbD1443bcd6"); //holds 32 BIFI

    const signers: SignerWithAddress[] = await hre.ethers.getSigners();
    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [DAI_WHALE],
    });
    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [USDC_WHALE],
    });
    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [WETH_WHALE],
    });
    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [WBTC_WHALE],
    });
    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [BIFI_WHALE],
    });
    this.signers.admin = signers[0];
    this.signers.owner = signers[1];
    this.signers.deployer = signers[2];
    this.signers.alice = signers[3];
    this.signers.daiWhale = await hre.ethers.getSigner(DAI_WHALE);
    this.signers.usdcWhale = await hre.ethers.getSigner(USDC_WHALE);
    this.signers.wethWhale = await hre.ethers.getSigner(WETH_WHALE);
    this.signers.wbtcWhale = await hre.ethers.getSigner(WBTC_WHALE);
    this.signers.bifiWhale = await hre.ethers.getSigner(BIFI_WHALE);

    const dai = await hre.ethers.getContractAt("IERC20", DAI_ADDRESS, this.signers.daiWhale);
    const usdc = await hre.ethers.getContractAt("IERC20", USDC_ADDRESS, this.signers.usdcWhale);
    const weth = await hre.ethers.getContractAt("IERC20", WETH_ADDRESS, this.signers.wethWhale);
    const wbtc = await hre.ethers.getContractAt("IERC20", WBTC_ADDRESS, this.signers.wbtcWhale);
    const bifi = await hre.ethers.getContractAt("IERC20", BIFI_ADDRESS, this.signers.bifiWhale);

    // get the UniswapV2Router contract instance
    this.uniswapV2Router02 = <IUniswapV2Router02>(
      await hre.ethers.getContractAt("IUniswapV2Router02", "0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff") //changed this to quickswap router
    );

    // deploy Beefy Finance Adapter
    const beefyFinanceAdapterArtifact: Artifact = await hre.artifacts.readArtifact("BeefyFinanceAdapter");
    this.beefyFinanceAdapter = <BeefyFinanceAdapter>(
      await deployContract(this.signers.deployer, beefyFinanceAdapterArtifact, [], getOverrideOptions())
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
      to: USDC_WHALE,
      value: hre.ethers.utils.parseEther("100"),
      ...getOverrideOptions(),
    });
    await this.signers.admin.sendTransaction({
      to: WETH_WHALE,
      value: hre.ethers.utils.parseEther("100"),
      ...getOverrideOptions(),
    });
    await this.signers.admin.sendTransaction({
      to: WBTC_WHALE,
      value: hre.ethers.utils.parseEther("100"),
      ...getOverrideOptions(),
    });
    await this.signers.admin.sendTransaction({
      to: BIFI_WHALE,
      value: hre.ethers.utils.parseEther("100"),
      ...getOverrideOptions(),
    });

    // fund TestDeFiAdapter with tokens
    await dai.transfer(this.testDeFiAdapter.address, hre.ethers.utils.parseEther("10000"), getOverrideOptions());
    await usdc.transfer(this.testDeFiAdapter.address, hre.ethers.utils.parseUnits("10000", 6), getOverrideOptions());
    await weth.transfer(this.testDeFiAdapter.address, hre.ethers.utils.parseEther("100"), getOverrideOptions());
    await wbtc.transfer(this.testDeFiAdapter.address, hre.ethers.utils.parseUnits("10", 8), getOverrideOptions());
    await bifi.transfer(this.testDeFiAdapter.address, hre.ethers.utils.parseUnits("10", 18), getOverrideOptions());
  });

  describe("BeefyFinanceAdapter", function () {
    Object.keys(BeefyFinancePools).map((token: string) => {
      shouldBehaveLikeBeefyFinanceAdapter(token, (BeefyFinancePools as LiquidityPool)[token]);
    });
  });

  describe("BeefyFinanceAdapter", function () {
    Object.keys(BeefyStakingPools).map((token: string) => {
      shouldStakeLikeBeefyFinanceAdapter(token, (BeefyStakingPools as LiquidityPool)[token]);
    });
  });
});
