#!/bin/bash

while true; do
  apibara run --allow-env=env-goerli src/items.ts -A dna_jX3t04zs9zywBnHWVmUq --status-server-address 0.0.0.0:1005 --persist-to-fs=.apibara --sink-id=items
  echo "Apibara exited with status $? - Restarting..." >&2
  sleep 1
done
