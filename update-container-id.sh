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

# Dashboards directory
DASHBOARD_DIR="$SCRIPT_DIR/grafana/dashboard-files"

# Get old container ID from any dashboard (if exists)
# Extract 12-char container ID from container_ metric queries
OLD_CONTAINER_ID=$(grep -R "container_" "$DASHBOARD_DIR"/*.json 2>/dev/null | grep -oE '[a-f0-9]{12}' | head -1)

if [ -z "$OLD_CONTAINER_ID" ]; then
    echo -e "${YELLOW}  ⚠ No existing container ID found in dashboard${NC}"
else
    echo -e "  Old container ID: ${YELLOW}${OLD_CONTAINER_ID}${NC}"

    if [ "$OLD_CONTAINER_ID" == "$CONTAINER_ID" ]; then
        echo -e "${GREEN}  ✓ Container ID is already up-to-date!${NC}"
        exit 0
    fi
fi

# Update ALL dashboard JSON files
echo -e "\n${GREEN}[2/5]${NC} Updating dashboards in ${DASHBOARD_DIR}..."
if [ -n "$OLD_CONTAINER_ID" ]; then
    # Replace old ID with new ID in all dashboards
    for f in "$DASHBOARD_DIR"/*.json; do
        sed -i.bak "s/${OLD_CONTAINER_ID}/${CONTAINER_ID}/g" "$f"
        rm -f "${f}.bak"
    done
    echo -e "  ✓ Updated ${OLD_CONTAINER_ID} → ${CONTAINER_ID} in all dashboards"
else
    # First time setup - replace placeholder pattern if exists
    for f in "$DASHBOARD_DIR"/*.json; do
        sed -i.bak -E "s/id=~\"\\.\\*\\/[a-f0-9]{12}\\.\*\"/id=~\".*\\/${CONTAINER_ID}.*\"/g" "$f"
        rm -f "${f}.bak"
    done
    echo -e "  ✓ Set container ID to ${CONTAINER_ID} in all dashboards"
fi

# Restart Grafana to reload dashboards
echo -e "\n${GREEN}[3/5]${NC} Restarting Grafana to reload dashboards..."
cd "$PROJECT_ROOT"
docker compose restart grafana > /dev/null 2>&1
echo -e "  ✓ Grafana restarted"

echo -e "\n${GREEN}✓ Successfully updated container ID!${NC}"
echo ""
echo "Dashboard: http://localhost:3000"
echo "Container ID: ${CONTAINER_ID}"
echo ""
echo -e "${YELLOW}Note:${NC} Run this script after recreating the broker container"
echo "      Example: docker compose up -d --force-recreate broker && ./monitoring/update-container-id.sh"
