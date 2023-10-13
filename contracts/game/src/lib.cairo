mod game {
    mod constants;
    mod interfaces;
}
mod tests {
    mod test_game;
}

#[starknet::contract]
mod Game {
    // TODO: TESTING CONFIGS 
    // ADJUST THESE BEFORE DEPLOYMENT
    const TEST_ENTROPY: u64 = 12303548;
    const MINIMUM_SCORE_FOR_PAYOUTS: u16 = 100;
    const LOOT_NAME_STORAGE_INDEX_1: u8 = 0;
    const LOOT_NAME_STORAGE_INDEX_2: u8 = 1;

    use core::{
        array::{SpanTrait, ArrayTrait}, integer::u256_try_as_non_zero, traits::{TryInto, Into},
        clone::Clone, poseidon::poseidon_hash_span, option::OptionTrait, box::BoxTrait,
        starknet::{
            get_caller_address, ContractAddress, ContractAddressIntoFelt252, contract_address_const,
            get_block_timestamp
        },
    };

    use openzeppelin::token::erc20::interface::{
        IERC20Camel, IERC20CamelDispatcher, IERC20CamelDispatcherTrait, IERC20CamelLibraryDispatcher
    };
    use openzeppelin::introspection::interface::{ISRC5Dispatcher, ISRC5DispatcherTrait};

    use openzeppelin::token::erc721::interface::{
        IERC721, IERC721Dispatcher, IERC721DispatcherTrait, IERC721LibraryDispatcher
    };

    use goldenToken::ERC721::{
        GoldenToken, GoldenTokenDispatcher, GoldenTokenDispatcherTrait, GoldenTokenLibraryDispatcher
    };

    use arcade_account::{
        account::interface::{
            IMasterControl, IMasterControlDispatcher, IMasterControlDispatcherTrait
        },
        Account, ARCADE_ACCOUNT_ID
    };

    use super::game::{
        interfaces::{IGame},
        constants::{
            messages, Week, REWARD_DISTRIBUTIONS_PHASE1, REWARD_DISTRIBUTIONS_PHASE2,
            REWARD_DISTRIBUTIONS_PHASE3, BLOCKS_IN_A_WEEK, COST_TO_PLAY, U64_MAX, U128_MAX,
            STARTER_BEAST_ATTACK_DAMAGE, NUM_STARTING_STATS,
            STARTING_GAME_ENTROPY_ROTATION_INTERVAL, MINIMUM_DAMAGE_FROM_BEASTS
        }
    };
    use lootitems::{
        loot::{ILoot, Loot, ImplLoot}, constants::{ItemId, NamePrefixLength, NameSuffixLength}
    };
    use survivor::{
        adventurer::{Adventurer, ImplAdventurer, IAdventurer}, stats::{Stats, StatUtils},
        item_primitive::{ImplItemPrimitive, ItemPrimitive}, bag::{Bag, IBag, ImplBag},
        adventurer_meta::{AdventurerMetadata}, exploration::ExploreUtils,
        constants::{
            discovery_constants::DiscoveryEnums::{ExploreResult, DiscoveryType},
            adventurer_constants::{
                POTION_HEALTH_AMOUNT, ITEM_XP_MULTIPLIER_BEASTS, ITEM_XP_MULTIPLIER_OBSTACLES,
                ITEM_MAX_GREATNESS, MAX_GREATNESS_STAT_BONUS, StatisticIndex,
                VITALITY_INSTANT_HEALTH_BONUS, BEAST_SPECIAL_NAME_LEVEL_UNLOCK, XP_FOR_DISCOVERIES,
                STARTING_GOLD, STARTING_HEALTH, POTION_PRICE, MINIMUM_POTION_PRICE,
                CHARISMA_POTION_DISCOUNT, CHARISMA_ITEM_DISCOUNT, MINIMUM_ITEM_PRICE,
                MINIMUM_DAMAGE_TO_BEASTS, MINIMUM_DAMAGE_FROM_OBSTACLES,
                OBSTACLE_CRITICAL_HIT_CHANCE, MAX_STAT_UPGRADE_POINTS
            }
        },
        item_meta::{ImplItemSpecials, ItemSpecials, IItemSpecials, ItemSpecialsStorage},
        adventurer_utils::AdventurerUtils, leaderboard::{Score, Leaderboard},
    };
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
    use game_entropy::game_entropy::{GameEntropy, ImplGameEntropy};

    #[storage]
    struct Storage {
        _adventurer: LegacyMap::<felt252, Adventurer>,
        _adventurer_meta: LegacyMap::<felt252, AdventurerMetadata>,
        _bag: LegacyMap::<felt252, Bag>,
        _collectible_beasts: ContractAddress,
        _dao: ContractAddress,
        _game_counter: felt252,
        _game_entropy: GameEntropy,
        _genesis_block: u64,
        _golden_token: ContractAddress,
        _item_specials: LegacyMap::<(felt252, u8), ItemSpecialsStorage>,
        _leaderboard: Leaderboard,
        _lords: ContractAddress,
        _owner: LegacyMap::<felt252, ContractAddress>,
        _golden_token_last_use: LegacyMap::<felt252, felt252>,
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
        IdleDeathPenalty: IdleDeathPenalty,
        RewardDistribution: RewardDistribution,
        GameEntropyRotatedEvent: GameEntropyRotatedEvent,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        lords_address: ContractAddress,
        dao_address: ContractAddress,
        beasts_address: ContractAddress,
        golden_token_address: ContractAddress,
    ) {
        // set the contract addresses
        self._lords.write(lords_address);
        self._dao.write(dao_address);
        self._collectible_beasts.write(beasts_address);

        // set the genesis block number
        let current_block_info = starknet::get_block_info().unbox();
        self._genesis_block.write(current_block_info.block_number);

        // set golden token address
        self._golden_token.write(golden_token_address);

        // initialize game entropy
        let new_game_entropy = ImplGameEntropy::new(
            current_block_info.block_number,
            current_block_info.block_timestamp,
            current_block_info.block_number + STARTING_GAME_ENTROPY_ROTATION_INTERVAL.into()
        );

        // save game entropy
        _save_game_entropy(ref self, new_game_entropy);
    }

    // ------------------------------------------ //
    // ------------ Impl ------------------------ //
    // ------------------------------------------ //

    #[external(v0)]
    impl Game of IGame<ContractState> {
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
            name: u128,
            golden_token_id: u256
        ) {
            // assert provided weapon
            _assert_valid_starter_weapon(weapon);

            // if player has a golden token
            // there is no 0 token
            if (golden_token_id != 0) {
                _play_with_token(ref self, golden_token_id);
            } else {
                _process_payment_and_distribute_rewards(ref self, client_reward_address);
            }

            // start the game
            _start_game(ref self, weapon, name);
        }

        /// @title Explore Function
        ///
        /// @notice Allows an adventurer to explore
        ///
        /// @param adventurer_id A u256 representing the ID of the adventurer.
        /// @param till_beast A boolean flag indicating if the exploration continues until encountering a beast.
        fn explore(ref self: ContractState, adventurer_id: felt252, till_beast: bool) {
            // get adventurer from storage with stat boosts applied
            let (mut adventurer, stat_boosts, _) = _unpack_adventurer_and_bag_with_stat_boosts(
                @self, adventurer_id
            );

            // use an immutable adventurer for assertions
            let immutable_adventurer = adventurer.clone();

            // assert action is valid
            _assert_ownership(@self, adventurer_id);
            _assert_not_dead(immutable_adventurer);
            _assert_no_stat_upgrades_available(immutable_adventurer);
            _assert_not_in_battle(immutable_adventurer);

            // get adventurer and game entropy
            let (adventurer_entropy, game_entropy) = _get_adventurer_and_game_entropy(
                @self, adventurer_id
            );

            // ensure player is not exceeding the rate limit
            // @player this is to protect you from bots
            let block_number = starknet::get_block_info().unbox().block_number;
            if !adventurer.block_changed_since_last_action(block_number) {
                _assert_rate_limit(adventurer.actions_per_block, game_entropy.get_rate_limit());
            }

            // if game entropy is eligible to be rotated, rotate it
            if block_number > game_entropy.next_update_block {
                _rotate_game_entropy(ref self);
            }

            // update actions per block
            adventurer.update_actions_per_block(block_number);

            // get number of blocks between actions
            let (idle, num_blocks) = _is_idle(immutable_adventurer, game_entropy);

            // process explore or apply idle penalty
            if !idle {
                _explore(
                    ref self,
                    ref adventurer,
                    adventurer_id,
                    adventurer_entropy,
                    game_entropy.hash,
                    till_beast
                );
            } else {
                _apply_idle_penalty(ref self, adventurer_id, ref adventurer, num_blocks);
            }

            // update players last action block number to reset idle counter
            adventurer.set_last_action_block(starknet::get_block_info().unbox().block_number);

            // pack and save adventurer
            _pack_adventurer_remove_stat_boost(
                ref self, ref adventurer, adventurer_id, stat_boosts
            );
        }

        /// @title Attack Function
        ///
        /// @notice Allows an adventurer to attack a beast 
        ///
        /// @param adventurer_id A u256 representing the ID of the adventurer.
        /// @param to_the_death A boolean flag indicating if the attack should continue until either the adventurer or the beast is defeated.
        fn attack(ref self: ContractState, adventurer_id: felt252, to_the_death: bool) {
            // get adventurer from storage with stat boosts applied
            let (mut adventurer, stat_boosts, _) = _unpack_adventurer_and_bag_with_stat_boosts(
                @self, adventurer_id
            );

            // use an immutable adventurer for assertions
            let immutable_adventurer = adventurer.clone();

            // assert action is valid
            _assert_ownership(@self, adventurer_id);
            _assert_not_dead(immutable_adventurer);
            _assert_in_battle(immutable_adventurer);

            // get adventurer and game entropy
            let (adventurer_entropy, game_entropy) = _get_adventurer_and_game_entropy(
                @self, adventurer_id
            );

            // ensure player is not exceeding the rate limit
            // @player this is to protect you from bots
            let block_number = starknet::get_block_info().unbox().block_number;
            if !adventurer.block_changed_since_last_action(block_number) {
                _assert_rate_limit(adventurer.actions_per_block, game_entropy.get_rate_limit());
            }

            // update actions per block
            adventurer.update_actions_per_block(starknet::get_block_info().unbox().block_number);

            // if game entropy is eligible to be rotated, rotate it
            if block_number > game_entropy.next_update_block {
                _rotate_game_entropy(ref self);
            }

            // get number of blocks between actions
            let (idle, num_blocks) = _is_idle(immutable_adventurer, game_entropy);

            // process attack or apply idle penalty
            if !idle {
                // get weapon specials
                let weapon_specials = _get_item_specials(@self, adventurer_id, adventurer.weapon);

                // get beast and beast seed
                let (beast, beast_seed) = adventurer.get_beast(adventurer_entropy);

                // get weapon details
                let weapon = ImplLoot::get_item(adventurer.weapon.id);
                let weapon_combat_spec = CombatSpec {
                    tier: weapon.tier,
                    item_type: weapon.item_type,
                    level: adventurer.weapon.get_greatness().into(),
                    specials: SpecialPowers {
                        special1: weapon_specials.special1,
                        special2: weapon_specials.special2,
                        special3: weapon_specials.special3
                    }
                };

                _attack(
                    ref self,
                    ref adventurer,
                    weapon_combat_spec,
                    adventurer_id,
                    adventurer_entropy,
                    beast,
                    beast_seed,
                    game_entropy.hash,
                    to_the_death
                );
            } else {
                _apply_idle_penalty(ref self, adventurer_id, ref adventurer, num_blocks);
            }

            // update players last action block
            adventurer.set_last_action_block(starknet::get_block_info().unbox().block_number);

            // pack and save adventurer
            _pack_adventurer_remove_stat_boost(
                ref self, ref adventurer, adventurer_id, stat_boosts
            );
        }

