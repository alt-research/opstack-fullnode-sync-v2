#!/bin/sh
set -eu

: "${RETH_DATADIR:=/data}"
: "${OP_NODE_DATADIR:=/data}"

download_to() {
  url="$1"
  dest="$2"

  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "${url}" -o "${dest}"
  elif command -v wget >/dev/null 2>&1; then
    wget -O "${dest}" "${url}"
  else
    echo "ERROR: neither curl nor wget is available for downloading ${url}"
    return 1
  fi
}

map_data_path() {
  container_path="$1"
  container_root="$2"
  volume_root="$3"

  case "${container_path}" in
    "${container_root}"/*)
      printf '%s/%s\n' "${volume_root}" "${container_path#${container_root}/}"
      ;;
    "${container_root}")
      printf '%s\n' "${volume_root}"
      ;;
    *)
      echo "ERROR: expected path under ${container_root}, got ${container_path}"
      return 1
      ;;
  esac
}

if [ -n "${RETH_CHAIN:-}" ]; then
  reth_genesis_target="$(map_data_path "${RETH_CHAIN}" "${RETH_DATADIR}" /reth-data)"
elif [ -n "${GENESIS_URL:-}" ]; then
  reth_genesis_target="/reth-data/genesis.json"
else
  reth_genesis_target=""
fi

if [ -n "${reth_genesis_target}" ] && [ -n "${GENESIS_URL:-}" ]; then
  mkdir -p "$(dirname "${reth_genesis_target}")"
  echo "Downloading genesis.json from ${GENESIS_URL}"
  download_to "${GENESIS_URL}" "${reth_genesis_target}" || {
    echo "ERROR: failed to download genesis.json"
    exit 1
  }
fi

if [ -n "${OP_NODE_ROLLUP_CONFIG:-}" ]; then
  op_node_rollup_target="$(map_data_path "${OP_NODE_ROLLUP_CONFIG}" "${OP_NODE_DATADIR}" /node-data)"
elif [ -n "${ROLLUP_CONFIG_URL:-}" ]; then
  op_node_rollup_target="/node-data/rollup.json"
else
  op_node_rollup_target=""
fi

if [ -n "${op_node_rollup_target}" ] && [ -n "${ROLLUP_CONFIG_URL:-}" ]; then
  mkdir -p "$(dirname "${op_node_rollup_target}")"
  echo "Downloading rollup.json from ${ROLLUP_CONFIG_URL}"
  download_to "${ROLLUP_CONFIG_URL}" "${op_node_rollup_target}" || {
    echo "ERROR: failed to download rollup.json"
    exit 1
  }
fi
