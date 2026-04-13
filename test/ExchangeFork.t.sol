// SPDX-License-Identifier: MIT
// solhint-disable comprehensive-interface,no-console,no-empty-blocks,function-max-lines
pragma solidity 0.8.22;

import {PowerToken} from "../src/PowerToken.sol";
import {IErrors} from "../src/interfaces/IErrors.sol";
import {IEvents} from "../src/interfaces/IEvents.sol";
import {TransparentUpgradeableProxy as Proxy} from "../src/upgradeability/TransparentUpgradeableProxy.sol";
import {Utils} from "./helpers/Utils.sol";

contract ExchangeFork is Utils, IErrors, IEvents {
    address public appAdmin = 0xf496eEeD857aA4709AC4D5B66b6711975623D355;
    uint256 public exchangeRate = 23;
    address public proxyAdminOwner = 0x8AC80fa0993D95C9d6B8Cb494E561E6731038941;

    address payable public powerProxyAddress = payable(0xE06Af68F0c9e819513a6CD083EF6848E76C28CD8);

    address public constant user = 0xf496eEeD857aA4709AC4D5B66b6711975623D355;

    function setUp() public {
        vm.createSelectFork("https://rpc.rss3.io", 33_105_472);

        Proxy powerProxy = Proxy(payable(powerProxyAddress));

        PowerToken newImpl = new PowerToken(appAdmin, exchangeRate);
        vm.prank(proxyAdminOwner);
        powerProxy.upgradeTo(address(newImpl));
    }

    function testExchangeFork() public {
        PowerToken token = PowerToken(powerProxyAddress);

        uint256 redeemableAmt = token.balanceOf(user) - token.balanceOfPoints(user);
        uint256 nativeOut = redeemableAmt / exchangeRate;

        assertGt(redeemableAmt, 0);
        assertGt(nativeOut, 0);

        uint256 contractPowerBefore = token.balanceOf(powerProxyAddress);
        uint256 userEthBefore = user.balance;

        vm.deal(powerProxyAddress, nativeOut);

        address[] memory users = new address[](1);
        users[0] = user;

        expectEmit();
        emit Exchanged(user, redeemableAmt, nativeOut);
        token.exchange(users);

        assertEq(token.balanceOf(user) - token.balanceOfPoints(user), 0);
        assertEq(user.balance, userEthBefore + nativeOut);
        assertEq(token.balanceOf(powerProxyAddress), contractPowerBefore + redeemableAmt);
    }
}
