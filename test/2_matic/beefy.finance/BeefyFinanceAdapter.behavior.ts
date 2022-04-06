import hre from "hardhat";
import chai, { expect } from "chai";
import { solidity } from "ethereum-waffle";
import { BigNumber, utils } from "ethers";
import { PoolItem, StakingPoolItem } from "../types";
import { getOverrideOptions } from "../../utils";
import { getAddress } from "ethers/lib/utils";

chai.use(solidity);

export function shouldBehaveLikeBeefyFinanceAdapter(token: string, pool: PoolItem): void {
  it(`should deposit ${token} to and withdraw ${token} from ${token} pool of Beefy Finance`, async function () {
    // beefy finance's deposit vault instance
    const beefyDepositInstance = await hre.ethers.getContractAt("IBeefyDeposit", pool.beefyVault);
    // beefy lpToken decimals
    const decimals = await beefyDepositInstance.decimals();
    // underlying token instance
    const underlyingTokenInstance = await hre.ethers.getContractAt(
      "@openzeppelin/contracts-0.8.x/token/ERC20/IERC20.sol:IERC20",
      pool.wantToken,
    );
    // 1. deposit all underlying tokens
    await this.testDeFiAdapter.testGetDepositAllCodes(
      pool.wantToken, //e.g. USDC, DAI, WETH, WBTC
      pool.beefyVault, //the address of the vault we're paying into
      this.beefyFinanceAdapter.address, //what is this?
      getOverrideOptions(),
    );
    // 1.1a assert whether lptoken balance is non-zero after deposit
    const actualLPTokenBalanceAfterDeposit = await this.beefyFinanceAdapter.getLiquidityPoolTokenBalance(
      this.testDeFiAdapter.address,
      this.testDeFiAdapter.address, // placeholder of type address
      pool.beefyVault,
    );
    expect(actualLPTokenBalanceAfterDeposit).not.to.eq(0);
    // 1.1b assert whether lptoken balance is as expected or not after deposit
    // const actualLPTokenBalanceAfterDeposit = await this.beefyFinanceAdapter.getLiquidityPoolTokenBalance(
    //   this.testDeFiAdapter.address,
    //   this.testDeFiAdapter.address, // placeholder of type address
    //   pool.pool,
    // );
    const expectedLPTokenBalanceAfterDeposit = await beefyDepositInstance.balanceOf(this.testDeFiAdapter.address);
    expect(actualLPTokenBalanceAfterDeposit).to.be.eq(expectedLPTokenBalanceAfterDeposit);
    // 1.2 assert whether underlying token balance is as expected or not after deposit
    const actualUnderlyingTokenBalanceAfterDeposit = await this.testDeFiAdapter.getERC20TokenBalance(
      (
        await this.beefyFinanceAdapter.getUnderlyingTokens(pool.beefyVault, pool.beefyVault)
      )[0],
      this.testDeFiAdapter.address,
    );
    const expectedUnderlyingTokenBalanceAfterDeposit = await underlyingTokenInstance.balanceOf(
      this.testDeFiAdapter.address,
    );
    expect(actualUnderlyingTokenBalanceAfterDeposit).to.be.eq(expectedUnderlyingTokenBalanceAfterDeposit);
    // 1.3 assert whether the amount in token is as expected or not after depositing
    const actualAmountInTokenAfterDeposit = await this.beefyFinanceAdapter.getAllAmountInToken(
      this.testDeFiAdapter.address,
      pool.wantToken,
      pool.beefyVault,
    );
    const pricePerFullShareAfterDeposit = await beefyDepositInstance.getPricePerFullShare();
    const expectedAmountInTokenAfterDeposit = BigNumber.from(expectedLPTokenBalanceAfterDeposit)
      .mul(BigNumber.from(pricePerFullShareAfterDeposit))
      .div(BigNumber.from("10").pow(BigNumber.from(decimals)));
    expect(actualAmountInTokenAfterDeposit).to.be.eq(expectedAmountInTokenAfterDeposit);

    // 6. Withdraw all lpToken balance
    await this.testDeFiAdapter.testGetWithdrawAllCodes(
      pool.wantToken,
      pool.beefyVault,
      this.beefyFinanceAdapter.address,
      getOverrideOptions(),
    );
    // 6.1 assert whether lpToken balance is as expected or not
    const actualLPTokenBalanceAfterWithdraw = await this.beefyFinanceAdapter.getLiquidityPoolTokenBalance(
      this.testDeFiAdapter.address,
      this.testDeFiAdapter.address, // placeholder of type address
      pool.beefyVault,
    );
    const expectedLPTokenBalanceAfterWithdraw = await beefyDepositInstance.balanceOf(this.testDeFiAdapter.address);
    expect(actualLPTokenBalanceAfterWithdraw).to.be.eq(expectedLPTokenBalanceAfterWithdraw);
    // 6.2 assert whether underlying token balance is as expected or not after withdraw
    const actualUnderlyingTokenBalanceAfterWithdraw = await this.testDeFiAdapter.getERC20TokenBalance(
      (
        await this.beefyFinanceAdapter.getUnderlyingTokens(pool.beefyVault, pool.beefyVault)
      )[0],
      this.testDeFiAdapter.address,
    );
    const expectedUnderlyingTokenBalanceAfterWithdraw = await underlyingTokenInstance.balanceOf(
      this.testDeFiAdapter.address,
    );
    expect(actualUnderlyingTokenBalanceAfterWithdraw).to.be.eq(expectedUnderlyingTokenBalanceAfterWithdraw);
  });
}

