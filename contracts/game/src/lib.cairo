mod game;
mod tests;

#[starknet::contract]
mod Game {
    // TODO: TESTING CONFIGS 
    // ADJUST THESE BEFORE DEPLOYMENT
    const MIN_BLOCKS_FOR_GAME_ENTROPY_CHANGE: u64 = 4;
    const IDLE_PENALTY_THRESHOLD_BLOCKS: u16 = 4;
    const IDLE_DEATH_PENALTY_BLOCKS: u16 = 300;
    const MAX_STORAGE_BLOCKS: u64 = 512;
    const TEST_ENTROPY: u64 = 12303548;
    const LOOT_NAME_STORAGE_INDEX_1: u256 = 0;
    const LOOT_NAME_STORAGE_INDEX_2: u256 = 1;
    const STAT_UPGRADE_POINTS_PER_LEVEL: u8 = 1;

    use option::OptionTrait;
    use box::BoxTrait;
    use starknet::{
        get_caller_address, ContractAddress, ContractAddressIntoFelt252, contract_address_const
    };
    use integer::{
        Felt252TryIntoU64, U8IntoU16, U16IntoU64, U16IntoU128, U64IntoU128, U8IntoU128,
        U128TryIntoU8, U64IntoFelt252, U64TryIntoU16
    };
    use core::traits::{TryInto, Into};
    use array::ArrayTrait;
    use poseidon::poseidon_hash_span;

    use game::game::{
        interfaces::{IGame, IERC20Dispatcher, IERC20DispatcherTrait, IERC20LibraryDispatcher},
        constants::{
            messages, Week, WEEK_2, WEEK_4, WEEK_8, BLOCKS_IN_A_WEEK, COST_TO_PLAY, U64_MAX,
            U128_MAX
        }
    };
    use lootitems::{
        loot::{ILoot, Loot, ImplLoot}, statistics::constants::{NamePrefixLength, NameSuffixLength}
    };
    use pack::{pack::{Packing, rshift_split}, constants::{MASK_16, pow, MASK_8, MASK_BOOL, mask}};
    use survivor::{
        adventurer::{Adventurer, ImplAdventurer, IAdventurer}, adventurer_stats::Stats,
        item_primitive::ItemPrimitive, bag::{Bag, BagActions, ImplBagActions},
        adventurer_meta::AdventurerMetadata, exploration::ExploreUtils,
        constants::{
            discovery_constants::DiscoveryEnums::{ExploreResult, TreasureDiscovery},
            adventurer_constants::{POTION_HEALTH_AMOUNT, ITEM_XP_MULTIPLIER}
        },
        item_meta::{
            ImplLootItemSpecialNames, LootItemSpecialNames, ILootItemSpecialNames,
            LootItemSpecialNamesStorage
        },
        adventurer_utils::AdventurerUtils
    };
    use market::market::{ImplMarket, LootWithPrice};
    use obstacles::obstacle::{ImplObstacle, IObstacle};
    use combat::{combat::{CombatSpec, SpecialPowers, ImplCombat}, constants::CombatEnums};
    use beasts::beast::{Beast, IBeast, ImplBeast};

    #[storage]
    struct Storage {
        _game_entropy: u64,
        _last_game_entropy_block: felt252,
        _adventurer: LegacyMap::<u256, felt252>,
        _owner: LegacyMap::<u256, ContractAddress>,
        _adventurer_meta: LegacyMap::<u256, felt252>,
        _loot: LegacyMap::<u256, felt252>,
        _loot_special_names: LegacyMap::<(u256, u256), felt252>,
        _bag: LegacyMap::<u256, felt252>,
        _counter: u256,
        _lords: ContractAddress,
        _dao: ContractAddress,
        // 1,2,3 // Survivor ID
        _scoreboard: LegacyMap::<u256, u256>,
        _scores: LegacyMap::<u256, u256>,
        _genesis_block: u64,
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
        AdventurerDied: AdventurerDied,
        AdventurerLeveledUp: AdventurerLeveledUp,
        NewItemsAvailable: NewItemsAvailable,
    }

    #[constructor]
    fn constructor(ref self: ContractState, lords: ContractAddress, dao: ContractAddress) {
        // set the contract addresses
        self._lords.write(lords);
        self._dao.write(dao);

        // set the genesis block
        self._genesis_block.write(starknet::get_block_info().unbox().block_number.into());

        _set_entropy(ref self);
    }

    // ------------------------------------------ //
    // ------------ Impl ------------------------ //
    // ------------------------------------------ //

    #[external(v0)]
    impl Game of IGame<ContractState> {
        fn start(
            ref self: ContractState,
            interface_id: ContractAddress,
            starting_weapon: u8,
            adventurer_meta: AdventurerMetadata
        ) {
            // assert starting_weapon is a valid starting weapon
            assert(
                ImplLoot::is_starting_weapon(starting_weapon) == true,
                messages::INVALID_STARTING_WEAPON
            );

            let caller = get_caller_address();
            let block_number = starknet::get_block_info().unbox().block_number;

            _start(ref self, block_number, caller, starting_weapon, adventurer_meta);
            _payout(ref self, caller, block_number, interface_id);
        }
        fn explore(ref self: ContractState, adventurer_id: u256) {
            // assert caller owns adventurer
            _assert_ownership(@self, adventurer_id);

            // get item names from storage
            let mut name_storage1 = _loot_special_names_storage_unpacked(
                @self, adventurer_id, LOOT_NAME_STORAGE_INDEX_1
            );
            let mut name_storage2 = _loot_special_names_storage_unpacked(
                @self, adventurer_id, LOOT_NAME_STORAGE_INDEX_2
            );

            // get adventurer from storage and unpack
            let mut adventurer = _unpack_adventurer_apply_stat_boost(
                @self, adventurer_id, name_storage1, name_storage2
            );

            // assert adventurer is not dead
            _assert_not_dead(@self, adventurer);

            // assert adventurer does not have stat upgrades available
            _assert_no_stat_upgrades_available(@self, adventurer);

            // assert adventurer is not in battle
            _assert_not_in_battle(@self, adventurer);

            // if the adventurer hasn't exceeded idle threshold
            if !_idle_longer_than_penalty_threshold(@self, adventurer) {
                // send adventurer to go exploring
                _explore(
                    ref self, ref adventurer, adventurer_id, ref name_storage1, ref name_storage2
                );
            } else {
                // if adventurer has exceeded idle threshold
                // they receive a fixed penalty
                // TODO: Make this based on worst case scenario obstacle discovery
                adventurer.deduct_health(_idle_penalty(@self, adventurer));

                // if adventurer is dead
                if (adventurer.health == 0) {
                    // emit AdventurerDied event
                    __event_AdventurerDied(
                        ref self,
                        AdventurerState {
                            owner: self._owner.read(adventurer_id),
                            adventurer_id: adventurer_id,
                            adventurer: adventurer
                        },
                        killed_by_beast: false,
                        killed_by_obstacle: false,
                        killer_id: 0
                    );
                }
            }

            // update players last action block number
            adventurer
                .last_action =
                    U64TryIntoU16::try_into(
                        starknet::get_block_info().unbox().block_number % MAX_STORAGE_BLOCKS
                    )
                .unwrap();

            // write the resulting adventurer to storage
            _pack_adventurer_remove_stat_boost(
                ref self, adventurer_id, ref adventurer, name_storage1, name_storage2
            );
        }
        fn attack(ref self: ContractState, adventurer_id: u256) {
            // assert caller owns adventurer
            _assert_ownership(@self, adventurer_id);

            // get item names from storage
            let mut name_storage1 = _loot_special_names_storage_unpacked(
                @self, adventurer_id, LOOT_NAME_STORAGE_INDEX_1
            );
            let mut name_storage2 = _loot_special_names_storage_unpacked(
                @self, adventurer_id, LOOT_NAME_STORAGE_INDEX_2
            );

            // get adventurer from storage and unpack
            let mut adventurer = _unpack_adventurer_apply_stat_boost(
                @self, adventurer_id, name_storage1, name_storage2
            );

            // assert adventurer is not dead
            _assert_not_dead(@self, adventurer);

            // assert adventurer has a beast to attack
            _assert_in_battle(@self, adventurer);

            // pass adventurer ref into internal function
            _attack(ref self, ref adventurer, adventurer_id, ref name_storage1, ref name_storage2);

            // update players last action block number
            adventurer
                .last_action =
                    U64TryIntoU16::try_into(
                        starknet::get_block_info().unbox().block_number % MAX_STORAGE_BLOCKS
                    )
                .unwrap();

            // pack and save adventurer
            _pack_adventurer_remove_stat_boost(
                ref self, adventurer_id, ref adventurer, name_storage1, name_storage2
            );
        }
        fn flee(ref self: ContractState, adventurer_id: u256) {
            // check caller owns adventurer
            _assert_ownership(@self, adventurer_id);

            // get item names from storage
            let mut name_storage1 = _loot_special_names_storage_unpacked(
                @self, adventurer_id, LOOT_NAME_STORAGE_INDEX_1
            );
            let mut name_storage2 = _loot_special_names_storage_unpacked(
                @self, adventurer_id, LOOT_NAME_STORAGE_INDEX_2
            );

            // get adventurer from storage and unpack
            let mut adventurer = _unpack_adventurer_apply_stat_boost(
                @self, adventurer_id, name_storage1, name_storage2
            );

            // assert adventurer is not dead
            _assert_not_dead(@self, adventurer);

            // can't flee from first beast
            _assert_not_starter_beast(@self, adventurer);

            // assert adventurer has a beast to attack
            _assert_in_battle(@self, adventurer);

            // pass adventurer ref into internal function
            _flee(ref self, ref adventurer, adventurer_id);

            // update players last action block number
            adventurer
                .last_action =
                    U64TryIntoU16::try_into(
                        starknet::get_block_info().unbox().block_number % MAX_STORAGE_BLOCKS
                    )
                .unwrap();

            // pack and save adventurer
            _pack_adventurer_remove_stat_boost(
                ref self, adventurer_id, ref adventurer, name_storage1, name_storage2
            );
        }
        fn equip(ref self: ContractState, adventurer_id: u256, item_id: u8) {
            // assert caller owns adventurer
            _assert_ownership(@self, adventurer_id);

            // unpack adventurer from storage (no need to apply stat boosts)
            let mut adventurer = _unpack_adventurer(@self, adventurer_id);

            // assert adventurer is not dead
            _assert_not_dead(@self, adventurer);

            // get adventurers bag
            let mut bag = _bag_unpacked(@self, adventurer_id);

            // equip item
            _equip(ref self, adventurer_id, ref adventurer, item_id, ref bag);

            // pack and save (stat boosts weren't applied so no need to remove)
            _pack_adventurer(ref self, adventurer_id, adventurer);
            _pack_bag(ref self, adventurer_id, bag);
        }
        fn buy_item(ref self: ContractState, adventurer_id: u256, item_id: u8, equip: bool) {
            // assert caller owns adventurer
            _assert_ownership(@self, adventurer_id);

            // get item names from storage
            let mut name_storage1 = _loot_special_names_storage_unpacked(
                @self, adventurer_id, LOOT_NAME_STORAGE_INDEX_1
            );
            let mut name_storage2 = _loot_special_names_storage_unpacked(
                @self, adventurer_id, LOOT_NAME_STORAGE_INDEX_2
            );

            // unpack adventurer from storage
            let mut adventurer = _unpack_adventurer_apply_stat_boost(
                @self, adventurer_id, name_storage1, name_storage2
            );

            // assert adventurer is not dead
            _assert_not_dead(@self, adventurer);

            // assert adventurer is not in battle
            _assert_not_in_battle(@self, adventurer);

            // assert market is open
            _assert_market_is_open(@self, adventurer);

            let adventurer_entropy: u128 = _adventurer_meta_unpacked(@self, adventurer_id)
                .entropy
                .into();

            // check item is available in market
            _assert_item_is_available(
                @self, adventurer, adventurer_id, adventurer_entropy, item_id
            );

            // buy item
            _buy_item(ref self, adventurer_id, ref adventurer, item_id, equip);

            // pack and save adventurer
            _pack_adventurer_remove_stat_boost(
                ref self, adventurer_id, ref adventurer, name_storage1, name_storage2
            );
        }
        fn upgrade_stat(ref self: ContractState, adventurer_id: u256, stat: u8) {
            // assert caller owns adventurer
            _assert_ownership(@self, adventurer_id);

            // unpack adventurer from storage (no need to apply stat boosts)
            let mut adventurer = _unpack_adventurer(@self, adventurer_id);

            // assert adventurer is not dead
            _assert_not_dead(@self, adventurer);

            // assert adventurer has stat StatUpgradesAvailable available
            _assert_has_stat_upgrades_available(@self, adventurer);

            // upgrade adventurer's stat
            _upgrade_stat(ref self, adventurer_id, ref adventurer, stat);

            // pack and save (stat boosts weren't applied so no need to remove)
            _pack_adventurer(ref self, adventurer_id, adventurer);
        }
        fn buy_potion(ref self: ContractState, adventurer_id: u256) {
            // get item names from storage
            let mut name_storage1 = _loot_special_names_storage_unpacked(
                @self, adventurer_id, LOOT_NAME_STORAGE_INDEX_1
            );
            let mut name_storage2 = _loot_special_names_storage_unpacked(
                @self, adventurer_id, LOOT_NAME_STORAGE_INDEX_2
            );

            // assert caller owns adventurer
            _assert_ownership(@self, adventurer_id);

            // unpack adventurer from storage (stat boosts applied on unpacking)
            let mut adventurer = _unpack_adventurer_apply_stat_boost(
                @self, adventurer_id, name_storage1, name_storage2
            );

            // assert adventurer is not dead
            _assert_not_dead(@self, adventurer);

            // assert adventurer is not in a battle
            _assert_not_in_battle(@self, adventurer);

            // purchase health
            _buy_health(ref self, adventurer_id, ref adventurer);

            // pack and save adventurer
            _pack_adventurer_remove_stat_boost(
                ref self, adventurer_id, ref adventurer, name_storage1, name_storage2
            );
        }

