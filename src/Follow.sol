// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {IFollow} from "./interfaces/IFollow.sol";
import {
    ERC20Upgradeable
} from "@openzeppelin-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";

contract Follow is IFollow, ERC20Upgradeable {
    /// @inheritdoc IFollow
    function initialize(string calldata name_, string calldata symbol_) external initializer {
        super.__ERC20_init(name_, symbol_);
    }

    /// @inheritdoc IFollow
    function mint(address to) external override {}

    /// @inheritdoc IFollow
    function tip(address from, uint256 amount, bytes32 feedId) external override {}

    /// @inheritdoc IFollow
    function withdraw(address to, uint256 amount) external override {}
}
