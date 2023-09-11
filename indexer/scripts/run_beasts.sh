#!/bin/bash

while true; do
  apibara run --allow-env=env-goerli src/beasts.ts -A dna_jX3t04zs9zywBnHWVmUq --status-server-address 0.0.0.0:1003 --persist-to-fs=.apibara --sink-id=beasts
  echo "Apibara exited with status $? - Restarting..." >&2
  sleep 1
done
