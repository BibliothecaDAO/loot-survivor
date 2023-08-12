mod game;
mod tests;

#[starknet::contract]
mod Game {
    // TODO: TESTING CONFIGS 
    // ADJUST THESE BEFORE DEPLOYMENT
    const MIN_BLOCKS_FOR_GAME_ENTROPY_CHANGE: u64 = 8;
    const IDLE_PENALTY_THRESHOLD_BLOCKS: u16 = 8;
    const IDLE_DEATH_PENALTY_BLOCKS: u16 = 300;
    const TEST_ENTROPY: u64 = 12303548;
    const MINIMUM_SCORE_FOR_PAYOUTS: u256 = 500;
    const LOOT_NAME_STORAGE_INDEX_1: u256 = 0;
    const LOOT_NAME_STORAGE_INDEX_2: u256 = 1;

    use option::OptionTrait;
    use box::BoxTrait;
    use core::array::SpanTrait;
    use starknet::{
        get_caller_address, ContractAddress, ContractAddressIntoFelt252, contract_address_const
    };
    use core::traits::{TryInto, Into};
    use core::clone::Clone;
    use array::ArrayTrait;
    use poseidon::poseidon_hash_span;

    use super::game::{
        interfaces::{IGame, IERC20Dispatcher, IERC20DispatcherTrait, IERC20LibraryDispatcher},
        constants::{
            messages, Week, WEEK_2, WEEK_4, WEEK_8, BLOCKS_IN_A_WEEK, COST_TO_PLAY, U64_MAX,
            U128_MAX, STARTER_BEAST_ATTACK_DAMAGE, STARTING_STATS
        }
    };
    use lootitems::{
        loot::{ILoot, Loot, ImplLoot}, statistics::constants::{NamePrefixLength, NameSuffixLength}
    };
    use pack::{pack::{Packing, rshift_split}, constants::{MASK_16, pow, MASK_8, MASK_BOOL, mask}};
    use survivor::{
        adventurer::{Adventurer, ImplAdventurer, IAdventurer}, adventurer_stats::Stats,
        item_primitive::{ImplItemPrimitive, ItemPrimitive}, bag::{Bag, IBag, ImplBag},
        adventurer_meta::{AdventurerMetadata}, exploration::ExploreUtils,
        constants::{
            discovery_constants::DiscoveryEnums::{ExploreResult, TreasureDiscovery},
            adventurer_constants::{
                POTION_HEALTH_AMOUNT, ITEM_XP_MULTIPLIER_BEASTS, ITEM_XP_MULTIPLIER_OBSTACLES,
                ITEM_MAX_GREATNESS, MAX_GREATNESS_STAT_BONUS, StatisticIndex,
                VITALITY_INSTANT_HEALTH_BONUS
            }
        },
        item_meta::{ImplItemSpecials, ItemSpecials, IItemSpecials, ItemSpecialsStorage},
        adventurer_utils::AdventurerUtils
    };
    use market::market::{ImplMarket, LootWithPrice, ItemPurchase};
    use obstacles::obstacle::{ImplObstacle, IObstacle};
    use combat::{
        combat::{CombatSpec, SpecialPowers, ImplCombat}, constants::CombatEnums::{Slot, Tier}
    };
    use beasts::beast::{Beast, IBeast, ImplBeast};

    #[storage]
    struct Storage {
        _global_entropy: u64,
        _last_global_entropy_block: felt252,
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
        UpgradeAvailable: UpgradeAvailable,
        DiscoveredHealth: DiscoveredHealth,
        DiscoveredGold: DiscoveredGold,
        DiscoveredXP: DiscoveredXP,
        DodgedObstacle: DodgedObstacle,
        HitByObstacle: HitByObstacle,
        AmbushedByBeast: AmbushedByBeast,
        DiscoveredBeast: DiscoveredBeast,
        AttackedBeast: AttackedBeast,
        AttackedByBeast: AttackedByBeast,
        SlayedBeast: SlayedBeast,
        FleeFailed: FleeFailed,
        FleeSucceeded: FleeSucceeded,
        PurchasedItems: PurchasedItems,
        PurchasedPotions: PurchasedPotions,
        EquippedItems: EquippedItems,
        DroppedItems: DroppedItems,
        ItemLeveledUp: ItemLeveledUp,
        ItemSpecialUnlocked: ItemSpecialUnlocked,
        NewHighScore: NewHighScore,
        AdventurerDied: AdventurerDied,
        AdventurerLeveledUp: AdventurerLeveledUp,
        NewItemsAvailable: NewItemsAvailable,
        IdleDamagePenalty: IdleDamagePenalty,
        AdventurerUpgraded: AdventurerUpgraded
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
        //@notice Initiates the adventure for an adventurer with specific starting configurations.
        //@param self The current state of the contract.
        //@param interface_id The address of the specific contract interface.
        //@param starting_weapon The initial weapon choice of the adventurer (e.g. wand, book, club, short sword).
        //@param adventurer_meta Metadata containing information about the adventurer.
        //@param starting_stats The initial statistics of the adventurer.
        //@dev Ensures that the chosen starting weapon and stats are valid before beginning the adventure.
        fn start(
            ref self: ContractState,
            interface_id: ContractAddress,
            starting_weapon: u8,
            adventurer_meta: AdventurerMetadata,
            starting_stats: Stats,
        ) {
            // assert weapon is valid starter weapon (wand, book, club, short sword)
            _assert_valid_starter_weapon(starting_weapon);

            // assert correct number of starting stats
            _assert_starting_stat_count(starting_stats);

            let caller = get_caller_address();
            let block_number = starknet::get_block_info().unbox().block_number;

            _start(
                ref self, block_number, caller, starting_weapon, adventurer_meta, starting_stats
            );

            _payout(ref self, caller, block_number, interface_id);
        }

        //@notice Sends an adventurer to explore.
        //@param self The current state of the contract.
        //@param adventurer_id The unique identifier of the adventurer.
        //@param till_beast Indicates if the adventurer will explore until encountering a beast.
        //@dev Ensures the caller owns the adventurer and checks various conditions such as the adventurer's health and battle status.
        fn explore(ref self: ContractState, adventurer_id: u256, till_beast: bool) {
            // assert caller owns adventurer
            _assert_ownership(@self, adventurer_id);

            // get item names from storage
            let (mut name_storage1, mut name_storage2) = _get_special_storages(
                @self, adventurer_id
            );

            // store the unmodified storages so we can use these
            // to remove the same stat boosts when we pack and save the adventurer
            let original_name_storage1 = name_storage1;
            let original_name_storage2 = name_storage2;

            // get adventurer from storage and unpack
            let mut adventurer = _unpack_adventurer_apply_stat_boost(
                @self, adventurer_id, name_storage1, name_storage2
            );

            // assert adventurer is not dead
            _assert_not_dead(adventurer.health);

            // assert adventurer does not have stat upgrades available
            _assert_no_stat_upgrades_available(adventurer.stat_points_available);

            // assert adventurer is not in battle
            _assert_not_in_battle(adventurer.beast_health);

            // if the adventurer has exceeded the idle penalty threshold
            let (is_idle, num_blocks) = _idle_longer_than_penalty_threshold(adventurer);
            if (is_idle) {
                // apply idle penalty
                _apply_idle_penalty(ref self, adventurer_id, ref adventurer, num_blocks);
            } else {
                // else send them off to explore
                let adventurer_entropy: u128 = _adventurer_meta_unpacked(@self, adventurer_id)
                    .entropy
                    .into();

                let global_entropy = _get_global_entropy(@self).into();

                _explore(
                    ref self,
                    ref adventurer,
                    adventurer_id,
                    ref name_storage1,
                    ref name_storage2,
                    adventurer_entropy,
                    global_entropy,
                    till_beast
                );
            }

            // update players last action block number
            adventurer.set_last_action(starknet::get_block_info().unbox().block_number);

            // write the resulting adventurer to storage
            _pack_adventurer_remove_stat_boost(
                ref self,
                adventurer_id,
                ref adventurer,
                original_name_storage1,
                original_name_storage2
            );
        }

        //@notice Initiates an attack action for an adventurer.
        //@param self The current state of the contract.
        //@param adventurer_id The unique identifier of the adventurer.
        //@param to_the_death Indicates if the adventurer will fight to the death.
        //@dev Ensures the caller owns the adventurer, verifies various conditions, and executes the attack logic.
        fn attack(ref self: ContractState, adventurer_id: u256, to_the_death: bool) {
            // assert caller owns adventurer
            _assert_ownership(@self, adventurer_id);

            // get item names from storage
            let (mut name_storage1, mut name_storage2) = _get_special_storages(
                @self, adventurer_id
            );

            // store the unmodified storages so we can use these
            // to remove the same stat boosts when we pack and save the adventurer
            // TODO: If we add a modified flag to the storages, we can
            // check if they have been modified and if they have
            // we can grab a fresh copy of the storages from storage
            // to remove the special stat boosts before overwriting specials storage
            // this will remove the need for these lines of code in all the 
            // external functions. 
            let original_name_storage1 = name_storage1;
            let original_name_storage2 = name_storage2;

            // get adventurer from storage and unpack
            let mut adventurer = _unpack_adventurer_apply_stat_boost(
                @self, adventurer_id, name_storage1, name_storage2
            );

            // assert adventurer is not dead
            _assert_not_dead(adventurer.health);

            // assert adventurer has a beast to attack
            _assert_in_battle(adventurer.beast_health);

            // if the adventurer has exceeded the idle penalty threshold
            let (is_idle, num_blocks) = _idle_longer_than_penalty_threshold(adventurer);
            if (is_idle) {
                // apply idle penalty
                _apply_idle_penalty(ref self, adventurer_id, ref adventurer, num_blocks);
            } else {
                // otherwise process their attack
                _attack(
                    ref self,
                    ref adventurer,
                    adventurer_id,
                    ref name_storage1,
                    ref name_storage2,
                    to_the_death
                );
            }

            // update players last action block number
            adventurer.set_last_action(starknet::get_block_info().unbox().block_number);

            // pack and save adventurer
            _pack_adventurer_remove_stat_boost(
                ref self,
                adventurer_id,
                ref adventurer,
                original_name_storage1,
                original_name_storage2
            );
        }

        //@notice Initiates a flee action for an adventurer.
        //@param self The current state of the contract.
        //@param adventurer_id The unique identifier of the adventurer.
        //@param to_the_death Indicates if the adventurer will attempt to flee to the death.
        //@dev Ensures the caller owns the adventurer, verifies various conditions, and executes the flee logic. 
        //If to_the_death is set, the adventurer will repeatedly attempt to flee until either the adventurer or the beast is dead.
        fn flee(ref self: ContractState, adventurer_id: u256, to_the_death: bool) {
            // assert caller owns adventurer
            _assert_ownership(@self, adventurer_id);

            // get item names from storage
            let (name_storage1, name_storage2) = _get_special_storages(@self, adventurer_id);

            // get adventurer from storage and unpack
            let mut adventurer = _unpack_adventurer_apply_stat_boost(
                @self, adventurer_id, name_storage1, name_storage2
            );

            // assert adventurer is not dead
            _assert_not_dead(adventurer.health);

            // can't flee from first beast
            _assert_not_starter_beast(adventurer.get_level());

            // assert adventurer has a beast to attack
            _assert_in_battle(adventurer.beast_health);

            // assert dexterity is not zero
            _assert_dexterity_not_zero(adventurer.stats.dexterity);

            // if the adventurer has exceeded the idle penalty threshold
            let (is_idle, num_blocks) = _idle_longer_than_penalty_threshold(adventurer);
            if (is_idle) {
                // apply idle penalty
                _apply_idle_penalty(ref self, adventurer_id, ref adventurer, num_blocks);
            } else {
                // get adventurer entropy from storage
                let adventurer_entropy: u128 = _adventurer_meta_unpacked(@self, adventurer_id)
                    .entropy
                    .into();

                // get game entropy from storage
                let global_entropy: u128 = _get_global_entropy(@self).into();

                // get beast seed based on adventurer entropy and adventurer state
                let beast_seed: u128 = adventurer.get_beast_seed(adventurer_entropy);
                // generate beast without special powers ()
                let beast = ImplBeast::get_beast(
                    adventurer.get_level(),
                    ImplBeast::get_special_names(
                        adventurer.get_level(),
                        beast_seed,
                        NamePrefixLength.into(),
                        NameSuffixLength.into()
                    ),
                    beast_seed,
                    ImplLoot::get_type(adventurer.weapon.id)
                );

                // attempt to flee
                _flee(
                    ref self,
                    ref adventurer,
                    adventurer_id,
                    adventurer_entropy,
                    global_entropy,
                    beast_seed,
                    beast,
                    to_the_death
                );
                loop {
                    if !to_the_death || adventurer.health == 0 || adventurer.beast_health == 0 {
                        break ();
                    }

                    // if adventurer set the attack to the death flag
                    // and the adventurer is still alive and the beast is still alive
                    // attempt to flee again
                    _flee(
                        ref self,
                        ref adventurer,
                        adventurer_id,
                        adventurer_entropy,
                        global_entropy,
                        beast_seed,
                        beast,
                        to_the_death
                    );
                };
            }

            // update players last action block number
            adventurer.set_last_action(starknet::get_block_info().unbox().block_number);

            // pack and save adventurer
            _pack_adventurer_remove_stat_boost(
                ref self, adventurer_id, ref adventurer, name_storage1, name_storage2
            );
        }

