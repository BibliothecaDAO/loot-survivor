#!/bin/bash

while true; do
  apibara run --allow-env=env-goerli src/scores.ts -A dna_jX3t04zs9zywBnHWVmUq --status-server-address 0.0.0.0:1006 --persist-to-fs=.apibara --sink-id=scores
  echo "Apibara exited with status $? - Restarting..." >&2
  sleep 1
done
