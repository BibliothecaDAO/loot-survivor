use core::serde::Serde;
use integer::{
    U128IntoFelt252, Felt252IntoU256, Felt252TryIntoU64, U256TryIntoFelt252, u256_from_felt252,
};
use traits::{TryInto, Into};
use option::OptionTrait;
use debug::PrintTrait;

use pack::pack::{pack_value, unpack_value, U256TryIntoU32, U256TryIntoU16, U256TryIntoU8};
use pack::constants::{pow, mask};

use super::adventurer::{Adventurer, AdventurerActions, Actions};

use super::bag::{Bag, BagActions, Item};

mod ITEM_META_INDEX {
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

#[derive(Drop, Copy)]
struct ItemMeta {
    id: u8, // 7 bits
    name_prefix: u8, // 7 bits
    name_suffix: u8, // 5 bits
    item_suffix: u8, // 4 bit
}

#[derive(Drop, Copy)]
struct ItemMetaStorage {
    item_1: ItemMeta,
    item_2: ItemMeta,
    item_3: ItemMeta,
    item_4: ItemMeta,
    item_5: ItemMeta,
    item_6: ItemMeta,
    item_7: ItemMeta,
    item_8: ItemMeta,
    item_9: ItemMeta,
    item_10: ItemMeta,
}

// Item meta only is set once and is filled up as items are found
// There is no swapping of positions
// When an item is found we find the next available slot and set it on the Item NOT in the metadata -> this saves gas
// We only set the metadata when an item is upgraded
trait ItemMetaActions {
    fn pack(self: ItemMetaStorage) -> felt252;
    fn unpack(packed: felt252) -> ItemMetaStorage;

    // takes Item and sets the metadata slot for that item
    // 1. Find highest slot from equipped and unequipped items
    // 2. Return Item with slot which is then saved on the Adventurer/Bag

    // this could be somewhere else
    // this needs to be run when an item is found/purchased
    fn get_item_metadata_slot(adventurer: Adventurer, bag: Bag, item: Item) -> Item;

