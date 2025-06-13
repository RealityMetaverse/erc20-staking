// SPDX-License-Identifier: BUSL-1.1
// Copyright 2025 Reality Metaverse

pragma solidity 0.8.20;

import "../ComplianceCheck.sol";

abstract contract ReadFunctions is ComplianceCheck {
    // ======================================
    // =  Functoins to check program data   =
    // ======================================
    function checkConfirmationCode() external view returns (uint256) {
        return CONFIRMATION_CODE;
    }

    function checkPoolCount() external view returns (uint256) {
        return _checkProgramStatus(true);
    }

    function checkDefaultStakingTarget() external view returns (uint256) {
        return defaultStakingTarget;
    }

    function checkDefaultMinimumDeposit() external view returns (uint256) {
        return defaultMinimumDeposit;
    }

    function checkInterestPool() external view returns (uint256) {
        return interestPool;
    }

    function checkInterestProvidedBy(address userAddress) external view returns (uint256) {
        return interestProviderList[userAddress];
    }

    // ======================================
    // =Functions to check stakingPool data =
    // ======================================
    function checkPoolType(uint256 poolID) external view ifPoolExists(poolID) returns (uint256) {
        return (stakingPoolList[poolID].poolType == PoolType.LOCKED) ? 0 : 1;
    }

    function checkStakingTarget(uint256 poolID) external view ifPoolExists(poolID) returns (uint256) {
        return stakingPoolList[poolID].stakingTarget;
    }

    function checkMinimumDeposit(uint256 poolID) external view ifPoolExists(poolID) returns (uint256) {
        return stakingPoolList[poolID].minimumDeposit;
    }

    /// @dev Internal function to get APY for a pool
    function _checkAPY(uint256 poolID) internal view returns (uint256) {
        return stakingPoolList[poolID].APY / FIXED_POINT_PRECISION;
    }

    function checkAPY(uint256 poolID) external view ifPoolExists(poolID) returns (uint256) {
        return _checkAPY(poolID);
    }

    /// @dev Returns timestamp
    function checkEndDate(uint256 poolID) external view ifPoolExists(poolID) returns (uint256) {
        return stakingPoolList[poolID].endDate;
    }

    /// @dev Availability status requests
    function checkIfStakingOpen(uint256 poolID) external view ifPoolExists(poolID) returns (bool) {
        return stakingPoolList[poolID].isStakingOpen;
    }

    function checkIfWithdrawalOpen(uint256 poolID) external view ifPoolExists(poolID) returns (bool) {
        return stakingPoolList[poolID].isWithdrawalOpen;
    }

    function checkIfInterestClaimOpen(uint256 poolID) external view ifPoolExists(poolID) returns (bool) {
        return stakingPoolList[poolID].isInterestClaimOpen;
    }

    function checkIfPoolEnded(uint256 poolID) external view ifPoolExists(poolID) returns (bool) {
        return _checkIfPoolEnded(poolID, true);
    }

    /// @dev Total data requests
    function checkTotalStaked(uint256 poolID) public view ifPoolExists(poolID) returns (uint256) {
        return stakingPoolList[poolID].totalList[DataType.STAKED];
    }

    function checkTotalWithdrawn(uint256 poolID) external view ifPoolExists(poolID) returns (uint256) {
        return stakingPoolList[poolID].totalList[DataType.WITHDREW];
    }

    function checkTotalInterestClaimed(uint256 poolID) external view ifPoolExists(poolID) returns (uint256) {
        return stakingPoolList[poolID].totalList[DataType.INTEREST_CLAIMED];
    }

    function checkTotalFundCollected(uint256 poolID) external view ifPoolExists(poolID) returns (uint256) {
        return stakingPoolList[poolID].totalList[DataType.FUNDS_COLLECTED];
    }

    function checkTotalFundRestored(uint256 poolID) external view ifPoolExists(poolID) returns (uint256) {
        return stakingPoolList[poolID].totalList[DataType.FUNDS_RESTORED];
    }

    // ======================================
    // =    Functoins to check user data    =
    // ======================================
    function checkTotalAllowedAmountFor(address userAddress, uint256 poolID)
        external
        view
        ifPoolExists(poolID)
        returns (uint256)
    {
        return _checkTotalAllowedAmountFor(userAddress, poolID);
    }

    function checkTotalUsedAllowedAmountFor(address userAddress, uint256 poolID)
        external
        view
        ifPoolExists(poolID)
        returns (uint256)
    {
        return _checkTotalUsedAllowedAmountFor(userAddress, poolID);
    }

    function checkAllowedAmountLeftFor(address userAddress, uint256 poolID)
        external
        view
        ifPoolExists(poolID)
        returns (uint256)
    {
        return _checkAllowedAmountLeftFor(userAddress, poolID);
    }

    function getAllowlistEntryCountFor(uint256 poolID, address userAddress)
        external
        view
        ifPoolExists(poolID)
        returns (uint256)
    {
        return userAllowedAmounts[poolID][userAddress].length;
    }

    function getAllowlistEntriesFor(uint256 poolID, address userAddress)
        external
        view
        ifPoolExists(poolID)
        returns (uint256[] memory)
    {
        return userAllowedAmounts[poolID][userAddress];
    }

    function _getAllowlistRemainingAmountsFor(address userAddress, uint256 poolID)
        private
        view
        returns (uint256[] memory)
    {
        uint256[] memory allowedAmounts = userAllowedAmounts[poolID][userAddress];
        uint256 usedAmount = _checkTotalUsedAllowedAmountFor(userAddress, poolID);
        uint256[] memory remainingAmounts = new uint256[](allowedAmounts.length);

        for (uint256 i = 0; i < allowedAmounts.length; i++) {
            if (usedAmount >= allowedAmounts[i]) {
                remainingAmounts[i] = 0;
                usedAmount -= allowedAmounts[i];
            } else {
                remainingAmounts[i] = allowedAmounts[i] - usedAmount;
                usedAmount = 0;
            }
        }

        return remainingAmounts;
    }

    function getAllowlistRemainingAmountsFor(address userAddress, uint256 poolID)
        external
        view
        ifPoolExists(poolID)
        returns (uint256[] memory)
    {
        return _getAllowlistRemainingAmountsFor(userAddress, poolID);
    }

    function _checkStakedAmountBy(address userAddress, uint256 poolID) internal view returns (uint256) {
        return stakingPoolList[poolID].stakerList[userAddress];
    }

    function checkStakedAmountBy(address userAddress, uint256 poolID)
        external
        view
        ifPoolExists(poolID)
        returns (uint256)
    {
        return _checkStakedAmountBy(userAddress, poolID);
    }

    function checkDepositStakedAmount(address userAddress, uint256 poolID, uint256 depositNumber)
        external
        view
        ifPoolExists(poolID)
        returns (uint256)
    {
        return stakingPoolList[poolID].stakerDepositList[userAddress][depositNumber].amount;
    }

    function checkWithdrawnAmountBy(address userAddress, uint256 poolID)
        external
        view
        ifPoolExists(poolID)
        returns (uint256)
    {
        return stakingPoolList[poolID].withdrawerList[userAddress];
    }

    function checkInterestClaimedBy(address userAddress, uint256 poolID)
        external
        view
        ifPoolExists(poolID)
        returns (uint256)
    {
        return stakingPoolList[poolID].interestClaimerList[userAddress];
    }

    function checkRestoredFundsBy(address userAddress, uint256 poolID)
        external
        view
        ifPoolExists(poolID)
        returns (uint256)
    {
        return stakingPoolList[poolID].fundRestorerList[userAddress];
    }

    function _checkDepositCountOfAddress(address userAddress, uint256 poolID) internal view returns (uint256) {
        return stakingPoolList[poolID].stakerDepositList[userAddress].length;
    }

    function checkDepositCountOfAddress(address userAddress, uint256 poolID)
        external
        view
        ifPoolExists(poolID)
        returns (uint256)
    {
        return _checkDepositCountOfAddress(userAddress, poolID);
    }

    function getDepositsInRangeFor(address userAddress, uint256 poolID, uint256 fromIndex, uint256 toIndex)
        external
        view
        ifPoolExists(poolID)
        returns (TokenDepositWithClaimableInterest[] memory)
    {
        TokenDepositWithClaimableInterest[] memory userDepositsInRange =
            new TokenDepositWithClaimableInterest[](toIndex - fromIndex);

        for (uint256 i = fromIndex; i < toIndex; i++) {
            TokenDeposit storage deposit = stakingPoolList[poolID].stakerDepositList[userAddress][i];
            userDepositsInRange[i - fromIndex].stakingDate = deposit.stakingDate;
            userDepositsInRange[i - fromIndex].withdrawalDate = deposit.withdrawalDate;
            userDepositsInRange[i - fromIndex].amount = deposit.amount;
            userDepositsInRange[i - fromIndex].APY = deposit.APY;
            userDepositsInRange[i - fromIndex].claimedInterest = deposit.claimedInterest;
            userDepositsInRange[i - fromIndex].claimableInterest = _checkClaimableInterestBy(userAddress, poolID, i);
        }

        return userDepositsInRange;
    }

    /// @dev Returns APY, remaining amounts, and allowed amount left for a user in a pool
    function checkPoolUserInfo(address userAddress, uint256 poolID)
        external
        view
        ifPoolExists(poolID)
        returns (
            uint256 apy,
            uint256 allowedAmountLeft,
            uint256[] memory remainingAmounts,
            uint256 depositCount,
            uint256 totalStakedAmount,
            uint256 totalClaimableInterest
        )
    {
        apy = _checkAPY(poolID);
        allowedAmountLeft = _checkAllowedAmountLeftFor(userAddress, poolID);
        remainingAmounts = _getAllowlistRemainingAmountsFor(userAddress, poolID);
        depositCount = _checkDepositCountOfAddress(userAddress, poolID);
        totalStakedAmount = _checkStakedAmountBy(userAddress, poolID);
        totalClaimableInterest = _checkTotalClaimableInterestBy(userAddress, poolID);
    }

    // ======================================
    // =   Interest Calculation Functions   =
    // ======================================
    function _calculateDaysPassed(uint256 poolID, uint256 startDate, uint256 withdrawalDate)
        internal
        view
        returns (uint256)
    {
        uint256 timePassed;
        uint256 poolEndDate = stakingPoolList[poolID].endDate;

        if (withdrawalDate != 0) {
            if (poolEndDate == 0 || withdrawalDate <= poolEndDate) {
                timePassed = withdrawalDate - startDate;
            } else if (withdrawalDate > poolEndDate) {
                timePassed = poolEndDate - startDate;
            }
        } else if (poolEndDate != 0) {
            timePassed = poolEndDate - startDate;
        } else {
            timePassed = block.timestamp - startDate;
        }

        // Convert the time elapsed to days
        uint256 daysPassed = timePassed / (1 days);
        return daysPassed;
    }

    function _calculateInterest(uint256 poolID, address userAddress, uint256 depositNumber)
        internal
        view
        returns (uint256)
    {
        uint256 daysPassed;
        uint256 depositAPY;
        uint256 depositAmount;
        uint256 interestAlreadyClaimed;

        uint256 claimableInterest;

        // A local variable to refer to the appropriate TokenDeposit
        TokenDeposit storage deposit = stakingPoolList[poolID].stakerDepositList[userAddress][depositNumber];

        daysPassed = _calculateDaysPassed(poolID, deposit.stakingDate, deposit.withdrawalDate);
        depositAPY = deposit.APY;
        depositAmount = deposit.amount;
        interestAlreadyClaimed = deposit.claimedInterest;

        claimableInterest = (((depositAmount * ((depositAPY / 365) * daysPassed) / 100)) / FIXED_POINT_PRECISION)
            - interestAlreadyClaimed;
        return claimableInterest;
    }

    function _checkClaimableInterestBy(address userAddress, uint256 poolID, uint256 depositNumber)
        internal
        view
        returns (uint256)
    {
        return _calculateInterest(poolID, userAddress, depositNumber);
    }

    function _checkTotalClaimableInterestBy(address userAddress, uint256 poolID) internal view returns (uint256) {
        uint256 userDepositCount = _checkDepositCountOfAddress(userAddress, poolID);
        uint256 totalClaimableInterest = 0;

        for (uint256 depositNumber = 0; depositNumber < userDepositCount; depositNumber++) {
            totalClaimableInterest += _checkClaimableInterestBy(userAddress, poolID, depositNumber);
        }

        return totalClaimableInterest;
    }
}
