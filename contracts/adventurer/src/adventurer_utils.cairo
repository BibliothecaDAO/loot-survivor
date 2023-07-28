use core::{result::ResultTrait, traits::{TryInto, Into}};
use poseidon::poseidon_hash_span;
use option::OptionTrait;
use array::ArrayTrait;
use integer::{u8_overflowing_add, u16_overflowing_add, u16_overflowing_sub, U128IntoU256};
use super::{
    constants::{
        adventurer_constants::{MAX_STAT_VALUE, U128_MAX, ClassStatBoosts},
        discovery_constants::DiscoveryEnums::{ExploreResult, TreasureDiscovery}
    },
    adventurer_meta::AdventurerClass, adventurer_stats::Stats
};
use lootitems::statistics::constants::{
    NUM_ITEMS,
    ItemSuffix::{
        of_Power, of_Giant, of_Titans, of_Skill, of_Perfection, of_Brilliance, of_Enlightenment,
        of_Protection, of_Anger, of_Rage, of_Fury, of_Vitriol, of_the_Fox, of_Detection,
        of_Reflection, of_the_Twins
    }
};
use combat::constants::CombatEnums::{Type, Tier, Slot};
use pack::pack::{rshift_split};

#[generate_trait]
impl AdventurerUtils of IAdventurer {
    // @dev Provides overflow protected stat increase.
    //      This function protects against u8 overflow but allows stat
    //      to exceed MAX_STAT_VALUE as adventurers live stats are expected
    //      to exceed MAX_STAT_VALUE. Ensuring a stat does not overflow adventurer packing
    //      code is the responsibility of the adventurer packing code
    // @param current_stat The current value of the stat.
    // @param increase_amount The amount by which to increase the stat.
    // @return The increased stat value, or `MAX_STAT_VALUE` if an increase would cause an overflow.
    fn overflow_protected_stat_increase(current_stat: u8, increase_amount: u8) -> u8 {
        // u8 overflow check
        if (u8_overflowing_add(current_stat, increase_amount).is_ok()) {
            current_stat + increase_amount
        } else {
            MAX_STAT_VALUE
        }
    }

    // get_random_explore returns a random number between 0 and 3 based on provided entropy
    // @param entropy: entropy for generating random explore
    // @return u64: A random number between 0 and 3 denoting the outcome of the explore
    fn get_random_explore(entropy: u128) -> ExploreResult {
        let result = entropy % 3;
        if (result == 0) {
            ExploreResult::Beast(())
        } else if (result == 1) {
            ExploreResult::Obstacle(())
        } else {
            ExploreResult::Treasure(())
        }
    }

    // @notice Determines a random attack location based on the provided entropy
    // @param entropy The entropy used to generate a random attack location
    // @return A Slot type which represents the randomly determined attack location
    fn get_random_attack_location(entropy: u128) -> Slot {
        // project entropy into 0-4 range
        let rnd_slot = entropy % 5;

        // return disinct slot for each outcome
        if (rnd_slot == 0) {
            Slot::Chest(())
        } else if (rnd_slot == 1) {
            Slot::Head(())
        } else if (rnd_slot == 2) {
            Slot::Waist(())
        } else if (rnd_slot == 3) {
            Slot::Foot(())
        } else {
            Slot::Hand(())
        }
    }

    // @notice Generates entropy for an adventurer based on a block number and adventurer ID
    // @param block_number The block number used in generating the entropy
    // @param adventurer_id The ID of the adventurer used in generating the entropy
    // @return A u128 type entropy unique to the block number and adventurer ID
    fn generate_adventurer_entropy(block_number: u64, adventurer_id: u256) -> u128 {
        let mut hash_span = ArrayTrait::<felt252>::new();
        hash_span.append(block_number.into());
        hash_span.append(adventurer_id.try_into().unwrap());
        let poseidon: felt252 = poseidon_hash_span(hash_span.span()).into();
        let (d, r) = rshift_split(poseidon.into(), U128_MAX.into());
        r.try_into().unwrap()
    }

    // @notice Generates special entropy for an item based on provided entropy and item ID
    // @param entropy The entropy used to generate the special entropy
    // @param item_id The ID of the item used in generating the special entropy
    // @return A tuple of u128 types which represent the special entropy of the item
    fn generate_item_special_entropy(entropy: u128, item_id: u8) -> (u128, u128) {
        let mut hash_span = ArrayTrait::<felt252>::new();
        hash_span.append(entropy.into());
        hash_span.append(item_id.into());
        let poseidon: felt252 = poseidon_hash_span(hash_span.span()).into();
        let (d, r) = rshift_split(poseidon.into(), U128_MAX.into());
        (r.try_into().unwrap(), d.try_into().unwrap())
    }

