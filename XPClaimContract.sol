// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title XPClaimContract
 * @notice Allows users to claim tokens (ETH, USDC, IRYS) by burning XP
 * @dev Uses signature verification to prevent unauthorized claims
 */
contract XPClaimContract is Ownable, ReentrancyGuard, Pausable {
    // Token addresses on Base mainnet
    address public constant USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
    address public irysToken;
    
    // Backend signer address for signature verification
    address public backendSigner;
    
    // Conversion rates (XP to token amount)
    // IRYS: 100 XP = 1 IRYS (rate = 100)
    // USDC: 1000 XP = 0.1 USDC = 100000 (rate = 10000000, USDC has 6 decimals)
    // ETH: Dynamic based on USD price, 1000 XP = 0.1 USD worth
    uint256 public constant IRYS_RATE = 100; // 100 XP = 1 IRYS (18 decimals)
    uint256 public constant USDC_RATE = 10000000; // For 0.1 USDC per 1000 XP (6 decimals)
    
    // Track claimed amounts to prevent double claims
    mapping(address => mapping(bytes32 => bool)) public claimedSignatures;
    
    // Events
    event TokensClaimed(
        address indexed user,
        string tokenType,
        uint256 xpAmount,
        uint256 tokenAmount
    );
    event BackendSignerUpdated(address indexed oldSigner, address indexed newSigner);
    event IrysTokenUpdated(address indexed oldToken, address indexed newToken);
    event FundsWithdrawn(address indexed token, uint256 amount);
    
    constructor(address _backendSigner, address _irysToken) {
        require(_backendSigner != address(0), "Invalid signer");
        backendSigner = _backendSigner;
        irysToken = _irysToken;
    }
    
    /**
     * @notice Claim tokens by providing XP amount and backend signature
     * @param xpAmount Amount of XP to burn (must be multiple of 100)
     * @param tokenType Type of token to claim ("IRYS", "BASE_USDC", "BASE_ETH")
     * @param signature Backend signature to verify the claim
     * @param nonce Unique nonce to prevent replay attacks
     */
    function claimTokens(
        uint256 xpAmount,
        string calldata tokenType,
        uint256 ethPriceUSD, // Current ETH price in USD (with 8 decimals, e.g., 300000000000 = $3000)
        bytes calldata signature,
        bytes32 nonce
    ) external nonReentrant whenNotPaused {
        require(xpAmount >= 100 && xpAmount % 100 == 0, "Invalid XP amount");
        require(!claimedSignatures[msg.sender][nonce], "Already claimed");
        
        // Verify signature
        bytes32 messageHash = getMessageHash(msg.sender, xpAmount, tokenType, ethPriceUSD, nonce);
        require(verifySignature(messageHash, signature), "Invalid signature");
        
        // Mark as claimed
        claimedSignatures[msg.sender][nonce] = true;
        
        // Calculate token amount and transfer
        uint256 tokenAmount;
        
        if (keccak256(bytes(tokenType)) == keccak256(bytes("BASE_ETH"))) {
            // ETH claiming: 1000 XP = $0.10 worth of ETH
            tokenAmount = calculateEthAmount(xpAmount, ethPriceUSD);
            require(address(this).balance >= tokenAmount, "Insufficient ETH");
            (bool success, ) = msg.sender.call{value: tokenAmount}("");
            require(success, "ETH transfer failed");
            
        } else if (keccak256(bytes(tokenType)) == keccak256(bytes("BASE_USDC"))) {
            // USDC claiming: 1000 XP = 0.1 USDC (100000 units with 6 decimals)
            tokenAmount = (xpAmount * 1e6) / USDC_RATE;
            require(IERC20(USDC).transfer(msg.sender, tokenAmount), "USDC transfer failed");
            
        } else if (keccak256(bytes(tokenType)) == keccak256(bytes("IRYS"))) {
            // IRYS claiming: 100 XP = 1 IRYS
            tokenAmount = (xpAmount * 1e18) / IRYS_RATE;
            require(irysToken != address(0), "IRYS token not set");
            require(IERC20(irysToken).transfer(msg.sender, tokenAmount), "IRYS transfer failed");
            
        } else {
            revert("Invalid token type");
        }
        
        emit TokensClaimed(msg.sender, tokenType, xpAmount, tokenAmount);
    }
    
    /**
     * @notice Calculate ETH amount based on XP and current ETH price
     * @param xpAmount Amount of XP
     * @param ethPriceUSD Current ETH price in USD (8 decimals)
     * @return Amount of ETH to send (18 decimals)
     */
    function calculateEthAmount(uint256 xpAmount, uint256 ethPriceUSD) public pure returns (uint256) {
        // 1000 XP = $0.10 USD worth of ETH
        // usdValue = (xpAmount * 0.10) / 1000 = xpAmount / 10000 USD
        // ethAmount = usdValue / ethPriceUSD
        // ethAmount = (xpAmount * 1e18) / (10000 * ethPriceUSD / 1e8)
        // ethAmount = (xpAmount * 1e26) / (10000 * ethPriceUSD)
        return (xpAmount * 1e26) / (10000 * ethPriceUSD);
    }
    
    /**
     * @notice Get message hash for signature verification
     */
    function getMessageHash(
        address user,
        uint256 xpAmount,
        string calldata tokenType,
        uint256 ethPriceUSD,
        bytes32 nonce
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(user, xpAmount, tokenType, ethPriceUSD, nonce));
    }
    
    /**
     * @notice Verify signature
     */
    function verifySignature(bytes32 messageHash, bytes memory signature) internal view returns (bool) {
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, signature) == backendSigner;
    }
    
    function getEthSignedMessageHash(bytes32 messageHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
    }
    
    function recoverSigner(bytes32 ethSignedMessageHash, bytes memory signature) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);
        return ecrecover(ethSignedMessageHash, v, r, s);
    }
    
    function splitSignature(bytes memory sig) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "Invalid signature length");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }
    
    // Admin functions
    function updateBackendSigner(address newSigner) external onlyOwner {
        require(newSigner != address(0), "Invalid signer");
        address oldSigner = backendSigner;
        backendSigner = newSigner;
        emit BackendSignerUpdated(oldSigner, newSigner);
    }
    
    function updateIrysToken(address newToken) external onlyOwner {
        address oldToken = irysToken;
        irysToken = newToken;
        emit IrysTokenUpdated(oldToken, newToken);
    }
    
    function pause() external onlyOwner {
        _pause();
    }
    
    function unpause() external onlyOwner {
        _unpause();
    }
    
    function withdrawTokens(address token, uint256 amount) external onlyOwner {
        if (token == address(0)) {
            (bool success, ) = owner().call{value: amount}("");
            require(success, "ETH withdrawal failed");
        } else {
            require(IERC20(token).transfer(owner(), amount), "Token withdrawal failed");
        }
        emit FundsWithdrawn(token, amount);
    }
    
    // Allow contract to receive ETH
    receive() external payable {}
}
