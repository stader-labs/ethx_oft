// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.22;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import { IERC20Burnable } from "./IERC20Burnable.sol";

/**
 * @title Stader token Contract for L2s
 * @author Stader Labs
 * @notice The ERC20 contract for the Stader token
 */
contract Stader is Initializable, ERC20Upgradeable, PausableUpgradeable, AccessControlUpgradeable, IERC20Burnable {
    error ZeroAddress();

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

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

    function initialize(address _admin) external initializer requireNonZeroAddress(_admin) {
        __ERC20_init("Stader", "SD");
        __Pausable_init();
        __AccessControl_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    /**
     * @notice Mints SD token when called by an authorized caller
     * @param to the account to mint to
     * @param amount the amount of SD token to mint
     */
    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) whenNotPaused {
        _mint(to, amount);
    }

    /**
     * @notice Burns SD token when called by an authorized caller
     * @param account the account to burn from
     * @param amount the amount of SD token to burn
     */
    function burnFrom(address account, uint256 amount) external onlyRole(BURNER_ROLE) whenNotPaused {
        _burn(account, amount);
    }

    /**
     * used by certain bridge contracts to burn tokens
     * @dev the caller must have the BURNER_ROLE as well
     * as the number of requested tokens to burn
     * @param amount the amount of SD token to burn
     */
    function burn(uint256 amount) external onlyRole(BURNER_ROLE) whenNotPaused {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Triggers stopped state.
     * Contract must not be paused.
     */
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @dev Returns to normal state.
     * Contract must be paused
     */
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }
}
