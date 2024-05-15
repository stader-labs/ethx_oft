// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import { BaseTest } from "./BaseTest.t.sol";
import { ETHxTokenWrapper, ERC20Upgradeable } from "contracts/L2/ETHxTokenWrapper.sol";

import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

contract ETHxTokenWrapperSetUpTest is BaseTest {
    ETHxTokenWrapper public ethxWrapper;
    AltETHx public altETHx;

    address public manager;
    address public bridger;

    event Deposit(address asset, address _sender, uint256 _amount);
    event Withdraw(address asset, address _sender, uint256 _amount);
    event BridgerDeposited(address asset, uint256 _amount);

    function setUp() public virtual override {
        super.setUp();

        ProxyAdmin proxyAdmin = new ProxyAdmin();
        ETHxTokenWrapper tokenImpl = new ETHxTokenWrapper();
        TransparentUpgradeableProxy tokenProxy =
            new TransparentUpgradeableProxy(address(tokenImpl), address(proxyAdmin), "");

        ethxWrapper = ETHxTokenWrapper(address(tokenProxy));

        manager = address(this);
        altETHx = new AltETHx();

        ethxWrapper.initialize(admin, manager, address(altETHx));

        // give bridger role to manager
        vm.startPrank(admin);
        ethxWrapper.grantRole(ethxWrapper.BRIDGER_ROLE(), manager);
        vm.stopPrank();
    }
}

contract ETHxTokenWrapperInitialize is ETHxTokenWrapperSetUpTest {
    function test_InitializeContractsVariables() external {
        assertTrue(ethxWrapper.allowedTokens(address(altETHx)), "altETHx is not allowed");
        assertEq(ethxWrapper.name(), "ETHxWrapper", "Name is not set");
        assertEq(ethxWrapper.symbol(), "WETHx", "Symbol is not set");
        assertEq(ethxWrapper.decimals(), 18, "Decimals is not set");
        assertTrue(ethxWrapper.hasRole(ethxWrapper.DEFAULT_ADMIN_ROLE(), admin), "Admin role is not set");
    }
}

contract ETHxTokenWrapperDeposit is ETHxTokenWrapperSetUpTest {
    function setUp() public override {
        super.setUp();
        altETHx.mint(address(this), 100);
        altETHx.approve(address(ethxWrapper), 100);
    }

    function test_RevertDepositWhenTokenIsNotAllowed() external {
        address falseToken = address(0x1234);
        vm.expectRevert();
        ethxWrapper.deposit(address(falseToken), 100);
    }

    function test_Deposit() external {
        expectEmit();
        emit Deposit(address(altETHx), address(this), 100);
        ethxWrapper.deposit(address(altETHx), 100);

        assertEq(ethxWrapper.balanceOf(address(this)), 100, "Balance is not set");
        assertEq(altETHx.balanceOf(address(this)), 0, "Balance is not set");
    }

    function test_DepositTo() external {
        expectEmit();
        emit Deposit(address(altETHx), address(this), 100);
        ethxWrapper.depositTo(address(altETHx), address(this), 100);

        assertEq(ethxWrapper.balanceOf(address(this)), 100, "Balance is not set");
        assertEq(altETHx.balanceOf(address(this)), 0, "Balance is not set");
    }
}

