mod game {
    mod constants;
    mod interfaces;
}
mod tests {
    mod test_game;
    mod mock_randomness;
}

#[starknet::contract]
mod Game {
    // TODO: TESTING CONFIGS 
    // ADJUST THESE BEFORE DEPLOYMENT
    use core::starknet::SyscallResultTrait;
    const TEST_ENTROPY: u64 = 12303548;
    const MAINNET_CHAIN_ID: felt252 = 0x534e5f4d41494e;
    const SEPOLIA_CHAIN_ID: felt252 = 0x534e5f5345504f4c4941;
    const MINIMUM_SCORE_FOR_PAYOUTS: u16 = 200;
    const SECONDS_IN_HOUR: u32 = 3600;
    const SECONDS_IN_DAY: u32 = 86400;
    const SECONDS_IN_WEEK: u32 = 604800;
    const PHASE2_START: u8 = 12;
    const PHASE3_START: u8 = 24;
    const TARGET_PRICE_USD_CENTS: u16 = 300;
    const PRAGMA_LORDS_KEY: felt252 = 'LORDS/USD'; // felt252 conversion of "LORDS/USD"

    use core::{
        array::{SpanTrait, ArrayTrait}, integer::u256_try_as_non_zero, traits::{TryInto, Into},
        clone::Clone, poseidon::poseidon_hash_span, option::OptionTrait, box::BoxTrait,
        starknet::{
            get_caller_address, ContractAddress, ContractAddressIntoFelt252, contract_address_const,
            get_block_timestamp, info::BlockInfo
        },
    };

    use openzeppelin::token::erc20::interface::{
        IERC20Camel, IERC20CamelDispatcher, IERC20CamelDispatcherTrait, IERC20CamelLibraryDispatcher
    };

    use openzeppelin::introspection::interface::{
        ISRC5Dispatcher, ISRC5DispatcherTrait, ISRC5CamelDispatcher, ISRC5CamelDispatcherTrait
    };

    use openzeppelin::token::erc721::interface::{
        IERC721, IERC721Dispatcher, IERC721DispatcherTrait, IERC721LibraryDispatcher
    };

    use pragma_lib::abi::{IRandomnessDispatcher, IRandomnessDispatcherTrait};
    use pragma_lib::abi::{IPragmaABIDispatcher, IPragmaABIDispatcherTrait};
    use pragma_lib::types::{AggregationMode, DataType, PragmaPricesResponse};

    use arcade_account::{
        account::interface::{
            IMasterControl, IMasterControlDispatcher, IMasterControlDispatcherTrait
        },
        Account, ARCADE_ACCOUNT_ID
    };

    use super::game::{
        interfaces::{IGame},
        constants::{
            messages, Rewards, REWARD_DISTRIBUTIONS_PHASE1_BP, REWARD_DISTRIBUTIONS_PHASE2_BP,
            REWARD_DISTRIBUTIONS_PHASE3_BP, BLOCKS_IN_A_WEEK, COST_TO_PLAY, U64_MAX, U128_MAX,
            STARTER_BEAST_ATTACK_DAMAGE, NUM_STARTING_STATS, MINIMUM_DAMAGE_FROM_BEASTS
        }
    };
    use loot::{
        loot::{ILoot, Loot, ImplLoot},
        constants::{ItemId, NamePrefixLength, NameSuffixLength, SUFFIX_UNLOCK_GREANTESS}
    };
    use adventurer::{
        adventurer::{Adventurer, ImplAdventurer, IAdventurer}, stats::{Stats, ImplStats},
        item::{ImplItem, Item}, equipment::{Equipment, ImplEquipment}, bag::{Bag, IBag, ImplBag},
        adventurer_meta::{AdventurerMetadata, ImplAdventurerMetadata}, exploration::ExploreUtils,
        constants::{
            discovery_constants::DiscoveryEnums::{ExploreResult, DiscoveryType},
            adventurer_constants::{
                POTION_HEALTH_AMOUNT, ITEM_XP_MULTIPLIER_BEASTS, ITEM_XP_MULTIPLIER_OBSTACLES,
                ITEM_MAX_GREATNESS, MAX_GREATNESS_STAT_BONUS, StatisticIndex,
                VITALITY_INSTANT_HEALTH_BONUS, BEAST_SPECIAL_NAME_LEVEL_UNLOCK, XP_FOR_DISCOVERIES,
                STARTING_GOLD, STARTING_HEALTH, POTION_PRICE, MINIMUM_POTION_PRICE,
                CHARISMA_POTION_DISCOUNT, CHARISMA_ITEM_DISCOUNT, MINIMUM_ITEM_PRICE,
                MINIMUM_DAMAGE_TO_BEASTS, MINIMUM_DAMAGE_FROM_OBSTACLES,
                OBSTACLE_CRITICAL_HIT_CHANCE, MAX_STAT_UPGRADES_AVAILABLE
            }
        },
        adventurer_utils::AdventurerUtils, leaderboard::{Score, Leaderboard},
    };
    use openzeppelin::token::erc20::{interface::{IERC20Dispatcher, IERC20DispatcherTrait}};

    use market::{
        market::{ImplMarket, LootWithPrice, ItemPurchase},
        constants::{NUMBER_OF_ITEMS_PER_LEVEL, TIER_PRICE},
    };
    use obstacles::obstacle::{ImplObstacle, IObstacle};
    use combat::{
        combat::{CombatSpec, SpecialPowers, ImplCombat},
        constants::{CombatSettings::STRENGTH_DAMAGE_BONUS, CombatEnums::{Slot, Tier, Type}}
    };
    use beasts::beast::{Beast, IBeast, ImplBeast};

    #[storage]
    struct Storage {
        _adventurer: LegacyMap::<felt252, Adventurer>,
        _adventurer_meta: LegacyMap::<felt252, AdventurerMetadata>,
        _bag: LegacyMap::<felt252, Bag>,
        _collectible_beasts: ContractAddress,
        _dao: ContractAddress,
        _game_counter: felt252,
        _genesis_block: u64,
        _genesis_timestamp: u64,
        _leaderboard: Leaderboard,
        _lords: ContractAddress,
        _owner: LegacyMap::<felt252, ContractAddress>,
        _golden_token_last_use: LegacyMap::<felt252, felt252>,
        _golden_token: ContractAddress,
        _cost_to_play: u128,
        _terminal_timestamp: u64,
        _adventurer_entropy: LegacyMap::<felt252, felt252>,
        _randomness_contract_address: ContractAddress,
        _randomness_rotation_interval: u8,
        _oracle_address: ContractAddress,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        StartGame: StartGame,
        UpgradesAvailable: UpgradesAvailable,
        DiscoveredHealth: DiscoveredHealth,
        DiscoveredGold: DiscoveredGold,
        DodgedObstacle: DodgedObstacle,
        HitByObstacle: HitByObstacle,
        AmbushedByBeast: AmbushedByBeast,
        DiscoveredBeast: DiscoveredBeast,
        AttackedBeast: AttackedBeast,
        AttackedByBeast: AttackedByBeast,
        SlayedBeast: SlayedBeast,
        FleeFailed: FleeFailed,
        FleeSucceeded: FleeSucceeded,
        AdventurerLeveledUp: AdventurerLeveledUp,
        PurchasedItems: PurchasedItems,
        PurchasedPotions: PurchasedPotions,
        AdventurerUpgraded: AdventurerUpgraded,
        EquippedItems: EquippedItems,
        DroppedItems: DroppedItems,
        ItemsLeveledUp: ItemsLeveledUp,
        AdventurerDied: AdventurerDied,
        NewHighScore: NewHighScore,
        RewardDistribution: RewardDistribution,
        PriceChangeEvent: PriceChangeEvent,
        ReceivedEntropy: ReceivedEntropy,
        ClearedEntropy: ClearedEntropy
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        lords: ContractAddress,
        dao: ContractAddress,
        collectible_beasts: ContractAddress,
        golden_token_address: ContractAddress,
        terminal_timestamp: u64,
        randomness_contract_address: ContractAddress,
        randomness_rotation_interval: u8,
        oracle_address: ContractAddress
    ) {
        // init storage
        self._lords.write(lords);
        self._dao.write(dao);
        self._collectible_beasts.write(collectible_beasts);
        self._terminal_timestamp.write(terminal_timestamp);
        self._genesis_block.write(starknet::get_block_info().unbox().block_number.into());
        self._randomness_contract_address.write(randomness_contract_address);
        self._randomness_rotation_interval.write(randomness_rotation_interval);
        self._oracle_address.write(oracle_address);

        // On mainnet, set genesis timestamp to LSV1.0 genesis to preserve same reward distribution schedule for V1.1 
        let chain_id = starknet::get_execution_info().unbox().tx_info.unbox().chain_id;
        if chain_id == MAINNET_CHAIN_ID {
            self._genesis_timestamp.write(1699552291);
        } else {
            // on non-mainnet, use the current block timestamp so tests run correctly
            self
                ._genesis_timestamp
                .write(starknet::get_block_info().unbox().block_timestamp.into());
        };

        // set the golden token address
        self._golden_token.write(golden_token_address);

        // set the cost to play
        self._cost_to_play.write(COST_TO_PLAY);
    }

    // ------------------------------------------ //
    // ------------ Impl ------------------------ //
    // ------------------------------------------ //

    #[abi(embed_v0)]
    impl Game of IGame<ContractState> {
        fn receive_random_words(
            ref self: ContractState,
            requestor_address: ContractAddress,
            request_id: u64,
            random_words: Span<felt252>,
            calldata: Array<felt252>
        ) {
            // verify caller is the vrf contract
            assert(
                get_caller_address() == self._randomness_contract_address.read(),
                'caller not vrf contract'
            );

            // verify requestor is the game contract
            assert(requestor_address == starknet::get_contract_address(), 'requestor is not self');

            // get random word and save it as adventurer entropy
            let adventurer_entropy = *random_words.at(0);
            let adventurer_id = *calldata.at(0);
            self._adventurer_entropy.write(adventurer_id, adventurer_entropy);
            __event_ReceivedEntropy(
                ref self, adventurer_id, get_caller_address(), adventurer_entropy
            );

            // get adventurer
            let mut adventurer = _load_adventurer_no_boosts(@self, adventurer_id);
            let adventurer_level = adventurer.get_level();

            // If the adventurer is on level 2, they are waiting on this entropy to come in for the market to be available
            if adventurer_level == 2 {
                process_initial_entropy(
                    ref self, ref adventurer, adventurer_id, adventurer_entropy
                );
                // we only need to save adventurer is they received Vitality as part of starting stats
                if adventurer.stats.vitality > 0 {
                    _save_adventurer(ref self, ref adventurer, adventurer_id);
                }
            } else if adventurer_level > 2 {
                let adventurer_state = AdventurerState {
                    owner: self._owner.read(adventurer_id),
                    adventurer_id,
                    adventurer_entropy,
                    adventurer
                };

                // get market items based on new adventurer entropy 
                let available_items = _get_items_on_market(
                    @self, adventurer_entropy, adventurer.xp, adventurer.stat_upgrades_available
                );

                // emit upgrades available event 
                __event_UpgradesAvailable(ref self, adventurer_state, available_items);
            }
        }

        /// @title New Game
        ///
        /// @notice Creates a new game of Loot Survivor
        /// @dev The function asserts the provided weapon's validity, starts the game, and distributes rewards.
        ///
        /// @param client_reward_address Address where client rewards should be sent.
        /// @param weapon A u8 representing the weapon to start the game with. Valid options are: {wand: 12, book: 17, short sword: 46, club: 76}
        /// @param name A u128 value representing the player's name.
        fn new_game(
            ref self: ContractState,
            client_reward_address: ContractAddress,
            weapon: u8,
            name: felt252,
            golden_token_id: u256,
            interface_camel: bool,
            vrf_fee_limit: u128
        ) {
            // assert game terminal time has not been reached
            _assert_terminal_time_not_reached(@self);

            // assert provided weapon
            _assert_valid_starter_weapon(weapon);

            // process payment for game and distribute rewards
            if (golden_token_id != 0) {
                _play_with_token(ref self, golden_token_id, interface_camel);
            } else {
                _process_payment_and_distribute_rewards(ref self, client_reward_address);
            }

            // start the game
            _start_game(ref self, weapon, name, interface_camel, vrf_fee_limit);
        }

        /// @title Explore Function
        ///
        /// @notice Allows an adventurer to explore
        ///
        /// @param adventurer_id A u256 representing the ID of the adventurer.
        /// @param till_beast A boolean flag indicating if the exploration continues until encountering a beast.
        fn explore(ref self: ContractState, adventurer_id: felt252, till_beast: bool) {
            // load player assets
            let (mut adventurer, adventurer_entropy, _) = _load_player_assets(@self, adventurer_id);

            // use an immutable adventurer for assertions
            let immutable_adventurer = adventurer.clone();

            // assert action is valid
            _assert_ownership(@self, adventurer_id);
            _assert_not_dead(immutable_adventurer);
            _assert_no_stat_upgrades_available(immutable_adventurer);
            _assert_not_in_battle(immutable_adventurer);
            _assert_entropy_set(@self, adventurer_id);

            // go explore 
            _explore(ref self, ref adventurer, adventurer_id, adventurer_entropy, till_beast);

            _save_adventurer(ref self, ref adventurer, adventurer_id);
        }

        /// @title Attack Function
        ///
        /// @notice Allows an adventurer to attack a beast 
        ///
        /// @param adventurer_id A u256 representing the ID of the adventurer.
        /// @param to_the_death A boolean flag indicating if the attack should continue until either the adventurer or the beast is defeated.
        fn attack(ref self: ContractState, adventurer_id: felt252, to_the_death: bool) {
            // load player assets
            let (mut adventurer, adventurer_entropy, _) = _load_player_assets(@self, adventurer_id);

            // use an immutable adventurer for assertions
            let immutable_adventurer = adventurer.clone();

            // assert action is valid
            _assert_ownership(@self, adventurer_id);
            _assert_not_dead(immutable_adventurer);
            _assert_in_battle(immutable_adventurer);

            // Allow Adventurer to attack starter beast before rnd from VRF comes in
            if (adventurer.get_level() > 1) {
                _assert_entropy_set(@self, adventurer_id);
            }

            // get weapon specials
            let start_entropy = _load_adventurer_metadata(@self, adventurer_id).start_entropy;
            let weapon_specials = ImplLoot::get_specials(
                adventurer.equipment.weapon.id,
                adventurer.equipment.weapon.get_greatness(),
                start_entropy
            );

            // get beast and beast seed
            let (beast, beast_seed) = adventurer.get_beast(adventurer_entropy);

            // get weapon details
            let weapon = ImplLoot::get_item(adventurer.equipment.weapon.id);
            let weapon_combat_spec = CombatSpec {
                tier: weapon.tier,
                item_type: weapon.item_type,
                level: adventurer.equipment.weapon.get_greatness().into(),
                specials: weapon_specials
            };

            _attack(
                ref self,
                ref adventurer,
                weapon_combat_spec,
                adventurer_id,
                adventurer_entropy,
                start_entropy,
                beast,
                beast_seed,
                to_the_death
            );

            _save_adventurer(ref self, ref adventurer, adventurer_id);
        }

