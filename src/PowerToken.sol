// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {ERC20Upgradeable} from "@openzeppelin-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {
    AccessControlEnumerableUpgradeable
} from "@openzeppelin-upgradeable/access/extensions/AccessControlEnumerableUpgradeable.sol";
import {IPowerToken} from "./interfaces/IPowerToken.sol";
import {IErrors} from "./interfaces/IErrors.sol";
import {IEvents} from "./interfaces/IEvents.sol";

contract PowerToken is
    IPowerToken,
    IErrors,
    IEvents,
    AccessControlEnumerableUpgradeable,
    ERC20Upgradeable
{
    string public constant version = "1.0.0";

    bytes32 public constant APP_ADMIN_ROLE = keccak256("APP_ADMIN_ROLE");

    /// @dev Points balances of the users, which are non-transferable and can be used to tip others.
    mapping(address account => uint256) internal _pointsBalances;

    /// @dev Token balances of the feed, which could be withdrawn to the feed owner.
    mapping(bytes32 feedId => uint256) internal _feedBalances;

    /// @inheritdoc IPowerToken
    function initialize(
        string calldata name_,
        string calldata symbol_,
        address admin_
    ) external override reinitializer(2) {
        super.__ERC20_init(name_, symbol_);

        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _grantRole(APP_ADMIN_ROLE, admin_);
    }

    /// @inheritdoc IPowerToken
    function mint(address to, uint256 amount) external override onlyRole(APP_ADMIN_ROLE) {
        _pointsBalances[to] += amount;
        _mint(address(this), amount);

        emit DistributePoints(to, amount);
    }

    /// @inheritdoc IPowerToken
    function tip(uint256 amount, address to, bytes32 feedId) external override {
        if (amount == 0) revert TipAmountIsZero();

        if (feedId == bytes32(0) && to == address(0)) revert TipReceiverIsEmpty();

        uint256 oldPoints = _pointsBalances[msg.sender];
        uint256 newPoints;

        uint256 amountToTransfer;

        if (oldPoints >= amount) {
            newPoints = oldPoints - amount;
            amountToTransfer = 0;
        } else if (oldPoints + balanceOf(msg.sender) >= amount) {
            newPoints = 0;
            amountToTransfer = amount - oldPoints;
        } else {
            revert InsufficientBalanceAndPoints();
        }

        _pointsBalances[msg.sender] = newPoints;

        address receiver;
        if (to != address(0)) {
            receiver = to;
            _transfer(address(this), to, amount - amountToTransfer);
        } else {
            receiver = address(this);
            _feedBalances[feedId] += amount;
        }

        if (amountToTransfer > 0) {
            _transfer(msg.sender, receiver, amountToTransfer);
        }

        emit Tip(msg.sender, to, feedId, amount);
    }

    /// @inheritdoc IPowerToken
    function withdraw(address to, bytes32 feedId) external override onlyRole(APP_ADMIN_ROLE) {
        if (feedId == bytes32(0)) revert PointsInvalidReceiver(bytes32(0));

        uint256 amount = _feedBalances[feedId];
        _feedBalances[feedId] = 0;
        _transfer(address(this), to, amount);

        emit Withdraw(to, feedId, amount);
    }

    /// @inheritdoc IPowerToken
    function balanceOfPoints(address owner) external view override returns (uint256) {
        return _pointsBalances[owner];
    }

    /// @inheritdoc IPowerToken
    function balanceOfByFeed(bytes32 feedId) external view override returns (uint256) {
        return _feedBalances[feedId];
    }
}
