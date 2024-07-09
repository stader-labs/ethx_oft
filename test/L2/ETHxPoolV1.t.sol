// SPDX_License_Identifier: UNLICENSED
pragma solidity 0.8.22;

import { Test } from "forge-std/Test.sol";
import { ETHxPoolV1 } from "../../contracts/L2/ETHxPoolV1.sol";
import { AggregatorV3Interface } from "../../contracts/L2/ETHxPoolV1.sol";
import { ERC20Mock } from "../mocks/ERC20Mock.sol";

contract ETHxPoolV1Test is Test {
    uint256 private constant ETHX_RATE = 1 ether;
    uint256 private constant FEE_BPS = 1000;
    address private admin;
    address private bridger;

    address private oracle;
    address private ETHx;

    ETHxPoolV1 private eTHxPoolV1;

    function setUp() public {
        vm.clearMockedCalls();
        admin = vm.addr(0x100);
        bridger = vm.addr(0x101);
        address pool = vm.addr(0x1000);

        ETHx = vm.addr(0x1001);
        oracle = vm.addr(0x1004);
        mockRateOracle(oracle);
        mockErc20(ETHx, "ETHx");

        eTHxPoolV1 = mockETHxPoolV1(pool, admin, bridger, ETHx, FEE_BPS, oracle);
    }

    function testInitialization() public {
        assertEq(address(eTHxPoolV1.ETHx()), ETHx);
        assertTrue(eTHxPoolV1.hasRole(keccak256("BRIDGER_ROLE"), bridger));
        assertTrue(eTHxPoolV1.hasRole(0x0, admin));
    }

    function testInitializeDisabled() public {
        eTHxPoolV1 = new ETHxPoolV1();
        vm.expectRevert("Initializable: contract is already initialized");
        eTHxPoolV1.initialize(vm.addr(0x100), vm.addr(0x101), vm.addr(0x102), 9000, vm.addr(0x1001));
    }

    function testETHxNonZeroAddressRequired() public {
        address pool = vm.addr(0x1003);
        mockProxyDeploy(pool);
        eTHxPoolV1 = ETHxPoolV1(pool);
        vm.expectRevert(ETHxPoolV1.ZeroAddress.selector);
        eTHxPoolV1.initialize(vm.addr(0x100), vm.addr(0x101), vm.addr(0x102), 9000, address(0));
    }

    function testSetFeeBps() public {
        vm.prank(admin);
        eTHxPoolV1.setFeeBps(FEE_BPS);
        assertEq(eTHxPoolV1.feeBps(), FEE_BPS);
    }

    function testSetFeeInvalidBps(uint256 feeBps) public {
        vm.assume(feeBps > 10_000);
        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSelector(ETHxPoolV1.InvalidBps.selector));
        eTHxPoolV1.setFeeBps(feeBps);
    }

    function testSetFeeAdminRequired() public {
        address nonAdmin = vm.addr(0x102);
        vm.prank(nonAdmin);
        vm.expectRevert(
            "AccessControl: account 0x85e4e16bd367e4259537269633da9a6aa4cf95a3 is missing role 0x0000000000000000000000000000000000000000000000000000000000000000"
        );
        eTHxPoolV1.setFeeBps(10_000);
    }

    function testOracleAdminRequired() public {
        address nonAdmin = vm.addr(0x102);
        address oracle_ = vm.addr(0x103);
        vm.prank(nonAdmin);
        vm.expectRevert(
            "AccessControl: account 0x85e4e16bd367e4259537269633da9a6aa4cf95a3 is missing role 0x0000000000000000000000000000000000000000000000000000000000000000"
        );
        eTHxPoolV1.setETHXOracle(oracle_);
    }

    function testOracleZeroAddressNotAllowed() public {
        address oracle_ = address(0);
        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSelector(ETHxPoolV1.ZeroAddress.selector));
        eTHxPoolV1.setETHXOracle(oracle_);
    }

    function testOracleSetAddress() public {
        vm.prank(admin);
        eTHxPoolV1.setETHXOracle(oracle);
        assertEq(eTHxPoolV1.ethxOracle(), oracle);
    }

    function testDepositRequiresNonZeroAmount() public {
        vm.prank(admin);
        vm.expectRevert(ETHxPoolV1.InvalidAmount.selector);
        eTHxPoolV1.swapETHToETHx{ value: 0 }("referral");
    }

    function testSwapETHForETHx(uint256 ethAmount) public {
        vm.assume(ethAmount > 0.1 ether && ethAmount < 100 ether);
        address user = vm.addr(0x110);
        vm.deal(user, ethAmount);
        vm.prank(admin);
        ERC20Mock(ETHx).mint(address(eTHxPoolV1), ethAmount);
        vm.prank(user);
        eTHxPoolV1.swapETHToETHx{ value: ethAmount }("referral");
        uint256 expectedBalance = ethAmount - (ethAmount * FEE_BPS / 10_000);
        assertEq(ERC20Mock(ETHx).balanceOf(user), expectedBalance);
        (uint256 _amtLessFee,) = eTHxPoolV1.viewSwapETHxAmountAndFee(ethAmount);
        assertEq(ERC20Mock(ETHx).balanceOf(user), _amtLessFee);
    }

    function testViewSwapETHxAmountAndFee(uint256 ethAmount) public {
        vm.assume(ethAmount > 0.1 ether && ethAmount < 100 ether);
        vm.prank(admin);
        (uint256 _amt, uint256 _fee) = eTHxPoolV1.viewSwapETHxAmountAndFee(ethAmount);
        uint256 expectFee = ethAmount * FEE_BPS / 1e4;
        uint256 expectAmt = (ethAmount - expectFee) * 1e18 / ETHX_RATE;
        assertEq(_fee, expectFee);
        assertEq(_amt, expectAmt);
    }

    function testWithdrawFeesForToken(uint256 ethAmount) public {
        vm.assume(ethAmount > 0.1 ether && ethAmount < 100 ether);
        address user = vm.addr(0x110);
        vm.prank(admin);
        ERC20Mock(ETHx).mint(address(eTHxPoolV1), ethAmount);
        vm.deal(user, ethAmount);
        vm.prank(user);
        eTHxPoolV1.swapETHToETHx{ value: ethAmount }("referral");
        uint256 expectedBalance = ethAmount - (ethAmount * FEE_BPS / 10_000);
        assertEq(ERC20Mock(ETHx).balanceOf(user), expectedBalance);
        (, uint256 feeAmnt) = eTHxPoolV1.viewSwapETHxAmountAndFee(ethAmount);
        address _owner = vm.addr(0x111);
        vm.prank(bridger);
        eTHxPoolV1.withdrawFees(_owner);
        assertEq(_owner.balance, feeAmnt);
    }

    function testWithdrawFeesRequiresBridgerRole() public {
        vm.expectRevert(
            "AccessControl: account 0x7fa9385be102ac3eac297483dd6233d62b3e1496 is missing role 0xc809a7fd521f10cdc3c068621a1c61d5fd9bb3f1502a773e53811bc248d919a8"
        );
        eTHxPoolV1.withdrawFees(vm.addr(0x111));
    }

    function testWithdrawCollectedETH(uint256 ethAmount) public {
        vm.assume(ethAmount > 0.1 ether && ethAmount < 100 ether);
        vm.prank(admin);
        address user = vm.addr(0x110);
        vm.deal(user, ethAmount);
        ERC20Mock(ETHx).mint(address(eTHxPoolV1), ethAmount);
        vm.prank(user);
        eTHxPoolV1.swapETHToETHx{ value: ethAmount }("referral");
        uint256 feeEarned = eTHxPoolV1.feeEarnedInETH();
        vm.prank(admin);
        eTHxPoolV1.withdrawCollectedETH();
        assertEq(admin.balance, ethAmount - feeEarned);
    }

    function testWithdrawETHxRequireAdminRole(uint256 ethxAmount) public {
        vm.expectRevert(
            "AccessControl: account 0x7fa9385be102ac3eac297483dd6233d62b3e1496 is missing role 0x0000000000000000000000000000000000000000000000000000000000000000"
        );
        eTHxPoolV1.withdrawETHx(ethxAmount);
    }

    function testWithdrawETHxInvalidAmount(uint256 ethxAmount) public {
        vm.assume(ethxAmount > 0.1 ether && ethxAmount < 100 ether);
        vm.startPrank(admin);
        ERC20Mock(ETHx).mint(address(eTHxPoolV1), ethxAmount / 10);
        vm.expectRevert(abi.encodeWithSelector(ETHxPoolV1.InvalidAmount.selector));
        eTHxPoolV1.withdrawETHx(ethxAmount);
        vm.stopPrank();
    }

    function testWithdrawETHx(uint256 ethxAmount) public {
        vm.assume(ethxAmount > 0.1 ether && ethxAmount < 100 ether);
        vm.startPrank(admin);
        ERC20Mock(ETHx).mint(address(eTHxPoolV1), ethxAmount);
        eTHxPoolV1.withdrawETHx(ethxAmount);
        assertEq(ERC20Mock(ETHx).balanceOf(admin), ethxAmount);
        vm.stopPrank();
    }

    function mockProxyDeploy(address ethxPool) private {
        ETHxPoolV1 implementation = new ETHxPoolV1();
        bytes memory code = address(implementation).code;
        vm.etch(ethxPool, code);
    }

    function mockRateOracle(address _oracle) private returns (AggregatorV3Interface mock_) {
        AggregatorV3Interface mock = AggregatorV3Interface(_oracle);
        vm.mockCall(
            _oracle,
            abi.encodeWithSelector(AggregatorV3Interface.latestRoundData.selector),
            abi.encode(0, ETHX_RATE, 0, 0, 0)
        );
        return mock;
    }

    function mockErc20(address ethxMock, string memory name) private {
        ERC20Mock implementation = new ERC20Mock(name, name);
        bytes memory code = address(implementation).code;
        vm.etch(ethxMock, code);
    }

    function mockETHxPoolV1(
        address ethxPool,
        address _admin,
        address _bridger,
        address _ETHx,
        uint256 _feeBps,
        address _ethxOracle
    )
        private
        returns (ETHxPoolV1 mock_)
    {
        mockProxyDeploy(ethxPool);
        ETHxPoolV1 mock = ETHxPoolV1(ethxPool);
        mock.initialize(_admin, _bridger, _ETHx, _feeBps, _ethxOracle);
        return mock;
    }
}
