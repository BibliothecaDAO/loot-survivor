use core::serde::Serde;
use traits::{TryInto, Into};
use option::OptionTrait;
use integer::{
    U256TryIntoU32, U256TryIntoU16, U256TryIntoU8
};
use pack::pack::{pack_value, unpack_value};
use pack::constants::{pow, mask};

use super::adventurer::{Adventurer, IAdventurer, ImplAdventurer};
use super::bag::{Bag, BagActions, LootStatistics};

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

// LootStatistics meta only is set once and is filled up as items are found
// There is no swapping of positions
// When an item is found we find the next available slot and set it on the LootStatistics NOT in the metadata -> this saves gas
// We only set the metadata when an item is upgraded
trait ILootItemSpecialNames {
    fn pack(self: LootItemSpecialNamesStorage) -> felt252;
    fn unpack(packed: felt252) -> LootItemSpecialNamesStorage;

    // takes LootStatistics and sets the metadata slot for that item
    // 1. Find highest slot from equipped and unequipped items
    // 2. Return LootStatistics with slot which is then saved on the Adventurer/Bag

    // this could be somewhere else
    // this needs to be run when an item is found/purchased
    fn get_loot_special_names_slot(
        adventurer: Adventurer, bag: Bag, loot_statistics: LootStatistics
    ) -> LootStatistics;

    // on contract side we check if item.metadata > 10 if it is pass in second metadata storage
    fn set_loot_special_names(
        ref self: LootItemSpecialNamesStorage,
        loot_statistics: LootStatistics,
        loot_special_names: LootItemSpecialNames
    ) -> LootItemSpecialNamesStorage;

    fn get_loot_special_names(
        self: LootItemSpecialNamesStorage, loot_statistics: LootStatistics
    ) -> LootItemSpecialNames;
}

