import assert from 'assert'

import { type DeployFunction } from 'hardhat-deploy/types'

const feeBps = 10;

const networkAddresses = {
    arbitrumSepolia:{
        "owner": "0xfcB068B43AB08aA9210F52eabd261A7a3b0C8357",
        "bridger": "0xfcB068B43AB08aA9210F52eabd261A7a3b0C8357",
        "ethx": "0x52312ea29135A468417F0C71d6A75CfEA75351b7",
        "ethxOracle": "0x2b700f8b3F03798e7Db0e67a5aB48c12D10046DE"
    }, 

    arbitrum:{
        "owner": "0xe85F0d083D0CD18485E531c1A8B8a05ad2C0308f",
        "bridger": "0xc6160F5bC3C673AC390f11c492E8ED0d0693579A",
        "ethx": "0xED65C5085a18Fa160Af0313E60dcc7905E944Dc7",
        "ethxOracle": "0xB4AC4078DDA43d0eB6Bb9e08b8C12A73f9FEAA7d"
    }
}

const deployETHxPool: DeployFunction = async (hre) => {
    const { getNamedAccounts, deployments } = hre

    const { deploy } = deployments
    const { deployer } = await getNamedAccounts()

    assert(deployer, 'Missing named deployer account')

    console.log(`Network: ${hre.network.name}`)
    console.log(`Deployer: ${deployer}`)

    const { arbitrumSepolia } = networkAddresses
    
    const ethxPool = await deploy("ETHxPoolV1", {
        from: deployer,
        contract: "ETHxPoolV1",
        proxy: {
          owner: arbitrumSepolia.owner,
          proxyContract: "OpenZeppelinTransparentProxy",
          execute: {
            methodName: "initialize",
            args: [arbitrumSepolia.owner, arbitrumSepolia.bridger, arbitrumSepolia.ethx, feeBps, arbitrumSepolia.ethxOracle],
          },
        },
        autoMine: true,
        log: true,
      });

    console.log(`Deployed contract: ${"ETHxPoolV1"}, network: ${hre.network.name}, address: ${ethxPool.address}`)
}

deployETHxPool.tags = ["ETHxPoolV1"]
export default deployETHxPool