        fn slay_idle_adventurer(ref self: ContractState, adventurer_id: u256) {
            // anyone can call this function so we intentinoally don't _assert_ownership
            // unpack adventurer from storage (stat boosts applied on unpacking)
            let mut adventurer = _unpack_adventurer(@self, adventurer_id);

            // assert adventurer is not dead
            _assert_not_dead(@self, adventurer);

            // assert adventurer is idle
            _assert_fatally_idle(@self, adventurer);

            // set adventurer health to 0
            adventurer.health = 0;

            // emit adventurer dead event
            // TODO: consider including caller address in event
            __event_AdventurerDied(
                ref self,
                AdventurerState {
                    owner: self._owner.read(adventurer_id),
                    adventurer_id: adventurer_id,
                    adventurer: adventurer
                },
                killed_by_beast: false,
                killed_by_obstacle: false,
                killer_id: 0
            );

            // pack and save adventurer
            _pack_adventurer(ref self, adventurer_id, adventurer);
        }

        // view functions
        fn get_adventurer(self: @ContractState, adventurer_id: u256) -> Adventurer {
            // get item names from storage
            let mut name_storage1 = _loot_special_names_storage_unpacked(
                self, adventurer_id, LOOT_NAME_STORAGE_INDEX_1
            );
            let mut name_storage2 = _loot_special_names_storage_unpacked(
                self, adventurer_id, LOOT_NAME_STORAGE_INDEX_2
            );
            // get adventurer (stat boosts automatically applied during unpacking)
            // _unpack_adventurer_apply_stat_boost(self, adventurer_id, name_storage1, name_storage2)
            _unpack_adventurer(self, adventurer_id)
        }

        fn get_adventurer_meta(self: @ContractState, adventurer_id: u256) -> AdventurerMetadata {
            _adventurer_meta_unpacked(self, adventurer_id)
        }

        fn get_bag(self: @ContractState, adventurer_id: u256) -> Bag {
            _bag_unpacked(self, adventurer_id)
        }
        fn get_equipped_weapon_names(
            self: @ContractState, adventurer_id: u256
        ) -> LootItemSpecialNames {
            let adventurer = _unpack_adventurer(self, adventurer_id);
            _get_special_names(self, adventurer_id, adventurer.weapon)
        }
        fn get_equipped_chest_names(
            self: @ContractState, adventurer_id: u256
        ) -> LootItemSpecialNames {
            let adventurer = _unpack_adventurer(self, adventurer_id);
            _get_special_names(self, adventurer_id, adventurer.chest)
        }
        fn get_equipped_head_names(
            self: @ContractState, adventurer_id: u256
        ) -> LootItemSpecialNames {
            let adventurer = _unpack_adventurer(self, adventurer_id);
            _get_special_names(self, adventurer_id, adventurer.head)
        }
        fn get_equipped_waist_names(
            self: @ContractState, adventurer_id: u256
        ) -> LootItemSpecialNames {
            let adventurer = _unpack_adventurer(self, adventurer_id);
            _get_special_names(self, adventurer_id, adventurer.waist)
        }
        fn get_equipped_foot_names(
            self: @ContractState, adventurer_id: u256
        ) -> LootItemSpecialNames {
            let adventurer = _unpack_adventurer(self, adventurer_id);
            _get_special_names(self, adventurer_id, adventurer.foot)
        }
        fn get_equipped_hand_names(
            self: @ContractState, adventurer_id: u256
        ) -> LootItemSpecialNames {
            let adventurer = _unpack_adventurer(self, adventurer_id);
            _get_special_names(self, adventurer_id, adventurer.hand)
        }
        fn get_equipped_necklace_names(
            self: @ContractState, adventurer_id: u256
        ) -> LootItemSpecialNames {
            let adventurer = _unpack_adventurer(self, adventurer_id);
            _get_special_names(self, adventurer_id, adventurer.neck)
        }
        fn get_equipped_ring_names(
            self: @ContractState, adventurer_id: u256
        ) -> LootItemSpecialNames {
            let adventurer = _unpack_adventurer(self, adventurer_id);
            _get_special_names(self, adventurer_id, adventurer.ring)
        }
        fn get_items_on_market(self: @ContractState, adventurer_id: u256) -> Array<LootWithPrice> {
            _get_items_on_market(self, adventurer_id)
        }

        fn get_potion_price(self: @ContractState, adventurer_id: u256) -> u16 {
            _get_potion_price(self, adventurer_id)
        }

        fn get_attacking_beast(self: @ContractState, adventurer_id: u256) -> Beast {
            _get_attacking_beast(self, adventurer_id)
        }

        fn get_health(self: @ContractState, adventurer_id: u256) -> u16 {
            _unpack_adventurer(self, adventurer_id).health
        }

        fn get_xp(self: @ContractState, adventurer_id: u256) -> u16 {
            _unpack_adventurer(self, adventurer_id).xp
        }

        fn get_level(self: @ContractState, adventurer_id: u256) -> u8 {
            _unpack_adventurer(self, adventurer_id).get_level()
        }

