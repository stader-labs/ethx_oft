// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import { MultiChainRateProvider } from "./MultiChainRateProvider.sol";

import { IPriceFetcher } from "../../contracts/oracle/IPriceFetcher.sol";

/// @title rsETH cross chain rate provider
/// @notice Provides the current exchange rate of rsETH to a receiver contract on a different chain than the one this
/// contract is deployed on
contract ETHxRateProvider is MultiChainRateProvider {
    address public immutable ethxPriceOracle;

    constructor(address _ethxPriceOracle, address _ethx, address _layerZeroEndpoint) {
        ethxPriceOracle = _ethxPriceOracle;

        rateInfo = RateInfo({
            tokenSymbol: "ETHx",
            tokenAddress: _ethx,
            baseTokenSymbol: "ETH",
            baseTokenAddress: address(0) // Address 0 for native tokens
         });
        layerZeroEndpoint = _layerZeroEndpoint;
    }

    /// @notice Returns the latest rate from the rsETH contract
    function getLatestRate() public view override returns (uint256) {
        return IPriceFetcher(ethxPriceOracle).getAssetPrice(rateInfo.tokenAddress);
    }

    /// @notice Calls the getLatestRate function and returns the rate
    function getRate() external view returns (uint256) {
        return getLatestRate();
    }
}
