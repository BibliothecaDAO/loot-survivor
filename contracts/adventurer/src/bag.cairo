use traits::{TryInto, Into};
use option::OptionTrait;

use pack::pack::{Packing, rshift_split};
use pack::constants::pow;

use super::adventurer::{Adventurer, ImplAdventurer, IAdventurer};

#[derive(Drop, Copy, Serde)] // 21 bits
struct LootStatistics {
    id: u8, // 7 bits
    xp: u16, // 9 bits
    // this is set as the items are found/purchased
    metadata: u8, // 5 bits
}

#[derive(Drop, Copy, Serde)]
struct Bag {
    item_1: LootStatistics, // club
    item_2: LootStatistics, // club
    item_3: LootStatistics, // club
    item_4: LootStatistics, // club
    item_5: LootStatistics, // club
    item_6: LootStatistics, // club
    item_7: LootStatistics, // club
    item_8: LootStatistics, // club
    item_9: LootStatistics, // club
    item_10: LootStatistics, // club
    item_11: LootStatistics, // club
    item_12: LootStatistics, // club
}

trait BagActions {
    // swap item
    // take bag and item to swap and item to equip
    // return bag with swapped items and item that was swapped for
    // we then store the item on the Adventurer
    // fn swap_items(self: Bag, incoming: u8, outgoing: u8) -> (Bag, LootStatistics);

    // set item in first available slot
    fn add_item(ref self: Bag, item: LootStatistics) -> Bag;

    // // finds open slot
    fn find_slot(self: Bag) -> u8;

    // check if bag full
    fn is_full(self: Bag) -> bool;
    // get item by id
    fn get_item(self: Bag, item_id: u8) -> LootStatistics;
    fn remove_item(ref self: Bag, item_id: u8) -> Bag;

    // creates new item
    fn new_item(item_id: u8) -> LootStatistics;
}

impl LootStatisticsPacking of Packing<LootStatistics> {
    fn pack(self: LootStatistics) -> felt252 {
        (self.id.into()
         + self.xp.into() * pow::TWO_POW_7
         + self.metadata.into() * pow::TWO_POW_16
        ).try_into().unwrap()
    }

    fn unpack(packed: felt252) -> LootStatistics {
        let packed = packed.into();
        let (packed, id) = rshift_split(packed, pow::TWO_POW_7);
        let (packed, xp) = rshift_split(packed, pow::TWO_POW_9);
        let (_, metadata) = rshift_split(packed, pow::TWO_POW_5);

        LootStatistics {
            id: id.try_into().unwrap(),
            xp: xp.try_into().unwrap(),
            metadata: metadata.try_into().unwrap()
        }
    }
}

impl BagPacking of Packing<Bag> {
    fn pack(self: Bag) -> felt252 {
        (self.item_1.pack().into()
         + self.item_2.pack().into() * pow::TWO_POW_21
         + self.item_3.pack().into() * pow::TWO_POW_42
         + self.item_4.pack().into() * pow::TWO_POW_63
         + self.item_5.pack().into() * pow::TWO_POW_84
         + self.item_6.pack().into() * pow::TWO_POW_105
         + self.item_7.pack().into() * pow::TWO_POW_126
         + self.item_8.pack().into() * pow::TWO_POW_147
         + self.item_9.pack().into() * pow::TWO_POW_168
         + self.item_10.pack().into() * pow::TWO_POW_189
         + self.item_11.pack().into() * pow::TWO_POW_210
         + self.item_12.pack().into() * pow::TWO_POW_231
        ).try_into().unwrap()
    }

