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

    /// @notice checks if adventurer's health is full
    /// @param self: adventurer
    /// @return bool: true if health is full, false otherwise
    #[inline(always)]
    fn is_health_full(self: Adventurer) -> bool {
        self.health == self.stats.get_max_health()
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
    #[available_gas(259644)]
    fn test_is_health_full() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);

        // adventurers should start with full health
        assert(adventurer.is_health_full() == true, 'should start with full health');

        // increase max health via vitality boost
        // health is no longer technically full
        adventurer.stats.vitality = 2;
        assert(adventurer.is_health_full() == false, 'vitality increased max');

        // fill up health
        adventurer.increase_health(100);
        assert(adventurer.is_health_full() == true, 'health should be full');

        // deduct 1 health
        adventurer.decrease_health(1);
        assert(adventurer.is_health_full() == false, 'health should not be full');
    }

    #[test]
    #[available_gas(205004)]
    fn test_get_max_health() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);

        // assert starting state
        assert(
            adventurer.stats.get_max_health() == STARTING_HEALTH, 'advntr should have max health'
        );

        // base case
        adventurer.stats.vitality = 1;
        // assert max health is starting health + single vitality increase
        assert(
            adventurer.stats.get_max_health() == STARTING_HEALTH
                + HEALTH_INCREASE_PER_VITALITY.into(),
            'max health shuld be 120'
        );

        // extreme/overflow case
        adventurer.stats.vitality = 255;
        assert(adventurer.stats.get_max_health() == MAX_ADVENTURER_HEALTH, 'wrong max health');
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
