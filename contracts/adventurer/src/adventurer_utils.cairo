use core::result::ResultTrait;
use integer::{u8_overflowing_add, u16_overflowing_add, u16_overflowing_sub};
use super::constants::{
    adventurer_constants::{MAX_STAT_VALUE},
    discovery_constants::DiscoveryEnums::{ExploreResult, TreasureDiscovery}
};
use combat::constants::CombatEnums::{Type, Tier, Slot};

#[generate_trait]
impl AdventurerUtils of IAdventurer {
    fn overflow_protected_stat_increase(current_stat: u8, increase_amount: u8) -> u8 {
        // u8 overflow check
        if (u8_overflowing_add(current_stat, increase_amount).is_ok()) {
            // if the strength plus the amount is less than or equal to the max stat value
            if (current_stat + increase_amount <= MAX_STAT_VALUE) {
                // add the amount to the strength
                return current_stat + increase_amount;
            }
        }

        // otherwise set the strength to the max stat value
        // this will happen either in u8 overflow case
        // or if the strength plus the amount is greater than the max stat value
        MAX_STAT_VALUE
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
}

#[test]
#[available_gas(30000)]
fn test_overflow_protected_stat_increase() {
    // base case
    assert(AdventurerUtils::overflow_protected_stat_increase(1, 1) == 2, 'stat should increase by 1');

    // max stat value case
    assert(AdventurerUtils::overflow_protected_stat_increase(MAX_STAT_VALUE, 1) == MAX_STAT_VALUE, 'stat should not increase');

    // u8 overflow case
    assert(AdventurerUtils::overflow_protected_stat_increase(MAX_STAT_VALUE, 255) == MAX_STAT_VALUE, 'stat should not overflow');
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
