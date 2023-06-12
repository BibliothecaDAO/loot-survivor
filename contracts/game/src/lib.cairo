#[contract]
mod Adventurer {
    use option::OptionTrait;
    use starknet::get_caller_address;
    use starknet::ContractAddress;

    use lootitems::loot::{Loot, ItemStats};
    use pack::pack::{pack_value, unpack_value, U256TryIntoU32, U256TryIntoU8};

    use survivor::adventurer::{Adventurer, AdventurerActions, Actions};
    // events

    // adventurer_update
    // adventurer_items
    // leaderboard_update

    #[event]
    fn AdventurerUpdate(owner: ContractAddress, id: u256, adventurer: Adventurer) {}

    #[storage]
    struct Storage {
        _adventurer: LegacyMap::<(ContractAddress, u256), felt252>,
        _loot: LegacyMap::<u256, felt252>,
        _counter: u256,
    // lords_address
    // dao_address
    // leaders
    }

    #[constructor]
    fn constructor() { // set items in constructor with loop
    // set beasts in constructor with loop
    // set lords _address
    // set DAO address
    }

    // @loothero
    fn start(starting_weapon: u8) {
        // TODO: check item is starting weapon
        // TODO: set adventurer metadata
        // TODO: set mint fees

        // generate new adventurer with starting weapon and beast health
        let new_adventurer: Adventurer = AdventurerActions::new(starting_weapon);

        let current_adventurer_id = _counter::read();
        let caller = get_caller_address();

        _adventurer::write((caller, current_adventurer_id), new_adventurer.pack());

        AdventurerUpdate(caller, current_adventurer_id, new_adventurer);

        _counter::write(current_adventurer_id + 1);
    }

    // @loothero
    fn explore(adventurer_id: u256) {
        let mut adventurer = _adventurer::read((get_caller_address(), adventurer_id)).unpack();

        adventurer.add_beast(100);

        _adventurer::write((get_caller_address(), adventurer_id), adventurer.pack());
    // get random explore
    // calculate discovery (beast, obstacle, item)
    // if beast -> create beast -> check ambush -> attack adventurer
    // if obstacle -> calculate obstacle dmg
    // if item -> generate random discovery (gold,xp,health)
    // if adventurer dies -> set leaderboard, kill adventurer
    }

    // @loothero
    fn attack(adventurer_id: u256) { //
    // check beast exists on Adventurer
    // calculate attack dmg
    // check if beast is dead
    // if dead -> calculate xp & gold
    // if not dead -> update beast health

    // if adventurer dies -> set leaderboard, kill adventurer
    }

    // @loothero
    fn flee(adventurer_id: u256) { // 
    // check beast exists on Adventurer
    // calculate if can flee
    // if can flee -> set beast to null
    // if can't flee -> beast counter attack
    // if adventurer dies -> set leaderboard, kill adventurer
    }

    // @loaf
    fn equip(adventurer_id: u256, item_id: u8) { // 
    // check item exists on Adventurer
    // swap with current slot if exists or just set
    }

    // @loaf
    fn buy_item(adventurer_id: u256, item_id: u8) { // 
    // check item exists on Market
    // check gold balance
    // set item on Adventurer in first free slot
    // update gold balance - item price
    }

    // @loothero
    fn upgrade_stat(adventurer_id: u256, stat_id: u8) { //
    // check can upgradable
    // upgrade stat
    // set upgrade to false
    }

    // @loothero
    fn purchase_health(adventurer_id: u256) { // 
    // check gold balance
    // update health
    // update gold - health price
    }

    // maybe deprecate??
    fn unequip(adventurer_id: u256, item_id: u8) { //
    // check item exists on Adventurer
    // 
    }
}
// #[test]
// #[available_gas(2000000)]
// fn test_component() {}

// on mint -> get random number

// on explore ->

// global seed

