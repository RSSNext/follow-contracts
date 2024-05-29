# PowerToken
[Git Source](https://github.com/RSSNext/follow-contracts/blob/9b10b5dde4a39f8d3563aed64242b231d54904d7/src/PowerToken.sol)

**Inherits:**
ERC20Upgradeable, [IPowerToken](/src/interfaces/IPowerToken.sol/interface.IPowerToken.md), AccessControlEnumerable


## State Variables
### APP_ADMIN_ROLE

```solidity
bytes32 public constant APP_ADMIN_ROLE = keccak256("APP_ADMIN_ROLE");
```


### _pointsBalances

```solidity
mapping(bytes32 feedId => uint256) internal _pointsBalances;
```


## Functions
### initialize


```solidity
function initialize(string calldata name_, string calldata symbol_) external override initializer;
```

### mint


```solidity
function mint(address to) external override onlyRole(APP_ADMIN_ROLE);
```

### tip


```solidity
function tip(uint256 amount, address to, bytes32 feedId) external override onlyRole(APP_ADMIN_ROLE);
```

### withdraw


```solidity
function withdraw(address to, bytes32 feedId) external override onlyRole(APP_ADMIN_ROLE);
```

### balanceOfPoins


```solidity
function balanceOfPoins(address owner) external view override returns (uint256);
```

### _contextSuffixLength


```solidity
function _contextSuffixLength() internal view virtual override(Context, ContextUpgradeable) returns (uint256);
```

### _msgSender


```solidity
function _msgSender() internal view virtual override(Context, ContextUpgradeable) returns (address);
```

### _msgData


```solidity
function _msgData() internal view virtual override(Context, ContextUpgradeable) returns (bytes calldata);
```

