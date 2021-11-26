import { getAddress } from "@ethersproject/address";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";
import hre from "hardhat";
import { Artifact } from "hardhat/types";
import { LidoAdapter, LidoEthGateway } from "../../../typechain";
import { TestDeFiAdapter } from "../../../typechain/TestDeFiAdapter";
import { getOverrideOptions } from "../../utils";
import { LiquidityPool, Signers } from "../types";
import { default as LidoPools } from "./lido.fi-pools.json";
import { shouldBehaveLikeLidoAdapter } from "./LidoAdapter.behavior";

const { deployContract } = hre.waffle;

describe("Unit tests", function () {
  before(async function () {
    this.signers = {} as Signers;
    const WETH_ADDRESS: string = getAddress("0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2");
    const WETH_WHALE: string = getAddress("0x56178a0d5f301baf6cf3e1cd53d9863437345bf9");
    const signers: SignerWithAddress[] = await hre.ethers.getSigners();
    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [WETH_WHALE],
    });
    this.signers.admin = signers[0];
    this.signers.owner = signers[1];
    this.signers.deployer = signers[2];
    this.signers.alice = signers[3];
    this.signers.wethWhale = await hre.ethers.getSigner(WETH_WHALE);
    const weth = await hre.ethers.getContractAt("IERC20", WETH_ADDRESS, this.signers.wethWhale);

    // deploy Lido ETH Gateway
    const lidoEthGatewayArtifact: Artifact = await hre.artifacts.readArtifact("LidoEthGateway");
    this.lidoEthGateway = <LidoEthGateway>(
      await deployContract(this.signers.deployer, lidoEthGatewayArtifact, [], getOverrideOptions())
    );

    // deploy Lido Adapter
    const lidoAdapterArtifact: Artifact = await hre.artifacts.readArtifact("LidoAdapter");
    this.lidoAdapter = <LidoAdapter>(
      await deployContract(
        this.signers.deployer,
        lidoAdapterArtifact,
        [this.lidoEthGateway.address],
        getOverrideOptions(),
      )
    );

    // deploy TestDeFiAdapter Contract
    const testDeFiAdapterArtifact: Artifact = await hre.artifacts.readArtifact("TestDeFiAdapter");
    this.testDeFiAdapter = <TestDeFiAdapter>(
      await deployContract(this.signers.deployer, testDeFiAdapterArtifact, [], getOverrideOptions())
    );

    // fund the whale's wallet with gas
    await this.signers.admin.sendTransaction({
      to: WETH_WHALE,
      value: hre.ethers.utils.parseEther("1000"),
      ...getOverrideOptions(),
    });

    // fund the TestDeFiAdapter with 10 tokens
    await weth.transfer(this.testDeFiAdapter.address, hre.ethers.utils.parseEther("10"), getOverrideOptions());
  });

  describe("LidoAdapter", function () {
    Object.keys(LidoPools).map((token: string) => {
      shouldBehaveLikeLidoAdapter(token, (LidoPools as LiquidityPool)[token]);
    });
  });
});
