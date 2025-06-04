# ERC20 Whitelisted Staking

![version](https://img.shields.io/badge/version-0.1.0-blue)

This is a fork of [RealityMetaverse/erc20-staking](https://github.com/RealityMetaverse/erc20-staking) (version 1.4.2) with added whitelisting functionality.

## Whitelisting Features

The fork adds whitelisting capabilities to the original ERC20 staking contract, allowing for controlled access to staking pools. The following functions have been added:

| Function                        | Parameters                                                   | Description                                                     |
| ------------------------------- | ------------------------------------------------------------ | --------------------------------------------------------------- |
| `setWhitelistingStatus`         | `uint256 poolID, bool status`                                | Enables or disables whitelisting for a specific staking pool    |
| `setWhitelistedAmountFor`       | `uint256 poolID, address userAddress, uint256 amount`        | Sets the maximum staking amount for a specific user in a pool   |
| `setWhitelistedAmountsForBatch` | `uint256 poolID, address[] userAddresses, uint256[] amounts` | Sets maximum staking amounts for multiple users in a pool       |
| `checkWhitelistedAmountFor`     | `uint256 poolID, address userAddress`                        | Returns the maximum staking amount allowed for a user in a pool |

### Whitelist Amount Behavior

When a user stakes tokens, their whitelisted amount is deducted by the staked amount. However, when tokens are withdrawn, the whitelisted amount is not increased back. This means the whitelisted amount represents the maximum amount a user can stake in total, and it decreases permanently as they stake tokens.

## Unit Tests

The whitelisting functionality includes comprehensive unit tests to ensure proper operation of the new features.

## Original Features

For all other features and functionality, please refer to the original repository at [RealityMetaverse/erc20-staking](https://github.com/RealityMetaverse/erc20-staking).
