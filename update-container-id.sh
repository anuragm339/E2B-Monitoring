#!/bin/bash

# Script to automatically update container ID in Grafana dashboards
# Usage: ./update-container-id.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Container ID Update Script${NC}"
echo "========================================"

# Get current broker container ID (short hash)
echo -e "\n${GREEN}[1/5]${NC} Finding messaging-broker container..."
CONTAINER_ID=$(docker ps --filter "name=messaging-broker" --format "{{.ID}}")

if [ -z "$CONTAINER_ID" ]; then
    echo -e "${RED}ERROR: messaging-broker container not found!${NC}"
    echo "Please ensure the broker is running: docker compose up -d broker"
    exit 1
fi

echo -e "  ✓ Found container ID: ${GREEN}${CONTAINER_ID}${NC}"

# Get old container ID from dashboard file (if exists)
DASHBOARD_FILE="$SCRIPT_DIR/grafana/dashboard-files/broker-system-metrics.json"
# Extract container ID from container_ metric queries
OLD_CONTAINER_ID=$(grep "container_" "$DASHBOARD_FILE" | grep -oE '[a-f0-9]{12}' | head -1)

if [ -z "$OLD_CONTAINER_ID" ]; then
    echo -e "${YELLOW}  ⚠ No existing container ID found in dashboard${NC}"
else
    echo -e "  Old container ID: ${YELLOW}${OLD_CONTAINER_ID}${NC}"

    if [ "$OLD_CONTAINER_ID" == "$CONTAINER_ID" ]; then
        echo -e "${GREEN}  ✓ Container ID is already up-to-date!${NC}"
        exit 0
    fi
fi

# Update broker-system-metrics.json
echo -e "\n${GREEN}[2/5]${NC} Updating broker-system-metrics.json..."
if [ -n "$OLD_CONTAINER_ID" ]; then
    # Replace old ID with new ID
    sed -i.bak "s/${OLD_CONTAINER_ID}/${CONTAINER_ID}/g" "$DASHBOARD_FILE"
    echo -e "  ✓ Updated ${OLD_CONTAINER_ID} → ${CONTAINER_ID}"
else
    # First time setup - replace placeholder if exists
    sed -i.bak "s/id=~\"\\.\\*\\/[a-f0-9]*\\.\*\"/id=~\".*\/${CONTAINER_ID}.*\"/g" "$DASHBOARD_FILE"
    echo -e "  ✓ Set container ID to ${CONTAINER_ID}"
fi

# Remove backup file
rm -f "${DASHBOARD_FILE}.bak"

# Update data-refresh-overview.json if it exists
REFRESH_DASHBOARD="$SCRIPT_DIR/grafana/dashboard-files/data-refresh-overview.json"
if [ -f "$REFRESH_DASHBOARD" ]; then
    echo -e "\n${GREEN}[3/5]${NC} Checking data-refresh-overview.json..."
    if grep -q "container_id" "$REFRESH_DASHBOARD" 2>/dev/null; then
        if [ -n "$OLD_CONTAINER_ID" ]; then
            sed -i.bak "s/${OLD_CONTAINER_ID}/${CONTAINER_ID}/g" "$REFRESH_DASHBOARD"
            rm -f "${REFRESH_DASHBOARD}.bak"
            echo -e "  ✓ Updated data-refresh-overview.json"
        fi
    else
        echo -e "  ○ No container ID references found"
    fi
else
    echo -e "\n${GREEN}[3/5]${NC} Skipping data-refresh-overview.json (not found)"
fi

# Update storage-disk-health.json if it exists
STORAGE_DASHBOARD="$SCRIPT_DIR/grafana/dashboard-files/storage-disk-health.json"
if [ -f "$STORAGE_DASHBOARD" ]; then
    echo -e "\n${GREEN}[4/5]${NC} Checking storage-disk-health.json..."
    if grep -q "container_" "$STORAGE_DASHBOARD" 2>/dev/null; then
        if [ -n "$OLD_CONTAINER_ID" ]; then
            sed -i.bak "s/${OLD_CONTAINER_ID}/${CONTAINER_ID}/g" "$STORAGE_DASHBOARD"
            rm -f "${STORAGE_DASHBOARD}.bak"
            echo -e "  ✓ Updated storage-disk-health.json"
        fi
    else
        echo -e "  ○ No container ID references found"
    fi
else
    echo -e "\n${GREEN}[4/5]${NC} Skipping storage-disk-health.json (not found)"
fi

# Restart Grafana to reload dashboards
echo -e "\n${GREEN}[5/5]${NC} Restarting Grafana to reload dashboards..."
cd "$PROJECT_ROOT"
docker compose restart grafana > /dev/null 2>&1
echo -e "  ✓ Grafana restarted"

echo -e "\n${GREEN}✓ Successfully updated container ID!${NC}"
echo ""
echo "Dashboard: http://localhost:3000/d/broker-system-metrics"
echo "Container ID: ${CONTAINER_ID}"
echo ""
echo -e "${YELLOW}Note:${NC} Run this script after recreating the broker container"
echo "      Example: docker compose up -d --force-recreate broker && ./monitoring/update-container-id.sh"