        //@notice Equips an adventurer with specified items.
        //@param self The current state of the contract.
        //@param adventurer_id The ID of the adventurer to equip.
        //@param items An array of items (up to 8) to equip the adventurer with.
        //@dev This function verifies the ownership, ensures the item count, and equips the adventurer. It also handles a counter-attack if the adventurer is in battle.
        //@dev This function interacts with various internal methods for assert checks, state unpacking, item equipping, and counter-attacks.
        //@dev Emits an event if a counter-attack happens in battle (not shown in the code).
        fn equip(ref self: ContractState, adventurer_id: u256, items: Array<u8>) {
            // assert caller owns adventurer
            _assert_ownership(@self, adventurer_id);

            // assert items length is less than or equal to 8
            assert(items.len() <= 8, messages::TOO_MANY_ITEMS);

            // get item names from storage
            let (name_storage1, name_storage2) = _get_special_storages(@self, adventurer_id);

            // unpack adventurer from storage and apply boosts
            let mut adventurer = _unpack_adventurer_apply_stat_boost(
                @self, adventurer_id, name_storage1, name_storage2
            );

            // assert adventurer is not dead
            _assert_not_dead(adventurer.health);

            // get adventurers bag
            let mut bag = _bag_unpacked(@self, adventurer_id);

            // equip items, passing in items as a clone so we can maintain ownership of original for event
            _equip_items(
                ref self,
                ref adventurer,
                adventurer_id,
                ref bag,
                name_storage1,
                name_storage2,
                items.clone(),
                false
            );

            // if the adventurer is equipping an item during battle
            if (adventurer.in_battle()) {
                // the beast gets a counter attack

                // get entropy
                let (adventurer_entropy, global_entropy) = _get_adventurer_and_global_entropy(
                    @self, adventurer_id
                );

                // get beast seed from entropy
                let (beast, beast_seed) = _get_beast(@self, adventurer, adventurer_entropy);

                // get two random numbers from entropy sources
                let (attack_rnd_1, attack_rnd_2) = _get_live_entropy(
                    adventurer_entropy, global_entropy.into(), adventurer
                );

                // process beast counter attacks
                _beast_counter_attack(
                    ref self,
                    ref adventurer,
                    adventurer_id,
                    AdventurerUtils::get_random_attack_location(attack_rnd_1),
                    beast,
                    beast_seed,
                    attack_rnd_2,
                    false
                );
            }

            // remove stats, pack, and save adventurer 
            _pack_adventurer_remove_stat_boost(
                ref self, adventurer_id, ref adventurer, name_storage1, name_storage2
            );

            // if the bag was mutated
            if bag.mutated {
                // pack and update bag
                _pack_bag(ref self, adventurer_id, bag);
            }
        }


        // @dev This function allows the owner of an adventurer to drop multiple items.
        // @param adventurer_id The ID of the adventurer dropping the items.
        // @param items A Array of item IDs to be dropped. The length of this Array must be less than or equal to the maximum item capacity.
        // @notice This function does not handle adding dropped items to any form of external inventory or the ground. This must be handled separately. It does however emit an event for each dropped item.
        fn drop_items(ref self: ContractState, adventurer_id: u256, items: Array<u8>) {
            // assert caller owns adventurer
            _assert_ownership(@self, adventurer_id);

            // unpack adventurer from storage (no need to apply stat boosts)
            let mut adventurer = _unpack_adventurer(@self, adventurer_id);

            // assert adventurer is not dead
            _assert_not_dead(adventurer.health);

            // get adventurers bag
            let mut bag = _bag_unpacked(@self, adventurer_id);

            // drop items
            _drop_items(ref self, ref adventurer, ref bag, adventurer_id, items.clone());

            // if the adventurer was mutated
            if (adventurer.mutated) {
                // pack and save it
                _pack_adventurer(ref self, adventurer_id, adventurer);
            }

            // if the bag was mutated
            if (bag.mutated) {
                // pack and save it
                _pack_bag(ref self, adventurer_id, bag);
            }

            // emit dropped items event
            __event_DroppedItems(
                ref self,
                AdventurerStateWithBag {
                    adventurer_state: AdventurerState {
                        owner: get_caller_address(),
                        adventurer_id: adventurer_id,
                        adventurer: adventurer
                    }, bag: bag
                },
                items
            );
        }

        //@notice Upgrades an adventurer's stats and optionally purchases potions and items.
        //@param self The current state of the contract.
        //@param adventurer_id The ID of the adventurer to upgrade.
        //@param potions The number of potions to purchase.
        //@param strength Points to add to the strength stat.
        //@param dexterity Points to add to the dexterity stat.
        //@param vitality Points to add to the vitality stat.
        //@param intelligence Points to add to the intelligence stat.
        //@param wisdom Points to add to the wisdom stat.
        //@param charisma Points to add to the charisma stat.
        //@param items An array of items to purchase as part of the upgrade.
        //@dev This function verifies ownership, asserts that the adventurer is not dead or in battle, ensures the market is open, upgrades stats, and processes potions and item purchases.
        //@dev Interacts with various internal methods for assert checks, stat upgrades, item purchasing, and event emission.
        //@emit AdventurerUpgraded An event that is emitted when the adventurer is successfully upgraded.
        fn upgrade_adventurer(
            ref self: ContractState,
            adventurer_id: u256,
            potions: u8,
            strength: u8,
            dexterity: u8,
            vitality: u8,
            intelligence: u8,
            wisdom: u8,
            charisma: u8,
            items: Array<ItemPurchase>,
        ) {
            // assert caller owns adventurer
            _assert_ownership(@self, adventurer_id);

            // get item names from storage
            let (name_storage1, name_storage2) = _get_special_storages(@self, adventurer_id);

            // unpack adventurer from storage (stat boosts applied on unpacking)
            let mut adventurer = _unpack_adventurer_apply_stat_boost(
                @self, adventurer_id, name_storage1, name_storage2
            );
            let unmodified_adventurer = adventurer;

            // unpack Loot bag from storage
            let mut bag = _bag_unpacked(@self, adventurer_id);

            // assert adventurer is not dead
            _assert_not_dead(adventurer.health);

            // assert adventurer is not in battle
            _assert_not_in_battle(adventurer.beast_health);

            // assert market is open
            _assert_market_is_open(adventurer.stat_points_available);

            // upgrade adventurer's stats
            _upgrade_stats(
                @self, ref adventurer, strength, dexterity, vitality, intelligence, wisdom, charisma
            );

            // if the player is buying potions as part of the upgrade
            if potions > 0 {
                // process potion purchase
                _buy_potions(ref self, ref adventurer, adventurer_id, potions);
            }

            // if the player is buying items as part of the upgrade
            if (items.len() > 0) {
                // process item purchase, passing in the unmodified adventurer so we can access the original market items
                _buy_items(
                    ref self,
                    ref adventurer,
                    unmodified_adventurer,
                    ref bag,
                    name_storage1,
                    name_storage2,
                    adventurer_id,
                    items.clone()
                );
            }

            // emit adventurer upgraded event
            __event_AdventurerUpgraded(
                ref self,
                AdventurerUpgraded {
                    adventurer_state_with_bag: AdventurerStateWithBag {
                        adventurer_state: AdventurerState {
                            owner: get_caller_address(), adventurer_id, adventurer
                        }, bag: bag
                    },
                    strength_increase: adventurer.stats.strength
                        - unmodified_adventurer.stats.strength,
                    dexterity_increase: adventurer.stats.dexterity
                        - unmodified_adventurer.stats.dexterity,
                    vitality_increase: adventurer.stats.vitality
                        - unmodified_adventurer.stats.vitality,
                    intelligence_increase: adventurer.stats.intelligence
                        - unmodified_adventurer.stats.intelligence,
                    wisdom_increase: adventurer.stats.wisdom - unmodified_adventurer.stats.wisdom,
                    charisma_increase: adventurer.stats.charisma
                        - unmodified_adventurer.stats.charisma
                }
            );

            // if the upgrade mutated the adventurer's bag
            if (bag.mutated) {
                // pack and save updated bag
                _pack_bag(ref self, adventurer_id, bag);
            }

            // remove stat boosts, pack, and save adventurer
            _pack_adventurer_remove_stat_boost(
                ref self, adventurer_id, ref adventurer, name_storage1, name_storage2
            );
        }

        // @notice slays an adventurer that has been idle for too long
        // @dev Anyone can call this function, so we intentionally don't assert ownership.
        // @param adventurer_id The unique identifier for the adventurer to be slayed.
        fn slay_idle_adventurer(ref self: ContractState, adventurer_id: u256) {
            // unpack adventurer from storage (no need for stat boosts)
            let mut adventurer = _unpack_adventurer(@self, adventurer_id);

            // assert adventurer is not already dead
            _assert_not_dead(adventurer.health);

            // assert adventurer is actually idle
            _assert_fatally_idle(adventurer);

            // slay adventurer by setting adventurer health to 0
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

            // remove stat boosts, pack, and save adventurer
            _pack_adventurer(ref self, adventurer_id, adventurer);
        }

