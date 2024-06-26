// SPDX-License-Identifier: Apache-2.0
// Copyright 2024 HB Craft.

pragma solidity 0.8.22;

import "./contract-functions/WriteFunctions.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

abstract contract ComplianceCheck is WriteFunctions {
    // ======================================
    // =              Errors                =
    // ======================================
    using SafeERC20 for IERC20Metadata;

    /// @dev Exception raised if a value is tried to be reassigned
    error ValueReassignment();
    /**
     *  @dev
     *  Exception raised:
     *     - If listers try to list more NFTs than they own
     *     - If buyers try to buy more NFTs than available
     */
    error InsufficientQuantity(uint256 requested, uint256 available);
    error ContractNotApproved();
    error NonExistentListing(uint256 listingID);
    error InvalidListing(uint256 listingID);
    /// @dev Exception raised if listers try to list an NFT that has the same contract address and ID with an existing listing
    error RepetitiveListing(uint256 listingID);
    /// @dev Exception raised if listers try to create a listing with a BT price that, when converted to QT, is lower than the minimumPriceInQT
    error PriceBelowMinRequirement(uint256 currentMinBTPriceReq);
    /// @dev Exception raised when 0 is provided as quantity
    error InvalidArgumentValue(string argument, uint256 minValue);
    /// ??? @dev Exception raised when 0 is provided as quantity
    error PriceInQTIncreased(uint256 listingID, uint256 requestedPriceInQT, uint256 currentPriceInQT);

    // ======================================
    // =             Functions              =
    // ======================================
    /// @dev Checks if BT price is higher than or equal to the minimumPriceInQT when  converted QT price
    function checkMinimumPriceInBT() public view returns (uint256) {
        return (10 ** BASE_TOKEN.decimals()) * FIXED_POINT_PRECISION / getReferenceBTQTRate();
    }

    /// @dev Checks if the lister holds quantity equal to or more than the Listing.quantity
    function _doesListerOwnEnoughNFTs(
        address listerAddress,
        address nftContractAddress,
        uint256 nftID,
        uint256 quantity
    ) private view returns (bool) {
        if (quantity > IERC1155(nftContractAddress).balanceOf(listerAddress, nftID)) return false;
        else return true;
    }

    /// ???
    function _isStoreContractApprovedByLister(address listerAddress, address nftContractAddress)
        private
        view
        returns (bool)
    {
        if (IERC1155(nftContractAddress).isApprovedForAll(listerAddress, address(this))) return true;
        else return false;
    }

    /**
     * @dev Returns false if:
     *   - The listing is canceled
     *   - The lister doesn't hold the quantity equal to or more than the Listing.quantity
     *   - QT price of the listing is lower than the minimumPriceInQT
     */
    function checkIfListingValid(uint256 listingID, uint256 minimumPriceInBT) public view returns (bool) {
        Listing memory targetListing = listings[listingID];
        if (
            targetListing.isActive
                && _isStoreContractApprovedByLister(targetListing.listerAddress, targetListing.nftContractAddress)
                && (targetListing.btPricePerFraction >= minimumPriceInBT)
                && _doesListerOwnEnoughNFTs(
                    targetListing.listerAddress,
                    targetListing.nftContractAddress,
                    targetListing.nftID,
                    targetListing.quantity
                )
        ) return true;
        else return false;
    }

    function getValidListingIDs() public view returns (uint256[] memory) {
        uint256[] memory tempActiveListings = new uint256[](listings.length);
        uint256 count = 0;

        // Loop through all listings and check if they are valid
        uint256 minimumPriceInBT = checkMinimumPriceInBT();
        for (uint256 i = activeListingStartIndex; i < listings.length; i++) {
            if (checkIfListingValid(i, minimumPriceInBT)) {
                tempActiveListings[count] = i;
                count++;
            }
        }

        // Create an array of active listings with the exact count
        uint256[] memory activeListingIDs = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            activeListingIDs[i] = tempActiveListings[i];
        }

        return activeListingIDs;
    }

    function getActiveListingIDs() public view returns (uint256[] memory) {
        uint256[] memory tempActiveListings = new uint256[](listings.length);
        uint256 count = 0;

        // Loop through all listings and check if they are active
        for (uint256 i = activeListingStartIndex; i < listings.length; i++) {
            if (listings[i].isActive) {
                tempActiveListings[count] = i;
                count++;
            }
        }

        // Create an array of active listings with the exact count
        uint256[] memory activeListingIDs = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            activeListingIDs[i] = tempActiveListings[i];
        }

        return activeListingIDs;
    }

    /// @dev Checks if a listing with the same nftContractAddress and nftID is added before
    function _isRepetitiveListing(address contractAddress, uint256 nftID, bool ifRevert)
        private
        view
        returns (bool, uint256)
    {
        bool isRepetitive;
        uint256 repetiveListingID;

        uint256[] memory activeListingIDs = getActiveListingIDs();

        for (uint256 count = 0; count < activeListingIDs.length; count++) {
            uint256 targetListingID = activeListingIDs[count];
            Listing memory targetListing = listings[targetListingID];
            if (targetListing.nftContractAddress == contractAddress && targetListing.nftID == nftID) {
                if (ifRevert) revert RepetitiveListing(targetListingID);

                isRepetitive = true;
                repetiveListingID = targetListingID;
            }
        }

        if (isRepetitive) return (true, repetiveListingID);
        else return (false, listings.length);
    }

    function _checkListingExistence(uint256 listingID) private view {
        if (!(listings.length > listingID)) revert NonExistentListing(listingID);
    }

    // ======================================
    // =             Modifiers              =
    // ======================================
    modifier ifListingExists(uint256 listingID) {
        _checkListingExistence(listingID);
        _;
    }

    modifier ifStoreContractApprovedByLister(address listerAddress, address nftContractAddress) {
        if (!_isStoreContractApprovedByLister(listerAddress, nftContractAddress)) revert ContractNotApproved();
        _;
    }

    modifier ifListingMeetsListingReqs(address nftContractAddress, uint256 nftID, uint256 quantity, uint256 btPrice) {
        if (quantity == 0) revert InvalidArgumentValue("quantity", 1);
        uint256 minimumPriceInBT = checkMinimumPriceInBT();
        if (btPrice < minimumPriceInBT) revert PriceBelowMinRequirement(minimumPriceInBT);
        _isRepetitiveListing(nftContractAddress, nftID, true);
        if (!_doesListerOwnEnoughNFTs(msg.sender, nftContractAddress, nftID, quantity)) {
            revert InsufficientQuantity(quantity, IERC1155(nftContractAddress).balanceOf(msg.sender, nftID));
        }
        _;
    }

    modifier ifPurchaseCallValid(uint256 listingID, uint256 quantity) {
        if (quantity == 0) revert InvalidArgumentValue("quantity", 1);
        _checkListingExistence(listingID);
        uint256 minimumPriceInBT = checkMinimumPriceInBT();
        if (!checkIfListingValid(listingID, minimumPriceInBT)) revert InvalidListing(listingID);
        Listing memory targetListing = listings[listingID];
        if (quantity > listings[listingID].quantity) revert InsufficientQuantity(quantity, targetListing.quantity);
        _;
    }

    // ======================================
    // =    Token Management Functions      =
    // ======================================
    function _payLister(address listerAddress, uint256 tokenAmount) internal {
        QUOTE_TOKEN.safeTransferFrom(msg.sender, listerAddress, tokenAmount);
    }

    function _transferNFTs(address listerAddress, address nftContractAddress, uint256 nftID, uint256 quantity)
        internal
    {
        IERC1155(nftContractAddress).safeTransferFrom(listerAddress, msg.sender, nftID, quantity, "");
    }
}
