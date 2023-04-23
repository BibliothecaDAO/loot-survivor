from starknet_py.contract import identifier_manager_from_abi
from starknet_py.utils.data_transformer import FunctionCallSerializer
from apibara.starknet import felt

from typing import Iterator

## TYPES
uint256_abi = {
    "name": "Uint256",
    "type": "struct",
    "size": 2,
    "members": [
        {"name": "low", "offset": 0, "type": "felt"},
        {"name": "high", "offset": 1, "type": "felt"},
    ],
}

adventurer_state_abi = {
    "members": [
        {"name": "Race", "offset": 0, "type": "felt"},
        {"name": "HomeRealm", "offset": 1, "type": "felt"},
        {"name": "Birthdate", "offset": 2, "type": "felt"},
        {"name": "Name", "offset": 3, "type": "felt"},
        {"name": "Order", "offset": 4, "type": "felt"},
        {"name": "ImageHash1", "offset": 5, "type": "felt"},
        {"name": "ImageHash2", "offset": 6, "type": "felt"},
        {"name": "Health", "offset": 7, "type": "felt"},
        {"name": "Level", "offset": 8, "type": "felt"},
        {"name": "Strength", "offset": 9, "type": "felt"},
        {"name": "Dexterity", "offset": 10, "type": "felt"},
        {"name": "Vitality", "offset": 11, "type": "felt"},
        {"name": "Intelligence", "offset": 12, "type": "felt"},
        {"name": "Wisdom", "offset": 13, "type": "felt"},
        {"name": "Charisma", "offset": 14, "type": "felt"},
        {"name": "Luck", "offset": 15, "type": "felt"},
        {"name": "XP", "offset": 16, "type": "felt"},
        {"name": "WeaponId", "offset": 17, "type": "felt"},
        {"name": "ChestId", "offset": 18, "type": "felt"},
        {"name": "HeadId", "offset": 19, "type": "felt"},
        {"name": "WaistId", "offset": 20, "type": "felt"},
        {"name": "FeetId", "offset": 21, "type": "felt"},
        {"name": "HandsId", "offset": 22, "type": "felt"},
        {"name": "NeckId", "offset": 23, "type": "felt"},
        {"name": "RingId", "offset": 24, "type": "felt"},
        {"name": "Status", "offset": 25, "type": "felt"},
        {"name": "Beast", "offset": 26, "type": "felt"},
        {"name": "Upgrading", "offset": 27, "type": "felt"},
    ],
    "name": "AdventurerState",
    "size": 28,
    "type": "struct",
}

thief_state_abi = {
    "members": [
        {"name": "AdventurerId", "offset": 0, "type": "Uint256"},
        {"name": "StartTime", "offset": 2, "type": "felt"},
        {"name": "Gold", "offset": 3, "type": "felt"},
    ],
    "name": "ThiefState",
    "size": 4,
    "type": "struct",
}

beast_state_abi = {
    "members": [
        {"name": "Id", "offset": 0, "type": "felt"},
        {"name": "AttackType", "offset": 1, "type": "felt"},
        {"name": "ArmorType", "offset": 2, "type": "felt"},
        {"name": "Rank", "offset": 3, "type": "felt"},
        {"name": "Prefix_1", "offset": 4, "type": "felt"},
        {"name": "Prefix_2", "offset": 5, "type": "felt"},
        {"name": "Health", "offset": 6, "type": "felt"},
        {"name": "Adventurer", "offset": 7, "type": "felt"},
        {"name": "XP", "offset": 8, "type": "felt"},
        {"name": "Level", "offset": 9, "type": "felt"},
        {"name": "SlainOnDate", "offset": 10, "type": "felt"},
    ],
    "name": "Beast",
    "size": 11,
    "type": "struct",
}

item_state_abi = {
    "members": [
        {"name": "Id", "offset": 0, "type": "felt"},
        {"name": "Slot", "offset": 1, "type": "felt"},
        {"name": "Type", "offset": 2, "type": "felt"},
        {"name": "Material", "offset": 3, "type": "felt"},
        {"name": "Rank", "offset": 4, "type": "felt"},
        {"name": "Prefix_1", "offset": 5, "type": "felt"},
        {"name": "Prefix_2", "offset": 6, "type": "felt"},
        {"name": "Suffix", "offset": 7, "type": "felt"},
        {"name": "Greatness", "offset": 8, "type": "felt"},
        {"name": "CreatedBlock", "offset": 9, "type": "felt"},
        {"name": "XP", "offset": 10, "type": "felt"},
        {"name": "Adventurer", "offset": 11, "type": "felt"},
        {"name": "Bag", "offset": 12, "type": "felt"},
    ],
    "name": "Item",
    "size": 13,
    "type": "struct",
}

