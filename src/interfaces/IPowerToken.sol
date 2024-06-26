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
     * @notice Mints new token points.
     * @dev The caller must have the APP_ADMIN_ROLE.
     * @param to The account to receive the token points.
     * @param amount The amount of token points to mint.
     */
    function mint(address to, uint256 amount) external;

    /**
     * @notice Tips with token points. If token points are not enough, it will try the balance.
     * @param amount The amount of token points to send. It can be empty.
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
    function withdraw(address to, bytes32 feedId) external;

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
