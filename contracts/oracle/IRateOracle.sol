// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import { IPriceOracle } from "./IPriceOracle.sol";

interface IRateOracle is IPriceOracle {
    /**
     * @notice get the current exchange rate for the asset
     * @return the exchange rate
     */
    function getRate() external view returns (uint256);
}
