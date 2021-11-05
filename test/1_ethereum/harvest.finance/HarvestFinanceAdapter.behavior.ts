import hre from "hardhat";
import chai, { expect } from "chai";
import { solidity } from "ethereum-waffle";
import { getAddress } from "ethers/lib/utils";
import { BigNumber, utils } from "ethers";
import { PoolItem } from "../types";
import { getOverrideOptions } from "../../utils";

chai.use(solidity);

export function shouldBehaveLikeHarvestFinanceAdapter(token: string, pool: PoolItem): void {
  it(`should deposit ${token}, stake f${token}, claim FARM, harvest FARM, unstake f${token}, and withdraw f${token} in ${token} pool of Harvest Finance`, async function () {
    // harvest finance's deposit vault instance
    const harvestDepositInstance = await hre.ethers.getContractAt("IHarvestDeposit", pool.pool);
    // harvest lpToken decimals
    const decimals = await harvestDepositInstance.decimals();
    // harvest finance's staking vault instance
    const harvestStakingInstance = await hre.ethers.getContractAt("IHarvestFarm", pool.stakingPool as string);
    // harvest finance reward token's instance
    const farmRewardInstance = await hre.ethers.getContractAt("IERC20", (pool.rewardTokens as string[])[0]);
    // underlying token instance
    const underlyingTokenInstance = await hre.ethers.getContractAt("IERC20", pool.tokens[0]);
    // 1. deposit all underlying tokens
    await this.testDeFiAdapter.testGetDepositAllCodes(
      pool.tokens[0],
      pool.pool,
      this.harvestFinanceAdapter.address,
      getOverrideOptions(),
    );
    // 1.1 assert whether lptoken balance is as expected or not after deposit
    const actualLPTokenBalanceAfterDeposit = await this.harvestFinanceAdapter.getLiquidityPoolTokenBalance(
      this.testDeFiAdapter.address,
      this.testDeFiAdapter.address, // placeholder of type address
      pool.pool,
    );
    const expectedLPTokenBalanceAfterDeposit = await harvestDepositInstance.balanceOf(this.testDeFiAdapter.address);
    expect(actualLPTokenBalanceAfterDeposit).to.be.eq(expectedLPTokenBalanceAfterDeposit);
    // 1.2 assert whether underlying token balance is as expected or not after deposit
    const actualUnderlyingTokenBalanceAfterDeposit = await this.testDeFiAdapter.getERC20TokenBalance(
      (
        await this.harvestFinanceAdapter.getUnderlyingTokens(pool.pool, pool.pool)
      )[0],
      this.testDeFiAdapter.address,
    );
    const expectedUnderlyingTokenBalanceAfterDeposit = await underlyingTokenInstance.balanceOf(
      this.testDeFiAdapter.address,
    );
    expect(actualUnderlyingTokenBalanceAfterDeposit).to.be.eq(expectedUnderlyingTokenBalanceAfterDeposit);
    // 1.3 assert whether the amount in token is as expected or not after depositing
    const actualAmountInTokenAfterDeposit = await this.harvestFinanceAdapter.getAllAmountInToken(
      this.testDeFiAdapter.address,
      pool.tokens[0],
      pool.pool,
    );
    const pricePerFullShareAfterDeposit = await harvestDepositInstance.getPricePerFullShare();
    const expectedAmountInTokenAfterDeposit = BigNumber.from(expectedLPTokenBalanceAfterDeposit)
      .mul(BigNumber.from(pricePerFullShareAfterDeposit))
      .div(BigNumber.from("10").pow(BigNumber.from(decimals)));
    expect(actualAmountInTokenAfterDeposit).to.be.eq(expectedAmountInTokenAfterDeposit);
    // 2. stake all lpTokens
    await this.testDeFiAdapter.testGetStakeAllCodes(
      pool.pool,
      pool.tokens[0],
      this.harvestFinanceAdapter.address,
      getOverrideOptions(),
    );
    // 2.1 assert whether the staked lpToken balance is as expected or not after staking lpToken
    const actualStakedLPTokenBalanceAfterStake = await this.harvestFinanceAdapter.getLiquidityPoolTokenBalanceStake(
      this.testDeFiAdapter.address,
      pool.pool,
    );
    const expectedStakedLPTokenBalanceAfterStake = await harvestStakingInstance.balanceOf(this.testDeFiAdapter.address);
    expect(actualStakedLPTokenBalanceAfterStake).to.be.eq(expectedStakedLPTokenBalanceAfterStake);
    // 2.2 assert whether the reward token is as expected or not
    const actualRewardToken = await this.harvestFinanceAdapter.getRewardToken(pool.pool);
    const expectedRewardToken = (pool.rewardTokens as string[])[0];
    expect(getAddress(actualRewardToken)).to.be.eq(getAddress(expectedRewardToken));
    // 2.3 make a transaction for mining a block to get finite unclaimed reward amount
    await this.signers.admin.sendTransaction({
      value: utils.parseEther("0"),
      to: await this.signers.admin.getAddress(),
      ...getOverrideOptions(),
    });
    // 2.4 assert whether the unclaimed reward amount is as expected or not after staking
    const actualUnclaimedRewardAfterStake = await this.harvestFinanceAdapter.getUnclaimedRewardTokenAmount(
      this.testDeFiAdapter.address,
      pool.pool,
      pool.tokens[0],
    );
    const expectedUnclaimedRewardAfterStake = await harvestStakingInstance.earned(this.testDeFiAdapter.address);
    expect(actualUnclaimedRewardAfterStake).to.be.eq(expectedUnclaimedRewardAfterStake);
    // 2.5 assert whether the amount in token is as expected or not after staking
    const actualAmountInTokenAfterStake = await this.harvestFinanceAdapter.getAllAmountInTokenStake(
      this.testDeFiAdapter.address,
      pool.tokens[0],
      pool.pool,
    );
    // get price per full share of the harvest lpToken
    const pricePerFullShareAfterStake = await harvestDepositInstance.getPricePerFullShare();
    // get amount in underling token if reward token is swapped
    const rewardInTokenAfterStake = (
      await this.uniswapV2Router02.getAmountsOut(expectedUnclaimedRewardAfterStake, [
        expectedRewardToken,
        await this.uniswapV2Router02.WETH(),
        pool.tokens[0],
      ])
    )[2];
    // calculate amount in token for staked lpToken
    const expectedAmountInTokenFromStakedLPTokenAfterStake = BigNumber.from(expectedStakedLPTokenBalanceAfterStake)
      .mul(BigNumber.from(pricePerFullShareAfterStake))
      .div(BigNumber.from("10").pow(BigNumber.from(decimals)));
    // calculate total amount token when lpToken is redeemed plus reward token is harvested
    const expectedAmountInTokenAfterStake = BigNumber.from(rewardInTokenAfterStake).add(
      expectedAmountInTokenFromStakedLPTokenAfterStake,
    );
    expect(actualAmountInTokenAfterStake).to.be.eq(expectedAmountInTokenAfterStake);
    // 3. claim the reward token
    await this.testDeFiAdapter.testClaimRewardTokenCode(
      pool.pool,
      this.harvestFinanceAdapter.address,
      getOverrideOptions(),
    );
    // 3.1 assert whether the reward token's balance is as expected or not after claiming
    const actualRewardTokenBalanceAfterClaim = await this.testDeFiAdapter.getERC20TokenBalance(
      await this.harvestFinanceAdapter.getRewardToken(pool.pool),
      this.testDeFiAdapter.address,
    );
    const expectedRewardTokenBalanceAfterClaim = await farmRewardInstance.balanceOf(this.testDeFiAdapter.address);
    expect(actualRewardTokenBalanceAfterClaim).to.be.eq(expectedRewardTokenBalanceAfterClaim);
    // 4. Swap the reward token into underlying token
    await this.testDeFiAdapter.testGetHarvestAllCodes(
      pool.pool,
      pool.tokens[0],
      this.harvestFinanceAdapter.address,
      getOverrideOptions(),
    );
    // 4.1 assert whether the reward token is swapped to underlying token or not
    expect(await this.testDeFiAdapter.getERC20TokenBalance(pool.tokens[0], this.testDeFiAdapter.address)).to.be.gt(0);
    // 5. Unstake all staked lpTokens
    await this.testDeFiAdapter.testGetUnstakeAllCodes(
      pool.pool,
      this.harvestFinanceAdapter.address,
      getOverrideOptions(),
    );
    // 5.1 assert whether lpToken balance is as expected or not
    const actualLPTokenBalanceAfterUnstake = await this.harvestFinanceAdapter.getLiquidityPoolTokenBalance(
      this.testDeFiAdapter.address,
      this.testDeFiAdapter.address, // placeholder of type address
      pool.pool,
    );
    const expectedLPTokenBalanceAfterUnstake = await harvestDepositInstance.balanceOf(this.testDeFiAdapter.address);
    expect(actualLPTokenBalanceAfterUnstake).to.be.eq(expectedLPTokenBalanceAfterUnstake);
    // 5.2 assert whether staked lpToken balance is as expected or not
    const actualStakedLPTokenBalanceAfterUnstake = await this.harvestFinanceAdapter.getLiquidityPoolTokenBalanceStake(
      this.testDeFiAdapter.address,
      pool.pool,
    );
    const expectedStakedLPTokenBalanceAfterUnstake = await harvestStakingInstance.balanceOf(
      this.testDeFiAdapter.address,
    );
    expect(actualStakedLPTokenBalanceAfterUnstake).to.be.eq(expectedStakedLPTokenBalanceAfterUnstake);
    // 6. Withdraw all lpToken balance
    await this.testDeFiAdapter.testGetWithdrawAllCodes(
      pool.tokens[0],
      pool.pool,
      this.harvestFinanceAdapter.address,
      getOverrideOptions(),
    );
    // 6.1 assert whether lpToken balance is as expected or not
    const actualLPTokenBalanceAfterWithdraw = await this.harvestFinanceAdapter.getLiquidityPoolTokenBalance(
      this.testDeFiAdapter.address,
      this.testDeFiAdapter.address, // placeholder of type address
      pool.pool,
    );
    const expectedLPTokenBalanceAfterWithdraw = await harvestDepositInstance.balanceOf(this.testDeFiAdapter.address);
    expect(actualLPTokenBalanceAfterWithdraw).to.be.eq(expectedLPTokenBalanceAfterWithdraw);
    // 6.2 assert whether underlying token balance is as expected or not after withdraw
    const actualUnderlyingTokenBalanceAfterWithdraw = await this.testDeFiAdapter.getERC20TokenBalance(
      (
        await this.harvestFinanceAdapter.getUnderlyingTokens(pool.pool, pool.pool)
      )[0],
      this.testDeFiAdapter.address,
    );
    const expectedUnderlyingTokenBalanceAfterWithdraw = await underlyingTokenInstance.balanceOf(
      this.testDeFiAdapter.address,
    );
    expect(actualUnderlyingTokenBalanceAfterWithdraw).to.be.eq(expectedUnderlyingTokenBalanceAfterWithdraw);
  }).timeout(100000);
}
