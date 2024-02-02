// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TestSetUp.t.sol";

contract ReadFunctions is TestSetUp {
    function _getTotalStaked(uint256 poolID) internal view
    returns (uint256) {
        return stakingContract.checkTotalStaked()[poolID];
    }

    function _getTotalStakedBy(address userAddress, uint256 poolID) internal view
    returns (uint256) {
        return stakingContract.checkStakedAmountByAddress(userAddress)[poolID];
    }

    function _getTotalWithdrawn(uint256 poolID) internal view
    returns (uint256) {
        return stakingContract.checkTotalWithdrew()[poolID];
    }

    function _getTotalWithdrawnBy(address userAddress, uint256 poolID) internal view
    returns (uint256) {
        return stakingContract.checkWithdrewAmountByAddress(userAddress)[poolID];
    }

    function _getUserDepositCount(address userAddress, uint256 poolID) internal view
    returns (uint256) {
        return stakingContract.checkDepositCountOfAddress(userAddress)[poolID];
    }

    function _getTokenBalance(address userAddress, bool withDecimals) internal view
    returns (uint256) {
        return myToken.balanceOf(userAddress) / ((withDecimals) ? 1 : myTokenDecimals);
    }

    function _getCurrentData(address userAddress, uint256 _poolID, bool ifWithDecimals) internal view
    returns (uint256[] memory) {
        uint256[] memory data = new uint256[](4);
        data[0] = _getTotalStaked(_poolID);
        data[1] = _getTokenBalance(userAddress, ifWithDecimals);
        data[2] = _getTotalStakedBy(userAddress, _poolID);
        data[3] = _getTokenBalance(address(stakingContract), ifWithDecimals);
        return data;
    }
}