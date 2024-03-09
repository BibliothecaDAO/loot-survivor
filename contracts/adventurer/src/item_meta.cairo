use starknet::{StorePacking};
use lootitems::{constants::{ItemId, ItemSuffix}, loot::ImplLoot};
use combat::combat::Slot;
use super::{
    adventurer::{Adventurer, IAdventurer, ImplAdventurer}, item_primitive::ItemPrimitive,
    stats::Stats, bag::{Bag, IBag}
};

#[derive(PartialEq, Drop, Copy, Serde)]
struct ItemSpecials {
    special1: u8, // 4 bits in storage
    special2: u8, // 7 bits in storage
    special3: u8, // 5 bits in storage
}

// Fixed size to fit optimally in felt252
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
    mutated: bool,
}

impl ItemSpecialsPacking of StorePacking<ItemSpecials, felt252> {
    fn pack(value: ItemSpecials) -> felt252 {
        (value.special2.into()
            + value.special3.into() * TWO_POW_7
            + value.special1.into() * TWO_POW_12)
            .try_into()
            .unwrap()
    }

    fn unpack(value: felt252) -> ItemSpecials {
        let packed = value.into();
        let (packed, special2) = integer::U256DivRem::div_rem(
            packed, TWO_POW_7.try_into().unwrap()
        );
        let (packed, special3) = integer::U256DivRem::div_rem(
            packed, TWO_POW_5.try_into().unwrap()
        );
        let (_, special1) = integer::U256DivRem::div_rem(packed, TWO_POW_4.try_into().unwrap());

        ItemSpecials {
            special2: special2.try_into().expect('unpack LISN special2'),
            special3: special3.try_into().expect('unpack LISN special3'),
            special1: special1.try_into().expect('unpack LISN special1')
        }
    }
}

impl ItemSpecialsStoragePacking of StorePacking<ItemSpecialsStorage, felt252> {
    fn pack(value: ItemSpecialsStorage) -> felt252 {
        (ItemSpecialsPacking::pack(value.item_1).into()
            + ItemSpecialsPacking::pack(value.item_2).into() * TWO_POW_16
            + ItemSpecialsPacking::pack(value.item_3).into() * TWO_POW_32
            + ItemSpecialsPacking::pack(value.item_4).into() * TWO_POW_48
            + ItemSpecialsPacking::pack(value.item_5).into() * TWO_POW_64
            + ItemSpecialsPacking::pack(value.item_6).into() * TWO_POW_80
            + ItemSpecialsPacking::pack(value.item_7).into() * TWO_POW_96
            + ItemSpecialsPacking::pack(value.item_8).into() * TWO_POW_112
            + ItemSpecialsPacking::pack(value.item_9).into() * TWO_POW_128
            + ItemSpecialsPacking::pack(value.item_10).into() * TWO_POW_144)
            .try_into()
            .unwrap()
    }

    fn unpack(value: felt252) -> ItemSpecialsStorage {
        let packed = value.into();
        let (packed, item_1) = integer::U256DivRem::div_rem(packed, TWO_POW_16.try_into().unwrap());
        let (packed, item_2) = integer::U256DivRem::div_rem(packed, TWO_POW_16.try_into().unwrap());
        let (packed, item_3) = integer::U256DivRem::div_rem(packed, TWO_POW_16.try_into().unwrap());
        let (packed, item_4) = integer::U256DivRem::div_rem(packed, TWO_POW_16.try_into().unwrap());
        let (packed, item_5) = integer::U256DivRem::div_rem(packed, TWO_POW_16.try_into().unwrap());
        let (packed, item_6) = integer::U256DivRem::div_rem(packed, TWO_POW_16.try_into().unwrap());
        let (packed, item_7) = integer::U256DivRem::div_rem(packed, TWO_POW_16.try_into().unwrap());
        let (packed, item_8) = integer::U256DivRem::div_rem(packed, TWO_POW_16.try_into().unwrap());
        let (packed, item_9) = integer::U256DivRem::div_rem(packed, TWO_POW_16.try_into().unwrap());
        let (_, item_10) = integer::U256DivRem::div_rem(packed, TWO_POW_16.try_into().unwrap());

        ItemSpecialsStorage {
            item_1: ItemSpecialsPacking::unpack(item_1.try_into().unwrap()),
            item_2: ItemSpecialsPacking::unpack(item_2.try_into().unwrap()),
            item_3: ItemSpecialsPacking::unpack(item_3.try_into().unwrap()),
            item_4: ItemSpecialsPacking::unpack(item_4.try_into().unwrap()),
            item_5: ItemSpecialsPacking::unpack(item_5.try_into().unwrap()),
            item_6: ItemSpecialsPacking::unpack(item_6.try_into().unwrap()),
            item_7: ItemSpecialsPacking::unpack(item_7.try_into().unwrap()),
            item_8: ItemSpecialsPacking::unpack(item_8.try_into().unwrap()),
            item_9: ItemSpecialsPacking::unpack(item_9.try_into().unwrap()),
            item_10: ItemSpecialsPacking::unpack(item_10.try_into().unwrap()),
            mutated: false,
        }
    }
}

#[generate_trait]
impl ImplItemSpecials of IItemSpecials {
    // @notice gets item specials from storage using the items meta data pointer
    // @param self A reference to ItemSpecialsStorage which stores all special items.
    // @param item An instance of ItemPrimitive that contains metadata used for item retrieval.
    // @return An instance of ItemSpecials corresponding to the metadata in item.
    // @throws 'item specials not in storage' if the item doesn't have specials in storage
    fn get_specials(self: ItemSpecialsStorage, item: ItemPrimitive) -> ItemSpecials {
        // @dev Since this function doesn't know which name storage it has been given
        // it needs to consider both storage 1 and storage 2. In the current system
        // which is rigid because it's highly gas optimized, storage 1 is used for the first 10 items
        // and name storage 2 is used for the next 9 items. As such, if this function
        // is called for an item with meta data 1, it will be in the first slot of
        // storage. Similarly, if this function is called with an item with meta data 11
        // it will be in the first slot of storage 2. This is why we need to check for
        // both storage 1 and storage 2. If you add more storage slots, you will need
        // to update this function accordingly
        if item.metadata == STORAGE::INDEX_1 || item.metadata == STORAGE::INDEX_11 {
            self.item_1
        } else if item.metadata == STORAGE::INDEX_2 || item.metadata == STORAGE::INDEX_12 {
            self.item_2
        } else if item.metadata == STORAGE::INDEX_3 || item.metadata == STORAGE::INDEX_13 {
            self.item_3
        } else if item.metadata == STORAGE::INDEX_4 || item.metadata == STORAGE::INDEX_14 {
            self.item_4
        } else if item.metadata == STORAGE::INDEX_5 || item.metadata == STORAGE::INDEX_15 {
            self.item_5
        } else if item.metadata == STORAGE::INDEX_6 || item.metadata == STORAGE::INDEX_16 {
            self.item_6
        } else if item.metadata == STORAGE::INDEX_7 || item.metadata == STORAGE::INDEX_17 {
            self.item_7
        } else if item.metadata == STORAGE::INDEX_8 || item.metadata == STORAGE::INDEX_18 {
            self.item_8
        } else if item.metadata == STORAGE::INDEX_9 || item.metadata == STORAGE::INDEX_19 {
            self.item_9
        } else if item.metadata == STORAGE::INDEX_10 {
            // storage 2 only has 9 items in it because we only support 19 Items
            // so we don't need to check INDEX_20 (that doesn't exist)
            self.item_10
        } else {
            // assert at the top of the function should prevent this outcome
            // but just in case throw a panic to ensure this function is
            // behaving as intended
            panic_with_felt252('item specials not in storage')
        }
    }

