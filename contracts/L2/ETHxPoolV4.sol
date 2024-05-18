// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.22;

import { ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// solhint-disable-next-line max-line-length
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import { IERC20Minter } from "../IERC20Minter.sol";
import { IRateOracle } from "../oracle/IRateOracle.sol";

/**
 * @notice ETHxPoolV4 is a contract that allows users to swap ERC-20 tokens for ETHx.
 * A rate provider must be set to provide the rate of wETHx denominated in the other token.
 * @dev This contract is upgradable
 */
contract ETHxPoolV4 is ERC20Upgradeable, AccessControlUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;

    bytes32 public constant BRIDGER_ROLE = keccak256("BRIDGER_ROLE");
    uint256 public constant ETHX_BASE_RATE = 1e18;

    error ZeroAmount();
    error ZeroAddress();
    error InvalidBps(uint256 bps);
    error InvalidOracle(address token, address oracle);
    error TokenAlreadyAdded(address token);
    error TokenNotSupported(address token);

    event SwapOccurred(address indexed user, uint256 ethxAmount, uint256 fee, string referralId);
    event FeesWithdrawn(uint256 feeEarned, address token);
    event AssetsMovedForBridging(uint256 tokenBalanceLessFees, address token);
    event FeeBpsSet(address token, uint256 feeBps);
    event OracleSet(address token, address oracle);

    IERC20Minter public wETHx;

    mapping(address token => uint256 feeBps) public feeBpsForToken;
    mapping(address token => uint256 feeEarned) public feeEarnedForToken;
    mapping(address token => address oracle) public tokenRateOracle;

    address[] public supportedTokenList;

    // reserved for oracle and native OKB implementation
    uint256[10] private _reserved;

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

    modifier requireSupportedToken(address _token) {
        if (tokenRateOracle[_token] == address(0)) {
            revert TokenNotSupported(_token);
        }
        _;
    }

    modifier requireValidBps(uint256 _bps) {
        if (_bps > 10_000) {
            revert InvalidBps(_bps);
        }
        _;
    }

    /// @dev Initialize the contract
    /// @param admin The admin address
    /// @param bridger The bridger address
    /// @param _wETHx The ETHx token address
    function initialize(
        address admin,
        address bridger,
        address _wETHx
    )
        public
        initializer
        requireNonZeroAddress(_wETHx)
    {
        __ERC20_init("ETHx", "ETHx");
        __AccessControl_init();
        __ReentrancyGuard_init();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(BRIDGER_ROLE, admin);
        _setupRole(BRIDGER_ROLE, bridger);

        wETHx = IERC20Minter(_wETHx);
    }

    /// @dev Gets the rate from the Oracle
    function getRate(address _token) public view requireSupportedToken(_token) returns (uint256) {
        address ethxOracle = tokenRateOracle[_token];
        uint256 currentRate = IRateOracle(ethxOracle).getRate();
        if (currentRate == 0) {
            revert InvalidOracle(_token, ethxOracle);
        }
        return currentRate;
    }

    /// @dev Swaps token for wETHx
    /// @param _token The token to swap
    /// @param _amount The amount of token to swap
    /// @param _referralId The referral id
    function deposit(
        address _token,
        uint256 _amount,
        string memory _referralId
    )
        external
        nonReentrant
        requireSupportedToken(_token)
    {
        if (_amount == 0) revert ZeroAmount();
        IERC20(_token).safeTransferFrom(_msgSender(), address(this), _amount);
        (uint256 ethxAmount, uint256 fee) = viewSwapETHxAmountAndFee(_token, _amount);
        feeEarnedForToken[_token] += fee;
        wETHx.mint(msg.sender, ethxAmount);
        emit SwapOccurred(msg.sender, ethxAmount, fee, _referralId);
    }

    /// @dev view function to get the ETHx amount for a given amount of token
    /// @param _token The token address
    /// @param _amount The amount of token
    /// @return ethxAmount_ The amount of ETHx that will be received
    /// @return fee_ The fee that will be charged
    function viewSwapETHxAmountAndFee(
        address _token,
        uint256 _amount
    )
        public
        view
        requireSupportedToken(_token)
        returns (uint256 ethxAmount_, uint256 fee_)
    {
        uint256 feeBps = feeBpsForToken[_token];
        fee_ = _amount * feeBps / 10_000;
        uint256 amountAfterFee = _amount - fee_;

        // rate of ETHx in token
        uint256 ethxToTokenRate = getRate(_token);

        // Calculate the final ETHx amount
        ethxAmount_ = amountAfterFee * ETHX_BASE_RATE / ethxToTokenRate;
    }

    /*//////////////////////////////////////////////////////////////
                            ACCESS RESTRICTED FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev Withdraws fees earned by the pool
    /// @param _receiver The receiver of the fees
    /// @param _token The token to withdraw fees in
    function withdrawFees(
        address _receiver,
        address _token
    )
        external
        onlyRole(BRIDGER_ROLE)
        requireSupportedToken(_token)
    {
        // withdraw fees in ETH
        uint256 amountToSendInToken = feeEarnedForToken[_token];
        feeEarnedForToken[_token] = 0;
        IERC20(_token).safeTransfer(_receiver, amountToSendInToken);
        emit FeesWithdrawn(amountToSendInToken, _token);
    }

    /// @dev Withdraws assets from the contract for bridging
    /// @param _token The token to withdraw
    function moveAssetsForBridging(address _token) external onlyRole(BRIDGER_ROLE) requireSupportedToken(_token) {
        // withdraw token less fees
        uint256 tokenBalance = IERC20(_token).balanceOf(address(this));
        uint256 tokenBalanceLessFees = tokenBalance - feeEarnedForToken[_token];
        IERC20(_token).safeTransfer(_msgSender(), tokenBalanceLessFees);
        emit AssetsMovedForBridging(tokenBalanceLessFees, _token);
    }

    /// @dev Sets the fee basis points
    /// @param _token The token address
    /// @param _feeBps The fee basis points
    function setFeeBps(address _token, uint256 _feeBps) public onlyRole(DEFAULT_ADMIN_ROLE) requireValidBps(_feeBps) {
        feeBpsForToken[_token] = _feeBps;
        emit FeeBpsSet(_token, _feeBps);
    }

    /// @dev Adds a token to the supported token list
    /// @param _token The token address
    /// @param _oracle The rate oracle address
    /// @param _feeBps The fee basis points
    function addSupportedToken(
        address _token,
        address _oracle,
        uint256 _feeBps
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        requireNonZeroAddress(_token)
        requireNonZeroAddress(_oracle)
    {
        if (tokenRateOracle[_token] != address(0)) revert TokenAlreadyAdded(_token);
        supportedTokenList.push(_token);
        tokenRateOracle[_token] = _oracle;
        setFeeBps(_token, _feeBps);
        emit OracleSet(_token, _oracle);
    }
}
