use survivor::adventurer::{Adventurer, ImplAdventurer, IAdventurer};

#[starknet::interface]
trait IGame<T> {
    fn start(ref self: T, starting_weapon: u8);
    fn explore(ref self: T, adventurer_id: u256);

    fn attack(ref self: T, adventurer_id: u256);
    fn flee(ref self: T, adventurer_id: u256);
    fn equip(ref self: T, adventurer_id: u256, item_id: u8);
    fn buy_item(ref self: T, adventurer_id: u256, item_id: u8, equip: bool);
    fn upgrade_stat(ref self: T, adventurer_id: u256, stat: u8);
    fn purchase_health(ref self: T, adventurer_id: u256);

    // view functions
    fn get_adventurer(self: @T, adventurer_id: u256) -> Adventurer;
}

#[starknet::contract]
mod Game {
    use option::OptionTrait;
    use box::BoxTrait;
    use starknet::get_caller_address;
    use starknet::{ContractAddress, ContractAddressIntoFelt252};
    use integer::U64IntoFelt252;
    use core::traits::{TryInto, Into};
    use lootitems::loot::{Loot, ItemUtils};
    use pack::pack::{pack_value, unpack_value, U256TryIntoU32, U256TryIntoU8, Felt252TryIntoU64};

    use survivor::adventurer::{Adventurer, ImplAdventurer, IAdventurer};
    use survivor::bag::{Bag, BagActions, ImplBagActions};

