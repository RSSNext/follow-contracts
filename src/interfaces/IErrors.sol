// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

interface IErrors {
    /// @dev Tip parameter is empty.
    error TipReceiverIsEmpty();

    /// @dev Points receiver is invalid.
    error PointsInvalidReceiver(bytes32);

    /// @dev Tip amount is zero.
    error TipAmountIsZero();

    /// @dev Insufficient balance and points.
    error InsufficientBalanceAndPoints();

    /// @dev Insufficient balance to transfer.
    error InsufficientBalanceToTransfer();

    /// @dev Exceeds max supply.
    error ExceedsMaxSupply();

    /// @dev Already minted today.
    error AlreadyMintedToday(address account);
}
