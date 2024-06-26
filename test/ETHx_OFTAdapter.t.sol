// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import { Test } from "forge-std/Test.sol";

import { MessagingFee } from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";

import { EndpointV2Mock as EndpointV2 } from "test-devtools-evm-foundry/contracts/mocks/EndpointV2Mock.sol";

import { ETHx_OFTAdapter } from "../contracts/ETHx_OFTAdapter.sol";

import { ERC20Mock } from "./mocks/ERC20Mock.sol";
import { ETHx_OFTAdapterMock } from "./mocks/ETHx_OFTAdapterMock.sol";

contract ETHx_OFTAdapterTest is Test {
    error AdapterPaused();

    uint32 public constant EID = 1;

    ERC20Mock erc20Mock;
    ETHx_OFTAdapterMock adapter;
    EndpointV2 endpoint;

    function setUp() public {
        erc20Mock = new ERC20Mock("ETHx", "ETHx");
        endpoint = new EndpointV2(EID, address(this));
        adapter = new ETHx_OFTAdapterMock(address(erc20Mock), address(endpoint), address(this));
    }

    function testConstructor() public {
        assertEq(address(erc20Mock), adapter.token());
        assertEq(address(this), adapter.owner());
        assertTrue(adapter.approvalRequired());
    }
}
