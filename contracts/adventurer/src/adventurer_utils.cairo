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
        discovery_constants::DiscoveryEnums::{ExploreResult, DiscoveryType}
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
use pack::{
    pack::{rshift_split},
    constants::{MASK_16, pow, MASK_8, MASK_3, MASK_BOOL, mask, U128_MASK_8, u128_pow}
};

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
            ExploreResult::Discovery(())
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

    // @notice gets randomness for adventurer
    // @param adventurer_xp: adventurer xp
    // @param adventurer_entropy: adventurer entropy
    // @param global_entropy: global entropy
    // @return (u128, u128): tuple of randomness
    fn get_randomness(
        adventurer_xp: u16, adventurer_entropy: u128, global_entropy: u128
    ) -> (u128, u128) {
        let mut hash_span = ArrayTrait::<felt252>::new();
        hash_span.append(adventurer_xp.into());
        hash_span.append(adventurer_entropy.into());
        hash_span.append(global_entropy.into());
        let poseidon = poseidon_hash_span(hash_span.span());
        AdventurerUtils::split_hash(poseidon)
    }

    // @notice gets randomness for adventurer with health included in entropy
    // @param adventurer_xp: adventurer xp
    // @param adventurer_entropy: adventurer entropy
    // @param adventurer_health: adventurer health
    // @param global_entropy: global entropy
    // @return (u128, u128): tuple of randomness
    fn get_randomness_with_health(
        adventurer_xp: u16, adventurer_health: u16, adventurer_entropy: u128, global_entropy: u128
    ) -> (u128, u128) {
        let mut hash_span = ArrayTrait::<felt252>::new();
        hash_span.append(adventurer_xp.into());
        hash_span.append(adventurer_health.into());
        hash_span.append(adventurer_entropy.into());
        hash_span.append(global_entropy.into());
        let poseidon = poseidon_hash_span(hash_span.span());
        AdventurerUtils::split_hash(poseidon)
    }

    // @notice splits hash into two u128s
    // @param felt_to_split: felt to split
    // @return (u128, u128): tuple of u128s
    fn split_hash(felt_to_split: felt252) -> (u128, u128) {
        let (d, r) = rshift_split(felt_to_split.into(), U128_MAX.into());
        (r.try_into().unwrap(), d.try_into().unwrap())
    }

    fn generate_starting_stats(entropy: u128, starting_stat_count: u8) -> Stats {
        let mut starting_stats = Stats {
            strength: 0,
            dexterity: 0,
            vitality: 0,
            charisma: 0,
            intelligence: 0,
            wisdom: 0,
            luck: 0,
        };

        let random_outcomes = AdventurerUtils::u128_to_u8_array(entropy);

        // TODO: Use conditional compilation to only run this check in debug mode as not to waste gas in production
        assert(starting_stat_count.into() < random_outcomes.len(), 'stat count out of bounds');

        let mut i = 0;
        loop {
            if i == starting_stat_count.into() {
                break;
            }
            let random_u8 = *random_outcomes.at(i);
            let random_stat_index = random_u8 % 6;
            if random_stat_index == 0 {
                starting_stats.strength += 1;
            } else if random_stat_index == 1 {
                starting_stats.dexterity += 1;
            } else if random_stat_index == 2 {
                starting_stats.vitality += 1;
            } else if random_stat_index == 3 {
                starting_stats.charisma += 1;
            } else if random_stat_index == 4 {
                starting_stats.intelligence += 1;
            } else if random_stat_index == 5 {
                starting_stats.wisdom += 1;
            } else {
                panic_with_felt252('stat out of range');
            }

            i += 1;
        };

        starting_stats
    }

    fn u128_to_u8_array(value: u128) -> Array<u8> {
        let mut result = ArrayTrait::<u8>::new();
        result.append((value & U128_MASK_8).try_into().unwrap());
        result.append(((value / u128_pow::_8) & U128_MASK_8).try_into().unwrap());
        result.append(((value / u128_pow::_16) & U128_MASK_8).try_into().unwrap());
        result.append(((value / u128_pow::_24) & U128_MASK_8).try_into().unwrap());
        result.append(((value / u128_pow::_32) & U128_MASK_8).try_into().unwrap());
        result.append(((value / u128_pow::_40) & U128_MASK_8).try_into().unwrap());
        result.append(((value / u128_pow::_48) & U128_MASK_8).try_into().unwrap());
        result.append(((value / u128_pow::_56) & U128_MASK_8).try_into().unwrap());
        result.append(((value / u128_pow::_64) & U128_MASK_8).try_into().unwrap());
        result.append(((value / u128_pow::_72) & U128_MASK_8).try_into().unwrap());
        result.append(((value / u128_pow::_80) & U128_MASK_8).try_into().unwrap());
        result.append(((value / u128_pow::_88) & U128_MASK_8).try_into().unwrap());
        result.append(((value / u128_pow::_96) & U128_MASK_8).try_into().unwrap());
        result.append(((value / u128_pow::_104) & U128_MASK_8).try_into().unwrap());
        result.append(((value / u128_pow::_112) & U128_MASK_8).try_into().unwrap());
        result.append(((value / u128_pow::_120) & U128_MASK_8).try_into().unwrap());
        result
    }
}

