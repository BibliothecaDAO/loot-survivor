use core::{
    array::{ArrayTrait, SpanTrait},
    integer::{u8_overflowing_add, u16_overflowing_add, u256_try_as_non_zero}, option::OptionTrait,
    poseidon::poseidon_hash_span, result::ResultTrait, traits::{TryInto, Into}
};
use super::{
    constants::{
        adventurer_constants::{
            U128_MAX, STARTING_HEALTH, HEALTH_INCREASE_PER_VITALITY, MAX_ADVENTURER_HEALTH
        },
        discovery_constants::DiscoveryEnums::{ExploreResult, DiscoveryType}
    },
    stats::Stats, adventurer::{Adventurer, ImplAdventurer, IAdventurer},
};
use loot::constants::{
    NUM_ITEMS,
    ItemSuffix::{
        of_Power, of_Giant, of_Titans, of_Skill, of_Perfection, of_Brilliance, of_Enlightenment,
        of_Protection, of_Anger, of_Rage, of_Fury, of_Vitriol, of_the_Fox, of_Detection,
        of_Reflection, of_the_Twins
    }
};
use combat::constants::CombatEnums::{Type, Tier, Slot};

#[generate_trait]
impl AdventurerUtils of IAdventurerUtils {
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
    fn get_random_attack_location(entropy: felt252) -> Slot {
        let slots: u256 = 5;

        // project entropy into 0-4 range
        let (_, rnd_slot) = integer::U256DivRem::div_rem(entropy.into(), slots.try_into().unwrap());

        // return disinct slot for each outcome
        if (rnd_slot == 0) {
            Slot::Chest(())
        } else if (rnd_slot == 1) {
            Slot::Head(())
        } else if (rnd_slot == 2) {
            Slot::Waist(())
        } else if (rnd_slot == 3) {
            Slot::Foot(())
        } else if (rnd_slot == 4) {
            Slot::Hand(())
        } else {
            panic_with_felt252('slot out of range')
        }
    }

    // @notice gets vitality item boost
    // @param suffix: suffix of item
    // @return u8: vitality item boost
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
    // @param vitality: adventurer's vitality
    // @return The maximum health as a u16. If the total health would exceed the maximum possible health, 
    //         then this value is capped to MAX_ADVENTURER_HEALTH.
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

    // @notice checks if adventurer's health is full
    // @param health: adventurer's health
    // @param vitality: adventurer's vitality
    // @return bool: true if health is full, false otherwise
    #[inline(always)]
    fn is_health_full(health: u16, vitality: u8) -> bool {
        health == AdventurerUtils::get_max_health(vitality)
    }

    // @notice gets randomness for adventurer
    // @param adventurer_xp: adventurer xp
    // @param adventurer_entropy: adventurer entropy
    // @return (u128, u128): tuple of randomness
    fn get_randomness(adventurer_xp: u16, adventurer_entropy: felt252) -> (u128, u128) {
        let mut hash_span = ArrayTrait::<felt252>::new();
        hash_span.append(adventurer_xp.into());
        hash_span.append(adventurer_entropy);
        let poseidon = poseidon_hash_span(hash_span.span());
        AdventurerUtils::split_hash(poseidon)
    }

    /// @title get_battle_randomness
    /// @notice gets randomness for adventurer for use during battles
    /// @dev this function increments battle action count so each battle action has unique randomness
    /// @param adventurer_entropy: adventurer entropy
    /// @return (u128, u128): tuple of randomness
    fn get_battle_randomness(ref self: Adventurer, adventurer_entropy: felt252) -> (u128, u128) {
        let mut hash_span = ArrayTrait::<felt252>::new();
        hash_span.append(self.xp.into());
        hash_span.append(self.battle_action_count.into());
        hash_span.append(adventurer_entropy);

        // increment battle action count so each battle action has unique randomness
        if (u8_overflowing_add(self.battle_action_count, 1).is_ok()) {
            self.battle_action_count += 1;
        } else {
            // @dev if we overflow, reset battle action count back to 0
            self.battle_action_count = 0;
        }

        let poseidon = poseidon_hash_span(hash_span.span());
        AdventurerUtils::split_hash(poseidon)
    }

    // @notice splits hash into two u128s
    // @param felt_to_split: felt to split
    // @return (u128, u128): tuple of u128s
    fn split_hash(felt_to_split: felt252) -> (u128, u128) {
        let (d, r) = integer::U256DivRem::div_rem(
            felt_to_split.into(), u256_try_as_non_zero(U128_MAX.into()).unwrap()
        );
        (r.try_into().unwrap(), d.try_into().unwrap())
    }

