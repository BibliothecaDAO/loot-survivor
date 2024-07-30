// a randomised deterministic marketplace
use traits::{TryInto, Into};
use array::{ArrayTrait, SpanTrait};
use poseidon::poseidon_hash_span;
use integer::u256_try_as_non_zero;

use loot::{loot::{Loot, ILoot, ImplLoot}, constants::{ItemId, NUM_ITEMS, NUM_ITEMS_NZ}};

use combat::constants::CombatEnums::{Tier, Slot};
use super::constants::{NUM_LOOT_ITEMS, NUMBER_OF_ITEMS_PER_LEVEL, TIER_PRICE};

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

// @dev: While we could abstract the loop in many of the functions of this class
//       we intentionally don't to provide maximum gas efficieny. For example, we could
//       provide a 'get_market_item_ids' and then have the other functions iterate over that
//       array, but that would require an additional loop and additional gas. Perhaps one of you
//       reading this will be able to find a way to abstract the loop without incurring additional
//       gas costs. If so, I look forward to seeing the associated pull request. Cheers.
#[generate_trait]
impl ImplMarket of IMarket {
    // @notice Retrieves the price associated with an item tier.
    // @param tier - A Tier enum indicating the item tier.
    // @return The price as an unsigned 16-bit integer.
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

    /// @notice Returns an array of items that are available on the market.
    /// @param seed The seed to be divided.
    /// @param market_size The size of the market.
    /// @return An array of items that are available on the market.
    fn get_available_items(seed: u64, market_size: u8) -> Array<u8> {
        if market_size >= NUM_ITEMS {
            return ImplMarket::get_all_items();
        }

        let (seed, offset) = ImplMarket::get_market_seed_and_offset(seed);

        let mut all_items = ArrayTrait::<u8>::new();
        let mut item_count: u16 = 0;
        loop {
            if item_count == market_size.into() {
                break;
            } else {
                let item_id = ImplMarket::get_id(seed + (offset.into() * item_count).into());
                all_items.append(item_id);
                item_count += 1;
            }
        };
        all_items
    }

    /// @notice Returns the size of the market based on the number of stat points available.
    /// @param stat_upgrades_available The number of stat points available to the adventurer.
    /// @return The size of the market as an unsigned 8-bit integer.
    fn get_market_size(stat_upgrades_available: u8) -> u8 {
        if stat_upgrades_available > 5 {
            NUM_ITEMS.into()
        } else {
            stat_upgrades_available * NUMBER_OF_ITEMS_PER_LEVEL
        }
    }

    /// @notice Gets a u8 item id from a u64 seed
    /// @param seed a u64 representing a unique seed.
    /// @return a u8 representing the item ID.
    fn get_id(seed: u64) -> u8 {
        (seed % NUM_ITEMS.into()).try_into().unwrap() + 1
    }

    /// @notice Checks if an item is available on the market
    /// @param inventory The inventory of the market
    /// @param item_id The item id to check for availability
    /// @return A boolean indicating if the item is available on the market.
    fn is_item_available(ref inventory: Span<u8>, item_id: u8) -> bool {
        if inventory.len() < NUM_ITEMS.into() {
            loop {
                match inventory.pop_front() {
                    Option::Some(market_item_id) => {
                        if item_id == *market_item_id {
                            break true;
                        }
                    },
                    Option::None(_) => { break false; }
                };
            }
        } else {
            true
        }
    }

