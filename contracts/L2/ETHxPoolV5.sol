// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title ETHxPool Contract
 * @author Stader Labs
 * @notice This contract is responsible for the swap of ETHx; the user must deposit ETH in order to receive ETHx in
 * return.
 */
interface AggregatorV3Interface {
    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

contract ETHxPoolV5 is AccessControlUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;

    /// @notice Role hash of BRIDGER
    bytes32 public constant BRIDGER_ROLE = keccak256("BRIDGER_ROLE");
    /// @notice Base rate of ETHx/ETH
    uint256 public constant ETHX_BASE_RATE = 1e18;
    /// @notice Address of ETHx token
    IERC20 public ETHx;
    /// @notice Basis points for fees
    uint256 public feeBps;
    /// @notice Total fees earned in swap
    uint256 public feeEarnedInETH;
    /// @notice Address of the ETHx/ETH oracle
    address public ethxOracle;

    /// @notice Emitted when swap occured successfully
    event SwapOccurred(address indexed user, uint256 ETHxAmount, uint256 fee, string referralId);
    /// @notice Emitted when accumulated fees is withdrawn
    event FeesWithdrawn(uint256 feeEarnedInETH);
    /// @notice Emitted when deposited ETH is withdrawn
    event AssetsMovedForBridging(uint256 ethBalanceMinusFees);
    /// @notice Emitted when basis fee is updated
    event FeeBpsSet(uint256 feeBps);
    /// @notice Emitted when oracle address is updated
    event OracleSet(address indexed oracle);

    /// @dev Thrown when input is zero address
    error ZeroAddress();
    /// @dev Thrown when input is invalid amount
    error InvalidAmount();
    /// @dev Thrown when input is invalid basis fee
    error InvalidBps();
    /// @dev Thrown when transfer is failed
    error TransferFailed();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @dev Initialize the contract
    /// @param _admin The admin address
    /// @param _bridger The bridger address
    /// @param _ethx The ETHx token address
    /// @param _feeBps The fee basis points
    /// @param _ethxOracle The ethxOracle address
    function initialize(
        address _admin,
        address _bridger,
        address _ethx,
        uint256 _feeBps,
        address _ethxOracle
    )
        public
        initializer
    {
        _checkNonZeroAddress(_ethx);
        _checkNonZeroAddress(_ethxOracle);

        __AccessControl_init();
        __ReentrancyGuard_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _setupRole(BRIDGER_ROLE, _bridger);

        ETHx = IERC20(_ethx);
        feeBps = _feeBps;
        ethxOracle = _ethxOracle;
    }

    /// @dev Swaps ETH for ETHx
    /// @param _referralId The referral id
    function deposit(string memory _referralId) external payable nonReentrant {
        uint256 amount = msg.value;

        if (amount == 0) revert InvalidAmount();

        (uint256 ethxAmount, uint256 fee) = viewSwapETHxAmountAndFee(amount);

        feeEarnedInETH += fee;

        ETHx.safeTransfer(msg.sender, ethxAmount);

        emit SwapOccurred(msg.sender, ethxAmount, fee, _referralId);
    }

    /// @dev view function to get the ETHx amount for a given amount of ETH
    /// @param _amount The amount of ETH
    /// @return ethxAmount The amount of ETHx that will be received
    /// @return fee The fee that will be charged
    function viewSwapETHxAmountAndFee(uint256 _amount) public view returns (uint256 ethxAmount, uint256 fee) {
        fee = _amount * feeBps / 10_000;
        uint256 amountAfterFee = _amount - fee;

        (, int256 ethxToEthRate,,,) = AggregatorV3Interface(ethxOracle).latestRoundData();

        // Calculate the final ETHx amount
        ethxAmount = amountAfterFee * ETHX_BASE_RATE / uint256(ethxToEthRate);
    }

    /*//////////////////////////////////////////////////////////////
                            ACCESS RESTRICTED FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev Withdraws fees earned by the pool
    function withdrawFees(address _receiver) external onlyRole(BRIDGER_ROLE) {
        // withdraw fees in ETH
        uint256 amountToSendInETH = feeEarnedInETH;
        feeEarnedInETH = 0;
        (bool success,) = payable(_receiver).call{ value: amountToSendInETH }("");
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
        if (_feeBps > 10_000) revert InvalidBps();

        feeBps = _feeBps;

        emit FeeBpsSet(_feeBps);
    }

    /// @dev Sets the ethxOracle address
    /// @param _ethxOracle The ethxOracle address
    function setETHXOracle(address _ethxOracle) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _checkNonZeroAddress(_ethxOracle);
        ethxOracle = _ethxOracle;
        emit OracleSet(_ethxOracle);
    }

    function _checkNonZeroAddress(address _addr) private pure {
        if (_addr == address(0)) {
            revert ZeroAddress();
        }
    }
}
