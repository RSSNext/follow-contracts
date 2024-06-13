// SPDX-License-Identifier: MIT
// solhint-disable comprehensive-interface,no-console,no-empty-blocks
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
    bytes32 public constant someEntryId1 = bytes32("someEntryId1");
    bytes32 public constant someEntryId2 = bytes32("someEntryId2");
    bytes32 public constant someEntryId3 = bytes32("someEntryId3");

    PowerToken internal _token;

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
        vm.assume(amount > 0 && amount < 10000);

        expectEmit();
        emit Transfer(address(0), address(_token), amount);
        emit DistributePoints(alice, amount);
        _mintPoints(alice, amount);

        uint256 balance = _token.balanceOf(alice);
        assertEq(balance, 0);

        uint256 pointsBalance = _token.balanceOfPoints(alice);
        assertEq(pointsBalance, amount);

        uint256 tokenBalance = _token.balanceOf(address(_token));
        assertEq(tokenBalance, amount);
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
        emit Tip(alice, address(0x0), someEntryId1, 10);
        _token.tip(10, address(0x0), someEntryId1);
    }

    function testTipEntryAndBalanceOf() public {
        _mintPoints(alice, 100);
        _mintPoints(bob, 100);

        uint256 balance = _token.balanceOf(charlie);
        assertEq(balance, 0);

        vm.startPrank(alice);
        _token.tip(10, address(0x0), someEntryId1);
        _token.tip(20, address(0x0), someEntryId2);
        _token.tip(30, address(0x0), someEntryId3);
        vm.stopPrank();

        vm.startPrank(bob);
        _token.tip(15, address(0x0), someEntryId1);
        _token.tip(25, address(0x0), someEntryId2);
        _token.tip(35, address(0x0), someEntryId3);
        vm.stopPrank();

        uint256 entryBalance1 = _token.balanceOfByEntry(someEntryId1);
        uint256 entryBalance2 = _token.balanceOfByEntry(someEntryId2);
        uint256 entryBalance3 = _token.balanceOfByEntry(someEntryId3);
        assertEq(entryBalance1, 10 + 15);
        assertEq(entryBalance2, 20 + 25);
        assertEq(entryBalance3, 30 + 35);
    }

    function testTipAddress(uint256 amount) public {
        uint256 initialPoints = 100;
        vm.assume(amount > 10 && amount < initialPoints);

        _mintPoints(alice, initialPoints);

        // Alice tips bob (only points)
        vm.prank(alice);

        vm.expectEmit();
        emit Transfer(address(_token), bob, amount);
        emit Tip(alice, bob, "", amount);
        _token.tip(amount, bob, "");

        _checkBalanceAndPoints(alice, 0, initialPoints - amount);
        _checkBalanceAndPoints(bob, amount, 0);

        // Bob is minted with some points. Then bob tips charlie (points + balance)
        uint256 bobInitialPoints = amount / 2;
        _mintPoints(bob, bobInitialPoints);

        _checkBalanceAndPoints(bob, amount, bobInitialPoints);

        vm.expectRevert(abi.encodeWithSelector(InsufficientBalanceAndPoints.selector));
        _token.tip(amount * 2, charlie, "");

        vm.prank(bob);
        vm.expectEmit();
        emit Transfer(address(_token), charlie, bobInitialPoints);
        emit Transfer(bob, charlie, amount + 1 - bobInitialPoints);
        emit Tip(bob, charlie, "", amount + 1 - bobInitialPoints);
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

    function testWithdraw(uint256 amount) public {
        uint256 initialPoints = 100;
        _mintPoints(alice, initialPoints);

        vm.assume(amount > 10 && amount < initialPoints);

        vm.prank(alice);
        _token.tip(amount, address(0x0), someEntryId1);

        vm.prank(appAdmin);
        vm.expectRevert(abi.encodeWithSelector(PointsInvalidReceiver.selector, bytes32(0)));
        _token.withdraw(charlie, "");

        vm.prank(appAdmin);
        _token.withdraw(charlie, someEntryId1);

        _checkBalanceAndPoints(alice, 0, initialPoints - amount);
        _checkBalanceAndPoints(charlie, amount, 0);
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