    fn get_specials_full(
        specials_storage1: ItemSpecialsStorage,
        specials_storage2: ItemSpecialsStorage,
        item: ItemPrimitive
    ) -> ItemSpecials {
        if item.metadata == STORAGE::INDEX_1 {
            specials_storage1.item_1
        } else if item.metadata == STORAGE::INDEX_2 {
            specials_storage1.item_2
        } else if item.metadata == STORAGE::INDEX_3 {
            specials_storage1.item_3
        } else if item.metadata == STORAGE::INDEX_4 {
            specials_storage1.item_4
        } else if item.metadata == STORAGE::INDEX_5 {
            specials_storage1.item_5
        } else if item.metadata == STORAGE::INDEX_6 {
            specials_storage1.item_6
        } else if item.metadata == STORAGE::INDEX_7 {
            specials_storage1.item_7
        } else if item.metadata == STORAGE::INDEX_8 {
            specials_storage1.item_8
        } else if item.metadata == STORAGE::INDEX_9 {
            specials_storage1.item_9
        } else if item.metadata == STORAGE::INDEX_10 {
            specials_storage1.item_10
        } else if item.metadata == STORAGE::INDEX_11 {
            specials_storage2.item_1
        } else if item.metadata == STORAGE::INDEX_12 {
            specials_storage2.item_2
        } else if item.metadata == STORAGE::INDEX_13 {
            specials_storage2.item_3
        } else if item.metadata == STORAGE::INDEX_14 {
            specials_storage2.item_4
        } else if item.metadata == STORAGE::INDEX_15 {
            specials_storage2.item_5
        } else if item.metadata == STORAGE::INDEX_16 {
            specials_storage2.item_6
        } else if item.metadata == STORAGE::INDEX_17 {
            specials_storage2.item_7
        } else if item.metadata == STORAGE::INDEX_18 {
            specials_storage2.item_8
        } else if item.metadata == STORAGE::INDEX_19 {
            specials_storage2.item_9
        } else {
            panic_with_felt252('item specials not in storage')
        }
    }

    // @dev This function sets special attributes for a given item in storage.
    //
    // @notice It uses the metadata of an item to decide where to place the special attributes
    // in the storage. If the item's metadata matches one of the predefined indices (from 1 to 10),
    // it assigns the specials to the corresponding slot in the storage.
    // If the item's metadata doesn't match any of the predefined indices, it triggers a panic with the message 'item not in bag'.
    //
    // @param self A mutable reference to ItemSpecialsStorage which stores all special items.
    // @param item An instance of ItemPrimitive whose metadata is used for placing the item.
    // @param specials An instance of ItemSpecials which contains the special attributes to be placed in storage.
    //
    // @throws This function will throw an error if the metadata in item doesn't match any of the predefined indices.
    fn set_specials(ref self: ItemSpecialsStorage, item: ItemPrimitive, specials: ItemSpecials) {
        // @dev Since this function doesn't know which name storage it has been given
        // it needs to consider both storage 1 and storage 2. In the current system
        // which is relatively rigid (wip), name storage 1 is used for the first 10 items
        // and name storage 2 is used for the next 9 items. As such, if this function
        // is called for an item with meta data is 1, it will be in the first slot of
        // storage. Similarly, if this function is called with an item with meta data 11
        // it will be in the first slot of storage 2. This is why we need to check for
        // both storage 1 and storage 2. If we add more storage slots in the future
        // we will need to update this function to check for those as well.
        // I have a TODO at the top to restructure our ItemSpecialStorage struct to include
        // an explicit storage id and size so we can provide a more flexible and robust
        // solution to this problem.
        if item.metadata == STORAGE::INDEX_1 || item.metadata == STORAGE::INDEX_11 {
            self.item_1 = specials;
        } else if item.metadata == STORAGE::INDEX_2 || item.metadata == STORAGE::INDEX_12 {
            self.item_2 = specials;
        } else if item.metadata == STORAGE::INDEX_3 || item.metadata == STORAGE::INDEX_13 {
            self.item_3 = specials;
        } else if item.metadata == STORAGE::INDEX_4 || item.metadata == STORAGE::INDEX_14 {
            self.item_4 = specials;
        } else if item.metadata == STORAGE::INDEX_5 || item.metadata == STORAGE::INDEX_15 {
            self.item_5 = specials;
        } else if item.metadata == STORAGE::INDEX_6 || item.metadata == STORAGE::INDEX_16 {
            self.item_6 = specials;
        } else if item.metadata == STORAGE::INDEX_7 || item.metadata == STORAGE::INDEX_17 {
            self.item_7 = specials;
        } else if item.metadata == STORAGE::INDEX_8 || item.metadata == STORAGE::INDEX_18 {
            self.item_8 = specials;
        } else if item.metadata == STORAGE::INDEX_9 || item.metadata == STORAGE::INDEX_19 {
            self.item_9 = specials;
        } else if item.metadata == STORAGE::INDEX_10 {
            // storage 2 only has 9 items in it because we only support 19 Items
            // so we don't need to check INDEX_20 (that doesn't exist)
            self.item_10 = specials;
        } else {
            // assert at the top of the function should prevent this outcome
            // but just in case throw a panic to ensure this function is
            // behaving as intended
            panic_with_felt252('meta data id not in storage')
        }

        // flag storage as mutated so we know we need to write it to storage
        self.mutated = true;
    }

    /// @title get_recycled_metadata
    ///
    /// @notice This function is used to find and return the metadata of the first item that has been dropped by the adventurer.
    ///         An item is considered dropped if its id is 0 but its metadata is not 0.
    ///
    /// @dev The function iterates through the adventurer's equipment and the bag's items in a specific order.
    ///      The order is: weapon, head, chest, hand, foot, ring, neck, waist, and then items 1 to 11 in the bag.
    ///      It returns the metadata of the first item it finds that has been dropped.
    ///      If no dropped items are found, it returns 0.
    ///
    /// @param item The Item we are assigning a metadata id to.
    /// @param adventurer The adventurer object, which contains the metadata and id for each piece of equipment the adventurer has.
    /// @param bag The bag object, which contains the metadata and id for each item in the bag.
    /// @param equipping A boolean that indicates whether the item is being equipped or placed in the bag.
    ///
    /// @return The metadata of the first dropped item found, or 0 if no dropped items are found.
    fn get_recycled_metadata(
        item: ItemPrimitive, adventurer: Adventurer, bag: Bag, equipping: bool
    ) -> u8 {
        // if the item is being equipped
        if equipping {
            // look for available metadata slots in the adventurer's equipment
            if (ImplLoot::get_slot(item.id) == Slot::Weapon(())
                && adventurer.weapon.id == 0
                && adventurer.weapon.metadata != 0) {
                adventurer.weapon.metadata
            } else if (ImplLoot::get_slot(item.id) == Slot::Head(())
                && adventurer.head.id == 0
                && adventurer.head.metadata != 0) {
                adventurer.head.metadata
            } else if (ImplLoot::get_slot(item.id) == Slot::Chest(())
                && adventurer.chest.id == 0
                && adventurer.chest.metadata != 0) {
                adventurer.chest.metadata
            } else if (ImplLoot::get_slot(item.id) == Slot::Waist(())
                && adventurer.waist.id == 0
                && adventurer.waist.metadata != 0) {
                adventurer.waist.metadata
            } else if (ImplLoot::get_slot(item.id) == Slot::Hand(())
                && adventurer.hand.id == 0
                && adventurer.hand.metadata != 0) {
                adventurer.hand.metadata
            } else if (ImplLoot::get_slot(item.id) == Slot::Foot(())
                && adventurer.foot.id == 0
                && adventurer.foot.metadata != 0) {
                adventurer.foot.metadata
            } else if (ImplLoot::get_slot(item.id) == Slot::Ring(())
                && adventurer.ring.id == 0
                && adventurer.ring.metadata != 0) {
                adventurer.ring.metadata
            } else if (ImplLoot::get_slot(item.id) == Slot::Neck(())
                && adventurer.neck.id == 0
                && adventurer.neck.metadata != 0) {
                adventurer.neck.metadata
            } else {
                0
            }
        // otherwise item is going into bag
        } else {
            // so look for free metadata available in bag
            if (bag.item_1.id == 0 && bag.item_1.metadata != 0) {
                bag.item_1.metadata
            } else if (bag.item_2.id == 0 && bag.item_2.metadata != 0) {
                bag.item_2.metadata
            } else if (bag.item_3.id == 0 && bag.item_3.metadata != 0) {
                bag.item_3.metadata
            } else if (bag.item_4.id == 0 && bag.item_4.metadata != 0) {
                bag.item_4.metadata
            } else if (bag.item_5.id == 0 && bag.item_5.metadata != 0) {
                bag.item_5.metadata
            } else if (bag.item_6.id == 0 && bag.item_6.metadata != 0) {
                bag.item_6.metadata
            } else if (bag.item_7.id == 0 && bag.item_7.metadata != 0) {
                bag.item_7.metadata
            } else if (bag.item_8.id == 0 && bag.item_8.metadata != 0) {
                bag.item_8.metadata
            } else if (bag.item_9.id == 0 && bag.item_9.metadata != 0) {
                bag.item_9.metadata
            } else if (bag.item_10.id == 0 && bag.item_10.metadata != 0) {
                bag.item_10.metadata
            } else if (bag.item_11.id == 0 && bag.item_11.metadata != 0) {
                bag.item_11.metadata
            } else {
                0
            }
        }
    }