    fn unpack(packed: felt252) -> Bag {
        let packed = packed.into();
        let (packed, item_1) = rshift_split(packed, pow::TWO_POW_21);
        let (packed, item_2) = rshift_split(packed, pow::TWO_POW_21);
        let (packed, item_3) = rshift_split(packed, pow::TWO_POW_21);
        let (packed, item_4) = rshift_split(packed, pow::TWO_POW_21);
        let (packed, item_5) = rshift_split(packed, pow::TWO_POW_21);
        let (packed, item_6) = rshift_split(packed, pow::TWO_POW_21);
        let (packed, item_7) = rshift_split(packed, pow::TWO_POW_21);
        let (packed, item_8) = rshift_split(packed, pow::TWO_POW_21);
        let (packed, item_9) = rshift_split(packed, pow::TWO_POW_21);
        let (packed, item_10) = rshift_split(packed, pow::TWO_POW_21);
        let (packed, item_11) = rshift_split(packed, pow::TWO_POW_21);
        let (_, item_12) = rshift_split(packed, pow::TWO_POW_21);

        Bag {
            item_1: Packing::unpack(item_1.try_into().unwrap()),
            item_2: Packing::unpack(item_2.try_into().unwrap()),
            item_3: Packing::unpack(item_3.try_into().unwrap()),
            item_4: Packing::unpack(item_4.try_into().unwrap()),
            item_5: Packing::unpack(item_5.try_into().unwrap()),
            item_6: Packing::unpack(item_6.try_into().unwrap()),
            item_7: Packing::unpack(item_7.try_into().unwrap()),
            item_8: Packing::unpack(item_8.try_into().unwrap()),
            item_9: Packing::unpack(item_9.try_into().unwrap()),
            item_10: Packing::unpack(item_10.try_into().unwrap()),
            item_11: Packing::unpack(item_11.try_into().unwrap()),
            item_12: Packing::unpack(item_12.try_into().unwrap())
        }
    }
}
impl ImplBagActions of BagActions {
    fn add_item(ref self: Bag, item: LootStatistics) -> Bag {
        assert(self.is_full() == false, 'Bag is full');

        let slot = self.find_slot();

        if slot == 0 {
            self.item_1 = item;
            return self;
        } else if slot == 1 {
            self.item_2 = item;
            return self;
        } else if slot == 2 {
            self.item_3 = item;
            return self;
        } else if slot == 3 {
            self.item_4 = item;
            return self;
        } else if slot == 4 {
            self.item_5 = item;
            return self;
        } else if slot == 5 {
            self.item_6 = item;
            return self;
        } else if slot == 6 {
            self.item_7 = item;
            return self;
        } else if slot == 7 {
            self.item_8 = item;
            return self;
        } else if slot == 8 {
            self.item_9 = item;
            return self;
        } else if slot == 9 {
            self.item_10 = item;
            return self;
        } else if slot == 10 {
            self.item_11 = item;
            return self;
        } else if slot == 11 {
            self.item_12 = item;
            return self;
        } else {
            return self;
        }
    }
    fn find_slot(self: Bag) -> u8 {
        if self.item_1.id == 0 {
            return 0;
        } else if self.item_2.id == 0 {
            return 1;
        } else if self.item_3.id == 0 {
            return 2;
        } else if self.item_4.id == 0 {
            return 3;
        } else if self.item_5.id == 0 {
            return 4;
        } else if self.item_6.id == 0 {
            return 5;
        } else if self.item_7.id == 0 {
            return 6;
        } else if self.item_8.id == 0 {
            return 7;
        } else if self.item_9.id == 0 {
            return 8;
        } else if self.item_10.id == 0 {
            return 9;
        } else if self.item_11.id == 0 {
            return 10;
        } else {
            return 11;
        }
    }
    fn is_full(self: Bag) -> bool {
        if self.item_12.id == 0 {
            return false;
        } else {
            return true;
        }
    }
    fn get_item(self: Bag, item_id: u8) -> LootStatistics {
        if self.item_1.id == item_id {
            return self.item_1;
        } else if self.item_2.id == item_id {
            return self.item_2;
        } else if self.item_3.id == item_id {
            return self.item_3;
        } else if self.item_4.id == item_id {
            return self.item_4;
        } else if self.item_5.id == item_id {
            return self.item_5;
        } else if self.item_6.id == item_id {
            return self.item_6;
        } else if self.item_7.id == item_id {
            return self.item_7;
        } else if self.item_8.id == item_id {
            return self.item_8;
        } else if self.item_9.id == item_id {
            return self.item_9;
        } else if self.item_10.id == item_id {
            return self.item_10;
        } else if self.item_11.id == item_id {
            return self.item_11;
        } else {
            return self.item_12;
        }
    }
    fn remove_item(ref self: Bag, item_id: u8) -> Bag {
        // this doesn't check if item is in the bag... It just removes by id...
        if self.item_1.id == item_id {
            self.item_1 = LootStatistics { id: 0, xp: 0, metadata: 0 };
            return self;
        } else if self.item_2.id == item_id {
            self.item_2 = LootStatistics { id: 0, xp: 0, metadata: 0 };
            return self;
        } else if self.item_3.id == item_id {
            self.item_3 = LootStatistics { id: 0, xp: 0, metadata: 0 };
            return self;
        } else if self.item_4.id == item_id {
            self.item_4 = LootStatistics { id: 0, xp: 0, metadata: 0 };
            return self;
        } else if self.item_5.id == item_id {
            self.item_5 = LootStatistics { id: 0, xp: 0, metadata: 0 };
            return self;
        } else if self.item_6.id == item_id {
            self.item_6 = LootStatistics { id: 0, xp: 0, metadata: 0 };
            return self;
        } else if self.item_7.id == item_id {
            self.item_7 = LootStatistics { id: 0, xp: 0, metadata: 0 };
            return self;
        } else if self.item_8.id == item_id {
            self.item_8 = LootStatistics { id: 0, xp: 0, metadata: 0 };
            return self;
        } else if self.item_9.id == item_id {
            self.item_9 = LootStatistics { id: 0, xp: 0, metadata: 0 };
            return self;
        } else if self.item_10.id == item_id {
            self.item_10 = LootStatistics { id: 0, xp: 0, metadata: 0 };
            return self;
        } else if self.item_11.id == item_id {
            self.item_11 = LootStatistics { id: 0, xp: 0, metadata: 0 };
            return self;
        } else {
            self.item_12 = LootStatistics { id: 0, xp: 0, metadata: 0 };
            return self;
        }
    }
    fn new_item(item_id: u8) -> LootStatistics {
        LootStatistics { id: item_id, xp: 0, metadata: 0 }
    }
}
#[test]
#[available_gas(5000000)]
fn test_pack_bag() {
    let mut bag = Bag {
        item_1: LootStatistics {
            id: 127, xp: 511, metadata: 31
            }, item_2: LootStatistics {
            id: 127, xp: 511, metadata: 31
            }, item_3: LootStatistics {
            id: 127, xp: 511, metadata: 31
            }, item_4: LootStatistics {
            id: 127, xp: 511, metadata: 31
            }, item_5: LootStatistics {
            id: 127, xp: 511, metadata: 31
            }, item_6: LootStatistics {
            id: 127, xp: 511, metadata: 31
            }, item_7: LootStatistics {
            id: 127, xp: 511, metadata: 31
            }, item_8: LootStatistics {
            id: 127, xp: 511, metadata: 31
            }, item_9: LootStatistics {
            id: 127, xp: 511, metadata: 31
            }, item_10: LootStatistics {
            id: 127, xp: 511, metadata: 31
            }, item_11: LootStatistics {
            id: 127, xp: 511, metadata: 31
            }, item_12: LootStatistics {
            id: 127, xp: 511, metadata: 31
        },
    };

    let packed_bag: Bag = Packing::unpack(bag.pack());

    assert(packed_bag.item_1.id == 127, 'Loot 1 ID is not 127');
    assert(packed_bag.item_1.xp == 511, 'Loot 1 XP is not 511');
    assert(packed_bag.item_1.metadata == 31, ' metadata is not 31');

    assert(packed_bag.item_2.id == 127, 'Loot 2 ID is not 127');
    assert(packed_bag.item_2.xp == 511, 'Loot 2 XP is not 511');
    assert(packed_bag.item_2.metadata == 31, ' 2 metadata is not 31');

    assert(packed_bag.item_3.id == 127, 'Loot 3 ID is not 127');
    assert(packed_bag.item_3.xp == 511, 'Loot 3 XP is not 511');
    assert(packed_bag.item_3.metadata == 31, ' 3 metadata is not 31');

    assert(packed_bag.item_4.id == 127, 'Loot 4 ID is not 127');
    assert(packed_bag.item_4.xp == 511, 'Loot 4 XP is not 511');
    assert(packed_bag.item_4.metadata == 31, ' 4 metadata is not 31');

    assert(packed_bag.item_5.id == 127, 'Loot 5 ID is not 127');
    assert(packed_bag.item_5.xp == 511, 'Loot 5 XP is not 511');
    assert(packed_bag.item_5.metadata == 31, ' 5 metadata is not 31');

    assert(packed_bag.item_6.id == 127, 'Loot 6 ID is not 127');
    assert(packed_bag.item_6.xp == 511, 'Loot 6 XP is not 511');
    assert(packed_bag.item_6.metadata == 31, ' 6 metadata is not 31');

    assert(packed_bag.item_7.id == 127, 'Loot 7 ID is not 127');
    assert(packed_bag.item_7.xp == 511, 'Loot 7 XP is not 511');
    assert(packed_bag.item_7.metadata == 31, ' 7 metadata is not 31');

    assert(packed_bag.item_8.id == 127, 'Loot 8 ID is not 127');
    assert(packed_bag.item_8.xp == 511, 'Loot 8 XP is not 511');
    assert(packed_bag.item_8.metadata == 31, ' 8 metadata is not 31');

    assert(packed_bag.item_9.id == 127, 'Loot 9 ID is not 127');
    assert(packed_bag.item_9.xp == 511, 'Loot 9 XP is not 511');
    assert(packed_bag.item_9.metadata == 31, ' 9 metadata is not 31');

    assert(packed_bag.item_10.id == 127, 'Loot 10 ID is not 127');
    assert(packed_bag.item_10.xp == 511, 'Loot 10 XP is not 511');
    assert(packed_bag.item_10.metadata == 31, ' 10 metadata is not 31');

    assert(packed_bag.item_11.id == 127, 'Loot 11 ID is not 127');
    assert(packed_bag.item_11.xp == 511, 'Loot 11 XP is not 511');
    assert(packed_bag.item_11.metadata == 31, ' 11 metadata is not 31');

    assert(packed_bag.item_12.id == 127, 'Loot 12 ID is not 127');
    assert(packed_bag.item_12.xp == 511, 'Loot 12 XP is not 511');
    assert(packed_bag.item_12.metadata == 31, ' 12 metadata is not 31');
}

