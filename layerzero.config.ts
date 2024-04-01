// eslint-disable-next-line @typescript-eslint/no-var-requires
const { EndpointId } = require('@layerzerolabs/lz-definitions');
const { ExecutorOptionType } = require('@layerzerolabs/lz-v2-utilities');

const ethereumContract = {
    eid: EndpointId.HOLESKY_V2_TESTNET,
    contractName: 'ETHx_OFTAdapter',
};

const arbitrumContract = {
    eid: EndpointId.ARBSEP_V2_TESTNET,
    contractName: 'ETHx_OFT',
};


module.exports = {
    contracts: [
        {
            contract: arbitrumContract,
        },
        {
            contract: ethereumContract,
        }
    ],
    connections: [
        {
            from: arbitrumContract,
            to: ethereumContract,
            config: {
                enforcedOptions: [
                    {
                        msgType: 1,
                        optionType: ExecutorOptionType.LZ_RECEIVE,
                        gas: 200000,
                        value: 0,
                    },
                ],
            },
        },
        {
            from: ethereumContract,
            to: arbitrumContract,
            config: {
                enforcedOptions: [
                    {
                        msgType: 1,
                        optionType: ExecutorOptionType.LZ_RECEIVE,
                        gas: 200000,
                        value: 0,
                    },
                ],
            },
        },  
    ],
};