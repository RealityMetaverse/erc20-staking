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
    mapping(uint256 poolID => bool isWhitelistingEnabled) public poolWhitelistingStatuses;
    mapping(uint256 poolID => mapping(address userAddress => uint256 whitelistedAmount)) public whitelistedAmounts;

    // ======================================
    // =              Errors                =
    // ======================================
    error UnauthorizedAccess(AccessTier requiredAccessTier);
    error OverWhitelistedAmount(address userAddress, uint256 amountToBeStaked, uint256 allowedAmount);

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

    modifier ifCompliedWithWhitelisting(uint256 poolID, uint256 amountToBeStaked) {
        if (poolWhitelistingStatuses[poolID]) {
            uint256 whitelistedAmount = whitelistedAmounts[poolID][msg.sender];

            if (whitelistedAmount < amountToBeStaked) {
                revert OverWhitelistedAmount(msg.sender, amountToBeStaked, whitelistedAmount);
            }

            whitelistedAmounts[poolID][msg.sender] = whitelistedAmount - amountToBeStaked;
        }
        _;
    }
}
