import { task } from "hardhat/config";
import { TaskArguments } from "hardhat/types";
import { ConvexFinanceAdapter, ConvexFinanceAdapter__factory } from "../../typechain";

task("deploy:ConvexFinanceAdapter").setAction(async function (taskArguments: TaskArguments, { ethers }) {
  const convexFinanceAdapterFactory: ConvexFinanceAdapter__factory = await ethers.getContractFactory(
    "ConvexFinanceAdapter",
  );
  const convexFinanceAdapter: ConvexFinanceAdapter = <ConvexFinanceAdapter>await convexFinanceAdapterFactory.deploy();
  await convexFinanceAdapter.deployed();
  console.log("ConexFinanceAdapter deployed to: ", convexFinanceAdapter.address);
});
