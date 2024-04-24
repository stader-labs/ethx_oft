// SPDX_License_Identifier: UNLICENSED
pragma solidity 0.8.22;

import { Test } from "forge-std/Test.sol";

import { ETHx } from "../contracts/ETHx.sol";

contract ETHxTest is Test {
    error EnforcedPause();

    ETHx private ethx;

    function setUp() public {
        address ethxmock = vm.addr(500);
        mockEthx(ethxmock);
        ethx = ETHx(ethxmock);
    }

    function testInitialize() public {
        assertEq(ethx.name(), "ETHx");
        assertEq(ethx.symbol(), "ETHx");
    }

    function testMint() public {
        address user = vm.addr(1001);
        ethx.mint(user, 100);
        assertEq(ethx.balanceOf(user), 100);
    }

    function testBurn() public {
        // burn operation only works when the caller has the BURNER_ROLE
        address user = address(this);
        ethx.mint(user, 100);
        ethx.burn(75);
        assertEq(ethx.balanceOf(user), 25);
    }

    function testBurnPaused() public {
        // burn operation only works when the contract is not paused
        address user = address(this);
        ethx.mint(user, 100);
        ethx.pause();
        vm.expectRevert("Pausable: paused");
        ethx.burn(75);
    }

    function mockEthx(address ethxMock) private {
        ETHx implementation = new ETHx();
        bytes memory code = address(implementation).code;
        vm.etch(ethxMock, code);
        ETHx mock = ETHx(ethxMock);
        mock.initialize(address(this));
        mock.grantRole(mock.MINTER_ROLE(), address(this));
        mock.grantRole(mock.BURNER_ROLE(), address(this));
        mock.grantRole(mock.PAUSER_ROLE(), address(this));
    }
}
