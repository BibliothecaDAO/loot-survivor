use core::serde::Serde;
use integer::{
    U128IntoFelt252, Felt252IntoU256, Felt252TryIntoU64, U256TryIntoFelt252, u256_from_felt252,
};
use traits::{TryInto, Into};
use option::OptionTrait;
use debug::PrintTrait;
use survivor::adventurer::Adventurer;
use lootitems::loot::{Loot, ImplLoot, ILoot};

#[derive(Drop, Copy, Serde)] // 24 bits
struct Beast {
    id: u8, // beast id 1 - 18
    Level: u16, // level
    Health: u16, // health of the beast
    AttackType: u8, // same as Loot weapons: magic, bludgeon, blade
    ArmorType: u8, // same as Loot weapons: cloth, metal, hide
    Tier: u8, // same as Loot weapons: T1 is strongest
    Prefix_1: u8, // First part of the name prefix (i.e Tear)
    Prefix_2: u8, // Second part of the name prefix (i.e Bearer)
}

trait BeastTrait {
    fn get_beast(adventurer: Adventurer) -> Beast;
    fn get_level(id: u8) -> u16;
    fn get_starting_health(
        adventurer: Adventurer, adventurer_entropy: u64, game_entropy: u64
    ) -> u16;
    fn get_health(adventurer: Adventurer) -> u16;
    fn get_attack_type(id: u8) -> u8;
    fn get_armor_type(id: u8) -> u8;
    fn get_tier(id: u8) -> u8;
    fn get_prefix_1(id: u8) -> u8;
    fn get_prefix_2(id: u8) -> u8;
}

impl BeastUtils of BeastTrait {
    fn get_beast(adventurer: Adventurer) -> Beast {
        // TODO: Generate a deterministic beast using the details of the adventurer
        Beast {
            id: 1,
            Level: 1,
            Health: adventurer.beast_health,
            AttackType: 1,
            ArmorType: 1,
            Tier: 1,
            Prefix_1: 1,
            Prefix_2: 1,
        }
    }
    fn get_starting_health(
        adventurer: Adventurer, adventurer_entropy: u64, game_entropy: u64
    ) -> u16 {
        return 1;
    }
    fn get_level(id: u8) -> u16 {
        return 1;
    }
    fn get_health(adventurer: Adventurer) -> u16 {
        return adventurer.beast_health;
    }
    fn get_attack_type(id: u8) -> u8 {
        return 1;
    }
    fn get_armor_type(id: u8) -> u8 {
        return 1;
    }
    fn get_tier(id: u8) -> u8 {
        return 1;
    }
    fn get_prefix_1(id: u8) -> u8 {
        return 1;
    }
    fn get_prefix_2(id: u8) -> u8 {
        return 1;
    }
}

#[test]
#[available_gas(100000000)]
fn test() {}
