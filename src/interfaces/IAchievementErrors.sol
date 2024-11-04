// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

interface IErrors {
    /// @dev receiver is empty.
    error Unauthorized();

    /// @dev achievement is not set.
    error AchievementNotSet();
}
