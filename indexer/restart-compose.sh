#!/bin/bash

# Path to your docker-compose.yml file
COMPOSE_PATH="goerli-compose.yaml"

# Container names (as specified in docker-compose.yml)
CONTAINER_NAMES=("indexer-adventurers_indexer-1" "indexer-battles_indexer-1" "indexer-beasts_indexer-1" "indexer-discoveries_indexer-1" "indexer-items_indexer-1" "indexer-scores_indexer-1")

# Time to wait between checks (5mins / 300 seconds)
INTERVAL=300

# Check if a block has been processed in the last minute
check_container_activity() {
    local CONTAINER_NAME="$1"
    LAST_LOG=$(docker logs "$CONTAINER_NAME" 2>&1 | tail -1)  # Assuming you want the last log entry
    echo "Extracted log: $LAST_LOG"  # Print timestamp for verification
    LAST_TIMESTAMP=$(echo "$LAST_LOG" | sed -E 's/\x1B\[[0-9;]*[JKmsu]//g' | cut -d' ' -f1)

    echo "Extracted timestamp: $LAST_TIMESTAMP"  # Print timestamp for verification

    # Convert timestamp to epoch (seconds since 1970)
    LAST_EPOCH=$(date -d "$LAST_TIMESTAMP" +%s)
    CURRENT_EPOCH=$(date +%s)
    echo "Current time difference: $((CURRENT_EPOCH - LAST_EPOCH)) seconds"

    # If the difference is more than the interval, return 1 (unhealthy)
    if (( CURRENT_EPOCH - LAST_EPOCH > INTERVAL )); then
        return 1
    else
        return 0
    fi
}

while true; do
    for CONTAINER_NAME in "${CONTAINER_NAMES[@]}"; do
        if ! check_container_activity "$CONTAINER_NAME"; then
            echo "Container $CONTAINER_NAME seems to be stuck. Restarting..."
            docker-compose -f $COMPOSE_PATH stop "$CONTAINER_NAME"
            docker-compose -f $COMPOSE_PATH up -d "$CONTAINER_NAME"
            # # Add a notification mechanism here if needed
        fi
    done
    sleep $INTERVAL
done
