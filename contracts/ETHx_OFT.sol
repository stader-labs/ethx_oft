// SPDX-License-Identifier: GNU-3.0-or-later
pragma solidity 0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import { OFTCore } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFTCore.sol";
import {
    MessagingFee,
    MessagingReceipt
} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";

import { IERC20Burnable } from "./IERC20Burnable.sol";
import { ComposedPauser } from "./ComposedPauser.sol";
import { IPausable } from "./IPausable.sol";

// solhint-disable-next-line contract-name-camelcase
contract ETHx_OFT is OFTCore, IPausable {
    using SafeERC20 for IERC20;

    error AdapterPaused();

    // solhint-disable-next-line var-name-mixedcase
    IERC20Burnable internal immutable ETHx;

    ComposedPauser private _composedPauser;

    constructor(
        // solhint-disable-next-line var-name-mixedcase
        address _ETHx,
        address _lzEndpoint,
        address _delegate
    )
        OFTCore(IERC20Metadata(_ETHx).decimals(), _lzEndpoint, _delegate)
    {
        transferOwnership(_delegate);
        ETHx = IERC20Burnable(_ETHx);
        _composedPauser = new ComposedPauser();
    }

    /**
     * public functions
     */
    function token() public view virtual override returns (address) {
        return address(ETHx);
    }

    /**
     * @dev Returns the balance of the specified account.
     * @param _account The address to query the balance of.
     * @return balance The balance of the specified account.
     */
    function balanceOf(address _account) public view virtual returns (uint256) {
        return ETHx.balanceOf(_account);
    }

    /**
     * @dev Returns whether the OFT requires approval to transfer tokens.
     * @return approvalRequired True if approval is required, false otherwise.
     */
    function approvalRequired() external pure returns (bool) {
        return false;
    }

    /**
     * @dev Returns whether the OFT is paused.
     * @return True if the OFT is paused, false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return PausableUpgradeable(address(ETHx)).paused() || _composedPauser.paused();
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
        _mint(_to, _amountLD);
        // @dev In the case of NON-default OFT, the _amountLD MIGHT not be == amountReceivedLD.
        return _amountLD;
    }

    /*
        * @dev Mints tokens to the specified address.
        * @param _to The address to mint the tokens to.
        * @param _amount The amount of tokens to mint.
        */

    function _mint(address _to, uint256 _amount) internal virtual {
        ETHx.mint(_to, _amount);
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