        //
        // view functions
        //
        fn get_adventurer(self: @ContractState, adventurer_id: u256) -> Adventurer {
            let (name_storage1, name_storage2) = _get_special_storages(self, adventurer_id);
            _unpack_adventurer_apply_stat_boost(self, adventurer_id, name_storage1, name_storage2)
        }
        fn get_adventurer_no_boosts(self: @ContractState, adventurer_id: u256) -> Adventurer {
            _unpack_adventurer(self, adventurer_id)
        }
        fn get_adventurer_meta(self: @ContractState, adventurer_id: u256) -> AdventurerMetadata {
            _adventurer_meta_unpacked(self, adventurer_id)
        }
        fn get_bag(self: @ContractState, adventurer_id: u256) -> Bag {
            _bag_unpacked(self, adventurer_id)
        }
        fn get_weapon_specials(self: @ContractState, adventurer_id: u256) -> ItemSpecials {
            let adventurer = _unpack_adventurer(self, adventurer_id);
            _get_special_names(self, adventurer_id, adventurer.weapon)
        }
        fn get_chest_specials(self: @ContractState, adventurer_id: u256) -> ItemSpecials {
            let adventurer = _unpack_adventurer(self, adventurer_id);
            _get_special_names(self, adventurer_id, adventurer.chest)
        }
        fn get_head_specials(self: @ContractState, adventurer_id: u256) -> ItemSpecials {
            let adventurer = _unpack_adventurer(self, adventurer_id);
            _get_special_names(self, adventurer_id, adventurer.head)
        }
        fn get_waist_specials(self: @ContractState, adventurer_id: u256) -> ItemSpecials {
            let adventurer = _unpack_adventurer(self, adventurer_id);
            _get_special_names(self, adventurer_id, adventurer.waist)
        }
        fn get_foot_specials(self: @ContractState, adventurer_id: u256) -> ItemSpecials {
            let adventurer = _unpack_adventurer(self, adventurer_id);
            _get_special_names(self, adventurer_id, adventurer.foot)
        }
        fn get_hand_specials(self: @ContractState, adventurer_id: u256) -> ItemSpecials {
            let adventurer = _unpack_adventurer(self, adventurer_id);
            _get_special_names(self, adventurer_id, adventurer.hand)
        }
        fn get_necklace_specials(self: @ContractState, adventurer_id: u256) -> ItemSpecials {
            let adventurer = _unpack_adventurer(self, adventurer_id);
            _get_special_names(self, adventurer_id, adventurer.neck)
        }
        fn get_ring_specials(self: @ContractState, adventurer_id: u256) -> ItemSpecials {
            let adventurer = _unpack_adventurer(self, adventurer_id);
            _get_special_names(self, adventurer_id, adventurer.ring)
        }
        fn get_items_on_market(self: @ContractState, adventurer_id: u256) -> Array<LootWithPrice> {
            let adventurer = _unpack_adventurer(self, adventurer_id);
            _assert_market_is_open(adventurer.stat_points_available);
            _get_items_on_market(self, adventurer_id, adventurer)
        }
        fn get_items_on_market_by_slot(
            self: @ContractState, adventurer_id: u256, slot: u8
        ) -> Array<u8> {
            let adventurer = _unpack_adventurer(self, adventurer_id);
            _assert_market_is_open(adventurer.stat_points_available);
            _get_market_items_by_slot(self, adventurer_id, adventurer, ImplCombat::u8_to_slot(slot))
        }
        fn get_items_on_market_by_tier(
            self: @ContractState, adventurer_id: u256, tier: u8
        ) -> Array<u8> {
            let adventurer = _unpack_adventurer(self, adventurer_id);
            _assert_market_is_open(adventurer.stat_points_available);

            if tier == 1 {
                _get_market_items_by_tier(self, adventurer_id, adventurer, Tier::T1(()))
            } else if tier == 2 {
                _get_market_items_by_tier(self, adventurer_id, adventurer, Tier::T2(()))
            } else if tier == 3 {
                _get_market_items_by_tier(self, adventurer_id, adventurer, Tier::T3(()))
            } else if tier == 4 {
                _get_market_items_by_tier(self, adventurer_id, adventurer, Tier::T4(()))
            } else {
                _get_market_items_by_tier(self, adventurer_id, adventurer, Tier::T5(()))
            }
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
        fn get_stat_upgrades_available(self: @ContractState, adventurer_id: u256) -> u8 {
            _unpack_adventurer(self, adventurer_id).stat_points_available
        }
        fn get_last_action(self: @ContractState, adventurer_id: u256) -> u16 {
            _unpack_adventurer(self, adventurer_id).last_action
        }
        fn get_weapon_greatness(self: @ContractState, adventurer_id: u256) -> u8 {
            _unpack_adventurer(self, adventurer_id).weapon.get_greatness()
        }
        fn get_chest_greatness(self: @ContractState, adventurer_id: u256) -> u8 {
            _unpack_adventurer(self, adventurer_id).chest.get_greatness()
        }
        fn get_head_greatness(self: @ContractState, adventurer_id: u256) -> u8 {
            _unpack_adventurer(self, adventurer_id).head.get_greatness()
        }
        fn get_waist_greatness(self: @ContractState, adventurer_id: u256) -> u8 {
            _unpack_adventurer(self, adventurer_id).waist.get_greatness()
        }
        fn get_foot_greatness(self: @ContractState, adventurer_id: u256) -> u8 {
            _unpack_adventurer(self, adventurer_id).foot.get_greatness()
        }
        fn get_hand_greatness(self: @ContractState, adventurer_id: u256) -> u8 {
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
        fn get_stats(self: @ContractState, adventurer_id: u256) -> Stats {
            let (name_storage1, name_storage2) = _get_special_storages(self, adventurer_id);
            _unpack_adventurer_apply_stat_boost(self, adventurer_id, name_storage1, name_storage2)
                .stats
        }
        fn get_base_strength(self: @ContractState, adventurer_id: u256) -> u8 {
            _unpack_adventurer(self, adventurer_id).stats.strength
        }
        fn get_strength(self: @ContractState, adventurer_id: u256) -> u8 {
            let (name_storage1, name_storage2) = _get_special_storages(self, adventurer_id);
            _unpack_adventurer_apply_stat_boost(self, adventurer_id, name_storage1, name_storage2)
                .stats
                .strength
        }
        fn get_base_dexterity(self: @ContractState, adventurer_id: u256) -> u8 {
            _unpack_adventurer(self, adventurer_id).stats.dexterity
        }
        fn get_dexterity(self: @ContractState, adventurer_id: u256) -> u8 {
            let (name_storage1, name_storage2) = _get_special_storages(self, adventurer_id);
            _unpack_adventurer_apply_stat_boost(self, adventurer_id, name_storage1, name_storage2)
                .stats
                .dexterity
        }
        fn get_base_vitality(self: @ContractState, adventurer_id: u256) -> u8 {
            _unpack_adventurer(self, adventurer_id).stats.vitality
        }
        fn get_vitality(self: @ContractState, adventurer_id: u256) -> u8 {
            let (name_storage1, name_storage2) = _get_special_storages(self, adventurer_id);
            _unpack_adventurer_apply_stat_boost(self, adventurer_id, name_storage1, name_storage2)
                .stats
                .vitality
        }
        fn get_base_intelligence(self: @ContractState, adventurer_id: u256) -> u8 {
            _unpack_adventurer(self, adventurer_id).stats.intelligence
        }
        fn get_intelligence(self: @ContractState, adventurer_id: u256) -> u8 {
            let (name_storage1, name_storage2) = _get_special_storages(self, adventurer_id);
            _unpack_adventurer_apply_stat_boost(self, adventurer_id, name_storage1, name_storage2)
                .stats
                .intelligence
        }
        fn get_base_wisdom(self: @ContractState, adventurer_id: u256) -> u8 {
            _unpack_adventurer(self, adventurer_id).stats.wisdom
        }
        fn get_wisdom(self: @ContractState, adventurer_id: u256) -> u8 {
            let (name_storage1, name_storage2) = _get_special_storages(self, adventurer_id);
            _unpack_adventurer_apply_stat_boost(self, adventurer_id, name_storage1, name_storage2)
                .stats
                .wisdom
        }
        fn get_base_charisma(self: @ContractState, adventurer_id: u256) -> u8 {
            _unpack_adventurer(self, adventurer_id).stats.charisma
        }
        fn get_charisma(self: @ContractState, adventurer_id: u256) -> u8 {
            let (name_storage1, name_storage2) = _get_special_storages(self, adventurer_id);
            _unpack_adventurer_apply_stat_boost(self, adventurer_id, name_storage1, name_storage2)
                .stats
                .charisma
        }
        fn get_special_storage(
            self: @ContractState, adventurer_id: u256, storage_index: u256
        ) -> ItemSpecialsStorage {
            Packing::unpack(self._loot_special_names.read((adventurer_id, storage_index)))
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
            _get_global_entropy(self)
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

        let mut week = Week {
            DAO: _to_ether(WEEK_2::DAO),
            INTERFACE: _to_ether(WEEK_2::INTERFACE),
            FIRST_PLACE: _to_ether(WEEK_2::FIRST_PLACE),
            SECOND_PLACE: _to_ether(WEEK_2::SECOND_PLACE),
            THIRD_PLACE: _to_ether(WEEK_2::THIRD_PLACE)
        };

        // if third place score is less than minimum score for payouts
        if (self._scores.read(3) < MINIMUM_SCORE_FOR_PAYOUTS) {
            // all rewards go to the DAO
            // the purpose of this is to let a decent set of top scores get set before payouts begin
            // without this, there would be an incentive to start and die immediately after contract is deployed
            // to capture the rewards from the launch hype
            // IERC20Dispatcher {
            //     contract_address: lords
            // }.transferFrom(caller, self._dao.read(), week.DAO);
            return;
        }

        // once reasonable scores have been set
        // we start doing payouts

        // for the first eight weeks, the majority go to the top three score
        week = Week {
            DAO: _to_ether(WEEK_4::DAO),
            INTERFACE: _to_ether(WEEK_4::INTERFACE),
            FIRST_PLACE: _to_ether(WEEK_4::FIRST_PLACE),
            SECOND_PLACE: _to_ether(WEEK_4::SECOND_PLACE),
            THIRD_PLACE: _to_ether(WEEK_4::THIRD_PLACE)
        };

        // after 8 weeks, the client providers start getting a share
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
        adventurer_meta: AdventurerMetadata,
        starting_stats: Stats,
    ) {
        // increment adventurer id (first adventurer is id 1)
        let adventurer_id = self._counter.read() + 1;

        // generate a new adventurer using the provided started weapon and current block number
        let mut new_adventurer: Adventurer = ImplAdventurer::new(
            starting_weapon, block_number, starting_stats
        );

        let adventurer_entropy = AdventurerUtils::generate_adventurer_entropy(
            block_number, adventurer_id
        );

        // set entropy on adventurer metadata
        let adventurer_meta = AdventurerMetadata {
            name: adventurer_meta.name,
            home_realm: adventurer_meta.home_realm,
            class: adventurer_meta.class,
            entropy: adventurer_entropy
        };

        // emit a StartGame event 
        __event__StartGame(
            ref self,
            AdventurerState { owner: caller, adventurer_id, adventurer: new_adventurer },
            adventurer_meta
        );

        // adventurer immediately gets ambushed by a starter beast
        _starter_beast_ambush(
            ref self, ref new_adventurer, adventurer_id, starting_weapon, adventurer_entropy
        );

        // pack and save new adventurer and metadata
        _pack_adventurer(ref self, adventurer_id, new_adventurer);
        _pack_adventurer_meta(ref self, adventurer_id, adventurer_meta);

        // increment the adventurer id counter
        self._counter.write(adventurer_id);

        // set caller as owner
        self._owner.write(adventurer_id, caller);
    // TODO: distribute mint fees
    }

    fn _starter_beast_ambush(
        ref self: ContractState,
        ref adventurer: Adventurer,
        adventurer_id: u256,
        starting_weapon: u8,
        adventurer_entropy: u128
    ) {
        let beast_seed: u128 = adventurer.get_beast_seed(adventurer_entropy);

        // generate starter beast which will have weak armor against the adventurers starter weapon
        let starter_beast = ImplBeast::get_starter_beast(
            ImplLoot::get_type(starting_weapon), beast_seed
        );

        // spoof a beast ambush by deducting health from the adventurer
        adventurer.deduct_health(STARTER_BEAST_ATTACK_DAMAGE);

        // and emitting an AmbushedByBeast event
        __event__AmbushedByBeast(
            ref self,
            AmbushedByBeast {
                adventurer_state: AdventurerState {
                    owner: get_caller_address(),
                    adventurer_id: adventurer_id,
                    adventurer: adventurer
                    }, seed: beast_seed, id: starter_beast.id, beast_specs: CombatSpec {
                    tier: starter_beast.combat_spec.tier,
                    item_type: starter_beast.combat_spec.item_type,
                    level: starter_beast.combat_spec.level,
                    specials: starter_beast.combat_spec.specials
                },
                damage: STARTER_BEAST_ATTACK_DAMAGE,
                critical_hit: false,
                location: ImplCombat::slot_to_u8(
                    AdventurerUtils::get_random_attack_location(adventurer_entropy)
                ),
            }
        );
    }

    // _explore is called by the adventurer to explore the world
    // @param self: ContractState
    // @param adventurer: Adventurer
    // @param adventurer_id: u256
    fn _explore(
        ref self: ContractState,
        ref adventurer: Adventurer,
        adventurer_id: u256,
        ref name_storage1: ItemSpecialsStorage,
        ref name_storage2: ItemSpecialsStorage,
        adventurer_entropy: u128,
        global_entropy: u128,
        till_beast: bool
    ) {
        // use entropy sources to generate random exploration
        let (main_explore_rnd, sub_explore_rnd) = _get_live_entropy(
            adventurer_entropy, global_entropy, adventurer
        );

        // get a random explore result
        let explore_result = AdventurerUtils::get_random_explore(main_explore_rnd);

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

                // if adventurer was ambushed
                if (was_ambushed) {
                    // get random attack location
                    let damage_slot = AdventurerUtils::get_random_attack_location(sub_explore_rnd);

                    // determine damage (adventurer dieing will be handled as part of the counter attack)
                    _beast_counter_attack(
                        ref self,
                        ref adventurer,
                        adventurer_id,
                        damage_slot,
                        beast,
                        beast_seed,
                        sub_explore_rnd,
                        true
                    );
                } else {
                    // Emit Discover Beast event
                    __event__DiscoveredBeast(
                        ref self,
                        DiscoveredBeast {
                            adventurer_state: AdventurerState {
                                owner: get_caller_address(),
                                adventurer_id: adventurer_id,
                                adventurer: adventurer
                                }, seed: beast_seed, id: beast.id, beast_specs: CombatSpec {
                                tier: beast.combat_spec.tier,
                                item_type: beast.combat_spec.item_type,
                                level: beast.combat_spec.level,
                                specials: beast.combat_spec.specials
                            }
                        }
                    );
                }

                // discovering a beast ends explore recursion
                return;
            },
            ExploreResult::Obstacle(()) => {
                _obstacle_encounter(
                    ref self,
                    ref adventurer,
                    adventurer_id,
                    ref name_storage1,
                    ref name_storage2,
                    sub_explore_rnd
                );
            },
            ExploreResult::Treasure(()) => {
                let (treasure_type, amount) = adventurer.discover_treasure(sub_explore_rnd);
                match treasure_type {
                    TreasureDiscovery::Gold(()) => {
                        // add gold to adventurer
                        adventurer.add_gold(amount);
                        // emit discovered gold event
                        __event__DiscoveredGold(ref self, adventurer_id, adventurer, amount);
                    },
                    TreasureDiscovery::XP(()) => {
                        // apply XP to adventurer
                        let (previous_level, new_level) = adventurer.increase_adventurer_xp(amount);
                        // emit discovered xp event
                        __event__DiscoveredXP(ref self, adventurer_id, adventurer, amount);
                        // check for level up
                        if (new_level > previous_level) {
                            // process level up
                            _emit_level_up_events(
                                ref self, ref adventurer, adventurer_id, previous_level, new_level
                            );

                            // leveling up ends explore recursion
                            return;
                        }
                    },
                    TreasureDiscovery::Health(()) => {
                        // if adventurer's health is already full
                        if (adventurer.has_full_health()) {
                            // play gets gold instead of health 
                            adventurer.add_gold(amount);
                            __event__DiscoveredGold(ref self, adventurer_id, adventurer, amount);
                        } else {
                            // otherwise add health
                            adventurer.increase_health(amount);
                            __event__DiscoveredHealth(ref self, adventurer_id, adventurer, amount);
                        }
                    }
                }
            }
        }

        // if adventurer elected to explore till they find a beast and they are still alive with no stat points
        if till_beast && adventurer.health > 0 && !(adventurer.stat_points_available > 0) {
            // Keep exploring
            _explore(
                ref self,
                ref adventurer,
                adventurer_id,
                ref name_storage1,
                ref name_storage2,
                adventurer_entropy,
                global_entropy,
                till_beast
            );
        }
        return;
    }