    // on contract side we check if item.metadata > 9 if it is pass in second metadata storage
    fn set_item_metadata(
        ref self: ItemMetaStorage, item: Item, item_meta: ItemMeta
    ) -> ItemMetaStorage;
}


impl ImplItemMetaActions of ItemMetaActions {
    fn pack(self: ItemMetaStorage) -> felt252 {
        let mut packed = 0;
        packed = packed | pack_value(self.item_1.id.into(), pow::TWO_POW_244);
        packed = packed | pack_value(self.item_1.name_prefix.into(), pow::TWO_POW_238);
        packed = packed | pack_value(self.item_1.name_suffix.into(), pow::TWO_POW_233);
        packed = packed | pack_value(self.item_1.item_suffix.into(), pow::TWO_POW_229);

        packed = packed | pack_value(self.item_2.id.into(), pow::TWO_POW_222);
        packed = packed | pack_value(self.item_2.name_prefix.into(), pow::TWO_POW_215);
        packed = packed | pack_value(self.item_2.name_suffix.into(), pow::TWO_POW_210);
        packed = packed | pack_value(self.item_2.item_suffix.into(), pow::TWO_POW_206);

        packed = packed | pack_value(self.item_3.id.into(), pow::TWO_POW_199);
        packed = packed | pack_value(self.item_3.name_prefix.into(), pow::TWO_POW_192);
        packed = packed | pack_value(self.item_3.name_suffix.into(), pow::TWO_POW_187);
        packed = packed | pack_value(self.item_3.item_suffix.into(), pow::TWO_POW_183);

        packed = packed | pack_value(self.item_4.id.into(), pow::TWO_POW_176);
        packed = packed | pack_value(self.item_4.name_prefix.into(), pow::TWO_POW_169);
        packed = packed | pack_value(self.item_4.name_suffix.into(), pow::TWO_POW_164);
        packed = packed | pack_value(self.item_4.item_suffix.into(), pow::TWO_POW_160);

        packed = packed | pack_value(self.item_5.id.into(), pow::TWO_POW_153);
        packed = packed | pack_value(self.item_5.name_prefix.into(), pow::TWO_POW_146);
        packed = packed | pack_value(self.item_5.name_suffix.into(), pow::TWO_POW_141);
        packed = packed | pack_value(self.item_5.item_suffix.into(), pow::TWO_POW_137);

        packed = packed | pack_value(self.item_6.id.into(), pow::TWO_POW_130);
        packed = packed | pack_value(self.item_6.name_prefix.into(), pow::TWO_POW_123);
        packed = packed | pack_value(self.item_6.name_suffix.into(), pow::TWO_POW_118);
        packed = packed | pack_value(self.item_6.item_suffix.into(), pow::TWO_POW_114);

        packed = packed | pack_value(self.item_7.id.into(), pow::TWO_POW_107);
        packed = packed | pack_value(self.item_7.name_prefix.into(), pow::TWO_POW_100);
        packed = packed | pack_value(self.item_7.name_suffix.into(), pow::TWO_POW_95);
        packed = packed | pack_value(self.item_7.item_suffix.into(), pow::TWO_POW_91);

        packed = packed | pack_value(self.item_8.id.into(), pow::TWO_POW_84);
        packed = packed | pack_value(self.item_8.name_prefix.into(), pow::TWO_POW_77);
        packed = packed | pack_value(self.item_8.name_suffix.into(), pow::TWO_POW_72);
        packed = packed | pack_value(self.item_8.item_suffix.into(), pow::TWO_POW_68);

        packed = packed | pack_value(self.item_9.id.into(), pow::TWO_POW_61);
        packed = packed | pack_value(self.item_9.name_prefix.into(), pow::TWO_POW_54);
        packed = packed | pack_value(self.item_9.name_suffix.into(), pow::TWO_POW_49);
        packed = packed | pack_value(self.item_9.item_suffix.into(), pow::TWO_POW_45);

        packed = packed | pack_value(self.item_10.id.into(), pow::TWO_POW_38);
        packed = packed | pack_value(self.item_10.name_prefix.into(), pow::TWO_POW_31);
        packed = packed | pack_value(self.item_10.name_suffix.into(), pow::TWO_POW_26);
        packed = packed | pack_value(self.item_10.item_suffix.into(), pow::TWO_POW_22);

        packed.try_into().unwrap()
    }
    fn unpack(packed: felt252) -> ItemMetaStorage {
        let packed = packed.into();

        ItemMetaStorage {
            item_1: ItemMeta {
                id: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_244, mask::MASK_7))
                    .unwrap(),
                name_prefix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_238, mask::MASK_7)
                )
                    .unwrap(),
                name_suffix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_233, mask::MASK_5)
                )
                    .unwrap(),
                item_suffix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_229, mask::MASK_4)
                )
                    .unwrap(),
                }, item_2: ItemMeta {
                id: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_222, mask::MASK_7))
                    .unwrap(),
                name_prefix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_215, mask::MASK_7)
                )
                    .unwrap(),
                name_suffix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_210, mask::MASK_5)
                )
                    .unwrap(),
                item_suffix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_206, mask::MASK_4)
                )
                    .unwrap(),
                }, item_3: ItemMeta {
                id: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_199, mask::MASK_7))
                    .unwrap(),
                name_prefix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_192, mask::MASK_7)
                )
                    .unwrap(),
                name_suffix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_187, mask::MASK_5)
                )
                    .unwrap(),
                item_suffix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_183, mask::MASK_4)
                )
                    .unwrap(),
                }, item_4: ItemMeta {
                id: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_176, mask::MASK_7))
                    .unwrap(),
                name_prefix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_169, mask::MASK_7)
                )
                    .unwrap(),
                name_suffix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_164, mask::MASK_5)
                )
                    .unwrap(),
                item_suffix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_160, mask::MASK_4)
                )
                    .unwrap(),
                }, item_5: ItemMeta {
                id: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_153, mask::MASK_7))
                    .unwrap(),
                name_prefix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_146, mask::MASK_7)
                )
                    .unwrap(),
                name_suffix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_141, mask::MASK_5)
                )
                    .unwrap(),
                item_suffix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_137, mask::MASK_4)
                )
                    .unwrap(),
                }, item_6: ItemMeta {
                id: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_130, mask::MASK_7))
                    .unwrap(),
                name_prefix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_123, mask::MASK_7)
                )
                    .unwrap(),
                name_suffix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_118, mask::MASK_5)
                )
                    .unwrap(),
                item_suffix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_114, mask::MASK_4)
                )
                    .unwrap(),
                }, item_7: ItemMeta {
                id: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_107, mask::MASK_7))
                    .unwrap(),
                name_prefix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_100, mask::MASK_7)
                )
                    .unwrap(),
                name_suffix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_95, mask::MASK_5)
                )
                    .unwrap(),
                item_suffix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_91, mask::MASK_4)
                )
                    .unwrap(),
                }, item_8: ItemMeta {
                id: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_84, mask::MASK_7))
                    .unwrap(),
                name_prefix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_77, mask::MASK_7)
                )
                    .unwrap(),
                name_suffix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_72, mask::MASK_5)
                )
                    .unwrap(),
                item_suffix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_68, mask::MASK_4)
                )
                    .unwrap(),
                }, item_9: ItemMeta {
                id: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_61, mask::MASK_7))
                    .unwrap(),
                name_prefix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_54, mask::MASK_7)
                )
                    .unwrap(),
                name_suffix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_49, mask::MASK_5)
                )
                    .unwrap(),
                item_suffix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_45, mask::MASK_4)
                )
                    .unwrap(),
                }, item_10: ItemMeta {
                id: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_38, mask::MASK_7))
                    .unwrap(),
                name_prefix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_31, mask::MASK_7)
                )
                    .unwrap(),
                name_suffix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_26, mask::MASK_5)
                )
                    .unwrap(),
                item_suffix: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_22, mask::MASK_4)
                )
                    .unwrap(),
            }
        }
    }
    fn get_item_metadata_slot(adventurer: Adventurer, bag: Bag, item: Item) -> Item {
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
            Item { id: item.id, xp: item.xp, metadata: 1 }
        } else {
            Item { id: item.id, xp: item.xp, metadata: slot + 1 }
        }
    }
    fn set_item_metadata(
        ref self: ItemMetaStorage, item: Item, item_meta: ItemMeta
    ) -> ItemMetaStorage {
        // TODO:
        // @loothere: should we generate the prefix here or up in the contract?
        if item.metadata == 1 {
            self.item_1 = item_meta;
            self
        } else if item.metadata == 2 {
            self.item_2 = item_meta;
            self
        } else if item.metadata == 3 {
            self.item_3 = item_meta;
            self
        } else if item.metadata == 4 {
            self.item_4 = item_meta;
            self
        } else if item.metadata == 5 {
            self.item_5 = item_meta;
            self
        } else if item.metadata == 6 {
            self.item_6 = item_meta;
            self
        } else if item.metadata == 7 {
            self.item_7 = item_meta;
            self
        } else if item.metadata == 8 {
            self.item_8 = item_meta;
            self
        } else if item.metadata == 9 {
            self.item_9 = item_meta;
            self
        } else {
            self.item_10 = item_meta;
            self
        }
    }
}
// #[test]
// #[available_gas(5000000)]
// fn test_item_meta_packing() {
//     let mut item_meta_storage = ItemMetaStorage {
//         item_1: ItemMeta {
//             id: 127, name_prefix: 127, name_suffix: 31, item_suffix: 15, 
//             }, item_2: ItemMeta {
//             id: 127, name_prefix: 127, name_suffix: 31, item_suffix: 15, 
//             }, item_3: ItemMeta {
//             id: 127, name_prefix: 127, name_suffix: 31, item_suffix: 15, 
//             }, item_4: ItemMeta {
//             id: 127, name_prefix: 127, name_suffix: 31, item_suffix: 15, 
//             }, item_5: ItemMeta {
//             id: 127, name_prefix: 127, name_suffix: 31, item_suffix: 15, 
//             }, item_6: ItemMeta {
//             id: 127, name_prefix: 127, name_suffix: 31, item_suffix: 15, 
//             }, item_7: ItemMeta {
//             id: 127, name_prefix: 127, name_suffix: 31, item_suffix: 15, 
//             }, item_8: ItemMeta {
//             id: 127, name_prefix: 127, name_suffix: 31, item_suffix: 15, 
//             }, item_9: ItemMeta {
//             id: 127, name_prefix: 127, name_suffix: 31, item_suffix: 15, 
//             }, item_10: ItemMeta {
//             id: 127, name_prefix: 127, name_suffix: 31, item_suffix: 15, 
//         }
//     };

