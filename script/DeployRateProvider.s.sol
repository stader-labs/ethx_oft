// SPDX-License-Identifier: GNU-3.0-or-later
pragma solidity ^0.8.22;

import { Script, console } from "forge-std/Script.sol";

import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

import {
    ITransparentUpgradeableProxy,
    TransparentUpgradeableProxy
} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import { ETHxPriceOracle } from "../contracts/oracle/ETHxPriceOracle.sol";
import { ETHxRateProvider } from "../contracts/oracle/ETHxRateProvider.sol";

contract DeployRateProvider is Script {
    event DeployedRateProvider(address rateProvider);
    event DeployedRateOracle(address rateOracle);

    function deployProxyOracle() public {
        address proxyAdmin = vm.envAddress("PROXY_ADMIN");
        address stakePoolManager = vm.envAddress("STAKE_POOL_MANAGER");
        vm.startBroadcast();
        ETHxPriceOracle implementation = new ETHxPriceOracle();
        bytes memory initializationData = abi.encodeWithSelector(ETHxPriceOracle.initialize.selector, stakePoolManager);
        TransparentUpgradeableProxy proxy =
            new TransparentUpgradeableProxy(address(implementation), proxyAdmin, initializationData);
        console.log("ETHxPriceOracle deployed to proxy at: ", address(proxy));
        emit DeployedRateOracle(address(proxy));
        vm.stopBroadcast();
    }

    function deployProvider() public {
        address admin = vm.envAddress("ETHX_ADMIN");
        address ethxPriceOracle = vm.envAddress("ETHX_PRICE_ORACLE");
        address ethx = vm.envAddress("ETHX");
        address layerZeroEndpoint = vm.envAddress("LZ_ENDPOINT");
        vm.startBroadcast();
        ETHxRateProvider rateProvider = new ETHxRateProvider(ethxPriceOracle, ethx, layerZeroEndpoint);
        rateProvider.transferOwnership(admin);
        console.log("Rate provider deployed at: ", address(rateProvider));
        emit DeployedRateProvider(address(rateProvider));
        vm.stopBroadcast();
    }

    function wireProvider() public {
        address rateProvider = vm.envAddress("RATE_PROVIDER");
        uint16 dstChainId = uint16(vm.envUint("DST_CHAIN_ID") & 0xffff);
        address rateReceiver = vm.envAddress("RATE_RECEIVER");
        vm.startBroadcast();
        ETHxRateProvider ethxRateProvider = ETHxRateProvider(rateProvider);
        ethxRateProvider.addRateReceiver(dstChainId, rateReceiver);
        vm.stopBroadcast();
    }
}
