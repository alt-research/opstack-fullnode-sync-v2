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

looks_like_file_path() {
  case "${1:-}" in
    /*|*.json)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

trim_trailing_slash() {
  path="$1"
  case "${path}" in
    /)
      printf '/\n'
      ;;
    */)
      printf '%s\n' "${path%/}"
      ;;
    *)
      printf '%s\n' "${path}"
      ;;
  esac
}

map_data_path() {
  container_path="$1"
  service_data_root="$(trim_trailing_slash "$2")"
  volume_root="$3"

  case "${container_path}" in
    "${service_data_root}")
      printf '%s\n' "${volume_root}"
      ;;
    "${service_data_root}"/*)
      printf '%s/%s\n' "${volume_root}" "${container_path#${service_data_root}/}"
      ;;
    *)
      echo "ERROR: expected path under ${service_data_root}, got ${container_path}"
      return 1
      ;;
  esac
}

reth_genesis_target=""
if [ -n "${GENESIS_URL:-}" ]; then
  if [ -n "${RETH_CHAIN:-}" ]; then
    if ! looks_like_file_path "${RETH_CHAIN}"; then
      echo "ERROR: GENESIS_URL requires RETH_CHAIN to be a file path, got ${RETH_CHAIN}"
      exit 1
    fi
    reth_genesis_target="$(map_data_path "${RETH_CHAIN}" "${RETH_DATADIR}" /reth-data)"
  else
    reth_genesis_target="/reth-data/genesis.json"
  fi
fi

if [ -n "${reth_genesis_target}" ]; then
  mkdir -p "$(dirname "${reth_genesis_target}")"
  echo "Downloading genesis.json from ${GENESIS_URL}"
  download_to "${GENESIS_URL}" "${reth_genesis_target}" || {
    echo "ERROR: failed to download genesis.json"
    exit 1
  }
fi

op_node_rollup_target=""
if [ -n "${ROLLUP_CONFIG_URL:-}" ]; then
  if [ -n "${OP_NODE_NETWORK:-}" ]; then
    echo "ERROR: ROLLUP_CONFIG_URL is mutually exclusive with OP_NODE_NETWORK"
    exit 1
  fi

  if [ -n "${OP_NODE_ROLLUP_CONFIG:-}" ]; then
    op_node_rollup_target="$(map_data_path "${OP_NODE_ROLLUP_CONFIG}" "${OP_NODE_DATADIR}" /node-data)"
  else
    op_node_rollup_target="/node-data/rollup.json"
  fi
fi

if [ -n "${op_node_rollup_target}" ]; then
  mkdir -p "$(dirname "${op_node_rollup_target}")"
  echo "Downloading rollup.json from ${ROLLUP_CONFIG_URL}"
  download_to "${ROLLUP_CONFIG_URL}" "${op_node_rollup_target}" || {
    echo "ERROR: failed to download rollup.json"
    exit 1
  }
fi
