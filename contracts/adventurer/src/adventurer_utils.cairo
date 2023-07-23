use core::{result::ResultTrait, traits::{TryInto, Into}};
use integer::{u8_overflowing_add, u16_overflowing_add, u16_overflowing_sub, U128IntoU256};
use super::{
    constants::{
        adventurer_constants::{MAX_STAT_VALUE, U128_MAX, ClassStatBoosts},
        discovery_constants::DiscoveryEnums::{ExploreResult, TreasureDiscovery}
    },
    adventurer_meta::AdventurerClass,
    adventurer_stats::Stats
};
use combat::constants::CombatEnums::{Type, Tier, Slot};
use poseidon::poseidon_hash_span;
use option::OptionTrait;
use array::ArrayTrait;
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
                    strength: 0,
                    dexterity: 0,
                    vitality: 0,
                    intelligence: 0,
                    wisdom: 0,
                    charisma: 0
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
