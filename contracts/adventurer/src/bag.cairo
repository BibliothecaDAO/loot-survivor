use traits::{TryInto, Into};
use option::OptionTrait;
use pack::{pack::{Packing, rshift_split}, constants::pow};
use super::{
    adventurer::{Adventurer, ImplAdventurer, IAdventurer},
    item_primitive::{ItemPrimitive, ImplItemPrimitive}, item_meta::{ImplItemSpecials, IItemSpecials}
};
use lootitems::statistics::constants::ItemId;

// Bag is used for storing gear not equipped to the adventurer
// TODO: Change this to an Array<ItemPrimitive> with id: u8, size: u8, and modified: bool
// this will make the Bag more extensible and easier to work with in code
#[derive(Drop, Copy, Serde)]
struct Bag {
    item_1: ItemPrimitive,
    item_2: ItemPrimitive,
    item_3: ItemPrimitive,
    item_4: ItemPrimitive,
    item_5: ItemPrimitive,
    item_6: ItemPrimitive,
    item_7: ItemPrimitive,
    item_8: ItemPrimitive,
    item_9: ItemPrimitive,
    item_10: ItemPrimitive,
    item_11: ItemPrimitive,
    mutated: bool,
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
            + self.item_11.pack().into() * pow::TWO_POW_210)
            .try_into()
            .expect('pack Bag')
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
        let (_, item_11) = rshift_split(packed, pow::TWO_POW_21);

        Bag {
            item_1: Packing::unpack(item_1.try_into().expect('unpack Bag item_1')),
            item_2: Packing::unpack(item_2.try_into().expect('unpack Bag item_2')),
            item_3: Packing::unpack(item_3.try_into().expect('unpack Bag item_3')),
            item_4: Packing::unpack(item_4.try_into().expect('unpack Bag item_4')),
            item_5: Packing::unpack(item_5.try_into().expect('unpack Bag item_5')),
            item_6: Packing::unpack(item_6.try_into().expect('unpack Bag item_6')),
            item_7: Packing::unpack(item_7.try_into().expect('unpack Bag item_7')),
            item_8: Packing::unpack(item_8.try_into().expect('unpack Bag item_8')),
            item_9: Packing::unpack(item_9.try_into().expect('unpack Bag item_9')),
            item_10: Packing::unpack(item_10.try_into().expect('unpack Bag item_10')),
            item_11: Packing::unpack(item_11.try_into().expect('unpack Bag item_11')),
            mutated: false
        }
    }

    // TODO: add overflow pack protection
    fn overflow_pack_protection(self: Bag) -> Bag {
        self
    }
}

#[generate_trait]
impl ImplBag of IBag {
    // @notice Retrieves an item from the bag by its id
    // @dev If the item with the specified id is not in the bag, it throws an error
    // @param self The instance of the Bag
    // @param item_id The id of the item to be retrieved
    // @return The item from the bag with the specified id
    fn get_item(self: Bag, item_id: u8) -> ItemPrimitive {
        if self.item_1.id == item_id {
            self.item_1
        } else if self.item_2.id == item_id {
            self.item_2
        } else if self.item_3.id == item_id {
            self.item_3
        } else if self.item_4.id == item_id {
            self.item_4
        } else if self.item_5.id == item_id {
            self.item_5
        } else if self.item_6.id == item_id {
            self.item_6
        } else if self.item_7.id == item_id {
            self.item_7
        } else if self.item_8.id == item_id {
            self.item_8
        } else if self.item_9.id == item_id {
            self.item_9
        } else if self.item_10.id == item_id {
            self.item_10
        } else if self.item_11.id == item_id {
            self.item_11
        } else {
            panic_with_felt252('Item not in bag')
        }
    }

