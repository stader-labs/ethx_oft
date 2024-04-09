// SPDX-License-Identifier: GNU-3.0-or-later
pragma solidity ^0.8.22;

import { Script, console } from "forge-std/Script.sol";

contract OFT is Script {
    event DeployOFT(address oft);

    function deploy() public {
        vm.startBroadcast();
        console.log("OFT deployed at: ", address(0x0));
        vm.stopBroadcast();
    }
}
