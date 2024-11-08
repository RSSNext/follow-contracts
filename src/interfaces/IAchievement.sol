// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {AchievementDetails} from "../../src/libraries/AchievementDataTypes.sol";

interface IAchievement {
    /**
     * @notice Initializes the contract. Setup token name, symbol and account with APP_ADMIN_ROLE.
     * @param name_ The name of the token.
     * @param symbol_ The symbol of the token.
     * @param admin_ The account to be granted with APP_ADMIN_ROLE.
     * @param powerToken_ The address of the power token.
     */
    function initialize(
        string calldata name_,
        string calldata symbol_,
        address admin_,
        address powerToken_
    ) external;

    /**
     * @notice Only the APP_ADMIN_ROLE can set the achievement details.
     * @param name Name of the achievement.
     * @param description Description of the achievement.
     * @param imageURL Image URL of the achievement.
     */
    function setAchievement(
        string calldata name,
        string calldata description,
        string calldata imageURL
    ) external;

    /**
     * @notice Mints a token to `account`.
     * @param achievement Name of the achievement to mint.
     * @return tokenId The new minted token id.
     */
    function mint(string calldata achievement) external returns (uint256 tokenId);

    /**
     * @notice Returns total supply of tokens.
     * @return Total supply of tokens.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Returns the achievement details of all achievements.
     * @return Achievement details.
     */
    function getAllAchievements() external view returns (AchievementDetails[] memory);

    /**
     * @notice Returns whether the account has the achievement.
     * @param account The address of the account.
     * @param achievementName The name of the achievement.
     * @return Whether the account has the achievement.
     */
    function hasAchievement(address account, string calldata achievementName)
        external
        view
        returns (bool);

    /**
     * @notice  Returns the address of the PowerToken contract.
     * @return Address of the PowerToken contract.
     */
    function powerToken() external view returns (address);
}
