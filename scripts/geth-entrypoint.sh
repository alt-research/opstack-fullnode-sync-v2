#!/bin/sh
set -e

# ======================================
# GETH Entrypoint Script
# ======================================

# Set default values if not set
if [ -z ${GETH_HTTP_API+x} ]; then
    export GETH_HTTP_API="web3,eth,txpool,net,engine,debug,miner"
fi

if [ -z ${GETH_WS_API+x} ]; then
    export GETH_WS_API="web3,eth,txpool,net,engine,debug,miner"
fi

# Set default port values if not set
: ${GETH_HTTP_PORT:=8545}
: ${GETH_WS_PORT:=8546}
: ${GETH_AUTHRPC_PORT:=8551}
: ${GETH_METRICS_PORT:=6060}
: ${GETH_P2P_PORT:=30303}
: ${GETH_DATADIR:=/data}

# Create config.toml for static nodes
cat > ${GETH_DATADIR}/config.toml <<EOF
[Node.P2P]
  StaticNodes = ${GETH_STATICNODES}
EOF

echo "Geth P2P bootnodes configuration:"
cat ${GETH_DATADIR}/config.toml

# Initialize geth if datadir is empty
if [ ! -d "${GETH_DATADIR}/geth" ]; then
  echo "Initializing geth datadir with genesis from ${GENESIS_URL}"
  wget -O ${GETH_DATADIR}/genesis.json "${GENESIS_URL}"
  geth init --state.scheme=hash --datadir=${GETH_DATADIR} ${GETH_DATADIR}/genesis.json
else
  echo "Geth datadir already initialized, skipping initialization..."
fi

# Download genesis.json if missing (for reference)
if [ ! -f "${GETH_DATADIR}/genesis.json" ]; then
  echo "Downloading genesis.json for reference"
  wget -O ${GETH_DATADIR}/genesis.json "${GENESIS_URL}"
fi

echo "Starting geth with flags..."

# Build geth command with flags from environment variables
exec geth \
  --config=${GETH_DATADIR}/config.toml \
  --datadir=${GETH_DATADIR} \
  --syncmode=$GETH_SYNCMODE \
  --gcmode=$GETH_GCMODE \
  --port=${GETH_P2P_PORT} \
  --rollup.disabletxpoolgossip=true \
  --rollup.sequencerhttp=$GETH_ROLLUP_SEQUENCERHTTP \
  --http \
  --http.corsdomain="*" \
  --http.vhosts="*" \
  --http.addr=0.0.0.0 \
  --http.port=${GETH_HTTP_PORT} \
  --http.api=$GETH_HTTP_API \
  --ws \
  --ws.addr=0.0.0.0 \
  --ws.port=${GETH_WS_PORT} \
  --ws.api=$GETH_WS_API \
  --authrpc.addr=0.0.0.0 \
  --authrpc.vhosts="*" \
  --authrpc.port=${GETH_AUTHRPC_PORT} \
  --authrpc.jwtsecret=${GETH_DATADIR}/jwt.txt \
  --metrics \
  --metrics.port=${GETH_METRICS_PORT} \
  --metrics.addr=0.0.0.0 \
  ${GETH_OP_NETWORK:+--op-network=$GETH_OP_NETWORK} \
  ${GETH_ROLLUP_SUPERCHAIN_UPGRADES:+--rollup.superchain-upgrades=$GETH_ROLLUP_SUPERCHAIN_UPGRADES}
