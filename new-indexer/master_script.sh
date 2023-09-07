#!/bin/bash

/scripts/run_adventurers.sh &
/scripts/run_battles.sh &
/scripts/run_beasts.sh &
/scripts/run_discoveries.sh &
/scripts/run_items.sh &
/scripts/run_scores.sh &

# Wait for all background jobs to finish (should never happen in this case)
wait
