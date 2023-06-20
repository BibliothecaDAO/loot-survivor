#[starknet::contract]
mod Game {
    // TESTING CONSTS REMOVE 

    const TEST_ENTROPY: u64 = 12303548;

    use game::game::interfaces::IGame;


    const LOOT_DESCRIPTION_INDEX_1: u256 = 0;
    const LOOT_DESCRIPTION_INDEX_2: u256 = 1;

    use option::OptionTrait;
    use box::BoxTrait;
    use starknet::get_caller_address;
    use starknet::{ContractAddress, ContractAddressIntoFelt252};
    use integer::{U256TryIntoU32, U256TryIntoU8, Felt252TryIntoU64, U8IntoU16};
    use integer::U64IntoFelt252;
    use core::traits::{TryInto, Into};

    use game::game::messages::messages;

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
    use survivor::constants::adventurer_constants::{POTION_HEALTH_AMOUNT};
    use survivor::item_meta::{
        ImplLootDescription, LootDescription, ILootDescription, LootDescriptionStorage
    };

    use market::market::{ImplMarket};
    use obstacles::obstacle::{ImplObstacle};
    use combat::combat::{CombatSpec, SpecialPowers, ImplCombat};
    use combat::constants::CombatEnums;

    #[storage]
    struct Storage {
        _game_entropy: felt252,
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

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        StartGame: StartGame,
        StatUpgraded: StatUpgraded,
        DiscoverHealth: DiscoverHealth,
        DiscoverGold: DiscoverGold,
        DiscoverXP: DiscoverXP,
        DiscoverObstacle: DiscoverObstacle,
        DiscoverBeast: DiscoverBeast,
        AttackBeast: AttackBeast,
        SlayedBeast: SlayedBeast,
        FleeAttempt: FleeAttempt,
        PurchasedItem: PurchasedItem,
        EquipItem: EquipItem,
        GreatnessIncreased: GreatnessIncreased,
        ItemPrefixDiscovered: ItemPrefixDiscovered,
        ItemSuffixDiscovered: ItemSuffixDiscovered,
        PurchasedPotion: PurchasedPotion,
        NewHighScore: NewHighScore,
        AdventurerDied: AdventurerDied
    }

    #[constructor]
    fn constructor(ref self: ContractState, lords: ContractAddress, dao: ContractAddress) {
        // set the contract addresses
        self._lords.write(lords);
        self._dao.write(dao);

        _set_entropy(ref self, 1);
    }

    // ------------------------------------------ //
    // ------------ Impl ------------------------ //
    // ------------------------------------------ //

    #[external(v0)]
    impl Game of IGame<ContractState> {
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

        fn get_bag(self: @ContractState, adventurer_id: u256) -> Bag {
            _bag_unpacked(self, adventurer_id)
        }

        fn get_items_on_market(self: @ContractState, adventurer_id: u256) -> Array<Loot> {
            _get_items_on_market(self, adventurer_id)
        }

        fn get_dao_address(self: @ContractState) -> ContractAddress {
            _dao_address(self)
        }

        fn get_lords_address(self: @ContractState) -> ContractAddress {
            _lords_address(self)
        }

        fn get_entropy(self: @ContractState) -> u256 {
            _get_entropy(self)
        }

        fn set_entropy(ref self: ContractState, entropy: felt252) {
            _set_entropy(ref self, entropy)
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
            ImplLoot::is_starting_weapon(starting_weapon) == true, messages::INVALID_STARTING_WEAPON
        );

        // get current block timestamp and convert to felt252
        let block_info = starknet::get_block_info().unbox();

        // and the current block number as start time
        let new_adventurer: Adventurer = ImplAdventurer::new(
            starting_weapon, block_info.block_number
        );

        // get the current adventurer id
        let adventurer_id = self._counter.read();

        // build meta
        let adventurer_meta = AdventurerMetadata {
            name: adventurer_meta.name,
            home_realm: adventurer_meta.home_realm,
            race: adventurer_meta.race,
            order: adventurer_meta.order,
            entropy: Felt252TryIntoU64::try_into(
                ContractAddressIntoFelt252::into(caller)
                    + U64IntoFelt252::into(block_info.block_timestamp)
            )
                .unwrap()
        };

