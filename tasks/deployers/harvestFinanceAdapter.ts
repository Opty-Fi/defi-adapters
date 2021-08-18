import { task } from "hardhat/config";
import { TaskArguments } from "hardhat/types";

import { HarvestFinanceAdapter, HarvestFinanceAdapter__factory } from "../../typechain";

task("deploy:HarvestFinanceAdapter").setAction(async function (taskArguments: TaskArguments, { ethers }) {
  const harvestFinanceAdapterFactory: HarvestFinanceAdapter__factory = await ethers.getContractFactory(
    "HarvestFinanceAdapter",
  );
  const harvestFinanceAdapter: HarvestFinanceAdapter = <HarvestFinanceAdapter>(
    await harvestFinanceAdapterFactory.deploy()
  );
  await harvestFinanceAdapter.deployed();
  console.log("HarvestFinanceAdapter deployed to: ", harvestFinanceAdapter.address);
});
