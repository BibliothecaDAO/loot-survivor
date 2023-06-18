use survivor::adventurer::{Adventurer, ImplAdventurer, IAdventurer};
use survivor::adventurer_meta::{AdventurerMetadata, ImplAdventurerMetadata};
use starknet::{ContractAddress};


#[starknet::interface]
trait IGame<T> {
    fn start(ref self: T, starting_weapon: u8, adventurer_meta: AdventurerMetadata);
    fn explore(ref self: T, adventurer_id: u256);
    fn attack(ref self: T, adventurer_id: u256);
    fn flee(ref self: T, adventurer_id: u256);
    fn equip(ref self: T, adventurer_id: u256, item_id: u8);
    fn buy_item(ref self: T, adventurer_id: u256, item_id: u8, equip: bool);
    fn upgrade_stat(ref self: T, adventurer_id: u256, stat: u8);
    fn purchase_health(ref self: T, adventurer_id: u256);

    // view functions
    fn get_adventurer(self: @T, adventurer_id: u256) -> Adventurer;
    fn get_adventurer_meta(self: @T, adventurer_id: u256) -> AdventurerMetadata;
    fn owner_of(self: @T, adventurer_id: u256) -> ContractAddress;
}

#[starknet::contract]
mod Game {
    const LOOT_DESCRIPTION_INDEX_1: u256 = 0;
    const LOOT_DESCRIPTION_INDEX_2: u256 = 1;

    use option::OptionTrait;
    use box::BoxTrait;
    use starknet::get_caller_address;
    use starknet::{ContractAddress, ContractAddressIntoFelt252};
    use integer::{U256TryIntoU32, U256TryIntoU8, Felt252TryIntoU64, U8IntoU16};
    use integer::U64IntoFelt252;
    use core::traits::{TryInto, Into};
    use lootitems::loot::{Loot, ImplLoot};
    use pack::pack::{pack_value, unpack_value};

    use survivor::adventurer::{Adventurer, ImplAdventurer, IAdventurer};
    use survivor::bag::{Bag, BagActions, ImplBagActions, LootStatistics};
    use survivor::adventurer_meta::{
        AdventurerMetadata, ImplAdventurerMetadata, IAdventurerMetadata
    };
    use survivor::exploration::ExploreUtils;
    use survivor::constants::discovery_constants::DiscoveryEnums::{
        ExploreResult, TreasureDiscovery
    };
    use survivor::item_meta::{
        ImplLootDescription, LootDescription, ILootDescription, LootDescriptionStorage
    };

    use market::market::{ImplMarket};
    use obstacles::obstacle::{ImplObstacle};
    use combat::combat::{CombatSpec, SpecialPowers, ImplCombat};
    use combat::constants::CombatEnums;

    // events

    // adventurer_update
    // adventurer_items
    // leaderboard_update

    #[event]
    fn AdventurerUpdate(owner: ContractAddress, id: u256, adventurer: Adventurer) {}

    #[storage]
    struct Storage {
        _adventurer: LegacyMap::<u256, felt252>,
        _owner: LegacyMap::<u256, ContractAddress>,
        _adventurer_meta: LegacyMap::<u256, felt252>,
        _loot: LegacyMap::<u256, felt252>,
        _loot_description: LegacyMap::<(u256, u256), felt252>,
        _bag: LegacyMap::<u256, felt252>,
        _counter: u256,
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
        fn start(
            ref self: ContractState, starting_weapon: u8, adventurer_meta: AdventurerMetadata
        ) {
            _start(ref self, starting_weapon, adventurer_meta);
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

        fn get_adventurer_meta(self: @ContractState, adventurer_id: u256) -> AdventurerMetadata {
            _adventurer_meta_unpacked(self, adventurer_id)
        }

        fn owner_of(self: @ContractState, adventurer_id: u256) -> ContractAddress {
            _owner_of(self, adventurer_id)
        }
    }

    // ------------------------------------------ //
    // ------------ Internal Functions ---------- //
    // ------------------------------------------ //

