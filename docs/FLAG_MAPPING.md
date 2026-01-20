# Flag to Environment Variable Mapping

This document shows how environment variables map to command-line flags for geth and op-node.

## Geth Flags → Environment Variables

| Flag | Environment Variable | Default | Example |
|------|---------------------|---------|---------|
| `--datadir` | `GETH_DATADIR` | `/data` | `GETH_DATADIR=/data` |
| `--syncmode` | `GETH_SYNCMODE` | - | `GETH_SYNCMODE=full` |
| `--gcmode` | `GETH_GCMODE` | - | `GETH_GCMODE=archive` |
| `--port` | `GETH_P2P_PORT` | `30303` | `GETH_P2P_PORT=30303` |
| `--rollup.disabletxpoolgossip` | Hardcoded | `true` | - |
| `--rollup.sequencerhttp` | `GETH_ROLLUP_SEQUENCERHTTP` | - | `GETH_ROLLUP_SEQUENCERHTTP=https://rpc.example.com` |
| `--http` | Hardcoded | `enabled` | - |
| `--http.corsdomain` | Hardcoded | `"*"` | - |
| `--http.vhosts` | Hardcoded | `"*"` | - |
| `--http.addr` | Hardcoded | `0.0.0.0` | - |
| `--http.port` | `GETH_HTTP_PORT` | `8545` | `GETH_HTTP_PORT=8545` |
| `--http.api` | `GETH_HTTP_API` | `web3,eth,txpool,net,engine,debug,miner` | - |
| `--ws` | Hardcoded | `enabled` | - |
| `--ws.addr` | Hardcoded | `0.0.0.0` | - |
| `--ws.port` | `GETH_WS_PORT` | `8546` | `GETH_WS_PORT=8546` |
| `--ws.api` | `GETH_WS_API` | `web3,eth,txpool,net,engine,debug,miner` | - |
| `--authrpc.addr` | Hardcoded | `0.0.0.0` | - |
| `--authrpc.vhosts` | Hardcoded | `"*"` | - |
| `--authrpc.port` | `GETH_AUTHRPC_PORT` | `8551` | `GETH_AUTHRPC_PORT=8551` |
| `--authrpc.jwtsecret` | Path | `${GETH_DATADIR}/jwt.txt` | - |
| `--metrics` | Hardcoded | `enabled` | - |
| `--metrics.port` | `GETH_METRICS_PORT` | `6060` | `GETH_METRICS_PORT=6060` |
| `--metrics.addr` | Hardcoded | `0.0.0.0` | - |
| `--config` | Generated | `${GETH_DATADIR}/config.toml` | From `GETH_STATICNODES` |
| `--op-network` | `GETH_OP_NETWORK` | - | `GETH_OP_NETWORK=base-mainnet` |
| `--rollup.superchain-upgrades` | `GETH_ROLLUP_SUPERCHAIN_UPGRADES` | - | `GETH_ROLLUP_SUPERCHAIN_UPGRADES=false` |

**Note**: Static nodes are configured via `/data/config.toml` file generated from `GETH_STATICNODES` environment variable.

## OP-Node Flags → Environment Variables

