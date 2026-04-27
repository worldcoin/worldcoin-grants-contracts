#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

DEPLOY_CONFIG_PATH="${DEPLOY_CONFIG_PATH:-${ROOT_DIR}/script/deploy-config.production.json}"
RPC_URL="${ETH_RPC_URL:-${RPC_URL:-https://worldchain-mainnet.g.alchemy.com/public}}"
DEFAULT_LEDGER_HD_PATH="m/44'/60'/0'/0/0"
LEDGER_HD_PATH="${LEDGER_HD_PATH:-${DEFAULT_LEDGER_HD_PATH}}"
CREATE2_DEPLOYER="${CREATE2_DEPLOYER:-0x4e59b44847b379578588920ca78fbf26c0b4956c}"

if [[ -z "${CREATE2_SALT:-}" ]]; then
  echo "CREATE2_SALT is required. Use script/grind-locked-one-time-grant-address.mjs to find one." >&2
  exit 1
fi

if [[ -z "${ETHERSCAN_API_KEY:-}" ]]; then
  echo "ETHERSCAN_API_KEY is required because this deploy script runs with --verify." >&2
  exit 1
fi

export CREATE2_DEPLOYER
export CREATE2_SALT
export DEPLOY_CONFIG_PATH

args=(
  "script/LockedOneTimeGrant.s.sol:DeployLockedOneTimeGrantCreate2"
  "--fork-url" "${RPC_URL}"
  "--ledger"
  "--mnemonic-derivation-paths" "${LEDGER_HD_PATH}"
  "--always-use-create-2-factory"
  "--create2-deployer" "${CREATE2_DEPLOYER}"
  "--broadcast"
  "--verify"
  "--etherscan-api-key" "${ETHERSCAN_API_KEY}"
  "-vvvv"
)

if [[ -n "${SENDER:-}" ]]; then
  args+=("--sender" "${SENDER}")
fi

cd "${ROOT_DIR}"
forge script "${args[@]}"
