// SPDX-License-Identifier: Apache-2.0
// Copyright 2024 HB Craft.


pragma solidity ^0.8.0;


import "./ReadFunctions.sol";
import "./WriteFunctions.sol";

contract StakingFunctions is ReadFunctions, WriteFunctions {
    function stakeToken(uint256 poolID, uint256 tokenAmount) external
    nonReentrant
    onlyUser
    ifPoolExists(poolID)
    ifAvailable(poolID, PoolDataType.IS_STAKING_OPEN)
    enoughTokenSent(tokenAmount, stakingPoolList[poolID].minimumDeposit)
    ifTargetReached(poolID, tokenAmount) {
        _receiveToken(tokenAmount);

        // Update the staking pool balances
        _updatePoolData(ActionType.STAKING, poolID, msg.sender, 0, tokenAmount);

        StakingPool storage targetPool = stakingPoolList[poolID];
        emit Stake(msg.sender, poolID, targetPool.poolType, targetPool.stakerDepositList[msg.sender].length - 1,  tokenAmount);
    }
}