impl ImplLootItemSpecialNames of ILootItemSpecialNames {
    fn get_loot_special_names(
        self: LootItemSpecialNamesStorage, loot_statistics: LootStatistics
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

    fn pack(self: LootItemSpecialNamesStorage) -> felt252 {
        let mut packed = 0;
        packed = packed | pack_value(self.item_1.name_prefix.into(), pow::TWO_POW_244);
        packed = packed | pack_value(self.item_1.name_suffix.into(), pow::TWO_POW_240);
        packed = packed | pack_value(self.item_1.item_suffix.into(), pow::TWO_POW_236);

        packed = packed | pack_value(self.item_2.name_prefix.into(), pow::TWO_POW_229);
        packed = packed | pack_value(self.item_2.name_suffix.into(), pow::TWO_POW_224);
        packed = packed | pack_value(self.item_2.item_suffix.into(), pow::TWO_POW_220);

        packed = packed | pack_value(self.item_3.name_prefix.into(), pow::TWO_POW_213);
        packed = packed | pack_value(self.item_3.name_suffix.into(), pow::TWO_POW_208);
        packed = packed | pack_value(self.item_3.item_suffix.into(), pow::TWO_POW_204);

        packed = packed | pack_value(self.item_4.name_prefix.into(), pow::TWO_POW_197);
        packed = packed | pack_value(self.item_4.name_suffix.into(), pow::TWO_POW_192);
        packed = packed | pack_value(self.item_4.item_suffix.into(), pow::TWO_POW_188);

        packed = packed | pack_value(self.item_5.name_prefix.into(), pow::TWO_POW_181);
        packed = packed | pack_value(self.item_5.name_suffix.into(), pow::TWO_POW_176);
        packed = packed | pack_value(self.item_5.item_suffix.into(), pow::TWO_POW_172);

        packed = packed | pack_value(self.item_6.name_prefix.into(), pow::TWO_POW_165);
        packed = packed | pack_value(self.item_6.name_suffix.into(), pow::TWO_POW_160);
        packed = packed | pack_value(self.item_6.item_suffix.into(), pow::TWO_POW_156);

        packed = packed | pack_value(self.item_7.name_prefix.into(), pow::TWO_POW_149);
        packed = packed | pack_value(self.item_7.name_suffix.into(), pow::TWO_POW_144);
        packed = packed | pack_value(self.item_7.item_suffix.into(), pow::TWO_POW_140);

        packed = packed | pack_value(self.item_8.name_prefix.into(), pow::TWO_POW_133);
        packed = packed | pack_value(self.item_8.name_suffix.into(), pow::TWO_POW_128);
        packed = packed | pack_value(self.item_8.item_suffix.into(), pow::TWO_POW_124);

        packed = packed | pack_value(self.item_9.name_prefix.into(), pow::TWO_POW_117);
        packed = packed | pack_value(self.item_9.name_suffix.into(), pow::TWO_POW_112);
        packed = packed | pack_value(self.item_9.item_suffix.into(), pow::TWO_POW_108);

        packed = packed | pack_value(self.item_10.name_prefix.into(), pow::TWO_POW_101);
        packed = packed | pack_value(self.item_10.name_suffix.into(), pow::TWO_POW_96);
        packed = packed | pack_value(self.item_10.item_suffix.into(), pow::TWO_POW_92);

        packed.try_into().unwrap()
    }

    fn unpack(packed: felt252) -> LootItemSpecialNamesStorage {
        internal::revoke_ap_tracking();
        let packed = packed.into();

        LootItemSpecialNamesStorage {
            item_1: LootItemSpecialNames {
                name_prefix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_244, mask::MASK_7)
                )
                    .unwrap(),
                name_suffix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_240, mask::MASK_5)
                )
                    .unwrap(),
                item_suffix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_236, mask::MASK_4)
                )
                    .unwrap(),
                }, item_2: LootItemSpecialNames {
                name_prefix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_229, mask::MASK_7)
                )
                    .unwrap(),
                name_suffix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_224, mask::MASK_5)
                )
                    .unwrap(),
                item_suffix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_220, mask::MASK_4)
                )
                    .unwrap(),
                }, item_3: LootItemSpecialNames {
                name_prefix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_213, mask::MASK_7)
                )
                    .unwrap(),
                name_suffix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_208, mask::MASK_5)
                )
                    .unwrap(),
                item_suffix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_204, mask::MASK_4)
                )
                    .unwrap(),
                }, item_4: LootItemSpecialNames {
                name_prefix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_197, mask::MASK_7)
                )
                    .unwrap(),
                name_suffix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_192, mask::MASK_5)
                )
                    .unwrap(),
                item_suffix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_188, mask::MASK_4)
                )
                    .unwrap(),
                }, item_5: LootItemSpecialNames {
                name_prefix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_181, mask::MASK_7)
                )
                    .unwrap(),
                name_suffix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_176, mask::MASK_5)
                )
                    .unwrap(),
                item_suffix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_172, mask::MASK_4)
                )
                    .unwrap(),
                }, item_6: LootItemSpecialNames {
                name_prefix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_165, mask::MASK_7)
                )
                    .unwrap(),
                name_suffix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_160, mask::MASK_5)
                )
                    .unwrap(),
                item_suffix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_156, mask::MASK_4)
                )
                    .unwrap(),
                }, item_7: LootItemSpecialNames {
                name_prefix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_149, mask::MASK_7)
                )
                    .unwrap(),
                name_suffix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_144, mask::MASK_5)
                )
                    .unwrap(),
                item_suffix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_140, mask::MASK_4)
                )
                    .unwrap(),
                }, item_8: LootItemSpecialNames {
                name_prefix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_133, mask::MASK_7)
                )
                    .unwrap(),
                name_suffix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_128, mask::MASK_5)
                )
                    .unwrap(),
                item_suffix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_124, mask::MASK_4)
                )
                    .unwrap(),
                }, item_9: LootItemSpecialNames {
                name_prefix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_117, mask::MASK_7)
                )
                    .unwrap(),
                name_suffix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_112, mask::MASK_5)
                )
                    .unwrap(),
                item_suffix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_108, mask::MASK_4)
                )
                    .unwrap(),
                }, item_10: LootItemSpecialNames {
                name_prefix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_101, mask::MASK_7)
                )
                    .unwrap(),
                name_suffix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_96, mask::MASK_5)
                )
                    .unwrap(),
                item_suffix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_92, mask::MASK_4)
                )
                    .unwrap(),
            }
        }
    }
    fn get_loot_special_names_slot(
        adventurer: Adventurer, bag: Bag, loot_statistics: LootStatistics
    ) -> LootStatistics {
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
        if bag.item_12.metadata >= slot {
            slot = bag.item_12.metadata;
        }

        // if no slots -> return first index which is 0
        if slot == 1 {
            LootStatistics { id: loot_statistics.id, xp: loot_statistics.xp, metadata: 1 }
        } else {
            LootStatistics { id: loot_statistics.id, xp: loot_statistics.xp, metadata: slot + 1 }
        }
    }
    fn set_loot_special_names(
        ref self: LootItemSpecialNamesStorage,
        loot_statistics: LootStatistics,
        loot_special_names: LootItemSpecialNames
    ) -> LootItemSpecialNamesStorage {
        if loot_statistics.metadata == STORAGE::INDEX_1 {
            self.item_1 = loot_special_names;
            self
        } else if loot_statistics.metadata == STORAGE::INDEX_2 {
            self.item_2 = loot_special_names;
            self
        } else if loot_statistics.metadata == STORAGE::INDEX_3 {
            self.item_3 = loot_special_names;
            self
        } else if loot_statistics.metadata == STORAGE::INDEX_4 {
            self.item_4 = loot_special_names;
            self
        } else if loot_statistics.metadata == STORAGE::INDEX_5 {
            self.item_5 = loot_special_names;
            self
        } else if loot_statistics.metadata == STORAGE::INDEX_6 {
            self.item_6 = loot_special_names;
            self
        } else if loot_statistics.metadata == STORAGE::INDEX_7 {
            self.item_7 = loot_special_names;
            self
        } else if loot_statistics.metadata == STORAGE::INDEX_8 {
            self.item_8 = loot_special_names;
            self
        } else if loot_statistics.metadata == STORAGE::INDEX_9 {
            self.item_9 = loot_special_names;
            self
        } else {
            self.item_10 = loot_special_names;
            self
        }
        self
    }
}

