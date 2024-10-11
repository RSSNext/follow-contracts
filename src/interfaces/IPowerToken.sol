// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

interface IPowerToken {
    /**
     * @notice Initializes the contract. Setup token name, symbol and account with APP_ADMIN_ROLE.
     * @param name_ The name of the token.
     * @param symbol_ The symbol of the token.
     * @param admin_ The account to be granted with APP_ADMIN_ROLE.
     * @param dailyMintLimit_ The token limit for daily mint.
     */
    function initialize(
        string calldata name_,
        string calldata symbol_,
        address admin_,
        uint256 dailyMintLimit_
    ) external;

    /**
     * @notice Sets the token limit for daily mint.
     * @dev The caller must have the APP_ADMIN_ROLE.
     * @param limit The new limit to set.
     */
    function setDailyMintLimit(uint256 limit) external;

    /**
     * @notice Mints tokens to the treasury.
     * @dev The caller must have the APP_ADMIN_ROLE.
     * @param treasuryAdmin The account to receive the tokens.
     * @param amount The amount of tokens to mint.
     */
    function mintToTreasury(address treasuryAdmin, uint256 amount) external;

    /**
     * @notice Issues new token points.
     * @dev The caller must have the APP_ADMIN_ROLE.
     * @param to The account to receive the token points.
     * @param amount The amount of token points to mint.
     * @param taxBasisPoints The tax basis points.
     */
    function mint(address to, uint256 amount, uint256 taxBasisPoints) external;

    /**
     * @notice Issues new token points to caller.
     * @dev The caller must have the APP_USER_ROLE.
     * @param amount The amount of token points to mint.
     * @param taxBasisPoints The tax basis points.
     */
    function dailyMint(uint256 amount, uint256 taxBasisPoints) external;

    /**
     * @notice Airdrops tokens to the users.
     * @dev The caller must have the APP_ADMIN_ROLE.
     * @param to The account to receive the tokens.
     * @param amount The amount of tokens to mint.
     * @param taxBasisPoints The tax basis points.
     */
    function airdrop(address to, uint256 amount, uint256 taxBasisPoints) external;

    /**
     * @notice Tips with token points. If token points are not enough, it will try the balance.
     * @param amount The amount of token points to send. It can be empty.
     * @param to The address to send the token points. It can be empty.
     * @param feedId The feed id. It can be empty.
     * @param taxBasisPoints The tax basis points.
     * @dev The to and feedId are optional, but at least one of them must be provided.
     * If both are provided, the `to` will be used.
     */
    function tip(uint256 amount, address to, bytes32 feedId, uint256 taxBasisPoints) external;

    /**
     * @notice Withdraws tokens by feedId. `to` is supposed to be the true owner of the feedId.
     * @dev The caller must have the APP_ADMIN_ROLE.
     * @param to The address who receives the tokens.
     * @param feedId The amount belongs to the feedId.
     */
    function withdrawByFeedId(address to, bytes32 feedId) external;

    /**
     * @notice Grants the APP_USER_ROLE to the specified account and mints token points to it.
     * @dev The caller must have the APP_ADMIN_ROLE.
     * @param account The address to grant the role and mint token points to.
     * @param amount The amount of token points to mint.
     * @param taxBasisPoints The basis points to calculate the tax from.
     */
    function addUser(address account, uint256 amount, uint256 taxBasisPoints) external;

    /**
     * @notice Revokes the APP_USER_ROLE from the specified account.
     * @dev The caller must have the APP_ADMIN_ROLE.
     * @param account The address from which to revoke the role.
     */
    function removeUser(address account) external;

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

    /**
     * @notice Returns the token limit for daily mint.
     * @return The token limit for daily mint.
     */
    function getDailyMintLimit() external view returns (uint256);
}