#[test]
#[available_gas(5000000)]
fn test_add_item() {
    let mut bag = Bag {
        item_1: LootStatistics {
            id: 1, xp: 0, metadata: 0
            }, item_2: LootStatistics {
            id: 2, xp: 0, metadata: 0
            }, item_3: LootStatistics {
            id: 3, xp: 0, metadata: 0
            }, item_4: LootStatistics {
            id: 4, xp: 0, metadata: 0
            }, item_5: LootStatistics {
            id: 5, xp: 0, metadata: 0
            }, item_6: LootStatistics {
            id: 0, xp: 0, metadata: 0
            }, item_7: LootStatistics {
            id: 0, xp: 0, metadata: 0
            }, item_8: LootStatistics {
            id: 0, xp: 0, metadata: 0
            }, item_9: LootStatistics {
            id: 0, xp: 0, metadata: 0
            }, item_10: LootStatistics {
            id: 0, xp: 0, metadata: 0
            }, item_11: LootStatistics {
            id: 0, xp: 0, metadata: 0
            }, item_12: LootStatistics {
            id: 0, xp: 0, metadata: 0
        },
    };

    let item = LootStatistics { id: 23, xp: 1, metadata: 5 };

    bag.add_item(item);

    assert(bag.item_6.id == 23, 'Loot id should be 23');
}

