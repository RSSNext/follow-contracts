// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

interface IPowerToken {
    /**
     * @notice Initializes the contract. Setup token name, symbol and account with APP_ADMIN_ROLE.
     * @param name_ The name of the token.
     * @param symbol_ The symbol of the token.
     * @param admin_ The account to be granted with APP_ADMIN_ROLE.
     */
    function initialize(string calldata name_, string calldata symbol_, address admin_) external;

    /**
     * @notice Migrates the token points of users.
     * @dev The caller must have the APP_ADMIN_ROLE.
     * @param users The addresses of the users to migrate.
     * @param feedIds The feed ids of the feeds to migrate.
     */
    function migrate(address[] calldata users, bytes32[] calldata feedIds) external;

    /**
     * @notice Mints new token points.
     * @dev The caller must have the APP_ADMIN_ROLE.
     * @param to The account to receive the token points.
     * @param amount The amount of token points to mint.
     */
    function mint(address to, uint256 amount) external;

    /**
     * @notice Tips with token points. If token points are not enough, it will try the balance.
     * @param amount The amount of token points to send. It can be empty.
     * @param to The address to send the token points. It can be empty.
     * @param feedId The feed id. It can be empty.
     * @dev The to and feedId are optional, but at least one of them must be provided.
     * If both are provided, the `to` will be used.
     */
    function tip(uint256 amount, address to, bytes32 feedId) external;

    /**
     * @notice Withdraws tokens by feedId. `to` is supposed to be the true owner of the feedId.
     * @dev The caller must have the APP_ADMIN_ROLE.
     * @param to The address who receives the tokens.
     * @param feedId The amount belongs to the feedId.
     */
    function withdrawByFeedId(address to, bytes32 feedId) external;

    /**
     * @notice Withdraws tokens from a user's balance to a specified address.
     * @dev It checks if the user has enough balance to withdraw after accounting for non-transferable points.
     * @param to The address to which the tokens are to be transferred.
     * @param amount The amount of tokens to withdraw.
     */
    function withdraw(address to, uint256 amount) external;

    /**
     * @notice Return the balance of the feedId
     * @param feedId The feed id
     * @return The amount of the balance
     */
    function balanceOfByFeed(bytes32 feedId) external view returns (uint256);

    /**
     * @notice Return the balance of points, aka the inactive tokens, of the owner
     * @param owner The address of the owner
     * @return The amount of the balance
     */
    function balanceOfPoints(address owner) external view returns (uint256);
}
