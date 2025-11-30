# Drop Claim Smart Contract

This contract manages tiered drop claims based on user eligibility.

## Eligibility Tiers

1. **Tier 1** - Wallet + Twitter connected: **$10 USD**
2. **Tier 2** - Twitter only (no wallet): **$5 USD**  
3. **Tier 3** - Neither connected: **$0.1 USD**

## Features

- ✅ Three-tier eligibility system
- ✅ Signature verification to prevent unauthorized claims
- ✅ Support for ETH and USDC tokens
- ✅ Per-drop claim tracking (users can't claim same drop twice)
- ✅ Gas-sponsored transactions via paymaster
- ✅ Pausable for emergency stops
- ✅ Owner-controlled fund management

## Deployment

### 1. Install Dependencies

```bash
cd contracts
npm install
```

### 2. Set Environment Variables

Create a `.env` file:

```env
DEPLOYER_PRIVATE_KEY=your_deployer_private_key_here
BACKEND_SIGNER_ADDRESS=your_backend_signer_address_here
BASESCAN_API_KEY=your_basescan_api_key_here
```

### 3. Deploy to Base Sepolia (Testnet)

```bash
npx hardhat run scripts/deploy-drop-claim.ts --network baseSepolia
```

### 4. Deploy to Base Mainnet

```bash
npx hardhat run scripts/deploy-drop-claim.ts --network base
```

## Funding the Contract

After deployment, fund the contract with tokens:

```bash
# Send ETH directly
cast send <CONTRACT_ADDRESS> --value 1ether --private-key $DEPLOYER_PRIVATE_KEY

# Send USDC (Base mainnet: 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913)
cast send 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913 "transfer(address,uint256)" <CONTRACT_ADDRESS> 10000000000 --private-key $DEPLOYER_PRIVATE_KEY
```

## Backend Integration

The contract requires a backend signature to verify eligibility. See `supabase/functions/check-drop-eligibility/index.ts` for the implementation.

## Frontend Integration

See `src/components/drops/` for the claim flow components.

## Contract Addresses

- **Base Sepolia**: TBD (deploy first)
- **Base Mainnet**: TBD (deploy after testing)