//     let unpacked = ImplItemMetaActions::unpack(item_meta_storage.pack());

//     unpacked.item_1.id.print();

//     assert(unpacked.item_1.id == 127, 'item_1 id 127');
//     assert(unpacked.item_1.name_prefix == 127, 'item_1 name_prefix  127');
//     assert(unpacked.item_1.name_suffix == 31, 'item_1 name_suffix  31');
//     assert(unpacked.item_1.item_suffix == 15, 'item_1 item_suffix 15');

//     assert(unpacked.item_2.id == 127, 'item_2 id 127');
//     assert(unpacked.item_2.name_prefix == 127, 'item_2 name_prefix  127');
//     assert(unpacked.item_2.name_suffix == 31, 'item_2 name_suffix  31');
//     assert(unpacked.item_2.item_suffix == 15, 'item_2 item_suffix 15');

//     assert(unpacked.item_3.id == 127, 'item_3 id 127');
//     assert(unpacked.item_3.name_prefix == 127, 'item_3 name_prefix  127');
//     assert(unpacked.item_3.name_suffix == 31, 'item_3 name_suffix  31');
//     assert(unpacked.item_3.item_suffix == 15, 'item_3 item_suffix 15');

//     assert(unpacked.item_4.id == 127, 'item_4 id 127');
//     assert(unpacked.item_4.name_prefix == 127, 'item_4 name_prefix  127');
//     assert(unpacked.item_4.name_suffix == 31, 'item_4 name_suffix  31');
//     assert(unpacked.item_4.item_suffix == 15, 'item_4 item_suffix 15');