        /// @title Flee Function
        ///
        /// @notice Allows an adventurer to flee from a beast
        ///
        /// @param adventurer_id A u256 representing the unique ID of the adventurer.
        /// @param to_the_death A boolean flag indicating if the flee attempt should continue until either the adventurer escapes or is defeated.
        fn flee(ref self: ContractState, adventurer_id: felt252, to_the_death: bool) {
            // load player assets
            let (mut adventurer, adventurer_entropy, _) = _load_player_assets(@self, adventurer_id);

            // use an immutable adventurer for assertions
            let immutable_adventurer = adventurer.clone();

            // assert action is valid
            _assert_ownership(@self, adventurer_id);
            _assert_not_dead(immutable_adventurer);
            _assert_in_battle(immutable_adventurer);
            _assert_not_starter_beast(immutable_adventurer);
            _assert_dexterity_not_zero(immutable_adventurer);
            _assert_entropy_set(@self, adventurer_id);

            // get beast and beast seed
            let (beast, beast_seed) = adventurer.get_beast(adventurer_entropy);

            // attempt to flee
            _flee(
                ref self,
                ref adventurer,
                adventurer_id,
                adventurer_entropy,
                beast_seed,
                beast,
                to_the_death
            );

            // if adventurer died while attempting to flee, process death
            if adventurer.health == 0 {
                _process_adventurer_death(ref self, ref adventurer, adventurer_id, beast.id, 0);
            }

            _save_adventurer(ref self, ref adventurer, adventurer_id);
        }

        /// @title Equip Function
        ///
        /// @notice Allows an adventurer to equip items from their bag
        /// @player Calling this during battle will result in a beast counter-attack
        ///
        /// @param adventurer_id A u256 representing the unique ID of the adventurer.
        /// @param items A u8 array representing the item IDs to equip.
        fn equip(ref self: ContractState, adventurer_id: felt252, items: Array<u8>) {
            // load player assets
            let (mut adventurer, adventurer_entropy, mut bag) = _load_player_assets(
                @self, adventurer_id
            );

            // assert action is valid
            _assert_ownership(@self, adventurer_id);
            _assert_not_dead(adventurer);
            assert(items.len() != 0, messages::NO_ITEMS);
            assert(items.len() <= 8, messages::TOO_MANY_ITEMS);

            // equip items and record the unequipped items for event
            let unequipped_items = _equip_items(
                @self, ref adventurer, ref bag, adventurer_id, items.clone(), false
            );

            __event_EquippedItems(
                ref self, adventurer, adventurer_id, bag, items, unequipped_items,
            );

            // if the adventurer is equipping an item during battle, the beast will counter attack
            if (adventurer.in_battle()) {
                // get beast and beast seed
                let (beast, beast_seed) = adventurer.get_beast(adventurer_entropy);

                // get two random numbers
                let (rnd1, rnd2) = AdventurerUtils::get_randomness(
                    adventurer.xp, adventurer_entropy
                );

                // process beast attack
                let start_entropy = _load_adventurer_metadata(@self, adventurer_id).start_entropy;
                let beast_battle_details = _beast_attack(
                    ref self,
                    ref adventurer,
                    adventurer_id,
                    beast,
                    beast_seed,
                    start_entropy,
                    rnd1,
                    rnd2,
                );

                // emit attacked by beast event
                __event_AttackedByBeast(ref self, adventurer, adventurer_id, beast_battle_details);

                // if adventurer died from counter attack, process death
                if (adventurer.health == 0) {
                    _process_adventurer_death(ref self, ref adventurer, adventurer_id, beast.id, 0);
                }
            }

            // save adventurer 
            _save_adventurer(ref self, ref adventurer, adventurer_id);

            // if the bag was mutated, pack and save it
            if bag.mutated {
                _save_bag(ref self, adventurer_id, bag);
            }
        }

        /// @title Drop Function
        ///
        /// @notice Allows an adventurer to drop equpped items or items from their bag
        ///
        /// @param adventurer_id A u256 representing the unique ID of the adventurer.
        /// @param items A u8 Array representing the IDs of the items to drop.
        fn drop(ref self: ContractState, adventurer_id: felt252, items: Array<u8>) {
            // load player assets
            let (mut adventurer, _, mut bag) = _load_player_assets(@self, adventurer_id);

            // assert action is valid (ownership of item is handled in internal function when we iterate over items)
            _assert_ownership(@self, adventurer_id);
            _assert_not_dead(adventurer);
            assert(items.len() != 0, messages::NO_ITEMS);

            // drop items
            _drop(ref self, ref adventurer, ref bag, adventurer_id, items.clone());

            // emit dropped items event
            __event_DroppedItems(ref self, adventurer, adventurer_id, bag, items);

            // if the adventurer was mutated, save it
            if (adventurer.mutated) {
                _save_adventurer(ref self, ref adventurer, adventurer_id);
            }

            // if the bag was mutated, save it
            if bag.mutated {
                _save_bag(ref self, adventurer_id, bag);
            }
        }

        /// @title Upgrade Function
        ///
        /// @notice Allows an adventurer to upgrade their stats, purchase potions, and buy new items.
        ///
        /// @param adventurer_id A u256 representing the unique ID of the adventurer.
        /// @param potions A u8 representing the number of potions to purchase
        /// @param stat_upgrades A Stats struct detailing the upgrades the adventurer wants to apply to their stats.
        /// @param items An array of ItemPurchase detailing the items the adventurer wishes to purchase during the upgrade.
        fn upgrade(
            ref self: ContractState,
            adventurer_id: felt252,
            potions: u8,
            stat_upgrades: Stats,
            items: Array<ItemPurchase>,
        ) {
            // load player assets
            let (mut adventurer, _, mut bag) = _load_player_assets(@self, adventurer_id);

            let immutable_adventurer = adventurer.clone();

            // assert action is valid
            _assert_ownership(@self, adventurer_id);
            _assert_not_dead(immutable_adventurer);
            _assert_not_in_battle(immutable_adventurer);
            _assert_valid_stat_selection(immutable_adventurer, stat_upgrades);
            _assert_entropy_set(@self, adventurer_id);

            // get number of stat upgrades available before we use them
            let pre_upgrade_stat_points = adventurer.stat_upgrades_available;

            // upgrade adventurer's stats
            _upgrade_stats(@self, ref adventurer, stat_upgrades);

            // if the player is buying items, process purchases
            if (items.len() != 0) {
                let (purchases, equipped_items, unequipped_items) = _buy_items(
                    @self,
                    ref adventurer,
                    ref bag,
                    adventurer_id,
                    pre_upgrade_stat_points,
                    items.clone()
                );

                // emit purchased item event
                __event_PurchasedItems(ref self, adventurer, adventurer_id, bag, purchases);

                // if purchase required equipment change,
                if (equipped_items.len() != 0) {
                    // emit equipped items event
                    __event_EquippedItems(
                        ref self, adventurer, adventurer_id, bag, equipped_items, unequipped_items,
                    );
                }
            }

            // if the player is buying potions as part of the upgrade, process purchase
            // @dev process potion purchase after items in case item purchases changes item stat boosts
            if potions != 0 {
                _buy_potions(ref self, ref adventurer, adventurer_id, potions);
            }

            // emit adventurer upgraded event
            __event_AdventurerUpgraded(ref self, adventurer, adventurer_id, bag, stat_upgrades);

            // if the upgrade mutated the adventurer's bag
            if bag.mutated {
                _save_bag(ref self, adventurer_id, bag);
            }

            _save_adventurer(ref self, ref adventurer, adventurer_id);
        }

        fn update_cost_to_play(ref self: ContractState) {
            let previous_price = self._cost_to_play.read();
            let oracle_address = self._oracle_address.read();
            let lords_price = get_asset_price_median(
                oracle_address, DataType::SpotEntry(PRAGMA_LORDS_KEY)
            );

            // target price is the target price in cents * 10^8 because pragma uses 8 decimals for LORDS price
            let target_price = TARGET_PRICE_USD_CENTS.into() * 100000000;

            // new price is the target price (in cents) divided by the current lords price (in cents)
            let new_price = (target_price / (lords_price * 100)) * 1000000000000000000;

            self._cost_to_play.write(new_price);
            self
                .emit(
                    PriceChangeEvent {
                        previous_price, new_price, lords_price, changer: get_caller_address()
                    }
                );
        }
        // ------------------------------------------ //
        // ------------ View Functions -------------- //
        // ------------------------------------------ //
        fn get_adventurer(self: @ContractState, adventurer_id: felt252) -> Adventurer {
            _load_adventurer(self, adventurer_id)
        }
        fn get_adventurer_entropy(self: @ContractState, adventurer_id: felt252) -> felt252 {
            self._adventurer_entropy.read(adventurer_id)
        }
        fn get_randomness_address(self: @ContractState) -> ContractAddress {
            self._randomness_contract_address.read()
        }
        fn get_adventurer_no_boosts(self: @ContractState, adventurer_id: felt252) -> Adventurer {
            _load_adventurer_no_boosts(self, adventurer_id)
        }
        fn get_adventurer_meta(self: @ContractState, adventurer_id: felt252) -> AdventurerMetadata {
            _load_adventurer_metadata(self, adventurer_id)
        }
        fn get_bag(self: @ContractState, adventurer_id: felt252) -> Bag {
            _load_bag(self, adventurer_id)
        }
        fn get_items_on_market(self: @ContractState, adventurer_id: felt252) -> Array<u8> {
            let adventurer = _load_adventurer_no_boosts(self, adventurer_id);
            _assert_upgrades_available(adventurer);

            let adventurer_entropy = _get_adventurer_entropy(self, adventurer_id);
            _assert_entropy_set(self, adventurer_id);

            _get_items_on_market(
                self, adventurer_entropy, adventurer.xp, adventurer.stat_upgrades_available
            )
        }
        fn get_items_on_market_by_slot(
            self: @ContractState, adventurer_id: felt252, slot: u8
        ) -> Array<u8> {
            let adventurer = _load_adventurer(self, adventurer_id);
            _assert_upgrades_available(adventurer);

            let adventurer_entropy = _get_adventurer_entropy(self, adventurer_id);

            _get_items_on_market_by_slot(
                self,
                adventurer_entropy,
                adventurer.xp,
                adventurer.stat_upgrades_available,
                ImplCombat::u8_to_slot(slot)
            )
        }
        fn get_items_on_market_by_tier(
            self: @ContractState, adventurer_id: felt252, tier: u8
        ) -> Array<u8> {
            let adventurer = _load_adventurer_no_boosts(self, adventurer_id);
            _assert_upgrades_available(adventurer);

            let adventurer_entropy = _get_adventurer_entropy(self, adventurer_id);

            if tier == 1 {
                _get_items_on_market_by_tier(
                    self,
                    adventurer_entropy,
                    adventurer.xp,
                    adventurer.stat_upgrades_available,
                    Tier::T1(())
                )
            } else if tier == 2 {
                _get_items_on_market_by_tier(
                    self,
                    adventurer_entropy,
                    adventurer.xp,
                    adventurer.stat_upgrades_available,
                    Tier::T2(())
                )
            } else if tier == 3 {
                _get_items_on_market_by_tier(
                    self,
                    adventurer_entropy,
                    adventurer.xp,
                    adventurer.stat_upgrades_available,
                    Tier::T3(())
                )
            } else if tier == 4 {
                _get_items_on_market_by_tier(
                    self,
                    adventurer_entropy,
                    adventurer.xp,
                    adventurer.stat_upgrades_available,
                    Tier::T4(())
                )
            } else {
                _get_items_on_market_by_tier(
                    self,
                    adventurer_entropy,
                    adventurer.xp,
                    adventurer.stat_upgrades_available,
                    Tier::T5(())
                )
            }
        }