        fn get_gold(self: @ContractState, adventurer_id: u256) -> u16 {
            _unpack_adventurer(self, adventurer_id).gold
        }
        fn get_beast_health(self: @ContractState, adventurer_id: u256) -> u16 {
            _unpack_adventurer(self, adventurer_id).beast_health
        }
        fn get_stat_points_available(self: @ContractState, adventurer_id: u256) -> u8 {
            _unpack_adventurer(self, adventurer_id).stat_points_available
        }
        fn get_last_action(self: @ContractState, adventurer_id: u256) -> u16 {
            _unpack_adventurer(self, adventurer_id).last_action
        }
        fn get_weapon_greatness(self: @ContractState, adventurer_id: u256) -> u8 {
            _unpack_adventurer(self, adventurer_id).weapon.get_greatness()
        }
        fn get_chest_armor_greatness(self: @ContractState, adventurer_id: u256) -> u8 {
            _unpack_adventurer(self, adventurer_id).chest.get_greatness()
        }
        fn get_head_armor_greatness(self: @ContractState, adventurer_id: u256) -> u8 {
            _unpack_adventurer(self, adventurer_id).head.get_greatness()
        }
        fn get_waist_armor_greatness(self: @ContractState, adventurer_id: u256) -> u8 {
            _unpack_adventurer(self, adventurer_id).waist.get_greatness()
        }
        fn get_foot_armor_greatness(self: @ContractState, adventurer_id: u256) -> u8 {
            _unpack_adventurer(self, adventurer_id).foot.get_greatness()
        }
        fn get_hand_armor_greatness(self: @ContractState, adventurer_id: u256) -> u8 {
            _unpack_adventurer(self, adventurer_id).hand.get_greatness()
        }
        fn get_necklace_greatness(self: @ContractState, adventurer_id: u256) -> u8 {
            _unpack_adventurer(self, adventurer_id).neck.get_greatness()
        }
        fn get_ring_greatness(self: @ContractState, adventurer_id: u256) -> u8 {
            _unpack_adventurer(self, adventurer_id).ring.get_greatness()
        }
        fn get_base_stats(self: @ContractState, adventurer_id: u256) -> Stats {
            _unpack_adventurer(self, adventurer_id).stats
        }
        fn get_boosted_stats(self: @ContractState, adventurer_id: u256) -> Stats {
            let mut name_storage1 = _loot_special_names_storage_unpacked(
                self, adventurer_id, LOOT_NAME_STORAGE_INDEX_1
            );
            let mut name_storage2 = _loot_special_names_storage_unpacked(
                self, adventurer_id, LOOT_NAME_STORAGE_INDEX_2
            );
            _unpack_adventurer_apply_stat_boost(self, adventurer_id, name_storage1, name_storage2)
                .stats
        }
        fn get_base_strength(self: @ContractState, adventurer_id: u256) -> u8 {
            _unpack_adventurer(self, adventurer_id).stats.strength
        }
        fn get_boosted_strength(self: @ContractState, adventurer_id: u256) -> u8 {
            let mut name_storage1 = _loot_special_names_storage_unpacked(
                self, adventurer_id, LOOT_NAME_STORAGE_INDEX_1
            );
            let mut name_storage2 = _loot_special_names_storage_unpacked(
                self, adventurer_id, LOOT_NAME_STORAGE_INDEX_2
            );
            _unpack_adventurer_apply_stat_boost(self, adventurer_id, name_storage1, name_storage2)
                .stats
                .strength
        }
        fn get_base_dexterity(self: @ContractState, adventurer_id: u256) -> u8 {
            _unpack_adventurer(self, adventurer_id).stats.dexterity
        }
        fn get_boosted_dexterity(self: @ContractState, adventurer_id: u256) -> u8 {
            let mut name_storage1 = _loot_special_names_storage_unpacked(
                self, adventurer_id, LOOT_NAME_STORAGE_INDEX_1
            );
            let mut name_storage2 = _loot_special_names_storage_unpacked(
                self, adventurer_id, LOOT_NAME_STORAGE_INDEX_2
            );
            _unpack_adventurer_apply_stat_boost(self, adventurer_id, name_storage1, name_storage2)
                .stats
                .dexterity
        }
        fn get_base_vitality(self: @ContractState, adventurer_id: u256) -> u8 {
            _unpack_adventurer(self, adventurer_id).stats.vitality
        }
        fn get_boosted_vitality(self: @ContractState, adventurer_id: u256) -> u8 {
            let mut name_storage1 = _loot_special_names_storage_unpacked(
                self, adventurer_id, LOOT_NAME_STORAGE_INDEX_1
            );
            let mut name_storage2 = _loot_special_names_storage_unpacked(
                self, adventurer_id, LOOT_NAME_STORAGE_INDEX_2
            );
            _unpack_adventurer_apply_stat_boost(self, adventurer_id, name_storage1, name_storage2)
                .stats
                .vitality
        }
        fn get_base_intelligence(self: @ContractState, adventurer_id: u256) -> u8 {
            _unpack_adventurer(self, adventurer_id).stats.intelligence
        }
        fn get_boosted_intelligence(self: @ContractState, adventurer_id: u256) -> u8 {
            let mut name_storage1 = _loot_special_names_storage_unpacked(
                self, adventurer_id, LOOT_NAME_STORAGE_INDEX_1
            );
            let mut name_storage2 = _loot_special_names_storage_unpacked(
                self, adventurer_id, LOOT_NAME_STORAGE_INDEX_2
            );
            _unpack_adventurer_apply_stat_boost(self, adventurer_id, name_storage1, name_storage2)
                .stats
                .intelligence
        }
        fn get_base_wisdom(self: @ContractState, adventurer_id: u256) -> u8 {
            _unpack_adventurer(self, adventurer_id).stats.wisdom
        }
        fn get_boosted_wisdom(self: @ContractState, adventurer_id: u256) -> u8 {
            let mut name_storage1 = _loot_special_names_storage_unpacked(
                self, adventurer_id, LOOT_NAME_STORAGE_INDEX_1
            );
            let mut name_storage2 = _loot_special_names_storage_unpacked(
                self, adventurer_id, LOOT_NAME_STORAGE_INDEX_2
            );
            _unpack_adventurer_apply_stat_boost(self, adventurer_id, name_storage1, name_storage2)
                .stats
                .wisdom
        }
        fn get_base_charisma(self: @ContractState, adventurer_id: u256) -> u8 {
            _unpack_adventurer(self, adventurer_id).stats.charisma
        }
        fn get_boosted_charisma(self: @ContractState, adventurer_id: u256) -> u8 {
            let mut name_storage1 = _loot_special_names_storage_unpacked(
                self, adventurer_id, LOOT_NAME_STORAGE_INDEX_1
            );
            let mut name_storage2 = _loot_special_names_storage_unpacked(
                self, adventurer_id, LOOT_NAME_STORAGE_INDEX_2
            );
            _unpack_adventurer_apply_stat_boost(self, adventurer_id, name_storage1, name_storage2)
                .stats
                .charisma
        }
        fn get_beast_type(self: @ContractState, beast_id: u8) -> u8 {
            ImplCombat::type_to_u8(ImplBeast::get_type(beast_id))
        }

        fn get_beast_tier(self: @ContractState, beast_id: u8) -> u8 {
            ImplCombat::tier_to_u8(ImplBeast::get_tier(beast_id))
        }

        fn get_dao_address(self: @ContractState) -> ContractAddress {
            _dao_address(self)
        }

        fn get_lords_address(self: @ContractState) -> ContractAddress {
            _lords_address(self)
        }

        fn get_entropy(self: @ContractState) -> u64 {
            _get_entropy(self)
        }

        fn set_entropy(ref self: ContractState) {
            _set_entropy(ref self)
        }

        fn owner_of(self: @ContractState, adventurer_id: u256) -> ContractAddress {
            _owner_of(self, adventurer_id)
        }
    }

    // ------------------------------------------ //
    // ------------ Internal Functions ---------- //
    // ------------------------------------------ //

    fn _to_ether(amount: u256) -> u256 {
        amount * 10 ^ 18
    }

    fn _payout(
        ref self: ContractState,
        caller: ContractAddress,
        block_number: u64,
        interface: ContractAddress
    ) {
        let lords = self._lords.read();
        let genesis_block = self._genesis_block.read();

        if (BLOCKS_IN_A_WEEK + genesis_block) > block_number {
            // TODO: Update to actual Lords interface
            // burn baby
            // IERC20Dispatcher {
            //     contract_address: lords
            // }.burn_away(caller, _to_ether(COST_TO_PLAY));
            return;
        }

        let mut week = Week {
            DAO: _to_ether(WEEK_2::DAO),
            INTERFACE: _to_ether(WEEK_2::INTERFACE),
            FIRST_PLACE: _to_ether(WEEK_2::FIRST_PLACE),
            SECOND_PLACE: _to_ether(WEEK_2::SECOND_PLACE),
            THIRD_PLACE: _to_ether(WEEK_2::THIRD_PLACE)
        };

        // weeks 2-4
        if (BLOCKS_IN_A_WEEK * 4 + genesis_block) > block_number {
            week = Week {
                DAO: _to_ether(WEEK_4::DAO),
                INTERFACE: _to_ether(WEEK_4::INTERFACE),
                FIRST_PLACE: _to_ether(WEEK_4::FIRST_PLACE),
                SECOND_PLACE: _to_ether(WEEK_4::SECOND_PLACE),
                THIRD_PLACE: _to_ether(WEEK_4::THIRD_PLACE)
            }
        }

        if (BLOCKS_IN_A_WEEK * 8 + genesis_block) > block_number {
            week = Week {
                DAO: _to_ether(WEEK_8::DAO),
                INTERFACE: _to_ether(WEEK_8::INTERFACE),
                FIRST_PLACE: _to_ether(WEEK_8::FIRST_PLACE),
                SECOND_PLACE: _to_ether(WEEK_8::SECOND_PLACE),
                THIRD_PLACE: _to_ether(WEEK_8::THIRD_PLACE)
            }
        }

        // DAO
        if (week.DAO > 0) {
            IERC20Dispatcher {
                contract_address: lords
            }.transferFrom(caller, self._dao.read(), week.DAO);
        }

        // interface
        if (week.INTERFACE > 0) {
            IERC20Dispatcher {
                contract_address: lords
            }.transferFrom(caller, interface, week.INTERFACE);
        }

        // first place
        IERC20Dispatcher {
            contract_address: lords
        }.transferFrom(caller, self._owner.read(self._scoreboard.read(1)), week.FIRST_PLACE);

        // second place
        IERC20Dispatcher {
            contract_address: lords
        }.transferFrom(caller, self._owner.read(self._scoreboard.read(2)), week.SECOND_PLACE);

        // third place
        IERC20Dispatcher {
            contract_address: lords
        }.transferFrom(caller, self._owner.read(self._scoreboard.read(3)), week.THIRD_PLACE);
    }

    fn _start(
        ref self: ContractState,
        block_number: u64,
        caller: ContractAddress,
        starting_weapon: u8,
        adventurer_meta: AdventurerMetadata
    ) {
        // and the current block number as start time
        let new_adventurer: Adventurer = ImplAdventurer::new(starting_weapon, block_number);

        // get the current adventurer id - start at 1
        let adventurer_id = self._counter.read() + 1;

        let mut hash_span = ArrayTrait::<felt252>::new();
        hash_span.append(block_number.into());
        hash_span.append(adventurer_id.try_into().unwrap());

        let poseidon: felt252 = poseidon_hash_span(hash_span.span()).into();
        // let entropy: u256 = (poseidon.into() % U128_MAX.into());

        let (d, r) = rshift_split(poseidon.into(), U128_MAX.into());

        // build meta
        let adventurer_meta = AdventurerMetadata {
            name: adventurer_meta.name,
            home_realm: adventurer_meta.home_realm,
            race: adventurer_meta.race,
            entropy: r.try_into().unwrap()
        };

        // emit the StartGame
        __event__StartGame(
            ref self,
            AdventurerState { owner: caller, adventurer_id, adventurer: new_adventurer },
            adventurer_meta
        );

        // emit BeastDiscovered
        let starter_beast = ImplBeast::get_starter_beast(ImplLoot::get_type(starting_weapon));
        __event__DiscoverBeast(
            ref self,
            DiscoverBeast {
                adventurer_state: AdventurerState {
                    owner: caller, adventurer_id, adventurer: new_adventurer
                },
                seed: 0,
                id: starter_beast.id,
                level: starter_beast.combat_spec.level,
                ambushed: false,
                damage_taken: 0,
                health: starter_beast.starting_health,
                special1: starter_beast.combat_spec.special_powers.prefix1,
                special2: starter_beast.combat_spec.special_powers.prefix2,
            }
        );

        // write the new adventurer to storage
        _pack_adventurer(ref self, adventurer_id, new_adventurer);

        // pack metadata with entropy seed
        _pack_adventurer_meta(ref self, adventurer_id, adventurer_meta);

        // increment the adventurer counter
        self._counter.write(adventurer_id);

        // set caller as owner
        self._owner.write(adventurer_id, caller);
    // TODO: distribute mint fees
    }

