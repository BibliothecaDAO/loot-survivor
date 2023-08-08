// a randomised deterministic marketplace
use traits::{TryInto, Into};
use array::{ArrayTrait, SpanTrait};
use option::OptionTrait;
use core::clone::Clone;

use lootitems::{
    loot::{Loot, ILoot, ImplLoot}, statistics::{item_tier, constants::{ItemId, NUM_ITEMS}}
};

use combat::constants::CombatEnums::{Tier, Slot};
use super::constants::{NUM_LOOT_ITEMS, NUMBER_OF_ITEMS_PER_LEVEL, TIER_PRICE};
use pack::pack::{rshift_split};


#[derive(Drop, Serde)]
struct LootWithPrice {
    item: Loot,
    price: u16,
}

#[derive(Copy, Drop, Serde)]
struct ItemPurchase {
    item_id: u8,
    equip: bool,
}

#[generate_trait]
impl ImplMarket of IMarket {
    // @notice Retrieves the price associated with a particular tier.
    // @param tier - A Tier enum indicating the item tier.
    // @return The price as an unsigned 16-bit integer.
    // @dev This function matches the tier enum to a respective price calculation.
    fn get_price(tier: Tier) -> u16 {
        match tier {
            Tier::None(()) => 0,
            Tier::T1(()) => 5 * TIER_PRICE,
            Tier::T2(()) => 4 * TIER_PRICE,
            Tier::T3(()) => 3 * TIER_PRICE,
            Tier::T4(()) => 2 * TIER_PRICE,
            Tier::T5(()) => 1 * TIER_PRICE,
        }
    }

    /// @notice Retrieves all items associated with an array of seeds and offsets.
    /// @param seeds - A Span of 128-bit unsigned integers representing unique identifiers for the seeds.
    /// @param offsets - A Span of 8-bit unsigned integers representing offset values for the seeds.
    /// @return An Array of Loot.
    fn get_all_items(seeds: Span<u256>, offsets: Span<u8>) -> Array<Loot> {
        let mut all_items = ArrayTrait::<Loot>::new();

        // iterate over our array of seeds
        let mut seed_index: u32 = 0;
        loop {
            // if we checked all seeds, return false
            if seed_index >= seeds.len() {
                break;
            }
            let seed = *seeds.at(seed_index);
            let offset = *offsets.at(seed_index);

            let mut item_offset: u256 = 0;
            loop {
                if item_offset >= offset.into() * NUMBER_OF_ITEMS_PER_LEVEL.into() {
                    break;
                }

                all_items.append(ImplLoot::get_item(ImplMarket::get_id(seed + item_offset.into())));
                item_offset += offset.into();
            };

            // otherwise continue to the next seed
            seed_index += 1;
        };

        all_items
    }

    // Retrieves all items with their associated prices for an array of seeds and offsets.
    // @param seeds - A Span of 128-bit unsigned integers representing unique identifiers for the seeds.
    // @param offsets - A Span of 8-bit unsigned integers representing offset values for the seeds.
    // @return An Array of LootWithPrice.
    fn get_all_items_with_price(seeds: Span<u256>, offsets: Span<u8>) -> Array<LootWithPrice> {
        let mut all_items = ArrayTrait::<LootWithPrice>::new();

        // iterate over our array of seeds
        let mut seed_index: u32 = 0;
        loop {
            // if we checked all seeds, return false
            if seed_index >= seeds.len() {
                break;
            }
            let seed = *seeds.at(seed_index);
            let offset = *offsets.at(seed_index);

            let mut item_offset: u256 = 0;
            loop {
                if item_offset >= offset.into() * NUMBER_OF_ITEMS_PER_LEVEL.into() {
                    break ();
                }

                let id = ImplMarket::get_id(seed + item_offset.into());
                all_items
                    .append(
                        LootWithPrice {
                            item: ImplLoot::get_item(id),
                            price: ImplMarket::get_price(ImplLoot::get_tier(id))
                        }
                    );
                item_offset += offset.into();
            };
            // otherwise continue to the next seed
            seed_index += 1;
        };

        all_items
    }

