from starknet_py.abi.v1.parser import AbiParser
from starknet_py.serialization import serializer_for_payload

from typing import Iterator

raw_abi = [
    {
        "name": "survivor::adventurer_meta::AdventurerMetadata",
        "type": "struct",
        "members": [
            {"name": "name", "type": "core::integer::u32"},
            {"name": "home_realm", "type": "core::integer::u8"},
            {"name": "race", "type": "core::integer::u8"},
            {"name": "order", "type": "core::integer::u8"},
            {"name": "entropy", "type": "core::integer::u64"},
        ],
    },
    {
        "name": "core::integer::u256",
        "type": "struct",
        "members": [
            {"name": "low", "type": "core::integer::u128"},
            {"name": "high", "type": "core::integer::u128"},
        ],
    },
    {
        "name": "core::bool",
        "type": "enum",
        "variants": [{"name": "False", "type": "()"}, {"name": "True", "type": "()"}],
    },
    {
        "name": "survivor::adventurer::Stats",
        "type": "struct",
        "members": [
            {"name": "strength", "type": "core::integer::u8"},
            {"name": "dexterity", "type": "core::integer::u8"},
            {"name": "vitality", "type": "core::integer::u8"},
            {"name": "intelligence", "type": "core::integer::u8"},
            {"name": "wisdom", "type": "core::integer::u8"},
            {"name": "charisma", "type": "core::integer::u8"},
        ],
    },
    {
        "name": "survivor::bag::LootStatistics",
        "type": "struct",
        "members": [
            {"name": "id", "type": "core::integer::u8"},
            {"name": "xp", "type": "core::integer::u16"},
            {"name": "metadata", "type": "core::integer::u8"},
        ],
    },
    {
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
    },
    {
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
    },
    {
        "name": "combat::constants::CombatEnums::Tier",
        "type": "enum",
        "variants": [
            {"name": "T1", "type": "()"},
            {"name": "T2", "type": "()"},
            {"name": "T3", "type": "()"},
            {"name": "T4", "type": "()"},
            {"name": "T5", "type": "()"},
        ],
    },
    {
        "name": "combat::constants::CombatEnums::Slot",
        "type": "enum",
        "variants": [
            {"name": "Weapon", "type": "()"},
            {"name": "Chest", "type": "()"},
            {"name": "Head", "type": "()"},
            {"name": "Waist", "type": "()"},
            {"name": "Foot", "type": "()"},
            {"name": "Hand", "type": "()"},
            {"name": "Neck", "type": "()"},
            {"name": "Ring", "type": "()"},
        ],
    },
    {
        "name": "combat::constants::CombatEnums::Type",
        "type": "enum",
        "variants": [
            {"name": "Magic_or_Cloth", "type": "()"},
            {"name": "Blade_or_Hide", "type": "()"},
            {"name": "Bludgeon_or_Metal", "type": "()"},
            {"name": "Necklace", "type": "()"},
            {"name": "Ring", "type": "()"},
        ],
    },
    {
        "name": "lootitems::loot::Loot",
        "type": "struct",
        "members": [
            {"name": "id", "type": "core::integer::u8"},
            {"name": "tier", "type": "combat::constants::CombatEnums::Tier"},
            {"name": "item_type", "type": "combat::constants::CombatEnums::Type"},
            {"name": "slot", "type": "combat::constants::CombatEnums::Slot"},
        ],
    },
    {
        "name": "game::game::game::Game::AdventurerState",
        "type": "struct",
        "members": [
            {
                "name": "owner",
                "type": "core::starknet::contract_address::ContractAddress",
            },
            {"name": "adventurer_id", "type": "core::integer::u256"},
            {"name": "adventurer", "type": "survivor::adventurer::Adventurer"},
        ],
    },
    {
        "kind": "struct",
        "name": "game::game::game::Game::StartGame",
        "type": "event",
        "inputs": [
            {
                "name": "adventurer_state",
                "type": "game::game::game::Game::AdventurerState",
            },
            {
                "name": "adventurer_meta",
                "type": "survivor::adventurer_meta::AdventurerMetadata",
            },
        ],
    },
    {
        "kind": "struct",
        "name": "game::game::game::Game::StatUpgraded",
        "type": "event",
        "inputs": [
            {
                "name": "adventurer_state",
                "type": "game::game::game::Game::AdventurerState",
            },
            {"name": "stat_id", "type": "core::integer::u8"},
        ],
    },
    {
        "kind": "struct",
        "name": "game::game::game::Game::DiscoverHealth",
        "type": "event",
        "inputs": [
            {
                "name": "adventurer_state",
                "type": "game::game::game::Game::AdventurerState",
            },
            {"name": "health_amount", "type": "core::integer::u16"},
        ],
    },
    {
        "kind": "struct",
        "name": "game::game::game::Game::DiscoverGold",
        "type": "event",
        "inputs": [
            {
                "name": "adventurer_state",
                "type": "game::game::game::Game::AdventurerState",
            },
            {"name": "gold_amount", "type": "core::integer::u16"},
        ],
    },
    {
        "kind": "struct",
        "name": "game::game::game::Game::DiscoverXP",
        "type": "event",
        "inputs": [
            {
                "name": "adventurer_state",
                "type": "game::game::game::Game::AdventurerState",
            },
            {"name": "xp_amount", "type": "core::integer::u16"},
        ],
    },
    {
        "kind": "struct",
        "name": "game::game::game::Game::DiscoverObstacle",
        "type": "event",
        "inputs": [
            {
                "name": "adventurer_state",
                "type": "game::game::game::Game::AdventurerState",
            },
            {"name": "id", "type": "core::integer::u8"},
            {"name": "level", "type": "core::integer::u16"},
            {"name": "dodged", "type": "core::bool"},
            {"name": "damage_taken", "type": "core::integer::u16"},
            {"name": "damage_location", "type": "core::integer::u8"},
            {
                "name": "xp_earned_adventurer",
                "type": "core::integer::u16",
            },
            {"name": "xp_earned_items", "type": "core::integer::u16"},
        ],
    },
    {
        "kind": "struct",
        "name": "game::game::game::Game::DiscoverBeast",
        "type": "event",
        "inputs": [
            {
                "name": "adventurer_state",
                "type": "game::game::game::Game::AdventurerState",
            },
            {"name": "id", "type": "core::integer::u8"},
            {"name": "level", "type": "core::integer::u16"},
            {"name": "ambushed", "type": "core::bool"},
            {"name": "damage_taken", "type": "core::integer::u16"},
            {"name": "health", "type": "core::integer::u16"},
            {"name": "prefix1", "type": "core::integer::u8"},
            {"name": "prefix2", "type": "core::integer::u8"},
        ],
    },
    {
        "kind": "struct",
        "name": "game::game::game::Game::AttackBeast",
        "type": "event",
        "inputs": [
            {
                "name": "adventurer_state",
                "type": "game::game::game::Game::AdventurerState",
            },
            {"name": "beast_id", "type": "core::integer::u8"},
            {"name": "beast_level", "type": "core::integer::u16"},
            {"name": "beast_health", "type": "core::integer::u16"},
            {"name": "prefix_1", "type": "core::integer::u8"},
            {"name": "prefix_2", "type": "core::integer::u8"},
            {"name": "damage_dealt", "type": "core::integer::u16"},
            {"name": "damage_taken", "type": "core::integer::u16"},
            {"name": "damage_location", "type": "core::integer::u8"},
        ],
    },
    {
        "kind": "struct",
        "name": "game::game::game::Game::SlayedBeast",
        "type": "event",
        "inputs": [
            {
                "name": "adventurer_state",
                "type": "game::game::game::Game::AdventurerState",
            },
            {"name": "beast_id", "type": "core::integer::u8"},
            {"name": "prefix_1", "type": "core::integer::u8"},
            {"name": "prefix_2", "type": "core::integer::u8"},
            {"name": "beast_level", "type": "core::integer::u16"},
            {"name": "beast_health", "type": "core::integer::u16"},
            {"name": "damage_dealt", "type": "core::integer::u16"},
            {
                "name": "xp_earned_adventurer",
                "type": "core::integer::u16",
            },
            {"name": "xp_earned_items", "type": "core::integer::u16"},
            {"name": "gold_earned", "type": "core::integer::u16"},
        ],
    },
    {
        "kind": "struct",
        "name": "game::game::game::Game::FleeAttempt",
        "type": "event",
        "inputs": [
            {
                "name": "adventurer_state",
                "type": "game::game::game::Game::AdventurerState",
            },
            {"name": "beast_id", "type": "core::integer::u8"},
            {"name": "beast_level", "type": "core::integer::u16"},
            {"name": "beast_health", "type": "core::integer::u16"},
            {"name": "damage_taken", "type": "core::integer::u16"},
            {"name": "damage_location", "type": "core::integer::u8"},
            {"name": "fled", "type": "core::bool"},
        ],
    },
    {
        "name": "game::game::game::Game::AdventurerStateWithBag",
        "type": "struct",
        "members": [
            {
                "name": "adventurer_state",
                "type": "game::game::game::Game::AdventurerState",
            },
            {"name": "bag", "type": "survivor::bag::Bag"},
        ],
    },
    {
        "kind": "struct",
        "name": "game::game::game::Game::PurchasedItem",
        "type": "event",
        "inputs": [
            {
                "name": "adventurer_state_with_bag",
                "type": "game::game::game::Game::AdventurerStateWithBag",
            },
            {"name": "item_id", "type": "core::integer::u8"},
            {"name": "cost", "type": "core::integer::u16"},
        ],
    },
    {
        "kind": "struct",
        "name": "game::game::game::Game::EquipItem",
        "type": "event",
        "inputs": [
            {
                "name": "adventurer_state_with_bag",
                "type": "game::game::game::Game::AdventurerStateWithBag",
            },
            {"name": "equiped_item_id", "type": "core::integer::u8"},
            {"name": "unequiped_item_id", "type": "core::integer::u8"},
        ],
    },
    {
        "kind": "struct",
        "name": "game::game::game::Game::GreatnessIncreased",
        "type": "event",
        "inputs": [
            {
                "name": "adventurer_state",
                "type": "game::game::game::Game::AdventurerState",
            },
            {"name": "item_id", "type": "core::integer::u8"},
            {"name": "previous_level", "type": "core::integer::u8"},
            {"name": "new_level", "type": "core::integer::u8"},
        ],
    },
    {
        "name": "survivor::item_meta::LootItemSpecialNames",
        "type": "struct",
        "members": [
            {"name": "name_prefix", "type": "core::integer::u8"},
            {"name": "name_suffix", "type": "core::integer::u8"},
            {"name": "item_suffix", "type": "core::integer::u8"},
        ],
    },
    {
        "kind": "struct",
        "name": "game::game::game::Game::ItemPrefixDiscovered",
        "type": "event",
        "inputs": [
            {
                "name": "adventurer_state",
                "type": "game::game::game::Game::AdventurerState",
            },
            {
                "name": "special_names",
                "type": "survivor::item_meta::LootItemSpecialNames",
            },
        ],
    },
    {
        "kind": "struct",
        "name": "game::game::game::Game::ItemSuffixDiscovered",
        "type": "event",
        "inputs": [
            {
                "name": "adventurer_state",
                "type": "game::game::game::Game::AdventurerState",
            },
            {
                "name": "special_names",
                "type": "survivor::item_meta::LootItemSpecialNames",
            },
        ],
    },
    {
        "kind": "struct",
        "name": "game::game::game::Game::PurchasedPotion",
        "type": "event",
        "inputs": [
            {
                "name": "adventurer_state",
                "type": "game::game::game::Game::AdventurerState",
            },
            {"name": "health_amount", "type": "core::integer::u16"},
        ],
    },
    {
        "kind": "struct",
        "name": "game::game::game::Game::NewHighScore",
        "type": "event",
        "inputs": [
            {
                "name": "adventurer_state",
                "type": "game::game::game::Game::AdventurerState",
            },
            {"name": "rank", "type": "core::integer::u8"},
        ],
    },
    {
        "kind": "struct",
        "name": "game::game::game::Game::AdventurerDied",
        "type": "event",
        "inputs": [
            {
                "name": "adventurer_state",
                "type": "game::game::game::Game::AdventurerState",
            },
            {"name": "killed_by_beast", "type": "core::bool"},
            {"name": "killed_by_obstacle", "type": "core::bool"},
            {"name": "killer_id", "type": "core::integer::u8"},
        ],
    },
]

