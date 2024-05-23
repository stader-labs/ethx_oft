// SPDX-License-Identifier: GNU-3.0-or-later
pragma solidity ^0.8.22;

import { Script, console } from "forge-std/Script.sol";

import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

import {
    ITransparentUpgradeableProxy,
    TransparentUpgradeableProxy
} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import { ETHx } from "../contracts/ETHx.sol";

contract DeployETHx is Script {
    event DeployedETHx(address ethxProxy, address ethx);
    event ProxyAdminCreated(address admin);

    function deployAdmin() public {
        address admin = vm.envAddress("ETHX_ADMIN");
        vm.startBroadcast();
        ProxyAdmin proxyAdmin = new ProxyAdmin();
        console.log("ProxyAdmin: ", address(proxyAdmin));
        proxyAdmin.transferOwnership(admin);
        emit ProxyAdminCreated(address(proxyAdmin));
        vm.stopBroadcast();
    }

    function deployProxy() public {
        address admin = vm.envAddress("ETHX_ADMIN");
        address proxyAdmin = vm.envAddress("PROXY_ADMIN");
        console.log("ProxyAdmin: ", proxyAdmin);
        address deploymentAdmin = msg.sender;
        vm.startBroadcast();
        ETHx implementation = new ETHx();
        bytes memory initializationData = abi.encodeWithSelector(ETHx.initialize.selector, deploymentAdmin);
        TransparentUpgradeableProxy proxy =
            new TransparentUpgradeableProxy(address(implementation), proxyAdmin, initializationData);
        console.log("ETHx deployed to proxy at: ", address(proxy));
        emit DeployedETHx(address(proxy), address(implementation));
        ETHx ethx = ETHx(address(proxy));
        if (admin != deploymentAdmin) {
            ethx.grantRole(ethx.DEFAULT_ADMIN_ROLE(), admin);
            ethx.renounceRole(ethx.DEFAULT_ADMIN_ROLE(), deploymentAdmin);
            console.log("ETHx set admin to: ", admin);
            console.log("ETHx renounced admin: ", deploymentAdmin);
        } else {
            console.log("ETHx set admin to: ", admin);
        }
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
        vm.startBroadcast();
        ethx.grantRole(ethx.MINTER_ROLE(), admin);
        ethx.grantRole(ethx.BURNER_ROLE(), admin);
        ethx.grantRole(ethx.PAUSER_ROLE(), admin);
        vm.stopBroadcast();
    }
}
