// SPDX-License-Identifier: MIT
// solhint-disable comprehensive-interface,no-console,no-empty-blocks,function-max-lines
pragma solidity 0.8.22;

import {DeployConfig} from "../script/DeployConfig.s.sol";
import {PowerToken} from "../src/PowerToken.sol";
import {IErrors} from "../src/interfaces/IErrors.sol";
import {IEvents} from "../src/interfaces/IEvents.sol";
import {IPowerToken} from "../src/interfaces/IPowerToken.sol";
import {TransparentUpgradeableProxy} from "../src/upgradeability/TransparentUpgradeableProxy.sol";
import {Utils} from "./helpers/Utils.sol";
import {ERC20Upgradeable} from "@openzeppelin-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract PowerTokenTest is Utils, IErrors, IEvents, ERC20Upgradeable {
    bytes32 public constant APP_ADMIN_ROLE = keccak256("APP_ADMIN_ROLE");
    bytes32 public constant APP_USER_ROLE = keccak256("APP_USER_ROLE");

    address public constant alice = address(0x123);
    address public constant bob = address(0x456);
    address public constant charlie = address(0x789);
    address public constant david = address(0xabc);
    bytes32 public constant someFeedId1 = bytes32("someFeedId1");
    bytes32 public constant someFeedId2 = bytes32("someFeedId2");
    bytes32 public constant someFeedId3 = bytes32("someFeedId3");

    DeployConfig internal _cfg;
    address public appAdmin;

    PowerToken internal _token;

    error AccessControlUnauthorizedAccount(address account, bytes32 neededRole);

    function setUp() public {
        // read config from local.json
        string memory path = string.concat(vm.projectRoot(), "/deploy-config/", "local" ".json");
        _cfg = new DeployConfig(path);
        appAdmin = _cfg.appAdmin();

        PowerToken tokenImpl = new PowerToken();

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(tokenImpl),
            _cfg.proxyAdminOwner(),
            abi.encodeWithSelector(
                IPowerToken.initialize.selector,
                _cfg.name(),
                _cfg.symbol(),
                _cfg.appAdmin(),
                _cfg.dailyMintLimit()
            )
        );

        _token = PowerToken(address(proxy));
    }

    function testMintToTreasury(uint256 amount) public {
        amount = bound(amount, 1, _token.MAX_SUPPLY());

        expectEmit();
        emit Transfer(address(0x0), appAdmin, amount);
        vm.prank(appAdmin);
        _token.mintToTreasury(appAdmin, amount);

        // check balance and points
        assertEq(_token.balanceOf(appAdmin), amount);
        assertEq(_token.balanceOfPoints(appAdmin), 0);
    }

    function testMintToTreasuryFail() public {
        // case 1: caller has no `APP_ADMIN_ROLE` permission
        vm.expectRevert(
            abi.encodeWithSelector(
                AccessControlUnauthorizedAccount.selector,
                address(this),
                keccak256("APP_ADMIN_ROLE")
            )
        );
        _token.mintToTreasury(alice, 1);

        // case 2: max supply is reached
        uint256 maxSupply = _token.MAX_SUPPLY();
        vm.expectRevert(abi.encodeWithSelector(ExceedsMaxSupply.selector));
        vm.prank(appAdmin);
        _token.mintToTreasury(alice, maxSupply + 1);
    }

    function testMintPointsSucceed(uint256 amount, uint256 taxBasisPoints) public {
        amount = bound(amount, 1, 10_000);
        amount *= 1 ether;
        taxBasisPoints = bound(taxBasisPoints, 1, 10_000);

        uint256 expectedTax = (taxBasisPoints * amount) / 10_000;

        vm.prank(appAdmin);
        _token.mintToTreasury(address(_token), amount);

        expectEmit();
        emit DistributePoints(alice, amount - expectedTax);
        vm.prank(appAdmin);
        _token.mint(alice, amount, taxBasisPoints);

        assertEq(_token.balanceOf(alice), amount - expectedTax);
        assertEq(_token.balanceOfPoints(alice), amount - expectedTax);

        assertEq(_token.balanceOf(appAdmin), expectedTax);
    }

    function testMintPointsFail() public {
        // case 1: caller has no `APP_ADMIN_ROLE` permission
        vm.expectRevert(
            abi.encodeWithSelector(
                AccessControlUnauthorizedAccount.selector,
                address(this),
                keccak256("APP_ADMIN_ROLE")
            )
        );
        _token.mint(alice, 1, 0);

        uint256 amount = 1000 ether;
        vm.prank(appAdmin);
        _token.mintToTreasury(address(_token), amount);

        // case 2: balance is insufficient
        vm.expectRevert(
            abi.encodeWithSelector(
                ERC20InsufficientBalance.selector, address(_token), amount, amount + 1
            )
        );
        vm.prank(appAdmin);
        _token.mint(alice, amount + 1, 0);
    }

    function testDailyMintPoints(uint256 amount) public {
        amount = bound(amount, 1, 1000);
        amount *= 1 ether;

        vm.prank(appAdmin);
        _token.mintToTreasury(address(_token), amount * 2);

        _addUser(alice);

        expectEmit();
        emit DistributePoints(alice, amount);
        vm.prank(alice);
        _token.dailyMint(amount, 0);

        assertEq(_token.balanceOf(alice), amount);
        assertEq(_token.balanceOfPoints(alice), amount);

        assertEq(_token.balanceOf(address(this)), 0);

        // mint after a day
        skip(1 days);
        vm.prank(alice);
        _token.dailyMint(amount, 0);
        assertEq(_token.balanceOf(alice), amount * 2);
        assertEq(_token.balanceOfPoints(alice), amount * 2);
    }

    function testDailyMintPointsFail() public {
        // case 1: caller has no `APP_USER_ROLE` permission
        vm.expectRevert(
            abi.encodeWithSelector(
                AccessControlUnauthorizedAccount.selector,
                address(alice),
                keccak256("APP_USER_ROLE")
            )
        );
        vm.prank(alice);
        _token.dailyMint(1, 0);

        uint256 amount = 10_000 ether;
        vm.prank(appAdmin);
        _token.mintToTreasury(address(_token), amount);

        // case 2: balance is insufficient
        _addUser(alice);
        vm.expectRevert(
            abi.encodeWithSelector(
                ERC20InsufficientBalance.selector, address(_token), amount, amount + 1
            )
        );
        vm.prank(alice);
        _token.dailyMint(amount + 1, 0);

        // case 3: ExceedsDailyLimit
        _addUser(alice);
        amount = _token.getDailyMintLimit() + 1;
        vm.expectRevert(abi.encodeWithSelector(ExceedsDailyLimit.selector));
        vm.prank(alice);
        _token.dailyMint(amount, 0);

        // case 4: AlreadyMintedToday
        vm.prank(alice);
        _token.dailyMint(100 ether, 0);
        skip(10 hours);
        vm.expectRevert(abi.encodeWithSelector(AlreadyMintedToday.selector, alice));
        vm.prank(alice);
        _token.dailyMint(100 ether, 0);
    }

    function testDailyMintWithTax(uint256 taxBasisPoints) public {
        uint256 amount = 1000 ether;
        taxBasisPoints = bound(taxBasisPoints, 1, 10_000);

        uint256 tax = (amount * taxBasisPoints) / 10_000;

        vm.prank(appAdmin);
        _token.mintToTreasury(address(_token), amount);

        _addUser(alice);

        expectEmit();
        emit Transfer(address(_token), appAdmin, tax);
        emit Transfer(address(_token), alice, amount - tax);
        emit DistributePoints(alice, amount - tax);
        vm.prank(alice);
        _token.dailyMint(amount, taxBasisPoints);
    }

    function testAddUserSucceed() public {
        uint256 amount = 1000 ether;
        vm.deal(appAdmin, amount);

        vm.prank(appAdmin);
        _token.addUser{value: amount}(alice);

        assertEq(_token.hasRole(APP_USER_ROLE, alice), true);
        assertEq(alice.balance, amount);
    }

    function testAddUserFail() public {
        // case 1: caller has no `APP_ADMIN_ROLE` permission
        vm.expectRevert(
            abi.encodeWithSelector(
                AccessControlUnauthorizedAccount.selector,
                address(this),
                keccak256("APP_ADMIN_ROLE")
            )
        );
        _token.addUser(alice);
    }

    function testAddUsers() public {
        address[] memory users = new address[](3);
        users[0] = alice;
        users[1] = bob;
        users[2] = charlie;

        vm.prank(appAdmin);
        _token.addUsers(users);

        assertEq(_token.hasRole(APP_USER_ROLE, alice), true);
        assertEq(_token.hasRole(APP_USER_ROLE, bob), true);
        assertEq(_token.hasRole(APP_USER_ROLE, charlie), true);
    }

    function testAddUsersFail() public {
        // case 1: caller has no `APP_ADMIN_ROLE` permission
        address[] memory users = new address[](1);
        users[0] = alice;

        vm.expectRevert(
            abi.encodeWithSelector(
                AccessControlUnauthorizedAccount.selector,
                address(this),
                keccak256("APP_ADMIN_ROLE")
            )
        );
        _token.addUsers(users);
    }

    function testRemoveUser() public {
        vm.startPrank(appAdmin);
        _token.addUser(alice);
        _token.removeUser(alice);
        vm.stopPrank();

        assertEq(_token.hasRole(APP_USER_ROLE, alice), false);
    }

    function testRemoveUserFail() public {
        // case 1: caller has no `APP_ADMIN_ROLE` permission
        vm.expectRevert(
            abi.encodeWithSelector(
                AccessControlUnauthorizedAccount.selector,
                address(this),
                keccak256("APP_ADMIN_ROLE")
            )
        );
        _token.removeUser(alice);
    }

    function testAirdrop(uint256 taxBasisPoints) public {
        uint256 amount = 1000 ether;
        taxBasisPoints = bound(taxBasisPoints, 1, 10_000);

        uint256 tax = (amount * taxBasisPoints) / 10_000;

        vm.prank(appAdmin);
        _token.mintToTreasury(address(_token), amount);

        expectEmit();
        emit Transfer(address(_token), appAdmin, tax);
        emit Transfer(address(_token), alice, amount - tax);
        emit AirdropTokens(alice, amount - tax);
        vm.prank(appAdmin);
        _token.airdrop(alice, amount, taxBasisPoints);
    }

    function testTipFeedIdSucceed(uint256 amount) public {
        amount = bound(amount, 1, 1000 ether);
        uint256 initialPoints = 10 * amount;

        _mintPoints(alice, initialPoints);

        expectEmit();
        emit Tip(alice, address(0x0), someFeedId1, 10);
        vm.prank(alice);
        _token.tip(10, address(0x0), someFeedId1, 0);

        assertEq(_token.balanceOf(alice), initialPoints - 10);
        assertEq(_token.balanceOfPoints(alice), initialPoints - 10);
        assertEq(_token.balanceOfByFeed(someFeedId1), 10);
    }

    function testTipFeedIdMultiple() public {
        _mintPoints(alice, 100);
        _mintPoints(bob, 100);

        uint256 tokenInitalBalance = _token.balanceOf(address(_token));

        uint256 balance = _token.balanceOf(charlie);
        assertEq(balance, 0);

        vm.startPrank(alice);
        _token.tip(10, address(0x0), someFeedId1, 0);
        _token.tip(20, address(0x0), someFeedId2, 0);
        _token.tip(30, address(0x0), someFeedId3, 0);
        vm.stopPrank();

        vm.startPrank(bob);
        _token.tip(15, address(0x0), someFeedId1, 0);
        _token.tip(25, address(0x0), someFeedId2, 0);
        _token.tip(35, address(0x0), someFeedId3, 0);
        vm.stopPrank();

        uint256 feedBalance1 = _token.balanceOfByFeed(someFeedId1);
        uint256 feedBalance2 = _token.balanceOfByFeed(someFeedId2);
        uint256 feedBalance3 = _token.balanceOfByFeed(someFeedId3);
        assertEq(feedBalance1, 10 + 15);
        assertEq(feedBalance2, 20 + 25);
        assertEq(feedBalance3, 30 + 35);

        assertEq(_token.balanceOf(address(_token)), tokenInitalBalance + 135);
    }

    function testTipAddress(uint256 amount) public {
        uint256 initialPoints = 1000 ether;
        amount = bound(amount, 10, initialPoints - 1);

        _mintPoints(alice, initialPoints);

        // Alice tips bob (only points)
        vm.expectEmit();
        emit Transfer(alice, bob, amount);
        emit Tip(alice, bob, "", amount);
        vm.prank(alice);
        _token.tip(amount, bob, "", 0);

        _checkBalanceAndPoints(alice, initialPoints - amount, initialPoints - amount);
        _checkBalanceAndPoints(bob, amount, 0);

        // Bob is minted with some points. Then bob tips charlie (points + balance)
        uint256 bobInitialPoints = amount / 2;
        _mintPoints(bob, bobInitialPoints);

        _checkBalanceAndPoints(bob, amount + bobInitialPoints, bobInitialPoints);

        vm.expectEmit();
        emit Transfer(bob, charlie, amount + 1);
        emit Tip(bob, charlie, "", amount + 1);
        vm.prank(bob);
        _token.tip(amount + 1, charlie, "", 0);

        uint256 expectedBobTokenBalance = bobInitialPoints - 1;

        // points is prioritized to be used over balance
        _checkBalanceAndPoints(bob, expectedBobTokenBalance, 0);

        // Bob tips alice only with tokens
        vm.expectEmit();
        emit Transfer(bob, alice, expectedBobTokenBalance);
        emit Tip(bob, alice, "", expectedBobTokenBalance);
        vm.prank(bob);
        _token.tip(expectedBobTokenBalance, alice, "", 0);
    }

    function testTipAddressWithPointsAndBalance(uint256 amount) public {
        amount = bound(amount, 10, 1000 ether);

        _mintPoints(alice, amount);
        _mintPoints(bob, amount);

        vm.prank(alice);
        _token.tip(amount, bob, "", 0);

        _checkBalanceAndPoints(alice, 0, 0);
        _checkBalanceAndPoints(bob, amount * 2, amount);

        uint256 tipAmount = amount + amount / 2;
        vm.prank(bob);
        _token.tip(tipAmount, alice, "", 0);

        _checkBalanceAndPoints(alice, tipAmount, 0);
        _checkBalanceAndPoints(bob, amount * 2 - tipAmount, 0);
    }

    function testTipWithTax(uint256 taxBasisPoints) public {
        // 1. tip address with tax
        uint256 amount = 1000 ether;
        uint256 initialPoints = 10 * amount;
        taxBasisPoints = bound(taxBasisPoints, 1, 10_000);

        _mintPoints(alice, initialPoints);

        uint256 tax = (amount * taxBasisPoints) / 10_000;
        uint256 tipAmount = amount - tax;

        vm.expectEmit();
        emit Transfer(alice, appAdmin, tax);
        emit Transfer(alice, bob, tipAmount);
        emit Tip(alice, bob, "", tipAmount);
        vm.prank(alice);
        _token.tip(amount, bob, "", taxBasisPoints);

        // 2. tip feedId with tax
        vm.expectEmit();
        emit Transfer(alice, appAdmin, tax);
        emit Transfer(alice, address(this), tipAmount);
        emit Tip(alice, address(0x0), someFeedId1, tipAmount);

        vm.prank(alice);
        _token.tip(amount, address(0x0), someFeedId1, taxBasisPoints);

        _checkBalanceAndPoints(bob, tipAmount, 0);
    }

    function testTipFail() public {
        // case 1:  TipAmountIsZero
        vm.expectRevert(abi.encodeWithSelector(TipAmountIsZero.selector));
        _token.tip(0, bob, "", 0);

        // case 2: TipReceiverIsEmpty
        vm.expectRevert(abi.encodeWithSelector(TipReceiverIsEmpty.selector));
        _token.tip(1, address(0x0), "", 0);

        // case 3: InsufficientBalanceAndPoints
        vm.expectRevert(abi.encodeWithSelector(InsufficientBalanceAndPoints.selector));
        _token.tip(1, bob, "", 0);

        // case 4: InsufficientBalanceToTransfer
        _mintPoints(charlie, 100);
        _mintPoints(david, 100);

        vm.prank(charlie);
        _token.tip(50, david, "", 0);

        vm.expectRevert(abi.encodeWithSelector(InsufficientBalanceAndPoints.selector));
        vm.prank(david);
        _token.tip(200, david, "", 0);
    }

    function testWithdrawByFeedId(uint256 amount) public {
        amount = bound(amount, 1, 100 ether);
        uint256 initialPoints = 10 * amount;

        _mintPoints(alice, initialPoints);

        vm.prank(alice);
        _token.tip(amount, address(0x0), someFeedId1, 0);

        expectEmit();
        emit WithdrawnByFeedId(charlie, someFeedId1, amount);
        vm.prank(appAdmin);
        _token.withdrawByFeedId(charlie, someFeedId1);

        _checkBalanceAndPoints(alice, initialPoints - amount, initialPoints - amount);
        _checkBalanceAndPoints(charlie, amount, 0);
    }

    function testWithdrawByFeedIdFail() public {
        // case 1: PointsInvalidReceiver
        vm.prank(appAdmin);
        vm.expectRevert(abi.encodeWithSelector(PointsInvalidReceiver.selector, bytes32(0)));
        _token.withdrawByFeedId(charlie, "");
    }

    function testWithdraw(uint256 amount) public {
        amount = bound(amount, 1, 100 ether);
        uint256 tipAmount = bound(amount, 1, amount);

        _mintPoints(alice, amount);
        _mintPoints(bob, amount);

        vm.prank(alice);
        _token.tip(tipAmount, bob, "", 0);

        uint256 withdrawAmount = bound(amount, 1, tipAmount);
        address receiver = address(0xaaaa);

        vm.expectEmit();
        emit Transfer(bob, receiver, withdrawAmount);
        vm.prank(bob);
        _token.transfer(receiver, withdrawAmount);

        _checkBalanceAndPoints(alice, amount - tipAmount, amount - tipAmount);
        _checkBalanceAndPoints(bob, amount + tipAmount - withdrawAmount, amount);
        _checkBalanceAndPoints(receiver, withdrawAmount, 0);
    }

    function testWithdrawFail(uint256 amount) public {
        amount = bound(amount, 1, 100 ether);
        uint256 tipAmount = bound(amount, 1, amount);

        _mintPoints(alice, amount);
        _mintPoints(bob, amount);

        // case 1: InsufficientBalanceToTransfer
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(InsufficientBalanceToTransfer.selector));
        _token.transfer(bob, 1);

        // case 2: InsufficientBalanceToTransfer
        vm.prank(alice);
        _token.tip(tipAmount, bob, "", 0);

        vm.expectRevert(abi.encodeWithSelector(InsufficientBalanceToTransfer.selector));
        _token.transfer(bob, tipAmount + 1);
    }

    function testSetDailyMintLimit(uint256 limit) public {
        limit = bound(limit, 1, 100_000);
        limit *= 1 ether;

        vm.prank(appAdmin);
        _token.setDailyMintLimit(limit);

        assertEq(_token.getDailyMintLimit(), limit);
    }

    function testSetDailyMintLimitFail() public {
        // case 1: caller has no `APP_ADMIN_ROLE` permission
        vm.expectRevert(
            abi.encodeWithSelector(
                AccessControlUnauthorizedAccount.selector,
                address(this),
                keccak256("APP_ADMIN_ROLE")
            )
        );
        _token.setDailyMintLimit(100 ether);
    }

    function testTransfer(uint256 amount) public {
        amount = bound(amount, 1, 100 ether);
        uint256 tipAmount = bound(amount, 1, amount);

        _mintPoints(alice, amount);
        _mintPoints(bob, amount);

        vm.prank(alice);
        _token.tip(tipAmount, bob, "", 0);

        uint256 transferAmount = bound(amount, 1, tipAmount);
        address receiver = address(0xaaaa);

        vm.expectEmit();
        emit Transfer(bob, receiver, transferAmount);
        vm.prank(bob);
        _token.transfer(receiver, transferAmount);
    }

    function testTransferFail(uint256 amount) public {
        amount = bound(amount, 1, 100 ether);

        _mintPoints(alice, amount);

        // can't transfer points
        vm.expectRevert(abi.encodeWithSelector(InsufficientBalanceToTransfer.selector));
        vm.prank(alice);
        _token.transfer(bob, 1);
    }

    function testTransferFrom(uint256 amount) public {
        amount = bound(amount, 1, 100 ether);
        uint256 tipAmount = bound(amount, 1, amount);

        _mintPoints(alice, amount);
        _mintPoints(bob, amount);

        vm.prank(alice);
        _token.tip(tipAmount, bob, "", 0);

        uint256 transferAmount = bound(amount, 1, tipAmount);
        address receiver = address(0xaaaa);

        // bob approve charlie to transfer bob's tokens
        vm.prank(bob);
        _token.approve(charlie, transferAmount);

        // charlie transfer bob's tokens to receiver
        vm.expectEmit();
        emit Transfer(bob, receiver, transferAmount);
        vm.prank(charlie);
        _token.transferFrom(bob, receiver, transferAmount);
    }

    function testTransferFromFail(uint256 amount) public {
        // case 1: InsufficientBalanceToTransfer
        amount = bound(amount, 1, 100 ether);
        uint256 tipAmount = bound(amount, 1, amount);

        _mintPoints(alice, amount);
        // alice tip bob
        vm.prank(alice);
        _token.tip(tipAmount, bob, "", 0);

        // mint points to bob
        _mintPoints(bob, amount);

        _checkBalanceAndPoints(bob, amount + tipAmount, amount);

        uint256 transferAmount = tipAmount + 1;

        // bob approve charlie to transfer bob's tokens
        vm.prank(bob);
        _token.approve(charlie, transferAmount);

        // charlie transfer bob's tokens to receiver, but bob has insufficient balance
        vm.expectRevert(abi.encodeWithSelector(InsufficientBalanceToTransfer.selector));
        vm.prank(charlie);
        _token.transferFrom(bob, address(0xaaaa), transferAmount);
    }

    function _mintPoints(address user, uint256 amount) internal {
        vm.startPrank(appAdmin);
        _token.mintToTreasury(address(_token), amount);
        _token.mint(user, amount, 0);
        _token.addUser(user);
        vm.stopPrank();
    }

    function _addUser(address user) internal {
        vm.prank(appAdmin);
        _token.addUser(user);
    }

    function _checkBalanceAndPoints(address user, uint256 balance, uint256 points) internal view {
        uint256 userBalance = _token.balanceOf(user);
        assertEq(userBalance, balance);

        uint256 userPoints = _token.balanceOfPoints(user);
        assertEq(userPoints, points);
    }
}
