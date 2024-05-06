// SPDX-License-Identifier: GNU-3.0-or-later
pragma solidity 0.8.22;

import { OFTAdapter } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFTAdapter.sol";
import {
    MessagingFee,
    MessagingReceipt
} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";

import { IPausable } from "./IPausable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import { ComposedPauser } from "./ComposedPauser.sol";

/// @dev contract used for Origin chain where the token is already deployed
// solhint-disable-next-line contract-name-camelcase
contract ETHx_OFTAdapter is OFTAdapter, IPausable {
    error AdapterPaused();

    ComposedPauser private _composedPauser;

    constructor(address _token, address _lzEndpoint, address _delegate) OFTAdapter(_token, _lzEndpoint, _delegate) {
        transferOwnership(_delegate);
        _composedPauser = new ComposedPauser();
    }

    /**
     * @notice Returns whether the adapter is paused
     * @return true if the adapter is paused, false otherwise
     */
    function paused() public view returns (bool) {
        return PausableUpgradeable(token()).paused() || _composedPauser.paused();
    }

    /**
     * @notice Pauses the adapter
     */
    function pause() external onlyOwner {
        _composedPauser.pause();
    }

    /**
     * @notice Unpauses the adapter
     */
    function unpause() external onlyOwner {
        _composedPauser.unpause();
    }

    /*
     * @notice Send a message to the destination endpoint or
     * error if paused
     */
    function _lzSend(
        uint32 _dstEid,
        bytes memory _message,
        bytes memory _options,
        MessagingFee memory _fee,
        address _refundAddress
    )
        internal
        virtual
        override
        returns (MessagingReceipt memory receipt)
    {
        if (paused()) revert AdapterPaused();
        return super._lzSend(_dstEid, _message, _options, _fee, _refundAddress);
    }
}
