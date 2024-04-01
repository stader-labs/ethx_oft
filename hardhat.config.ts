// Get the environment configuration from .env file
//
// To make use of automatic environment setup:
// - Duplicate .env.example file and name it .env
// - Fill in the environment variables
import 'dotenv/config'

import 'hardhat-deploy'
import 'hardhat-contract-sizer'
import '@nomiclabs/hardhat-ethers'
import '@layerzerolabs/toolbox-hardhat'

import { HardhatUserConfig, HttpNetworkAccountsUserConfig } from 'hardhat/types'

import { EndpointId } from '@layerzerolabs/lz-definitions'

// Set your preferred authentication method
//
// If you prefer using a mnemonic, set a MNEMONIC environment variable
// to a valid mnemonic
const MNEMONIC = process.env.MNEMONIC

// If you prefer to be authenticated using a private key, set a PRIVATE_KEY environment variable
const PRIVATE_KEY = process.env.PRIVATE_KEY

const accounts: HttpNetworkAccountsUserConfig | undefined = MNEMONIC
    ? { mnemonic: MNEMONIC }
    : PRIVATE_KEY
      ? [PRIVATE_KEY]
      : undefined

if (accounts == null) {
    console.warn(
        'Could not find MNEMONIC or PRIVATE_KEY environment variables. It will not be possible to execute transactions in your example.'
    )
}

const config: HardhatUserConfig = {
    solidity: {
        compilers: [
            {
                version: '0.8.22',
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 200,
                    },
                },
            },
        ],
    },
    networks: {
        sepolia: {
            eid: EndpointId.SEPOLIA_V2_TESTNET,
            url: process.env.RPC_URL_SEPOLIA || 'https://rpc.sepolia.org/',
            accounts,
        },
        holesky: {
            eid: EndpointId.HOLESKY_V2_TESTNET,
            url: process.env.RPC_URL_HOLESKY || 'https://rpc.holesky.ethpandaops.io',
            accounts,
        },
        fuji: {
            eid: EndpointId.AVALANCHE_V2_TESTNET,
            url: process.env.RPC_URL_FUJI || 'https://rpc.ankr.com/avalanche_fuji',
            accounts,
        },
        mumbai: {
            eid: EndpointId.POLYGON_V2_TESTNET,
            url: process.env.RPC_URL_MUMBAI || 'https://rpc.ankr.com/polygon_mumbai',
            accounts,
        },
        arbitrum: {
            eid: EndpointId.ARBSEP_V2_TESTNET,
            url: process.env.RPC_URL_ARBITRUM || 'https://sepolia-rollup.arbitrum.io/rpc',
            accounts,
        }
    },
    namedAccounts: {
        deployer: {
            default: 0, // wallet address of index[0], of the mnemonic in .env
        },
    },
    etherscan: {
        // Your API key for Etherscan
        // Obtain one at https://etherscan.io/
        apiKey: {
          holesky: process.env.API_KEY,
          arbitrum: process.env.ARBITRUM_API_KEY
        },
        customChains: [
          {
            network: 'holesky',
            chainId: 17000,
            urls:{
              apiURL: "https://api-holesky.etherscan.io/api",
              browserURL: "https://holesky.etherscan.io"
            }
          },
          {
            network: 'arbitrum',
            chainId: 421614,
            urls:{
              apiURL: "https://api-sepolia.arbiscan.io/api",
              browserURL: "https://sepolia.arbiscan.io/"
            }
          },
        ]
    
      },
}

export default config