    // @notice Adds a new item to a given adventurer's bag.
    // @param self The reference to the Bag instance.
    // @param adventurer The adventurer instance representing the owner of the bag.
    // @param item_id The unique identifier for the item.
    // @dev This function constructs a new item with the given item_id, sets its metadata using the Adventurer and Bag reference, and adds the item to the bag.
    fn add_new_item(ref self: Bag, adventurer: Adventurer, item_id: u8) {
        let mut item = ImplItemPrimitive::new(item_id);
        item.set_metadata_id(adventurer, self);
        self.add_item(item);
    }

    // @notice Adds an item to the bag
    // @dev If the bag is full, it throws an error
    // @param self The instance of the Bag
    // @param item The item to be added to the bag
    fn add_item(ref self: Bag, item: ItemPrimitive) {
        // assert item id is not 0
        assert(item.id != 0, 'Item ID cannot be 0');

        // add item to next available slot
        if self.item_1.id == 0 {
            self.item_1 = item;
        } else if self.item_2.id == 0 {
            self.item_2 = item;
        } else if self.item_3.id == 0 {
            self.item_3 = item;
        } else if self.item_4.id == 0 {
            self.item_4 = item;
        } else if self.item_5.id == 0 {
            self.item_5 = item;
        } else if self.item_6.id == 0 {
            self.item_6 = item;
        } else if self.item_7.id == 0 {
            self.item_7 = item;
        } else if self.item_8.id == 0 {
            self.item_8 = item;
        } else if self.item_9.id == 0 {
            self.item_9 = item;
        } else if self.item_10.id == 0 {
            self.item_10 = item;
        } else if self.item_11.id == 0 {
            self.item_11 = item;
        } else {
            panic_with_felt252('Bag is full')
        }

        // flag bag as being mutated
        self.mutated = true;
    }

    // @notice Removes an item from the bag by its id
    // @dev To remove an item we set it's id and xp to zero
    // @dev We intentionally leave the previous metadata index in place
    // @dev If the provided item id does not exist in the bag, this function throws an error
    // @param self The instance of the Bag
    // @param item_id The id of the item to be removed
    // @return The item that was removed from the bag
    fn remove_item(ref self: Bag, item_id: u8) -> ItemPrimitive {
        let removed_item = self.get_item(item_id);

        if self.item_1.id == item_id {
            self.item_1.id = 0;
            self.item_1.xp = 0;
        } else if self.item_2.id == item_id {
            self.item_2.id = 0;
            self.item_2.xp = 0;
        } else if self.item_3.id == item_id {
            self.item_3.id = 0;
            self.item_3.xp = 0;
        } else if self.item_4.id == item_id {
            self.item_4.id = 0;
            self.item_4.xp = 0;
        } else if self.item_5.id == item_id {
            self.item_5.id = 0;
            self.item_5.xp = 0;
        } else if self.item_6.id == item_id {
            self.item_6.id = 0;
            self.item_6.xp = 0;
        } else if self.item_7.id == item_id {
            self.item_7.id = 0;
            self.item_7.xp = 0;
        } else if self.item_8.id == item_id {
            self.item_8.id = 0;
            self.item_8.xp = 0;
        } else if self.item_9.id == item_id {
            self.item_9.id = 0;
            self.item_9.xp = 0;
        } else if self.item_10.id == item_id {
            self.item_10.id = 0;
            self.item_10.xp = 0;
        } else if self.item_11.id == item_id {
            self.item_11.id = 0;
            self.item_11.xp = 0;
        } else {
            panic_with_felt252('item not in bag')
        }

        // flag bag as being mutated
        self.mutated = true;

        // return the removed item
        removed_item
    }

    // @notice Checks if the bag is full
    // @dev A bag is considered full if all item slots are occupied (id of the item is non-zero)
    // @param self The instance of the Bag
    // @return A boolean value indicating whether the bag is full
    fn is_full(self: Bag) -> bool {
        if self.item_1.id == 0 {
            false
        } else if self.item_2.id == 0 {
            false
        } else if self.item_3.id == 0 {
            false
        } else if self.item_4.id == 0 {
            false
        } else if self.item_5.id == 0 {
            false
        } else if self.item_6.id == 0 {
            false
        } else if self.item_7.id == 0 {
            false
        } else if self.item_8.id == 0 {
            false
        } else if self.item_9.id == 0 {
            false
        } else if self.item_10.id == 0 {
            false
        } else if self.item_11.id == 0 {
            false
        } else {
            // if the id of all item slots is non-zero
            // bag is full, return true
            true
        }
    }

