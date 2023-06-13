use core::serde::Serde;
use integer::{
    U128IntoFelt252, Felt252IntoU256, Felt252TryIntoU64, U256TryIntoFelt252, u256_from_felt252,
};
use traits::{TryInto, Into};
use option::OptionTrait;
use debug::PrintTrait;

use pack::pack::{pack_value, unpack_value, U256TryIntoU32, U256TryIntoU16, U256TryIntoU8};
use pack::constants::{MASK_16, pow, MASK_8, MASK_BOOL, mask};

use lootitems::loot::{Loot, ItemStats, ItemTrait};


#[derive(Drop, Copy, Serde)]
struct AdventurerMeta {
    name: u32,
    home_realm: u8,
    race: u8,
    entropy: u128,
}

trait MetaActions {
    fn pack(adventurer_meta: AdventurerMeta) -> felt252;
    fn unpack(packed: felt252) -> AdventurerMeta;
}


impl AdventurerMetaActions of MetaActions {
    fn pack(adventurer_meta: AdventurerMeta) -> felt252 {
        0
    }
    fn unpack(packed: felt252) -> AdventurerMeta {
        AdventurerMeta { name: 0, home_realm: 0, race: 0, entropy: 0 }
    }
}
