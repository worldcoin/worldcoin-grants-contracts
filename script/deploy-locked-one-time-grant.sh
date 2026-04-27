#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

DEPLOY_CONFIG_PATH="${DEPLOY_CONFIG_PATH:-${ROOT_DIR}/script/deploy-config.production.json}"
RPC_URL="${ETH_RPC_URL:-${RPC_URL:-https://worldchain-mainnet.g.alchemy.com/public}}"
DEFAULT_LEDGER_HD_PATH="m/44'/60'/0'/0/0"
LEDGER_HD_PATH="${LEDGER_HD_PATH:-${DEFAULT_LEDGER_HD_PATH}}"

if [[ -z "${ETHERSCAN_API_KEY:-}" ]]; then
  echo "ETHERSCAN_API_KEY is required because this deploy script runs with --verify." >&2
  exit 1
fi

export DEPLOY_CONFIG_PATH

args=(
  "script/LockedOneTimeGrant.s.sol:DeployLockedOneTimeGrant"
  "--fork-url" "${RPC_URL}"
  "--ledger"
  "--mnemonic-derivation-paths" "${LEDGER_HD_PATH}"
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
