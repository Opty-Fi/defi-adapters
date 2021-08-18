import chai, { expect } from "chai";
import { solidity } from "ethereum-waffle";
import { PoolItem } from "../types";

chai.use(solidity);

export function shouldBehaveLikeHarvestFinanceAdapter(token: string, pool: PoolItem): void {
  it(`should deposit and withdraw ${token} in ${token} pool of Harvest Finance`, async function () {
    await this.testDeFiAdapter.testGetDepositAllCodes(pool.tokens[0], pool.pool, this.harvestFinanceAdapter.address);
    expect(
      await this.harvestFinanceAdapter.getLiquidityPoolTokenBalance(
        this.testDeFiAdapter.address,
        this.testDeFiAdapter.address,
        pool.pool,
      ),
    ).to.be.gt(0);
    await this.testDeFiAdapter.testGetWithdrawAllCodes(pool.tokens[0], pool.pool, this.harvestFinanceAdapter.address);
    expect(
      await this.harvestFinanceAdapter.getLiquidityPoolTokenBalance(
        this.testDeFiAdapter.address,
        this.testDeFiAdapter.address,
        pool.pool,
      ),
    ).to.be.eq(0);
  });
}
