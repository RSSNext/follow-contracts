// SPDX-License-Identifier: MIT
// solhint-disable comprehensive-interface
pragma solidity 0.8.22;

import {DeployConfig} from "../../script/DeployConfig.s.sol";
import {IPowerToken} from "../../src/interfaces/IPowerToken.sol";
import {TransparentUpgradeableProxy} from "../../src/upgradeability/TransparentUpgradeableProxy.sol";

import {PowerToken} from "../../src/PowerToken.sol";
import {Achievement} from "../../src/misc/Achievement.sol";
import "forge-std/Test.sol";
import "forge-std/Vm.sol";

contract Utils is Test {
    uint8 public constant CheckTopic1 = 0x1;
    uint8 public constant CheckTopic2 = 0x2;
    uint8 public constant CheckTopic3 = 0x4;
    uint8 public constant CheckData = 0x8;
    uint8 public constant CheckAll = 0xf;

    function expectEmit() public {
        expectEmit(CheckAll);
    }

    function expectEmit(uint8 checks) public {
        uint8 mask = 0x1; //0001
        bool checkTopic1 = (checks & mask) > 0;
        bool checkTopic2 = (checks & (mask << 1)) > 0;
        bool checkTopic3 = (checks & (mask << 2)) > 0;
        bool checkData = (checks & (mask << 3)) > 0;

        vm.expectEmit(checkTopic1, checkTopic2, checkTopic3, checkData);
    }

    function deployPowerTokenProxy(DeployConfig cfg) public returns (address) {
        address appAdmin = cfg.appAdmin();

        PowerToken tokenImpl = new PowerToken(appAdmin);

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(tokenImpl),
            cfg.proxyAdminOwner(),
            abi.encodeWithSelector(
                IPowerToken.initialize.selector,
                cfg.name(),
                cfg.symbol(),
                cfg.appAdmin(),
                cfg.dailyMintLimit()
            )
        );

        return address(proxy);
    }

    function deployAchievementProxy(DeployConfig cfg, address powerToken)
        public
        returns (address)
    {
        Achievement achievementImpl = new Achievement();

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(achievementImpl),
            cfg.proxyAdminOwner(),
            abi.encodeWithSelector(
                Achievement.initialize.selector,
                cfg.nftName(),
                cfg.nftSymbol(),
                cfg.appAdmin(),
                powerToken
            )
        );

        return address(proxy);
    }
}
