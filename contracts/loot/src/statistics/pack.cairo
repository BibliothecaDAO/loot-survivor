use integer::{
    U128IntoFelt252, Felt252IntoU256, Felt252TryIntoU64, U256TryIntoFelt252, u256_from_felt252
};
use traits::{TryInto, Into};
use option::OptionTrait;
use debug::PrintTrait;

use pack::pack::{pack_value, unpack_value, U256TryIntoU32};
use pack::constants::{TWO_POW_63, TWO_POW_126, TWO_POW_189, MASK_63};

#[derive(Copy, Drop)]
struct Loot {
    rank: u32,
    material: u32,
    item_type: u32,
    slot: u32,
}

fn pack_loot(loot: Loot) -> felt252 {
    let mut packed = 0;

    packed = packed | pack_value(loot.rank.into(), TWO_POW_189);
    packed = packed | pack_value(loot.material.into(), TWO_POW_126);
    packed = packed | pack_value(loot.item_type.into(), TWO_POW_63);
    packed = packed | pack_value(loot.slot.into(), 1);

    packed.try_into().unwrap()
}


fn unpack_loot(packed: felt252) -> Loot {
    let packed = packed.into();

    Loot {
        rank: U256TryIntoU32::try_into(unpack_value(packed, TWO_POW_189, MASK_63)).unwrap(),
        material: U256TryIntoU32::try_into(unpack_value(packed, TWO_POW_126, MASK_63)).unwrap(),
        item_type: U256TryIntoU32::try_into(unpack_value(packed, TWO_POW_63, MASK_63)).unwrap(),
        slot: U256TryIntoU32::try_into(unpack_value(packed, 1, MASK_63)).unwrap(),
    }
}


#[test]
#[available_gas(1000000)]
fn test() {
    let lootItem = Loot { rank: 1213123, material: 21231231, item_type: 3123123, slot: 412312 };

    let packed = pack_loot(lootItem);
    let unpacked = unpack_loot(packed);

    assert(lootItem.rank == unpacked.rank, 'rank');
    assert(lootItem.material == unpacked.material, 'material');
    assert(lootItem.item_type == unpacked.item_type, 'item_type');
    assert(lootItem.slot == unpacked.slot, 'slot');
}

