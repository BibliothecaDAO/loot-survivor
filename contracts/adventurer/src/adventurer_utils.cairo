use core::array::SpanTrait;
use core::{result::ResultTrait, traits::{TryInto, Into}};
use poseidon::poseidon_hash_span;
use option::OptionTrait;
use array::ArrayTrait;
use integer::{u8_overflowing_add, u16_overflowing_add, u16_overflowing_sub, U128IntoU256};
use super::{
    constants::{
        adventurer_constants::{
            MAX_STAT_VALUE, U128_MAX, ClassStatBoosts, STARTING_HEALTH,
            HEALTH_INCREASE_PER_VITALITY, MAX_ADVENTURER_HEALTH
        },
        discovery_constants::DiscoveryEnums::{ExploreResult, TreasureDiscovery}
    },
    adventurer_stats::Stats, adventurer::{Adventurer, ImplAdventurer, IAdventurer},
};
use lootitems::constants::{
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
impl AdventurerUtils of IAdventurerUtils {
    // @dev Provides overflow protected stat increase.
    //      This function protects against u8 overflow but allows stat
    //      to exceed MAX_STAT_VALUE as adventurers live stats are expected
    //      to exceed MAX_STAT_VALUE. Ensuring a stat does not overflow adventurer packing
    //      code is the responsibility of the adventurer packing code
    // @param current_stat The current value of the stat.
    // @param increase_amount The amount by which to increase the stat.
    // @return The increased stat value, or `MAX_STAT_VALUE` if an increase would cause an overflow.
    fn overflow_protected_stat_increase(ref self: u8, amount: u8) {
        // u8 overflow check
        if (u8_overflowing_add(self, amount).is_ok()) {
            self += amount
        } else {
            self = MAX_STAT_VALUE
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

    // TODO: Need to refactor this and apply_suffix_boost to ensure they
    // stay insync. I think the design used for AdventurerClass in adventurer_meta
    // is good. 
    #[inline(always)]
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

    // Returns the maximum health an adventurer can have.
    // The maximum health is the sum of the starting health and the health increase due to the adventurer's vitality.
    //
    // @return The maximum health as a u16. If the total health would exceed the maximum possible health, 
    //         then this value is capped to MAX_ADVENTURER_HEALTH.
    #[inline(always)]
    fn get_max_health(vitality: u8) -> u16 {
        // Calculate vitality boost, casting to u16 to prevent overflow during multiplication
        let vitality_boost: u16 = (vitality.into() * HEALTH_INCREASE_PER_VITALITY.into());

        // Check if health calculation would result in overflow
        if (u16_overflowing_add(STARTING_HEALTH, vitality_boost).is_ok()) {
            // If it does not cause overflow, check if health + vitality boost is within maximum allowed health
            if (STARTING_HEALTH + vitality_boost <= MAX_ADVENTURER_HEALTH) {
                // if it is, return full boost
                return (STARTING_HEALTH + vitality_boost);
            }
        }

        // In the case of potential overflow or exceeding max adventurer health, return max adventurer health
        MAX_ADVENTURER_HEALTH
    }

    #[inline(always)]
    fn is_health_full(health: u16, vitality: u8) -> bool {
        health == AdventurerUtils::get_max_health(vitality)
    }
}

// ---------------------------
// ---------- Tests ----------
// ---------------------------
#[cfg(test)]
mod tests {
    use survivor::{
        constants::{
            adventurer_constants::{
                MAX_STAT_VALUE, U128_MAX, ClassStatBoosts, STARTING_HEALTH,
                HEALTH_INCREASE_PER_VITALITY, MAX_ADVENTURER_HEALTH
            },
            discovery_constants::DiscoveryEnums::{ExploreResult, TreasureDiscovery}
        },
        adventurer_stats::Stats, adventurer::{Adventurer, ImplAdventurer, IAdventurer},
        adventurer_utils::AdventurerUtils
    };
    use combat::constants::CombatEnums::{Type, Tier, Slot};
    #[test]
    #[available_gas(150000)]
    fn test_is_health_full() {
        let starting_stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
        };
        let mut adventurer = ImplAdventurer::new(12, 0, starting_stats);

        // adventurers should start with full health
        assert(
            AdventurerUtils::is_health_full(adventurer.health, adventurer.stats.vitality) == true,
            'should start with full health'
        );

        // increase max health via vitality boost
        // health is no longer technically full
        adventurer.stats.vitality = 2;
        assert(
            AdventurerUtils::is_health_full(adventurer.health, adventurer.stats.vitality) == false,
            'vitality increased max'
        );

        // fill up health
        adventurer.increase_health(100);
        assert(
            AdventurerUtils::is_health_full(adventurer.health, adventurer.stats.vitality) == true,
            'health should be full'
        );

        // deduct 1 health
        adventurer.decrease_health(1);
        assert(
            AdventurerUtils::is_health_full(adventurer.health, adventurer.stats.vitality) == false,
            'health should not be full'
        );
    }

    #[test]
    #[available_gas(200000)]
    fn test_get_max_health() {
        let starting_stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
        };
        let mut adventurer = ImplAdventurer::new(12, 0, starting_stats);

        // assert starting state
        assert(
            AdventurerUtils::get_max_health(adventurer.stats.vitality) == STARTING_HEALTH,
            'advntr should have max health'
        );

        // base case
        adventurer.stats.vitality = 1;
        // assert max health is starting health + single vitality increase
        assert(
            AdventurerUtils::get_max_health(adventurer.stats.vitality) == STARTING_HEALTH
                + HEALTH_INCREASE_PER_VITALITY.into(),
            'max health shuld be 120'
        );

        // extreme/overflow case
        adventurer.stats.vitality = 255;
        assert(
            AdventurerUtils::get_max_health(adventurer.stats.vitality) == MAX_ADVENTURER_HEALTH,
            'wrong max health'
        );
    }


    #[test]
    #[available_gas(6482260)]
    fn test_generate_adventurer_entropy() {
        let mut i: u256 = 1;
        loop {
            if (i >= 100) {
                break;
            }
            let adventurer_id: u256 = i;
            let block_number = 839152;
            let adventurer_entropy = AdventurerUtils::generate_adventurer_entropy(
                block_number, adventurer_id
            );
            i += 1;
        };
    }

    #[test]
    #[available_gas(30000)]
    fn test_overflow_protected_stat_increase() {
        let mut stat: u8 = 1;

        // base case
        AdventurerUtils::overflow_protected_stat_increase(ref stat, 1);
        assert(stat == 2, 'stat should increase by 1');

        // u8 overflow case
        AdventurerUtils::overflow_protected_stat_increase(ref stat, 255);
        assert(stat == MAX_STAT_VALUE, 'stat should not overflow');
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
}
