from starknet_py.contract import identifier_manager_from_abi
from starknet_py.utils.data_transformer import FunctionCallSerializer
from apibara.starknet import felt

from typing import Iterator

## TYPES
uint256_abi = {
    "name": "core::integer::u256",
    "type": "struct",
    "members": [
        {"name": "low", "type": "core::integer::u128"},
        {"name": "high", "type": "core::integer::u128"},
    ],
}

adventurer_metadata_abi = {
    "name": "survivor::adventurer_meta::AdventurerMetadata",
    "type": "struct",
    "members": [
        {"name": "name", "type": "core::integer::u32"},
        {"name": "home_realm", "type": "core::integer::u8"},
        {"name": "race", "type": "core::integer::u8"},
        {"name": "order", "type": "core::integer::u8"},
        {"name": "entropy", "type": "core::integer::u64"},
    ],
}

adventurer_abi = {
    "name": "survivor::adventurer::Adventurer",
    "type": "struct",
    "members": [
        {"name": "last_action", "type": "core::integer::u16"},
        {"name": "health", "type": "core::integer::u16"},
        {"name": "xp", "type": "core::integer::u16"},
        {"name": "stats", "type": "survivor::adventurer::Stats"},
        {"name": "gold", "type": "core::integer::u16"},
        {"name": "weapon", "type": "survivor::bag::LootStatistics"},
        {"name": "chest", "type": "survivor::bag::LootStatistics"},
        {"name": "head", "type": "survivor::bag::LootStatistics"},
        {"name": "waist", "type": "survivor::bag::LootStatistics"},
        {"name": "foot", "type": "survivor::bag::LootStatistics"},
        {"name": "hand", "type": "survivor::bag::LootStatistics"},
        {"name": "neck", "type": "survivor::bag::LootStatistics"},
        {"name": "ring", "type": "survivor::bag::LootStatistics"},
        {"name": "beast_health", "type": "core::integer::u16"},
        {"name": "stat_upgrade_available", "type": "core::integer::u8"},
    ],
}

bag_abi = {
    "name": "survivor::bag::Bag",
    "type": "struct",
    "members": [
        {"name": "item_1", "type": "survivor::bag::LootStatistics"},
        {"name": "item_2", "type": "survivor::bag::LootStatistics"},
        {"name": "item_3", "type": "survivor::bag::LootStatistics"},
        {"name": "item_4", "type": "survivor::bag::LootStatistics"},
        {"name": "item_5", "type": "survivor::bag::LootStatistics"},
        {"name": "item_6", "type": "survivor::bag::LootStatistics"},
        {"name": "item_7", "type": "survivor::bag::LootStatistics"},
        {"name": "item_8", "type": "survivor::bag::LootStatistics"},
        {"name": "item_9", "type": "survivor::bag::LootStatistics"},
        {"name": "item_10", "type": "survivor::bag::LootStatistics"},
        {"name": "item_11", "type": "survivor::bag::LootStatistics"},
    ],
}

adventurer_state_abi = {
    "name": "game::game::game::Game::AdventurerState",
    "type": "struct",
    "outputs": [
        {"name": "owner", "type": "core::starknet::contract_address::ContractAddress"},
        {"name": "adventurer_id", "type": "core::integer::u256"},
        {"name": "adventurer", "type": "survivor::adventurer::Adventurer"},
    ],
}

adventurer_state_with_bag_abi = {
    "name": "game::game::game::Game::AdventurerStateWithBag",
    "type": "struct",
    "members": [
        {"name": "adventurer_state", "type": "game::game::game::Game::AdventurerState"},
        {"name": "bag", "type": "survivor::bag::Bag"},
    ],
}

loot_statistics_abi = {
    "name": "survivor::bag::LootStatistics",
    "type": "struct",
    "members": [
        {"name": "id", "type": "core::integer::u8"},
        {"name": "xp", "type": "core::integer::u16"},
        {"name": "metadata", "type": "core::integer::u8"},
    ],
}


loot_item_special_names_abi = {
    "name": "survivor::item_meta::LootItemSpecialNames",
    "type": "struct",
    "members": [
        {"name": "name_prefix", "type": "core::integer::u8"},
        {"name": "name_suffix", "type": "core::integer::u8"},
        {"name": "item_suffix", "type": "core::integer::u8"},
    ],
}

