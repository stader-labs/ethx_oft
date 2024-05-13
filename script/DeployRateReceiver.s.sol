// SPDX-License-Identifier: GNU-3.0-or-later
pragma solidity ^0.8.22;

import { Script, console } from "forge-std/Script.sol";

import { ETHxRateReceiver } from "../contracts/oracle/ETHxRateReceiver.sol";

contract DeployRateReceiver is Script {
    event RateReceiverDeployed(address rateReceiver);

    function deployReceiver() public {
        address admin = vm.envAddress("ETHX_ADMIN");
        address rateProvider = vm.envAddress("ETHX_RATE_PROVIDER");
        address layerZeroEndpoint = vm.envAddress("LZ_ENDPOINT");
        uint16 srcChainId = uint16(vm.envUint("SRC_CHAIN_ID") & 0xffff);
        vm.startBroadcast();
        ETHxRateReceiver rateReceiver = new ETHxRateReceiver(srcChainId, rateProvider, layerZeroEndpoint);
        rateReceiver.transferOwnership(admin);
        console.log("Rate receiver deployed at: ", address(rateReceiver));
        emit RateReceiverDeployed(address(rateReceiver));
        vm.stopBroadcast();
    }
}
