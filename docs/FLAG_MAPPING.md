# Flag Mapping

This repo now has one runtime path only: `reth + op-node`.

The config model is intentionally split in two:

- `op-node` keeps native `OP_NODE_*` env names in `.env`
- `reth` uses a thin env-to-flag shim because reth itself is launched via flags

## Reth Mapping

The following env variables are consumed by [scripts/reth-entrypoint.sh](../scripts/reth-entrypoint.sh) and mapped to `op-reth node` flags.

| Env variable | Flag | Notes |
|-------------|------|-------|
| `RETH_CHAIN` | `--chain` | Superchain uses the chain id/name that reth accepts and must be set explicitly. Non-superchain uses `/data/genesis.json`. |
| `RETH_DATADIR` | `--datadir` | Default `/data` |
| `RETH_HTTP_API` | `--http.api` | Optional override |
| `RETH_WS_API` | `--ws.api` | Optional override |
| `RETH_ROLLUP_SEQUENCER_HTTP` | `--rollup.sequencer-http` | Required in this repo for fullnode mode |
| `RETH_BOOTNODES` | `--bootnodes` | Required in this repo for fullnode mode |
| `RETH_VERBOSITY` | raw flag | Example: `-vvv` |
| `RETH_EXTRA_ARGS` | raw flags | Appended verbatim. Use this as the platform-generated extension point for chain-specific optional reth flags such as flashblock args. |

Bootstrap helper variables:

| Helper env | Purpose |
|-----------|---------|
| `GENESIS_URL` | Download source for `RETH_CHAIN=/data/genesis.json` |

## Op-Node Mapping

This is primarily a reference table for users who know the `op-node` flag but want the corresponding official env name.

If you run `op-node --help`, upstream `op-node` prints both the flag and the official env name.

| Flag | Official env | Notes |
|------|--------------|-------|
| `--network` | `OP_NODE_NETWORK` | Superchain mode |
| `--rollup.config` | `OP_NODE_ROLLUP_CONFIG` | Non-superchain rollup config path |
| `--l1` | `OP_NODE_L1_ETH_RPC` | L1 RPC endpoint |
| `--l1.rpckind` | `OP_NODE_L1_RPC_KIND` | Usually `standard` |
| `--l1.rpc-rate-limit` | `OP_NODE_L1_RPC_RATE_LIMIT` | Optional self-imposed L1 RPC rate limit |
| `--l1.trustrpc` | `OP_NODE_L1_TRUST_RPC` | Trust optimization |
| `--l1.beacon` | `OP_NODE_L1_BEACON` | Beacon endpoint |
| `--l1.beacon.ignore` | `OP_NODE_L1_BEACON_IGNORE` | Ignore beacon endpoint startup check |
| `--l2` | `OP_NODE_L2_ENGINE_RPC` | L2 engine RPC |
| `--l2.jwt-secret` | `OP_NODE_L2_ENGINE_AUTH` | JWT secret file |
| `--l2.enginekind` | `OP_NODE_L2_ENGINE_KIND` | Engine kind, e.g. `reth` |
| `--syncmode` | `OP_NODE_SYNCMODE` | Sync mode |
| `--verifier.l1-confs` | `OP_NODE_VERIFIER_L1_CONFS` | L1 confirmation depth for verifier/fullnode mode |
| `--safedb.path` | `OP_NODE_SAFEDB_PATH` | Safe DB path |
| `--rpc.addr` | `OP_NODE_RPC_ADDR` | RPC listen address |
| `--rpc.port` | `OP_NODE_RPC_PORT` | RPC listen port |
| `--rpc.enable-admin` | `OP_NODE_RPC_ENABLE_ADMIN` | Optional admin API |
| `--metrics.enabled` | `OP_NODE_METRICS_ENABLED` | Enable metrics |
| `--metrics.addr` | `OP_NODE_METRICS_ADDR` | Metrics listen address |
| `--metrics.port` | `OP_NODE_METRICS_PORT` | Metrics listen port |
| `--p2p.listen.ip` | `OP_NODE_P2P_LISTEN_IP` | P2P listen IP |
| `--p2p.listen.tcp` | `OP_NODE_P2P_LISTEN_TCP_PORT` | P2P TCP port |
| `--p2p.listen.udp` | `OP_NODE_P2P_LISTEN_UDP_PORT` | P2P UDP port |
| `--p2p.priv.path` | `OP_NODE_P2P_PRIV_PATH` | Peer private key path |
| `--p2p.static` | `OP_NODE_P2P_STATIC` | Static peer list |
| `--p2p.discovery.path` | `OP_NODE_P2P_DISCOVERY_PATH` | Discovery DB path |
| `--p2p.peerstore.path` | `OP_NODE_P2P_PEERSTORE_PATH` | Peerstore DB path |
| `--altda.enabled` | `OP_NODE_ALTDA_ENABLED` | Enable AltDA mode |
| `--altda.da-server` | `OP_NODE_ALTDA_DA_SERVER` | ALTDA server |
| `--altda.da-service` | `OP_NODE_ALTDA_DA_SERVICE` | ALTDA service mode |

