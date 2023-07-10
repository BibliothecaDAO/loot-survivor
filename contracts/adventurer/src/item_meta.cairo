use core::serde::Serde;
use traits::{TryInto, Into};
use option::OptionTrait;
use integer::{U256TryIntoU32, U256TryIntoU16, U256TryIntoU8};
use pack::pack::{Packing, rshift_split};
use pack::constants::pow;

use super::{adventurer::{Adventurer, IAdventurer, ImplAdventurer}, item_primitive::ItemPrimitive};
use super::bag::{Bag, BagActions};

mod STORAGE {
    const INDEX_1: u8 = 1;
    const INDEX_2: u8 = 2;
    const INDEX_3: u8 = 3;
    const INDEX_4: u8 = 4;
    const INDEX_5: u8 = 5;
    const INDEX_6: u8 = 6;
    const INDEX_7: u8 = 7;
    const INDEX_8: u8 = 8;
    const INDEX_9: u8 = 9;
    const INDEX_10: u8 = 10;
}

#[derive(Drop, Copy, Serde)]
struct LootItemSpecialNames {
    name_prefix: u8, // 7 bits
    name_suffix: u8, // 5 bits
    item_suffix: u8, // 4 bit
}

// Player can have a total of 20 items. We map the items index to a slot in the metadata
#[derive(Drop, Copy, Serde)]
struct LootItemSpecialNamesStorage {
    item_1: LootItemSpecialNames,
    item_2: LootItemSpecialNames,
    item_3: LootItemSpecialNames,
    item_4: LootItemSpecialNames,
    item_5: LootItemSpecialNames,
    item_6: LootItemSpecialNames,
    item_7: LootItemSpecialNames,
    item_8: LootItemSpecialNames,
    item_9: LootItemSpecialNames,
    item_10: LootItemSpecialNames,
}

impl LootItemSpecialNamesPacking of Packing<LootItemSpecialNames> {
    fn pack(self: LootItemSpecialNames) -> felt252 {
        (self.name_prefix.into()
            + self.name_suffix.into() * pow::TWO_POW_7
            + self.item_suffix.into() * pow::TWO_POW_12)
            .try_into()
            .expect('pack LootItemSpecialNames')
    }

    fn unpack(packed: felt252) -> LootItemSpecialNames {
        let packed = packed.into();
        let (packed, name_prefix) = rshift_split(packed, pow::TWO_POW_7);
        let (packed, name_suffix) = rshift_split(packed, pow::TWO_POW_5);
        let (_, item_suffix) = rshift_split(packed, pow::TWO_POW_4);

        LootItemSpecialNames {
            name_prefix: name_prefix.try_into().expect('unpack LISN name_prefix'),
            name_suffix: name_suffix.try_into().expect('unpack LISN name_suffix'),
            item_suffix: item_suffix.try_into().expect('unpack LISN item_suffix')
        }
    }
}

impl LootItemSpecialNamesStoragePacking of Packing<LootItemSpecialNamesStorage> {
    fn pack(self: LootItemSpecialNamesStorage) -> felt252 {
        (self.item_1.pack().into()
            + self.item_2.pack().into() * pow::TWO_POW_16
            + self.item_3.pack().into() * pow::TWO_POW_32
            + self.item_4.pack().into() * pow::TWO_POW_48
            + self.item_5.pack().into() * pow::TWO_POW_64
            + self.item_6.pack().into() * pow::TWO_POW_80
            + self.item_7.pack().into() * pow::TWO_POW_96
            + self.item_8.pack().into() * pow::TWO_POW_112
            + self.item_9.pack().into() * pow::TWO_POW_128
            + self.item_10.pack().into() * pow::TWO_POW_144)
            .try_into()
            .expect('pack LISNS')
    }