    // @notice Retrieves the stats for an adventurer class
    // @param adventurer_class The class of the adventurer to retrieve the stats for
    // @return A Stats object which represents the stats of the given adventurer class
    fn get_class_stats(adventurer_class: AdventurerClass) -> Stats {
        match adventurer_class {
            AdventurerClass::None(()) => {
                Stats {
                    strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0
                }
            },
            AdventurerClass::Cleric(()) => {
                Stats {
                    strength: ClassStatBoosts::Cleric::STRENGTH,
                    dexterity: ClassStatBoosts::Cleric::DEXTERITY,
                    vitality: ClassStatBoosts::Cleric::VITALITY,
                    intelligence: ClassStatBoosts::Cleric::INTELLIGENCE,
                    wisdom: ClassStatBoosts::Cleric::WISDOM,
                    charisma: ClassStatBoosts::Cleric::VITALITY
                }
            },
            AdventurerClass::Scout(()) => {
                Stats {
                    strength: ClassStatBoosts::Scout::STRENGTH,
                    dexterity: ClassStatBoosts::Scout::DEXTERITY,
                    vitality: ClassStatBoosts::Scout::VITALITY,
                    intelligence: ClassStatBoosts::Scout::INTELLIGENCE,
                    wisdom: ClassStatBoosts::Scout::WISDOM,
                    charisma: ClassStatBoosts::Scout::VITALITY
                }
            },
            AdventurerClass::Hunter(()) => {
                Stats {
                    strength: ClassStatBoosts::Hunter::STRENGTH,
                    dexterity: ClassStatBoosts::Hunter::DEXTERITY,
                    vitality: ClassStatBoosts::Hunter::VITALITY,
                    intelligence: ClassStatBoosts::Hunter::INTELLIGENCE,
                    wisdom: ClassStatBoosts::Hunter::WISDOM,
                    charisma: ClassStatBoosts::Hunter::VITALITY
                }
            },
            AdventurerClass::Warrior(()) => {
                Stats {
                    strength: ClassStatBoosts::Warrior::STRENGTH,
                    dexterity: ClassStatBoosts::Warrior::DEXTERITY,
                    vitality: ClassStatBoosts::Warrior::VITALITY,
                    intelligence: ClassStatBoosts::Warrior::INTELLIGENCE,
                    wisdom: ClassStatBoosts::Warrior::WISDOM,
                    charisma: ClassStatBoosts::Warrior::VITALITY
                }
            },
        }
    }

    // TODO: Need to refactor this and add_suffix_boost to ensure they
    // stay insync. I think the design used for AdventurerClass in adventurer_meta
    // is good. 
    fn get_vitality_item_boost(suffix: u8) -> u8 {
        if (suffix == of_Power) {
            0
        } else if (suffix == of_Giant) {
            3
        } else if (suffix == of_Titans) {
            0
        } else if (suffix == of_Skill) {
            0
        } else if (suffix == of_Perfection) {
            1
        } else if (suffix == of_Brilliance) {
            0
        } else if (suffix == of_Enlightenment) {
            0
        } else if (suffix == of_Protection) {
            2
        } else if (suffix == of_Anger) {
            0
        } else if (suffix == of_Rage) {
            0
        } else if (suffix == of_Fury) {
            1
        } else if (suffix == of_Vitriol) {
            0
        } else if (suffix == of_the_Fox) {
            0
        } else if (suffix == of_Detection) {
            0
        } else if (suffix == of_Reflection) {
            0
        } else if (suffix == of_the_Twins) {
            0
        } else {
            0
        }
    }

    // @dev Function to generate a unique hash for the market based on the adventurer's id, entropy, xp and stat points available.
    // @param adventurer_id The unique identifier for the adventurer.
    // @param adventurer_entropy The entropy of the adventurer used for randomness.
    // @param xp The experience points of the adventurer.
    // @param stats_points_available The available stat points that can be used for upgrades.
    // @return A unique hash in the form of a 128-bit unsigned integer.
    fn get_market_seed_and_offset(
        adventurer_id: u256, adventurer_entropy: u128, xp: u16, stats_points_available: u8
    ) -> (u128, u8) {
        let mut hash_span = ArrayTrait::new();
        hash_span.append(adventurer_id.try_into().unwrap());
        hash_span.append(adventurer_entropy.into());
        hash_span.append(xp.into());
        hash_span.append(stats_points_available.into());
        AdventurerUtils::split_hash_into_seed_and_offset(poseidon_hash_span(hash_span.span()))
    }

    fn split_hash_into_seed_and_offset(poseidon_hash: felt252) -> (u128, u8) {
        let (market_offset, market_seed) = rshift_split(
            poseidon_hash.into(), 170141183460469231731687303715884105727
        );
        (
            market_seed.try_into().unwrap(),
            (1 + (market_offset % NUM_ITEMS.into()).try_into().unwrap())
        )
    }
}