    // @notice Retrieves item IDs by specific slot for an array of seeds and offsets.
    // @param seeds - A Span of 128-bit unsigned integers representing unique identifiers for the seeds.
    // @param offsets - A Span of 8-bit unsigned integers representing offset values for the seeds.
    // @param slot - A Slot enum indicating the specific slot to filter by.
    // @return An Array of 8-bit unsigned integers representing item IDs.
    fn get_items_by_slot(seeds: Span<u256>, offsets: Span<u8>, slot: Slot) -> Array<u8> {
        let mut return_ids = ArrayTrait::<u8>::new();

        // iterate over our array of seeds
        let mut seed_index: u32 = 0;
        loop {
            // if we checked all seeds, return false
            if seed_index >= seeds.len() {
                break;
            }
            let seed = *seeds.at(seed_index);
            let offset = *offsets.at(seed_index);
            let mut item_offset: u256 = 0;
            loop {
                if item_offset >= offset.into() * NUMBER_OF_ITEMS_PER_LEVEL.into() {
                    break ();
                }
                let id = ImplMarket::get_id((seed + item_offset.into()));
                if (ImplLoot::get_slot(id) == slot) {
                    return_ids.append(id);
                }

                item_offset += offset.into();
            };
            seed_index += 1;
        };

        return_ids
    }

    // @notice Retrieves item IDs by specific tier for an array of seeds and offsets.
    // @param seeds - A Span of 128-bit unsigned integers representing unique identifiers for the seeds.
    // @param offsets - A Span of 8-bit unsigned integers representing offset values for the seeds.
    // @param tier - A Tier enum indicating the specific tier to filter by.
    // @return An Array of 8-bit unsigned integers representing item IDs.
    fn get_items_by_tier(seeds: Span<u256>, offsets: Span<u8>, tier: Tier) -> Array<u8> {
        let mut return_ids = ArrayTrait::<u8>::new();

        // iterate over our array of seeds
        let mut seed_index: u32 = 0;
        loop {
            // if we checked all seeds, return false
            if seed_index >= seeds.len() {
                break;
            }
            let seed = *seeds.at(seed_index);
            let offset = *offsets.at(seed_index);

            let mut item_offset: u256 = 0;
            loop {
                if item_offset >= offset.into() * NUMBER_OF_ITEMS_PER_LEVEL.into() {
                    break ();
                }
                let id = ImplMarket::get_id((seed + item_offset.into()));
                if (ImplLoot::get_tier(id) == tier) {
                    return_ids.append(id);
                }

                item_offset += offset.into();
            };
            // otherwise continue to the next seed
            seed_index += 1;
        };

        return_ids
    }

    // @notice Gets a u8 item id from a u256 seed
    // @param seed a 256-bit unsigned integer representing a unique identifier for the seed.
    // @return a u8 representing the item ID.
    fn get_id(seed: u256) -> u8 {
        let (_, item_id) = rshift_split(seed, NUM_ITEMS.into());
        1 + item_id.try_into().unwrap()
    }

    // @notice This function checks if an item is available within the provided seeds and offsets.
    // @dev The function iterates over seeds and offsets. For each seed, it checks 
    //      whether the item is available. If the item is not found in any of the seeds, 
    //      the function returns false. If the item is found, the function returns true.
    // @param seeds An array of seed values of type `u256`.
    // @param offsets An array of offset values of type `u8`.
    // @param item_id The ID of the item to be checked, of type `u8`.
    // @return A boolean value indicating whether the item is available within the seeds and offsets.
    fn is_item_available(seeds: Span<u256>, offsets: Span<u8>, item_id: u8) -> bool {
        // iterate over our array of seeds
        let mut seed_index: u32 = 0;
        loop {
            // if we checked all seeds, return false
            if seed_index >= seeds.len() {
                break false;
            }
            let seed = *seeds.at(seed_index);
            let offset = *offsets.at(seed_index);

            // for each seed check if the item is available
            let mut item_available_for_seed = false;
            let mut item_offset: u256 = 0;
            loop {
                // if we checked all items for this seed, return false

                if item_offset >= offset.into() * NUMBER_OF_ITEMS_PER_LEVEL.into() {
                    break;
                }

                // if we found the item in this seed
                if item_id == ImplMarket::get_id((seed.into() + item_offset.into())) {
                    // capture that we found the item
                    item_available_for_seed = true;
                    // and break out of this loop   
                    break;
                }
                item_offset += offset.into();
            };

            // if we found the item in this seed, return true
            if item_available_for_seed == true {
                break true;
            }

            // otherwise continue to the next seed
            seed_index += 1;
        }
    }
}

