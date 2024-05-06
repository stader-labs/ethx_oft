// SPDX-License-Identifier: GNU-3.0-or-later
pragma solidity 0.8.22;

import { OFTAdapter } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFTAdapter.sol";

/// @dev contract used for Origin chain where the token is already deployed
// solhint-disable-next-line contract-name-camelcase
contract ETHx_OFTAdapter is OFTAdapter {
    constructor(address _token, address _lzEndpoint, address _delegate) OFTAdapter(_token, _lzEndpoint, _delegate) {
        transferOwnership(_delegate);
    }
}