    // @notice generates starting stats for adventurer
    // @param entropy: entropy for generating starting stats
    // @param starting_stat_count: number of starting stats to generate
    // @return Stats: starting stats
    fn generate_starting_stats(entropy: u256, starting_stat_count: u8) -> Stats {
        let mut starting_stats = Stats {
            strength: 0,
            dexterity: 0,
            vitality: 0,
            charisma: 0,
            intelligence: 0,
            wisdom: 0,
            luck: 0,
        };

        let random_outcomes = AdventurerUtils::u256_to_u8_array(entropy);

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

    // @notice converts u256 to u8 array
    // @param value: value to convert
    // @return Array<u8>: u8 array
    fn u256_to_u8_array(value: u256) -> Array<u8> {
        let mut result = ArrayTrait::<u8>::new();
        result.append((value & MASK_8).try_into().unwrap());
        result.append(((value / TWO_POW_8) & MASK_8).try_into().unwrap());
        result.append(((value / TWO_POW_16) & MASK_8).try_into().unwrap());
        result.append(((value / TWO_POW_24) & MASK_8).try_into().unwrap());
        result.append(((value / TWO_POW_32) & MASK_8).try_into().unwrap());
        result.append(((value / TWO_POW_40) & MASK_8).try_into().unwrap());
        result.append(((value / TWO_POW_48) & MASK_8).try_into().unwrap());
        result.append(((value / TWO_POW_56) & MASK_8).try_into().unwrap());
        result.append(((value / TWO_POW_64) & MASK_8).try_into().unwrap());
        result.append(((value / TWO_POW_72) & MASK_8).try_into().unwrap());
        result.append(((value / TWO_POW_80) & MASK_8).try_into().unwrap());
        result.append(((value / TWO_POW_88) & MASK_8).try_into().unwrap());
        result.append(((value / TWO_POW_96) & MASK_8).try_into().unwrap());
        result.append(((value / TWO_POW_104) & MASK_8).try_into().unwrap());
        result.append(((value / TWO_POW_112) & MASK_8).try_into().unwrap());
        result.append(((value / TWO_POW_120) & MASK_8).try_into().unwrap());
        result
    }
}
const MASK_8: u256 = 0xFF;
const TWO_POW_8: u256 = 0x100;
const TWO_POW_16: u256 = 0x10000;
const TWO_POW_24: u256 = 0x1000000;
const TWO_POW_32: u256 = 0x100000000;
const TWO_POW_40: u256 = 0x10000000000;
const TWO_POW_48: u256 = 0x1000000000000;
const TWO_POW_56: u256 = 0x100000000000000;
const TWO_POW_64: u256 = 0x10000000000000000;
const TWO_POW_72: u256 = 0x1000000000000000000;
const TWO_POW_80: u256 = 0x100000000000000000000;
const TWO_POW_88: u256 = 0x10000000000000000000000;
const TWO_POW_96: u256 = 0x1000000000000000000000000;
const TWO_POW_104: u256 = 0x100000000000000000000000000;
const TWO_POW_112: u256 = 0x10000000000000000000000000000;
const TWO_POW_120: u256 = 0x1000000000000000000000000000000;

// ---------------------------
// ---------- Tests ----------
// ---------------------------
#[cfg(test)]
mod tests {
    use debug::PrintTrait;
    use poseidon::poseidon_hash_span;
    use adventurer::{
        constants::{
            adventurer_constants::{
                U128_MAX, STARTING_HEALTH, HEALTH_INCREASE_PER_VITALITY, MAX_ADVENTURER_HEALTH
            },
            discovery_constants::DiscoveryEnums::{ExploreResult, DiscoveryType}
        },
        stats::Stats, adventurer::{Adventurer, ImplAdventurer, IAdventurer},
        adventurer_utils::AdventurerUtils
    };
    use combat::constants::CombatEnums::{Type, Tier, Slot};
    use loot::{constants::{ItemId}};

    #[test]
    #[available_gas(286398)]
    fn test_generate_starting_stats_gas() {
        AdventurerUtils::generate_starting_stats(0, 1);
    }

    #[test]
    #[available_gas(244018)]
    #[should_panic(expected: ('stat count out of bounds',))]
    fn test_generate_starting_stats_fail_out_of_bounds() {
        AdventurerUtils::generate_starting_stats(0, 20);
    }

