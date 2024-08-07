// SPDX-License-Identifier: GNU-3.0-or-later
pragma solidity ^0.8.22;

import { Script, console } from "forge-std/Script.sol";

import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

import {
    ITransparentUpgradeableProxy,
    TransparentUpgradeableProxy
} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import { Stader } from "../contracts/Stader.sol";

contract DeployStader is Script {
    event DeployedStader(address staderProxy, address sd);

    function deployProxy() public {
        address admin = vm.envAddress("STADER_ADMIN");
        address proxyAdmin = vm.envAddress("PROXY_ADMIN");
        console.log("ProxyAdmin: ", proxyAdmin);
        address deploymentAdmin = msg.sender;
        vm.startBroadcast();
        Stader implementation = new Stader();
        bytes memory initializationData = abi.encodeWithSelector(Stader.initialize.selector, deploymentAdmin);
        TransparentUpgradeableProxy proxy =
            new TransparentUpgradeableProxy(address(implementation), proxyAdmin, initializationData);
        console.log("Stader deployed to proxy at: ", address(proxy));
        emit DeployedStader(address(proxy), address(implementation));
        Stader sd = Stader(address(proxy));
        if (admin != deploymentAdmin) {
            sd.grantRole(sd.DEFAULT_ADMIN_ROLE(), admin);
            sd.renounceRole(sd.DEFAULT_ADMIN_ROLE(), deploymentAdmin);
            console.log("Stader set admin to: ", admin);
            console.log("Stader renounced admin: ", deploymentAdmin);
        } else {
            console.log("Stader set admin to: ", admin);
        }
        vm.stopBroadcast();
    }

    function upgradeProxy() public {
        address proxy = vm.envAddress("STADER");
        vm.startBroadcast();
        Stader implementation = new Stader();
        ITransparentUpgradeableProxy proxyInterface = ITransparentUpgradeableProxy(proxy);
        proxyInterface.upgradeTo(address(implementation));
        vm.stopBroadcast();
    }

    function deployImplementation() public {
        vm.startBroadcast();
        Stader implementation = new Stader();
        console.log("Stader deployed at: ", address(implementation));
        vm.stopBroadcast();
    }

    function setupGrants() public {
        address proxy = vm.envAddress("STADER");
        address ccipTokenPool = vm.envAddress("TOKEN_POOL");
        address admin = vm.envAddress("STADER_ADMIN");
        Stader sd = Stader(proxy);
        vm.startBroadcast();
        sd.grantRole(sd.MINTER_ROLE(), ccipTokenPool);
        sd.grantRole(sd.BURNER_ROLE(), ccipTokenPool);
        sd.grantRole(sd.PAUSER_ROLE(), admin);
        vm.stopBroadcast();
    }
}
