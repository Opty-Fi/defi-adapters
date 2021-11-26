import { task } from "hardhat/config";
import { TaskArguments } from "hardhat/types";

import { BeefyFinanceAdapter, BeefyFinanceAdapter__factory } from "../../typechain";

task("deploy:BeefyFinanceAdapter").setAction(async function (taskArguments: TaskArguments, { ethers }) {
  const beefyFinanceAdapterFactory: BeefyFinanceAdapter__factory = await ethers.getContractFactory(
    "BeefyFinanceAdapter",
  );
  const beefyFinanceAdapter: BeefyFinanceAdapter = <BeefyFinanceAdapter>await beefyFinanceAdapterFactory.deploy();
  await beefyFinanceAdapter.deployed();
  console.log("BeefyFinanceAdapter deployed to: ", beefyFinanceAdapter.address);
});
