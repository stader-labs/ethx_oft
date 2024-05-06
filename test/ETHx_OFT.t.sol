// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

// Forge imports
import "forge-std/console.sol";

// OZ imports
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

// Mock imports
import { OFTMock } from "./mocks/OFTMock.sol";
import { ERC20Mock } from "./mocks/ERC20Mock.sol";
import { OFTComposerMock } from "./mocks/OFTComposerMock.sol";

// OApp imports
import {
    IOAppOptionsType3,
    EnforcedOptionParam
} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OAppOptionsType3.sol";
import { OptionsBuilder } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OptionsBuilder.sol";

// OFT imports
import { IOFT, SendParam, OFTReceipt } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";
import { MessagingFee, MessagingReceipt } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFTCore.sol";
import { OFTMsgCodec } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/libs/OFTMsgCodec.sol";
import { OFTComposeMsgCodec } from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/libs/OFTComposeMsgCodec.sol";

import { ETHx } from "../contracts/ETHx.sol";
import { ETHxOFTMock } from "./mocks/ETHxOFTMock.sol";

// DevTools imports
import { TestHelperOz5 } from "test-devtools-evm-foundry/contracts/TestHelperOz5.sol";

contract ETHxOFTTest is TestHelperOz5 {
    using OptionsBuilder for bytes;

    uint32 aEid = 1;
    uint32 bEid = 2;

    OFTMock anOFT;
    ETHx erc20;
    ETHxOFTMock ethxOFT;

    address public userA = address(0x1);
    address public userB = address(0x2);
    uint256 public initialBalance = 100 ether;

    function setUp() public virtual override {
        vm.deal(userA, 1000 ether);
        vm.deal(userB, 1000 ether);

        address erc20Mock = vm.addr(1001);
        mockEthx(erc20Mock);
        erc20 = ETHx(erc20Mock);

        super.setUp();
        setUpEndpoints(2, LibraryType.UltraLightNode);

        anOFT = OFTMock(
            _deployOApp(
                type(OFTMock).creationCode, abi.encode("anOFT", "anOFT", address(endpoints[aEid]), address(this))
            )
        );

        ethxOFT = ETHxOFTMock(
            _deployOApp(type(ETHxOFTMock).creationCode, abi.encode(erc20Mock, address(endpoints[bEid]), address(this)))
        );

        erc20.grantRole(erc20.PAUSER_ROLE(), address(ethxOFT));
        erc20.grantRole(erc20.MINTER_ROLE(), address(ethxOFT));
        erc20.grantRole(erc20.BURNER_ROLE(), address(ethxOFT));

        // config and wire the ofts
        address[] memory ofts = new address[](2);
        ofts[0] = address(anOFT);
        ofts[1] = address(ethxOFT);
        this.wireOApps(ofts);

        // mint tokens
        anOFT.mint(userA, initialBalance);
        vm.prank(address(ethxOFT));
        ethxOFT.mint(userB, initialBalance);
    }

    function testConstructor() public {
        assertEq(anOFT.owner(), address(this));
        assertEq(ethxOFT.owner(), address(this));

        assertEq(anOFT.balanceOf(userA), initialBalance);
        assertEq(ethxOFT.balanceOf(userB), initialBalance);

        assertEq(anOFT.token(), address(anOFT));
        assertEq(ethxOFT.token(), address(erc20));
    }

    function testBalanceOf() public {
        address user1 = vm.addr(0x1);
        address user2 = vm.addr(0x2);
        vm.prank(address(ethxOFT));
        erc20.mint(user1, 100);
        assertEq(100, ethxOFT.balanceOf(user1));
        assertEq(0, ethxOFT.balanceOf(user2));
    }

    function testSendOft() public {
        uint256 tokensToSend = 1 ether;
        bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(200_000, 0);
        SendParam memory sendParam =
            SendParam(bEid, addressToBytes32(userB), tokensToSend, tokensToSend, options, "", "");
        MessagingFee memory fee = anOFT.quoteSend(sendParam, false);

        assertEq(anOFT.balanceOf(userA), initialBalance);
        assertEq(ethxOFT.balanceOf(userB), initialBalance);

        vm.prank(userA);
        anOFT.send{ value: fee.nativeFee }(sendParam, fee, payable(address(this)));
        verifyPackets(bEid, addressToBytes32(address(ethxOFT)));

        assertEq(anOFT.balanceOf(userA), initialBalance - tokensToSend);
        assertEq(ethxOFT.balanceOf(userB), initialBalance + tokensToSend);
    }

    function testSendOftComposeMsg() public {
        uint256 tokensToSend = 1 ether;

        OFTComposerMock composer = new OFTComposerMock();

        bytes memory options =
            OptionsBuilder.newOptions().addExecutorLzReceiveOption(200_000, 0).addExecutorLzComposeOption(0, 500_000, 0);
        bytes memory composeMsg = hex"1234";
        SendParam memory sendParam =
            SendParam(bEid, addressToBytes32(address(composer)), tokensToSend, tokensToSend, options, composeMsg, "");
        MessagingFee memory fee = anOFT.quoteSend(sendParam, false);

        assertEq(anOFT.balanceOf(userA), initialBalance);
        assertEq(ethxOFT.balanceOf(address(composer)), 0);

        vm.prank(userA);
        (MessagingReceipt memory msgReceipt, OFTReceipt memory oftReceipt) =
            anOFT.send{ value: fee.nativeFee }(sendParam, fee, payable(address(this)));
        verifyPackets(bEid, addressToBytes32(address(ethxOFT)));

        // lzCompose params
        uint32 dstEid_ = bEid;
        address from_ = address(ethxOFT);
        bytes memory options_ = options;
        bytes32 guid_ = msgReceipt.guid;
        address to_ = address(composer);
        bytes memory composerMsg_ = OFTComposeMsgCodec.encode(
            msgReceipt.nonce, aEid, oftReceipt.amountReceivedLD, abi.encodePacked(addressToBytes32(userA), composeMsg)
        );
        this.lzCompose(dstEid_, from_, options_, guid_, to_, composerMsg_);

        assertEq(anOFT.balanceOf(userA), initialBalance - tokensToSend);
        assertEq(ethxOFT.balanceOf(address(composer)), tokensToSend);

        assertEq(composer.from(), from_);
        assertEq(composer.guid(), guid_);
        assertEq(composer.message(), composerMsg_);
        assertEq(composer.executor(), address(this));
        assertEq(composer.extraData(), composerMsg_); // default to setting the extraData to the message as well to test
    }

    function testPauseAndUnpause() public {
        assert(!ethxOFT.paused());
        ethxOFT.pause();
        assert(ethxOFT.paused());
        ethxOFT.unpause();
        assert(!ethxOFT.paused());
    }

    function testSendPausedEmitError() public {
        ethxOFT.pause();
        uint256 tokensToSend = 1 ether;
        bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(200_000, 0);
        SendParam memory sendParam =
            SendParam(bEid, addressToBytes32(userB), tokensToSend, tokensToSend, options, "", "");
        MessagingFee memory fee = anOFT.quoteSend(sendParam, false);

        assertEq(anOFT.balanceOf(userA), initialBalance);
        assertEq(ethxOFT.balanceOf(userB), initialBalance);

        vm.prank(userA);
        anOFT.send{ value: fee.nativeFee }(sendParam, fee, payable(address(this)));
    }

    function testPauseRequiresOwner() public {
        address owner1 = vm.addr(0x1);
        ethxOFT.transferOwnership(owner1);
        vm.expectRevert("Ownable: caller is not the owner");
        ethxOFT.pause();
    }

    function testUnpauseRequiresOwner() public {
        address owner1 = vm.addr(0x1);
        ethxOFT.transferOwnership(owner1);
        vm.expectRevert("Ownable: caller is not the owner");
        ethxOFT.unpause();
    }

    function mockEthx(address ethxMock) private {
        ETHx implementation = new ETHx();
        bytes memory code = address(implementation).code;
        vm.etch(ethxMock, code);
        ETHx mock = ETHx(ethxMock);
        mock.initialize(address(this));
    }
}