    // _explore is called by the adventurer to explore the world
    // @param self: ContractState
    // @param adventurer: Adventurer
    // @param adventurer_id: u256
    fn _explore(
        ref self: ContractState,
        ref adventurer: Adventurer,
        adventurer_id: u256,
        ref name_storage1: LootItemSpecialNamesStorage,
        ref name_storage2: LootItemSpecialNamesStorage
    ) {
        // https://github.com/starkware-libs/cairo/issues/2942
        // internal::revoke_ap_tracking();
        // get adventurer entropy from storage
        let adventurer_entropy: u128 = _adventurer_meta_unpacked(@self, adventurer_id)
            .entropy
            .into();

        // get global game entropy
        let game_entropy = _get_entropy(@self).into();

        // use entropy sources to generate random exploration
        let exploration_entropy = _get_live_entropy(adventurer_entropy, game_entropy, adventurer);

        // get a random explore result
        let explore_result = AdventurerUtils::get_random_explore(exploration_entropy);

        match explore_result {
            ExploreResult::Beast(()) => {
                // get a seed for the beast based on adventurer stats
                // this seed needs to be fixed during the course of the battle
                // so we can use it to dynamically generate the same beast during combat
                let beast_seed: u128 = adventurer.get_beast_seed(adventurer_entropy);

                // encounter beast and check if adventurer was ambushed
                let (beast, was_ambushed) = ImplBeast::beast_encounter(
                    adventurer.get_level(),
                    adventurer.stats.wisdom,
                    NamePrefixLength,
                    NameSuffixLength,
                    beast_seed
                );

                // initialize the beast health. This is the only timeD beast.starting_health should be
                // used. In subsequent calls to attack the beast, adventurer.beast_health should be used as the persistent
                // storage of the beast health
                adventurer.beast_health = beast.starting_health;

                // initialize damage taken to zero
                let mut damage_taken = 0;

                // if adventurer was ambushed
                if (was_ambushed) {
                    // determine damage (adventurer dieing will be handled as part of the counter attack)
                    let damage_taken = _beast_counter_attack(
                        ref self,
                        ref adventurer,
                        adventurer_id,
                        CombatEnums::Slot::Chest(()),
                        beast,
                        beast_seed
                    );
                }

                // Emit Discover Beast event
                __event__DiscoverBeast(
                    ref self,
                    DiscoverBeast {
                        adventurer_state: AdventurerState {
                            owner: get_caller_address(),
                            adventurer_id: adventurer_id,
                            adventurer: adventurer
                        },
                        seed: beast_seed,
                        id: beast.id,
                        level: beast.combat_spec.level,
                        ambushed: was_ambushed,
                        damage_taken: damage_taken,
                        health: beast.starting_health,
                        special1: beast.combat_spec.special_powers.prefix1,
                        special2: beast.combat_spec.special_powers.prefix2,
                    }
                );

                // and if the adventurer is dead
                if (adventurer.health == 0) {
                    // emit adventurer died
                    // note we technically could do this inside of _beast_counter_attack but
                    // doing so would result in AdventurerDied being emitted before
                    // the DiscoverBeast for the beast that killed them.
                    __event_AdventurerDied(
                        ref self,
                        AdventurerState {
                            owner: get_caller_address(),
                            adventurer_id: adventurer_id,
                            adventurer: adventurer
                        },
                        killed_by_beast: true,
                        killed_by_obstacle: false,
                        killer_id: beast.id
                    );
                }
            },
            ExploreResult::Obstacle(()) => {
                // TODO: Generate new entropy here
                _obstacle_encounter(
                    ref self,
                    ref adventurer,
                    adventurer_id,
                    ref name_storage1,
                    ref name_storage2,
                    exploration_entropy
                );
            },
            ExploreResult::Treasure(()) => {
                // TODO: Generate new entropy here
                let (treasure_type, amount) = adventurer.discover_treasure(exploration_entropy);
                let adventurer_state = AdventurerState {
                    owner: get_caller_address(),
                    adventurer_id: adventurer_id,
                    adventurer: adventurer
                };
                match treasure_type {
                    TreasureDiscovery::Gold(()) => {
                        __event__DiscoverGold(ref self, adventurer_state, amount);
                    },
                    TreasureDiscovery::XP(()) => {
                        __event__DiscoverXP(ref self, adventurer_state, amount);
                    },
                    TreasureDiscovery::Health(()) => {
                        __event__DiscoverHealth(ref self, adventurer_state, amount);
                    },
                }
            },
        }
    }

    //fn _beast_discovery(ref self: ContractState, adventurer_id: u256) {}

    fn _obstacle_encounter(
        ref self: ContractState,
        ref adventurer: Adventurer,
        adventurer_id: u256,
        ref name_storage1: LootItemSpecialNamesStorage,
        ref name_storage2: LootItemSpecialNamesStorage,
        entropy: u128
    ) -> Adventurer {
        // https://github.com/starkware-libs/cairo/issues/2942
        // internal::revoke_ap_tracking();
        // delegate obstacle encounter to obstacle library
        let (obstacle, dodged) = ImplObstacle::obstacle_encounter(
            adventurer.get_level(), adventurer.stats.intelligence, entropy
        );

        // get the xp reward for the obstacle
        let xp_reward = obstacle.get_xp_reward();

        // reward adventurer with xp (regarldess of obstacle outcome)
        let (previous_level, new_level) = adventurer.increase_adventurer_xp(xp_reward);
        if (new_level > previous_level) {
            _handle_adventurer_level_up(
                ref self, ref adventurer, adventurer_id, previous_level, new_level
            );
        }

        // allocate XP to equipped items
        _grant_xp_to_equipped_items(
            ref self,
            adventurer_id,
            ref adventurer,
            ref name_storage1,
            ref name_storage2,
            xp_reward,
            entropy
        );

        let mut damage_taken: u16 = 0;
        let mut damage_location: u8 = 0;

        // if the obstacle was not dodged
        if (!dodged) {
            // get adventurer armor at the random location the obstacle is dealing damage to
            let damage_slot = AdventurerUtils::get_random_armor_slot(entropy);
            let damage_location = ImplCombat::slot_to_u8(damage_slot);
            let armor = adventurer.get_item_at_slot(damage_slot);

            // get combat spec for that item
            let armor_combat_spec = _get_combat_spec(@self, adventurer_id, armor);

            // calculate damage from the obstacle
            damage_taken = ImplObstacle::get_damage(obstacle, armor_combat_spec, entropy);

            // deduct the health from the adventurer
            adventurer.deduct_health(damage_taken);
        }

        let adventurer_state = AdventurerState {
            owner: get_caller_address(), adventurer_id: adventurer_id, adventurer: adventurer
        };

        // emit obstacle discover event
        __event__DiscoverObstacle(
            ref self,
            DiscoverObstacle {
                adventurer_state: adventurer_state,
                id: obstacle.id,
                level: obstacle.combat_specs.level,
                dodged: dodged,
                damage_taken: damage_taken,
                damage_location: damage_location,
                xp_earned_adventurer: xp_reward,
                xp_earned_items: xp_reward * ITEM_XP_MULTIPLIER,
            }
        );

        // if obstacle killed adventurer
        if (adventurer.health == 0) {
            // emit adventurer died event
            __event_AdventurerDied(
                ref self,
                AdventurerState {
                    owner: get_caller_address(),
                    adventurer_id: adventurer_id,
                    adventurer: adventurer
                },
                killed_by_beast: false,
                killed_by_obstacle: true,
                killer_id: obstacle.id
            );
        }

        return adventurer;
    }

    // @title Handle Item Leveling Events
    // @notice This function handles the various events that may occur when an item levels up.
    // @dev This function should only be called internally within the smart contract.
    //
    // @param self A reference to the ContractState. This function requires mutable access to the ContractState to handle item leveling events.
    // @param adventurer The Adventurer object representing the adventurer who owns the item.
    // @param adventurer_id The unique identifier for the adventurer who owns the item.
    // @param item_id The unique identifier for the item that may level up.
    // @param previous_level The previous level of the item before it possibly leveled up.
    // @param new_level The new level of the item after it possibly leveled up.
    // @param suffix_assigned A boolean indicating whether a suffix was assigned to the item when it leveled up.
    // @param prefixes_assigned A boolean indicating whether a prefix was assigned to the item when it leveled up.
    // @param special_names The LootItemSpecialNames object storing the special names for the item.
    //
    // The function first checks if the item's new level is higher than its previous level. If it is, it generates a 'GreatnessIncreased' event.
    // The function then checks if a suffix was assigned to the item when it leveled up. If it was, it generates an 'ItemSuffixDiscovered' event.
    // Lastly, the function checks if a prefix was assigned to the item when it leveled up. If it was, it generates an 'ItemPrefixDiscovered' event.
    fn handle_item_leveling_events(
        ref self: ContractState,
        adventurer: Adventurer,
        adventurer_id: u256,
        item_id: u8,
        previous_level: u8,
        new_level: u8,
        suffix_assigned: bool,
        prefixes_assigned: bool,
        special_names: LootItemSpecialNames
    ) {
        // https://github.com/starkware-libs/cairo/issues/2942
        // internal::revoke_ap_tracking();
        // if the new level is higher than the previous level
        if (new_level > previous_level) {
            // generate greatness increased event
            __event_GreatnessIncreased(
                ref self,
                AdventurerState {
                    owner: get_caller_address(),
                    adventurer_id: adventurer_id,
                    adventurer: adventurer
                },
                item_id,
                previous_level,
                new_level
            );

            // if item suffix was assigned
            if (suffix_assigned) {
                // generate item suffix discovered event
                __event_ItemSuffixDiscovered(
                    ref self,
                    AdventurerState {
                        owner: get_caller_address(),
                        adventurer_id: adventurer_id,
                        adventurer: adventurer
                    },
                    special_names
                );
            }

            // if item prefixes were assigned
            if (prefixes_assigned) {
                // generate item prefix discovered event
                __event_ItemPrefixDiscovered(
                    ref self,
                    AdventurerState {
                        owner: get_caller_address(),
                        adventurer_id: adventurer_id,
                        adventurer: adventurer
                    },
                    special_names
                );
            }
        }
    }

