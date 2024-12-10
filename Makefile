all: install build

# Install forge dependencies (not needed if submodules are already initialized).
install:; forge install && npm install

# Build contracts and inject the Poseidon library.
build:; forge build 

# Run tests, with debug information and gas reports.
test:; FOUNDRY_PROFILE=debug forge test

# ===== Profiling Rules ===============================================================================================

# Benchmark the tests.
bench:; FOUNDRY_PROFILE=bench forge test --gas-report 

# Snapshot the current test usages.
snapshot:; FOUNDRY_PROFILE=bench forge snapshot 

# ===== Deployment Rules ==============================================================================================

# Deploy contracts 
deploy-airdrop:; node --no-warnings script/deploy.js deploy-airdrop

deploy-airdrop-reservations:; node --no-warnings script/deploy.js deploy-airdrop-reservations

set-allowance-max:; node --no-warnings script/deploy.js set-allowance-max

set-allowance:; node --no-warnings script/deploy.js set-allowance

add-allowed-nullifier-hash-blocker:; node --no-warnings script/deploy.js add-allowed-nullifier-hash-blocker

deploy-wld-grant-pre-grant-4-new:; node --no-warnings script/deploy.js deploy-wld-grant-pre-grant-4-new

deploy-nfc-id:; node --no-warnings script/deploy.js deploy-nfc-id

deploy-gated-multicall3:; node --no-warnings script/deploy.js deploy-gated-multicall3

# ===== Utility Rules =================================================================================================

# Format the solidity code.
format:; forge fmt; npx prettier --write .

# Update forge dependencies.
update:; forge update