    use market::market::{ImplMarket};

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
        // contract
        _lords: ContractAddress,
        _dao: ContractAddress
    }

    #[constructor]
    fn constructor(ref self: ContractState, lords: ContractAddress, dao: ContractAddress) {
        // set the contract addresses
        self._lords.write(lords);
        self._dao.write(dao);
    }

    // ------------------------------------------ //
    // ------------ Impl ------------------------ //
    // ------------------------------------------ //

    #[external(v0)]
    impl Game of super::IGame<ContractState> {
        fn start(ref self: ContractState, starting_weapon: u8) {
            _start(ref self, starting_weapon);
        }
        fn explore(ref self: ContractState, adventurer_id: u256) {
            _explore(ref self, adventurer_id);
        }
        fn attack(ref self: ContractState, adventurer_id: u256) {
            _attack(ref self, adventurer_id);
        }
        fn flee(ref self: ContractState, adventurer_id: u256) {
            _flee(ref self, adventurer_id);
        }
        fn equip(ref self: ContractState, adventurer_id: u256, item_id: u8) {
            _equip(ref self, adventurer_id, item_id);
        }
        fn buy_item(ref self: ContractState, adventurer_id: u256, item_id: u8, equip: bool) {
            _buy_item(ref self, adventurer_id, item_id, equip);
        }
        fn upgrade_stat(ref self: ContractState, adventurer_id: u256, stat: u8) {
            _upgrade_stat(ref self, adventurer_id, stat);
        }
        fn purchase_health(ref self: ContractState, adventurer_id: u256) {
            _purchase_health(ref self, adventurer_id);
        }

        // view functions
        fn get_adventurer(self: @ContractState, adventurer_id: u256) -> Adventurer {
            _adventurer_unpacked(self, adventurer_id)
        }
    }

    // ------------------------------------------ //
    // ------------ Internal Functions ---------- //
    // ------------------------------------------ //

    fn _start(ref self: ContractState, starting_weapon: u8) {
        // assert item is a starting weapon
        assert(
            ItemUtils::is_starting_weapon(starting_weapon) == true, 'Loot is not a starter weapon'
        );

        // generate adventurer entropy seed based on current block timestamp and caller address
        // TODO: Make this stronger by perhaps using the current block hash instead of timestamp

        // get current block timestamp and convert to felt252
        let block_info = starknet::get_block_info().unbox();
        let block_timestamp = U64IntoFelt252::into(block_info.block_timestamp);

        // get caller address and convert to felt252
        let caller_address_felt = ContractAddressIntoFelt252::into(get_caller_address());

        // combine caller address and block timestamp to create adventurer entropy seed as a u64
        let adventurer_entropy_seed = Felt252TryIntoU64::try_into(
            caller_address_felt + block_timestamp
        )
            .unwrap();

        // TODO: initialize adventurer metadata using the adventurer entropy seed

        // TODO: distribute mint fees

        // create a new adventurer with the selected starting weapon
        // and the current block number as start time
        let new_adventurer: Adventurer = ImplAdventurer::new(
            starting_weapon, block_info.block_number
        );

        // get the current adventurer id
        let current_adventurer_id = self._counter.read();

        // get the caller address
        let caller = get_caller_address();

        // emit the AdventurerUpdate event
        AdventurerUpdate(caller, current_adventurer_id, new_adventurer);

        // write the new adventurer to storage
        _pack_adventurer(ref self, current_adventurer_id, new_adventurer);

        // TODO: write adventurer meta data to storage

        // increment the adventurer counter
        self._counter.write(current_adventurer_id + 1);
    }

    // @loothero
    fn _explore(ref self: ContractState, adventurer_id: u256) {
        // get adventurer from storage and unpack
        let mut adventurer = _adventurer_unpacked(@self, adventurer_id);

        // TODO: get adventurer entropy from AdventurerMeta
        let adventurer_entropy = 1;

        // TODO: get game_entropy from storage
        let game_entropy = 1;

        // send adventurer out to explore
        // result of the explore will mutate adventurer
        adventurer.explore(adventurer_entropy, game_entropy);

        // write the updated adventurer to storage
        _pack_adventurer(ref self, adventurer_id, adventurer);
    }

    // @loothero
    fn _attack(ref self: ContractState, adventurer_id: u256) { //
    // check beast exists on Adventurer
    // calculate attack dmg
    // check if beast is dead
    // if dead -> calculate xp & gold
    // if not dead -> update beast health

    // if adventurer dies -> set leaderboard, kill adventurer
    }

    // @loothero
    fn _flee(ref self: ContractState, adventurer_id: u256) { // 
    // check beast exists on Adventurer
    // calculate if can flee
    // if can flee -> set beast to null
    // if can't flee -> beast counter attack
    // if adventurer dies -> set leaderboard, kill adventurer
    }

    // @loaf
    fn _equip(ref self: ContractState, adventurer_id: u256, item_id: u8) {
        // TODO: check ownership
        let mut adventurer = _adventurer_unpacked(@self, adventurer_id);

        let mut bag = _bag_unpacked(ref self, adventurer_id);

        let equipping_item = bag.get_item(item_id);

        // TODO: could be moved to lib
        assert(equipping_item.id > 0, 'Loot does not exist in bag');

        // check what item type exists on adventurer
        // if some exists pluck from adventurer and add to bag
        if adventurer.is_slot_free(equipping_item) == false {
            let unequipping_item = adventurer.get_item_at_slot(equipping_item);
            bag.add_item(unequipping_item);
        }

        // equip item
        adventurer.add_item(equipping_item);

        // pack and save
        _pack_adventurer(ref self, adventurer_id, adventurer);
        _pack_bag(ref self, adventurer_id, bag);
    }

    // @loaf
    // checks item exists on market according to the adventurers entropy
    // checks adventurer has enough gold
    // equips item if equip is true
    // stashes item in bag if equip is false
    fn _buy_item(ref self: ContractState, adventurer_id: u256, item_id: u8, equip: bool) {
        let mut adventurer = _adventurer_unpacked(@self, adventurer_id);

        // TODO: update to real entropy
        let entropy: u32 = 123;

        // check item exists on Market
        assert(ImplMarket::check_ownership(entropy, item_id) == true, 'Market item does not exist');

        // creates new item struct
        let item = ImplBagActions::new_item(item_id);

        // TODO: get item price based on tier 
        let item_price = 15;

        // check adventurer has enough gold
        assert(adventurer.check_gold(item_price) == true, 'Not enough gold');

        // deduct gold
        adventurer.deduct_gold(item_price);

        if equip == true {
            let unequipping_item = adventurer.get_item_at_slot(item);

            adventurer.add_item(item);

            // check if item exists
            if unequipping_item.id > 0 {
                let mut bag = _bag_unpacked(ref self, adventurer_id);
                bag.add_item(unequipping_item);

                // pack bag
                _pack_bag(ref self, adventurer_id, bag);
            }
            _pack_adventurer(ref self, adventurer_id, adventurer);
        } else {
            // add and pack bag
            let mut bag = _bag_unpacked(ref self, adventurer_id);
            bag.add_item(item);
            _pack_bag(ref self, adventurer_id, bag);

            // pack adventurer
            _pack_adventurer(ref self, adventurer_id, adventurer);
        }
    }


    // @loothero
    fn _upgrade_stat(ref self: ContractState, adventurer_id: u256, stat_id: u8) { //
    // check can upgradable
    // upgrade stat
    // set upgrade to false
    }

    // @loothero
    fn _purchase_health(ref self: ContractState, adventurer_id: u256) { // 
    // check gold balance
    // update health
    // update gold - health price
    }

    // ------------------------------------------ //
    // ------------ Helper Functions ------------ //
    // ------------------------------------------ //

    #[view]
    fn _adventurer_unpacked(self: @ContractState, adventurer_id: u256) -> Adventurer {
        ImplAdventurer::unpack(self._adventurer.read((get_caller_address(), adventurer_id)))
    }

    fn _pack_adventurer(ref self: ContractState, adventurer_id: u256, adventurer: Adventurer) {
        self._adventurer.write((get_caller_address(), adventurer_id), adventurer.pack());
    }

    fn _bag_unpacked(ref self: ContractState, adventurer_id: u256) -> Bag {
        ImplBagActions::unpack(self._bag.read(adventurer_id))
    }

    fn _pack_bag(ref self: ContractState, adventurer_id: u256, bag: Bag) {
        self._bag.write(adventurer_id, bag.pack());
    }

    #[view]
    fn lords_address(ref self: ContractState) -> ContractAddress {
        self._lords.read()
    }

    #[view]
    fn dao_address(ref self: ContractState) -> ContractAddress {
        self._dao.read()
    }
}