export function shouldStakeLikeBeefyFinanceAdapter(token: string, pool: StakingPoolItem): void {
  it(`should stake mooPolygon${token} ,claim rewards, and then unstake and withdraw mooPolygon${token} from mooPolygon${token} staking pool of Beefy Finance`, async function () {
    // beefy finance's deposit vault instance
    const beefyDepositInstance = await hre.ethers.getContractAt("IBeefyDeposit", pool.pool);
    // beefy lpToken decimals
    const decimals = await beefyDepositInstance.decimals();
    // beefy finance's staking vault instance
    const beefyStakingInstance = await hre.ethers.getContractAt("IBeefyFarm", pool.stakingPool as string);
    // beefy finance reward token's instance
    const farmRewardInstance = await hre.ethers.getContractAt(
      "@openzeppelin/contracts-0.8.x/token/ERC20/IERC20.sol:IERC20",
      (pool.rewardTokens as string[])[0],
    );
    // underlying token instance
    const underlyingTokenInstance = await hre.ethers.getContractAt(
      "@openzeppelin/contracts-0.8.x/token/ERC20/IERC20.sol:IERC20",
      pool.tokens[0],
    );
    // 1. deposit all underlying tokens
    await this.testDeFiAdapter.testGetDepositAllCodes(
      pool.tokens[0],
      pool.pool,
      this.beefyFinanceAdapter.address,
      getOverrideOptions(),
    );
    // 1.1a assert whether lptoken balance is non-zero after deposit
    const actualLPTokenBalanceAfterDeposit = await this.beefyFinanceAdapter.getLiquidityPoolTokenBalance(
      this.testDeFiAdapter.address,
      this.testDeFiAdapter.address, // placeholder of type address
      pool.pool,
    );
    expect(actualLPTokenBalanceAfterDeposit).not.to.eq(0);
    // 1.1b assert whether lptoken balance is as expected or not after deposit
    // const actualLPTokenBalanceAfterDeposit = await this.beefyFinanceAdapter.getLiquidityPoolTokenBalance(
    //   this.testDeFiAdapter.address,
    //   this.testDeFiAdapter.address, // placeholder of type address
    //   pool.pool,
    // );
    const expectedLPTokenBalanceAfterDeposit = await beefyDepositInstance.balanceOf(this.testDeFiAdapter.address);
    expect(actualLPTokenBalanceAfterDeposit).to.be.eq(expectedLPTokenBalanceAfterDeposit);

    // 1.2 assert whether underlying token balance is as expected or not after deposit
    const actualUnderlyingTokenBalanceAfterDeposit = await this.testDeFiAdapter.getERC20TokenBalance(
      (
        await this.beefyFinanceAdapter.getUnderlyingTokens(pool.pool, pool.pool)
      )[0],
      this.testDeFiAdapter.address,
    );
    const expectedUnderlyingTokenBalanceAfterDeposit = await underlyingTokenInstance.balanceOf(
      this.testDeFiAdapter.address,
    );
    expect(actualUnderlyingTokenBalanceAfterDeposit).to.be.eq(expectedUnderlyingTokenBalanceAfterDeposit);
    // 1.3 assert whether the amount in token is as expected or not after depositing
    const actualAmountInTokenAfterDeposit = await this.beefyFinanceAdapter.getAllAmountInToken(
      this.testDeFiAdapter.address,
      pool.tokens[0],
      pool.pool,
    );
    const pricePerFullShareAfterDeposit = await beefyDepositInstance.getPricePerFullShare();
    const expectedAmountInTokenAfterDeposit = BigNumber.from(expectedLPTokenBalanceAfterDeposit)
      .mul(BigNumber.from(pricePerFullShareAfterDeposit))
      .div(BigNumber.from("10").pow(BigNumber.from(decimals)));
    expect(actualAmountInTokenAfterDeposit).to.be.eq(expectedAmountInTokenAfterDeposit);
    // 2. stake all lpTokens
    await this.testDeFiAdapter.testGetStakeAllCodes(
      pool.pool,
      pool.tokens[0],
      this.beefyFinanceAdapter.address,
      getOverrideOptions(),
    );
    // 2.1 assert whether the staked lpToken balance is as expected or not after staking lpToken
    const actualStakedLPTokenBalanceAfterStake = await this.beefyFinanceAdapter.getLiquidityPoolTokenBalanceStake(
      this.testDeFiAdapter.address,
      pool.pool,
    );
    const expectedStakedLPTokenBalanceAfterStake = await beefyStakingInstance.balanceOf(this.testDeFiAdapter.address);
    expect(actualStakedLPTokenBalanceAfterStake).to.be.eq(expectedStakedLPTokenBalanceAfterStake);

    // 2.2 assert whether the reward token is as expected or not
    const actualRewardToken = await this.beefyFinanceAdapter.getRewardToken(pool.pool);
    const expectedRewardToken = (pool.rewardTokens as string[])[0];
    expect(getAddress(actualRewardToken)).to.be.eq(getAddress(expectedRewardToken));
    // 2.3 make a transaction for mining a block to get finite unclaimed reward amount
    await this.signers.admin.sendTransaction({
      value: utils.parseEther("0"),
      to: await this.signers.admin.getAddress(),
      ...getOverrideOptions(),
    });
    // 2.4 assert whether the unclaimed reward amount is as expected or not after staking
    const actualUnclaimedRewardAfterStake = await this.beefyFinanceAdapter.getUnclaimedRewardTokenAmount(
      this.testDeFiAdapter.address,
      pool.pool,
      pool.tokens[0],
    );
    const expectedUnclaimedRewardAfterStake = await beefyStakingInstance.earned(this.testDeFiAdapter.address);
    expect(actualUnclaimedRewardAfterStake).to.be.eq(expectedUnclaimedRewardAfterStake);

    // 2.5 assert whether the amount in token is as expected or not after staking
    const actualAmountInTokenAfterStake = await this.beefyFinanceAdapter.getAllAmountInTokenStake(
      this.testDeFiAdapter.address,
      pool.tokens[0],
      pool.pool,
    );
    // get price per full share of the beefy lpToken
    const pricePerFullShareAfterStake = await beefyDepositInstance.getPricePerFullShare();

    // calculate amount in token for staked lpToken
    const expectedAmountInTokenFromStakedLPTokenAfterStake = BigNumber.from(expectedStakedLPTokenBalanceAfterStake)
      .mul(BigNumber.from(pricePerFullShareAfterStake))
      .div(BigNumber.from("10").pow(BigNumber.from(decimals)));
    expect(actualAmountInTokenAfterStake).to.be.eq(expectedAmountInTokenFromStakedLPTokenAfterStake);

    // 3. claim the reward token
    await this.testDeFiAdapter.testClaimRewardTokenCode(
      pool.pool,
      this.beefyFinanceAdapter.address,
      getOverrideOptions(),
    );
    // 3.1 assert whether the reward token's balance is as expected or not after claiming
    const actualRewardTokenBalanceAfterClaim = await this.testDeFiAdapter.getERC20TokenBalance(
      await this.beefyFinanceAdapter.getRewardToken(pool.pool),
      this.testDeFiAdapter.address,
    );
    const expectedRewardTokenBalanceAfterClaim = await farmRewardInstance.balanceOf(this.testDeFiAdapter.address);
    expect(actualRewardTokenBalanceAfterClaim).to.be.eq(expectedRewardTokenBalanceAfterClaim);

    // // 4. Swap the reward token into underlying token
    //COMMENTED OUT UNTIL SUFFICIENT LIQUIDITY IN WATCH FOR QUICKSWAP CALLS NOT TO REVERT
    // await this.testDeFiAdapter.testGetHarvestAllCodes(
    //   pool.pool,
    //   pool.tokens[0],
    //   this.beefyFinanceAdapter.address,
    //   getOverrideOptions(),
    // );
    // // 4.1 assert whether the reward token is swapped to underlying token or not
    // expect(await this.testDeFiAdapter.getERC20TokenBalance(pool.tokens[0], this.testDeFiAdapter.address)).to.be.gt(0);

    // 5. Unstake all staked lpTokens
    await this.testDeFiAdapter.testGetUnstakeAllCodes(
      pool.pool,
      this.beefyFinanceAdapter.address,
      getOverrideOptions(),
    );
    // 5.1 assert whether lpToken balance is as expected or not
    const actualLPTokenBalanceAfterUnstake = await this.beefyFinanceAdapter.getLiquidityPoolTokenBalance(
      this.testDeFiAdapter.address,
      this.testDeFiAdapter.address, // placeholder of type address
      pool.pool,
    );
    const expectedLPTokenBalanceAfterUnstake = await beefyDepositInstance.balanceOf(this.testDeFiAdapter.address);
    expect(actualLPTokenBalanceAfterUnstake).to.be.eq(expectedLPTokenBalanceAfterUnstake);
    // 5.2 assert whether staked lpToken balance is as expected or not
    const actualStakedLPTokenBalanceAfterUnstake = await this.beefyFinanceAdapter.getLiquidityPoolTokenBalanceStake(
      this.testDeFiAdapter.address,
      pool.pool,
    );
    const expectedStakedLPTokenBalanceAfterUnstake = await beefyStakingInstance.balanceOf(this.testDeFiAdapter.address);
    expect(actualStakedLPTokenBalanceAfterUnstake).to.be.eq(expectedStakedLPTokenBalanceAfterUnstake);
    // 6. Withdraw all lpToken balance
    await this.testDeFiAdapter.testGetWithdrawAllCodes(
      pool.tokens[0],
      pool.pool,
      this.beefyFinanceAdapter.address,
      getOverrideOptions(),
    );
    // 6.1 assert whether lpToken balance is as expected or not
    const actualLPTokenBalanceAfterWithdraw = await this.beefyFinanceAdapter.getLiquidityPoolTokenBalance(
      this.testDeFiAdapter.address,
      this.testDeFiAdapter.address, // placeholder of type address
      pool.pool,
    );
    const expectedLPTokenBalanceAfterWithdraw = await beefyDepositInstance.balanceOf(this.testDeFiAdapter.address);
    expect(actualLPTokenBalanceAfterWithdraw).to.be.eq(expectedLPTokenBalanceAfterWithdraw);
    // 6.2 assert whether underlying token balance is as expected or not after withdraw
    const actualUnderlyingTokenBalanceAfterWithdraw = await this.testDeFiAdapter.getERC20TokenBalance(
      (
        await this.beefyFinanceAdapter.getUnderlyingTokens(pool.pool, pool.pool)
      )[0],
      this.testDeFiAdapter.address,
    );
    const expectedUnderlyingTokenBalanceAfterWithdraw = await underlyingTokenInstance.balanceOf(
      this.testDeFiAdapter.address,
    );
    expect(actualUnderlyingTokenBalanceAfterWithdraw).to.be.eq(expectedUnderlyingTokenBalanceAfterWithdraw);
  });
}
