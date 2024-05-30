// SPDX-License-Identifier: MIT
// solhint-disable comprehensive-interface,no-console,no-empty-blocks
pragma solidity 0.8.22;

import {Utils} from "./helpers/Utils.sol";
import {PowerToken} from "../src/PowerToken.sol";
import {TransparentUpgradeableProxy} from "../src/upgradeability/TransparentUpgradeableProxy.sol";

contract PowerTokenTest is Utils {
    address public constant proxyAdmin = address(0x777);
    address public constant appAdmin = address(0x999);

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

    function testMint() public {}
}