        fn get_potion_price(self: @ContractState, adventurer_id: felt252) -> u16 {
            _get_potion_price(self, adventurer_id)
        }
        fn get_item_price(self: @ContractState, adventurer_id: felt252, item_id: u8) -> u16 {
            _get_item_price(self, adventurer_id, item_id)
        }
        fn get_attacking_beast(self: @ContractState, adventurer_id: felt252) -> Beast {
            _get_attacking_beast(self, adventurer_id)
        }
        fn get_health(self: @ContractState, adventurer_id: felt252) -> u16 {
            _load_adventurer_no_boosts(self, adventurer_id).health
        }
        fn get_xp(self: @ContractState, adventurer_id: felt252) -> u16 {
            _load_adventurer_no_boosts(self, adventurer_id).xp
        }
        fn get_level(self: @ContractState, adventurer_id: felt252) -> u8 {
            _load_adventurer_no_boosts(self, adventurer_id).get_level()
        }
        fn get_gold(self: @ContractState, adventurer_id: felt252) -> u16 {
            _load_adventurer_no_boosts(self, adventurer_id).gold
        }
        fn get_beast_health(self: @ContractState, adventurer_id: felt252) -> u16 {
            _load_adventurer_no_boosts(self, adventurer_id).beast_health
        }
        fn get_stat_upgrades_available(self: @ContractState, adventurer_id: felt252) -> u8 {
            _load_adventurer_no_boosts(self, adventurer_id).stat_upgrades_available
        }
        fn get_equipped_items(self: @ContractState, adventurer_id: felt252) -> Array<Item> {
            let adventurer = _load_adventurer_no_boosts(self, adventurer_id);
            let mut equipped_items = ArrayTrait::<Item>::new();
            equipped_items.append(adventurer.equipment.weapon);
            equipped_items.append(adventurer.equipment.chest);
            equipped_items.append(adventurer.equipment.head);
            equipped_items.append(adventurer.equipment.waist);
            equipped_items.append(adventurer.equipment.foot);
            equipped_items.append(adventurer.equipment.hand);
            equipped_items.append(adventurer.equipment.neck);
            equipped_items.append(adventurer.equipment.ring);
            equipped_items
        }
        fn get_weapon_greatness(self: @ContractState, adventurer_id: felt252) -> u8 {
            _load_adventurer_no_boosts(self, adventurer_id).equipment.weapon.get_greatness()
        }
        fn get_chest_greatness(self: @ContractState, adventurer_id: felt252) -> u8 {
            _load_adventurer_no_boosts(self, adventurer_id).equipment.chest.get_greatness()
        }
        fn get_head_greatness(self: @ContractState, adventurer_id: felt252) -> u8 {
            _load_adventurer_no_boosts(self, adventurer_id).equipment.head.get_greatness()
        }
        fn get_waist_greatness(self: @ContractState, adventurer_id: felt252) -> u8 {
            _load_adventurer_no_boosts(self, adventurer_id).equipment.waist.get_greatness()
        }
        fn get_foot_greatness(self: @ContractState, adventurer_id: felt252) -> u8 {
            _load_adventurer_no_boosts(self, adventurer_id).equipment.foot.get_greatness()
        }
        fn get_hand_greatness(self: @ContractState, adventurer_id: felt252) -> u8 {
            _load_adventurer_no_boosts(self, adventurer_id).equipment.hand.get_greatness()
        }
        fn get_necklace_greatness(self: @ContractState, adventurer_id: felt252) -> u8 {
            _load_adventurer_no_boosts(self, adventurer_id).equipment.neck.get_greatness()
        }
        fn get_ring_greatness(self: @ContractState, adventurer_id: felt252) -> u8 {
            _load_adventurer_no_boosts(self, adventurer_id).equipment.ring.get_greatness()
        }
        fn get_base_stats(self: @ContractState, adventurer_id: felt252) -> Stats {
            _load_adventurer_no_boosts(self, adventurer_id).stats
        }
        fn get_stats(self: @ContractState, adventurer_id: felt252) -> Stats {
            _load_adventurer(self, adventurer_id).stats
        }
        // fn get_base_strength(self: @ContractState, adventurer_id: felt252) -> u8 {
        //     _load_adventurer_no_boosts(self, adventurer_id).stats.strength
        // }
        // fn get_strength(self: @ContractState, adventurer_id: felt252) -> u8 {
        //     _load_adventurer(self, adventurer_id).stats.strength
        // }
        // fn get_base_dexterity(self: @ContractState, adventurer_id: felt252) -> u8 {
        //     _load_adventurer_no_boosts(self, adventurer_id).stats.dexterity
        // }
        // fn get_dexterity(self: @ContractState, adventurer_id: felt252) -> u8 {
        //     _load_adventurer(self, adventurer_id).stats.dexterity
        // }
        // fn get_base_vitality(self: @ContractState, adventurer_id: felt252) -> u8 {
        //     _load_adventurer_no_boosts(self, adventurer_id).stats.vitality
        // }
        // fn get_vitality(self: @ContractState, adventurer_id: felt252) -> u8 {
        //     _load_adventurer(self, adventurer_id).stats.vitality
        // }
        // fn get_base_intelligence(self: @ContractState, adventurer_id: felt252) -> u8 {
        //     _load_adventurer_no_boosts(self, adventurer_id).stats.intelligence
        // }
        // fn get_intelligence(self: @ContractState, adventurer_id: felt252) -> u8 {
        //     _load_adventurer(self, adventurer_id).stats.intelligence
        // }
        // fn get_base_wisdom(self: @ContractState, adventurer_id: felt252) -> u8 {
        //     _load_adventurer_no_boosts(self, adventurer_id).stats.wisdom
        // }
        // fn get_wisdom(self: @ContractState, adventurer_id: felt252) -> u8 {
        //     _load_adventurer(self, adventurer_id).stats.wisdom
        // }
        // fn get_base_charisma(self: @ContractState, adventurer_id: felt252) -> u8 {
        //     _load_adventurer_no_boosts(self, adventurer_id).stats.charisma
        // }
        // fn get_charisma(self: @ContractState, adventurer_id: felt252) -> u8 {
        //     _load_adventurer(self, adventurer_id).stats.charisma
        // }
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
        fn get_leaderboard(self: @ContractState) -> Leaderboard {
            self._leaderboard.read()
        }
        fn owner_of(self: @ContractState, adventurer_id: felt252) -> ContractAddress {
            self._owner.read(adventurer_id)
        }
        // fn starting_gold(self: @ContractState) -> u16 {
        //     STARTING_GOLD
        // }
        // fn starting_health(self: @ContractState) -> u16 {
        //     STARTING_HEALTH
        // }
        // fn base_potion_price(self: @ContractState) -> u16 {
        //     POTION_PRICE
        // }
        // fn potion_health_amount(self: @ContractState) -> u16 {
        //     POTION_HEALTH_AMOUNT
        // }
        // fn minimum_potion_price(self: @ContractState) -> u16 {
        //     MINIMUM_POTION_PRICE
        // }
        // fn charisma_potion_discount(self: @ContractState) -> u16 {
        //     CHARISMA_POTION_DISCOUNT
        // }
        // fn items_per_stat_upgrade(self: @ContractState) -> u8 {
        //     NUMBER_OF_ITEMS_PER_LEVEL
        // }
        // fn item_tier_price_multiplier(self: @ContractState) -> u16 {
        //     TIER_PRICE
        // }
        // fn charisma_item_discount(self: @ContractState) -> u16 {
        //     CHARISMA_ITEM_DISCOUNT
        // }
        // fn minimum_item_price(self: @ContractState) -> u16 {
        //     MINIMUM_ITEM_PRICE
        // }
        // fn minimum_damage_to_beasts(self: @ContractState) -> u8 {
        //     MINIMUM_DAMAGE_TO_BEASTS
        // }
        // fn minimum_damage_from_beasts(self: @ContractState) -> u8 {
        //     MINIMUM_DAMAGE_FROM_BEASTS
        // }
        // fn minimum_damage_from_obstacles(self: @ContractState) -> u8 {
        //     MINIMUM_DAMAGE_FROM_OBSTACLES
        // }
        // fn obstacle_critical_hit_chance(self: @ContractState) -> u8 {
        //     OBSTACLE_CRITICAL_HIT_CHANCE
        // }
        // fn stat_upgrades_per_level(self: @ContractState) -> u8 {
        //     MAX_STAT_UPGRADES_AVAILABLE
        // }
        // fn beast_special_name_unlock_level(self: @ContractState) -> u16 {
        //     BEAST_SPECIAL_NAME_LEVEL_UNLOCK
        // }
        // fn item_xp_multiplier_beasts(self: @ContractState) -> u16 {
        //     ITEM_XP_MULTIPLIER_BEASTS
        // }
        // fn item_xp_multiplier_obstacles(self: @ContractState) -> u16 {
        //     ITEM_XP_MULTIPLIER_OBSTACLES
        // }
        // fn strength_bonus_damage(self: @ContractState) -> u8 {
        //     STRENGTH_DAMAGE_BONUS
        // }

        fn get_cost_to_play(self: @ContractState) -> u128 {
            _get_cost_to_play(self)
        }

        fn can_play(self: @ContractState, golden_token_id: u256) -> bool {
            _can_play(self, golden_token_id)
        }
    }

    // ------------------------------------------ //
    // ------------ Internal Functions ---------- //
    // ------------------------------------------ //

    fn process_initial_entropy(
        ref self: ContractState,
        ref adventurer: Adventurer,
        adventurer_id: felt252,
        adventurer_entropy: felt252
    ) {
        // reveal starting stats
        let adventurer_meta = _handle_stat_reveal(
            @self, ref adventurer, adventurer_id, adventurer_entropy
        );

        // create adventurer state for UpgradesAvailable event
        let adventurer_state = AdventurerState {
            owner: self._owner.read(adventurer_id), adventurer_id, adventurer_entropy, adventurer
        };
        let available_items = _get_items_on_market(
            @self, adventurer_entropy, adventurer.xp, adventurer.stat_upgrades_available
        );

        // emit UpgradesAvailable event
        __event_UpgradesAvailable(ref self, adventurer_state, available_items);

        // save the starting stats to adventurer metadata for cheap and easy future lookup
        _save_adventurer_metadata(ref self, adventurer_id, adventurer_meta);
    }

    fn get_asset_price_median(oracle_address: ContractAddress, asset: DataType) -> u128 {
        let oracle_dispatcher = IPragmaABIDispatcher { contract_address: oracle_address };
        let output: PragmaPricesResponse = oracle_dispatcher
            .get_data(asset, AggregationMode::Median(()));
        return output.price;
    }

    fn request_randomness(
        randomness_address: ContractAddress, seed: u64, adventurer_id: felt252, fee_limit: u128
    ) {
        let publish_delay = 0;
        let num_words = 1;
        let calldata = array![adventurer_id];
        let ETH_ADDRESS = 0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7;

        // Approve the randomness contract to transfer the callback fee
        let eth_dispatcher = IERC20Dispatcher { contract_address: ETH_ADDRESS.try_into().unwrap() };

        eth_dispatcher.approve(randomness_address, (fee_limit + fee_limit / 5).into());

        // Request the randomness
        let randomness_dispatcher = IRandomnessDispatcher { contract_address: randomness_address };

        randomness_dispatcher
            .request_random(
                seed,
                starknet::get_contract_address(),
                fee_limit,
                publish_delay,
                num_words,
                calldata
            );
    }

    fn _assert_terminal_time_not_reached(self: @ContractState) {
        let current_timestamp = starknet::get_block_info().unbox().block_timestamp;
        let terminal_timestamp = self._terminal_timestamp.read();
        assert(
            terminal_timestamp == 0 || current_timestamp < terminal_timestamp,
            messages::TERMINAL_TIME_REACHED
        );
    }

    fn _process_beast_death(
        ref self: ContractState,
        ref adventurer: Adventurer,
        adventurer_id: felt252,
        beast: Beast,
        beast_seed: u128,
        attack_rnd_2: u128,
        damage_dealt: u16,
        critical_hit: bool
    ) {
        // zero out beast health
        adventurer.beast_health = 0;

        // get gold reward and increase adventurers gold
        let gold_earned = beast.get_gold_reward(beast_seed);
        let ring_bonus = adventurer.equipment.ring.jewelry_gold_bonus(gold_earned);
        adventurer.increase_gold(gold_earned + ring_bonus);

        // get xp reward and increase adventurers xp
        let xp_earned_adventurer = beast.get_xp_reward();
        let (previous_level, new_level) = adventurer.increase_adventurer_xp(xp_earned_adventurer);

        // items use adventurer xp with an item multplier so they level faster than Adventurer
        let xp_earned_items = xp_earned_adventurer * ITEM_XP_MULTIPLIER_BEASTS;
        // assigning xp to items is more complex so we delegate to an internal function
        let start_entropy = _load_adventurer_metadata(@self, adventurer_id).start_entropy;
        let items_leveled_up = _grant_xp_to_equipped_items(
            ref self, ref adventurer, adventurer_id, xp_earned_items, start_entropy
        );

        // emit slayed beast event
        __event_SlayedBeast(
            ref self,
            adventurer,
            adventurer_id,
            beast_seed,
            beast,
            damage_dealt,
            critical_hit,
            xp_earned_adventurer,
            xp_earned_items,
            gold_earned
        );

        // if any items leveled up
        if items_leveled_up.len() != 0 {
            // emit event
            __event_ItemsLeveledUp(ref self, adventurer, adventurer_id, items_leveled_up);
        }

        // if adventurer gained stat points
        if (adventurer.stat_upgrades_available != 0) {
            // emit events
            _process_level_up(ref self, ref adventurer, adventurer_id, previous_level, new_level);
        }

        // if beast beast level is above collectible threshold
        if beast.combat_spec.level >= BEAST_SPECIAL_NAME_LEVEL_UNLOCK {
            // mint beast to the players Primary Account address instead of Arcade Account
            let owner_address = self._owner.read(adventurer_id);
            let primary_address = _get_primary_account_address(
                @self,
                owner_address,
                _load_adventurer_metadata(@self, adventurer_id).interface_camel
            );

            // mint the beast
            _mint_beast(@self, beast, primary_address);
        }
    }

    /// @title Stat Reveal Handler
    /// @notice Handle the revelation and setting of an adventurer's starting stats.
    /// @dev This function generates starting stats for an adventurer using entropy, which is based on the block hash of the block 
    /// after the player committed to playing the game.
    /// @param self A reference to the ContractState object.
    /// @param adventurer A reference to the Adventurer object whose stats are to be revealed and set.
    /// @param adventurer_id The unique identifier of the adventurer.
    /// @return The adventurer's metadata.
    fn _handle_stat_reveal(
        self: @ContractState,
        ref adventurer: Adventurer,
        adventurer_id: felt252,
        adventurer_entropy: felt252
    ) -> AdventurerMetadata {
        // generate starting stats using the adventurer entropy which is based on the block hash of the block after
        // the player committed to playing the game
        let starting_stats = AdventurerUtils::generate_starting_stats(
            adventurer_entropy.into(), NUM_STARTING_STATS
        );

        // adventurer shouldn't have any stats so save gas and overwrite
        adventurer.stats = starting_stats;

        // credit adventurer with health from their vitality starting stats
        adventurer.health += AdventurerUtils::get_max_health(adventurer.stats.vitality)
            - STARTING_HEALTH;

        // update adventurer meta with starting stats, this is last time we need to update adventurer meta data
        // we store starting stats separate from adventurer so we don't consume the limited bits of the adventurer storage slot
        let mut adventurer_meta = _load_adventurer_metadata(self, adventurer_id);
        adventurer_meta.starting_stats = starting_stats;
        adventurer_meta
            .start_entropy = ImplAdventurerMetadata::generate_start_entropy(adventurer_entropy);
        adventurer_meta
    }

    fn _mint_beast(self: @ContractState, beast: Beast, to_address: ContractAddress) {
        let collectible_beasts_contract = ILeetLootDispatcher {
            contract_address: self._collectible_beasts.read()
        };

        let is_beast_minted = collectible_beasts_contract
            .isMinted(
                beast.id, beast.combat_spec.specials.special2, beast.combat_spec.specials.special3
            );

        let beasts_minter = collectible_beasts_contract.getMinter();

        if !is_beast_minted && beasts_minter == starknet::get_contract_address() {
            collectible_beasts_contract
                .mint(
                    to_address,
                    beast.id,
                    beast.combat_spec.specials.special2,
                    beast.combat_spec.specials.special3,
                    beast.combat_spec.level,
                    beast.starting_health
                );
        }
    }

    fn _process_adventurer_death(
        ref self: ContractState,
        ref adventurer: Adventurer,
        adventurer_id: felt252,
        beast_id: u8,
        obstacle_id: u8
    ) {
        let adventurer_entropy = _get_adventurer_entropy(@self, adventurer_id);
        let adventurer_state = AdventurerState {
            owner: self._owner.read(adventurer_id), adventurer_id, adventurer_entropy, adventurer
        };

        let death_details = DeathDetails {
            killed_by_beast: beast_id,
            killed_by_obstacle: obstacle_id,
            caller_address: get_caller_address()
        };

        __event_AdventurerDied(ref self, AdventurerDied { adventurer_state, death_details });

        // and adventurer got a top score
        if _is_top_score(@self, adventurer.xp) {
            // update the leaderboard
            _update_leaderboard(ref self, adventurer_id, adventurer);
        }
    }

    fn _golden_token_dispatcher(ref self: ContractState) -> IERC721Dispatcher {
        IERC721Dispatcher { contract_address: self._golden_token.read() }
    }

    fn _lords_dispatcher(ref self: ContractState) -> IERC20CamelDispatcher {
        IERC20CamelDispatcher { contract_address: self._lords.read() }
    }

    fn _calculate_payout(bp: u256, price: u128) -> u256 {
        (bp * price.into()) / 1000
    }

    fn _get_cost_to_play(self: @ContractState) -> u128 {
        self._cost_to_play.read()
    }

