// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../AuxiliaryFunctions.sol";

contract AccessControlTest is AuxiliaryFunctions {
    function _checkAccesControl(address userAddress, PMActions actionType) internal {
        vm.expectRevert();
        _performPMActions(userAddress, actionType);
    }

    function test_AccessControl_RevertProgramControlAccess() external {
        for (uint256 actionNo; actionNo < 2; actionNo++) {
            for (uint256 userNo = 0; userNo < addressList.length; userNo++) {
                _checkAccesControl(addressList[userNo], PMActions(actionNo));
            }

            _checkAccesControl(contractAdmin, PMActions(actionNo));
        }
    }

    function test_AccessControl_RevertAddPool() external {
        for (uint256 userNo = 0; userNo < addressList.length; userNo++) {
            vm.expectRevert();
            _addPool(addressList[userNo], true);
        }
    }

    function test_AccessControl_RevertAddCustomPool() external {
        for (uint256 userNo = 0; userNo < addressList.length; userNo++) {
            vm.expectRevert();
            _addCustomPool(addressList[userNo], true);
        }
    }

    function test_AccessControl_RevertEndPool() external {
        _addPool(address(this), true);

        for (uint256 userNo = 0; userNo < addressList.length; userNo++) {
            vm.expectRevert();
            _endPool(addressList[userNo], 0);
        }
    }

    function test_AccessControl_RevertSetAllowlistStatus() external {
        for (uint256 userNo = 0; userNo < addressList.length; userNo++) {
            vm.expectRevert();
            _setAllowlistStatus(addressList[userNo], 0, true);
        }
    }

    function test_AccessControl_RevertSetAllowedAmountFor() external {
        for (uint256 userNo = 0; userNo < addressList.length; userNo++) {
            vm.expectRevert();
            _addAllowedAmountFor(addressList[userNo], 0, addressList[userNo], 1);
        }
    }

    function test_AccessControl_SetAllowlistStatus_PoolDoesNotExist() external {
        vm.expectRevert();
        _setAllowlistStatus(address(this), 0, true);
    }

    function test_AccessControl_SetAllowedAmountFor_PoolDoesNotExist() external {
        vm.expectRevert();
        _addAllowedAmountFor(address(this), 0, address(this), 1);
    }

    function test_AccessControl_SetAllowlistStatus_PoolExists() external {
        _addPool(address(this), true);

        _setAllowlistStatus(address(this), 0, true);
    }

    function test_AccessControl_SetAllowedAmountFor_PoolExists() external {
        _addPool(address(this), true);

        _addAllowedAmountFor(address(this), 0, address(this), 1);
    }

    function test_AccessControl_SetAllowlistStatus_WrongPoolID() external {
        _addPool(address(this), true);

        vm.expectRevert();
        _setAllowlistStatus(address(this), 1, true);
    }

    function test_AccessControl_SetAllowedAmountFor_WrongPoolID() external {
        _addPool(address(this), true);

        vm.expectRevert();
        _addAllowedAmountFor(address(this), 1, address(this), 1);
    }

    function test_AccessControl_RevertSetAllowedAmountsForBatch() external {
        _addPool(address(this), true);

        address[] memory users = new address[](1);
        uint256[] memory amounts = new uint256[](1);

        users[0] = userOne;
        amounts[0] = amountToStake;

        for (uint256 userNo = 0; userNo < addressList.length; userNo++) {
            vm.expectRevert();
            _addAllowedAmountsForBatch(addressList[userNo], 0, users, amounts);
        }

        address[] memory shortUsers = new address[](2);
        vm.expectRevert("Arrays length mismatch");
        _addAllowedAmountsForBatch(address(this), 0, shortUsers, amounts);

        vm.expectRevert();
        _addAllowedAmountsForBatch(address(this), 1, users, amounts);
    }

    function test_AccessControl_RevertRemoveLastAllowlistEntryFor() external {
        _addPool(address(this), true);

        for (uint256 userNo = 0; userNo < addressList.length; userNo++) {
            vm.expectRevert();
            _removeLastAllowlistEntryFor(addressList[userNo], 0, userOne);
        }

        vm.expectRevert();
        _removeLastAllowlistEntryFor(address(this), 1, userOne);

        vm.expectRevert("No allowlist entries to remove");
        _removeLastAllowlistEntryFor(address(this), 0, userOne);
    }

    function test_AccessControl_RevertRemoveLastAllowlistEntriesForBatch() external {
        _addPool(address(this), true);

        address[] memory users = new address[](1);
        users[0] = userOne;

        for (uint256 userNo = 0; userNo < addressList.length; userNo++) {
            vm.expectRevert();
            _removeLastAllowlistEntriesForBatch(addressList[userNo], 0, users);
        }

        vm.expectRevert();
        _removeLastAllowlistEntriesForBatch(address(this), 1, users);

        vm.expectRevert("No allowlist entries to remove");
        _removeLastAllowlistEntriesForBatch(address(this), 0, users);
    }

    function test_AccessControl_RevertSetAmountOfAllowlistEntry() external {
        _addPool(address(this), true);

        for (uint256 userNo = 0; userNo < addressList.length; userNo++) {
            vm.expectRevert();
            _setAmountOfAllowlistEntry(addressList[userNo], 0, userOne, 0, amountToStake);
        }

        vm.expectRevert();
        _setAmountOfAllowlistEntry(address(this), 1, userOne, 0, amountToStake);

        vm.expectRevert();
        _setAmountOfAllowlistEntry(address(this), 0, userOne, 0, amountToStake);
    }

    function test_AccessControl_RevertSetAmountOfAllowlistEntriesForBatch() external {
        _addPool(address(this), true);

        address[] memory users = new address[](1);
        uint256[] memory entryNos = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);

        users[0] = userOne;
        entryNos[0] = 0;
        amounts[0] = amountToStake;

        for (uint256 userNo = 0; userNo < addressList.length; userNo++) {
            vm.expectRevert();
            _setAmountOfAllowlistEntriesForBatch(addressList[userNo], 0, users, entryNos, amounts);
        }

        vm.expectRevert();
        _setAmountOfAllowlistEntriesForBatch(address(this), 1, users, entryNos, amounts);

        address[] memory shortUsers = new address[](2);
        vm.expectRevert("Arrays length mismatch");
        _setAmountOfAllowlistEntriesForBatch(address(this), 0, shortUsers, entryNos, amounts);

        vm.expectRevert();
        _setAmountOfAllowlistEntriesForBatch(address(this), 0, users, entryNos, amounts);
    }
}