#[test]
#[available_gas(500000)]
fn test_get_market_seed_and_offset() {
    // test get_market_seed_and_offset function
    let adventurer_id: u256 = 1;
    let adventurer_entropy: u128 = 2;
    let xp: u16 = 3;
    let stats_points_available: u8 = 4;
    let (market_seed, market_offset) = AdventurerUtils::get_market_seed_and_offset(
        adventurer_id, adventurer_entropy, xp, stats_points_available
    );
    assert(market_seed == 8653894592905011222407811648701776700, 'wrong seed');
    assert(market_offset == 74, 'wrong offset');

    let stats_points_available: u8 = 3;
    let (market_seed, market_offset) = AdventurerUtils::get_market_seed_and_offset(
        adventurer_id, adventurer_entropy, xp, stats_points_available
    );
    assert(market_seed == 88279057010784366245946951591011804619, 'wrong seed');
    assert(market_offset == 73, 'wrong offset');

    let stats_points_available: u8 = 2;
    let (market_seed, market_offset) = AdventurerUtils::get_market_seed_and_offset(
        adventurer_id, adventurer_entropy, xp, stats_points_available
    );
    assert(market_seed == 149615908700113160033263432132807492851, 'wrong seed');
    assert(market_offset == 82, 'wrong offset');

    let stats_points_available: u8 = 1;
    let (market_seed, market_offset) = AdventurerUtils::get_market_seed_and_offset(
        adventurer_id, adventurer_entropy, xp, stats_points_available
    );
    assert(market_seed == 50575806029835951894834837822879558346, 'wrong seed');
    assert(market_offset == 36, 'wrong offset');
}

#[test]
#[available_gas(500000)]
fn test_split_hash_into_seed_and_offset() {
    // test the split_hash_into_seed_and_offset function
    let poseidon_hash: felt252 = 170141183460469231731687303715884105727.into();
    let (market_seed, market_offset) = AdventurerUtils::split_hash_into_seed_and_offset(
        poseidon_hash
    );
    assert(market_seed == 0, 'market seed should be 0');
    assert(market_offset == 2, 'market offset should be 2');

    let poseidon_hash: felt252 = 170141183460469231731687303715884105728.into();
    let (market_seed, market_offset) = AdventurerUtils::split_hash_into_seed_and_offset(
        poseidon_hash
    );
    assert(market_seed == 1, 'market seed should be 1');
    assert(market_offset == 2, 'market offset should be 2');

    let poseidon_hash: felt252 = 170141103715884105728.into();
    let (market_seed, market_offset) = AdventurerUtils::split_hash_into_seed_and_offset(
        poseidon_hash
    );
    assert(market_seed == 170141103715884105728, 'wrong market seed');
    assert(market_offset == 1, 'market offset should be 2');

    let poseidon_hash: felt252 = 170141183460469712313168730371588410572712312.into();
    let (market_seed, market_offset) = AdventurerUtils::split_hash_into_seed_and_offset(
        poseidon_hash
    );
    assert(market_seed == 480581481426655704304845712312, 'wrong market seed');
    assert(market_offset == 101, 'market offset should be 2');
}

#[test]
#[available_gas(30000)]
fn test_overflow_protected_stat_increase() {
    // base case
    assert(
        AdventurerUtils::overflow_protected_stat_increase(1, 1) == 2, 'stat should increase by 1'
    );

    // u8 overflow case
    assert(
        AdventurerUtils::overflow_protected_stat_increase(MAX_STAT_VALUE, 255) == MAX_STAT_VALUE,
        'stat should not overflow'
    );
}

#[test]
#[available_gas(40000)]
fn test_get_random_explore() {
    // exploring with zero entropy will result in a beast discovery
    let entropy = 0;
    let discovery = AdventurerUtils::get_random_explore(entropy);
    assert(discovery == ExploreResult::Beast(()), 'adventurer should find beast');

    let entropy = 1;
    let discovery = AdventurerUtils::get_random_explore(entropy);
    assert(discovery == ExploreResult::Obstacle(()), 'adventurer should find obstacle');

    let entropy = 2;
    let discovery = AdventurerUtils::get_random_explore(entropy);
    assert(discovery == ExploreResult::Treasure(()), 'adventurer should find treasure');

    // rollover and verify beast discovery
    let entropy = 3;
    let discovery = AdventurerUtils::get_random_explore(entropy);
    assert(discovery == ExploreResult::Beast(()), 'adventurer should find beast');
}

#[test]
#[available_gas(60000)]
fn test_get_random_attack_location() {
    // base cases
    let mut entropy = 0;
    let mut armor = AdventurerUtils::get_random_attack_location(entropy);
    assert(armor == Slot::Chest(()), 'should be chest');

    entropy = 1;
    armor = AdventurerUtils::get_random_attack_location(entropy);
    assert(armor == Slot::Head(()), 'should be head');

    entropy = 2;
    armor = AdventurerUtils::get_random_attack_location(entropy);
    assert(armor == Slot::Waist(()), 'should be waist');

    entropy = 3;
    armor = AdventurerUtils::get_random_attack_location(entropy);
    assert(armor == Slot::Foot(()), 'should be foot');

    entropy = 4;
    armor = AdventurerUtils::get_random_attack_location(entropy);
    assert(armor == Slot::Hand(()), 'should be hand');

    // rollover and verify armor goes back to chest
    entropy = 5;
    armor = AdventurerUtils::get_random_attack_location(entropy);
    assert(armor == Slot::Chest(()), 'should be chest');
}