    fn _age_of_game_weeks(contract: @ContractState) -> u64 {
        let genesis_timestamp = contract._genesis_timestamp.read();
        let current_timestamp = starknet::get_block_info().unbox().block_timestamp;
        (current_timestamp - genesis_timestamp) / SECONDS_IN_WEEK.into()
    }

    fn _age_of_game_hours(contract: @ContractState) -> u64 {
        let genesis_timestamp = contract._genesis_timestamp.read();
        let current_timestamp = starknet::get_block_info().unbox().block_timestamp;
        (current_timestamp - genesis_timestamp) / SECONDS_IN_HOUR.into()
    }

    fn _get_reward_distribution(self: @ContractState) -> Rewards {
        let cost_to_play = self._cost_to_play.read();
        let third_place_score = self._leaderboard.read().third.xp;

        // use hours for distribution phases on testnet and weeks for mainnet
        let chain_id = starknet::get_execution_info().unbox().tx_info.unbox().chain_id;
        let age_of_game = if chain_id == MAINNET_CHAIN_ID {
            _age_of_game_weeks(self)
        } else {
            _age_of_game_hours(self)
        };

        // distribute all rewards to DAO until we get a reasonable third place score
        if (third_place_score < MINIMUM_SCORE_FOR_PAYOUTS) {
            Rewards {
                DAO: cost_to_play.into(),
                INTERFACE: 0,
                FIRST_PLACE: 0,
                SECOND_PLACE: 0,
                THIRD_PLACE: 0
            }
        } else if age_of_game > PHASE3_START.into() {
            // use phase 3 distribution
            Rewards {
                DAO: _calculate_payout(REWARD_DISTRIBUTIONS_PHASE3_BP::DAO, cost_to_play),
                INTERFACE: _calculate_payout(
                    REWARD_DISTRIBUTIONS_PHASE3_BP::INTERFACE, cost_to_play
                ),
                FIRST_PLACE: _calculate_payout(
                    REWARD_DISTRIBUTIONS_PHASE3_BP::FIRST_PLACE, cost_to_play
                ),
                SECOND_PLACE: _calculate_payout(
                    REWARD_DISTRIBUTIONS_PHASE3_BP::SECOND_PLACE, cost_to_play
                ),
                THIRD_PLACE: _calculate_payout(
                    REWARD_DISTRIBUTIONS_PHASE3_BP::THIRD_PLACE, cost_to_play
                )
            }
        } else if age_of_game > PHASE2_START.into() {
            Rewards {
                DAO: _calculate_payout(REWARD_DISTRIBUTIONS_PHASE2_BP::DAO, cost_to_play),
                INTERFACE: _calculate_payout(
                    REWARD_DISTRIBUTIONS_PHASE2_BP::INTERFACE, cost_to_play
                ),
                FIRST_PLACE: _calculate_payout(
                    REWARD_DISTRIBUTIONS_PHASE2_BP::FIRST_PLACE, cost_to_play
                ),
                SECOND_PLACE: _calculate_payout(
                    REWARD_DISTRIBUTIONS_PHASE2_BP::SECOND_PLACE, cost_to_play
                ),
                THIRD_PLACE: _calculate_payout(
                    REWARD_DISTRIBUTIONS_PHASE2_BP::THIRD_PLACE, cost_to_play
                )
            }
        } else {
            Rewards {
                DAO: _calculate_payout(REWARD_DISTRIBUTIONS_PHASE1_BP::DAO, cost_to_play),
                INTERFACE: _calculate_payout(
                    REWARD_DISTRIBUTIONS_PHASE1_BP::INTERFACE, cost_to_play
                ),
                FIRST_PLACE: _calculate_payout(
                    REWARD_DISTRIBUTIONS_PHASE1_BP::FIRST_PLACE, cost_to_play
                ),
                SECOND_PLACE: _calculate_payout(
                    REWARD_DISTRIBUTIONS_PHASE1_BP::SECOND_PLACE, cost_to_play
                ),
                THIRD_PLACE: _calculate_payout(
                    REWARD_DISTRIBUTIONS_PHASE1_BP::THIRD_PLACE, cost_to_play
                )
            }
        }
    }

    fn _process_payment_and_distribute_rewards(
        ref self: ContractState, client_address: ContractAddress
    ) {
        let caller = get_caller_address();
        let dao_address = self._dao.read();
        let leaderboard = self._leaderboard.read();
        let first_place_address = self._owner.read(leaderboard.first.adventurer_id.into());
        let second_place_address = self._owner.read(leaderboard.second.adventurer_id.into());
        let third_place_address = self._owner.read(leaderboard.third.adventurer_id.into());

        let rewards = _get_reward_distribution(@self);

        if (rewards.DAO != 0) {
            _lords_dispatcher(ref self).transferFrom(caller, dao_address, rewards.DAO);
        }

        if (rewards.INTERFACE != 0) {
            _lords_dispatcher(ref self).transferFrom(caller, client_address, rewards.INTERFACE);
        }

        if (rewards.FIRST_PLACE != 0) {
            _lords_dispatcher(ref self)
                .transferFrom(caller, first_place_address, rewards.FIRST_PLACE);
        }

        if (rewards.SECOND_PLACE != 0) {
            _lords_dispatcher(ref self)
                .transferFrom(caller, second_place_address, rewards.SECOND_PLACE);
        }

        if (rewards.THIRD_PLACE != 0) {
            _lords_dispatcher(ref self)
                .transferFrom(caller, third_place_address, rewards.THIRD_PLACE);
        }

        __event_RewardDistribution(
            ref self,
            RewardDistribution {
                first_place: PlayerReward {
                    adventurer_id: leaderboard.first.adventurer_id.into(),
                    rank: 1,
                    amount: rewards.FIRST_PLACE,
                    address: first_place_address
                },
                second_place: PlayerReward {
                    adventurer_id: leaderboard.second.adventurer_id.into(),
                    rank: 2,
                    amount: rewards.SECOND_PLACE,
                    address: second_place_address
                },
                third_place: PlayerReward {
                    adventurer_id: leaderboard.third.adventurer_id.into(),
                    rank: 3,
                    amount: rewards.THIRD_PLACE,
                    address: third_place_address
                },
                client: ClientReward { amount: rewards.INTERFACE, address: client_address },
                dao: rewards.DAO
            }
        );
    }

    fn _start_game(
        ref self: ContractState,
        weapon: u8,
        name: felt252,
        interface_camel: bool,
        vrf_fee_limit: u128
    ) {
        // increment adventurer id (first adventurer is id 1)
        let adventurer_id = self._game_counter.read() + 1;

        // randomness for starter beast isn't sensitive so we can use basic entropy
        let starter_beast_rnd = _get_basic_entropy(adventurer_id);

        // generate a new adventurer using the provided started weapon
        let mut adventurer = ImplAdventurer::new(weapon);

        // create meta data for the adventurer
        let adventurer_meta = ImplAdventurerMetadata::new(name, interface_camel);

        // adventurer immediately gets ambushed by a starter beast
        let beast_battle_details = _starter_beast_ambush(
            ref adventurer, adventurer_id, weapon, starter_beast_rnd
        );

        // request verifiable randomness for starting entropy
        let randomness_address = self._randomness_contract_address.read();
        request_randomness(randomness_address, adventurer.xp.into(), adventurer_id, vrf_fee_limit);

        // pack and save new adventurer and metadata
        _save_adventurer_no_boosts(ref self, adventurer, adventurer_id);
        _save_adventurer_metadata(ref self, adventurer_id, adventurer_meta);

        // increment the adventurer id counter
        self._game_counter.write(adventurer_id);

        // set caller as owner
        self._owner.write(adventurer_id, get_caller_address());

        // emit events 
        __event_StartGame(ref self, adventurer, adventurer_id, adventurer_meta);
        __event_AmbushedByBeast(ref self, adventurer, adventurer_id, beast_battle_details);
    }

    fn _starter_beast_ambush(
        ref adventurer: Adventurer,
        adventurer_id: felt252,
        starting_weapon: u8,
        adventurer_entropy: felt252
    ) -> BattleDetails {
        let beast_seed = adventurer.get_beast_seed(adventurer_entropy);

        // generate starter beast which will have weak armor against the adventurers starter weapon
        let starter_beast = ImplBeast::get_starter_beast(
            ImplLoot::get_type(starting_weapon), beast_seed
        );

        // spoof a beast ambush by deducting health from the adventurer
        adventurer.decrease_health(STARTER_BEAST_ATTACK_DAMAGE);

        // return battle details
        BattleDetails {
            seed: beast_seed,
            id: starter_beast.id,
            beast_specs: starter_beast.combat_spec,
            damage: STARTER_BEAST_ATTACK_DAMAGE,
            critical_hit: false,
            location: ImplCombat::slot_to_u8(
                AdventurerUtils::get_random_attack_location(adventurer_entropy)
            ),
        }
    }

    // _explore is called by the adventurer to explore the world
    // @param self: ContractState
    // @param adventurer: Adventurer
    // @param adventurer_id: felt252
    fn _explore(
        ref self: ContractState,
        ref adventurer: Adventurer,
        adventurer_id: felt252,
        adventurer_entropy: felt252,
        explore_till_beast: bool
    ) {
        // generate randomenss for exploration
        let (rnd1, rnd2) = AdventurerUtils::get_randomness(adventurer.xp, adventurer_entropy);

        // go exploring
        match AdventurerUtils::get_random_explore(rnd1) {
            ExploreResult::Beast(()) => {
                _beast_encounter(ref self, ref adventurer, adventurer_entropy, adventurer_id, rnd2);
            },
            ExploreResult::Obstacle(()) => {
                _obstacle_encounter(ref self, ref adventurer, adventurer_id, rnd2);
            },
            ExploreResult::Discovery(()) => {
                _process_discovery(ref self, ref adventurer, adventurer_id, rnd2);
            }
        }

        // if explore_till_beast is true and adventurer can still explore
        if explore_till_beast && adventurer.can_explore() {
            // Keep exploring
            _explore(
                ref self, ref adventurer, adventurer_id, adventurer_entropy, explore_till_beast
            );
        }
    }

    fn _alive_no_beast_no_upgrades(self: Adventurer) -> bool {
        self.health != 0 && self.beast_health == 0 && self.stat_upgrades_available == 0
    }

    fn _process_discovery(
        ref self: ContractState, ref adventurer: Adventurer, adventurer_id: felt252, entropy: u128
    ) {
        // TODO: Consider passing in adventurer ref into discover_treasure and handling
        //       adventurer mutations within lib functions. The lib functions could return
        //       a generic Discovery event which would be emitted here
        let (treasure_type, mut amount) = adventurer.discover_treasure(entropy);

        // Grant adventurer XP to ensure entropy changes
        let (previous_level, new_level) = adventurer.increase_adventurer_xp(XP_FOR_DISCOVERIES);

        match treasure_type {
            DiscoveryType::Gold(()) => {
                // add gold to adventurer
                adventurer.increase_gold(amount);
            },
            DiscoveryType::Health(()) => {
                // otherwise add health
                adventurer.increase_health(amount);
            }
        }

        __event_Discovery(ref self, adventurer, adventurer_id, amount, treasure_type,);

        // check for level up
        if (adventurer.stat_upgrades_available != 0) {
            // process level up
            _process_level_up(ref self, ref adventurer, adventurer_id, previous_level, new_level);
        }
    }

    fn _beast_encounter(
        ref self: ContractState,
        ref adventurer: Adventurer,
        adventurer_entropy: felt252,
        adventurer_id: felt252,
        entropy: u128
    ) {
        // get beast and beast seed
        let (beast, beast_seed) = adventurer.get_beast(adventurer_entropy);

        // init beast health (this is only info about beast that we store)
        adventurer.beast_health = beast.starting_health;

        // check if beast ambushed adventurer
        let is_ambushed = adventurer.is_ambushed(beast_seed);

        // if adventurer was ambushed
        if (is_ambushed) {
            // process beast attack
            let start_entropy = _load_adventurer_metadata(@self, adventurer_id).start_entropy;
            let beast_battle_details = _beast_attack(
                ref self,
                ref adventurer,
                adventurer_id,
                beast,
                beast_seed,
                start_entropy,
                entropy,
                entropy
            );
            __event_AmbushedByBeast(ref self, adventurer, adventurer_id, beast_battle_details);
            if (adventurer.health == 0) {
                _process_adventurer_death(ref self, ref adventurer, adventurer_id, beast.id, 0);
                return;
            }
        } else {
            // Emit Discover Beast event
            __event_DiscoveredBeast(ref self, adventurer, adventurer_id, beast_seed, beast);
        }
    }

    fn _obstacle_encounter(
        ref self: ContractState, ref adventurer: Adventurer, adventurer_id: felt252, entropy: u128
    ) {
        // get random obstacle
        let obstacle = adventurer.get_random_obstacle(entropy);

        // get a random attack location for the obstacle
        let damage_slot = AdventurerUtils::get_random_attack_location(entropy.into());

        // get armor at the location being attacked
        let armor = adventurer.equipment.get_item_at_slot(damage_slot);

        // get damage from obstalce
        let (combat_result, _) = adventurer.get_obstacle_damage(obstacle, armor, entropy);

        // pull damage taken out of combat result for easy access
        let damage_taken = combat_result.total_damage;

        // get base xp reward for obstacle
        let base_reward = obstacle.get_xp_reward();

        // get item xp reward for obstacle
        let item_xp_reward = base_reward * ITEM_XP_MULTIPLIER_OBSTACLES;

        // create obstacle details for event
        let obstacle_details = ObstacleDetails {
            id: obstacle.id,
            level: obstacle.combat_spec.level,
            damage_taken,
            damage_location: ImplCombat::slot_to_u8(damage_slot),
            critical_hit: combat_result.critical_hit_bonus > 0,
            adventurer_xp_reward: base_reward,
            item_xp_reward
        };

        // attempt to dodge obstacle
        let dodged = ImplCombat::ability_based_avoid_threat(
            adventurer.get_level(), adventurer.stats.intelligence, entropy
        );

        // if adventurer did not dodge obstacle
        if (!dodged) {
            // adventurer takes damage
            adventurer.decrease_health(damage_taken);

            // if adventurer died
            if (adventurer.health == 0) {
                // emit obstacle encounter event
                __event_ObstacleEncounter(
                    ref self, adventurer, adventurer_id, dodged, obstacle_details
                );
                // process death
                _process_adventurer_death(ref self, ref adventurer, adventurer_id, 0, obstacle.id);
                // return without granting xp to adventurer or items
                return;
            }
        }

        // grant adventurer xp and get previous and new level
        let (previous_level, new_level) = adventurer.increase_adventurer_xp(base_reward);

        // grant items xp and get array of items that leveled up
        let start_entropy = _load_adventurer_metadata(@self, adventurer_id).start_entropy;
        let items_leveled_up = _grant_xp_to_equipped_items(
            ref self, ref adventurer, adventurer_id, item_xp_reward, start_entropy
        );

        // emit obstacle encounter event after granting xp to adventurer and items
        __event_ObstacleEncounter(ref self, adventurer, adventurer_id, dodged, obstacle_details);

        // if items leveled up
        if items_leveled_up.len() != 0 {
            // emit item leveled up event
            __event_ItemsLeveledUp(ref self, adventurer, adventurer_id, items_leveled_up);
        }

        // if adventurer got new stat upgrades
        if (adventurer.stat_upgrades_available != 0) {
            // emit levled up event
            _process_level_up(ref self, ref adventurer, adventurer_id, previous_level, new_level);
        }
    }