//     assert(unpacked.item_5.id == 127, 'item_5 id 127');
//     assert(unpacked.item_5.name_prefix == 127, 'item_5 name_prefix  127');
//     assert(unpacked.item_5.name_suffix == 31, 'item_5 name_suffix  31');
//     assert(unpacked.item_5.item_suffix == 15, 'item_5 item_suffix 15');

//     assert(unpacked.item_6.id == 127, 'item_6 id 127');
//     assert(unpacked.item_6.name_prefix == 127, 'item_6 name_prefix  127');
//     assert(unpacked.item_6.name_suffix == 31, 'item_6 name_suffix  31');
//     assert(unpacked.item_6.item_suffix == 15, 'item_6 item_suffix 15');

//     assert(unpacked.item_7.id == 127, 'item_7 id 127');
//     assert(unpacked.item_7.name_prefix == 127, 'item_7 name_prefix  127');
//     assert(unpacked.item_7.name_suffix == 31, 'item_7 name_suffix  31');
//     assert(unpacked.item_7.item_suffix == 15, 'item_7 item_suffix 15');

//     assert(unpacked.item_8.id == 127, 'item_8 id 127');
//     assert(unpacked.item_8.name_prefix == 127, 'item_8 name_prefix  127');
//     assert(unpacked.item_8.name_suffix == 31, 'item_8 name_suffix  31');
//     assert(unpacked.item_8.item_suffix == 15, 'item_8 item_suffix 15');

//     assert(unpacked.item_9.id == 127, 'item_9 id 127');
//     assert(unpacked.item_9.name_prefix == 127, 'item_9 name_prefix  127');
//     assert(unpacked.item_9.name_suffix == 31, 'item_9 name_suffix  31');
//     assert(unpacked.item_9.item_suffix == 15, 'item_9 item_suffix 15');

//     assert(unpacked.item_10.id == 127, 'item_10 id 127');
//     assert(unpacked.item_10.name_prefix == 127, 'item_10 name_prefix  127');
//     assert(unpacked.item_10.name_suffix == 31, 'item_10 name_suffix  31');
//     assert(unpacked.item_10.item_suffix == 15, 'item_10 item_suffix 15');
// }

