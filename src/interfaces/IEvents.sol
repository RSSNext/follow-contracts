// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

interface IEvents {
    /**
     * @dev Emitted when points are distributed to an address.
     */
    event DistributePoints(address indexed to, uint256 indexed amount);
    /**
     * @dev Emitted when points are tipped from one address to another.
     */
    event Tip(address indexed from, address indexed to, bytes32 indexed entryId, uint256 amount);
    /**
     * @dev Emitted when points are withdrawn from an address.
     */
    event Withdraw(address indexed to, bytes32 indexed entryId, uint256 indexed amount);
}
