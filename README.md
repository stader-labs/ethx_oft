<h1 align="center">Stader OFT</h1>

<p align="center">
  <a href="https://layerzero.network">
    <img alt="LayerZero" style="max-width: 50px" src="https://d3a2dpnnrypp5h.cloudfront.net/bridge-app/lz.png"/>
  </a>
</p>

<p align="center">
  <a href="https://layerzero.network" style="color: #a77dff">Homepage</a> | <a href="https://docs.layerzero.network/" style="color: #a77dff">Docs</a> | <a href="https://layerzero.network/developers" style="color: #a77dff">Developers</a>
</p>

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

[![Test](https://github.com/stader-labs/ethx_oft/actions/workflows/ci-image.yml/badge.svg)](https://github.com/stader-labs/ethx_oft/actions/workflows/ci-image.yml)

<p align="left">An Omnichain fungible token is a type of asset designed to provide liquidity across multiple blockchain networks without being restricted. This technology allows for greater interoperability and fluidity of the sd token.  These tokens can be used, traded, and managed across different blockchain systems without the need for complex and costly bridging solutions. By leveraging protocols that enable cross-chain interactions, omnichain tokens aim to foster a more connected and efficient ecosystem for digital assets, enhancing user experience by simplifying transactions and reducing fragmentation across the blockchain landscape. This approach not only enhances liquidity and accessibility but also supports broader adoption of blockchain technology by creating a more unified and versatile digital economy.


## 1 - Developing Contracts

#### using Docker
```bash
$ docker build . -t ethx_oft:1
```
#### using Visual Studio Code

##### A Dockerfile and `devcontainer.json` is provided

Using the Dev Containers extension in VS Code simply reopen the project in it's container.

    `Reopen in Container`

### Foundry

This project is using [Foundry](https://github.com/foundry-rs/foundry). Development is enabled with the [Foundry Development](https://github.com/collectivexyz/foundry) container

### From the command line

Install dependencies.

```bash
$ npm ci --frozen-lockfile
```

Update forge dependencies
```bash
$ forge install
```

Run tests
```bash
$ forge test -v
```

### 2 - Audit History

[AUDIT.md](AUDIT.md)

## 3 - Deploying Contracts

## Contracts Deployed

| Contract         | Address                                    | Network          |
| ---------------- | ------------------------------------------ | ---------------- |
| ProxyAdmin       | 0xD99E8bA5259Dd2b8B9aBFE0eD78913ec60B8F898 | Ethereum         |
| ETHx             | 0xA35b1B31Ce002FBF2058D22F30f95D405200A15b | Ethereum         |
| ETHx_OFTAdapter  | 0x39d0ce7d1509a4f22619D0f666978FBe820665E9 | Ethereum         |
| ETHxPriceOracle  | 0x9305d41Ac91A200B848D285242D8e415E6414B2F | Ethereum         |
| ETHxRateProvider | 0x0B2fAadfe75fE6507Dc8F81f8331198C65cA2C24 | Ethereum         |
| ETHx ProxyAdmin  | 0x99A7102235A7773003D70bA0f6cc8D97e38ABB53 | XLayer           |
| ETHx             | 0xDC685bf4b416f8D5cAc64927E9c516be45b81d28 | XLayer           |
| ETHx_OFT         | 0xC0A0fDD802b2750b7f972C2a7972c8942328099f | XLayer           |
| ETHxTokenWrapper | 0xDBAaD20ffd67dfaeBdE40b842cB78eAa18F1BB74 | XLayer           |
| ETHxRateReceiver | 0x063d4c8CFeF375C2Fc1710934504e2b7aB85fd15 | XLayer           |
| ETHxPoolV4       | 0xaE11a5de90D6eC8b296b5D8cc7d0F262c0074Eef | XLayer           |
| ETHx             | 0xED65C5085a18Fa160Af0313E60dcc7905E944Dc7 | Arbitrum         |
| ETHx ProxyAdmin  | 0xAAE054B9b822554dd1D9d1F48f892B4585D3bbf0 | Arbitrum         |
| ETHx             | 0xc54B43eaF921A5194c7973A4d65E055E5a1453c2 | Optimism         |
| ETHx ProxyAdmin  | 0x8bc3646d175ECb081469Be6a0b2A10eeE112101C | Optimism         |
| ETHx             | 0xB4F5fc289a778B80392b86fa70A7111E5bE0F859 | Holesky          |
| ETHx_OFTAdapter  | 0x4a5CC4c467CF043247f4d06Ef0b688aa5C3F7F6a | Holesky          |
| ETHx ProxyAdmin  | 0xe6460418db6D7A6D85423560B19A8Af37c1092a4 | Holesky          |
| ETHx PriceOracle | 0x66C4924Cc30dC47D0c8484143236F465F4e37c9E | Holesky          |
| ETHxRateProvider | 0xbF11aB33C9E1206Fb868b3dbFc8C9cB8D4e6BD79 | Holesky          |
| ETHx             | 0x52312ea29135A468417F0C71d6A75CfEA75351b7 | Arbitrum Sepolia |
| ETHx_OFT         | 0x8AEDA11bD0C5fBafbFb142830d23812Df02A8424 | Arbitrum Sepolia |
| ETHxRateReceiver | 0x2b700f8b3F03798e7Db0e67a5aB48c12D10046DE | Arbitrum Sepolia |
| ETHx ProxyAdmin  | 0xb30256CA8A9Ebe058Eb78a4edbf3364e7F8e5d86 | XLayer Testnet   |
| ETHx             | 0x7D03Bfa72Cd70e96A391cF32e7B27e43AE68a574 | XLayer Testnet   |
| ETHx_OFT         | 0xD99E8bA5259Dd2b8B9aBFE0eD78913ec60B8F898 | XLayer Testnet   |
| ETHx Wrapper     | 0x0B2fAadfe75fE6507Dc8F81f8331198C65cA2C24 | XLayer Testnet   |
| ETHxPoolV4       | 0x217EBabCf15EC6deaCF11f737d79275e95C97EFE | XLayer Testnet   |
| ETHxRateReceiver | 0xBe23e1A64969Cb28eFdB6c3d2CE9E4Bf16042187 | XLayer Testnet   |
| ETHx ProxyAdmin  | 0xbF11aB33C9E1206Fb868b3dbFc8C9cB8D4e6BD79 | Sepolia          |
| ETHx             | 0xD4a5B7967858f361689C88Af11F3180fc09dF620 | Sepolia          |
| ETHx ProxyAdmin  | 0xb30256CA8A9Ebe058Eb78a4edbf3364e7F8e5d86 | Chiado           |
| ETHx             | 0x7D03Bfa72Cd70e96A391cF32e7B27e43AE68a574 | Chiado           |
| ETHx_OFT         | 0xD99E8bA5259Dd2b8B9aBFE0eD78913ec60B8F898 | Chiado           |


### Deployment
Set up deployer wallet/account:

- Rename `.env.example` -> `.env`
- Choose your preferred means of setting up your deployer wallet/account:

```
MNEMONIC="test test test test test test test test test test test junk"
or...
PRIVATE_KEY="0xabc...def"
```

- Fund this address with the corresponding chain's native tokens you want to deploy to.

To deploy your contracts to your desired blockchains, run the following command in your project's folder:

```bash
npx hardhat lz:deploy
```

More information about available CLI arguments can be found using the `--help` flag:

```bash
npx hardhat lz:deploy --help
```

By following these steps, you can focus more on creating innovative omnichain solutions and less on the complexities of cross-chain communication.

<br></br>

<p align="center">
  Join our community on <a href="https://discord-layerzero.netlify.app/discord" style="color: #a77dff">Discord</a> | Follow us on <a href="https://twitter.com/LayerZero_Labs" style="color: #a77dff">Twitter</a>
</p>


#### Forge deployment

```bash
$ forge script ./script/DeployETHx.s.sol --sig 'deployImplementation()' --broadcast --slow --rpc-url ${ARBITRUM_URL} --private-key ${PRIVATE_KEY} --etherscan-api-key ${ARBISCAN_API_KEY} --verifier-url https://api.arbiscan.io/api --verify
```


#### Examples

Get fees for L2 to send in LayerZero Transaction.

```bash
$cast call 0xbF11aB33C9E1206Fb868b3dbFc8C9cB8D4e6BD79 "estimateTotalFee()" --rpc-url ${HOLESKY_URL} 
0x0000000000000000000000000000000000000000000000000002780ecc6d1951
```

Update rate on Holesky Testnet:

```bash
cast send 0xbF11aB33C9E1206Fb868b3dbFc8C9cB8D4e6BD79 "updateRate()" --rpc-url ${HOLESKY_URL} --private-key ${PRIVATE_KEY} --value 694954907998545
status                  1 (success)
transactionHash         0x1ad899d3094a5d1e92d9e1eda12f507950d9ce7d7c18638209ef6e910ebf8d10
transactionIndex        18
type                    2
blobGasPrice            
blobGasUsed             
to                      0xbF11aB33C9E1206Fb868b3dbFc8C9cB8D4e6BD79
```

Check result on [LayerZero Scan](https://testnet.layerzeroscan.com/tx/0x1ad899d3094a5d1e92d9e1eda12f507950d9ce7d7c18638209ef6e910ebf8d10)

Get rate on XLayer Testnet:

```bash
$ cast call 0xBe23e1A64969Cb28eFdB6c3d2CE9E4Bf16042187 "rate()" --rpc-url ${XLAYER_URL}
0x0000000000000000000000000000000000000000000000000de0bf5399e7bdd6
```