contract ETHxTokenWrapperWithdraw is ETHxTokenWrapperSetUpTest {
    function setUp() public override {
        super.setUp();
        altETHx.mint(address(this), 100);
        altETHx.approve(address(ethxWrapper), 100);
        ethxWrapper.deposit(address(altETHx), 100);
    }

    function test_RevertWithdrawWhenTokenIsNotAllowed() external {
        address falseToken = address(0x1234);
        vm.expectRevert();
        ethxWrapper.withdraw(address(falseToken), 100);
    }

    function test_Withdraw() external {
        expectEmit();
        emit Withdraw(address(altETHx), address(this), 100);
        ethxWrapper.withdraw(address(altETHx), 100);

        assertEq(ethxWrapper.balanceOf(address(this)), 0, "Balance is not set");
        assertEq(altETHx.balanceOf(address(this)), 100, "Balance is not set");
    }

    function test_WithdrawTo() external {
        expectEmit();
        emit Withdraw(address(altETHx), address(this), 100);
        ethxWrapper.withdrawTo(address(altETHx), address(this), 100);

        assertEq(ethxWrapper.balanceOf(address(this)), 0, "Balance is not set");
        assertEq(altETHx.balanceOf(address(this)), 100, "Balance is not set");
    }
}

contract ethxWrapperAdminAccessControlFunctions is ETHxTokenWrapperSetUpTest {
    address public falseAdmin = address(0x1);

    function setUp() public override {
        super.setUp();
    }

    function test_DepositBridgerAssets_reverts_WhenNotBridger() external {
        address asset = address(altETHx);
        altETHx.mint(address(this), 100);
        altETHx.approve(address(ethxWrapper), 100);

        vm.startPrank(falseAdmin);
        vm.expectRevert(
            "AccessControl: account 0x0000000000000000000000000000000000000001 is missing role 0xc809a7fd521f10cdc3c068621a1c61d5fd9bb3f1502a773e53811bc248d919a8"
        );
        ethxWrapper.depositBridgerAssets(asset, 100);
        vm.stopPrank();
    }

    // fuzzing test
    function test_DepositBridgerAssets(uint256 amountToDeposit) external {
        address asset = address(altETHx);
        // balance of free floating ethxWrapper needs to be larger than ethxWrapper contract balance of asset
        // 1. mint more rsETH wrapper tokens
        vm.startPrank(admin);
        ethxWrapper.grantRole(ethxWrapper.MINTER_ROLE(), admin);

        address randomAddress = address(0x1234);
        ethxWrapper.mint(randomAddress, amountToDeposit);
        vm.stopPrank();

        // 2. mint the asset to the ethxWrapper contract
        altETHx.mint(manager, amountToDeposit);

        vm.startPrank(manager); // it has also bridger role
        // max amount able to deposit is the amount minted to the ethxWrapper contract is the same as the amount minted
        // to the ethxWrapper contract
        uint256 maxAmountToDeposit = ethxWrapper.maxAmountToDepositBridgerAsset(asset);
        assertEq(maxAmountToDeposit, amountToDeposit, "Max amount to deposit is not correct");
        // manager approves ethxWrapper to spend amountToDeposit tokens
        altETHx.approve(address(ethxWrapper), amountToDeposit);

        expectEmit();
        emit BridgerDeposited(asset, amountToDeposit);
        ethxWrapper.depositBridgerAssets(asset, amountToDeposit);

        vm.stopPrank();

        assertEq(altETHx.balanceOf(address(ethxWrapper)), amountToDeposit, "ethxWrapper did not receive the tokens");
    }

    function test_RemoveAllowedToken() external {
        address altETHxAllowedToken = address(altETHx);

        assertTrue(ethxWrapper.allowedTokens(altETHxAllowedToken), "Token is not allowed");

        vm.startPrank(falseAdmin);
        vm.expectRevert(
            "AccessControl: account 0x0000000000000000000000000000000000000001 is missing role 0x0000000000000000000000000000000000000000000000000000000000000000"
        );
        ethxWrapper.removeAllowedToken(altETHxAllowedToken);
        vm.stopPrank();

        vm.startPrank(admin);
        ethxWrapper.removeAllowedToken(altETHxAllowedToken);
        assertTrue(!ethxWrapper.allowedTokens(altETHxAllowedToken), "Token is allowed");
        vm.stopPrank();
    }
}

contract AltETHx is ERC20Upgradeable {
    function mint(address _to, uint256 _amount) external {
        _mint(_to, _amount);
    }
}
