// randomised deterministic marketplace
use core::traits::Into;
use core::clone::Clone;
use array::ArrayTrait;
use debug::PrintTrait;
use option::OptionTrait;


// remove when finised
#[derive(Copy, Drop, Clone)]
struct Loot {
    rank: u32,
    material: u32,
    item_type: u32,
    slot: u32,
}


trait MarketTrait {
    fn get_items(adventurer: u8) -> Array<Loot>;
}