game_contract_abi = AbiParser(raw_abi).parse()

decode_start_game_event = serializer_for_payload(
    game_contract_abi.events["game::game::game::Game::StartGame"].inputs
)

decode_stat_upgrade_event = serializer_for_payload(
    game_contract_abi.events["game::game::game::Game::StatUpgraded"].inputs
)

decode_discover_health_event = serializer_for_payload(
    game_contract_abi.events["game::game::game::Game::DiscoverHealth"].inputs
)

decode_discover_gold_event = serializer_for_payload(
    game_contract_abi.events["game::game::game::Game::DiscoverGold"].inputs
)

decode_discover_xp_event = serializer_for_payload(
    game_contract_abi.events["game::game::game::Game::DiscoverXP"].inputs
)

decode_discover_obstacle_event = serializer_for_payload(
    game_contract_abi.events["game::game::game::Game::DiscoverObstacle"].inputs
)

decode_discover_beast_event = serializer_for_payload(
    game_contract_abi.events["game::game::game::Game::DiscoverBeast"].inputs
)

decode_attack_beast_event = serializer_for_payload(
    game_contract_abi.events["game::game::game::Game::AttackBeast"].inputs
)

decode_slayed_beast_event = serializer_for_payload(
    game_contract_abi.events["game::game::game::Game::SlayedBeast"].inputs
)

