// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "./MarketplaceStorage.sol";
import "./MarketplaceErrors.sol";
import "./IEducationalMarketplace.sol";

/**
 * @title MarketplaceViews
 * @dev View functions for Educational Content Marketplace
 */
contract MarketplaceViews is MarketplaceStorage, MarketplaceErrors {
    
    /**
     * @dev Get content details
     */
    function getContentDetails(uint256 _contentId) 
        external 
        view 
        returns (
            string memory title,
            string memory description,
            IEducationalMarketplace.ContentCategory category,
            bytes32 contentHash,
            uint256 price,
            uint256 royaltyPercent,
            IEducationalMarketplace.ContentStatus status,
            address creator,
            address currentOwner,
            uint32 totalSales,
            uint256 createdAt
        ) 
    {
        if (_contentId >= nextContentId) revert ContentNotFound(_contentId);
        IEducationalMarketplace.ContentItem memory content = contentItems[_contentId];
        
        return (
            content.title,
            content.description,
            content.category,
            content.contentHash,
            content.price,
            content.royaltyPercent,
            content.status,
            content.creator,
            content.currentOwner,
            content.totalSales,
            content.createdAtBlock
        );
    }
    
    /**
     * @dev Get content hash (access controlled)
     */
    function getContentHash(uint256 _contentId) 
        external 
        view 
        returns (bytes32) 
    {
        if (_contentId >= nextContentId) revert ContentNotFound(_contentId);
        
        IEducationalMarketplace.ContentItem memory content = contentItems[_contentId];
        if (!userPurchases[msg.sender][_contentId] && 
            content.creator != msg.sender && 
            content.currentOwner != msg.sender) {
            revert UnauthorizedAccess();
        }
        
        return content.contentHash;
    }
    
    /**
     * @dev Get content collaborators
     */
    function getContentCollaborators(uint256 _contentId) 
        external 
        view 
        returns (
            address[] memory collaboratorAddresses,
            uint256[] memory sharePercents,
            bytes32[] memory roleHashes
        ) 
    {
        if (_contentId >= nextContentId) revert ContentNotFound(_contentId);
        
        IEducationalMarketplace.Collaborator[] memory collaborators = contentCollaborators[_contentId];
        collaboratorAddresses = new address[](collaborators.length);
        sharePercents = new uint256[](collaborators.length);
        roleHashes = new bytes32[](collaborators.length);
        
        for (uint256 i = 0; i < collaborators.length; i++) {
            collaboratorAddresses[i] = collaborators[i].collaboratorAddress;
            sharePercents[i] = collaborators[i].sharePercent;
            roleHashes[i] = collaborators[i].roleHash;
        }
    }
    
    /**
     * @dev Get creator statistics
     */
    function getCreatorStats(address _creator) 
        external 
        view 
        returns (
            uint256 totalContent,
            uint256 totalSales,
            uint256 totalEarnings,
            uint256 averageRating,
            uint256 lastContentBlock
        ) 
    {
        IEducationalMarketplace.Creator storage creator = creators[_creator];
        return (
            creator.totalContent,
            creator.totalSales,
            creator.totalEarnings,
            creator.averageRating,
            creator.lastContentBlock
        );
    }
    
    /**
     * @dev Check if user purchased content
     */
    function hasPurchased(address _user, uint256 _contentId) 
        external 
        view 
        returns (bool) 
    {
        return userPurchases[_user][_contentId];
    }
    
    /**
     * @dev Get marketplace statistics
     */
    function getMarketplaceStats() 
        external 
        view 
        returns (
            uint256 totalContent,
            uint256 activeContent,
            uint256 totalSalesCount,
            uint256 totalRevenueAmount,
            uint256 currentBlock
        ) 
    {
        return (
            nextContentId,
            totalActiveContent,
            totalSales,
            totalRevenue,
            block.number
        );
    }
    
    /**
     * @dev Get active content IDs with pagination
     */
    function getActiveContentIds(uint256 _offset, uint256 _limit) 
        external 
        view 
        returns (uint256[] memory contentIds, uint256 totalActive) 
    {
        uint256[] memory activeIds = new uint256[](_limit);
        uint256 count = 0;
        uint256 activeCount = 0;
        
        for (uint256 i = 0; i < nextContentId && count < _limit; i++) {
            if (contentItems[i].status == IEducationalMarketplace.ContentStatus.Active) {
                if (activeCount >= _offset) {
                    activeIds[count] = i;
                    count++;
                }
                activeCount++;
            }
        }
        
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = activeIds[i];
        }
        
        return (result, activeCount);
    }
    
    /**
     * @dev Get content by category
     */
    function getContentByCategory(
        IEducationalMarketplace.ContentCategory _category, 
        uint256 _offset, 
        uint256 _limit
    ) 
        external 
        view 
        returns (uint256[] memory contentIds, uint256 totalMatching) 
    {
        uint256[] memory matchingIds = new uint256[](_limit);
        uint256 count = 0;
        uint256 matchingCount = 0;
        
        for (uint256 i = 0; i < nextContentId && count < _limit; i++) {
            if (contentItems[i].status == IEducationalMarketplace.ContentStatus.Active && 
                contentItems[i].category == _category) {
                if (matchingCount >= _offset) {
                    matchingIds[count] = i;
                    count++;
                }
                matchingCount++;
            }
        }
        
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = matchingIds[i];
        }
        
        return (result, matchingCount);
    }
    
    /**
     * @dev Get content by price range
     */
    function getContentByPriceRange(
        uint256 _minPrice,
        uint256 _maxPrice,
        uint256 _offset,
        uint256 _limit
    ) 
        external 
        view 
        returns (uint256[] memory contentIds, uint256 totalMatching) 
    {
        uint256[] memory matchingIds = new uint256[](_limit);
        uint256 count = 0;
        uint256 matchingCount = 0;
        
        for (uint256 i = 0; i < nextContentId && count < _limit; i++) {
            if (contentItems[i].status == IEducationalMarketplace.ContentStatus.Active && 
                contentItems[i].price >= _minPrice && 
                contentItems[i].price <= _maxPrice) {
                if (matchingCount >= _offset) {
                    matchingIds[count] = i;
                    count++;
                }
                matchingCount++;
            }
        }
        
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = matchingIds[i];
        }
        
        return (result, matchingCount);
    }
    
    /**
     * @dev Get trending content by sales
     */
    function getTrendingContentIds(uint256 _limit) 
        external 
        view 
        returns (uint256[] memory contentIds) 
    {
        uint256[] memory activeIds = new uint256[](totalActiveContent);
        uint256 activeCount = 0;
        
        for (uint256 i = 0; i < nextContentId; i++) {
            if (contentItems[i].status == IEducationalMarketplace.ContentStatus.Active) {
                activeIds[activeCount] = i;
                activeCount++;
            }
        }
        
        // Sort by total sales
        for (uint256 i = 0; i < activeCount; i++) {
            for (uint256 j = i + 1; j < activeCount; j++) {
                if (contentItems[activeIds[i]].totalSales < contentItems[activeIds[j]].totalSales) {
                    uint256 temp = activeIds[i];
                    activeIds[i] = activeIds[j];
                    activeIds[j] = temp;
                }
            }
        }
        
        uint256 resultCount = _limit > activeCount ? activeCount : _limit;
        contentIds = new uint256[](resultCount);
        
        for (uint256 i = 0; i < resultCount; i++) {
            contentIds[i] = activeIds[i];
        }
    }
    
    /**
     * @dev Get user's purchase history
     */
    function getUserPurchaseHistory(address _user) 
        external 
        view 
        returns (uint256[] memory contentIds) 
    {
        return userPurchaseHistory[_user];
    }
    
    /**
     * @dev Get creator's content
     */
    function getCreatorContent(address _creator) 
        external 
        view 
        returns (uint256[] memory) 
    {
        return creatorContent[_creator];
    }
    
    /**
     * @dev Check if user can create content
     */
    function canUserCreateContent(address _user) 
        external 
        view 
        returns (bool canCreate, bytes32 statusHash) 
    {
        if (emergencyStop) {
            return (false, keccak256("Emergency stop active"));
        }
        
        if (blacklistedUsers[_user]) {
            return (false, keccak256("User blacklisted"));
        }
        
        uint256 blocksPassed = block.number - creators[_user].lastContentBlock;
        if (blocksPassed < creationCooldownBlocks) {
            return (false, keccak256("Creation cooldown active"));
        }
        
        uint256 today = block.number / BLOCKS_PER_DAY;
        if (dailyUploads[_user][today] >= dailyUploadLimit) {
            return (false, keccak256("Daily upload limit reached"));
        }
        
        return (true, keccak256("Ready"));
    }
    
    /**
     * @dev Get daily upload status
     */
    function getDailyUploadStatus(address _user) 
        external 
        view 
        returns (uint256 todayUploads, uint256 remainingUploads) 
    {
        uint256 today = block.number / BLOCKS_PER_DAY;
        todayUploads = dailyUploads[_user][today];
        remainingUploads = todayUploads >= dailyUploadLimit ? 0 : dailyUploadLimit - todayUploads;
    }
    
    /**
     * @dev Calculate purchase preview
     */
    function calculatePurchasePreview(uint256 _contentId) 
        external 
        view 
        returns (
            uint256 contentPrice,
            uint256 platformFee,
            uint256 royaltyAmount,
            uint256 sellerAmount,
            uint256 totalRequired
        ) 
    {
        if (_contentId >= nextContentId) revert ContentNotFound(_contentId);
        
        IEducationalMarketplace.ContentItem memory content = contentItems[_contentId];
        contentPrice = content.price;
        platformFee = (contentPrice * platformFeePercent) / BASIS_POINTS;
        royaltyAmount = (contentPrice * content.royaltyPercent) / BASIS_POINTS;
        sellerAmount = contentPrice - platformFee - royaltyAmount;
        totalRequired = contentPrice;
    }
    
    /**
     * @dev Get user's creation cooldown status
     */
    function getUserCooldown(address _user) 
        external 
        view 
        returns (
            uint256 blocksRemaining,
            bool canCreate
        ) 
    {
        uint256 blocksPassed = block.number - creators[_user].lastContentBlock;
        
        if (blocksPassed >= creationCooldownBlocks) {
            return (0, true);
        } else {
            return (creationCooldownBlocks - blocksPassed, false);
 }
}
}