    // @notice Grants XP to items currently equipped by an adventurer, and processes any level ups.// 
    // @dev This function does three main things:
    //   1. Iterates through each of the equipped items for the given adventurer.
    //   2. Increases the XP for the equipped item. If the item levels up, it processes the level up and updates the item.
    //   3. If any items have leveled up, emits an `ItemsLeveledUp` event.// 
    // @param self The contract's state reference.
    // @param adventurer Reference to the adventurer's state.
    // @param adventurer_id Unique identifier for the adventurer.
    // @param xp_amount Amount of XP to grant to each equipped item.
    // @param entropy Random data used for any deterministic randomness during processing.// 
    // @return Array of items that leveled up.
    fn _grant_xp_to_equipped_items(
        ref self: ContractState,
        ref adventurer: Adventurer,
        adventurer_id: felt252,
        xp_amount: u16,
        start_entropy: u64
    ) -> Array<ItemLeveledUp> {
        let mut items_leveled_up = ArrayTrait::<ItemLeveledUp>::new();
        let equipped_items = adventurer.get_equipped_items();
        let mut item_index: u32 = 0;
        loop {
            if item_index == equipped_items.len() {
                break;
            }
            // get item
            let item = *equipped_items.at(item_index);
            // increase item xp and record previous and new level
            let (previous_level, new_level) = adventurer
                .equipment
                .increase_item_xp_at_slot(ImplLoot::get_slot(item.id), xp_amount);
            // if item leveled up
            if new_level > previous_level {
                // process level up
                let updated_item = _process_item_level_up(
                    ref self, ref adventurer, item, previous_level, new_level, start_entropy
                );

                // add item to list of items that leveled up to be emitted in event
                items_leveled_up.append(updated_item);
            }

            item_index += 1;
        };

        items_leveled_up
    }

    fn _process_item_level_up(
        ref self: ContractState,
        ref adventurer: Adventurer,
        item: Item,
        previous_level: u8,
        new_level: u8,
        start_entropy: u64
    ) -> ItemLeveledUp {
        // init specials with no specials
        let mut specials = SpecialPowers { special1: 0, special2: 0, special3: 0 };

        // check if item reached greatness 20
        if (new_level == ITEM_MAX_GREATNESS) {
            // if so, adventurer gets a stat point as a reward
            adventurer.increase_stat_upgrades_available(MAX_GREATNESS_STAT_BONUS);
        }

        // check if item unlocked specials as part of level up
        let (suffix_unlocked, prefixes_unlocked) = ImplAdventurer::unlocked_specials(
            previous_level, new_level
        );

        // if specials were unlocked
        if (suffix_unlocked || prefixes_unlocked) {
            // apply them and record the new specials so we can include them in event

            specials = ImplLoot::get_specials(item.id, item.get_greatness(), start_entropy);

            // if item received a suffix as part of the level up
            if (suffix_unlocked) {
                // apply the item stat boosts so that subsequent events include this information
                adventurer.stats.apply_suffix_boost(specials.special1);

                // check if the suffix provided a vitality boost
                let vitality_boost = AdventurerUtils::get_vitality_item_boost(specials.special1);
                if (vitality_boost != 0) {
                    // if so, adventurer gets health
                    let health_amount = vitality_boost.into() * VITALITY_INSTANT_HEALTH_BONUS;
                    adventurer.increase_health(health_amount);
                }
            }
        }
        ItemLeveledUp {
            item_id: item.id,
            previous_level,
            new_level,
            suffix_unlocked,
            prefixes_unlocked,
            specials
        }
    }

    /// @notice Executes an adventurer's attack on a beast and manages the consequences of the combat
    /// @dev This function covers the entire combat process between an adventurer and a beast, including generating randomness for combat, handling the aftermath of the attack, and any subsequent counter-attacks by the beast.
    /// @param self The current contract state
    /// @param adventurer The attacking adventurer
    /// @param weapon_combat_spec The combat specifications of the adventurer's weapon
    /// @param adventurer_id The unique identifier of the adventurer
    /// @param adventurer_entropy A random value tied to the adventurer to aid in determining certain random aspects of the combat
    /// @param beast The defending beast
    /// @param beast_seed The seed associated with the beast
    /// @param fight_to_the_death Flag to indicate whether the adventurer should continue attacking until either they or the beast is defeated
    fn _attack(
        ref self: ContractState,
        ref adventurer: Adventurer,
        weapon_combat_spec: CombatSpec,
        adventurer_id: felt252,
        adventurer_entropy: felt252,
        start_entropy: u64,
        beast: Beast,
        beast_seed: u128,
        fight_to_the_death: bool,
    ) {
        // get two random numbers using adventurer xp and health as part of entropy
        let (rnd1, rnd2) = AdventurerUtils::get_randomness_with_health(
            adventurer.xp, adventurer.health, adventurer_entropy
        );

        // attack beast and get combat result that provides damage breakdown
        let combat_result = adventurer.attack(weapon_combat_spec, beast, rnd1);

        // provide critical hit as a boolean for events
        let is_critical_hit = combat_result.critical_hit_bonus > 0;

        // if the damage dealt exceeds the beasts health
        if (combat_result.total_damage >= adventurer.beast_health) {
            // process beast death
            _process_beast_death(
                ref self,
                ref adventurer,
                adventurer_id,
                beast,
                beast_seed,
                rnd2,
                combat_result.total_damage,
                is_critical_hit
            );
        } else {
            // if beast survived the attack, deduct damage dealt
            adventurer.beast_health -= combat_result.total_damage;

            // process beast counter attack
            let attacked_by_beast_details = _beast_attack(
                ref self,
                ref adventurer,
                adventurer_id,
                beast,
                beast_seed,
                start_entropy,
                rnd1,
                rnd2,
            );

            // emit events
            __event_AttackedBeast(
                ref self,
                adventurer,
                adventurer_id,
                BattleDetails {
                    seed: beast_seed,
                    id: beast.id,
                    beast_specs: beast.combat_spec,
                    damage: combat_result.total_damage,
                    critical_hit: is_critical_hit,
                    location: ImplCombat::slot_to_u8(Slot::None(())),
                }
            );
            __event_AttackedByBeast(ref self, adventurer, adventurer_id, attacked_by_beast_details);

            // if adventurer is dead
            if (adventurer.health == 0) {
                _process_adventurer_death(ref self, ref adventurer, adventurer_id, beast.id, 0);
                return;
            }

            // if the adventurer is still alive and fighting to the death
            if fight_to_the_death {
                // attack again
                _attack(
                    ref self,
                    ref adventurer,
                    weapon_combat_spec,
                    adventurer_id,
                    adventurer_entropy,
                    start_entropy,
                    beast,
                    beast_seed,
                    true
                );
            }
        }
    }

    /// @notice Simulates an attack by a beast on an adventurer
    /// @dev This function determines a random attack location on the adventurer, retrieves armor and specials from that location, processes the beast attack, and deducts the damage from the adventurer's health.
    /// @param self The current contract state
    /// @param adventurer The adventurer being attacked
    /// @param adventurer_id The unique identifier of the adventurer
    /// @param beast The beast that is attacking
    /// @param beast_seed The seed associated with the beast
    /// @param entropy A random value to determine certain random aspects of the combat
    /// @param attack_location_rnd A random value used to determine the attack location on the adventurer
    /// @return Returns a BattleDetails object containing details of the beast's attack, including the seed, beast ID, combat specifications of the beast, total damage dealt, whether a critical hit was made, and the location of the attack on the adventurer.
    fn _beast_attack(
        ref self: ContractState,
        ref adventurer: Adventurer,
        adventurer_id: felt252,
        beast: Beast,
        beast_seed: u128,
        start_entropy: u64,
        battle_entropy: u128,
        attack_location_rnd: u128,
    ) -> BattleDetails {
        // beasts attack random location on adventurer
        let attack_location = AdventurerUtils::get_random_attack_location(
            attack_location_rnd.into()
        );

        // get armor at attack location
        let armor = adventurer.equipment.get_item_at_slot(attack_location);

        // get armor specials
        let armor_specials = ImplLoot::get_specials(armor.id, armor.get_greatness(), start_entropy);

        // process beast attack
        let (combat_result, _jewlery_armor_bonus) = adventurer
            .defend(beast, armor, armor_specials, battle_entropy);

        // deduct damage taken from adventurer's health
        adventurer.decrease_health(combat_result.total_damage);

        // return beast battle details
        BattleDetails {
            seed: beast_seed,
            id: beast.id,
            beast_specs: beast.combat_spec,
            damage: combat_result.total_damage,
            critical_hit: combat_result.critical_hit_bonus > 0,
            location: ImplCombat::slot_to_u8(attack_location),
        }
    }

    // @notice Handles an attempt by the adventurer to flee from a battle with a beast.
    // @param self The contract's state.
    // @param adventurer The adventurer attempting to flee.
    // @param adventurer_id The unique ID of the adventurer.
    // @param adventurer_entropy The entropy related to the adventurer used for generating the beast.
    // @param beast_seed The seed related to the beast.
    // @param beast The beast that the adventurer is attempting to flee from.
    // @param flee_to_the_death Flag to indicate if the flee attempt should continue until either success or the adventurer's defeat.
    fn _flee(
        ref self: ContractState,
        ref adventurer: Adventurer,
        adventurer_id: felt252,
        adventurer_entropy: felt252,
        beast_seed: u128,
        beast: Beast,
        flee_to_the_death: bool
    ) {
        // get flee and ambush entropy seeds
        let (flee_entropy, ambush_entropy) = AdventurerUtils::get_randomness_with_health(
            adventurer.xp, adventurer.health, adventurer_entropy
        );

        // attempt to flee
        let fled = ImplBeast::attempt_flee(
            adventurer.get_level(), adventurer.stats.dexterity, flee_entropy
        );

        // if adventurer fled
        if (fled) {
            // set beast health to zero to denote adventurer is no longer in battle
            adventurer.beast_health = 0;

            // increment adventurer xp by one to change adventurer entropy state
            let (previous_level, new_level) = adventurer.increase_adventurer_xp(1);

            // emit flee attempt event
            __event_FleeSucceeded(ref self, adventurer, adventurer_id, beast_seed, beast);

            // check for adventurer level up
            if (adventurer.stat_upgrades_available != 0) {
                _process_level_up(
                    ref self, ref adventurer, adventurer_id, previous_level, new_level
                );
            }
        } else {
            // if the flee attempt failed, beast counter attacks
            let start_entropy = _load_adventurer_metadata(@self, adventurer_id).start_entropy;
            let beast_battle_details = _beast_attack(
                ref self,
                ref adventurer,
                adventurer_id,
                beast,
                beast_seed,
                start_entropy,
                ambush_entropy,
                ambush_entropy,
            );

            __event_FleeFailed(ref self, adventurer, adventurer_id, beast_seed, beast);
            __event_AttackedByBeast(ref self, adventurer, adventurer_id, beast_battle_details);

            // if player is still alive and elected to flee till death
            if (flee_to_the_death && adventurer.health != 0) {
                // reattempt flee
                _flee(
                    ref self,
                    ref adventurer,
                    adventurer_id,
                    adventurer_entropy,
                    beast_seed,
                    beast,
                    true
                );
            }
        }
    }

    // @notice Equips a specific item to the adventurer, and if there's an item already equipped in that slot, it's moved to the bag.
    // @param adventurer The reference to the adventurer's state.
    // @param bag The reference to the adventurer's bag.
    // @param item The primitive item to be equipped.
    // @return The ID of the item that has been unequipped.
    fn _equip_item(
        self: @ContractState,
        ref adventurer: Adventurer,
        ref bag: Bag,
        adventurer_id: felt252,
        item: Item
    ) -> u8 {
        // get the item currently equipped to the slot the item is being equipped to
        let unequipping_item = adventurer.equipment.get_item_at_slot(ImplLoot::get_slot(item.id));

        // if the item exists
        if unequipping_item.id != 0 {
            // put it into the adventurer's bag
            bag.add_item(unequipping_item);

            // if the item was providing a stat boosts, remove it
            if unequipping_item.get_greatness() >= SUFFIX_UNLOCK_GREANTESS {
                _remove_item_stat_boost(self, ref adventurer, adventurer_id, unequipping_item);
            }
        }

        // equip item
        adventurer.equipment.equip(item);

        // if item being equipped has stat boosts unlocked, apply it to adventurer
        if item.get_greatness() >= SUFFIX_UNLOCK_GREANTESS {
            _apply_item_stat_boost(self, ref adventurer, adventurer_id, item);
        }

        // return the item being unequipped for events
        unequipping_item.id
    }

    // @dev Equips an item to the adventurer by removing it from the bag and attaching it to the adventurer. If there's already an item in the slot being equipped, it moves the existing item to the bag.
    // @param self The contract state
    // @param adventurer The adventurer who is equipping the item
    // @param bag The bag containing the adventurer's items
    // @param adventurer_id The identifier of the adventurer
    // @param item_id The identifier of the item being equipped
    // @return an array of items that were unequipped as a result of equipping the items
    fn _equip_items(
        contract_state: @ContractState,
        ref adventurer: Adventurer,
        ref bag: Bag,
        adventurer_id: felt252,
        items_to_equip: Array<u8>,
        is_newly_purchased: bool
    ) -> Array<u8> {
        // mutable array from returning items that were unequipped as a result of equipping the items
        let mut unequipped_items = ArrayTrait::<u8>::new();

        // get a clone of our items to equip to keep ownership for event
        let _equipped_items = items_to_equip.clone();

        // for each item we need to equip
        let mut i: u32 = 0;
        loop {
            if i == items_to_equip.len() {
                break ();
            }

            // get the item id
            let item_id = *items_to_equip.at(i);

            // assume we won't need to unequip an item to equip new one
            let mut unequipped_item_id: u8 = 0;

            // if item is newly purchased
            if is_newly_purchased {
                // assert adventurer does not already own the item
                _assert_item_not_owned(adventurer, bag, item_id.clone());

                // create new item, equip it, and record if we need unequipped an item
                let mut new_item = ImplItem::new(item_id);
                unequipped_item_id =
                    _equip_item(contract_state, ref adventurer, ref bag, adventurer_id, new_item);
            } else {
                // otherwise item is being equipped from bag
                // so remove it from bag, equip it, and record if we need to unequip an item
                unequipped_item_id =
                    _equip_item(
                        contract_state,
                        ref adventurer,
                        ref bag,
                        adventurer_id,
                        bag.remove_item(item_id)
                    );
            }

            // if an item was unequipped
            if unequipped_item_id != 0 {
                // add it to our return array so we can emit these in events
                unequipped_items.append(unequipped_item_id);
            }

            i += 1;
        };

        unequipped_items
    }