    fn unpack(packed: felt252) -> LootItemSpecialNamesStorage {
        let packed = packed.into();
        let (packed, item_1) = rshift_split(packed, pow::TWO_POW_16);
        let (packed, item_2) = rshift_split(packed, pow::TWO_POW_16);
        let (packed, item_3) = rshift_split(packed, pow::TWO_POW_16);
        let (packed, item_4) = rshift_split(packed, pow::TWO_POW_16);
        let (packed, item_5) = rshift_split(packed, pow::TWO_POW_16);
        let (packed, item_6) = rshift_split(packed, pow::TWO_POW_16);
        let (packed, item_7) = rshift_split(packed, pow::TWO_POW_16);
        let (packed, item_8) = rshift_split(packed, pow::TWO_POW_16);
        let (packed, item_9) = rshift_split(packed, pow::TWO_POW_16);
        let (_, item_10) = rshift_split(packed, pow::TWO_POW_16);

        LootItemSpecialNamesStorage {
            item_1: Packing::unpack(item_1.try_into().expect('unpack LISNS item_1')),
            item_2: Packing::unpack(item_2.try_into().expect('unpack LISNS item_2')),
            item_3: Packing::unpack(item_3.try_into().expect('unpack LISNS item_3')),
            item_4: Packing::unpack(item_4.try_into().expect('unpack LISNS item_4')),
            item_5: Packing::unpack(item_5.try_into().expect('unpack LISNS item_5')),
            item_6: Packing::unpack(item_6.try_into().expect('unpack LISNS item_6')),
            item_7: Packing::unpack(item_7.try_into().expect('unpack LISNS item_7')),
            item_8: Packing::unpack(item_8.try_into().expect('unpack LISNS item_8')),
            item_9: Packing::unpack(item_9.try_into().expect('unpack LISNS item_9')),
            item_10: Packing::unpack(item_10.try_into().expect('unpack LISNS item_10'))
        }
    }
}

#[generate_trait]
impl ImplLootItemSpecialNames of ILootItemSpecialNames {
    fn get_loot_special_names(
        self: LootItemSpecialNamesStorage, loot_statistics: ItemPrimitive
    ) -> LootItemSpecialNames {
        if loot_statistics.metadata == STORAGE::INDEX_1 {
            return self.item_1;
        } else if loot_statistics.metadata == STORAGE::INDEX_2 {
            return self.item_2;
        } else if loot_statistics.metadata == STORAGE::INDEX_3 {
            return self.item_3;
        } else if loot_statistics.metadata == STORAGE::INDEX_4 {
            return self.item_4;
        } else if loot_statistics.metadata == STORAGE::INDEX_5 {
            return self.item_5;
        } else if loot_statistics.metadata == STORAGE::INDEX_6 {
            return self.item_6;
        } else if loot_statistics.metadata == STORAGE::INDEX_7 {
            return self.item_7;
        } else if loot_statistics.metadata == STORAGE::INDEX_8 {
            return self.item_8;
        } else if loot_statistics.metadata == STORAGE::INDEX_9 {
            return self.item_9;
        } else {
            return self.item_10;
        }
    }

