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

    uint256 public constant MAX_SUPPLY = 10000000000 ether;

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
        // migrate balances and points balances
        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];

            // mint 9 times of the balance to the user
            uint256 balance = balanceOf(user);
            _mint(user, balance * 9);

            // migrate v1 points balances to v2
            uint256 points = _pointsBalancesV1[user];
            _mintPoints(user, points * 10);
            // burn the v1 points balances from token contract
            _burn(address(this), points);

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
        _mintPoints(to, amount);
    }

    /// @inheritdoc IPowerToken
    function tip(uint256 amount, address to, bytes32 feedId) external override {
        if (amount == 0) revert TipAmountIsZero();
        if (feedId == bytes32(0) && to == address(0)) revert TipReceiverIsEmpty();
        if (balanceOf(msg.sender) < amount) revert InsufficientBalanceAndPoints();

        if (_pointsBalancesV2[msg.sender] >= amount) {
            _pointsBalancesV2[msg.sender] -= amount;
        } else {
            _pointsBalancesV2[msg.sender] = 0;
        }

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
    function balanceOfPoints(address owner) external view override returns (uint256) {
        return _pointsBalancesV2[owner];
    }

    /// @inheritdoc IPowerToken
    function balanceOfByFeed(bytes32 feedId) external view override returns (uint256) {
        return _feedBalances[feedId];
    }

    /// @inheritdoc IERC20
    function transfer(address to, uint256 value) public override returns (bool) {
        _checkTransferBalance(msg.sender, value);

        return super.transfer(to, value);
    }

    /// @inheritdoc IERC20
    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
        _checkTransferBalance(from, value);

        return super.transferFrom(from, to, value);
    }

    /**
     * @dev Mints points to a specified address.
     * Increases the points balance of the recipient and mints the corresponding amount of tokens.
     * Reverts if the total supply exceeds the maximum supply.
     */
    function _mintPoints(address to, uint256 amount) internal {
        if (totalSupply() + amount > MAX_SUPPLY) revert ExceedsMaxSupply();

        _pointsBalancesV2[to] += amount;
        _mint(to, amount);

        emit DistributePoints(to, amount);
    }

    /**
     * @dev Checks if the transfer balance is sufficient.
     * This function verifies that the `from` address has enough balance to cover the transfer amount
     * after accounting for the points balance.
     * @param from The address from which the tokens are being transferred.
     * @param value The amount of tokens to be transferred.
     */
    function _checkTransferBalance(address from, uint256 value) internal view {
        uint256 points = _pointsBalancesV2[from];
        uint256 balance = balanceOf(from);
        if (value > balance - points) revert InsufficientBalanceToTransfer();
    }
}
