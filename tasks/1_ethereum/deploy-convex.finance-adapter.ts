import { task } from "hardhat/config";
import { TaskArguments } from "hardhat/types";

import { ConvexFinanceAdapter, ConvexFinanceAdapter__factory } from "../../typechain";

const registryContractAddress = "0x99fa011e33a8c6196869dec7bc407e896ba67fe3";

task("deploy-convex.finance-adapter").setAction(async function (taskArguments: TaskArguments, { ethers }) {
  const convexFinanceAdapterFactory: ConvexFinanceAdapter__factory = await ethers.getContractFactory(
    "ConvexFinanceAdapter",
  );
  const convexFinanceAdapter: ConvexFinanceAdapter = <ConvexFinanceAdapter>(
    await convexFinanceAdapterFactory.deploy(registryContractAddress)
  );
  await convexFinanceAdapter.deployed();
  console.log("ConvexFinanceAdapter deployed to: ", convexFinanceAdapter.address);
});
