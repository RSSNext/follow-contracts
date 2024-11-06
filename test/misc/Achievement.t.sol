// SPDX-License-Identifier: MIT
// solhint-disable comprehensive-interface,no-console,no-empty-blocks,function-max-lines,quotes
pragma solidity 0.8.22;

import {DeployConfig} from "../../script/DeployConfig.s.sol";

import {PowerToken} from "../../src/PowerToken.sol";
import {Achievement} from "../../src/misc/Achievement.sol";

import {IErrors} from "../../src/interfaces/IAchievementErrors.sol";
import {IEvents} from "../../src/interfaces/IAchievementEvents.sol";
import {TransparentUpgradeableProxy} from "../../src/upgradeability/TransparentUpgradeableProxy.sol";
import {Utils} from "../helpers/Utils.sol";

import {AchievementDetails} from "../../src/libraries/AchievementDataTypes.sol";
import {ERC721Upgradeable} from "@openzeppelin-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {console} from "forge-std/Test.sol";

contract AchievementTest is Utils, ERC721Upgradeable, IEvents, IErrors {
    bytes32 public constant APP_ADMIN_ROLE = keccak256("APP_ADMIN_ROLE");
    bytes32 public constant APP_USER_ROLE = keccak256("APP_USER_ROLE");
    address public constant alice = address(0x123);
    address public constant bob = address(0x456);

    Achievement internal _achievement;
    PowerToken internal _powerToken;

    address internal _appAdmin;

    string public mockAchievementName = "Feed Owner";
    string public mockAchievemenDescription = "You own your feed on Follow.";
    string public mockAchievemenImageURL = "https://example.com/feed-owner.png";

    function setUp() public {
        string memory path = string.concat(vm.projectRoot(), "/deploy-config/", "local" ".json");

        DeployConfig cfg = new DeployConfig(path);

        _appAdmin = cfg.appAdmin();

        address powerProxy = deployPowerTokenProxy(cfg);

        _powerToken = PowerToken(powerProxy);

        address achievementProxy = deployAchievementProxy(cfg, powerProxy);

        _achievement = Achievement(achievementProxy);
    }

    function testSetAchievement() public {
        vm.prank(_appAdmin);

        expectEmit();
        emit AchievementSet(mockAchievementName, mockAchievemenDescription, mockAchievemenImageURL);
        _achievement.setAchievement(
            mockAchievementName, mockAchievemenDescription, mockAchievemenImageURL
        );

        AchievementDetails[] memory allAchievements = _achievement.getAllAchievements();

        assertEq(allAchievements.length, 1);
        assertEq(allAchievements[0].name, mockAchievementName);
        assertEq(allAchievements[0].description, mockAchievemenDescription);
        assertEq(allAchievements[0].imageURL, mockAchievemenImageURL);
    }

    function testMintFail() public {
        // Preparation
        vm.prank(_appAdmin);
        _achievement.setAchievement(
            mockAchievementName, mockAchievemenDescription, mockAchievemenImageURL
        );

        // Mint without APP_USER_ROLE role: Unauthorized
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(Unauthorized.selector));
        _achievement.mint(mockAchievementName);

        // Mint without achievement set: AchievementNotSet
        vm.prank(_appAdmin);
        _powerToken.addUser(bob);

        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(AchievementNotSet.selector));
        _achievement.mint("something");
    }

    function testAddRoleAndMint() public {
        // Preparation
        vm.prank(_appAdmin);
        _achievement.setAchievement(
            mockAchievementName, mockAchievemenDescription, mockAchievemenImageURL
        );

        vm.prank(_appAdmin);
        _powerToken.addUser(bob);

        // Mint achievement: balance of bob should be 1
        vm.prank(bob);
        vm.expectEmit();
        emit Transfer(address(0), bob, 1);
        _achievement.mint(mockAchievementName);

        assertEq(_achievement.totalSupply(), 1);
        assertEq(_achievement.balanceOf(bob), 1);

        // Test tokenURI
        assertEq(
            _achievement.tokenURI(1),
            string.concat(
                '{"name": "Achievement: ',
                mockAchievementName,
                '", "description": "',
                mockAchievemenDescription,
                '", "image": "',
                mockAchievemenImageURL,
                '"}'
            )
        );

        // Mint achievement again: AlreadyMinted
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(AlreadyMinted.selector, mockAchievementName));
        _achievement.mint(mockAchievementName);

        // Remove Bob and mint achievement: Unauthorized
        vm.prank(_appAdmin);
        _powerToken.removeUser(bob);

        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(Unauthorized.selector));
        _achievement.mint(mockAchievementName);
    }

    function testSetUp() public {
        assertEq(_achievement.powerToken(), address(_powerToken));
        assertEq(_achievement.totalSupply(), 0);
    }
}
