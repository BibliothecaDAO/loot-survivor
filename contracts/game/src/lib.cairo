mod game;
mod tests;

#[starknet::contract]
mod Game {
    // TODO: TESTING CONFIGS 
    // ADJUST THESE BEFORE DEPLOYMENT
    const MIN_BLOCKS_FOR_GAME_ENTROPY_CHANGE: u64 = 8;
    const IDLE_DEATH_PENALTY_BLOCKS: u16 = 16;
    const TEST_ENTROPY: u64 = 12303548;
    const MINIMUM_SCORE_FOR_PAYOUTS: u256 = 300;
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

    use openzeppelin::token::erc20::interface::{
        IERC20Camel, IERC20CamelDispatcher, IERC20CamelDispatcherTrait, IERC20CamelLibraryDispatcher
    };

    use super::game::{
        interfaces::{IGame},
        constants::{
            messages, Week, WEEK_2, WEEK_4, WEEK_8, BLOCKS_IN_A_WEEK, COST_TO_PLAY, U64_MAX,
            U128_MAX, STARTER_BEAST_ATTACK_DAMAGE, STARTING_STATS
        }
    };
    use lootitems::{
        loot::{ILoot, Loot, ImplLoot}, constants::{ItemId, NamePrefixLength, NameSuffixLength}
    };
    use pack::{pack::{Packing, rshift_split}, constants::{MASK_16, pow, MASK_8, MASK_BOOL, mask}};
    use survivor::{
        adventurer::{Adventurer, ImplAdventurer, IAdventurer}, adventurer_stats::{Stats, StatUtils},
        item_primitive::{ImplItemPrimitive, ItemPrimitive}, bag::{Bag, IBag, ImplBag},
        adventurer_meta::{AdventurerMetadata}, exploration::ExploreUtils,
        constants::{
            discovery_constants::DiscoveryEnums::{ExploreResult, TreasureDiscovery},
            adventurer_constants::{
                POTION_HEALTH_AMOUNT, ITEM_XP_MULTIPLIER_BEASTS, ITEM_XP_MULTIPLIER_OBSTACLES,
                ITEM_MAX_GREATNESS, MAX_GREATNESS_STAT_BONUS, StatisticIndex,
                VITALITY_INSTANT_HEALTH_BONUS, BEAST_SPECIAL_NAME_LEVEL_UNLOCK
            }
        },
        item_meta::{ImplItemSpecials, ItemSpecials, IItemSpecials, ItemSpecialsStorage},
        adventurer_utils::AdventurerUtils
    };
    use market::{
        market::{ImplMarket, LootWithPrice, ItemPurchase}, constants::{NUMBER_OF_ITEMS_PER_LEVEL}
    };
    use obstacles::obstacle::{ImplObstacle, IObstacle};
    use combat::{
        combat::{CombatSpec, SpecialPowers, ImplCombat}, constants::CombatEnums::{Slot, Tier, Type}
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
        _collectible_beasts: ContractAddress,
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
        ItemsLeveledUp: ItemsLeveledUp,
        ItemSpecialUnlocked: ItemSpecialUnlocked,
        NewHighScore: NewHighScore,
        AdventurerDied: AdventurerDied,
        AdventurerLeveledUp: AdventurerLeveledUp,
        NewItemsAvailable: NewItemsAvailable,
        IdleDeathPenalty: IdleDeathPenalty,
        AdventurerUpgraded: AdventurerUpgraded,
        RewardDistribution: RewardDistribution,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        lords: ContractAddress,
        dao: ContractAddress,
        collectible_beasts: ContractAddress
    ) {
        // set the contract addresses
        self._lords.write(lords);
        self._dao.write(dao);
        self._collectible_beasts.write(collectible_beasts);

        // set the genesis block
        self._genesis_block.write(starknet::get_block_info().unbox().block_number.into());

        // set global game entropy
        _set_global_entropy(ref self);
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

            // unpack adventurer from storage and apply item stat boosts
            let (mut adventurer, stat_boosts) = _unpack_adventurer_with_stat_boosts(
                @self, adventurer_id
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
                    adventurer_entropy,
                    global_entropy,
                    till_beast
                );
            }

            // update players last action block number
            adventurer.last_action.set_last_action(starknet::get_block_info().unbox().block_number);

