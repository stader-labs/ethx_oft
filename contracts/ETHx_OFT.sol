// SPDX-License-Identifier: GNU-3.0-or-later
pragma solidity 0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { OFTCore, Origin } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFTCore.sol";

import { IERC20Burnable } from "./IERC20Burnable.sol";
import { IPausable } from "./IPausable.sol";

contract ETHx_OFT is OFTCore {
    using SafeERC20 for IERC20;

    event Pause(uint32 srcEid);
    event Unpause(uint32 srcEid);

    IERC20Burnable internal immutable ETHx;

    constructor(
        address _ETHx,
        address _lzEndpoint,
        address _delegate
    )
        OFTCore(IERC20Metadata(_ETHx).decimals(), _lzEndpoint, _delegate)
        Ownable(_delegate)
    {
        ETHx = IERC20Burnable(_ETHx);
    }

    /**
     * public functions
     */
    function token() public view virtual override returns (address) {
        return address(ETHx);
    }

    /**
     * pause the oft
     */
    function pause() public onlyOwner {
        ETHx.pause();
    }

    /**
     * unpause the oft
     */
    function unpause() public onlyOwner {
        ETHx.unpause();
    }

    function approvalRequired() external pure returns (bool) {
        return false;
    }

    /**
     * @dev Burns tokens from the sender's specified balance.
     * @param _from The address to debit the tokens from.
     * @param _amountLD The amount of tokens to send in local decimals.
     * @param _minAmountLD The minimum amount to send in local decimals.
     * @param _dstEid The destination chain ID.
     * @return amountSentLD The amount sent in local decimals.
     * @return amountReceivedLD The amount received in local decimals on the remote.
     */
    function _debit(
        address _from,
        uint256 _amountLD,
        uint256 _minAmountLD,
        uint32 _dstEid
    )
        internal
        virtual
        override
        returns (uint256 amountSentLD, uint256 amountReceivedLD)
    {
        (amountSentLD, amountReceivedLD) = _debitView(_amountLD, _minAmountLD, _dstEid);

        // @dev In NON-default OFT, amountSentLD could be 100, with a 10% fee, the amountReceivedLD amount is 90,
        // therefore amountSentLD CAN differ from amountReceivedLD.

        // @dev Default OFT burns on src.
        ETHx.burnFrom(_from, amountSentLD);
    }

    /**
     * @dev Credits tokens to the specified address.
     * @param _to The address to credit the tokens to.
     * @param _amountLD The amount of tokens to credit in local decimals.
     * @dev _srcEid The source chain ID.
     * @return amountReceivedLD The amount of tokens ACTUALLY received in local decimals.
     */
    function _credit(
        address _to,
        uint256 _amountLD,
        uint32 /*_srcEid*/
    )
        internal
        virtual
        override
        returns (uint256 amountReceivedLD)
    {
        // @dev Default OFT mints on dst.
        ETHx.mint(_to, _amountLD);
        // @dev In the case of NON-default OFT, the _amountLD MIGHT not be == amountReceivedLD.
        return _amountLD;
    }

    function _lzReceive(
        Origin calldata _origin, // struct containing info about the message sender
        bytes32 _guid, // global packet identifier
        bytes calldata _payload, // encoded message payload being received
        address _executor, // the Executor address.
        bytes calldata _extraData // arbitrary data appended by the Executor
    )
        internal
        virtual
        override
    {
        bytes4 signature = abi.decode(_payload, (bytes4));
        if (signature == IPausable.pause.selector) {
            pause();
            emit Pause(_origin.srcEid);
        } else if (signature == IPausable.unpause.selector) {
            unpause();
            emit Unpause(_origin.srcEid);
        } else {
            super._lzReceive(_origin, _guid, _payload, _executor, _extraData);
        }
    }
}