// ---------------------------
// ---------- Tests ----------
// ---------------------------
#[cfg(test)]
mod tests {
    use traits::{TryInto, Into};
    use array::{ArrayTrait, SpanTrait};
    use option::OptionTrait;
    use core::clone::Clone;

    use lootitems::{
        loot::{Loot, ILoot, ImplLoot}, statistics::{item_tier, constants::{ItemId, NUM_ITEMS}}
    };

    use combat::constants::CombatEnums::{Tier, Slot};
    use market::{
        market::ImplMarket, constants::{NUM_LOOT_ITEMS, NUMBER_OF_ITEMS_PER_LEVEL, TIER_PRICE}
    };
    use pack::pack::{rshift_split};

    const TEST_MARKET_SEED: u256 = 515;
    const TEST_OFFSET: u8 = 3;


    #[test]
    #[available_gas(50000000)]
    fn test_get_id() {
        // test bottom end of u256
        let mut i: u256 = 0;
        loop {
            if (i >= 500) {
                break;
            }
            // get market item id
            let item_id = ImplMarket::get_id(i);
            // assert item id is within range of items
            assert(item_id > 0 && item_id <= NUM_ITEMS, 'offset out of bounds');
            i += 1;
        };

        // test upper end of u256
        let mut i: u256 =
            115792089237316195423570985008687907853269984665640564039457584007913129639735;
        loop {
            if (i >= 115792089237316195423570985008687907853269984665640564039457584007913129639935) {
                break;
            }
            // get market item id
            let item_id = ImplMarket::get_id(i);
            // assert item id is within range of items
            assert(item_id > 0 && item_id <= NUM_ITEMS, 'offset out of bounds');
            i += 1;
        };
    }

    #[test]
    #[available_gas(9000000)]
    fn test_get_price() {
        let t1_price = ImplMarket::get_price(Tier::T1(()));
        assert(t1_price == (6 - 1) * TIER_PRICE, 't1 price');

        let t2_price = ImplMarket::get_price(Tier::T2(()));
        assert(t2_price == (6 - 2) * TIER_PRICE, 't2 price');

        let t3_price = ImplMarket::get_price(Tier::T3(()));
        assert(t3_price == (6 - 3) * TIER_PRICE, 't3 price');

        let t4_price = ImplMarket::get_price(Tier::T4(()));
        assert(t4_price == (6 - 4) * TIER_PRICE, 't4 price');

        let t5_price = ImplMarket::get_price(Tier::T5(()));
        assert(t5_price == (6 - 5) * TIER_PRICE, 't5 price');
    }

    #[test]
    #[available_gas(220000000)]
    fn test_get_all_items() {
        let mut market_seeds = ArrayTrait::<u256>::new();
        market_seeds.append(77);

        let mut offset = ArrayTrait::<u8>::new();
        offset.append(20);

        // get items from the market
        let market_items = ImplMarket::get_all_items(market_seeds.span(), offset.span());

        // iterate over the items
        let mut item_index = 0;
        loop {
            if item_index >= market_items.len() {
                break;
            }
            let item = *market_items.at(item_index);
            let market_items_clone = market_items.clone();

            // and verify the item is not a duplicate
            let mut duplicate_check_index = item_index + 1;
            loop {
                if duplicate_check_index >= market_items_clone.len() {
                    break;
                }
                assert(
                    item.id != *market_items_clone.at(duplicate_check_index).id, 'duplicate item id'
                );
                duplicate_check_index += 1;
            };
            item_index += 1;
        };
    }


