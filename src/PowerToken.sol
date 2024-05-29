// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {
    ERC20Upgradeable
} from "@openzeppelin-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";

contract PowerToken is ERC20Upgradeable {
    mapping(bytes32 feedId => uint256) internal _pointsBalances;

    /**
     * @notice Initializes the contract.
     * @param name_ The token name.
     * @param symbol_ The token symbol.
     */
    function initialize(string calldata name_, string calldata symbol_) external initializer {
        super.__ERC20_init(name_, symbol_);
    }

    /**
     * @notice Mints new token points.
     * @param to The account to receive the tokens.
     */
    function mint(address to) external {}

    /**
     * @notice Transfers token points.
     * @param amount The amount token points to send.
     * @param feedId The feed id.
     */
    function transferPoints(uint256 amount, bytes32 feedId) external {}

    /**
     * @notice Withdraws tokens.
     * @param to The address who receives the tokens.
     * @param amount The amount of the tokens.
     */
    function withdraw(address to, uint256 amount) external {}
}
