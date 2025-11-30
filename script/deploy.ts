import { ethers } from "hardhat";
import * as dotenv from "dotenv";
import * as path from "path";

// Load environment variables from .env file in contracts directory
dotenv.config({ path: path.resolve(__dirname, '../.env') });

async function main() {
  console.log("Deploying XPClaimContract...");

  // Configuration
  const BACKEND_SIGNER = process.env.BACKEND_SIGNER_ADDRESS || "";
  const IRYS_TOKEN_ADDRESS = process.env.IRYS_TOKEN_ADDRESS || "0x0000000000000000000000000000000000000000";
  
  if (!BACKEND_SIGNER) {
    throw new Error("BACKEND_SIGNER_ADDRESS environment variable not set");
  }

  const [deployer] = await ethers.getSigners();
  console.log("Deploying with account:", deployer.address);
  console.log("Account balance:", (await ethers.provider.getBalance(deployer.address)).toString());

  // Deploy contract
  const XPClaimContract = await ethers.getContractFactory("XPClaimContract");
  const claimContract = await XPClaimContract.deploy(BACKEND_SIGNER, IRYS_TOKEN_ADDRESS);
  
  await claimContract.waitForDeployment();
  const contractAddress = await claimContract.getAddress();
  
  console.log("✅ XPClaimContract deployed to:", contractAddress);
  console.log("Backend signer:", BACKEND_SIGNER);
  console.log("IRYS token:", IRYS_TOKEN_ADDRESS);
  
  console.log("\n📝 Next steps:");
  console.log("1. Fund the contract with ETH, USDC, and IRYS tokens");
  console.log("2. Update CLAIM_CONTRACT_ADDRESS in src/components/ClaimTokens.tsx");
  console.log("3. Update IRYS_TOKEN_ADDRESS if needed");
  console.log(`4. Verify contract: npx hardhat verify --network base ${contractAddress} ${BACKEND_SIGNER} ${IRYS_TOKEN_ADDRESS}`);
  
  // Fund contract instructions
  console.log("\n💰 To fund the contract:");
  console.log(`- Send ETH to: ${contractAddress}`);
  console.log(`- Send USDC to: ${contractAddress} (use USDC contract: 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913)`);
  console.log(`- Send IRYS to: ${contractAddress} (if IRYS token address is set)`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
