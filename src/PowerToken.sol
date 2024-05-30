// SPDX-License-Identifier: MIT
// solhint-disable no-empty-blocks
pragma solidity 0.8.22;

import {ERC20Upgradeable} from "@openzeppelin-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {
    AccessControlEnumerableUpgradeable
} from "@openzeppelin-upgradeable/access/extensions/AccessControlEnumerableUpgradeable.sol";
import {IPowerToken} from "./interfaces/IPowerToken.sol";

contract PowerToken is IPowerToken, AccessControlEnumerableUpgradeable, ERC20Upgradeable {
    bytes32 public constant APP_ADMIN_ROLE = keccak256("APP_ADMIN_ROLE");

    mapping(bytes32 feedId => uint256) internal _pointsBalances;

    /// @inheritdoc IPowerToken
    function initialize(
        string calldata name_,
        string calldata symbol_
    ) external override initializer {
        super.__ERC20_init(name_, symbol_);
        _grantRole(APP_ADMIN_ROLE, _msgSender());
    }

    /// @inheritdoc IPowerToken
    function mint(address to) external override onlyRole(APP_ADMIN_ROLE) {}

    /// @inheritdoc IPowerToken
    function tip(
        uint256 amount,
        address to,
        bytes32 feedId
    ) external override onlyRole(APP_ADMIN_ROLE) {}

    /// @inheritdoc IPowerToken
    function withdraw(address to, bytes32 feedId) external override onlyRole(APP_ADMIN_ROLE) {}

    /// @inheritdoc IPowerToken
    function balanceOfPoins(address owner) external view override returns (uint256) {}
}
