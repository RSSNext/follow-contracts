// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {IErrors} from "./interfaces/IErrors.sol";
import {IEvents} from "./interfaces/IEvents.sol";
import {IPowerToken} from "./interfaces/IPowerToken.sol";
import {AccessControlEnumerableUpgradeable} from
    "@openzeppelin-upgradeable/access/extensions/AccessControlEnumerableUpgradeable.sol";
import {ERC20Upgradeable} from "@openzeppelin-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

contract PowerToken is
    IPowerToken,
    IErrors,
    IEvents,
    AccessControlEnumerableUpgradeable,
    ERC20Upgradeable
{
    using Address for address;

    string public constant version = "1.1.0";

    bytes32 public constant APP_ADMIN_ROLE = keccak256("APP_ADMIN_ROLE");
    bytes32 public constant APP_USER_ROLE = keccak256("APP_USER_ROLE");

    uint256 public constant MAX_SUPPLY = 10_000_000_000 ether;

    address public immutable ADMIN; // Admin address who will receive the tax

    mapping(address account => uint256) internal _pointsBalancesV1;

    /// @dev Token balances of the feed, which could be withdrawn to the feed owner.
    mapping(bytes32 feedId => uint256) internal _feedBalances;

    /// @dev Points balances of the users, which are non-transferable and can be used to tip others.
    /// Points balances are included in user's balance.
    mapping(address account => uint256) internal _pointsBalancesV2;

    mapping(address account => mapping(uint256 day => bool hasMinted)) internal _dailyMinted;
    uint256 internal _dailyMintLimit;

    modifier onlyAdminRole() {
        _checkRole(APP_ADMIN_ROLE);
        _;
    }

    constructor(address admin_) {
        ADMIN = admin_;
    }

    /// @inheritdoc IPowerToken
    function initialize(
        string calldata name_,
        string calldata symbol_,
        address admin_,
        uint256 dailyMintLimit_
    ) external override reinitializer(4) {
        super.__ERC20_init(name_, symbol_);

        if (admin_ != address(0)) {
            _grantRole(DEFAULT_ADMIN_ROLE, admin_);
            _grantRole(APP_ADMIN_ROLE, admin_);
        }

        if (dailyMintLimit_ > 0) {
            _dailyMintLimit = dailyMintLimit_;
        }
    }

    /// @inheritdoc IPowerToken
    function setDailyMintLimit(uint256 limit) external override onlyAdminRole {
        _dailyMintLimit = limit;
    }

    /// @inheritdoc IPowerToken
    function mintToTreasury(address treasuryAdmin, uint256 amount)
        external
        override
        onlyAdminRole
    {
        if (amount + totalSupply() > MAX_SUPPLY) revert ExceedsMaxSupply();
        _mint(treasuryAdmin, amount);
    }

    /// @inheritdoc IPowerToken
    function mint(address to, uint256 amount, uint256 taxBasisPoints)
        external
        override
        onlyAdminRole
    {
        _issuePoints(to, amount, taxBasisPoints);
    }

    /// @inheritdoc IPowerToken
    function dailyMint(uint256 amount, uint256 taxBasisPoints)
        external
        override
        onlyRole(APP_USER_ROLE)
    {
        if (amount > _dailyMintLimit) revert ExceedsDailyLimit();

        uint256 currentDay = block.timestamp / 1 days;
        if (_hasMinted(msg.sender, currentDay)) revert AlreadyMintedToday(msg.sender);
        _setMinted(msg.sender, currentDay);

        _issuePoints(msg.sender, amount, taxBasisPoints);
    }

    /// @inheritdoc IPowerToken
    function airdrop(address to, uint256 amount, uint256 taxBasisPoints)
        external
        override
        onlyAdminRole
    {
        if (amount > balanceOf(address(this))) revert InsufficientBalanceToTransfer();

        uint256 tax = _getTaxAmount(taxBasisPoints, amount);

        uint256 airdropAmount = amount - tax;

        if (tax > 0) {
            _transfer(address(this), ADMIN, tax);
            emit TaxCollected(ADMIN, tax);
        }

        _transfer(address(this), to, airdropAmount);

        emit AirdropTokens(to, amount);
    }

    /// @inheritdoc IPowerToken
    function purchase(uint256 amount, address to, bytes32 feedId, uint256 taxBasisPoints)
        external
        override
    {
        uint256 purchaseAmount = _payWithTax(msg.sender, to, feedId, amount, taxBasisPoints);

        emit Purchase(msg.sender, to, feedId, purchaseAmount);
    }

    /// @inheritdoc IPowerToken
    function tip(uint256 amount, address to, bytes32 feedId, uint256 taxBasisPoints)
        external
        override
    {
        uint256 tipAmount = _payWithTax(msg.sender, to, feedId, amount, taxBasisPoints);

        emit Tip(msg.sender, to, feedId, tipAmount);
    }

    /// @inheritdoc IPowerToken
    function withdrawByFeedId(address to, bytes32 feedId) external override onlyAdminRole {
        if (feedId == bytes32(0)) revert PointsInvalidReceiver(bytes32(0));

        uint256 amount = _feedBalances[feedId];
        _feedBalances[feedId] = 0;
        _transfer(address(this), to, amount);

        emit WithdrawnByFeedId(to, feedId, amount);
    }

    /// @inheritdoc IPowerToken
    function addUser(address account) external payable override onlyAdminRole {
        _grantRole(APP_USER_ROLE, account);

        if (msg.value > 0) {
            Address.sendValue(payable(account), msg.value);
        }
    }

    /// @inheritdoc IPowerToken
    function addUsers(address[] calldata accounts) external payable override onlyAdminRole {
        uint256 len = accounts.length;
        for (uint256 i = 0; i < len; i++) {
            _grantRole(APP_USER_ROLE, accounts[i]);
        }

        if (msg.value > 0) {
            uint256 value = msg.value / len;
            for (uint256 i = 0; i < len; i++) {
                Address.sendValue(payable(accounts[i]), value);
            }
        }
    }

    /// @inheritdoc IPowerToken
    function removeUser(address account) external override onlyAdminRole {
        _revokeRole(APP_USER_ROLE, account);
    }

    /// @inheritdoc IPowerToken
    function balanceOfPoints(address owner) external view override returns (uint256) {
        return _pointsBalancesV2[owner];
    }

    /// @inheritdoc IPowerToken
    function balanceOfByFeed(bytes32 feedId) external view override returns (uint256) {
        return _feedBalances[feedId];
    }

    /// @inheritdoc IPowerToken
    function getDailyMintLimit() external view override returns (uint256) {
        return _dailyMintLimit;
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

    function _payWithTax(
        address from,
        address to,
        bytes32 feedId,
        uint256 amount,
        uint256 taxBasisPoints
    ) internal returns (uint256) {
        if (amount == 0) revert AmountIsZero();

        if (balanceOf(from) < amount) revert InsufficientBalanceAndPoints();

        if (feedId == bytes32(0) && to == address(0)) revert ReceiverIsEmpty();

        if (_pointsBalancesV2[from] >= amount) {
            _pointsBalancesV2[from] -= amount;
        } else {
            _pointsBalancesV2[from] = 0;
        }
        uint256 tax = _getTaxAmount(taxBasisPoints, amount);

        if (tax > 0) {
            _transfer(msg.sender, ADMIN, tax);
            emit TaxCollected(ADMIN, tax);
        }

        uint256 tipAmount = amount - tax;

        address receiver = to != address(0) ? to : address(this);
        if (receiver == address(this)) {
            _feedBalances[feedId] += tipAmount;
        }

        _transfer(msg.sender, receiver, tipAmount);

        return tipAmount;
    }

    /**
     * @dev Issues points to a specified address by transferring tokens from the token contract.
     */
    function _issuePoints(address to, uint256 amount, uint256 taxBasisPoints) internal {
        uint256 tax = _getTaxAmount(taxBasisPoints, amount);
        uint256 points = amount - tax;

        if (tax > 0) {
            _transfer(address(this), ADMIN, tax);
            emit TaxCollected(ADMIN, tax);
        }

        _pointsBalancesV2[to] += points;
        _transfer(address(this), to, points);

        emit DistributePoints(to, points);
    }

    function _setMinted(address account, uint256 day) internal {
        _dailyMinted[account][day] = true;
    }

    function _hasMinted(address account, uint256 day) internal view returns (bool) {
        return _dailyMinted[account][day];
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
