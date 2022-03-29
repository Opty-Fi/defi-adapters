import hre from "hardhat";
import { Artifact } from "hardhat/types";
import { getAddress } from "ethers/lib/utils";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";
import { BeefyFinanceAdapter } from "../../../typechain/BeefyFinanceAdapter";
import { TestDeFiAdapter } from "../../../typechain/TestDeFiAdapter";
import { LiquidityPool, StakingPool, Signers } from "../types";
import { shouldBehaveLikeBeefyFinanceAdapter } from "./BeefyFinanceAdapter.behavior";
import { shouldStakeLikeBeefyFinanceAdapter } from "./BeefyFinanceAdapter.behavior";
import { default as BeefyFinanceLiquidityPools } from "./beefy-liquidity-pools.json";
import { default as BeefyStakingPools } from "./beefy-staking-pools.json";
import { IUniswapV2Router02 } from "../../../typechain";
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
    this.signers.operator = signers[8];
    this.signers.riskOperator = signers[9];

    const registryArtifact: Artifact = await hre.artifacts.readArtifact("IAdapterRegistryBase");
    this.mockRegistry = await hre.waffle.deployMockContract(this.signers.deployer, registryArtifact.abi);
    await this.mockRegistry.mock.getOperator.returns(this.signers.operator.address);
    await this.mockRegistry.mock.getRiskOperator.returns(this.signers.riskOperator.address);

    // deploy Beefy Finance Adapter
    const beefyFinanceAdapterArtifact: Artifact = await hre.artifacts.readArtifact("BeefyFinanceAdapter");
    this.beefyFinanceAdapter = <BeefyFinanceAdapter>(
      await deployContract(
        this.signers.deployer,
        beefyFinanceAdapterArtifact,
        [this.mockRegistry.address],
        getOverrideOptions(),
      )
    );

    // deploy TestDeFiAdapter Contract
    const testDeFiAdapterArtifact: Artifact = await hre.artifacts.readArtifact("TestDeFiAdapter");
    this.testDeFiAdapter = <TestDeFiAdapter>(
      await deployContract(this.signers.deployer, testDeFiAdapterArtifact, [], getOverrideOptions())
    );

    this.defaultRouter = <IUniswapV2Router02>(
      await hre.ethers.getContractAt("IUniswapV2Router02", "0xa5e0829caced8ffdd4de3c43696c57f7d7a678ff")
    ); //changed this to polygon apeswap router

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
        case "single_asset":
          swapRouterAddress = "0xa5e0829caced8ffdd4de3c43696c57f7d7a678ff";
          hostRouterAddress = "0xa5e0829caced8ffdd4de3c43696c57f7d7a678ff";
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
          await wmatic_token.deposit({ value: hre.ethers.utils.parseEther("5") });
        } else {
          try {
            await this.swapRouter.swapExactETHForTokens(
              0,
              [wmatic_address, wantTokenAddress],
              this.signers.admin.address,
              Date.now() + 900,
              { value: hre.ethers.utils.parseEther("5") },
            );
          } catch (err) {
            console.log("Single asset swap failed");
            console.log(err);
          }
        }
        const WANT_TOKEN_CONTRACT = await hre.ethers.getContractAt(
          "@openzeppelin/contracts-0.8.x/token/ERC20/ERC20.sol:ERC20",
          pool.wantToken,
        );

        const initialWantTokenBalance = await WANT_TOKEN_CONTRACT.balanceOf(this.signers.admin.address);

        // fund TestDeFiAdapter with initialWantTokenBalance
        await WANT_TOKEN_CONTRACT.transfer(this.testDeFiAdapter.address, initialWantTokenBalance, getOverrideOptions());
        console.log(`${await WANT_TOKEN_CONTRACT.symbol()} funded from single asset swap`);
      } else if (pool.platform == "Curve") {
        try {
          const WHALE: string = getAddress(pool.whaleLP);
          await hre.network.provider.request({
            method: "hardhat_impersonateAccount",
            params: [WHALE],
          });
          const LP_TOKEN_ADDRESS: string = getAddress(pool.wantToken);
          this.signers.tokenWhale = await hre.ethers.getSigner(WHALE);
          const LPtokenNeeded = await hre.ethers.getContractAt(
            "@openzeppelin/contracts-0.8.x/token/ERC20/ERC20.sol:ERC20",
            LP_TOKEN_ADDRESS,
            this.signers.tokenWhale,
          );
          //fund whale's wallet with gas
          await this.signers.admin.sendTransaction({
            to: WHALE,
            value: hre.ethers.utils.parseEther("1"),
            ...getOverrideOptions(),
          });
          // fund admin with 50 tokens
          const decimals = await LPtokenNeeded.decimals();
          await LPtokenNeeded.transfer(
            this.testDeFiAdapter.address,
            hre.ethers.utils.parseUnits("0.1", decimals),
            getOverrideOptions(),
          );
          console.log(`${await LPtokenNeeded.symbol()} funded from whale`);
        } catch (err) {
          console.log("Failed to source LP token from whale");
          console.log(err);
        }
      } else {
        //case where want is an LPtoken
        const LP_TOKEN_CONTRACT = await hre.ethers.getContractAt("IUniswapV2Pair", pool.wantToken);
        //get the addresses of the two respective tokens
        const token0_address = await LP_TOKEN_CONTRACT.token0();
        const token1_address = await LP_TOKEN_CONTRACT.token1();

        // swap 100 MATIC for token0 and token1 respectively
        if (token0_address == hre.ethers.utils.getAddress(wmatic_address)) {
          const wmatic_token = await hre.ethers.getContractAt("IWETH", token0_address);
          await wmatic_token.deposit({ value: hre.ethers.utils.parseEther("5") });
        } else {
          try {
            await this.swapRouter.swapExactETHForTokens(
              0,
              [wmatic_address, token0_address],
              this.signers.admin.address,
              Date.now() + 900,
              { value: hre.ethers.utils.parseEther("5") },
            );
          } catch (err) {
            try {
              await this.defaultRouter.swapExactETHForTokens(
                0,
                [wmatic_address, token0_address],
                this.signers.admin.address,
                Date.now() + 900,
                { value: hre.ethers.utils.parseEther("5") },
              );
            } catch (err) {
              try {
                const WHALE: string = getAddress(pool.whale0);
                await hre.network.provider.request({
                  method: "hardhat_impersonateAccount",
                  params: [WHALE],
                });
                const TOKEN_ADDRESS: string = getAddress(token0_address);
                this.signers.tokenWhale = await hre.ethers.getSigner(WHALE);
                const tokenNeeded0 = await hre.ethers.getContractAt(
                  "@openzeppelin/contracts-0.8.x/token/ERC20/ERC20.sol:ERC20",
                  TOKEN_ADDRESS,
                  this.signers.tokenWhale,
                );
                //fund whale's wallet with gas
                await this.signers.admin.sendTransaction({
                  to: WHALE,
                  value: hre.ethers.utils.parseEther("1"),
                  ...getOverrideOptions(),
                });
                // fund admin with 50 tokens
                const decimals = await tokenNeeded0.decimals();
                await tokenNeeded0.transfer(
                  this.signers.admin.address,
                  hre.ethers.utils.parseUnits("5", decimals),
                  getOverrideOptions(),
                );
              } catch (err) {
                console.log("Failed to source token0 from whale");
              }
            }
          }
        }
        if (token1_address == hre.ethers.utils.getAddress(wmatic_address)) {
          const wmatic_token = await hre.ethers.getContractAt("IWETH", token1_address);
          await wmatic_token.deposit({ value: hre.ethers.utils.parseEther("5") });
        } else if (token1_address == hre.ethers.utils.getAddress("0x4EaC4c4e9050464067D673102F8E24b2FccEB350")) {
          const path = [wmatic_address, token0_address, token1_address];
          console.log("ibBTC trade exception");
          await this.swapRouter.swapExactETHForTokens(0, path, this.signers.admin.address, Date.now() + 900, {
            value: hre.ethers.utils.parseEther("5"),
          });
        } else if (token1_address == hre.ethers.utils.getAddress("0x948d2a81086A075b3130BAc19e4c6DEe1D2E3fE8")) {
          const path = [wmatic_address, token0_address, token1_address];
          console.log("GUARD trade exception");
          await this.swapRouter.swapExactETHForTokens(0, path, this.signers.admin.address, Date.now() + 900, {
            value: hre.ethers.utils.parseEther("5"),
          });
        } else if (token1_address == hre.ethers.utils.getAddress("0xfC40a4F89b410a1b855b5e205064a38fC29F5eb5")) {
          const path = [wmatic_address, token0_address, token1_address];
          console.log("rUSD trade exception");
          await this.swapRouter.swapExactETHForTokens(0, path, this.signers.admin.address, Date.now() + 900, {
            value: hre.ethers.utils.parseEther("5"),
          });
        } else {
          0x948d2a81086a075b3130bac19e4c6dee1d2e3fe8;
          try {
            const path = [wmatic_address, token1_address];
            const amounts = await this.swapRouter.getAmountsOut(hre.ethers.utils.parseEther("5"), path);
            const amountOut = amounts[amounts.length - 1];
            await this.swapRouter.swapExactETHForTokens(amountOut, path, this.signers.admin.address, Date.now() + 900, {
              value: hre.ethers.utils.parseEther("5"),
            });
          } catch (err) {
            try {
              await this.defaultRouter.swapExactETHForTokens(
                0,
                [wmatic_address, token1_address],
                this.signers.admin.address,
                Date.now() + 900,
                { value: hre.ethers.utils.parseEther("5") },
              );
            } catch (err) {
              try {
                const WHALE: string = getAddress(pool.whale1);
                await hre.network.provider.request({
                  method: "hardhat_impersonateAccount",
                  params: [WHALE],
                });
                const TOKEN_ADDRESS: string = getAddress(token1_address);
                this.signers.tokenWhale = await hre.ethers.getSigner(WHALE);
                const tokenNeeded1 = await hre.ethers.getContractAt(
                  "@openzeppelin/contracts-0.8.x/token/ERC20/ERC20.sol:ERC20",
                  TOKEN_ADDRESS,
                  this.signers.tokenWhale,
                );
                //fund whale's wallet with gas
                await this.signers.admin.sendTransaction({
                  to: WHALE,
                  value: hre.ethers.utils.parseEther("1"),
                  ...getOverrideOptions(),
                });
                // fund admin with 50 tokens
                const decimals = await tokenNeeded1.decimals();
                await tokenNeeded1.transfer(
                  this.signers.admin.address,
                  hre.ethers.utils.parseUnits("5", decimals),
                  getOverrideOptions(),
                );
              } catch (err) {
                console.log("Failed to source token1 from whale");
              }
            }
          }
        }
        // get the UniswapV2Router contract instance that hosts this liquidity pool
        this.hostRouter = <IUniswapV2Router02>await hre.ethers.getContractAt("IUniswapV2Router02", hostRouterAddress); //changed this to polygon apeswap router

        //approve spending token 0
        const token0 = await hre.ethers.getContractAt(
          "@openzeppelin/contracts-0.8.x/token/ERC20/ERC20.sol:ERC20",
          token0_address,
        );
        const token0Balance = await token0.balanceOf(this.signers.admin.address);
        await token0.approve(this.hostRouter.address, token0Balance);
        //approve spending token 1
        const token1 = await hre.ethers.getContractAt(
          "@openzeppelin/contracts-0.8.x/token/ERC20/ERC20.sol:ERC20",
          token1_address,
        );
        const token1Balance = await token1.balanceOf(this.signers.admin.address);
        await token1.approve(this.hostRouter.address, token1Balance);
        //add liquidity to get LP tokens for deposit
        try {
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
        } catch (err) {
          //try to get LP from whale??
          console.log(`${pool.wantToken} failed to add liquidity`);
          console.log(err);
        }
        const initialLPtokenBalance = await LP_TOKEN_CONTRACT.balanceOf(this.signers.admin.address);
        // fund TestDeFiAdapter with initialLPtokenBalance
        if (initialLPtokenBalance > 0) {
          await LP_TOKEN_CONTRACT.transfer(this.testDeFiAdapter.address, initialLPtokenBalance, getOverrideOptions());
          console.log(`${await LP_TOKEN_CONTRACT.symbol()} funded by adding liquidity`);
        }
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
