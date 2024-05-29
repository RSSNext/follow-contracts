# IPowerToken
[Git Source](https://github.com/RSSNext/follow-contracts/blob/9b10b5dde4a39f8d3563aed64242b231d54904d7/src/interfaces/IPowerToken.sol)


## Functions
### initialize

Initializes the contract. Setup token name and symbol.
Also The msg.sender will be the APP_ADMIN_ROLE.


```solidity
function initialize(string calldata name_, string calldata symbol_) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`name_`|`string`|The name of the token.|
|`symbol_`|`string`|The symbol of the token.|


### tip

Tips with tokens. The caller must have the APP_ADMIN_ROLE.

*The to and feedId are optional, but at least one of them must be provided.*


```solidity
function tip(uint256 amount, address to, bytes32 feedId) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount token points to send. It can be empty.|
|`to`|`address`||
|`feedId`|`bytes32`|The feed id. It can be empty.|


### mint

Mints new token points. The caller must have the APP_ADMIN_ROLE.


```solidity
function mint(address to) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`to`|`address`|The account to receive the tokens.|


### withdraw

Withdraws tokens by feedId. The caller must have the APP_ADMIN_ROLE.


```solidity
function withdraw(address to, bytes32 feedId) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`to`|`address`|The address who receives the tokens.|
|`feedId`|`bytes32`|The amount belongs to the feedId.|


### balanceOfPoins


```solidity
function balanceOfPoins(address owner) external view returns (uint256);
```

