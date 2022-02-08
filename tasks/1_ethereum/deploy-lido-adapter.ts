import { task } from "hardhat/config";
import { TaskArguments } from "hardhat/types";

import { LidoAdapter, LidoAdapter__factory } from "../../typechain";

const registryContractAddress = "0x99fa011e33a8c6196869dec7bc407e896ba67fe3";

task("deploy-lido-adapter").setAction(async function (taskArguments: TaskArguments, { ethers }) {
  const lidoAdapterFactory: LidoAdapter__factory = await ethers.getContractFactory("LidoAdapter");
  const lidoAdapter: LidoAdapter = <LidoAdapter>await lidoAdapterFactory.deploy(registryContractAddress);
  await lidoAdapter.deployed();
  console.log("LidoAdapter deployed to: ", lidoAdapter.address);
});