    fn get_loot_special_names_slot(
        adventurer: Adventurer, bag: Bag, loot_statistics: ItemPrimitive
    ) -> ItemPrimitive {
        // check slots

        let mut slot = 0;

        if adventurer.weapon.metadata >= slot {
            slot = adventurer.weapon.metadata;
        }
        if adventurer.head.metadata >= slot {
            slot = adventurer.head.metadata;
        }
        if adventurer.chest.metadata >= slot {
            slot = adventurer.chest.metadata;
        }
        if adventurer.hand.metadata >= slot {
            slot = adventurer.hand.metadata;
        }
        if adventurer.foot.metadata >= slot {
            slot = adventurer.foot.metadata;
        }
        if adventurer.ring.metadata >= slot {
            slot = adventurer.ring.metadata;
        }
        if adventurer.neck.metadata >= slot {
            slot = adventurer.neck.metadata;
        }
        if adventurer.waist.metadata >= slot {
            slot = adventurer.waist.metadata;
        }

        if bag.item_1.metadata >= slot {
            slot = bag.item_1.metadata;
        }
        if bag.item_2.metadata >= slot {
            slot = bag.item_2.metadata;
        }
        if bag.item_3.metadata >= slot {
            slot = bag.item_3.metadata;
        }
        if bag.item_4.metadata >= slot {
            slot = bag.item_4.metadata;
        }
        if bag.item_5.metadata >= slot {
            slot = bag.item_5.metadata;
        }
        if bag.item_6.metadata >= slot {
            slot = bag.item_6.metadata;
        }
        if bag.item_7.metadata >= slot {
            slot = bag.item_7.metadata;
        }
        if bag.item_8.metadata >= slot {
            slot = bag.item_8.metadata;
        }
        if bag.item_9.metadata >= slot {
            slot = bag.item_9.metadata;
        }
        if bag.item_10.metadata >= slot {
            slot = bag.item_10.metadata;
        }
        if bag.item_11.metadata >= slot {
            slot = bag.item_11.metadata;
        }

        // if no slots -> return first index which is 0
        if slot == 1 {
            ItemPrimitive { id: loot_statistics.id, xp: loot_statistics.xp, metadata: 1 }
        } else {
            ItemPrimitive { id: loot_statistics.id, xp: loot_statistics.xp, metadata: slot + 1 }
        }
    }
    fn set_loot_special_names(
        ref self: LootItemSpecialNamesStorage,
        loot_statistics: ItemPrimitive,
        loot_special_names: LootItemSpecialNames
    ) {
        if loot_statistics.metadata == STORAGE::INDEX_1 {
            self.item_1 = loot_special_names;
        } else if loot_statistics.metadata == STORAGE::INDEX_2 {
            self.item_2 = loot_special_names;
        } else if loot_statistics.metadata == STORAGE::INDEX_3 {
            self.item_3 = loot_special_names;
        } else if loot_statistics.metadata == STORAGE::INDEX_4 {
            self.item_4 = loot_special_names;
        } else if loot_statistics.metadata == STORAGE::INDEX_5 {
            self.item_5 = loot_special_names;
        } else if loot_statistics.metadata == STORAGE::INDEX_6 {
            self.item_6 = loot_special_names;
        } else if loot_statistics.metadata == STORAGE::INDEX_7 {
            self.item_7 = loot_special_names;
        } else if loot_statistics.metadata == STORAGE::INDEX_8 {
            self.item_8 = loot_special_names;
        } else if loot_statistics.metadata == STORAGE::INDEX_9 {
            self.item_9 = loot_special_names;
        } else {
            self.item_10 = loot_special_names;
        }
    }
}