    /// @title Grant XP to Equipped Items
    /// @notice This function handles the process of granting experience (XP) to all the equipped items of an adventurer.
    /// @dev This function should only be called internally within the smart contract.
    ///
    /// @param self A reference to the ContractState. This function requires mutable access to the ContractState to update the adventurer's equipped items' XP.
    /// @param adventurer_id The unique identifier for the adventurer whose equipped items will be updated.
    /// @param adventurer A reference to the Adventurer object. This object represents the adventurer whose equipped items' XP will be updated.
    /// @param value The amount of experience points to be added to the equipped items before applying the item XP multiplier.
    /// @param entropy An unsigned integer used for entropy generation. This is often derived from a source of randomness.
    ///
    /// The function first retrieves the names of the special items an adventurer may possess. It then calculates the XP increase by applying a multiplier to the provided 'value'.
    /// The function then checks each item slot (weapon, chest, head, waist, foot, hand, neck, ring) of the adventurer to see if an item is equipped (item ID > 0).
    /// If an item is equipped, it calls `_grant_xp_to_item_and_emit_event` to apply the XP increase to the item and handle any resulting events.
    fn _grant_xp_to_equipped_items(
        ref self: ContractState,
        adventurer_id: u256,
        ref adventurer: Adventurer,
        ref name_storage1: LootItemSpecialNamesStorage,
        ref name_storage2: LootItemSpecialNamesStorage,
        value: u16,
        entropy: u128
    ) {
        // https://github.com/starkware-libs/cairo/issues/2942
        // internal::revoke_ap_tracking();
        let xp_increase = value * ITEM_XP_MULTIPLIER;

        // if weapon is equipped
        if adventurer.weapon.id > 0 {
            // grant xp and handle any resulting events
            _grant_xp_to_item_and_emit_event(
                ref self,
                adventurer_id,
                ref adventurer,
                ref adventurer.weapon,
                xp_increase,
                ref name_storage1,
                ref name_storage2,
                entropy
            );
        }
        // if chest armor is equipped
        if adventurer.chest.id > 0 {
            // grant xp and handle any resulting events
            _grant_xp_to_item_and_emit_event(
                ref self,
                adventurer_id,
                ref adventurer,
                ref adventurer.chest,
                xp_increase,
                ref name_storage1,
                ref name_storage2,
                entropy
            );
        }
        // if head armor is equipped
        if adventurer.head.id > 0 {
            // grant xp and handle any resulting events
            _grant_xp_to_item_and_emit_event(
                ref self,
                adventurer_id,
                ref adventurer,
                ref adventurer.head,
                xp_increase,
                ref name_storage1,
                ref name_storage2,
                entropy
            );
        }
        // if waist armor is equipped
        if adventurer.waist.id > 0 {
            // grant xp and handle any resulting events
            _grant_xp_to_item_and_emit_event(
                ref self,
                adventurer_id,
                ref adventurer,
                ref adventurer.waist,
                xp_increase,
                ref name_storage1,
                ref name_storage2,
                entropy
            );
        }
        // if foot armor is equipped
        if adventurer.foot.id > 0 {
            // grant xp and handle any resulting events
            _grant_xp_to_item_and_emit_event(
                ref self,
                adventurer_id,
                ref adventurer,
                ref adventurer.foot,
                xp_increase,
                ref name_storage1,
                ref name_storage2,
                entropy
            );
        }
        // if hand armor is equipped
        if adventurer.hand.id > 0 {
            // grant xp and handle any resulting events
            _grant_xp_to_item_and_emit_event(
                ref self,
                adventurer_id,
                ref adventurer,
                ref adventurer.hand,
                xp_increase,
                ref name_storage1,
                ref name_storage2,
                entropy
            );
        }
        // if neck armor is equipped
        if adventurer.neck.id > 0 {
            // grant xp and handle any resulting events
            _grant_xp_to_item_and_emit_event(
                ref self,
                adventurer_id,
                ref adventurer,
                ref adventurer.neck,
                xp_increase,
                ref name_storage1,
                ref name_storage2,
                entropy
            );
        }
        // if ring is equipped
        if adventurer.ring.id > 0 {
            // grant xp and handle any resulting events
            _grant_xp_to_item_and_emit_event(
                ref self,
                adventurer_id,
                ref adventurer,
                ref adventurer.ring,
                xp_increase,
                ref name_storage1,
                ref name_storage2,
                entropy
            );
        }
    }

    // @title Grant XP to Item and Emit Event
    // @notice This function grants experience (XP) to a specified item and emits any resulting events.
    // @dev This function should only be called internally within the smart contract.
    //
    // @param self A reference to the ContractState. This function requires mutable access to the ContractState to update the specified item's XP.
    // @param adventurer_id The unique identifier for the adventurer who owns the item.
    // @param adventurer A reference to the Adventurer object. This object represents the adventurer who owns the item.
    // @param item A reference to the ItemPrimitive object. This object represents the item to which XP will be granted.
    // @param amount The amount of experience points to be added to the item before applying the item XP multiplier.
    // @param name_storage1 A reference to the LootItemSpecialNamesStorage object. This object stores the special names for items that an adventurer may possess.
    // @param name_storage2 A reference to the LootItemSpecialNamesStorage object. This object stores the special names for items that an adventurer may possess.
    // @param entropy An unsigned integer used for entropy generation. This is often derived from a source of randomness.
    //
    // The function first calculates the XP increase by applying a multiplier to the provided 'amount'.
    // It then checks the description index of the item. If the index matches with LOOT_NAME_STORAGE_INDEX_1, it uses name_storage1 for the item's special names; otherwise, it uses name_storage2.
    // It then calls `increase_item_xp` on the item to apply the XP increase and retrieve data about the item's original level, new level, and whether a suffix or prefix was assigned, and the item's special names.
    // Lastly, it calls `handle_item_leveling_events` to handle any events resulting from the item leveling up.
    fn _grant_xp_to_item_and_emit_event(
        ref self: ContractState,
        adventurer_id: u256,
        ref adventurer: Adventurer,
        ref item: ItemPrimitive,
        xp_increase: u16,
        ref name_storage1: LootItemSpecialNamesStorage,
        ref name_storage2: LootItemSpecialNamesStorage,
        entropy: u128
    ) {
        // https://github.com/starkware-libs/cairo/issues/2942
        internal::revoke_ap_tracking();

        if (_get_storage_index(@self, item.metadata) == LOOT_NAME_STORAGE_INDEX_1) {
            let (original_level, new_level, suffix_assigned, prefix_assigned, special_names) = item
                .increase_item_xp(xp_increase, ref name_storage1, entropy);

            handle_item_leveling_events(
                ref self,
                adventurer,
                adventurer_id,
                item.id,
                original_level,
                new_level,
                suffix_assigned,
                prefix_assigned,
                special_names
            );
        } else {
            let (original_level, new_level, suffix_assigned, prefix_assigned, special_names) = item
                .increase_item_xp(xp_increase, ref name_storage2, entropy);
            handle_item_leveling_events(
                ref self,
                adventurer,
                adventurer_id,
                item.id,
                original_level,
                new_level,
                suffix_assigned,
                prefix_assigned,
                special_names
            );
        }
    }


    fn _attack(
        ref self: ContractState,
        ref adventurer: Adventurer,
        adventurer_id: u256,
        ref name_storage1: LootItemSpecialNamesStorage,
        ref name_storage2: LootItemSpecialNamesStorage
    ) {
        // https://github.com/starkware-libs/cairo/issues/2942
        // internal::revoke_ap_tracking();
        // get adventurer entropy from storage
        let adventurer_entropy: u128 = _adventurer_meta_unpacked(@self, adventurer_id)
            .entropy
            .into();

        // get beast seed based on adventurer state and adventurer entropy
        let beast_seed: u128 = adventurer.get_beast_seed(adventurer_entropy);

        // regenerate beast from seed
        let beast = ImplBeast::get_beast(
            adventurer.get_level(),
            ImplBeast::get_special_names(
                adventurer.get_level(), beast_seed, NamePrefixLength.into(), NameSuffixLength.into()
            ),
            beast_seed,
            ImplLoot::get_type(adventurer.weapon.id)
        );

        // get game entropy from storage
        let game_entropy: u128 = _get_entropy(@self).into();

        // When generating the beast, we need to ensure entropy remains fixed for the battle
        // for attacking however, we should change the entropy during battle so we use adventurer and beast health
        // to accomplish this
        let attack_entropy = game_entropy
            + adventurer_entropy
            + U16IntoU128::into(adventurer.health + adventurer.beast_health);

        let damage_dealt = beast
            .attack(
                _get_combat_spec(@self, adventurer_id, adventurer.weapon),
                adventurer.get_luck(),
                adventurer.stats.strength,
                attack_entropy
            );
        // if the amount of damage dealt to beast exceeds its health
        if (damage_dealt >= adventurer.beast_health) {
            // the beast is dead so set health to zero
            adventurer.beast_health = 0;

            // grant equipped items and adventurer xp for the encounter
            let xp_earned = beast.get_xp_reward();

            // grant adventuer xp
            let (previous_level, new_level) = adventurer.increase_adventurer_xp(xp_earned);

            // if adventurers new level is greater than previous level
            if (new_level > previous_level) {
                _handle_adventurer_level_up(
                    ref self, ref adventurer, adventurer_id, previous_level, new_level
                );
            }

            // grant equipped items xp
            _grant_xp_to_equipped_items(
                ref self,
                adventurer_id,
                ref adventurer,
                ref name_storage1,
                ref name_storage2,
                xp_earned,
                attack_entropy
            );

            // grant adventurer gold reward. We use battle fixed entropy
            // to fix this result at the start of the battle, mitigating simulate-and-wait strategies
            let gold_reward = beast.get_gold_reward(beast_seed);
            adventurer.add_gold(gold_reward);

            // emit slayed beast event
            __event__SlayedBeast(
                ref self,
                SlayedBeast {
                    adventurer_state: AdventurerState {
                        owner: get_caller_address(),
                        adventurer_id: adventurer_id,
                        adventurer: adventurer
                    },
                    seed: beast_seed,
                    id: beast.id,
                    health: adventurer.beast_health,
                    level: beast.combat_spec.level,
                    special1: beast.combat_spec.special_powers.prefix1,
                    special2: beast.combat_spec.special_powers.prefix2,
                    damage_dealt: damage_dealt,
                    xp_earned_adventurer: xp_earned,
                    xp_earned_items: xp_earned * ITEM_XP_MULTIPLIER,
                    gold_earned: gold_reward
                }
            );
        } else {
            // beast has more health than was dealt so subtract damage dealt
            adventurer.beast_health = adventurer.beast_health - damage_dealt;

            // then handle the beast counter attack

            // start by generating a random attack location
            let attack_location = AdventurerUtils::get_random_armor_slot(attack_entropy);

            // then calling internal function to calculate damage
            let damage_taken = _beast_counter_attack(
                ref self, ref adventurer, adventurer_id, attack_location, beast, attack_entropy
            );

            // if adventurer health is zero (beast_counter_attack checks for underflow)
            if (adventurer.health == 0) {
                // emit adventurer died
                // note we technically could do this inside of _beast_counter_attack but
                // doing so would result in AdventurerDied being emitted before
                // the DiscoverBeast for the beast that killed them.
                __event_AdventurerDied(
                    ref self,
                    AdventurerState {
                        owner: get_caller_address(),
                        adventurer_id: adventurer_id,
                        adventurer: adventurer
                    },
                    killed_by_beast: true,
                    killed_by_obstacle: false,
                    killer_id: beast.id
                );
            }

            // emit attack beast event
            __event__AttackBeast(
                ref self,
                AttackBeast {
                    adventurer_state: AdventurerState {
                        owner: get_caller_address(),
                        adventurer_id: adventurer_id,
                        adventurer: adventurer
                    },
                    seed: beast_seed,
                    id: beast.id,
                    level: beast.combat_spec.level,
                    health: adventurer.beast_health,
                    special1: beast.combat_spec.special_powers.prefix1,
                    special2: beast.combat_spec.special_powers.prefix2,
                    damage_dealt: damage_dealt,
                    damage_taken: damage_taken,
                    damage_location: ImplCombat::slot_to_u8(attack_location),
                }
            );
        }
    }