    // @dev Drops multiple items from the adventurer's possessions, either from equipment or bag.
    // It tracks if the adventurer or the bag was mutated (updated).
    // @param self The contract state
    // @param adventurer The adventurer from which items will be dropped
    // @param bag The bag containing the adventurer's items
    // @param adventurer_id The identifier of the adventurer
    // @param items The list of items to be dropped
    // @return A tuple containing two boolean values. The first indicates if the adventurer was mutated, the second indicates if the bag was mutated
    fn _drop(
        ref self: ContractState,
        ref adventurer: Adventurer,
        ref bag: Bag,
        adventurer_id: felt252,
        items: Array<u8>,
    ) {
        // for each item
        let mut i: u32 = 0;
        loop {
            if i == items.len() {
                break ();
            }

            // get and drop item
            let item_id = *items.at(i);
            if adventurer.equipment.is_equipped(item_id) {
                adventurer.equipment.drop(item_id);
                adventurer.mutated = true;
            } else {
                let (item_in_bag, _) = bag.contains(item_id);
                if item_in_bag {
                    bag.remove_item(item_id);
                } else {
                    panic_with_felt252('Item not owned by adventurer');
                }
            }

            i += 1;
        };
    }

    // @dev Function to facilitate the purchase of multiple items.
    // @param adventurer The Adventurer struct instance representing the adventurer buying items.
    // @param bag The Bag struct instance representing the adventurer's current bag of items.
    // @param stat_upgrades_available The number of stat points available to the adventurer.
    // @param adventurer_id The unique identifier for the adventurer.
    // @param adventurer_entropy The entropy of the adventurer used for randomness.
    // @param items The Array of ItemPurchase instances representing items to be purchased.
    // @return A tuple containing three arrays: the first contains the items purchased, the second contains the items that were equipped as part of the purchase, and the third contains the items that were unequipped as a result of equipping the newly purchased items.
    fn _buy_items(
        contract_state: @ContractState,
        ref adventurer: Adventurer,
        ref bag: Bag,
        adventurer_id: felt252,
        stat_upgrades_available: u8,
        items_to_purchase: Array<ItemPurchase>,
    ) -> (Array<LootWithPrice>, Array<u8>, Array<u8>) {
        // get adventurer entropy
        let adventurer_entropy = _get_adventurer_entropy(contract_state, adventurer_id);

        // mutable array for returning items that need to be equipped as part of this purchase
        let mut unequipped_items = ArrayTrait::<u8>::new();
        let mut items_to_equip = ArrayTrait::<u8>::new();

        // iterate over item ids to purchase and store results in purchases array
        let mut purchases = ArrayTrait::<LootWithPrice>::new();
        let mut item_number: u32 = 0;
        loop {
            if item_number == items_to_purchase.len() {
                break ();
            }

            // get the item
            let item = *items_to_purchase.at(item_number);

            // assert item is available on market
            _assert_item_is_available(
                adventurer_entropy, stat_upgrades_available, adventurer.xp, item.item_id
            );

            // buy it and store result in our purchases array for event
            purchases.append(_buy_item(ref adventurer, ref bag, item.item_id));

            // if item is being equipped as part of the purchase 
            if item.equip {
                // add it to our array of items to equip
                items_to_equip.append(item.item_id);
            } else {
                // if it's not being equipped, just add it to bag
                bag.add_new_item(adventurer, item.item_id)
            }

            // increment counter
            item_number += 1;
        };

        // if we have items to equip as part of the purchase
        if (items_to_equip.len() != 0) {
            // equip them and record the items that were unequipped
            unequipped_items =
                _equip_items(
                    contract_state,
                    ref adventurer,
                    ref bag,
                    adventurer_id,
                    items_to_equip.clone(),
                    true
                );
        }

        (purchases, items_to_equip, unequipped_items)
    }

    // @notice Process the purchase of potions for the adventurer
    // @param adventurer reference to Adventurer to buy potions for
    // @param adventurer_id The ID of the adventurer
    // @param amount The number of potions to buy
    // @dev Emits a `PurchasedPotions` event
    // @dev Panics if the adventurer does not have enough gold or is buying more health than they can use.
    fn _buy_potions(
        ref self: ContractState, ref adventurer: Adventurer, adventurer_id: felt252, quantity: u8
    ) {
        let cost = adventurer.charisma_adjusted_potion_price() * quantity.into();
        let health = POTION_HEALTH_AMOUNT * quantity.into();

        // assert adventurer has enough gold to buy the potions
        _assert_has_enough_gold(adventurer, cost);

        // assert adventurer is not buying more health than they can use
        _assert_not_buying_excess_health(adventurer, health);

        // deduct cost of potions from adventurers gold balance
        adventurer.deduct_gold(cost);

        // add health to adventurer
        adventurer.increase_health(health);

        // emit purchased potions event
        __event_PurchasedPotions(ref self, adventurer, adventurer_id, quantity, cost, health);
    }

    // @notice Upgrades the stats of the adventurer.
    // @param adventurer The reference to the adventurer's state.
    // @param strength_increase The number of points to increase the strength stat.
    // @param dexterity_increase The number of points to increase the dexterity stat.
    // @param vitality_increase The number of points to increase the vitality stat.
    // @param intelligence_increase The number of points to increase the intelligence stat.
    // @param wisdom_increase The number of points to increase the wisdom stat.
    // @param charisma_increase The number of points to increase the charisma stat.
    // @dev Throws if not all available stats are being used.
    fn _upgrade_stats(self: @ContractState, ref adventurer: Adventurer, stat_upgrades: Stats) {
        if stat_upgrades.strength != 0 {
            adventurer.stats.increase_strength(stat_upgrades.strength);
        }
        if stat_upgrades.dexterity != 0 {
            adventurer.stats.increase_dexterity(stat_upgrades.dexterity);
        }
        if stat_upgrades.vitality != 0 {
            adventurer.stats.increase_vitality(stat_upgrades.vitality);
            adventurer
                .increase_health(VITALITY_INSTANT_HEALTH_BONUS * stat_upgrades.vitality.into());
        }
        if stat_upgrades.intelligence != 0 {
            adventurer.stats.increase_intelligence(stat_upgrades.intelligence);
        }
        if stat_upgrades.wisdom != 0 {
            adventurer.stats.increase_wisdom(stat_upgrades.wisdom);
        }
        if stat_upgrades.charisma != 0 {
            adventurer.stats.increase_charisma(stat_upgrades.charisma);
        }
        adventurer.stat_upgrades_available = 0;
    }

    // @notice Buy an item with the item price adjusted for adventurer's charisma.
    // @param adventurer The adventurer buying the item. The function modifies the adventurer's gold and equipment.
    // @param bag The bag of the adventurer. The function may add items to the bag if the adventurer unequips an item or opts not to equip a purchased item.
    // @param item_id The ID of the item to be purchased.
    // @return The item that was purchased and its price.
    fn _buy_item(ref adventurer: Adventurer, ref bag: Bag, item_id: u8) -> LootWithPrice {
        // create an immutable copy of our adventurer to use for validation
        let immutable_adventurer = adventurer;

        // assert adventurer does not already own the item
        _assert_item_not_owned(immutable_adventurer, bag, item_id);

        let item = ImplLoot::get_item(item_id);

        // get item price
        let base_item_price = ImplMarket::get_price(item.tier);

        // get item price after charisma discount
        let charisma_adjusted_price = adventurer.charisma_adjusted_item_price(base_item_price);

        // check adventurer has enough gold
        _assert_has_enough_gold(immutable_adventurer, charisma_adjusted_price);

        // deduct charisma adjusted cost of item from adventurer's gold balance
        adventurer.deduct_gold(charisma_adjusted_price);

        // return item with price
        LootWithPrice { item: item, price: charisma_adjusted_price }
    }

    // ------------------------------------------ //
    // ------------ Helper Functions ------------ //
    // ------------------------------------------ //
    fn _load_player_assets(
        self: @ContractState, adventurer_id: felt252
    ) -> (Adventurer, felt252, Bag) {
        let adventurer = _load_adventurer(self, adventurer_id);
        let adventurer_entropy = _get_adventurer_entropy(self, adventurer_id);
        let bag = _load_bag(self, adventurer_id);
        (adventurer, adventurer_entropy, bag)
    }

    fn _load_adventurer(self: @ContractState, adventurer_id: felt252) -> Adventurer {
        let mut adventurer = self._adventurer.read(adventurer_id);
        _apply_starting_stats(self, ref adventurer, adventurer_id);
        _apply_equipment_stat_boosts(self, ref adventurer, adventurer_id);
        _apply_luck(self, ref adventurer, adventurer_id);
        adventurer
    }
    fn _load_adventurer_no_boosts(self: @ContractState, adventurer_id: felt252) -> Adventurer {
        self._adventurer.read(adventurer_id)
    }

    fn _save_adventurer(
        ref self: ContractState, ref adventurer: Adventurer, adventurer_id: felt252,
    ) {
        _remove_starting_stats(@self, ref adventurer, adventurer_id);
        _remove_equipment_stat_boosts(@self, ref adventurer, adventurer_id);
        self._adventurer.write(adventurer_id, adventurer);
    }

    fn _save_adventurer_no_boosts(
        ref self: ContractState, adventurer: Adventurer, adventurer_id: felt252,
    ) {
        self._adventurer.write(adventurer_id, adventurer);
    }

    fn _apply_luck(self: @ContractState, ref adventurer: Adventurer, adventurer_id: felt252) {
        let bag = _load_bag(self, adventurer_id);
        adventurer.set_luck(bag);
    }
    fn _load_bag(self: @ContractState, adventurer_id: felt252) -> Bag {
        self._bag.read(adventurer_id)
    }
    #[inline(always)]
    fn _save_bag(ref self: ContractState, adventurer_id: felt252, bag: Bag) {
        self._bag.write(adventurer_id, bag);
    }

    fn _apply_starting_stats(
        self: @ContractState, ref adventurer: Adventurer, adventurer_id: felt252
    ) {
        let starting_stats = _load_adventurer_metadata(self, adventurer_id).starting_stats;
        adventurer.stats.apply_stat_boosts(starting_stats);
    }

    fn _remove_starting_stats(
        self: @ContractState, ref adventurer: Adventurer, adventurer_id: felt252
    ) {
        let starting_stats = _load_adventurer_metadata(self, adventurer_id).starting_stats;
        adventurer.stats.remove_stat_boosts(starting_stats);
    }
    fn _load_adventurer_metadata(
        self: @ContractState, adventurer_id: felt252
    ) -> AdventurerMetadata {
        self._adventurer_meta.read(adventurer_id)
    }

    fn _apply_item_stat_boost(
        self: @ContractState, ref adventurer: Adventurer, adventurer_id: felt252, item: Item
    ) {
        let start_entropy = _load_adventurer_metadata(self, adventurer_id).start_entropy;
        let item_suffix = ImplLoot::get_suffix(item.id, start_entropy);
        adventurer.stats.apply_suffix_boost(item_suffix);
    }

    fn _remove_item_stat_boost(
        self: @ContractState, ref adventurer: Adventurer, adventurer_id: felt252, item: Item
    ) {
        let start_entropy = _load_adventurer_metadata(self, adventurer_id).start_entropy;
        let item_suffix = ImplLoot::get_suffix(item.id, start_entropy);
        adventurer.stats.remove_suffix_boost(item_suffix);

        // if the adventurer's health is now above the max health due to a change in Vitality
        let max_health = AdventurerUtils::get_max_health(adventurer.stats.vitality);
        if adventurer.health > max_health {
            // lower adventurer's health to max health 
            adventurer.health = max_health;
        }
    }

    fn _apply_equipment_stat_boosts(
        self: @ContractState, ref adventurer: Adventurer, adventurer_id: felt252
    ) {
        if adventurer.equipment.has_specials() {
            let start_entropy = _load_adventurer_metadata(self, adventurer_id).start_entropy;
            let item_stat_boosts = adventurer.equipment.get_stat_boosts(start_entropy);
            adventurer.stats.apply_stat_boosts(item_stat_boosts);
        }
    }

    fn _remove_equipment_stat_boosts(
        self: @ContractState, ref adventurer: Adventurer, adventurer_id: felt252
    ) {
        if adventurer.equipment.has_specials() {
            let start_entropy = _load_adventurer_metadata(self, adventurer_id).start_entropy;
            let item_stat_boosts = adventurer.equipment.get_stat_boosts(start_entropy);
            adventurer.stats.remove_stat_boosts(item_stat_boosts);
        }
    }
    #[inline(always)]
    fn _save_adventurer_metadata(
        ref self: ContractState, adventurer_id: felt252, adventurer_meta: AdventurerMetadata
    ) {
        self._adventurer_meta.write(adventurer_id, adventurer_meta);
    }

