#[contract]
mod Adventurer {
    use option::OptionTrait;
    use starknet::get_caller_address;
    use starknet::ContractAddress;

    use loot::loot::{Loot, ItemTrait};

    // events

    // adventurer_update
    // adventurer_items
    // leaderboard_update

    #[storage]
    struct Storage {
        adventurer: LegacyMap::<u256, u256>, 
    // lords_address
    // dao_address
    // leaders
    }

    #[constructor]
    fn constructor(_name: felt252, _address: ContractAddress) { //
    // set items in constructor with loop
    // set beasts in constructor with loop
    // set lords _address
    // set DAO address
    }

    // @loothero
    fn start(starting_weapon: u256) { //
    // get item_type
    // generate starting beast
    // create and set Adventurer with beast and item
    // mint fees etc
    }

    // @loothero
    fn explore(adventurer_id: u256) { // get random explore
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


#[test]
#[available_gas(2000000)]
fn test_component() {}
