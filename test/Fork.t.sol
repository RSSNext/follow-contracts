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
        vm.createSelectFork("https://rpc.rss3.io", 8095321);

        PowerToken token = new PowerToken();

        // power token on mainnet
        Proxy powerProxy = Proxy(payable(0xE06Af68F0c9e819513a6CD083EF6848E76C28CD8));
        vm.prank(0x8AC80fa0993D95C9d6B8Cb494E561E6731038941);
        powerProxy.upgradeTo(address(token));
        _token = PowerToken(address(powerProxy));
    }

    function testMigrate() public {
        address[] memory users = new address[](12);
        users[0] = 0x0E36aFC0aEc6e948A52D928385CBa4bCe9F697bD;
        users[1] = 0x8E1165Eb2953979Ff70c05928acBccf98F70f323;
        users[2] = 0xb7a919114579db8f310eE73B8c404c60b798e7ba;
        users[3] = 0x70C215A06873afb3730ABF1861d9c6Ce2A3FBd08;
        users[4] = 0x9fcd2cA7cE37bC9291CD7728794adE08Fbe350a4;
        users[5] = 0x1C2393Dbaf9197e2eeb7Dce0362F4B4d0C52e9E8;
        users[6] = 0x22621bB3C54Fd820C1aF62EaBB645Bfe124949D9;
        users[7] = 0x3cFD45f691a583EBaB54Af4B4611559Bdd7B25B6;
        users[8] = 0xAbb4e8dA48784b13C9d14066150ab7E19F310135;
        users[9] = 0x09a46cC643009BbF871B4edF30c5dcAb54cF589d;
        users[10] = 0x7F6A707531ffcc955aeC8e4cABce333DAA87fC3A;
        users[11] = 0x89f15B190370567f3d556b586D3b6186DaC29503;

        // get balance before migrate
        uint256[] memory balancesOfPoints = new uint256[](12);
        uint256[] memory balances = new uint256[](12);
        for (uint256 i = 0; i < users.length; i++) {
            bytes32 slot = keccak256(abi.encode(users[i], 0));
            balancesOfPoints[i] = uint256(vm.load(address(_token), slot));

            balances[i] = _token.balanceOf(users[i]);
        }

        bytes32[] memory feedIds = new bytes32[](3);
        feedIds[0] = 0x3536323834373335373537363435383234000000000000000000000000000000;
        feedIds[1] = 0x3431323439393537303237363832333034000000000000000000000000000000;
        feedIds[2] = 0x3533383730383631383738303139303732000000000000000000000000000000;
        uint256[] memory balancesOfFeeds = new uint256[](3);
        for (uint256 i = 0; i < feedIds.length; i++) {
            balancesOfFeeds[i] = _token.balanceOfByFeed(feedIds[i]);
        }

        uint256 totalSupply = _token.totalSupply();

        vm.prank(0xf496eEeD857aA4709AC4D5B66b6711975623D355);
        _token.migrate(users, feedIds);

        // check points balance
        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            assertEq(_token.balanceOfPoints(user), balancesOfPoints[i] * 10);
            assertEq(_token.balanceOf(user), balances[i] * 10 + balancesOfPoints[i] * 10);
        }
        // check feed balance
        for (uint256 i = 0; i < feedIds.length; i++) {
            assertEq(_token.balanceOfByFeed(feedIds[i]), balancesOfFeeds[i] * 10);
        }

        // check total supply
        uint256 delta;
        for (uint256 i = 0; i < users.length; i++) {
            delta += balances[i] * 9 + balancesOfPoints[i] * 9;
        }
        for (uint256 i = 0; i < feedIds.length; i++) {
            delta += balancesOfFeeds[i] * 9;
        }
        assertEq(_token.totalSupply(), totalSupply + delta);
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
