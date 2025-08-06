// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import "./MarketplaceStorage.sol";
import "./MarketplaceErrors.sol";
import "./IEducationalMarketplace.sol";

/**
 * @title MarketplaceCore
 * @dev Core functionality for Educational Content Marketplace
 */
contract MarketplaceCore is MarketplaceStorage, MarketplaceErrors {
    using Address for address payable;
    
    // Events
    event ContentCreated(
        uint256 indexed contentId,
        address indexed creator,
        bytes32 indexed titleHash,
        uint256 price,
        IEducationalMarketplace.ContentCategory category,
        uint256 blockNumber
    );
    
    event ContentPurchased(
        address indexed buyer,
        uint256 indexed contentId,
        address indexed seller,
        uint256 price,
        uint256 royaltyPaid,
        bytes32 purchaseHash
    );
    
    event RoyaltyDistributed(
        uint256 indexed contentId,
        address indexed recipient,
        uint256 amount,
        bytes32 roleHash
    );
    
    event CollaboratorAdded(
        uint256 indexed contentId,
        address indexed collaborator,
        uint256 sharePercent,
        bytes32 roleHash
    );
    
    // Modifiers
    modifier validActiveContent(uint256 _contentId) {
        if (_contentId >= nextContentId) revert ContentNotFound(_contentId);
        if (contentItems[_contentId].status != IEducationalMarketplace.ContentStatus.Active) {
            revert ContentNotActive(_contentId);
        }
        _;
    }
    
    modifier creationCooldownPassed(address _creator) {
        uint256 blocksPassed = block.number - creators[_creator].lastContentBlock;
        if (blocksPassed < creationCooldownBlocks) {
            revert CreationCooldownActive(creationCooldownBlocks - blocksPassed);
        }
        _;
    }
    
    modifier notBlacklisted(address _user) {
        if (blacklistedUsers[_user]) revert UserIsBlacklisted();
        _;
    }
    
    modifier notEmergencyStop() {
        if (emergencyStop) revert EmergencyStopActive();
        _;
    }
    
    modifier onlyContentCreator(uint256 _contentId) {
        if (contentItems[_contentId].creator != msg.sender) revert UnauthorizedAccess();
        _;
    }
    
    /**
     * @dev Create new educational content
     */
    function _createContent(
        string calldata _title,
        string calldata _description,
        IEducationalMarketplace.ContentCategory _category,
        bytes32 _contentHash,
        uint256 _price,
        uint256 _customRoyaltyPercent
    ) internal returns (uint256) {
        _validateContentData(_title, _description, _price, _customRoyaltyPercent);
        _checkDailyUploadLimit(msg.sender);
        
        uint256 newContentId = nextContentId;
        nextContentId++;
        
        uint256 royaltyPercent = _customRoyaltyPercent > 0 ? _customRoyaltyPercent : defaultRoyaltyPercent;
        
        contentItems[newContentId] = IEducationalMarketplace.ContentItem({
            contentId: newContentId,
            title: _title,
            description: _description,
            category: _category,
            contentHash: _contentHash,
            price: _price,
            royaltyPercent: royaltyPercent,
            status: IEducationalMarketplace.ContentStatus.Active,
            creator: payable(msg.sender),
            currentOwner: payable(msg.sender),
            createdAtBlock: block.number,
            totalSales: 0,
            totalViews: 0,
            totalEarnings: 0
        });
        
        // Update creator data
        creators[msg.sender].totalContent++;
        creators[msg.sender].lastContentBlock = block.number;
        createdContent[msg.sender][newContentId] = true;
        
        creatorContent[msg.sender].push(newContentId);
        totalActiveContent++;
        
        uint256 today = block.number / BLOCKS_PER_DAY;
        dailyUploads[msg.sender][today]++;
        
        bytes32 titleHash = keccak256(abi.encodePacked(_title));
        emit ContentCreated(newContentId, msg.sender, titleHash, _price, _category, block.number);
        
        return newContentId;
    }
    
    /**
     * @dev Add collaborators to content
     */
    function _addCollaborators(
        uint256 _contentId,
        address[] calldata _collaborators,
        uint256[] calldata _sharePercents,
        bytes32[] calldata _roleHashes
    ) internal {
        if (_collaborators.length != _sharePercents.length || _collaborators.length != _roleHashes.length) {
            revert InvalidContentData();
        }
        if (_collaborators.length > maxCollaborators) revert TooManyCollaborators();
        
        delete contentCollaborators[_contentId];
        
        uint256 totalShare = 0;
        for (uint256 i = 0; i < _collaborators.length; i++) {
            if (_collaborators[i] == address(0) || _sharePercents[i] == 0) {
                revert InvalidCollaboratorShare();
            }
            
            contentCollaborators[_contentId].push(IEducationalMarketplace.Collaborator({
                collaboratorAddress: _collaborators[i],
                sharePercent: _sharePercents[i],
                roleHash: _roleHashes[i]
            }));
            
            totalShare += _sharePercents[i];
            
            emit CollaboratorAdded(_contentId, _collaborators[i], _sharePercents[i], _roleHashes[i]);
        }
        
        if (totalShare > BASIS_POINTS) revert InvalidCollaboratorShare();
    }
    
    /**
     * @dev Purchase content with royalty distribution
     */
    function _purchaseContent(uint256 _contentId) internal {
        IEducationalMarketplace.ContentItem storage content = contentItems[_contentId];
        
        if (userPurchases[msg.sender][_contentId]) revert ContentAlreadyPurchased(_contentId);
        if (msg.value < content.price) revert InsufficientPayment(content.price, msg.value);
        
        uint256 totalPayment = content.price;
        
        uint256 platformFee = (totalPayment * platformFeePercent) / BASIS_POINTS;
        uint256 royaltyAmount = (totalPayment * content.royaltyPercent) / BASIS_POINTS;
        uint256 sellerAmount = totalPayment - platformFee - royaltyAmount;
        
        userPurchases[msg.sender][_contentId] = true;
        userPurchaseHistory[msg.sender].push(_contentId);
        
        content.totalSales++;
        content.totalEarnings += totalPayment;
        totalSales++;
        totalRevenue += totalPayment;
        
        creators[content.creator].totalSales++;
        creators[content.creator].totalEarnings += sellerAmount + royaltyAmount;
        
        bytes32 purchaseHash = keccak256(abi.encodePacked(
            msg.sender, 
            _contentId, 
            block.number, 
            totalPayment,
            block.prevrandao
        ));
        
        purchases.push(IEducationalMarketplace.Purchase({
            buyer: msg.sender,
            contentId: _contentId,
            blockNumber: block.number,
            pricePaid: totalPayment,
            royaltyPaid: royaltyAmount,
            platformFeePaid: platformFee,
            purchaseHash: purchaseHash
        }));
        
        _distributeRoyalties(_contentId, royaltyAmount);
        
        if (sellerAmount > 0) {
            content.currentOwner.sendValue(sellerAmount);
        }
        
        if (msg.value > totalPayment) {
            payable(msg.sender).sendValue(msg.value - totalPayment);
        }
        
        emit ContentPurchased(msg.sender, _contentId, content.currentOwner, totalPayment, royaltyAmount, purchaseHash);
    }
    
    /**
     * @dev Distribute royalties to creator and collaborators
     */
    function _distributeRoyalties(uint256 _contentId, uint256 _totalRoyalty) internal {
        IEducationalMarketplace.ContentItem memory content = contentItems[_contentId];
        IEducationalMarketplace.Collaborator[] memory collaborators = contentCollaborators[_contentId];
        
        if (collaborators.length == 0) {
            if (_totalRoyalty > 0) {
                content.creator.sendValue(_totalRoyalty);
                emit RoyaltyDistributed(_contentId, content.creator, _totalRoyalty, keccak256("Creator"));
            }
        } else {
            uint256 totalCollaboratorShare = 0;
            
            for (uint256 i = 0; i < collaborators.length; i++) {
                uint256 collaboratorAmount = (_totalRoyalty * collaborators[i].sharePercent) / BASIS_POINTS;
                if (collaboratorAmount > 0) {
                    payable(collaborators[i].collaboratorAddress).sendValue(collaboratorAmount);
                    emit RoyaltyDistributed(_contentId, collaborators[i].collaboratorAddress, collaboratorAmount, collaborators[i].roleHash);
                }
                totalCollaboratorShare += collaborators[i].sharePercent;
            }
            
            uint256 creatorShare = BASIS_POINTS - totalCollaboratorShare;
            uint256 creatorAmount = (_totalRoyalty * creatorShare) / BASIS_POINTS;
            if (creatorAmount > 0) {
                content.creator.sendValue(creatorAmount);
                emit RoyaltyDistributed(_contentId, content.creator, creatorAmount, keccak256("Creator"));
            }
        }
    }
    
    /**
     * @dev Validate content data
     */
    function _validateContentData(
        string calldata _title,
        string calldata _description,
        uint256 _price,
        uint256 _royaltyPercent
    ) internal view {
        if (bytes(_title).length < MIN_TITLE_LENGTH || bytes(_title).length > MAX_TITLE_LENGTH) {
            revert InvalidContentData();
        }
        if (bytes(_description).length < minDescriptionLength || bytes(_description).length > maxDescriptionLength) {
            revert InvalidContentData();
        }
        if (_price < minContentPrice || _price > maxContentPrice) {
            revert InvalidPrice(_price);
        }
        if (_royaltyPercent > maxRoyaltyPercent) {
            revert InvalidRoyaltyPercent(_royaltyPercent);
        }
    }
    
    /**
     * @dev Check daily upload limit
     */
    function _checkDailyUploadLimit(address _creator) internal view {
        uint256 today = block.number / BLOCKS_PER_DAY;
        uint256 todayUploads = dailyUploads[_creator][today];
        
        if (todayUploads >= dailyUploadLimit) {
            revert DailyLimitExceeded(todayUploads, dailyUploadLimit);
 }
}
}