    // @notice This function emits events relevant to adventurer leveling up
    // @dev In Loot Survivor, leveling up provides stat upgrades and access to the market
    // @param ref self A reference to the contract state.
    // @param ref adventurer A reference to the adventurer whose level is being updated.
    // @param adventurer_id The unique identifier of the adventurer.
    // @param previous_level The level of the adventurer before this level up.
    // @param new_level The new level of the adventurer after leveling up.
    fn _process_level_up(
        ref self: ContractState,
        ref adventurer: Adventurer,
        adventurer_id: felt252,
        previous_level: u8,
        new_level: u8,
    ) {
        let adventurer_entropy = _get_adventurer_entropy(@self, adventurer_id);

        // if adventurer is leveling from first level (starter beast)
        if (previous_level == 1) {
            // emit the leveled up event
            let adventurer_state = AdventurerState {
                owner: self._owner.read(adventurer_id),
                adventurer_id,
                adventurer_entropy,
                adventurer
            };
            __event_AdventurerLeveledUp(ref self, adventurer_state, previous_level, new_level);

            // if we already have adventurer entropy from VRF
            if (adventurer_entropy != 0) {
                // process initial entropy which will reveal starting stats and emit starting market
                process_initial_entropy(
                    ref self, ref adventurer, adventurer_id, adventurer_entropy
                );
            }
        } else if (new_level > previous_level) {
            // if this is any level up beyond the starter beast

            // get randomness rotation interval
            let randomness_rotation_interval = self._randomness_rotation_interval.read();

            // and check if adventurer has reached a level that merits entropy rotation
            if (previous_level
                / randomness_rotation_interval < new_level
                / randomness_rotation_interval) {
                // if they have, zero out current entropy
                self._adventurer_entropy.write(adventurer_id, 0);

                // request new entropy
                // TODO: make this dynamic
                let max_callback_fee = 10000000000000000;
                let randomness_address = self._randomness_contract_address.read();
                let seed = adventurer.get_vrf_seed(adventurer_id, adventurer_entropy);
                request_randomness(randomness_address, seed, adventurer_id, max_callback_fee);

                // emit ClearedEntropy event to let clients know the contact is fetching new entropy
                __event_ClearedEntropy(ref self, adventurer_id, randomness_address, seed);
            }

            // get new entropy
            let adventurer_entropy = _get_adventurer_entropy(@self, adventurer_id);
            let adventurer_state = AdventurerState {
                owner: self._owner.read(adventurer_id),
                adventurer_id,
                adventurer_entropy,
                adventurer
            };
            // emit the leveled up event
            __event_AdventurerLeveledUp(ref self, adventurer_state, previous_level, new_level);
        }
    }
    fn _assert_ownership(self: @ContractState, adventurer_id: felt252) {
        assert(self._owner.read(adventurer_id) == get_caller_address(), messages::NOT_OWNER);
    }
    fn _assert_in_battle(adventurer: Adventurer) {
        assert(adventurer.beast_health != 0, messages::NOT_IN_BATTLE);
    }
    fn _assert_dexterity_not_zero(adventurer: Adventurer) {
        assert(adventurer.stats.dexterity != 0, messages::ZERO_DEXTERITY);
    }
    fn _assert_not_in_battle(adventurer: Adventurer) {
        assert(adventurer.beast_health == 0, messages::ACTION_NOT_ALLOWED_DURING_BATTLE);
    }
    fn _assert_upgrades_available(adventurer: Adventurer) {
        assert(adventurer.stat_upgrades_available != 0, messages::MARKET_CLOSED);
    }
    fn _assert_item_not_owned(adventurer: Adventurer, bag: Bag, item_id: u8) {
        let (item_in_bag, _) = bag.contains(item_id);
        assert(
            adventurer.equipment.is_equipped(item_id) == false && item_in_bag == false,
            messages::ITEM_ALREADY_OWNED
        );
    }
    fn _assert_item_is_available(
        adventurer_entropy: felt252, stat_upgrades_available: u8, adventurer_xp: u16, item_id: u8
    ) {
        assert(
            ImplMarket::is_item_available(
                adventurer_entropy, adventurer_xp, stat_upgrades_available, item_id
            ),
            messages::ITEM_DOES_NOT_EXIST
        );
    }
    fn _assert_not_starter_beast(adventurer: Adventurer) {
        assert(adventurer.get_level() > 1, messages::CANT_FLEE_STARTER_BEAST);
    }
    fn _assert_no_stat_upgrades_available(adventurer: Adventurer) {
        assert(adventurer.stat_upgrades_available == 0, messages::STAT_UPGRADES_AVAILABLE);
    }
    fn _assert_not_dead(self: Adventurer) {
        assert(self.health != 0, messages::DEAD_ADVENTURER);
    }
    fn _assert_valid_starter_weapon(starting_weapon: u8) {
        assert(
            ImplLoot::is_starting_weapon(starting_weapon) == true, messages::INVALID_STARTING_WEAPON
        );
    }
    fn _assert_zero_luck(stats: Stats) {
        assert(stats.luck == 0, messages::NON_ZERO_STARTING_LUCK);
    }
    fn _assert_has_enough_gold(adventurer: Adventurer, cost: u16) {
        assert(adventurer.gold >= cost, messages::NOT_ENOUGH_GOLD);
    }
    fn _assert_not_buying_excess_health(adventurer: Adventurer, purchased_health: u16) {
        let adventurer_health_after_potions = adventurer.health + purchased_health;
        // assert adventurer is not buying more health than needed
        assert(
            adventurer_health_after_potions < AdventurerUtils::get_max_health(
                adventurer.stats.vitality
            )
                + POTION_HEALTH_AMOUNT,
            messages::HEALTH_FULL
        );
    }

    fn _assert_stat_balance(stat_upgrades: Stats, stat_upgrades_available: u8) {
        let stat_upgrade_count = stat_upgrades.strength
            + stat_upgrades.dexterity
            + stat_upgrades.vitality
            + stat_upgrades.intelligence
            + stat_upgrades.wisdom
            + stat_upgrades.charisma;

        if stat_upgrades_available < stat_upgrade_count {
            panic_with_felt252(messages::INSUFFICIENT_STAT_UPGRADES);
        } else if stat_upgrades_available > stat_upgrade_count {
            panic_with_felt252(messages::MUST_USE_ALL_STATS);
        }
    }
    fn _assert_valid_stat_selection(adventurer: Adventurer, stat_upgrades: Stats) {
        _assert_upgrades_available(adventurer);
        _assert_stat_balance(stat_upgrades, adventurer.stat_upgrades_available);
        _assert_zero_luck(stat_upgrades);
    }

    fn _assert_entropy_set(self: @ContractState, adventurer_id: felt252) {
        assert(
            self._adventurer_entropy.read(adventurer_id) != 0, messages::ADVENTURER_ENTROPY_NOT_SET
        );
    }
    #[inline(always)]
    fn _lords_address(self: @ContractState) -> ContractAddress {
        self._lords.read()
    }
    #[inline(always)]
    fn _dao_address(self: @ContractState) -> ContractAddress {
        self._dao.read()
    }
    #[inline(always)]
    fn _get_items_on_market(
        self: @ContractState,
        adventurer_entropy: felt252,
        adventurer_xp: u16,
        adventurer_stat_points: u8
    ) -> Array<u8> {
        ImplMarket::get_market_items(adventurer_entropy, adventurer_xp, adventurer_stat_points)
    }
    #[inline(always)]
    fn _get_items_on_market_by_slot(
        self: @ContractState,
        adventurer_entropy: felt252,
        adventurer_xp: u16,
        adventurer_stat_points: u8,
        slot: Slot
    ) -> Array<u8> {
        ImplMarket::get_items_by_slot(
            adventurer_entropy, adventurer_xp, adventurer_stat_points, slot
        )
    }

    #[inline(always)]
    fn _get_items_on_market_by_tier(
        self: @ContractState,
        adventurer_entropy: felt252,
        adventurer_xp: u16,
        adventurer_stat_points: u8,
        tier: Tier
    ) -> Array<u8> {
        ImplMarket::get_items_by_tier(
            adventurer_entropy, adventurer_xp, adventurer_stat_points, tier
        )
    }

    #[inline(always)]
    fn _get_potion_price(self: @ContractState, adventurer_id: felt252) -> u16 {
        _load_adventurer(self, adventurer_id).charisma_adjusted_potion_price()
    }

    fn _get_item_price(self: @ContractState, adventurer_id: felt252, item_id: u8) -> u16 {
        let base_item_price = ImplMarket::get_price(ImplLoot::get_tier(item_id));
        _load_adventurer(self, adventurer_id).charisma_adjusted_item_price(base_item_price)
    }

    fn _get_attacking_beast(self: @ContractState, adventurer_id: felt252) -> Beast {
        // get adventurer
        let adventurer = _load_adventurer_no_boosts(self, adventurer_id);

        // assert adventurer is in battle
        assert(adventurer.beast_health != 0, messages::NOT_IN_BATTLE);

        // get adventurer entropy
        let adventurer_entropy = _get_adventurer_entropy(self, adventurer_id);

        // get beast and beast seed
        let (beast, _) = adventurer.get_beast(adventurer_entropy);

        // return beast
        beast
    }

    #[inline(always)]
    fn _get_adventurer_entropy(self: @ContractState, adventurer_id: felt252) -> felt252 {
        self._adventurer_entropy.read(adventurer_id)
    }

    #[inline(always)]
    fn _get_basic_entropy(adventurer_id: felt252) -> felt252 {
        let mut hash_span = ArrayTrait::new();
        hash_span.append(adventurer_id);
        poseidon_hash_span(hash_span.span())
    }

    #[inline(always)]
    fn _is_top_score(self: @ContractState, score: u16) -> bool {
        if score > self._leaderboard.read().third.xp {
            true
        } else {
            false
        }
    }

    fn _update_owner_to_primary_account(ref self: ContractState, adventurer_id: felt252) {
        let interface_camel = _load_adventurer_metadata(@self, adventurer_id).interface_camel;
        let owner_address = self._owner.read(adventurer_id);
        let primary_address = _get_primary_account_address(@self, owner_address, interface_camel);
        if primary_address != self._owner.read(adventurer_id) {
            self._owner.write(adventurer_id, primary_address)
        }
    }

    // @title Update Leaderboard Function
    //
    // @param adventurer_id The unique identifier of the adventurer
    // @param adventurer The adventurer that scored a new high score
    fn _update_leaderboard(
        ref self: ContractState, adventurer_id: felt252, adventurer: Adventurer
    ) {
        // if player was using an Arcade Account (AA), update owner of their adventurer to their Primary Account (PA)
        // so their rewards get distributed to their PA instead of AA
        _update_owner_to_primary_account(ref self, adventurer_id);

        // get current leaderboard which will be mutated as part of this function
        let mut leaderboard = self._leaderboard.read();

        // create a score struct for the players score
        let player_score = Score {
            adventurer_id: adventurer_id.try_into().unwrap(),
            xp: adventurer.xp,
            gold: adventurer.gold
        };

        let mut player_rank = 0;

        // shift leaderboard based on players placement
        if player_score.xp > leaderboard.first.xp {
            leaderboard.third = leaderboard.second;
            leaderboard.second = leaderboard.first;
            leaderboard.first = player_score;
            player_rank = 1;
        } else if player_score.xp > leaderboard.second.xp {
            leaderboard.third = leaderboard.second;
            leaderboard.second = player_score;
            player_rank = 2;
        } else if player_score.xp > leaderboard.third.xp {
            leaderboard.third = player_score;
            player_rank = 3;
        }

        // emit new high score event
        __event_NewHighScore(ref self, adventurer_id, adventurer, player_rank);

        // save leaderboard
        self._leaderboard.write(leaderboard);
    }

    // ---------- EVENTS ---------- //
    #[derive(Copy, Drop, Serde, starknet::Event)]
    struct AdventurerState {
        owner: ContractAddress,
        adventurer_id: felt252,
        adventurer_entropy: felt252,
        adventurer: Adventurer
    }

    #[derive(Copy, Drop, Serde, starknet::Event)]
    struct AdventurerStateWithBag {
        adventurer_state: AdventurerState,
        bag: Bag
    }

    #[derive(Drop, starknet::Event)]
    struct StartGame {
        adventurer_state: AdventurerState,
        adventurer_meta: AdventurerMetadata,
        reveal_block: u64,
    }

    #[derive(Drop, Serde, starknet::Event)]
    struct Discovery {
        adventurer_state: AdventurerState,
        amount: u16
    }

    #[derive(Drop, starknet::Event)]
    struct DiscoveredGold {
        discovery: Discovery
    }

    #[derive(Drop, starknet::Event)]
    struct DiscoveredHealth {
        discovery: Discovery
    }

    #[derive(Drop, Serde, starknet::Event)]
    struct ObstacleEvent {
        adventurer_state: AdventurerState,
        obstacle_details: ObstacleDetails,
    }

    #[derive(Drop, Serde)]
    struct ObstacleDetails {
        id: u8,
        level: u16,
        damage_taken: u16,
        damage_location: u8,
        critical_hit: bool,
        adventurer_xp_reward: u16,
        item_xp_reward: u16,
    }

    #[derive(Drop, starknet::Event)]
    struct DodgedObstacle {
        obstacle_event: ObstacleEvent
    }

    #[derive(Drop, starknet::Event)]
    struct HitByObstacle {
        obstacle_event: ObstacleEvent
    }

    #[derive(Drop, starknet::Event)]
    struct DiscoveredBeast {
        adventurer_state: AdventurerState,
        seed: u128,
        id: u8,
        beast_specs: CombatSpec,
    }

    #[derive(Drop, Serde, starknet::Event)]
    struct BattleDetails {
        seed: u128,
        id: u8,
        beast_specs: CombatSpec,
        damage: u16,
        critical_hit: bool,
        location: u8,
    }

    #[derive(Drop, starknet::Event)]
    struct AmbushedByBeast {
        adventurer_state: AdventurerState,
        beast_battle_details: BattleDetails,
    }

    #[derive(Drop, starknet::Event)]
    struct AttackedBeast {
        adventurer_state: AdventurerState,
        beast_battle_details: BattleDetails,
    }

    #[derive(Drop, starknet::Event)]
    struct AttackedByBeast {
        adventurer_state: AdventurerState,
        beast_battle_details: BattleDetails,
    }

    #[derive(Drop, starknet::Event)]
    struct SlayedBeast {
        adventurer_state: AdventurerState,
        seed: u128,
        id: u8,
        beast_specs: CombatSpec,
        damage_dealt: u16,
        critical_hit: bool,
        xp_earned_adventurer: u16,
        xp_earned_items: u16,
        gold_earned: u16,
    }

    #[derive(Drop, Serde)]
    struct FleeEvent {
        adventurer_state: AdventurerState,
        seed: u128,
        id: u8,
        beast_specs: CombatSpec,
    }

    #[derive(Drop, starknet::Event)]
    struct FleeFailed {
        flee_event: FleeEvent
    }

    #[derive(Drop, starknet::Event)]
    struct FleeSucceeded {
        flee_event: FleeEvent
    }

    #[derive(Drop, starknet::Event)]
    struct PurchasedPotions {
        adventurer_state: AdventurerState,
        quantity: u8,
        cost: u16,
        health: u16,
    }

    #[derive(Drop, starknet::Event)]
    struct PurchasedItems {
        adventurer_state_with_bag: AdventurerStateWithBag,
        purchases: Array<LootWithPrice>,
    }

    #[derive(Clone, Drop, starknet::Event)]
    struct EquippedItems {
        adventurer_state_with_bag: AdventurerStateWithBag,
        equipped_items: Array<u8>,
        unequipped_items: Array<u8>,
    }

    #[derive(Clone, Drop, starknet::Event)]
    struct DroppedItems {
        adventurer_state_with_bag: AdventurerStateWithBag,
        item_ids: Array<u8>,
    }

    #[derive(Drop, Serde)]
    struct ItemLeveledUp {
        item_id: u8,
        previous_level: u8,
        new_level: u8,
        suffix_unlocked: bool,
        prefixes_unlocked: bool,
        specials: SpecialPowers
    }

    #[derive(Drop, starknet::Event)]
    struct ItemsLeveledUp {
        adventurer_state: AdventurerState,
        items: Array<ItemLeveledUp>,
    }

    #[derive(Drop, starknet::Event)]
    struct NewHighScore {
        adventurer_state: AdventurerState,
        rank: u8, // 1-3
    }

    #[derive(Clone, Drop, starknet::Event)]
    struct AdventurerDied {
        adventurer_state: AdventurerState,
        death_details: DeathDetails
    }

    #[derive(Clone, Drop, Serde)]
    struct DeathDetails {
        killed_by_beast: u8,
        killed_by_obstacle: u8,
        caller_address: ContractAddress,
    }

    #[derive(Drop, starknet::Event)]
    struct AdventurerLeveledUp {
        adventurer_state: AdventurerState,
        previous_level: u8,
        new_level: u8,
    }

    #[derive(Drop, starknet::Event)]
    struct UpgradesAvailable {
        adventurer_state: AdventurerState,
        items: Array<u8>,
    }