    fn _beast_counter_attack(
        ref self: ContractState,
        ref adventurer: Adventurer,
        adventurer_id: u256,
        attack_location: CombatEnums::Slot,
        beast: Beast,
        entropy: u128
    ) -> u16 {
        // https://github.com/starkware-libs/cairo/issues/2942
        // internal::revoke_ap_tracking();
        // generate a random attack slot for the beast and get the armor the adventurer has at that slot
        let armor = adventurer.get_item_at_slot(attack_location);

        // convert loot item to combat spec so it can be used with combat library
        let armor_combat_spec = _get_combat_spec(@self, adventurer_id, armor);

        // process beast counter attack
        let damage_taken = beast.counter_attack(armor_combat_spec, entropy);

        // if the damage taken is greater than or equal to adventurers health
        // the adventurer is dead
        let adventurer_died = (damage_taken >= adventurer.health);
        if (adventurer_died) {
            // set their health to 0
            adventurer.health = 0;
            // TODO: Check for Top score
            return damage_taken;
        } // if the adventurer is not dead
        else {
            // deduct the damage dealt
            adventurer.deduct_health(damage_taken);
            return damage_taken;
        }
    }

    fn _flee(ref self: ContractState, ref adventurer: Adventurer, adventurer_id: u256) {
        // https://github.com/starkware-libs/cairo/issues/2942
        internal::revoke_ap_tracking();
        // get adventurer entropy from storage
        let adventurer_entropy: u128 = _adventurer_meta_unpacked(@self, adventurer_id)
            .entropy
            .into();

        // get game entropy from storage
        let game_entropy: u128 = _get_entropy(@self).into();

        // generate live entropy from fixed entropy sources and live adventurer stats
        let flee_entropy = _get_live_entropy(adventurer_entropy, game_entropy, adventurer);

        let fled = ImplBeast::attempt_flee(
            adventurer.get_level(), adventurer.stats.dexterity, flee_entropy
        );

        // get beast seed based on adventurer entropy and adventurer state
        let beast_seed: u128 = adventurer.get_beast_seed(adventurer_entropy);

        // generate beast without special powers ()
        let beast = ImplBeast::get_beast(
            adventurer.get_level(),
            ImplBeast::get_special_names(
                adventurer.get_level(), beast_seed, NamePrefixLength.into(), NameSuffixLength.into()
            ),
            beast_seed,
            ImplLoot::get_type(adventurer.weapon.id)
        );
        let mut damage_taken = 0;
        let mut attack_location = 0;
        if (fled) {
            // set beast health to zero to denote adventurer is no longer in battle
            adventurer.beast_health = 0;
        } else {
            // if flee attempt was unsuccessful the beast counter attacks
            // adventurer death will be handled as part of counter attack
            let attack_slot = AdventurerUtils::get_random_armor_slot(flee_entropy);
            attack_location = ImplCombat::slot_to_u8(attack_slot);
            damage_taken =
                _beast_counter_attack(
                    ref self, ref adventurer, adventurer_id, attack_slot, beast, flee_entropy
                );
        }

        // emit flee attempt event
        __event__FleeAttempt(
            ref self,
            flee_attempt: FleeAttempt {
                adventurer_state: AdventurerState {
                    owner: get_caller_address(),
                    adventurer_id: adventurer_id,
                    adventurer: adventurer
                },
                seed: beast_seed,
                id: beast.id,
                health: adventurer.beast_health,
                level: beast.combat_spec.level,
                special1: beast.combat_spec.special_powers.prefix1,
                special2: beast.combat_spec.special_powers.prefix2,
                damage_taken: damage_taken,
                damage_location: attack_location,
                fled
            }
        );

        // if adventurer died trying to flee
        if (adventurer.health == 0) {
            // emit adventurer died event
            __event_AdventurerDied(
                ref self,
                AdventurerState {
                    owner: get_caller_address(),
                    adventurer_id: adventurer_id,
                    adventurer: adventurer
                },
                killed_by_beast: true,
                killed_by_obstacle: false,
                killer_id: beast.id
            );
        }
    }

    fn _equip(
        ref self: ContractState,
        adventurer_id: u256,
        ref adventurer: Adventurer,
        item_id: u8,
        ref bag: Bag
    ) {
        // https://github.com/starkware-libs/cairo/issues/2942
        internal::revoke_ap_tracking();
        // get item the adventurer is equipping
        let equipping_item = bag.get_item(item_id);

        // remove item from bag
        bag.remove_item(equipping_item.id);

        // TODO: could be moved to lib
        assert(equipping_item.id > 0, messages::ITEM_NOT_IN_BAG);

        // check what item type exists on adventurer
        // if some exists pluck from adventurer and add to bag
        let mut unequipping_item = ItemPrimitive { id: 0, xp: 0, metadata: 0 };
        if adventurer.is_slot_free(equipping_item) == false {
            let unequipping_item = adventurer
                .get_item_at_slot(ImplLoot::get_slot(equipping_item.id));
            bag.add_item(unequipping_item);
        }

        // equip item
        adventurer.add_item(equipping_item);

        // get item names from storage
        let mut name_storage1 = _loot_special_names_storage_unpacked(
            @self, adventurer_id, LOOT_NAME_STORAGE_INDEX_1
        );
        let mut name_storage2 = _loot_special_names_storage_unpacked(
            @self, adventurer_id, LOOT_NAME_STORAGE_INDEX_2
        );

        // apply stat boosts so the event has the correct stats
        _apply_stat_boots(@self, adventurer_id, ref adventurer, name_storage1, name_storage2);

        // emit equipped item event
        __event_EquipItem(
            ref self,
            AdventurerStateWithBag {
                adventurer_state: AdventurerState {
                    owner: get_caller_address(),
                    adventurer_id: adventurer_id,
                    adventurer: adventurer
                }, bag: bag
            },
            item_id,
            unequipping_item.id,
        );

        // remove stats here to prevent boosts from being saved to chain
        _remove_stat_boots(@self, adventurer_id, ref adventurer, name_storage1, name_storage2);
    }

    // @loaf
    // checks item exists on market according to the adventurers entropy
    // checks adventurer has enough gold
    // equips item if equip is true
    // stashes item in bag if equip is false
    fn _buy_item(
        ref self: ContractState,
        adventurer_id: u256,
        ref adventurer: Adventurer,
        item_id: u8,
        equip: bool
    ) {
        // https://github.com/starkware-libs/cairo/issues/2942
        // internal::revoke_ap_tracking();
        // TODO: Remove after testing

        // unpack Loot bag from storage
        let mut bag = _bag_unpacked(@self, adventurer_id);

        // get item and determine metadata slot
        let item = ImplLootItemSpecialNames::get_loot_special_names_slot(
            adventurer, bag, ImplBagActions::new_item(item_id)
        );

        // TODO: Replace with read from state. We could also move all to lib
        let item_tier = ImplLoot::get_tier(item_id);
        let item_price = ImplMarket::get_price(item_tier);

        // get item price after charisma discount
        let charisma_discount_price = adventurer.charisma_adjusted_item_price(item_price);

        // check adventurer has enough gold
        assert(adventurer.check_gold(charisma_discount_price) == true, messages::NOT_ENOUGH_GOLD);

        // deduct gold
        adventurer.deduct_gold(charisma_discount_price);

        // emit purchased item event
        __event_PurchasedItem(
            ref self,
            AdventurerStateWithBag {
                adventurer_state: AdventurerState {
                    owner: get_caller_address(),
                    adventurer_id: adventurer_id,
                    adventurer: adventurer
                }, bag: bag
            },
            item_id,
            charisma_discount_price,
        );

        if equip == true {
            let unequipping_item = adventurer.get_item_at_slot(ImplLoot::get_slot(item.id));

            adventurer.add_item(item);

            // check if item exists
            if unequipping_item.id > 0 {
                bag.add_item(unequipping_item);

                // pack and save bag
                _pack_bag(ref self, adventurer_id, bag);
            }
        } else {
            bag.add_item(item);
            // pack and save bag
            _pack_bag(ref self, adventurer_id, bag);
        }
    }


    fn _upgrade_stat(
        ref self: ContractState, adventurer_id: u256, ref adventurer: Adventurer, stat_id: u8
    ) {
        // https://github.com/starkware-libs/cairo/issues/2942
        // internal::revoke_ap_tracking();
        _assert_ownership(@self, adventurer_id);

        assert(adventurer.stat_points_available > 0, 'no stat points available');

        // add stat to adventuer
        adventurer.increment_stat(stat_id);

        //deduct one from the adventurers available stat upgrades
        adventurer.stat_points_available -= 1;

        // emit stat upgraded event
        __event__StatUpgraded(
            ref self,
            AdventurerState { owner: get_caller_address(), adventurer_id, adventurer: adventurer },
            stat_id
        );
    }

    fn _buy_health(ref self: ContractState, adventurer_id: u256, ref adventurer: Adventurer) {
        internal::revoke_ap_tracking();

        // check gold balance
        assert(
            adventurer.check_gold(adventurer.charisma_adjusted_potion_price()) == true,
            messages::NOT_ENOUGH_GOLD
        );

        // verify adventurer isn't already at max health
        assert(adventurer.get_max_health() != adventurer.health, messages::HEALTH_FULL);

        // calculate cost of potion based on the Adventurers level
        adventurer.deduct_gold(adventurer.charisma_adjusted_potion_price());

        // TODO: We could remove the value from here altogether and have it within the function
        adventurer.add_health(POTION_HEALTH_AMOUNT);

        // emit purchase potion event
        __event_PurchasedPotion(
            ref self,
            AdventurerState { owner: get_caller_address(), adventurer_id, adventurer: adventurer },
            POTION_HEALTH_AMOUNT
        );
    }

    // _get_live_entropy generates entropy for exploration
    // @param adventurer_entropy - entropy from adventurer
    // @param game_entropy - entropy from game
    // @param adventurer - the adventurer
    // @return u128 - entropy to be used for exploration
    // TODOs:
    // 1. Move this to Adventurer lib
    // 2. Consider using cairo hashing algorithm
    fn _get_live_entropy(
        adventurer_entropy: u128, game_entropy: u128, adventurer: Adventurer
    ) -> u128 {
        let mut hash_span = ArrayTrait::<felt252>::new();
        hash_span.append(adventurer.xp.into());
        hash_span.append(adventurer.last_action.into());
        hash_span.append(adventurer_entropy.into());
        hash_span.append(game_entropy.into());

        let poseidon = poseidon_hash_span(hash_span.span());
        let (d, r) = rshift_split(poseidon.into(), U128_MAX.into());
        r.try_into().unwrap()
    }

    // ------------------------------------------ //
    // ------------ Helper Functions ------------ //
    // ------------------------------------------ //