    fn _obstacle_encounter(
        ref self: ContractState,
        ref adventurer: Adventurer,
        adventurer_id: u256,
        ref name_storage1: ItemSpecialsStorage,
        ref name_storage2: ItemSpecialsStorage,
        entropy: u128
    ) {
        // get obstacle from obstacle lib and check if it was dodged
        let (obstacle, dodged) = ImplObstacle::obstacle_encounter(
            adventurer.get_level(), adventurer.stats.intelligence, entropy
        );

        // get a random attack location for the obstacle
        let damage_slot = AdventurerUtils::get_random_attack_location(entropy);
        // get adventurer armor at attack location
        let damage_location = ImplCombat::slot_to_u8(damage_slot);
        // get combat spec for the armor
        let armor_combat_spec = _get_combat_spec(
            @self, adventurer_id, adventurer.get_item_at_slot(damage_slot)
        );

        // get the xp reward for the obstacle
        let adventurer_xp_reward = obstacle.get_xp_reward();
        let item_xp_reward = adventurer_xp_reward * ITEM_XP_MULTIPLIER_OBSTACLES;
        // increase adventurer xp and check for level up
        let (previous_level, new_level) = adventurer.increase_adventurer_xp(adventurer_xp_reward);

        // calculate damage from the obstacle
        let damage_taken = ImplObstacle::get_damage(obstacle, armor_combat_spec, entropy);

        // if the obstalce was not dodged
        if (!dodged) {
            // adventurer takes this damage
            adventurer.deduct_health(damage_taken);
        }

        // grant XP to equipped items
        _grant_xp_to_equipped_items(
            ref self,
            adventurer_id,
            ref adventurer,
            ref name_storage1,
            ref name_storage2,
            item_xp_reward,
            entropy
        );

        // if the obstacle was not dodged
        if (!dodged) {
            // emit obstacle discover event
            // items only earn XP when damage is taken
            __event__HitByObstacle(
                ref self,
                HitByObstacle {
                    adventurer_state: AdventurerState {
                        owner: get_caller_address(),
                        adventurer_id: adventurer_id,
                        adventurer: adventurer
                    },
                    id: obstacle.id,
                    level: obstacle.combat_specs.level,
                    damage_taken: damage_taken,
                    damage_location: damage_location,
                    xp_earned_adventurer: adventurer_xp_reward,
                    xp_earned_items: item_xp_reward
                }
            );
        } else {
            // emit obstacle discover event
            // items do not earn XP from obstacles
            __event__DodgedObstacle(
                ref self,
                DodgedObstacle {
                    adventurer_state: AdventurerState {
                        owner: get_caller_address(),
                        adventurer_id: adventurer_id,
                        adventurer: adventurer
                    },
                    id: obstacle.id,
                    level: obstacle.combat_specs.level,
                    damage_taken: damage_taken,
                    damage_location: damage_location,
                    xp_earned_adventurer: adventurer_xp_reward,
                    xp_earned_items: item_xp_reward
                }
            );
        }

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
            // and return as game is now over
            return;
        }

