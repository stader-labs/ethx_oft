// SPDX_License_identifier: UNLICENSED
pragma solidity ^0.8.22;

import {
    MessagingFee,
    MessagingReceipt
} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";

import { ETHx_OFTAdapter } from "../../contracts/ETHx_OFTAdapter.sol";

contract ETHx_OFTAdapterMock is ETHx_OFTAdapter {
    constructor(
        address _token,
        address _lzEndpoint,
        address _delegate
    )
        ETHx_OFTAdapter(_token, _lzEndpoint, _delegate)
    { }

    function send(
        uint32 _dstEid,
        bytes memory _message,
        bytes memory _options,
        MessagingFee memory _fee,
        address _refundAddress
    )
        public
        virtual
        returns (MessagingReceipt memory receipt)
    {
        return super._lzSend(_dstEid, _message, _options, _fee, _refundAddress);
    }
}
