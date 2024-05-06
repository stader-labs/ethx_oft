// SPDX-License-Identifier: GNU-3.0-or-later
pragma solidity 0.8.22;

/**
 * @title PauserCodec
 * provides encoding and decoding for pauser contract
 */
library PauserCodec {
    error InvalidMessageData();

    uint8 public constant PAUSED = 1;
    uint8 public constant UNPAUSED = 2;

    /**
     * @notice Encodes a paused message
     */
    function encodePaused() internal pure returns (bytes memory) {
        return abi.encodePacked(PAUSED);
    }

    /**
     * @notice Encodes an unpaused message
     */
    function encodeUnpaused() internal pure returns (bytes memory) {
        return abi.encodePacked(UNPAUSED);
    }

    /**
     * @notice Decodes a paused message
     */
    function pauseType(bytes memory _data) internal pure returns (uint8) {
        uint8 paused = uint8(bytes1(_data));
        if (paused != PAUSED && paused != UNPAUSED) {
            revert InvalidMessageData();
        }
        return paused;
    }
}