#[test]
#[available_gas(5000000)]
fn test_item_meta_packing() {
    let storage = LootItemSpecialNamesStorage {
        item_1: LootItemSpecialNames {
            name_prefix: 11, name_suffix: 1, item_suffix: 15, 
            }, item_2: LootItemSpecialNames {
            name_prefix: 22, name_suffix: 2, item_suffix: 14, 
            }, item_3: LootItemSpecialNames {
            name_prefix: 33, name_suffix: 3, item_suffix: 13, 
            }, item_4: LootItemSpecialNames {
            name_prefix: 44, name_suffix: 4, item_suffix: 12, 
            }, item_5: LootItemSpecialNames {
            name_prefix: 55, name_suffix: 5, item_suffix: 11, 
            }, item_6: LootItemSpecialNames {
            name_prefix: 66, name_suffix: 6, item_suffix: 10, 
            }, item_7: LootItemSpecialNames {
            name_prefix: 77, name_suffix: 7, item_suffix: 9, 
            }, item_8: LootItemSpecialNames {
            name_prefix: 88, name_suffix: 8, item_suffix: 8, 
            }, item_9: LootItemSpecialNames {
            name_prefix: 99, name_suffix: 9, item_suffix: 7, 
            }, item_10: LootItemSpecialNames {
            name_prefix: 111, name_suffix: 10, item_suffix: 6, 
        }
    };

    let unpacked: LootItemSpecialNamesStorage = Packing::unpack(storage.pack());

    assert(unpacked.item_1.name_prefix == storage.item_1.name_prefix, 'item_1 name_prefix');
    assert(unpacked.item_1.name_suffix == storage.item_1.name_suffix, 'item_1 name_suffix');
    assert(unpacked.item_1.item_suffix == storage.item_1.item_suffix, 'item_1 item_suffix');

    assert(unpacked.item_2.name_prefix == storage.item_2.name_prefix, 'item_2 name_prefix');
    assert(unpacked.item_2.name_suffix == storage.item_2.name_suffix, 'item_2 name_suffix');
    assert(unpacked.item_2.item_suffix == storage.item_2.item_suffix, 'item_2 item_suffix');

    assert(unpacked.item_3.name_prefix == storage.item_3.name_prefix, 'item_3 name_prefix');
    assert(unpacked.item_3.name_suffix == storage.item_3.name_suffix, 'item_3 name_suffix');
    assert(unpacked.item_3.item_suffix == storage.item_3.item_suffix, 'item_3 item_suffix');

    assert(unpacked.item_4.name_prefix == storage.item_4.name_prefix, 'item_4 name_prefix');
    assert(unpacked.item_4.name_suffix == storage.item_4.name_suffix, 'item_4 name_suffix');
    assert(unpacked.item_4.item_suffix == storage.item_4.item_suffix, 'item_4 item_suffix');

    assert(unpacked.item_5.name_prefix == storage.item_5.name_prefix, 'item_5 name_prefix');
    assert(unpacked.item_5.name_suffix == storage.item_5.name_suffix, 'item_5 name_suffix');
    assert(unpacked.item_5.item_suffix == storage.item_5.item_suffix, 'item_5 item_suffix');

    assert(unpacked.item_6.name_prefix == storage.item_6.name_prefix, 'item_6 name_prefix');
    assert(unpacked.item_6.name_suffix == storage.item_6.name_suffix, 'item_6 name_suffix');
    assert(unpacked.item_6.item_suffix == storage.item_6.item_suffix, 'item_6 item_suffix');

    assert(unpacked.item_7.name_prefix == storage.item_7.name_prefix, 'item_7 name_prefix');
    assert(unpacked.item_7.name_suffix == storage.item_7.name_suffix, 'item_7 name_suffix');
    assert(unpacked.item_7.item_suffix == storage.item_7.item_suffix, 'item_7 item_suffix');

    assert(unpacked.item_8.name_prefix == storage.item_8.name_prefix, 'item_8 name_prefix');
    assert(unpacked.item_8.name_suffix == storage.item_8.name_suffix, 'item_8 name_suffix');
    assert(unpacked.item_8.item_suffix == storage.item_8.item_suffix, 'item_8 item_suffix');

    assert(unpacked.item_9.name_prefix == storage.item_9.name_prefix, 'item_9 name_prefix');
    assert(unpacked.item_9.name_suffix == storage.item_9.name_suffix, 'item_9 name_suffix');
    assert(unpacked.item_9.item_suffix == storage.item_9.item_suffix, 'item_9 item_suffix');

    assert(unpacked.item_10.name_prefix == storage.item_10.name_prefix, 'item_10 name_prefix');
    assert(unpacked.item_10.name_suffix == storage.item_10.name_suffix, 'item_10 name_suffix');
    assert(unpacked.item_10.item_suffix == storage.item_10.item_suffix, 'item_10 item_suffix');
}

#[test]
#[available_gas(5000000)]
fn test_get_item_metadata_slot() {
    let mut adventurer = ImplAdventurer::new(1, 1);

    // add test items
    let item_pendant = ItemPrimitive { id: 1, xp: 1, metadata: 3 };
    let item_silver_ring = ItemPrimitive { id: 4, xp: 1, metadata: 4 };
    let item_ghost_wand = ItemPrimitive { id: 9, xp: 1, metadata: 5 };
    let item_silk_robe = ItemPrimitive { id: 18, xp: 1, metadata: 6 };

    adventurer.add_item(item_pendant);
    adventurer.add_item(item_silver_ring);
    adventurer.add_item(item_ghost_wand);
    adventurer.add_item(item_silk_robe);

    let bag = Bag {
        item_1: ItemPrimitive {
            id: 1, xp: 0, metadata: 4, 
            }, item_2: ItemPrimitive {
            id: 2, xp: 0, metadata: 5, 
            }, item_3: ItemPrimitive {
            id: 3, xp: 0, metadata: 6, 
            }, item_4: ItemPrimitive {
            id: 4, xp: 0, metadata: 7, 
            }, item_5: ItemPrimitive {
            id: 5, xp: 0, metadata: 8, 
            }, item_6: ItemPrimitive {
            id: 6, xp: 0, metadata: 11, 
            }, item_7: ItemPrimitive {
            id: 7, xp: 0, metadata: 0, 
            }, item_8: ItemPrimitive {
            id: 8, xp: 0, metadata: 12, 
            }, item_9: ItemPrimitive {
            id: 9, xp: 0, metadata: 0, 
            }, item_10: ItemPrimitive {
            id: 10, xp: 0, metadata: 0, 
            }, item_11: ItemPrimitive {
            id: 11, xp: 0, metadata: 18, 
        },
    };

    let new_item = ItemPrimitive { id: 1, xp: 1, metadata: 0 };

    let item = ILootItemSpecialNames::get_loot_special_names_slot(adventurer, bag, new_item);

    assert(item.metadata == 19, 'ItemPrimitive');
}

