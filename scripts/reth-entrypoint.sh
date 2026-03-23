#!/bin/sh
set -eu

: "${RETH_DATADIR:=/data}"
: "${RETH_HTTP_API:=admin,net,eth,web3,debug,trace,txpool,miner}"
: "${RETH_WS_API:=net,eth,web3,debug,trace,txpool,miner}"

mkdir -p "${RETH_DATADIR}"

if [ -z "${RETH_ROLLUP_SEQUENCER_HTTP:-}" ]; then
  echo "ERROR: RETH_ROLLUP_SEQUENCER_HTTP is required for fullnode mode"
  exit 1
fi

if [ -z "${RETH_BOOTNODES:-}" ]; then
  echo "ERROR: RETH_BOOTNODES is required for fullnode mode"
  exit 1
fi

if [ -z "${RETH_CHAIN:-}" ]; then
  if [ -n "${GENESIS_URL:-}" ]; then
    RETH_CHAIN="${RETH_DATADIR}/genesis.json"
  else
    echo "ERROR: set RETH_CHAIN explicitly, or provide GENESIS_URL for custom mode"
    exit 1
  fi
fi

case "${RETH_CHAIN}" in
  /*|*.json)
    if [ ! -f "${RETH_CHAIN}" ]; then
      if [ -z "${GENESIS_URL:-}" ]; then
        echo "ERROR: GENESIS_URL is required when RETH_CHAIN points to a local genesis file"
        exit 1
      fi

      mkdir -p "$(dirname "${RETH_CHAIN}")"
      echo "Downloading genesis.json from ${GENESIS_URL}"
      wget -O "${RETH_CHAIN}" "${GENESIS_URL}" || {
        echo "ERROR: failed to download genesis.json"
        exit 1
      }
    else
      echo "Using existing genesis file at ${RETH_CHAIN}"
    fi
    ;;
  *)
    echo "Using superchain chain id ${RETH_CHAIN}"
    if [ -n "${OP_NODE_NETWORK:-}" ]; then
      echo "Op-node network is ${OP_NODE_NETWORK}"
    fi
    ;;
esac

echo "Starting op-reth"

exec op-reth node \
  ${RETH_VERBOSITY:+$RETH_VERBOSITY} \
  --chain="${RETH_CHAIN}" \
  --datadir="${RETH_DATADIR}" \
  --http \
  --http.addr=0.0.0.0 \
  --http.port=8545 \
  --http.corsdomain="*" \
  --http.api="${RETH_HTTP_API}" \
  --ws \
  --ws.addr=0.0.0.0 \
  --ws.port=8546 \
  --ws.origins="*" \
  --ws.api="${RETH_WS_API}" \
  --authrpc.addr=0.0.0.0 \
  --authrpc.port=8551 \
  --authrpc.jwtsecret="${RETH_DATADIR}/jwt.txt" \
  --port=30303 \
  --discovery.port=30303 \
  --metrics=0.0.0.0:6060 \
  --rollup.sequencer-http="${RETH_ROLLUP_SEQUENCER_HTTP}" \
  --bootnodes="${RETH_BOOTNODES}" \
  ${RETH_EXTRA_ARGS:-}
