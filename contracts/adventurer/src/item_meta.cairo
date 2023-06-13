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

mod item_meta_index {
    const INDEX_1: u8 = 0;
    const INDEX_2: u8 = 1;
    const INDEX_3: u8 = 2;
    const INDEX_4: u8 = 3;
    const INDEX_5: u8 = 4;
    const INDEX_6: u8 = 5;
    const INDEX_7: u8 = 6;
    const INDEX_8: u8 = 7;
    const INDEX_9: u8 = 8;
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
        0
    }
    fn unpack(packed: felt252) -> ItemMetaStorage {
        ItemMetaStorage {
            item_1: ItemMeta {
                id: 0, name_prefix: 0, name_suffix: 0, item_suffix: 0, 
                }, item_2: ItemMeta {
                id: 0, name_prefix: 0, name_suffix: 0, item_suffix: 0, 
                }, item_3: ItemMeta {
                id: 0, name_prefix: 0, name_suffix: 0, item_suffix: 0, 
                }, item_4: ItemMeta {
                id: 0, name_prefix: 0, name_suffix: 0, item_suffix: 0, 
                }, item_5: ItemMeta {
                id: 0, name_prefix: 0, name_suffix: 0, item_suffix: 0, 
                }, item_6: ItemMeta {
                id: 0, name_prefix: 0, name_suffix: 0, item_suffix: 0, 
                }, item_7: ItemMeta {
                id: 0, name_prefix: 0, name_suffix: 0, item_suffix: 0, 
                }, item_8: ItemMeta {
                id: 0, name_prefix: 0, name_suffix: 0, item_suffix: 0, 
                }, item_9: ItemMeta {
                id: 0, name_prefix: 0, name_suffix: 0, item_suffix: 0, 
                }, item_10: ItemMeta {
                id: 0, name_prefix: 0, name_suffix: 0, item_suffix: 0, 
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
        if slot == 0 {
            Item { id: item.id, xp: item.xp, metadata: 0 }
        } else {
            Item { id: item.id, xp: item.xp, metadata: slot + 1 }
        }
    }
    fn set_item_metadata(
        ref self: ItemMetaStorage, item: Item, item_meta: ItemMeta
    ) -> ItemMetaStorage {
        // TODO:
        // @loothere: should we generate the prefix here or up in the contract?
        if item.metadata == item_meta_index::INDEX_1 {
            self.item_1 = item_meta;
            return self;
        } else if item.metadata == item_meta_index::INDEX_2 {
            self.item_2 = item_meta;
            return self;
        } else if item.metadata == item_meta_index::INDEX_3 {
            self.item_3 = item_meta;
            return self;
        } else if item.metadata == item_meta_index::INDEX_4 {
            self.item_4 = item_meta;
            return self;
        } else if item.metadata == item_meta_index::INDEX_5 {
            self.item_5 = item_meta;
            return self;
        } else if item.metadata == item_meta_index::INDEX_6 {
            self.item_6 = item_meta;
            return self;
        } else if item.metadata == item_meta_index::INDEX_7 {
            self.item_7 = item_meta;
            return self;
        } else if item.metadata == item_meta_index::INDEX_8 {
            self.item_8 = item_meta;
            return self;
        } else if item.metadata == item_meta_index::INDEX_9 {
            self.item_9 = item_meta;
            return self;
        } else {
            self.item_10 = item_meta;
            return self;
        }
    }
}


#[test]
#[available_gas(5000000)]
fn test_get_item_metadata_slot() {
    let mut adventurer = AdventurerActions::new(1, 1);

    // add test items
    let item_pendant = Item { id: 1, xp: 1, metadata: 0 };
    let item_silver_ring = Item { id: 4, xp: 1, metadata: 1 };
    let item_ghost_wand = Item { id: 9, xp: 1, metadata: 2 };
    let item_silk_robe = Item { id: 18, xp: 1, metadata: 3 };

    adventurer.add_item(item_pendant);
    adventurer.add_item(item_silver_ring);
    adventurer.add_item(item_ghost_wand);
    adventurer.add_item(item_silk_robe);

    let bag = Bag {
        item_1: Item {
            id: 1, xp: 0, metadata: 4, 
            }, item_2: Item {
            id: 2, xp: 0, metadata: 5, 
            }, item_3: Item {
            id: 3, xp: 0, metadata: 6, 
            }, item_4: Item {
            id: 4, xp: 0, metadata: 7, 
            }, item_5: Item {
            id: 5, xp: 0, metadata: 8, 
            }, item_6: Item {
            id: 6, xp: 0, metadata: 11, 
            }, item_7: Item {
            id: 7, xp: 0, metadata: 0, 
            }, item_8: Item {
            id: 8, xp: 0, metadata: 12, 
            }, item_9: Item {
            id: 9, xp: 0, metadata: 0, 
            }, item_10: Item {
            id: 10, xp: 0, metadata: 0, 
            }, item_11: Item {
            id: 11, xp: 0, metadata: 18, 
            }, item_12: Item {
            id: 12, xp: 0, metadata: 0, 
        },
    };

    let new_item = Item { id: 1, xp: 1, metadata: 0 };

    let item = ItemMetaActions::get_item_metadata_slot(adventurer, bag, new_item);

    assert(item.metadata == 19, 'Item metadata should be 5');
}

#[test]
#[available_gas(5000000)]
fn test_set_item_metadata_slot() {
    let mut item_meta_storage = ItemMetaStorage {
        item_1: ItemMeta {
            id: 0, name_prefix: 0, name_suffix: 0, item_suffix: 0, 
            }, item_2: ItemMeta {
            id: 0, name_prefix: 0, name_suffix: 0, item_suffix: 0, 
            }, item_3: ItemMeta {
            id: 0, name_prefix: 0, name_suffix: 0, item_suffix: 0, 
            }, item_4: ItemMeta {
            id: 0, name_prefix: 0, name_suffix: 0, item_suffix: 0, 
            }, item_5: ItemMeta {
            id: 0, name_prefix: 0, name_suffix: 0, item_suffix: 0, 
            }, item_6: ItemMeta {
            id: 0, name_prefix: 0, name_suffix: 0, item_suffix: 0, 
            }, item_7: ItemMeta {
            id: 0, name_prefix: 0, name_suffix: 0, item_suffix: 0, 
            }, item_8: ItemMeta {
            id: 0, name_prefix: 0, name_suffix: 0, item_suffix: 0, 
            }, item_9: ItemMeta {
            id: 0, name_prefix: 0, name_suffix: 0, item_suffix: 0, 
            }, item_10: ItemMeta {
            id: 0, name_prefix: 0, name_suffix: 0, item_suffix: 0, 
        }
    };
    let item = Item { id: 1, xp: 1, metadata: 0 };

    let item_meta = ItemMeta { id: 1, name_prefix: 12, name_suffix: 11, item_suffix: 13 };

    item_meta_storage.set_item_metadata(item, item_meta);

    assert(item_meta_storage.item_1.name_prefix == 12, 'Item id should be 1');
    assert(item_meta_storage.item_1.name_suffix == 11, 'Item id should be 1');
    assert(item_meta_storage.item_1.item_suffix == 13, 'Item id should be 1');
}
