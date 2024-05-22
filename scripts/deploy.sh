#!/bin/bash

lords_cairo_string=0x6c6f726473
initial_supply=10000000000000000
dao_address=0x06a519DCcd7Ed4D1aACD3975691AEEae47bF7f9F5b62Ed7C2D929D2E27A9CC5E
beasts_address=0x06a519DCcd7Ed4D1aACD3975691AEEae47bF7f9F5b62Ed7C2D929D2E27A9CC5E
collectible_address=0x06a519DCcd7Ed4D1aACD3975691AEEae47bF7f9F5b62Ed7C2D929D2E27A9CC5E
golden_token_address=0x06a519DCcd7Ed4D1aACD3975691AEEae47bF7f9F5b62Ed7C2D929D2E27A9CC5E
terminal_timestamp=0
randomness_contract=0x60c69136b39319547a4df303b6b3a26fab8b2d78de90b6bd215ce82e9cb515c
randomness_rotation_interval=1
oracle_address=0x36031daa264c24520b11d93af622c848b2499b66b41d611bac95e13cfca131a
client_reward_address=0x06a519DCcd7Ed4D1aACD3975691AEEae47bF7f9F5b62Ed7C2D929D2E27A9CC5E
starting_weapon=12
player_name=0x706c6179657231
golden_token_id="0 0"
interface_camel=0
vrf_fee_limit=5000000000000000

# Source env vars
ENV_FILE="/workspaces/loot-survivor/.env"
source $ENV_FILE

# build game contract
cd /workspaces/loot-survivor/contracts/
scarb build

#declare lords contract
lords_class_hash=$(starkli declare --watch /workspaces/loot-survivor/target/dev/lords_ERC20.contract_class.json --account $STARKNET_ACCOUNT --private-key $PRIVATE_KEY 2>/dev/null)

# declare game contract
game_class_hash=$(starkli declare --watch /workspaces/loot-survivor/target/dev/game_Game.contract_class.json --account $STARKNET_ACCOUNT --private-key $PRIVATE_KEY 2>/dev/null)

# deploy lords
lords_contract=$(starkli deploy --watch $lords_class_hash $lords_cairo_string $lords_cairo_string $initial_supply 0 $ACCOUNT_ADDRESS --account $STARKNET_ACCOUNT --private-key $PRIVATE_KEY --max-fee-raw 2224764349828573 2>/dev/null)
sleep 10
echo "lords contract: " $lords_contract

# deploy game
game_contract=$(starkli deploy --watch $game_class_hash $lords_contract $dao_address $collectible_address $golden_token_address $terminal_timestamp $randomness_contract $randomness_rotation_interval $oracle_address --account $STARKNET_ACCOUNT --private-key $PRIVATE_KEY --max-fee-raw 12224764349828573 2>/dev/null)
echo "game contract: " $game_contract
sleep 5

# mint lords
starkli invoke $lords_contract mint $ACCOUNT_ADDRESS 1000000000000000000000 0 --account $STARKNET_ACCOUNT --private-key $PRIVATE_KEY --max-fee-raw 979281252380409 2>/dev/null
sleep 5

# give game contract approval to spent lords
starkli invoke $lords_contract approve $game_contract 1000000000000000000000 0 --account $STARKNET_ACCOUNT --private-key $PRIVATE_KEY --max-fee-raw 979281252380409 2>/dev/null
sleep 5

# transfer eth to game contract so it can pay for VRF
eth_contract=0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7
starkli invoke $eth_contract transfer $game_contract 5000000000000000 0 --account $STARKNET_ACCOUNT --private-key $PRIVATE_KEY --max-fee-raw 979281252380409
sleep 5

# start new game
starkli invoke $game_contract new_game $client_reward_address $starting_weapon $player_name $golden_token_id $interface_camel $vrf_fee_limit --account $STARKNET_ACCOUNT --private-key $PRIVATE_KEY --max-fee-raw 979281252380409

