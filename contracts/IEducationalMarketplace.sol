// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/**
 * @title IEducationalMarketplace
 * @dev Interface for Educational Content Marketplace
 */
interface IEducationalMarketplace {
    // Enums
    enum ContentStatus { Active, Deactivated, Pending }
    enum ContentCategory { Programming, Mathematics, Science, Language, Business, Art, Other }
    
    // Structs
    struct ContentItem {
        uint256 contentId;
        string title;
        string description;
        ContentCategory category;
        bytes32 contentHash;
        uint256 price;
        uint256 royaltyPercent;
        ContentStatus status;
        address payable creator;
        address payable currentOwner;
        uint256 createdAtBlock;
        uint32 totalSales;
        uint32 totalViews;
        uint256 totalEarnings;
    }
    
    struct Creator {
        uint256 totalContent;
        uint256 totalSales;
        uint256 totalEarnings;
        uint256 averageRating;
        uint256 lastContentBlock;
    }
    
    struct Purchase {
        address buyer;
        uint256 contentId;
        uint256 blockNumber;
        uint256 pricePaid;
        uint256 royaltyPaid;
        uint256 platformFeePaid;
        bytes32 purchaseHash;
    }
    
    struct Collaborator {
        address collaboratorAddress;
        uint256 sharePercent;
        bytes32 roleHash;
    }
    
    // Core Functions - only function signatures, no events in interface
    function createContent(
        string calldata title,
        string calldata description,
        ContentCategory category,
        bytes32 contentHash,
        uint256 price,
        uint256 customRoyaltyPercent
    ) external returns (uint256);
    
    function purchaseContent(uint256 contentId) external payable;
    
    function addCollaborators(
        uint256 contentId,
        address[] calldata collaborators,
        uint256[] calldata sharePercents,
        bytes32[] calldata roleHashes
    ) external;
    
    function updateContentPrice(uint256 contentId, uint256 newPrice) external;
}