    fn get_all_items() -> Array<u8> {
        let mut all_items = ArrayTrait::<u8>::new();
        all_items.append(1);
        all_items.append(2);
        all_items.append(3);
        all_items.append(4);
        all_items.append(5);
        all_items.append(6);
        all_items.append(7);
        all_items.append(8);
        all_items.append(9);
        all_items.append(10);
        all_items.append(11);
        all_items.append(12);
        all_items.append(13);
        all_items.append(14);
        all_items.append(15);
        all_items.append(16);
        all_items.append(17);
        all_items.append(18);
        all_items.append(19);
        all_items.append(20);
        all_items.append(21);
        all_items.append(22);
        all_items.append(23);
        all_items.append(24);
        all_items.append(25);
        all_items.append(26);
        all_items.append(27);
        all_items.append(28);
        all_items.append(29);
        all_items.append(30);
        all_items.append(31);
        all_items.append(32);
        all_items.append(33);
        all_items.append(34);
        all_items.append(35);
        all_items.append(36);
        all_items.append(37);
        all_items.append(38);
        all_items.append(39);
        all_items.append(40);
        all_items.append(41);
        all_items.append(42);
        all_items.append(43);
        all_items.append(44);
        all_items.append(45);
        all_items.append(46);
        all_items.append(47);
        all_items.append(48);
        all_items.append(49);
        all_items.append(50);
        all_items.append(51);
        all_items.append(52);
        all_items.append(53);
        all_items.append(54);
        all_items.append(55);
        all_items.append(56);
        all_items.append(57);
        all_items.append(58);
        all_items.append(59);
        all_items.append(60);
        all_items.append(61);
        all_items.append(62);
        all_items.append(63);
        all_items.append(64);
        all_items.append(65);
        all_items.append(66);
        all_items.append(67);
        all_items.append(68);
        all_items.append(69);
        all_items.append(70);
        all_items.append(71);
        all_items.append(72);
        all_items.append(73);
        all_items.append(74);
        all_items.append(75);
        all_items.append(76);
        all_items.append(77);
        all_items.append(78);
        all_items.append(79);
        all_items.append(80);
        all_items.append(81);
        all_items.append(82);
        all_items.append(83);
        all_items.append(84);
        all_items.append(85);
        all_items.append(86);
        all_items.append(87);
        all_items.append(88);
        all_items.append(89);
        all_items.append(90);
        all_items.append(91);
        all_items.append(92);
        all_items.append(93);
        all_items.append(94);
        all_items.append(95);
        all_items.append(96);
        all_items.append(97);
        all_items.append(98);
        all_items.append(99);
        all_items.append(100);
        all_items.append(101);
        all_items
    }

