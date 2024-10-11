#!/usr/bin/env bash
set -x

ABI_DIR=./deployments/

forge build --silent

for contract in PowerToken
do
  # extract abi and bin files
  forge inspect ${contract} abi > ${ABI_DIR}/${contract}.abi
done
