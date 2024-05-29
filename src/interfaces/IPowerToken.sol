// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

interface IPowerToken {
    /**
     * @notice Initializes the contract. Setup token name and symbol.
     * Also The msg.sender will be the APP_ADMIN_ROLE.
     * @param name_ The name of the token.
     * @param symbol_ The symbol of the token.
     */
    function initialize(string calldata name_, string calldata symbol_) external;

    /**
     * @notice Tips with tokens. The caller must have the APP_ADMIN_ROLE.
     * @param amount The amount token points to send. It can be empty.
     * @param feedId The feed id. It can be empty.
     * @dev The to and feedId are optional, but at least one of them must be provided.
     */
    function tip(uint256 amount, address to, bytes32 feedId) external;

    /**
     * @notice Mints new token points. The caller must have the APP_ADMIN_ROLE.
     * @param to The account to receive the tokens.
     */
    function mint(address to) external;

    /**
     * @notice Withdraws tokens by feedId. The caller must have the APP_ADMIN_ROLE.
     * @param to The address who receives the tokens.
     * @param feedId The amount belongs to the feedId.
     */
    function withdraw(address to, bytes32 feedId) external;

    /* @notice Return the balance of points, aka the inactive tokens, of the owner
     * @param owner The address of the owner
     * @return The amount of the balance
     */
    function balanceOfPoins(address owner) external view returns (uint256);
}