bid_abi = {
    "members": [
        {"name": "price", "offset": 0, "type": "felt"},
        {"name": "expiry", "offset": 1, "type": "felt"},
        {"name": "bidder", "offset": 2, "type": "felt"},
        {"name": "status", "offset": 3, "type": "felt"},
        {"name": "item_id", "offset": 4, "type": "felt"},
    ],
    "name": "Bid",
    "size": 5,
    "type": "struct",
}

# ADVENTURER EVENTS
mint_adventurer_abi = {
    "outputs": [
        {"name": "adventurer_id", "type": "Uint256"},
        {"name": "owner", "type": "felt"},
    ],
    "keys": [],
    "name": "MintAdventurer",
    "type": "event",
}

adventurer_update_state_abi = {
    "outputs": [
        {"name": "adventurer_id", "type": "Uint256"},
        {"name": "adventurer_state", "type": "AdventurerState"},
    ],
    "keys": [],
    "name": "UpdateAdventurerState",
    "type": "event",
}

adventurer_level_up_abi = {
    "outputs": [
        {"name": "adventurer_id", "type": "Uint256"},
        {"name": "level", "type": "felt"},
    ],
    "keys": [],
    "name": "AdventurerLeveledUp",
    "type": "event",
}

discovery_abi = {
    "outputs": [
        {"name": "adventurer_id", "type": "Uint256"},
        {"name": "discovery_type", "type": "felt"},
        {"name": "sub_discovery_type", "type": "felt"},
        {"name": "entity_id", "type": "Uint256"},
        {"name": "output_amount", "type": "felt"},
    ],
    "keys": [],
    "name": "Discovery",
    "type": "event",
}

update_thief_state_abi = {
    "outputs": [{"name": "thief_state", "type": "ThiefState"}],
    "keys": [],
    "name": "UpdateThiefState",
    "type": "event",
}


# BEAST EVENTS

create_beast_abi = {
    "outputs": [
        {"name": "beast_token_id", "type": "Uint256"},
        {"name": "beast_state", "type": "Beast"},
    ],
    "keys": [],
    "name": "CreateBeast",
    "type": "event",
}

beast_update_state_abi = {
    "outputs": [
        {"name": "beast_token_id", "type": "Uint256"},
        {"name": "beast_state", "type": "Beast"},
    ],
    "keys": [],
    "name": "UpdateBeastState",
    "type": "event",
}

beast_level_up_abi = {
    "outputs": [
        {"name": "beast_token_id", "type": "Uint256"},
        {"name": "beast_level", "type": "felt"},
    ],
    "keys": [],
    "name": "BeastLevelUp",
    "type": "event",
}

beast_attacked_abi = {
    "outputs": [
        {"name": "beast_token_id", "type": "Uint256"},
        {"name": "adventurer_token_id", "type": "Uint256"},
        {"name": "damage", "type": "felt"},
        {"name": "beast_health", "type": "felt"},
        {"name": "xp_gained", "type": "felt"},
        {"name": "gold_reward", "type": "felt"},
    ],
    "keys": [],
    "name": "BeastAttacked",
    "type": "event",
}

adventurer_attacked_abi = {
    "outputs": [
        {"name": "beast_token_id", "type": "Uint256"},
        {"name": "adventurer_token_id", "type": "Uint256"},
        {"name": "damage", "type": "felt"},
        {"name": "adventurer_health", "type": "felt"},
        {"name": "xp_gained", "type": "felt"},
        {"name": "gold_reward", "type": "felt"},
    ],
    "keys": [],
    "name": "AdventurerAttacked",
    "type": "event",
}

fled_beast_abi = {
    "outputs": [
        {"name": "beast_token_id", "type": "Uint256"},
        {"name": "adventurer_token_id", "type": "Uint256"},
    ],
    "keys": [],
    "name": "FledBeast",
    "type": "event",
}

adventurer_ambushed_abi = {
    "outputs": [
        {"name": "beast_token_id", "type": "Uint256"},
        {"name": "adventurer_token_id", "type": "Uint256"},
        {"name": "damage", "type": "felt"},
        {"name": "adventurer_health", "type": "felt"},
    ],
    "keys": [],
    "name": "AdventurerAmbushed",
    "type": "event",
}

update_gold_balance_abi = {
    "outputs": [
        {"name": "adventurer_token_id", "type": "Uint256"},
        {"name": "balance", "type": "felt"},
    ],
    "keys": [],
    "name": "UpdateGoldBalance",
    "type": "event",
}
# LOOT EVENTS

mint_item_abi = {
    "outputs": [
        {"name": "item_token_id", "type": "Uint256"},
        {"name": "to", "type": "felt"},
        {"name": "adventurer_token_id", "type": "Uint256"},
    ],
    "keys": [],
    "name": "MintItem",
    "type": "event",
}

