const { network, ethers } = require("hardhat");
const { expect } = require("chai");
const web3 = require("@solana/web3.js");
const { NATIVE_MINT } = require("@solana/spl-token");
const config = require("../config.js");




const {
  deployContract,
  setupSPLTokens,
  setupATAAccounts,
  approveSplTokens
} = require("./utils.js");


const connection = new web3.Connection(config.svm_node[network.name], "processed");
describe("RaydiumStakingVault", function () {
  console.log("Network name: " + network.name);

  const RECEIPTS_COUNT = 1;
  const WSOL = "0xc7Fc9b46e479c5Cb42f6C458D1881e55E6B7986c";

  let deployer,
    RaydiumStakingVault,
    tokenA,
    tokenA_Erc20ForSpl,
    poolId;

  before(async function () {
    const deployment = await deployContract("RaydiumStakingVault", null);
    deployer = deployment.deployer;
    RaydiumStakingVault = deployment.contract;

    tokenA = NATIVE_MINT.toBase58(); // Solana wrapped SOL (wSOL)
    await setupATAAccounts(
      ethers.encodeBase58(await RaydiumStakingVault.CALL_SOLANA().getPayer()),
      [tokenA]
    );

    const erc20ForSplFactory = await ethers.getContractFactory('contracts/token/ERC20ForSpl/erc20_for_spl.sol:ERC20ForSpl');
    tokenA_Erc20ForSpl = erc20ForSplFactory.attach(WSOL);

    await approveSplTokens(tokenA, tokenA_Erc20ForSpl, deployer);

    // mock a valid poolId for testing

    const poolId = ethers.zeroPadValue(ethers.toBeHex(ethers.decodeBase58("9XY7jqVAFxA9YLGmrMvAXQbTUkH9yUNnhYkG84YkPMfG")), 32);

  });

  it("should deposit tokens and mint shares", async function () {
    const amount = ethers.parseUnits("0.05", 9);
    const slippage = 1;

    await expect(
      RaydiumStakingVault.connect(deployer).deposit(poolId, amount, slippage)
    ).to.emit(RaydiumStakingVault, "Deposited");

    const shares = await RaydiumStakingVault.getUserShares(deployer.address, poolId);
    expect(shares).to.be.gt(0);
  });

  it("should withdraw tokens and burn shares", async function () {
    const sharesBefore = await RaydiumStakingVault.getUserShares(deployer.address, poolId);
    const slippage = 1;

    await expect(
      RaydiumStakingVault.connect(deployer).withdraw(poolId, sharesBefore, slippage)
    ).to.emit(RaydiumStakingVault, "Withdrawn");

    const sharesAfter = await RaydiumStakingVault.getUserShares(deployer.address, poolId);
    expect(sharesAfter).to.equal(0n); // use bigint zero
  });

  it("should calculate shares correctly", async function () {
    const shares = await RaydiumStakingVault.calculateShares(poolId, 1000);
    expect(shares).to.be.a("bigint");
  });

  it("should get total LP in pool", async function () {
    const totalLP = await RaydiumStakingVault.getTotalLpInPool(poolId);
    expect(totalLP).to.be.a("bigint");
  });
});
