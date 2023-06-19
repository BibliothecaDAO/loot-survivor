// a randomised deterministic marketplace for loot items
use traits::{TryInto, Into};
use core::clone::Clone;
use array::ArrayTrait;
use debug::PrintTrait;
use option::OptionTrait;

use lootitems::statistics::constants::ItemId;
use lootitems::loot::{Loot, ILoot, ImplLoot};
use lootitems::statistics::item_tier;

use combat::constants::CombatEnums::{Tier};

use super::constants::{NUM_LOOT_ITEMS, NUMBER_OF_ITEMS_PER_LEVEL, OFFSET, TIER_PRICE};

trait IMarket {
    fn get_all_items(seed: u64) -> Array<Loot>;
    fn get_id(seed: u64) -> u8;
    fn check_ownership(seed: u64, item_id: u8) -> bool;
    fn get_price(tier: Tier) -> u16;
}

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
    fn get_all_items(seed: u64) -> Array<Loot> {
        let mut all_items = ArrayTrait::<Loot>::new();

        let mut i: u64 = 0;
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
    fn get_id(seed: u64) -> u8 {
        let id: u8 = (seed % NUM_LOOT_ITEMS).try_into().unwrap();

        id
    }
    fn check_ownership(seed: u64, item_id: u8) -> bool {
        let mut i: u64 = 0;
        let result = loop {
            if i > OFFSET * NUMBER_OF_ITEMS_PER_LEVEL {
                break ();
            }

            let id = ImplMarket::get_id(seed + i);

            if item_id == id {
                break ();
            }

            assert(item_id == id, 'item does not exist');

            i += OFFSET;
        };
        true
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

    let len: u64 = items.len().into();

    assert(len == NUMBER_OF_ITEMS_PER_LEVEL, 'too many items');
}

#[test]
#[available_gas(9000000)]
fn test_check_ownership() {
    let mut seed = 123456;

    let mut i: u64 = 0;
    loop {
        if i > OFFSET * NUMBER_OF_ITEMS_PER_LEVEL {
            break ();
        }

        let id = ImplMarket::get_id(seed + i);

        let result = ImplMarket::check_ownership(seed + i, id);

        assert(result == true, 'item');

        i += OFFSET;
    };
}

#[test]
#[available_gas(9000000)]
#[should_panic(expected: ('item does not exist', ))]
fn test_fake_check_ownership() {
    let mut seed = 123456;

    let mut i: u64 = 0;
    loop {
        if i > OFFSET * NUMBER_OF_ITEMS_PER_LEVEL {
            break ();
        }

        let id = ImplMarket::get_id(seed + i + 2);

        let result = ImplMarket::check_ownership(seed + i, id);

        assert(result == false, 'item');

        i += OFFSET;
    };
}

#[test]
#[available_gas(9000000)]
fn test_get_all_items_ownership() {
    let mut seed = 123456;

    let items = @ImplMarket::get_all_items(seed);

    let mut i: u64 = 0;
    let mut item_index: usize = 0;

    loop {
        if i > OFFSET * NUMBER_OF_ITEMS_PER_LEVEL {
            break ();
        }

        let snap = items.at(item_index);

        let result = ImplMarket::check_ownership(seed + i, *snap.id);

        assert(result == true, 'item');

        i += OFFSET;
        item_index += 1;
    };
}

