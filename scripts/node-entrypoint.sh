#!/bin/sh
set -e

# ======================================
# OP-NODE Entrypoint Script
# ======================================
# This script handles conditional configuration and starts op-node
# Only OP_NODE_* environment variables will be passed to the op-node binary

# Save helper variables before processing
_ROLLUP_CONFIG_URL="${ROLLUP_CONFIG_URL}"
_GENESIS_URL="${GENESIS_URL}"

# Set default values if not set
: ${OP_NODE_DATADIR:=/data}
: ${OP_NODE_SYNCMODE:=execution-layer}
: ${OP_NODE_L1_RPC_KIND:=standard}
: ${OP_NODE_L1_TRUST_RPC:=true}
: ${OP_NODE_RPC_PORT:=9545}
: ${OP_NODE_METRICS_PORT:=7300}
: ${OP_NODE_P2P_TCP_PORT:=9003}
: ${OP_NODE_P2P_UDP_PORT:=9003}
: ${OP_NODE_P2P_PRIV_PATH:=${OP_NODE_DATADIR}/p2p_priv.txt}

# Initialize directories
mkdir -p ${OP_NODE_DATADIR}/p2p_discovery
mkdir -p ${OP_NODE_DATADIR}/p2p_peerstore
mkdir -p ${OP_NODE_DATADIR}/safedb
mkdir -p ${OP_NODE_DATADIR}/admin

echo "==================================="
echo "OP-NODE Configuration"
echo "==================================="

# ======================================
# Rollup Config Processing (OP_NODE_NETWORK and ROLLUP_CONFIG_URL are mutually exclusive)
# ======================================
if [ -n "${OP_NODE_NETWORK}" ]; then
  echo "✓ Using Superchain network: ${OP_NODE_NETWORK}"
  # OP_NODE_NETWORK already set in environment, op-node will use it automatically
elif [ -n "${_ROLLUP_CONFIG_URL}" ]; then
  echo "✓ Downloading rollup.json from: ${_ROLLUP_CONFIG_URL}"
  wget -O ${OP_NODE_DATADIR}/rollup.json "${_ROLLUP_CONFIG_URL}" || {
    echo "✗ Failed to download rollup.json"
    exit 1
  }
  export OP_NODE_ROLLUP_CONFIG=${OP_NODE_DATADIR}/rollup.json
else
  echo "✗ ERROR: Neither OP_NODE_NETWORK nor ROLLUP_CONFIG_URL is set"
  echo "Please set ONE of the following in your .env file:"
  echo "  - OP_NODE_NETWORK=chain-mainnet (for Superchain)"
  echo "  - ROLLUP_CONFIG_URL=https://... (for non-Superchain)"
  exit 1
fi

# ======================================
# ALTDA Conditional Processing
# ======================================
if [ "${OP_NODE_ALTDA_ENABLED}" = "true" ]; then
  echo "✓ ALTDA enabled"
  echo "  - DA Server: ${OP_NODE_ALTDA_DA_SERVER}"

  if [ "${OP_NODE_ALTDA_DA_SERVICE}" = "true" ]; then
    echo "  - ALTDA DA Service enabled"
  fi

  # Automatically ignore L1 Beacon
  export OP_NODE_L1_BEACON_IGNORE=true
  unset OP_NODE_L1_BEACON
  echo "  - L1 Beacon ignored (ALTDA mode)"
elif [ -n "${OP_NODE_L1_BEACON}" ]; then
  echo "✓ Using L1 Beacon: ${OP_NODE_L1_BEACON}"
else
  echo "⚠ Warning: Neither ALTDA nor L1_BEACON is configured"
fi

# ======================================
# Clean up helper variables
# ======================================
# Unset non-OP_NODE variables to keep environment clean
unset GENESIS_URL ROLLUP_CONFIG_URL
unset NODE_IMAGE GETH_IMAGE
unset GETH_DATADIR GETH_SYNCMODE GETH_GCMODE GETH_AUTHRPC_ADDR GETH_AUTHRPC_PORT
unset GETH_AUTHRPC_VHOSTS GETH_AUTHRPC_JWTSECRET GETH_HTTP GETH_HTTP_ADDR GETH_HTTP_PORT
unset GETH_HTTP_API GETH_HTTP_CORSDOMAIN GETH_HTTP_VHOSTS GETH_WS GETH_WS_ADDR
unset GETH_WS_PORT GETH_WS_API GETH_WS_ORIGINS GETH_METRICS GETH_METRICS_ADDR
unset GETH_METRICS_PORT GETH_ROLLUP_SEQUENCERHTTP GETH_ROLLUP_DISABLETXPOOLGOSSIP
unset GETH_STATICNODES GETH_DISCOVERY_PORT GETH_OP_NETWORK GETH_ROLLUP_SUPERCHAIN_UPGRADES
unset GETH_P2P_PORT

echo "==================================="
echo "Starting op-node with flags..."
echo "==================================="

# Build op-node command with flags from environment variables
# Use printf to build command array to avoid trailing backslash issues
exec op-node \
  ${OP_NODE_NETWORK:+--network=$OP_NODE_NETWORK} \
  ${OP_NODE_ROLLUP_CONFIG:+--rollup.config=$OP_NODE_ROLLUP_CONFIG} \
  --syncmode=${OP_NODE_SYNCMODE} \
  --safedb.path=${OP_NODE_DATADIR}/safedb \
  --l1=$OP_NODE_L1_ETH_RPC \
  --l1.rpckind=${OP_NODE_L1_RPC_KIND} \
  ${OP_NODE_L1_BEACON:+--l1.beacon=$OP_NODE_L1_BEACON} \
  ${OP_NODE_L1_BEACON_IGNORE:+--l1.beacon-ignore} \
  ${OP_NODE_L1_TRUST_RPC:+--l1.trustrpc} \
  --l2=http://geth:${GETH_AUTHRPC_PORT:-8551} \
  --l2.jwt-secret=${OP_NODE_DATADIR}/jwt.txt \
  --metrics.enabled \
  --metrics.port=${OP_NODE_METRICS_PORT} \
  --metrics.addr=0.0.0.0 \
  --rpc.addr=0.0.0.0 \
  --rpc.port=${OP_NODE_RPC_PORT} \
  --p2p.listen.ip=0.0.0.0 \
  --p2p.listen.tcp=${OP_NODE_P2P_TCP_PORT} \
  --p2p.listen.udp=${OP_NODE_P2P_UDP_PORT} \
  ${OP_NODE_P2P_STATIC:+--p2p.static=$OP_NODE_P2P_STATIC} \
  --p2p.discovery.path=${OP_NODE_DATADIR}/p2p_discovery \
  --p2p.peerstore.path=${OP_NODE_DATADIR}/p2p_peerstore \
  --p2p.priv.path=${OP_NODE_P2P_PRIV_PATH} \
  ${OP_NODE_ALTDA_ENABLED:+--altda.enabled} \
  ${OP_NODE_ALTDA_DA_SERVER:+--altda.da-server=$OP_NODE_ALTDA_DA_SERVER} \
  ${OP_NODE_ALTDA_DA_SERVICE:+--altda.da-service} \
  $OP_NODE_EXTRA_FLAGS