        /// @title Flee Function
        ///
        /// @notice Allows an adventurer to flee from a beast
        ///
        /// @param adventurer_id A u256 representing the unique ID of the adventurer.
        /// @param to_the_death A boolean flag indicating if the flee attempt should continue until either the adventurer escapes or is defeated.
        fn flee(ref self: ContractState, adventurer_id: felt252, to_the_death: bool) {
            // get adventurer from storage with stat boosts applied
            let (mut adventurer, stat_boosts, _) = _unpack_adventurer_and_bag_with_stat_boosts(
                @self, adventurer_id
            );

            // use an immutable adventurer for assertions
            let immutable_adventurer = adventurer.clone();

            // assert action is valid
            _assert_ownership(@self, adventurer_id);
            _assert_not_dead(immutable_adventurer);
            _assert_in_battle(immutable_adventurer);
            _assert_not_starter_beast(immutable_adventurer);
            _assert_dexterity_not_zero(immutable_adventurer);

            // get adventurer and game entropy
            let (adventurer_entropy, game_entropy) = _get_adventurer_and_game_entropy(
                @self, adventurer_id
            );

            // ensure player is not exceeding the rate limit
            // @player this is to protect you from bots
            let block_number = starknet::get_block_info().unbox().block_number;
            if !adventurer.block_changed_since_last_action(block_number) {
                _assert_rate_limit(adventurer.actions_per_block, game_entropy.get_rate_limit());
            }

            // update actions per block
            adventurer.update_actions_per_block(block_number);

            // if game entropy is eligible to be rotated, rotate it
            if block_number > game_entropy.next_update_block {
                _rotate_game_entropy(ref self);
            }

            // get number of blocks between actions
            let (idle, num_blocks) = _is_idle(immutable_adventurer, game_entropy);

            // if adventurer is not idle
            if !idle {
                // get beast and beast seed
                let (beast, beast_seed) = adventurer.get_beast(adventurer_entropy);

                // attempt to flee
                _flee(
                    ref self,
                    ref adventurer,
                    adventurer_id,
                    adventurer_entropy,
                    game_entropy.hash,
                    beast_seed,
                    beast,
                    to_the_death
                );

                // if adventurer died while attempting to flee
                if (adventurer.health == 0) {
                    // process death
                    _process_adventurer_death(ref self, adventurer, adventurer_id, beast.id, 0);
                }
            } else {
                _apply_idle_penalty(ref self, adventurer_id, ref adventurer, num_blocks);
            }

            // update players last action block number
            adventurer.set_last_action_block(starknet::get_block_info().unbox().block_number);

            // pack and save adventurer
            _pack_adventurer_remove_stat_boost(
                ref self, ref adventurer, adventurer_id, stat_boosts
            );
        }

        /// @title Equip Function
        ///
        /// @notice Allows an adventurer to equip items from their bag
        /// @player Calling this during battle will result in a beast counter-attack
        ///
        /// @param adventurer_id A u256 representing the unique ID of the adventurer.
        /// @param items A u8 array representing the item IDs to equip.
        fn equip(ref self: ContractState, adventurer_id: felt252, items: Array<u8>) {
            // get adventurer and bag from storage with stat boosts applied
            let (mut adventurer, stat_boosts, mut bag) =
                _unpack_adventurer_and_bag_with_stat_boosts(
                @self, adventurer_id
            );

            // assert action is valid
            _assert_ownership(@self, adventurer_id);
            _assert_not_dead(adventurer);
            assert(items.len() != 0, messages::NO_ITEMS);
            assert(items.len() <= 8, messages::TOO_MANY_ITEMS);

            // equip items, passing in items as a clone so we can maintain ownership of original for event
            _equip_items(ref self, ref adventurer, ref bag, adventurer_id, items.clone(), false);

            // if the adventurer is equipping an item during battle, the beast will counter attack
            if (adventurer.in_battle()) {
                // get adventurer and game entropy
                let (adventurer_entropy, game_entropy) = _get_adventurer_and_game_entropy(
                    @self, adventurer_id
                );

                // get beast and beast seed
                let (beast, beast_seed) = adventurer.get_beast(adventurer_entropy);

                // get two random numbers
                let (rnd1, rnd2) = AdventurerUtils::get_randomness(
                    adventurer.xp, adventurer_entropy, game_entropy.hash
                );

                // process beast attack
                let beast_battle_details = _beast_attack(
                    ref self, ref adventurer, adventurer_id, beast, beast_seed, rnd1, rnd2,
                );

                // emit event
                __event_AttackedByBeast(ref self, adventurer, adventurer_id, beast_battle_details);

                // if adventurer died from counter attack, process death
                if (adventurer.health == 0) {
                    _process_adventurer_death(ref self, adventurer, adventurer_id, beast.id, 0);
                }
            }

            // pack and save adventurer 
            _pack_adventurer_remove_stat_boost(
                ref self, ref adventurer, adventurer_id, stat_boosts
            );

            // if the bag was mutated, pack and save it
            if bag.mutated {
                _pack_bag(ref self, adventurer_id, bag);
            }
        }

        /// @title Drop Function
        ///
        /// @notice Allows an adventurer to drop equpped items or items from their bag
        ///
        /// @param adventurer_id A u256 representing the unique ID of the adventurer.
        /// @param items A u8 Array representing the IDs of the items to drop.
        fn drop(ref self: ContractState, adventurer_id: felt252, items: Array<u8>) {
            // get adventurer and bag from storage with stat boosts applied
            let (mut adventurer, stat_boosts, mut bag) =
                _unpack_adventurer_and_bag_with_stat_boosts(
                @self, adventurer_id
            );

            // assert action is valid (ownership of item is handled in internal function when we iterate over items)
            _assert_ownership(@self, adventurer_id);
            _assert_not_dead(adventurer);
            assert(items.len() != 0, messages::NO_ITEMS);

            // drop items
            _drop(ref self, ref adventurer, ref bag, adventurer_id, items.clone());

            // if the adventurer was mutated, pack and save it
            if (adventurer.mutated) {
                _pack_adventurer_remove_stat_boost(
                    ref self, ref adventurer, adventurer_id, stat_boosts
                );
            }

            // if the bag was mutated, pack and save it
            if (bag.mutated) {
                _pack_bag(ref self, adventurer_id, bag);
            }

            // emit dropped items event
            __event_DroppedItems(ref self, adventurer, adventurer_id, bag, items);
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
            // get adventurer and bag from storage with stat boosts applied
            let (mut adventurer, stat_boosts, mut bag) =
                _unpack_adventurer_and_bag_with_stat_boosts(
                @self, adventurer_id
            );

            let immutable_adventurer = adventurer.clone();

            // assert action is valid
            _assert_ownership(@self, adventurer_id);
            _assert_not_dead(immutable_adventurer);
            _assert_not_in_battle(immutable_adventurer);
            _assert_valid_stat_selection(immutable_adventurer, stat_upgrades);

            // load game entropy
            let game_entropy = _load_game_entropy(@self);

            // ensure player is not exceeding the rate limit
            // @player this is to protect you from bots
            let block_number = starknet::get_block_info().unbox().block_number;
            if !adventurer.block_changed_since_last_action(block_number) {
                _assert_rate_limit(adventurer.actions_per_block, game_entropy.get_rate_limit());
            }

            // update actions per block
            adventurer.update_actions_per_block(block_number);

            // if game entropy is eligible to be rotated, rotate it
            if block_number > game_entropy.next_update_block {
                _rotate_game_entropy(ref self);
            }

            // get number of blocks between actions
            let (idle, num_blocks) = _is_idle(immutable_adventurer, game_entropy);

            // if adventurer exceeded idle penalty threshold, apply penalty and return
            if idle {
                _apply_idle_penalty(ref self, adventurer_id, ref adventurer, num_blocks);
                return;
            }

            // get number of stat upgrades available before we use them
            let pre_upgrade_stat_points = adventurer.stat_points_available;

            // upgrade adventurer's stats
            _upgrade_stats(@self, ref adventurer, stat_upgrades);

            // if the player is buying potions as part of the upgrade
            if potions != 0 {
                _buy_potions(ref self, ref adventurer, adventurer_id, potions);
            }

            // if the player is buying items, process purchases
            if (items.len() != 0) {
                _buy_items(
                    ref self,
                    ref adventurer,
                    ref bag,
                    adventurer_id,
                    pre_upgrade_stat_points,
                    items.clone()
                );
            }

            // update players last action block number
            adventurer.set_last_action_block(starknet::get_block_info().unbox().block_number);

            // emit adventurer upgraded event
            __event_AdventurerUpgraded(ref self, adventurer, adventurer_id, bag, stat_upgrades);

            // if the upgrade mutated the adventurer's bag
            if (bag.mutated) {
                _pack_bag(ref self, adventurer_id, bag);
            }

            // remove stat boosts, pack, and save adventurer
            _pack_adventurer_remove_stat_boost(
                ref self, ref adventurer, adventurer_id, stat_boosts
            );
        }

        /// @title Slay Idle Adventurers Function
        ///
        /// @notice Allows anyone to slay idle adventurers
        ///
        /// @param adventurer_ids: A u256 array representing the IDs of adventurers to slay
        fn slay_idle_adventurers(ref self: ContractState, adventurer_ids: Array<felt252>) {
            let mut adventurer_index: u32 = 0;
            loop {
                if adventurer_index == adventurer_ids.len() {
                    break;
                }
                let adventurer_id = *adventurer_ids.at(adventurer_index);
                _slay_idle_adventurer(ref self, adventurer_id);
                adventurer_index += 1;
            }
        }

