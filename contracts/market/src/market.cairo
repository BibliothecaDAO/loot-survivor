// a randomised deterministic marketplace for loot items
use traits::{TryInto, Into};
use core::clone::Clone;
use array::ArrayTrait;
use option::OptionTrait;

use lootitems::statistics::constants::ItemId;
use lootitems::loot::{Loot, ILoot, ImplLoot};
use lootitems::statistics::item_tier;

use combat::constants::CombatEnums::{Tier};

use super::constants::{NUM_LOOT_ITEMS, NUMBER_OF_ITEMS_PER_LEVEL, OFFSET, TIER_PRICE};

const MARKET_SEED: u256 = 512;

#[derive(Drop, Serde)]
struct LootWithPrice {
    item: Loot,
    price: u16,
}

#[generate_trait]
impl ImplMarket of IMarket {
    fn get_price(tier: Tier) -> u16 {
        match tier {
            Tier::T1(()) => 5 * TIER_PRICE,
            Tier::T2(()) => 4 * TIER_PRICE,
            Tier::T3(()) => 3 * TIER_PRICE,
            Tier::T4(()) => 2 * TIER_PRICE,
            Tier::T5(()) => 1 * TIER_PRICE,
        }
    }

    fn get_all_items(seed: u256) -> Array<Loot> {
        let mut all_items = ArrayTrait::<Loot>::new();

        let mut i: u256 = 0;
        loop {
            if i >= OFFSET * NUMBER_OF_ITEMS_PER_LEVEL {
                break ();
            }

            // TODO: We need to move this to fetch from state - it's too gassy...
            all_items.append(ImplLoot::get_item(ImplMarket::get_id(seed + i)));
            i += OFFSET;
        };

        all_items
    }

    fn get_all_items_with_price(seed: u256) -> Array<LootWithPrice> {
        let mut all_items = ArrayTrait::<LootWithPrice>::new();

        let mut i: u256 = 0;
        loop {
            if i >= OFFSET * NUMBER_OF_ITEMS_PER_LEVEL {
                break ();
            }

            let id = ImplMarket::get_id(seed + i);

            // id.print();

            // TODO: We need to move this to fetch from state - it's too gassy...
            all_items
                .append(
                    LootWithPrice {
                        item: ImplLoot::get_item(id),
                        price: ImplMarket::get_price(
                            ImplLoot::get_tier(id)
                        )
                    }
                );
            i += OFFSET;
        };

        all_items
    }

    fn get_id(seed: u256) -> u8 {
        let cast_seed: u128 = seed.try_into().unwrap();
        (cast_seed % NUM_LOOT_ITEMS.into()).try_into().unwrap()
    }

    fn is_item_available(seed: u256, item_id: u8) -> bool {
        let mut i: u256 = 0;

        loop {
            if i >= OFFSET * NUMBER_OF_ITEMS_PER_LEVEL {
                break false;
            }

            if item_id == ImplMarket::get_id(seed + i) {
                break true;
            }

            i += OFFSET;
        }
    }
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

// TODO: This needs to be optimised - it's too gassy....
#[test]
#[available_gas(10000000)]
fn test_get_all_items() {
    let items = ImplMarket::get_all_items(1);

    let len: u256 = items.len().into();

    assert(len == NUMBER_OF_ITEMS_PER_LEVEL, 'too many items');
}

#[test]
#[available_gas(9000000)]
fn test_is_item_available() {
    let mut i: u256 = 0;
    loop {
        if i > OFFSET * NUMBER_OF_ITEMS_PER_LEVEL {
            break ();
        }

        let id = ImplMarket::get_id(MARKET_SEED + i);

        let result = ImplMarket::is_item_available(MARKET_SEED + i, id);

        assert(result == true, 'item not available');

        i += OFFSET;
    };
}

#[test]
#[available_gas(90000000)]
fn test_fake_check_ownership() {
    let mut i: u256 = 0;
    loop {
        if i >= OFFSET * NUMBER_OF_ITEMS_PER_LEVEL {
            break ();
        }

        let id = ImplMarket::get_id(MARKET_SEED + i + 2);

        let result = ImplMarket::is_item_available(MARKET_SEED + i, id);

        assert(result == false, 'item');

        i += OFFSET;
    };
}

#[test]
#[available_gas(9000000)]
fn test_get_all_items_ownership() {
    let items = @ImplMarket::get_all_items(MARKET_SEED);

    let mut i: u256 = 0;
    let mut item_index: usize = 0;

    loop {
        if i >= OFFSET * NUMBER_OF_ITEMS_PER_LEVEL {
            break ();
        }

        let id = *items.at(item_index).id;

        let result = ImplMarket::is_item_available(MARKET_SEED + i, id);

        assert(result == true, 'item');

        i += OFFSET;
        item_index += 1;
    };
}