item_update_state_abi = {
    "outputs": [
        {"name": "item_token_id", "type": "Uint256"},
        {"name": "item", "type": "Item"},
    ],
    "keys": [],
    "name": "UpdateItemState",
    "type": "event",
}

item_xp_increase_abi = {
    "outputs": [
        {"name": "item_token_id", "type": "Uint256"},
    ],
    "keys": [],
    "name": "ItemXPIncrease",
    "type": "event",
}

item_greatness_increase_abi = {
    "outputs": [
        {"name": "item_token_id", "type": "Uint256"},
    ],
    "keys": [],
    "name": "ItemGreatnessIncrease",
    "type": "event",
}

item_prefixes_assigned_abi = {
    "outputs": [
        {"name": "item_token_id", "type": "Uint256"},
    ],
    "keys": [],
    "name": "ItemNamePrefixesAssigned",
    "type": "event",
}

item_suffix_assigned_abi = {
    "outputs": [
        {"name": "item_token_id", "type": "Uint256"},
    ],
    "keys": [],
    "name": "ItemNameSuffixAssigned",
    "type": "event",
}

mint_daily_items_abi = {
    "outputs": [
        {"name": "caller", "type": "felt"},
        {"name": "items_number", "type": "felt"},
    ],
    "keys": [],
    "name": "MintDailyItems",
    "type": "event",
}

claim_item_abi = {
    "outputs": [
        {"name": "market_token_id", "type": "Uint256"},
        {"name": "item_token_id", "type": "Uint256"},
        {"name": "adventurer_token_id", "type": "Uint256"},
        {"name": "owner", "type": "felt"},
    ],
    "keys": [],
    "name": "ClaimItem",
    "type": "event",
}

item_merchant_update_abi = {
    "outputs": [
        {"name": "item", "type": "Item"},
        {"name": "market_item_id", "type": "felt"},
        {"name": "bid", "type": "Bid"},
    ],
    "keys": [],
    "name": "ItemMerchantUpdate",
    "type": "event",
}


## ADVENTURER DECODERS

mint_adventurer_decoder = FunctionCallSerializer(
    abi=mint_adventurer_abi,
    identifier_manager=identifier_manager_from_abi([mint_adventurer_abi, uint256_abi]),
)

adventurer_update_state_decoder = FunctionCallSerializer(
    abi=adventurer_update_state_abi,
    identifier_manager=identifier_manager_from_abi(
        [adventurer_update_state_abi, uint256_abi, adventurer_state_abi]
    ),
)

adventurer_level_up_decoder = FunctionCallSerializer(
    abi=adventurer_level_up_abi,
    identifier_manager=identifier_manager_from_abi(
        [adventurer_level_up_abi, uint256_abi]
    ),
)

discovery_decoder = FunctionCallSerializer(
    abi=discovery_abi,
    identifier_manager=identifier_manager_from_abi([discovery_abi, uint256_abi]),
)

update_thief_state_decoder = FunctionCallSerializer(
    abi=update_thief_state_abi,
    identifier_manager=identifier_manager_from_abi(
        [update_thief_state_abi, thief_state_abi]
    ),
)


def decode_mint_adventurer_event(data):
    return mint_adventurer_decoder.to_python([felt.to_int(d) for d in data])


def decode_update_adventurer_state_event(data):
    return adventurer_update_state_decoder.to_python([felt.to_int(d) for d in data])


def decode_adventurer_level_up_event(data):
    return adventurer_level_up_decoder.to_python([felt.to_int(d) for d in data])


def decode_discovery_event(data):
    return discovery_decoder.to_python([felt.to_int(d) for d in data])


def decode_update_thief_state_event(data):
    return update_thief_state_decoder.to_python([felt.to_int(d) for d in data])


## BEAST DECODERS

create_beast_decoder = FunctionCallSerializer(
    abi=create_beast_abi,
    identifier_manager=identifier_manager_from_abi(
        [create_beast_abi, uint256_abi, beast_state_abi]
    ),
)

beast_update_state_decoder = FunctionCallSerializer(
    abi=beast_update_state_abi,
    identifier_manager=identifier_manager_from_abi(
        [beast_update_state_abi, uint256_abi, beast_state_abi]
    ),
)

beast_level_up_decoder = FunctionCallSerializer(
    abi=beast_level_up_abi,
    identifier_manager=identifier_manager_from_abi([beast_level_up_abi, uint256_abi]),
)

beast_attacked_decoder = FunctionCallSerializer(
    abi=beast_attacked_abi,
    identifier_manager=identifier_manager_from_abi([beast_attacked_abi, uint256_abi]),
)

adventurer_attacked_decoder = FunctionCallSerializer(
    abi=adventurer_attacked_abi,
    identifier_manager=identifier_manager_from_abi(
        [adventurer_attacked_abi, uint256_abi]
    ),
)

