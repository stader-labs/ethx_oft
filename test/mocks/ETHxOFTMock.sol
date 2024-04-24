// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import { SendParam, Origin } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFTCore.sol";

import { ETHx_OFT } from "../../contracts/ETHx_OFT.sol";

contract ETHxOFTMock is ETHx_OFT {
    constructor(address _ETHx, address _lzEndpoint, address _delegate) ETHx_OFT(_ETHx, _lzEndpoint, _delegate) { }

    function mint(address _to, uint256 _amount) public virtual {
        _mint(_to, _amount);
    }

    // @dev expose internal functions for testing purposes
    function debit(
        uint256 _amountToSendLD,
        uint256 _minAmountToCreditLD,
        uint32 _dstEid
    )
        public
        returns (uint256 amountDebitedLD, uint256 amountToCreditLD)
    {
        return _debit(msg.sender, _amountToSendLD, _minAmountToCreditLD, _dstEid);
    }

    function debitView(
        uint256 _amountToSendLD,
        uint256 _minAmountToCreditLD,
        uint32 _dstEid
    )
        public
        view
        returns (uint256 amountDebitedLD, uint256 amountToCreditLD)
    {
        return _debitView(_amountToSendLD, _minAmountToCreditLD, _dstEid);
    }

    function removeDust(uint256 _amountLD) public view returns (uint256 amountLD) {
        return _removeDust(_amountLD);
    }

    function toLD(uint64 _amountSD) public view returns (uint256 amountLD) {
        return _toLD(_amountSD);
    }

    function toSD(uint256 _amountLD) public view returns (uint64 amountSD) {
        return _toSD(_amountLD);
    }

    function credit(address _to, uint256 _amountToCreditLD, uint32 _srcEid) public returns (uint256 amountReceivedLD) {
        return _credit(_to, _amountToCreditLD, _srcEid);
    }

    function buildMsgAndOptions(
        SendParam calldata _sendParam,
        uint256 _amountToCreditLD
    )
        public
        view
        returns (bytes memory message, bytes memory options)
    {
        return _buildMsgAndOptions(_sendParam, _amountToCreditLD);
    }

    function lzReceive(
        Origin calldata _origin,
        address _receiver,
        bytes32 _guid,
        bytes calldata _message,
        bytes calldata _extraData
    )
        external
        payable
    { }

    function balanceOf(address _account) public view override returns (uint256) {
        return super.balanceOf(_account);
    }
}