    #[test]
    #[available_gas(2020662)]
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
        let stats = AdventurerUtils::generate_starting_stats(poseidon.into(), starting_stat_count);
        let stat_count = stats.strength
            + stats.dexterity
            + stats.vitality
            + stats.intelligence
            + stats.wisdom
            + stats.charisma;
        assert(stat_count == starting_stat_count, 'wrong stat total');
        assert(stats.strength == 2, 'strength should be 2');
        assert(stats.dexterity == 3, 'dexterity should be 3');
        assert(stats.vitality == 1, 'vitality should be 1');
        assert(stats.intelligence == 0, 'intelligence should be 0');
        assert(stats.wisdom == 1, 'wisdom should be 1');
        assert(stats.charisma == 2, 'charisma should be 2');

        let stats = AdventurerUtils::generate_starting_stats(
            poseidon.into(), starting_stat_count + 5
        );
        let stat_count = stats.strength
            + stats.dexterity
            + stats.vitality
            + stats.intelligence
            + stats.wisdom
            + stats.charisma;
        assert(stat_count == starting_stat_count + 5, 'wrong stat total');
        assert(stats.strength == 2, 'strength should be 2');
        assert(stats.dexterity == 3, 'dexterity should be 3');
        assert(stats.vitality == 2, 'vitality should be 2');
        assert(stats.intelligence == 2, 'intelligence should be 2');
        assert(stats.wisdom == 2, 'wisdom should be 2');
        assert(stats.charisma == 3, 'charisma should be 3');
    }

    #[test]
    #[available_gas(1448412)]
    fn test_u128_to_u8_array() {
        // zero case
        let value = 0;
        let values = AdventurerUtils::u256_to_u8_array(value);
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
        let values = AdventurerUtils::u256_to_u8_array(value);
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

        let values = AdventurerUtils::u256_to_u8_array(value);
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
    #[available_gas(259644)]
    fn test_is_health_full() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);

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
    #[available_gas(205004)]
    fn test_get_max_health() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);

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
    #[available_gas(163120)]
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

    #[test]
    fn test_get_battle_randomness() {
        // Test case 1: Basic functionality
        let entropy = 1;
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        assert(adventurer.battle_action_count == 0, 'Battle action should start at 0');
        let (rand1, rand2) = AdventurerUtils::get_battle_randomness(ref adventurer, entropy);
        assert(adventurer.battle_action_count == 1, 'Battle action should increment');
        assert(rand1 != 0 && rand2 != 0, 'Randomness should not be zero');

        // Test case 2: Different entropy produces different results
        let entropy2 = 2;
        let (rand3, rand4) = AdventurerUtils::get_battle_randomness(ref adventurer, entropy2);
        assert(rand1 != rand3 || rand2 != rand4, 'entropy should affect rnd');

        // Test case 3: XP affects randomness
        adventurer.xp = 0;
        adventurer.battle_action_count = 0;
        let (rand7, rand8) = AdventurerUtils::get_battle_randomness(ref adventurer, entropy);
        adventurer.xp = 1;
        adventurer.battle_action_count = 0;
        let (rand9, rand10) = AdventurerUtils::get_battle_randomness(ref adventurer, entropy);
        assert(rand7 != rand9 || rand8 != rand10, 'XP should affect rnd');

        // Test case 4: Battle action count affects randomness
        adventurer.battle_action_count = 0;
        let (rand11, rand12) = AdventurerUtils::get_battle_randomness(ref adventurer, entropy);
        adventurer.battle_action_count = 1;
        let (rand13, rand14) = AdventurerUtils::get_battle_randomness(ref adventurer, entropy);
        assert(rand11 != rand13 || rand12 != rand14, 'battle count should affect rnd');

        // Test case 5: Consecutive calls produce different results
        let (rand15, rand16) = AdventurerUtils::get_battle_randomness(ref adventurer, entropy);
        let (rand17, rand18) = AdventurerUtils::get_battle_randomness(ref adventurer, entropy);
        assert(rand15 != rand17 || rand16 != rand18, 'rnd should change each call');

        // Test case 6: Battle action count overflow
        adventurer.battle_action_count = 255;
        AdventurerUtils::get_battle_randomness(ref adventurer, entropy);
        assert(adventurer.battle_action_count == 0, 'battle count should overflow');
    }
}
