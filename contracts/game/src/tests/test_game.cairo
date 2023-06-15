use starknet::ContractAddress;
use starknet::contract_address_const;
use core::traits::Into;
use game::game::game::Game;


fn LORDS_ADDRESS() -> ContractAddress {
    contract_address_const::<10>()
}

fn DAO_ADDRESS() -> ContractAddress {
    contract_address_const::<20>()
}


fn setup() {
    Game::constructor(LORDS_ADDRESS(), DAO_ADDRESS());
}

#[test]
#[available_gas(20000000)]
fn test_constructor() { // setup();
// assert(Game::lords_address() == LORDS_ADDRESS(), 'LORDS_ADDRESS');
// assert(Game::dao_address() == DAO_ADDRESS(), 'DAO_ADDRESS');
}


#[test]
#[available_gas(20000000)]
fn test_new_adventurer() {// setup();
// Game::start(1);
// assert(Game::lords_address() == LORDS_ADDRESS(), 'LORDS_ADDRESS');
}