        // emit the StartGame
        __event__StartGame(
            ref self,
            AdventurerState { owner: caller, adventurer_id, adventurer: new_adventurer },
            adventurer_meta
        );

        // write the new adventurer to storage
        _pack_adventurer(ref self, adventurer_id, new_adventurer);

        // pack metadata with entropy seed
        _pack_adventurer_meta(ref self, adventurer_id, adventurer_meta);

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
        let game_entropy: u64 = _get_entropy(@self).try_into().unwrap();

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
        let adventurer_level = ImplAdventurer::get_level(adventurer);

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
            let armor = ImplAdventurer::get_item_at_slot(adventurer, obstacle.damage_location);

            // get combat spec for that item
            let armor_combat_spec = _get_combat_spec(@self, adventurer_id, armor);

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

        let mut adventurer = _adventurer_unpacked(@self, adventurer_id);

        let mut bag = _bag_unpacked(@self, adventurer_id);

        let equipping_item = bag.get_item(item_id);

        // remove item from bag
        bag.remove_item(equipping_item.id);

        // TODO: could be moved to lib
        assert(equipping_item.id > 0, messages::ITEM_NOT_IN_BAG);

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

        let mut bag = _bag_unpacked(@self, adventurer_id);

        // check item exists on Market
        // TODO: replace entropy
        assert(
            ImplMarket::check_ownership(TEST_ENTROPY, item_id) == true,
            messages::ITEM_DOES_NOT_EXIST
        );

        // get item and determine metadata slot
        let item = ImplLootDescription::get_loot_description_slot(
            adventurer, bag, ImplBagActions::new_item(item_id)
        );

        // TODO: Replace with read from state
        let item_tier = ImplLoot::get_tier(item_id);
        let item_price = ImplMarket::get_price(item_tier);

        // check adventurer has enough gold
        assert(adventurer.check_gold(item_price) == true, messages::NOT_ENOUGH_GOLD);

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


    fn _upgrade_stat(ref self: ContractState, adventurer_id: u256, stat_id: u8) {
        _assert_ownership(@self, adventurer_id);

        let mut adventurer = _adventurer_unpacked(@self, adventurer_id);

        assert(adventurer.stat_upgrade_available == 1, messages::STAT_POINT_NOT_AVAILABLE);

        adventurer.add_statistic(stat_id);
        adventurer.stat_upgrade_available == 0;

        _pack_adventurer(ref self, adventurer_id, adventurer);
    }

