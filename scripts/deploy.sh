#!/bin/bash

# Source env vars
ENV_FILE="/workspaces/loot-survivor/.env"
source $ENV_FILE

# build game contract
cd /workspaces/loot-survivor/contracts/
scarb build

# declare game contract
starkli declare --watch /workspaces/loot-survivor/target/dev/game_Game.contract_class.json --account $STARKNET_ACCOUNT --private-key $PRIVATE_KEY