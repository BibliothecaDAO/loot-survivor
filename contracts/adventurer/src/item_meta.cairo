use core::serde::Serde;
use traits::{TryInto, Into};
use option::OptionTrait;
use integer::{U256TryIntoU32, U256TryIntoU16, U256TryIntoU8};
use pack::pack::{Packing, rshift_split};
use pack::constants::pow;
use lootitems::statistics::constants::ItemId;

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
struct ItemSpecials {
    special1: u8, // 4 bit
    special2: u8, // 7 bits
    special3: u8, // 5 bits
}

// Player can have a total of 20 items. We map the items index to a slot in the metadata
#[derive(Drop, Copy, Serde)]
struct ItemSpecialsStorage {
    item_1: ItemSpecials,
    item_2: ItemSpecials,
    item_3: ItemSpecials,
    item_4: ItemSpecials,
    item_5: ItemSpecials,
    item_6: ItemSpecials,
    item_7: ItemSpecials,
    item_8: ItemSpecials,
    item_9: ItemSpecials,
    item_10: ItemSpecials,
}

impl ItemSpecialsPacking of Packing<ItemSpecials> {
    fn pack(self: ItemSpecials) -> felt252 {
        (self.special2.into()
            + self.special3.into() * pow::TWO_POW_7
            + self.special1.into() * pow::TWO_POW_12)
            .try_into()
            .expect('pack ItemSpecials')
    }

    fn unpack(packed: felt252) -> ItemSpecials {
        let packed = packed.into();
        let (packed, special2) = rshift_split(packed, pow::TWO_POW_7);
        let (packed, special3) = rshift_split(packed, pow::TWO_POW_5);
        let (_, special1) = rshift_split(packed, pow::TWO_POW_4);

        ItemSpecials {
            special2: special2.try_into().expect('unpack LISN special2'),
            special3: special3.try_into().expect('unpack LISN special3'),
            special1: special1.try_into().expect('unpack LISN special1')
        }
    }
    // TODO: add overflow pack protection
    fn overflow_pack_protection(self: ItemSpecials) -> ItemSpecials {
        self
    }
}

