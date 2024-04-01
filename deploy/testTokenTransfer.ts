import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers'
import { expect } from 'chai'
import { Contract, ContractFactory } from 'ethers'
const Web3 = require('web3');
import { deployments, ethers } from 'hardhat'

import { Options } from '@layerzerolabs/lz-v2-utilities'

// send 10 token to Mumbai from Sepolia
// send 10 token from Fuji to Sepolia

const CONTRACT_NAME = 'ETHx_OFTAdapter';

const OFT_Adaptor = require('../artifacts/contracts/ETHx_OFTAdapter.sol/ETHx_OFTAdapter.json')

// const EID_MUMBAI = 40109;
const EID_SEPOLIA = 40231;
// const EID_FUJI = 40106;

async function main() {

    // Before hook for setup that runs once before all tests in the block
    // Fetching the first three signers (accounts) from Hardhat's local Ethereum network
    // const signers = await ethers.getSigners()
    let ownerA: SignerWithAddress

    const signers = await ethers.getSigners()

    ownerA = signers.at(0)!

    // // Minting an initial amount of tokens to ownerA's address in the myOFTA contract
    // const initialAmount = ethers.utils.parseEther('100')
    // await myOFTA.mint(ownerA.address, initialAmount)

    // const deployment = await deployments.get(CONTRACT_NAME);

    // // Defining the amount of tokens to send and constructing the parameters for the send operation
    const tokensToSend = ethers.utils.parseEther('1')

    // // Defining extra message execution options for the send operation
    const options = Options.newOptions().addExecutorLzReceiveOption(200000, 0).toHex().toString()        

    const sendParam = [
        EID_SEPOLIA,
        ethers.utils.hexZeroPad(ownerA.address, 32),
        tokensToSend,
        tokensToSend,
        options,
        '0x',
        '0x',
    ]

    console.log({
        sendParam,
        options
    })

    const MyOFT = await ethers.getContractFactory(CONTRACT_NAME)
    const myOFTA = MyOFT.attach('0x4D306b4d57BEFdFFB7d98b47e8c8D07CE517D9BF').connect(ownerA);

    // Fetching the native fee for the token send operation
    const [nativeFee] = await myOFTA.quoteSend(sendParam, false)
    console.log({
        nativeFee
    })

    // Executing the send operation from myOFTA contract
    const tx = await myOFTA.send(sendParam, [nativeFee, 0], ownerA.address, { value: nativeFee, gasLimit: 600000 })
    console.log({
        tx
    })

    // // Fetching the final token balances of ownerA and ownerB
    // const finalBalanceA = await myOFTA.balanceOf(ownerA.address)
    // const finalBalanceB = await myOFTB.balanceOf(ownerB.address)

    // // Asserting that the final balances are as expected after the send operation
    // expect(finalBalanceA.eq(initialAmount.sub(tokensToSend))).to.be.true
    // expect(finalBalanceB.eq(tokensToSend)).to.be.true
}

main()