# GAME EVENTS

start_game_abi = {
    "kind": "struct",
    "name": "game::game::game::Game::StartGame",
    "type": "event",
    "outputs": [
        {
            "kind": "data",
            "name": "adventurer_state",
            "type": "game::game::game::Game::AdventurerState",
        },
        {
            "kind": "data",
            "name": "adventurer_meta",
            "type": "survivor::adventurer_meta::AdventurerMetadata",
        },
    ],
}

stat_upgraded_abi = {
    "kind": "struct",
    "name": "game::game::game::Game::StatUpgraded",
    "type": "event",
    "outputs": [
        {
            "kind": "data",
            "name": "adventurer_state",
            "type": "game::game::game::Game::AdventurerState",
        },
        {"kind": "data", "name": "stat_id", "type": "core::integer::u8"},
    ],
}

discover_health_abi = {
    "kind": "struct",
    "name": "game::game::game::Game::DiscoverHealth",
    "type": "event",
    "outputs": [
        {
            "kind": "data",
            "name": "adventurer_state",
            "type": "game::game::game::Game::AdventurerState",
        },
        {"kind": "data", "name": "health_amount", "type": "core::integer::u16"},
    ],
}

discover_gold_abi = {
    "kind": "struct",
    "name": "game::game::game::Game::DiscoverGold",
    "type": "event",
    "outputs": [
        {
            "kind": "data",
            "name": "adventurer_state",
            "type": "game::game::game::Game::AdventurerState",
        },
        {"kind": "data", "name": "gold_amount", "type": "core::integer::u16"},
    ],
}

disocver_xp_abi = {
    "kind": "struct",
    "name": "game::game::game::Game::DiscoverXP",
    "type": "event",
    "outputs": [
        {
            "kind": "data",
            "name": "adventurer_state",
            "type": "game::game::game::Game::AdventurerState",
        },
        {"kind": "data", "name": "xp_amount", "type": "core::integer::u16"},
    ],
}

discover_obstacle_abi = {
    "kind": "struct",
    "name": "game::game::game::Game::DiscoverObstacle",
    "type": "event",
    "outputs": [
        {
            "kind": "data",
            "name": "adventurer_state",
            "type": "game::game::game::Game::AdventurerState",
        },
        {"kind": "data", "name": "id", "type": "core::integer::u8"},
        {"kind": "data", "name": "level", "type": "core::integer::u16"},
        {"kind": "data", "name": "dodged", "type": "core::bool"},
        {"kind": "data", "name": "damage_taken", "type": "core::integer::u16"},
        {"kind": "data", "name": "damage_location", "type": "core::integer::u8"},
        {"kind": "data", "name": "xp_earned_adventurer", "type": "core::integer::u16"},
        {"kind": "data", "name": "xp_earned_items", "type": "core::integer::u16"},
    ],
}

discover_beast_abi = {
    "kind": "struct",
    "name": "game::game::game::Game::DiscoverBeast",
    "type": "event",
    "outputs": [
        {
            "kind": "data",
            "name": "adventurer_state",
            "type": "game::game::game::Game::AdventurerState",
        },
        {"kind": "data", "name": "id", "type": "core::integer::u8"},
        {"kind": "data", "name": "level", "type": "core::integer::u16"},
        {"kind": "data", "name": "ambushed", "type": "core::bool"},
        {"kind": "data", "name": "damage_taken", "type": "core::integer::u16"},
        {"kind": "data", "name": "health", "type": "core::integer::u16"},
        {"kind": "data", "name": "prefix1", "type": "core::integer::u8"},
        {"kind": "data", "name": "prefix2", "type": "core::integer::u8"},
    ],
}

attack_beast_abi = {
    "kind": "struct",
    "name": "game::game::game::Game::AttackBeast",
    "type": "event",
    "outputs": [
        {
            "kind": "data",
            "name": "adventurer_state",
            "type": "game::game::game::Game::AdventurerState",
        },
        {"kind": "data", "name": "beast_id", "type": "core::integer::u8"},
        {"kind": "data", "name": "beast_level", "type": "core::integer::u16"},
        {"kind": "data", "name": "beast_health", "type": "core::integer::u16"},
        {"kind": "data", "name": "prefix_1", "type": "core::integer::u8"},
        {"kind": "data", "name": "prefix_2", "type": "core::integer::u8"},
        {"kind": "data", "name": "damage_dealt", "type": "core::integer::u16"},
        {"kind": "data", "name": "damage_taken", "type": "core::integer::u16"},
        {"kind": "data", "name": "damage_location", "type": "core::integer::u8"},
    ],
}

