#!/bin/sh
set -eu

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
  volume_root="$2"

  case "${container_path}" in
    /data/*)
      printf '%s/%s\n' "${volume_root}" "${container_path#/data/}"
      ;;
    /data)
      printf '%s\n' "${volume_root}"
      ;;
    *)
      echo "ERROR: expected path under /data, got ${container_path}"
      return 1
      ;;
  esac
}

if [ -n "${RETH_CHAIN:-}" ]; then
  reth_genesis_target="$(map_data_path "${RETH_CHAIN}" /reth-data)"
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
  op_node_rollup_target="$(map_data_path "${OP_NODE_ROLLUP_CONFIG}" /node-data)"
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