    /// @title get_next_metadata
    ///
    /// @notice This function is used to find the highest metadata value currently in use by the adventurer's equipment or the bag's items, and then returns the next available metadata value.
    ///
    /// @dev The function iterates through the adventurer's equipment and the bag's items in a specific order.
    ///      The order is: weapon, head, chest, hand, foot, ring, neck, waist, and then items 1 to 11 in the bag.
    ///      It keeps track of the highest metadata value it finds, and then increments it by 1 to get the next available metadata value.
    ///      If the next available metadata value is greater than the maximum allowed storage slots, it triggers a panic with the error code 'out of metadata storage slots'.
    ///
    /// @param adventurer The adventurer object, which contains the metadata for each piece of equipment the adventurer has.
    /// @param bag The bag object, which contains the metadata for each item in the bag.
    ///
    /// @return The next available metadata value, or triggers a panic if no more metadata storage slots are available.
    fn get_next_metadata(adventurer: Adventurer, bag: Bag) -> u8 {
        let mut latest_metadata = 1;
        if adventurer.weapon.metadata >= latest_metadata {
            latest_metadata = adventurer.weapon.metadata;
        }
        if adventurer.head.metadata >= latest_metadata {
            latest_metadata = adventurer.head.metadata;
        }
        if adventurer.chest.metadata >= latest_metadata {
            latest_metadata = adventurer.chest.metadata;
        }
        if adventurer.hand.metadata >= latest_metadata {
            latest_metadata = adventurer.hand.metadata;
        }
        if adventurer.foot.metadata >= latest_metadata {
            latest_metadata = adventurer.foot.metadata;
        }
        if adventurer.ring.metadata >= latest_metadata {
            latest_metadata = adventurer.ring.metadata;
        }
        if adventurer.neck.metadata >= latest_metadata {
            latest_metadata = adventurer.neck.metadata;
        }
        if adventurer.waist.metadata >= latest_metadata {
            latest_metadata = adventurer.waist.metadata;
        }
        if bag.item_1.metadata >= latest_metadata {
            latest_metadata = bag.item_1.metadata;
        }
        if bag.item_2.metadata >= latest_metadata {
            latest_metadata = bag.item_2.metadata;
        }
        if bag.item_3.metadata >= latest_metadata {
            latest_metadata = bag.item_3.metadata;
        }
        if bag.item_4.metadata >= latest_metadata {
            latest_metadata = bag.item_4.metadata;
        }
        if bag.item_5.metadata >= latest_metadata {
            latest_metadata = bag.item_5.metadata;
        }
        if bag.item_6.metadata >= latest_metadata {
            latest_metadata = bag.item_6.metadata;
        }
        if bag.item_7.metadata >= latest_metadata {
            latest_metadata = bag.item_7.metadata;
        }
        if bag.item_8.metadata >= latest_metadata {
            latest_metadata = bag.item_8.metadata;
        }
        if bag.item_9.metadata >= latest_metadata {
            latest_metadata = bag.item_9.metadata;
        }
        if bag.item_10.metadata >= latest_metadata {
            latest_metadata = bag.item_10.metadata;
        }
        if bag.item_11.metadata >= latest_metadata {
            latest_metadata = bag.item_11.metadata;
        }

        // if the slot is less than the max storage slots, assign the new metadata id
        let next_metadata = latest_metadata + 1;
        if next_metadata <= STORAGE::MAX_TOTAL_STORAGE_SPECIALS {
            next_metadata
        } else {
            panic_with_felt252('out of metadata storage slots')
        }
    }

    /// @title set_metadata_id
    ///
    /// @notice This function is used to set the metadata of an item. It first tries to reuse the metadata of a dropped item. If no dropped items are found, it gets the next available metadata value.
    ///
    /// @dev The function first calls the `get_recycled_metadata` function, which returns the metadata of the first dropped item it finds, or 0 if no dropped items are found.
    ///      If `get_recycled_metadata` returns a value greater than 0, the function sets the item's metadata to this value.
    ///      If `get_recycled_metadata` returns 0, the function calls the `get_next_metadata` function, which returns the next available metadata value, and sets the item's metadata to this value.
    ///
    /// @param self The item object, which contains the metadata for the item.
    /// @param adventurer The adventurer object, which contains the metadata for each piece of equipment the adventurer has.
    /// @param bag The bag object, which contains the metadata for each item in the bag.
    ///
    /// @return None. The function modifies the item's metadata in place.
    fn set_metadata_id(ref self: ItemPrimitive, adventurer: Adventurer, bag: Bag, equipping: bool) {
        let reused_metadata = ImplItemSpecials::get_recycled_metadata(
            self, adventurer, bag, equipping
        );
        if reused_metadata > 0 {
            self.metadata = reused_metadata;
        } else {
            self.metadata = ImplItemSpecials::get_next_metadata(adventurer, bag);
        }
    }
}

mod STORAGE {
    // First 10 indexes are stored in storage 1
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

    // next 9 indexes are stored in storage 2
    const INDEX_11: u8 = 11;
    const INDEX_12: u8 = 12;
    const INDEX_13: u8 = 13;
    const INDEX_14: u8 = 14;
    const INDEX_15: u8 = 15;
    const INDEX_16: u8 = 16;
    const INDEX_17: u8 = 17;
    const INDEX_18: u8 = 18;
    const INDEX_19: u8 = 19;

    // make sure to update this if you add more storage slots
    const MAX_TOTAL_STORAGE_SPECIALS: u8 = 19;
    const MAX_SPECIALS_PER_STORAGE: u8 = 10;
}