        /// @title Rotate Game Entropy Function
        ///
        /// @notice Rotates the game entropy
        /// @dev This is intentional callable by anyone
        /// @players Ideally this is called at the minimum block interval to provide optimal game entropy. If the community does not do this, bots will likely use this to their advantage.
        fn rotate_game_entropy(ref self: ContractState) {
            _rotate_game_entropy(ref self);
        }

        //
        // view functions
        //
        fn get_adventurer(self: @ContractState, adventurer_id: felt252) -> Adventurer {
            let (adventurer, _, _) = _unpack_adventurer_and_bag_with_stat_boosts(
                self, adventurer_id
            );
            adventurer
        }
        fn get_adventurer_no_boosts(self: @ContractState, adventurer_id: felt252) -> Adventurer {
            _unpack_adventurer(self, adventurer_id)
        }
        fn get_adventurer_meta(self: @ContractState, adventurer_id: felt252) -> AdventurerMetadata {
            _unpack_adventurer_meta(self, adventurer_id)
        }
        fn get_bag(self: @ContractState, adventurer_id: felt252) -> Bag {
            _unpacked_bag(self, adventurer_id)
        }
        fn get_weapon_specials(self: @ContractState, adventurer_id: felt252) -> ItemSpecials {
            let adventurer = _unpack_adventurer(self, adventurer_id);
            _get_item_specials(self, adventurer_id, adventurer.weapon)
        }
        fn get_chest_specials(self: @ContractState, adventurer_id: felt252) -> ItemSpecials {
            let adventurer = _unpack_adventurer(self, adventurer_id);
            _get_item_specials(self, adventurer_id, adventurer.chest)
        }
        fn get_head_specials(self: @ContractState, adventurer_id: felt252) -> ItemSpecials {
            let adventurer = _unpack_adventurer(self, adventurer_id);
            _get_item_specials(self, adventurer_id, adventurer.head)
        }
        fn get_waist_specials(self: @ContractState, adventurer_id: felt252) -> ItemSpecials {
            let adventurer = _unpack_adventurer(self, adventurer_id);
            _get_item_specials(self, adventurer_id, adventurer.waist)
        }
        fn get_foot_specials(self: @ContractState, adventurer_id: felt252) -> ItemSpecials {
            let adventurer = _unpack_adventurer(self, adventurer_id);
            _get_item_specials(self, adventurer_id, adventurer.foot)
        }
        fn get_hand_specials(self: @ContractState, adventurer_id: felt252) -> ItemSpecials {
            let adventurer = _unpack_adventurer(self, adventurer_id);
            _get_item_specials(self, adventurer_id, adventurer.hand)
        }
        fn get_necklace_specials(self: @ContractState, adventurer_id: felt252) -> ItemSpecials {
            let adventurer = _unpack_adventurer(self, adventurer_id);
            _get_item_specials(self, adventurer_id, adventurer.neck)
        }
        fn get_ring_specials(self: @ContractState, adventurer_id: felt252) -> ItemSpecials {
            let adventurer = _unpack_adventurer(self, adventurer_id);
            _get_item_specials(self, adventurer_id, adventurer.ring)
        }
        fn get_items_on_market(self: @ContractState, adventurer_id: felt252) -> Array<u8> {
            let adventurer = _unpack_adventurer(self, adventurer_id);
            _assert_upgrades_available(adventurer);
            let adventurer_entropy: u128 = _unpack_adventurer_meta(self, adventurer_id)
                .entropy
                .into();
            _get_items_on_market(
                self, adventurer_entropy, adventurer.xp, adventurer.stat_points_available
            )
        }
        fn get_items_on_market_by_slot(
            self: @ContractState, adventurer_id: felt252, slot: u8
        ) -> Array<u8> {
            let adventurer = _unpack_adventurer(self, adventurer_id);
            _assert_upgrades_available(adventurer);
            let adventurer_entropy: u128 = _unpack_adventurer_meta(self, adventurer_id)
                .entropy
                .into();
            _get_items_on_market_by_slot(
                self,
                adventurer_entropy,
                adventurer.xp,
                adventurer.stat_points_available,
                ImplCombat::u8_to_slot(slot)
            )
        }
        fn get_items_on_market_by_tier(
            self: @ContractState, adventurer_id: felt252, tier: u8
        ) -> Array<u8> {
            let adventurer = _unpack_adventurer(self, adventurer_id);
            _assert_upgrades_available(adventurer);
            let adventurer_entropy: u128 = _unpack_adventurer_meta(self, adventurer_id)
                .entropy
                .into();

            if tier == 1 {
                _get_items_on_market_by_tier(
                    self,
                    adventurer_entropy,
                    adventurer.xp,
                    adventurer.stat_points_available,
                    Tier::T1(())
                )
            } else if tier == 2 {
                _get_items_on_market_by_tier(
                    self,
                    adventurer_entropy,
                    adventurer.xp,
                    adventurer.stat_points_available,
                    Tier::T2(())
                )
            } else if tier == 3 {
                _get_items_on_market_by_tier(
                    self,
                    adventurer_entropy,
                    adventurer.xp,
                    adventurer.stat_points_available,
                    Tier::T3(())
                )
            } else if tier == 4 {
                _get_items_on_market_by_tier(
                    self,
                    adventurer_entropy,
                    adventurer.xp,
                    adventurer.stat_points_available,
                    Tier::T4(())
                )
            } else {
                _get_items_on_market_by_tier(
                    self,
                    adventurer_entropy,
                    adventurer.xp,
                    adventurer.stat_points_available,
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
            _unpack_adventurer(self, adventurer_id).health
        }
        fn get_xp(self: @ContractState, adventurer_id: felt252) -> u16 {
            _unpack_adventurer(self, adventurer_id).xp
        }
        fn get_level(self: @ContractState, adventurer_id: felt252) -> u8 {
            _unpack_adventurer(self, adventurer_id).get_level()
        }
        fn get_gold(self: @ContractState, adventurer_id: felt252) -> u16 {
            _unpack_adventurer(self, adventurer_id).gold
        }
        fn get_beast_health(self: @ContractState, adventurer_id: felt252) -> u16 {
            _unpack_adventurer(self, adventurer_id).beast_health
        }
        fn get_stat_upgrades_available(self: @ContractState, adventurer_id: felt252) -> u8 {
            _unpack_adventurer(self, adventurer_id).stat_points_available
        }
        fn get_last_action_block(self: @ContractState, adventurer_id: felt252) -> u16 {
            _unpack_adventurer(self, adventurer_id).last_action_block
        }
        fn get_actions_per_block(self: @ContractState, adventurer_id: felt252) -> u8 {
            _unpack_adventurer(self, adventurer_id).actions_per_block
        }
        fn get_equipped_items(
            self: @ContractState, adventurer_id: felt252
        ) -> Array<ItemPrimitive> {
            let adventurer = _unpack_adventurer(self, adventurer_id);
            let mut equipped_items = ArrayTrait::<ItemPrimitive>::new();
            equipped_items.append(adventurer.weapon);
            equipped_items.append(adventurer.chest);
            equipped_items.append(adventurer.head);
            equipped_items.append(adventurer.waist);
            equipped_items.append(adventurer.foot);
            equipped_items.append(adventurer.hand);
            equipped_items.append(adventurer.neck);
            equipped_items.append(adventurer.ring);
            equipped_items
        }
        fn get_equipped_weapon(self: @ContractState, adventurer_id: felt252) -> ItemPrimitive {
            _unpack_adventurer(self, adventurer_id).weapon
        }
        fn get_equipped_chest(self: @ContractState, adventurer_id: felt252) -> ItemPrimitive {
            _unpack_adventurer(self, adventurer_id).chest
        }
        fn get_equipped_head(self: @ContractState, adventurer_id: felt252) -> ItemPrimitive {
            _unpack_adventurer(self, adventurer_id).head
        }
        fn get_equipped_waist(self: @ContractState, adventurer_id: felt252) -> ItemPrimitive {
            _unpack_adventurer(self, adventurer_id).waist
        }
        fn get_equipped_foot(self: @ContractState, adventurer_id: felt252) -> ItemPrimitive {
            _unpack_adventurer(self, adventurer_id).foot
        }
        fn get_equipped_hand(self: @ContractState, adventurer_id: felt252) -> ItemPrimitive {
            _unpack_adventurer(self, adventurer_id).hand
        }
        fn get_equipped_necklace(self: @ContractState, adventurer_id: felt252) -> ItemPrimitive {
            _unpack_adventurer(self, adventurer_id).neck
        }
        fn get_equipped_ring(self: @ContractState, adventurer_id: felt252) -> ItemPrimitive {
            _unpack_adventurer(self, adventurer_id).ring
        }
        fn get_weapon_greatness(self: @ContractState, adventurer_id: felt252) -> u8 {
            _unpack_adventurer(self, adventurer_id).weapon.get_greatness()
        }
        fn get_chest_greatness(self: @ContractState, adventurer_id: felt252) -> u8 {
            _unpack_adventurer(self, adventurer_id).chest.get_greatness()
        }
        fn get_head_greatness(self: @ContractState, adventurer_id: felt252) -> u8 {
            _unpack_adventurer(self, adventurer_id).head.get_greatness()
        }
        fn get_waist_greatness(self: @ContractState, adventurer_id: felt252) -> u8 {
            _unpack_adventurer(self, adventurer_id).waist.get_greatness()
        }
        fn get_foot_greatness(self: @ContractState, adventurer_id: felt252) -> u8 {
            _unpack_adventurer(self, adventurer_id).foot.get_greatness()
        }
        fn get_hand_greatness(self: @ContractState, adventurer_id: felt252) -> u8 {
            _unpack_adventurer(self, adventurer_id).hand.get_greatness()
        }
        fn get_necklace_greatness(self: @ContractState, adventurer_id: felt252) -> u8 {
            _unpack_adventurer(self, adventurer_id).neck.get_greatness()
        }
        fn get_ring_greatness(self: @ContractState, adventurer_id: felt252) -> u8 {
            _unpack_adventurer(self, adventurer_id).ring.get_greatness()
        }
        fn get_base_stats(self: @ContractState, adventurer_id: felt252) -> Stats {
            _unpack_adventurer(self, adventurer_id).stats
        }
        fn get_stats(self: @ContractState, adventurer_id: felt252) -> Stats {
            let (adventurer, _, _) = _unpack_adventurer_and_bag_with_stat_boosts(
                self, adventurer_id
            );
            adventurer.stats
        }
        fn get_base_strength(self: @ContractState, adventurer_id: felt252) -> u8 {
            _unpack_adventurer(self, adventurer_id).stats.strength
        }
        fn get_strength(self: @ContractState, adventurer_id: felt252) -> u8 {
            let (adventurer, _, _) = _unpack_adventurer_and_bag_with_stat_boosts(
                self, adventurer_id
            );
            adventurer.stats.strength
        }
        fn get_base_dexterity(self: @ContractState, adventurer_id: felt252) -> u8 {
            _unpack_adventurer(self, adventurer_id).stats.dexterity
        }
        fn get_dexterity(self: @ContractState, adventurer_id: felt252) -> u8 {
            let (adventurer, _, _) = _unpack_adventurer_and_bag_with_stat_boosts(
                self, adventurer_id
            );
            adventurer.stats.dexterity
        }
        fn get_base_vitality(self: @ContractState, adventurer_id: felt252) -> u8 {
            _unpack_adventurer(self, adventurer_id).stats.vitality
        }
        fn get_vitality(self: @ContractState, adventurer_id: felt252) -> u8 {
            let (adventurer, _, _) = _unpack_adventurer_and_bag_with_stat_boosts(
                self, adventurer_id
            );
            adventurer.stats.vitality
        }
        fn get_base_intelligence(self: @ContractState, adventurer_id: felt252) -> u8 {
            _unpack_adventurer(self, adventurer_id).stats.intelligence
        }
        fn get_intelligence(self: @ContractState, adventurer_id: felt252) -> u8 {
            let (adventurer, _, _) = _unpack_adventurer_and_bag_with_stat_boosts(
                self, adventurer_id
            );
            adventurer.stats.intelligence
        }
        fn get_base_wisdom(self: @ContractState, adventurer_id: felt252) -> u8 {
            _unpack_adventurer(self, adventurer_id).stats.wisdom
        }
        fn get_wisdom(self: @ContractState, adventurer_id: felt252) -> u8 {
            let (adventurer, _, _) = _unpack_adventurer_and_bag_with_stat_boosts(
                self, adventurer_id
            );
            adventurer.stats.wisdom
        }
        fn get_base_charisma(self: @ContractState, adventurer_id: felt252) -> u8 {
            _unpack_adventurer(self, adventurer_id).stats.charisma
        }
        fn get_charisma(self: @ContractState, adventurer_id: felt252) -> u8 {
            let (adventurer, _, _) = _unpack_adventurer_and_bag_with_stat_boosts(
                self, adventurer_id
            );
            adventurer.stats.charisma
        }
        fn get_special_storage(
            self: @ContractState, adventurer_id: felt252, storage_index: u8
        ) -> ItemSpecialsStorage {
            self._item_specials.read((adventurer_id, storage_index))
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
        fn get_game_entropy(self: @ContractState) -> GameEntropy {
            _load_game_entropy(self)
        }
        fn get_leaderboard(self: @ContractState) -> Leaderboard {
            self._leaderboard.read()
        }
        fn owner_of(self: @ContractState, adventurer_id: felt252) -> ContractAddress {
            _owner_of(self, adventurer_id)
        }
        fn next_game_entropy_rotation(self: @ContractState) -> felt252 {
            _next_game_entropy_rotation(self)
        }
        fn game_rate_limit(self: @ContractState) -> u64 {
            _load_game_entropy(self).get_rate_limit()
        }
        fn starting_gold(self: @ContractState) -> u16 {
            STARTING_GOLD
        }
        fn starting_health(self: @ContractState) -> u16 {
            STARTING_HEALTH
        }
        fn base_potion_price(self: @ContractState) -> u16 {
            POTION_PRICE
        }
        fn potion_health_amount(self: @ContractState) -> u16 {
            POTION_HEALTH_AMOUNT
        }
        fn minimum_potion_price(self: @ContractState) -> u16 {
            MINIMUM_POTION_PRICE
        }
        fn charisma_potion_discount(self: @ContractState) -> u16 {
            CHARISMA_POTION_DISCOUNT
        }
        fn items_per_stat_upgrade(self: @ContractState) -> u8 {
            NUMBER_OF_ITEMS_PER_LEVEL
        }
        fn item_tier_price_multiplier(self: @ContractState) -> u16 {
            TIER_PRICE
        }
        fn charisma_item_discount(self: @ContractState) -> u16 {
            CHARISMA_ITEM_DISCOUNT
        }
        fn minimum_item_price(self: @ContractState) -> u16 {
            MINIMUM_ITEM_PRICE
        }
        fn minimum_damage_to_beasts(self: @ContractState) -> u8 {
            MINIMUM_DAMAGE_TO_BEASTS
        }
        fn minimum_damage_from_beasts(self: @ContractState) -> u8 {
            MINIMUM_DAMAGE_FROM_BEASTS
        }
        fn minimum_damage_from_obstacles(self: @ContractState) -> u8 {
            MINIMUM_DAMAGE_FROM_OBSTACLES
        }
        fn obstacle_critical_hit_chance(self: @ContractState) -> u8 {
            OBSTACLE_CRITICAL_HIT_CHANCE
        }
        fn stat_upgrades_per_level(self: @ContractState) -> u8 {
            MAX_STAT_UPGRADE_POINTS
        }
        fn beast_special_name_unlock_level(self: @ContractState) -> u16 {
            BEAST_SPECIAL_NAME_LEVEL_UNLOCK
        }
        fn item_xp_multiplier_beasts(self: @ContractState) -> u16 {
            ITEM_XP_MULTIPLIER_BEASTS
        }
        fn item_xp_multiplier_obstacles(self: @ContractState) -> u16 {
            ITEM_XP_MULTIPLIER_OBSTACLES
        }
        fn strength_bonus_damage(self: @ContractState) -> u8 {
            STRENGTH_DAMAGE_BONUS
        }
    }

    // ------------------------------------------ //
    // ------------ Internal Functions ---------- //
    // ------------------------------------------ //

    fn _slay_idle_adventurer(ref self: ContractState, adventurer_id: felt252) {
        // unpack adventurer from storage (no need for stat boosts)
        let mut adventurer = _unpack_adventurer(@self, adventurer_id);

        // assert adventurer is not already dead
        _assert_not_dead(adventurer);

        // assert adventurer is idle
        _assert_is_idle(@self, adventurer);

        // slay adventurer by setting health to 0
        adventurer.health = 0;

        // handle adventurer death
        _process_adventurer_death(ref self, adventurer, adventurer_id, 0, 0,);

        // save adventurer (gg)
        _pack_adventurer(ref self, adventurer_id, adventurer);
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
        let ring_bonus = adventurer.ring.jewelry_gold_bonus(gold_earned);
        adventurer.increase_gold(gold_earned + ring_bonus);

        // get xp reward and increase adventurers xp
        let xp_earned_adventurer = beast.get_xp_reward();
        let (previous_level, new_level) = adventurer.increase_adventurer_xp(xp_earned_adventurer);

        // items use adventurer xp with an item multplier so they level faster than Adventurer
        let xp_earned_items = xp_earned_adventurer * ITEM_XP_MULTIPLIER_BEASTS;
        // assigning xp to items is more complex so we delegate to an internal function
        let items_leveled_up = _grant_xp_to_equipped_items(
            ref self, ref adventurer, adventurer_id, xp_earned_items, attack_rnd_2
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
        if (adventurer.stat_points_available != 0) {
            // emit events
            _emit_level_up_events(ref self, adventurer, adventurer_id, previous_level, new_level);
        }

        // if beast beast level is above collectible threshold
        if beast.combat_spec.level >= BEAST_SPECIAL_NAME_LEVEL_UNLOCK {
            // adventurers gets the beast
            _mint_beast(@self, beast);
        }
    }

    fn _mint_beast(self: @ContractState, beast: Beast) {
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
                    get_caller_address(),
                    beast.id,
                    beast.combat_spec.specials.special2,
                    beast.combat_spec.specials.special3,
                    beast.combat_spec.level.into()
                );
        }
    }

    fn _process_adventurer_death(
        ref self: ContractState,
        adventurer: Adventurer,
        adventurer_id: felt252,
        beast_id: u8,
        obstacle_id: u8
    ) {
        let adventurer_state = AdventurerState {
            owner: _owner_of(@self, adventurer_id), adventurer_id, adventurer
        };

        let death_details = DeathDetails {
            killed_by_beast: beast_id,
            killed_by_obstacle: obstacle_id,
            caller_address: get_caller_address()
        };

        __event_AdventurerDied(ref self, AdventurerDied { adventurer_state, death_details });

        if _is_top_score(@self, adventurer.xp) {
            _update_leaderboard(ref self, adventurer_id, adventurer);
        }
    }

    fn _golden_token_dispatcher(ref self: ContractState) -> IERC721Dispatcher {
        IERC721Dispatcher { contract_address: self._golden_token.read() }
    }

    fn _lords_dispatcher(ref self: ContractState) -> IERC20CamelDispatcher {
        IERC20CamelDispatcher { contract_address: self._lords.read() }
    }
    fn _process_payment_and_distribute_rewards(
        ref self: ContractState, client_address: ContractAddress
    ) {
        let caller = get_caller_address();
        let block_number = starknet::get_block_info().unbox().block_number;

        let genesis_block = self._genesis_block.read();
        let dao_address = self._dao.read();

        let leaderboard = self._leaderboard.read();
        let first_place_address = self._owner.read(leaderboard.first.adventurer_id.into());
        let second_place_address = self._owner.read(leaderboard.second.adventurer_id.into());
        let third_place_address = self._owner.read(leaderboard.third.adventurer_id.into());

        // if third place score is less than minimum score for payouts
        if (leaderboard.third.xp < MINIMUM_SCORE_FOR_PAYOUTS) {
            // all rewards go to the DAO
            // the purpose of this is to let a decent set of top scores get set before payouts begin
            // without this, there would be an incentive to start and die immediately after contract is deployed
            // to capture the rewards from the launch hype
            _lords_dispatcher(ref self).transferFrom(caller, dao_address, COST_TO_PLAY.into());

            __event_RewardDistribution(
                ref self,
                RewardDistribution {
                    first_place: PlayerReward {
                        adventurer_id: 0, rank: 0, amount: 0, address: dao_address,
                    },
                    second_place: PlayerReward {
                        adventurer_id: 0, rank: 0, amount: 0, address: dao_address,
                    },
                    third_place: PlayerReward {
                        adventurer_id: 0, rank: 0, amount: 0, address: dao_address,
                    },
                    client: ClientReward { amount: 0, address: dao_address },
                    dao: COST_TO_PLAY.into()
                }
            );
            return;
        }

        // First phase all rewards go to players
        let mut week = Week {
            DAO: REWARD_DISTRIBUTIONS_PHASE1::DAO,
            INTERFACE: REWARD_DISTRIBUTIONS_PHASE1::INTERFACE,
            FIRST_PLACE: REWARD_DISTRIBUTIONS_PHASE1::FIRST_PLACE,
            SECOND_PLACE: REWARD_DISTRIBUTIONS_PHASE1::SECOND_PLACE,
            THIRD_PLACE: REWARD_DISTRIBUTIONS_PHASE1::THIRD_PLACE
        };

        // after 2 weeks, the DAO gets a share of rewards
        if (BLOCKS_IN_A_WEEK * 2 + genesis_block) > block_number {
            week =
                Week {
                    DAO: REWARD_DISTRIBUTIONS_PHASE2::DAO,
                    INTERFACE: REWARD_DISTRIBUTIONS_PHASE2::INTERFACE,
                    FIRST_PLACE: REWARD_DISTRIBUTIONS_PHASE2::FIRST_PLACE,
                    SECOND_PLACE: REWARD_DISTRIBUTIONS_PHASE2::SECOND_PLACE,
                    THIRD_PLACE: REWARD_DISTRIBUTIONS_PHASE2::THIRD_PLACE
                };
        }

        // after 8 weeks, client builders start getting rewards
        if (BLOCKS_IN_A_WEEK * 8 + genesis_block) > block_number {
            week =
                Week {
                    DAO: REWARD_DISTRIBUTIONS_PHASE3::DAO,
                    INTERFACE: REWARD_DISTRIBUTIONS_PHASE3::INTERFACE,
                    FIRST_PLACE: REWARD_DISTRIBUTIONS_PHASE3::FIRST_PLACE,
                    SECOND_PLACE: REWARD_DISTRIBUTIONS_PHASE3::SECOND_PLACE,
                    THIRD_PLACE: REWARD_DISTRIBUTIONS_PHASE3::THIRD_PLACE
                }
        }

        // DAO
        if (week.DAO != 0) {
            _lords_dispatcher(ref self).transferFrom(caller, dao_address, week.DAO);
        }

        // interface
        if (week.INTERFACE != 0) {
            _lords_dispatcher(ref self).transferFrom(caller, client_address, week.INTERFACE);
        }

        // first place
        _lords_dispatcher(ref self).transferFrom(caller, first_place_address, week.FIRST_PLACE);

        // second place
        _lords_dispatcher(ref self).transferFrom(caller, second_place_address, week.SECOND_PLACE);

        // third place
        _lords_dispatcher(ref self).transferFrom(caller, third_place_address, week.THIRD_PLACE);

        // emit reward distribution event
        __event_RewardDistribution(
            ref self,
            RewardDistribution {
                first_place: PlayerReward {
                    adventurer_id: leaderboard.first.adventurer_id.into(),
                    rank: 1,
                    amount: week.FIRST_PLACE,
                    address: first_place_address
                },
                second_place: PlayerReward {
                    adventurer_id: leaderboard.second.adventurer_id.into(),
                    rank: 2,
                    amount: week.SECOND_PLACE,
                    address: second_place_address
                },
                third_place: PlayerReward {
                    adventurer_id: leaderboard.third.adventurer_id.into(),
                    rank: 3,
                    amount: week.THIRD_PLACE,
                    address: third_place_address
                },
                client: ClientReward { amount: week.INTERFACE, address: client_address },
                dao: week.DAO
            }
        );
    }

    fn _start_game(ref self: ContractState, weapon: u8, name: u128) {
        // increment adventurer id (first adventurer is id 1)
        let adventurer_id = self._game_counter.read() + 1;

        // use current starknet block number and timestamp as entropy sources
        let block_number = starknet::get_block_info().unbox().block_number;
        let block_timestamp = starknet::get_block_info().unbox().block_timestamp;

        // generate entropy seed for adventurer
        let entropy = AdventurerUtils::generate_adventurer_entropy(
            adventurer_id, block_number, block_timestamp
        );

        // generate a new adventurer using the provided started weapon and current block number
        let mut adventurer = ImplAdventurer::new(weapon, NUM_STARTING_STATS, block_number, entropy);

        // set entropy on adventurer metadata
        let adventurer_meta = AdventurerMetadata { name, entropy };

        // emit a StartGame event 
        __event_StartGame(ref self, adventurer, adventurer_id, adventurer_meta);

        // adventurer immediately gets ambushed by a starter beast
        let beast_battle_details = _starter_beast_ambush(
            ref adventurer, adventurer_id, weapon, entropy
        );

        __event_AmbushedByBeast(ref self, adventurer, adventurer_id, beast_battle_details);

        // pack and save new adventurer and metadata
        _pack_adventurer(ref self, adventurer_id, adventurer);
        _pack_adventurer_meta(ref self, adventurer_id, adventurer_meta);

        // increment the adventurer id counter
        self._game_counter.write(adventurer_id);

        // set caller as owner
        self._owner.write(adventurer_id, get_caller_address());
    }

    fn _starter_beast_ambush(
        ref adventurer: Adventurer,
        adventurer_id: felt252,
        starting_weapon: u8,
        adventurer_entropy: u128
    ) -> BattleDetails {
        let beast_seed: u128 = adventurer.get_beast_seed(adventurer_entropy);

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
        adventurer_entropy: u128,
        game_entropy: felt252,
        explore_till_beast: bool
    ) {
        // generate randomenss for exploration
        let (rnd1, rnd2) = AdventurerUtils::get_randomness(
            adventurer.xp, adventurer_entropy, game_entropy
        );

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
                ref self,
                ref adventurer,
                adventurer_id,
                adventurer_entropy,
                game_entropy,
                explore_till_beast
            );
        }
    }

    fn _alive_no_beast_no_upgrades(self: Adventurer) -> bool {
        self.health != 0 && self.beast_health == 0 && self.stat_points_available == 0
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
        if (adventurer.stat_points_available != 0) {
            // process level up
            _emit_level_up_events(ref self, adventurer, adventurer_id, previous_level, new_level);
        }
    }

    fn _beast_encounter(
        ref self: ContractState,
        ref adventurer: Adventurer,
        adventurer_entropy: u128,
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
            let beast_battle_details = _beast_attack(
                ref self, ref adventurer, adventurer_id, beast, beast_seed, entropy, entropy
            );
            __event_AmbushedByBeast(ref self, adventurer, adventurer_id, beast_battle_details);
            if (adventurer.health == 0) {
                _process_adventurer_death(ref self, adventurer, adventurer_id, beast.id, 0);
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
        let damage_slot = AdventurerUtils::get_random_attack_location(entropy);

        // get armor at the location being attacked
        let armor = adventurer.get_item_at_slot(damage_slot);

        // get damage from obstalce
        let (combat_result, jewlery_armor_bonus) = adventurer
            .get_obstacle_damage(obstacle, armor, entropy);

        // pull damage taken out of combat result for easy access
        let damage_taken = combat_result.total_damage;

        // attempt to dodge obstacle
        let dodged = adventurer.dodge_obstacle(entropy);
        if (!dodged) {
            // if not dodged, adventurer takes damage
            adventurer.decrease_health(damage_taken);
        }

        // get base xp reward for obstacle
        let base_reward = obstacle.get_xp_reward();

        // get item xp reward for obstacle
        let item_xp_reward = base_reward * ITEM_XP_MULTIPLIER_OBSTACLES;

        // grant adventurer xp and get previous and new level
        let (previous_level, new_level) = adventurer.increase_adventurer_xp(base_reward);

        // grant items xp and get array of items that leveled up
        let items_leveled_up = _grant_xp_to_equipped_items(
            ref self, ref adventurer, adventurer_id, item_xp_reward, entropy
        );

        // event vars
        let critical_hit = combat_result.critical_hit_bonus > 0;
        let damage_location = ImplCombat::slot_to_u8(damage_slot);

        __event_ObstacleEncounter(
            ref self,
            adventurer,
            adventurer_id,
            dodged,
            ObstacleDetails {
                id: obstacle.id,
                level: obstacle.combat_spec.level,
                damage_taken,
                damage_location,
                critical_hit,
                adventurer_xp_reward: base_reward,
                item_xp_reward
            }
        );

        // if adventurer is dead
        if (adventurer.health == 0) {
            _process_adventurer_death(ref self, adventurer, adventurer_id, 0, obstacle.id);
        } else {
            // if adventurer is still alive

            // check if any items leveled up
            if items_leveled_up.len() != 0 {
                // if they did, emit event
                __event_ItemsLeveledUp(ref self, adventurer, adventurer_id, items_leveled_up);
            }

            // check if adventurer got new stat upgrades
            if (adventurer.stat_points_available != 0) {
                _emit_level_up_events(
                    ref self, adventurer, adventurer_id, previous_level, new_level
                );
            }
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
        entropy: u128
    ) -> Array<ItemLeveledUp> {
        let (mut name_storage1, mut name_storage2) = _get_special_storages(@self, adventurer_id);
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
                .increase_item_xp_at_slot(ImplLoot::get_slot(item.id), xp_amount);
            // if item leveled up
            if new_level > previous_level {
                // process level up
                let updated_item = _process_item_level_up(
                    ref self,
                    ref adventurer,
                    ref name_storage1,
                    ref name_storage2,
                    item,
                    previous_level,
                    new_level,
                    entropy
                );

                // add item to list of items that leveled up to be emitted in event
                items_leveled_up.append(updated_item);
            }

            item_index += 1;
        };

        if (name_storage1.mutated) {
            _pack_loot_special_names_storage(
                ref self, adventurer_id, LOOT_NAME_STORAGE_INDEX_1, name_storage1
            );
        }
        if (name_storage2.mutated) {
            _pack_loot_special_names_storage(
                ref self, adventurer_id, LOOT_NAME_STORAGE_INDEX_2, name_storage2
            );
        }

        items_leveled_up
    }

    fn _process_item_level_up(
        ref self: ContractState,
        ref adventurer: Adventurer,
        ref name_storage1: ItemSpecialsStorage,
        ref name_storage2: ItemSpecialsStorage,
        item: ItemPrimitive,
        previous_level: u8,
        new_level: u8,
        entropy: u128
    ) -> ItemLeveledUp {
        // init specials with no specials
        let mut specials = ItemSpecials { special1: 0, special2: 0, special3: 0 };

        // check if item reached greatness 20
        if (new_level == ITEM_MAX_GREATNESS) {
            // if so, adventurer gets a stat point as a reward
            adventurer.increase_stat_points_available(MAX_GREATNESS_STAT_BONUS);
        }

        // check if item unlocked specials as part of level up
        let (suffix_unlocked, prefixes_unlocked) = ImplAdventurer::unlocked_specials(
            previous_level, new_level
        );

        // if specials were unlocked
        if (suffix_unlocked || prefixes_unlocked) {
            // apply them and record the new specials so we can include them in event
            if (_get_storage_index(@self, item.metadata) == LOOT_NAME_STORAGE_INDEX_1) {
                specials = item
                    .apply_specials(ref name_storage1, suffix_unlocked, prefixes_unlocked, entropy);
            } else {
                specials = item
                    .apply_specials(ref name_storage2, suffix_unlocked, prefixes_unlocked, entropy);
            }

            // if item received a suffix as part of the level up
            if (suffix_unlocked) {
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
    /// @param game_entropy A random value used globally in determining certain random aspects of the combat
    /// @param fight_to_the_death Flag to indicate whether the adventurer should continue attacking until either they or the beast is defeated
    fn _attack(
        ref self: ContractState,
        ref adventurer: Adventurer,
        weapon_combat_spec: CombatSpec,
        adventurer_id: felt252,
        adventurer_entropy: u128,
        beast: Beast,
        beast_seed: u128,
        game_entropy: felt252,
        fight_to_the_death: bool,
    ) {
        // get two random numbers using adventurer xp and health as part of entropy
        let (rnd1, rnd2) = AdventurerUtils::get_randomness_with_health(
            adventurer.xp, adventurer.health, adventurer_entropy, game_entropy
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
                ref self, ref adventurer, adventurer_id, beast, beast_seed, rnd1, rnd2,
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
                _process_adventurer_death(ref self, adventurer, adventurer_id, beast.id, 0);
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
                    beast,
                    beast_seed,
                    game_entropy,
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
        entropy: u128,
        attack_location_rnd: u128,
    ) -> BattleDetails {
        // beasts attack random location on adventurer
        let attack_location = AdventurerUtils::get_random_attack_location(attack_location_rnd);

        // get armor at attack location
        let armor = adventurer.get_item_at_slot(attack_location);

        // get armor specials
        let armor_specials = _get_item_specials(@self, adventurer_id, armor);

        // process beast attack
        let (combat_result, jewlery_armor_bonus) = adventurer
            .defend(beast, armor, armor_specials, entropy);

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
    // @param game_entropy The game entropy value.
    // @param beast_seed The seed related to the beast.
    // @param beast The beast that the adventurer is attempting to flee from.
    // @param flee_to_the_death Flag to indicate if the flee attempt should continue until either success or the adventurer's defeat.
    fn _flee(
        ref self: ContractState,
        ref adventurer: Adventurer,
        adventurer_id: felt252,
        adventurer_entropy: u128,
        game_entropy: felt252,
        beast_seed: u128,
        beast: Beast,
        flee_to_the_death: bool
    ) {
        // get flee and ambush entropy seeds
        let (flee_entropy, ambush_entropy) = AdventurerUtils::get_randomness_with_health(
            adventurer.xp, adventurer.health, adventurer_entropy, game_entropy
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
            if (adventurer.stat_points_available != 0) {
                _emit_level_up_events(
                    ref self, adventurer, adventurer_id, previous_level, new_level
                );
            }
        } else {
            // if the flee attempt failed, beast counter attacks
            let beast_battle_details = _beast_attack(
                ref self,
                ref adventurer,
                adventurer_id,
                beast,
                beast_seed,
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
                    game_entropy,
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
    fn _equip_item(ref adventurer: Adventurer, ref bag: Bag, item: ItemPrimitive) -> u8 {
        // get the item currently equipped to the slot the item is being equipped to
        let unequipping_item = adventurer.get_item_at_slot(ImplLoot::get_slot(item.id));

        // if the item exists
        if unequipping_item.id != 0 {
            // put it into the adventurer's bag
            bag.add_item(unequipping_item);
        }

        // equip item
        adventurer.equip_item(item);

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
        ref self: ContractState,
        ref adventurer: Adventurer,
        ref bag: Bag,
        adventurer_id: felt252,
        items_to_equip: Array<u8>,
        is_newly_purchased: bool
    ) {
        // mutable array from returning items that were unequipped as a result of equipping the items
        let mut unequipped_items = ArrayTrait::<u8>::new();

        // get a clone of our items to equip to keep ownership for event
        let equipped_items = items_to_equip.clone();

        // for we item we need to equip
        let mut i: u32 = 0;
        loop {
            if i == items_to_equip.len() {
                break ();
            }

            // get the item
            let item_id = *items_to_equip.at(i);

            // assume we won't need to unequip an item to equip new one
            let mut unequipped_item_id: u8 = 0;

            // if item is newly purchased
            if is_newly_purchased {
                // assert adventurer does not already own the item
                _assert_item_not_owned(adventurer, bag, item_id.clone());

                // create new item, equip it, and record if we need unequipped an item
                let mut new_item = ImplItemPrimitive::new(item_id);
                new_item.set_metadata_id(adventurer, bag);
                unequipped_item_id = _equip_item(ref adventurer, ref bag, new_item);
            } else {
                // otherwise item is being equipped from bag
                // so remove it from bag, equip it, and record if we need to unequip an item
                unequipped_item_id = _equip_item(ref adventurer, ref bag, bag.remove_item(item_id));
            }

            // if an item was unequipped
            if unequipped_item_id != 0 {
                // add it to our return array so we can emit these in events
                unequipped_items.append(unequipped_item_id);
            }

            i += 1;
        };

        // and emit equipped item event
        __event_EquippedItems(
            ref self, adventurer, adventurer_id, bag, equipped_items, unequipped_items,
        );
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
            if adventurer.is_equipped(item_id) {
                adventurer.drop_item(item_id);
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
    // @param stat_points_available The number of stat points available to the adventurer.
    // @param adventurer_id The unique identifier for the adventurer.
    // @param adventurer_entropy The entropy of the adventurer used for randomness.
    // @param items The Array of ItemPurchase instances representing items to be purchased.
    fn _buy_items(
        ref self: ContractState,
        ref adventurer: Adventurer,
        ref bag: Bag,
        adventurer_id: felt252,
        stat_points_available: u8,
        items_to_purchase: Array<ItemPurchase>,
    ) {
        // get adventurer entropy
        let adventurer_entropy: u128 = _unpack_adventurer_meta(@self, adventurer_id).entropy.into();

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
                adventurer_entropy, stat_points_available, adventurer.xp, item.item_id
            );

            // buy it and store result in our purchases array for event
            purchases.append(_buy_item(ref self, ref adventurer, ref bag, item.item_id));

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

        // emit purchased items event
        __event_PurchasedItems(ref self, adventurer, adventurer_id, bag, purchases);

        // if we have items to equip as part of the purchase
        if (items_to_equip.len() != 0) {
            // equip them and record the items that were unequipped
            _equip_items(
                ref self, ref adventurer, ref bag, adventurer_id, items_to_equip.clone(), true
            );
        }
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
        adventurer.stat_points_available = 0;
    }

    // @notice Buy an item with the item price adjusted for adventurer's charisma.
    // @param adventurer The adventurer buying the item. The function modifies the adventurer's gold and equipment.
    // @param bag The bag of the adventurer. The function may add items to the bag if the adventurer unequips an item or opts not to equip a purchased item.
    // @param item_id The ID of the item to be purchased.
    fn _buy_item(
        ref self: ContractState, ref adventurer: Adventurer, ref bag: Bag, item_id: u8
    ) -> LootWithPrice {
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
    fn _unpack_adventurer(self: @ContractState, adventurer_id: felt252) -> Adventurer {
        let adventurer = self._adventurer.read(adventurer_id);
        adventurer
    }
    fn _unpack_adventurer_and_bag_with_stat_boosts(
        self: @ContractState, adventurer_id: felt252
    ) -> (Adventurer, Stats, Bag) {
        // unpack adventurer
        let mut adventurer: Adventurer = self._adventurer.read(adventurer_id);

        // start with no stat boosts
        let mut stat_boosts = StatUtils::new();

        // if adventurer has item specials
        if adventurer.has_item_specials() {
            // get specials from storage
            let (name_storage1, name_storage2) = _get_special_storages(self, adventurer_id);
            // get resulting stat boosts
            stat_boosts = adventurer.get_stat_boosts(name_storage1, name_storage2);
            // apply stat boosts
            adventurer.apply_stat_boosts(stat_boosts);
        }

        // get bag from storage
        let bag = _unpacked_bag(self, adventurer_id);

        // luck isn't stored, it is calculated dynamically
        adventurer.set_luck(bag);

        // return adventurer with stat boosts
        (adventurer, stat_boosts, bag)
    }

    #[inline(always)]
    fn _pack_adventurer(ref self: ContractState, adventurer_id: felt252, adventurer: Adventurer) {
        self._adventurer.write(adventurer_id, adventurer);
    }
    // @dev Packs and saves an adventurer after removing stat boosts.
    // @param adventurer_id The ID of the adventurer to be modified.
    // @param adventurer The adventurer to be modified.
    // @param stat_boosts The stat boosts to be removed.
    fn _pack_adventurer_remove_stat_boost(
        ref self: ContractState,
        ref adventurer: Adventurer,
        adventurer_id: felt252,
        stat_boosts: Stats
    ) {
        // remove stat boosts
        adventurer.remove_stat_boosts(stat_boosts);

        // save adventurer
        self._adventurer.write(adventurer_id, adventurer);
    }

    #[inline(always)]
    fn _unpacked_bag(self: @ContractState, adventurer_id: felt252) -> Bag {
        self._bag.read(adventurer_id)
    }
    #[inline(always)]
    fn _pack_bag(ref self: ContractState, adventurer_id: felt252, bag: Bag) {
        self._bag.write(adventurer_id, bag);
    }
    #[inline(always)]
    fn _unpack_adventurer_meta(self: @ContractState, adventurer_id: felt252) -> AdventurerMetadata {
        self._adventurer_meta.read(adventurer_id)
    }
    #[inline(always)]
    fn _pack_adventurer_meta(
        ref self: ContractState, adventurer_id: felt252, adventurer_meta: AdventurerMetadata
    ) {
        self._adventurer_meta.write(adventurer_id, adventurer_meta);
    }
    #[inline(always)]
    fn _load_game_entropy(self: @ContractState) -> GameEntropy {
        self._game_entropy.read()
    }
    #[inline(always)]
    fn _save_game_entropy(ref self: ContractState, game_entropy: GameEntropy) {
        self._game_entropy.write(game_entropy);
    }

    /// @title Internal Rotate Game Entropy Function
    ///
    /// @notice Rotates the game's entropy based on the current block information.
    /// @dev This function checks that the minimum blocks have elapsed since the last rotation before proceeding.
    /// Uses the Poseidon hash function for the entropy generation.
    fn _rotate_game_entropy(ref self: ContractState) {
        // load current game entropy
        let prev_game_entropy = _load_game_entropy(@self);

        // get current block data
        let current_block_info = starknet::get_block_info().unbox();

        // assert game entropy is eligible to be rotated
        assert(
            current_block_info.block_number >= prev_game_entropy.next_update_block,
            messages::BLOCK_NUMBER_ERROR
        );

        // calculate the blocks per hour over the last entropy rotation period
        let blocks_per_hour = ImplGameEntropy::calculate_blocks_per_hour(
            prev_game_entropy.last_updated_block,
            prev_game_entropy.last_updated_time,
            current_block_info.block_number,
            current_block_info.block_timestamp
        );

        // use the block speed to dynamically set the next block eligible for rotation
        // @dev this ensures game can handle starknet changing block times
        let next_update_block = ImplGameEntropy::calculate_next_update_block(
            current_block_info.block_number, blocks_per_hour
        );

        // generate new game entropy
        let new_game_entropy = ImplGameEntropy::new(
            current_block_info.block_number, current_block_info.block_timestamp, next_update_block
        );

        // save game entropy
        _save_game_entropy(ref self, new_game_entropy);

        // emit event
        __event_GameEntropyRotated(
            ref self,
            GameEntropyRotatedEvent {
                prev_hash: prev_game_entropy.hash,
                prev_block_number: prev_game_entropy.last_updated_block,
                prev_block_timestamp: prev_game_entropy.last_updated_time,
                prev_next_rotation_block: prev_game_entropy.next_update_block,
                new_hash: new_game_entropy.hash,
                new_block_number: new_game_entropy.last_updated_block,
                new_block_timestamp: new_game_entropy.last_updated_time,
                new_next_rotation_block: new_game_entropy.next_update_block,
                blocks_per_hour,
            }
        );
    }

    // @notice This function emits events relevant to adventurer leveling up
    // @dev In Loot Survivor, leveling up provides stat upgrades and access to the market
    // @param ref self A reference to the contract state.
    // @param ref adventurer A reference to the adventurer whose level is being updated.
    // @param adventurer_id The unique identifier of the adventurer.
    // @param previous_level The level of the adventurer before this level up.
    // @param new_level The new level of the adventurer after leveling up.
    fn _emit_level_up_events(
        ref self: ContractState,
        adventurer: Adventurer,
        adventurer_id: felt252,
        previous_level: u8,
        new_level: u8,
    ) {
        let adventurer_state = AdventurerState {
            owner: get_caller_address(), adventurer_id, adventurer
        };
        let adventurer_entropy: u128 = _unpack_adventurer_meta(@self, adventurer_id).entropy.into();

        // emit level up event
        if (new_level > previous_level) {
            __event_AdventurerLeveledUp(ref self, adventurer_state, previous_level, new_level);
        }
        // emit stat upgrades available event
        let available_items = _get_items_on_market(
            @self, adventurer_entropy, adventurer.xp, adventurer.stat_points_available
        );

        __event_UpgradesAvailable(ref self, adventurer_state, available_items);
    }

    #[inline(always)]
    fn _pack_loot_special_names_storage(
        ref self: ContractState,
        adventurer_id: felt252,
        storage_index: u8,
        loot_special_names_storage: ItemSpecialsStorage,
    ) {
        self._item_specials.write((adventurer_id, storage_index), loot_special_names_storage);
    }

    #[inline(always)]
    fn _get_special_storages(
        self: @ContractState, adventurer_id: felt252
    ) -> (ItemSpecialsStorage, ItemSpecialsStorage) {
        (
            _get_specials_storage(self, adventurer_id, LOOT_NAME_STORAGE_INDEX_1),
            _get_specials_storage(self, adventurer_id, LOOT_NAME_STORAGE_INDEX_2),
        )
    }

    #[inline(always)]
    fn _get_specials_storage(
        self: @ContractState, adventurer_id: felt252, storage_index: u8
    ) -> ItemSpecialsStorage {
        self._item_specials.read((adventurer_id, storage_index))
    }

    #[inline(always)]
    fn _get_item_specials(
        self: @ContractState, adventurer_id: felt252, item: ItemPrimitive
    ) -> ItemSpecials {
        if (item.get_greatness() >= 15) {
            ImplItemSpecials::get_specials(
                _get_specials_storage(self, adventurer_id, _get_storage_index(self, item.metadata)),
                item
            )
        } else {
            ItemSpecials { special1: 0, special2: 0, special3: 0 }
        }
    }
    #[inline(always)]
    fn _owner_of(self: @ContractState, adventurer_id: felt252) -> ContractAddress {
        self._owner.read(adventurer_id)
    }
    #[inline(always)]
    fn _next_game_entropy_rotation(self: @ContractState) -> felt252 {
        _load_game_entropy(self).last_updated_block.into()
            + STARTING_GAME_ENTROPY_ROTATION_INTERVAL.into()
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
        assert(adventurer.stat_points_available != 0, messages::MARKET_CLOSED);
    }
    fn _assert_item_not_owned(adventurer: Adventurer, bag: Bag, item_id: u8) {
        let (item_in_bag, _) = bag.contains(item_id);
        assert(
            adventurer.is_equipped(item_id) == false && item_in_bag == false,
            messages::ITEM_ALREADY_OWNED
        );
    }
    fn _assert_item_is_available(
        adventurer_entropy: u128, stat_points_available: u8, adventurer_xp: u16, item_id: u8
    ) {
        assert(
            ImplMarket::is_item_available(
                adventurer_entropy, adventurer_xp, stat_points_available, item_id
            ),
            messages::ITEM_DOES_NOT_EXIST
        );
    }
    fn _assert_not_starter_beast(adventurer: Adventurer) {
        assert(adventurer.get_level() > 1, messages::CANT_FLEE_STARTER_BEAST);
    }
    fn _assert_no_stat_upgrades_available(adventurer: Adventurer) {
        assert(adventurer.stat_points_available == 0, messages::STAT_UPGRADES_AVAILABLE);
    }
    fn _assert_not_dead(self: Adventurer) {
        assert(self.health != 0, messages::DEAD_ADVENTURER);
    }
    fn _assert_valid_starter_weapon(starting_weapon: u8) {
        assert(
            ImplLoot::is_starting_weapon(starting_weapon) == true, messages::INVALID_STARTING_WEAPON
        );
    }
    fn _assert_starting_stats(starting_stats: Stats) {
        let total_stats = starting_stats.strength
            + starting_stats.dexterity
            + starting_stats.vitality
            + starting_stats.intelligence
            + starting_stats.wisdom
            + starting_stats.charisma;
        assert(total_stats == NUM_STARTING_STATS, messages::WRONG_NUM_STARTING_STATS);
        _assert_zero_luck(starting_stats);
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

    fn _assert_stat_balance(stat_upgrades: Stats, stat_points_available: u8) {
        let stat_upgrade_count = stat_upgrades.strength
            + stat_upgrades.dexterity
            + stat_upgrades.vitality
            + stat_upgrades.intelligence
            + stat_upgrades.wisdom
            + stat_upgrades.charisma;

        if stat_points_available < stat_upgrade_count {
            panic_with_felt252(messages::INSUFFICIENT_STAT_UPGRADES);
        } else if stat_points_available > stat_upgrade_count {
            panic_with_felt252(messages::MUST_USE_ALL_STATS);
        }
    }
    fn _assert_valid_stat_selection(adventurer: Adventurer, stat_upgrades: Stats) {
        _assert_upgrades_available(adventurer);
        _assert_stat_balance(stat_upgrades, adventurer.stat_points_available);
        _assert_zero_luck(stat_upgrades);
    }

    fn _assert_rate_limit(actions_per_block: u8, rate_limit: u64) {
        assert(actions_per_block.into() < rate_limit, messages::RATE_LIMIT_EXCEEDED);
    }

    fn _assert_is_idle(self: @ContractState, adventurer: Adventurer) {
        let game_entropy = _load_game_entropy(self);
        let (is_idle, _) = _is_idle(adventurer, game_entropy);
        assert(is_idle, messages::ADVENTURER_NOT_IDLE);
    }
    fn _is_idle(self: Adventurer, game_entropy: GameEntropy) -> (bool, u16) {
        // get number of blocks since the players last turn
        let idle_blocks = self.get_idle_blocks(starknet::get_block_info().unbox().block_number);

        // return if player is idle along with number of blocks
        (game_entropy.is_adventurer_idle(idle_blocks.into()), idle_blocks)
    }

    // @notice: The idle penalty in Loot Survivor is death to protect the game against bots
    //          while this may seem harsh, Loot Survivor is modeled after an arcade game. You can't
    //          walk away from a game of Galaga for 10 minutes and come back expecting to still be alive
    fn _apply_idle_penalty(
        ref self: ContractState,
        adventurer_id: felt252,
        ref adventurer: Adventurer,
        idle_blocks: u16
    ) {
        // deduct it from adventurer's health
        adventurer.health = 0;

        // emit idle death penalty event
        __event_IdleDeathPenalty(ref self, adventurer, adventurer_id, idle_blocks);

        // process adventurer death
        _process_adventurer_death(ref self, adventurer, adventurer_id, 0, 0);
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
        adventurer_entropy: u128,
        adventurer_xp: u16,
        adventurer_stat_points: u8
    ) -> Array<u8> {
        ImplMarket::get_market_items(adventurer_entropy, adventurer_xp, adventurer_stat_points)
    }
    #[inline(always)]
    fn _get_items_on_market_by_slot(
        self: @ContractState,
        adventurer_entropy: u128,
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
        adventurer_entropy: u128,
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
        let (adventurer, _, _) = _unpack_adventurer_and_bag_with_stat_boosts(self, adventurer_id);
        adventurer.charisma_adjusted_potion_price()
    }

    fn _get_item_price(self: @ContractState, adventurer_id: felt252, item_id: u8) -> u16 {
        let (adventurer, _, _) = _unpack_adventurer_and_bag_with_stat_boosts(self, adventurer_id);
        let base_item_price = ImplMarket::get_price(ImplLoot::get_tier(item_id));
        let charisma_adjusted_price = adventurer.charisma_adjusted_item_price(base_item_price);

        charisma_adjusted_price
    }

    fn _get_attacking_beast(self: @ContractState, adventurer_id: felt252) -> Beast {
        // get adventurer
        let adventurer = _unpack_adventurer(self, adventurer_id);

        // assert adventurer is in battle
        assert(adventurer.beast_health != 0, messages::NOT_IN_BATTLE);

        // get adventurer entropy
        let adventurer_entropy: u128 = _unpack_adventurer_meta(self, adventurer_id).entropy.into();

        // get beast and beast seed
        let (beast, beast_seed) = adventurer.get_beast(adventurer_entropy);

        // return beast
        beast
    }

    #[inline(always)]
    fn _get_storage_index(self: @ContractState, meta_data_id: u8) -> u8 {
        if (meta_data_id <= 10) {
            LOOT_NAME_STORAGE_INDEX_1
        } else {
            LOOT_NAME_STORAGE_INDEX_2
        }
    }

    // @notice returns the combat spec for an item so it can be used with combat module
    // @param self - read-only reference to the contract state
    // @param adventurer_id - the id of the adventurer
    // @param item - the item to get the combat spec for
    fn _get_combat_spec(
        self: @ContractState, adventurer_id: felt252, item: ItemPrimitive
    ) -> CombatSpec {
        // if item is 0, return a default combat spec
        if (item.id == 0) {
            CombatSpec {
                tier: Tier::None(()),
                item_type: Type::None(()),
                level: 1,
                specials: SpecialPowers { special1: 0, special2: 0, special3: 0 }
            }
        } else {
            // otherwise get the loot item from the item id
            let loot_item = ImplLoot::get_item(item.id);

            // if the item is lower than G15
            if item.get_greatness() < 15 {
                // we don't need to fetch item specials from storage
                CombatSpec {
                    tier: loot_item.tier,
                    item_type: loot_item.item_type,
                    level: item.get_greatness().into(),
                    specials: SpecialPowers { special1: 0, special2: 0, special3: 0 }
                }
            } else {
                // if item is G15 or above, we need to fetch specials
                let item_details = ImplItemSpecials::get_specials(
                    _get_specials_storage(
                        self, adventurer_id, _get_storage_index(self, item.metadata)
                    ),
                    item
                );
                let specials = SpecialPowers {
                    special1: item_details.special1,
                    special2: item_details.special2,
                    special3: item_details.special3
                };
                // and return a CombatSpec with those specials
                CombatSpec {
                    tier: loot_item.tier,
                    item_type: loot_item.item_type,
                    level: item.get_greatness().into(),
                    specials
                }
            }
        }
    }

    #[inline(always)]
    fn _get_adventurer_entropy(self: @ContractState, adventurer_id: felt252) -> u128 {
        _unpack_adventurer_meta(self, adventurer_id).entropy
    }

    // @notice _get_adventurer_and_game_entropy returns the adventurer entropy and game entropy
    // @param self - read-only reference to the contract state
    // @param adventurer_id - the id of the adventurer
    // @return (u128, u64) - adventurer entropy and game entropy
    #[inline(always)]
    fn _get_adventurer_and_game_entropy(
        self: @ContractState, adventurer_id: felt252
    ) -> (u128, GameEntropy) {
        (_get_adventurer_entropy(self, adventurer_id), _load_game_entropy(self))
    }

    #[inline(always)]
    fn _is_top_score(self: @ContractState, score: u16) -> bool {
        if score > self._leaderboard.read().third.xp {
            true
        } else {
            false
        }
    }

    // @title Update Leaderboard Function
    //
    // @param adventurer_id The unique identifier of the adventurer
    // @param adventurer The adventurer that scored a new high score
    fn _update_leaderboard(
        ref self: ContractState, adventurer_id: felt252, adventurer: Adventurer
    ) {
        // get current leaderboard which will be mutated as part of this function
        let mut leaderboard = self._leaderboard.read();

        // if the player scored a highscore using an Arcade account, we change the owner of the
        // adventurer_id they played with to the master account since the arcade account is intended to be disposable.
        // By doing this, when rewards are later distributed to that adventurer_id, we'll send them to primary account instead of arcade account
        let caller = get_caller_address();
        let account = ISRC5Dispatcher { contract_address: caller };
        if account.supports_interface(ARCADE_ACCOUNT_ID) {
            let primary_account = IMasterControlDispatcher { contract_address: caller }
                .get_master_account();
            self._owner.write(adventurer_id, primary_account);
        };

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
        adventurer_meta: AdventurerMetadata
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
        specials: ItemSpecials
    }

    #[derive(Drop, starknet::Event)]
    struct ItemsLeveledUp {
        adventurer_state: AdventurerState,
        items: Array<ItemLeveledUp>,
    }

    #[derive(Drop, starknet::Event)]
    struct ItemSpecialUnlocked {
        adventurer_state: AdventurerState,
        id: u8,
        level: u8,
        specials: ItemSpecials
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
    struct IdleDeathPenalty {
        adventurer_state: AdventurerState,
        idle_blocks: u16, // number of blocks adventurer was idle
        penalty_threshold: u64, // idle penalty threshold setting
        caller: ContractAddress // address of caller
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
    struct GameEntropyRotatedEvent {
        prev_hash: felt252,
        prev_block_number: u64,
        prev_block_timestamp: u64,
        prev_next_rotation_block: u64,
        new_hash: felt252,
        new_block_number: u64,
        new_block_timestamp: u64,
        new_next_rotation_block: u64,
        blocks_per_hour: u64,
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

    fn __event_GameEntropyRotated(ref self: ContractState, event: GameEntropyRotatedEvent) {
        self.emit(event);
    }

    fn __event_AdventurerUpgraded(
        ref self: ContractState,
        adventurer: Adventurer,
        adventurer_id: felt252,
        bag: Bag,
        stat_upgrades: Stats
    ) {
        let adventurer_state = AdventurerState {
            owner: get_caller_address(), adventurer_id, adventurer
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
        let adventurer_state = AdventurerState {
            owner: get_caller_address(), adventurer_id, adventurer
        };
        self.emit(StartGame { adventurer_state, adventurer_meta });
    }

    fn __event_Discovery(
        ref self: ContractState,
        adventurer: Adventurer,
        adventurer_id: felt252,
        amount: u16,
        discovery_type: DiscoveryType
    ) {
        let adventurer_state = AdventurerState {
            owner: get_caller_address(), adventurer_id, adventurer
        };

        let discovery = Discovery { adventurer_state, amount };

        match discovery_type {
            DiscoveryType::Gold => {
                self.emit(DiscoveredGold { discovery });
            },
            DiscoveryType::Health => {
                self.emit(DiscoveredHealth { discovery });
            }
        }
    }

    fn __event_ObstacleEncounter(
        ref self: ContractState,
        adventurer: Adventurer,
        adventurer_id: felt252,
        dodged: bool,
        obstacle_details: ObstacleDetails,
    ) {
        let adventurer_state = AdventurerState {
            owner: get_caller_address(), adventurer_id, adventurer
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
        let adventurer_state = AdventurerState {
            owner: get_caller_address(), adventurer_id, adventurer
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
        let adventurer_state = AdventurerState {
            owner: get_caller_address(), adventurer_id, adventurer
        };
        self.emit(AttackedBeast { adventurer_state, beast_battle_details });
    }

    fn __event_AttackedByBeast(
        ref self: ContractState,
        adventurer: Adventurer,
        adventurer_id: felt252,
        beast_battle_details: BattleDetails
    ) {
        let adventurer_state = AdventurerState {
            owner: get_caller_address(), adventurer_id, adventurer
        };
        self.emit(AttackedByBeast { adventurer_state, beast_battle_details });
    }

    fn __event_AmbushedByBeast(
        ref self: ContractState,
        adventurer: Adventurer,
        adventurer_id: felt252,
        beast_battle_details: BattleDetails
    ) {
        let adventurer_state = AdventurerState {
            owner: get_caller_address(), adventurer_id, adventurer
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
        let adventurer_state = AdventurerState {
            owner: get_caller_address(), adventurer_id, adventurer
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
        let adventurer_state = AdventurerState {
            owner: get_caller_address(), adventurer_id, adventurer
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
        let adventurer_state = AdventurerState {
            owner: get_caller_address(), adventurer_id, adventurer
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
        let adventurer_state = AdventurerState {
            owner: get_caller_address(), adventurer_id, adventurer
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
        let adventurer_state = AdventurerState {
            owner: get_caller_address(), adventurer_id, adventurer
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
        let adventurer_state = AdventurerState {
            owner: get_caller_address(), adventurer_id, adventurer
        };
        self.emit(ItemsLeveledUp { adventurer_state, items });
    }

    fn __event_NewHighScore(
        ref self: ContractState, adventurer_id: felt252, adventurer: Adventurer, rank: u8
    ) {
        let adventurer_state = AdventurerState {
            owner: get_caller_address(), adventurer_id, adventurer
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

    fn __event_IdleDeathPenalty(
        ref self: ContractState, adventurer: Adventurer, adventurer_id: felt252, idle_blocks: u16,
    ) {
        // intentionally read storage for owner instead of using get_caller_address()
        // because non-owner can result in this function being emitted via `slay_idle_adventurer`
        let adventurer_state = AdventurerState {
            owner: self._owner.read(adventurer_id), adventurer_id, adventurer
        };

        let game_entropy = _load_game_entropy(@self);

        let idle_death_penalty_event = IdleDeathPenalty {
            adventurer_state,
            idle_blocks,
            penalty_threshold: game_entropy.get_idle_penalty_blocks().into(),
            caller: get_caller_address()
        };

        self.emit(idle_death_penalty_event);
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
        let adventurer_state = AdventurerState {
            owner: get_caller_address(), adventurer_id, adventurer
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
        let adventurer_state = AdventurerState {
            owner: get_caller_address(), adventurer_id, adventurer
        };
        self.emit(PurchasedPotions { adventurer_state, quantity, cost, health, });
    }

    #[starknet::interface]
    trait ILeetLoot<T> {
        fn mint(
            ref self: T, to: ContractAddress, beast: u8, prefix: u8, suffix: u8, level: felt252
        );
        fn isMinted(self: @T, beast: u8, prefix: u8, suffix: u8) -> bool;
        fn getMinter(self: @T) -> ContractAddress;
    }

    const DAY: felt252 = 86400;

    fn _can_play(self: @ContractState, token_id: u256) -> bool {
        _last_usage(self, token_id) + DAY.into() < get_block_timestamp().into()
    }

    fn _play_with_token(ref self: ContractState, token_id: u256) {
        let golden_token = _golden_token_dispatcher(ref self);

        let account = ISRC5Dispatcher { contract_address: get_caller_address() };
        // let player = if account.supports_interface(ARCADE_ACCOUNT_ID) {
        //     IMasterControlDispatcher { contract_address: get_caller_address() }.get_master_account()
        // } else {
        //     get_caller_address()
        // };

        assert(_can_play(@self, token_id), 'Cant play');
        assert(golden_token.owner_of(token_id) == account, 'Not owner');

        self
            ._golden_token_last_use
            .write(token_id.try_into().unwrap(), get_block_timestamp().into());
    }

    fn _last_usage(self: @ContractState, token_id: u256) -> u256 {
        self._golden_token_last_use.read(token_id.try_into().unwrap()).into()
    }
}
