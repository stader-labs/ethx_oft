// SPDX_License_Identifier: UNLICENSED
pragma solidity 0.8.22;

import { Test } from "forge-std/Test.sol";

import { ETHxPoolV4 } from "../../contracts/L2/ETHxPoolV4.sol";
import { IRateOracle } from "../../contracts/oracle/IRateOracle.sol";

import { ERC20Mock } from "../mocks/ERC20Mock.sol";

contract ETHxPoolV4Test is Test {
    uint256 private constant ETHX_RATE = 99 gwei;
    uint256 private constant FEE_BPS = 9750;
    address private admin;
    address private bridger;

    address private oracle;
    address private wETHx;
    address private wETH;

    ETHxPoolV4 private eTHxPoolV4;

    function setUp() public {
        vm.clearMockedCalls();
        admin = vm.addr(0x100);
        bridger = vm.addr(0x101);
        address pool = vm.addr(0x1000);

        wETHx = vm.addr(0x1001);
        wETH = vm.addr(0x1002);
        oracle = vm.addr(0x1004);
        mockRateOracle(oracle);
        mockErc20(wETHx, "wETHx");
        mockErc20(wETH, "wETH");

        eTHxPoolV4 = mockETHxPoolV4(pool, admin, bridger, wETHx);
    }

    function testInitialization() public {
        assertEq(address(eTHxPoolV4.wETHx()), wETHx);
        assertTrue(eTHxPoolV4.hasRole(keccak256("BRIDGER_ROLE"), bridger));
        assertTrue(eTHxPoolV4.hasRole(0x0, admin));
    }

    function testInitializeDisabled() public {
        eTHxPoolV4 = new ETHxPoolV4();
        vm.expectRevert("Initializable: contract is already initialized");
        eTHxPoolV4.initialize(vm.addr(0x100), vm.addr(0x101), vm.addr(0x1001));
    }

    function testwETHxNonZeroAddressRequired() public {
        address pool = vm.addr(0x1003);
        mockProxyDeploy(pool);
        eTHxPoolV4 = ETHxPoolV4(pool);
        vm.expectRevert(ETHxPoolV4.ZeroAddress.selector);
        eTHxPoolV4.initialize(vm.addr(0x100), vm.addr(0x101), address(0));
    }

    function testSetFeeBps() public {
        vm.prank(admin);
        eTHxPoolV4.setFeeBps(wETH, FEE_BPS);
        assertEq(eTHxPoolV4.feeBpsForToken(wETH), FEE_BPS);
    }

    function testSetFeeInvalidBps(uint256 feeBps) public {
        vm.assume(feeBps > 10_000);
        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSelector(ETHxPoolV4.InvalidBps.selector, feeBps));
        eTHxPoolV4.setFeeBps(wETH, feeBps);
    }

    function testSetFeeAdminRequired() public {
        address nonAdmin = vm.addr(0x102);
        vm.prank(nonAdmin);
        vm.expectRevert(
            "AccessControl: account 0x85e4e16bd367e4259537269633da9a6aa4cf95a3 is missing role 0x0000000000000000000000000000000000000000000000000000000000000000"
        );
        eTHxPoolV4.setFeeBps(wETH, 10_000);
    }

    function testAddSupportedTokenRequiresAdmin() public {
        address nonAdmin = vm.addr(0x102);
        vm.prank(nonAdmin);
        vm.expectRevert(
            "AccessControl: account 0x85e4e16bd367e4259537269633da9a6aa4cf95a3 is missing role 0x0000000000000000000000000000000000000000000000000000000000000000"
        );
        eTHxPoolV4.addSupportedToken(wETH, oracle, FEE_BPS);
    }

    function testAddSupportedTokenNonZeroTokenRequired() public {
        vm.prank(admin);
        vm.expectRevert(ETHxPoolV4.ZeroAddress.selector);
        eTHxPoolV4.addSupportedToken(address(0), oracle, FEE_BPS);
    }

    function testAddSupportedTokenNonZeroOracleRequired() public {
        vm.prank(admin);
        vm.expectRevert(ETHxPoolV4.ZeroAddress.selector);
        eTHxPoolV4.addSupportedToken(wETH, address(0), FEE_BPS);
    }

    function testAddSupportedTokenValidFeeBpsRequired() public {
        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSelector(ETHxPoolV4.InvalidBps.selector, 10_001));
        eTHxPoolV4.addSupportedToken(wETH, oracle, 10_001);
    }

    function testAddSupportedTokenOneTimeOnly() public {
        vm.startPrank(admin);
        eTHxPoolV4.addSupportedToken(wETH, oracle, FEE_BPS);
        vm.expectRevert(abi.encodeWithSelector(ETHxPoolV4.TokenAlreadyAdded.selector, wETH));
        eTHxPoolV4.addSupportedToken(wETH, oracle, FEE_BPS);
        vm.stopPrank();
    }

    function testAddSupportedToken() public {
        vm.prank(admin);
        eTHxPoolV4.addSupportedToken(wETH, oracle, FEE_BPS);
        assertEq(eTHxPoolV4.tokenRateOracle(wETH), oracle);
        assertEq(eTHxPoolV4.feeBpsForToken(wETH), FEE_BPS);
        assertEq(eTHxPoolV4.supportedTokenList(0), wETH);
    }

    function testGetRateForToken() public {
        vm.prank(admin);
        eTHxPoolV4.addSupportedToken(wETH, oracle, FEE_BPS);
        assertEq(eTHxPoolV4.getRate(wETH), ETHX_RATE);
    }

    function testGetRateRequiresSupportedToken() public {
        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSelector(ETHxPoolV4.TokenNotSupported.selector, wETH));
        eTHxPoolV4.getRate(wETH);
    }

    function testGetRateRequiresValidOracle() public {
        vm.prank(admin);
        eTHxPoolV4.addSupportedToken(wETH, oracle, FEE_BPS);
        vm.mockCall(oracle, abi.encodeWithSelector(IRateOracle.getRate.selector), abi.encode(0));
        vm.expectRevert(abi.encodeWithSelector(ETHxPoolV4.InvalidOracle.selector, wETH, oracle));
        eTHxPoolV4.getRate(wETH);
    }

    function testDepositNotSupportedForToken() public {
        vm.expectRevert(abi.encodeWithSelector(ETHxPoolV4.TokenNotSupported.selector, wETH));
        eTHxPoolV4.deposit(wETH, 1 ether, "referral");
    }

    function testDepositRequiresNonZeroAmount() public {
        vm.prank(admin);
        eTHxPoolV4.addSupportedToken(wETH, oracle, FEE_BPS);
        vm.expectRevert(ETHxPoolV4.ZeroAmount.selector);
        eTHxPoolV4.deposit(wETH, 0, "referral");
    }

    function testSwapwETHForETHx(uint256 ethAmount) public {
        vm.assume(ethAmount > 0.1 ether && ethAmount < 1000 ether);
        address user = vm.addr(0x110);
        vm.prank(admin);
        eTHxPoolV4.addSupportedToken(wETH, oracle, FEE_BPS);
        ERC20Mock(wETH).mint(user, ethAmount);
        vm.startPrank(user);
        ERC20Mock(wETH).approve(address(eTHxPoolV4), ethAmount);
        eTHxPoolV4.deposit(wETH, ethAmount, "referral");
        vm.stopPrank();
        assertEq(ERC20Mock(wETH).balanceOf(user), 0);
        (uint256 _amtLessFee,) = eTHxPoolV4.viewSwapETHxAmountAndFee(wETH, ethAmount);
        assertEq(ERC20Mock(wETHx).balanceOf(user), _amtLessFee);
    }

    function testViewSwapETHxAmountAndFee(uint256 ethAmount) public {
        vm.assume(ethAmount > 0.1 ether && ethAmount < 100 ether);
        vm.prank(admin);
        eTHxPoolV4.addSupportedToken(wETH, oracle, FEE_BPS);
        (uint256 _amt, uint256 _fee) = eTHxPoolV4.viewSwapETHxAmountAndFee(wETH, ethAmount);
        uint256 expectFee = ethAmount * FEE_BPS / 1e4;
        uint256 expectAmt = (ethAmount - expectFee) * 1e18 / ETHX_RATE;
        assertEq(_fee, expectFee);
        assertEq(_amt, expectAmt);
    }

    function testViewSwapETHxAmountAndFeeRequiresSupportedToken() public {
        vm.expectRevert(abi.encodeWithSelector(ETHxPoolV4.TokenNotSupported.selector, wETH));
        eTHxPoolV4.viewSwapETHxAmountAndFee(wETH, 1 ether);
    }

    function testWithdrawFeesForToken(uint256 ethAmount) public {
        vm.assume(ethAmount > 0.1 ether && ethAmount < 100 ether);
        vm.prank(admin);
        eTHxPoolV4.addSupportedToken(wETH, oracle, FEE_BPS);
        address user = vm.addr(0x110);
        ERC20Mock(wETH).mint(user, ethAmount);
        vm.startPrank(user);
        ERC20Mock(wETH).approve(address(eTHxPoolV4), ethAmount);
        eTHxPoolV4.deposit(wETH, ethAmount, "referral");
        vm.stopPrank();
        assertEq(ERC20Mock(wETH).balanceOf(user), 0);
        (, uint256 feeAmnt) = eTHxPoolV4.viewSwapETHxAmountAndFee(wETH, ethAmount);
        address _owner = vm.addr(0x111);
        vm.prank(bridger);
        eTHxPoolV4.withdrawFees(_owner, wETH);
        assertEq(eTHxPoolV4.feeEarnedForToken(wETH), 0);
        assertEq(ERC20Mock(wETH).balanceOf(_owner), feeAmnt);
    }

    function testWithdrawFeesRequiresBridgerRole() public {
        vm.expectRevert(
            "AccessControl: account 0x7fa9385be102ac3eac297483dd6233d62b3e1496 is missing role 0xc809a7fd521f10cdc3c068621a1c61d5fd9bb3f1502a773e53811bc248d919a8"
        );
        eTHxPoolV4.withdrawFees(vm.addr(0x111), wETH);
    }

    function testWithdrawFeesRequiresSupportedToken() public {
        vm.prank(bridger);
        vm.expectRevert(abi.encodeWithSelector(ETHxPoolV4.TokenNotSupported.selector, wETH));
        eTHxPoolV4.withdrawFees(vm.addr(0x111), wETH);
    }

    function testMoveAssetForBridging(uint256 ethAmount) public {
        vm.assume(ethAmount > 0.1 ether && ethAmount < 100 ether);
        vm.prank(admin);
        eTHxPoolV4.addSupportedToken(wETH, oracle, FEE_BPS);
        address user = vm.addr(0x110);
        ERC20Mock(wETH).mint(user, ethAmount);
        vm.startPrank(user);
        ERC20Mock(wETH).approve(address(eTHxPoolV4), ethAmount);
        eTHxPoolV4.deposit(wETH, ethAmount, "referral");
        vm.stopPrank();
        uint256 tokenBalance = ERC20Mock(wETH).balanceOf(address(eTHxPoolV4));
        uint256 feeEarned = eTHxPoolV4.feeEarnedForToken(wETH);
        vm.prank(bridger);
        eTHxPoolV4.moveAssetsForBridging(wETH);
        assertEq(ERC20Mock(wETH).balanceOf(bridger), tokenBalance - feeEarned);
    }

    function mockProxyDeploy(address ethxPool) private {
        ETHxPoolV4 implementation = new ETHxPoolV4();
        bytes memory code = address(implementation).code;
        vm.etch(ethxPool, code);
    }

    function mockRateOracle(address _oracle) private returns (IRateOracle mock_) {
        IRateOracle mock = IRateOracle(_oracle);
        vm.mockCall(_oracle, abi.encodeWithSelector(IRateOracle.getRate.selector), abi.encode(ETHX_RATE));
        return mock;
    }

    function mockErc20(address ethxMock, string memory name) private {
        ERC20Mock implementation = new ERC20Mock(name, name);
        bytes memory code = address(implementation).code;
        vm.etch(ethxMock, code);
    }

    function mockETHxPoolV4(
        address ethxPool,
        address _admin,
        address _bridger,
        address _wETHx
    )
        private
        returns (ETHxPoolV4 mock_)
    {
        mockProxyDeploy(ethxPool);
        ETHxPoolV4 mock = ETHxPoolV4(ethxPool);
        mock.initialize(_admin, _bridger, _wETHx);
        return mock;
    }
}
