# XP Claim Contract - Deployment Guide

## Prerequisites

1. **Wallet with ETH on Base**: You need a wallet with ETH for deployment gas fees
2. **Tokens to fund contract**: ETH, USDC, and potentially IRYS tokens
3. **Backend signer wallet**: A separate wallet for signing claim requests

## Step-by-Step Deployment

### 1. Prepare Your Environment

```bash
cd contracts
npm install
```

Create `.env` file:
```env
# Your wallet private key (needs ETH for gas)
DEPLOYER_PRIVATE_KEY=0x...

# Backend wallet address (will sign claim requests)
BACKEND_SIGNER_ADDRESS=0x...

# IRYS token address on Base (leave as zeros if not available yet)
IRYS_TOKEN_ADDRESS=0x0000000000000000000000000000000000000000

# Optional: For contract verification
BASESCAN_API_KEY=your_api_key
```

### 2. Test on Base Sepolia First

```bash
# Deploy to testnet
npm run deploy:base-sepolia

# Note the deployed contract address
```

### 3. Fund the Test Contract

```bash
# Send test ETH
cast send <CONTRACT_ADDRESS> --value 0.01ether --private-key $DEPLOYER_PRIVATE_KEY --rpc-url https://sepolia.base.org

# Get test USDC from faucet and send to contract
# Base Sepolia USDC: Check Base docs for test token address
```

### 4. Test Claims on Frontend

1. Update `CLAIM_CONTRACT_ADDRESS` in `src/components/ClaimTokens.tsx`
2. Test the claim flow
3. Verify transactions on BaseScan

### 5. Deploy to Mainnet

Once testing is complete:

```bash
# Deploy to Base mainnet
npm run deploy:base

# Note the production contract address
```

### 6. Fund the Production Contract

**Recommended initial funding:**
- 0.1 ETH (~$300 at current prices)
- 100 USDC
- 1000 IRYS (if available)

This should support approximately:
- 3000 ETH claims (0.0001 ETH each)
- 1000 USDC claims (0.1 USDC each)
- 1000 IRYS claims (1 IRYS each)

```bash
# Send ETH
cast send <CONTRACT_ADDRESS> --value 0.1ether --private-key $DEPLOYER_PRIVATE_KEY --rpc-url https://mainnet.base.org

# Send USDC (Base USDC: 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913)
cast send 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913 "transfer(address,uint256)" <CONTRACT_ADDRESS> 100000000 --private-key $DEPLOYER_PRIVATE_KEY --rpc-url https://mainnet.base.org
```

### 7. Configure Backend

Add to Supabase secrets:
```bash
BACKEND_SIGNER_PRIVATE_KEY=0x... # Private key of BACKEND_SIGNER_ADDRESS
CLAIM_CONTRACT_ADDRESS=0x... # Your deployed contract address
```

### 8. Update Frontend

In `src/components/ClaimTokens.tsx`:
```typescript
const CLAIM_CONTRACT_ADDRESS = '0xYourDeployedContractAddress';
const IRYS_TOKEN_ADDRESS = '0xIrysTokenOnBase'; // Update when available
```

### 9. Verify Contract (Optional but Recommended)

```bash
npx hardhat verify --network base <CONTRACT_ADDRESS> <BACKEND_SIGNER_ADDRESS> <IRYS_TOKEN_ADDRESS>
```

## Monitoring & Maintenance

### Check Contract Balances

```bash
# Check ETH balance
cast balance <CONTRACT_ADDRESS> --rpc-url https://mainnet.base.org

# Check USDC balance
cast call 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913 "balanceOf(address)(uint256)" <CONTRACT_ADDRESS> --rpc-url https://mainnet.base.org

# Check IRYS balance (when available)
cast call <IRYS_TOKEN_ADDRESS> "balanceOf(address)(uint256)" <CONTRACT_ADDRESS> --rpc-url https://mainnet.base.org
```

### Refill When Low

Monitor contract balances and refill when running low:
- Set up alerts at 20% remaining
- Plan refills in advance
- Keep backup funds ready

### Emergency Controls

The contract has emergency functions:
```bash
# Pause claims (only owner)
cast send <CONTRACT_ADDRESS> "pause()" --private-key $DEPLOYER_PRIVATE_KEY --rpc-url https://mainnet.base.org

# Unpause
cast send <CONTRACT_ADDRESS> "unpause()" --private-key $DEPLOYER_PRIVATE_KEY --rpc-url https://mainnet.base.org

# Withdraw funds (only owner)
cast send <CONTRACT_ADDRESS> "withdrawTokens(address,uint256)" <TOKEN_ADDRESS> <AMOUNT> --private-key $DEPLOYER_PRIVATE_KEY --rpc-url https://mainnet.base.org
```

## Costs Estimate

**One-time costs:**
- Contract deployment: ~$5-10 in gas
- Contract verification: Free

**Ongoing costs:**
- User claims: $0 (sponsored by paymaster)
- Contract refills: Gas fees only (~$1 per refill transaction)
- Monitoring: Free (use BaseScan)

## Security Considerations

1. **Keep deployer private key secure**: This controls the contract
2. **Rotate backend signer**: Update if compromised
3. **Monitor claim patterns**: Watch for unusual activity
4. **Set reasonable limits**: Consider adding daily claim limits
5. **Regular audits**: Review claim history periodically

## Troubleshooting

**Issue: Claims failing**
- Check contract has enough token balance
- Verify signature generation is working
- Check user has enough XP in database

**Issue: Gas fees too high**
- Paymaster should cover fees
- Check OnchainKit paymaster configuration
- Verify chain ID matches Base mainnet (8453)

**Issue: Wrong token amounts**
- Verify XP to token rate calculations
- Check ETH price feed is updating
- Validate token decimal handling

## Support

For issues or questions:
1. Check contract on BaseScan
2. Review edge function logs in Supabase
3. Check console logs in browser dev tools
