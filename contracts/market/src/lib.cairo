// a randomised deterministic marketplace for loot items
use traits::{TryInto, Into};
use core::clone::Clone;
use array::ArrayTrait;
use debug::PrintTrait;
use option::OptionTrait;

use lootitems::loot::{Loot, ItemTrait, ItemUtils};

const NUMBER_OF_ITEMS_PER_LEVEL: u32 = 20;
// this gives more randomness to the items generated
const OFFSET: u32 = 9636;
const LOOT_ITEMS: u32 = 101;

trait MarketTrait {
    fn get_all_items(adventurer: felt252) -> Array<Loot>;
    fn seed(seed: felt252) -> u32;
    fn get_id(seed: u32) -> u8;
    fn check_ownership(seed: u32, item_id: u8) -> bool;
}

impl Market of MarketTrait {
    fn get_all_items(adventurer: felt252) -> Array<Loot> {
        let seed = Market::seed(adventurer);

        let mut all_items = ArrayTrait::<Loot>::new();

        let mut i: usize = 0;
        loop {
            if i > OFFSET * NUMBER_OF_ITEMS_PER_LEVEL {
                break ();
            }

            // TODO: We need to move this to fetch from state - it's too gassy...
            all_items.append(ItemUtils::get_item(Market::get_id(seed + i)));
            i += OFFSET;
        };

        all_items
    }

    // this could be redudant -> we could just pass the seed directly into fns
    fn seed(seed: felt252) -> u32 {
        // TOOD: get the seed from the adventurer
        1234512
    }
    fn get_id(seed: u32) -> u8 {
        let id: u8 = (seed % LOOT_ITEMS).try_into().unwrap();

        id
    }
    fn check_ownership(seed: u32, item_id: u8) -> bool {
        let mut i: usize = 0;
        let result = loop {
            if i > OFFSET * NUMBER_OF_ITEMS_PER_LEVEL {
                break ();
            }

            let id = Market::get_id(seed + i);

            if item_id == id {
                break ();
            }

            assert(item_id == id, 'item does not exist');

            i += OFFSET;
        };
        true
    }
}


// TODO: This needs to be optimised - it's too gassy....
#[test]
#[available_gas(10000000)]
fn test_get_all_items() {
    let items = Market::get_all_items(1);

    assert(items.len() > NUMBER_OF_ITEMS_PER_LEVEL, 'too many items');
}

#[test]
#[available_gas(9000000)]
fn test_check_ownership() {
    let mut seed = Market::seed(1);

    let mut i: usize = 0;
    loop {
        if i > OFFSET * NUMBER_OF_ITEMS_PER_LEVEL {
            break ();
        }

        let id = Market::get_id(seed + i);

        let result = Market::check_ownership(seed + i, id);

        assert(result == true, 'item');

        i += OFFSET;
    };
}

#[test]
#[available_gas(9000000)]
#[should_panic(expected: ('item does not exist', ))]
fn test_fake_check_ownership() {
    let mut seed = Market::seed(1);

    let mut i: usize = 0;
    loop {
        if i > OFFSET * NUMBER_OF_ITEMS_PER_LEVEL {
            break ();
        }

        let id = Market::get_id(seed + i + 2);

        let result = Market::check_ownership(seed + i, id);

        assert(result == false, 'item');

        i += OFFSET;
    };
}


#[test]
#[available_gas(9000000)]
fn test_get_all_items_ownership() {
    let mut seed = Market::seed(1);

    let items = Market::get_all_items(1);

    let mut i: usize = 0;
    let mut item_index: usize = 0;

    loop {
        if i > OFFSET * NUMBER_OF_ITEMS_PER_LEVEL {
            break ();
        }

        let result = Market::check_ownership(seed + i, *items[item_index].id);

        assert(result == true, 'item');

        i += OFFSET;
        item_index += 1;
    };
}
