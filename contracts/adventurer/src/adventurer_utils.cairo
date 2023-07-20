use core::{result::ResultTrait, traits::{TryInto, Into}};
use integer::{u8_overflowing_add, u16_overflowing_add, u16_overflowing_sub, U128IntoU256};
use super::constants::{
    adventurer_constants::{MAX_STAT_VALUE, U128_MAX},
    discovery_constants::DiscoveryEnums::{ExploreResult, TreasureDiscovery}
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
            return ExploreResult::Beast(());
        } else if (result == 1) {
            return ExploreResult::Obstacle(());
        } else {
            return ExploreResult::Treasure(());
        }
    }

    fn get_random_attack_location(entropy: u128) -> Slot {
        // project entropy into 0-4 range
        let rnd_slot = entropy % 5;

        // return disinct slot for each outcome
        if (rnd_slot == 0) {
            return Slot::Chest(());
        } else if (rnd_slot == 1) {
            return Slot::Head(());
        } else if (rnd_slot == 2) {
            return Slot::Waist(());
        } else if (rnd_slot == 3) {
            return Slot::Foot(());
        } else {
            return Slot::Hand(());
        }
    }

    fn generate_adventurer_entropy(block_number: u64, adventurer_id: u256) -> u128 {
        let mut hash_span = ArrayTrait::<felt252>::new();
        hash_span.append(block_number.into());
        hash_span.append(adventurer_id.try_into().unwrap());
        let poseidon: felt252 = poseidon_hash_span(hash_span.span()).into();
        let (d, r) = rshift_split(poseidon.into(), U128_MAX.into());
        r.try_into().unwrap()
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
