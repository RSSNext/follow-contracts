#!/usr/bin/env bash
set -eo pipefail

# List of contracts to generate ABI for
# Add new contracts here when needed
CONTRACTS=(
    "PowerToken"
)

# Color definitions
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ABI_DIR="./deployments/abi"
ABI_SIGNATURE_DIR="./deployments/abi-signature"

# Check if running from project root
if [ ! -d "src" ]; then
    echo -e "${RED}Error: Script must be run from project root './tools/generateABI.sh'${NC}"
    exit 1
fi

# Ensure directories exist
ensure_directories() {
    echo -e "${BLUE}Creating ABI directories if they don't exist...${NC}"
    mkdir -p "${ABI_DIR}"
    mkdir -p "${ABI_SIGNATURE_DIR}"
}

# Build contracts
build_contracts() {
    echo -e "${BLUE}Building contracts...${NC}"
    if ! forge build --silent; then
        echo -e "${RED}Error: Failed to build contracts${NC}"
        exit 1
    fi
}

# Generate ABI for a contract
generate_abi() {
    local contract=$1
    
    echo -e "${BLUE}Generating ABI for ${contract}...${NC}"
    
    # Generate human-readable ABI
    if ! forge inspect "${contract}" abi > "${ABI_SIGNATURE_DIR}/${contract}.abi"; then
        echo -e "${RED}Error: Failed to generate ABI signature for ${contract}${NC}"
        return 1
    fi
    
    # Generate JSON ABI
    if ! forge inspect "${contract}" abi --json > "${ABI_DIR}/${contract}.abi"; then
        echo -e "${RED}Error: Failed to generate JSON ABI for ${contract}${NC}"
        return 1
    fi
    
    echo -e "${GREEN}Successfully generated ABI for ${contract}${NC}"
    return 0
}

# Main function
main() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Starting ABI generation...${NC}"

    export FOUNDRY_PROFILE=no_via_ir
    
    # Ensure directories exist
    ensure_directories
    
    # Build contracts
    build_contracts
    
    # Use the global CONTRACTS array
    local generation_failed=false
    
    # Generate ABI for each contract
    for contract in "${CONTRACTS[@]}"; do
        if ! generate_abi "${contract}"; then
            generation_failed=true
        fi
    done
    
    # Report results
    if [ "$generation_failed" = true ]; then
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${RED}ABI generation failed${NC}"
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        exit 1
    else
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${GREEN}ABI generation completed successfully${NC}"
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    fi
}

# Execute main function
main
