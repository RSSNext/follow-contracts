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

struct AchievementDetails {
    string description;
    string imageURL;
}

contract Achievement is
    IERC721,
    AccessControlEnumerableUpgradeable,
    ERC721Upgradeable,
    IErrors,
    IEvents,
    IAchievement
{
    bytes32 public constant APP_ADMIN_ROLE = keccak256("APP_ADMIN_ROLE");

    bytes32 public constant APP_USER_ROLE = keccak256("APP_USER_ROLE");

    uint256 internal _counter;
    uint256 internal _totalSupply;

    address internal _powerToken;

    // achievement name => achievement details
    mapping(string => AchievementDetails) internal _achievements;

    // tokenId => achievement name
    mapping(uint256 => string) internal _tokenIdToAchievements;

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
        _achievements[name] = AchievementDetails(description, imageURL);
        emit AchievementSet(name, description, imageURL);
    }

    /// @inheritdoc IAchievement
    function mint(string calldata achievement) external override returns (uint256 tokenId) {
        address account = msg.sender;

        if (!AccessControlEnumerableUpgradeable(_powerToken).hasRole(APP_USER_ROLE, account)) {
            revert Unauthorized();
        }

        if (bytes(_achievements[achievement].imageURL).length == 0) {
            revert AchievementNotSet();
        }

        tokenId = ++_counter;
        _mint(account, tokenId);

        _tokenIdToAchievements[tokenId] = achievement;

        ++_totalSupply;
    }

    /// @inheritdoc ERC721Upgradeable
    function tokenURI(uint256 id) public view override returns (string memory) {
        AchievementDetails memory details = _achievements[_tokenIdToAchievements[id]];
        string memory json = string.concat(
            '{"name": "Achievement: ',
            _tokenIdToAchievements[id],
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
}
