// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

import { ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
// solhint-disable-next-line max-line-length
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import { IERC20Minter } from "../IERC20Minter.sol";
import { IRateOracle } from "../oracle/IRateOracle.sol";

contract ETHxPoolV2 is ERC20Upgradeable, AccessControlUpgradeable, ReentrancyGuardUpgradeable {
    bytes32 public constant BRIDGER_ROLE = keccak256("BRIDGER_ROLE");
    uint256 public constant ETHX_BASE_RATE = 1e18;

    error InvalidAmount();
    error TransferFailed();
    error ZeroAddress();

    event SwapOccurred(address indexed user, uint256 ethxAmount, uint256 fee, string referralId);
    event FeesWithdrawn(uint256 feeEarnedInETH);
    event AssetsMovedForBridging(uint256 ethBalanceMinusFees);
    event FeeBpsSet(uint256 feeBps);
    event OracleSet(address oracle);

    IERC20Minter public wETHx;

    uint256 public feeBps; // Basis points for fees
    uint256 public feeEarnedInETH;
    address public ethxOracle;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    modifier requireNonZeroAddress(address _addr) {
        if (_addr == address(0)) {
            revert ZeroAddress();
        }
        _;
    }

    /// @dev Initialize the contract
    /// @param admin The admin address
    /// @param bridger The bridger address
    /// @param _wETHx The ETHx token address
    /// @param _feeBps The fee basis points
    /// @param _ethxOracle The ethxOracle address
    function initialize(
        address admin,
        address bridger,
        address _wETHx,
        uint256 _feeBps,
        address _ethxOracle
    )
        public
        initializer
        requireNonZeroAddress(_wETHx)
        requireNonZeroAddress(_ethxOracle)
    {
        __ERC20_init("ETHx", "ETHx");
        __AccessControl_init();
        __ReentrancyGuard_init();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(BRIDGER_ROLE, admin);
        _setupRole(BRIDGER_ROLE, bridger);

        wETHx = IERC20Minter(_wETHx);
        feeBps = _feeBps;
        ethxOracle = _ethxOracle;
    }

    /// @dev Gets the rate from the ethxOracle
    function getRate() public view returns (uint256) {
        return IRateOracle(ethxOracle).getRate();
    }

    /// @dev Swaps ETH for ETHx
    /// @param referralId The referral id
    function deposit(string memory referralId) external payable nonReentrant {
        uint256 amount = msg.value;

        if (amount == 0) revert InvalidAmount();

        (uint256 ethxAmount, uint256 fee) = viewSwapETHxAmountAndFee(amount);

        feeEarnedInETH += fee;

        wETHx.mint(msg.sender, ethxAmount);

        emit SwapOccurred(msg.sender, ethxAmount, fee, referralId);
    }

    /// @dev view function to get the ETHx amount for a given amount of ETH
    /// @param amount The amount of ETH
    /// @return ethxAmount The amount of ETHx that will be received
    /// @return fee The fee that will be charged
    function viewSwapETHxAmountAndFee(uint256 amount) public view returns (uint256 ethxAmount, uint256 fee) {
        fee = amount * feeBps / 10_000;
        uint256 amountAfterFee = amount - fee;

        // rate of ETHx in ETH
        uint256 ethxToETHrate = getRate();

        // Calculate the final ETHx amount
        ethxAmount = amountAfterFee * ETHX_BASE_RATE / ethxToETHrate;
    }

    /*//////////////////////////////////////////////////////////////
                            ACCESS RESTRICTED FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev Withdraws fees earned by the pool
    function withdrawFees(address receiver) external onlyRole(BRIDGER_ROLE) {
        // withdraw fees in ETH
        uint256 amountToSendInETH = feeEarnedInETH;
        feeEarnedInETH = 0;
        (bool success,) = payable(receiver).call{ value: amountToSendInETH }("");
        if (!success) revert TransferFailed();

        emit FeesWithdrawn(amountToSendInETH);
    }

    /// @dev Withdraws assets from the contract for bridging
    function moveAssetsForBridging() external onlyRole(BRIDGER_ROLE) {
        // withdraw ETH - fees
        uint256 ethBalanceMinusFees = address(this).balance - feeEarnedInETH;

        (bool success,) = msg.sender.call{ value: ethBalanceMinusFees }("");
        if (!success) revert TransferFailed();

        emit AssetsMovedForBridging(ethBalanceMinusFees);
    }

    /// @dev Sets the fee basis points
    /// @param _feeBps The fee basis points
    function setFeeBps(uint256 _feeBps) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_feeBps > 10_000) revert InvalidAmount();

        feeBps = _feeBps;

        emit FeeBpsSet(_feeBps);
    }

    /// @dev Sets the ethxOracle address
    /// @param _ethxOracle The ethxOracle address
    function setETHxOracle(address _ethxOracle)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        requireNonZeroAddress(_ethxOracle)
    {
        ethxOracle = _ethxOracle;
        emit OracleSet(_ethxOracle);
    }
}
