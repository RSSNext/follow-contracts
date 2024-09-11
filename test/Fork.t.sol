// SPDX-License-Identifier: MIT
// solhint-disable comprehensive-interface,no-console,no-empty-blocks,function-max-lines
pragma solidity 0.8.22;

import {Utils} from "./helpers/Utils.sol";
import {PowerToken} from "../src/PowerToken.sol";
import {IErrors} from "../src/interfaces/IErrors.sol";
import {IEvents} from "../src/interfaces/IEvents.sol";
import {
    TransparentUpgradeableProxy as Proxy
} from "../src/upgradeability/TransparentUpgradeableProxy.sol";

contract ForkTest is Utils, IErrors, IEvents {
    PowerToken internal _token;

    function setUp() public {
        vm.createSelectFork("https://rpc.rss3.io", 8091639);

        PowerToken token = new PowerToken();

        // power token on mainnet
        Proxy powerProxy = Proxy(payable(0xE06Af68F0c9e819513a6CD083EF6848E76C28CD8));
        vm.prank(0x8AC80fa0993D95C9d6B8Cb494E561E6731038941);
        powerProxy.upgradeTo(address(token));
        _token = PowerToken(address(powerProxy));
    }

    function testMigrate() public {
        address[] memory users = new address[](4);
        users[0] = 0xAbb4e8dA48784b13C9d14066150ab7E19F310135;
        users[1] = 0x09a46cC643009BbF871B4edF30c5dcAb54cF589d;
        users[2] = 0x7F6A707531ffcc955aeC8e4cABce333DAA87fC3A;
        users[3] = 0x89f15B190370567f3d556b586D3b6186DaC29503;

        bytes32[] memory feedIds = new bytes32[](2);
        feedIds[0] = 0x3536323834373335373537363435383234000000000000000000000000000000;
        feedIds[1] = 0x3431323439393537303237363832333034000000000000000000000000000000;

        // get balance before migrate
        uint256[] memory balancesOfPoints = new uint256[](4);
        uint256[] memory balances = new uint256[](4);
        for (uint256 i = 0; i < users.length; i++) {
            bytes32 slot = keccak256(abi.encode(users[i], 0));
            balancesOfPoints[i] = uint256(vm.load(address(_token), slot));

            balances[i] = _token.balanceOf(users[i]);
        }

        vm.prank(0xf496eEeD857aA4709AC4D5B66b6711975623D355);
        _token.migrate(users, feedIds);

        // check points balance
        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            assertEq(_token.balanceOfPoints(user), balancesOfPoints[i] * 10);

            assertEq(_token.balanceOf(user), balances[i] * 10 + balancesOfPoints[i] * 10);
        }

        // check feed balance
        assertEq(_token.balanceOfByFeed(feedIds[0]), 30000000000000000000);
        assertEq(_token.balanceOfByFeed(feedIds[1]), 40000000000000000000);
    }

    function testTipToFeed() public {
        address[] memory users = new address[](1);
        users[0] = 0x5EF1994162EA6b5dC1b2F9c0A962bb2F33F103F7;

        bytes32 feedId = 0x3536323834373335373537363435383234000000000000000000000000000000;
        uint256 amount = 5 ether;

        vm.prank(0xf496eEeD857aA4709AC4D5B66b6711975623D355);
        _token.migrate(users, new bytes32[](0));

        vm.prank(users[0]);
        _token.tip(amount, address(0), feedId);

        assertEq(_token.balanceOfByFeed(feedId), 8 ether);
        assertEq(_token.balanceOf(users[0]), 15 ether);
    }
}
