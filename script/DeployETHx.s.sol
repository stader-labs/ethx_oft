// SPDX-License-Identifier: GNU-3.0-or-later
pragma solidity ^0.8.22;

import { Script, console } from "forge-std/Script.sol";

import {
    ITransparentUpgradeableProxy,
    TransparentUpgradeableProxy
} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import { ETHx } from "../contracts/ETHx.sol";

contract DeployETHx is Script {
    event DeployedETHx(address ethxProxy, address ethx);

    function deployProxy() public {
        address admin = vm.envAddress("ETHX_ADMIN");
        vm.startBroadcast();
        ETHx implementation = new ETHx();
        bytes memory initializationData = abi.encodeWithSelector(ETHx.initialize.selector, admin);
        TransparentUpgradeableProxy proxy =
            new TransparentUpgradeableProxy(address(implementation), admin, initializationData);
        console.log("ETHx deployed to proxy at: ", address(proxy));
        ITransparentUpgradeableProxy proxyInterface = ITransparentUpgradeableProxy(address(proxy));
        console.log("Proxy admin: ", proxyInterface.admin());
        emit DeployedETHx(address(proxy), address(implementation));
        vm.stopBroadcast();
    }

    function upgradeProxy() public {
        address proxy = vm.envAddress("ETHX");
        vm.startBroadcast();
        ETHx implementation = new ETHx();
        ITransparentUpgradeableProxy proxyInterface = ITransparentUpgradeableProxy(proxy);
        proxyInterface.upgradeTo(address(implementation));
        vm.stopBroadcast();
    }

    function deployImplementation() public {
        vm.startBroadcast();
        ETHx implementation = new ETHx();
        console.log("ETHx deployed at: ", address(implementation));
        vm.stopBroadcast();
    }

    function setupGrants() public {
        address proxy = vm.envAddress("ETHX");
        address admin = vm.envAddress("ETHX_ADMIN");
        ETHx ethx = ETHx(proxy);
        ethx.grantRole(ethx.MINTER_ROLE(), admin);
        ethx.grantRole(ethx.BURNER_ROLE(), admin);
        ethx.grantRole(ethx.PAUSER_ROLE(), admin);
    }
}
