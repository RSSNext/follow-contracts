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
forge script script/Deploy.s.sol:Deploy --sig 'deployPowerToken()' \
--chain-id $CHAIN_ID \
--rpc-url $RPC_URL \
--private-key $PRIVATE_KEY \
--verifier-url $VERIFIER_URL \
--verifier $VERIFIER \
--verify \
--broadcast --ffi -vvvv 

cast calldata 'initialize(string calldata name_, string calldata symbol_, address admin_)' "POWER" "POWER" 0xD4Bc2Ab6e4eAeCC04D83b389A57A59EEcdE91709
0x077f224a000000000000000000000000000000000000000000000000000000000000006000000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000d4bc2ab6e4eaecc04d83b389a57a59eecde917090000000000000000000000000000000000000000000000000000000000000005504f5745520000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005504f574552000000000000000000000000000000000000000000000000000000



# generate easily readable abi to /deployments
forge script script/Deploy.s.sol:Deploy --sig 'sync()' --rpc-url $RPC_URL --broadcast --ffi
```