    #[derive(Drop, starknet::Event)]
    struct AdventurerUpgraded {
        adventurer_state_with_bag: AdventurerStateWithBag,
        strength_increase: u8,
        dexterity_increase: u8,
        vitality_increase: u8,
        intelligence_increase: u8,
        wisdom_increase: u8,
        charisma_increase: u8,
    }

    #[derive(Drop, starknet::Event)]
    struct RewardDistribution {
        first_place: PlayerReward,
        second_place: PlayerReward,
        third_place: PlayerReward,
        client: ClientReward,
        dao: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct PriceChangeEvent {
        previous_price: u128,
        new_price: u128,
        lords_price: u128,
        changer: ContractAddress
    }

    #[derive(Drop, starknet::Event)]
    struct ClearedEntropy {
        adventurer_id: felt252,
        vrf_address: ContractAddress,
        seed: u64
    }

    #[derive(Drop, starknet::Event)]
    struct ReceivedEntropy {
        adventurer_id: felt252,
        vrf_address: ContractAddress,
        rnd: felt252
    }

    #[derive(Drop, Serde)]
    struct PlayerReward {
        adventurer_id: felt252,
        rank: u8,
        amount: u256,
        address: ContractAddress,
    }

    #[derive(Drop, Serde)]
    struct ClientReward {
        amount: u256,
        address: ContractAddress,
    }

    fn __event_RewardDistribution(ref self: ContractState, event: RewardDistribution) {
        self.emit(event);
    }
    fn __event_ClearedEntropy(
        ref self: ContractState, adventurer_id: felt252, vrf_address: ContractAddress, seed: u64
    ) {
        self.emit(ClearedEntropy { adventurer_id, vrf_address, seed });
    }
    fn __event_ReceivedEntropy(
        ref self: ContractState, adventurer_id: felt252, vrf_address: ContractAddress, rnd: felt252
    ) {
        self.emit(ReceivedEntropy { adventurer_id, vrf_address, rnd });
    }
    fn __event_AdventurerUpgraded(
        ref self: ContractState,
        adventurer: Adventurer,
        adventurer_id: felt252,
        bag: Bag,
        stat_upgrades: Stats
    ) {
        let adventurer_entropy = _get_adventurer_entropy(@self, adventurer_id);
        let adventurer_state = AdventurerState {
            owner: self._owner.read(adventurer_id), adventurer_id, adventurer_entropy, adventurer
        };
        let adventurer_state_with_bag = AdventurerStateWithBag { adventurer_state, bag };
        self
            .emit(
                AdventurerUpgraded {
                    adventurer_state_with_bag,
                    strength_increase: stat_upgrades.strength,
                    dexterity_increase: stat_upgrades.dexterity,
                    vitality_increase: stat_upgrades.vitality,
                    intelligence_increase: stat_upgrades.intelligence,
                    wisdom_increase: stat_upgrades.wisdom,
                    charisma_increase: stat_upgrades.charisma,
                }
            );
    }

    fn __event_StartGame(
        ref self: ContractState,
        adventurer: Adventurer,
        adventurer_id: felt252,
        adventurer_meta: AdventurerMetadata
    ) {
        let adventurer_entropy = _get_adventurer_entropy(@self, adventurer_id);
        let adventurer_state = AdventurerState {
            owner: self._owner.read(adventurer_id), adventurer_id, adventurer_entropy, adventurer
        };

        let reveal_block = 0; // TODO: consider removing this

        self.emit(StartGame { adventurer_state, adventurer_meta, reveal_block });
    }

    fn __event_Discovery(
        ref self: ContractState,
        adventurer: Adventurer,
        adventurer_id: felt252,
        amount: u16,
        discovery_type: DiscoveryType
    ) {
        let adventurer_entropy = _get_adventurer_entropy(@self, adventurer_id);
        let adventurer_state = AdventurerState {
            owner: self._owner.read(adventurer_id), adventurer_id, adventurer_entropy, adventurer
        };

        let discovery = Discovery { adventurer_state, amount };

        match discovery_type {
            DiscoveryType::Gold => { self.emit(DiscoveredGold { discovery }); },
            DiscoveryType::Health => { self.emit(DiscoveredHealth { discovery }); }
        }
    }

    fn __event_ObstacleEncounter(
        ref self: ContractState,
        adventurer: Adventurer,
        adventurer_id: felt252,
        dodged: bool,
        obstacle_details: ObstacleDetails,
    ) {
        let adventurer_entropy = _get_adventurer_entropy(@self, adventurer_id);
        let adventurer_state = AdventurerState {
            owner: self._owner.read(adventurer_id), adventurer_id, adventurer_entropy, adventurer
        };

        let obstacle_event = ObstacleEvent { adventurer_state, obstacle_details, };

        if dodged {
            self.emit(DodgedObstacle { obstacle_event });
        } else {
            self.emit(HitByObstacle { obstacle_event });
        }
    }

    fn __event_DiscoveredBeast(
        ref self: ContractState,
        adventurer: Adventurer,
        adventurer_id: felt252,
        seed: u128,
        beast: Beast
    ) {
        let adventurer_entropy = _get_adventurer_entropy(@self, adventurer_id);
        let adventurer_state = AdventurerState {
            owner: self._owner.read(adventurer_id), adventurer_id, adventurer_entropy, adventurer
        };

        let discovered_beast_event = DiscoveredBeast {
            adventurer_state, seed, id: beast.id, beast_specs: beast.combat_spec
        };
        self.emit(discovered_beast_event);
    }

    fn __event_AttackedBeast(
        ref self: ContractState,
        adventurer: Adventurer,
        adventurer_id: felt252,
        beast_battle_details: BattleDetails
    ) {
        let adventurer_entropy = _get_adventurer_entropy(@self, adventurer_id);
        let adventurer_state = AdventurerState {
            owner: self._owner.read(adventurer_id), adventurer_id, adventurer_entropy, adventurer
        };
        self.emit(AttackedBeast { adventurer_state, beast_battle_details });
    }

    fn __event_AttackedByBeast(
        ref self: ContractState,
        adventurer: Adventurer,
        adventurer_id: felt252,
        beast_battle_details: BattleDetails
    ) {
        let adventurer_entropy = _get_adventurer_entropy(@self, adventurer_id);
        let adventurer_state = AdventurerState {
            owner: self._owner.read(adventurer_id), adventurer_id, adventurer_entropy, adventurer
        };
        self.emit(AttackedByBeast { adventurer_state, beast_battle_details });
    }

    fn __event_AmbushedByBeast(
        ref self: ContractState,
        adventurer: Adventurer,
        adventurer_id: felt252,
        beast_battle_details: BattleDetails
    ) {
        let adventurer_entropy = _get_adventurer_entropy(@self, adventurer_id);
        let adventurer_state = AdventurerState {
            owner: self._owner.read(adventurer_id), adventurer_id, adventurer_entropy, adventurer
        };
        self.emit(AmbushedByBeast { adventurer_state, beast_battle_details });
    }

    fn __event_SlayedBeast(
        ref self: ContractState,
        adventurer: Adventurer,
        adventurer_id: felt252,
        seed: u128,
        beast: Beast,
        damage_dealt: u16,
        critical_hit: bool,
        xp_earned_adventurer: u16,
        xp_earned_items: u16,
        gold_earned: u16
    ) {
        let adventurer_entropy = _get_adventurer_entropy(@self, adventurer_id);
        let adventurer_state = AdventurerState {
            owner: self._owner.read(adventurer_id), adventurer_id, adventurer_entropy, adventurer
        };
        let slayed_beast_event = SlayedBeast {
            adventurer_state,
            seed,
            id: beast.id,
            beast_specs: beast.combat_spec,
            damage_dealt,
            critical_hit,
            xp_earned_adventurer,
            xp_earned_items,
            gold_earned,
        };
        self.emit(slayed_beast_event);
    }

    fn __event_FleeFailed(
        ref self: ContractState,
        adventurer: Adventurer,
        adventurer_id: felt252,
        seed: u128,
        beast: Beast
    ) {
        let adventurer_entropy = _get_adventurer_entropy(@self, adventurer_id);
        let adventurer_state = AdventurerState {
            owner: self._owner.read(adventurer_id), adventurer_id, adventurer_entropy, adventurer
        };
        let flee_event = FleeEvent {
            adventurer_state, seed, id: beast.id, beast_specs: beast.combat_spec
        };
        self.emit(FleeFailed { flee_event });
    }

    fn __event_FleeSucceeded(
        ref self: ContractState,
        adventurer: Adventurer,
        adventurer_id: felt252,
        seed: u128,
        beast: Beast
    ) {
        let adventurer_entropy = _get_adventurer_entropy(@self, adventurer_id);
        let adventurer_state = AdventurerState {
            owner: self._owner.read(adventurer_id), adventurer_id, adventurer_entropy, adventurer
        };
        let flee_event = FleeEvent {
            adventurer_state, seed, id: beast.id, beast_specs: beast.combat_spec
        };
        self.emit(FleeSucceeded { flee_event });
    }

    fn __event_EquippedItems(
        ref self: ContractState,
        adventurer: Adventurer,
        adventurer_id: felt252,
        bag: Bag,
        equipped_items: Array<u8>,
        unequipped_items: Array<u8>,
    ) {
        let adventurer_entropy = _get_adventurer_entropy(@self, adventurer_id);
        let adventurer_state = AdventurerState {
            owner: self._owner.read(adventurer_id), adventurer_id, adventurer_entropy, adventurer
        };
        let adventurer_state_with_bag = AdventurerStateWithBag { adventurer_state, bag };
        let equipped_items_event = EquippedItems {
            adventurer_state_with_bag, equipped_items, unequipped_items,
        };
        self.emit(equipped_items_event);
    }

    fn __event_DroppedItems(
        ref self: ContractState,
        adventurer: Adventurer,
        adventurer_id: felt252,
        bag: Bag,
        item_ids: Array<u8>,
    ) {
        let adventurer_entropy = _get_adventurer_entropy(@self, adventurer_id);
        let adventurer_state = AdventurerState {
            owner: self._owner.read(adventurer_id), adventurer_id, adventurer_entropy, adventurer
        };
        let adventurer_state_with_bag = AdventurerStateWithBag { adventurer_state, bag };
        self.emit(DroppedItems { adventurer_state_with_bag, item_ids });
    }

    fn __event_ItemsLeveledUp(
        ref self: ContractState,
        adventurer: Adventurer,
        adventurer_id: felt252,
        items: Array<ItemLeveledUp>,
    ) {
        let adventurer_entropy = _get_adventurer_entropy(@self, adventurer_id);
        let adventurer_state = AdventurerState {
            owner: self._owner.read(adventurer_id), adventurer_id, adventurer_entropy, adventurer
        };
        self.emit(ItemsLeveledUp { adventurer_state, items });
    }

    fn __event_NewHighScore(
        ref self: ContractState, adventurer_id: felt252, adventurer: Adventurer, rank: u8
    ) {
        let adventurer_entropy = _get_adventurer_entropy(@self, adventurer_id);
        let adventurer_state = AdventurerState {
            owner: self._owner.read(adventurer_id), adventurer_id, adventurer_entropy, adventurer
        };
        self.emit(NewHighScore { adventurer_state, rank });
    }

    fn __event_AdventurerDied(ref self: ContractState, adventurer_died_event: AdventurerDied) {
        self.emit(adventurer_died_event);
    }

    fn __event_AdventurerLeveledUp(
        ref self: ContractState,
        adventurer_state: AdventurerState,
        previous_level: u8,
        new_level: u8,
    ) {
        self.emit(AdventurerLeveledUp { adventurer_state, previous_level, new_level });
    }

    fn __event_UpgradesAvailable(
        ref self: ContractState, adventurer_state: AdventurerState, items: Array<u8>
    ) {
        self.emit(UpgradesAvailable { adventurer_state, items });
    }

    fn __event_PurchasedItems(
        ref self: ContractState,
        adventurer: Adventurer,
        adventurer_id: felt252,
        bag: Bag,
        purchases: Array<LootWithPrice>
    ) {
        let adventurer_entropy = _get_adventurer_entropy(@self, adventurer_id);
        let adventurer_state = AdventurerState {
            owner: self._owner.read(adventurer_id), adventurer_id, adventurer_entropy, adventurer
        };
        let adventurer_state_with_bag = AdventurerStateWithBag { adventurer_state, bag };
        self.emit(PurchasedItems { adventurer_state_with_bag, purchases });
    }

    fn __event_PurchasedPotions(
        ref self: ContractState,
        adventurer: Adventurer,
        adventurer_id: felt252,
        quantity: u8,
        cost: u16,
        health: u16
    ) {
        let adventurer_entropy = _get_adventurer_entropy(@self, adventurer_id);
        let adventurer_state = AdventurerState {
            owner: self._owner.read(adventurer_id), adventurer_id, adventurer_entropy, adventurer
        };
        self.emit(PurchasedPotions { adventurer_state, quantity, cost, health, });
    }

    #[starknet::interface]
    trait ILeetLoot<T> {
        fn mint(
            ref self: T,
            to: ContractAddress,
            beast: u8,
            prefix: u8,
            suffix: u8,
            level: u16,
            health: u16
        );
        fn isMinted(self: @T, beast: u8, prefix: u8, suffix: u8) -> bool;
        fn getMinter(self: @T) -> ContractAddress;
    }

    fn _can_play(self: @ContractState, token_id: u256) -> bool {
        _last_usage(self, token_id) + SECONDS_IN_DAY.into() <= get_block_timestamp().into()
    }

    fn _get_primary_account_address(
        self: @ContractState, address: ContractAddress, interface_camel: bool
    ) -> ContractAddress {
        if interface_camel {
            let account_camel = ISRC5CamelDispatcher { contract_address: address };
            if account_camel.supportsInterface(ARCADE_ACCOUNT_ID) {
                IMasterControlDispatcher { contract_address: address }.get_master_account()
            } else {
                address
            }
        } else {
            let account_snake = ISRC5Dispatcher { contract_address: address };
            if account_snake.supports_interface(ARCADE_ACCOUNT_ID) {
                IMasterControlDispatcher { contract_address: address }.get_master_account()
            } else {
                address
            }
        }
    }

    fn _play_with_token(ref self: ContractState, token_id: u256, interface_camel: bool) {
        assert(_can_play(@self, token_id), messages::CANNOT_PLAY_WITH_TOKEN);

        let golden_token = _golden_token_dispatcher(ref self);

        // we use caller address here because we don't have an adventurer id yet
        let address = get_caller_address();
        let player = _get_primary_account_address(@self, address, interface_camel);
        assert(golden_token.owner_of(token_id) == player, messages::NOT_OWNER_OF_TOKEN);

        self
            ._golden_token_last_use
            .write(token_id.try_into().unwrap(), get_block_timestamp().into());
    }

    fn _last_usage(self: @ContractState, token_id: u256) -> u256 {
        self._golden_token_last_use.read(token_id.try_into().unwrap()).into()
    }
}
