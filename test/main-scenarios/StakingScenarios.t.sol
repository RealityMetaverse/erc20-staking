// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../AuxiliaryFunctions.sol";

contract StakingScenarious is AuxiliaryFunctions {
    function test_Staking_BeforeLaunch() external {
        _stakeTokenWithTest(userOne, 0, amountToStake, true);
    }

    function test_Staking_NoAllowance() external {
        _addPool(address(this), true);

        _stakeTokenWithTest(userOne, 0, amountToStake, true);
    }

    function test_Staking_IncreasedAllowance() external {
        _addPool(address(this), true);

        _increaseAllowance(userOne, amountToStake);
        _stakeTokenWithTest(userOne, 0, amountToStake, false);
    }

    function test_Staking_MultiplePools() external {
        _tryMultiUserMultiStake(10, true);
    }

    function test_Staking_InsufficentDeposit() external {
        _addPool(address(this), true);

        _increaseAllowance(userOne, 1);
        _stakeTokenWithTest(userOne, 0, 1, true);
    }

    function test_Staking_AmountExceedsTarget() external {
        _addPool(address(this), true);
        _addPool(address(this), true);
        _stakeTokenWithAllowance(userThree, 0, stakingContract.checkStakingTarget(0));

        _increaseAllowance(userOne, amountToStake);
        _stakeTokenWithTest(userOne, 0, amountToStake, true);

        _increaseAllowance(userOne, amountToStake);
        _stakeTokenWithTest(userOne, 1, amountToStake, false);
    }

    function test_Staking_NotOpen() external {
        _addPool(address(this), true);
        stakingContract.changePoolAvailabilityStatus(0, 0, false);

        _increaseAllowance(userOne, amountToStake);
        _stakeTokenWithTest(userOne, 0, amountToStake, true);
    }

    function test_Staking_ProgramPaused() external {
        _addPool(address(this), true);
        _performPMActions(address(this), PMActions.PAUSE);

        _increaseAllowance(userOne, amountToStake);
        _stakeTokenWithTest(userOne, 0, amountToStake, true);
    }

    function test_Staking_ProgramResumed() external {
        _addPool(address(this), true);
        _performPMActions(address(this), PMActions.PAUSE);
        _performPMActions(address(this), PMActions.RESUME);

        _stakeTokenWithAllowance(userOne, 0, amountToStake);
    }

    function test_Staking_ProgramEnded() external {
        _addPool(address(this), true);
        _addPool(address(this), true);
        _endPool(address(this), 0);

        _increaseAllowance(userOne, amountToStake);
        _stakeTokenWithTest(userOne, 1, amountToStake, false);

        _increaseAllowance(userOne, amountToStake);
        _stakeTokenWithTest(userOne, 0, amountToStake, true);
    }

    function test_Staking_AllowlistEnabled() external {
        _addPool(address(this), true);
        _setAllowlistStatus(address(this), 0, true);
        _addAllowedAmountFor(address(this), 0, userOne, amountToStake);

        _increaseAllowance(userOne, amountToStake);
        _stakeTokenWithTest(userOne, 0, amountToStake, false);
    }

    function test_Staking_AllowlistAmountExceeded() external {
        _addPool(address(this), true);
        _setAllowlistStatus(address(this), 0, true);
        _addAllowedAmountFor(address(this), 0, userOne, amountToStake - 1);

        _increaseAllowance(userOne, amountToStake);
        _stakeTokenWithTest(userOne, 0, amountToStake, true);
    }

    function test_Staking_AllowlistAmountUpdatesAndMultiplePools() external {
        // Setup initial pool with allowlist enabled
        _addPool(address(this), true);
        _setPoolMiniumumDeposit(address(this), 0, amountToStake / 10);

        // Test 1: Verify staking works when allowlist is disabled
        _addAllowedAmountFor(address(this), 0, userOne, amountToStake);

        _increaseAllowance(userOne, amountToStake);
        _stakeTokenWithTest(userOne, 0, amountToStake, false);

        assertEq(_getAllowedAmountLeftFor(userOne, 0), amountToStake);
        assertEq(_getTotalStakedBy(userOne, 0), amountToStake);
        assertEq(_getTotalStaked(0), amountToStake);
        assertEq(_getAllowlistEntryCountFor(userOne, 0), 1);
        assertEq(_getAllowlistRemainingAmountsFor(userOne, 0)[0], amountToStake);

        // Test 2: Verify staking fails when allowlist is enabled and allowed amount is insufficient
        _setAllowlistStatus(address(this), 0, true);
        _setAmountOfAllowlistEntry(address(this), 0, userOne, 0, amountToStake - 1);

        _increaseAllowance(userOne, amountToStake);
        _stakeTokenWithTest(userOne, 0, amountToStake, true);

        assertEq(_getAllowedAmountLeftFor(userOne, 0), amountToStake - 1);
        assertEq(_getTotalStakedBy(userOne, 0), amountToStake);
        assertEq(_getTotalStaked(0), amountToStake);
        assertEq(_getAllowlistEntryCountFor(userOne, 0), 1);
        assertEq(_getAllowlistRemainingAmountsFor(userOne, 0)[0], amountToStake - 1);

        // Test 3: Verify staking succeeds when allowlist is enabled and allowed amount is sufficient
        _setAmountOfAllowlistEntry(address(this), 0, userOne, 0, amountToStake);
        _stakeTokenWithTest(userOne, 0, amountToStake, false);

        assertEq(_getAllowedAmountLeftFor(userOne, 0), 0);
        assertEq(_getTotalStakedBy(userOne, 0), amountToStake * 2);
        assertEq(_getTotalStaked(0), amountToStake * 2);
        assertEq(_getAllowlistEntryCountFor(userOne, 0), 1);
        assertEq(_getAllowlistRemainingAmountsFor(userOne, 0)[0], 0);

        // Test 4: Verify partial staking works and updates allowed amount correctly
        _addAllowedAmountFor(address(this), 0, userOne, amountToStake);

        _increaseAllowance(userOne, amountToStake);
        _stakeTokenWithTest(userOne, 0, amountToStake - 5, false);

        assertEq(_getAllowedAmountLeftFor(userOne, 0), 5);
        assertEq(_getTotalStakedBy(userOne, 0), amountToStake * 3 - 5);
        assertEq(_getTotalStaked(0), amountToStake * 3 - 5);
        assertEq(_getAllowlistEntryCountFor(userOne, 0), 2);
        assertEq(_getAllowlistRemainingAmountsFor(userOne, 0)[0], 0);
        assertEq(_getAllowlistRemainingAmountsFor(userOne, 0)[1], 5);

        // Test 5: Verify staking fails when trying to stake more than remaining allowed amount
        _increaseAllowance(userOne, amountToStake);
        _stakeTokenWithTest(userOne, 0, amountToStake, true);

        assertEq(_getAllowedAmountLeftFor(userOne, 0), 5);
        assertEq(_getTotalStakedBy(userOne, 0), amountToStake * 3 - 5);
        assertEq(_getTotalStaked(0), amountToStake * 3 - 5);
        assertEq(_getAllowlistEntryCountFor(userOne, 0), 2);
        assertEq(_getAllowlistRemainingAmountsFor(userOne, 0)[0], 0);
        assertEq(_getAllowlistRemainingAmountsFor(userOne, 0)[1], 5);

        // Test 6: Verify staking succeeds when allowed amount is increased
        _addAllowedAmountFor(address(this), 0, userOne, amountToStake);
        _stakeTokenWithTest(userOne, 0, amountToStake, false);

        assertEq(_getAllowedAmountLeftFor(userOne, 0), 5);
        assertEq(_getTotalStakedBy(userOne, 0), amountToStake * 4 - 5);
        assertEq(_getTotalStaked(0), amountToStake * 4 - 5);
        assertEq(_getAllowlistEntryCountFor(userOne, 0), 3);
        assertEq(_getAllowlistRemainingAmountsFor(userOne, 0)[2], 5);

        // Test 7: Verify staking fails when allowed amount is set to 0
        _addAllowedAmountFor(address(this), 0, userOne, 0);
        _increaseAllowance(userOne, amountToStake);
        _stakeTokenWithTest(userOne, 0, amountToStake, true);

        assertEq(_getAllowedAmountLeftFor(userOne, 0), 5);
        assertEq(_getTotalStakedBy(userOne, 0), amountToStake * 4 - 5);
        assertEq(_getTotalStaked(0), amountToStake * 4 - 5);
        assertEq(_getAllowlistEntryCountFor(userOne, 0), 4);
        assertEq(_getAllowlistRemainingAmountsFor(userOne, 0)[2], 5);

        // Test 8: Verify staking works when allowlist is disabled
        _setAllowlistStatus(address(this), 0, false);
        _stakeTokenWithTest(userOne, 0, amountToStake, false);

        assertEq(_getTotalStakedBy(userOne, 0), amountToStake * 5 - 5);
        assertEq(_getTotalStaked(0), amountToStake * 5 - 5);
        assertEq(_getAllowedAmountLeftFor(userOne, 0), 5);
        assertEq(_getAllowlistEntryCountFor(userOne, 0), 4);
        assertEq(_getAllowlistRemainingAmountsFor(userOne, 0)[2], 5);

        // Test 9: Verify removeLastAllowlistEntryFor works correctly
        _addAllowedAmountFor(address(this), 0, userOne, amountToStake);
        _addAllowedAmountFor(address(this), 0, userOne, amountToStake * 2);
        assertEq(_getAllowedAmountLeftFor(userOne, 0), amountToStake * 3 + 5);
        assertEq(_getAllowlistEntryCountFor(userOne, 0), 6);
        assertEq(_getAllowlistRemainingAmountsFor(userOne, 0)[0], 0);
        assertEq(_getAllowlistRemainingAmountsFor(userOne, 0)[1], 0);
        assertEq(_getAllowlistRemainingAmountsFor(userOne, 0)[2], 5);
        assertEq(_getAllowlistRemainingAmountsFor(userOne, 0)[3], 0);
        assertEq(_getAllowlistRemainingAmountsFor(userOne, 0)[4], amountToStake);
        assertEq(_getAllowlistRemainingAmountsFor(userOne, 0)[5], amountToStake * 2);

        _removeLastAllowlistEntryFor(address(this), 0, userOne);
        assertEq(_getAllowedAmountLeftFor(userOne, 0), amountToStake + 5);
        assertEq(_getAllowlistEntryCountFor(userOne, 0), 5);
        assertEq(_getAllowlistRemainingAmountsFor(userOne, 0)[0], 0);
        assertEq(_getAllowlistRemainingAmountsFor(userOne, 0)[1], 0);
        assertEq(_getAllowlistRemainingAmountsFor(userOne, 0)[2], 5);
        assertEq(_getAllowlistRemainingAmountsFor(userOne, 0)[3], 0);
        assertEq(_getAllowlistRemainingAmountsFor(userOne, 0)[4], amountToStake);

        // Test 10: Verify removeLastAllowlistEntriesForBatch works correctly
        address[] memory usersToRemove = new address[](2);
        usersToRemove[0] = userOne;
        usersToRemove[1] = userTwo;

        _addAllowedAmountFor(address(this), 0, userTwo, amountToStake);
        _addAllowedAmountFor(address(this), 0, userTwo, amountToStake * 2);

        _removeLastAllowlistEntriesForBatch(address(this), 0, usersToRemove);
        assertEq(_getAllowedAmountLeftFor(userOne, 0), 5);
        assertEq(_getAllowedAmountLeftFor(userTwo, 0), amountToStake);
        assertEq(_getAllowlistEntryCountFor(userOne, 0), 4);
        assertEq(_getAllowlistEntryCountFor(userTwo, 0), 1);
        assertEq(_getAllowlistRemainingAmountsFor(userOne, 0)[0], 0);
        assertEq(_getAllowlistRemainingAmountsFor(userOne, 0)[1], 0);
        assertEq(_getAllowlistRemainingAmountsFor(userOne, 0)[2], 5);
        assertEq(_getAllowlistRemainingAmountsFor(userOne, 0)[3], 0);
        assertEq(_getAllowlistRemainingAmountsFor(userTwo, 0)[0], amountToStake);

        // Test 11: Verify setAmountOfAllowlistEntriesForBatch works correctly
        _addAllowedAmountFor(address(this), 0, userOne, amountToStake);

        address[] memory usersToUpdate = new address[](2);
        uint256[] memory entryNos = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);

        usersToUpdate[0] = userOne;
        usersToUpdate[1] = userTwo;
        entryNos[0] = 0;
        entryNos[1] = 0;
        amounts[0] = amountToStake * 3;
        amounts[1] = amountToStake * 4;

        _setAmountOfAllowlistEntriesForBatch(address(this), 0, usersToUpdate, entryNos, amounts);
        assertEq(_getAllowedAmountLeftFor(userOne, 0), amountToStake * 3 + 5);
        assertEq(_getAllowedAmountLeftFor(userTwo, 0), amountToStake * 4);
        assertEq(_getAllowlistEntryCountFor(userOne, 0), 5);
        assertEq(_getAllowlistEntryCountFor(userTwo, 0), 1);
        assertEq(_getAllowlistRemainingAmountsFor(userOne, 0)[0], 5);
        assertEq(_getAllowlistRemainingAmountsFor(userOne, 0)[1], amountToStake);
        assertEq(_getAllowlistRemainingAmountsFor(userOne, 0)[2], amountToStake);
        assertEq(_getAllowlistRemainingAmountsFor(userOne, 0)[3], 0);
        assertEq(_getAllowlistRemainingAmountsFor(userTwo, 0)[0], amountToStake * 4);

        // Test 12: Setup second pool with allowlist disabled
        _addPool(address(this), true);
        _setPoolMiniumumDeposit(address(this), 1, amountToStake / 10);

        // Test 13: Verify staking works in second pool when allowlist is disabled
        _increaseAllowance(userOne, amountToStake);
        _stakeTokenWithTest(userOne, 1, amountToStake, false);

        assertEq(_getTotalStakedBy(userOne, 1), amountToStake);
        assertEq(_getTotalStaked(1), amountToStake);
        assertEq(_getAllowedAmountLeftFor(userOne, 1), 0);
        assertEq(_getAllowlistEntryCountFor(userOne, 1), 0);

        // Test 14: Verify staking works in second pool when allowlist is disabled and allowed amount is 0
        _addAllowedAmountFor(address(this), 1, userOne, 0);

        _increaseAllowance(userOne, amountToStake);
        _stakeTokenWithTest(userOne, 1, amountToStake, false);

        assertEq(_getTotalStakedBy(userOne, 1), amountToStake * 2);
        assertEq(_getTotalStaked(1), amountToStake * 2);
        assertEq(_getAllowedAmountLeftFor(userOne, 1), 0);
        assertEq(_getAllowlistEntryCountFor(userOne, 1), 1);
        assertEq(_getAllowlistRemainingAmountsFor(userOne, 1)[0], 0);

        // Test 15: Verify staking fails in second pool when allowlist is enabled and no allowed amount
        _setAllowlistStatus(address(this), 1, true);
        _increaseAllowance(userOne, amountToStake);
        _stakeTokenWithTest(userOne, 1, amountToStake, true);

        assertEq(_getTotalStakedBy(userOne, 1), amountToStake * 2);
        assertEq(_getTotalStaked(1), amountToStake * 2);
        assertEq(_getAllowedAmountLeftFor(userOne, 1), 0);
        assertEq(_getAllowlistEntryCountFor(userOne, 1), 1);
        assertEq(_getAllowlistRemainingAmountsFor(userOne, 1)[0], 0);

        // Test 16: Verify staking succeeds in second pool when allowlist is enabled and allowed amount is sufficient
        _addAllowedAmountFor(address(this), 1, userOne, amountToStake);
        _stakeTokenWithTest(userOne, 1, amountToStake, false);

        assertEq(_getTotalStakedBy(userOne, 1), amountToStake * 3);
        assertEq(_getTotalStaked(1), amountToStake * 3);
        assertEq(_getAllowedAmountLeftFor(userOne, 1), 0);
        assertEq(_getAllowlistEntryCountFor(userOne, 1), 2);
        assertEq(_getAllowlistRemainingAmountsFor(userOne, 1)[1], 0);

        // Final state verification
        assertEq(_getTotalStakedBy(userOne, 0), amountToStake * 5 - 5);
        assertEq(_getTotalStakedBy(userOne, 1), amountToStake * 3);
        assertEq(_getTotalStaked(0), amountToStake * 5 - 5);
        assertEq(_getTotalStaked(1), amountToStake * 3);
        assertEq(_getAllowedAmountLeftFor(userOne, 1), 0);
    }

    function test_Staking_BatchAllowlistAmounts() external {
        // Setup initial pool
        _addPool(address(this), true);
        _setAllowlistStatus(address(this), 0, true);

        // Test 1: Set allowed amounts for multiple users
        address[] memory users = new address[](3);
        uint256[] memory amounts = new uint256[](3);

        users[0] = userOne;
        users[1] = userTwo;
        users[2] = userThree;

        amounts[0] = amountToStake;
        amounts[1] = amountToStake * 2;
        amounts[2] = amountToStake * 3;

        _addAllowedAmountsForBatch(address(this), 0, users, amounts);

        // Verify amounts were set correctly
        assertEq(_getAllowedAmountLeftFor(userOne, 0), amountToStake);
        assertEq(_getAllowedAmountLeftFor(userTwo, 0), amountToStake * 2);
        assertEq(_getAllowedAmountLeftFor(userThree, 0), amountToStake * 3);

        // Test 2: Verify staking works with allowed amounts
        _increaseAllowance(userOne, amountToStake);
        _stakeTokenWithTest(userOne, 0, amountToStake, false);

        _increaseAllowance(userTwo, amountToStake * 2);
        _stakeTokenWithTest(userTwo, 0, amountToStake * 2, false);

        _increaseAllowance(userThree, amountToStake * 3);
        _stakeTokenWithTest(userThree, 0, amountToStake * 3, false);

        // Verify final state after all staking operations
        assertEq(_getTotalStakedBy(userOne, 0), amountToStake);
        assertEq(_getTotalStakedBy(userTwo, 0), amountToStake * 2);
        assertEq(_getTotalStakedBy(userThree, 0), amountToStake * 3);

        // Verify no allowed amounts remain
        assertEq(_getAllowedAmountLeftFor(userOne, 0), 0);
        assertEq(_getAllowedAmountLeftFor(userTwo, 0), 0);
        assertEq(_getAllowedAmountLeftFor(userThree, 0), 0);

        // Verify total staked in pool
        assertEq(_getTotalStaked(0), amountToStake * 6);
    }
}
