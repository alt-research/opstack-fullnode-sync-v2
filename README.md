# OP Stack Fullnode Sync v2

A universal Docker Compose configuration for running OP Stack fullnode syncs across different chains and configurations.

## Features

- **Universal Configuration**: Single `docker-compose.yml` supports all OP Stack chain types
- **Environment-Driven**: All configuration via `.env` files - no code changes needed
- **Multiple DA Solutions**: Supports standard L1 DA, ALTDA (EigenDA), and Plasma
- **Superchain Compatible**: Works with both Superchain and non-Superchain networks
- **Plug-and-Play**: Pre-configured examples for popular chains

## Supported Configurations

| Pattern | DA Layer | Rollup Config | Use Case |
|---------|----------|---------------|----------|
| Pattern 1 | L1 Beacon | ROLLUP_CONFIG_URL | Non-Superchain with standard DA |
| Pattern 2 | ALTDA (Plasma/EigenDA) | OP_NODE_NETWORK | Superchain with alternative DA |
| Pattern 3 | L1 Beacon | OP_NODE_NETWORK | Superchain with standard DA |
| Pattern 4 | ALTDA + Service | ROLLUP_CONFIG_URL | Non-Superchain with EigenDA service |

## Prerequisites

### JWT Secret Generation

Before starting the node, you **must** generate a JWT secret that will be shared between geth and op-node for secure communication:

```bash
# Generate a random 32-byte hex string
openssl rand -hex 32 > jwt.txt
```

This file will be mounted as read-only into both containers. **Never commit `jwt.txt` to version control.**

### L1 RPC Provider Requirements

Your L1 RPC endpoint is critical for node operation. Ensure it meets these requirements:

**Requirements:**
- ✓ **Must be Ethereum L1** (mainnet or sepolia) - NOT the L2 you're syncing
- ✓ **Full node required** - Archive node recommended, light clients not supported
- ✓ **Sufficient rate limits** - Syncing requires sustained high throughput
- ✓ **Reliable uptime** - Node will stall if L1 RPC is unavailable
- ✓ **WebSocket support** (optional but recommended for beacon API)

**Recommended Providers:**
- **Self-hosted**: Geth, Erigon, Nethermind, Besu
- **Managed services**: Alchemy, Infura, QuickNode, Ankr
- **Public endpoints**: Use only for testing (rate limits too low for production)

**Example configurations:**
```bash
# Alchemy (recommended for production)
OP_NODE_L1_ETH_RPC=https://eth-mainnet.g.alchemy.com/v2/YOUR_API_KEY
OP_NODE_L1_BEACON=https://eth-mainnet.g.alchemy.com/v2/YOUR_API_KEY

# Infura
OP_NODE_L1_ETH_RPC=https://mainnet.infura.io/v3/YOUR_PROJECT_ID
OP_NODE_L1_BEACON=https://mainnet.infura.io/v3/YOUR_PROJECT_ID

# Self-hosted
OP_NODE_L1_ETH_RPC=http://your-geth-node:8545
OP_NODE_L1_BEACON=http://your-beacon-node:5052
```

**⚠️ Common Mistakes:**
- ❌ Using L2 RPC URL as L1 endpoint
- ❌ Using public endpoints without API keys (rate limited)
- ❌ Using light client or pruned node
- ❌ Not checking beacon API availability for non-ALTDA chains

## Quick Start

### 1. Choose Your Configuration Pattern

We provide 4 ready-to-use configuration patterns:

```bash
# Pattern 1: Standard (ROLLUP_CONFIG_URL + L1_BEACON)
cp examples/.env.pattern1-standard .env

# Pattern 2: Superchain + ALTDA
cp examples/.env.pattern2-superchain-altda .env

# Pattern 3: Superchain + Beacon
cp examples/.env.pattern3-superchain-beacon .env

# Pattern 4: ALTDA + Service
cp examples/.env.pattern4-altda-service .env
```

### 2. Generate JWT Secret

```bash
# Generate JWT secret for geth <-> op-node authentication
openssl rand -hex 32 > jwt.txt
```

### 3. Configure Your Chain

Edit `.env` and update the following required values:

```bash
# For standard chains
OP_NODE_L1_ETH_RPC=https://your-ethereum-rpc.com
OP_NODE_L1_BEACON=https://your-beacon-api.com

# For ALTDA chains
OP_NODE_L1_ETH_RPC=https://your-ethereum-rpc.com
ALTDA_DA_SERVER=https://your-da-server.com
```

### 4. Start the Node

```bash
# Start services
docker-compose up -d

# View logs
docker-compose logs -f

# Check status
docker-compose ps
```

### 5. Verify Sync

Use the provided health check script for comprehensive sync status:

```bash
# Run the health check script
./scripts/check-sync.sh
```