const TWO_POW_4: u256 = 0x10;
const TWO_POW_5: u256 = 0x20;
const TWO_POW_7: u256 = 0x80;
const TWO_POW_12: u256 = 0x1000;
const TWO_POW_16: u256 = 0x10000;
const TWO_POW_32: u256 = 0x100000000;
const TWO_POW_48: u256 = 0x1000000000000;
const TWO_POW_64: u256 = 0x10000000000000000;
const TWO_POW_80: u256 = 0x100000000000000000000;
const TWO_POW_96: u256 = 0x1000000000000000000000000;
const TWO_POW_112: u256 = 0x10000000000000000000000000000;
const TWO_POW_128: u256 = 0x100000000000000000000000000000000;
const TWO_POW_144: u256 = 0x1000000000000000000000000000000000000;

// ---------------------------
// ---------- Tests ----------
// ---------------------------
#[cfg(test)]
mod tests {
    use lootitems::constants::{ItemId};
    use survivor::{
        adventurer::{ImplAdventurer}, item_primitive::ItemPrimitive, stats::Stats, bag::{Bag, IBag},
        item_meta::{
            ImplItemSpecials, ItemSpecialsStorage, ItemSpecials, ItemSpecialsStoragePacking, STORAGE
        },
    };

    #[test]
    #[available_gas(3000000)]
    fn test_item_meta_packing() {
        // initailize ItemSpecialsStorage with strategic test values
        let storage = ItemSpecialsStorage {
            item_1: ItemSpecials { special1: 0, special2: 0, special3: 0 // zero case
             },
            item_2: ItemSpecials { special1: 1, special2: 2, special3: 3 // uniqueness
             },
            item_3: ItemSpecials { special1: 4, special2: 4, special3: 4 // all same
             },
            item_4: ItemSpecials {
                special1: 15, special2: 127, special3: 31 // max packable values
            },
            item_5: ItemSpecials { special1: 4, special2: 23, special3: 2 },
            item_6: ItemSpecials { special1: 5, special2: 5, special3: 5 },
            item_7: ItemSpecials { special1: 6, special2: 6, special3: 6 },
            item_8: ItemSpecials { special1: 7, special2: 7, special3: 7 },
            item_9: ItemSpecials { special1: 8, special2: 8, special3: 8 },
            item_10: ItemSpecials { special1: 9, special2: 9, special3: 9 },
            mutated: false,
        };

        // pack and then unpack the specials
        let unpacked: ItemSpecialsStorage = ItemSpecialsStoragePacking::unpack(
            ItemSpecialsStoragePacking::pack(storage)
        );

        // assert the values were not altered using PartialEq
        assert(unpacked.item_1 == storage.item_1, 'item 1 packing error');
        assert(unpacked.item_2 == storage.item_2, 'item 2 packing error');
        assert(unpacked.item_3 == storage.item_3, 'item 3 packing error');
        assert(unpacked.item_4 == storage.item_4, 'item 4 packing error');
        assert(unpacked.item_5 == storage.item_5, 'item 5 packing error');
        assert(unpacked.item_6 == storage.item_6, 'item 6 packing error');
        assert(unpacked.item_7 == storage.item_7, 'item 7 packing error');
        assert(unpacked.item_8 == storage.item_8, 'item 8 packing error');
        assert(unpacked.item_9 == storage.item_9, 'item 9 packing error');
        assert(unpacked.item_10 == storage.item_10, 'item 10 packing error');
    }

    #[test]
    #[available_gas(4000000)]
    fn test_set_metadata_id() {
        // start test with a new adventurer wielding a wand
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);

        // assert adventurer starter weapon has meta data id 1
        assert(adventurer.weapon.metadata == 1, 'advntr wpn meta data shld be 1');

        // generate starter wand
        let mut starter_wand = ItemPrimitive { id: ItemId::Wand, xp: 1, metadata: 1 };

        // and an empty bag
        let mut bag = Bag {
            item_1: ItemPrimitive { id: 0, xp: 0, metadata: 0, },
            item_2: ItemPrimitive { id: 0, xp: 0, metadata: 0, },
            item_3: ItemPrimitive { id: 0, xp: 0, metadata: 0, },
            item_4: ItemPrimitive { id: 0, xp: 0, metadata: 0, },
            item_5: ItemPrimitive { id: 0, xp: 0, metadata: 0, },
            item_6: ItemPrimitive { id: 0, xp: 0, metadata: 0, },
            item_7: ItemPrimitive { id: 0, xp: 0, metadata: 0, },
            item_8: ItemPrimitive { id: 0, xp: 0, metadata: 0, },
            item_9: ItemPrimitive { id: 0, xp: 0, metadata: 0, },
            item_10: ItemPrimitive { id: 0, xp: 0, metadata: 0, },
            item_11: ItemPrimitive { id: 0, xp: 0, metadata: 0, },
            mutated: false
        };

        // stage a bunch of gear
        let mut katana = ItemPrimitive { id: ItemId::Katana, xp: 1, metadata: 0 };
        let mut demon_crown = ItemPrimitive { id: ItemId::DemonCrown, xp: 1, metadata: 0 };
        let mut silk_robe = ItemPrimitive { id: ItemId::SilkRobe, xp: 1, metadata: 0 };
        let mut demon_hands = ItemPrimitive { id: ItemId::DemonsHands, xp: 1, metadata: 0 };
        let mut shoes = ItemPrimitive { id: ItemId::Shoes, xp: 1, metadata: 0 };
        let mut brightsilk_sash = ItemPrimitive { id: ItemId::BrightsilkSash, xp: 1, metadata: 0 };
        let mut silk_gloves = ItemPrimitive { id: ItemId::SilkGloves, xp: 1, metadata: 0 };
        let mut linen_gloves = ItemPrimitive { id: ItemId::LinenGloves, xp: 1, metadata: 0 };
        let mut crown = ItemPrimitive { id: ItemId::Crown, xp: 1, metadata: 0 };
        let mut divine_slippers = ItemPrimitive { id: ItemId::DivineSlippers, xp: 1, metadata: 0 };
        let mut warhammer = ItemPrimitive { id: ItemId::Warhammer, xp: 1, metadata: 0 };
        let mut ancient_helm = ItemPrimitive { id: ItemId::AncientHelm, xp: 1, metadata: 0 };
        let mut divine_robe = ItemPrimitive { id: ItemId::DivineRobe, xp: 1, metadata: 0 };
        let mut holy_chestplate = ItemPrimitive { id: ItemId::HolyChestplate, xp: 1, metadata: 0 };
        let mut holy_greaves = ItemPrimitive { id: ItemId::HolyGreaves, xp: 1, metadata: 0 };
        let mut demonhide_boots = ItemPrimitive { id: ItemId::DemonhideBoots, xp: 1, metadata: 0 };
        let mut _holy_gauntlets = ItemPrimitive { id: ItemId::HolyGauntlets, xp: 1, metadata: 0 };
        let mut _demonhide_belt = ItemPrimitive { id: ItemId::DemonhideBelt, xp: 1, metadata: 0 };

        // take the common start with T1 Katana
        katana.set_metadata_id(adventurer, bag, false);

        // toss starter wand in bag
        bag.add_item(starter_wand);

        // equip katana
        adventurer.equip_item(katana);

        // katana should pickup new metadata pointer 2
        assert(katana.metadata == 2, 'wrong katana metadata');

        // starter wand should now be item1 in bag and meta data should have moved with it
        assert(
            bag.item_1.id == starter_wand.id && bag.item_1.metadata == 1,
            'wrong starter wand bag data'
        );

        // proceed to buy armor for the adventurer, verifying meta data pointers for each item
        demon_crown.set_metadata_id(adventurer, bag, true);
        adventurer.equip_item(demon_crown);
        assert(demon_crown.metadata == 3, 'wrong demon crown metadata');