// ---------------------------
// ---------- Tests ----------
// ---------------------------
#[cfg(test)]
mod tests {
    use poseidon::poseidon_hash_span;
    use survivor::{
        constants::{
            adventurer_constants::{
                MAX_STAT_VALUE, U128_MAX, ClassStatBoosts, STARTING_HEALTH,
                HEALTH_INCREASE_PER_VITALITY, MAX_ADVENTURER_HEALTH
            },
            discovery_constants::DiscoveryEnums::{ExploreResult, DiscoveryType}
        },
        adventurer_stats::Stats, adventurer::{Adventurer, ImplAdventurer, IAdventurer},
        adventurer_utils::AdventurerUtils
    };
    use combat::constants::CombatEnums::{Type, Tier, Slot};
        #[test]
    #[available_gas(166544)]
    fn test_generate_starting_stats_gas() {
        AdventurerUtils::generate_starting_stats(0, 1);
    }

    #[test]
    #[available_gas(166544)]
    #[should_panic(expected: ('stat count out of bounds',))]
    fn test_generate_starting_stats_fail_out_of_bounds() {
        AdventurerUtils::generate_starting_stats(0, 20);
    }

    #[test]
    #[available_gas(1924040)]
    fn test_generate_starting_stats() {
        let starting_stat_count = 9;

        // zero case
        let entropy = 0;
        let stats = AdventurerUtils::generate_starting_stats(entropy, starting_stat_count);
        let stat_count = stats.strength
            + stats.dexterity
            + stats.vitality
            + stats.intelligence
            + stats.wisdom
            + stats.charisma;
        assert(stat_count == starting_stat_count, 'wrong stat total');
        assert(stats.strength == 9, 'strength should be 9');
        assert(stats.dexterity == 0, 'dexterity should be 0');
        assert(stats.vitality == 0, 'vitality should be 0');
        assert(stats.intelligence == 0, 'intelligence should be 0');
        assert(stats.wisdom == 0, 'wisdom should be 0');
        assert(stats.charisma == 0, 'charisma should be 0');

        // max u128 case
        let entropy = 0xffffffffffffffffffffffffffffffff;
        let stats = AdventurerUtils::generate_starting_stats(entropy, starting_stat_count);
        let stat_count = stats.strength
            + stats.dexterity
            + stats.vitality
            + stats.intelligence
            + stats.wisdom
            + stats.charisma;
        assert(stat_count == starting_stat_count, 'wrong stat total');
        assert(stats.strength == 0, 'strength should be 0');
        assert(stats.dexterity == 0, 'dexterity should be 0');
        assert(stats.vitality == 0, 'vitality should be 0');
        assert(stats.intelligence == 0, 'intelligence should be 0');
        assert(stats.wisdom == 0, 'wisdom should be 0');
        assert(stats.charisma == 9, 'charisma should be 9');

        let mut hash_span = ArrayTrait::new();
        hash_span.append(241);
        hash_span.append(14212);
        let poseidon = poseidon_hash_span(hash_span.span());
        let (rnd1, rnd2) = AdventurerUtils::split_hash(poseidon);
        let stats = AdventurerUtils::generate_starting_stats(rnd1, starting_stat_count);
        let stat_count = stats.strength
            + stats.dexterity
            + stats.vitality
            + stats.intelligence
            + stats.wisdom
            + stats.charisma;
        assert(stat_count == starting_stat_count, 'wrong stat total');
        assert(stats.strength == 1, 'strength should be 1');
        assert(stats.dexterity == 1, 'dexterity should be 1');
        assert(stats.vitality == 2, 'vitality should be 2');
        assert(stats.intelligence == 1, 'intelligence should be 1');
        assert(stats.wisdom == 4, 'wisdom should be 4');
        assert(stats.charisma == 0, 'charisma should be 0');

        let stats = AdventurerUtils::generate_starting_stats(rnd2, starting_stat_count);
        let stat_count = stats.strength
            + stats.dexterity
            + stats.vitality
            + stats.intelligence
            + stats.wisdom
            + stats.charisma;
        assert(stat_count == starting_stat_count, 'wrong stat total');
        assert(stats.strength == 0, 'strength should be 0');
        assert(stats.dexterity == 1, 'dexterity should be 1');
        assert(stats.vitality == 3, 'vitality should be 3');
        assert(stats.intelligence == 4, 'intelligence should be 4');
        assert(stats.wisdom == 1, 'wisdom should be 1');
        assert(stats.charisma == 0, 'charisma should be 0');

        let stats = AdventurerUtils::generate_starting_stats(rnd2, starting_stat_count + 5);
        let stat_count = stats.strength
            + stats.dexterity
            + stats.vitality
            + stats.intelligence
            + stats.wisdom
            + stats.charisma;
        assert(stat_count == starting_stat_count + 5, 'wrong stat total');
        assert(stats.strength == 0, 'strength should be 0');
        assert(stats.dexterity == 3, 'dexterity should be 3');
        assert(stats.vitality == 4, 'vitality should be 4');
        assert(stats.intelligence == 5, 'intelligence should be 5');
        assert(stats.wisdom == 1, 'wisdom should be 1');
        assert(stats.charisma == 1, 'charisma should be 1');
    }

