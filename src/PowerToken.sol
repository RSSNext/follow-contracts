// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {IErrors} from "./interfaces/IErrors.sol";
import {IEvents} from "./interfaces/IEvents.sol";
import {IPowerToken} from "./interfaces/IPowerToken.sol";
import {AccessControlEnumerableUpgradeable} from
    "@openzeppelin-upgradeable/access/extensions/AccessControlEnumerableUpgradeable.sol";
import {ERC20Upgradeable} from "@openzeppelin-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PowerToken is
    IPowerToken,
    IErrors,
    IEvents,
    AccessControlEnumerableUpgradeable,
    ERC20Upgradeable
{
    string public constant version = "1.1.0";

    bytes32 public constant APP_ADMIN_ROLE = keccak256("APP_ADMIN_ROLE");

    uint256 public constant MAX_SUPPLY = 10_000_000_000 ether;

    mapping(address account => uint256) internal _pointsBalancesV1;

    /// @dev Token balances of the feed, which could be withdrawn to the feed owner.
    mapping(bytes32 feedId => uint256) internal _feedBalances;

    /// @dev Points balances of the users, which are non-transferable and can be used to tip others.
    /// Points balances are included in user's balance.
    mapping(address account => uint256) internal _pointsBalancesV2;

    address public admin; // Admin address who will receive the tax

    /// @inheritdoc IPowerToken
    function initialize(string calldata name_, string calldata symbol_, address admin_)
        external
        override
        reinitializer(4)
    {
        super.__ERC20_init(name_, symbol_);

        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _grantRole(APP_ADMIN_ROLE, admin_);

        admin = admin_;
    }

    /// @inheritdoc IPowerToken
    function mintToTreasury(address treasuryAdmin, uint256 amount)
        external
        override
        onlyRole(APP_ADMIN_ROLE)
    {
        if (amount + totalSupply() > MAX_SUPPLY) revert ExceedsMaxSupply();
        _mint(treasuryAdmin, amount);
    }

    /// @inheritdoc IPowerToken
    function mint(address to, uint256 amount, uint256 taxBasisPoints)
        external
        override
        onlyRole(APP_ADMIN_ROLE)
    {
        if (amount > balanceOf(address(this))) revert InsufficientBalanceToTransfer();

        uint256 tax = _getTaxAmount(taxBasisPoints, amount);

        _transfer(address(this), admin, tax);

        _issuePoints(to, amount - tax);
    }

    function airdrop(address to, uint256 amount, uint256 taxBasisPoints)
        external
        override
        onlyRole(APP_ADMIN_ROLE)
    {
        if (amount > balanceOf(address(this))) revert InsufficientBalanceToTransfer();

        uint256 tax = _getTaxAmount(taxBasisPoints, amount);

        _transfer(address(this), admin, tax);

        _transfer(address(this), to, amount - tax);

        emit AirdropTokens(to, amount);
    }

    /// @inheritdoc IPowerToken
    function tip(uint256 amount, address to, bytes32 feedId, uint256 taxBasisPoints)
        external
        override
    {
        if (amount == 0) revert TipAmountIsZero();
        if (feedId == bytes32(0) && to == address(0)) revert TipReceiverIsEmpty();
        if (balanceOf(msg.sender) < amount) revert InsufficientBalanceAndPoints();

        if (_pointsBalancesV2[msg.sender] >= amount) {
            _pointsBalancesV2[msg.sender] -= amount;
        } else {
            _pointsBalancesV2[msg.sender] = 0;
        }
        uint256 tax = _getTaxAmount(taxBasisPoints, amount);

        uint256 tipAmount = amount - tax;

        address receiver = to != address(0) ? to : address(this);
        if (receiver == address(this)) {
            _feedBalances[feedId] += tipAmount;
        }

        _transfer(msg.sender, admin, tax);

        _transfer(msg.sender, receiver, tipAmount);

        emit Tip(msg.sender, to, feedId, tipAmount);
    }

    /// @inheritdoc IPowerToken
    function withdrawByFeedId(address to, bytes32 feedId)
        external
        override
        onlyRole(APP_ADMIN_ROLE)
    {
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
     * @dev Issues points to a specified address by transferring tokens from the token contract.
     */
    function _issuePoints(address to, uint256 amount) internal {
        _pointsBalancesV2[to] += amount;

        _transfer(address(this), to, amount);

        emit DistributePoints(to, amount);
    }

    /**
     * @dev Checks if the transfer balance is sufficient.
     * This function verifies that the `from` address has enough balance to cover the transfer
     * amount
     * after accounting for the points balance.
     * @param from The address from which the tokens are being transferred.
     * @param value The amount of tokens to be transferred.
     */
    function _checkTransferBalance(address from, uint256 value) internal view {
        uint256 points = _pointsBalancesV2[from];
        uint256 balance = balanceOf(from);
        if (value > balance - points) revert InsufficientBalanceToTransfer();
    }

    function _getTaxAmount(uint256 taxBasisPoints, uint256 amount)
        internal
        pure
        returns (uint256)
    {
        return (taxBasisPoints * amount) / 10_000;
    }
}
