#[contract]
mod Adventurer {
    use option::OptionTrait;
    use box::BoxTrait;
    use starknet::get_caller_address;
    use starknet::ContractAddress;
    use lootitems::loot::{Loot, ItemUtils};
    use pack::pack::{pack_value, unpack_value, U256TryIntoU32, U256TryIntoU8};
    use survivor::adventurer::{Adventurer, AdventurerActions, Actions};

    use survivor::bag::{Bag, BagActions, ImplBagActions};

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
        _bag: LegacyMap::<u256, felt252>,
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
        // TODO: set adventurer metadata including adventurer entropy seed
        // TODO: set mint fees

        // get the current block info
        let block_info = starknet::get_block_info().unbox();

        // create a new adventurer with the selected starting weapon
        // and the current block number as start time
        let new_adventurer: Adventurer = AdventurerActions::new(
            starting_weapon, block_info.block_number
        );

        // get the current adventurer id
        let current_adventurer_id = _counter::read();

        // get the caller address
        let caller = get_caller_address();

        // emit the AdventurerUpdate event
        AdventurerUpdate(caller, current_adventurer_id, new_adventurer);

        // write the new adventurer to storage
        _adventurer::write((caller, current_adventurer_id), new_adventurer.pack());
        _counter::write(current_adventurer_id + 1);
    }

    // @loothero
    fn explore(adventurer_id: u256) {
        // get adventurer from storage and unpack
        let mut adventurer = AdventurerActions::unpack(
            _adventurer::read((get_caller_address(), adventurer_id))
        );

        // TODO: get adventurer entropy from AdventurerMeta
        let adventurer_entropy = 1;

        // TODO: get game_entropy from storage
        let game_entropy = 1;

        // send adventurer out to explore
        // result of the explore will mutate adventurer
        adventurer.explore(adventurer_entropy, game_entropy);

        // write the updated adventurer to storage
        _adventurer::write((get_caller_address(), adventurer_id), adventurer.pack());
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
    fn equip(adventurer_id: u256, item_id: u8) {
        // TODO: check ownership
        let mut adventurer = AdventurerActions::unpack(
            _adventurer::read((get_caller_address(), adventurer_id))
        );

        let mut bag = ImplBagActions::unpack(_bag::read(adventurer_id));

        let equipping_item = bag.get_item(item_id);
        // TODO: could be moved to lib
        assert(equipping_item.id > 0, 'Item does not exist in bag');

        // check what item type exists on adventurer
        // if some exists pluck from adventurer and add to bag
        if adventurer.is_slot_free(equipping_item) == false {
            let unequipping_item = adventurer.get_item_at_slot(equipping_item);
            bag.add_item(unequipping_item);
        }

        // equip item
        adventurer.add_item(equipping_item);

        // pack and save
        _adventurer::write((get_caller_address(), adventurer_id), adventurer.pack());
        _bag::write(adventurer_id, bag.pack());
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