        silk_robe.set_metadata_id(adventurer, bag, true);
        adventurer.equip_item(silk_robe);
        assert(silk_robe.metadata == 4, 'wrong silk robe metadata');

        demon_hands.set_metadata_id(adventurer, bag, true);
        adventurer.equip_item(demon_hands);
        assert(demon_hands.metadata == 5, 'wrong demonhands metadata');

        shoes.set_metadata_id(adventurer, bag, true);
        adventurer.equip_item(shoes);
        assert(shoes.metadata == 6, 'wrong shoes metadata');

        brightsilk_sash.set_metadata_id(adventurer, bag, true);
        adventurer.equip_item(brightsilk_sash);
        assert(brightsilk_sash.metadata == 7, 'wrong leather gloves metadata');

        // Adventurer now has full armor (we are intentionally deferring jewlery)
        // so now start buying items for the bag, filling it up to one less than capacity
        silk_gloves.set_metadata_id(adventurer, bag, false);
        bag.add_item(silk_gloves);
        assert(
            bag.item_2 == silk_gloves && silk_gloves.metadata == 8, 'wrong silk gloves metadata'
        );

        linen_gloves.set_metadata_id(adventurer, bag, false);
        bag.add_item(linen_gloves);
        assert(
            bag.item_3 == linen_gloves && linen_gloves.metadata == 9, 'wrong linen gloves metadata'
        );

        crown.set_metadata_id(adventurer, bag, false);
        bag.add_item(crown);
        assert(bag.item_4 == crown && crown.metadata == 10, 'wrong crown metadata');

        divine_slippers.set_metadata_id(adventurer, bag, false);
        bag.add_item(divine_slippers);
        assert(
            bag.item_5 == divine_slippers && divine_slippers.metadata == 11,
            'wrong divine slippers metadata'
        );

        warhammer.set_metadata_id(adventurer, bag, false);
        bag.add_item(warhammer);
        assert(bag.item_6 == warhammer && warhammer.metadata == 12, 'wrong warhammer metadata');

        ancient_helm.set_metadata_id(adventurer, bag, false);
        bag.add_item(ancient_helm);
        assert(
            bag.item_7 == ancient_helm && ancient_helm.metadata == 13, 'wrong ancient helm metadata'
        );

        divine_robe.set_metadata_id(adventurer, bag, false);
        bag.add_item(divine_robe);
        assert(
            bag.item_8 == divine_robe && divine_robe.metadata == 14, 'wrong divine robe metadata'
        );

        holy_chestplate.set_metadata_id(adventurer, bag, false);
        bag.add_item(holy_chestplate);
        assert(
            bag.item_9 == holy_chestplate && holy_chestplate.metadata == 15,
            'wrong holy chestplate metadata'
        );

        holy_greaves.set_metadata_id(adventurer, bag, false);
        bag.add_item(holy_greaves);
        assert(
            bag.item_10 == holy_greaves && holy_greaves.metadata == 16,
            'wrong holy greaves metadata'
        );

        demonhide_boots.set_metadata_id(adventurer, bag, false);
        bag.add_item(demonhide_boots);
        assert(
            bag.item_11 == demonhide_boots && demonhide_boots.metadata == 17,
            'wrong demonhide boots metadata'
        );

        // before we proceed to test drop and buy, double check meta data pointers
        assert(starter_wand.metadata == 1, 'wrong starter wand metadata');
        assert(katana.metadata == 2, 'wrong katana metadata');
        assert(demon_crown.metadata == 3, 'wrong demon crown metadata');
        assert(silk_robe.metadata == 4, 'wrong silk robe metadata');
        assert(demon_hands.metadata == 5, 'wrong silver ring metadata');
        assert(shoes.metadata == 6, 'wrong ghost wand metadata');
        assert(brightsilk_sash.metadata == 7, 'wrong leather gloves metadata');
        assert(silk_gloves.metadata == 8, 'wrong silk gloves metadata');
        assert(linen_gloves.metadata == 9, 'wrong linen gloves metadata');
        assert(crown.metadata == 10, 'wrong crown metadata');
        assert(divine_slippers.metadata == 11, 'wrong divine slippers metadata');
        assert(warhammer.metadata == 12, 'wrong warhammer metadata');
        assert(ancient_helm.metadata == 13, 'wrong ancient helm metadata');
        assert(divine_robe.metadata == 14, 'wrong divine robe metadata');
        assert(holy_chestplate.metadata == 15, 'wrong holy chestplate metadata');
        assert(holy_greaves.metadata == 16, 'wrong holy greaves metadata');
        assert(demonhide_boots.metadata == 17, 'wrong demonhide boots metadata');

        // drop wand from bag and verify ID and XP get zero'd out but metadata stays the same
        bag.remove_item(starter_wand.id);
        assert(bag.item_1.id == 0, 'wand not zerod out');
        assert(bag.item_1.xp == 0, 'wand xp not zerod out');
        assert(bag.item_1.metadata == 1, 'wand metadata should not change');

        // buy another item for the bag and verify it fills the spot of the dropped wand and uses the same metadata
        let mut demonhide_belt = ItemPrimitive { id: ItemId::DemonhideBelt, xp: 1, metadata: 0 };
        demonhide_belt.set_metadata_id(adventurer, bag, false);
        bag.add_item(demonhide_belt);
        assert(
            bag.item_1 == demonhide_belt && demonhide_belt.metadata == 1,
            'wrong demonhide belt metadata'
        );

        // same test but this time dropping two items from bag and verifying the new items fill the spots and use the same metadata
        let item_2_metadata = bag.item_2.metadata;
        let item_3_metadata = bag.item_3.metadata;
        bag.remove_item(bag.item_2.id);
        bag.remove_item(bag.item_3.id);
        let mut book = ItemPrimitive { id: ItemId::Book, xp: 1, metadata: 0 };
        book.set_metadata_id(adventurer, bag, false);
        bag.add_item(book);
        let mut tome = ItemPrimitive { id: ItemId::Tome, xp: 1, metadata: 0 };
        tome.set_metadata_id(adventurer, bag, false);
        bag.add_item(tome);
        assert(bag.item_2 == book && book.metadata == item_2_metadata, 'wrong book metadata');
        assert(bag.item_3 == tome && tome.metadata == item_3_metadata, 'wrong tome metadata');

        // with the holes filled, purchase remaining jewelry items

        // necklace should pickup metadata 18
        let mut necklace = ItemPrimitive { id: ItemId::Necklace, xp: 1, metadata: 0 };
        necklace.set_metadata_id(adventurer, bag, true);
        adventurer.equip_necklace(necklace);
        assert(adventurer.neck == necklace && necklace.metadata == 18, 'wrong necklace metadata');

        // and ring should get the last metadata spot of 19
        let mut gold_ring = ItemPrimitive { id: ItemId::GoldRing, xp: 1, metadata: 0 };
        gold_ring.set_metadata_id(adventurer, bag, true);
        adventurer.equip_ring(gold_ring);
        assert(
            adventurer.ring == gold_ring && gold_ring.metadata == 19, 'wrong gold ring metadata'
        );