This will show:
- ✓ Geth sync progress and peer count
- ✓ Op-node sync status (unsafe/safe/finalized blocks)
- ✓ L1/L2 block heights
- ✓ Output root information

**Manual checks:**

```bash
# Check geth sync status
curl -X POST http://localhost:8545 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}'

# Check op-node sync status
curl -X POST http://localhost:9545 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"optimism_syncStatus","params":[],"id":1}'
```

## Configuration Types

### Standard Chain (ROLLUP_CONFIG_URL + L1_BEACON)

Used for non-Superchain networks with standard L1 data availability.

**Key Variables**:
- `ROLLUP_CONFIG_URL` - URL to rollup configuration JSON
- `OP_NODE_L1_BEACON` - L1 Beacon API endpoint
- `ALTDA_ENABLED=false`

**Example**: [Pattern 1](examples/.env.pattern1-standard)

### ALTDA Chain (ROLLUP_CONFIG_URL + ALTDA)

Uses alternative data availability layer (EigenDA, Avail, etc.)

**Key Variables**:
- `ROLLUP_CONFIG_URL` - URL to rollup configuration JSON
- `OP_NODE_ALTDA_ENABLED=true`
- `OP_NODE_ALTDA_DA_SERVER` - DA server endpoint
- `OP_NODE_ALTDA_DA_SERVICE=true` - For EigenDA service
- L1_BEACON automatically ignored

**Example**: [Pattern 4](examples/.env.pattern4-altda-service)

### Superchain Standard (OP_NODE_NETWORK + L1_BEACON)

Part of the Superchain with standard L1 DA.

**Key Variables**:
- `OP_NODE_NETWORK` - Network name (e.g., "swell-mainnet")
- `GETH_OP_NETWORK` - Same as OP_NODE_NETWORK
- `OP_NODE_L1_BEACON` - L1 Beacon API endpoint

**Example**: [Pattern 3](examples/.env.pattern3-superchain-beacon)

### Superchain + ALTDA (OP_NODE_NETWORK + ALTDA)

Superchain network using alternative DA.

**Key Variables**:
- `OP_NODE_NETWORK` - Network name (e.g., "cyber-mainnet")
- `GETH_OP_NETWORK` - Same as OP_NODE_NETWORK
- `OP_NODE_ALTDA_ENABLED=true`
- `OP_NODE_ALTDA_DA_SERVER` - DA server endpoint
- L1_BEACON automatically ignored

**Example**: [Pattern 2](examples/.env.pattern2-superchain-altda)

## Documentation

- [Flag to Environment Variable Mapping](docs/FLAG_MAPPING.md) - Complete flag → env var reference
- [.env.example](.env.example) - Template with all available variables and configuration examples

## Troubleshooting

### Genesis Initialization Failed

```bash
# Check genesis URL is accessible
curl -I https://operator-public.s3.us-west-2.amazonaws.com/chain/mainnet/genesis.json

# Restart with fresh data
docker-compose down -v
docker-compose up -d
```

### ALTDA Connection Issues

```bash
# Verify DA server is reachable
curl https://your-da-server.com/health

# Check logs for ALTDA errors
docker-compose logs node | grep -i altda
```

### Rollup Config Download Failed

```bash
# Verify rollup config URL
curl https://operator-public.s3.us-west-2.amazonaws.com/chain/mainnet/rollup.json

# Check op-node startup logs
docker-compose logs node
```

### OP_NODE_NETWORK vs ROLLUP_CONFIG_URL Conflict

If you see: "ERROR: Neither OP_NODE_NETWORK nor ROLLUP_CONFIG_URL is set"

**Solution**: Set exactly ONE of these variables in your `.env`:
- For Superchain: Set `OP_NODE_NETWORK=chain-mainnet`
- For non-Superchain: Set `ROLLUP_CONFIG_URL=https://...`

## Port Reference

| Service | Port | Purpose |
|---------|------|---------|
| geth | 8545 | HTTP RPC |
| geth | 8546 | WebSocket RPC |
| geth | 8551 | Engine API (auth) |
| geth | 6060 | Metrics |
| geth | 30303 | P2P |
| op-node | 9545 | RPC |
| op-node | 7300 | Metrics |
| op-node | 9003 | P2P |

## Resource Requirements

### Minimum Requirements (Archive Node)

- **CPU**: 4 cores
- **RAM**: 16GB
- **Storage**: 500GB+ SSD (grows over time)
- **Network**: Stable internet, no port blocking

### Recommended (Production)

- **CPU**: 8+ cores
- **RAM**: 32GB
- **Storage**: 1TB+ NVMe SSD
- **Network**: 100+ Mbps

---

**Need Help?**

1. Review [docs/FLAG_MAPPING.md](docs/FLAG_MAPPING.md) for environment variable details
2. Try example configurations in [examples/](examples/)
3. Check troubleshooting section above
4. Run `./scripts/check-sync.sh` to monitor sync status