fled_beast_decoder = FunctionCallSerializer(
    abi=fled_beast_abi,
    identifier_manager=identifier_manager_from_abi([fled_beast_abi, uint256_abi]),
)

adventurer_ambushed_decoder = FunctionCallSerializer(
    abi=adventurer_ambushed_abi,
    identifier_manager=identifier_manager_from_abi(
        [adventurer_ambushed_abi, uint256_abi]
    ),
)

update_gold_balance_decoder = FunctionCallSerializer(
    abi=update_gold_balance_abi,
    identifier_manager=identifier_manager_from_abi(
        [update_gold_balance_abi, uint256_abi]
    ),
)


def decode_create_beast_event(data):
    return create_beast_decoder.to_python([felt.to_int(d) for d in data])


def decode_beast_state_event(data):
    return beast_update_state_decoder.to_python([felt.to_int(d) for d in data])


def decode_beast_level_up_event(data):
    return beast_level_up_decoder.to_python([felt.to_int(d) for d in data])


def decode_beast_attacked_event(data):
    return beast_attacked_decoder.to_python([felt.to_int(d) for d in data])


def decode_adventurer_attacked_event(data):
    return adventurer_attacked_decoder.to_python([felt.to_int(d) for d in data])


def decode_fled_beast_event(data):
    return fled_beast_decoder.to_python([felt.to_int(d) for d in data])


def decode_adventurer_ambushed_event(data):
    return adventurer_attacked_decoder.to_python([felt.to_int(d) for d in data])


def decode_update_gold_event(data):
    return update_gold_balance_decoder.to_python([felt.to_int(d) for d in data])


## LOOT DECODERS

mint_item_decoder = FunctionCallSerializer(
    abi=mint_item_abi,
    identifier_manager=identifier_manager_from_abi([mint_item_abi, uint256_abi]),
)

item_update_state_decoder = FunctionCallSerializer(
    abi=item_update_state_abi,
    identifier_manager=identifier_manager_from_abi(
        [item_update_state_abi, uint256_abi, item_state_abi]
    ),
)

item_xp_increase_decoder = FunctionCallSerializer(
    abi=item_xp_increase_abi,
    identifier_manager=identifier_manager_from_abi([item_xp_increase_abi, uint256_abi]),
)

item_greatness_increase_decoder = FunctionCallSerializer(
    abi=item_greatness_increase_abi,
    identifier_manager=identifier_manager_from_abi(
        [item_greatness_increase_abi, uint256_abi]
    ),
)

item_prefixes_assigned_decoder = FunctionCallSerializer(
    abi=item_prefixes_assigned_abi,
    identifier_manager=identifier_manager_from_abi(
        [item_prefixes_assigned_abi, uint256_abi]
    ),
)

item_suffix_assigned_decoder = FunctionCallSerializer(
    abi=item_suffix_assigned_abi,
    identifier_manager=identifier_manager_from_abi(
        [item_suffix_assigned_abi, uint256_abi]
    ),
)

mint_daily_items_decoder = FunctionCallSerializer(
    abi=mint_daily_items_abi,
    identifier_manager=identifier_manager_from_abi([mint_daily_items_abi]),
)

claim_item_decoder = FunctionCallSerializer(
    abi=claim_item_abi,
    identifier_manager=identifier_manager_from_abi([claim_item_abi, uint256_abi]),
)

item_merchant_update_decoder = FunctionCallSerializer(
    abi=item_merchant_update_abi,
    identifier_manager=identifier_manager_from_abi(
        [item_merchant_update_abi, item_state_abi, bid_abi]
    ),
)


def decode_item_state_event(data):
    return item_update_state_decoder.to_python([felt.to_int(d) for d in data])


def decode_item_xp_increase_event(data):
    return item_xp_increase_decoder.to_python([felt.to_int(d) for d in data])


def decode_item_greatness_increase_event(data):
    return item_greatness_increase_decoder.to_python([felt.to_int(d) for d in data])


def decode_item_prefixes_assigned_event(data):
    return item_prefixes_assigned_decoder.to_python([felt.to_int(d) for d in data])


def decode_item_suffix_assigned_event(data):
    return item_suffix_assigned_decoder.to_python([felt.to_int(d) for d in data])


def decode_mint_daily_items_event(data):
    return mint_daily_items_decoder.to_python([felt.to_int(d) for d in data])


def decode_claim_item_event(data):
    return claim_item_decoder.to_python([felt.to_int(d) for d in data])


def decode_item_merchant_update_event(data):
    return item_merchant_update_decoder.to_python([felt.to_int(d) for d in data])


def decode_mint_item_event(data):
    return mint_item_decoder.to_python([felt.to_int(d) for d in data])
