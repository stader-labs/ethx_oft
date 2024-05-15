// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

interface IPriceOracle {
    /**
     * @dev Get the price of an asset
     * @param asset The asset to get the price of
     * @return The price of the asset
     */
    function getAssetPrice(address asset) external view returns (uint256);
}
