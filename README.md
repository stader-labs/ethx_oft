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


## 1) Developing Contracts

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

## 2) Deploying Contracts

## Contracts Deployed

### ETH Holesky

ETHx_OFTAdapter: 0x4D306b4d57BEFdFFB7d98b47e8c8D07CE517D9BF

### Arbitrum Sepolia

ETHx: 0x7F9c175343637e03b2a056D831BD5C96d1157ED6

ETHx_OFT: 0x8826E2Dd7555Ec6A8782F63e3b10A4C7F973b03d

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


#### Forge implementation deployment to mainnet

```bash
$ forge script ./script/DeployETHx.s.sol --sig 'deployImplementation()' --broadcast --slow --rpc-url ${ARBITRUM_URL} --private-key ${PRIVATE_KEY} --etherscan-api-key ${ARBISCAN_API_KEY} --verifier-url https://api.arbiscan.io/api --verify
```
