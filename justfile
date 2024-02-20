set dotenv-load # automatically loads .env file in the current directory
set positional-arguments

test:
    cargo test --workspace

fmt:
    cargo fmt --all

check:
    cargo check --all

lint: fmt
    cargo clippy --all-targets --all-features --workspace

build-contracts:
    forge build

deploy-contracts-local:
    forge script ./script/DeploySpectreLocal.s.sol:DeploySpectre --fork-url $LOCAL_RPC_URL --broadcast

deploy-contracts-testnet:
    forge script ./script/DeploySpectre.s.sol:DeploySpectre --private-key $DEPLOYER_PRIVATE_KEY --fork-url $SEPOLIA_RPC_URL --broadcast

deploy-contracts network: # network one of [MAINNET, GOERLI, SEPOLIA]
    #! /usr/bin/env bash
    RPC_URL="$1_RPC_URL"
    forge script ./script/DeploySpectre.s.sol:DeploySpectre --rpc-url ${!RPC_URL} --broadcast --verify -vvvv