            // write the resulting adventurer to storage
            _pack_adventurer_remove_stat_boost(
                ref self, ref adventurer, adventurer_id, stat_boosts
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

            // unpack adventurer from storage and apply item stat boosts
            let (mut adventurer, stat_boosts) = _unpack_adventurer_with_stat_boosts(
                @self, adventurer_id
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
                _attack(ref self, ref adventurer, adventurer_id, to_the_death);
            }

            // update players last action block number
            adventurer.last_action.set_last_action(starknet::get_block_info().unbox().block_number);

            // pack and save adventurer
            _pack_adventurer_remove_stat_boost(
                ref self, ref adventurer, adventurer_id, stat_boosts
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

            // unpack adventurer from storage and apply item stat boosts
            let (mut adventurer, stat_boosts) = _unpack_adventurer_with_stat_boosts(
                @self, adventurer_id
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
                let (beast, beast_seed) = adventurer.get_beast(adventurer_entropy);

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
            }

            // update players last action block number
            adventurer.last_action.set_last_action(starknet::get_block_info().unbox().block_number);

            // pack and save adventurer
            _pack_adventurer_remove_stat_boost(
                ref self, ref adventurer, adventurer_id, stat_boosts
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

            // unpack adventurer from storage and apply item stat boosts
            let (mut adventurer, stat_boosts) = _unpack_adventurer_with_stat_boosts(
                @self, adventurer_id
            );

            // assert adventurer is not dead
            _assert_not_dead(adventurer.health);

            // get adventurers bag
            let mut bag = _bag_unpacked(@self, adventurer_id);

            // equip items, passing in items as a clone so we can maintain ownership of original for event
            _equip_items(ref self, ref adventurer, ref bag, adventurer_id, items.clone(), false);

            // if the adventurer is equipping an item during battle
            if (adventurer.in_battle()) {
                // the beast gets a counter attack

                // get entropy
                let (adventurer_entropy, global_entropy) = _get_adventurer_and_global_entropy(
                    @self, adventurer_id
                );

                // get beast seed from entropy
                let (beast, beast_seed) = adventurer.get_beast(adventurer_entropy);

                // get two random numbers from entropy sources
                let (attack_rnd_1, attack_rnd_2) = _get_live_entropy(
                    adventurer_entropy, global_entropy.into(), adventurer
                );

                // process beast counter attacks
                _beast_counter_attack(
                    ref self,
                    ref adventurer,
                    adventurer_id,
                    beast,
                    beast_seed,
                    attack_rnd_1,
                    attack_rnd_2,
                    false
                );
            }

            // remove stats, pack, and save adventurer 
            _pack_adventurer_remove_stat_boost(
                ref self, ref adventurer, adventurer_id, stat_boosts
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
            let (mut adventurer, stat_boosts) = _unpack_adventurer_with_stat_boosts(
                @self, adventurer_id
            );

            // assert adventurer is not dead
            _assert_not_dead(adventurer.health);

            // get adventurers bag
            let mut bag = _bag_unpacked(@self, adventurer_id);

            // drop items
            _drop_items(ref self, ref adventurer, ref bag, adventurer_id, items.clone());

            // if the adventurer was mutated
            if (adventurer.mutated) {
                // pack and save it
                _pack_adventurer_remove_stat_boost(
                    ref self, ref adventurer, adventurer_id, stat_boosts
                );
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
                    },
                    bag: bag
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

            // unpack adventurer from storage and apply item stat boosts
            let (mut adventurer, stat_boosts) = _unpack_adventurer_with_stat_boosts(
                @self, adventurer_id
            );

            // unpack Loot bag from storage
            let mut bag = _bag_unpacked(@self, adventurer_id);

            // assert adventurer is not dead
            _assert_not_dead(adventurer.health);

            // assert adventurer is not in battle
            _assert_not_in_battle(adventurer.beast_health);

            // assert market is open
            _assert_market_is_open(adventurer.stat_points_available);

            // get number of stat upgrades available before we use them
            let num_stat_upgrades = adventurer.stat_points_available;

            // upgrade adventurer's stats
            _upgrade_stats(
                @self, ref adventurer, strength, dexterity, vitality, intelligence, wisdom, charisma
            );

            // if the player is buying potions as part of the upgrade
            if potions != 0 {
                // process potion purchase
                _buy_potions(ref self, ref adventurer, adventurer_id, potions);
            }

            // if the player is buying items as part of the upgrade
            if (items.len() != 0) {
                // process item purchases
                _buy_items(
                    ref self,
                    ref adventurer,
                    ref bag,
                    adventurer_id,
                    num_stat_upgrades,
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
                        },
                        bag: bag
                    },
                    strength_increase: strength,
                    dexterity_increase: dexterity,
                    vitality_increase: vitality,
                    intelligence_increase: intelligence,
                    wisdom_increase: wisdom,
                    charisma_increase: charisma,
                }
            );

            // if the upgrade mutated the adventurer's bag
            if (bag.mutated) {
                // pack and save updated bag
                _pack_bag(ref self, adventurer_id, bag);
            }

            // remove stat boosts, pack, and save adventurer
            _pack_adventurer_remove_stat_boost(
                ref self, ref adventurer, adventurer_id, stat_boosts
            );
        }

        // @notice slays an adventurer that has been idle for too long
        // @dev Anyone can call this function, so we intentionally don't assert ownership.
        // @param adventurer_id The unique identifier for the adventurer to be slayed.
        fn slay_idle_adventurers(ref self: ContractState, adventurer_ids: Array<u256>) {
            assert(adventurer_ids.len() != 0, 'No adventurer ids provided');
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

        //
        // view functions
        //
        fn get_adventurer(self: @ContractState, adventurer_id: u256) -> Adventurer {
            let (adventurer, _) = _unpack_adventurer_with_stat_boosts(self, adventurer_id);
            adventurer
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
            _get_item_specials(self, adventurer_id, adventurer.weapon)
        }
        fn get_chest_specials(self: @ContractState, adventurer_id: u256) -> ItemSpecials {
            let adventurer = _unpack_adventurer(self, adventurer_id);
            _get_item_specials(self, adventurer_id, adventurer.chest)
        }
        fn get_head_specials(self: @ContractState, adventurer_id: u256) -> ItemSpecials {
            let adventurer = _unpack_adventurer(self, adventurer_id);
            _get_item_specials(self, adventurer_id, adventurer.head)
        }
        fn get_waist_specials(self: @ContractState, adventurer_id: u256) -> ItemSpecials {
            let adventurer = _unpack_adventurer(self, adventurer_id);
            _get_item_specials(self, adventurer_id, adventurer.waist)
        }
        fn get_foot_specials(self: @ContractState, adventurer_id: u256) -> ItemSpecials {
            let adventurer = _unpack_adventurer(self, adventurer_id);
            _get_item_specials(self, adventurer_id, adventurer.foot)
        }
        fn get_hand_specials(self: @ContractState, adventurer_id: u256) -> ItemSpecials {
            let adventurer = _unpack_adventurer(self, adventurer_id);
            _get_item_specials(self, adventurer_id, adventurer.hand)
        }
        fn get_necklace_specials(self: @ContractState, adventurer_id: u256) -> ItemSpecials {
            let adventurer = _unpack_adventurer(self, adventurer_id);
            _get_item_specials(self, adventurer_id, adventurer.neck)
        }
        fn get_ring_specials(self: @ContractState, adventurer_id: u256) -> ItemSpecials {
            let adventurer = _unpack_adventurer(self, adventurer_id);
            _get_item_specials(self, adventurer_id, adventurer.ring)
        }
        fn get_items_on_market(self: @ContractState, adventurer_id: u256) -> Array<u8> {
            let adventurer = _unpack_adventurer(self, adventurer_id);
            _assert_market_is_open(adventurer.stat_points_available);
            let adventurer_entropy: u128 = _adventurer_meta_unpacked(self, adventurer_id)
                .entropy
                .into();
            _get_items_on_market(
                self, adventurer_entropy, adventurer.xp, adventurer.stat_points_available
            )
        }
        fn get_items_on_market_by_slot(
            self: @ContractState, adventurer_id: u256, slot: u8
        ) -> Array<u8> {
            let adventurer = _unpack_adventurer(self, adventurer_id);
            _assert_market_is_open(adventurer.stat_points_available);
            let adventurer_entropy: u128 = _adventurer_meta_unpacked(self, adventurer_id)
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
            self: @ContractState, adventurer_id: u256, tier: u8
        ) -> Array<u8> {
            let adventurer = _unpack_adventurer(self, adventurer_id);
            _assert_market_is_open(adventurer.stat_points_available);
            let adventurer_entropy: u128 = _adventurer_meta_unpacked(self, adventurer_id)
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

        fn get_potion_price(self: @ContractState, adventurer_id: u256) -> u16 {
            _get_potion_price(self, adventurer_id)
        }
        fn get_item_price(self: @ContractState, adventurer_id: u256, item_id: u8) -> u16 {
            _get_item_price(self, adventurer_id, item_id)
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
            let (adventurer, _) = _unpack_adventurer_with_stat_boosts(self, adventurer_id);
            adventurer.stats
        }
        fn get_base_strength(self: @ContractState, adventurer_id: u256) -> u8 {
            _unpack_adventurer(self, adventurer_id).stats.strength
        }
        fn get_strength(self: @ContractState, adventurer_id: u256) -> u8 {
            let (adventurer, _) = _unpack_adventurer_with_stat_boosts(self, adventurer_id);
            adventurer.stats.strength
        }
        fn get_base_dexterity(self: @ContractState, adventurer_id: u256) -> u8 {
            _unpack_adventurer(self, adventurer_id).stats.dexterity
        }
        fn get_dexterity(self: @ContractState, adventurer_id: u256) -> u8 {
            let (adventurer, _) = _unpack_adventurer_with_stat_boosts(self, adventurer_id);
            adventurer.stats.dexterity
        }
        fn get_base_vitality(self: @ContractState, adventurer_id: u256) -> u8 {
            _unpack_adventurer(self, adventurer_id).stats.vitality
        }
        fn get_vitality(self: @ContractState, adventurer_id: u256) -> u8 {
            let (adventurer, _) = _unpack_adventurer_with_stat_boosts(self, adventurer_id);
            adventurer.stats.vitality
        }
        fn get_base_intelligence(self: @ContractState, adventurer_id: u256) -> u8 {
            _unpack_adventurer(self, adventurer_id).stats.intelligence
        }
        fn get_intelligence(self: @ContractState, adventurer_id: u256) -> u8 {
            let (adventurer, _) = _unpack_adventurer_with_stat_boosts(self, adventurer_id);
            adventurer.stats.intelligence
        }
        fn get_base_wisdom(self: @ContractState, adventurer_id: u256) -> u8 {
            _unpack_adventurer(self, adventurer_id).stats.wisdom
        }
        fn get_wisdom(self: @ContractState, adventurer_id: u256) -> u8 {
            let (adventurer, _,) = _unpack_adventurer_with_stat_boosts(self, adventurer_id);
            adventurer.stats.wisdom
        }
        fn get_base_charisma(self: @ContractState, adventurer_id: u256) -> u8 {
            _unpack_adventurer(self, adventurer_id).stats.charisma
        }
        fn get_charisma(self: @ContractState, adventurer_id: u256) -> u8 {
            let (adventurer, _) = _unpack_adventurer_with_stat_boosts(self, adventurer_id);
            adventurer.stats.charisma
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
            _set_global_entropy(ref self)
        }

        fn owner_of(self: @ContractState, adventurer_id: u256) -> ContractAddress {
            _owner_of(self, adventurer_id)
        }
    }

    // ------------------------------------------ //
    // ------------ Internal Functions ---------- //
    // ------------------------------------------ //

    fn _slay_idle_adventurer(ref self: ContractState, adventurer_id: u256) {
        // unpack adventurer from storage (no need for stat boosts)
        let mut adventurer = _unpack_adventurer(@self, adventurer_id);

        // assert adventurer is not already dead
        _assert_not_dead(adventurer.health);

        // assert adventurer is idle
        _assert_is_idle(adventurer);

        // slay adventurer by setting health to 0
        adventurer.health = 0;

        // handle adventurer death
        _process_adventurer_death(
            ref self,
            AdventurerDied {
                adventurer_state: AdventurerState {
                    owner: self._owner.read(adventurer_id),
                    adventurer_id: adventurer_id,
                    adventurer: adventurer
                },
                killed_by_beast: 0,
                killed_by_obstacle: 0,
                caller_address: get_caller_address()
            }
        );

        // save adventurer (gg)
        _pack_adventurer(ref self, adventurer_id, adventurer);
    }

    fn _process_beast_death(
        ref self: ContractState,
        ref adventurer: Adventurer,
        adventurer_id: u256,
        beast: Beast,
        beast_seed: u128,
        attack_rnd_2: u128,
        damage_dealt: u16,
        critical_hit: bool
    ) {
        // zero out beast health
        adventurer.beast_health = 0;

        // give adventurer gold reward
        // TODO Gas Optimization: beast.get_gold_reward and get_xp_reward both call the same 
        // get_base_reward from Combat module. Should refactor this to only make that call once and have
        // get_gold_reward and get_xp_reward operator on the base reward
        let mut gold_reward = beast.get_gold_reward(beast_seed);
        let bag = _bag_unpacked(@self, adventurer_id);
        adventurer.increase_gold(gold_reward * adventurer.beast_gold_reward_multiplier().into());

        // grant adventuer xp
        let adventurer_xp_reward = beast.get_xp_reward();
        let (previous_level, new_level) = adventurer.increase_adventurer_xp(adventurer_xp_reward);

        // grant equipped items xp, items level faster than Adventurers
        let item_xp_reward = adventurer_xp_reward * ITEM_XP_MULTIPLIER_BEASTS;
        _grant_xp_to_equipped_items(
            ref self, ref adventurer, adventurer_id, item_xp_reward, attack_rnd_2
        );

        // emit slayed beast event
        __event_SlayedBeast(
            ref self,
            SlayedBeast {
                adventurer_state: AdventurerState {
                    owner: get_caller_address(),
                    adventurer_id: adventurer_id,
                    adventurer: adventurer
                },
                seed: beast_seed,
                id: beast.id,
                beast_specs: CombatSpec {
                    tier: beast.combat_spec.tier,
                    item_type: beast.combat_spec.item_type,
                    level: beast.combat_spec.level,
                    specials: beast.combat_spec.specials
                },
                damage_dealt: damage_dealt,
                critical_hit: critical_hit,
                xp_earned_adventurer: adventurer_xp_reward,
                xp_earned_items: item_xp_reward,
                gold_earned: gold_reward
            }
        );

        // if adventurers new level is greater than previous level
        if (adventurer.stat_points_available > 0) {
            _emit_level_up_events(ref self, adventurer, adventurer_id, previous_level, new_level);
        }

        if beast.combat_spec.level >= BEAST_SPECIAL_NAME_LEVEL_UNLOCK {
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

        if !is_beast_minted {
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

    fn _process_adventurer_death(ref self: ContractState, adventurer_died_event: AdventurerDied) {
        // emit adventurer died event
        __event_AdventurerDied(ref self, adventurer_died_event.clone());

        // if game was a top score
        let adventurer_score = adventurer_died_event.adventurer_state.adventurer.xp;
        if _is_top_score(@self, adventurer_score) {
            // update leaderboard
            _update_leaderboard(
                ref self, adventurer_died_event.adventurer_state.adventurer_id, adventurer_score
            );
        }
    }

    fn _to_ether(amount: u256) -> u256 {
        amount * 10 ^ 18
    }

    fn _payout(
        ref self: ContractState,
        caller: ContractAddress,
        block_number: u64,
        client_address: ContractAddress
    ) {
        let lords = self._lords.read();
        let genesis_block = self._genesis_block.read();
        let dao_address = self._dao.read();
        let first_place_adventurer_id = self._scoreboard.read(1);
        let first_place_address = self._owner.read(first_place_adventurer_id);
        let second_place_adventurer_id = self._scoreboard.read(2);
        let second_place_address = self._owner.read(second_place_adventurer_id);
        let third_place_adventurer_id = self._scoreboard.read(3);
        let third_place_address = self._owner.read(third_place_adventurer_id);

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
            IERC20CamelDispatcher { contract_address: lords }
                .transferFrom(caller, dao_address, _to_ether(COST_TO_PLAY));

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
                    dao: COST_TO_PLAY
                }
            );
            return;
        }

        // once reasonable scores have been set
        // we start doing payouts

        // for the first eight weeks, the majority go to the top three score
        week =
            Week {
                DAO: _to_ether(WEEK_4::DAO),
                INTERFACE: _to_ether(WEEK_4::INTERFACE),
                FIRST_PLACE: _to_ether(WEEK_4::FIRST_PLACE),
                SECOND_PLACE: _to_ether(WEEK_4::SECOND_PLACE),
                THIRD_PLACE: _to_ether(WEEK_4::THIRD_PLACE)
            };

        // after 8 weeks, the client providers start getting a share
        if (BLOCKS_IN_A_WEEK * 8 + genesis_block) > block_number {
            week =
                Week {
                    DAO: _to_ether(WEEK_8::DAO),
                    INTERFACE: _to_ether(WEEK_8::INTERFACE),
                    FIRST_PLACE: _to_ether(WEEK_8::FIRST_PLACE),
                    SECOND_PLACE: _to_ether(WEEK_8::SECOND_PLACE),
                    THIRD_PLACE: _to_ether(WEEK_8::THIRD_PLACE)
                }
        }

        // DAO
        if (week.DAO != 0) {
            IERC20CamelDispatcher { contract_address: lords }
                .transferFrom(caller, dao_address, week.DAO);
        }

        // interface
        if (week.INTERFACE != 0) {
            IERC20CamelDispatcher { contract_address: lords }
                .transferFrom(caller, client_address, week.INTERFACE);
        }

        // first place
        IERC20CamelDispatcher { contract_address: lords }
            .transferFrom(caller, first_place_address, week.FIRST_PLACE);

        // second place
        IERC20CamelDispatcher { contract_address: lords }
            .transferFrom(caller, second_place_address, week.SECOND_PLACE);

        // third place
        IERC20CamelDispatcher { contract_address: lords }
            .transferFrom(caller, third_place_address, week.THIRD_PLACE);

        __event_RewardDistribution(
            ref self,
            RewardDistribution {
                first_place: PlayerReward {
                    adventurer_id: first_place_adventurer_id,
                    rank: 1,
                    amount: week.FIRST_PLACE,
                    address: first_place_address
                },
                second_place: PlayerReward {
                    adventurer_id: second_place_adventurer_id,
                    rank: 2,
                    amount: week.SECOND_PLACE,
                    address: second_place_address
                },
                third_place: PlayerReward {
                    adventurer_id: third_place_adventurer_id,
                    rank: 3,
                    amount: week.THIRD_PLACE,
                    address: third_place_address
                },
                client: ClientReward { amount: week.INTERFACE, address: client_address },
                dao: week.DAO
            }
        );
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
        __event_StartGame(
            ref self,
            event: StartGame {
                adventurer_state: AdventurerState {
                    owner: caller, adventurer_id, adventurer: new_adventurer
                },
                adventurer_meta: adventurer_meta
            }
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
        adventurer.decrease_health(STARTER_BEAST_ATTACK_DAMAGE);

        // and emitting an AmbushedByBeast event
        __event_AmbushedByBeast(
            ref self,
            AmbushedByBeast {
                adventurer_state: AdventurerState {
                    owner: get_caller_address(),
                    adventurer_id: adventurer_id,
                    adventurer: adventurer
                },
                seed: beast_seed,
                id: starter_beast.id,
                beast_specs: CombatSpec {
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
                // get beast and beast seed
                let (beast, beast_seed) = adventurer.get_beast(adventurer_entropy);

                // init beast health (this is only info about beast that we store)
                adventurer.beast_health = beast.starting_health;

                // check if beast ambushed adventurer
                let is_ambushed = adventurer.is_ambushed(beast_seed);

                // if adventurer was ambushed
                if (is_ambushed) {
                    // process beast attack
                    _beast_counter_attack(
                        ref self,
                        ref adventurer,
                        adventurer_id,
                        beast,
                        beast_seed,
                        sub_explore_rnd,
                        sub_explore_rnd,
                        true
                    );
                } else {
                    // Emit Discover Beast event
                    __event_DiscoveredBeast(
                        ref self,
                        DiscoveredBeast {
                            adventurer_state: AdventurerState {
                                owner: get_caller_address(),
                                adventurer_id: adventurer_id,
                                adventurer: adventurer
                            },
                            seed: beast_seed,
                            id: beast.id,
                            beast_specs: CombatSpec {
                                tier: beast.combat_spec.tier,
                                item_type: beast.combat_spec.item_type,
                                level: beast.combat_spec.level,
                                specials: beast.combat_spec.specials
                            }
                        }
                    );
                }
            },
            ExploreResult::Obstacle(()) => {
                _obstacle_encounter(ref self, ref adventurer, adventurer_id, sub_explore_rnd);
            },
            ExploreResult::Treasure(()) => {
                // TODO: Consider passing in adventurer ref into discover_treasure and handling
                //       adventurer mutations within lib functions. The lib functions could return
                //       a generic Discovery event which would be emitted here
                let (treasure_type, mut amount) = adventurer.discover_treasure(sub_explore_rnd);

                // apply discover bonus based on adventurer
                amount *= adventurer.discovery_bonus_multplier().into();

                match treasure_type {
                    TreasureDiscovery::Gold(()) => {
                        // add gold to adventurer
                        adventurer.increase_gold(amount);
                        // emit discovered gold event
                        __event_DiscoveredGold(
                            ref self,
                            DiscoveredGold {
                                discovery: Discovery {
                                    adventurer_state: AdventurerState {
                                        owner: get_caller_address(),
                                        adventurer_id: adventurer_id,
                                        adventurer: adventurer
                                    },
                                    amount: amount
                                }
                            }
                        );
                    },
                    TreasureDiscovery::XP(()) => {
                        // apply XP to adventurer
                        let (previous_level, new_level) = adventurer.increase_adventurer_xp(amount);
                        // emit discovered xp event
                        __event_DiscoveredXP(
                            ref self,
                            DiscoveredXP {
                                discovery: Discovery {
                                    adventurer_state: AdventurerState {
                                        owner: get_caller_address(),
                                        adventurer_id: adventurer_id,
                                        adventurer: adventurer
                                    },
                                    amount: amount
                                }
                            }
                        );
                        // check for level up
                        if (adventurer.stat_points_available > 0) {
                            // process level up
                            _emit_level_up_events(
                                ref self, adventurer, adventurer_id, previous_level, new_level
                            );
                        }
                    },
                    TreasureDiscovery::Health(()) => {
                        // if adventurer's health is already full
                        if (AdventurerUtils::is_health_full(
                            adventurer.health, adventurer.stats.vitality
                        )) {
                            // adventurer gets gold instead of health
                            adventurer.increase_gold(amount);
                            // emit discovered gold event
                            __event_DiscoveredGold(
                                ref self,
                                DiscoveredGold {
                                    discovery: Discovery {
                                        adventurer_state: AdventurerState {
                                            owner: get_caller_address(),
                                            adventurer_id: adventurer_id,
                                            adventurer: adventurer
                                        },
                                        amount: amount
                                    }
                                }
                            );
                        } else {
                            // otherwise add health
                            adventurer.increase_health(amount);
                            __event_DiscoveredHealth(
                                ref self,
                                DiscoveredHealth {
                                    discovery: Discovery {
                                        adventurer_state: AdventurerState {
                                            owner: get_caller_address(),
                                            adventurer_id: adventurer_id,
                                            adventurer: adventurer
                                        },
                                        amount: amount
                                    }
                                }
                            );
                        }
                    }
                }
            }
        }

        // if adventurer elected to explore till they find a beast and
        // they have not found a beast yet and
        // they are still alive and
        // they have not leveled up
        if till_beast
            && adventurer.beast_health == 0
            && adventurer.health != 0
            && !(adventurer.stat_points_available != 0) {
            // Keep exploring
            _explore(
                ref self,
                ref adventurer,
                adventurer_id,
                adventurer_entropy,
                global_entropy,
                till_beast
            );
        }
    }

    fn _obstacle_encounter(
        ref self: ContractState, ref adventurer: Adventurer, adventurer_id: u256, entropy: u128
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

        // if the adventurer has unlocked obstalce gold reward multplier
        let obstacle_gold_reward_multiplier = adventurer.obstacle_gold_reward_multplier();
        if (obstacle_gold_reward_multiplier != 0) {
            // adventurer gets gold
            adventurer.increase_gold(adventurer_xp_reward * obstacle_gold_reward_multiplier.into());
        }
        // increase adventurer xp and check for level up
        let (previous_level, new_level) = adventurer.increase_adventurer_xp(adventurer_xp_reward);

        // get armor defense bonus for adventurer
        let armor_defense_bonus = adventurer.critical_hit_bonus_multiplier();

        // calculate damage from the obstacle
        let (damage_taken, critical_hit) = ImplObstacle::get_damage(
            obstacle, armor_combat_spec, armor_defense_bonus, entropy
        );

        // if the obstalce was not dodged
        if (!dodged) {
            // adventurer takes this damage
            adventurer.decrease_health(damage_taken);
        }

        // grant XP to equipped items
        _grant_xp_to_equipped_items(
            ref self, ref adventurer, adventurer_id, item_xp_reward, entropy
        );

        let obstacle_event = ObstacleEvent {
            adventurer_state: AdventurerState {
                owner: get_caller_address(), adventurer_id: adventurer_id, adventurer: adventurer
            },
            id: obstacle.id,
            level: obstacle.combat_specs.level,
            damage_taken,
            damage_location,
            critical_hit,
            adventurer_xp_reward,
            item_xp_reward
        };

        if (dodged) {
            __event_DodgedObstacle(ref self, DodgedObstacle { obstacle_event });
        } else {
            __event_HitByObstacle(ref self, HitByObstacle { obstacle_event });
        }

        // if obstacle killed adventurer
        if (adventurer.health == 0) {
            // process adventurer death
            _process_adventurer_death(
                ref self,
                AdventurerDied {
                    adventurer_state: AdventurerState {
                        owner: self._owner.read(adventurer_id),
                        adventurer_id: adventurer_id,
                        adventurer: adventurer
                    },
                    killed_by_beast: 0,
                    killed_by_obstacle: obstacle.id,
                    caller_address: get_caller_address()
                }
            );
            // and return as game is now over
            return;
        } else if (adventurer.stat_points_available > 0) {
            // if adventurer leveled up, process level up
            _emit_level_up_events(ref self, adventurer, adventurer_id, previous_level, new_level);
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
    // @return None. However, it may emit an `ItemsLeveledUp` event.// 
    fn _grant_xp_to_equipped_items(
        ref self: ContractState,
        ref adventurer: Adventurer,
        adventurer_id: u256,
        xp_amount: u16,
        entropy: u128
    ) {
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

        if items_leveled_up.len() != 0 {
            __event_ItemsLeveledUp(
                ref self,
                AdventurerState {
                    owner: get_caller_address(),
                    adventurer_id: adventurer_id,
                    adventurer: adventurer
                },
                items_leveled_up
            );
        }

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
        // check if item reached greatness 20
        if (new_level == ITEM_MAX_GREATNESS) {
            // if so, adventurer gets bonus stat points (currently just 1)
            adventurer
                .stat_points_available
                .increase_stat_points_available(MAX_GREATNESS_STAT_BONUS);
        }

        // check if item unlocked any specials as part of level up
        let (suffix_unlocked, prefixes_unlocked) = ImplAdventurer::unlocked_specials(
            previous_level, new_level
        );

        let mut specials = ItemSpecials { special1: 0, special2: 0, special3: 0 };
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

            ItemLeveledUp {
                item_id: item.id,
                previous_level,
                new_level,
                suffix_unlocked,
                prefixes_unlocked,
                specials
            }
        } else {
            ItemLeveledUp {
                item_id: item.id,
                previous_level,
                new_level,
                suffix_unlocked,
                prefixes_unlocked,
                specials
            }
        }
    }

    // @notice Simulates an attack by the adventurer on a beast.
    // @param self The contract's state.
    // @param adventurer The adventurer who is attacking.
    // @param adventurer_id The unique ID of the adventurer.
    // @param fight_to_the_death Flag to indicate if the fight should continue until either the adventurer or the beast is defeated.
    fn _attack(
        ref self: ContractState,
        ref adventurer: Adventurer,
        adventurer_id: u256,
        fight_to_the_death: bool,
    ) {
        // get adventurer entropy from storage
        let adventurer_entropy: u128 = _adventurer_meta_unpacked(@self, adventurer_id)
            .entropy
            .into();

        // get game entropy from storage
        let global_entropy: u128 = _get_global_entropy(@self).into();

        // get beast and beast seed
        let (beast, beast_seed) = adventurer.get_beast(adventurer_entropy);

        // When generating the beast, we need to ensure entropy remains fixed for the battle
        // for attacking however, we should change the entropy during battle so we use adventurer and beast health
        // to accomplish this
        let (attack_rnd_1, attack_rnd_2) = _get_live_entropy(
            adventurer_entropy, global_entropy, adventurer
        );

        // get the damage dealt to the beast
        // TODO: Consider returning a tuple with detailed damage info (total_damage, base_damage, critical_hit_damage, name_bonus_damage)
        let weapon_combat_spec = _get_combat_spec(@self, adventurer_id, adventurer.weapon);
        let critical_hit_damage_multiplier = adventurer.critical_hit_bonus_multplier();
        let name_bonus_damage_multplier = adventurer.name_match_bonus_damage_multiplier();
        let armor_defense_multiplier = adventurer.critical_hit_bonus_multiplier();
        let bag = _bag_unpacked(@self, adventurer_id);
        let adventurer_luck = adventurer.get_luck(bag);
        let (damage_dealt, critical_hit) = beast
            .attack(
                weapon_combat_spec,
                adventurer_luck,
                adventurer.stats.strength,
                critical_hit_damage_multiplier,
                name_bonus_damage_multplier,
                armor_defense_multiplier,
                attack_rnd_1
            );

        // if the damage dealt exceeds the beasts health
        if (damage_dealt >= adventurer.beast_health) {
            // process beast death
            _process_beast_death(
                ref self,
                ref adventurer,
                adventurer_id,
                beast,
                beast_seed,
                attack_rnd_2,
                damage_dealt,
                critical_hit
            );
        } else {
            // if beast is still alive

            // deduct the damage dealt from their health
            adventurer.beast_health -= damage_dealt;

            // emit attack beast event
            __event_AttackedBeast(
                ref self,
                AttackedBeast {
                    adventurer_state: AdventurerState {
                        owner: get_caller_address(),
                        adventurer_id: adventurer_id,
                        adventurer: adventurer
                    },
                    seed: beast_seed,
                    id: beast.id,
                    beast_specs: CombatSpec {
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

            // beast counter attacks
            let adventurer_died = _beast_counter_attack(
                ref self,
                ref adventurer,
                adventurer_id,
                beast,
                beast_seed,
                attack_rnd_1,
                attack_rnd_2,
                false
            );

            // if the adventurer is still alive and fighting to the death
            if (fight_to_the_death && adventurer.health != 0) {
                // attack again
                _attack(ref self, ref adventurer, adventurer_id, true);
            }
        }
    }

    // @notice Handles a counter-attack by a beast after an adventurer's attack or flee attempt.
    // @param self The contract's state.
    // @param adventurer The adventurer who is being counter-attacked.
    // @param adventurer_id The unique ID of the adventurer.
    // @param attack_location The location of the attack on the adventurer.
    // @param beast The beast that is counter-attacking.
    // @param beast_seed The seed related to the beast.
    // @param entropy The entropy used for the attack simulation.
    // @param ambushed Flag to indicate if the counter-attack was an ambush.
    fn _beast_counter_attack(
        ref self: ContractState,
        ref adventurer: Adventurer,
        adventurer_id: u256,
        beast: Beast,
        beast_seed: u128,
        critical_hit_rnd: u128,
        attack_location_rnd: u128,
        ambushed: bool
    ) {
        // get the location of the beast attack
        let attack_location = AdventurerUtils::get_random_attack_location(attack_location_rnd);

        // get adventurer armor at that location
        let armor = adventurer.get_item_at_slot(attack_location);

        // convert get combat spec of the armor
        let armor_combat_spec = _get_combat_spec(@self, adventurer_id, armor);

        // process beast counter attack
        let (damage, critical_hit) = beast.counter_attack(armor_combat_spec, critical_hit_rnd);

        // deduct the damage dealt
        adventurer.decrease_health(damage);

        // if counter attack was result of an ambush
        // emit ambushed by beast event
        if (ambushed) {
            // emit attack by beast event
            __event_AmbushedByBeast(
                ref self,
                AmbushedByBeast {
                    adventurer_state: AdventurerState {
                        owner: get_caller_address(),
                        adventurer_id: adventurer_id,
                        adventurer: adventurer
                    },
                    seed: beast_seed,
                    id: beast.id,
                    beast_specs: CombatSpec {
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
            __event_AttackedByBeast(
                ref self,
                AttackedByBeast {
                    adventurer_state: AdventurerState {
                        owner: get_caller_address(),
                        adventurer_id: adventurer_id,
                        adventurer: adventurer
                    },
                    seed: beast_seed,
                    id: beast.id,
                    beast_specs: CombatSpec {
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
            // process adventurer death
            _process_adventurer_death(
                ref self,
                AdventurerDied {
                    adventurer_state: AdventurerState {
                        owner: self._owner.read(adventurer_id),
                        adventurer_id: adventurer_id,
                        adventurer: adventurer
                    },
                    killed_by_beast: beast.id,
                    killed_by_obstacle: 0,
                    caller_address: get_caller_address()
                }
            );
        }
    }

    // @notice Handles an attempt by the adventurer to flee from a battle with a beast.
    // @param self The contract's state.
    // @param adventurer The adventurer attempting to flee.
    // @param adventurer_id The unique ID of the adventurer.
    // @param adventurer_entropy The entropy related to the adventurer used for generating the beast.
    // @param global_entropy The global entropy value.
    // @param beast_seed The seed related to the beast.
    // @param beast The beast that the adventurer is attempting to flee from.
    // @param flee_to_the_death Flag to indicate if the flee attempt should continue until either success or the adventurer's defeat.
    fn _flee(
        ref self: ContractState,
        ref adventurer: Adventurer,
        adventurer_id: u256,
        adventurer_entropy: u128,
        global_entropy: u128,
        beast_seed: u128,
        beast: Beast,
        flee_to_the_death: bool
    ) {
        // get flee and ambush entropy seeds
        let (flee_entropy, ambush_entropy) = _get_live_entropy(
            adventurer_entropy, global_entropy, adventurer
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
            __event_FleeSucceeded(
                ref self,
                FleeSucceeded {
                    flee_event: FleeEvent {
                        adventurer_state: AdventurerState {
                            owner: get_caller_address(),
                            adventurer_id: adventurer_id,
                            adventurer: adventurer
                        },
                        seed: beast_seed,
                        id: beast.id,
                        beast_specs: beast.combat_spec
                    }
                }
            );

            // check for adventurer level up
            if (adventurer.stat_points_available > 0) {
                _emit_level_up_events(
                    ref self, adventurer, adventurer_id, previous_level, new_level
                );
            }
        } else {
            // // emit flee attempt event
            __event_FleeFailed(
                ref self,
                FleeFailed {
                    flee_event: FleeEvent {
                        adventurer_state: AdventurerState {
                            owner: get_caller_address(),
                            adventurer_id: adventurer_id,
                            adventurer: adventurer
                        },
                        seed: beast_seed,
                        id: beast.id,
                        beast_specs: beast.combat_spec
                    }
                }
            );

            // if the flee attempt failed, beast counter attacks
            _beast_counter_attack(
                ref self,
                ref adventurer,
                adventurer_id,
                beast,
                beast_seed,
                ambush_entropy,
                ambush_entropy,
                false
            );

            // if player has elected to flee till death and they
            // are still alive with a beast attached to them
            if (flee_to_the_death && adventurer.health != 0) {
                // try to flee again
                _flee(
                    ref self,
                    ref adventurer,
                    adventurer_id,
                    adventurer_entropy,
                    global_entropy,
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
        adventurer_id: u256,
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
            ref self,
            AdventurerStateWithBag {
                adventurer_state: AdventurerState {
                    owner: get_caller_address(),
                    adventurer_id: adventurer_id,
                    adventurer: adventurer
                },
                bag: bag
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
        adventurer_id: u256,
        stat_points_available: u8,
        items_to_purchase: Array<ItemPurchase>,
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
        __event_PurchasedItems(
            ref self,
            PurchasedItems {
                adventurer_state_with_bag: AdventurerStateWithBag {
                    adventurer_state: AdventurerState {
                        owner: get_caller_address(),
                        adventurer_id: adventurer_id,
                        adventurer: adventurer
                    },
                    bag: bag
                },
                purchases: purchases
            }
        );

        // if we have items to equip as part of the purchase
        if (items_to_equip.len() != 0) {
            // equip them and record the items that were unequipped
            _equip_items(
                ref self, ref adventurer, ref bag, adventurer_id, items_to_equip.clone(), true
            );
        }
    }

    // @notice Process the purchase of potions for the adventurer.
    // @param adventurer The reference to the adventurer's state.
    // @param adventurer_id The ID of the adventurer.
    // @param amount The number of potions to buy.
    // @dev Emits a `PurchasedPotions` event. Throws if the adventurer does not have enough gold or is buying more health than they can use.
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
                },
                quantity: amount,
                cost: cost_of_potions,
                health: health_from_potions
            }
        );
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

        if strength_increase != 0 {
            adventurer.stats.increase_strength(strength_increase);
        }

        if dexterity_increase != 0 {
            adventurer.stats.increase_dexterity(dexterity_increase);
        }
        if vitality_increase != 0 {
            adventurer.stats.increase_vitality(vitality_increase);
            adventurer.increase_health(VITALITY_INSTANT_HEALTH_BONUS);
        }
        if intelligence_increase != 0 {
            adventurer.stats.increase_intelligence(intelligence_increase);
        }
        if wisdom_increase != 0 {
            adventurer.stats.increase_wisdom(wisdom_increase);
        }
        if charisma_increase != 0 {
            adventurer.stats.increase_charisma(charisma_increase);
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
    fn _unpack_adventurer(self: @ContractState, adventurer_id: u256) -> Adventurer {
        Packing::unpack(self._adventurer.read(adventurer_id))
    }
    fn _unpack_adventurer_with_stat_boosts(
        self: @ContractState, adventurer_id: u256
    ) -> (Adventurer, Stats) {
        // unpack adventurer
        let mut adventurer: Adventurer = Packing::unpack(self._adventurer.read(adventurer_id));
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

        // return adventurer with stat boosts
        (adventurer, stat_boosts)
    }

    fn _pack_adventurer(ref self: ContractState, adventurer_id: u256, adventurer: Adventurer) {
        self._adventurer.write(adventurer_id, adventurer.pack());
    }
    // @dev Packs and saves an adventurer after removing stat boosts.
    // @param adventurer_id The ID of the adventurer to be modified.
    // @param adventurer The adventurer to be modified.
    // @param stat_boosts The stat boosts to be removed.
    fn _pack_adventurer_remove_stat_boost(
        ref self: ContractState, ref adventurer: Adventurer, adventurer_id: u256, stat_boosts: Stats
    ) {
        // remove stat boosts
        adventurer.remove_stat_boosts(stat_boosts);

        // pack and save
        self._adventurer.write(adventurer_id, adventurer.pack());
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
        adventurer_id: u256,
        previous_level: u8,
        new_level: u8,
    ) {
        let adventurer_state = AdventurerState {
            owner: get_caller_address(), adventurer_id: adventurer_id, adventurer: adventurer
        };
        let adventurer_entropy: u128 = _adventurer_meta_unpacked(@self, adventurer_id)
            .entropy
            .into();

        // emit level up event
        if (new_level > previous_level) {
            __event_AdventurerLeveledUp(
                ref self,
                adventurer_state: adventurer_state,
                previous_level: previous_level,
                new_level: new_level
            );
        }
        // emit stat upgrades available event
        __event_UpgradeAvailable(ref self, adventurer_state);

        // emit new items availble with available items
        __event_NewItemsAvailable(
            ref self,
            adventurer_state: adventurer_state,
            items: _get_items_on_market(
                @self, adventurer_entropy, adventurer.xp, adventurer.stat_points_available
            )
        );
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
            _get_specials_storage(self, adventurer_id, LOOT_NAME_STORAGE_INDEX_1),
            _get_specials_storage(self, adventurer_id, LOOT_NAME_STORAGE_INDEX_2),
        )
    }

    fn _get_specials_storage(
        self: @ContractState, adventurer_id: u256, storage_index: u256
    ) -> ItemSpecialsStorage {
        Packing::unpack(self._loot_special_names.read((adventurer_id, storage_index)))
    }

    fn _get_item_specials(
        self: @ContractState, adventurer_id: u256, item: ItemPrimitive
    ) -> ItemSpecials {
        ImplItemSpecials::get_specials(
            _get_specials_storage(self, adventurer_id, _get_storage_index(self, item.metadata)),
            item
        )
    }
    #[inline(always)]
    fn _owner_of(self: @ContractState, adventurer_id: u256) -> ContractAddress {
        self._owner.read(adventurer_id)
    }
    #[inline(always)]
    fn _assert_ownership(self: @ContractState, adventurer_id: u256) {
        assert(self._owner.read(adventurer_id) == get_caller_address(), messages::NOT_OWNER);
    }
    #[inline(always)]
    fn _assert_in_battle(beast_health: u16) {
        assert(beast_health != 0, messages::NOT_IN_BATTLE);
    }
    #[inline(always)]
    fn _assert_dexterity_not_zero(dexterity: u8) {
        assert(dexterity != 0, messages::ZERO_DEXTERITY);
    }
    #[inline(always)]
    fn _assert_not_in_battle(beast_health: u16) {
        assert(beast_health == 0, messages::ACTION_NOT_ALLOWED_DURING_BATTLE);
    }
    #[inline(always)]
    fn _assert_market_is_open(stat_points_available: u8) {
        assert(stat_points_available != 0, messages::MARKET_CLOSED);
    }
    #[inline(always)]
    fn _assert_item_not_owned(adventurer: Adventurer, bag: Bag, item_id: u8) {
        let (item_in_bag, _) = bag.contains(item_id);
        assert(
            adventurer.is_equipped(item_id) == false && item_in_bag == false,
            messages::ITEM_ALREADY_OWNED
        );
    }
    #[inline(always)]
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
    #[inline(always)]
    fn _assert_not_starter_beast(adventurer_level: u8) {
        assert(adventurer_level > 1, messages::CANT_FLEE_STARTER_BEAST);
    }
    #[inline(always)]
    fn _assert_no_stat_upgrades_available(stat_points_available: u8) {
        assert(stat_points_available == 0, messages::STAT_UPGRADES_AVAILABLE);
    }
    #[inline(always)]
    fn _assert_not_dead(health: u16) {
        assert(health != 0, messages::DEAD_ADVENTURER);
    }
    #[inline(always)]
    fn _assert_valid_starter_weapon(starting_weapon: u8) {
        assert(
            ImplLoot::is_starting_weapon(starting_weapon) == true, messages::INVALID_STARTING_WEAPON
        );
    }
    #[inline(always)]
    fn _assert_starting_stat_count(starting_stats: Stats) {
        let total_stats = starting_stats.strength
            + starting_stats.dexterity
            + starting_stats.vitality
            + starting_stats.intelligence
            + starting_stats.wisdom
            + starting_stats.charisma;

        assert(total_stats == STARTING_STATS, messages::WRONG_STARTING_STATS);
    }
    #[inline(always)]
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

    fn _assert_is_idle(adventurer: Adventurer) {
        let (is_idle, _) = _idle_longer_than_penalty_threshold(adventurer);
        assert(is_idle, messages::ADVENTURER_NOT_IDLE);
    }

    fn _idle_longer_than_penalty_threshold(adventurer: Adventurer) -> (bool, u16) {
        let idle_blocks = adventurer
            .get_idle_blocks(starknet::get_block_info().unbox().block_number);

        (idle_blocks >= IDLE_DEATH_PENALTY_BLOCKS, idle_blocks)
    }

    // @notice: The idle penalty in Loot Survivor is death to protect the game against bots
    //          while this may seem harsh, Loot Survivor is modeled after an arcade game. You can't
    //          walk away from a game of Galaga for 10 minutes and come back expecting to still be alive
    fn _apply_idle_penalty(
        ref self: ContractState, adventurer_id: u256, ref adventurer: Adventurer, idle_blocks: u16
    ) {
        // deduct it from adventurer's health
        adventurer.health = 0;

        // emit idle death penalty event
        __event_IdleDeathPenalty(
            ref self,
            IdleDeathPenalty {
                adventurer_state: AdventurerState {
                    owner: self._owner.read(adventurer_id),
                    adventurer_id: adventurer_id,
                    adventurer: adventurer
                },
                idle_blocks: idle_blocks,
                penalty_threshold: IDLE_DEATH_PENALTY_BLOCKS,
                caller: get_caller_address()
            }
        );

        // process adventurer death
        _process_adventurer_death(
            ref self,
            AdventurerDied {
                adventurer_state: AdventurerState {
                    owner: self._owner.read(adventurer_id),
                    adventurer_id: adventurer_id,
                    adventurer: adventurer
                },
                killed_by_beast: 0,
                killed_by_obstacle: 0,
                caller_address: get_caller_address()
            }
        );
    }

    fn _lords_address(self: @ContractState) -> ContractAddress {
        self._lords.read()
    }

    fn _dao_address(self: @ContractState) -> ContractAddress {
        self._dao.read()
    }

    fn _get_items_on_market(
        self: @ContractState,
        adventurer_entropy: u128,
        adventurer_xp: u16,
        adventurer_stat_points: u8
    ) -> Array<u8> {
        ImplMarket::get_market_items(adventurer_entropy, adventurer_xp, adventurer_stat_points)
    }

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

    fn _get_potion_price(self: @ContractState, adventurer_id: u256) -> u16 {
        let (adventurer, _) = _unpack_adventurer_with_stat_boosts(self, adventurer_id);
        adventurer.charisma_adjusted_potion_price()
    }

    fn _get_item_price(self: @ContractState, adventurer_id: u256, item_id: u8) -> u16 {
        let (adventurer, _) = _unpack_adventurer_with_stat_boosts(self, adventurer_id);
        let base_item_price = ImplMarket::get_price(ImplLoot::get_tier(item_id));
        let charisma_adjusted_price = adventurer.charisma_adjusted_item_price(base_item_price);

        charisma_adjusted_price
    }

    fn _get_attacking_beast(self: @ContractState, adventurer_id: u256) -> Beast {
        // get adventurer
        let adventurer = _unpack_adventurer(self, adventurer_id);

        // assert adventurer is in battle
        assert(adventurer.beast_health != 0, messages::NOT_IN_BATTLE);

        // get adventurer entropy
        let adventurer_entropy: u128 = _adventurer_meta_unpacked(self, adventurer_id)
            .entropy
            .into();

        // get beast and beast seed
        let (beast, beast_seed) = adventurer.get_beast(adventurer_entropy);

        // return beast
        beast
    }

    fn _get_storage_index(self: @ContractState, meta_data_id: u8) -> u256 {
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
        self: @ContractState, adventurer_id: u256, item: ItemPrimitive
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
                    specials: specials
                }
            }
        }
    }

    fn _set_global_entropy(ref self: ContractState) {
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

    #[derive(Drop, Serde)]
    struct Discovery {
        adventurer_state: AdventurerState,
        amount: u16
    }

    #[derive(Drop, starknet::Event)]
    struct DiscoveredHealth {
        discovery: Discovery
    }

    #[derive(Drop, starknet::Event)]
    struct DiscoveredGold {
        discovery: Discovery
    }

    #[derive(Drop, starknet::Event)]
    struct DiscoveredXP {
        discovery: Discovery
    }

    #[derive(Drop, Serde)]
    struct ObstacleEvent {
        adventurer_state: AdventurerState,
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
    struct NewItemsAvailable {
        adventurer_state: AdventurerState,
        items: Array<u8>,
    }

    #[derive(Drop, starknet::Event)]
    struct IdleDeathPenalty {
        adventurer_state: AdventurerState,
        idle_blocks: u16, // number of blocks adventurer was idle
        penalty_threshold: u16, // idle penalty threshold setting
        caller: ContractAddress // address of caller
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

    #[derive(Drop, starknet::Event)]
    struct RewardDistribution {
        first_place: PlayerReward,
        second_place: PlayerReward,
        third_place: PlayerReward,
        client: ClientReward,
        dao: u256,
    }

    #[derive(Drop, Serde)]
    struct PlayerReward {
        adventurer_id: u256,
        rank: u8,
        amount: u256,
        address: ContractAddress,
    }

    #[derive(Drop, Serde)]
    struct ClientReward {
        amount: u256,
        address: ContractAddress,
    }

    #[inline(always)]
    fn __event_RewardDistribution(ref self: ContractState, event: RewardDistribution) {
        self.emit(Event::RewardDistribution(event));
    }

    #[inline(always)]
    fn __event_AdventurerUpgraded(ref self: ContractState, event: AdventurerUpgraded) {
        self.emit(Event::AdventurerUpgraded(event));
    }
    #[inline(always)]
    fn __event_StartGame(ref self: ContractState, event: StartGame) {
        self.emit(Event::StartGame(event));
    }
    #[inline(always)]
    fn __event_DiscoveredHealth(ref self: ContractState, event: DiscoveredHealth) {
        self.emit(event);
    }
    #[inline(always)]
    fn __event_DiscoveredGold(ref self: ContractState, event: DiscoveredGold) {
        self.emit(Event::DiscoveredGold(event));
    }
    #[inline(always)]
    fn __event_DiscoveredXP(ref self: ContractState, event: DiscoveredXP) {
        self.emit(event);
    }
    #[inline(always)]
    fn __event_DodgedObstacle(ref self: ContractState, event: DodgedObstacle) {
        self.emit(Event::DodgedObstacle(event));
    }
    #[inline(always)]
    fn __event_HitByObstacle(ref self: ContractState, hit_by_obstacle: HitByObstacle) {
        self.emit(Event::HitByObstacle(hit_by_obstacle));
    }
    #[inline(always)]
    fn __event_DiscoveredBeast(ref self: ContractState, discover_beast_event: DiscoveredBeast,) {
        self.emit(Event::DiscoveredBeast(discover_beast_event));
    }
    #[inline(always)]
    fn __event_AttackedBeast(ref self: ContractState, attack_beast: AttackedBeast,) {
        self.emit(Event::AttackedBeast(attack_beast));
    }
    #[inline(always)]
    fn __event_AttackedByBeast(ref self: ContractState, attack_by_beast: AttackedByBeast,) {
        self.emit(Event::AttackedByBeast(attack_by_beast));
    }
    #[inline(always)]
    fn __event_AmbushedByBeast(ref self: ContractState, ambushed_by_beast: AmbushedByBeast,) {
        self.emit(Event::AmbushedByBeast(ambushed_by_beast));
    }
    #[inline(always)]
    fn __event_SlayedBeast(ref self: ContractState, slayed_beast: SlayedBeast,) {
        self.emit(Event::SlayedBeast(slayed_beast));
    }
    #[inline(always)]
    fn __event_FleeFailed(ref self: ContractState, flee_event: FleeFailed) {
        self.emit(Event::FleeFailed(flee_event));
    }
    #[inline(always)]
    fn __event_FleeSucceeded(ref self: ContractState, flee_event: FleeSucceeded) {
        self.emit(Event::FleeSucceeded(flee_event));
    }
    #[inline(always)]
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
    #[inline(always)]
    fn __event_DroppedItems(
        ref self: ContractState,
        adventurer_state_with_bag: AdventurerStateWithBag,
        item_ids: Array<u8>,
    ) {
        self.emit(Event::DroppedItems(DroppedItems { adventurer_state_with_bag, item_ids }));
    }
    #[inline(always)]
    fn __event_ItemsLeveledUp(
        ref self: ContractState, adventurer_state: AdventurerState, items: Array<ItemLeveledUp>,
    ) {
        self.emit(Event::ItemsLeveledUp(ItemsLeveledUp { adventurer_state, items }));
    }
    #[inline(always)]
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
    #[inline(always)]
    fn __event_NewHighScore(ref self: ContractState, adventurer_state: AdventurerState, rank: u8) {
        self.emit(Event::NewHighScore(NewHighScore { adventurer_state, rank }));
    }
    #[inline(always)]
    fn __event_AdventurerDied(ref self: ContractState, adventurer_died_event: AdventurerDied) {
        self.emit(Event::AdventurerDied(adventurer_died_event));
    }
    #[inline(always)]
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
    #[inline(always)]
    fn __event_NewItemsAvailable(
        ref self: ContractState, adventurer_state: AdventurerState, items: Array<u8>,
    ) {
        self.emit(Event::NewItemsAvailable(NewItemsAvailable { adventurer_state, items }));
    }
    #[inline(always)]
    fn __event_IdleDeathPenalty(ref self: ContractState, idle_death_penalty: IdleDeathPenalty) {
        self.emit(Event::IdleDeathPenalty(idle_death_penalty));
    }
    #[inline(always)]
    fn __event_UpgradeAvailable(ref self: ContractState, adventurer_state: AdventurerState) {
        self.emit(Event::UpgradeAvailable(UpgradeAvailable { adventurer_state }));
    }
    #[inline(always)]
    fn __event_PurchasedItems(ref self: ContractState, purchased_items: PurchasedItems) {
        self.emit(Event::PurchasedItems(purchased_items));
    }
    #[inline(always)]
    fn __event_PurchasedPotions(ref self: ContractState, purchased_potions: PurchasedPotions) {
        self.emit(Event::PurchasedPotions(purchased_potions));
    }

    #[starknet::interface]
    trait ILeetLoot<T> {
        fn mint(
            ref self: T, to: ContractAddress, beast: u8, prefix: u8, suffix: u8, level: felt252
        );
        fn isMinted(ref self: T, beast: u8, prefix: u8, suffix: u8) -> bool;
    }
}