#[test]
#[available_gas(5000000)]
fn test_set_item_metadata_slot() {
    let mut item_meta_storage = LootItemSpecialNamesStorage {
        item_1: LootItemSpecialNames {
            name_prefix: 0, name_suffix: 0, item_suffix: 0, 
            }, item_2: LootItemSpecialNames {
            name_prefix: 0, name_suffix: 0, item_suffix: 0, 
            }, item_3: LootItemSpecialNames {
            name_prefix: 0, name_suffix: 0, item_suffix: 0, 
            }, item_4: LootItemSpecialNames {
            name_prefix: 0, name_suffix: 0, item_suffix: 0, 
            }, item_5: LootItemSpecialNames {
            name_prefix: 0, name_suffix: 0, item_suffix: 0, 
            }, item_6: LootItemSpecialNames {
            name_prefix: 0, name_suffix: 0, item_suffix: 0, 
            }, item_7: LootItemSpecialNames {
            name_prefix: 0, name_suffix: 0, item_suffix: 0, 
            }, item_8: LootItemSpecialNames {
            name_prefix: 0, name_suffix: 0, item_suffix: 0, 
            }, item_9: LootItemSpecialNames {
            name_prefix: 0, name_suffix: 0, item_suffix: 0, 
            }, item_10: LootItemSpecialNames {
            name_prefix: 0, name_suffix: 0, item_suffix: 0, 
        }
    };

    let loot_statistics_1 = ItemPrimitive { id: 102, xp: 0, metadata: 1 };

    let loot_special_names_2 = LootItemSpecialNames {
        name_prefix: 12, name_suffix: 11, item_suffix: 13
    };

    item_meta_storage.set_loot_special_names(loot_statistics_1, loot_special_names_2);

    assert(item_meta_storage.item_1.name_prefix == 12, 'should be 12');
    assert(item_meta_storage.item_1.name_suffix == 11, 'should be 11');
    assert(item_meta_storage.item_1.item_suffix == 13, 'should be 13');

    let loot_statistics_2 = ItemPrimitive { id: 102, xp: 0, metadata: 2 };

    let loot_special_names_2 = LootItemSpecialNames {
        name_prefix: 12, name_suffix: 11, item_suffix: 13
    };

    item_meta_storage.set_loot_special_names(loot_statistics_2, loot_special_names_2);
    assert(item_meta_storage.item_2.name_prefix == 12, 'should be 12');
    assert(item_meta_storage.item_2.name_suffix == 11, 'should be 11');
    assert(item_meta_storage.item_2.item_suffix == 13, 'should be 13');
}

