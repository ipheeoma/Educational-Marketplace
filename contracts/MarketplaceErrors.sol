// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/**
 * @title MarketplaceErrors
 * @dev Custom errors for Educational Content Marketplace
 */
contract MarketplaceErrors {
    // Content errors
    error ContentNotFound(uint256 contentId);
    error ContentNotActive(uint256 contentId);
    error ContentAlreadyPurchased(uint256 contentId);
    error InvalidContentData();
    
    // User access errors
    error UserIsBlacklisted();
    error UnauthorizedAccess();
    error CreationCooldownActive(uint256 remainingBlocks);
    
    // System errors
    error EmergencyStopActive();
    error InvalidPrice(uint256 price);
    error InvalidRoyaltyPercent(uint256 percent);
    error InsufficientPayment(uint256 required, uint256 provided);
    
    // Limit errors
    error DailyLimitExceeded(uint256 current, uint256 limit);
    error TooManyCollaborators();
    error InvalidCollaboratorShare();
}