In this repo:

- Some of the envs above are exposed directly in `.env`
- Some are currently set in `scripts/node-entrypoint.sh` for simplicity

Bootstrap helper variables:

| Helper env | Purpose |
|-----------|---------|
| `ROLLUP_CONFIG_URL` | Download source for `OP_NODE_ROLLUP_CONFIG=/data/rollup.json` |

## Current Wiring

These values are currently set by the repo and do not need to live in `.env`:

- `op-node` currently connects to `reth` at `http://reth:8551`
- `op-node` currently launches with `--l2.enginekind=reth`
- AltDA mode is currently driven by explicit `OP_NODE_ALTDA_ENABLED=true`
- Current port values:
  - reth HTTP `8545`
  - reth WS `8546`
  - reth Auth RPC `8551`
  - reth metrics `6060`
  - reth P2P `30303`
  - op-node RPC `9545`
  - op-node metrics `7300`
  - op-node P2P TCP/UDP `9003`

## Supported Modes

| Mode | Required keys |
|------|---------------|
| `custom-ethda` | `RETH_CHAIN=/data/genesis.json`, `GENESIS_URL`, `OP_NODE_ROLLUP_CONFIG`, `ROLLUP_CONFIG_URL`, `OP_NODE_L1_BEACON` |
| `custom-legacy-da` | `RETH_CHAIN=/data/genesis.json`, `GENESIS_URL`, `OP_NODE_ROLLUP_CONFIG`, `ROLLUP_CONFIG_URL`, `OP_NODE_L1_BEACON_IGNORE=true`, `OP_NODE_ALTDA_ENABLED=true`, `OP_NODE_ALTDA_DA_SERVER` |
| `custom-generic-da` | `RETH_CHAIN=/data/genesis.json`, `GENESIS_URL`, `OP_NODE_ROLLUP_CONFIG`, `ROLLUP_CONFIG_URL`, `OP_NODE_L1_BEACON_IGNORE=true`, `OP_NODE_ALTDA_ENABLED=true`, `OP_NODE_ALTDA_DA_SERVER`, `OP_NODE_ALTDA_DA_SERVICE=true` |
| `superchain-ethda` | `RETH_CHAIN=<reth-chain>`, `OP_NODE_NETWORK=<op-node-network>`, `OP_NODE_L1_BEACON` |
| `superchain-legacy-da` | `RETH_CHAIN=<reth-chain>`, `OP_NODE_NETWORK=<op-node-network>`, `OP_NODE_L1_BEACON_IGNORE=true`, `OP_NODE_ALTDA_ENABLED=true`, `OP_NODE_ALTDA_DA_SERVER` |
| `superchain-generic-da` | `RETH_CHAIN=<reth-chain>`, `OP_NODE_NETWORK=<op-node-network>`, `OP_NODE_L1_BEACON_IGNORE=true`, `OP_NODE_ALTDA_ENABLED=true`, `OP_NODE_ALTDA_DA_SERVER`, `OP_NODE_ALTDA_DA_SERVICE=true` |

`RETH_CHAIN` and `OP_NODE_NETWORK` are allowed to differ in superchain mode.
Example: `RETH_CHAIN=arena-z`, `OP_NODE_NETWORK=arena-z-mainnet`.
