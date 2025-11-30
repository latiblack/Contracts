# Seedback Smart Contracts

Smart contracts for the Seedback platform, enabling XP-to-token redemptions and drop claims on Base network.

## 📋 Overview

This repository contains:
- **XPClaimContract.sol** - Allows users to redeem XP for tokens (ETH, USDC, IRYS)
- **DropClaimContract.sol** - Handles tiered reward drops for campaigns

## 🚀 Quick Start

### Prerequisites

- Node.js 18 or higher
- A wallet with ETH on Base network for deployment
- Backend signer wallet address

### Installation

```bash
npm install
```

### Environment Setup

Create a `.env` file in the contracts directory:

```env
# Deployment wallet private key (needs ETH for gas)
DEPLOYER_PRIVATE_KEY=0x...

# Backend signer address (signs claim requests)
BACKEND_SIGNER_ADDRESS=0x...

# IRYS token address on Base (use zero address if not deployed yet)
IRYS_TOKEN_ADDRESS=0x0000000000000000000000000000000000000000

# For contract verification on BaseScan (optional)
BASESCAN_API_KEY=your_basescan_api_key
```

## 📦 Deployment

### Test on Base Sepolia (Testnet)

```bash
npm run deploy:base-sepolia
```

### Deploy to Base Mainnet

```bash
npm run deploy:base
```

See [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md) for detailed deployment instructions.

## 🏗️ Contract Addresses

After deployment, update these addresses in your main application:

### XP Claim Contract
- **Base Sepolia**: `TBD`
- **Base Mainnet**: `TBD`

### Drop Claim Contract
- **Base Sepolia**: `TBD`
- **Base Mainnet**: `TBD`

## 🔗 Integration with Main App

After deploying contracts, update the main app's `src/config/contracts.ts`:

```typescript
export const XP_CLAIM_CONTRACT_ADDRESS = "0xYourDeployedXPClaimAddress";
export const DROP_CLAIM_CONTRACT_ADDRESS = "0xYourDeployedDropClaimAddress";
```

## 💰 Funding the Contracts

Contracts need to be funded with tokens for user redemptions:

### Send ETH
```bash
cast send <CONTRACT_ADDRESS> --value 0.1ether --private-key $DEPLOYER_PRIVATE_KEY --rpc-url https://mainnet.base.org
```

### Send USDC (Base: 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913)
```bash
cast send 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913 "transfer(address,uint256)" <CONTRACT_ADDRESS> 100000000 --private-key $DEPLOYER_PRIVATE_KEY --rpc-url https://mainnet.base.org
```

## 🔐 Backend Signature Service

The contracts require signatures from a trusted backend signer. Set up the [contract-service](../contract-service/) to generate signatures:

1. Deploy contract-service to Vercel
2. Configure `BACKEND_SIGNER_PRIVATE_KEY` environment variable
3. Add contract-service URL to your main app's Supabase secrets

The signature flow:
1. User initiates redemption
2. Backend verifies XP balance
3. Backend calls contract-service to generate signature
4. User submits on-chain transaction with signature
5. Contract verifies signature and transfers tokens

## ✅ Contract Verification

Verify contracts on BaseScan for transparency:

```bash
# XP Claim Contract
npx hardhat verify --network base <XP_CLAIM_ADDRESS> <BACKEND_SIGNER_ADDRESS> <IRYS_TOKEN_ADDRESS>

# Drop Claim Contract
npx hardhat verify --network base <DROP_CLAIM_ADDRESS> <BACKEND_SIGNER_ADDRESS>
```

## 📊 Monitoring

### Check Contract Balances

```bash
# ETH balance
cast balance <CONTRACT_ADDRESS> --rpc-url https://mainnet.base.org

# USDC balance
cast call 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913 "balanceOf(address)(uint256)" <CONTRACT_ADDRESS> --rpc-url https://mainnet.base.org
```

### Emergency Controls

Only the contract owner can execute these:

```bash
# Pause contract
cast send <CONTRACT_ADDRESS> "pause()" --private-key $DEPLOYER_PRIVATE_KEY --rpc-url https://mainnet.base.org

# Unpause contract
cast send <CONTRACT_ADDRESS> "unpause()" --private-key $DEPLOYER_PRIVATE_KEY --rpc-url https://mainnet.base.org

# Withdraw tokens
cast send <CONTRACT_ADDRESS> "withdrawTokens(address,uint256)" <TOKEN_ADDRESS> <AMOUNT> --private-key $DEPLOYER_PRIVATE_KEY --rpc-url https://mainnet.base.org
```

## 🏛️ Contract Architecture

### XPClaimContract

**Key Features:**
- Multi-token support (ETH, USDC, IRYS)
- Dynamic ETH pricing based on real-time rates
- Signature-based authorization
- Nonce system to prevent double claims
- Pausable for emergency stops

**Flow:**
```
User → Backend → Contract-Service → Signature
User + Signature → XPClaimContract → Token Transfer
```

### DropClaimContract

**Key Features:**
- Three-tier reward system
- Campaign-specific claims
- One claim per user per drop
- Signature verification
- USDC rewards

**Tiers:**
- Tier 1: $10 USDC
- Tier 2: $5 USDC  
- Tier 3: $0.1 USDC

## 🛠️ Development

### Compile Contracts

```bash
npx hardhat compile
```

### Run Tests

```bash
npx hardhat test
```

### Local Development

```bash
npx hardhat node
```

## 📚 Additional Documentation

- [Deployment Guide](./DEPLOYMENT_GUIDE.md) - Step-by-step deployment instructions
- [Drop Claim Contract](./README-DROP-CLAIM.md) - Drop claim specific documentation
- [XP Claim Contract Details](./XPClaimContract.sol) - Contract source code

## 🔒 Security

- Keep private keys secure and never commit them
- Use hardware wallets for mainnet deployments
- Audit contracts before mainnet deployment
- Monitor contract activity regularly
- Set up alerts for unusual patterns

## 📄 License

MIT License - See LICENSE file for details

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 💬 Support

For issues or questions:
- Check [BaseScan](https://basescan.org) for transaction details
- Review contract events and logs
- Contact the development team
