use core::traits::Into;
use core::clone::Clone;
use array::ArrayTrait;
use debug::PrintTrait;
use option::OptionTrait;

use loot::statistics::rank;
use loot::statistics::slot;
use loot::statistics::item_type;
use loot::statistics::material;

#[derive(Copy, Drop, Clone)]
struct Loot {
    rank: u32,
    material: u32,
    item_type: u32,
    slot: u32,
}

trait ItemTrait {
    fn get(id: u32) -> Loot;
    fn rank(id: u32) -> u32;
    fn material(id: u32) -> u32;
    fn item_type(id: u32) -> u32;
    fn slot(id: u32) -> u32;
}

impl ItemStats of ItemTrait {
    fn get(id: u32) -> Loot {
        Loot {
            rank: ItemStats::rank(id),
            material: ItemStats::material(id),
            item_type: ItemStats::item_type(id),
            slot: ItemStats::slot(id),
        }
    }
    fn rank(id: u32) -> u32 {
        return rank::get(id);
    }
    fn material(id: u32) -> u32 {
        return material::get(id);
    }
    fn item_type(id: u32) -> u32 {
        return item_type::get(id);
    }
    fn slot(id: u32) -> u32 {
        return slot::get(id);
    }
}

#[test]
#[available_gas(100000)]
fn test_array() {
    ItemStats::get(1);
}
