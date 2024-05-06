// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import { Test } from "forge-std/Test.sol";

import { PauserCodec } from "../contracts/ComposedPauser.sol";

contract PauserCodecTest is Test {
    // codec test
    function testEncodePaused() public {
        assertEq(hex"01", PauserCodec.encodePaused());
    }

    function testEncodeUnpaused() public {
        assertEq(hex"02", PauserCodec.encodeUnpaused());
    }

    function testDecodePaused() public {
        assertEq(PauserCodec.PAUSED, PauserCodec.pauseType(hex"01"));
    }

    function testDecodeUnpaused() public {
        assertEq(PauserCodec.UNPAUSED, PauserCodec.pauseType(hex"02"));
    }

    function testDecodeInvalid(uint8 paused) public {
        vm.assume(paused != PauserCodec.PAUSED && paused != PauserCodec.UNPAUSED);
        bytes memory _pauseMessage = abi.encodePacked(paused);
        vm.expectRevert(abi.encodeWithSelector(PauserCodec.InvalidMessageData.selector));
        PauserCodec.pauseType(_pauseMessage);
    }
}
