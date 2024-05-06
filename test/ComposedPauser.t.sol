// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import { Test } from "forge-std/Test.sol";

import { ComposedPauser, PauserCodec } from "../contracts/ComposedPauser.sol";

contract ComposedPauserTest is Test {
    ComposedPauser pauser;

    function setUp() public {
        pauser = new ComposedPauser();
    }

    function testConstructor() public {
        assertFalse(pauser.paused());
    }

    function testPauseAndUnpause() public {
        pauser.pause();
        assertTrue(pauser.paused());
        pauser.unpause();
        assertFalse(pauser.paused());
    }

    function testOwnership() public {
        address newOwner = vm.addr(0x1);
        pauser.transferOwnership(newOwner);
        assertEq(newOwner, pauser.owner());
    }

    function testOwnerRequiredForPause() public {
        address newOwner = vm.addr(0x1);
        pauser.transferOwnership(newOwner);
        vm.expectRevert("Ownable: caller is not the owner");
        pauser.pause();
    }

    function testOwnerRequiredForUnpause() public {
        address newOwner = vm.addr(0x1);
        pauser.transferOwnership(newOwner);
        vm.expectRevert("Ownable: caller is not the owner");
        pauser.unpause();
    }

    function testDecomposePause() public {
        pauser.decompose(PauserCodec.encodePaused());
        assertTrue(pauser.paused());
    }

    function testDecomposeUnpause() public {
        pauser.pause();
        pauser.decompose(PauserCodec.encodeUnpaused());
        assertFalse(pauser.paused());
    }

    function testDecomposeRequiresOwner() public {
        address newOwner = vm.addr(0x1);
        pauser.transferOwnership(newOwner);
        vm.expectRevert("Ownable: caller is not the owner");
        pauser.decompose(PauserCodec.encodePaused());
    }
}
