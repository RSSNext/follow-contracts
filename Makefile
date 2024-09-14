# include .env file and export its env vars
# (-include to ignore error if it does not exist)
-include .env

all: clean install build foundry-test

# Clean the repo
clean  :; forge clean

# Install the Modules
install :; forge install --no-commit

# Update Dependencies
update:; forge update

# Builds
build  :; forge build

# Tests
# --ffi # enable if you need the `ffi` cheat code on HEVM
foundry-test :; forge clean && forge test --optimize --optimizer-runs 200 -v

# Run solhint
solhint :; solhint -f table "{src,test,scripts}/**/*.sol"

# slither
# to install slither, visit [https://github.com/crytic/slither]
slither :; slither . --fail-low #--triage-mode


# upgradeable check
upgradeable:
	@echo " > \033[32mChecking upgradeable...\033[0m"
	./tools/checkUpgradeable.sh

# check upgradeable contract storage layout
storage-layout:
	@echo " > \033[32mChecking contract storage layout...\033[0m"
	./tools/checkStorageLayout.sh

# Lints
lint :; forge fmt
