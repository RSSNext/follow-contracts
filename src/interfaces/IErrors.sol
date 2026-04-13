// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

interface IErrors {
    /// @dev receiver is empty.
    error ReceiverIsEmpty();

    /// @dev Points receiver is invalid.
    error PointsInvalidReceiver(bytes32);

    /// @dev Amount is zero.
    error AmountIsZero();

    /// @dev Insufficient balance and points.
    error InsufficientBalanceAndPoints();

    /// @dev Insufficient balance to transfer.
    error InsufficientBalanceToTransfer();

    /// @dev Exceeds max supply.
    error ExceedsMaxSupply();

    /// @dev Already minted today.
    error AlreadyMintedToday(address account);

    /// @dev Exceeds daily limit.
    error ExceedsDailyLimit();
}
