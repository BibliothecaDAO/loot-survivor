use core::serde::Serde;
use integer::{
    U128IntoFelt252, Felt252IntoU256, Felt252TryIntoU64, U256TryIntoFelt252, u256_from_felt252,
};
use traits::{TryInto, Into};
use option::OptionTrait;
use debug::PrintTrait;
use survivor::adventurer::Adventurer;
use lootitems::loot::{Loot, ItemUtils, ItemTrait};

#[derive(Drop, Copy, Serde)] // 24 bits
struct Obstacle {
    id: u8, // beast id 1 - 18
    Level: u16, // level
    Type: u8, // same as Loot weapons: magic, bludgeon, blade
    Tier: u8, // same as Loot weapons: T1 is strongest
}

trait ObstacleTrait {
    fn get_damage(adventurer: Adventurer, adventurer_entropy: u64, game_entropy: u64) -> u16;
}

impl ObstacleUtils of ObstacleTrait {
    fn get_damage(adventurer: Adventurer, adventurer_entropy: u64, game_entropy: u64) -> u16 {
        return 1;
    }
}

#[test]
#[available_gas(100000000)]
fn test() {}
