// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

interface IEntryPoint {
    /**
     * @notice Creates a new contract account.
     * @dev Only ADMIN_ROLE is allowed to call this method.
     * @param owner The account owner.
     */
    function createAccount(address owner) external returns (address);

    /**
     * @notice Creates a new contract account.
     * @param to The account to receive the tokens.
     */
    function claimTokens(address to) external;

    /**
     * @notice Creates a feed.
     * @dev Only ADMIN_ROLE is allowed to call this method.
     * @param feedId The feed id.
     * @param account The account who owns the feed.
     */
    function createFeed(bytes32 feedId, address account) external;

    /**
     * @notice Tips the recipient feed.
     * @param from The address who sends the tip.
     * @param amount The amount of the tip.
     * @param feedId The feed id.
     * @param entryId The entry id.
     */
    function tip(address from, uint256 amount, bytes32 feedId, uint256 entryId) external;

    /**
     * @notice Transfer tokens.
     * @param from The address who sends the tokens.
     * @param to The address who receives the tokens.
     * @param amount The amount of the tokens.
     */
    function transfer(address from, address to, uint256 amount) external;
}