    #[test]
    #[available_gas(1448412)]
    fn test_u128_to_u8_array() {
        // zero case
        let value = 0;
        let values = AdventurerUtils::u128_to_u8_array(value);
        let mut i = 0;
        loop {
            if i == values.len() {
                break;
            }

            let value = *values.at(i);
            assert(value == 0, 'all values should be 0');
            i += 1;
        };

        // max u128 case
        let value = 0xffffffffffffffffffffffffffffffff;
        let values = AdventurerUtils::u128_to_u8_array(value);
        let mut i = 0;
        loop {
            if i == values.len() {
                break;
            }

            let value = *values.at(i);
            assert(value == 255, 'all values should be 1');
            i += 1;
        };

        // random case
        let value =
            0b00000110110100110000110010010111000001000110111100110010001111010010000001111110000110100111101100010101000000001111111101100101;

        let values = AdventurerUtils::u128_to_u8_array(value);
        assert(*values.at(15) == 6, 'rand15 should be 6');
        assert(*values.at(14) == 211, 'rand14 should be 211');
        assert(*values.at(13) == 12, 'rand13 should be 12');
        assert(*values.at(12) == 151, 'rand12 should be 151');
        assert(*values.at(11) == 4, 'rand11 should be 4');
        assert(*values.at(10) == 111, 'rand10 should be 111');
        assert(*values.at(9) == 50, 'rand9 should be 50');
        assert(*values.at(8) == 61, 'rand8 should be 61');
        assert(*values.at(7) == 32, 'rand7 should be 32');
        assert(*values.at(6) == 126, 'rand6 should be 126');
        assert(*values.at(5) == 26, 'rand5 should be 26');
        assert(*values.at(4) == 123, 'rand4 should be 123');
        assert(*values.at(3) == 21, 'rand3 should be 21');
        assert(*values.at(2) == 0, 'rand2 should be 0');
        assert(*values.at(1) == 255, 'rand1 should be 255');
        assert(*values.at(0) == 101, 'rand0 should be 101');
    }

    #[test]
    #[available_gas(259044)]
    fn test_is_health_full() {
        let mut adventurer = ImplAdventurer::new(12, 0, 0, 0);

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
    #[available_gas(204804)]
    fn test_get_max_health() {
        let mut adventurer = ImplAdventurer::new(12, 0, 0, 0);

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
        assert(discovery == ExploreResult::Discovery(()), 'adventurer should find treasure');

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