slayed_beast_abi = {
    "kind": "struct",
    "name": "game::game::game::Game::SlayedBeast",
    "type": "event",
    "outputs": [
        {
            "kind": "data",
            "name": "adventurer_state",
            "type": "game::game::game::Game::AdventurerState",
        },
        {"kind": "data", "name": "beast_id", "type": "core::integer::u8"},
        {"kind": "data", "name": "prefix_1", "type": "core::integer::u8"},
        {"kind": "data", "name": "prefix_2", "type": "core::integer::u8"},
        {"kind": "data", "name": "beast_level", "type": "core::integer::u16"},
        {"kind": "data", "name": "beast_health", "type": "core::integer::u16"},
        {"kind": "data", "name": "damage_dealt", "type": "core::integer::u16"},
        {"kind": "data", "name": "xp_earned_adventurer", "type": "core::integer::u16"},
        {"kind": "data", "name": "xp_earned_items", "type": "core::integer::u16"},
        {"kind": "data", "name": "gold_earned", "type": "core::integer::u16"},
    ],
}

flee_attempt_abi = {
    "kind": "struct",
    "name": "game::game::game::Game::FleeAttempt",
    "type": "event",
    "outputs": [
        {
            "kind": "data",
            "name": "adventurer_state",
            "type": "game::game::game::Game::AdventurerState",
        },
        {"kind": "data", "name": "beast_id", "type": "core::integer::u8"},
        {"kind": "data", "name": "beast_level", "type": "core::integer::u16"},
        {"kind": "data", "name": "beast_health", "type": "core::integer::u16"},
        {"kind": "data", "name": "damage_taken", "type": "core::integer::u16"},
        {"kind": "data", "name": "damage_location", "type": "core::integer::u8"},
        {"kind": "data", "name": "fled", "type": "core::bool"},
    ],
}

purchased_item_abi = {
    "kind": "struct",
    "name": "game::game::game::Game::PurchasedItem",
    "type": "event",
    "outputs": [
        {
            "kind": "data",
            "name": "adventurer_state_with_bag",
            "type": "game::game::game::Game::AdventurerStateWithBag",
        },
        {"kind": "data", "name": "item_id", "type": "core::integer::u8"},
        {"kind": "data", "name": "cost", "type": "core::integer::u16"},
    ],
}

equip_item_abi = {
    "kind": "struct",
    "name": "game::game::game::Game::EquipItem",
    "type": "event",
    "outputs": [
        {
            "kind": "data",
            "name": "adventurer_state_with_bag",
            "type": "game::game::game::Game::AdventurerStateWithBag",
        },
        {"kind": "data", "name": "equiped_item_id", "type": "core::integer::u8"},
        {"kind": "data", "name": "unequiped_item_id", "type": "core::integer::u8"},
    ],
}

greatness_increased_abi = {
    "kind": "struct",
    "name": "game::game::game::Game::GreatnessIncreased",
    "type": "event",
    "outputs": [
        {
            "kind": "data",
            "name": "adventurer_state",
            "type": "game::game::game::Game::AdventurerState",
        },
        {"kind": "data", "name": "item_id", "type": "core::integer::u8"},
        {"kind": "data", "name": "previous_level", "type": "core::integer::u8"},
        {"kind": "data", "name": "new_level", "type": "core::integer::u8"},
    ],
}

item_prefix_discovered_abi = {
    "kind": "struct",
    "name": "game::game::game::Game::ItemPrefixDiscovered",
    "type": "event",
    "outputs": [
        {
            "kind": "data",
            "name": "adventurer_state",
            "type": "game::game::game::Game::AdventurerState",
        },
        {
            "kind": "data",
            "name": "special_names",
            "type": "survivor::item_meta::LootItemSpecialNames",
        },
    ],
}

