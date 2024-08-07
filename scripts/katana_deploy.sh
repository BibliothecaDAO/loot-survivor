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
eth_contract=0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7

# Source env vars
ENV_FILE="/workspaces/loot-survivor/.env"
source $ENV_FILE

# build game contract
cd /workspaces/loot-survivor/contracts/
scarb build

katana --disable-fee --block-time 30000 --seed 0x6c6f6f747375727669766f72 --accounts 1 --json-log > ~/katana.log 2>&1 & echo $! > ~/katana_pid.txt
sleep 3
output=$(head -n 1 ~/katana.log | jq -r '.fields.message | fromjson | .accounts[0] | .[0], .[-1].private_key')
account_address_decimal=$(echo "$output" | head -n 1)
echo "account address decimal: " $account_address_decimal   
#account_address is in decimal so convert it to hex
account_address=$(echo "obase=16; ibase=10; $account_address_decimal" | bc | tr '[:upper:]' '[:lower:]')
full_account_address="0x${account_address}"
private_key=$(echo "$output" | tail -n 1)

echo "account address:" $account_address
echo "private key:" $private_key

starkli account fetch --force --output ~/katana_account $account_address
PRIVATE_KEY=$private_key

export STARKNET_RPC="http:127.0.0.1:5050"
export STARKLI_NO_PLAIN_KEY_WARNING="true"
export STARKNET_ACCOUNT="~/katana_account"
#declare lords contract
lords_class_hash=$(starkli declare --watch /workspaces/loot-survivor/target/dev/lords_ERC20.contract_class.json --private-key $PRIVATE_KEY --compiler-version 2.6.2 2>/dev/null)

# declare game contract
game_class_hash=$(starkli declare --watch /workspaces/loot-survivor/target/dev/game_Game.contract_class.json --private-key $PRIVATE_KEY --compiler-version 2.6.2 2>/dev/null)

# deploy lords
lords_contract=$(starkli deploy --watch $lords_class_hash $lords_cairo_string $lords_cairo_string $initial_supply 0 $ACCOUNT_ADDRESS --private-key $PRIVATE_KEY --max-fee 0.01 2>/dev/null)

# deploy game
game_contract=$(starkli deploy --watch $game_class_hash $lords_contract $dao_address $collectible_address $golden_token_address $terminal_timestamp $randomness_contract $randomness_rotation_interval $oracle_address --private-key $PRIVATE_KEY --max-fee 0.01 2>/dev/null)

# mint lords
echo "minting lords"
starkli invoke --watch $lords_contract mint $full_account_address 1000000000000000000000 0 --private-key $PRIVATE_KEY --max-fee 0.01 2>/dev/null

# give game contract approval to spent lords
echo "approving game contract to spend lords"
starkli invoke --watch $lords_contract approve $game_contract 1000000000000000000000 0 --private-key $PRIVATE_KEY --max-fee 0.01 2>/dev/null

# transfer eth to game contract so it can pay for VRF
echo "transfering eth to game contract"
starkli invoke --watch $eth_contract transfer $game_contract 50000000000000000 0 --private-key $PRIVATE_KEY --max-fee 0.01 2>/dev/null

# start new game
echo "starting new game"
starkli invoke --watch $game_contract new_game $client_reward_address $starting_weapon $player_name $golden_token_id $interface_camel $vrf_fee_limit --private-key $PRIVATE_KEY --max-fee 0.01 2>/dev/null

#output contracts and export contract vars
echo "game contract: " $game_contract
echo "lords contract: " $lords_contract
export game_contract
export lords_contract