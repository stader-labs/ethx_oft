// SPDX-License-Identifier: GNU-3.0-or-later
pragma solidity 0.8.22;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { PauserCodec } from "./PauserCodec.sol";

/**
 * @title ComposedPauser
 * provides support for horizontal composition of pausable contracts
 */
contract ComposedPauser is Ownable {
    error NotPausedOrUnpaused();

    bool public isPaused;

    constructor() {
        isPaused = false;
    }

    /**
     * @notice Returns whether the contract is paused
     * @return true if the contract is paused, false otherwise
     */
    function paused() public view returns (bool) {
        return isPaused;
    }

    /**
     * @notice Pauses the contract
     */
    function pause() public onlyOwner {
        isPaused = true;
    }

    /**
     * @notice Unpauses the contract
     */
    function unpause() public onlyOwner {
        isPaused = false;
    }

    /**
     * @notice decodes a paused message
     */
    function decompose(bytes memory _data) external returns (uint8) {
        uint8 ptype = PauserCodec.pauseType(_data);
        if (ptype == PauserCodec.PAUSED) {
            pause();
            return ptype;
        } else if (ptype == PauserCodec.UNPAUSED) {
            unpause();
            return ptype;
        }
        revert NotPausedOrUnpaused();
    }
}
