// SPDX-License-Identifier: MIT
// solhint-disable comprehensive-interface,no-console,no-empty-blocks,function-max-lines
pragma solidity 0.8.22;

import {PowerToken} from "../src/PowerToken.sol";
import {IErrors} from "../src/interfaces/IErrors.sol";
import {IEvents} from "../src/interfaces/IEvents.sol";
import {IPowerToken} from "../src/interfaces/IPowerToken.sol";
import {TransparentUpgradeableProxy as Proxy} from
    "../src/upgradeability/TransparentUpgradeableProxy.sol";
import {Utils} from "./helpers/Utils.sol";

contract ForkTest is Utils, IErrors, IEvents {
    address public appAdmin = vm.addr(11);
    address public proxyAdminOwner = 0x8AC80fa0993D95C9d6B8Cb494E561E6731038941;
    bytes32 public initializerSlot =
        0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00;

    address public powerProxyAddress = 0xE06Af68F0c9e819513a6CD083EF6848E76C28CD8;

    function setUp() public {
        vm.createSelectFork("https://rpc.rss3.io", 9_376_625);

        // power token on mainnet
        Proxy powerProxy = Proxy(payable(powerProxyAddress));

        // initializer should be 3 before upgrade
        assertEq(
            vm.load(powerProxyAddress, initializerSlot),
            bytes32(uint256(3)),
            "check initializer before upgrade"
        );

        // upgrade and call initialize
        PowerToken newImpl = new PowerToken(appAdmin);
        vm.prank(proxyAdminOwner);
        powerProxy.upgradeToAndCall(
            address(newImpl),
            abi.encodeWithSelector(
                IPowerToken.initialize.selector, "POWER", "POWER", appAdmin, 10_000 ether
            )
        );
    }

    function testCheckUpgradeFork() public view {
        // initializer should be 4 after upgrade
        assertEq(
            vm.load(powerProxyAddress, initializerSlot),
            bytes32(uint256(4)),
            "check initializer after upgrade"
        );

        // check name and symbol
        PowerToken token = PowerToken(powerProxyAddress);
        assertEq(token.name(), "POWER");
        assertEq(token.symbol(), "POWER");

        // check admin role
        assertEq(token.ADMIN(), appAdmin);
        assertEq(token.hasRole(keccak256("APP_ADMIN_ROLE"), appAdmin), true);
        assertEq(token.hasRole(0x00, appAdmin), true);

        // check max supply
        assertEq(token.totalSupply(), token.MAX_SUPPLY());
    }
}