    // @notice Checks if a specific item exists in the bag
    // @param self The Bag object in which to search for the item
    // @param item The id of the item to search for
    // @return A bool indicating whether the item is present in the bag
    fn contains(self: Bag, item: u8) -> bool {
        if self.item_1.id == item {
            true
        } else if self.item_2.id == item {
            true
        } else if self.item_3.id == item {
            true
        } else if self.item_4.id == item {
            true
        } else if self.item_5.id == item {
            true
        } else if self.item_6.id == item {
            true
        } else if self.item_7.id == item {
            true
        } else if self.item_8.id == item {
            true
        } else if self.item_9.id == item {
            true
        } else if self.item_10.id == item {
            true
        } else if self.item_11.id == item {
            true
        } else {
            false
        }
    }
}

#[test]
#[available_gas(200000)]
fn test_contains() {
    let bag = Bag {
        item_1: ItemPrimitive {
            id: 0, xp: 511, metadata: 1
            }, item_2: ItemPrimitive {
            id: 2, xp: 511, metadata: 2
            }, item_3: ItemPrimitive {
            id: 3, xp: 511, metadata: 3
            }, item_4: ItemPrimitive {
            id: 4, xp: 511, metadata: 4
            }, item_5: ItemPrimitive {
            id: 5, xp: 511, metadata: 5
            }, item_6: ItemPrimitive {
            id: 6, xp: 511, metadata: 6
            }, item_7: ItemPrimitive {
            id: 7, xp: 511, metadata: 7
            }, item_8: ItemPrimitive {
            id: 8, xp: 511, metadata: 8
            }, item_9: ItemPrimitive {
            id: 9, xp: 511, metadata: 9
            }, item_10: ItemPrimitive {
            id: 10, xp: 511, metadata: 10
            }, item_11: ItemPrimitive {
            id: 255, xp: 511, metadata: 11, 
        }, mutated: false
    };

    assert(bag.contains(0) == true, 'Item 0 should be in bag');
    assert(bag.contains(2) == true, 'Item 2 should be in bag');
    assert(bag.contains(3) == true, 'Item 3 should be in bag');
    assert(bag.contains(4) == true, 'Item 4 should be in bag');
    assert(bag.contains(5) == true, 'Item 5 should be in bag');
    assert(bag.contains(6) == true, 'Item 6 should be in bag');
    assert(bag.contains(7) == true, 'Item 7 should be in bag');
    assert(bag.contains(8) == true, 'Item 8 should be in bag');
    assert(bag.contains(9) == true, 'Item 9 should be in bag');
    assert(bag.contains(10) == true, 'Item 10 should be in bag');
    assert(bag.contains(255) == true, 'Item 255 should be in bag');
    assert(bag.contains(100) == false, 'Item 100 not in bag');
}