#[test]
#[available_gas(5000000)]
fn test_is_full() {
    let mut bag = Bag {
        item_1: LootStatistics {
            id: 1, xp: 0, metadata: 0
            }, item_2: LootStatistics {
            id: 2, xp: 0, metadata: 0
            }, item_3: LootStatistics {
            id: 3, xp: 0, metadata: 0
            }, item_4: LootStatistics {
            id: 4, xp: 0, metadata: 0
            }, item_5: LootStatistics {
            id: 5, xp: 0, metadata: 0
            }, item_6: LootStatistics {
            id: 8, xp: 0, metadata: 0
            }, item_7: LootStatistics {
            id: 9, xp: 0, metadata: 0
            }, item_8: LootStatistics {
            id: 11, xp: 0, metadata: 0
            }, item_9: LootStatistics {
            id: 12, xp: 0, metadata: 0
            }, item_10: LootStatistics {
            id: 13, xp: 0, metadata: 0
            }, item_11: LootStatistics {
            id: 14, xp: 0, metadata: 0
            }, item_12: LootStatistics {
            id: 15, xp: 0, metadata: 0
        },
    };

    assert(bag.is_full() == true, 'Bag should be full');
}
#[test]
#[available_gas(5000000)]
fn remove_item() {
    let mut bag = Bag {
        item_1: LootStatistics {
            id: 1, xp: 0, metadata: 0
            }, item_2: LootStatistics {
            id: 2, xp: 0, metadata: 0
            }, item_3: LootStatistics {
            id: 3, xp: 0, metadata: 0
            }, item_4: LootStatistics {
            id: 4, xp: 0, metadata: 0
            }, item_5: LootStatistics {
            id: 5, xp: 0, metadata: 0
            }, item_6: LootStatistics {
            id: 8, xp: 0, metadata: 0
            }, item_7: LootStatistics {
            id: 9, xp: 0, metadata: 0
            }, item_8: LootStatistics {
            id: 11, xp: 0, metadata: 0
            }, item_9: LootStatistics {
            id: 12, xp: 0, metadata: 0
            }, item_10: LootStatistics {
            id: 13, xp: 0, metadata: 0
            }, item_11: LootStatistics {
            id: 14, xp: 0, metadata: 0
            }, item_12: LootStatistics {
            id: 15, xp: 0, metadata: 0
        },
    };

    bag.remove_item(8);

    assert(bag.item_6.id == 0, 'Loot id should be 0');
}