// #[test]
// #[available_gas(5000000)]
// fn test_get_item_metadata_slot() {
//     let mut adventurer = AdventurerActions::new(1, 1);

//     // add test items
//     let item_pendant = Item { id: 1, xp: 1, metadata: 3 };
//     let item_silver_ring = Item { id: 4, xp: 1, metadata: 4 };
//     let item_ghost_wand = Item { id: 9, xp: 1, metadata: 5 };
//     let item_silk_robe = Item { id: 18, xp: 1, metadata: 6 };

//     adventurer.add_item(item_pendant);
//     adventurer.add_item(item_silver_ring);
//     adventurer.add_item(item_ghost_wand);
//     adventurer.add_item(item_silk_robe);

//     let bag = Bag {
//         item_1: Item {
//             id: 1, xp: 0, metadata: 4, 
//             }, item_2: Item {
//             id: 2, xp: 0, metadata: 5, 
//             }, item_3: Item {
//             id: 3, xp: 0, metadata: 6, 
//             }, item_4: Item {
//             id: 4, xp: 0, metadata: 7, 
//             }, item_5: Item {
//             id: 5, xp: 0, metadata: 8, 
//             }, item_6: Item {
//             id: 6, xp: 0, metadata: 11, 
//             }, item_7: Item {
//             id: 7, xp: 0, metadata: 0, 
//             }, item_8: Item {
//             id: 8, xp: 0, metadata: 12, 
//             }, item_9: Item {
//             id: 9, xp: 0, metadata: 0, 
//             }, item_10: Item {
//             id: 10, xp: 0, metadata: 0, 
//             }, item_11: Item {
//             id: 11, xp: 0, metadata: 18, 
//             }, item_12: Item {
//             id: 12, xp: 0, metadata: 0, 
//         },
//     };

//     let new_item = Item { id: 1, xp: 1, metadata: 0 };

//     let item = ItemMetaActions::get_item_metadata_slot(adventurer, bag, new_item);

//     assert(item.metadata == 19, 'Item metadata should be 5');
// }

// #[test]
// #[available_gas(5000000)]
// fn test_set_item_metadata_slot() {
//     let mut item_meta_storage = ItemMetaStorage {
//         item_1: ItemMeta {
//             id: 0, name_prefix: 0, name_suffix: 0, item_suffix: 0, 
//             }, item_2: ItemMeta {
//             id: 0, name_prefix: 0, name_suffix: 0, item_suffix: 0, 
//             }, item_3: ItemMeta {
//             id: 0, name_prefix: 0, name_suffix: 0, item_suffix: 0, 
//             }, item_4: ItemMeta {
//             id: 0, name_prefix: 0, name_suffix: 0, item_suffix: 0, 
//             }, item_5: ItemMeta {
//             id: 0, name_prefix: 0, name_suffix: 0, item_suffix: 0, 
//             }, item_6: ItemMeta {
//             id: 0, name_prefix: 0, name_suffix: 0, item_suffix: 0, 
//             }, item_7: ItemMeta {
//             id: 0, name_prefix: 0, name_suffix: 0, item_suffix: 0, 
//             }, item_8: ItemMeta {
//             id: 0, name_prefix: 0, name_suffix: 0, item_suffix: 0, 
//             }, item_9: ItemMeta {
//             id: 0, name_prefix: 0, name_suffix: 0, item_suffix: 0, 
//             }, item_10: ItemMeta {
//             id: 0, name_prefix: 0, name_suffix: 0, item_suffix: 0, 
//         }
//     };
//     let item = Item { id: 1, xp: 1, metadata: 1 };

//     let item_meta = ItemMeta { id: 1, name_prefix: 12, name_suffix: 11, item_suffix: 13 };

//     item_meta_storage.set_item_metadata(item, item_meta);
//     assert(item_meta_storage.item_1.name_prefix == 12, 'Item id should be 1');
//     assert(item_meta_storage.item_1.name_suffix == 11, 'Item id should be 1');
//     assert(item_meta_storage.item_1.item_suffix == 13, 'Item id should be 1');
// }

