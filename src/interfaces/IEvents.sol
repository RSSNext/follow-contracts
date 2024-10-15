// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

interface IEvents {
    /**
     * @dev Emitted when points are distributed to an address.
     */
    event DistributePoints(address indexed to, uint256 indexed amount);
    /**
     * @dev Emitted when points are tipped from one address to another.
     */
    event Tip(address indexed from, address indexed to, bytes32 indexed feedId, uint256 amount);
    /**
     * @dev Emitted when points are airdropped to an address.
     */
    event AirdropTokens(address indexed to, uint256 indexed amount);
    /**
     * @dev Emitted when tax is collected.
     * @param collector The address that collected the tax.
     * @param amount The amount of tax collected.
     */
    event TaxCollected(address indexed collector, uint256 indexed amount);
    /**
     * @dev Emitted when points are withdrawn by feed id.
     */
    event WithdrawnByFeedId(address indexed to, bytes32 indexed feedId, uint256 indexed amount);
    /**
     * @dev Emitted when tokens are withdrawn from an address.
     */
    event Withdrawn(address indexed user, address indexed to, uint256 indexed amount);
}