        if (new_level > previous_level) {
            // if adventurer leveled up, process level up
            _emit_level_up_events(
                ref self, ref adventurer, adventurer_id, previous_level, new_level
            );
        }
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
    // @param special_names The ItemSpecials object storing the special names for the item.
    //
    // The function first checks if the item's new level is higher than its previous level. If it is, it generates a 'ItemLeveledUp' event.
    // The function then checks if a suffix was assigned to the item when it leveled up. If it was, it generates an 'ItemSpecialUnlocked' event.
    // Lastly, the function checks if a prefix was assigned to the item when it leveled up. If it was, it generates an 'ItemSpecialUnlocked' event.
    fn _handle_item_leveling_events(
        ref self: ContractState,
        adventurer: Adventurer,
        adventurer_id: u256,
        item_id: u8,
        previous_level: u8,
        new_level: u8,
        suffix_assigned: bool,
        prefixes_assigned: bool,
        special_names: ItemSpecials
    ) {
        // if the new level is higher than the previous level
        if (new_level > previous_level) {
            // generate greatness increased event
            __event_ItemLeveledUp(
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
                __event_ItemSpecialUnlocked(
                    ref self,
                    AdventurerState {
                        owner: get_caller_address(),
                        adventurer_id: adventurer_id,
                        adventurer: adventurer
                    },
                    item_id,
                    new_level,
                    special_names
                );
            }

            // if item prefixes were assigned
            if (prefixes_assigned) {
                // generate item prefix discovered event
                __event_ItemSpecialUnlocked(
                    ref self,
                    AdventurerState {
                        owner: get_caller_address(),
                        adventurer_id: adventurer_id,
                        adventurer: adventurer
                    },
                    item_id,
                    new_level,
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
    /// If an item is equipped, it calls `_add_xp_to_item` to apply the XP increase to the item and handle any resulting events.
    fn _grant_xp_to_equipped_items(
        ref self: ContractState,
        adventurer_id: u256,
        ref adventurer: Adventurer,
        ref name_storage1: ItemSpecialsStorage,
        ref name_storage2: ItemSpecialsStorage,
        value: u16,
        entropy: u128
    ) {
        // https://github.com/starkware-libs/cairo/issues/2942
        // internal::revoke_ap_tracking();
        let xp_increase = value * ITEM_XP_MULTIPLIER_BEASTS;

        // TODO LH: Consider including a modified bool on the 
        // ItemSpecialsStorage struct so that we can more easily
        // flag the storage as modified when it happens.
        let mut name_storage1_modified = false;
        let mut name_storage2_modified = false;

        // if weapon is equipped
        if adventurer.weapon.id > 0 {
            // grant xp and handle any resulting events
            let specials_assigned = _add_xp_to_item(
                ref self,
                adventurer_id,
                ref adventurer,
                ref adventurer.weapon,
                xp_increase,
                ref name_storage1,
                ref name_storage2,
                entropy
            );

            if (specials_assigned) {
                if (_get_storage_index(
                    @self, adventurer.weapon.metadata
                ) == LOOT_NAME_STORAGE_INDEX_1) {
                    name_storage1_modified = true;
                } else {
                    name_storage2_modified = true;
                }
            }
        }
        // if chest armor is equipped
        if adventurer.chest.id > 0 {
            // grant xp and handle any resulting events
            let specials_assigned = _add_xp_to_item(
                ref self,
                adventurer_id,
                ref adventurer,
                ref adventurer.chest,
                xp_increase,
                ref name_storage1,
                ref name_storage2,
                entropy
            );

            if (specials_assigned) {
                if (_get_storage_index(
                    @self, adventurer.chest.metadata
                ) == LOOT_NAME_STORAGE_INDEX_1) {
                    name_storage1_modified = true;
                } else {
                    name_storage2_modified = true;
                }
            }
        }
        // if head armor is equipped
        if adventurer.head.id > 0 {
            // grant xp and handle any resulting events
            let specials_assigned = _add_xp_to_item(
                ref self,
                adventurer_id,
                ref adventurer,
                ref adventurer.head,
                xp_increase,
                ref name_storage1,
                ref name_storage2,
                entropy
            );

            if (specials_assigned) {
                if (_get_storage_index(
                    @self, adventurer.head.metadata
                ) == LOOT_NAME_STORAGE_INDEX_1) {
                    name_storage1_modified = true;
                } else {
                    name_storage2_modified = true;
                }
            }
        }

        // if waist armor is equipped
        if adventurer.waist.id > 0 {
            // grant xp and handle any resulting events
            let specials_assigned = _add_xp_to_item(
                ref self,
                adventurer_id,
                ref adventurer,
                ref adventurer.waist,
                xp_increase,
                ref name_storage1,
                ref name_storage2,
                entropy
            );
            if (specials_assigned) {
                if (_get_storage_index(
                    @self, adventurer.waist.metadata
                ) == LOOT_NAME_STORAGE_INDEX_1) {
                    name_storage1_modified = true;
                } else {
                    name_storage2_modified = true;
                }
            }
        }
        // if foot armor is equipped
        if adventurer.foot.id > 0 {
            // grant xp and handle any resulting events
            let specials_assigned = _add_xp_to_item(
                ref self,
                adventurer_id,
                ref adventurer,
                ref adventurer.foot,
                xp_increase,
                ref name_storage1,
                ref name_storage2,
                entropy
            );
            if (specials_assigned) {
                if (_get_storage_index(
                    @self, adventurer.foot.metadata
                ) == LOOT_NAME_STORAGE_INDEX_1) {
                    name_storage1_modified = true;
                } else {
                    name_storage2_modified = true;
                }
            }
        }
        // if hand armor is equipped
        if adventurer.hand.id > 0 {
            // grant xp and handle any resulting events
            let specials_assigned = _add_xp_to_item(
                ref self,
                adventurer_id,
                ref adventurer,
                ref adventurer.hand,
                xp_increase,
                ref name_storage1,
                ref name_storage2,
                entropy
            );
            if (specials_assigned) {
                if (_get_storage_index(
                    @self, adventurer.hand.metadata
                ) == LOOT_NAME_STORAGE_INDEX_1) {
                    name_storage1_modified = true;
                } else {
                    name_storage2_modified = true;
                }
            }
        }
        // if neck armor is equipped
        if adventurer.neck.id > 0 {
            // grant xp and handle any resulting events
            let specials_assigned = _add_xp_to_item(
                ref self,
                adventurer_id,
                ref adventurer,
                ref adventurer.neck,
                xp_increase,
                ref name_storage1,
                ref name_storage2,
                entropy
            );
            if (specials_assigned) {
                if (_get_storage_index(
                    @self, adventurer.neck.metadata
                ) == LOOT_NAME_STORAGE_INDEX_1) {
                    name_storage1_modified = true;
                } else {
                    name_storage2_modified = true;
                }
            }
        }
        // if ring is equipped
        if adventurer.ring.id > 0 {
            // grant xp and handle any resulting events
            let specials_assigned = _add_xp_to_item(
                ref self,
                adventurer_id,
                ref adventurer,
                ref adventurer.ring,
                xp_increase,
                ref name_storage1,
                ref name_storage2,
                entropy
            );
            if (specials_assigned) {
                if (_get_storage_index(
                    @self, adventurer.ring.metadata
                ) == LOOT_NAME_STORAGE_INDEX_1) {
                    name_storage1_modified = true;
                } else {
                    name_storage2_modified = true;
                }
            }
        }
        if (name_storage1_modified) {
            _pack_loot_special_names_storage(
                ref self, adventurer_id, LOOT_NAME_STORAGE_INDEX_1, name_storage1
            );
        }
        if (name_storage2_modified) {
            _pack_loot_special_names_storage(
                ref self, adventurer_id, LOOT_NAME_STORAGE_INDEX_2, name_storage2
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
    // @param name_storage1 A reference to the ItemSpecialsStorage object. This object stores the special names for items that an adventurer may possess.
    // @param name_storage2 A reference to the ItemSpecialsStorage object. This object stores the special names for items that an adventurer may possess.
    // @param entropy An unsigned integer used for entropy generation. This is often derived from a source of randomness.
    //
    // The function first calculates the XP increase by applying a multiplier to the provided 'amount'.
    // It then checks the description index of the item. If the index matches with LOOT_NAME_STORAGE_INDEX_1, it uses name_storage1 for the item's special names; otherwise, it uses name_storage2.
    // It then calls `increase_item_xp` on the item to apply the XP increase and retrieve data about the item's original level, new level, and whether a suffix or prefix was assigned, and the item's special names.
    // Lastly, it calls `_handle_item_leveling_events` to handle any events resulting from the item leveling up.
    // @return A boolean indicating whether a suffix or prefix was assigned to the item when it leveled up.
    fn _add_xp_to_item(
        ref self: ContractState,
        adventurer_id: u256,
        ref adventurer: Adventurer,
        ref item: ItemPrimitive,
        xp_increase: u16,
        ref name_storage1: ItemSpecialsStorage,
        ref name_storage2: ItemSpecialsStorage,
        entropy: u128
    ) -> bool {
        // https://github.com/starkware-libs/cairo/issues/2942
        internal::revoke_ap_tracking();

        // TODO: Refactor this to reduce code duplication
        if (_get_storage_index(@self, item.metadata) == LOOT_NAME_STORAGE_INDEX_1) {
            let (previous_level, new_level, suffix_assigned, prefix_assigned, special_names) = item
                .increase_item_xp(xp_increase, ref name_storage1, entropy);

            if (previous_level != new_level && new_level == ITEM_MAX_GREATNESS) {
                // adventurer gets stat upgrade points when item reaches max greatness
                adventurer.add_stat_upgrade_points(MAX_GREATNESS_STAT_BONUS);

                // emit stat upgrades available event
                __event_UpgradeAvailable(
                    ref self,
                    AdventurerState {
                        owner: get_caller_address(),
                        adventurer_id: adventurer_id,
                        adventurer: adventurer
                    }
                );

                __event_NewItemsAvailable(
                    ref self,
                    adventurer_state: AdventurerState {
                        owner: get_caller_address(), adventurer_id, adventurer
                    },
                    items: _get_items_on_market(@self, adventurer_id, adventurer)
                );
            }

            // if item received a suffix as part of the level up
            if (suffix_assigned) {
                // adventurer gets a health boost from items that boost vitality
                adventurer
                    .increase_health(
                        AdventurerUtils::get_vitality_item_boost(special_names.special1).into()
                            * VITALITY_INSTANT_HEALTH_BONUS
                    );
            }

            _handle_item_leveling_events(
                ref self,
                adventurer,
                adventurer_id,
                item.id,
                previous_level,
                new_level,
                suffix_assigned,
                prefix_assigned,
                special_names
            );

            (suffix_assigned == true || prefix_assigned == true)
        } else {
            let (previous_level, new_level, suffix_assigned, prefix_assigned, special_names) = item
                .increase_item_xp(xp_increase, ref name_storage2, entropy);

            if (previous_level != new_level && new_level == ITEM_MAX_GREATNESS) {
                // adventurer gets stat upgrade points when item reaches max greatness
                adventurer.add_stat_upgrade_points(MAX_GREATNESS_STAT_BONUS);

                // emit stat upgrades available event
                __event_UpgradeAvailable(
                    ref self,
                    AdventurerState {
                        owner: get_caller_address(),
                        adventurer_id: adventurer_id,
                        adventurer: adventurer
                    }
                );

                __event_NewItemsAvailable(
                    ref self,
                    adventurer_state: AdventurerState {
                        owner: get_caller_address(), adventurer_id, adventurer
                    },
                    items: _get_items_on_market(@self, adventurer_id, adventurer)
                );
            }

            _handle_item_leveling_events(
                ref self,
                adventurer,
                adventurer_id,
                item.id,
                previous_level,
                new_level,
                suffix_assigned,
                prefix_assigned,
                special_names
            );

            (suffix_assigned == true || prefix_assigned == true)
        }
    }

    fn _get_beast(
        self: @ContractState, adventurer: Adventurer, adventurer_entropy: u128
    ) -> (Beast, u128) {
        // get beast seed based on adventurer state and adventurer entropy
        let beast_seed: u128 = adventurer.get_beast_seed(adventurer_entropy);

        // get and return beast using beast seed
        (
            ImplBeast::get_beast(
                adventurer.get_level(),
                ImplBeast::get_special_names(
                    adventurer.get_level(),
                    beast_seed,
                    NamePrefixLength.into(),
                    NameSuffixLength.into()
                ),
                beast_seed,
                ImplLoot::get_type(adventurer.weapon.id)
            ),
            beast_seed
        )
    }

    fn _attack(
        ref self: ContractState,
        ref adventurer: Adventurer,
        adventurer_id: u256,
        ref name_storage1: ItemSpecialsStorage,
        ref name_storage2: ItemSpecialsStorage,
        to_the_death: bool,
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
        let global_entropy: u128 = _get_global_entropy(@self).into();

        // When generating the beast, we need to ensure entropy remains fixed for the battle
        // for attacking however, we should change the entropy during battle so we use adventurer and beast health
        // to accomplish this
        let (attack_rnd_1, attack_rnd_2) = _get_live_entropy(
            adventurer_entropy, global_entropy, adventurer
        );

        // get the damage dealt to the beast
        let (damage_dealt, critical_hit) = beast
            .attack(
                _get_combat_spec(@self, adventurer_id, adventurer.weapon),
                adventurer.get_luck(),
                adventurer.stats.strength,
                attack_rnd_1
            );

        // if the amount of damage dealt to beast exceeds its health
        if (damage_dealt >= adventurer.beast_health) {
            // the beast is dead so set health to zero
            adventurer.beast_health = 0;

            // grant equipped items and adventurer xp for the encounter
            let xp_earned = beast.get_xp_reward();

            // grant adventurer gold reward. We use battle fixed entropy
            // to fix this result at the start of the battle, mitigating simulate-and-wait strategies
            let gold_reward = beast.get_gold_reward(beast_seed);
            adventurer.add_gold(gold_reward);

            // grant adventuer xp
            let (previous_level, new_level) = adventurer.increase_adventurer_xp(xp_earned);

            // grant equipped items xp
            _grant_xp_to_equipped_items(
                ref self,
                adventurer_id,
                ref adventurer,
                ref name_storage1,
                ref name_storage2,
                xp_earned,
                attack_rnd_2
            );

            // emit slayed beast event
            __event__SlayedBeast(
                ref self,
                SlayedBeast {
                    adventurer_state: AdventurerState {
                        owner: get_caller_address(),
                        adventurer_id: adventurer_id,
                        adventurer: adventurer
                        }, seed: beast_seed, id: beast.id, beast_specs: CombatSpec {
                        tier: beast.combat_spec.tier,
                        item_type: beast.combat_spec.item_type,
                        level: beast.combat_spec.level,
                        specials: beast.combat_spec.specials
                    },
                    damage_dealt: damage_dealt,
                    critical_hit: critical_hit,
                    xp_earned_adventurer: xp_earned,
                    xp_earned_items: xp_earned * ITEM_XP_MULTIPLIER_BEASTS,
                    gold_earned: gold_reward
                }
            );

            // if adventurers new level is greater than previous level
            if (new_level > previous_level) {
                _emit_level_up_events(
                    ref self, ref adventurer, adventurer_id, previous_level, new_level
                );
            }
        } else {
            // handle beast counter attack

            // deduct adventurer damage from beast health
            adventurer.beast_health -= damage_dealt;

            // emit attack beast event
            __event__AttackedBeast(
                ref self,
                AttackedBeast {
                    adventurer_state: AdventurerState {
                        owner: get_caller_address(),
                        adventurer_id: adventurer_id,
                        adventurer: adventurer
                        }, seed: beast_seed, id: beast.id, beast_specs: CombatSpec {
                        tier: beast.combat_spec.tier,
                        item_type: beast.combat_spec.item_type,
                        level: beast.combat_spec.level,
                        specials: beast.combat_spec.specials
                    },
                    damage: damage_dealt,
                    critical_hit: critical_hit,
                    location: ImplCombat::slot_to_u8(Slot::None(())),
                }
            );

            // starter beast ambushes the adventurer
            let adventurer_died = _beast_counter_attack(
                ref self,
                ref adventurer,
                adventurer_id,
                AdventurerUtils::get_random_attack_location(attack_rnd_1),
                beast,
                beast_seed,
                attack_rnd_2,
                false
            );

            // if the adventurer is still alive and fighting to the death
            if (adventurer_died == false && to_the_death) {
                // attack again
                _attack(
                    ref self,
                    ref adventurer,
                    adventurer_id,
                    ref name_storage1,
                    ref name_storage2,
                    true
                );
            }
        }
    }

    // TODO LH: Pull more functionality into this function
    // such as:
    // 1. getting beast
    // 2. determining attack location
    // those two should significantly reduce the amount of inputs into this function and
    // reduce code duplication in areas that call this function (they all need to fetch beast, etc)
    fn _beast_counter_attack(
        ref self: ContractState,
        ref adventurer: Adventurer,
        adventurer_id: u256,
        attack_location: Slot,
        beast: Beast,
        beast_seed: u128,
        entropy: u128,
        ambushed: bool
    ) -> bool {
        // https://github.com/starkware-libs/cairo/issues/2942
        // internal::revoke_ap_tracking();
        // generate a random attack slot for the beast and get the armor the adventurer has at that slot
        let armor = adventurer.get_item_at_slot(attack_location);

        // convert loot item to combat spec so it can be used with combat library
        let armor_combat_spec = _get_combat_spec(@self, adventurer_id, armor);

        // process beast counter attack
        let (damage, critical_hit) = beast.counter_attack(armor_combat_spec, entropy);

        // deduct the damage dealt
        adventurer.deduct_health(damage);

        // if counter attack was result of an ambush
        // emit ambushed by beast event
        if (ambushed) {
            // emit attack by beast event
            __event__AmbushedByBeast(
                ref self,
                AmbushedByBeast {
                    adventurer_state: AdventurerState {
                        owner: get_caller_address(),
                        adventurer_id: adventurer_id,
                        adventurer: adventurer
                        }, seed: beast_seed, id: beast.id, beast_specs: CombatSpec {
                        tier: beast.combat_spec.tier,
                        item_type: beast.combat_spec.item_type,
                        level: beast.combat_spec.level,
                        specials: beast.combat_spec.specials
                    },
                    damage: damage,
                    critical_hit: critical_hit,
                    location: ImplCombat::slot_to_u8(attack_location),
                }
            );
        } else {
            // else emit attacked by beast event
            __event__AttackedByBeast(
                ref self,
                AttackedByBeast {
                    adventurer_state: AdventurerState {
                        owner: get_caller_address(),
                        adventurer_id: adventurer_id,
                        adventurer: adventurer
                        }, seed: beast_seed, id: beast.id, beast_specs: CombatSpec {
                        tier: beast.combat_spec.tier,
                        item_type: beast.combat_spec.item_type,
                        level: beast.combat_spec.level,
                        specials: beast.combat_spec.specials
                    },
                    damage: damage,
                    critical_hit: critical_hit,
                    location: ImplCombat::slot_to_u8(attack_location),
                }
            );
        }

        // the adventurer is dead
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
            // return true to indicate adventurer died
            true
        // TODO: Check for Top score
        } else {
            // return false to indicate adventurer is still alive
            false
        }
    }

    fn _flee(
        ref self: ContractState,
        ref adventurer: Adventurer,
        adventurer_id: u256,
        adventurer_entropy: u128,
        global_entropy: u128,
        beast_seed: u128,
        beast: Beast,
        to_the_death: bool
    ) {
        let (flee_entropy, ambush_entropy) = _get_live_entropy(
            adventurer_entropy, global_entropy, adventurer
        );

        let fled = ImplBeast::attempt_flee(
            adventurer.get_level(), adventurer.stats.dexterity, flee_entropy
        );

        // let mut damage_taken = 0;
        // let mut attack_location = 0;
        if (fled) {
            // set beast health to zero to denote adventurer is no longer in battle
            adventurer.beast_health = 0;

            // each adventurer xp by one to prevent entropy loops resulting
            // from the adventurer state being same
            let (previous_level, new_level) = adventurer.increase_adventurer_xp(1);

            // emit flee attempt event
            __event__FleeSucceeded(
                ref self,
                FleeSucceeded {
                    adventurer_state: AdventurerState {
                        owner: get_caller_address(),
                        adventurer_id: adventurer_id,
                        adventurer: adventurer
                    }, seed: beast_seed, id: beast.id, beast_specs: beast.combat_spec
                }
            );

            // check for adventurer level up
            if (new_level > previous_level) {
                _emit_level_up_events(
                    ref self, ref adventurer, adventurer_id, previous_level, new_level
                );
            }
        } else {
            // // emit flee attempt event
            __event__FleeFailed(
                ref self,
                FleeFailed {
                    adventurer_state: AdventurerState {
                        owner: get_caller_address(),
                        adventurer_id: adventurer_id,
                        adventurer: adventurer
                    }, seed: beast_seed, id: beast.id, beast_specs: beast.combat_spec
                }
            );

            // if flee attempt was unsuccessful the beast counter attacks
            // adventurer death will be handled as part of counter attack
            let attack_slot = AdventurerUtils::get_random_attack_location(ambush_entropy);
            let attack_location = ImplCombat::slot_to_u8(attack_slot);
            _beast_counter_attack(
                ref self,
                ref adventurer,
                adventurer_id,
                attack_slot,
                beast,
                beast_seed,
                ambush_entropy,
                false
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
        // TODO: This is the cleaner solution to flee till death
        // but current version of Cairo is unhappy with this
        // so doing a top level loop instead
        // else if (to_the_death) {
        //     // call _flee again
        //     _flee(
        //         ref self,
        //         ref adventurer,
        //         adventurer_id,
        //         adventurer_entropy,
        //         global_entropy,
        //         beast_seed,
        //         beast,
        //         true
        //     );
        // }
        }
    }

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
        adventurer_id: u256,
        ref bag: Bag,
        name_storage1: ItemSpecialsStorage,
        name_storage2: ItemSpecialsStorage,
        items_to_equip: Array<u8>,
        is_newly_purchased: bool
    ) {
        // remove previous stat boosts
        adventurer.remove_stat_boosts(name_storage1, name_storage2);

        // mutable array from returning items that were unequipped as a result of equipping the items
        let mut unequipped_items = ArrayTrait::<u8>::new();

        // get a clone of our items to equip to keep ownership for event
        let equipped_items = items_to_equip.clone();

        // for we item we need to equip
        let mut i: u32 = 0;
        loop {
            if i >= items_to_equip.len() {
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
                unequipped_item_id =
                    _equip_item(ref adventurer, ref bag, ImplItemPrimitive::new(item_id));
            } else {
                // otherwise item is being equipped from bag
                // so remove it from bag, equip it, and record if we need to unequip an item
                unequipped_item_id = _equip_item(ref adventurer, ref bag, bag.remove_item(item_id));
            }

            // if an item was unequipped
            if unequipped_item_id > 0 {
                // add it to our return array so we can emit these in events
                unequipped_items.append(unequipped_item_id);
            }

            i += 1;
        };

        // add stat boosts for newly equipped items
        adventurer.add_stat_boosts(name_storage1, name_storage2);

        // and emit equipped item event
        __event_EquippedItems(
            ref self,
            AdventurerStateWithBag {
                adventurer_state: AdventurerState {
                    owner: get_caller_address(),
                    adventurer_id: adventurer_id,
                    adventurer: adventurer
                }, bag: bag
            },
            equipped_items,
            unequipped_items,
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
    fn _drop_items(
        ref self: ContractState,
        ref adventurer: Adventurer,
        ref bag: Bag,
        adventurer_id: u256,
        items: Array<u8>,
    ) {
        // for each item
        let mut i: u32 = 0;
        loop {
            if i >= items.len() {
                break ();
            }

            // get and drop item
            let item_id = *items.at(i);
            if adventurer.is_equipped(item_id) {
                adventurer.drop_item(item_id);
            } else if bag.contains(item_id) {
                bag.remove_item(item_id);
            } else {
                panic_with_felt252('Item not owned by adventurer');
            }

            i += 1;
        };
    }

    // @dev Function to facilitate the purchase of multiple items.
    // @param adventurer The Adventurer struct instance representing the adventurer buying items.
    // @param bag The Bag struct instance representing the adventurer's current bag of items.
    // @param adventurer_id The unique identifier for the adventurer.
    // @param adventurer_entropy The entropy of the adventurer used for randomness.
    // @param items The Array of ItemPurchase instances representing items to be purchased.
    fn _buy_items(
        ref self: ContractState,
        ref adventurer: Adventurer,
        original_adventurer: Adventurer,
        ref bag: Bag,
        name_storage1: ItemSpecialsStorage,
        name_storage2: ItemSpecialsStorage,
        adventurer_id: u256,
        items: Array<ItemPurchase>,
    ) {
        // get adventurer entropy
        let adventurer_entropy: u128 = _adventurer_meta_unpacked(@self, adventurer_id)
            .entropy
            .into();

        let mut purchases = ArrayTrait::<LootWithPrice>::new();

        // mutable array for returning items that need to be equipped as part of this purchase
        let mut unequipped_items = ArrayTrait::<u8>::new();
        let mut items_to_equip = ArrayTrait::<u8>::new();

        // for each item being purchased
        let mut i: u32 = 0;
        loop {
            if i >= items.len() {
                break ();
            }

            // get the item
            let item = *items.at(i);

            // buy it and record receipt
            purchases
                .append(
                    _buy_item(
                        ref self,
                        ref adventurer,
                        original_adventurer,
                        ref bag,
                        adventurer_id,
                        adventurer_entropy,
                        item.item_id
                    )
                );

            // if item is being equipped as part of the purchase 
            if item.equip {
                // add it to our array of items to equip
                items_to_equip.append(item.item_id);
            } else {
                // if it's not being equipped, just add it to bag
                bag.add_new_item(adventurer, item.item_id)
            }

            // increment counter
            i += 1;
        };

        // emit purchased items event
        __event_PurchasedItems(
            ref self,
            PurchasedItems {
                adventurer_state_with_bag: AdventurerStateWithBag {
                    adventurer_state: AdventurerState {
                        owner: get_caller_address(),
                        adventurer_id: adventurer_id,
                        adventurer: adventurer
                    }, bag: bag
                }, purchases: purchases
            }
        );

        // if we have items to equip as part of the purchase
        if (items_to_equip.len() > 0) {
            // equip them and record the items that were unequipped
            _equip_items(
                ref self,
                ref adventurer,
                adventurer_id,
                ref bag,
                name_storage1,
                name_storage2,
                items_to_equip.clone(),
                true
            );
        }
    }

    fn _buy_potions(
        ref self: ContractState, ref adventurer: Adventurer, adventurer_id: u256, amount: u8
    ) {
        // otherwise process potions purchase
        let cost_of_potions = adventurer.charisma_adjusted_potion_price() * amount.into();
        let health_from_potions = POTION_HEALTH_AMOUNT * amount.into();

        // assert adventurer has enough gold to buy the potions
        _assert_has_enough_gold(adventurer, cost_of_potions);

        // assert adventurer is not buying more health than they can use
        _assert_not_buying_excess_health(adventurer, health_from_potions);

        // calculate cost of potion based on the adventurer's level
        adventurer.deduct_gold(cost_of_potions);

        // add health to adventurer
        adventurer.increase_health(health_from_potions);

        // emit purchased potions event
        __event_PurchasedPotions(
            ref self,
            PurchasedPotions {
                adventurer_state: AdventurerState {
                    owner: get_caller_address(),
                    adventurer_id: adventurer_id,
                    adventurer: adventurer
                }, quantity: amount, cost: cost_of_potions, health: health_from_potions
            }
        );
    }

    fn _upgrade_stats(
        self: @ContractState,
        ref adventurer: Adventurer,
        strength_increase: u8,
        dexterity_increase: u8,
        vitality_increase: u8,
        intelligence_increase: u8,
        wisdom_increase: u8,
        charisma_increase: u8
    ) {
        // assert all available stats are being used
        let num_stat_upgrades = strength_increase
            + dexterity_increase
            + vitality_increase
            + intelligence_increase
            + wisdom_increase
            + charisma_increase;

        _assert_stat_balance(adventurer, num_stat_upgrades.into());

        if strength_increase > 0 {
            adventurer.increase_strength(strength_increase);
        }

        if dexterity_increase > 0 {
            adventurer.increase_dexterity(dexterity_increase);
        }
        if vitality_increase > 0 {
            adventurer.increase_vitality(vitality_increase);
            adventurer.increase_health(VITALITY_INSTANT_HEALTH_BONUS);
        }
        if intelligence_increase > 0 {
            adventurer.increase_intelligence(intelligence_increase);
        }
        if wisdom_increase > 0 {
            adventurer.increase_wisdom(wisdom_increase);
        }
        if charisma_increase > 0 {
            adventurer.increase_charisma(charisma_increase);
        }
        adventurer.stat_points_available = 0;
    }

    // @dev This function allows the adventurer to purchase an item from the market.
    // @notice The item price is adjusted based on the adventurer's charisma. The function also manages the adventurer's inventory based on whether they equip the item or not. It emits an event whenever an item is purchased.
    // @param adventurer The adventurer buying the item. The function modifies the adventurer's gold and equipment.
    // @param bag The bag of the adventurer. The function may add items to the bag if the adventurer unequips an item or opts not to equip a purchased item.
    // @param adventurer_id The ID of the adventurer.
    // @param item_id The ID of the item to be purchased.
    // @param equip A boolean indicating if the adventurer should equip the item immediately upon purchasing it. If it is set to false, the item will be added to the adventurer's bag.
    fn _buy_item(
        ref self: ContractState,
        ref adventurer: Adventurer,
        original_adventurer: Adventurer,
        ref bag: Bag,
        adventurer_id: u256,
        adventurer_entropy: u128,
        item_id: u8
    ) -> LootWithPrice {
        // check item is available on market
        _assert_item_is_available(original_adventurer, adventurer_id, adventurer_entropy, item_id);

        // assert adventurer does not already own the item
        _assert_item_not_owned(adventurer, bag, item_id);

        // get item price
        let base_item_price = ImplMarket::get_price(ImplLoot::get_tier(item_id));

        // get item price after charisma discount
        let charisma_adjusted_price = adventurer.charisma_adjusted_item_price(base_item_price);

        // check adventurer has enough gold
        _assert_has_enough_gold(adventurer, charisma_adjusted_price);

        // deduct charisma adjusted cost of item from adventurer's gold balance
        adventurer.deduct_gold(charisma_adjusted_price);

        // return item with price
        LootWithPrice { item: ImplLoot::get_item(item_id), price: charisma_adjusted_price }
    }

    // _get_live_entropy generates entropy for exploration
    // @param adventurer_entropy - entropy from adventurer
    // @param global_entropy - entropy from game
    // @param adventurer - the adventurer
    // @return u128 - entropy to be used for exploration
    // TODOs:
    // 1. Move this to Adventurer lib
    fn _get_live_entropy(
        adventurer_entropy: u128, global_entropy: u128, adventurer: Adventurer
    ) -> (u128, u128) {
        let mut hash_span = ArrayTrait::<felt252>::new();
        hash_span.append(adventurer.xp.into());
        hash_span.append(adventurer.gold.into());
        hash_span.append(adventurer.health.into());
        hash_span.append(adventurer_entropy.into());
        hash_span.append(adventurer.last_action.into());
        hash_span.append(global_entropy.into());

        let poseidon = poseidon_hash_span(hash_span.span());
        let (d, r) = rshift_split(poseidon.into(), U128_MAX.into());
        return (r.try_into().unwrap(), d.try_into().unwrap());
    }

    // ------------------------------------------ //
    // ------------ Helper Functions ------------ //
    // ------------------------------------------ //

    // @dev Unpacks an adventurer's data, applies stat boosts, and returns the modified adventurer.
    // @param adventurer_id The ID of the adventurer to be modified.
    // @param name_storage1 The storage for the first set of item specials.
    // @param name_storage2 The storage for the second set of item specials.
    // @return The modified adventurer with applied stat boosts.
    fn _unpack_adventurer_apply_stat_boost(
        self: @ContractState,
        adventurer_id: u256,
        name_storage1: ItemSpecialsStorage,
        name_storage2: ItemSpecialsStorage
    ) -> Adventurer {
        // unpack adventurer
        let mut adventurer: Adventurer = Packing::unpack(self._adventurer.read(adventurer_id));
        // apply stat boosts to adventurer
        adventurer.add_stat_boosts(name_storage1, name_storage2);
        // return adventurer
        adventurer
    }

    // @dev Packs and saves an adventurer after removing stat boosts.
    // @param adventurer_id The ID of the adventurer to be modified.
    // @param adventurer The adventurer to be modified.
    // @param name_storage1 The storage for the first set of item specials.
    // @param name_storage2 The storage for the second set of item specials.
    fn _pack_adventurer_remove_stat_boost(
        ref self: ContractState,
        adventurer_id: u256,
        ref adventurer: Adventurer,
        name_storage1: ItemSpecialsStorage,
        name_storage2: ItemSpecialsStorage
    ) {
        // remove stat boosts
        adventurer.remove_stat_boosts(name_storage1, name_storage2);

        // pack and save
        self._adventurer.write(adventurer_id, adventurer.pack());
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
    fn _emit_level_up_events(
        ref self: ContractState,
        ref adventurer: Adventurer,
        adventurer_id: u256,
        previous_level: u8,
        new_level: u8,
    ) {
        let adventurer_state = AdventurerState {
            owner: get_caller_address(), adventurer_id: adventurer_id, adventurer: adventurer
        };

        // emit level up event
        __event_AdventurerLeveledUp(
            ref self,
            adventurer_state: adventurer_state,
            previous_level: previous_level,
            new_level: new_level
        );

        // emit stat upgrades available event
        __event_UpgradeAvailable(ref self, adventurer_state);

        // emit new items availble with available items
        __event_NewItemsAvailable(
            ref self,
            adventurer_state: adventurer_state,
            items: _get_items_on_market(@self, adventurer_id, adventurer)
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
        loot_special_names_storage: ItemSpecialsStorage,
    ) {
        self
            ._loot_special_names
            .write((adventurer_id, storage_index), loot_special_names_storage.pack());
    }

    fn _get_special_storages(
        self: @ContractState, adventurer_id: u256
    ) -> (ItemSpecialsStorage, ItemSpecialsStorage) {
        (
            _loot_special_names_storage_unpacked(self, adventurer_id, LOOT_NAME_STORAGE_INDEX_1),
            _loot_special_names_storage_unpacked(self, adventurer_id, LOOT_NAME_STORAGE_INDEX_2),
        )
    }

    fn _loot_special_names_storage_unpacked(
        self: @ContractState, adventurer_id: u256, storage_index: u256
    ) -> ItemSpecialsStorage {
        Packing::unpack(self._loot_special_names.read((adventurer_id, storage_index)))
    }

    fn _get_special_names(
        self: @ContractState, adventurer_id: u256, item: ItemPrimitive
    ) -> ItemSpecials {
        ImplItemSpecials::get_specials(
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
    fn _assert_in_battle(beast_health: u16) {
        assert(beast_health > 0, messages::NOT_IN_BATTLE);
    }
    fn _assert_dexterity_not_zero(dexterity: u8) {
        assert(dexterity > 0, messages::ZERO_DEXTERITY);
    }
    fn _assert_not_in_battle(beast_health: u16) {
        assert(beast_health == 0, messages::ACTION_NOT_ALLOWED_DURING_BATTLE);
    }
    fn _assert_market_is_open(stat_points_available: u8) {
        assert(stat_points_available > 0, messages::MARKET_CLOSED);
    }
    fn _assert_item_not_owned(adventurer: Adventurer, bag: Bag, item_id: u8) {
        // assert item is not equipped and not in bag
        assert(
            adventurer.is_equipped(item_id) == false && bag.contains(item_id) == false,
            messages::ITEM_ALREADY_OWNED
        );
    }
    fn _assert_item_is_available(
        adventurer: Adventurer, adventurer_id: u256, adventurer_entropy: u128, item_id: u8
    ) {
        let (seeds, offsets) = adventurer.get_market_seeds(adventurer_id, adventurer_entropy);
        assert(
            ImplMarket::is_item_available(seeds, offsets, item_id) == true,
            messages::ITEM_DOES_NOT_EXIST
        );
    }
    fn _assert_not_starter_beast(adventurer_level: u8) {
        assert(adventurer_level > 1, messages::CANT_FLEE_STARTER_BEAST);
    }
    fn _assert_no_stat_upgrades_available(stat_points_available: u8) {
        assert(stat_points_available == 0, messages::STAT_UPGRADES_AVAILABLE);
    }
    fn _assert_not_dead(health: u16) {
        assert(health > 0, messages::DEAD_ADVENTURER);
    }
    fn _assert_valid_starter_weapon(starting_weapon: u8) {
        assert(
            ImplLoot::is_starting_weapon(starting_weapon) == true, messages::INVALID_STARTING_WEAPON
        );
    }
    fn _assert_starting_stat_count(starting_stats: Stats) {
        let total_stats = starting_stats.strength
            + starting_stats.dexterity
            + starting_stats.vitality
            + starting_stats.intelligence
            + starting_stats.wisdom
            + starting_stats.charisma;

        assert(total_stats == STARTING_STATS, messages::WRONG_STARTING_STATS);
    }
    fn _assert_fatally_idle(adventurer: Adventurer) {
        let idle_blocks = adventurer
            .get_idle_blocks(starknet::get_block_info().unbox().block_number);

        assert(idle_blocks >= IDLE_DEATH_PENALTY_BLOCKS, messages::ADVENTURER_NOT_IDLE);
    }
    fn _assert_has_enough_gold(adventurer: Adventurer, cost: u16) {
        assert(adventurer.gold >= cost, messages::NOT_ENOUGH_GOLD);
    }
    fn _assert_not_buying_excess_health(adventurer: Adventurer, purchased_health: u16) {
        let adventurer_health_after_potions = adventurer.health + purchased_health;
        // assert adventurer is not buying more health than needed
        assert(
            adventurer_health_after_potions < adventurer.get_max_health() + POTION_HEALTH_AMOUNT,
            messages::HEALTH_FULL
        );
    }
    fn _assert_stat_balance(adventurer: Adventurer, stat_count: u32) {
        // if adventurer has less than the number of stats they are trying to upgrade
        if adventurer.stat_points_available.into() < stat_count {
            // panic with insufficient stat upgrades message
            panic_with_felt252(messages::INSUFFICIENT_STAT_UPGRADES);
        } else if adventurer.stat_points_available.into() > stat_count {
            // if the adventurer has more than the number of stats they are trying to upgrade
            // panic with must use all stats message
            panic_with_felt252(messages::MUST_USE_ALL_STATS);
        }
    }
    fn _idle_longer_than_penalty_threshold(adventurer: Adventurer) -> (bool, u16) {
        let idle_blocks = adventurer
            .get_idle_blocks(starknet::get_block_info().unbox().block_number);

        return (idle_blocks >= IDLE_PENALTY_THRESHOLD_BLOCKS, idle_blocks);
    }
    fn _get_idle_penalty(adventurer: Adventurer) -> u16 {
        // TODO: Get worst case scenario obstacle
        // 1. Identify adventurers weakest armor
        // 2. Get T1 obstacle that is strong against that armor
        // 3. Level will be maximum allowed by combat system for that adventurers Level

        // for now just return fixed 80 damage
        return 80;
    }

    fn _apply_idle_penalty(
        ref self: ContractState, adventurer_id: u256, ref adventurer: Adventurer, num_blocks: u16
    ) {
        // get idle penalty
        let idle_penalty_damage = _get_idle_penalty(adventurer);

        // deduct it from adventurer's health
        adventurer.deduct_health(idle_penalty_damage);

        // emit event
        __event_IdleDamagePenalty(
            ref self,
            AdventurerState {
                owner: self._owner.read(adventurer_id),
                adventurer_id: adventurer_id,
                adventurer: adventurer
            },
            num_blocks,
            idle_penalty_damage
        );

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

    fn _lords_address(self: @ContractState) -> ContractAddress {
        self._lords.read()
    }

    fn _dao_address(self: @ContractState) -> ContractAddress {
        self._dao.read()
    }

    fn _get_items_on_market(
        self: @ContractState, adventurer_id: u256, adventurer: Adventurer
    ) -> Array<LootWithPrice> {
        let adventurer_entropy: u128 = _adventurer_meta_unpacked(self, adventurer_id)
            .entropy
            .into();

        let (seeds, offsets) = adventurer.get_market_seeds(adventurer_id, adventurer_entropy);
        ImplMarket::get_all_items_with_price(seeds, offsets)
    }

    fn _get_market_items_by_slot(
        self: @ContractState, adventurer_id: u256, adventurer: Adventurer, slot: Slot
    ) -> Array<u8> {
        let adventurer_entropy: u128 = _adventurer_meta_unpacked(self, adventurer_id)
            .entropy
            .into();

        let (seeds, offsets) = adventurer.get_market_seeds(adventurer_id, adventurer_entropy);
        ImplMarket::get_items_by_slot(seeds, offsets, slot)
    }

    fn _get_market_items_by_tier(
        self: @ContractState, adventurer_id: u256, adventurer: Adventurer, tier: Tier
    ) -> Array<u8> {
        let adventurer_entropy: u128 = _adventurer_meta_unpacked(self, adventurer_id)
            .entropy
            .into();

        let (seeds, offsets) = adventurer.get_market_seeds(adventurer_id, adventurer_entropy);

        ImplMarket::get_items_by_tier(seeds, offsets, tier)
    }

    fn _get_potion_price(self: @ContractState, adventurer_id: u256) -> u16 {
        let (name_storage1, name_storage2) = _get_special_storages(self, adventurer_id);

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
                level: item.get_greatness().into(),
                specials: SpecialPowers {
                    special1: 0, special2: 0, special3: 0
                }
            };
        } else {
            // if it's above 15, fetch the special names
            let item_details = ImplItemSpecials::get_specials(
                _loot_special_names_storage_unpacked(
                    self, adventurer_id, _get_storage_index(self, item.metadata)
                ),
                item
            );
            // return combat spec of item
            return CombatSpec {
                tier: ImplLoot::get_tier(item.id),
                item_type: ImplLoot::get_type(item.id),
                level: item.get_greatness().into(),
                specials: SpecialPowers {
                    special1: item_details.special1,
                    special2: item_details.special2,
                    special3: item_details.special3
                }
            };
        }
    }

    fn _set_entropy(ref self: ContractState) {
        // let hash: felt252  = starknet::get_tx_info().unbox().transaction_hash.into();

        let blocknumber: u64 = starknet::get_block_info().unbox().block_number.into();
        let timestamp: u64 = starknet::get_block_info().unbox().block_timestamp.into();

        assert(
            blocknumber >= (self._last_global_entropy_block.read().try_into().unwrap()
                + MIN_BLOCKS_FOR_GAME_ENTROPY_CHANGE.into()),
            messages::BLOCK_NUMBER_ERROR
        );

        let mut hash_span = ArrayTrait::<felt252>::new();
        hash_span.append(blocknumber.into());
        hash_span.append(timestamp.into());

        let poseidon: felt252 = poseidon_hash_span(hash_span.span()).into();
        let (d, r) = rshift_split(poseidon.into(), U64_MAX.into());

        self._global_entropy.write(r.try_into().unwrap());
        self._last_global_entropy_block.write(blocknumber.into());
    }

    fn _get_global_entropy(self: @ContractState) -> u64 {
        self._global_entropy.read()
    }

    fn _get_adventurer_entropy(self: @ContractState, adventurer_id: u256) -> u128 {
        _adventurer_meta_unpacked(self, adventurer_id).entropy.into()
    }

    // @notice _get_adventurer_and_global_entropy returns the adventurer entropy and global entropy
    // @param self - read-only reference to the contract state
    // @param adventurer_id - the id of the adventurer
    // @return (u128, u64) - adventurer entropy and global entropy
    fn _get_adventurer_and_global_entropy(
        self: @ContractState, adventurer_id: u256
    ) -> (u128, u64) {
        (_get_adventurer_entropy(self, adventurer_id), _get_global_entropy(self))
    }

    fn _adventurer_meta_unpacked(self: @ContractState, adventurer_id: u256) -> AdventurerMetadata {
        Packing::unpack(self._adventurer_meta.read(adventurer_id))
    }

    fn _get_score_for_adventurer(self: @ContractState, adventurer_id: u256) -> u256 {
        self._scores.read(adventurer_id)
    }

    fn _is_top_score(self: @ContractState, score: u16) -> bool {
        if score.into() > self._scores.read(3) {
            return true;
        }
        false
    }


    // sets the scoreboard
    // we set the adventurer id in the scoreboard as we already store the owners address
    fn _update_leaderboard(ref self: ContractState, adventurer_id: u256, score: u16) {
        let second_place = self._scoreboard.read(2);
        let first_place = self._scoreboard.read(1);

        let adventurer = _unpack_adventurer(@self, adventurer_id);
        let adventurer_state = AdventurerState {
            owner: self._owner.read(adventurer_id),
            adventurer_id: adventurer_id,
            adventurer: adventurer
        };

        if score.into() > self._scores.read(1) {
            __event_NewHighScore(ref self, adventurer_state, 1);
            self._scoreboard.write(3, second_place);
            self._scoreboard.write(2, first_place);
            self._scoreboard.write(1, adventurer_id);
            self._scores.write(3, self._scores.read(2));
            self._scores.write(2, self._scores.read(1));
            self._scores.write(1, score.into());
        } else if score.into() > self._scores.read(2) {
            __event_NewHighScore(ref self, adventurer_state, 2);
            self._scoreboard.write(3, second_place);
            self._scoreboard.write(2, adventurer_id);
            self._scores.write(3, self._scores.read(2));
            self._scores.write(2, score.into());
        } else if score.into() > self._scores.read(3) {
            __event_NewHighScore(ref self, adventurer_state, 3);
            self._scoreboard.write(3, adventurer_id);
            self._scores.write(3, score.into());
        }
    }


    // EVENTS ------------------------------------ //

    #[derive(Copy, Drop, Serde, starknet::Event)]
    struct AdventurerState {
        owner: ContractAddress,
        adventurer_id: u256,
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

    #[derive(Drop, starknet::Event)]
    struct DiscoveredHealth {
        adventurer_state: AdventurerState,
        health_amount: u16
    }

    #[derive(Drop, starknet::Event)]
    struct DiscoveredGold {
        adventurer_state: AdventurerState,
        gold_amount: u16
    }

    #[derive(Drop, starknet::Event)]
    struct DiscoveredXP {
        adventurer_state: AdventurerState,
        xp_amount: u16
    }

    #[derive(Drop, starknet::Event)]
    struct DodgedObstacle {
        adventurer_state: AdventurerState,
        id: u8,
        level: u16,
        damage_taken: u16,
        damage_location: u8,
        xp_earned_adventurer: u16,
        xp_earned_items: u16,
    }

    #[derive(Drop, starknet::Event)]
    struct HitByObstacle {
        adventurer_state: AdventurerState,
        id: u8,
        level: u16,
        damage_taken: u16,
        damage_location: u8,
        xp_earned_adventurer: u16,
        xp_earned_items: u16,
    }

    #[derive(Drop, starknet::Event)]
    struct DiscoveredBeast {
        adventurer_state: AdventurerState,
        seed: u128,
        id: u8,
        beast_specs: CombatSpec,
    }

    #[derive(Drop, starknet::Event)]
    struct AmbushedByBeast {
        adventurer_state: AdventurerState,
        seed: u128,
        id: u8,
        beast_specs: CombatSpec,
        damage: u16,
        critical_hit: bool,
        location: u8,
    }

    #[derive(Drop, starknet::Event)]
    struct AttackedBeast {
        adventurer_state: AdventurerState,
        seed: u128,
        id: u8,
        beast_specs: CombatSpec,
        damage: u16,
        critical_hit: bool,
        location: u8,
    }

    #[derive(Drop, starknet::Event)]
    struct AttackedByBeast {
        adventurer_state: AdventurerState,
        seed: u128,
        id: u8,
        beast_specs: CombatSpec,
        damage: u16,
        critical_hit: bool,
        location: u8,
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

    #[derive(Drop, starknet::Event)]
    struct FleeFailed {
        adventurer_state: AdventurerState,
        seed: u128,
        id: u8,
        beast_specs: CombatSpec,
    }

    #[derive(Drop, starknet::Event)]
    struct FleeSucceeded {
        adventurer_state: AdventurerState,
        seed: u128,
        id: u8,
        beast_specs: CombatSpec,
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

    #[derive(Drop, starknet::Event)]
    struct ItemLeveledUp {
        adventurer_state: AdventurerState,
        item_id: u8,
        previous_level: u8,
        new_level: u8,
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

    #[derive(Drop, starknet::Event)]
    struct IdleDamagePenalty {
        adventurer_state: AdventurerState,
        idle_blocks: u16,
        damage_taken: u16
    }

    #[derive(Drop, starknet::Event)]
    struct UpgradeAvailable {
        adventurer_state: AdventurerState, 
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

    fn __event_AdventurerUpgraded(
        ref self: ContractState, adventurer_upgraded_event: AdventurerUpgraded
    ) {
        self.emit(Event::AdventurerUpgraded(adventurer_upgraded_event));
    }

    fn __event__StartGame(
        ref self: ContractState,
        adventurer_state: AdventurerState,
        adventurer_meta: AdventurerMetadata
    ) {
        self.emit(Event::StartGame(StartGame { adventurer_state, adventurer_meta }));
    }

    fn __event__DiscoveredHealth(
        ref self: ContractState, adventurer_id: u256, adventurer: Adventurer, health_amount: u16
    ) {
        self
            .emit(
                Event::DiscoveredHealth(
                    DiscoveredHealth {
                        adventurer_state: AdventurerState {
                            owner: get_caller_address(),
                            adventurer_id: adventurer_id,
                            adventurer: adventurer
                        }, health_amount
                    }
                )
            );
    }

    fn __event__DiscoveredGold(
        ref self: ContractState, adventurer_id: u256, adventurer: Adventurer, gold_amount: u16
    ) {
        self
            .emit(
                Event::DiscoveredGold(
                    DiscoveredGold {
                        adventurer_state: AdventurerState {
                            owner: get_caller_address(),
                            adventurer_id: adventurer_id,
                            adventurer: adventurer
                        }, gold_amount
                    }
                )
            );
    }

    fn __event__DiscoveredXP(
        ref self: ContractState, adventurer_id: u256, adventurer: Adventurer, xp_amount: u16
    ) {
        self
            .emit(
                Event::DiscoveredXP(
                    DiscoveredXP {
                        adventurer_state: AdventurerState {
                            owner: get_caller_address(),
                            adventurer_id: adventurer_id,
                            adventurer: adventurer
                        }, xp_amount
                    }
                )
            );
    }

    fn __event__DodgedObstacle(ref self: ContractState, dodged_obstacle: DodgedObstacle) {
        self.emit(Event::DodgedObstacle(dodged_obstacle));
    }

    fn __event__HitByObstacle(ref self: ContractState, hit_by_obstacle: HitByObstacle) {
        self.emit(Event::HitByObstacle(hit_by_obstacle));
    }

    fn __event__DiscoveredBeast(ref self: ContractState, discover_beast_event: DiscoveredBeast, ) {
        self.emit(Event::DiscoveredBeast(discover_beast_event));
    }

    fn __event__AttackedBeast(ref self: ContractState, attack_beast: AttackedBeast, ) {
        self.emit(Event::AttackedBeast(attack_beast));
    }

    fn __event__AttackedByBeast(ref self: ContractState, attack_by_beast: AttackedByBeast, ) {
        self.emit(Event::AttackedByBeast(attack_by_beast));
    }

    fn __event__AmbushedByBeast(ref self: ContractState, ambushed_by_beast: AmbushedByBeast, ) {
        self.emit(Event::AmbushedByBeast(ambushed_by_beast));
    }

    fn __event__SlayedBeast(ref self: ContractState, slayed_beast: SlayedBeast, ) {
        self.emit(Event::SlayedBeast(slayed_beast));
    }

    fn __event__FleeFailed(ref self: ContractState, flee_failed: FleeFailed) {
        self.emit(Event::FleeFailed(flee_failed));
    }

    fn __event__FleeSucceeded(ref self: ContractState, flee_succeeded: FleeSucceeded) {
        self.emit(Event::FleeSucceeded(flee_succeeded));
    }

    fn __event_EquippedItems(
        ref self: ContractState,
        adventurer_state_with_bag: AdventurerStateWithBag,
        equipped_items: Array<u8>,
        unequipped_items: Array<u8>,
    ) {
        self
            .emit(
                Event::EquippedItems(
                    EquippedItems { adventurer_state_with_bag, equipped_items, unequipped_items }
                )
            );
    }

    fn __event_DroppedItems(
        ref self: ContractState,
        adventurer_state_with_bag: AdventurerStateWithBag,
        item_ids: Array<u8>,
    ) {
        self.emit(Event::DroppedItems(DroppedItems { adventurer_state_with_bag, item_ids }));
    }

    fn __event_ItemLeveledUp(
        ref self: ContractState,
        adventurer_state: AdventurerState,
        item_id: u8,
        previous_level: u8,
        new_level: u8
    ) {
        self
            .emit(
                Event::ItemLeveledUp(
                    ItemLeveledUp { adventurer_state, item_id, previous_level, new_level }
                )
            );
    }

    fn __event_ItemSpecialUnlocked(
        ref self: ContractState,
        adventurer_state: AdventurerState,
        id: u8,
        level: u8,
        specials: ItemSpecials
    ) {
        self
            .emit(
                Event::ItemSpecialUnlocked(
                    ItemSpecialUnlocked { adventurer_state, id, level, specials }
                )
            );
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
        if _is_top_score(@self, adventurer_state.adventurer.xp) {
            _update_leaderboard(
                ref self, adventurer_state.adventurer_id, adventurer_state.adventurer.xp
            );
        }
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

    fn __event_IdleDamagePenalty(
        ref self: ContractState,
        adventurer_state: AdventurerState,
        idle_blocks: u16,
        damage_taken: u16
    ) {
        self
            .emit(
                Event::IdleDamagePenalty(
                    IdleDamagePenalty { adventurer_state, idle_blocks, damage_taken }
                )
            );
    }

    fn __event_UpgradeAvailable(ref self: ContractState, adventurer_state: AdventurerState) {
        self.emit(Event::UpgradeAvailable(UpgradeAvailable { adventurer_state }));
    }

    fn __event_PurchasedItems(ref self: ContractState, purchased_items: PurchasedItems) {
        self.emit(Event::PurchasedItems(purchased_items));
    }

    fn __event_PurchasedPotions(ref self: ContractState, purchased_potions: PurchasedPotions) {
        self.emit(Event::PurchasedPotions(purchased_potions));
    }
}
