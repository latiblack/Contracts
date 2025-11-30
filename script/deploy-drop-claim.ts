
import { ethers } from "hardhat";
import * as dotenv from "dotenv";
import * as path from "path";

// Load environment variables from .env file in contracts directory
dotenv.config({ path: path.resolve(__dirname, '../.env') });

async function main() {
  console.log("Deploying DropClaimContract...");

  // Configuration
  const BACKEND_SIGNER = process.env.BACKEND_SIGNER_ADDRESS || "";
  
  if (!BACKEND_SIGNER) {
    throw new Error("BACKEND_SIGNER_ADDRESS environment variable not set");
  }

  const [deployer] = await ethers.getSigners();
  console.log("Deploying with account:", deployer.address);
  console.log("Account balance:", (await ethers.provider.getBalance(deployer.address)).toString());

  // Deploy contract
  const DropClaimContract = await ethers.getContractFactory("DropClaimContract");
  const dropClaimContract = await DropClaimContract.deploy(BACKEND_SIGNER);
  
  await dropClaimContract.waitForDeployment();
  const contractAddress = await dropClaimContract.getAddress();
  
  console.log("✅ DropClaimContract deployed to:", contractAddress);
  console.log("Backend signer:", BACKEND_SIGNER);
  
  console.log("\n📝 Next steps:");
  console.log("1. Fund the contract with ETH and USDC tokens");
  console.log("2. Update DROP_CLAIM_CONTRACT_ADDRESS in src/config/contracts.ts");
  console.log(`3. Verify contract: npx hardhat verify --network base ${contractAddress} ${BACKEND_SIGNER}`);
  
  // Fund contract instructions
  console.log("\n💰 To fund the contract:");
  console.log(`- Send ETH to: ${contractAddress}`);
  console.log(`- Send USDC to: ${contractAddress} (USDC contract: 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913)`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
