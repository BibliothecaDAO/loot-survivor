#!/bin/bash

retry_indefinitely() {
  until "$@"; do
    exit_status=$?
    echo "Command failed with exit code $exit_status. Retrying in 1 second..." >&2
    sleep 1
  done
}

# Your script to run multiple commands
retry_indefinitely apibara run --allow-env=env src/adventurers.ts -A dna_jX3t04zs9zywBnHWVmUq --status-server-address 0.0.0.0:1001 &
retry_indefinitely apibara run --allow-env=env src/battles.ts -A dna_jX3t04zs9zywBnHWVmUq --status-server-address 0.0.0.0:1002 &
retry_indefinitely apibara run --allow-env=env src/beasts.ts -A dna_jX3t04zs9zywBnHWVmUq --status-server-address 0.0.0.0:1003 &
retry_indefinitely apibara run --allow-env=env src/discoveries.ts -A dna_jX3t04zs9zywBnHWVmUq --status-server-address 0.0.0.0:1004 &
retry_indefinitely apibara run --allow-env=env src/items.ts -A dna_jX3t04zs9zywBnHWVmUq --status-server-address 0.0.0.0:1005 &

# Wait for all background processes to finish
wait
