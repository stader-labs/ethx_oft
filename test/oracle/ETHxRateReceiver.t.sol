// SPDX_License_Identifier: UNLICENSED
pragma solidity 0.8.22;

import { Test } from "forge-std/Test.sol";

import { ETHxRateReceiver } from "../../contracts/oracle/ETHxRateReceiver.sol";
import { CrossChainRateReceiver } from "../../contracts/oracle/CrossChainRateReceiver.sol";

contract ETHxRateReceiverTest is Test {
    uint16 private constant SRC_CHAIN_ID = 1;
    uint16 private constant DST_CHAIN_ID = 2;
    uint256 private constant RATE_PROVIDER = 0x101;
    uint256 private constant LAYER_ZERO_ENDPOINT = 0x102;
    uint256 private constant RATE = 999;

    ETHxRateReceiver private ethXRateReceiver;

    function setUp() public {
        vm.clearMockedCalls();
        address rateProvider = vm.addr(RATE_PROVIDER);
        address lzEndpoint = vm.addr(LAYER_ZERO_ENDPOINT);
        ethXRateReceiver = new ETHxRateReceiver(SRC_CHAIN_ID, rateProvider, lzEndpoint);
    }

    function testRateInfo() public {
        (string memory symbol, string memory baseSymbol) = ethXRateReceiver.rateInfo();
        assertEq(symbol, "ETHx");
        assertEq(baseSymbol, "WETH");
    }

    function testSourceChainId() public {
        assertEq(ethXRateReceiver.srcChainId(), SRC_CHAIN_ID);
    }

    function testRateUpdate() public {
        assertNotEq(ethXRateReceiver.rate(), RATE);
        assertEq(ethXRateReceiver.lastUpdated(), 0);
        address rateProvider = vm.addr(RATE_PROVIDER);
        address endpoint = vm.addr(LAYER_ZERO_ENDPOINT);
        vm.prank(endpoint);
        ethXRateReceiver.lzReceive(SRC_CHAIN_ID, abi.encodePacked(rateProvider), 1, abi.encode(RATE));
        assertEq(ethXRateReceiver.rate(), RATE);
        assertTrue(ethXRateReceiver.lastUpdated() > 0);
    }

    function testSenderMustBeLayerZeroEndpoint() public {
        address rateProvider = vm.addr(RATE_PROVIDER);
        vm.expectRevert(abi.encodeWithSelector(CrossChainRateReceiver.SenderMustBeLayerZeroEndpoint.selector));
        ethXRateReceiver.lzReceive(SRC_CHAIN_ID, abi.encodePacked(rateProvider), 1, abi.encode(RATE));
    }

    function testSenderMustSourceChain() public {
        address rateProvider = vm.addr(RATE_PROVIDER);
        address endpoint = vm.addr(LAYER_ZERO_ENDPOINT);
        vm.prank(endpoint);
        vm.expectRevert(
            abi.encodeWithSelector(
                CrossChainRateReceiver.SourceChainIdDoesNotMatch.selector, DST_CHAIN_ID, SRC_CHAIN_ID
            )
        );
        ethXRateReceiver.lzReceive(DST_CHAIN_ID, abi.encodePacked(rateProvider), 1, abi.encode(RATE));
    }

    function testSenderMustBeExpectedApp() public {
        address rateProvider = vm.addr(RATE_PROVIDER);
        address fakeProvider = vm.addr(0x555);
        address endpoint = vm.addr(LAYER_ZERO_ENDPOINT);
        vm.prank(endpoint);
        vm.expectRevert(
            abi.encodeWithSelector(CrossChainRateReceiver.SourceOAppNotExpected.selector, fakeProvider, rateProvider)
        );
        ethXRateReceiver.lzReceive(SRC_CHAIN_ID, abi.encodePacked(fakeProvider), 1, abi.encode(RATE));
    }
}
