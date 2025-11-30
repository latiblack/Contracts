# Integration Guide: Connecting Contracts to Main App

This guide explains how to integrate the deployed smart contracts with your main Seedback application.

## Architecture Overview

```
User Interface (React App)
    ↓
Supabase Edge Function (Backend)
    ↓
Contract Service (Signature Generation)
    ↓
Smart Contracts (On Base Network)
```

## Step 1: Deploy Smart Contracts

1. Deploy contracts to Base network (see [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md))
2. Note the deployed contract addresses
3. Verify contracts on BaseScan

## Step 2: Update Main App Configuration

In your main application repository, update `src/config/contracts.ts`:

```typescript
// Smart contract addresses on Base network

// XP Claim Contract
export const XP_CLAIM_CONTRACT_ADDRESS = "0xYourDeployedXPClaimAddress";

// Drop Claim Contract
export const DROP_CLAIM_CONTRACT_ADDRESS = "0xYourDeployedDropClaimAddress";

// Token addresses on Base mainnet
export const TOKEN_ADDRESSES = {
  USDC: "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913",
  ETH: "0x0000000000000000000000000000000000000000", // Native ETH
  IRYS: "0xYourIRYSTokenAddress", // Update when IRYS is deployed on Base
} as const;
```

## Step 3: Deploy Contract Service

The contract-service generates signatures for redemptions.

1. Navigate to `contract-service/` directory
2. Deploy to Vercel:
```bash
vercel
```
3. Add environment variable in Vercel dashboard:
   - `BACKEND_SIGNER_PRIVATE_KEY` = Your backend signer's private key

4. Note the deployed URL (e.g., `https://your-contract-service.vercel.app`)

## Step 4: Configure Supabase Secrets

Add the contract service URL to your Supabase project:

```bash
# In Supabase dashboard → Settings → Edge Functions → Secrets
CONTRACT_SERVICE_URL=https://your-contract-service.vercel.app
```

## Step 5: Create Edge Function for Signature Generation

Create `supabase/functions/sign-redemption/index.ts`:

```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const { walletAddress, xpAmount, tokenType, ethPriceUsd } = await req.json();

    // Generate unique nonce
    const nonce = crypto.randomUUID();

    // Call contract-service to get signature
    const contractServiceUrl = Deno.env.get('CONTRACT_SERVICE_URL');
    const response = await fetch(`${contractServiceUrl}/api/sign-redemption`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        walletAddress,
        xpAmount,
        tokenType,
        ethPriceUsd,
        nonce,
      }),
    });

    const data = await response.json();

    return new Response(JSON.stringify(data), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
```

## Step 6: Update ClaimTokens Component

In your main app, update the redemption flow in `src/components/ClaimTokens.tsx`:

```typescript
// 1. Fetch ETH price
const { ethPrice } = useEthPrice();

// 2. Get signature from backend
const getSignature = async () => {
  const { data, error } = await supabase.functions.invoke('sign-redemption', {
    body: {
      walletAddress: address,
      xpAmount: selectedXpAmount,
      tokenType: selectedToken,
      ethPriceUsd: ethPrice * 1e9, // Convert to wei-compatible format
    },
  });

  if (error) throw error;
  return data;
};

// 3. Submit to contract with signature
const handleClaim = async () => {
  const { signature, nonce } = await getSignature();
  
  // Use OnchainKit Transaction component with signature
  // Contract will verify and transfer tokens
};
```

## Step 7: Test the Integration

### On Base Sepolia (Testnet)

1. Deploy contracts to Base Sepolia
2. Update contract addresses in config
3. Fund test contracts with test tokens
4. Test full redemption flow:
   - User selects XP amount and token
   - Backend generates signature
   - User submits transaction
   - Verify token transfer on BaseScan

### On Base Mainnet (Production)

1. Deploy contracts to Base Mainnet
2. Update contract addresses in config
3. Fund production contracts
4. Monitor first few redemptions closely
5. Set up alerts for low balances

## Monitoring & Maintenance

### Check Contract Balances

```bash
# ETH balance
cast balance <CONTRACT_ADDRESS> --rpc-url https://mainnet.base.org

# USDC balance  
cast call 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913 "balanceOf(address)(uint256)" <CONTRACT_ADDRESS> --rpc-url https://mainnet.base.org
```

### Monitor Edge Function Logs

Check Supabase edge function logs for signature generation:
- Successful signature generations
- Failed requests
- Error patterns

### Monitor Contract Events

Watch for these events on BaseScan:
- `TokensClaimed` - Successful redemptions
- `Paused/Unpaused` - Contract state changes
- Transfer events for token movements

## Troubleshooting

### Signature Verification Fails

**Possible causes:**
- Backend signer address mismatch
- Nonce already used
- Message hash calculation mismatch
- Wrong ETH price format

**Solution:**
- Verify backend signer address matches contract
- Check nonce is unique
- Review signature generation logic

### Insufficient Contract Balance

**Symptoms:**
- Transaction reverts with "Insufficient balance"

**Solution:**
- Check contract token balances
- Refill contracts when low
- Set up balance alerts

### Gas Fee Issues

**Symptoms:**
- Transactions failing due to gas

**Solution:**
- Verify paymaster is configured in OnchainKit
- Check gas price isn't too low
- Ensure Base network is selected

## Security Checklist

- [ ] Private keys stored securely (never in code)
- [ ] Contract addresses verified on BaseScan
- [ ] Backend signer address matches contract configuration
- [ ] Edge function has proper CORS headers
- [ ] Contract-service URL is HTTPS
- [ ] XP deduction happens after successful claim
- [ ] Nonce prevents double claims
- [ ] Contract is pausable in emergency
- [ ] Only owner can withdraw funds

## Support

For integration issues:
1. Check edge function logs in Supabase
2. Verify contract state on BaseScan
3. Test with small amounts first
4. Review this integration guide
5. Check contract event logs
