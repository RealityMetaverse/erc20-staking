// SPDX-License-Identifier: BUSL-1.1
// Copyright 2025 Reality Metaverse

pragma solidity 0.8.20;

import "./ReadFunctions.sol";
import "./WriteFunctions.sol";

abstract contract WithdrawFunctions is ReadFunctions, WriteFunctions {
    // ======================================
    // =     Interest Claim Functions       =
    // ======================================
    function checkClaimableInterestBy(address userAddress, uint256 poolID, uint256 depositNumber)
        external
        view
        ifPoolExists(poolID)
        returns (uint256)
    {
        return _calculateInterest(poolID, userAddress, depositNumber);
    }

    function checkTotalClaimableInterestBy(address userAddress, uint256 poolID) public view returns (uint256) {
        return _checkTotalClaimableInterestBy(userAddress, poolID);
    }

    function checkTotalClaimableInterest(uint256 poolID) external view ifPoolExists(poolID) returns (uint256) {
        uint256 totalClaimableInterest = 0;

        for (uint256 stakerNo = 0; stakerNo < stakingPoolList[poolID].stakerAddressList.length; stakerNo++) {
            totalClaimableInterest +=
                checkTotalClaimableInterestBy(stakingPoolList[poolID].stakerAddressList[stakerNo], poolID);
        }

        return totalClaimableInterest;
    }

    function checkGeneratedInterestLastDayFor(address userAddress, uint256 poolID)
        external
        view
        ifPoolExists(poolID)
        returns (uint256)
    {
        uint256 userDepositCount = _checkDepositCountOfAddress(userAddress, poolID);
        uint256 totalLastDayGenerated = 0;

        StakingPool storage targetStakingPool = stakingPoolList[poolID];
        for (uint256 depositNumber = 0; depositNumber < userDepositCount; depositNumber++) {
            TokenDeposit storage targetDeposit = targetStakingPool.stakerDepositList[userAddress][depositNumber];
            if (targetDeposit.withdrawalDate == 0 && (((block.timestamp - targetDeposit.stakingDate) / (1 days)) >= 1))
            {
                totalLastDayGenerated +=
                    (targetDeposit.amount * (targetDeposit.APY / 365) / 100) / FIXED_POINT_PRECISION;
            }
        }

        return totalLastDayGenerated;
    }

    function checkGeneratedInterestDailyTotal(uint256 poolID, bool ifPrecise)
        external
        view
        ifPoolExists(poolID)
        returns (uint256)
    {
        uint256 dailyTotalInterestGenerated = 0;

        if (ifPrecise) {
            address userAddress;
            uint256 userDepositCount;

            for (uint256 stakerNo = 0; stakerNo < stakingPoolList[poolID].stakerAddressList.length; stakerNo++) {
                userAddress = stakingPoolList[poolID].stakerAddressList[stakerNo];
                userDepositCount = _checkDepositCountOfAddress(userAddress, poolID);

                for (uint256 depositNumber = 0; depositNumber < userDepositCount; depositNumber++) {
                    TokenDeposit storage targetDeposit =
                        stakingPoolList[poolID].stakerDepositList[userAddress][depositNumber];
                    if (targetDeposit.withdrawalDate == 0) {
                        dailyTotalInterestGenerated +=
                            (targetDeposit.amount * (targetDeposit.APY / 365) / 100) / FIXED_POINT_PRECISION;
                    }
                }
            }
        } else {
            StakingPool storage targetStakingPool = stakingPoolList[poolID];
            dailyTotalInterestGenerated = (
                targetStakingPool.totalList[DataType.STAKED] * (targetStakingPool.APY / 365) / 100
            ) / FIXED_POINT_PRECISION;
        }

        return dailyTotalInterestGenerated;
    }

    function _processInterestClaim(uint256 poolID, address userAddress, uint256 depositNumber, bool isBatchClaim)
        private
    {
        uint256 interestToClaim = _calculateInterest(poolID, userAddress, depositNumber);

        if (!isBatchClaim) {
            if (interestPool < interestToClaim) {
                revert NotEnoughFundsInTheInterestPool(interestToClaim, interestPool);
            }

            if (interestToClaim == 0) {
                revert("Nothing to Claim");
            }
        }

        if (isBatchClaim && (interestPool < interestToClaim || interestToClaim == 0)) {
            // Skip claiming for this case
            return;
        }

        // Proceed with claiming process
        _updatePoolData(ActionType.INTEREST_CLAIM, poolID, msg.sender, depositNumber, interestToClaim);
        interestPool -= interestToClaim;

        emit ClaimInterest(msg.sender, poolID, depositNumber, interestToClaim);
        _sendToken(msg.sender, interestToClaim);
    }

    /// @dev isBatchClaim = true because the function is called by withdraw function and we don't want to raise an exception when nothing to claim
    function _claimInterest(uint256 poolID, address userAddress, uint256 depositNumber) private {
        bool _isInterestClaimOpen = stakingPoolList[poolID].isInterestClaimOpen;
        if (_isInterestClaimOpen) _processInterestClaim(poolID, userAddress, depositNumber, true);
    }

    function claimInterest(uint256 poolID, uint256 depositNumber)
        external
        nonReentrant
        ifPoolExists(poolID)
        ifAvailable(poolID, PoolDataType.IS_INTEREST_CLAIM_OPEN)
    {
        _processInterestClaim(poolID, msg.sender, depositNumber, false);
    }

    function claimAllInterest(uint256 poolID)
        external
        nonReentrant
        ifPoolExists(poolID)
        ifAvailable(poolID, PoolDataType.IS_INTEREST_CLAIM_OPEN)
    {
        for (
            uint256 depositNumber = 0;
            depositNumber < stakingPoolList[poolID].stakerDepositList[msg.sender].length;
            depositNumber++
        ) {
            _processInterestClaim(poolID, msg.sender, depositNumber, true);
        }
    }

    // ======================================
    // =    Withdraw Related Functions      =
    // ======================================
    function _withdrawDeposit(uint256 poolID, uint256 depositNumber, bool isBatchWithdrawal) private {
        TokenDeposit storage targetDeposit = stakingPoolList[poolID].stakerDepositList[msg.sender][depositNumber];
        uint256 depositWithdrawalDate = targetDeposit.withdrawalDate;

        if (depositWithdrawalDate != 0) {
            if (!isBatchWithdrawal) {
                revert("Deposit already withdrawn");
            }
        } else {
            _claimInterest(poolID, msg.sender, depositNumber);

            // Update the staking pool balances
            uint256 amountToWithdraw = targetDeposit.amount;
            _updatePoolData(ActionType.WITHDRAWAL, poolID, msg.sender, depositNumber, amountToWithdraw);

            emit Withdraw(msg.sender, poolID, stakingPoolList[poolID].poolType, depositNumber, amountToWithdraw);
            _sendToken(msg.sender, amountToWithdraw);
        }
    }

    function withdrawDeposit(uint256 poolID, uint256 depositNumber)
        external
        nonReentrant
        ifPoolExists(poolID)
        ifDepositExists(poolID, depositNumber)
        ifAvailable(poolID, PoolDataType.IS_WITHDRAWAL_OPEN)
        enoughFundsAvailable(poolID, stakingPoolList[poolID].stakerDepositList[msg.sender][depositNumber].amount)
    {
        _withdrawDeposit(poolID, depositNumber, false);
    }

    function withdrawAll(uint256 poolID)
        external
        nonReentrant
        ifPoolExists(poolID)
        sufficientBalance(poolID)
        ifAvailable(poolID, PoolDataType.IS_WITHDRAWAL_OPEN)
        enoughFundsAvailable(poolID, stakingPoolList[poolID].stakerList[msg.sender])
    {
        StakingPool storage targetPool = stakingPoolList[poolID];
        TokenDeposit[] storage targetDepositList = targetPool.stakerDepositList[msg.sender];

        for (uint128 depositNumber = 0; depositNumber < targetDepositList.length; depositNumber++) {
            _withdrawDeposit(poolID, depositNumber, true);
        }
    }
}
