import assert from 'assert'

import { type DeployFunction } from 'hardhat-deploy/types'

const contractName = 'ETHx_OFT'

const deployOFT: DeployFunction = async (hre) => {
    const { getNamedAccounts, deployments } = hre

    const { deploy } = deployments
    const { deployer } = await getNamedAccounts()

    assert(deployer, 'Missing named deployer account')

    console.log(`Network: ${hre.network.name}`)
    console.log(`Deployer: ${deployer}`)

    // This is an external deployment pulled in from @layerzerolabs/lz-evm-sdk-v2
    //
    // @layerzerolabs/toolbox-hardhat takes care of plugging in the external deployments
    // from @layerzerolabs packages based on the configuration in your hardhat config
    //
    // For this to work correctly, your network config must define an eid property
    // set to `EndpointId` as defined in @layerzerolabs/lz-definitions
    //
    // For example:
    //
    // networks: {
    //   fuji: {
    //     ...
    //     eid: EndpointId.AVALANCHE_V2_TESTNET
    //   }
    // }
    const endpointV2Deployment = await hre.deployments.get('EndpointV2')

    console.log('lz endpoint is ', endpointV2Deployment.address)
    
    const { address } = await deploy(contractName, {
        from: deployer,
        args: [
            '0x7F9c175343637e03b2a056D831BD5C96d1157ED6', //ETHx token address on L2
            endpointV2Deployment.address, // LayerZero's EndpointV2 address
            deployer, // owner
        ],
        log: true,
        skipIfAlreadyDeployed: false,
    })

    console.log(`Deployed contract: ${contractName}, network: ${hre.network.name}, address: ${address}`)
}

deployOFT.tags = [contractName]

export default deployOFT
