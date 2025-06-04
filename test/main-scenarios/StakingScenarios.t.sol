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

    function test_Staking_WhitelistingEnabled() external {
        _addPool(address(this), true);
        _setWhitelistingStatus(address(this), 0, true);
        _setWhitelistedAmountFor(address(this), 0, userOne, amountToStake);

        _increaseAllowance(userOne, amountToStake);
        _stakeTokenWithTest(userOne, 0, amountToStake, false);
    }

    function test_Staking_WhitelistingAmountExceeded() external {
        _addPool(address(this), true);
        _setWhitelistingStatus(address(this), 0, true);
        _setWhitelistedAmountFor(address(this), 0, userOne, amountToStake - 1);

        _increaseAllowance(userOne, amountToStake);
        _stakeTokenWithTest(userOne, 0, amountToStake, true);
    }

    function test_Staking_WhitelistAmountUpdatesAndMultiplePools() external {
        // Setup initial pool with whitelisting enabled
        _addPool(address(this), true);
        _setPoolMiniumumDeposit(address(this), 0, amountToStake / 10);

        // Test 1
        _setWhitelistedAmountFor(address(this), 0, userOne, amountToStake);

        _increaseAllowance(userOne, amountToStake);
        _stakeTokenWithTest(userOne, 0, amountToStake, false);

        assertEq(_getWhitelistedAmount(userOne, 0), amountToStake);

        // Test 2
        _setWhitelistingStatus(address(this), 0, true);
        _setWhitelistedAmountFor(address(this), 0, userOne, amountToStake - 1);

        _increaseAllowance(userOne, amountToStake);
        _stakeTokenWithTest(userOne, 0, amountToStake, true);

        assertEq(_getWhitelistedAmount(userOne, 0), amountToStake - 1);

        // Test 3
        _setWhitelistedAmountFor(address(this), 0, userOne, amountToStake);
        _stakeTokenWithTest(userOne, 0, amountToStake, false);

        assertEq(_getWhitelistedAmount(userOne, 0), 0);

        // Test 4
        _setWhitelistedAmountFor(address(this), 0, userOne, amountToStake);

        _increaseAllowance(userOne, amountToStake);
        _stakeTokenWithTest(userOne, 0, amountToStake - 5, false);

        assertEq(_getWhitelistedAmount(userOne, 0), 5);

        // Test 5
        _increaseAllowance(userOne, amountToStake);
        _stakeTokenWithTest(userOne, 0, amountToStake, true);

        // Test 6
        _setWhitelistedAmountFor(address(this), 0, userOne, amountToStake);
        _stakeTokenWithTest(userOne, 0, amountToStake, false);

        // Test 7
        _setWhitelistedAmountFor(address(this), 0, userOne, 0);
        _increaseAllowance(userOne, amountToStake);
        _stakeTokenWithTest(userOne, 0, amountToStake, true);

        // Test 8
        _setWhitelistingStatus(address(this), 0, false);
        _stakeTokenWithTest(userOne, 0, amountToStake, false);

        assertEq(_getTotalStakedBy(userOne, 0), amountToStake * 5 - 5);

        // Test 9
        _addPool(address(this), true);
        _setPoolMiniumumDeposit(address(this), 1, amountToStake / 10);

        // Test 10
        _increaseAllowance(userOne, amountToStake);
        _stakeTokenWithTest(userOne, 1, amountToStake, false);

        // Test 11
        _setWhitelistedAmountFor(address(this), 1, userOne, 0);

        _increaseAllowance(userOne, amountToStake);
        _stakeTokenWithTest(userOne, 1, amountToStake, false);

        // Test 13
        _setWhitelistingStatus(address(this), 1, true);
        _increaseAllowance(userOne, amountToStake);
        _stakeTokenWithTest(userOne, 1, amountToStake, true);

        // Test 14
        _setWhitelistedAmountFor(address(this), 1, userOne, amountToStake);
        _stakeTokenWithTest(userOne, 1, amountToStake, false);

        assertEq(_getTotalStakedBy(userOne, 1), amountToStake * 3);
        assertEq(_getWhitelistedAmount(userOne, 1), 0);
    }

    function test_Staking_BatchWhitelistAmounts() external {
        // Setup initial pool
        _addPool(address(this), true);
        _setWhitelistingStatus(address(this), 0, true);

        // Test 1: Set whitelisted amounts for multiple users
        address[] memory users = new address[](3);
        uint256[] memory amounts = new uint256[](3);

        users[0] = userOne;
        users[1] = userTwo;
        users[2] = userThree;

        amounts[0] = amountToStake;
        amounts[1] = amountToStake * 2;
        amounts[2] = amountToStake * 3;

        _setWhitelistedAmountsForBatch(address(this), 0, users, amounts);

        // Verify amounts were set correctly
        assertEq(_getWhitelistedAmount(userOne, 0), amountToStake);
        assertEq(_getWhitelistedAmount(userTwo, 0), amountToStake * 2);
        assertEq(_getWhitelistedAmount(userThree, 0), amountToStake * 3);

        // Test 2: Verify staking works with whitelisted amounts
        _increaseAllowance(userOne, amountToStake);
        _stakeTokenWithTest(userOne, 0, amountToStake, false);

        _increaseAllowance(userTwo, amountToStake * 2);
        _stakeTokenWithTest(userTwo, 0, amountToStake * 2, false);

        _increaseAllowance(userThree, amountToStake * 3);
        _stakeTokenWithTest(userThree, 0, amountToStake * 3, false);
    }
}
