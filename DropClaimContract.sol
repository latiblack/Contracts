// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract DropClaimContract is Ownable, Pausable, ReentrancyGuard {
    using ECDSA for bytes32;

    // Backend signer address
    address public backendSigner;

    // Token addresses
    address public constant USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913; // Base mainnet USDC
    
    // Tier amounts in USD (6 decimals for USDC)
    uint256 public constant TIER1_AMOUNT = 10 * 10**6;  // $10
    uint256 public constant TIER2_AMOUNT = 5 * 10**6;   // $5
    uint256 public constant TIER3_AMOUNT = 10**5;       // $0.1
    
    // Track claimed drops per user per drop campaign
    mapping(string => mapping(address => bool)) public hasClaimed;
    
    event DropClaimed(
        address indexed user,
        string indexed dropId,
        uint8 tier,
        uint256 amount,
        string tokenType
    );
    
    event FundsWithdrawn(
        address indexed token,
        address indexed to,
        uint256 amount
    );

    constructor(address _backendSigner) {
        require(_backendSigner != address(0), "Invalid signer address");
        backendSigner = _backendSigner;
    }

    /**
     * @notice Claim drop reward based on eligibility tier
     * @param dropId The unique drop campaign ID
     * @param tier Eligibility tier (1, 2, or 3)
     * @param tokenType Token to claim ("ETH" or "USDC")
     * @param nonce Unique nonce for this claim
     * @param signature Backend signature proving eligibility
     */
    function claimDrop(
        string memory dropId,
        uint8 tier,
        string memory tokenType,
        bytes32 nonce,
        bytes memory signature
    ) external nonReentrant whenNotPaused {
        require(tier >= 1 && tier <= 3, "Invalid tier");
        require(!hasClaimed[dropId][msg.sender], "Already claimed this drop");
        
        // Verify signature
        bytes32 messageHash = keccak256(abi.encodePacked(
            msg.sender,
            dropId,
            tier,
            tokenType,
            nonce
        ));
        
        bytes32 ethSignedMessageHash = messageHash.toEthSignedMessageHash();
        address recoveredSigner = ethSignedMessageHash.recover(signature);
        
        require(recoveredSigner == backendSigner, "Invalid signature");
        
        // Mark as claimed
        hasClaimed[dropId][msg.sender] = true;
        
        // Determine claim amount based on tier
        uint256 claimAmount;
        if (tier == 1) {
            claimAmount = TIER1_AMOUNT;
        } else if (tier == 2) {
            claimAmount = TIER2_AMOUNT;
        } else {
            claimAmount = TIER3_AMOUNT;
        }
        
        // Transfer tokens
        if (keccak256(bytes(tokenType)) == keccak256(bytes("ETH"))) {
            // For ETH, convert USDC amount to ETH equivalent (simplified 1:1 for demo)
            uint256 ethAmount = claimAmount * 10**12; // Convert from 6 to 18 decimals
            require(address(this).balance >= ethAmount, "Insufficient ETH balance");
            payable(msg.sender).transfer(ethAmount);
        } else if (keccak256(bytes(tokenType)) == keccak256(bytes("USDC"))) {
            require(IERC20(USDC).transfer(msg.sender, claimAmount), "USDC transfer failed");
        } else {
            revert("Invalid token type");
        }
        
        emit DropClaimed(msg.sender, dropId, tier, claimAmount, tokenType);
    }

    /**
     * @notice Check if user has claimed a specific drop
     */
    function hasClaimedDrop(string memory dropId, address user) external view returns (bool) {
        return hasClaimed[dropId][user];
    }

    /**
     * @notice Update backend signer address
     */
    function updateBackendSigner(address newSigner) external onlyOwner {
        require(newSigner != address(0), "Invalid signer address");
        backendSigner = newSigner;
    }

    /**
     * @notice Withdraw tokens from contract
     */
    function withdrawTokens(address token, address to, uint256 amount) external onlyOwner {
        require(to != address(0), "Invalid recipient");
        
        if (token == address(0)) {
            // Withdraw ETH
            require(address(this).balance >= amount, "Insufficient ETH balance");
            payable(to).transfer(amount);
        } else {
            // Withdraw ERC20
            require(IERC20(token).transfer(to, amount), "Token transfer failed");
        }
        
        emit FundsWithdrawn(token, to, amount);
    }

    /**
     * @notice Pause contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Receive ETH
     */
    receive() external payable {}
}