    /// @notice This function takes in a seed and returns a market seed and offset.
    /// @dev The seed is divided by the number of items to get the market seed and the remainder is the offset.
    /// @param seed The seed to be divided.
    /// @return A tuple where the first element is a u64 representing the market seed and the second element is a u8 representing the market offset.1
    fn get_market_seed_and_offset(seed: u64) -> (u64, u8) {
        let (seed, offset) = integer::u64_safe_divmod(seed, NUM_ITEMS_NZ);
        (seed, offset.try_into().unwrap())
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
    use loot::{loot::{Loot, ILoot, ImplLoot}, constants::{ItemId, NUM_ITEMS}};
    use combat::constants::CombatEnums::{Tier, Slot};
    use market::{
        market::ImplMarket, constants::{NUM_LOOT_ITEMS, NUMBER_OF_ITEMS_PER_LEVEL, TIER_PRICE}
    };
    const TEST_MARKET_SEED: u256 = 515;
    const TEST_OFFSET: u8 = 3;

    #[test]
    #[available_gas(15770)]
    fn test_is_item_available_gas() {
        let mut market_inventory = ArrayTrait::<u8>::new();
        market_inventory.append(ItemId::Wand);
        market_inventory.append(ItemId::Book);
        market_inventory.append(ItemId::Katana);
        market_inventory.append(ItemId::GhostWand);
        market_inventory.append(ItemId::DivineHood);
        market_inventory.append(ItemId::DivineSlippers);
        market_inventory.append(ItemId::DivineGloves);
        market_inventory.append(ItemId::ShortSword);
        market_inventory.append(ItemId::GoldRing);
        market_inventory.append(ItemId::Necklace);
        let mut market_inventory_span = market_inventory.span();
        assert(
            ImplMarket::is_item_available(ref market_inventory_span, ItemId::Katana),
            'item should be available'
        );
    }

    #[test]
    #[available_gas(34000000)]
    fn test_get_id() {
        // test lower end of u64
        let mut i: u64 = 0;
        loop {
            if (i == 999) {
                break;
            }
            // get market item id
            let item_id = ImplMarket::get_id(i);
            // assert item id is within range of items
            assert(item_id != 0 && item_id <= NUM_ITEMS, 'offset out of bounds');
            i += 1;
        };

        // test upper end of u64
        let mut i: u64 = 0xffffffffffffff0f;
        loop {
            if (i == 0xffffffffffffffff) {
                break;
            }
            // get market item id
            let item_id = ImplMarket::get_id(i);
            // assert item id is within range of items
            assert(item_id != 0 && item_id <= NUM_ITEMS, 'offset out of bounds');
            i += 1;
        };
    }

    #[test]
    #[available_gas(50000)]
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
    #[available_gas(33130)]
    fn test_get_available_items_gas_small_market() {
        let market_seed = 12345;
        let market_size = 1;
        ImplMarket::get_available_items(market_seed, market_size);
    }

    #[test]
    #[available_gas(309000)]
    fn test_get_available_items_gas_large_market() {
        let market_seed = 12345;
        let market_size = 50;
        ImplMarket::get_available_items(market_seed, market_size);
    }

    #[test]
    #[available_gas(21870)]
    fn test_get_available_items_gas_xlarge_market() {
        let market_seed = 12345;
        let market_size = 255;
        ImplMarket::get_available_items(market_seed, market_size);
    }

    #[test]
    #[available_gas(40550700)]
    fn test_get_available_items_check_duplicates() {
        let market_seed = 12345;
        let market_size = 100;

        // get items from the market
        let market_items = ImplMarket::get_available_items(market_seed, market_size);

        // iterate over the items
        let mut item_index = 0;
        loop {
            if item_index == market_items.len() {
                break;
            }
            let item = *market_items.at(item_index);
            let market_items_clone = market_items.clone();

            // and verify the item is not a duplicate
            let mut duplicate_check_index = item_index + 1;
            loop {
                if duplicate_check_index == market_items_clone.len() {
                    break;
                }
                assert(item != *market_items_clone.at(duplicate_check_index), 'duplicate item id');
                duplicate_check_index += 1;
            };
            item_index += 1;
        };
    }

    #[test]
    #[available_gas(4500000)]
    fn test_get_available_items_count() {
        let market_seed = 12345;
        let mut market_size = 1;

        let inventory = ImplMarket::get_available_items(market_seed, market_size);
        assert(inventory.len() == market_size.into(), 'inventory size should be 1');

        market_size = 2;
        let inventory = ImplMarket::get_available_items(market_seed, market_size);
        assert(inventory.len() == market_size.into(), 'inventory size should be 2');

        market_size = 10;
        let inventory = ImplMarket::get_available_items(market_seed, market_size);
        assert(inventory.len() == market_size.into(), 'inventory size should be 10');

        market_size = 100;
        let inventory = ImplMarket::get_available_items(market_seed, market_size);
        assert(inventory.len() == market_size.into(), 'inventory size should be 100');

        // test max u8 market size
        // should return all items which is 101 (NUM_ITEMS)
        market_size = 255;
        let inventory = ImplMarket::get_available_items(market_seed, market_size);
        assert(inventory.len() == NUM_ITEMS.into(), 'inventory size should be 101');
    }

    #[test]
    #[available_gas(15500000)]
    fn test_get_available_items_ownership() {
        let market_seed = 12345;
        let market_size = 21;

        let inventory = @ImplMarket::get_available_items(market_seed, market_size);
        assert(inventory.len() == market_size.into(), 'incorrect number of items');

        // iterate over the items on the market
        let mut item_count: u32 = 0;
        loop {
            if item_count == market_size.into() {
                break ();
            }

            // get item id and assert it's within range
            let item_id = *inventory.at(item_count.into());
            assert(item_id != 0 && item_id <= NUM_ITEMS, 'item id out of range');

            let mut inventory_span = inventory.span();

            // assert item is available on the market
            assert(ImplMarket::is_item_available(ref inventory_span, item_id), 'item');

            item_count += 1;
        };
    }

    #[test]
    #[available_gas(8000000)]
    fn test_get_available_items_ownership_multi_level8() {
        let market_seed = 12345;
        let market_size = 255;

        let inventory = @ImplMarket::get_available_items(market_seed, market_size);
        println!("inventory len: {}", inventory.len());
        assert(inventory.len() == NUM_ITEMS.into(), 'incorrect number of items');

        // iterate over the items on the market
        let mut item_count: u32 = 0;
        loop {
            if item_count == inventory.len() {
                break ();
            }

            // get item id and assert it's within range
            let item_id = *inventory.at(item_count);
            assert(item_id != 0 && item_id <= NUM_ITEMS, 'item id out of range');

            let mut inventory_span = inventory.span();

            // assert item is available on the market
            assert(
                ImplMarket::is_item_available(ref inventory_span, item_id),
                'item should be available'
            );

            item_count += 1;
        };
    }

    #[test]
    fn test_get_market_seed_and_offset() {
        let mut i: u8 = 1;
        loop {
            if (i == 255) {
                break;
            }
            let adventurer_entropy = 1;

            let (_, market_offset) = ImplMarket::get_market_seed_and_offset(adventurer_entropy);

            // assert market offset is within range of items
            assert(market_offset != 0 && market_offset < NUM_ITEMS, 'offset out of bounds');
            i += 1;
        };
    }

    #[test]
    #[available_gas(20700)]
    fn test_get_all_items_gas() {
        ImplMarket::get_all_items();
    }

    #[test]
    fn test_get_all_items() {
        let items = ImplMarket::get_all_items();
        assert(items.len() == NUM_ITEMS.into(), 'incorrect number of items');
        // verify item array contains numbers 1 through 101
        let mut item_count: u32 = 0;
        loop {
            if item_count == NUM_ITEMS.into() {
                break;
            }
            let item_id = *items.at(item_count);
            assert(item_id.into() == item_count + 1, 'item id out of range');
            item_count += 1;
        };
    }
}
