UpdateRate must be called from time to time on Stader ETHxRateProvider, an L2 Rate Oracle for ETHx.   The following steps demonstrate how to do this.

Deployment address – Ethereum mainnet:
```bash
ETHX_RATE_PROVIDER=0x0B2fAadfe75fE6507Dc8F81f8331198C65cA2C24
```

1\. Check LayerZero fee for sending rate information.

```bash
$ cast call 0x0B2fAadfe75fE6507Dc8F81f8331198C65cA2C24 "estimateTotalFee()" --rpc-url ${MAINNET_URL} --legacy
0x000000000000000000000000000000000000000000000000000104cdb2b763a5
```

2\. Convert the calldata response to a decimal value
```bash
$ cast to-base
0x000000000000000000000000000000000000000000000000000104cdb2b763a5
10
286756489880485
```

3\. Submit the call to updateRate including value equal to the requirement quoted by LayerZero above
```bash
cast send 0x0B2fAadfe75fE6507Dc8F81f8331198C65cA2C24 "updateRate()" --rpc-url ${MAINNET_URL} --legacy --private-key ${PRIVATE_KEY} --value 286756489880485

blockNumber             20191801                   
status                  1 (success)
transactionHash         0xa8ba9eee9a8a6ccaba24db8dc7e6af363b23db3a133ed35c5456d7d426599ad9
to                      0x0B2fAadfe75fE6507Dc8F81f8331198C65cA2C24
```

ETHx rate is now updated across supported implementations