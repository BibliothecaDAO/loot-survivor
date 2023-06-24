#[starknet::contract]
mod Game {
    // TESTING CONSTS REMOVE 

    const ENTROPY_BLOCK_TIME: u64 = 100;
    const TEST_ENTROPY: u64 = 12303548;

    use game::game::interfaces::IGame;

    const LOOT_DESCRIPTION_INDEX_1: u256 = 0;
    const LOOT_DESCRIPTION_INDEX_2: u256 = 1;

    use option::OptionTrait;
    use box::BoxTrait;
    use starknet::get_caller_address;
    use starknet::{ContractAddress, ContractAddressIntoFelt252};
    use integer::{
        Felt252TryIntoU64, U8IntoU16, U16IntoU64, U16IntoU128, U64IntoU128, U8IntoU128,
        U128TryIntoU8,
    };
    use integer::U64IntoFelt252;
    use core::traits::{TryInto, Into};

    use game::game::messages::messages;

    use lootitems::loot::{Loot, ImplLoot};
    use lootitems::statistics::constants::{NamePrefixLength, NameSuffixLength};
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
    use survivor::constants::adventurer_constants::{POTION_HEALTH_AMOUNT, ITEM_XP_MULTIPLIER};
    use survivor::item_meta::{
        ImplLootDescription, LootDescription, ILootDescription, LootDescriptionStorage
    };

    use market::market::{ImplMarket};
    use obstacles::obstacle::{ImplObstacle};
    use combat::combat::{CombatSpec, SpecialPowers, ImplCombat};
    use combat::constants::CombatEnums;
    use beasts::beast::{Beast, IBeast, ImplBeast};

    #[storage]
    struct Storage {
        _game_entropy: felt252,
        _last_game_entropy_block: felt252,
        _adventurer: LegacyMap::<u256, felt252>,
        _owner: LegacyMap::<u256, ContractAddress>,
        _adventurer_meta: LegacyMap::<u256, felt252>,
        _loot: LegacyMap::<u256, felt252>,
        _loot_description: LegacyMap::<(u256, u256), felt252>,
        _bag: LegacyMap::<u256, felt252>,
        _counter: u256,
        _lords: ContractAddress,
        _dao: ContractAddress,
        _scoreboard: LegacyMap::<u256, ContractAddress>,
        _scores: LegacyMap::<u256, u256>,
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

        // init the scoreboard with the dao address
        self._scoreboard.write(1, dao);
        self._scoreboard.write(2, dao);
        self._scoreboard.write(3, dao);
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
            // assert caller owns adventurer id
            _assert_ownership(@self, adventurer_id);

            // get adventurer from storage and unpack
            let mut adventurer = _adventurer_unpacked(@self, adventurer_id);

            // assert adventurer does not have stat upgrades available
            _assert_no_stat_upgrades_available(@self, adventurer);

