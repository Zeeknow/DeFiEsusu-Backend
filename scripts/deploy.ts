import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  // 1. Deploy Mock USDC first
  const MockUSDC = await ethers.getContractFactory("MockUSDC");
  const mockUsdc = await MockUSDC.deploy();
  await mockUsdc.waitForDeployment();
  const mockUsdcAddress = await mockUsdc.getAddress();

  console.log("----------------------------------------------------");
  console.log("💰 MockUSDC deployed to:", mockUsdcAddress);
  console.log("----------------------------------------------------");

  // 2. Deploy DeFi Esusu (passing the MockUSDC address & Deployer as fee collector)
  const DeFiEsusu = await ethers.getContractFactory("DeFiEsusu");
  const esusu = await DeFiEsusu.deploy(mockUsdcAddress, deployer.address);
  await esusu.waitForDeployment();
  const esusuAddress = await esusu.getAddress();

  console.log("🚀 DeFiEsusu deployed to:", esusuAddress);
  console.log("----------------------------------------------------");
  console.log("✅ Deployment Complete!");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});