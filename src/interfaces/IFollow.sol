// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

interface IFollow {
    /**
     * @notice Initializes the contract.
     * @param name_ The token name.
     * @param symbol_ The token symbol.
     */
    function initialize(string calldata name_, string calldata symbol_) external;

    /**
     * @notice Mints new tokens.
     * @param to The account to receive the tokens.
     */
    function mint(address to) external;

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