    fn _unpack_adventurer_apply_stat_boost(
        self: @ContractState,
        adventurer_id: u256,
        name_storage1: LootItemSpecialNamesStorage,
        name_storage2: LootItemSpecialNamesStorage
    ) -> Adventurer {
        // unpack adventurer
        let mut adventurer: Adventurer = Packing::unpack(self._adventurer.read(adventurer_id));
        // apply stat boosts
        _apply_stat_boots(self, adventurer_id, ref adventurer, name_storage1, name_storage2)
    }

    fn _pack_adventurer_remove_stat_boost(
        ref self: ContractState,
        adventurer_id: u256,
        ref adventurer: Adventurer,
        name_storage1: LootItemSpecialNamesStorage,
        name_storage2: LootItemSpecialNamesStorage
    ) {
        // remove stat boosts
        _remove_stat_boots(@self, adventurer_id, ref adventurer, name_storage1, name_storage2);
        // pack and save
        self._adventurer.write(adventurer_id, adventurer.pack());
    }

    fn _apply_stat_boots(
        self: @ContractState,
        adventurer_id: u256,
        ref adventurer: Adventurer,
        name_storage1: LootItemSpecialNamesStorage,
        name_storage2: LootItemSpecialNamesStorage
    ) -> Adventurer {
        // apply stat boosts to adventurer from item names
        adventurer.apply_item_stat_boosts(name_storage1, name_storage2);

        // check if adventurer is over max health
        // this could happen if they unequipped a vitality stat boosting item
        if adventurer.health > adventurer.get_max_health() {
            adventurer.health = adventurer.get_max_health();
        }
        adventurer
    }

    fn _remove_stat_boots(
        self: @ContractState,
        adventurer_id: u256,
        ref adventurer: Adventurer,
        name_storage1: LootItemSpecialNamesStorage,
        name_storage2: LootItemSpecialNamesStorage
    ) {
        // apply stat boosts to adventurer from item names
        adventurer.apply_item_stat_boosts(name_storage1, name_storage2);
    }

    // @title Adventurer Level Up Handler
    // @notice This function is responsible for managing the processes when an adventurer levels up. 
    // It emits a level up event, grants the adventurer stat upgrade points, and emits an event about newly available items.
    // @dev The function alters the state of the adventurer
    //
    // @param ref self A reference to the contract state.
    // @param ref adventurer A reference to the adventurer whose level is being updated.
    // @param adventurer_id The unique identifier of the adventurer.
    // @param previous_level The level of the adventurer before this level up.
    // @param new_level The new level of the adventurer after leveling up.
    fn _handle_adventurer_level_up(
        ref self: ContractState,
        ref adventurer: Adventurer,
        adventurer_id: u256,
        previous_level: u8,
        new_level: u8,
    ) {
        // emit level up event
        __event_AdventurerLeveledUp(
            ref self,
            adventurer_state: AdventurerState {
                owner: get_caller_address(), adventurer_id: adventurer_id, adventurer: adventurer
            },
            previous_level: previous_level,
            new_level: new_level
        );

        // add stat upgrades points to adventurer
        let stat_upgrade_points = (new_level - previous_level) * STAT_UPGRADE_POINTS_PER_LEVEL;
        adventurer.add_stat_upgrade_points(stat_upgrade_points);

        // emit new items availble with available items
        let available_items = _get_items_on_market(@self, adventurer_id);
        __event_NewItemsAvailable(
            ref self,
            adventurer_state: AdventurerState {
                owner: get_caller_address(), adventurer_id: adventurer_id, adventurer: adventurer
            },
            items: available_items
        );
    }

    fn _unpack_adventurer(self: @ContractState, adventurer_id: u256) -> Adventurer {
        // unpack adventurer
        Packing::unpack(self._adventurer.read(adventurer_id))
    }

    fn _pack_adventurer(ref self: ContractState, adventurer_id: u256, adventurer: Adventurer) {
        self._adventurer.write(adventurer_id, adventurer.pack());
    }

    fn _bag_unpacked(self: @ContractState, adventurer_id: u256) -> Bag {
        Packing::unpack(self._bag.read(adventurer_id))
    }

    fn _pack_bag(ref self: ContractState, adventurer_id: u256, bag: Bag) {
        self._bag.write(adventurer_id, bag.pack());
    }

    fn _adventurer_meta_unpacked(self: @ContractState, adventurer_id: u256) -> AdventurerMetadata {
        Packing::unpack(self._adventurer_meta.read(adventurer_id))
    }

    fn _pack_adventurer_meta(
        ref self: ContractState, adventurer_id: u256, adventurer_meta: AdventurerMetadata
    ) {
        self._adventurer_meta.write(adventurer_id, adventurer_meta.pack());
    }

    // we pack according to a storage index
    fn _pack_loot_special_names_storage(
        ref self: ContractState,
        adventurer_id: u256,
        storage_index: u256,
        loot_special_names_storage: LootItemSpecialNamesStorage,
    ) {
        self
            ._loot_special_names
            .write((adventurer_id, storage_index), loot_special_names_storage.pack());
    }

    fn _loot_special_names_storage_unpacked(
        self: @ContractState, adventurer_id: u256, storage_index: u256
    ) -> LootItemSpecialNamesStorage {
        Packing::unpack(self._loot_special_names.read((adventurer_id, storage_index)))
    }

    fn _get_special_names(
        self: @ContractState, adventurer_id: u256, item: ItemPrimitive
    ) -> LootItemSpecialNames {
        ImplLootItemSpecialNames::get_loot_special_names(
            _loot_special_names_storage_unpacked(
                self, adventurer_id, _get_storage_index(self, item.metadata)
            ),
            item
        )
    }

    fn _owner_of(self: @ContractState, adventurer_id: u256) -> ContractAddress {
        self._owner.read(adventurer_id)
    }

    fn _assert_ownership(self: @ContractState, adventurer_id: u256) {
        assert(self._owner.read(adventurer_id) == get_caller_address(), messages::NOT_OWNER);
    }
    fn _assert_in_battle(self: @ContractState, adventurer: Adventurer) {
        assert(adventurer.beast_health > 0, messages::NOT_IN_BATTLE);
    }
    fn _assert_not_in_battle(self: @ContractState, adventurer: Adventurer) {
        assert(adventurer.beast_health == 0, messages::ACTION_NOT_ALLOWED_DURING_BATTLE);
    }
    fn _assert_market_is_open(self: @ContractState, adventurer: Adventurer) {
        assert(adventurer.stat_points_available > 0, messages::MARKET_CLOSED);
    }
    fn _assert_item_is_available(
        self: @ContractState,
        adventurer: Adventurer,
        adventurer_id: u256,
        adventurer_entropy: u128,
        item_id: u8
    ) {
        assert(
            ImplMarket::is_item_available(
                adventurer.get_market_seed(adventurer_id, adventurer_entropy).into(), item_id
            ) == true,
            messages::ITEM_DOES_NOT_EXIST
        );
    }
    fn _assert_not_starter_beast(self: @ContractState, adventurer: Adventurer) {
        assert(adventurer.get_level() > 1, messages::CANT_FLEE_STARTER_BEAST);
    }
    fn _assert_no_stat_upgrades_available(self: @ContractState, adventurer: Adventurer) {
        assert(adventurer.stat_points_available == 0, messages::STAT_UPGRADES_AVAILABLE);
    }
    fn _assert_not_dead(self: @ContractState, adventurer: Adventurer) {
        assert(adventurer.health > 0, messages::DEAD_ADVENTURER);
    }
    fn _assert_one_explore_per_block(self: @ContractState, adventurer: Adventurer) {
        let current_block: u16 = U64TryIntoU16::try_into(
            starknet::get_block_info().unbox().block_number % MAX_STORAGE_BLOCKS
        )
            .unwrap();
        assert(adventurer.last_action != current_block, messages::ONE_EXPLORE_PER_BLOCK);
    }
    fn _assert_has_stat_upgrades_available(self: @ContractState, adventurer: Adventurer) {
        assert(adventurer.stat_points_available > 0, messages::NO_STAT_UPGRADES_AVAILABLE);
    }
    fn _assert_fatally_idle(self: @ContractState, adventurer: Adventurer) {
        let idle_blocks = adventurer
            .get_idle_blocks(starknet::get_block_info().unbox().block_number);

        assert(idle_blocks >= IDLE_DEATH_PENALTY_BLOCKS, messages::ADVENTURER_NOT_IDLE);
    }
    fn _idle_longer_than_penalty_threshold(self: @ContractState, adventurer: Adventurer) -> bool {
        let idle_blocks = adventurer
            .get_idle_blocks(starknet::get_block_info().unbox().block_number);
        idle_blocks >= IDLE_PENALTY_THRESHOLD_BLOCKS
    }
    fn _idle_penalty(self: @ContractState, adventurer: Adventurer) -> u16 {
        // TODO: Get worst case scenario obstacle
        // 1. Identify adventurers weakest armor
        // 2. Get T1 obstacle that is strong against that armor
        // 3. Level will be maximum allowed by combat system for that adventurers Level

        // for now just return fixed 80 damage
        return 80;
    }

    fn _lords_address(self: @ContractState) -> ContractAddress {
        self._lords.read()
    }

    fn _dao_address(self: @ContractState) -> ContractAddress {
        self._dao.read()
    }

    fn _get_items_on_market(self: @ContractState, adventurer_id: u256) -> Array<LootWithPrice> {
        let adventurer_entropy: u128 = _adventurer_meta_unpacked(self, adventurer_id)
            .entropy
            .into();

        ImplMarket::get_all_items_with_price(
            _unpack_adventurer(self, adventurer_id)
                .get_market_seed(adventurer_id, adventurer_entropy)
                .into()
        )
    }

    fn _get_potion_price(self: @ContractState, adventurer_id: u256) -> u16 {
        let mut name_storage1 = _loot_special_names_storage_unpacked(
            self, adventurer_id, LOOT_NAME_STORAGE_INDEX_1
        );
        let mut name_storage2 = _loot_special_names_storage_unpacked(
            self, adventurer_id, LOOT_NAME_STORAGE_INDEX_2
        );

        let adventurer = _unpack_adventurer_apply_stat_boost(
            self, adventurer_id, name_storage1, name_storage2
        );

        adventurer.charisma_adjusted_potion_price()
    }

    fn _get_attacking_beast(self: @ContractState, adventurer_id: u256) -> Beast {
        // get adventurer
        let adventurer = _unpack_adventurer(self, adventurer_id);

        // assert adventurer is in battle
        assert(adventurer.beast_health > 0, messages::NOT_IN_BATTLE);

        // get adventurer entropy
        let adventurer_entropy: u128 = _adventurer_meta_unpacked(self, adventurer_id)
            .entropy
            .into();

        // get beast seed based on adventurer entropy and adventurer state
        let beast_seed: u128 = adventurer.get_beast_seed(adventurer_entropy);

        // get beast based on adventurer level and beast special names
        ImplBeast::get_beast(
            adventurer.get_level(),
            ImplBeast::get_special_names(
                adventurer.get_level(),
                beast_seed,
                NamePrefixLength.into(),
                NameSuffixLength.into(),
            ),
            beast_seed,
            ImplLoot::get_type(adventurer.weapon.id)
        )
    }