    // @loothero
    fn _purchase_health(ref self: ContractState, adventurer_id: u256) {
        _assert_ownership(@self, adventurer_id);

        let mut adventurer = _adventurer_unpacked(@self, adventurer_id);

        // check gold balance
        assert(
            adventurer.check_gold(adventurer.get_potion_cost()) == true, messages::NOT_ENOUGH_GOLD
        );

        // calculate cost of potion based on the Adventurers level
        adventurer.deduct_gold(adventurer.get_potion_cost());

        // TODO: We could remove the value from here altogether and have it within the function
        adventurer.add_health(POTION_HEALTH_AMOUNT);

        _pack_adventurer(ref self, adventurer_id, adventurer);
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

    fn _bag_unpacked(self: @ContractState, adventurer_id: u256) -> Bag {
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
        assert(self._owner.read(adventurer_id) == get_caller_address(), messages::NOT_OWNER);
    }

    fn _lords_address(self: @ContractState) -> ContractAddress {
        self._lords.read()
    }

    fn _dao_address(self: @ContractState) -> ContractAddress {
        self._dao.read()
    }

    fn _get_items_on_market(self: @ContractState, adventurer_id: u256) -> Array<Loot> {
        // TODO: Replace with actual seed
        ImplMarket::get_all_items(TEST_ENTROPY)
    }

    fn _get_description_index(self: @ContractState, meta_data_id: u8) -> u256 {
        if (meta_data_id <= 10) {
            return LOOT_DESCRIPTION_INDEX_1;
        } else {
            return LOOT_DESCRIPTION_INDEX_2;
        }
    }

    // _get_combat_spec returns the combat spec of an item
    // as part of this we get the item details from the loot description
    fn _get_combat_spec(
        self: @ContractState, adventurer_id: u256, item: LootStatistics
    ) -> CombatSpec {
        // get item details
        let item_details = ImplLootDescription::get_loot_description(
            _loot_description_storage_unpacked(
                self, adventurer_id, _get_description_index(self, item.metadata)
            ),
            item
        );

        // return combat spec of item
        return CombatSpec {
            tier: ImplLoot::get_tier(item.id),
            item_type: ImplLoot::get_type(item.id),
            level: U8IntoU16::into(ImplLoot::get_greatness_level(item.xp)),
            special_powers: SpecialPowers {
                prefix1: item_details.name_prefix,
                prefix2: item_details.name_suffix,
                suffix: item_details.item_suffix
            }
        };
    }

    fn _set_entropy(ref self: ContractState, entropy: felt252) {
        // TODO: Replace with actual seed
        //starknet::get_tx_info().unbox().transaction_hash.into()
        self._game_entropy.write(entropy);
    }

    fn _get_entropy(self: @ContractState) -> u256 {
        self._game_entropy.read().into()
    }

    // EVENTS ------------------------------------ //

    #[derive(Drop, Serde, starknet::Event)]
    struct AdventurerState {
        owner: ContractAddress,
        adventurer_id: u256,
        adventurer: Adventurer
    }

    #[derive(Drop, Serde, starknet::Event)]
    struct AdventurerStateWithBag {
        adventurer_state: AdventurerState,
        bag: Bag
    }

    #[derive(Drop, starknet::Event)]
    struct StartGame {
        adventurer_state: AdventurerState,
        adventurer_meta: AdventurerMetadata
    }

    #[derive(Drop, starknet::Event)]
    struct StatUpgraded {
        adventurer_state: AdventurerState,
        stat_id: u8
    }

    #[derive(Drop, starknet::Event)]
    struct DiscoverHealth {
        adventurer_state: AdventurerState,
        health_amount: u8
    }

    #[derive(Drop, starknet::Event)]
    struct DiscoverGold {
        adventurer_state: AdventurerState,
        gold_amount: u8
    }

    #[derive(Drop, starknet::Event)]
    struct DiscoverXP {
        adventurer_state: AdventurerState,
        xp_amount: u8
    }

    #[derive(Drop, starknet::Event)]
    struct DiscoverObstacle {
        adventurer_state: AdventurerState,
        obstacle_id: u8,
        obstacle_level: u8,
        dodged: bool,
        damage_taken: u8,
        xp_earned_adventurer: u8,
        xp_earned_items: u8,
    }

    #[derive(Drop, starknet::Event)]
    struct DiscoverBeast {
        adventurer_state: AdventurerState,
        beast_id: u8,
        prefix_1: u8,
        prefix_2: u8,
        beast_level: u8,
        beast_health: u8,
        ambushed: bool,
        damage_taken: u8,
    }

    #[derive(Drop, starknet::Event)]
    struct AttackBeast {
        adventurer_state: AdventurerState,
        beast_id: u8,
        prefix_1: u8,
        prefix_2: u8,
        beast_level: u8,
        beast_health: u8,
        damage_dealt: u8,
        damage_taken: u8,
    }

    #[derive(Drop, starknet::Event)]
    struct SlayedBeast {
        adventurer_state: AdventurerState,
        beast_id: u8,
        prefix_1: u8,
        prefix_2: u8,
        beast_level: u8,
        beast_health: u8,
        damage_dealt: u8,
        damage_taken: u8,
        xp_earned_adventurer: u8,
        xp_earned_items: u8,
        gold_earned: u8,
    }

    #[derive(Drop, starknet::Event)]
    struct FleeAttempt {
        adventurer_state: AdventurerState,
        beast_id: u8,
        prefix_1: u8,
        prefix_2: u8,
        beast_level: u8,
        beast_health: u8,
        damage_taken: u8,
        fled: bool,
    }

    #[derive(Drop, starknet::Event)]
    struct PurchasedItem {
        adventurer_state_with_bag: AdventurerStateWithBag,
        item_id: u8,
        cost: u8,
    }

    #[derive(Drop, starknet::Event)]
    struct EquipItem {
        adventurer_state_with_bag: AdventurerStateWithBag,
        equiped_item_id: u8,
        unequiped_item_id: u8,
    }

    #[derive(Drop, starknet::Event)]
    struct GreatnessIncreased {
        adventurer_state: AdventurerState,
        item_id: u8
    }

    #[derive(Drop, starknet::Event)]
    struct ItemPrefixDiscovered {
        adventurer_state: AdventurerState,
        item_description: LootDescription
    }

    #[derive(Drop, starknet::Event)]
    struct ItemSuffixDiscovered {
        adventurer_state: AdventurerState,
        item_description: LootDescription
    }

    #[derive(Drop, starknet::Event)]
    struct PurchasedPotion {
        adventurer_state: AdventurerState,
        health_amount: u8,
    }

    #[derive(Drop, starknet::Event)]
    struct NewHighScore {
        adventurer_state: AdventurerState,
        rank: u8, // 1-3
    }

    #[derive(Drop, starknet::Event)]
    struct AdventurerDied {
        adventurer_state: AdventurerState,
        killed_by_beast: bool,
        killed_by_obstacle: bool,
        killer_id: u8,
    }

    fn __event__StartGame(
        ref self: ContractState,
        adventurer_state: AdventurerState,
        adventurer_meta: AdventurerMetadata
    ) {
        self.emit(Event::StartGame(StartGame { adventurer_state, adventurer_meta }));
    }

    fn __event__StatUpgraded(
        ref self: ContractState, adventurer_state: AdventurerState, stat_id: u8
    ) {
        self.emit(Event::StatUpgraded(StatUpgraded { adventurer_state, stat_id }));
    }

    fn __event__DiscoverHealth(
        ref self: ContractState, adventurer_state: AdventurerState, health_amount: u8
    ) {
        self.emit(Event::DiscoverHealth(DiscoverHealth { adventurer_state, health_amount }));
    }

    fn __event__DiscoverGold(
        ref self: ContractState, adventurer_state: AdventurerState, gold_amount: u8
    ) {
        self.emit(Event::DiscoverGold(DiscoverGold { adventurer_state, gold_amount }));
    }

    fn __event__DiscoverXP(
        ref self: ContractState, adventurer_state: AdventurerState, xp_amount: u8
    ) {
        self.emit(Event::DiscoverXP(DiscoverXP { adventurer_state, xp_amount }));
    }

    fn __event__DiscoverObstacle(
        ref self: ContractState,
        adventurer_state: AdventurerState,
        obstacle_id: u8,
        obstacle_level: u8,
        dodged: bool,
        damage_taken: u8,
        xp_earned_adventurer: u8,
        xp_earned_items: u8,
    ) {
        self
            .emit(
                Event::DiscoverObstacle(
                    DiscoverObstacle {
                        adventurer_state,
                        obstacle_id,
                        obstacle_level,
                        dodged,
                        damage_taken,
                        xp_earned_adventurer,
                        xp_earned_items,
                    }
                )
            );
    }

    fn __event__DiscoverBeast(
        ref self: ContractState,
        adventurer_state: AdventurerState,
        beast_id: u8,
        prefix_1: u8,
        prefix_2: u8,
        beast_level: u8,
        beast_health: u8,
        ambushed: bool,
        damage_taken: u8,
    ) {
        self
            .emit(
                Event::DiscoverBeast(
                    DiscoverBeast {
                        adventurer_state,
                        beast_id,
                        prefix_1,
                        prefix_2,
                        beast_level,
                        beast_health,
                        ambushed,
                        damage_taken,
                    }
                )
            );
    }

    fn __event__AttackBeast(
        ref self: ContractState,
        adventurer_state: AdventurerState,
        beast_id: u8,
        prefix_1: u8,
        prefix_2: u8,
        beast_level: u8,
        beast_health: u8,
        damage_dealt: u8,
        damage_taken: u8,
    ) {
        self
            .emit(
                Event::AttackBeast(
                    AttackBeast {
                        adventurer_state,
                        beast_id,
                        prefix_1,
                        prefix_2,
                        beast_level,
                        beast_health,
                        damage_dealt,
                        damage_taken,
                    }
                )
            );
    }

    fn __event__SlayedBeast(
        ref self: ContractState,
        adventurer_state: AdventurerState,
        beast_id: u8,
        prefix_1: u8,
        prefix_2: u8,
        beast_level: u8,
        beast_health: u8,
        damage_dealt: u8,
        damage_taken: u8,
        xp_earned_adventurer: u8,
        xp_earned_items: u8,
        gold_earned: u8,
    ) {
        self
            .emit(
                Event::SlayedBeast(
                    SlayedBeast {
                        adventurer_state,
                        beast_id,
                        prefix_1,
                        prefix_2,
                        beast_level,
                        beast_health,
                        damage_dealt,
                        damage_taken,
                        xp_earned_adventurer,
                        xp_earned_items,
                        gold_earned,
                    }
                )
            );
    }

    fn __event__FleeAttempt(
        ref self: ContractState,
        adventurer_state: AdventurerState,
        beast_id: u8,
        prefix_1: u8,
        prefix_2: u8,
        beast_level: u8,
        beast_health: u8,
        damage_taken: u8,
        fled: bool,
    ) {
        self
            .emit(
                Event::FleeAttempt(
                    FleeAttempt {
                        adventurer_state,
                        beast_id,
                        prefix_1,
                        prefix_2,
                        beast_level,
                        beast_health,
                        damage_taken,
                        fled
                    }
                )
            );
    }

    fn __event_PurchasedItem(
        ref self: ContractState,
        adventurer_state_with_bag: AdventurerStateWithBag,
        item_id: u8,
        cost: u8
    ) {
        self.emit(Event::PurchasedItem(PurchasedItem { adventurer_state_with_bag, item_id, cost }));
    }

    fn __event_EquipItem(
        ref self: ContractState,
        adventurer_state_with_bag: AdventurerStateWithBag,
        equiped_item_id: u8,
        unequiped_item_id: u8,
    ) {
        self
            .emit(
                Event::EquipItem(
                    EquipItem { adventurer_state_with_bag, equiped_item_id, unequiped_item_id }
                )
            );
    }


    fn __event_GreatnessIncreased(
        ref self: ContractState, adventurer_state: AdventurerState, item_id: u8
    ) {
        self.emit(Event::GreatnessIncreased(GreatnessIncreased { adventurer_state, item_id }));
    }

    fn __event_ItemPrefixDiscovered(
        ref self: ContractState,
        adventurer_state: AdventurerState,
        item_description: LootDescription
    ) {
        self
            .emit(
                Event::ItemPrefixDiscovered(
                    ItemPrefixDiscovered { adventurer_state, item_description }
                )
            );
    }

    fn __event_ItemSuffixDiscovered(
        ref self: ContractState,
        adventurer_state: AdventurerState,
        item_description: LootDescription
    ) {
        self
            .emit(
                Event::ItemSuffixDiscovered(
                    ItemSuffixDiscovered { adventurer_state, item_description }
                )
            );
    }

    fn __event_PurchasedPotion(
        ref self: ContractState, adventurer_state: AdventurerState, health_amount: u8
    ) {
        self.emit(Event::PurchasedPotion(PurchasedPotion { adventurer_state, health_amount }));
    }

    fn __event_NewHighScore(ref self: ContractState, adventurer_state: AdventurerState, rank: u8) {
        self.emit(Event::NewHighScore(NewHighScore { adventurer_state, rank }));
    }

    fn __event_AdventurerDied(
        ref self: ContractState,
        adventurer_state: AdventurerState,
        killed_by_beast: bool,
        killed_by_obstacle: bool,
        killer_id: u8
    ) {
        self
            .emit(
                Event::AdventurerDied(
                    AdventurerDied {
                        adventurer_state, killed_by_beast, killed_by_obstacle, killer_id
                    }
                )
            );
    }
}
