# ERC20 Allowlist Staking

![version](https://img.shields.io/badge/version-0.2.0-blue)

This is a fork of [RealityMetaverse/erc20-staking](https://github.com/RealityMetaverse/erc20-staking) (version 1.4.2) with added allowlist functionality.

## Allowlist Features

The fork adds allowlist capabilities to the original ERC20 staking contract, allowing for controlled access to staking pools. The following functions have been added:

| Function                          | Parameters                                                   | Description                                                                  |
| --------------------------------- | ------------------------------------------------------------ | ---------------------------------------------------------------------------- |
| `setAllowlistStatus`              | `uint256 poolID, bool status`                                | Enables or disables allowlist for a specific staking pool                    |
| `addAllowedAmountFor`             | `uint256 poolID, address userAddress, uint256 amount`        | Sets the maximum staking amount for a specific user in a pool                |
| `addAllowedAmountsForBatch`       | `uint256 poolID, address[] userAddresses, uint256[] amounts` | Sets maximum staking amounts for multiple users in a pool                    |
| `checkAllowedAmountFor`           | `uint256 poolID, address userAddress`                        | Returns the maximum staking amount allowed for a user in a pool              |
| `checkTotalAllowedAmountFor`      | `uint256 poolID, address userAddress`                        | Returns the total allowed amount for a user in a pool                        |
| `checkTotalUsedAllowedAmountFor`  | `uint256 poolID, address userAddress`                        | Returns the total amount already used from the allowed amount                |
| `checkAllowedAmountLeftFor`       | `uint256 poolID, address userAddress`                        | Returns the remaining allowed amount for a user in a pool                    |
| `getAllowlistEntryCountFor`       | `uint256 poolID, address userAddress`                        | Returns the number of allowlist entries for a user in a pool                 |
| `getAllowlistEntriesFor`          | `uint256 poolID, address userAddress`                        | Returns all allowlist entries for a user in a pool                           |
| `getAllowlistRemainingAmountsFor` | `uint256 poolID, address userAddress`                        | Returns remaining amounts for each allowlist entry                           |
| `checkPoolUserInfo`               | `uint256 poolID, address userAddress`                        | Returns combined pool info including APY, allowed amounts, and deposit count |

## Unit Tests

The allowlist functionality includes comprehensive unit tests to ensure proper operation of the new features.

## Original Features

For all other features and functionality, please refer to the original repository at [RealityMetaverse/erc20-staking](https://github.com/RealityMetaverse/erc20-staking).
