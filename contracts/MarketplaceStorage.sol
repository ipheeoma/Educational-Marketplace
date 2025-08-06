// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "./IEducationalMarketplace.sol";

/**
 * @title MarketplaceStorage
 * @dev Storage contract for Educational Content Marketplace
 */
contract MarketplaceStorage {
    
    // Role definitions
    bytes32 public constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");
    bytes32 public constant CONTENT_MANAGER_ROLE = keccak256("CONTENT_MANAGER_ROLE");
    bytes32 public constant EMERGENCY_ROLE = keccak256("EMERGENCY_ROLE");
    
    // State variables
    mapping(uint256 => IEducationalMarketplace.ContentItem) public contentItems;
    mapping(address => IEducationalMarketplace.Creator) public creators;
    mapping(address => mapping(uint256 => bool)) public userPurchases;
    mapping(address => bool) public blacklistedUsers;
    mapping(uint256 => IEducationalMarketplace.Collaborator[]) public contentCollaborators;
    mapping(address => uint256[]) public creatorContent;
    mapping(address => uint256[]) public userPurchaseHistory;
    IEducationalMarketplace.Purchase[] public purchases;
    
    // Content management
    uint256 public nextContentId;
    uint256 public totalActiveContent;
    uint256 public totalSales;
    uint256 public totalRevenue;
    
    // Platform parameters
    uint256 public platformFeePercent = 250; // 2.5%
    uint256 public defaultRoyaltyPercent = 1000; // 10%
    uint256 public maxRoyaltyPercent = 5000; // 50%
    uint256 public minContentPrice = 1000000000000000; // 0.001 ETH
    uint256 public maxContentPrice = 10000000000000000000; // 10 ETH
    uint256 public creationCooldownBlocks = 10;
    uint256 public minDescriptionLength = 50;
    uint256 public maxDescriptionLength = 1000;
    
    // Security parameters
    uint256 public dailyUploadLimit = 10;
    uint256 public maxCollaborators = 10;
    mapping(address => mapping(uint256 => uint256)) public dailyUploads;
    
    // Constants
    uint256 public constant BASIS_POINTS = 10000;
    uint256 public constant MIN_TITLE_LENGTH = 5;
    uint256 public constant MAX_TITLE_LENGTH = 100;
    uint256 public constant MAX_BATCH_SIZE = 20;
    uint256 public constant BLOCKS_PER_DAY = 5760;
    
    // Circuit breakers
    bool public emergencyStop = false;
    
    // Additional mappings for creator tracking
    mapping(address => mapping(uint256 => bool)) internal createdContent;
    mapping(address => mapping(address => bool)) internal purchasedFrom;
}