item_suffix_discovered_abi = {
    "kind": "struct",
    "name": "game::game::game::Game::ItemSuffixDiscovered",
    "type": "event",
    "outputs": [
        {
            "kind": "data",
            "name": "adventurer_state",
            "type": "game::game::game::Game::AdventurerState",
        },
        {
            "kind": "data",
            "name": "special_names",
            "type": "survivor::item_meta::LootItemSpecialNames",
        },
    ],
}

purchased_potion_abi = {
    "kind": "struct",
    "name": "game::game::game::Game::PurchasedPotion",
    "type": "event",
    "outputs": [
        {
            "kind": "data",
            "name": "adventurer_state",
            "type": "game::game::game::Game::AdventurerState",
        },
        {"kind": "data", "name": "health_amount", "type": "core::integer::u16"},
    ],
}

new_high_score_abi = {
    "kind": "struct",
    "name": "game::game::game::Game::NewHighScore",
    "type": "event",
    "outputs": [
        {
            "kind": "data",
            "name": "adventurer_state",
            "type": "game::game::game::Game::AdventurerState",
        },
        {"kind": "data", "name": "rank", "type": "core::integer::u8"},
    ],
}

adventurer_died_abi = {
    "kind": "struct",
    "name": "game::game::game::Game::AdventurerDied",
    "type": "event",
    "outputs": [
        {
            "kind": "data",
            "name": "adventurer_state",
            "type": "game::game::game::Game::AdventurerState",
        },
        {"kind": "data", "name": "killed_by_beast", "type": "core::bool"},
        {"kind": "data", "name": "killed_by_obstacle", "type": "core::bool"},
        {"kind": "data", "name": "killer_id", "type": "core::integer::u8"},
    ],
}


## ADVENTURER DECODERS

start_game_decoder = FunctionCallSerializer(
    abi=start_game_abi,
    identifier_manager=identifier_manager_from_abi(
        [
            start_game_abi,
            adventurer_state_abi,
            adventurer_metadata_abi,
            loot_statistics_abi,
        ]
    ),
)

stat_upgrade_decoder = FunctionCallSerializer(
    abi=stat_upgraded_abi,
    identifier_manager=identifier_manager_from_abi(
        [stat_upgraded_abi, adventurer_state_abi, loot_statistics_abi]
    ),
)

discover_health_decoder = FunctionCallSerializer(
    abi=discover_health_abi,
    identifier_manager=identifier_manager_from_abi(
        [discover_health_abi, adventurer_state_abi, loot_statistics_abi]
    ),
)

discover_gold_decoder = FunctionCallSerializer(
    abi=discover_gold_abi,
    identifier_manager=identifier_manager_from_abi(
        [discover_gold_abi, adventurer_state_abi, loot_statistics_abi]
    ),
)

discover_xp_decoder = FunctionCallSerializer(
    abi=disocver_xp_abi,
    identifier_manager=identifier_manager_from_abi(
        [disocver_xp_abi, adventurer_state_abi, loot_statistics_abi]
    ),
)

discover_obstacle_decoder = FunctionCallSerializer(
    abi=discover_obstacle_abi,
    identifier_manager=identifier_manager_from_abi(
        [discover_obstacle_abi, adventurer_state_abi, loot_statistics_abi]
    ),
)

discover_beast_decoder = FunctionCallSerializer(
    abi=discover_beast_abi,
    identifier_manager=identifier_manager_from_abi(
        [discover_beast_abi, adventurer_state_abi, loot_statistics_abi]
    ),
)

attack_beast_decoder = FunctionCallSerializer(
    abi=attack_beast_abi,
    identifier_manager=identifier_manager_from_abi(
        [attack_beast_abi, adventurer_state_abi, loot_statistics_abi]
    ),
)

slayed_beast_decoder = FunctionCallSerializer(
    abi=slayed_beast_abi,
    identifier_manager=identifier_manager_from_abi(
        [slayed_beast_abi, adventurer_state_abi, loot_statistics_abi]
    ),
)

flee_attempt_decoder = FunctionCallSerializer(
    abi=flee_attempt_abi,
    identifier_manager=identifier_manager_from_abi(
        [flee_attempt_abi, adventurer_state_abi, loot_statistics_abi]
    ),
)

