// SPDX-License-Identifier: GNU-3.0-or-later
pragma solidity ^0.8.22;

import { Script, console } from "forge-std/Script.sol";

contract OFTAdapter is Script {
    event DeployOFTAdapter(address oftAdapter);

    function deploy() public {
        vm.startBroadcast();
        console.log("OFTAdapter deployed at: ", address(0x0));
        vm.stopBroadcast();
    }
}
