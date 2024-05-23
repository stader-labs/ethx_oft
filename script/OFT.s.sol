// SPDX-License-Identifier: GNU-3.0-or-later
pragma solidity ^0.8.22;

import { Script, console } from "forge-std/Script.sol";

import { ETHx_OFT } from "../contracts/ETHx_OFT.sol";
import { ETHx } from "../contracts/ETHx.sol";

contract OFT is Script {
    event DeployOFT(address oft);

    function deploy() public {
        address ethx = vm.envAddress("ETHX");
        address lzEndpoint = vm.envAddress("LZ_ENDPOINT");
        address delegate = vm.envAddress("DELEGATE");

        vm.startBroadcast();
        ETHx_OFT oft = new ETHx_OFT(ethx, lzEndpoint, delegate);
        console.log("ETHx_OFT deployed to: ", address(oft));
        setupGrants(ethx, address(oft));
        emit DeployOFT(address(oft));
        vm.stopBroadcast();
    }

    function setupGrants(address proxy, address admin) private {
        ETHx ethx = ETHx(proxy);
        ethx.grantRole(ethx.MINTER_ROLE(), admin);
        ethx.grantRole(ethx.BURNER_ROLE(), admin);
    }

    function setPeer() public {
        address oft = vm.envAddress("OFT");
        uint32 peerEid = uint32(vm.envUint("PEER_EID"));
        address peerAddress = vm.envAddress("PEER_ADDRESS");
        ETHx_OFT ethx_oft = ETHx_OFT(oft);
        vm.startBroadcast();
        bytes32 peerAddressBytes = bytes32(uint256(uint160(peerAddress)));
        ethx_oft.setPeer(peerEid, peerAddressBytes);
        vm.stopBroadcast();
    }
}