#[test]
#[available_gas(5000000)]
fn test_item_meta_packing() {
    let mut item_meta_storage = LootItemSpecialNamesStorage {
        item_1: LootItemSpecialNames {
            name_prefix: 127, name_suffix: 31, item_suffix: 15, 
            }, item_2: LootItemSpecialNames {
            name_prefix: 127, name_suffix: 31, item_suffix: 15, 
            }, item_3: LootItemSpecialNames {
            name_prefix: 127, name_suffix: 31, item_suffix: 15, 
            }, item_4: LootItemSpecialNames {
            name_prefix: 127, name_suffix: 31, item_suffix: 15, 
            }, item_5: LootItemSpecialNames {
            name_prefix: 127, name_suffix: 31, item_suffix: 15, 
            }, item_6: LootItemSpecialNames {
            name_prefix: 127, name_suffix: 31, item_suffix: 15, 
            }, item_7: LootItemSpecialNames {
            name_prefix: 127, name_suffix: 31, item_suffix: 15, 
            }, item_8: LootItemSpecialNames {
            name_prefix: 127, name_suffix: 31, item_suffix: 15, 
            }, item_9: LootItemSpecialNames {
            name_prefix: 127, name_suffix: 31, item_suffix: 15, 
            }, item_10: LootItemSpecialNames {
            name_prefix: 127, name_suffix: 31, item_suffix: 15, 
        }
    };

    let unpacked = ImplLootItemSpecialNames::unpack(item_meta_storage.pack());

    assert(unpacked.item_1.name_prefix == 127, 'item_1 name_prefix  127');
    assert(unpacked.item_1.name_suffix == 31, 'item_1 name_suffix  31');
    assert(unpacked.item_1.item_suffix == 15, 'item_1 item_suffix 15');

    assert(unpacked.item_2.name_prefix == 127, 'item_2 name_prefix  127');
    assert(unpacked.item_2.name_suffix == 31, 'item_2 name_suffix  31');
    assert(unpacked.item_2.item_suffix == 15, 'item_2 item_suffix 15');

    assert(unpacked.item_3.name_prefix == 127, 'item_3 name_prefix  127');
    assert(unpacked.item_3.name_suffix == 31, 'item_3 name_suffix  31');
    assert(unpacked.item_3.item_suffix == 15, 'item_3 item_suffix 15');

    assert(unpacked.item_4.name_prefix == 127, 'item_4 name_prefix  127');
    assert(unpacked.item_4.name_suffix == 31, 'item_4 name_suffix  31');
    assert(unpacked.item_4.item_suffix == 15, 'item_4 item_suffix 15');

    assert(unpacked.item_5.name_prefix == 127, 'item_5 name_prefix  127');
    assert(unpacked.item_5.name_suffix == 31, 'item_5 name_suffix  31');
    assert(unpacked.item_5.item_suffix == 15, 'item_5 item_suffix 15');

    assert(unpacked.item_6.name_prefix == 127, 'item_6 name_prefix  127');
    assert(unpacked.item_6.name_suffix == 31, 'item_6 name_suffix  31');
    assert(unpacked.item_6.item_suffix == 15, 'item_6 item_suffix 15');

    assert(unpacked.item_7.name_prefix == 127, 'item_7 name_prefix  127');
    assert(unpacked.item_7.name_suffix == 31, 'item_7 name_suffix  31');
    assert(unpacked.item_7.item_suffix == 15, 'item_7 item_suffix 15');

    assert(unpacked.item_8.name_prefix == 127, 'item_8 name_prefix  127');
    assert(unpacked.item_8.name_suffix == 31, 'item_8 name_suffix  31');
    assert(unpacked.item_8.item_suffix == 15, 'item_8 item_suffix 15');

    assert(unpacked.item_9.name_prefix == 127, 'item_9 name_prefix  127');
    assert(unpacked.item_9.name_suffix == 31, 'item_9 name_suffix  31');
    assert(unpacked.item_9.item_suffix == 15, 'item_9 item_suffix 15');

    assert(unpacked.item_10.name_prefix == 127, 'item_10 name_prefix  127');
    assert(unpacked.item_10.name_suffix == 31, 'item_10 name_suffix  31');
    assert(unpacked.item_10.item_suffix == 15, 'item_10 item_suffix 15');
}

