// SPDX-License-Identifier: BUSL-1.1
// Copyright 2025 Reality Metaverse

pragma solidity 0.8.20;

import "./ProgramManager.sol";

abstract contract AccessControl is ProgramManager {
    // ======================================
    // =          State Variables           =
    // ======================================
    /**
     *     - Certain functions can be called only if you have the matching AccessTier requirement
     *     - Tier 2 - Contract Owner, Tier 1 - Contract Admins, Tier 0 - Users
     *     - Check ComplianceCheck.sol for more info
     */
    enum AccessTier {
        ADMIN,
        OWNER
    }

    address public contractOwner;
    mapping(address => bool) public contractAdmins;
    mapping(uint256 poolID => bool isAllowlistEnabled) public poolAllowlistStatuses;
    mapping(uint256 poolID => mapping(address userAdrress => uint256[] allowedAmounts)) public userAllowedAmounts;
    mapping(uint256 poolID => mapping(address userAddress => uint256 usedAllowedAmount)) public userUsedAllowedAmounts;

    // ======================================
    // =              Errors                =
    // ======================================
    error UnauthorizedAccess(AccessTier requiredAccessTier);
    error OverAllowedAmount(address userAddress, uint256 amountToBeStaked, uint256 allowedAmount);
    error AllowlistEntryDoesNotExist(uint256 poolID, address userAddress, uint256 entryNo);

    // ======================================
    // =             Functions              =
    // ======================================
    // Functions to check authorization and revert if not authorized
    function _checkAccess(AccessTier tierToCheck) private view {
        if (tierToCheck == AccessTier.OWNER && msg.sender != contractOwner) {
            revert UnauthorizedAccess(tierToCheck);
        } else if (tierToCheck == AccessTier.ADMIN && !contractAdmins[msg.sender] && msg.sender != contractOwner) {
            revert UnauthorizedAccess(tierToCheck);
        }
    }

    function _checkTotalAllowedAmountFor(address userAddress, uint256 poolID) internal view returns (uint256) {
        uint256[] memory allowlistEntriesForUser = userAllowedAmounts[poolID][userAddress];
        uint256 userAllowlistCount = allowlistEntriesForUser.length;
        uint256 userTotalAllowedAmount = 0;
        for (uint256 allowlistNo; allowlistNo < userAllowlistCount; allowlistNo++) {
            userTotalAllowedAmount += allowlistEntriesForUser[allowlistNo];
        }

        return userTotalAllowedAmount;
    }

    function _checkTotalUsedAllowedAmountFor(address userAddress, uint256 poolID) internal view returns (uint256) {
        return userUsedAllowedAmounts[poolID][userAddress];
    }

    function _checkAllowedAmountLeftFor(address userAddress, uint256 poolID) internal view returns (uint256) {
        uint256 allowedAmount = _checkTotalAllowedAmountFor(userAddress, poolID);
        uint256 usedAllowedAmount = _checkTotalUsedAllowedAmountFor(userAddress, poolID);

        if (usedAllowedAmount >= allowedAmount) {
            return 0;
        } else {
            return allowedAmount - usedAllowedAmount;
        }
    }

    // ======================================
    // =             Modifiers              =
    // ======================================
    /// @dev The functions only accesible by the address deployed the contract
    modifier onlyContractOwner() {
        _checkAccess(AccessTier.OWNER);
        _;
    }

    /**
     * @dev
     *     - The functions only accesible by the contractOwner and the addresses that have admin status
     *     - The admin status can only be assigned by the address deployed the contract
     *
     */
    modifier onlyAdmins() {
        _checkAccess(AccessTier.ADMIN);
        _;
    }

    modifier ifCompliedWithAllowlist(uint256 poolID, uint256 amountToBeStaked) {
        if (poolAllowlistStatuses[poolID]) {
            uint256 allowedAmountLeft = _checkAllowedAmountLeftFor(msg.sender, poolID);

            if (amountToBeStaked > allowedAmountLeft) {
                revert OverAllowedAmount(msg.sender, amountToBeStaked, allowedAmountLeft);
            }

            userUsedAllowedAmounts[poolID][msg.sender] += amountToBeStaked;
        }
        _;
    }

    modifier ifAllowlistEntryExists(uint256 poolID, address userAddress, uint256 entryNo) {
        if (entryNo >= userAllowedAmounts[poolID][userAddress].length) {
            revert AllowlistEntryDoesNotExist(poolID, userAddress, entryNo);
        }
        _;
    }
}
