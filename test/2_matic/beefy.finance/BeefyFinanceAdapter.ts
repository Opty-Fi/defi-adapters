import hre from "hardhat";
import { Artifact } from "hardhat/types";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";
import { BeefyFinanceAdapter } from "../../typechain/BeefyFinanceAdapter";
import { TestDeFiAdapter } from "../../typechain/TestDeFiAdapter";
import { LiquidityPool, StakingPool, Signers } from "../types";
import { shouldBehaveLikeBeefyFinanceAdapter } from "./BeefyFinanceAdapter.behavior";
import { shouldStakeLikeBeefyFinanceAdapter } from "./BeefyFinanceAdapter.behavior";
import { default as BeefyFinanceLiquidityPools } from "./beefy_single_asset_pools.json";
import { default as BeefyStakingPools } from "./beefy.staking-pools.json";
import { IUniswapV2Router02 } from "../../typechain";
import { getOverrideOptions } from "../../utils";
//
const { deployContract } = hre.waffle;

describe("Unit tests", function () {
  before(async function () {
    this.signers = {} as Signers;

    const signers: SignerWithAddress[] = await hre.ethers.getSigners();

    this.signers.admin = signers[0];
    this.signers.owner = signers[1];
    this.signers.deployer = signers[2];
    this.signers.alice = signers[3];

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

    for (const pool of Object.values(BeefyFinanceLiquidityPools)) {
      let hostRouterAddress, swapRouterAddress, wmatic_address;
      switch (pool.platform) {
        case "QuickSwap":
          swapRouterAddress = "0xa5e0829caced8ffdd4de3c43696c57f7d7a678ff";
          hostRouterAddress = "0xa5e0829caced8ffdd4de3c43696c57f7d7a678ff";
          wmatic_address = "0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270";
          break;
        case "JetSwap":
          swapRouterAddress = "0x5C6EC38fb0e2609672BDf628B1fD605A523E5923";
          hostRouterAddress = "0x5C6EC38fb0e2609672BDf628B1fD605A523E5923";
          wmatic_address = "0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270";
          break;
        case "SushiSwap":
          swapRouterAddress = "0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506";
          hostRouterAddress = "0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506";
          wmatic_address = "0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270";
          break;
        case "ApeSwap":
          swapRouterAddress = "0xC0788A3aD43d79aa53B09c2EaCc313A787d1d607";
          hostRouterAddress = "0xC0788A3aD43d79aa53B09c2EaCc313A787d1d607";
          wmatic_address = "0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270";
          break;
        case "Cometh":
          swapRouterAddress = "0x93bcDc45f7e62f89a8e901DC4A0E2c6C427D9F25";
          hostRouterAddress = "0x93bcDc45f7e62f89a8e901DC4A0E2c6C427D9F25";
          wmatic_address = "0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270";
          break;
        case "DFyn":
          swapRouterAddress = "0xa5e0829caced8ffdd4de3c43696c57f7d7a678ff"; //trying quickswap here...
          hostRouterAddress = "0xA102072A4C07F06EC3B4900FDC4C7B80b6c57429";
          wmatic_address = "0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270"; //Dfyn use a different WMATIC to most others: 0x4c28f48448720e9000907bc2611f73022fdce1fa
          break;
        case "WaultFinance":
          swapRouterAddress = "0x3a1D87f206D12415f5b0A33E786967680AAb4f6d";
          hostRouterAddress = "0x3a1D87f206D12415f5b0A33E786967680AAb4f6d";
          wmatic_address = "0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270";
          break;
        case "Polyzap":
          swapRouterAddress = "0x4aAEC1FA8247F85Dc3Df20F4e03FEAFdCB087Ae9";
          hostRouterAddress = "0x4aAEC1FA8247F85Dc3Df20F4e03FEAFdCB087Ae9";
          wmatic_address = "0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270";
          break;
        case "FireBird":
          swapRouterAddress = "0xa5e0829caced8ffdd4de3c43696c57f7d7a678ff"; //still failing with QS as swapRouter - failing at addLiq?
          hostRouterAddress = "0xF6fa9Ea1f64f1BBfA8d71f7f43fAF6D45520bfac";
          wmatic_address = "0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270";
          break;
        case "Curve":
          swapRouterAddress = "0xa5e0829caced8ffdd4de3c43696c57f7d7a678ff"; //Quickswap for the swaps - can't swap from wmatic in curve
          hostRouterAddress = "0xF6fa9Ea1f64f1BBfA8d71f7f43fAF6D45520bfac";
          wmatic_address = "0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270";
          break;
        default:
          swapRouterAddress = "0xa5e0829caced8ffdd4de3c43696c57f7d7a678ff";
          hostRouterAddress = "0xa5e0829caced8ffdd4de3c43696c57f7d7a678ff";
          wmatic_address = "0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270";
          break;
      }

      // get the UniswapV2Router contract instance that hosts this liquidity pool
      this.swapRouter = <IUniswapV2Router02>await hre.ethers.getContractAt("IUniswapV2Router02", swapRouterAddress); //changed this to polygon apeswap router

      if (pool.platform == "single_asset") {
        //case where want is a single token
        const wantTokenAddress = pool.wantToken;
        if (wantTokenAddress == hre.ethers.utils.getAddress(wmatic_address)) {
          const wmatic_token = await hre.ethers.getContractAt("IWETH", wantTokenAddress);
          await wmatic_token.deposit({ value: hre.ethers.utils.parseEther("50") });
        } else {
          try {
            await this.swapRouter.swapExactETHForTokens(
              0,
              [wmatic_address, wantTokenAddress],
              this.signers.admin.address,
              Date.now() + 900,
              { value: hre.ethers.utils.parseEther("50") },
            );
            console.log("swap into single asset done");
          } catch (err) {
            console.log("First swap failed");
            console.log(err);
          }
        }
        const WANT_TOKEN_CONTRACT = await hre.ethers.getContractAt("IERC20", pool.wantToken);

        const initialWantTokenBalance = await WANT_TOKEN_CONTRACT.balanceOf(this.signers.admin.address);

        // fund TestDeFiAdapter with initialWantTokenBalance
        await WANT_TOKEN_CONTRACT.transfer(this.testDeFiAdapter.address, initialWantTokenBalance, getOverrideOptions());

        // console.log(`${await WANT_TOKEN_CONTRACT.symbol()} funded`);
      } else {
        //case where want is an LPtoken
        const LP_TOKEN_CONTRACT = await hre.ethers.getContractAt("IUniswapV2Pair", pool.wantToken);
        //get the addresses of the two respective tokens
        const token0_address = await LP_TOKEN_CONTRACT.token0();
        const token1_address = await LP_TOKEN_CONTRACT.token1();
        console.log(token0_address);

        // swap 100 MATIC for token0 and token1 respectively
        if (token0_address == hre.ethers.utils.getAddress(wmatic_address)) {
          const wmatic_token = await hre.ethers.getContractAt("IWETH", token0_address);
          await wmatic_token.deposit({ value: hre.ethers.utils.parseEther("50") });
        } else {
          try {
            await this.swapRouter.swapExactETHForTokens(
              0,
              [wmatic_address, token0_address],
              this.signers.admin.address,
              Date.now() + 900,
              { value: hre.ethers.utils.parseEther("50") },
            );
            console.log("swap1 done");
          } catch (err) {
            console.log("First swap failed");
            console.log(err);
          }
        }
        if (token1_address == hre.ethers.utils.getAddress(wmatic_address)) {
          const wmatic_token = await hre.ethers.getContractAt("IWETH", token1_address);
          await wmatic_token.deposit({ value: hre.ethers.utils.parseEther("50") });
        } else {
          try {
            await this.swapRouter.swapExactETHForTokens(
              0,
              [wmatic_address, token1_address],
              this.signers.admin.address,
              Date.now() + 900,
              { value: hre.ethers.utils.parseEther("50") },
            );
            console.log("swap2 done");
          } catch (err) {
            console.log("Second swap failed");
            console.log(err);
          }
        }
        // get the UniswapV2Router contract instance that hosts this liquidity pool
        this.hostRouter = <IUniswapV2Router02>await hre.ethers.getContractAt("IUniswapV2Router02", hostRouterAddress); //changed this to polygon apeswap router

        //approve spending token 0
        const token0 = await hre.ethers.getContractAt("ERC20", token0_address);
        const token0Balance = await token0.balanceOf(this.signers.admin.address);
        await token0.approve(this.hostRouter.address, token0Balance);

        //approve spending token 1
        const token1 = await hre.ethers.getContractAt("ERC20", token1_address);
        const token1Balance = await token1.balanceOf(this.signers.admin.address);
        await token1.approve(this.hostRouter.address, token1Balance);
        console.log("approvals done");
        //add liquidity to get LP tokens for deposit
        await this.hostRouter.addLiquidity(
          token0_address,
          token1_address,
          token0Balance,
          token1Balance,
          0,
          0,
          this.signers.admin.address,
          Date.now() + 900,
        );
        console.log("liquidity added");
        const initialLPtokenBalance = await LP_TOKEN_CONTRACT.balanceOf(this.signers.admin.address);

        // fund TestDeFiAdapter with initialLPtokenBalance
        await LP_TOKEN_CONTRACT.transfer(this.testDeFiAdapter.address, initialLPtokenBalance, getOverrideOptions());
        console.log(`${await LP_TOKEN_CONTRACT.symbol()} funded`);
      }
    }
  });

  describe("BeefyFinanceAdapter", function () {
    Object.keys(BeefyFinanceLiquidityPools).map(async (token: string) => {
      shouldBehaveLikeBeefyFinanceAdapter(token, (BeefyFinanceLiquidityPools as LiquidityPool)[token]);
    });
  });

  describe("BeefyFinanceAdapter", function () {
    Object.keys(BeefyStakingPools).map(async (token: string) => {
      shouldStakeLikeBeefyFinanceAdapter(token, (BeefyStakingPools as StakingPool)[token]);
    });
  });
});
