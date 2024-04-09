// SPDX-License-Identifier: GNU-3.0-or-later
pragma solidity 0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IPausable } from "./IPausable.sol";

/**
 * @title IERC20Burnable Interface
 * @notice Interface for ERC20 burnable token
 */
interface IERC20Burnable is IERC20, IPausable {
    /**
     * @notice Burns a specific amount of the caller's tokens
     * @param amount the amount of tokens to burn
     */
    function burnFrom(address account, uint256 amount) external;

    /**
     * @notice Mints a specific amount of tokens to an address
     * @param to the address to mint to
     * @param amount the amount of tokens to mint
     */
    function mint(address to, uint256 amount) external;
}
