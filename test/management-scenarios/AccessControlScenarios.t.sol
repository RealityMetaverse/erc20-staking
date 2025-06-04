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

    function test_AccessControl_RevertSetWhitelistingStatus() external {
        for (uint256 userNo = 0; userNo < addressList.length; userNo++) {
            vm.expectRevert();
            _setWhitelistingStatus(addressList[userNo], 0, true);
        }
    }

    function test_AccessControl_RevertSetWhitelistedAmountFor() external {
        for (uint256 userNo = 0; userNo < addressList.length; userNo++) {
            vm.expectRevert();
            _setWhitelistedAmountFor(addressList[userNo], 0, addressList[userNo], 1);
        }
    }

    function test_AccessControl_SetWhitelistingStatus_PoolDoesNotExist() external {
        vm.expectRevert();
        _setWhitelistingStatus(address(this), 0, true);
    }

    function test_AccessControl_SetWhitelistedAmountFor_PoolDoesNotExist() external {
        vm.expectRevert();
        _setWhitelistedAmountFor(address(this), 0, address(this), 1);
    }

    function test_AccessControl_SetWhitelistingStatus_PoolExists() external {
        _addPool(address(this), true);

        _setWhitelistingStatus(address(this), 0, true);
    }

    function test_AccessControl_SetWhitelistedAmountFor_PoolExists() external {
        _addPool(address(this), true);

        _setWhitelistedAmountFor(address(this), 0, address(this), 1);
    }

    function test_AccessControl_SetWhitelistingStatus_WrongPoolID() external {
        _addPool(address(this), true);

        vm.expectRevert();
        _setWhitelistingStatus(address(this), 1, true);
    }

    function test_AccessControl_SetWhitelistedAmountFor_WrongPoolID() external {
        _addPool(address(this), true);

        vm.expectRevert();
        _setWhitelistedAmountFor(address(this), 1, address(this), 1);
    }

    function test_AccessControl_RevertSetWhitelistedAmountsForBatch() external {
        _addPool(address(this), true);

        address[] memory users = new address[](1);
        uint256[] memory amounts = new uint256[](1);

        users[0] = userOne;
        amounts[0] = amountToStake;

        // Test unauthorized access
        for (uint256 userNo = 0; userNo < addressList.length; userNo++) {
            vm.expectRevert();
            _setWhitelistedAmountsForBatch(addressList[userNo], 0, users, amounts);
        }

        // Test array length mismatch
        address[] memory shortUsers = new address[](2);
        vm.expectRevert("Arrays length mismatch");
        _setWhitelistedAmountsForBatch(address(this), 0, shortUsers, amounts);

        // Test non-existent pool
        vm.expectRevert();
        _setWhitelistedAmountsForBatch(address(this), 1, users, amounts);
    }
}
