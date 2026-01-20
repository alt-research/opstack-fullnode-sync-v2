#!/bin/bash

# ======================================
# OP Stack Node Sync Status Checker
# ======================================
# This script checks the sync status of both geth and op-node
# Usage: ./scripts/check-sync.sh

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default ports (can be overridden by environment variables)
GETH_HTTP_PORT=${GETH_HTTP_PORT:-8545}
OP_NODE_RPC_PORT=${OP_NODE_RPC_PORT:-9545}

echo "======================================="
echo "OP Stack Node Sync Status Check"
echo "======================================="
echo ""

# ======================================
# Check Geth Sync Status
# ======================================
echo -e "${BLUE}[Geth]${NC} Checking sync status on http://localhost:${GETH_HTTP_PORT}..."

GETH_SYNC=$(curl -s -X POST http://localhost:${GETH_HTTP_PORT} \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' 2>/dev/null)

if [ $? -ne 0 ]; then
  echo -e "${RED}✗ Error: Cannot connect to Geth RPC${NC}"
  echo "  Make sure Geth is running and accessible on port ${GETH_HTTP_PORT}"
  exit 1
fi

# Parse sync status
GETH_SYNCING=$(echo $GETH_SYNC | jq -r '.result')

if [ "$GETH_SYNCING" = "false" ]; then
  echo -e "${GREEN}✓ Geth is fully synced${NC}"

  # Get current block number
  GETH_BLOCK=$(curl -s -X POST http://localhost:${GETH_HTTP_PORT} \
    -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' | jq -r '.result')
  GETH_BLOCK_DEC=$((${GETH_BLOCK}))
  echo "  Current block: ${GETH_BLOCK_DEC} (${GETH_BLOCK})"
else
  echo -e "${YELLOW}⟳ Geth is syncing...${NC}"

  CURRENT_BLOCK=$(echo $GETH_SYNC | jq -r '.result.currentBlock' | xargs printf "%d")
  HIGHEST_BLOCK=$(echo $GETH_SYNC | jq -r '.result.highestBlock' | xargs printf "%d")

  if [ "$CURRENT_BLOCK" != "null" ] && [ "$HIGHEST_BLOCK" != "null" ]; then
    PROGRESS=$(echo "scale=2; ($CURRENT_BLOCK / $HIGHEST_BLOCK) * 100" | bc)
    REMAINING=$((HIGHEST_BLOCK - CURRENT_BLOCK))

    echo "  Current block: ${CURRENT_BLOCK}"
    echo "  Highest block: ${HIGHEST_BLOCK}"
    echo "  Progress: ${PROGRESS}%"
    echo "  Remaining: ${REMAINING} blocks"
  fi
fi

# Get peer count
PEER_COUNT=$(curl -s -X POST http://localhost:${GETH_HTTP_PORT} \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' | jq -r '.result')
PEER_COUNT_DEC=$((${PEER_COUNT}))
echo "  Connected peers: ${PEER_COUNT_DEC}"

echo ""

# ======================================
# Check Op-Node Sync Status
# ======================================
echo -e "${BLUE}[Op-Node]${NC} Checking sync status on http://localhost:${OP_NODE_RPC_PORT}..."

OP_NODE_SYNC=$(curl -s -X POST http://localhost:${OP_NODE_RPC_PORT} \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"optimism_syncStatus","params":[],"id":1}' 2>/dev/null)

if [ $? -ne 0 ]; then
  echo -e "${RED}✗ Error: Cannot connect to Op-Node RPC${NC}"
  echo "  Make sure Op-Node is running and accessible on port ${OP_NODE_RPC_PORT}"
  exit 1
fi

# Check if result is null or error
if echo "$OP_NODE_SYNC" | jq -e '.error' > /dev/null 2>&1; then
  ERROR_MSG=$(echo $OP_NODE_SYNC | jq -r '.error.message')
  echo -e "${RED}✗ Error from Op-Node: ${ERROR_MSG}${NC}"
else
  # Parse sync status
  UNSAFE_L2=$(echo $OP_NODE_SYNC | jq -r '.result.unsafe_l2.number')
  SAFE_L2=$(echo $OP_NODE_SYNC | jq -r '.result.safe_l2.number')
  FINALIZED_L2=$(echo $OP_NODE_SYNC | jq -r '.result.finalized_l2.number')
  CURRENT_L1=$(echo $OP_NODE_SYNC | jq -r '.result.current_l1.number')

  echo -e "${GREEN}✓ Op-Node is running${NC}"
  echo "  Unsafe L2 block:     ${UNSAFE_L2}"
  echo "  Safe L2 block:       ${SAFE_L2}"
  echo "  Finalized L2 block:  ${FINALIZED_L2}"
  echo "  Current L1 block:    ${CURRENT_L1}"

  # Calculate lag
  if [ "$UNSAFE_L2" != "null" ] && [ "$SAFE_L2" != "null" ]; then
    LAG=$((UNSAFE_L2 - SAFE_L2))
    if [ $LAG -gt 100 ]; then
      echo -e "  ${YELLOW}⚠ Lag between unsafe and safe: ${LAG} blocks${NC}"
    else
      echo -e "  ${GREEN}Lag: ${LAG} blocks (healthy)${NC}"
    fi
  fi
fi

# ======================================
# Check Op-Node Output (sequencer endpoint)
# ======================================
echo ""
echo -e "${BLUE}[Op-Node]${NC} Checking output root..."

OUTPUT_ROOT=$(curl -s -X POST http://localhost:${OP_NODE_RPC_PORT} \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"optimism_outputAtBlock","params":["latest"],"id":1}' 2>/dev/null)

if echo "$OUTPUT_ROOT" | jq -e '.result' > /dev/null 2>&1; then
  OUTPUT_VERSION=$(echo $OUTPUT_ROOT | jq -r '.result.version')
  OUTPUT_ROOT_HASH=$(echo $OUTPUT_ROOT | jq -r '.result.outputRoot')
  BLOCK_REF=$(echo $OUTPUT_ROOT | jq -r '.result.blockRef.number')

  echo -e "${GREEN}✓ Output root available${NC}"
  echo "  Version: ${OUTPUT_VERSION}"
  echo "  Block: ${BLOCK_REF}"
  echo "  Output root: ${OUTPUT_ROOT_HASH:0:20}..."
fi

echo ""
echo "======================================="
echo -e "${GREEN}Sync status check complete!${NC}"
echo "======================================="