| Flag | Environment Variable | Default | Example |
|------|---------------------|---------|---------|
| `--network` | `OP_NODE_NETWORK` | - | `OP_NODE_NETWORK=base-mainnet` |
| `--rollup.config` | `OP_NODE_ROLLUP_CONFIG` | Auto-set | Downloaded from `ROLLUP_CONFIG_URL` |
| `--syncmode` | `OP_NODE_SYNCMODE` | `execution-layer` | `OP_NODE_SYNCMODE=execution-layer` |
| `--safedb.path` | Path | `${OP_NODE_DATADIR}/safedb` | - |
| `--l1` | `OP_NODE_L1_ETH_RPC` | - | `OP_NODE_L1_ETH_RPC=https://eth-rpc.example.com` |
| `--l1.rpckind` | `OP_NODE_L1_RPC_KIND` | `standard` | `OP_NODE_L1_RPC_KIND=standard` |
| `--l1.beacon` | `OP_NODE_L1_BEACON` | - | `OP_NODE_L1_BEACON=https://beacon-api.example.com` |
| `--l1.beacon-ignore` | Auto-set | - | Auto-set when `OP_NODE_ALTDA_ENABLED=true` |
| `--l1.trustrpc` | `OP_NODE_L1_TRUST_RPC` | `true` | `OP_NODE_L1_TRUST_RPC=true` |
| `--l2` | Computed | `http://geth:${GETH_AUTHRPC_PORT}` | - |
| `--l2.jwt-secret` | Path | `${OP_NODE_DATADIR}/jwt.txt` | - |
| `--metrics.enabled` | Hardcoded | `enabled` | - |
| `--metrics.port` | `OP_NODE_METRICS_PORT` | `7300` | `OP_NODE_METRICS_PORT=7300` |
| `--metrics.addr` | Hardcoded | `0.0.0.0` | - |
| `--rpc.addr` | Hardcoded | `0.0.0.0` | - |
| `--rpc.port` | `OP_NODE_RPC_PORT` | `9545` | `OP_NODE_RPC_PORT=9545` |
| `--p2p.listen.ip` | Hardcoded | `0.0.0.0` | - |
| `--p2p.listen.tcp` | `OP_NODE_P2P_TCP_PORT` | `9003` | `OP_NODE_P2P_TCP_PORT=9003` |
| `--p2p.listen.udp` | `OP_NODE_P2P_UDP_PORT` | `9003` | `OP_NODE_P2P_UDP_PORT=9003` |
| `--p2p.static` | `OP_NODE_P2P_STATIC` | - | `OP_NODE_P2P_STATIC=/dns/bootnode...` |
| `--p2p.discovery.path` | Path | `${OP_NODE_DATADIR}/p2p_discovery` | - |
| `--p2p.peerstore.path` | Path | `${OP_NODE_DATADIR}/p2p_peerstore` | - |
| `--p2p.priv.path` | `OP_NODE_P2P_PRIV_PATH` | `${OP_NODE_DATADIR}/p2p_priv.txt` | - |
| `--altda.enabled` | `OP_NODE_ALTDA_ENABLED` | - | `OP_NODE_ALTDA_ENABLED=true` |
| `--altda.da-server` | `OP_NODE_ALTDA_DA_SERVER` | - | `OP_NODE_ALTDA_DA_SERVER=https://da-server.com` |
| `--altda.da-service` | `OP_NODE_ALTDA_DA_SERVICE` | - | `OP_NODE_ALTDA_DA_SERVICE=true` |
| Extra flags | `OP_NODE_EXTRA_FLAGS` | - | `OP_NODE_EXTRA_FLAGS="--log.level=debug"` |

## How It Works

The startup scripts ([geth-entrypoint.sh](../scripts/geth-entrypoint.sh) and [node-entrypoint.sh](../scripts/node-entrypoint.sh)) convert environment variables to command-line flags.

For example:
```bash
# In .env file
GETH_SYNCMODE=full
GETH_ROLLUP_SEQUENCERHTTP=https://rpc.example.com
OP_NODE_L1_ETH_RPC=https://ethereum-rpc.publicnode.com
OP_NODE_L1_BEACON=https://ethereum-beacon-api.publicnode.com

# Converted to flags in geth-entrypoint.sh
exec geth \
  --syncmode=$GETH_SYNCMODE \
  --rollup.sequencerhttp=$GETH_ROLLUP_SEQUENCERHTTP

# Converted to flags in node-entrypoint.sh
exec op-node \
  --l1=$OP_NODE_L1_ETH_RPC \
  --l1.beacon=$OP_NODE_L1_BEACON
```

This approach provides:
- **Direct mapping**: Environment variables use official `GETH_*` and `OP_NODE_*` prefixes
- **Clear correspondence**: See exactly which environment variable maps to which flag
- **Official naming**: Matches the naming convention used in Kubernetes deployments
- **Easy debugging**: Startup logs show the actual flags used
- **Consistent behavior**: Same configuration across Docker and Kubernetes

## Simplified Configuration

Compared to a full manual flag setup, this implementation:

- **Hardcodes sensible defaults** for network/RPC/metrics settings
- **Exposes only essential variables** that users typically need to customize
- **Uses official naming** matching geth and op-node conventions
- **Matches K8s deployments** for consistency across environments
