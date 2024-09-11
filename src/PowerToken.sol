// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {ERC20Upgradeable} from "@openzeppelin-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {
    AccessControlEnumerableUpgradeable
} from "@openzeppelin-upgradeable/access/extensions/AccessControlEnumerableUpgradeable.sol";
import {IPowerToken} from "./interfaces/IPowerToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
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

    uint256 public constant MAX_SUPPLY = 1000000000 ether;

    mapping(address account => uint256) internal _pointsBalancesV1;

    /// @dev Token balances of the feed, which could be withdrawn to the feed owner.
    mapping(bytes32 feedId => uint256) internal _feedBalances;

    /// @dev Points balances of the users, which are non-transferable and can be used to tip others.
    /// Points balances are included in user's balance.
    mapping(address account => uint256) internal _pointsBalancesV2;

    /// @inheritdoc IPowerToken
    function initialize(
        string calldata name_,
        string calldata symbol_,
        address admin_
    ) external override reinitializer(3) {
        super.__ERC20_init(name_, symbol_);

        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _grantRole(APP_ADMIN_ROLE, admin_);
    }

    /// @inheritdoc IPowerToken
    function migrate(
        address[] calldata users,
        bytes32[] calldata feedIds
    ) external override onlyRole(APP_ADMIN_ROLE) {
        // migrate points balances
        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            uint256 points = _pointsBalancesV1[user] * 10;

            _pointsBalancesV2[user] += points;
            _mint(user, points);
            emit DistributePoints(user, points);

            delete _pointsBalancesV1[user];
        }

        // migrate feed balances
        for (uint256 i = 0; i < feedIds.length; i++) {
            bytes32 feedId = feedIds[i];

            _mint(address(this), _feedBalances[feedId] * 9);
            _feedBalances[feedId] *= 10;
        }
    }

    /// @inheritdoc IPowerToken
    function mint(address to, uint256 amount) external override onlyRole(APP_ADMIN_ROLE) {
        _pointsBalancesV2[to] += amount;
        _mint(to, amount);
        if (totalSupply() > MAX_SUPPLY) revert ExceedsMaxSupply();

        emit DistributePoints(to, amount);
    }

    /// @inheritdoc IPowerToken
    function tip(uint256 amount, address to, bytes32 feedId) external override {
        if (amount == 0) revert TipAmountIsZero();
        if (feedId == bytes32(0) && to == address(0)) revert TipReceiverIsEmpty();

        uint256 oldPoints = _pointsBalancesV2[msg.sender];
        uint256 newPoints;
        if (oldPoints >= amount) {
            newPoints = oldPoints - amount;
        } else if (balanceOf(msg.sender) >= amount) {
            newPoints = 0;
        } else {
            revert InsufficientBalanceAndPoints();
        }
        _pointsBalancesV2[msg.sender] = newPoints;

        address receiver = to != address(0) ? to : address(this);
        if (receiver == address(this)) {
            _feedBalances[feedId] += amount;
        }
        _transfer(msg.sender, receiver, amount);

        emit Tip(msg.sender, to, feedId, amount);
    }

    /// @inheritdoc IPowerToken
    function withdrawByFeedId(
        address to,
        bytes32 feedId
    ) external override onlyRole(APP_ADMIN_ROLE) {
        if (feedId == bytes32(0)) revert PointsInvalidReceiver(bytes32(0));

        uint256 amount = _feedBalances[feedId];
        _feedBalances[feedId] = 0;
        _transfer(address(this), to, amount);

        emit WithdrawnByFeedId(to, feedId, amount);
    }

    /// @inheritdoc IPowerToken
    function withdraw(address to, uint256 amount) external override {
        transfer(to, amount);

        emit Withdrawn(msg.sender, to, amount);
    }

    /// @inheritdoc IPowerToken
    function balanceOfPoints(address owner) external view override returns (uint256) {
        return _pointsBalancesV2[owner];
    }

    /// @inheritdoc IPowerToken
    function balanceOfByFeed(bytes32 feedId) external view override returns (uint256) {
        return _feedBalances[feedId];
    }

    /// @inheritdoc IERC20
    function transfer(address to, uint256 value) public override returns (bool) {
        uint256 points = _pointsBalancesV2[msg.sender];
        uint256 balance = balanceOf(msg.sender);
        if (value > balance - points) revert InsufficientBalanceToWithdraw();

        return super.transfer(to, value);
    }
}
