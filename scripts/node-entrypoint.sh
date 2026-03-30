#!/bin/sh
set -eu

is_true() {
  case "${1:-}" in
    1|true|TRUE|True|yes|YES|on|ON)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

mkdir -p /data/p2p_discovery
mkdir -p /data/p2p_peerstore
mkdir -p /data/safedb
mkdir -p /data

if [ -n "${OP_NODE_NETWORK:-}" ] && { [ -n "${OP_NODE_ROLLUP_CONFIG:-}" ] || [ -n "${ROLLUP_CONFIG_URL:-}" ]; }; then
  echo "ERROR: OP_NODE_NETWORK is mutually exclusive with OP_NODE_ROLLUP_CONFIG and ROLLUP_CONFIG_URL"
  exit 1
fi

if [ -z "${OP_NODE_NETWORK:-}" ] && [ -z "${OP_NODE_ROLLUP_CONFIG:-}" ] && [ -n "${ROLLUP_CONFIG_URL:-}" ]; then
  OP_NODE_ROLLUP_CONFIG=/data/rollup.json
  export OP_NODE_ROLLUP_CONFIG
fi

if [ -n "${OP_NODE_NETWORK:-}" ]; then
  echo "Using superchain network ${OP_NODE_NETWORK}"
elif [ -n "${OP_NODE_ROLLUP_CONFIG:-}" ]; then
  if [ ! -f "${OP_NODE_ROLLUP_CONFIG}" ]; then
    echo "ERROR: expected rollup.json at ${OP_NODE_ROLLUP_CONFIG}"
    echo "Please ensure config-init downloaded it successfully."
    exit 1
  fi
  echo "Using existing rollup config at ${OP_NODE_ROLLUP_CONFIG}"
else
  echo "ERROR: set OP_NODE_NETWORK or OP_NODE_ROLLUP_CONFIG"
  exit 1
fi

if [ -z "${OP_NODE_P2P_STATIC:-}" ]; then
  echo "ERROR: OP_NODE_P2P_STATIC is required for fullnode mode"
  exit 1
fi

if is_true "${OP_NODE_ALTDA_ENABLED:-false}"; then
  if [ -z "${OP_NODE_ALTDA_DA_SERVER:-}" ]; then
    echo "ERROR: OP_NODE_ALTDA_DA_SERVER is required when OP_NODE_ALTDA_ENABLED=true"
    exit 1
  fi
  if ! is_true "${OP_NODE_L1_BEACON_IGNORE:-false}"; then
    echo "ERROR: OP_NODE_L1_BEACON_IGNORE=true is required when OP_NODE_ALTDA_ENABLED=true"
    exit 1
  fi
  if [ -n "${OP_NODE_L1_BEACON:-}" ]; then
    echo "ERROR: OP_NODE_L1_BEACON must not be set in AltDA modes"
    exit 1
  fi
elif [ -n "${OP_NODE_ALTDA_DA_SERVER:-}" ] || is_true "${OP_NODE_ALTDA_DA_SERVICE:-false}"; then
  echo "ERROR: OP_NODE_ALTDA_ENABLED=true is required when using AltDA envs"
  exit 1
else
  if [ -z "${OP_NODE_L1_BEACON:-}" ]; then
    echo "ERROR: OP_NODE_L1_BEACON is required for beacon mode"
    exit 1
  fi
  if is_true "${OP_NODE_L1_BEACON_IGNORE:-false}"; then
    echo "ERROR: OP_NODE_L1_BEACON_IGNORE=true is only valid in AltDA modes"
    exit 1
  fi
fi

echo "Starting op-node"

set -- op-node

exec env \
  OP_NODE_RPC_ADDR="${OP_NODE_RPC_ADDR:-0.0.0.0}" \
  OP_NODE_RPC_PORT="${OP_NODE_RPC_PORT:-9545}" \
  OP_NODE_METRICS_ENABLED="${OP_NODE_METRICS_ENABLED:-true}" \
  OP_NODE_METRICS_ADDR="${OP_NODE_METRICS_ADDR:-0.0.0.0}" \
  OP_NODE_METRICS_PORT="${OP_NODE_METRICS_PORT:-7300}" \
  OP_NODE_P2P_LISTEN_IP="${OP_NODE_P2P_LISTEN_IP:-0.0.0.0}" \
  OP_NODE_P2P_LISTEN_TCP_PORT="${OP_NODE_P2P_LISTEN_TCP_PORT:-9003}" \
  OP_NODE_P2P_LISTEN_UDP_PORT="${OP_NODE_P2P_LISTEN_UDP_PORT:-9003}" \
  OP_NODE_P2P_PRIV_PATH="/data/p2p_priv.txt" \
  OP_NODE_SAFEDB_PATH="/data/safedb" \
  OP_NODE_P2P_DISCOVERY_PATH="/data/p2p_discovery" \
  OP_NODE_P2P_PEERSTORE_PATH="/data/p2p_peerstore" \
  OP_NODE_L2_ENGINE_RPC="${OP_NODE_L2_ENGINE_RPC:-http://reth:8551}" \
  OP_NODE_L2_ENGINE_AUTH="${OP_NODE_L2_ENGINE_AUTH:-/data/jwt.txt}" \
  OP_NODE_L2_ENGINE_KIND="${OP_NODE_L2_ENGINE_KIND:-reth}" \
  OP_NODE_L1_ETH_RPC="${OP_NODE_L1_ETH_RPC}" \
  OP_NODE_L1_RPC_KIND="${OP_NODE_L1_RPC_KIND:-standard}" \
  OP_NODE_L1_TRUST_RPC="${OP_NODE_L1_TRUST_RPC:-true}" \
  OP_NODE_L1_RPC_RATE_LIMIT="${OP_NODE_L1_RPC_RATE_LIMIT:-1000}" \
  OP_NODE_SYNCMODE="${OP_NODE_SYNCMODE:-consensus-layer}" \
  OP_NODE_VERIFIER_L1_CONFS="${OP_NODE_VERIFIER_L1_CONFS:-15}" \
  OP_NODE_P2P_STATIC="${OP_NODE_P2P_STATIC}" \
  OP_NODE_SEQUENCER_ENABLED="${OP_NODE_SEQUENCER_ENABLED:-false}" \
  ${OP_NODE_NETWORK:+OP_NODE_NETWORK="${OP_NODE_NETWORK}"} \
  ${OP_NODE_ROLLUP_CONFIG:+OP_NODE_ROLLUP_CONFIG="${OP_NODE_ROLLUP_CONFIG}"} \
  ${OP_NODE_L1_BEACON:+OP_NODE_L1_BEACON="${OP_NODE_L1_BEACON}"} \
  ${OP_NODE_L1_BEACON_IGNORE:+OP_NODE_L1_BEACON_IGNORE="${OP_NODE_L1_BEACON_IGNORE}"} \
  ${OP_NODE_ALTDA_ENABLED:+OP_NODE_ALTDA_ENABLED="${OP_NODE_ALTDA_ENABLED}"} \
  ${OP_NODE_ALTDA_DA_SERVER:+OP_NODE_ALTDA_DA_SERVER="${OP_NODE_ALTDA_DA_SERVER}"} \
  ${OP_NODE_ALTDA_DA_SERVICE:+OP_NODE_ALTDA_DA_SERVICE="${OP_NODE_ALTDA_DA_SERVICE}"} \
  "$@"
