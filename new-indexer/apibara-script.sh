#!/bin/bash

# Your script to run multiple commands
apibara run --allow-env=env src/adventurers.ts -A dna_jX3t04zs9zywBnHWVmUq --status-server-address 0.0.0.0:1001 &
apibara run --allow-env=env src/battles.ts -A dna_jX3t04zs9zywBnHWVmUq --status-server-address 0.0.0.0:1002 &
apibara run --allow-env=env src/beasts.ts -A dna_jX3t04zs9zywBnHWVmUq --status-server-address 0.0.0.0:1003 &
apibara run --allow-env=env src/discoveries.ts -A dna_jX3t04zs9zywBnHWVmUq --status-server-address 0.0.0.0:1004 &
apibara run --allow-env=env src/items.ts -A dna_jX3t04zs9zywBnHWVmUq --status-server-address 0.0.0.0:1005 &

# Wait for all background processes to finish
wait
