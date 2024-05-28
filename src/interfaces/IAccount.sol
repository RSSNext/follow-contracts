// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

interface IAccount {
    function nonce() external view returns (uint256);
}
