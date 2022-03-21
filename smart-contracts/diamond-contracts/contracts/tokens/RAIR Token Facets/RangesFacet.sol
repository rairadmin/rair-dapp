// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.11;

import './AppStorage.sol';

/// @title  This is contract to manage the Rair token ranges facet
/// @notice You can use this contract to administrate ranges, transfers & minting of the tokens
/// @author Juan M. Sanchez M.
/// @dev 	Notice that this contract is inheriting from AccessControlAppStorageEnumerable721
contract RAIRRangesFacet is AccessControlAppStorageEnumerable721 {
	bytes32 public constant CREATOR = keccak256("CREATOR");

	/// @notice This event stores in the blockchain when the NFT range is correctly created
    /// @param  productIndex Contains the position where the product was indexed
	/// @param  start Contains the start position of the range of nft collection
	/// @param  end Contains the last NFT of the range collection
	/// @param  price Contains the selling price for the range of NFT
	/// @param  tokensAllowed Contains all the allowed NFT tokens in the range that are available for sell
	/// @param  lockedTokens Contains all the NFT tokens in the range that are unavailable for sell
	/// @param  name Contains the name for the created NFT collection range
	/// @param  rangeIndex Contains the position where the range was indexed
	event CreatedRange(uint productIndex, uint start, uint end, uint price, uint tokensAllowed, uint lockedTokens, string name, uint rangeIndex);
	/// @notice This event stores in the blockchain when the NFT range is correctly updated
    /// @param  rangeIndex Contains the position where the range was indexed
	/// @param  name Contains the name for the created NFT collection range
	/// @param  price Contains the selling price for the range of NFT
	/// @param  tokensAllowed Contains all the allowed NFT tokens in the range that are available for sell
	/// @param  lockedTokens Contains all the NFT tokens in the range that are unavailable for sell
	event UpdatedRange(uint rangeIndex, string name, uint price, uint tokensAllowed, uint lockedTokens);
	/// @notice This event stores in the blockchain when the NFT range trading is effectively locked  
    /// @param  rangeIndex Contains the position where the range was indexed
	/// @param  from Contains the starting NFT of the range that we want to lock
	/// @param  to Contains the last NTF of the range that we want to lock
	/// @param  lockedTokens Contains all the NFT tokens in the range that are unavailable for sell
	event TradingLocked(uint indexed rangeIndex, uint from, uint to, uint lockedTokens);
	/// @notice This event stores in the blockchain when the NFT range trading is effectively unlocked 
    /// @param  rangeIndex Contains the position where the range was indexed
	/// @param  from Contains the starting NFT of the range that we want to lock
	/// @param  to Contains the last NTF of the range that we want to lock
	event TradingUnlocked(uint indexed rangeIndex, uint from, uint to);

	// Auxiliary struct used to avoid Stack too deep errors
	struct rangeData {
		uint rangeStart;
		uint rangeEnd;
		uint price;
		uint tokensAllowed;
		uint lockedTokens;
		string name;
	}

	/// @notice Verifies that the range exists
	/// @param	rangeID	Identification of the range to verify
	modifier rangeExists(uint rangeID) {
		require(s.ranges.length > rangeID, "RAIR ERC721 Ranges: Range does not exist");
		_;
	}

	/// @notice This functions
	/// @dev 	This function requires that the rangeIndex_ points to an existing range 
	/// @param	rangeIndex	Identification of the range to verify
	/// @return uint which indicates the 
	function rangeToProduct(uint rangeIndex_) public view rangeExists(rangeIndex_) returns (uint) {
		return s.rangeToProduct[rangeIndex_];
	}

	/// @notice This functions allow us to check the information of the range
	/// @dev 	This function requires that the rangeIndex_ points to an existing range 
	/// @param	rangeId	Identification of the range to verify
	/// @return range which has the saved memory iformation about the range
	/// @return productIndex Contains the index of the product in the range
	function rangeInfo(uint rangeId) external view rangeExists(rangeId) returns(range memory data, uint productIndex) {
		data = s.ranges[rangeId];
		productIndex = s.rangeToProduct[rangeId];
	}

	/// @notice This functions shows is the range is currently locked or not 
	/// @dev 	This function requires that the rangeIndex_ points to an existing range 
	/// @param	rangeId	Identification of the range to verify
	/// @return bool with the current status of the range lock
	///			true for lock and false for unlocked
	function isRangeLocked(uint rangeId) external view rangeExists(rangeId) returns (bool) {
		return s.ranges[rangeId].lockedTokens > 0;
	}

	/// @notice This functions shows the information for the range of a product
	/// @param	productId	Identification of the product to verify
	/// @param	rangeIndex	Identification of the range to verify
	/// @return range which has the saved memory iformation about the range
	function productRangeInfo(uint productId, uint rangeIndex) external view returns(range memory data) {
		require(s.products.length > productId, "RAIR ERC721 Ranges: Product does not exist");
		require(s.products[productId].rangeList.length > rangeIndex, "RAIR ERC721 Ranges: Invalid range index");
		data = s.ranges[s.products[productId].rangeList[rangeIndex]];
	}

	/// @notice This functions allow us to update the information about a range
	/// @dev 	This function requires that the rangeIndex_ points to an existing range
	/// @dev 	This function is only available to an account with a `CREATOR` role
	/// @param	rangeId	Identification of the range to verify
	/// @param	name	Contains the name for the created NFT collection range
	/// @param	price_	Contains the selling price for the range of NFT
	/// @param	tokensAllowed_	Contains all the allowed NFT tokens in the range that are available for sell
	/// @param	lockedtokens_	Contains all the NFT tokens in the range that are unavailable for sell
	function updateRange(uint rangeId, string memory name, uint price_, uint tokensAllowed_, uint lockedTokens_) public rangeExists(rangeId) onlyRole(CREATOR) {
		require(price_ >= 100, "RAIR ERC721: Minimum price allowed is 100 wei");
		range storage selectedRange = s.ranges[rangeId];
		require(selectedRange.rangeEnd - selectedRange.rangeStart + 1 >= tokensAllowed_, "RAIR ERC721: Allowed tokens should be less than range's length");
		require(selectedRange.rangeEnd - selectedRange.rangeStart + 1 >= lockedTokens_, "RAIR ERC721: Locked tokens should be less than range's length");
		selectedRange.tokensAllowed = tokensAllowed_;
		if (lockedTokens_ > 0) {
			emit TradingLocked(rangeId, selectedRange.rangeStart, selectedRange.rangeEnd, lockedTokens_);
			selectedRange.lockedTokens = lockedTokens_;
		}
		selectedRange.rangeName = name;
		selectedRange.rangePrice = price_;
		emit UpdatedRange(rangeId, name, price_, tokensAllowed_, lockedTokens_);
	}

	/// @notice This functions allow us to know if a desidred range can be created or not
	/// @param	productId_	Contains the identification for the product
	/// @param	rangeStart_	Contains the tentative NTF to use as starting point of the range 
	/// @param	rangeEnd_	Contains the tentative NTF to use as ending point of the range
	/// @return bool With the answer if the range cant be creater or not
	function canCreateRange(uint productId_, uint rangeStart_, uint rangeEnd_) public view returns (bool) {
		uint[] memory rangeList = s.products[productId_].rangeList;
		for (uint i = 0; i < rangeList.length; i++) {
			if ((s.ranges[rangeList[i]].rangeStart <= rangeStart_ &&
					s.ranges[rangeList[i]].rangeEnd >= rangeStart_) || 
				(s.ranges[rangeList[i]].rangeStart <= rangeEnd_ &&
					s.ranges[rangeList[i]].rangeEnd >= rangeEnd_)) {
				return false;
			}
		}
		return true;
	}
	
	/// @notice This is a internal function that will create the NTF range if the requirements are meet
	/// @param	productId_	Contains the identification for the product
	/// @param	rangeStart_	Contains the tentative NTF to use as starting point of the range 
	/// @param	rangeEnd_	Contains the tentative NTF to use as ending point of the range
	/// @param 	price_ Contains the selling price for the range of NFT
	/// @param 	tokensAllowed_ Contains all the allowed NFT tokens in the range that are available for sell
	/// @param 	lockedTokens_ Contains all the NFT tokens in the range that are unavailable for sell
	/// @param 	name_ Contains the name for the created NFT collection range
	function _createRange(uint productId_, uint rangeStart_, uint rangeEnd_, uint price_, uint tokensAllowed_, uint lockedTokens_, string memory name_) internal {
		require(price_ >= 100, "RAIR ERC721: Minimum price allowed is 100 wei");
		require(rangeStart_ <= rangeEnd_, 'RAIR ERC721: Invalid starting or ending token');
		// Add one because the starting token is included!
		require(rangeEnd_ - rangeStart_ + 1 >= tokensAllowed_, "RAIR ERC721: Allowed tokens should be less than range's length");
		require(rangeEnd_ - rangeStart_ + 1 >= lockedTokens_, "RAIR ERC721: Locked tokens should be less than range's length");
		product storage selectedProduct = s.products[productId_];
		range storage newRange = s.ranges.push();
		uint rangeIndex = s.ranges.length - 1;
		require(canCreateRange(productId_, rangeStart_, rangeEnd_), "RAIR ERC721: Can't create a lock of this range");
		newRange.rangeStart = rangeStart_;
		newRange.rangeEnd = rangeEnd_;
		newRange.tokensAllowed = tokensAllowed_;
		newRange.mintableTokens = rangeEnd_ - rangeStart_ + 1;
		newRange.lockedTokens = lockedTokens_;
		if (lockedTokens_ > 0) {
			emit TradingLocked(rangeIndex, rangeStart_, rangeEnd_, lockedTokens_);
		} else if (lockedTokens_ == 0) {
			emit TradingUnlocked(rangeIndex, rangeStart_, rangeEnd_);
		}
		newRange.rangePrice = price_;
		newRange.rangeName = name_;
		s.rangeToProduct[rangeIndex] = productId_;
		selectedProduct.rangeList.push(rangeIndex);
		emit CreatedRange(productId_, rangeStart_, rangeEnd_, price_, tokensAllowed_, lockedTokens_, name_, rangeIndex);
	}

	/// @notice This function that will create the NTF range if the requirements are meet
	/// @dev 	This function is only available to an account with a `CREATOR` role
	/// @param	productId	Contains the identification for the product
	/// @param	rangeStart	Contains the tentative NTF to use as starting point of the range 
	/// @param	rangeEnd	Contains the tentative NTF to use as ending point of the range
	/// @param 	price Contains the selling price for the range of NFT
	/// @param 	tokensAllowed Contains all the allowed NFT tokens in the range that are available for sell
	/// @param 	lockedTokens Contains all the NFT tokens in the range that are unavailable for sell
	/// @param 	name Contains the name for the created NFT collection range
	function createRange(uint productId, uint rangeStart, uint rangeEnd, uint price, uint tokensAllowed, uint lockedTokens, string calldata name) external onlyRole(CREATOR) {
		require(s.products.length > productId, "RAIR ERC721: Product does not exist");
		_createRange(productId, rangeStart, rangeEnd, price, tokensAllowed, lockedTokens, name);
	}

	/// @notice This function will create as much ranges as the data array requires
	/// @dev 	This function is only available to an account with a `CREATOR` role
	/// @param	productId	Contains the identification for the product
	/// @param	data An array with the data for all the ranges that we want to implement 
	function createRangeBatch(
		uint productId,
		rangeData[] calldata data
	) external onlyRole(CREATOR) {
		require(data.length > 0, "RAIR ERC721: Empty array");
		require(s.products.length > productId, "RAIR ERC721: Product does not exist");
		for (uint i = 0; i < data.length; i++) {
			_createRange(productId, data[i].rangeStart, data[i].rangeEnd, data[i].price, data[i].tokensAllowed, data[i].lockedTokens, data[i].name);
		}
	}
}