// SPDX-License-Identifier: MIT
// solhint-disable quotes
pragma solidity 0.8.22;

import {AccessControlEnumerableUpgradeable} from
    "@openzeppelin-upgradeable/access/extensions/AccessControlEnumerableUpgradeable.sol";
import {ERC721Upgradeable} from "@openzeppelin-upgradeable/token/ERC721/ERC721Upgradeable.sol";

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import {IAchievement} from "../interfaces/IAchievement.sol";
import {IErrors} from "../interfaces/IAchievementErrors.sol";
import {IEvents} from "../interfaces/IAchievementEvents.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import {AchievementDetails} from "../libraries/AchievementDataTypes.sol";

contract Achievement is
    IERC721,
    AccessControlEnumerableUpgradeable,
    ERC721Upgradeable,
    IErrors,
    IEvents,
    IAchievement
{
    using EnumerableSet for EnumerableSet.Bytes32Set;

    bytes32 public constant APP_ADMIN_ROLE = keccak256("APP_ADMIN_ROLE");

    bytes32 public constant APP_USER_ROLE = keccak256("APP_USER_ROLE");

    uint256 internal _counter;
    uint256 internal _totalSupply;

    address internal _powerToken;

    // achievement name => achievement details
    EnumerableSet.Bytes32Set internal _achievements;

    // mapping from bytes32(hash of achievement name) to AchievementDetails
    mapping(bytes32 => AchievementDetails) internal _achievementDetails;

    // tokenId => achievement name
    mapping(uint256 => bytes32) internal _tokenIdToAchievements;

    // if user has minted this type of achievement
    mapping(address => mapping(bytes32 => bool)) internal _userAchievements;

    /// @inheritdoc IAchievement
    function initialize(
        string calldata name_,
        string calldata symbol_,
        address admin_,
        address powerToken_
    ) external override initializer {
        __ERC721_init(name_, symbol_);

        if (admin_ != address(0)) {
            _grantRole(DEFAULT_ADMIN_ROLE, admin_);
            _grantRole(APP_ADMIN_ROLE, admin_);
        }

        _powerToken = powerToken_;
    }

    /// @inheritdoc IAchievement
    function setAchievement(
        string calldata name,
        string calldata description,
        string calldata imageURL
    ) external override {
        // convert name to bytes32

        bytes32 nameHash = _getNameHash(name);
        _achievements.add(nameHash);
        _achievementDetails[nameHash] = AchievementDetails(name, description, imageURL);
        emit AchievementSet(name, description, imageURL);
    }

    /// @inheritdoc IAchievement
    function mint(string calldata achievementName) external override returns (uint256 tokenId) {
        address account = msg.sender;

        if (!AccessControlEnumerableUpgradeable(_powerToken).hasRole(APP_USER_ROLE, account)) {
            revert Unauthorized();
        }

        bytes32 nameHash = _getNameHash(achievementName);
        if (bytes(_achievementDetails[nameHash].imageURL).length == 0) {
            revert AchievementNotSet();
        }

        // TODO: check if the user has already minted this type of achievement
        if (_userAchievements[account][nameHash]) {
            revert AlreadyMinted(achievementName);
        }

        _userAchievements[account][nameHash] = true;

        tokenId = ++_counter;
        _mint(account, tokenId);

        _tokenIdToAchievements[tokenId] = nameHash;

        ++_totalSupply;
    }

    /// @inheritdoc ERC721Upgradeable
    function tokenURI(uint256 id) public view override returns (string memory) {
        AchievementDetails memory details = _achievementDetails[_tokenIdToAchievements[id]];
        string memory json = string.concat(
            '{"name": "Achievement: ',
            details.name,
            '", "description": "',
            details.description,
            '", "image": "',
            details.imageURL,
            '"}'
        );

        return json;
    }

    /// @inheritdoc IAchievement
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    /// @inheritdoc IAchievement
    function getAllAchievements() external view override returns (AchievementDetails[] memory) {
        uint256 length = _achievements.length();
        AchievementDetails[] memory result = new AchievementDetails[](length);

        for (uint256 i = 0; i < length; i++) {
            bytes32 nameHash = _achievements.at(i);
            result[i] = _achievementDetails[nameHash];
        }

        return result;
    }

    /// @inheritdoc IAchievement
    function powerToken() external view override returns (address) {
        return _powerToken;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerableUpgradeable, ERC721Upgradeable, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _getNameHash(string calldata name) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(name));
    }
}