purchased_item_decoder = FunctionCallSerializer(
    abi=purchased_item_abi,
    identifier_manager=identifier_manager_from_abi(
        [
            purchased_item_abi,
            adventurer_state_with_bag_abi,
            bag_abi,
            loot_statistics_abi,
        ]
    ),
)

equip_item_decoder = FunctionCallSerializer(
    abi=equip_item_abi,
    identifier_manager=identifier_manager_from_abi(
        [equip_item_abi, adventurer_state_with_bag_abi, bag_abi, loot_statistics_abi]
    ),
)

greatness_increased_decoder = FunctionCallSerializer(
    abi=greatness_increased_abi,
    identifier_manager=identifier_manager_from_abi(
        [greatness_increased_abi, adventurer_state_abi, loot_statistics_abi]
    ),
)

item_prefix_discovered_decoder = FunctionCallSerializer(
    abi=item_prefix_discovered_abi,
    identifier_manager=identifier_manager_from_abi(
        [
            item_prefix_discovered_abi,
            adventurer_state_abi,
            loot_statistics_abi,
            loot_item_special_names_abi,
        ]
    ),
)

item_suffix_discovered_decoder = FunctionCallSerializer(
    abi=item_suffix_discovered_abi,
    identifier_manager=identifier_manager_from_abi(
        [
            item_suffix_discovered_abi,
            adventurer_state_abi,
            loot_statistics_abi,
            loot_item_special_names_abi,
        ]
    ),
)

purchased_potion_decoder = FunctionCallSerializer(
    abi=purchased_potion_abi,
    identifier_manager=identifier_manager_from_abi(
        [purchased_potion_abi, adventurer_state_abi, loot_statistics_abi]
    ),
)

new_high_score_decoder = FunctionCallSerializer(
    abi=new_high_score_abi,
    identifier_manager=identifier_manager_from_abi(
        [new_high_score_abi, adventurer_state_abi, loot_statistics_abi]
    ),
)

adventurer_died_decoder = FunctionCallSerializer(
    abi=adventurer_died_abi,
    identifier_manager=identifier_manager_from_abi(
        [adventurer_died_abi, adventurer_state_abi, loot_statistics_abi]
    ),
)


def decode_start_game_event(data):
    return start_game_decoder.to_python([felt.to_int(d) for d in data])


def decode_stat_upgrade_event(data):
    return stat_upgrade_decoder.to_python([felt.to_int(d) for d in data])


def decode_discover_health_event(data):
    return discover_health_decoder.to_python([felt.to_int(d) for d in data])


def decode_discover_gold_event(data):
    return discover_gold_decoder.to_python([felt.to_int(d) for d in data])


def decode_discover_xp_event(data):
    return discover_xp_decoder.to_python([felt.to_int(d) for d in data])


def decode_discover_obstacle_event(data):
    return discover_obstacle_decoder.to_python([felt.to_int(d) for d in data])


def decode_discover_beast_event(data):
    return discover_beast_decoder.to_python([felt.to_int(d) for d in data])


def decode_attack_beast_event(data):
    return attack_beast_decoder.to_python([felt.to_int(d) for d in data])


def decode_slayed_beast_event(data):
    return slayed_beast_decoder.to_python([felt.to_int(d) for d in data])


def decode_flee_attempt_event(data):
    return flee_attempt_decoder.to_python([felt.to_int(d) for d in data])


def decode_purchased_item_event(data):
    return purchased_item_decoder.to_python([felt.to_int(d) for d in data])


def decode_equip_item_event(data):
    return equip_item_decoder.to_python([felt.to_int(d) for d in data])


def decode_greatness_increased_event(data):
    return greatness_increased_decoder.to_python([felt.to_int(d) for d in data])


def decode_item_prefix_discovered_event(data):
    return item_prefix_discovered_decoder.to_python([felt.to_int(d) for d in data])


def decode_item_suffix_discovered_event(data):
    return item_suffix_discovered_decoder.to_python([felt.to_int(d) for d in data])


def decode_purchased_potion_event(data):
    return purchased_potion_decoder.to_python([felt.to_int(d) for d in data])


def decode_new_high_score_event(data):
    return new_high_score_decoder.to_python([felt.to_int(d) for d in data])


def decode_adventurer_died_event(data):
    return adventurer_died_decoder.to_python([felt.to_int(d) for d in data])