        // drop adventurers katana and buy a grimoire and verify the metadata is reused
        adventurer.drop_item(adventurer.weapon.id);
        let mut grimoire = ItemPrimitive { id: ItemId::Grimoire, xp: 1, metadata: 0 };
        grimoire.set_metadata_id(adventurer, bag, true);
        adventurer.equip_item(grimoire);
        assert(adventurer.weapon == grimoire && grimoire.metadata == 2, 'wrong grimoire metadata');
    }

    #[test]
    #[available_gas(500000)]
    fn test_get_specials() {
        // create 19 items to be used for the test
        let wand = ItemPrimitive { id: ItemId::Wand, xp: 1, metadata: 1 };
        let katana = ItemPrimitive { id: ItemId::Katana, xp: 1, metadata: 2 };
        let demon_crown = ItemPrimitive { id: ItemId::DemonCrown, xp: 1, metadata: 3 };
        let silk_robe = ItemPrimitive { id: ItemId::SilkRobe, xp: 1, metadata: 4 };
        let silver_ring = ItemPrimitive { id: ItemId::SilverRing, xp: 1, metadata: 5 };
        let ghost_wand = ItemPrimitive { id: ItemId::GhostWand, xp: 1, metadata: 6 };
        let leather_gloves = ItemPrimitive { id: ItemId::LeatherGloves, xp: 1, metadata: 7 };
        let silk_gloves = ItemPrimitive { id: ItemId::SilkGloves, xp: 1, metadata: 8 };
        let linen_gloves = ItemPrimitive { id: ItemId::LinenGloves, xp: 1, metadata: 9 };
        let crown = ItemPrimitive { id: ItemId::Crown, xp: 1, metadata: 10 };
        let divine_slippers = ItemPrimitive { id: ItemId::DivineSlippers, xp: 1, metadata: 11 };
        let warhammer = ItemPrimitive { id: ItemId::Warhammer, xp: 1, metadata: 12 };
        let ancient_helm = ItemPrimitive { id: ItemId::AncientHelm, xp: 1, metadata: 13 };
        let divine_robe = ItemPrimitive { id: ItemId::DivineRobe, xp: 1, metadata: 14 };
        let holy_chestplate = ItemPrimitive { id: ItemId::HolyChestplate, xp: 1, metadata: 15 };
        let holy_greaves = ItemPrimitive { id: ItemId::HolyGreaves, xp: 1, metadata: 16 };
        let _demonhide_boots = ItemPrimitive { id: ItemId::DemonhideBoots, xp: 1, metadata: 17 };
        let holy_gauntlets = ItemPrimitive { id: ItemId::HolyGauntlets, xp: 1, metadata: 18 };
        let demonhide_boots = ItemPrimitive { id: ItemId::DemonhideBoots, xp: 1, metadata: 19 };

        // generate unique specials for each item
        let wand_specials = ItemSpecials { special1: 1, special2: 1, special3: 1 };
        let katana_specials = ItemSpecials { special1: 2, special2: 2, special3: 2 };
        let demon_crown_specials = ItemSpecials { special1: 3, special2: 3, special3: 3 };
        let silk_robe_specials = ItemSpecials { special1: 4, special2: 4, special3: 4 };
        let silver_ring_specials = ItemSpecials { special1: 5, special2: 5, special3: 5 };
        let ghost_wand_specials = ItemSpecials { special1: 6, special2: 6, special3: 6 };
        let leather_gloves_specials = ItemSpecials { special1: 7, special2: 7, special3: 7 };
        let silk_gloves_specials = ItemSpecials { special1: 8, special2: 8, special3: 8 };
        let linen_gloves_specials = ItemSpecials { special1: 9, special2: 9, special3: 9 };
        let crown_specials = ItemSpecials { special1: 10, special2: 10, special3: 10 };
        let divine_slippers_specials = ItemSpecials { special1: 11, special2: 11, special3: 11 };
        let warhammer_specials = ItemSpecials { special1: 12, special2: 12, special3: 12 };
        let ancient_helm_specials = ItemSpecials { special1: 13, special2: 13, special3: 13 };
        let divine_robe_specials = ItemSpecials { special1: 14, special2: 14, special3: 14 };
        let holy_chestplate_specials = ItemSpecials { special1: 15, special2: 15, special3: 15 };
        let holy_greaves_specials = ItemSpecials { special1: 1, special2: 16, special3: 16 };
        let _demonhide_boots_specials = ItemSpecials { special1: 2, special2: 17, special3: 17 };
        let holy_gauntlets_specials = ItemSpecials { special1: 3, special2: 18, special3: 18 };
        let demonhide_boots_specials = ItemSpecials { special1: 4, special2: 19, special3: 19 };

        // initialize special storage 1 with first 10 items
        let storage1 = ItemSpecialsStorage {
            item_1: wand_specials,
            item_2: katana_specials,
            item_3: demon_crown_specials,
            item_4: silk_robe_specials,
            item_5: silver_ring_specials,
            item_6: ghost_wand_specials,
            item_7: leather_gloves_specials,
            item_8: silk_gloves_specials,
            item_9: linen_gloves_specials,
            item_10: crown_specials,
            mutated: false
        };

        // initialize special storage 2 with remaining 9 items
        let storage2 = ItemSpecialsStorage {
            item_1: divine_slippers_specials,
            item_2: warhammer_specials,
            item_3: ancient_helm_specials,
            item_4: divine_robe_specials,
            item_5: holy_chestplate_specials,
            item_6: holy_greaves_specials,
            item_7: demonhide_boots_specials,
            item_8: holy_gauntlets_specials,
            item_9: demonhide_boots_specials,
            item_10: ItemSpecials { // no item 10 in storage2
                special1: 0, special2: 0, special3: 0
            },
            mutated: false
        };

        // assert calling get_special for each item returns the expected specials
        // we use PartialEq for comparision so if any of the attributes of ItemSpecials are
        // different the assert will fail
        assert(storage1.get_specials(wand) == wand_specials, 'wrong wand specials');
        assert(storage1.get_specials(katana) == katana_specials, 'wrong katana specials');
        assert(
            storage1.get_specials(demon_crown) == demon_crown_specials, 'wrong demon crown specials'
        );
        assert(storage1.get_specials(silk_robe) == silk_robe_specials, 'wrong silk robe specials');
        assert(
            storage1.get_specials(silver_ring) == silver_ring_specials, 'wrong silver ring specials'
        );
        assert(
            storage1.get_specials(ghost_wand) == ghost_wand_specials, 'wrong ghost wand specials'
        );
        assert(
            storage1.get_specials(leather_gloves) == leather_gloves_specials,
            'wrong leather gloves specials'
        );
        assert(
            storage1.get_specials(silk_gloves) == silk_gloves_specials, 'wrong silk gloves specials'
        );
        assert(
            storage1.get_specials(linen_gloves) == linen_gloves_specials,
            'wrong linen gloves specials'
        );
        assert(storage1.get_specials(crown) == crown_specials, 'wrong crown specials');
        assert(
            storage2.get_specials(divine_slippers) == divine_slippers_specials,
            'wrong divine slippers specials'
        );
        assert(storage2.get_specials(warhammer) == warhammer_specials, 'wrong warhammer specials');
        assert(
            storage2.get_specials(ancient_helm) == ancient_helm_specials,
            'wrong ancient helm specials'
        );
        assert(
            storage2.get_specials(divine_robe) == divine_robe_specials, 'wrong divine robe specials'
        );
        assert(
            storage2.get_specials(holy_chestplate) == holy_chestplate_specials,
            'wrong holy chestplate specials'
        );
        assert(
            storage2.get_specials(holy_greaves) == holy_greaves_specials,
            'wrong holy greaves specials'
        );
        assert(
            storage2.get_specials(demonhide_boots) == demonhide_boots_specials,
            'wrong demonhide boots specials'
        );
        assert(
            storage2.get_specials(holy_gauntlets) == holy_gauntlets_specials,
            'wrong holy gauntlets specials'
        );
        assert(
            storage2.get_specials(demonhide_boots) == demonhide_boots_specials,
            'wrong demonhide boots specials'
        );
    }

    #[test]
    #[should_panic(expected: ('item specials not in storage',))]
    #[available_gas(30000)]
    fn test_get_specials_overflow_fail() {
        // initialize ItemSpecialsStorage with all empty ItemSpecials
        // as we don't need them for this test
        let name_storage1 = ItemSpecialsStorage {
            item_1: ItemSpecials { special2: 0, special3: 0, special1: 0 },
            item_2: ItemSpecials { special2: 0, special3: 0, special1: 0 },
            item_3: ItemSpecials { special2: 0, special3: 0, special1: 0 },
            item_4: ItemSpecials { special2: 0, special3: 0, special1: 0 },
            item_5: ItemSpecials { special2: 0, special3: 0, special1: 0 },
            item_6: ItemSpecials { special2: 0, special3: 0, special1: 0 },
            item_7: ItemSpecials { special2: 0, special3: 0, special1: 0 },
            item_8: ItemSpecials { special2: 0, special3: 0, special1: 0 },
            item_9: ItemSpecials { special2: 0, special3: 0, special1: 0 },
            item_10: ItemSpecials { special2: 0, special3: 0, special1: 0 },
            mutated: false
        };

        // initialze an item whose meta data exceeds the max storage slot for the special storage
        let meta_data_id = STORAGE::MAX_TOTAL_STORAGE_SPECIALS + 1;
        let item_11 = ItemPrimitive { id: 10, xp: 1, metadata: meta_data_id };

        // attempt to get specials for this item
        // this should throw a panic with the error 'metadata id out of bounds'
        // this test is annotated to expect this error and will fail
        // if it is not thrown
        let _meta_data = name_storage1.get_specials(item_11);
    }

    #[test]
    #[should_panic(expected: ('item specials not in storage',))]
    #[available_gas(30000)]
    fn test_get_specials_zero_fail() {
        // initialize ItemSpecialsStorage with all empty ItemSpecials
        // as we don't need them for this test
        let name_storage1 = ItemSpecialsStorage {
            item_1: ItemSpecials { special2: 0, special3: 0, special1: 0 },
            item_2: ItemSpecials { special2: 0, special3: 0, special1: 0 },
            item_3: ItemSpecials { special2: 0, special3: 0, special1: 0 },
            item_4: ItemSpecials { special2: 0, special3: 0, special1: 0 },
            item_5: ItemSpecials { special2: 0, special3: 0, special1: 0 },
            item_6: ItemSpecials { special2: 0, special3: 0, special1: 0 },
            item_7: ItemSpecials { special2: 0, special3: 0, special1: 0 },
            item_8: ItemSpecials { special2: 0, special3: 0, special1: 0 },
            item_9: ItemSpecials { special2: 0, special3: 0, special1: 0 },
            item_10: ItemSpecials { special2: 0, special3: 0, special1: 0 },
            mutated: false
        };

        // initialze an item whose meta data exceeds the max storage slot for the special storage
        let meta_data_id_zero = 0;
        let item_11 = ItemPrimitive { id: 10, xp: 1, metadata: meta_data_id_zero };

        // attempt to get specials for this item which has meta data id 0
        // this should throw a panic with the error 'metadata id out of bounds'
        // this test is annotated to expect this error
        let _meta_data = name_storage1.get_specials(item_11);
    }

    #[test]
    #[available_gas(600000)]
    fn test_set_specials() {
        let mut storage1 = ItemSpecialsStorage {
            item_1: ItemSpecials { special2: 0, special3: 0, special1: 0, },
            item_2: ItemSpecials { special2: 0, special3: 0, special1: 0, },
            item_3: ItemSpecials { special2: 0, special3: 0, special1: 0, },
            item_4: ItemSpecials { special2: 0, special3: 0, special1: 0, },
            item_5: ItemSpecials { special2: 0, special3: 0, special1: 0, },
            item_6: ItemSpecials { special2: 0, special3: 0, special1: 0, },
            item_7: ItemSpecials { special2: 0, special3: 0, special1: 0, },
            item_8: ItemSpecials { special2: 0, special3: 0, special1: 0, },
            item_9: ItemSpecials { special2: 0, special3: 0, special1: 0, },
            item_10: ItemSpecials { special2: 0, special3: 0, special1: 0, },
            mutated: false
        };

        let mut storage2 = ItemSpecialsStorage {
            item_1: ItemSpecials { special2: 0, special3: 0, special1: 0, },
            item_2: ItemSpecials { special2: 0, special3: 0, special1: 0, },
            item_3: ItemSpecials { special2: 0, special3: 0, special1: 0, },
            item_4: ItemSpecials { special2: 0, special3: 0, special1: 0, },
            item_5: ItemSpecials { special2: 0, special3: 0, special1: 0, },
            item_6: ItemSpecials { special2: 0, special3: 0, special1: 0, },
            item_7: ItemSpecials { special2: 0, special3: 0, special1: 0, },
            item_8: ItemSpecials { special2: 0, special3: 0, special1: 0, },
            item_9: ItemSpecials { special2: 0, special3: 0, special1: 0, },
            item_10: ItemSpecials { special2: 0, special3: 0, special1: 0, },
            mutated: false
        };

        // Storage 1 Tests
        let wand = ItemPrimitive { id: ItemId::Wand, xp: 0, metadata: 1 };
        let wand_specials = ItemSpecials { special2: 12, special3: 2, special1: 5 };
        storage1.set_specials(wand, wand_specials);
        assert(storage1.item_1 == wand_specials, 'wand set specials error');

        let katana = ItemPrimitive { id: ItemId::Wand, xp: 0, metadata: 2 };
        let katana_specials = ItemSpecials { special2: 1, special3: 2, special1: 3 };
        storage1.set_specials(katana, katana_specials);
        assert(storage1.item_2 == katana_specials, 'katana set specials error');

        let demon_crown = ItemPrimitive { id: ItemId::DemonCrown, xp: 0, metadata: 3 };
        let demon_crown_specials = ItemSpecials { special2: 2, special3: 3, special1: 4 };
        storage1.set_specials(demon_crown, demon_crown_specials);
        assert(storage1.item_3 == demon_crown_specials, 'demon crown set specials error');

        let silk_robe = ItemPrimitive { id: ItemId::SilkRobe, xp: 0, metadata: 4 };
        let silk_robe_specials = ItemSpecials { special2: 3, special3: 4, special1: 5 };
        storage1.set_specials(silk_robe, silk_robe_specials);
        assert(storage1.item_4 == silk_robe_specials, 'silk robe set specials error');

        let brightsilk_sash = ItemPrimitive { id: ItemId::BrightsilkSash, xp: 0, metadata: 5 };
        let brightsilk_sash_specials = ItemSpecials { special2: 4, special3: 5, special1: 6 };
        storage1.set_specials(brightsilk_sash, brightsilk_sash_specials);
        assert(storage1.item_5 == brightsilk_sash_specials, 'sash set specials error');

        let divine_gloves = ItemPrimitive { id: ItemId::DivineGloves, xp: 0, metadata: 6 };
        let divine_gloves_specials = ItemSpecials { special2: 5, special3: 6, special1: 7 };
        storage1.set_specials(divine_gloves, divine_gloves_specials);
        assert(storage1.item_6 == divine_gloves_specials, 'divine gloves set specials err');

        let shoes = ItemPrimitive { id: ItemId::Shoes, xp: 0, metadata: 7 };
        let shoes_specials = ItemSpecials { special2: 6, special3: 7, special1: 8 };
        storage1.set_specials(shoes, shoes_specials);
        assert(storage1.item_7 == shoes_specials, 'shoes set specials error');

        let silver_ring = ItemPrimitive { id: ItemId::SilverRing, xp: 0, metadata: 8 };
        let silver_ring_specials = ItemSpecials { special2: 4, special3: 5, special1: 6 };
        storage1.set_specials(silver_ring, silver_ring_specials);
        assert(storage1.item_5 == silver_ring_specials, 'silver ring set specials error');

        let necklace = ItemPrimitive { id: ItemId::Necklace, xp: 0, metadata: 9 };
        let necklace_specials = ItemSpecials { special2: 8, special3: 9, special1: 10 };
        storage1.set_specials(necklace, necklace_specials);
        assert(storage1.item_9 == necklace_specials, 'necklace set specials error');

        let linen_gloves = ItemPrimitive { id: ItemId::LinenGloves, xp: 0, metadata: 10 };
        let linen_gloves_specials = ItemSpecials { special2: 9, special3: 10, special1: 11 };
        storage1.set_specials(linen_gloves, linen_gloves_specials);
        assert(storage1.item_10 == linen_gloves_specials, 'linen gloves set specials error');

        // Repeat for Storage 2 with meta data ids in the 11-19 range
        let wand = ItemPrimitive { id: ItemId::Wand, xp: 0, metadata: 11 };
        let wand_specials = ItemSpecials { special2: 12, special3: 2, special1: 5 };
        storage2.set_specials(wand, wand_specials);
        assert(storage2.item_1 == wand_specials, 'wand set specials error');

        let katana = ItemPrimitive { id: ItemId::Wand, xp: 0, metadata: 12 };
        let katana_specials = ItemSpecials { special2: 1, special3: 2, special1: 3 };
        storage2.set_specials(katana, katana_specials);
        assert(storage2.item_2 == katana_specials, 'katana set specials error');

        let demon_crown = ItemPrimitive { id: ItemId::DemonCrown, xp: 0, metadata: 13 };
        let demon_crown_specials = ItemSpecials { special2: 2, special3: 3, special1: 4 };
        storage2.set_specials(demon_crown, demon_crown_specials);
        assert(storage2.item_3 == demon_crown_specials, 'demon crown set specials error');

        let silk_robe = ItemPrimitive { id: ItemId::SilkRobe, xp: 0, metadata: 14 };
        let silk_robe_specials = ItemSpecials { special2: 3, special3: 4, special1: 5 };
        storage2.set_specials(silk_robe, silk_robe_specials);
        assert(storage2.item_4 == silk_robe_specials, 'silk robe set specials error');

        let brightsilk_sash = ItemPrimitive { id: ItemId::BrightsilkSash, xp: 0, metadata: 15 };
        let brightsilk_sash_specials = ItemSpecials { special2: 4, special3: 5, special1: 6 };
        storage2.set_specials(brightsilk_sash, brightsilk_sash_specials);
        assert(storage2.item_5 == brightsilk_sash_specials, 'sash set specials error');

        let divine_gloves = ItemPrimitive { id: ItemId::DivineGloves, xp: 0, metadata: 16 };
        let divine_gloves_specials = ItemSpecials { special2: 5, special3: 6, special1: 7 };
        storage2.set_specials(divine_gloves, divine_gloves_specials);
        assert(storage2.item_6 == divine_gloves_specials, 'divine gloves set specials err');

        let shoes = ItemPrimitive { id: ItemId::Shoes, xp: 0, metadata: 17 };
        let shoes_specials = ItemSpecials { special2: 6, special3: 7, special1: 8 };
        storage2.set_specials(shoes, shoes_specials);
        assert(storage2.item_7 == shoes_specials, 'shoes set specials error');

        let silver_ring = ItemPrimitive { id: ItemId::SilverRing, xp: 0, metadata: 18 };
        let silver_ring_specials = ItemSpecials { special2: 4, special3: 5, special1: 6 };
        storage2.set_specials(silver_ring, silver_ring_specials);
        assert(storage2.item_5 == silver_ring_specials, 'silver ring set specials error');

        let necklace = ItemPrimitive { id: ItemId::Necklace, xp: 0, metadata: 19 };
        let necklace_specials = ItemSpecials { special2: 8, special3: 9, special1: 10 };
        storage2.set_specials(necklace, necklace_specials);
        assert(storage2.item_9 == necklace_specials, 'necklace set specials error');
    }

    #[test]
    #[should_panic(expected: ('meta data id not in storage',))]
    #[available_gas(40000)]
    fn test_set_specials_storage_zero_fail() {
        // initialize ItemSpecialsStorage with all empty ItemSpecials
        // as we don't need them for this test
        let mut name_storage1 = ItemSpecialsStorage {
            item_1: ItemSpecials { special2: 0, special3: 0, special1: 0 },
            item_2: ItemSpecials { special2: 0, special3: 0, special1: 0 },
            item_3: ItemSpecials { special2: 0, special3: 0, special1: 0 },
            item_4: ItemSpecials { special2: 0, special3: 0, special1: 0 },
            item_5: ItemSpecials { special2: 0, special3: 0, special1: 0 },
            item_6: ItemSpecials { special2: 0, special3: 0, special1: 0 },
            item_7: ItemSpecials { special2: 0, special3: 0, special1: 0 },
            item_8: ItemSpecials { special2: 0, special3: 0, special1: 0 },
            item_9: ItemSpecials { special2: 0, special3: 0, special1: 0 },
            item_10: ItemSpecials { special2: 0, special3: 0, special1: 0 },
            mutated: false
        };

        // initialze an item with meta data id zero
        let meta_data_zero = 0;
        let item_11 = ItemPrimitive { id: 10, xp: 1, metadata: meta_data_zero };
        let item_11_specials = ItemSpecials { special2: 1, special3: 1, special1: 1 };

        // attempt to set specials for an item with meta data id zero
        // since this is not possible, we expect set_specials to panic
        // with 'metadata id out of bounds'
        let _meta_data = name_storage1.set_specials(item_11, item_11_specials);
    }

    #[test]
    #[should_panic(expected: ('meta data id not in storage',))]
    #[available_gas(40000)]
    fn test_set_specials_storage_overflow_fail() {
        // initialize ItemSpecialsStorage with all empty ItemSpecials
        // as we don't need them for this test
        let mut name_storage1 = ItemSpecialsStorage {
            item_1: ItemSpecials { special2: 0, special3: 0, special1: 0 },
            item_2: ItemSpecials { special2: 0, special3: 0, special1: 0 },
            item_3: ItemSpecials { special2: 0, special3: 0, special1: 0 },
            item_4: ItemSpecials { special2: 0, special3: 0, special1: 0 },
            item_5: ItemSpecials { special2: 0, special3: 0, special1: 0 },
            item_6: ItemSpecials { special2: 0, special3: 0, special1: 0 },
            item_7: ItemSpecials { special2: 0, special3: 0, special1: 0 },
            item_8: ItemSpecials { special2: 0, special3: 0, special1: 0 },
            item_9: ItemSpecials { special2: 0, special3: 0, special1: 0 },
            item_10: ItemSpecials { special2: 0, special3: 0, special1: 0 },
            mutated: false
        };

        // initialze an item whose meta data exceeds the max storage slot for the special storage
        let meta_data_id = STORAGE::MAX_TOTAL_STORAGE_SPECIALS + 1;
        let item_11 = ItemPrimitive { id: 10, xp: 1, metadata: meta_data_id };
        let item_11_specials = ItemSpecials { special2: 1, special3: 1, special1: 1 };

        // attempt to set specials for this item which is not possible because
        // it's meta data exceeds the max storage slot for the special storage system
        // this should throw a panic with the error 'metadata id out of bounds'
        // this test is annotated to expect this error
        let _meta_data = name_storage1.set_specials(item_11, item_11_specials);
    }
}