decode_flee_attempt_event = serializer_for_payload(
    game_contract_abi.events["game::game::game::Game::FleeAttempt"].inputs
)

decode_purchased_item_event = serializer_for_payload(
    game_contract_abi.events["game::game::game::Game::PurchasedItem"].inputs
)

decode_equip_item_event = serializer_for_payload(
    game_contract_abi.events["game::game::game::Game::EquipItem"].inputs
)

decode_greatness_increased_event = serializer_for_payload(
    game_contract_abi.events["game::game::game::Game::GreatnessIncreased"].inputs
)

decode_item_prefix_discovered_event = serializer_for_payload(
    game_contract_abi.events["game::game::game::Game::ItemPrefixDiscovered"].inputs
)

decode_item_suffix_discovered_event = serializer_for_payload(
    game_contract_abi.events["game::game::game::Game::ItemSuffixDiscovered"].inputs
)

decode_purchased_potion_event = serializer_for_payload(
    game_contract_abi.events["game::game::game::Game::PurchasedPotion"].inputs
)

decode_new_high_score_event = serializer_for_payload(
    game_contract_abi.events["game::game::game::Game::NewHighScore"].inputs
)

decode_adventurer_died_event = serializer_for_payload(
    game_contract_abi.events["game::game::game::Game::AdventurerDied"].inputs
)