    fn _start(ref self: ContractState, starting_weapon: u8, adventurer_meta: AdventurerMetadata) {
        let caller = get_caller_address();

        assert(
            ImplLoot::is_starting_weapon(starting_weapon) == true, 'Loot is not a starter weapon'
        );

        // get current block timestamp and convert to felt252
        let block_info = starknet::get_block_info().unbox();

        // and the current block number as start time
        let new_adventurer: Adventurer = ImplAdventurer::new(
            starting_weapon, block_info.block_number
        );

        // get the current adventurer id
        let adventurer_id = self._counter.read();

        // emit the AdventurerUpdate event
        AdventurerUpdate(caller, adventurer_id, new_adventurer);

        // write the new adventurer to storage
        _pack_adventurer(ref self, adventurer_id, new_adventurer);

        // pack metadata with entropy seed
        _pack_adventurer_meta(
            ref self,
            adventurer_id,
            AdventurerMetadata {
                name: adventurer_meta.name,
                home_realm: adventurer_meta.home_realm,
                race: adventurer_meta.race,
                order: adventurer_meta.order,
                entropy: Felt252TryIntoU64::try_into(
                    ContractAddressIntoFelt252::into(caller)
                        + U64IntoFelt252::into(block_info.block_timestamp)
                )
                    .unwrap()
            }
        );

        // increment the adventurer counter
        self._counter.write(adventurer_id + 1);

        // set caller as owner
        self._owner.write(adventurer_id, caller);
    // TODO: distribute mint fees
    }

    // @loothero
    fn _explore(ref self: ContractState, adventurer_id: u256) {
        _assert_ownership(@self, adventurer_id);

        // get adventurer from storage and unpack
        let mut adventurer = _adventurer_unpacked(@self, adventurer_id);

        // get adventurer entropy from storage  
        let adventurer_entropy = _adventurer_meta_unpacked(@self, adventurer_id).entropy;

        // TODO: get game_entropy from storage
        let game_entropy = 1;

        // get armour based storage
        // fetch item according to obstacle location on Adventurer
        let example_item_to_replace = LootStatistics { id: 1, xp: 1, metadata: 1 };

        // withdraw from storage
        // TODO: check item even has any metadata
        if (example_item_to_replace.metadata <= 10) {
            let item = ImplLootDescription::get_loot_description(
                _loot_description_storage_unpacked(@self, adventurer_id, LOOT_DESCRIPTION_INDEX_1),
                example_item_to_replace
            );
        } else {
            let item = ImplLootDescription::get_loot_description(
                _loot_description_storage_unpacked(@self, adventurer_id, LOOT_DESCRIPTION_INDEX_2),
                example_item_to_replace
            );
        }

        let explore_result = ImplAdventurer::get_random_explore(game_entropy);
        match explore_result {
            ExploreResult::Beast(()) => {
                adventurer.beast_encounter(game_entropy);
            },
            ExploreResult::Obstacle(()) => {
                _obstacle_encounter(ref self, ref adventurer, adventurer_id, game_entropy);
            },
            ExploreResult::Treasure(()) => {
                adventurer.discover_treasure(game_entropy);
            },
        }

        // write the updated adventurer to storage
        _pack_adventurer(ref self, adventurer_id, adventurer);
    }

    fn _beast_discovery(ref self: ContractState, adventurer_id: u256) {}

    fn _obstacle_encounter(
        ref self: ContractState, ref adventurer: Adventurer, adventurer_id: u256, entropy: u64
    ) -> Adventurer {
        _assert_ownership(@self, adventurer_id);
        // get adventurer level from xp
        let adventurer_level = ImplAdventurer::get_level(adventurer.xp);

        // process obstacle encounter
        let (obstacle, dodged) = ImplObstacle::obstacle_encounter(
            adventurer_level, adventurer.intelligence, entropy
        );

        // grant equipped items and adventurer xp for the encounter
        let xp_reward = ImplObstacle::get_xp_reward(obstacle);
        adventurer.increase_adventurer_xp(xp_reward);
        adventurer.increase_item_xp(xp_reward);

        // if the obstacle was dodged, return the adventurer
        if (dodged) {
            // TODO: Generate ObstacleDodged event with obstacle details
            return adventurer;
        // if the obstacle was not dodged
        } else {
            // get item at the location the obstacle is dealing damage to
            // TODO: Clean this up
            let armor = ImplAdventurer::get_item_at_slot(adventurer, obstacle.damage_location);
            let armor_tier = ImplLoot::get_tier(armor.id);
            let armor_type = ImplLoot::get_type(armor.id);
            let item = ImplLootDescription::get_loot_description(
                _loot_description_storage_unpacked(@self, adventurer_id, LOOT_DESCRIPTION_INDEX_1),
                armor
            );
            let armor_level = ImplLoot::get_greatness_level(armor.xp);
            let armor_combat_spec = CombatSpec {
                tier: armor_tier,
                item_type: armor_type,
                level: U8IntoU16::into(armor_level),
                special_powers: SpecialPowers {
                    prefix1: item.name_prefix, prefix2: item.name_suffix, suffix: item.item_suffix
                }
            };

            // calculate damage from the obstacle
            let obstacle_damage = ImplObstacle::get_damage(obstacle, armor_combat_spec, entropy);

            // deduct the health from the adventurer
            adventurer.deduct_health(obstacle_damage);

            // TODO: Generate HitByObstacle event with obstacle details
            return adventurer;
        }
    }