    fn _get_storage_index(self: @ContractState, meta_data_id: u8) -> u256 {
        if (meta_data_id <= 10) {
            return LOOT_NAME_STORAGE_INDEX_1;
        } else {
            return LOOT_NAME_STORAGE_INDEX_2;
        }
    }

    // _get_combat_spec returns the combat spec of an item
    // as part of this we get the item details from the loot description
    fn _get_combat_spec(
        self: @ContractState, adventurer_id: u256, item: ItemPrimitive
    ) -> CombatSpec {
        // if item greatness is less than 15, no need to fetch the special names it doesn't have them
        if (item.get_greatness() < 15) {
            return CombatSpec {
                tier: ImplLoot::get_tier(item.id),
                item_type: ImplLoot::get_type(item.id),
                level: U8IntoU16::into(item.get_greatness()),
                special_powers: SpecialPowers {
                    prefix1: 0, prefix2: 0, suffix: 0
                }
            };
        } else {
            // if it's above 15, fetch the special names
            let item_details = ImplLootItemSpecialNames::get_loot_special_names(
                _loot_special_names_storage_unpacked(
                    self, adventurer_id, _get_storage_index(self, item.metadata)
                ),
                item
            );
            // return combat spec of item
            return CombatSpec {
                tier: ImplLoot::get_tier(item.id),
                item_type: ImplLoot::get_type(item.id),
                level: U8IntoU16::into(item.get_greatness()),
                special_powers: SpecialPowers {
                    prefix1: item_details.name_prefix,
                    prefix2: item_details.name_suffix,
                    suffix: item_details.item_suffix
                }
            };
        }
    }

    fn _set_entropy(ref self: ContractState) {
        // let hash: felt252  = starknet::get_tx_info().unbox().transaction_hash.into();

        let blocknumber: u64 = starknet::get_block_info().unbox().block_number.into();
        let timestamp: u64 = starknet::get_block_info().unbox().block_timestamp.into();

        assert(
            blocknumber >= (self._last_game_entropy_block.read().try_into().unwrap()
                + MIN_BLOCKS_FOR_GAME_ENTROPY_CHANGE.into()),
            messages::BLOCK_NUMBER_ERROR
        );

        let mut hash_span = ArrayTrait::<felt252>::new();
        hash_span.append(blocknumber.into());
        hash_span.append(timestamp.into());

        let poseidon: felt252 = poseidon_hash_span(hash_span.span()).into();
        let (d, r) = rshift_split(poseidon.into(), U64_MAX.into());

        self._game_entropy.write(r.try_into().unwrap());
        self._last_game_entropy_block.write(blocknumber.into());
    }

    fn _get_entropy(self: @ContractState) -> u64 {
        self._game_entropy.read()
    }

    fn _get_score_for_adventurer(self: @ContractState, adventurer_id: u256) -> u256 {
        self._scores.read(adventurer_id)
    }

    fn _check_if_top_score(ref self: ContractState, score: u256) -> bool {
        if score > self._scores.read(3) {
            return true;
        }
        false
    }


    // sets the scoreboard
    // we set the adventurer id in the scoreboard as we already store the owners address
    fn _set_scoreboard(ref self: ContractState, adventurer_id: u256, score: u16) {
        let second_place = self._scoreboard.read(2);
        let first_place = self._scoreboard.read(1);

        if score.into() > self._scores.read(1) {
            self._scoreboard.write(3, second_place);
            self._scoreboard.write(2, first_place);
            self._scoreboard.write(1, adventurer_id);
            self._scores.write(3, self._scores.read(2));
            self._scores.write(2, self._scores.read(1));
            self._scores.write(1, score.into());
        } else if score.into() > self._scores.read(2) {
            self._scoreboard.write(3, second_place);
            self._scoreboard.write(2, adventurer_id);
            self._scores.write(3, self._scores.read(2));
            self._scores.write(2, score.into());
        } else if score.into() > self._scores.read(3) {
            self._scoreboard.write(3, adventurer_id);
            self._scores.write(3, score.into());
        }
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
        health_amount: u16
    }

    #[derive(Drop, starknet::Event)]
    struct DiscoverGold {
        adventurer_state: AdventurerState,
        gold_amount: u16
    }

    #[derive(Drop, starknet::Event)]
    struct DiscoverXP {
        adventurer_state: AdventurerState,
        xp_amount: u16
    }

    #[derive(Drop, starknet::Event)]
    struct DiscoverObstacle {
        adventurer_state: AdventurerState,
        id: u8,
        level: u16,
        dodged: bool,
        damage_taken: u16,
        damage_location: u8,
        xp_earned_adventurer: u16,
        xp_earned_items: u16,
    }

    #[derive(Drop, starknet::Event)]
    struct DiscoverBeast {
        adventurer_state: AdventurerState,
        seed: u128,
        id: u8,
        health: u16,
        level: u16,
        special1: u8,
        special2: u8,
        ambushed: bool,
        damage_taken: u16,
    }

    #[derive(Drop, starknet::Event)]
    struct AttackBeast {
        adventurer_state: AdventurerState,
        seed: u128,
        id: u8,
        health: u16,
        level: u16,
        special1: u8,
        special2: u8,
        damage_dealt: u16,
        damage_taken: u16,
        damage_location: u8,
    }

    #[derive(Drop, starknet::Event)]
    struct SlayedBeast {
        adventurer_state: AdventurerState,
        seed: u128,
        id: u8,
        health: u16,
        level: u16,
        special1: u8,
        special2: u8,
        damage_dealt: u16,
        xp_earned_adventurer: u16,
        xp_earned_items: u16,
        gold_earned: u16,
    }

    #[derive(Drop, starknet::Event)]
    struct FleeAttempt {
        adventurer_state: AdventurerState,
        seed: u128,
        id: u8,
        health: u16,
        level: u16,
        special1: u8,
        special2: u8,
        fled: bool,
        damage_taken: u16,
        damage_location: u8,
    }

    #[derive(Drop, starknet::Event)]
    struct PurchasedItem {
        adventurer_state_with_bag: AdventurerStateWithBag,
        item_id: u8,
        cost: u16,
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
        item_id: u8,
        previous_level: u8,
        new_level: u8,
    }

    #[derive(Drop, starknet::Event)]
    struct ItemPrefixDiscovered {
        adventurer_state: AdventurerState,
        special_names: LootItemSpecialNames
    }

    #[derive(Drop, starknet::Event)]
    struct ItemSuffixDiscovered {
        adventurer_state: AdventurerState,
        special_names: LootItemSpecialNames
    }

    #[derive(Drop, starknet::Event)]
    struct PurchasedPotion {
        adventurer_state: AdventurerState,
        health_amount: u16,
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

    #[derive(Drop, starknet::Event)]
    struct ShopAvailable {
        inventory: Array<Loot>, 
    }

    #[derive(Drop, starknet::Event)]
    struct AdventurerLeveledUp {
        adventurer_state: AdventurerState,
        previous_level: u8,
        new_level: u8,
    }

    #[derive(Drop, starknet::Event)]
    struct NewItemsAvailable {
        adventurer_state: AdventurerState,
        items: Array<LootWithPrice>,
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
        ref self: ContractState, adventurer_state: AdventurerState, health_amount: u16
    ) {
        self.emit(Event::DiscoverHealth(DiscoverHealth { adventurer_state, health_amount }));
    }

    fn __event__DiscoverGold(
        ref self: ContractState, adventurer_state: AdventurerState, gold_amount: u16
    ) {
        self.emit(Event::DiscoverGold(DiscoverGold { adventurer_state, gold_amount }));
    }

    fn __event__DiscoverXP(
        ref self: ContractState, adventurer_state: AdventurerState, xp_amount: u16
    ) {
        self.emit(Event::DiscoverXP(DiscoverXP { adventurer_state, xp_amount }));
    }

    fn __event__DiscoverObstacle(
        ref self: ContractState, disover_obstacle_event: DiscoverObstacle
    ) {
        self.emit(Event::DiscoverObstacle(disover_obstacle_event));
    }

    fn __event__DiscoverBeast(ref self: ContractState, discover_beast_event: DiscoverBeast, ) {
        self.emit(Event::DiscoverBeast(discover_beast_event));
    }

    fn __event__AttackBeast(ref self: ContractState, attack_beast: AttackBeast, ) {
        self.emit(Event::AttackBeast(attack_beast));
    }

    fn __event__SlayedBeast(ref self: ContractState, slayed_beast: SlayedBeast, ) {
        self.emit(Event::SlayedBeast(slayed_beast));
    }

    fn __event__FleeAttempt(ref self: ContractState, flee_attempt: FleeAttempt) {
        self.emit(Event::FleeAttempt(flee_attempt));
    }

    fn __event_PurchasedItem(
        ref self: ContractState,
        adventurer_state_with_bag: AdventurerStateWithBag,
        item_id: u8,
        cost: u16
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
        ref self: ContractState,
        adventurer_state: AdventurerState,
        item_id: u8,
        previous_level: u8,
        new_level: u8
    ) {
        self
            .emit(
                Event::GreatnessIncreased(
                    GreatnessIncreased { adventurer_state, item_id, previous_level, new_level }
                )
            );
    }

    fn __event_ItemPrefixDiscovered(
        ref self: ContractState,
        adventurer_state: AdventurerState,
        special_names: LootItemSpecialNames
    ) {
        self
            .emit(
                Event::ItemPrefixDiscovered(
                    ItemPrefixDiscovered { adventurer_state, special_names }
                )
            );
    }

    fn __event_ItemSuffixDiscovered(
        ref self: ContractState,
        adventurer_state: AdventurerState,
        special_names: LootItemSpecialNames
    ) {
        self
            .emit(
                Event::ItemSuffixDiscovered(
                    ItemSuffixDiscovered { adventurer_state, special_names }
                )
            );
    }

    fn __event_PurchasedPotion(
        ref self: ContractState, adventurer_state: AdventurerState, health_amount: u16
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
        _set_scoreboard(ref self, adventurer_state.adventurer_id, adventurer_state.adventurer.xp);
        self
            .emit(
                Event::AdventurerDied(
                    AdventurerDied {
                        adventurer_state, killed_by_beast, killed_by_obstacle, killer_id
                    }
                )
            );
    }

    fn __event_AdventurerLeveledUp(
        ref self: ContractState,
        adventurer_state: AdventurerState,
        previous_level: u8,
        new_level: u8,
    ) {
        self
            .emit(
                Event::AdventurerLeveledUp(
                    AdventurerLeveledUp { adventurer_state, previous_level, new_level }
                )
            );
    }

    fn __event_NewItemsAvailable(
        ref self: ContractState, adventurer_state: AdventurerState, items: Array<LootWithPrice>, 
    ) {
        self.emit(Event::NewItemsAvailable(NewItemsAvailable { adventurer_state, items }));
    }
}
