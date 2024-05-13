// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import { IPriceFetcher } from "./IPriceFetcher.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

interface IETHxStakePoolManager {
    function getExchangeRate() external view returns (uint256);
    function staderConfig() external view returns (address);
}

interface IStaderConfig {
    function getETHxToken() external view returns (address);
}

/// @title EthXPriceOracle Contract
/// @notice contract that fetches the exchange rate of ETHX/ETH
contract ETHxPriceOracle is IPriceFetcher, Initializable {
    address public stakePoolManager;

    error InvalidAsset();

    /// @notice Emitted when an address is required to be non-zero
    error NonZeroAddressRequired();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    modifier nonZeroAddressRequired(address _address) {
        if (_address == address(0)) {
            revert NonZeroAddressRequired();
        }
        _;
    }

    /// @dev Initializes the contract
    /// @param stakePoolManager_ ETHX address
    function initialize(address stakePoolManager_) external initializer nonZeroAddressRequired(stakePoolManager_) {
        stakePoolManager = stakePoolManager_;
    }

    /// @notice Fetches Asset/ETH exchange rate
    /// @param asset the asset for which exchange rate is required
    /// @return assetPrice exchange rate of asset
    function getAssetPrice(address asset) external view returns (uint256) {
        address staderConfigProxyAddress = IETHxStakePoolManager(stakePoolManager).staderConfig();

        if (asset != IStaderConfig(staderConfigProxyAddress).getETHxToken()) {
            revert InvalidAsset();
        }

        return IETHxStakePoolManager(stakePoolManager).getExchangeRate();
    }
}
