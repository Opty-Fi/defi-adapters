import chai, { expect } from "chai";
import { solidity } from "ethereum-waffle";
import { BigNumber } from "ethers";
import hre from "hardhat";
import { getOverrideOptions, ignoreRoundingError } from "../../utils";
import { PoolItem } from "../../1_ethereum/types";

chai.use(solidity);

export function shouldBehaveLikeLidoAdapter(token: string, pool: PoolItem): void {
  it(`should deposit ${token} and receive st${token} in ${token} pool of Lido`, async function () {
    // lido's deposit vault instance
    const lidoDepositInstance = await hre.ethers.getContractAt("ILidoDeposit", pool.pool);
    // underlying token instance
    const underlyingToken = pool.tokens[0];
    const underlyingTokenInstance = await hre.ethers.getContractAt(
      "@openzeppelin/contracts-0.8.x/token/ERC20/IERC20.sol:IERC20",
      underlyingToken,
    );
    const balanceBeforeDeposit = await underlyingTokenInstance.balanceOf(this.testDeFiAdapter.address);
    const poolValueBeforeDeposit = await this.lidoAdapter.getPoolValue(pool.pool, underlyingToken);
    // 1. deposit all underlying tokens
    await this.testDeFiAdapter.testGetDepositAllCodes(
      pool.tokens[0],
      pool.pool,
      this.lidoAdapter.address,
      getOverrideOptions(),
    );
    // 1.1 assert whether lptoken balance is as expected or not after deposit
    const actualLPTokenBalanceAfterDeposit = await this.lidoAdapter.getLiquidityPoolTokenBalance(
      this.testDeFiAdapter.address,
      this.testDeFiAdapter.address, // placeholder of type address
      pool.pool,
    );
    const expectedLPTokenBalanceAfterDeposit = await this.lidoAdapter.calculateAmountInLPToken(
      underlyingToken,
      pool.pool,
      balanceBeforeDeposit,
    );
    expect(actualLPTokenBalanceAfterDeposit).to.be.gt(0);
    expect(ignoreRoundingError(actualLPTokenBalanceAfterDeposit)).to.be.eq(
      ignoreRoundingError(expectedLPTokenBalanceAfterDeposit),
    );
    // 1.2 assert whether the underlying token balance is as expected or not after deposit
    const actualBalanceAfterDeposit1 = await hre.ethers.provider.getBalance(this.testDeFiAdapter.address);
    expect(actualBalanceAfterDeposit1).to.be.eq(0);
    // 1.3 assert whether the amount in token is as expected or not after depositing
    const actualAmountInTokenAfterDeposit = await this.lidoAdapter.getAllAmountInToken(
      this.testDeFiAdapter.address,
      underlyingToken,
      pool.pool,
    );
    const totalPooledEtherAfterDeposit = await lidoDepositInstance.getTotalPooledEther();
    const totalSharesAfterDeposit = await lidoDepositInstance.getTotalShares();
    const expectedAmountInTokenAfterDeposit = BigNumber.from(expectedLPTokenBalanceAfterDeposit)
      .mul(BigNumber.from(totalPooledEtherAfterDeposit))
      .div(BigNumber.from(totalSharesAfterDeposit));
    expect(ignoreRoundingError(actualAmountInTokenAfterDeposit)).to.be.eq(
      ignoreRoundingError(expectedAmountInTokenAfterDeposit),
    );
    // 1.4 assert whether the calculated redeemable lpToken amount is as expected or not after deposit
    const actualRedeemableLPTokenAmountAfterDeposit = await this.lidoAdapter.calculateRedeemableLPTokenAmount(
      this.testDeFiAdapter.address,
      underlyingToken,
      pool.pool,
      expectedLPTokenBalanceAfterDeposit,
    );
    expect(actualRedeemableLPTokenAmountAfterDeposit).to.be.eq(expectedAmountInTokenAfterDeposit);
    // 1.5 assert whether the redeemable amount is sufficient or not after deposit
    const actualIsRedeemableAmountSufficientAfterDeposit = await this.lidoAdapter.isRedeemableAmountSufficient(
      this.testDeFiAdapter.address,
      underlyingToken,
      pool.pool,
      expectedLPTokenBalanceAfterDeposit,
    );
    expect(actualIsRedeemableAmountSufficientAfterDeposit).to.be.true;
    // 1.6 assert whether the pool value is as expected or not after deposit
    const actualPoolValueAfterDeposit = await this.lidoAdapter.getPoolValue(pool.pool, underlyingToken);
    const expectedPoolValueAfterDeposit = BigNumber.from(poolValueBeforeDeposit).add(expectedAmountInTokenAfterDeposit);
    expect(ignoreRoundingError(actualPoolValueAfterDeposit)).to.be.eq(
      ignoreRoundingError(expectedPoolValueAfterDeposit),
    );
    // 2. Withdraw all lpToken balance
    const underlyingBalanceBeforeWithdraw = await underlyingTokenInstance.balanceOf(this.testDeFiAdapter.address);
    await this.testDeFiAdapter.testGetWithdrawAllCodes(
      underlyingToken,
      pool.pool,
      this.lidoAdapter.address,
      getOverrideOptions(),
    );
    const actualAllowanceAfterWithdraw = await lidoDepositInstance.allowance(this.testDeFiAdapter.address, pool.swap);
    expect(actualAllowanceAfterWithdraw).to.be.eq(0);
    // 2.1 assert whether lpToken balance is as expected or not after withdraw
    const actualLPTokenBalanceAfterWithdraw = await this.lidoAdapter.getLiquidityPoolTokenBalance(
      this.testDeFiAdapter.address,
      this.testDeFiAdapter.address, // placeholder of type address
      pool.pool,
    );
    const expectedLPTokenBalanceAfterWithdraw = await lidoDepositInstance.sharesOf(this.testDeFiAdapter.address);
    expect(actualLPTokenBalanceAfterWithdraw).to.be.eq(expectedLPTokenBalanceAfterWithdraw);
    // 2.2 assert whether underlying token balance is as expected or not after withdraw
    const actualBalanceAfterWithdraw = await underlyingTokenInstance.balanceOf(this.testDeFiAdapter.address);
    expect(actualBalanceAfterWithdraw).to.be.gt(underlyingBalanceBeforeWithdraw);
  });

  it(`should return the reward token and assert that staking is not enabled`, async function () {
    // assert reward token
    const actualRewardToken = await this.lidoAdapter.getRewardToken(pool.pool);
    expect(actualRewardToken).to.be.eq(hre.ethers.constants.AddressZero);
    // assert cannot stake
    const actualCanStake = await this.lidoAdapter.canStake(pool.pool);
    expect(actualCanStake).to.be.false;
  });

  it(`should check correctness of view function return values`, async function () {
    const underlyingToken = pool.tokens[0];
    // assert underlying token
    const actualUnderlyingTokens = await this.lidoAdapter.getUnderlyingTokens(pool.pool, underlyingToken);
    expect(actualUnderlyingTokens[0]).to.be.eq(underlyingToken);
    // assert liquidity pool token
    const actualLiquidityPoolToken = await this.lidoAdapter.getLiquidityPoolToken(underlyingToken, pool.pool);
    expect(actualLiquidityPoolToken).to.be.eq(pool.lpToken);
    // assert redeemable amount is not sufficient
    const actualAmountInToken = await this.lidoAdapter.getAllAmountInToken(
      this.testDeFiAdapter.address,
      underlyingToken,
      pool.pool,
    );
    const actualIsRedeemableAmountSufficient = await this.lidoAdapter.isRedeemableAmountSufficient(
      this.testDeFiAdapter.address,
      underlyingToken,
      pool.pool,
      actualAmountInToken.add(1),
    );
    expect(actualIsRedeemableAmountSufficient).to.be.false;
  });
}
