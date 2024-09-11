// SPDX-License-Identifier: MIT
// solhint-disable comprehensive-interface,no-console,no-empty-blocks,function-max-lines
pragma solidity 0.8.22;

import {Utils} from "./helpers/Utils.sol";
import {PowerToken} from "../src/PowerToken.sol";
import {IErrors} from "../src/interfaces/IErrors.sol";
import {IEvents} from "../src/interfaces/IEvents.sol";
import {TransparentUpgradeableProxy} from "../src/upgradeability/TransparentUpgradeableProxy.sol";
import {ERC20Upgradeable} from "@openzeppelin-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract PowerTokenTest is Utils, IErrors, IEvents, ERC20Upgradeable {
    address public constant proxyAdmin = address(0x777);
    address public constant appAdmin = address(0x999);

    address public constant alice = address(0x123);
    address public constant bob = address(0x456);
    address public constant charlie = address(0x789);
    bytes32 public constant someFeedId1 = bytes32("someFeedId1");
    bytes32 public constant someFeedId2 = bytes32("someFeedId2");
    bytes32 public constant someFeedId3 = bytes32("someFeedId3");

    PowerToken internal _token;

    error AccessControlUnauthorizedAccount(address account, bytes32 neededRole);

    function setUp() public {
        PowerToken tokenImpl = new PowerToken();

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(tokenImpl),
            proxyAdmin,
            abi.encodeWithSignature("initialize(string,string,address)", "POWER", "POWER", appAdmin)
        );

        _token = PowerToken(address(proxy));
    }

    function testMintAndBalanceOfPoints(uint256 amount) public {
        amount = bound(amount, 1, 10000 ether);

        expectEmit();
        emit Transfer(address(0), alice, amount);
        emit DistributePoints(alice, amount);
        vm.prank(appAdmin);
        _token.mint(alice, amount);

        // check balance and points
        assertEq(_token.balanceOf(alice), amount);
        assertEq(_token.balanceOfPoints(alice), amount);
        assertEq(_token.balanceOfPoints(address(_token)), 0);
    }

    function testMintFail() public {
        // case 1: caller has no `APP_ADMIN_ROLE` permission
        vm.expectRevert(
            abi.encodeWithSelector(
                AccessControlUnauthorizedAccount.selector,
                address(this),
                keccak256("APP_ADMIN_ROLE")
            )
        );
        _token.mint(alice, 1);

        // case 2: max supply is reached
        uint256 maxSupply = _token.MAX_SUPPLY();
        vm.expectRevert(abi.encodeWithSelector(ExceedsMaxSupply.selector));
        vm.prank(appAdmin);
        _token.mint(alice, maxSupply + 1);
    }

    function testTip(uint256 amount) public {
        uint256 initialPoints = 100;
        vm.assume(amount > 10 && amount < initialPoints);

        _mintPoints(alice, initialPoints);

        vm.startPrank(alice);

        vm.expectRevert(abi.encodeWithSelector(TipReceiverIsEmpty.selector));
        _token.tip(amount, address(0x0), "");

        vm.expectRevert(abi.encodeWithSelector(TipAmountIsZero.selector));
        _token.tip(0, bob, "");

        vm.expectRevert(abi.encodeWithSelector(InsufficientBalanceAndPoints.selector));
        _token.tip(2 * initialPoints, bob, "");

        expectEmit();
        emit Tip(alice, address(0x0), someFeedId1, 10);
        _token.tip(10, address(0x0), someFeedId1);
        vm.stopPrank();

        assertEq(_token.balanceOf(alice), initialPoints - 10);
        assertEq(_token.balanceOfPoints(alice), initialPoints - 10);
        assertEq(_token.balanceOfByFeed(someFeedId1), 10);
    }

    function testTipEntryAndBalanceOf() public {
        _mintPoints(alice, 100);
        _mintPoints(bob, 100);

        uint256 balance = _token.balanceOf(charlie);
        assertEq(balance, 0);

        vm.startPrank(alice);
        _token.tip(10, address(0x0), someFeedId1);
        _token.tip(20, address(0x0), someFeedId2);
        _token.tip(30, address(0x0), someFeedId3);
        vm.stopPrank();

        vm.startPrank(bob);
        _token.tip(15, address(0x0), someFeedId1);
        _token.tip(25, address(0x0), someFeedId2);
        _token.tip(35, address(0x0), someFeedId3);
        vm.stopPrank();

        uint256 feedBalance1 = _token.balanceOfByFeed(someFeedId1);
        uint256 feedBalance2 = _token.balanceOfByFeed(someFeedId2);
        uint256 feedBalance3 = _token.balanceOfByFeed(someFeedId3);
        assertEq(feedBalance1, 10 + 15);
        assertEq(feedBalance2, 20 + 25);
        assertEq(feedBalance3, 30 + 35);
    }

    function testTipAddress(uint256 amount) public {
        uint256 initialPoints = 100;
        vm.assume(amount > 10 && amount < initialPoints);

        _mintPoints(alice, initialPoints);

        // Alice tips bob (only points)
        vm.prank(alice);

        vm.expectEmit();
        emit Transfer(alice, bob, amount);
        emit Tip(alice, bob, "", amount);
        _token.tip(amount, bob, "");

        _checkBalanceAndPoints(alice, initialPoints - amount, initialPoints - amount);
        _checkBalanceAndPoints(bob, amount, 0);

        // Bob is minted with some points. Then bob tips charlie (points + balance)
        uint256 bobInitialPoints = amount / 2;
        _mintPoints(bob, bobInitialPoints);

        _checkBalanceAndPoints(bob, amount + bobInitialPoints, bobInitialPoints);

        vm.expectRevert(abi.encodeWithSelector(InsufficientBalanceAndPoints.selector));
        _token.tip(amount * 2, charlie, "");

        vm.prank(bob);
        vm.expectEmit();
        emit Transfer(bob, charlie, amount + 1);
        emit Tip(bob, charlie, "", amount + 1);
        _token.tip(amount + 1, charlie, "");

        uint256 expectedBobTokenBalance = bobInitialPoints - 1;

        // points is prioritized to be used over balance
        _checkBalanceAndPoints(bob, expectedBobTokenBalance, 0);

        // Bob tips alice only with tokens
        vm.expectEmit();
        emit Transfer(bob, alice, expectedBobTokenBalance);
        emit Tip(bob, alice, "", expectedBobTokenBalance);
        vm.prank(bob);
        _token.tip(expectedBobTokenBalance, alice, "");
    }

    function testWithdrawByFeedId(uint256 amount) public {
        uint256 initialPoints = 100;
        _mintPoints(alice, initialPoints);

        vm.assume(amount > 10 && amount < initialPoints);

        vm.prank(alice);
        _token.tip(amount, address(0x0), someFeedId1);

        vm.prank(appAdmin);
        vm.expectRevert(abi.encodeWithSelector(PointsInvalidReceiver.selector, bytes32(0)));
        _token.withdrawByFeedId(charlie, "");

        vm.prank(appAdmin);
        _token.withdrawByFeedId(charlie, someFeedId1);

        _checkBalanceAndPoints(alice, initialPoints - amount, initialPoints - amount);
        _checkBalanceAndPoints(charlie, amount, 0);
    }

    function testWithdraw(uint256 amount) public {
        amount = bound(amount, 1, 100 ether);
        uint256 tipAmount = bound(amount, 1, amount);

        _mintPoints(alice, amount);
        _mintPoints(bob, amount);

        vm.prank(alice);
        _token.tip(tipAmount, bob, "");

        uint256 withdrawAmount = bound(amount, 1, tipAmount);
        address receiver = address(0xaaaa);

        vm.expectEmit();
        emit Transfer(bob, receiver, withdrawAmount);
        vm.prank(bob);
        _token.withdraw(receiver, withdrawAmount);

        _checkBalanceAndPoints(alice, amount - tipAmount, amount - tipAmount);
        _checkBalanceAndPoints(bob, amount + tipAmount - withdrawAmount, amount);
        _checkBalanceAndPoints(receiver, withdrawAmount, 0);
    }

    function testWithdrawFail() public {
        _mintPoints(alice, 100);

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(InsufficientBalanceToWithdraw.selector));
        _token.withdraw(bob, 1);
    }

    function _mintPoints(address user, uint256 amount) internal {
        vm.prank(appAdmin);
        _token.mint(user, amount);
    }

    function _checkBalanceAndPoints(address user, uint256 balance, uint256 points) internal view {
        uint256 userBalance = _token.balanceOf(user);
        assertEq(userBalance, balance);

        uint256 userPoints = _token.balanceOfPoints(user);
        assertEq(userPoints, points);
    }
}
