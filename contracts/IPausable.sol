// SPDX-License-Identifier: GNU-3.0-or-later
pragma solidity 0.8.22;

/**
 * @title IPausable Interface
 * @notice Interface for pausable token contract
 */
interface IPausable {
    /**
     * @notice Pauses the token
     */
    function pause() external;

    /**
     * @notice Unpauses the token
     */
    function unpause() external;
}
