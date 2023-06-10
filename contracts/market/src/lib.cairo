// randomised deterministic marketplace
use core::traits::Into;
use core::clone::Clone;

use array::ArrayTrait;
use debug::PrintTrait;
use option::OptionTrait;
use poseidon::poseidon_hash_span;

const NUMBER_OF_ITEMS_PER_LEVEL: u32 = 20;

const LOOT_ITEMS: u32 = 101;


// remove when finised
#[derive(Copy, Drop, Clone)]
struct Loot {
    id: u32, // Loot contract ID
    rank: u32,
    material: u32,
    item_type: u32,
    slot: u32,
}


trait MarketTrait {
    fn get_all_items(adventurer: felt252) -> Array<Loot>;
    fn seed(seed: felt252) -> u32;
    fn get_item(id: u32) -> Loot;
    fn get_id(seed: u32) -> u32;
    fn check_ownership(seed: u32, item: Loot) -> bool;
}

// adventurer Id
// seed

impl Market of MarketTrait {
    fn get_all_items(adventurer: felt252) -> Array<Loot> {
        let seed = Market::seed(adventurer);

        let mut a = ArrayTrait::<Loot>::new();

        let mut i: usize = 1;
        loop {
            if i > NUMBER_OF_ITEMS_PER_LEVEL {
                break ();
            }
            a.append(Market::get_item(Market::get_id(seed + i)));
            i += 1;
        };

        a
    }
    fn seed(seed: felt252) -> u32 {
        1234512 // this will be set on the Adventurer on each level upgrade
    }
    fn get_item(id: u32) -> Loot {
        // call state to get value or generate
        Loot { id: id, rank: 1, material: 1, item_type: 1, slot: 1 }
    }
    fn get_id(seed: u32) -> u32 {
        seed % LOOT_ITEMS
    }
    fn check_ownership(seed: u32, item: Loot) -> bool {
        // check called owns adventurer
        let min = seed;
        let max = seed + NUMBER_OF_ITEMS_PER_LEVEL;

        let item = Market::get_item(Market::get_id(seed));

        let mut i: usize = 0;

        let result = loop {
            if i > NUMBER_OF_ITEMS_PER_LEVEL {
                break ();
            }

            let id = Market::get_id(min + i);

            if id == item.id {
                assert(item.rank == 1, 's');
                break ();
            }

            i += 1;
        };
        true
    }
}


#[test]
#[available_gas(900000)]
fn test_get_all_items() {
    let items = Market::get_all_items(1);

    assert(items.len() == NUMBER_OF_ITEMS_PER_LEVEL, 's');
}
