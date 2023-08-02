from starknet_py.abi.v1.parser import AbiParser
from starknet_py.serialization import serializer_for_payload


from typing import Iterator

raw_abi = [
    {
        "name": "survivor::adventurer_meta::AdventurerMetadata",
        "type": "struct",
        "members": [
            {"name": "name", "type": "core::integer::u128"},
            {"name": "home_realm", "type": "core::integer::u16"},
            {"name": "class", "type": "core::integer::u8"},
            {"name": "entropy", "type": "core::integer::u128"},
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
            {"name": "stat_points_available", "type": "core::integer::u8"},
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
        "name": "market::market::LootWithPrice",
        "type": "struct",
        "members": [
            {"name": "item", "type": "lootitems::loot::Loot"},
            {"name": "price", "type": "core::integer::u16"},
        ],
    },
    {
        "name": "combat::constants::CombatEnums::Tier",
        "type": "enum",
        "variants": [
            {"name": "None", "type": "()"},
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
            {"name": "None", "type": "()"},
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
            {"name": "None", "type": "()"},
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
        "name": "game::Game::AdventurerState",
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
        "name": "game::Game::StartGame",
        "type": "event",
        "inputs": [
            {
                "name": "adventurer_state",
                "type": "game::Game::AdventurerState",
            },
            {
                "name": "adventurer_meta",
                "type": "survivor::adventurer_meta::AdventurerMetadata",
            },
        ],
    },
    {
        "kind": "struct",
        "name": "game::Game::StatUpgradesAvailable",
        "type": "event",
        "inputs": [
            {
                "name": "adventurer_state",
                "type": "game::Game::AdventurerState",
            }
        ],
    },
    {
        "kind": "struct",
        "name": "game::Game::StrengthIncreased",
        "type": "event",
        "inputs": [
            {"name": "adventurer_state", "type": "game::Game::AdventurerState"},
            {"name": "amount", "type": "core::integer::u8"},
        ],
    },
    {
        "kind": "struct",
        "name": "game::Game::DexterityIncreased",
        "type": "event",
        "inputs": [
            {"name": "adventurer_state", "type": "game::Game::AdventurerState"},
            {"name": "amount", "type": "core::integer::u8"},
        ],
    },
    {
        "kind": "struct",
        "name": "game::Game::VitalityIncreased",
        "type": "event",
        "inputs": [
            {"name": "adventurer_state", "type": "game::Game::AdventurerState"},
            {"name": "amount", "type": "core::integer::u8"},
        ],
    },
    {
        "kind": "struct",
        "name": "game::Game::IntelligenceIncreased",
        "type": "event",
        "inputs": [
            {"name": "adventurer_state", "type": "game::Game::AdventurerState"},
            {"name": "amount", "type": "core::integer::u8"},
        ],
    },
    {
        "kind": "struct",
        "name": "game::Game::WisdomIncreased",
        "type": "event",
        "inputs": [
            {"name": "adventurer_state", "type": "game::Game::AdventurerState"},
            {"name": "amount", "type": "core::integer::u8"},
        ],
    },
    {
        "kind": "struct",
        "name": "game::Game::CharismaIncreased",
        "type": "event",
        "inputs": [
            {"name": "adventurer_state", "type": "game::Game::AdventurerState"},
            {"name": "amount", "type": "core::integer::u8"},
        ],
    },
    {
        "kind": "struct",
        "name": "game::Game::DiscoveredHealth",
        "type": "event",
        "inputs": [
            {
                "name": "adventurer_state",
                "type": "game::Game::AdventurerState",
            },
            {"name": "health_amount", "type": "core::integer::u16"},
        ],
    },
    {
        "kind": "struct",
        "name": "game::Game::DiscoveredGold",
        "type": "event",
        "inputs": [
            {
                "name": "adventurer_state",
                "type": "game::Game::AdventurerState",
            },
            {"name": "gold_amount", "type": "core::integer::u16"},
        ],
    },
    {
        "kind": "struct",
        "name": "game::Game::DiscoveredXP",
        "type": "event",
        "inputs": [
            {
                "name": "adventurer_state",
                "type": "game::Game::AdventurerState",
            },
            {"name": "xp_amount", "type": "core::integer::u16"},
        ],
    },
    {
        "kind": "struct",
        "name": "game::Game::DodgedObstacle",
        "type": "event",
        "inputs": [
            {"name": "adventurer_state", "type": "game::Game::AdventurerState"},
            {"name": "id", "type": "core::integer::u8"},
            {"name": "level", "type": "core::integer::u16"},
            {"name": "damage_taken", "type": "core::integer::u16"},
            {"name": "damage_location", "type": "core::integer::u8"},
            {"name": "xp_earned_adventurer", "type": "core::integer::u16"},
            {"name": "xp_earned_items", "type": "core::integer::u16"},
        ],
    },
    {
        "kind": "struct",
        "name": "game::Game::HitByObstacle",
        "type": "event",
        "inputs": [
            {"name": "adventurer_state", "type": "game::Game::AdventurerState"},
            {"name": "id", "type": "core::integer::u8"},
            {"name": "level", "type": "core::integer::u16"},
            {"name": "damage_taken", "type": "core::integer::u16"},
            {"name": "damage_location", "type": "core::integer::u8"},
            {"name": "xp_earned_adventurer", "type": "core::integer::u16"},
            {"name": "xp_earned_items", "type": "core::integer::u16"},
        ],
    },
    {
        "name": "combat::combat::CombatSpec",
        "type": "struct",
        "members": [
            {"name": "tier", "type": "combat::constants::CombatEnums::Tier"},
            {"name": "item_type", "type": "combat::constants::CombatEnums::Type"},
            {"name": "level", "type": "core::integer::u16"},
            {"name": "specials", "type": "combat::combat::SpecialPowers"},
        ],
    },
    {
        "kind": "struct",
        "name": "game::Game::AmbushedByBeast",
        "type": "event",
        "inputs": [
            {"name": "adventurer_state", "type": "game::Game::AdventurerState"},
            {"name": "seed", "type": "core::integer::u128"},
            {"name": "id", "type": "core::integer::u8"},
            {"name": "beast_specs", "type": "combat::combat::CombatSpec"},
            {"name": "damage", "type": "core::integer::u16"},
            {"name": "critical_hit", "type": "core::bool"},
            {"name": "location", "type": "core::integer::u8"},
        ],
    },
    {
        "kind": "struct",
        "name": "game::Game::DiscoveredBeast",
        "type": "event",
        "inputs": [
            {"name": "adventurer_state", "type": "game::Game::AdventurerState"},
            {"name": "seed", "type": "core::integer::u128"},
            {"name": "id", "type": "core::integer::u8"},
            {"name": "beast_specs", "type": "combat::combat::CombatSpec"},
        ],
    },
    {
        "kind": "struct",
        "name": "game::Game::AttackedBeast",
        "type": "event",
        "inputs": [
            {"name": "adventurer_state", "type": "game::Game::AdventurerState"},
            {"name": "seed", "type": "core::integer::u128"},
            {"name": "id", "type": "core::integer::u8"},
            {"name": "beast_specs", "type": "combat::combat::CombatSpec"},
            {"name": "damage", "type": "core::integer::u16"},
            {"name": "critical_hit", "type": "core::bool"},
            {"name": "location", "type": "core::integer::u8"},
        ],
    },
    {
        "type": "event",
        "name": "game::Game::AttackedByBeast",
        "kind": "struct",
        "inputs": [
            {
                "name": "adventurer_state",
                "type": "game::Game::AdventurerState",
            },
            {
                "name": "seed",
                "type": "core::integer::u128",
            },
            {
                "name": "id",
                "type": "core::integer::u8",
            },
            {
                "name": "beast_specs",
                "type": "combat::combat::CombatSpec",
            },
            {
                "name": "damage",
                "type": "core::integer::u16",
            },
            {"name": "critical_hit", "type": "core::bool"},
            {
                "name": "location",
                "type": "core::integer::u8",
            },
        ],
    },
    {
        "kind": "struct",
        "name": "game::Game::SlayedBeast",
        "type": "event",
        "inputs": [
            {"name": "adventurer_state", "type": "game::Game::AdventurerState"},
            {"name": "seed", "type": "core::integer::u128"},
            {"name": "id", "type": "core::integer::u8"},
            {"name": "beast_specs", "type": "combat::combat::CombatSpec"},
            {"name": "damage_dealt", "type": "core::integer::u16"},
            {"name": "critical_hit", "type": "core::bool"},
            {"name": "xp_earned_adventurer", "type": "core::integer::u16"},
            {"name": "xp_earned_items", "type": "core::integer::u16"},
            {"name": "gold_earned", "type": "core::integer::u16"},
        ],
    },
    {
        "kind": "struct",
        "name": "game::Game::FleeFailed",
        "type": "event",
        "inputs": [
            {
                "name": "adventurer_state",
                "type": "game::Game::AdventurerState",
            },
            {
                "name": "seed",
                "type": "core::integer::u128",
            },
            {
                "name": "id",
                "type": "core::integer::u8",
            },
            {
                "name": "beast_specs",
                "type": "combat::combat::CombatSpec",
            },
        ],
    },
    {
        "kind": "struct",
        "name": "game::Game::FleeSucceeded",
        "type": "event",
        "inputs": [
            {
                "name": "adventurer_state",
                "type": "game::Game::AdventurerState",
            },
            {
                "name": "seed",
                "type": "core::integer::u128",
            },
            {
                "name": "id",
                "type": "core::integer::u8",
            },
            {
                "name": "beast_specs",
                "type": "combat::combat::CombatSpec",
            },
        ],
    },
    {
        "name": "game::Game::AdventurerStateWithBag",
        "type": "struct",
        "members": [
            {
                "name": "adventurer_state",
                "type": "game::Game::AdventurerState",
            },
            {"name": "bag", "type": "survivor::bag::Bag"},
        ],
    },
    {
        "name": "game::Game::PurchasedItem",
        "type": "event",
        "inputs": [
            {
                "name": "adventurer_state_with_bag",
                "type": "game::Game::AdventurerStateWithBag",
            },
            {"name": "item_id", "type": "core::integer::u8"},
            {"name": "cost", "type": "core::integer::u16"},
            {"name": "equipped", "type": "core::bool"},
            {"name": "unequipped_item_id", "type": "core::integer::u8"},
        ],
    },
    {
        "kind": "struct",
        "name": "game::Game::EquippedItem",
        "type": "event",
        "inputs": [
            {
                "name": "adventurer_state_with_bag",
                "type": "game::Game::AdventurerStateWithBag",
            },
            {"name": "equipped_item_id", "type": "core::integer::u8"},
            {"name": "unequipped_item_id", "type": "core::integer::u8"},
        ],
    },
    {
        "kind": "struct",
        "name": "game::Game::DroppedItem",
        "type": "event",
        "inputs": [
            {
                "name": "adventurer_state_with_bag",
                "type": "game::Game::AdventurerStateWithBag",
            },
            {"name": "item_id", "type": "core::integer::u8"},
        ],
    },
    {
        "kind": "struct",
        "name": "game::Game::GreatnessIncreased",
        "type": "event",
        "inputs": [
            {
                "name": "adventurer_state",
                "type": "game::Game::AdventurerState",
            },
            {"name": "item_id", "type": "core::integer::u8"},
            {"name": "previous_level", "type": "core::integer::u8"},
            {"name": "new_level", "type": "core::integer::u8"},
        ],
    },
    {
        "name": "survivor::item_meta::ItemSpecials",
        "type": "struct",
        "members": [
            {"name": "special1", "type": "core::integer::u8"},
            {"name": "special2", "type": "core::integer::u8"},
            {"name": "special3", "type": "core::integer::u8"},
        ],
    },
    {
        "name": "combat::combat::SpecialPowers",
        "type": "struct",
        "members": [
            {"name": "special1", "type": "core::integer::u8"},
            {"name": "special2", "type": "core::integer::u8"},
            {"name": "special3", "type": "core::integer::u8"},
        ],
    },
    {
        "kind": "struct",
        "name": "game::Game::ItemSpecialUnlocked",
        "type": "event",
        "inputs": [
            {"name": "adventurer_state", "type": "game::Game::AdventurerState"},
            {"name": "id", "type": "core::integer::u8"},
            {"name": "level", "type": "core::integer::u8"},
            {"name": "specials", "type": "survivor::item_meta::ItemSpecials"},
        ],
    },
    {
        "kind": "struct",
        "name": "game::Game::PurchasedPotion",
        "type": "event",
        "inputs": [
            {
                "name": "adventurer_state",
                "type": "game::Game::AdventurerState",
            },
            {"name": "quantity", "type": "core::integer::u8"},
            {"name": "health_amount", "type": "core::integer::u16"},
        ],
    },
    {
        "kind": "struct",
        "name": "game::Game::NewHighScore",
        "type": "event",
        "inputs": [
            {
                "name": "adventurer_state",
                "type": "game::Game::AdventurerState",
            },
            {"name": "rank", "type": "core::integer::u8"},
        ],
    },
    {
        "kind": "struct",
        "name": "game::Game::AdventurerDied",
        "type": "event",
        "inputs": [
            {
                "name": "adventurer_state",
                "type": "game::Game::AdventurerState",
            },
            {"name": "killed_by_beast", "type": "core::bool"},
            {"name": "killed_by_obstacle", "type": "core::bool"},
            {"name": "killer_id", "type": "core::integer::u8"},
        ],
    },
    {
        "kind": "struct",
        "name": "game::Game::AdventurerLeveledUp",
        "type": "event",
        "inputs": [
            {"name": "adventurer_state", "type": "game::Game::AdventurerState"},
            {"name": "previous_level", "type": "core::integer::u8"},
            {"name": "new_level", "type": "core::integer::u8"},
        ],
    },
    {
        "kind": "struct",
        "name": "game::Game::NewItemsAvailable",
        "type": "event",
        "inputs": [
            {"name": "adventurer_state", "type": "game::Game::AdventurerState"},
            {
                "name": "items",
                "type": "core::array::Array::<market::market::LootWithPrice>",
            },
        ],
    },
    {
        "kind": "struct",
        "name": "game::Game::IdleDamagePenalty",
        "type": "event",
        "inputs": [
            {"name": "adventurer_state", "type": "game::Game::AdventurerState"},
            {"name": "idle_blocks", "type": "core::integer::u16"},
            {"name": "damage_taken", "type": "core::integer::u16"},
        ],
    },
]

game_contract_abi = AbiParser(raw_abi).parse()

decode_start_game_event = serializer_for_payload(
    game_contract_abi.events["game::Game::StartGame"].inputs
)

decode_stat_upgrades_available_event = serializer_for_payload(
    game_contract_abi.events["game::Game::StatUpgradesAvailable"].inputs
)

decode_strength_increased_event = serializer_for_payload(
    game_contract_abi.events["game::Game::StrengthIncreased"].inputs
)

decode_dexterity_increased_event = serializer_for_payload(
    game_contract_abi.events["game::Game::DexterityIncreased"].inputs
)

decode_vitality_increased_event = serializer_for_payload(
    game_contract_abi.events["game::Game::VitalityIncreased"].inputs
)

decode_intelligence_increased_event = serializer_for_payload(
    game_contract_abi.events["game::Game::IntelligenceIncreased"].inputs
)

decode_wisdom_increased_event = serializer_for_payload(
    game_contract_abi.events["game::Game::WisdomIncreased"].inputs
)

decode_charisma_increased_event = serializer_for_payload(
    game_contract_abi.events["game::Game::CharismaIncreased"].inputs
)

decode_discover_health_event = serializer_for_payload(
    game_contract_abi.events["game::Game::DiscoveredHealth"].inputs
)

decode_discover_gold_event = serializer_for_payload(
    game_contract_abi.events["game::Game::DiscoveredGold"].inputs
)

decode_discover_xp_event = serializer_for_payload(
    game_contract_abi.events["game::Game::DiscoveredXP"].inputs
)

decode_dodged_obstacle_event = serializer_for_payload(
    game_contract_abi.events["game::Game::DodgedObstacle"].inputs
)

decode_hit_by_obstacle_event = serializer_for_payload(
    game_contract_abi.events["game::Game::HitByObstacle"].inputs
)

decode_ambushed_by_beast_event = serializer_for_payload(
    game_contract_abi.events["game::Game::AmbushedByBeast"].inputs
)

decode_discover_beast_event = serializer_for_payload(
    game_contract_abi.events["game::Game::DiscoveredBeast"].inputs
)

decode_attack_beast_event = serializer_for_payload(
    game_contract_abi.events["game::Game::AttackedBeast"].inputs
)

decode_attacked_by_beast_event = serializer_for_payload(
    game_contract_abi.events["game::Game::AttackedByBeast"].inputs
)

decode_slayed_beast_event = serializer_for_payload(
    game_contract_abi.events["game::Game::SlayedBeast"].inputs
)

decode_flee_failed_event = serializer_for_payload(
    game_contract_abi.events["game::Game::FleeFailed"].inputs
)

decode_flee_succeeded_event = serializer_for_payload(
    game_contract_abi.events["game::Game::FleeSucceeded"].inputs
)

decode_purchased_item_event = serializer_for_payload(
    game_contract_abi.events["game::Game::PurchasedItem"].inputs
)

decode_equipped_item_event = serializer_for_payload(
    game_contract_abi.events["game::Game::EquippedItem"].inputs
)

decode_dropped_item_event = serializer_for_payload(
    game_contract_abi.events["game::Game::DroppedItem"].inputs
)

decode_greatness_increased_event = serializer_for_payload(
    game_contract_abi.events["game::Game::GreatnessIncreased"].inputs
)

decode_item_special_unlocked_event = serializer_for_payload(
    game_contract_abi.events["game::Game::ItemSpecialUnlocked"].inputs
)

decode_purchased_potion_event = serializer_for_payload(
    game_contract_abi.events["game::Game::PurchasedPotion"].inputs
)

decode_new_high_score_event = serializer_for_payload(
    game_contract_abi.events["game::Game::NewHighScore"].inputs
)

decode_adventurer_died_event = serializer_for_payload(
    game_contract_abi.events["game::Game::AdventurerDied"].inputs
)

decode_adventurer_leveled_up_event = serializer_for_payload(
    game_contract_abi.events["game::Game::AdventurerLeveledUp"].inputs
)

decode_new_items_available_event = serializer_for_payload(
    game_contract_abi.events["game::Game::NewItemsAvailable"].inputs
)

decode_idle_damage_penalty_event = serializer_for_payload(
    game_contract_abi.events["game::Game::IdleDamagePenalty"].inputs
)
