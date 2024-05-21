// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { ERC20PermitUpgradeable } from
    "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/// @title ETHxTokenWrapper
/// @notice This contract is a wrapper for alternative ETHx tokens in L2 chains for a canonical ETHx token for Stader
/// Labs
/// @dev it is an upgradeable ERC20 token that wraps an alternative ETHx token
/// It also uses the ERC20PermitUpgradeable extension
/// the alt ETHx tokens can be swapped 1:1 for the canonical ETHx token
contract ETHxTokenWrapper is Initializable, AccessControlUpgradeable, ERC20Upgradeable, ERC20PermitUpgradeable {
    using SafeERC20Upgradeable for ERC20Upgradeable;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BRIDGER_ROLE = keccak256("BRIDGER_ROLE");

    /// @dev The address of the alternative ETHx token
    mapping(address allowedToken => bool isAllowed) public allowedTokens;

    error TokenNotAllowed();
    error CannotDeposit();

    event Deposit(address asset, address _sender, uint256 _amount);
    event Withdraw(address asset, address _sender, uint256 _amount);
    event BridgerDeposited(address asset, uint256 _amount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @dev Initialize the contract
    /// @param _admin The address of the admin
    /// @param _bridger The address of the bridger
    /// @param _altETHx An alternative ETHx token
    function initialize(address _admin, address _bridger, address _altETHx) public initializer {
        __ERC20_init("ETHxWrapper", "WETHx");
        __ERC20Permit_init("ETHxWrapper");
        __AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setupRole(BRIDGER_ROLE, _bridger);

        allowedTokens[_altETHx] = true;
    }

    /// @dev Deposit altETHx for WETHx
    /// @param asset The address of the token to deposit
    ///@param _amount The amount of tokens to deposit
    function deposit(address asset, uint256 _amount) external {
        _deposit(asset, msg.sender, _amount);
    }

    /// @dev Deposit altETHx for WETHx to a user
    /// @param asset The address of the token to deposit
    /// @param _to The user to send the XERC20 to
    /// @param _amount The amount of tokens to deposit
    function depositTo(address asset, address _to, uint256 _amount) external {
        _deposit(asset, _to, _amount);
    }

    /// @dev Withdraw altETHx tokens from WETHx
    /// @param asset The address of the token to withdraw
    /// @param _amount The amount of tokens to withdraw
    function withdraw(address asset, uint256 _amount) external {
        _withdraw(asset, msg.sender, _amount);
    }

    /// @dev Withdraw altETHx tokens from WETHx to a user
    /// @param asset The address of the token to withdraw
    /// @param _to The user to withdraw to
    /// @param _amount The amount of tokens to withdraw
    function withdrawTo(address asset, address _to, uint256 _amount) external {
        _withdraw(asset, _to, _amount);
    }

    /// @notice Get the maximum amount of the bridged asset that can be deposited
    /// @param _asset The address of the token to deposit
    /// @return uint256
    function maxAmountToDepositBridgerAsset(address _asset) public view returns (uint256) {
        if (!allowedTokens[_asset]) return 0;

        // get totalSupply of WETHx minted
        uint256 wethxSupply = totalSupply();
        // balance of _asset with the contract
        uint256 balanceOfAssetInWrapper = ERC20Upgradeable(_asset).balanceOf(address(this));

        if (balanceOfAssetInWrapper > wethxSupply) return 0;

        return wethxSupply - balanceOfAssetInWrapper;
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev Withdraw altETHx tokens from WETHx
    /// @param _asset The address of the token to withdraw
    /// @param _to The user to withdraw to
    /// @param _amount The amount of tokens to withdraw
    function _withdraw(address _asset, address _to, uint256 _amount) internal {
        if (!allowedTokens[_asset]) revert TokenNotAllowed();

        _burn(msg.sender, _amount);

        ERC20Upgradeable(_asset).safeTransfer(_to, _amount);

        emit Withdraw(_asset, _to, _amount);
    }

    /// @notice Deposit tokens into the lockbox
    /// @param _asset The address of the token to deposit
    /// @param _to The address to send the XERC20 to
    /// @param _amount The amount of tokens to deposit
    function _deposit(address _asset, address _to, uint256 _amount) internal {
        if (!allowedTokens[_asset]) revert TokenNotAllowed();

        ERC20Upgradeable(_asset).safeTransferFrom(msg.sender, address(this), _amount);

        _mint(_to, _amount);
        emit Deposit(_asset, _to, _amount);
    }

    /*//////////////////////////////////////////////////////////////
                           RESTRICTED ACCESS FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice deposit for when the ETHx is bridged by the bridger from L1
    /// @notice so as to collateralize already minted WETHx
    ///
    /// @param _asset The address of the token to deposit
    /// @param _amount The amount of tokens to deposit
    function depositBridgerAssets(address _asset, uint256 _amount) external onlyRole(BRIDGER_ROLE) {
        if (maxAmountToDepositBridgerAsset(_asset) < _amount) {
            revert CannotDeposit();
        }

        ERC20Upgradeable(_asset).safeTransferFrom(msg.sender, address(this), _amount);

        emit BridgerDeposited(_asset, _amount);
    }

    /// Dont' allow to add other tokens at the moment. Only allow the altETHx token as set in the initialize function

    /// @dev Remove a token from the allowed tokens list
    /// @param _asset The address of the token to remove
    function removeAllowedToken(address _asset) external onlyRole(DEFAULT_ADMIN_ROLE) {
        allowedTokens[_asset] = false;
    }

    /// @dev Mint WETHx tokens
    /// @param _to The address to mint the tokens to
    /// @param _amount The amount of tokens to mint
    function mint(address _to, uint256 _amount) external onlyRole(MINTER_ROLE) {
        _mint(_to, _amount);
    }
}
