// SPDX-License-Identifier: GNU-3.0-or-later
pragma solidity ^0.8.22;

import { Script, console } from "forge-std/Script.sol";

import { OptionsBuilder } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OptionsBuilder.sol"; // OFT imports
import {
    SendParam,
    OFTReceipt,
    OFTLimit,
    OFTReceipt,
    OFTFeeDetail,
    MessagingReceipt,
    MessagingFee
} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";
import { MessagingFee, MessagingReceipt } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFTCore.sol";

import { ETHx_OFTAdapter } from "../contracts/ETHx_OFTAdapter.sol";
import { ETHx } from "../contracts/ETHx.sol";

contract OFTAdapter is Script {
    event DeployOFTAdapter(address oftAdapter);

    function deploy() public {
        vm.startBroadcast();
        address ethx = vm.envAddress("ETHX");
        address lzEndpoint = vm.envAddress("LZ_ENDPOINT");
        address delegate = vm.envAddress("DELEGATE");
        ETHx_OFTAdapter oftAdapter = new ETHx_OFTAdapter(ethx, lzEndpoint, delegate);
        console.log("OFTAdapter deployed at: ", address(oftAdapter));
        vm.stopBroadcast();
    }

    function applygrants() public {
        address oftAdapter = vm.envAddress("OFT_ADAPTER");
        address ethx = vm.envAddress("ETHX");
        ETHx_OFTAdapter adapter = ETHx_OFTAdapter(oftAdapter);
        ETHx ethxInstance = ETHx(ethx);
        vm.startBroadcast();
        ethxInstance.grantRole(ethxInstance.MINTER_ROLE(), address(adapter));
        ethxInstance.grantRole(ethxInstance.BURNER_ROLE(), address(adapter));
        //ethxInstance.grantRole(ethxInstance.PAUSER_ROLE(), address(adapter));
        vm.stopBroadcast();
    }

    function setPeer() public {
        address oftAdapter = vm.envAddress("OFT_ADAPTER");
        uint32 peerEid = uint32(vm.envUint("PEER_EID"));
        address peerAddress = vm.envAddress("PEER_ADDRESS");
        ETHx_OFTAdapter adapter = ETHx_OFTAdapter(oftAdapter);
        vm.startBroadcast();
        bytes32 peerAddressBytes = bytes32(uint256(uint160(peerAddress)));
        adapter.setPeer(peerEid, peerAddressBytes);
        vm.stopBroadcast();
    }

    function quoteSend() public {
        address oftAdapter = vm.envAddress("OFT_ADAPTER");
        uint32 destEid = uint32(vm.envUint("PEER_EID"));
        address userAccount = vm.envAddress("DEST_ACCOUNT");
        uint256 tokensToSend = vm.envUint("AMOUNT");
        uint128 _gas = uint128(vm.envUint("GAS"));
        ETHx_OFTAdapter adapter = ETHx_OFTAdapter(oftAdapter);
        bytes memory options = OptionsBuilder.newOptions();
        options = OptionsBuilder.addExecutorLzReceiveOption(options, _gas, 0);
        SendParam memory sendParam =
            SendParam(destEid, addressToBytes32(userAccount), tokensToSend, tokensToSend, options, "", "");
        (OFTLimit memory limit, OFTFeeDetail[] memory detail, OFTReceipt memory receipt) = adapter.quoteOFT(sendParam);
        uint256 totalFee = 0;
        for (uint256 i = 0; i < detail.length; i++) {
            uint256 feeAmount = uint256(detail[i].feeAmountLD);
            console.log("Quote send fee: ", feeAmount);
            console.log("Quote send fee description: ", detail[i].description);
            totalFee += feeAmount;
        }
        console.log("Quote send min: ", limit.minAmountLD);
        console.log("Quote send max: ", limit.maxAmountLD);
        console.log("Quote send receipt: ", receipt.amountSentLD);
        vm.startBroadcast();
        console.log("Send fee: ", totalFee);
        (MessagingReceipt memory msgReceipt, OFTReceipt memory oftReceipt) =
            adapter.send{ value: totalFee }(sendParam, MessagingFee(totalFee, 0), payable(userAccount));
        console.log("Message receipt nonce: ", msgReceipt.nonce);
        console.log("OFT sent: ", oftReceipt.amountSentLD);
        vm.stopBroadcast();
    }

    function addressToBytes32(address addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(addr)));
    }
}
