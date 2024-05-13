// SPDX_License_Identifier: UNLICENSED
pragma solidity 0.8.22;

import { Test } from "forge-std/Test.sol";

import { IETHxStakePoolManager, IStaderConfig, ETHxPriceOracle } from "../../contracts/oracle/ETHxPriceOracle.sol";

contract ETHxPriceOracleTest is Test {
    uint256 private constant _INITIAL_EXCHANGE_RATE = 100;
    uint256 private constant _POOL_MANAGER = 0x1001;
    uint256 private constant _STADER_CONFIG = 0x1002;

    ETHxPriceOracle private ethXPriceOracle;
    address private ethx;

    function setUp() public {
        vm.clearMockedCalls();
        address proxy = vm.addr(0x101);
        ethx = vm.addr(0x102);
        ethXPriceOracle = ETHxPriceOracle(proxyDeploy(proxy));
    }

    function testInitializerDisabled() public {
        ethXPriceOracle = new ETHxPriceOracle();
        vm.expectRevert("Initializable: contract is already initialized");
        ethXPriceOracle.initialize(address(1));
    }

    function testInitialize() public {
        address poolManagerAddress = vm.addr(_POOL_MANAGER);
        ethXPriceOracle.initialize(poolManagerAddress);
        assertEq(ethXPriceOracle.stakePoolManager(), poolManagerAddress);
    }

    function testDuplicateInitialize() public {
        address poolManagerAddress = vm.addr(_POOL_MANAGER);
        ethXPriceOracle.initialize(poolManagerAddress);
        vm.expectRevert("Initializable: contract is already initialized");
        ethXPriceOracle.initialize(poolManagerAddress);
    }

    function testInitializeZero() public {
        vm.expectRevert(abi.encodeWithSelector(ETHxPriceOracle.NonZeroAddressRequired.selector));
        ethXPriceOracle.initialize(address(0));
    }

    function testGetAssetPrice() public {
        address config = vm.addr(_STADER_CONFIG);
        mockConfig(config);
        address poolManager = vm.addr(_POOL_MANAGER);
        mockETHXStakePoolManager(poolManager);
        ethXPriceOracle.initialize(poolManager);
        assertEq(ethXPriceOracle.getAssetPrice(ethx), _INITIAL_EXCHANGE_RATE);
    }

    function testRevertUnknownAsset() public {
        address config = vm.addr(_STADER_CONFIG);
        mockConfig(config);
        address poolManager = vm.addr(_POOL_MANAGER);
        mockETHXStakePoolManager(poolManager);
        ethXPriceOracle.initialize(poolManager);
        vm.expectRevert(abi.encodeWithSelector(ETHxPriceOracle.InvalidAsset.selector));
        ethXPriceOracle.getAssetPrice(address(1));
    }

    function proxyDeploy(address _proxyAddress) public returns (address proxyAddress) {
        ETHxPriceOracle implementation = new ETHxPriceOracle();
        bytes memory code = address(implementation).code;
        vm.etch(_proxyAddress, code);
        return _proxyAddress;
    }

    function mockConfig(address _configAddress) public returns (address configAddress) {
        vm.mockCall(_configAddress, abi.encodeWithSelector(IStaderConfig.getETHxToken.selector), abi.encode(ethx));
        return _configAddress;
    }

    function mockETHXStakePoolManager(address _poolManager) public returns (address poolManager) {
        vm.mockCall(
            _poolManager,
            abi.encodeWithSelector(IETHxStakePoolManager.getExchangeRate.selector),
            abi.encode(_INITIAL_EXCHANGE_RATE)
        );
        vm.mockCall(
            _poolManager,
            abi.encodeWithSelector(IETHxStakePoolManager.staderConfig.selector),
            abi.encode(vm.addr(_STADER_CONFIG))
        );
        return _poolManager;
    }
}
