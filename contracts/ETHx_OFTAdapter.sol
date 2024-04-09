// SPDX-License-Identifier: GNU-3.0-or-later
pragma solidity 0.8.22;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { OFTAdapter } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFTAdapter.sol";
import { OptionsBuilder } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OptionsBuilder.sol";
import { MessagingFee } from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";

import { IPausable } from "./IPausable.sol";

/// @dev contract used for Origin chain where the token is already deployed
contract ETHx_OFTAdapter is OFTAdapter {
    constructor(
        address _token,
        address _lzEndpoint,
        address _delegate
    )
        OFTAdapter(_token, _lzEndpoint, _delegate)
        Ownable(_delegate)
    { }

    /**
     * pause the OFT on the destination chain
     * @param _dstEid the destination chain Id
     * @param _lzReceiveGas the amount of gas to send to the LZ endpoint
     */
    function pause(uint32 _dstEid, uint128 _lzReceiveGas) external payable {
        _send(_dstEid, IPausable.pause.selector, _lzReceiveGas);
    }

    /**
     * unpause the OFT on the destination chain
     * @param _dstEid the destination chain Id
     * @param _lzReceiveGas the amount of gas to send to the LZ endpoint
     */
    function unpause(uint32 _dstEid, uint128 _lzReceiveGas) external payable {
        _send(_dstEid, IPausable.unpause.selector, _lzReceiveGas);
    }

    /**
     * @dev send a signature to the LZ endpoint
     * @param _dstEid the destination chain Id
     * @param _signature the signature to send
     * @param _lzReceiveGas the amount of gas to send to the LZ endpoint
     */
    function _send(uint32 _dstEid, bytes4 _signature, uint128 _lzReceiveGas) internal {
        bytes memory options = OptionsBuilder.newOptions();
        options = OptionsBuilder.addExecutorLzReceiveOption(options, _lzReceiveGas, 0);
        bytes memory payload = abi.encode(_signature);
        _lzSend(_dstEid, payload, options, MessagingFee(msg.value, 0), payable(msg.sender));
    }
}