    fn _treasure_discovery(ref self: ContractState, adventurer_id: u256) {}


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
        _assert_ownership(@self, adventurer_id);
        // TODO: check ownership
        let mut adventurer = _adventurer_unpacked(@self, adventurer_id);

        let mut bag = _bag_unpacked(ref self, adventurer_id);

        let equipping_item = bag.get_item(item_id);

        // TODO: could be moved to lib
        assert(equipping_item.id > 0, 'Loot does not exist in bag');

        // check what item type exists on adventurer
        // if some exists pluck from adventurer and add to bag
        if adventurer.is_slot_free(equipping_item) == false {
            let unequipping_item = adventurer
                .get_item_at_slot(ImplLoot::get_slot(equipping_item.id));
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
        _assert_ownership(@self, adventurer_id);

        let mut adventurer = _adventurer_unpacked(@self, adventurer_id);

        // TODO: Remove after testing
        // assert(adventurer.stat_upgrade_available == 1, 'Not available');

        let mut bag = _bag_unpacked(ref self, adventurer_id);

        // TODO: update to real entropy
        let entropy: u32 = 12303548;

        // check item exists on Market
        assert(ImplMarket::check_ownership(entropy, item_id) == true, 'Market item does not exist');

        // get item and determine metadata slot
        let item = ImplLootDescription::get_loot_description_slot(
            adventurer, bag, ImplBagActions::new_item(item_id)
        );

        // TODO: Replace with read from state
        let item_tier = ImplLoot::get_tier(item_id);
        let item_price = ImplMarket::get_price(item_tier);

        // check adventurer has enough gold
        assert(adventurer.check_gold(item_price) == true, 'Not enough gold');

        // deduct gold
        adventurer.deduct_gold(item_price);

        if equip == true {
            let unequipping_item = adventurer.get_item_at_slot(ImplLoot::get_slot(item.id));

            adventurer.add_item(item);

            // check if item exists
            if unequipping_item.id > 0 {
                bag.add_item(unequipping_item);

                // pack bag
                _pack_bag(ref self, adventurer_id, bag);
            }
            _pack_adventurer(ref self, adventurer_id, adventurer);
        } else {
            bag.add_item(item);

            // pack
            _pack_bag(ref self, adventurer_id, bag);
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

    fn _adventurer_unpacked(self: @ContractState, adventurer_id: u256) -> Adventurer {
        ImplAdventurer::unpack(self._adventurer.read(adventurer_id))
    }

    fn _pack_adventurer(ref self: ContractState, adventurer_id: u256, adventurer: Adventurer) {
        self._adventurer.write(adventurer_id, adventurer.pack());
    }

    fn _bag_unpacked(ref self: ContractState, adventurer_id: u256) -> Bag {
        ImplBagActions::unpack(self._bag.read(adventurer_id))
    }

    fn _pack_bag(ref self: ContractState, adventurer_id: u256, bag: Bag) {
        self._bag.write(adventurer_id, bag.pack());
    }

    fn _adventurer_meta_unpacked(self: @ContractState, adventurer_id: u256) -> AdventurerMetadata {
        ImplAdventurerMetadata::unpack(self._adventurer_meta.read(adventurer_id))
    }

    fn _pack_adventurer_meta(
        ref self: ContractState, adventurer_id: u256, adventurer_meta: AdventurerMetadata
    ) {
        self._adventurer_meta.write(adventurer_id, adventurer_meta.pack());
    }

    // we pack according to a storage index
    fn _pack_loot_description_storage(
        ref self: ContractState,
        adventurer_id: u256,
        storage_index: u256,
        loot_description_storage: LootDescriptionStorage,
    ) {
        self
            ._loot_description
            .write((adventurer_id, storage_index), loot_description_storage.pack());
    }

    fn _loot_description_storage_unpacked(
        self: @ContractState, adventurer_id: u256, storage_index: u256
    ) -> LootDescriptionStorage {
        ImplLootDescription::unpack(self._loot_description.read((adventurer_id, storage_index)))
    }

    fn _owner_of(self: @ContractState, adventurer_id: u256) -> ContractAddress {
        self._owner.read(adventurer_id)
    }

    fn _assert_ownership(self: @ContractState, adventurer_id: u256) {
        assert(self._owner.read(adventurer_id) == get_caller_address(), 'Not owner');
    }

    fn lords_address(ref self: ContractState) -> ContractAddress {
        self._lords.read()
    }

    fn dao_address(ref self: ContractState) -> ContractAddress {
        self._dao.read()
    }
}