#[test]
#[available_gas(2500000)]
fn test_pack_bag() {
    let mut bag = Bag {
        item_1: ItemPrimitive {
            id: 127, xp: 511, metadata: 31
            }, item_2: ItemPrimitive {
            id: 127, xp: 511, metadata: 31
            }, item_3: ItemPrimitive {
            id: 127, xp: 511, metadata: 31
            }, item_4: ItemPrimitive {
            id: 127, xp: 511, metadata: 31
            }, item_5: ItemPrimitive {
            id: 127, xp: 511, metadata: 31
            }, item_6: ItemPrimitive {
            id: 127, xp: 511, metadata: 31
            }, item_7: ItemPrimitive {
            id: 127, xp: 511, metadata: 31
            }, item_8: ItemPrimitive {
            id: 127, xp: 511, metadata: 31
            }, item_9: ItemPrimitive {
            id: 127, xp: 511, metadata: 31
            }, item_10: ItemPrimitive {
            id: 127, xp: 511, metadata: 31
            }, item_11: ItemPrimitive {
            id: 127, xp: 511, metadata: 31
        }, mutated: false,
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
}

#[test]
#[should_panic(expected: ('Item ID cannot be 0', ))]
#[available_gas(20000)]
fn test_add_item_blank_item() {
    // start with full bag
    let mut bag = Bag {
        item_1: ItemPrimitive {
            id: 1, xp: 1, metadata: 1
            }, item_2: ItemPrimitive {
            id: 2, xp: 1, metadata: 2
            }, item_3: ItemPrimitive {
            id: 3, xp: 1, metadata: 3
            }, item_4: ItemPrimitive {
            id: 4, xp: 1, metadata: 4
            }, item_5: ItemPrimitive {
            id: 5, xp: 1, metadata: 5
            }, item_6: ItemPrimitive {
            id: 6, xp: 1, metadata: 6
            }, item_7: ItemPrimitive {
            id: 7, xp: 1, metadata: 7
            }, item_8: ItemPrimitive {
            id: 8, xp: 1, metadata: 8
            }, item_9: ItemPrimitive {
            id: 9, xp: 1, metadata: 9
            }, item_10: ItemPrimitive {
            id: 10, xp: 1, metadata: 10
            }, item_11: ItemPrimitive {
            id: 0, xp: 0, metadata: 0
        }, mutated: false
    };

    // try adding an empty item to the bag
    // this should panic with 'Item ID cannot be 0'
    // which this test is annotated to expect
    bag.add_item(ItemPrimitive { id: 0, xp: 1, metadata: 1 });
}

#[test]
#[should_panic(expected: ('Bag is full', ))]
#[available_gas(20000)]
fn test_add_item_full_bag() {
    // start with full bag
    let mut bag = Bag {
        item_1: ItemPrimitive {
            id: 1, xp: 1, metadata: 1
            }, item_2: ItemPrimitive {
            id: 2, xp: 1, metadata: 2
            }, item_3: ItemPrimitive {
            id: 3, xp: 1, metadata: 3
            }, item_4: ItemPrimitive {
            id: 4, xp: 1, metadata: 4
            }, item_5: ItemPrimitive {
            id: 5, xp: 1, metadata: 5
            }, item_6: ItemPrimitive {
            id: 6, xp: 1, metadata: 6
            }, item_7: ItemPrimitive {
            id: 7, xp: 1, metadata: 7
            }, item_8: ItemPrimitive {
            id: 8, xp: 1, metadata: 8
            }, item_9: ItemPrimitive {
            id: 9, xp: 1, metadata: 9
            }, item_10: ItemPrimitive {
            id: 10, xp: 1, metadata: 10
            }, item_11: ItemPrimitive {
            id: 11, xp: 1, metadata: 11
        }, mutated: false
    };

    // try adding an item to a full bag
    // this should panic with 'Bag is full'
    // which this test is annotated to expect
    bag.add_item(ItemPrimitive { id: ItemId::Katana, xp: 1, metadata: 1 });
}

#[test]
#[available_gas(250000)]
fn test_add_item() {
    // start with empty bag
    let mut bag = Bag {
        item_1: ItemPrimitive {
            id: 0, xp: 0, metadata: 0
            }, item_2: ItemPrimitive {
            id: 0, xp: 0, metadata: 0
            }, item_3: ItemPrimitive {
            id: 0, xp: 0, metadata: 0
            }, item_4: ItemPrimitive {
            id: 0, xp: 0, metadata: 0
            }, item_5: ItemPrimitive {
            id: 0, xp: 0, metadata: 0
            }, item_6: ItemPrimitive {
            id: 0, xp: 0, metadata: 0
            }, item_7: ItemPrimitive {
            id: 0, xp: 0, metadata: 0
            }, item_8: ItemPrimitive {
            id: 0, xp: 0, metadata: 0
            }, item_9: ItemPrimitive {
            id: 0, xp: 0, metadata: 0
            }, item_10: ItemPrimitive {
            id: 0, xp: 0, metadata: 0
            }, item_11: ItemPrimitive {
            id: 0, xp: 0, metadata: 0
        }, mutated: false
    };

    // initialize items
    let katana = ItemPrimitive { id: ItemId::Katana, xp: 1, metadata: 1 };
    let demon_crown = ItemPrimitive { id: ItemId::DemonCrown, xp: 1, metadata: 2 };
    let silk_robe = ItemPrimitive { id: ItemId::SilkRobe, xp: 1, metadata: 3 };
    let silver_ring = ItemPrimitive { id: ItemId::SilverRing, xp: 1, metadata: 4 };
    let ghost_wand = ItemPrimitive { id: ItemId::GhostWand, xp: 1, metadata: 5 };
    let leather_gloves = ItemPrimitive { id: ItemId::LeatherGloves, xp: 1, metadata: 6 };
    let silk_gloves = ItemPrimitive { id: ItemId::SilkGloves, xp: 1, metadata: 7 };
    let linen_gloves = ItemPrimitive { id: ItemId::LinenGloves, xp: 1, metadata: 8 };
    let crown = ItemPrimitive { id: ItemId::Crown, xp: 1, metadata: 9 };
    let divine_slippers = ItemPrimitive { id: ItemId::DivineSlippers, xp: 1, metadata: 10 };
    let warhammer = ItemPrimitive { id: ItemId::Warhammer, xp: 1, metadata: 11 };

    // add items to bag
    bag.add_item(katana);
    bag.add_item(demon_crown);
    bag.add_item(silk_robe);
    bag.add_item(silver_ring);
    bag.add_item(ghost_wand);
    bag.add_item(leather_gloves);
    bag.add_item(silk_gloves);
    bag.add_item(linen_gloves);
    bag.add_item(crown);
    bag.add_item(divine_slippers);
    bag.add_item(warhammer);

    // assert items are in bag
    assert(bag.item_1.id == ItemId::Katana, 'item 1 should be katana');
    assert(bag.item_2.id == ItemId::DemonCrown, 'item 2 should be demon crown');
    assert(bag.item_3.id == ItemId::SilkRobe, 'item 3 should be silk robe');
    assert(bag.item_4.id == ItemId::SilverRing, 'item 4 should be silver ring');
    assert(bag.item_5.id == ItemId::GhostWand, 'item 5 should be ghost wand');
    assert(bag.item_6.id == ItemId::LeatherGloves, 'item 6 should be leather gloves');
    assert(bag.item_7.id == ItemId::SilkGloves, 'item 7 should be silk gloves');
    assert(bag.item_8.id == ItemId::LinenGloves, 'item 8 should be linen gloves');
    assert(bag.item_9.id == ItemId::Crown, 'item 9 should be crown');
    assert(bag.item_10.id == ItemId::DivineSlippers, 'should be divine slippers');
    assert(bag.item_11.id == ItemId::Warhammer, 'item 11 should be warhammer');
}

#[test]
#[available_gas(150000)]
fn test_is_full() {
    // start with full bag
    let mut bag = Bag {
        item_1: ItemPrimitive {
            id: 1, xp: 0, metadata: 0
            }, item_2: ItemPrimitive {
            id: 2, xp: 0, metadata: 0
            }, item_3: ItemPrimitive {
            id: 3, xp: 0, metadata: 0
            }, item_4: ItemPrimitive {
            id: 4, xp: 0, metadata: 0
            }, item_5: ItemPrimitive {
            id: 5, xp: 0, metadata: 0
            }, item_6: ItemPrimitive {
            id: 8, xp: 0, metadata: 0
            }, item_7: ItemPrimitive {
            id: 9, xp: 0, metadata: 0
            }, item_8: ItemPrimitive {
            id: 11, xp: 0, metadata: 0
            }, item_9: ItemPrimitive {
            id: 12, xp: 0, metadata: 0
            }, item_10: ItemPrimitive {
            id: 13, xp: 0, metadata: 0
            }, item_11: ItemPrimitive {
            id: 14, xp: 0, metadata: 0
        }, mutated: false
    };

    // assert bag is full
    assert(bag.is_full() == true, 'Bag should be full');

    // remove an item
    bag.remove_item(1);

    // assert bag is not full
    assert(bag.is_full() == false, 'Bag should be not full');

    // add a new item
    let mut warhammer = ItemPrimitive { id: ItemId::Warhammer, xp: 1, metadata: 11 };
    bag.add_item(warhammer);

    // assert bag is full again
    assert(bag.is_full() == true, 'Bag should be full again');
}

#[test]
#[should_panic(expected: ('Item not in bag', ))]
#[available_gas(15000)]
fn test_get_item_not_in_bag() {
    let item_1 = ItemPrimitive { id: 11, xp: 0, metadata: 0 };
    let item_2 = ItemPrimitive { id: 12, xp: 0, metadata: 0 };
    let item_3 = ItemPrimitive { id: 13, xp: 0, metadata: 0 };
    let item_4 = ItemPrimitive { id: 14, xp: 0, metadata: 0 };
    let item_5 = ItemPrimitive { id: 15, xp: 0, metadata: 0 };
    let item_6 = ItemPrimitive { id: 16, xp: 0, metadata: 0 };
    let item_7 = ItemPrimitive { id: 17, xp: 0, metadata: 0 };
    let item_8 = ItemPrimitive { id: 18, xp: 0, metadata: 0 };
    let item_9 = ItemPrimitive { id: 19, xp: 0, metadata: 0 };
    let item_10 = ItemPrimitive { id: 20, xp: 0, metadata: 0 };
    let item_11 = ItemPrimitive { id: 21, xp: 0, metadata: 0 };

    let bag = Bag {
        item_1: item_1,
        item_2: item_2,
        item_3: item_3,
        item_4: item_4,
        item_5: item_5,
        item_6: item_6,
        item_7: item_7,
        item_8: item_8,
        item_9: item_9,
        item_10: item_10,
        item_11: item_11,
        mutated: false,
    };

    // try to get an item that is not in bag
    // should panic with 'Item not in bag'
    // this test is annotated to expect this panic
    // and will fail if it not thrown
    bag.get_item(8);
}

#[test]
#[available_gas(150000)]
fn test_get_item() {
    let item_1 = ItemPrimitive { id: 11, xp: 0, metadata: 0 };
    let item_2 = ItemPrimitive { id: 12, xp: 0, metadata: 0 };
    let item_3 = ItemPrimitive { id: 13, xp: 0, metadata: 0 };
    let item_4 = ItemPrimitive { id: 14, xp: 0, metadata: 0 };
    let item_5 = ItemPrimitive { id: 15, xp: 0, metadata: 0 };
    let item_6 = ItemPrimitive { id: 16, xp: 0, metadata: 0 };
    let item_7 = ItemPrimitive { id: 17, xp: 0, metadata: 0 };
    let item_8 = ItemPrimitive { id: 18, xp: 0, metadata: 0 };
    let item_9 = ItemPrimitive { id: 19, xp: 0, metadata: 0 };
    let item_10 = ItemPrimitive { id: 20, xp: 0, metadata: 0 };
    let item_11 = ItemPrimitive { id: 21, xp: 0, metadata: 0 };

    let bag = Bag {
        item_1: item_1,
        item_2: item_2,
        item_3: item_3,
        item_4: item_4,
        item_5: item_5,
        item_6: item_6,
        item_7: item_7,
        item_8: item_8,
        item_9: item_9,
        item_10: item_10,
        item_11: item_11,
        mutated: false,
    };

    let item1_from_bag = bag.get_item(11);
    assert(item1_from_bag.id == item_1.id, 'Item id should be 11');

    let item2_from_bag = bag.get_item(12);
    assert(item2_from_bag.id == item_2.id, 'Item id should be 12');

    let item3_from_bag = bag.get_item(13);
    assert(item3_from_bag.id == item_3.id, 'Item id should be 13');

    let item4_from_bag = bag.get_item(14);
    assert(item4_from_bag.id == item_4.id, 'Item id should be 14');

    let item5_from_bag = bag.get_item(15);
    assert(item5_from_bag.id == item_5.id, 'Item id should be 15');

    let item6_from_bag = bag.get_item(16);
    assert(item6_from_bag.id == item_6.id, 'Item id should be 16');

    let item7_from_bag = bag.get_item(17);
    assert(item7_from_bag.id == item_7.id, 'Item id should be 17');

    let item8_from_bag = bag.get_item(18);
    assert(item8_from_bag.id == item_8.id, 'Item id should be 18');

    let item9_from_bag = bag.get_item(19);
    assert(item9_from_bag.id == item_9.id, 'Item id should be 19');

    let item10_from_bag = bag.get_item(20);
    assert(item10_from_bag.id == item_10.id, 'Item id should be 20');

    let item11_from_bag = bag.get_item(21);
    assert(item11_from_bag.id == item_11.id, 'Item id should be 21');
}

#[test]
#[available_gas(30000)]
fn test_remove_item() {
    let mut bag = Bag {
        item_1: ItemPrimitive {
            id: 1, xp: 0, metadata: 0
            }, item_2: ItemPrimitive {
            id: 2, xp: 0, metadata: 0
            }, item_3: ItemPrimitive {
            id: 3, xp: 0, metadata: 0
            }, item_4: ItemPrimitive {
            id: 4, xp: 0, metadata: 0
            }, item_5: ItemPrimitive {
            id: 5, xp: 0, metadata: 0
            }, item_6: ItemPrimitive {
            id: 6, xp: 0, metadata: 0
            }, item_7: ItemPrimitive {
            id: 7, xp: 0, metadata: 0
            }, item_8: ItemPrimitive {
            id: 8, xp: 1, metadata: 1
            }, item_9: ItemPrimitive {
            id: 9, xp: 0, metadata: 0
            }, item_10: ItemPrimitive {
            id: 10, xp: 0, metadata: 0
            }, item_11: ItemPrimitive {
            id: 11, xp: 0, metadata: 0
        }, mutated: false
    };

    // remove item from bag
    let removed_item = bag.remove_item(6);

    // verify it has been removed
    assert(bag.item_6.id == 0, 'id should be 0');
    assert(bag.item_6.xp == 0, 'xp should be 0');
    assert(bag.item_6.metadata == 0, 'metadata should be 0');
    assert(removed_item.id == 6, 'removed item is wrong');
}

#[test]
#[should_panic(expected: ('Item not in bag', ))]
#[available_gas(30000)]
fn test_remove_item_not_in_bag() {
    // initialize bag
    let mut bag = Bag {
        item_1: ItemPrimitive {
            id: 1, xp: 0, metadata: 0
            }, item_2: ItemPrimitive {
            id: 2, xp: 0, metadata: 0
            }, item_3: ItemPrimitive {
            id: 3, xp: 0, metadata: 0
            }, item_4: ItemPrimitive {
            id: 4, xp: 0, metadata: 0
            }, item_5: ItemPrimitive {
            id: 5, xp: 0, metadata: 0
            }, item_6: ItemPrimitive {
            id: 8, xp: 0, metadata: 0
            }, item_7: ItemPrimitive {
            id: 9, xp: 0, metadata: 0
            }, item_8: ItemPrimitive {
            id: 11, xp: 0, metadata: 0
            }, item_9: ItemPrimitive {
            id: 12, xp: 0, metadata: 0
            }, item_10: ItemPrimitive {
            id: 13, xp: 0, metadata: 0
            }, item_11: ItemPrimitive {
            id: 14, xp: 0, metadata: 0
        }, mutated: false
    };

    // try to remove an item not in the bag
    // this should panic with 'item not in bag'
    // which this test is annotated to expect
    bag.remove_item(255);
}
