// SPDX_License_Identifier: UNLICENSED
pragma solidity 0.8.22;

import { Test } from "forge-std/Test.sol";

import { ETHxRateProvider } from "../../contracts/oracle/ETHxRateProvider.sol";
import { IPriceFetcher } from "../../contracts/oracle/IPriceFetcher.sol";

contract EthXRateProviderTest is Test {
    uint256 private constant ETHX_ADDR = 0x1001;
    uint256 private constant RATE = 100;

    ETHxRateProvider private ethXRateProvider;

    function setUp() public {
        vm.clearMockedCalls();
        address rateOracle = vm.addr(0x101);
        mockOracle(rateOracle);
        address lzEndpoint = vm.addr(0x102);
        address ethx = vm.addr(ETHX_ADDR);
        ethXRateProvider = new ETHxRateProvider(rateOracle, ethx, lzEndpoint);
    }

    function testGetRate() public {
        assertEq(ethXRateProvider.getRate(), RATE);
    }

    function testGetLatestRate() public {
        assertEq(ethXRateProvider.getLatestRate(), RATE);
    }

    function mockOracle(address _rateOracle) private {
        vm.mockCall(_rateOracle, abi.encodeWithSelector(IPriceFetcher.getAssetPrice.selector), abi.encode(RATE));
    }
}