#[test]
#[available_gas(5000000)]
fn test_get_item_metadata() {
    let item_pendant = ItemPrimitive { id: 1, xp: 1, metadata: 1 };
    let item_silver_ring = ItemPrimitive { id: 2, xp: 1, metadata: 2 };
    let item_silk_robe = ItemPrimitive { id: 3, xp: 1, metadata: 3 };
    let item_iron_sword = ItemPrimitive { id: 4, xp: 1, metadata: 4 };
    let item_katana = ItemPrimitive { id: 5, xp: 1, metadata: 5 };
    let item_falchion = ItemPrimitive { id: 6, xp: 1, metadata: 6 };
    let item_leather_gloves = ItemPrimitive { id: 7, xp: 1, metadata: 7 };
    let item_silk_gloves = ItemPrimitive { id: 8, xp: 1, metadata: 8 };
    let item_linen_gloves = ItemPrimitive { id: 9, xp: 1, metadata: 9 };
    let item_crown = ItemPrimitive { id: 10, xp: 1, metadata: 10 };

    let mut item_meta_storage = LootItemSpecialNamesStorage {
        item_1: LootItemSpecialNames {
            name_prefix: 2, name_suffix: 2, item_suffix: 10, 
            }, item_2: LootItemSpecialNames {
            name_prefix: 4, name_suffix: 3, item_suffix: 11, 
            }, item_3: LootItemSpecialNames {
            name_prefix: 5, name_suffix: 4, item_suffix: 11, 
            }, item_4: LootItemSpecialNames {
            name_prefix: 6, name_suffix: 5, item_suffix: 3, 
            }, item_5: LootItemSpecialNames {
            name_prefix: 8, name_suffix: 6, item_suffix: 2, 
            }, item_6: LootItemSpecialNames {
            name_prefix: 9, name_suffix: 7, item_suffix: 1, 
            }, item_7: LootItemSpecialNames {
            name_prefix: 11, name_suffix: 8, item_suffix: 5, 
            }, item_8: LootItemSpecialNames {
            name_prefix: 2, name_suffix: 9, item_suffix: 6, 
            }, item_9: LootItemSpecialNames {
            name_prefix: 3, name_suffix: 0, item_suffix: 7, 
            }, item_10: LootItemSpecialNames {
            name_prefix: 11, name_suffix: 8, item_suffix: 5, 
        }
    };

    let meta_data = item_meta_storage.get_loot_special_names(item_pendant);

    assert(meta_data.name_prefix == 2, 'item_pendant.name_prefix');
    assert(meta_data.name_suffix == 2, 'item_pendant.name_suffix');
    assert(meta_data.item_suffix == 10, 'item_pendant.item_suffix');
    let meta_data = item_meta_storage.get_loot_special_names(item_silver_ring);

    assert(meta_data.name_prefix == 4, 'item_silver_ring.name_prefix');
    assert(meta_data.name_suffix == 3, 'item_silver_ring.name_suffix');
    assert(meta_data.item_suffix == 11, 'item_silver_ring.item_suffix');

    let meta_data = item_meta_storage.get_loot_special_names(item_silk_robe);

    assert(meta_data.name_prefix == 5, 'item_silk_robe.name_prefix');
    assert(meta_data.name_suffix == 4, 'item_silk_robe.name_suffix');
    assert(meta_data.item_suffix == 11, 'item_silk_robe.item_suffix');

    let meta_data = item_meta_storage.get_loot_special_names(item_iron_sword);

    assert(meta_data.name_prefix == 6, 'item_iron_sword.name_prefix');
    assert(meta_data.name_suffix == 5, 'item_iron_sword.name_suffix');
    assert(meta_data.item_suffix == 3, 'item_iron_sword.item_suffix');

    let meta_data = item_meta_storage.get_loot_special_names(item_katana);

    assert(meta_data.name_prefix == 8, 'item_katana');
    assert(meta_data.name_suffix == 6, 'item_katana');
    assert(meta_data.item_suffix == 2, 'item_katana');

    let meta_data = item_meta_storage.get_loot_special_names(item_falchion);

    assert(meta_data.name_prefix == 9, 'item_falchion');
    assert(meta_data.name_suffix == 7, 'item_falchion');
    assert(meta_data.item_suffix == 1, 'item_falchion');

    let meta_data = item_meta_storage.get_loot_special_names(item_leather_gloves);

    assert(meta_data.name_prefix == 11, 'item_leather_gloves');
    assert(meta_data.name_suffix == 8, 'item_leather_gloves');
    assert(meta_data.item_suffix == 5, 'item_leather_gloves');

    let meta_data = item_meta_storage.get_loot_special_names(item_silk_gloves);

    assert(meta_data.name_prefix == 2, 'item_silk_gloves');
    assert(meta_data.name_suffix == 9, 'item_silk_gloves');
    assert(meta_data.item_suffix == 6, 'item_silk_gloves');

    let meta_data = item_meta_storage.get_loot_special_names(item_linen_gloves);

    assert(meta_data.name_prefix == 3, 'item_linen_gloves');
    assert(meta_data.name_suffix == 0, 'item_linen_gloves');
    assert(meta_data.item_suffix == 7, 'item_linen_gloves');

    let meta_data = item_meta_storage.get_loot_special_names(item_crown);

    assert(meta_data.name_prefix == 11, 'item_crown');
    assert(meta_data.name_suffix == 8, 'item_crown');
    assert(meta_data.item_suffix == 5, 'item_crown');
}
