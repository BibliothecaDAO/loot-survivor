use core::array::SpanTrait;
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
    adventurer_stats::Stats
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
    ) -> (u256, u8) {
        let mut hash_span = ArrayTrait::new();
        hash_span.append(adventurer_id.try_into().unwrap());
        hash_span.append(adventurer_entropy.into());
        hash_span.append(xp.into());
        hash_span.append(stats_points_available.into());
        AdventurerUtils::split_hash_into_seed_and_offset(poseidon_hash_span(hash_span.span()))
    }

    // @notice This function takes in a Poseidon hash and splits it into a seed and offset.
    //
    // @dev The split is performed by shifting the hash and dividing it into two segments. The
    // function returns a tuple of a 256-bit unsigned integer and an 8-bit unsigned integer.
    //
    // @param poseidon_hash A 252-bit field element of a Poseidon hash.
    //
    // @return A tuple where the first element is a 256-bit unsigned integer that represents the
    // market seed and the second element is an 8-bit unsigned integer that represents the market offset.
    // The offset value has 1 added to it before it is returned.
    //
    // @example split_hash_into_seed_and_offset(poseidonHash)
    fn split_hash_into_seed_and_offset(poseidon_hash: felt252) -> (u256, u8) {
        // split hash into two u128s, one for market seed, one for offset
        let (market_seed, offset) = rshift_split(poseidon_hash.into(), NUM_ITEMS.into() - 1);

        // return market seed and market offset
        (market_seed, 1 + offset.try_into().unwrap())
    }
}

#[test]
#[available_gas(9999999999999999999)]
fn test_generate_advetnurer_entropy() {
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
#[available_gas(50000000)]
fn test_get_market_seed_and_offset() {
    // verify adventurers minted during the same block have different entropy
    let mut i: u128 = 1;
    loop {
        if (i >= 100) {
            break;
        }
        let adventurer_id: u256 = 1;
        let block_number = 839152;
        let xp: u16 = 3;
        let stats_points_available: u8 = 4;
        let adventurer_entropy = AdventurerUtils::generate_adventurer_entropy(
            block_number, adventurer_id
        );

        let (market_seed, market_offset) = AdventurerUtils::get_market_seed_and_offset(
            adventurer_id, adventurer_entropy, xp, stats_points_available
        );

        // assert market offset is within range of items
        assert(market_offset > 0 && market_offset < NUM_ITEMS, 'offset out of bounds');
        i += 1;
    };
}

#[test]
#[available_gas(30000000)]
fn test_split_hash_into_seed_and_offset() {
    // iterate over low range of u128 starting at 0
    let mut i: u128 = 0;
    loop {
        let poseidon_hash: felt252 = i.into();
        let (market_seed, market_offset) = AdventurerUtils::split_hash_into_seed_and_offset(
            poseidon_hash
        );
        if (i >= 102) {
            break;
        }

        // assert market offset is within range of items
        assert(market_offset > 0 && market_offset < NUM_ITEMS, 'offset out of bounds');
        i += 1;
    };

    // iterate over upper bound up to max u128
    let mut i: u128 = 340282366920938463463374607431768211100;
    loop {
        let poseidon_hash: felt252 = i.into();
        let (market_seed, market_offset) = AdventurerUtils::split_hash_into_seed_and_offset(
            poseidon_hash
        );
        if (i >= 340282366920938463463374607431768211455) {
            break;
        }

        // assert market offset is within range of items
        assert(market_offset > 0 && market_offset < NUM_ITEMS, 'offset out of bounds');
        i += 1;
    };
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