    #[test]
    #[available_gas(22000000)]
    fn test_get_all_items_count() {
        let mut market_seeds = ArrayTrait::<u256>::new();
        market_seeds.append(1);

        let mut offset = ArrayTrait::<u8>::new();
        offset.append(3);

        let items = ImplMarket::get_all_items(market_seeds.span(), offset.span());
        assert(items.len() == NUMBER_OF_ITEMS_PER_LEVEL.into(), 'incorrect number of items');

        market_seeds.append(2);
        offset.append(5);
        let items = ImplMarket::get_all_items(market_seeds.span(), offset.span());
        assert(items.len() == NUMBER_OF_ITEMS_PER_LEVEL.into() * 2, 'incorrect number of items');

        market_seeds.append(3);
        market_seeds.append(4);
        offset.append(51);
        offset.append(101);
        let items = ImplMarket::get_all_items(market_seeds.span(), offset.span());
        assert(items.len() == NUMBER_OF_ITEMS_PER_LEVEL.into() * 4, 'incorrect number of items');
    }

    #[test]
    #[available_gas(9000000)]
    fn test_is_item_available() {
        let mut i: u256 = 0;
        let OFFSET: u8 = 3;
        loop {
            if i > OFFSET.into() * NUMBER_OF_ITEMS_PER_LEVEL.into() {
                break ();
            }

            let id = ImplMarket::get_id(TEST_MARKET_SEED + i);
            let mut seeds = ArrayTrait::<u256>::new();
            seeds.append(TEST_MARKET_SEED + i);
            let mut offsets = ArrayTrait::<u8>::new();
            offsets.append(OFFSET);

            let result = ImplMarket::is_item_available(seeds.span(), offsets.span(), id);

            assert(result == true, 'item not available');

            i += OFFSET.into();
        };
    }

    #[test]
    #[available_gas(90000000)]
    fn test_fake_check_ownership() {
        let mut i: u256 = 0;
        let OFFSET: u8 = 3;

        loop {
            if i >= OFFSET.into() * NUMBER_OF_ITEMS_PER_LEVEL.into() {
                break ();
            }

            let id = ImplMarket::get_id(TEST_MARKET_SEED + i + 2);
            let mut seeds = ArrayTrait::<u256>::new();
            seeds.append(TEST_MARKET_SEED + i);
            let mut offsets = ArrayTrait::<u8>::new();
            offsets.append(OFFSET);

            let result = ImplMarket::is_item_available(seeds.span(), offsets.span(), id);

            assert(result == false, 'item');

            i += OFFSET.into();
        };
    }

    #[test]
    #[available_gas(9000000)]
    fn test_get_all_items_ownership() {
        let mut market_seeds = ArrayTrait::<u256>::new();
        market_seeds.append(TEST_MARKET_SEED);

        let OFFSET: u8 = 3;
        let mut offset = ArrayTrait::<u8>::new();
        offset.append(OFFSET);

        let items = @ImplMarket::get_all_items(market_seeds.span(), offset.span());

        let mut i: u256 = 0;
        let mut item_index: usize = 0;

        loop {
            if i >= OFFSET.into() * NUMBER_OF_ITEMS_PER_LEVEL.into() {
                break ();
            }

            let id = *items.at(item_index).id;
            assert(id != 0, 'item id should not be 0');

            let mut seeds = ArrayTrait::<u256>::new();
            seeds.append(TEST_MARKET_SEED + i);
            let mut offsets = ArrayTrait::<u8>::new();
            offsets.append(OFFSET);

            let result = ImplMarket::is_item_available(seeds.span(), offsets.span(), id);

            assert(result == true, 'item');

            i += OFFSET.into();
            item_index += 1;
        };
    }
}
