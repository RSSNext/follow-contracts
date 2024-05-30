## Follow contracts

[![Docs](https://github.com/RSSNext/follow-contracts/actions/workflows/docs.yml/badge.svg)](https://github.com/RSSNext/follow-contracts/actions/workflows/docs.yml)
[![checks](https://github.com/RSSNext/follow-contracts/actions/workflows/checks.yml/badge.svg)](https://github.com/RSSNext/follow-contracts/actions/workflows/checks.yml)
[![Tests](https://github.com/RSSNext/follow-contracts/actions/workflows/tests.yml/badge.svg)](https://github.com/RSSNext/follow-contracts/actions/workflows/tests.yml)
[![codecov](https://codecov.io/gh/RSSNext/follow-contracts/graph/badge.svg?token=23COU041UA)](https://codecov.io/gh/RSSNext/follow-contracts)

## Usage

### Build

```shell
yarn
forge build
```

### Test

```shell
forge test
```


### Deploy

```shell
forge script script/Deploy.s.sol:Deploy \
--chain-id $CHAIN_ID \
--rpc-url $RPC_URL \
--private-key $PRIVATE_KEY \
--verifier-url $VERIFIER_URL \
--verifier $VERIFIER \
--verify \
--broadcast --ffi -vvvv 

# generate easily readable abi to /deployments
forge script script/Deploy.s.sol:Deploy --sig 'sync()' --rpc-url $RPC_URL --broadcast --ffi
```
