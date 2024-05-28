// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

interface IAccountFactory {
    /**
     * @notice Creates a new contract account.
     * @dev Only ADMIN_ROLE is allowed to call this method.
     * @param owner The account owner.
     * @return The new created contract address.
     */
    function createAccount(address owner) external returns (address);

    /**
     * @notice Returns the account address by owner.
     * @param owner The account owner.
     * @return The contract address.
     */
    function getAddress(address owner) external view returns (address);
}
