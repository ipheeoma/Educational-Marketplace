// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import "./MarketplaceCore.sol";
import "./MarketplaceViews.sol";
import "./MarketplaceAdmin.sol";
import "./IEducationalMarketplace.sol";

/**
 * @title Educational Content Marketplace
 * @dev Pure on-chain marketplace for educational content with royalty distribution
 * @notice EduMarket - On-chain educational content trading platform
 */
contract EducationalContentMarketplace is 
    Ownable, 
    ReentrancyGuard, 
    Pausable, 
    MarketplaceCore, 
    MarketplaceViews, 
    MarketplaceAdmin
{
    
    // Additional events not in core modules
    event ContentPriceUpdated(
        uint256 indexed contentId,
        uint256 oldPrice,
        uint256 newPrice,
        address indexed creator
    );
    
    constructor(address initialOwner) Ownable(initialOwner) {
        _grantRole(DEFAULT_ADMIN_ROLE, initialOwner);
        _grantRole(MODERATOR_ROLE, initialOwner);
        _grantRole(CONTENT_MANAGER_ROLE, initialOwner);
        _grantRole(EMERGENCY_ROLE, initialOwner);
    }
    
    /**
     * @dev Create new educational content
     */
    function createContent(
        string calldata _title,
        string calldata _description,
        IEducationalMarketplace.ContentCategory _category,
        bytes32 _contentHash,
        uint256 _price,
        uint256 _customRoyaltyPercent
    ) 
        external 
        nonReentrant 
        whenNotPaused 
        notBlacklisted(msg.sender) 
        notEmergencyStop 
        creationCooldownPassed(msg.sender) 
        returns (uint256) 
    {
        return _createContent(_title, _description, _category, _contentHash, _price, _customRoyaltyPercent);
    }
    
    /**
     * @dev Add collaborators to content
     */
    function addCollaborators(
        uint256 _contentId,
        address[] calldata _collaborators,
        uint256[] calldata _sharePercents,
        bytes32[] calldata _roleHashes
    ) 
        external 
        validActiveContent(_contentId) 
        onlyContentCreator(_contentId) 
    {
        _addCollaborators(_contentId, _collaborators, _sharePercents, _roleHashes);
    }
    
    /**
     * @dev Purchase content with automatic royalty distribution
     */
    function purchaseContent(uint256 _contentId) 
        external 
        payable 
        nonReentrant 
        whenNotPaused 
        validActiveContent(_contentId) 
        notBlacklisted(msg.sender) 
        notEmergencyStop 
    {
        _purchaseContent(_contentId);
    }
    
    /**
     * @dev Update content price
     */
    function updateContentPrice(uint256 _contentId, uint256 _newPrice) 
        external 
        validActiveContent(_contentId) 
        onlyContentCreator(_contentId) 
    {
        if (_newPrice < minContentPrice || _newPrice > maxContentPrice) {
            revert InvalidPrice(_newPrice);
        }
        
        uint256 oldPrice = contentItems[_contentId].price;
        contentItems[_contentId].price = _newPrice;
        
        emit ContentPriceUpdated(_contentId, oldPrice, _newPrice, msg.sender);
    }
    
    /**
     * @dev Toggle content status
     */
    function toggleContentStatus(uint256 _contentId) 
        external 
        onlyContentCreator(_contentId) 
    {
        IEducationalMarketplace.ContentItem storage content = contentItems[_contentId];
        IEducationalMarketplace.ContentStatus oldStatus = content.status;
        
        if (content.status == IEducationalMarketplace.ContentStatus.Active) {
            content.status = IEducationalMarketplace.ContentStatus.Deactivated;
            totalActiveContent--;
        } else if (content.status == IEducationalMarketplace.ContentStatus.Deactivated) {
            content.status = IEducationalMarketplace.ContentStatus.Active;
            totalActiveContent++;
        }
        
        emit ContentStatusChanged(_contentId, oldStatus, content.status, msg.sender);
    }
    
    /**
     * @dev Pause platform
     */
    function pause() external onlyOwner {
        _pause();
    }
    
    /**
     * @dev Unpause platform
     */
    function unpause() external onlyOwner {
        _unpause();
    }
    
    /**
     * @dev Generate deterministic content hash
     */
    function generateContentHash(
        address _creator,
        string calldata _title,
        string calldata _description,
        uint256 _timestamp
    ) 
        external 
        pure 
        returns (bytes32) 
    {
        return keccak256(abi.encodePacked(_creator, _title, _description, _timestamp));
    }
    
    /**
     * @dev Verify content integrity
     */
    function verifyContentIntegrity(
        uint256 _contentId,
        bytes32 _expectedHash
    ) 
        external 
        view 
        returns (bool isValid) 
    {
        if (_contentId >= nextContentId) return false;
        return contentItems[_contentId].contentHash == _expectedHash;
    }
    
    /**
     * @dev Get purchase by hash
     */
    function getPurchaseByHash(bytes32 _purchaseHash) 
        external 
        view 
        returns (
            address buyer,
            uint256 contentId,
            uint256 blockNumber,
            uint256 pricePaid,
            bool found
        ) 
    {
        for (uint256 i = 0; i < purchases.length; i++) {
            if (purchases[i].purchaseHash == _purchaseHash) {
                IEducationalMarketplace.Purchase memory purchase = purchases[i];
                return (
                    purchase.buyer,
                    purchase.contentId,
                    purchase.blockNumber,
                    purchase.pricePaid,
                    true
                );
            }
        }
        return (address(0), 0, 0, 0, false);
    }
    
    /**
     * @dev Get recent purchases with pagination
     */
    function getRecentPurchases(uint256 _offset, uint256 _limit) 
        external 
        view 
        returns (IEducationalMarketplace.Purchase[] memory recentPurchases) 
    {
        uint256 totalPurchases = purchases.length;
        if (totalPurchases == 0 || _offset >= totalPurchases) {
            return new IEducationalMarketplace.Purchase[](0);
        }
        
        uint256 end = _offset + _limit;
        if (end > totalPurchases) {
            end = totalPurchases;
        }
        
        uint256 count = end - _offset;
        recentPurchases = new IEducationalMarketplace.Purchase[](count);
        
        // Return in reverse order (most recent first)
        for (uint256 i = 0; i < count; i++) {
            recentPurchases[i] = purchases[totalPurchases - 1 - _offset - i];
        }
    }
    
    /**
     * @dev Get content statistics
     */
    function getContentStats(uint256 _contentId) 
        external 
        view 
        returns (
            uint32 totalSales,
            uint32 totalViews,
            uint256 totalEarnings,
            uint256 createdAt,
            IEducationalMarketplace.ContentStatus status,
            address creator
        ) 
    {
        if (_contentId >= nextContentId) revert ContentNotFound(_contentId);
        
        IEducationalMarketplace.ContentItem memory content = contentItems[_contentId];
        
        return (
            content.totalSales,
            content.totalViews,
            content.totalEarnings,
            content.createdAtBlock,
            content.status,
            content.creator
        );
    }
    
    /**
     * @dev Get multiple content items by IDs (batch query)
     */
    function getContentBatch(uint256[] calldata _contentIds) 
        external 
        view 
        returns (
            bytes32[] memory titleHashes,
            uint256[] memory prices,
            IEducationalMarketplace.ContentCategory[] memory categories,
            IEducationalMarketplace.ContentStatus[] memory statuses
        ) 
    {
        uint256 length = _contentIds.length;
        titleHashes = new bytes32[](length);
        prices = new uint256[](length);
        categories = new IEducationalMarketplace.ContentCategory[](length);
        statuses = new IEducationalMarketplace.ContentStatus[](length);
        
        for (uint256 i = 0; i < length; i++) {
            uint256 contentId = _contentIds[i];
            if (contentId < nextContentId) {
                IEducationalMarketplace.ContentItem memory content = contentItems[contentId];
                titleHashes[i] = keccak256(abi.encodePacked(content.title));
                prices[i] = content.price;
                categories[i] = content.category;
                statuses[i] = content.status;
            }
        }
    }
    
    /**
     * @dev Get creator performance metrics
     */
    function getCreatorMetrics(address _creator) 
        external 
        view 
        returns (
            uint256 totalContentCreated,
            uint256 totalSalesCount,
            uint256 totalEarningsAmount,
            uint256 averageContentPrice,
            uint256 todayUploads
        ) 
    {
        IEducationalMarketplace.Creator storage creator = creators[_creator];
        
        // Calculate average price from on-chain data
        uint256[] memory creatorContentIds = creatorContent[_creator];
        uint256 totalPrice = 0;
        uint256 activeContentCount = 0;
        
        for (uint256 i = 0; i < creatorContentIds.length; i++) {
            uint256 contentId = creatorContentIds[i];
            if (contentItems[contentId].status == IEducationalMarketplace.ContentStatus.Active) {
                totalPrice += contentItems[contentId].price;
                activeContentCount++;
            }
        }
        
        uint256 avgPrice = activeContentCount > 0 ? totalPrice / activeContentCount : 0;
        
        // Get today's uploads
        uint256 today = block.number / BLOCKS_PER_DAY;
        uint256 todayUploadsCount = dailyUploads[_creator][today];
        
        return (
            creator.totalContent,
            creator.totalSales,
            creator.totalEarnings,
            avgPrice,
            todayUploadsCount
        );
    }
    
    // Fallback and receive functions
    receive() external payable {
        emit PlatformFunded(msg.sender, msg.value);
    }
    
    fallback() external {
        revert("Function not found");
    }
}
