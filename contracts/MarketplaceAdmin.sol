// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import "./MarketplaceStorage.sol";
import "./MarketplaceErrors.sol";
import "./IEducationalMarketplace.sol";

/**
 * @title MarketplaceAdmin
 * @dev Admin functions for Educational Content Marketplace
 */
contract MarketplaceAdmin is MarketplaceStorage, MarketplaceErrors, AccessControl {
    using Address for address payable;
    
    // Events
    event ContentStatusChanged(
        uint256 indexed contentId,
        IEducationalMarketplace.ContentStatus oldStatus,
        IEducationalMarketplace.ContentStatus newStatus,
        address indexed moderator
    );
    
    event EmergencyAction(
        address indexed admin,
        bytes32 actionHash,
        address indexed target,
        uint256 blockNumber
    );
    
    event PlatformFunded(address indexed funder, uint256 amount);
    event UserBlacklisted(address indexed user, bytes32 reasonHash);
    event UserWhitelisted(address indexed user);
    
    /**
     * @dev Update platform parameters
     */
    function updatePlatformParameters(
        uint256 _platformFeePercent,
        uint256 _defaultRoyaltyPercent,
        uint256 _maxRoyaltyPercent,
        uint256 _creationCooldownBlocks
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_platformFeePercent <= 1000, "Platform fee too high");
        require(_defaultRoyaltyPercent <= 2500, "Default royalty too high");
        require(_maxRoyaltyPercent <= 5000, "Max royalty too high");
        require(_creationCooldownBlocks >= 1 && _creationCooldownBlocks <= 100, "Invalid cooldown");
        
        platformFeePercent = _platformFeePercent;
        defaultRoyaltyPercent = _defaultRoyaltyPercent;
        maxRoyaltyPercent = _maxRoyaltyPercent;
        creationCooldownBlocks = _creationCooldownBlocks;
        
        emit EmergencyAction(msg.sender, keccak256("Platform parameters updated"), address(0), block.number);
    }
    
    /**
     * @dev Update security parameters
     */
    function updateSecurityParameters(
        uint256 _minContentPrice,
        uint256 _maxContentPrice,
        uint256 _dailyUploadLimit,
        uint256 _maxCollaborators
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_minContentPrice > 0, "Invalid min price");
        require(_maxContentPrice > _minContentPrice, "Invalid max price");
        require(_dailyUploadLimit > 0 && _dailyUploadLimit <= 50, "Invalid upload limit");
        require(_maxCollaborators > 0 && _maxCollaborators <= 20, "Invalid max collaborators");
        
        minContentPrice = _minContentPrice;
        maxContentPrice = _maxContentPrice;
        dailyUploadLimit = _dailyUploadLimit;
        maxCollaborators = _maxCollaborators;
        
        emit EmergencyAction(msg.sender, keccak256("Security parameters updated"), address(0), block.number);
    }
    
    /**
     * @dev Blacklist user
     */
    function blacklistUser(address _user, bytes32 _reasonHash) 
        external 
        onlyRole(MODERATOR_ROLE) 
    {
        blacklistedUsers[_user] = true;
        emit UserBlacklisted(_user, _reasonHash);
        emit EmergencyAction(msg.sender, _reasonHash, _user, block.number);
    }
    
    /**
     * @dev Whitelist user
     */
    function whitelistUser(address _user) 
        external 
        onlyRole(MODERATOR_ROLE) 
    {
        blacklistedUsers[_user] = false;
        emit UserWhitelisted(_user);
        emit EmergencyAction(msg.sender, keccak256("User whitelisted"), _user, block.number);
    }
    
    /**
     * @dev Emergency circuit breaker
     */
    function activateEmergencyStop() external onlyRole(EMERGENCY_ROLE) {
        emergencyStop = true;
        emit EmergencyAction(msg.sender, keccak256("Emergency stop activated"), address(0), block.number);
    }
    
    /**
     * @dev Reset emergency state
     */
    function resetEmergencyState() external onlyRole(DEFAULT_ADMIN_ROLE) {
        emergencyStop = false;
        emit EmergencyAction(msg.sender, keccak256("Emergency state reset"), address(0), block.number);
    }
    
    /**
     * @dev Moderate content status
     */
    function moderateContent(uint256 _contentId, IEducationalMarketplace.ContentStatus _newStatus) 
        external 
        onlyRole(MODERATOR_ROLE) 
    {
        if (_contentId >= nextContentId) revert ContentNotFound(_contentId);
        
        IEducationalMarketplace.ContentItem storage content = contentItems[_contentId];
        IEducationalMarketplace.ContentStatus oldStatus = content.status;
        
        if (oldStatus == IEducationalMarketplace.ContentStatus.Active && _newStatus != IEducationalMarketplace.ContentStatus.Active) {
            totalActiveContent--;
        } else if (oldStatus != IEducationalMarketplace.ContentStatus.Active && _newStatus == IEducationalMarketplace.ContentStatus.Active) {
            totalActiveContent++;
        }
        
        content.status = _newStatus;
        
        emit ContentStatusChanged(_contentId, oldStatus, _newStatus, msg.sender);
        emit EmergencyAction(msg.sender, keccak256("Content moderated"), address(uint160(_contentId)), block.number);
    }
    
    /**
     * @dev Batch moderate content
     */
    function batchModerateContent(uint256[] calldata _contentIds, IEducationalMarketplace.ContentStatus _newStatus) 
        external 
        onlyRole(MODERATOR_ROLE) 
    {
        require(_contentIds.length <= MAX_BATCH_SIZE, "Batch too large");
        
        for (uint256 i = 0; i < _contentIds.length; i++) {
            uint256 contentId = _contentIds[i];
            if (contentId < nextContentId) {
                IEducationalMarketplace.ContentItem storage content = contentItems[contentId];
                IEducationalMarketplace.ContentStatus oldStatus = content.status;
                
                if (oldStatus == IEducationalMarketplace.ContentStatus.Active && _newStatus != IEducationalMarketplace.ContentStatus.Active) {
                    totalActiveContent--;
                } else if (oldStatus != IEducationalMarketplace.ContentStatus.Active && _newStatus == IEducationalMarketplace.ContentStatus.Active) {
                    totalActiveContent++;
                }
                
                content.status = _newStatus;
                emit ContentStatusChanged(contentId, oldStatus, _newStatus, msg.sender);
            }
        }
    }
    
    /**
     * @dev Withdraw platform fees
     */
    function withdraw(uint256 _amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_amount > 0, "Invalid amount");
        require(_amount <= address(this).balance, "Insufficient balance");
        
        payable(msg.sender).sendValue(_amount);
        emit EmergencyAction(msg.sender, keccak256("Withdrawal"), address(0), block.number);
    }
    
    /**
     * @dev Fund platform
     */
    function fundPlatform() external payable {
        require(msg.value > 0, "Invalid amount");
        emit PlatformFunded(msg.sender, msg.value);
    }
    
    /**
     * @dev Get platform security status
     */
    function getSecurityStatus() 
        external 
        view 
        returns (
            bool emergencyActive,
            uint256 platformBalance,
            uint256 totalActiveContentCount,
            uint256 currentBlock
        ) 
    {
        return (
            emergencyStop,
            address(this).balance,
            totalActiveContent,
            block.number
  );
}
}