impl ItemSpecialsStoragePacking of Packing<ItemSpecialsStorage> {
    fn pack(self: ItemSpecialsStorage) -> felt252 {
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

    fn unpack(packed: felt252) -> ItemSpecialsStorage {
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

        ItemSpecialsStorage {
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

    // TODO: add overflow pack protection
    fn overflow_pack_protection(self: ItemSpecialsStorage) -> ItemSpecialsStorage {
        self
    }
}

#[generate_trait]
impl ImplItemSpecials of IItemSpecials {
    fn get_loot_special_names(
        self: ItemSpecialsStorage, loot_statistics: ItemPrimitive
    ) -> ItemSpecials {
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

    fn get_special_name_storage_slot(
        adventurer: Adventurer, bag: Bag, loot_statistics: ItemPrimitive
    ) -> ItemPrimitive {
        // check slots

        // slot 1 is always taken by the adventurer on start
        let mut slot = 1;

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

        ItemPrimitive { id: loot_statistics.id, xp: loot_statistics.xp, metadata: slot + 1 }
    }
    fn set_loot_special_names(
        ref self: ItemSpecialsStorage,
        loot_statistics: ItemPrimitive,
        loot_special_names: ItemSpecials
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
    let storage = ItemSpecialsStorage {
        item_1: ItemSpecials {
            special2: 11, special3: 1, special1: 15, 
            }, item_2: ItemSpecials {
            special2: 22, special3: 2, special1: 14, 
            }, item_3: ItemSpecials {
            special2: 33, special3: 3, special1: 13, 
            }, item_4: ItemSpecials {
            special2: 44, special3: 4, special1: 12, 
            }, item_5: ItemSpecials {
            special2: 55, special3: 5, special1: 11, 
            }, item_6: ItemSpecials {
            special2: 66, special3: 6, special1: 10, 
            }, item_7: ItemSpecials {
            special2: 77, special3: 7, special1: 9, 
            }, item_8: ItemSpecials {
            special2: 88, special3: 8, special1: 8, 
            }, item_9: ItemSpecials {
            special2: 99, special3: 9, special1: 7, 
            }, item_10: ItemSpecials {
            special2: 111, special3: 10, special1: 6, 
        }
    };

    let unpacked: ItemSpecialsStorage = Packing::unpack(storage.pack());

    assert(unpacked.item_1.special2 == storage.item_1.special2, 'item_1 special2');
    assert(unpacked.item_1.special3 == storage.item_1.special3, 'item_1 special3');
    assert(unpacked.item_1.special1 == storage.item_1.special1, 'item_1 special1');

    assert(unpacked.item_2.special2 == storage.item_2.special2, 'item_2 special2');
    assert(unpacked.item_2.special3 == storage.item_2.special3, 'item_2 special3');
    assert(unpacked.item_2.special1 == storage.item_2.special1, 'item_2 special1');

    assert(unpacked.item_3.special2 == storage.item_3.special2, 'item_3 special2');
    assert(unpacked.item_3.special3 == storage.item_3.special3, 'item_3 special3');
    assert(unpacked.item_3.special1 == storage.item_3.special1, 'item_3 special1');

    assert(unpacked.item_4.special2 == storage.item_4.special2, 'item_4 special2');
    assert(unpacked.item_4.special3 == storage.item_4.special3, 'item_4 special3');
    assert(unpacked.item_4.special1 == storage.item_4.special1, 'item_4 special1');

    assert(unpacked.item_5.special2 == storage.item_5.special2, 'item_5 special2');
    assert(unpacked.item_5.special3 == storage.item_5.special3, 'item_5 special3');
    assert(unpacked.item_5.special1 == storage.item_5.special1, 'item_5 special1');

    assert(unpacked.item_6.special2 == storage.item_6.special2, 'item_6 special2');
    assert(unpacked.item_6.special3 == storage.item_6.special3, 'item_6 special3');
    assert(unpacked.item_6.special1 == storage.item_6.special1, 'item_6 special1');

    assert(unpacked.item_7.special2 == storage.item_7.special2, 'item_7 special2');
    assert(unpacked.item_7.special3 == storage.item_7.special3, 'item_7 special3');
    assert(unpacked.item_7.special1 == storage.item_7.special1, 'item_7 special1');

    assert(unpacked.item_8.special2 == storage.item_8.special2, 'item_8 special2');
    assert(unpacked.item_8.special3 == storage.item_8.special3, 'item_8 special3');
    assert(unpacked.item_8.special1 == storage.item_8.special1, 'item_8 special1');

    assert(unpacked.item_9.special2 == storage.item_9.special2, 'item_9 special2');
    assert(unpacked.item_9.special3 == storage.item_9.special3, 'item_9 special3');
    assert(unpacked.item_9.special1 == storage.item_9.special1, 'item_9 special1');

    assert(unpacked.item_10.special2 == storage.item_10.special2, 'item_10 special2');
    assert(unpacked.item_10.special3 == storage.item_10.special3, 'item_10 special3');
    assert(unpacked.item_10.special1 == storage.item_10.special1, 'item_10 special1');
}

#[test]
#[available_gas(50000000)]
fn test_get_item_metadata_slot() {
    let mut adventurer = ImplAdventurer::new(1, 1);
    let bag = Bag {
        item_1: ItemPrimitive {
            id: 1, xp: 0, metadata: 0, 
            }, item_2: ItemPrimitive {
            id: 2, xp: 0, metadata: 0, 
            }, item_3: ItemPrimitive {
            id: 3, xp: 0, metadata: 0, 
            }, item_4: ItemPrimitive {
            id: 4, xp: 0, metadata: 0, 
            }, item_5: ItemPrimitive {
            id: 5, xp: 0, metadata: 0, 
            }, item_6: ItemPrimitive {
            id: 6, xp: 0, metadata: 0, 
            }, item_7: ItemPrimitive {
            id: 7, xp: 0, metadata: 0, 
            }, item_8: ItemPrimitive {
            id: 8, xp: 0, metadata: 0, 
            }, item_9: ItemPrimitive {
            id: 9, xp: 0, metadata: 0, 
            }, item_10: ItemPrimitive {
            id: 10, xp: 0, metadata: 0, 
            }, item_11: ItemPrimitive {
            id: 11, xp: 0, metadata: 0, 
        },
    };

    let mut pendant = ItemPrimitive { id: ItemId::Pendant, xp: 1, metadata: 0 };
    let mut silver_ring = ItemPrimitive { id: ItemId::SilverRing, xp: 1, metadata: 0 };
    let mut ghost_wand = ItemPrimitive { id: ItemId::GhostWand, xp: 1, metadata: 0 };
    let mut silk_robe = ItemPrimitive { id: ItemId::SilkRobe, xp: 1, metadata: 0 };
    let mut katana = ItemPrimitive { id: ItemId::Katana, xp: 1, metadata: 0 };
    let mut falchion = ItemPrimitive { id: ItemId::Falchion, xp: 1, metadata: 0 };
    let mut want = ItemPrimitive { id: ItemId::Wand, xp: 1, metadata: 0 };
    let mut bond = ItemPrimitive { id: ItemId::BoneWand, xp: 1, metadata: 0 };
    let mut ghost = ItemPrimitive { id: ItemId::GhostWand, xp: 1, metadata: 0 };
    let mut book = ItemPrimitive { id: ItemId::Book, xp: 1, metadata: 0 };


    let item = IItemSpecials::get_special_name_storage_slot(adventurer, bag, pendant);

    adventurer.add_item(item);
    assert(item.metadata == 2, 'ItemPrimitive');

    let item_2 = IItemSpecials::get_special_name_storage_slot(adventurer, bag, silver_ring);

    adventurer.add_item(item_2);
    assert(item_2.metadata == 3, 'ItemPrimitive');

    let item_3 = IItemSpecials::get_special_name_storage_slot(adventurer, bag, ghost_wand);

    adventurer.add_item(item_3);
    assert(item_3.metadata == 4, 'ItemPrimitive');

    let item_4 = IItemSpecials::get_special_name_storage_slot(adventurer, bag, silk_robe);

    adventurer.add_item(item_4);
    assert(item_4.metadata == 5, 'ItemPrimitive');

    let item_5 = IItemSpecials::get_special_name_storage_slot(adventurer, bag, katana);

    adventurer.add_item(item_5);
    assert(item_5.metadata == 6, 'ItemPrimitive');

    let item_6 = IItemSpecials::get_special_name_storage_slot(adventurer, bag, falchion);

    adventurer.add_item(item_6);
    assert(item_6.metadata == 7, 'ItemPrimitive');

    let item_7 = IItemSpecials::get_special_name_storage_slot(adventurer, bag, want);

    adventurer.add_item(item_7);
    assert(item_7.metadata == 8, 'ItemPrimitive');

    let item_8 = IItemSpecials::get_special_name_storage_slot(adventurer, bag, bond);

    adventurer.add_item(item_8);
    assert(item_8.metadata == 9, 'ItemPrimitive');

    let item_9 = IItemSpecials::get_special_name_storage_slot(adventurer, bag, ghost);

    adventurer.add_item(item_9);
    assert(item_9.metadata == 10, 'ItemPrimitive');

    let item_10 = IItemSpecials::get_special_name_storage_slot(adventurer, bag, book);

    adventurer.add_item(item_10);
    assert(item_10.metadata == 11, 'ItemPrimitive');

    let bag = Bag {
        item_1: ItemPrimitive {
            id: 1, xp: 0, metadata: 12, 
            }, item_2: ItemPrimitive {
            id: 2, xp: 0, metadata: 0, 
            }, item_3: ItemPrimitive {
            id: 3, xp: 0, metadata: 0, 
            }, item_4: ItemPrimitive {
            id: 4, xp: 0, metadata: 0, 
            }, item_5: ItemPrimitive {
            id: 5, xp: 0, metadata: 0, 
            }, item_6: ItemPrimitive {
            id: 6, xp: 0, metadata: 0, 
            }, item_7: ItemPrimitive {
            id: 7, xp: 0, metadata: 0, 
            }, item_8: ItemPrimitive {
            id: 8, xp: 0, metadata: 0, 
            }, item_9: ItemPrimitive {
            id: 9, xp: 0, metadata: 0, 
            }, item_10: ItemPrimitive {
            id: 10, xp: 0, metadata: 0, 
            }, item_11: ItemPrimitive {
            id: 11, xp: 0, metadata: 0, 
        },
    };

    let item_10 = IItemSpecials::get_special_name_storage_slot(adventurer, bag, book);

    adventurer.add_item(item_10);
    assert(item_10.metadata == 13, 'ItemPrimitive');

    let bag = Bag {
        item_1: ItemPrimitive {
            id: 1, xp: 0, metadata: 12, 
            }, item_2: ItemPrimitive {
            id: 2, xp: 0, metadata: 0, 
            }, item_3: ItemPrimitive {
            id: 3, xp: 0, metadata: 0, 
            }, item_4: ItemPrimitive {
            id: 4, xp: 0, metadata: 0, 
            }, item_5: ItemPrimitive {
            id: 5, xp: 0, metadata: 0, 
            }, item_6: ItemPrimitive {
            id: 6, xp: 0, metadata: 0, 
            }, item_7: ItemPrimitive {
            id: 7, xp: 0, metadata: 0, 
            }, item_8: ItemPrimitive {
            id: 8, xp: 0, metadata: 0, 
            }, item_9: ItemPrimitive {
            id: 9, xp: 0, metadata: 0, 
            }, item_10: ItemPrimitive {
            id: 10, xp: 0, metadata: 0, 
            }, item_11: ItemPrimitive {
            id: 11, xp: 0, metadata: 18, 
        },
    };

    let item_10 = IItemSpecials::get_special_name_storage_slot(adventurer, bag, book);

    adventurer.add_item(item_10);
    assert(item_10.metadata == 19, 'ItemPrimitive');
    
}

#[test]
#[available_gas(5000000)]
fn test_set_item_metadata_slot() {
    let mut item_meta_storage = ItemSpecialsStorage {
        item_1: ItemSpecials {
            special2: 0, special3: 0, special1: 0, 
            }, item_2: ItemSpecials {
            special2: 0, special3: 0, special1: 0, 
            }, item_3: ItemSpecials {
            special2: 0, special3: 0, special1: 0, 
            }, item_4: ItemSpecials {
            special2: 0, special3: 0, special1: 0, 
            }, item_5: ItemSpecials {
            special2: 0, special3: 0, special1: 0, 
            }, item_6: ItemSpecials {
            special2: 0, special3: 0, special1: 0, 
            }, item_7: ItemSpecials {
            special2: 0, special3: 0, special1: 0, 
            }, item_8: ItemSpecials {
            special2: 0, special3: 0, special1: 0, 
            }, item_9: ItemSpecials {
            special2: 0, special3: 0, special1: 0, 
            }, item_10: ItemSpecials {
            special2: 0, special3: 0, special1: 0, 
        }
    };

    let loot_statistics_1 = ItemPrimitive { id: 102, xp: 0, metadata: 1 };

    let loot_special_names_2 = ItemSpecials { special2: 12, special3: 11, special1: 13 };

    item_meta_storage.set_loot_special_names(loot_statistics_1, loot_special_names_2);

    assert(item_meta_storage.item_1.special2 == 12, 'should be 12');
    assert(item_meta_storage.item_1.special3 == 11, 'should be 11');
    assert(item_meta_storage.item_1.special1 == 13, 'should be 13');

    let loot_statistics_2 = ItemPrimitive { id: 102, xp: 0, metadata: 2 };

    let loot_special_names_2 = ItemSpecials { special2: 12, special3: 11, special1: 13 };

    item_meta_storage.set_loot_special_names(loot_statistics_2, loot_special_names_2);
    assert(item_meta_storage.item_2.special2 == 12, 'should be 12');
    assert(item_meta_storage.item_2.special3 == 11, 'should be 11');
    assert(item_meta_storage.item_2.special1 == 13, 'should be 13');
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

    let mut item_meta_storage = ItemSpecialsStorage {
        item_1: ItemSpecials {
            special2: 2, special3: 2, special1: 10, 
            }, item_2: ItemSpecials {
            special2: 4, special3: 3, special1: 11, 
            }, item_3: ItemSpecials {
            special2: 5, special3: 4, special1: 11, 
            }, item_4: ItemSpecials {
            special2: 6, special3: 5, special1: 3, 
            }, item_5: ItemSpecials {
            special2: 8, special3: 6, special1: 2, 
            }, item_6: ItemSpecials {
            special2: 9, special3: 7, special1: 1, 
            }, item_7: ItemSpecials {
            special2: 11, special3: 8, special1: 5, 
            }, item_8: ItemSpecials {
            special2: 2, special3: 9, special1: 6, 
            }, item_9: ItemSpecials {
            special2: 3, special3: 0, special1: 7, 
            }, item_10: ItemSpecials {
            special2: 11, special3: 8, special1: 5, 
        }
    };

    let meta_data = item_meta_storage.get_loot_special_names(item_pendant);

    assert(meta_data.special2 == 2, 'item_pendant.special2');
    assert(meta_data.special3 == 2, 'item_pendant.special3');
    assert(meta_data.special1 == 10, 'item_pendant.special1');
    let meta_data = item_meta_storage.get_loot_special_names(item_silver_ring);

    assert(meta_data.special2 == 4, 'item_silver_ring.special2');
    assert(meta_data.special3 == 3, 'item_silver_ring.special3');
    assert(meta_data.special1 == 11, 'item_silver_ring.special1');

    let meta_data = item_meta_storage.get_loot_special_names(item_silk_robe);

    assert(meta_data.special2 == 5, 'item_silk_robe.special2');
    assert(meta_data.special3 == 4, 'item_silk_robe.special3');
    assert(meta_data.special1 == 11, 'item_silk_robe.special1');

    let meta_data = item_meta_storage.get_loot_special_names(item_iron_sword);

    assert(meta_data.special2 == 6, 'item_iron_sword.special2');
    assert(meta_data.special3 == 5, 'item_iron_sword.special3');
    assert(meta_data.special1 == 3, 'item_iron_sword.special1');

    let meta_data = item_meta_storage.get_loot_special_names(item_katana);

    assert(meta_data.special2 == 8, 'item_katana');
    assert(meta_data.special3 == 6, 'item_katana');
    assert(meta_data.special1 == 2, 'item_katana');

    let meta_data = item_meta_storage.get_loot_special_names(item_falchion);

    assert(meta_data.special2 == 9, 'item_falchion');
    assert(meta_data.special3 == 7, 'item_falchion');
    assert(meta_data.special1 == 1, 'item_falchion');

    let meta_data = item_meta_storage.get_loot_special_names(item_leather_gloves);

    assert(meta_data.special2 == 11, 'item_leather_gloves');
    assert(meta_data.special3 == 8, 'item_leather_gloves');
    assert(meta_data.special1 == 5, 'item_leather_gloves');

    let meta_data = item_meta_storage.get_loot_special_names(item_silk_gloves);

    assert(meta_data.special2 == 2, 'item_silk_gloves');
    assert(meta_data.special3 == 9, 'item_silk_gloves');
    assert(meta_data.special1 == 6, 'item_silk_gloves');

    let meta_data = item_meta_storage.get_loot_special_names(item_linen_gloves);

    assert(meta_data.special2 == 3, 'item_linen_gloves');
    assert(meta_data.special3 == 0, 'item_linen_gloves');
    assert(meta_data.special1 == 7, 'item_linen_gloves');

    let meta_data = item_meta_storage.get_loot_special_names(item_crown);

    assert(meta_data.special2 == 11, 'item_crown');
    assert(meta_data.special3 == 8, 'item_crown');
    assert(meta_data.special1 == 5, 'item_crown');
}
