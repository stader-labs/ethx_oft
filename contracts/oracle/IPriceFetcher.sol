// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

interface IPriceFetcher {
    function getAssetPrice(address asset) external view returns (uint256);
}
