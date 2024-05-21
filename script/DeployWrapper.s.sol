// SPDX-License-Identifier: GNU-3.0-or-later
pragma solidity ^0.8.22;

import { Script, console } from "forge-std/Script.sol";

import {
    ITransparentUpgradeableProxy,
    TransparentUpgradeableProxy
} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import { ETHxTokenWrapper } from "../contracts/L2/ETHxTokenWrapper.sol";
import { ETHxPoolV4 } from "../contracts/L2/ETHxPoolV4.sol";

contract DeployWrapper is Script {
    function deployWrapper() public {
        address admin = vm.envAddress("ETHX_ADMIN");
        address bridger = vm.envAddress("BRIDGER");
        address proxyAdmin = vm.envAddress("PROXY_ADMIN");
        address ethx = vm.envAddress("ETHX");
        address deploymentAdmin = msg.sender;
        vm.startBroadcast();
        ETHxTokenWrapper implementation = new ETHxTokenWrapper();
        bytes memory initializationData =
            abi.encodeWithSelector(ETHxTokenWrapper.initialize.selector, admin, bridger, ethx);
        TransparentUpgradeableProxy proxy =
            new TransparentUpgradeableProxy(address(implementation), proxyAdmin, initializationData);
        console.log("ETHxTokenWrapper deployed to proxy at: ", address(proxy));
        if (admin != deploymentAdmin) {
            ETHxTokenWrapper ethxTokenWrapper = ETHxTokenWrapper(address(proxy));
            ethxTokenWrapper.grantRole(ethxTokenWrapper.DEFAULT_ADMIN_ROLE(), admin);
            ethxTokenWrapper.renounceRole(ethxTokenWrapper.DEFAULT_ADMIN_ROLE(), deploymentAdmin);
            console.log("ETHxTokenWrapper set admin to: ", admin);
            console.log("ETHxTokenWrapper renounced admin: ", deploymentAdmin);
        } else {
            console.log("ETHxTokenWrapper set admin to: ", admin);
        }
        vm.stopBroadcast();
    }

    function deployPool() public {
        address admin = vm.envAddress("ETHX_ADMIN");
        address bridger = vm.envAddress("BRIDGER");
        address proxyAdmin = vm.envAddress("PROXY_ADMIN");
        address wethx = vm.envAddress("ETHX_WRAPPER");
        address oracle = vm.envAddress("ORACLE");
        address weth = vm.envAddress("WETH");
        uint256 feeBps = vm.envUint("FEE_BPS");
        address deploymentAdmin = msg.sender;
        vm.startBroadcast();
        ETHxPoolV4 implementation = new ETHxPoolV4();
        bytes memory initializationData =
            abi.encodeWithSelector(ETHxTokenWrapper.initialize.selector, admin, bridger, wethx);
        TransparentUpgradeableProxy proxy =
            new TransparentUpgradeableProxy(address(implementation), proxyAdmin, initializationData);
        console.log("ETHxPoolV4 deployed to proxy at: ", address(proxy));
        addSupportedToken(address(proxy), weth, oracle, feeBps);
        grantMinter(wethx, address(proxy));
        if (admin != deploymentAdmin) {
            ETHxPoolV4 ethxPoolV4 = ETHxPoolV4(address(proxy));
            ethxPoolV4.grantRole(ethxPoolV4.DEFAULT_ADMIN_ROLE(), admin);
            ethxPoolV4.renounceRole(ethxPoolV4.DEFAULT_ADMIN_ROLE(), deploymentAdmin);
            console.log("ETHxPoolV4 set admin to: ", admin);
            console.log("ETHxPoolV4 renounced admin: ", deploymentAdmin);
        } else {
            console.log("ETHxPoolV4 set admin to: ", admin);
        }
        vm.stopBroadcast();
    }

    function addSupportedToken(address pool, address token, address oracle, uint256 feeBps) private {
        ETHxPoolV4 ethxPoolV4 = ETHxPoolV4(pool);
        ethxPoolV4.addSupportedToken(token, oracle, feeBps);
        console.log("Added supported token: ", token);
    }

    function grantMinter(address wethx, address pool) private {
        ETHxTokenWrapper ethxTokenWrapper = ETHxTokenWrapper(wethx);
        ethxTokenWrapper.grantRole(ethxTokenWrapper.MINTER_ROLE(), pool);
        console.log("Granted MINTER_ROLE to pool: ", pool);
    }
}
