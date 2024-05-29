// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

interface IFollow {
    /**
     * @notice Register a new account.
     * @dev Only ADMIN_ROLE is allowed to call this method.
     * @param userId The new user ID to register.
     */
    function register(bytes32 userId, address account) external returns (address);

    /**
     * @notice Mints new tokens.
     * @param to The account to receive the tokens.
     */
    function mint(address to) external;

    /**
     * @notice Creates a feed.
     * @dev Only ADMIN_ROLE is allowed to call this method.
     * @param feedId The feed id.
     * @param userId The user ID who owns the feed.
     */
    function createFeed(bytes32 feedId, bytes32 userId) external;

    /**
     * @notice Returns the feed owner.
     * @param feedId The feed id.
     * @return userId The user ID who owns the feed.
     */
    function getFeedOwner(bytes32 feedId) external view returns (bytes32 userId);

    /**
     * @notice Tips the recipient feed.
     * @param from The address who sends the tip.
     * @param amount The amount of the tip.
     * @param feedId The feed id.
     */
    function tip(address from, uint256 amount, bytes32 feedId) external;

    /**
     * @notice Withdraws tokens.
     * @param to The address who receives the tokens.
     * @param amount The amount of the tokens.
     */
    function withdraw(address to, uint256 amount) external;
}
