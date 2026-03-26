# OP Stack Fullnode Sync v2

A single Docker Compose setup for `op-node + reth` fullnode sync.

## What This Repo Does

- Keeps one runtime path only: `reth` + `op-node`
- Uses one `docker-compose.yml` for all supported mode templates
- Keeps `op-node` settings in native `OP_NODE_*` env names
- Keeps reth settings as flag-aligned env names such as `RETH_CHAIN` and `RETH_ROLLUP_SEQUENCER_HTTP`
- Validates one of the six supported mode combinations at startup

## Supported Modes

| Mode | Chain Source | DA Mode | Template |
|------|--------------|---------|----------|
| `custom-ethda` | non-superchain | beacon / blobs | `examples/modes/custom-ethda.env` |
| `custom-legacy-da` | non-superchain | generic AltDA | `examples/modes/custom-legacy-da.env` |
| `custom-generic-da` | non-superchain | AltDA service | `examples/modes/custom-generic-da.env` |
| `superchain-ethda` | superchain | beacon / blobs | `examples/modes/superchain-ethda.env` |
| `superchain-legacy-da` | superchain | generic AltDA | `examples/modes/superchain-legacy-da.env` |
| `superchain-generic-da` | superchain | AltDA service | `examples/modes/superchain-generic-da.env` |

The files under `examples/modes/*.env` are reference templates that describe the supported mode shapes only.
They are not the final delivery config used to run a fullnode.

The model is two-dimensional:

- Chain source:
  `superchain` or `custom`
- DA mode:
  `beacon`, `altda`, or `altda-service`

`reth` only cares whether it should launch with `--chain=<network>` or `--chain=/data/genesis.json`.
`op-node` then cares whether DA comes from beacon, generic AltDA, or AltDA service.

## Quick Start

1. Open `https://wizard.altlayer.io/`.

2. Sign in with the email address that was previously registered with AltLayer.
If your email has not been registered yet, contact an AltLayer team member first.

3. Find your rollup in the dashboard.

4. In the left sidebar, click `Run a Fullnode`.

5. Click `Download .env` to download the generated environment file for that rollup.

6. Place the downloaded file in this repo as `.env`.

7. Generate a JWT secret shared by reth and op-node.

```bash
openssl rand -hex 32 > jwt.txt
```

8. Start the stack.

```bash
docker compose up -d
docker compose logs -f
```

`docker compose` will start a small `config-init` helper first.
It downloads `genesis.json` and `rollup.json` only when the selected mode
provides `GENESIS_URL` or `ROLLUP_CONFIG_URL`. In superchain mode it exits
without downloading anything.

9. Verify sync.

```bash
./scripts/check-sync.sh
```

## Env Model

### Reth

Reth itself launches from flags, so the compose file uses a small set of flag-aligned env variables:

- `RETH_CHAIN`
- `RETH_ROLLUP_SEQUENCER_HTTP`
- `RETH_BOOTNODES`
- `RETH_EXTRA_ARGS`

For superchain mode:

```bash
RETH_CHAIN=your-reth-chain-id
```

`RETH_CHAIN` is the chain identifier reth accepts for `--chain`.
It must be set explicitly in superchain mode.
It may differ from `OP_NODE_NETWORK` depending on how each client names the target network.

For non-superchain mode:

```bash
RETH_CHAIN=/data/genesis.json
GENESIS_URL=https://.../genesis.json
```

For optional network-specific reth flags:

```bash
RETH_EXTRA_ARGS="--flashblocks-url=ws://xxx --flashblock-consensus"
```

`RETH_EXTRA_ARGS` is the extension point for reth-only optional flags.
Platform-generated `.env` should leave room for this field even if most networks keep it empty.

### Op-Node

The `.env` keeps native `OP_NODE_*` names for op-node settings, for example:

- `OP_NODE_NETWORK`
- `OP_NODE_ROLLUP_CONFIG`
- `OP_NODE_L1_ETH_RPC`
- `OP_NODE_L1_BEACON`
- `OP_NODE_L1_BEACON_IGNORE`
- `OP_NODE_ALTDA_ENABLED`
- `OP_NODE_ALTDA_DA_SERVER`
- `OP_NODE_ALTDA_DA_SERVICE`
- `OP_NODE_P2P_STATIC`
- `OP_NODE_SYNCMODE`

For superchain mode:

```bash
OP_NODE_NETWORK=your-op-node-network
```

`OP_NODE_NETWORK` is the network name op-node accepts for `--network`.
It may differ from `RETH_CHAIN` depending on how each client names the target network.

For non-superchain mode:

```bash
OP_NODE_ROLLUP_CONFIG=/data/rollup.json
ROLLUP_CONFIG_URL=https://.../rollup.json
```

For generic AltDA mode:

```bash
OP_NODE_L1_BEACON_IGNORE=true
OP_NODE_ALTDA_ENABLED=true
OP_NODE_ALTDA_DA_SERVER=https://...
```

For AltDA service mode:

```bash
OP_NODE_L1_BEACON_IGNORE=true
OP_NODE_ALTDA_ENABLED=true
OP_NODE_ALTDA_DA_SERVER=https://...
OP_NODE_ALTDA_DA_SERVICE=true
```

## Automatic Behavior

- `config-init` downloads `genesis.json` from `GENESIS_URL` when custom mode uses `/data/genesis.json`
- `RETH_ROLLUP_SEQUENCER_HTTP` is required in this repo for fullnode mode
- `RETH_BOOTNODES` is required in this repo for fullnode mode
- `config-init` downloads `rollup.json` from `ROLLUP_CONFIG_URL` when custom mode uses `/data/rollup.json`
- `node-entrypoint.sh` validates one of the six supported mode combinations:
  `custom/superchain` x `beacon/altda/altda-service`
- AltDA modes require `OP_NODE_ALTDA_ENABLED=true`
- AltDA modes also require `OP_NODE_ALTDA_DA_SERVER` and `OP_NODE_L1_BEACON_IGNORE=true`
- Beacon mode requires `OP_NODE_L1_BEACON`
- `op-node` currently connects to `reth` over `http://reth:8551`
- `OP_NODE_P2P_STATIC` is required in this repo for fullnode mode
- Ports currently live in [docker-compose.yml](docker-compose.yml). If you want different exposed host ports, edit compose directly instead of `.env`.

`OP_NODE_RPC_ENABLE_ADMIN` is optional.
It is not needed for normal fullnode RPC usage, and only exposes op-node admin RPC methods such as `admin_resetDerivationPipeline`.

## Reference

- [Flag Mapping](docs/FLAG_MAPPING.md)

## Ports

| Service | Port | Purpose |
|---------|------|---------|
| reth | 8545 | HTTP RPC |
| reth | 8546 | WebSocket RPC |
| reth | 8551 | Engine API |
| reth | 6060 | Metrics |
| reth | 30303 | P2P |
| op-node | 9545 | RPC |
| op-node | 7300 | Metrics |
| op-node | 9003 | P2P |