            // pass adventurer ref into internal function
            _explore(ref self, ref adventurer, adventurer_id);
        }
        fn attack(ref self: ContractState, adventurer_id: u256) {
            // assert caller owns adventurer id
            _assert_ownership(@self, adventurer_id);

            // get adventurer from storage and unpack
            let mut adventurer = _adventurer_unpacked(@self, adventurer_id);

            // assert adventurer has a beast to attack
            _assert_in_battle(@self, adventurer);

            // pass adventurer ref into internal function
            _attack(ref self, ref adventurer, adventurer_id);

            // pack and save adventurer
            _pack_adventurer(ref self, adventurer_id, adventurer);
        }
        fn flee(ref self: ContractState, adventurer_id: u256) {
            // check caller owns adventurer id
            _assert_ownership(@self, adventurer_id);

            // get adventurer from storage and unpack
            let mut adventurer = _adventurer_unpacked(@self, adventurer_id);

            // can't flee from start beast
            _assert_not_starter_beast(@self, adventurer);

            // assert adventurer has a beast to attack
            _assert_in_battle(@self, adventurer);

            // pass adventurer ref into internal function
            _flee(ref self, ref adventurer, adventurer_id);

            // pack and save adventurer
            _pack_adventurer(ref self, adventurer_id, adventurer);
        }
        fn equip(ref self: ContractState, adventurer_id: u256, item_id: u8) {
            _assert_ownership(@self, adventurer_id);

            _equip(ref self, adventurer_id, item_id);
        }
        fn buy_item(ref self: ContractState, adventurer_id: u256, item_id: u8, equip: bool) {
            _assert_ownership(@self, adventurer_id);

            _buy_item(ref self, adventurer_id, item_id, equip);
        }
        fn upgrade_stat(ref self: ContractState, adventurer_id: u256, stat: u8) {
            _assert_ownership(@self, adventurer_id);

            _upgrade_stat(ref self, adventurer_id, stat);
        }
        fn purchase_health(ref self: ContractState, adventurer_id: u256) {
            _assert_ownership(@self, adventurer_id);

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

    // _explore is called by the adventurer to explore the world
    // @param self: ContractState
    // @param adventurer: Adventurer
    // @param adventurer_id: u256
    fn _explore(ref self: ContractState, ref adventurer: Adventurer, adventurer_id: u256) {
        // get adventurer entropy from storage  
        let adventurer_entropy = _adventurer_meta_unpacked(@self, adventurer_id).entropy;

        // get global game entropy
        let game_entropy: u64 = _get_entropy(@self).try_into().unwrap();

        // use entropy sources to generate random exploration
        let exploration_entropy = _get_live_entropy(adventurer_entropy, game_entropy, adventurer);

        //
        let explore_result = ImplAdventurer::get_random_explore(exploration_entropy);

        match explore_result {
            ExploreResult::Beast(()) => {
                // get a source of entropy that will be constant for the duration of the battle
                let battle_fixed_entropy: u128 = adventurer
                    .get_battle_fixed_entropy(adventurer_entropy);

                // encounter beast and check if adventurer was ambushed
                let (beast, was_ambushed) = ImplBeast::beast_encounter(
                    adventurer.get_level(),
                    adventurer.wisdom,
                    NamePrefixLength,
                    NameSuffixLength,
                    exploration_entropy
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
                        battle_fixed_entropy
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
                        id: beast.id,
                        level: beast.combat_spec.level,
                        ambushed: was_ambushed,
                        damage_taken: damage_taken,
                        health: beast.starting_health,
                        prefix1: beast.combat_spec.special_powers.prefix1,
                        prefix2: beast.combat_spec.special_powers.prefix2,
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
                _obstacle_encounter(ref self, ref adventurer, adventurer_id, exploration_entropy);
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

        // write the updated adventurer to storage
        _pack_adventurer(ref self, adventurer_id, adventurer);
    }

    fn _beast_discovery(ref self: ContractState, adventurer_id: u256) {}

    fn _obstacle_encounter(
        ref self: ContractState, ref adventurer: Adventurer, adventurer_id: u256, entropy: u128
    ) -> Adventurer {
        // delegate obstacle encounter to obstacle library
        let (obstacle, dodged) = ImplObstacle::obstacle_encounter(
            adventurer.get_level(), adventurer.intelligence, entropy
        );

        // grant xp to equipped items and adventurer regardless of obstacle outcome
        let xp_reward = ImplObstacle::get_xp_reward(obstacle);
        adventurer.increase_adventurer_xp(xp_reward);
        adventurer.increase_item_xp(xp_reward);

        let mut damage_taken: u16 = 0;
        let mut damage_location: u8 = 0;

        // if the obstacle was not dodged
        if (!dodged) {
            // get adventurer armor at the random location the obstacle is dealing damage to
            let damage_slot = ImplAdventurer::get_random_armor_slot(entropy);
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

    fn _attack(
        ref self: ContractState, ref adventurer: Adventurer, adventurer_id: u256
    ) -> Adventurer { //
        // get adventurer entropy from storage  
        let adventurer_entropy = _adventurer_meta_unpacked(@self, adventurer_id).entropy;

        // generate battle fixed entropy by combining adventurer xp and adventurer entropy
        let battle_fixed_entropy: u128 = adventurer.get_battle_fixed_entropy(adventurer_entropy);

        // generate special names for beast using Loot name schema. 
        // We use Loot names because the combat system will deal bonus damage for matching names (these are the items super powers)
        // We do this here instead of in beast to prevent beast from depending on Loot
        let beast_prefix1 = U128TryIntoU8::try_into(
            battle_fixed_entropy % U8IntoU128::into(NamePrefixLength)
        )
            .unwrap();
        let beast_prefix2 = U128TryIntoU8::try_into(
            battle_fixed_entropy % U8IntoU128::into(NameSuffixLength)
        )
            .unwrap();

        // use the randomly generated prefixes but set suffic to 0
        let beast_name_prefix = SpecialPowers {
            prefix1: beast_prefix1, prefix2: beast_prefix2, suffix: 0
        };

        // if the items greatness is below 15, it won't have any special names so no need
        // to waste a read fetching them
        let weapon = adventurer.get_item_at_slot(CombatEnums::Slot::Weapon(()));
        let weapon_combat_spec = _get_combat_spec(@self, adventurer_id, weapon);

        // get battle fixed beast. The key to this is using battle fixed entropy
        let adventurer_level = adventurer.get_level();
        let beast = ImplBeast::get_beast(adventurer_level, beast_name_prefix, battle_fixed_entropy);
        if (adventurer.get_level() == 1) {
            let beast = ImplBeast::get_starter_beast(weapon_combat_spec.item_type);
        }

        // get game entropy from storage
        let game_entropy: u64 = _get_entropy(@self).try_into().unwrap();

        // When generating the beast, we need to ensure entropy remains fixed for the battle
        // for attacking however, we should change the entropy during battle so we use adventurer and beast health
        // to accomplish this
        let attack_entropy = U64IntoU128::into(
            game_entropy
                + adventurer_entropy
                + U16IntoU64::into(adventurer.health + adventurer.beast_health)
        );
        let damage_dealt = beast
            .attack(weapon_combat_spec, adventurer.get_luck(), adventurer.strength, attack_entropy);
        // if the amount of damage dealt to beast exceeds its health
        if (damage_dealt >= adventurer.beast_health) {
            // the beast is dead so set health to zero
            adventurer.beast_health = 0;

            // grant equipped items and adventurer xp for the encounter
            let xp_earned = beast.get_xp_reward();
            adventurer.increase_adventurer_xp(xp_earned);
            adventurer.increase_item_xp(xp_earned);

            // grant adventurer gold reward. We use battle fixed entropy
            // to fix this result at the start of the battle, mitigating simulate-and-wait strategies
            let gold_reward = beast.get_gold_reward(battle_fixed_entropy);
            adventurer.increase_gold(gold_reward);

            // emit slayed beast event
            __event__SlayedBeast(
                ref self,
                SlayedBeast {
                    adventurer_state: AdventurerState {
                        owner: get_caller_address(),
                        adventurer_id: adventurer_id,
                        adventurer: adventurer
                    },
                    beast_id: beast.id,
                    prefix_1: beast.combat_spec.special_powers.prefix1,
                    prefix_2: beast.combat_spec.special_powers.prefix2,
                    beast_level: beast.combat_spec.level,
                    beast_health: adventurer.beast_health,
                    damage_dealt: damage_dealt,
                    xp_earned_adventurer: xp_earned,
                    xp_earned_items: xp_earned * ITEM_XP_MULTIPLIER,
                    gold_earned: gold_reward
                }
            );
            return adventurer;
        } else {
            // beast has more health than was dealt so subtract damage dealt
            adventurer.beast_health = adventurer.beast_health - damage_dealt;

            // then handle the beast counter attack

            // start by generating a random attack location
            let attack_location = ImplAdventurer::get_random_armor_slot(attack_entropy);

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
                    beast_id: beast.id,
                    beast_level: beast.combat_spec.level,
                    beast_health: adventurer.beast_health,
                    prefix_1: beast.combat_spec.special_powers.prefix1,
                    prefix_2: beast.combat_spec.special_powers.prefix2,
                    damage_dealt: damage_dealt,
                    damage_taken: damage_taken,
                    damage_location: ImplCombat::slot_to_u8(attack_location),
                }
            );
            return adventurer;
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
            adventurer.health -= damage_taken;
            return damage_taken;
        }
    }

    // @loothero
    fn _flee(
        ref self: ContractState, ref adventurer: Adventurer, adventurer_id: u256
    ) -> Adventurer { // \
        // get adventurer entropy from storage  
        let adventurer_entropy = _adventurer_meta_unpacked(@self, adventurer_id).entropy;

        // get game entropy from storage
        let game_entropy: u64 = _get_entropy(@self).try_into().unwrap();

        // generate live entropy from fixed entropy sources and live adventurer stats
        let flee_entropy = _get_live_entropy(adventurer_entropy, game_entropy, adventurer);

        let fled = ImplBeast::attempt_flee(
            adventurer.get_level(), adventurer.dexterity, flee_entropy
        );

        // our fixed battle entropy which we use to generate same beast during a single battle
        let battle_fixed_entropy: u128 = adventurer.get_battle_fixed_entropy(adventurer_entropy);
        // here we save some compute by not looking up the beast's special names during a failed flee
        // since they won't impact damage
        let beast_name_prefix = SpecialPowers { prefix1: 0, prefix2: 0, suffix: 0 };
        let beast = ImplBeast::get_beast(
            adventurer.get_level(), beast_name_prefix, battle_fixed_entropy
        );
        let mut damage_taken = 0;
        let mut attack_location = 0;
        if (fled) {
            // set beast health to zero to denote adventurer is no longer in battle
            adventurer.beast_health = 0;
        } else {
            // if flee attempt was unsuccessful
            // the beast will counter attack

            // to process the counter attack we'll need
            // the adventurers level

            // process counter attack (adventurer death will be handled as part of counter attack)
            let attack_slot = ImplAdventurer::get_random_armor_slot(flee_entropy);
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
                beast_id: beast.id,
                beast_level: beast.combat_spec.level,
                beast_health: adventurer.beast_health,
                damage_taken: damage_taken,
                damage_location: attack_location,
                fled
            }
        );

        return adventurer;
    }

    // @loaf
    fn _equip(ref self: ContractState, adventurer_id: u256, item_id: u8) {
        let mut adventurer = _adventurer_unpacked(@self, adventurer_id);

        let mut bag = _bag_unpacked(@self, adventurer_id);

        let equipping_item = bag.get_item(item_id);

        // remove item from bag
        bag.remove_item(equipping_item.id);

        // TODO: could be moved to lib
        assert(equipping_item.id > 0, messages::ITEM_NOT_IN_BAG);

        // check what item type exists on adventurer
        // if some exists pluck from adventurer and add to bag
        let mut unequipping_item = LootStatistics { id: 0, xp: 0, metadata: 0 };
        if adventurer.is_slot_free(equipping_item) == false {
            let unequipping_item = adventurer
                .get_item_at_slot(ImplLoot::get_slot(equipping_item.id));
            bag.add_item(unequipping_item);
        }

        // equip item
        adventurer.add_item(equipping_item);

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

        // TODO: Replace with read from state. We could also move all to lib
        let item_tier = ImplLoot::get_tier(item_id);
        let item_price = ImplMarket::get_price(item_tier);

        let charisma_discount_price = adventurer.get_item_cost(item_price);

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

        // get adventurer
        let mut adventurer = _adventurer_unpacked(@self, adventurer_id);

        // assert adventurer has stat upgrade available
        assert(adventurer.stat_upgrade_available > 0, messages::STAT_POINT_NOT_AVAILABLE);

        // add stat to adventuer
        adventurer.add_statistic(stat_id);

        //deduct one from the adventurers available stat upgrades
        adventurer.stat_upgrade_available -= 1;

        // emit stat upgraded event
        __event__StatUpgraded(
            ref self,
            AdventurerState { owner: get_caller_address(), adventurer_id, adventurer: adventurer },
            stat_id
        );

        // pack and save
        _pack_adventurer(ref self, adventurer_id, adventurer);
    }

    fn _purchase_health(ref self: ContractState, adventurer_id: u256) {
        let mut adventurer = _adventurer_unpacked(@self, adventurer_id);

        // check gold balance
        assert(
            adventurer.check_gold(adventurer.get_potion_cost()) == true, messages::NOT_ENOUGH_GOLD
        );

        // calculate cost of potion based on the Adventurers level
        adventurer.deduct_gold(adventurer.get_potion_cost());

        // TODO: We could remove the value from here altogether and have it within the function
        adventurer.add_health(POTION_HEALTH_AMOUNT);

        // emit purchase potion event
        __event_PurchasedPotion(
            ref self,
            AdventurerState { owner: get_caller_address(), adventurer_id, adventurer: adventurer },
            POTION_HEALTH_AMOUNT
        );

        _pack_adventurer(ref self, adventurer_id, adventurer);
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
        adventurer_entropy: u64, game_entropy: u64, adventurer: Adventurer
    ) -> u128 {
        // cast everything to u128 before adding to avoid overflow
        return U64IntoU128::into(adventurer_entropy)
            + U64IntoU128::into(game_entropy)
            + U16IntoU128::into(adventurer.xp)
            + U16IntoU128::into(adventurer.gold)
            + U16IntoU128::into(adventurer.health);
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
    fn _assert_in_battle(self: @ContractState, adventurer: Adventurer) {
        assert(adventurer.beast_health > 0, messages::ATTACK_CALLED_OUTSIDE_BATTLE);
    }
    fn _assert_not_starter_beast(self: @ContractState, adventurer: Adventurer) {
        assert(adventurer.get_level() > 1, messages::CANT_FLEE_STARTER_BEAST);
    }
    fn _assert_no_stat_upgrades_available(self: @ContractState, adventurer: Adventurer) {
        assert(adventurer.stat_upgrade_available == 0, messages::STAT_UPGRADES_AVAILABLE);
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
        // get the greatness of the item
        let item_greatness = ImplLoot::get_greatness_level(item.xp);

        // if it's less than 15, no need to fetch the special names it doesn't have them
        if (item_greatness < 15) {
            return CombatSpec {
                tier: ImplLoot::get_tier(item.id),
                item_type: ImplLoot::get_type(item.id),
                level: U8IntoU16::into(ImplLoot::get_greatness_level(item.xp)),
                special_powers: SpecialPowers {
                    prefix1: 0, prefix2: 0, suffix: 0
                }
            };
        } else {
            // if it's above 15, fetch the special names
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
    }

    fn _set_entropy(ref self: ContractState, entropy: felt252) {
        // TODO: Replace with actual seed
        //starknet::get_tx_info().unbox().transaction_hash.into()

        // let blocknumber: u64 = starknet::get_block_info().unbox().block_number.into();

        // assert(
        //     blocknumber >= (self._last_game_entropy_block.read().try_into().unwrap()
        //         + ENTROPY_BLOCK_TIME.into()),
        //     messages::BLOCK_NUMBER_ERROR
        // );

        self._game_entropy.write(entropy);
    // self._last_game_entropy_block.write(blocknumber.into());
    }

    fn _get_entropy(self: @ContractState) -> u256 {
        self._game_entropy.read().into()
    }

    fn _set_scoreboard(ref self: ContractState, player: ContractAddress, score: u256) {
        let third_place = self._scoreboard.read(3);
        let second_place = self._scoreboard.read(2);
        let first_place = self._scoreboard.read(1);

        if score > self._scores.read(1) {
            self._scoreboard.write(3, second_place);
            self._scoreboard.write(2, first_place);
            self._scoreboard.write(1, player);
            self._scores.write(3, self._scores.read(2));
            self._scores.write(2, self._scores.read(1));
            self._scores.write(1, score);
        } else if score > self._scores.read(2) {
            self._scoreboard.write(3, second_place);
            self._scoreboard.write(2, player);
            self._scores.write(3, self._scores.read(2));
            self._scores.write(2, score);
        } else if score > self._scores.read(3) {
            self._scoreboard.write(3, player);
            self._scores.write(3, score);
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
        id: u8,
        level: u16,
        ambushed: bool,
        damage_taken: u16,
        health: u16,
        prefix1: u8,
        prefix2: u8,
    }

    #[derive(Drop, starknet::Event)]
    struct AttackBeast {
        adventurer_state: AdventurerState,
        beast_id: u8,
        beast_level: u16,
        beast_health: u16,
        prefix_1: u8,
        prefix_2: u8,
        damage_dealt: u16,
        damage_taken: u16,
        damage_location: u8,
    }

    #[derive(Drop, starknet::Event)]
    struct SlayedBeast {
        adventurer_state: AdventurerState,
        beast_id: u8,
        prefix_1: u8,
        prefix_2: u8,
        beast_level: u16,
        beast_health: u16,
        damage_dealt: u16,
        xp_earned_adventurer: u16,
        xp_earned_items: u16,
        gold_earned: u16,
    }

    #[derive(Drop, starknet::Event)]
    struct FleeAttempt {
        adventurer_state: AdventurerState,
        beast_id: u8,
        beast_level: u16,
        beast_health: u16,
        damage_taken: u16,
        damage_location: u8,
        fled: bool,
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
