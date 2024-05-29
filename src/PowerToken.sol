// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {ERC20Upgradeable} from "@openzeppelin-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {
    AccessControlEnumerable
} from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import {ContextUpgradeable} from "@openzeppelin-upgradeable/utils/ContextUpgradeable.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol"; // Add this line
import {IPowerToken} from "./interfaces/IPowerToken.sol";

contract PowerToken is ERC20Upgradeable, IPowerToken, AccessControlEnumerable {
    bytes32 public constant APP_ADMIN_ROLE = keccak256("APP_ADMIN_ROLE");

    mapping(bytes32 feedId => uint256) internal _pointsBalances;

    function initialize(
        string calldata name_,
        string calldata symbol_
    ) external override initializer {
        super.__ERC20_init(name_, symbol_);
        _grantRole(APP_ADMIN_ROLE, _msgSender());
    }

    function mint(address to) external override onlyRole(APP_ADMIN_ROLE) {}

    function tip(
        uint256 amount,
        address to,
        bytes32 feedId
    ) external override onlyRole(APP_ADMIN_ROLE) {}

    function withdraw(address to, bytes32 feedId) external override onlyRole(APP_ADMIN_ROLE) {}

    function balanceOfPoins(address owner) external view override returns (uint256) {}

    /* ContextUpgradeable */
    function _contextSuffixLength()
        internal
        view
        virtual
        override(Context, ContextUpgradeable)
        returns (uint256)
    {
        super._contextSuffixLength();
    }

    function _msgSender()
        internal
        view
        virtual
        override(Context, ContextUpgradeable)
        returns (address)
    {
        super._msgSender();
    }

    function _msgData()
        internal
        view
        virtual
        override(Context, ContextUpgradeable)
        returns (bytes calldata)
    {
        return super._msgData();
    }
}