#[test]
#[available_gas(5000000)]
fn test_get_item_metadata_slot() {
    let mut adventurer = ImplAdventurer::new(1, 1);

    // add test items
    let item_pendant = LootStatistics { id: 1, xp: 1, metadata: 3 };
    let item_silver_ring = LootStatistics { id: 4, xp: 1, metadata: 4 };
    let item_ghost_wand = LootStatistics { id: 9, xp: 1, metadata: 5 };
    let item_silk_robe = LootStatistics { id: 18, xp: 1, metadata: 6 };

    adventurer.add_item(item_pendant);
    adventurer.add_item(item_silver_ring);
    adventurer.add_item(item_ghost_wand);
    adventurer.add_item(item_silk_robe);

    let bag = Bag {
        item_1: LootStatistics {
            id: 1, xp: 0, metadata: 4, 
            }, item_2: LootStatistics {
            id: 2, xp: 0, metadata: 5, 
            }, item_3: LootStatistics {
            id: 3, xp: 0, metadata: 6, 
            }, item_4: LootStatistics {
            id: 4, xp: 0, metadata: 7, 
            }, item_5: LootStatistics {
            id: 5, xp: 0, metadata: 8, 
            }, item_6: LootStatistics {
            id: 6, xp: 0, metadata: 11, 
            }, item_7: LootStatistics {
            id: 7, xp: 0, metadata: 0, 
            }, item_8: LootStatistics {
            id: 8, xp: 0, metadata: 12, 
            }, item_9: LootStatistics {
            id: 9, xp: 0, metadata: 0, 
            }, item_10: LootStatistics {
            id: 10, xp: 0, metadata: 0, 
            }, item_11: LootStatistics {
            id: 11, xp: 0, metadata: 18, 
            }, item_12: LootStatistics {
            id: 12, xp: 0, metadata: 0, 
        },
    };

    let new_item = LootStatistics { id: 1, xp: 1, metadata: 0 };

    let item = ILootItemSpecialNames::get_loot_special_names_slot(adventurer, bag, new_item);

    assert(item.metadata == 19, 'LootStatistics');
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

    let loot_statistics_1 = LootStatistics { id: 102, xp: 0, metadata: 1 };

    let loot_special_names_2 = LootItemSpecialNames {
        name_prefix: 12, name_suffix: 11, item_suffix: 13
    };

    item_meta_storage.set_loot_special_names(loot_statistics_1, loot_special_names_2);

    assert(item_meta_storage.item_1.name_prefix == 12, 'should be 12');
    assert(item_meta_storage.item_1.name_suffix == 11, 'should be 11');
    assert(item_meta_storage.item_1.item_suffix == 13, 'should be 13');

    let loot_statistics_2 = LootStatistics { id: 102, xp: 0, metadata: 2 };

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
    let item_pendant = LootStatistics { id: 1, xp: 1, metadata: 1 };
    let item_silver_ring = LootStatistics { id: 2, xp: 1, metadata: 2 };
    let item_silk_robe = LootStatistics { id: 3, xp: 1, metadata: 3 };
    let item_iron_sword = LootStatistics { id: 4, xp: 1, metadata: 4 };
    let item_katana = LootStatistics { id: 5, xp: 1, metadata: 5 };
    let item_falchion = LootStatistics { id: 6, xp: 1, metadata: 6 };
    let item_leather_gloves = LootStatistics { id: 7, xp: 1, metadata: 7 };
    let item_silk_gloves = LootStatistics { id: 8, xp: 1, metadata: 8 };
    let item_linen_gloves = LootStatistics { id: 9, xp: 1, metadata: 9 };
    let item_crown = LootStatistics { id: 10, xp: 1, metadata: 10 };

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
