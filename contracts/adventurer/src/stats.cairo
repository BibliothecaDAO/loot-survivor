use core::integer::u8_overflowing_add;
use core::{option::OptionTrait, starknet::{StorePacking}, traits::{TryInto, Into}};
use loot::constants::ItemSuffix;

const MAX_STAT_VALUE: u8 = 31;

#[derive(Drop, Copy, Serde, PartialEq)]
struct Stats { // 30 bits total
    strength: u8,
    dexterity: u8,
    vitality: u8, // 5 bits per stat
    intelligence: u8,
    wisdom: u8,
    charisma: u8,
    luck: u8 // dynamically generated, not stored.
}

impl StatsPacking of StorePacking<Stats, felt252> {
    /// @notice packs the stats into a felt252
    /// @param value the Stats to pack
    /// @return the packed Stats
    fn pack(value: Stats) -> felt252 {
        assert(value.strength <= MAX_STAT_VALUE, 'strength pack overflow');
        assert(value.dexterity <= MAX_STAT_VALUE, 'dexterity pack overflow');
        assert(value.vitality <= MAX_STAT_VALUE, 'vitality pack overflow');
        assert(value.intelligence <= MAX_STAT_VALUE, 'intelligence pack overflow');
        assert(value.wisdom <= MAX_STAT_VALUE, 'wisdom pack overflow');
        assert(value.charisma <= MAX_STAT_VALUE, 'charisma pack overflow');

        (value.strength.into()
            + value.dexterity.into() * TWO_POW_5
            + value.vitality.into() * TWO_POW_10
            + value.intelligence.into() * TWO_POW_15
            + value.wisdom.into() * TWO_POW_20
            + value.charisma.into() * TWO_POW_25)
            .try_into()
            .unwrap()
    }

    /// @notice unpacks the stats from a felt252
    /// @param value the felt252 to unpack
    /// @return the unpacked Stats
    fn unpack(value: felt252) -> Stats {
        let packed = value.into();
        let (packed, strength) = integer::U256DivRem::div_rem(packed, TWO_POW_5_NZ);
        let (packed, dexterity) = integer::U256DivRem::div_rem(packed, TWO_POW_5_NZ);
        let (packed, vitality) = integer::U256DivRem::div_rem(packed, TWO_POW_5_NZ);
        let (packed, intelligence) = integer::U256DivRem::div_rem(packed, TWO_POW_5_NZ);
        let (packed, wisdom) = integer::U256DivRem::div_rem(packed, TWO_POW_5_NZ);
        let (_, charisma) = integer::U256DivRem::div_rem(packed, TWO_POW_5_NZ);

        Stats {
            strength: strength.try_into().unwrap(),
            dexterity: dexterity.try_into().unwrap(),
            vitality: vitality.try_into().unwrap(),
            intelligence: intelligence.try_into().unwrap(),
            wisdom: wisdom.try_into().unwrap(),
            charisma: charisma.try_into().unwrap(),
            luck: 0
        }
    }
}

#[generate_trait]
impl ImplStats of IStat {
    /// @notice Creates a new Stats instance with all stats set to 0.
    /// @return A new Stats instance with all stats set to 0.
    fn new() -> Stats {
        Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0, luck: 0
        }
    }

    /// @notice applies stat boosts to adventurer
    /// @param self The Adventurer to apply stat boosts to.
    /// @param stats The stat boosts to apply to the adventurer.
    #[inline(always)]
    fn apply_stats(ref self: Stats, stats: Stats) {
        self.increase_strength(stats.strength);
        self.increase_dexterity(stats.dexterity);
        self.increase_vitality(stats.vitality);
        self.increase_charisma(stats.charisma);
        self.increase_intelligence(stats.intelligence);
        self.increase_wisdom(stats.wisdom);
    }

    /// @notice removes stat boosts from adventurer
    /// @param self The Stats to remove stat boosts from.
    /// @param stats The stat boosts to remove from the adventurer.
    #[inline(always)]
    fn remove_stats(ref self: Stats, stats: Stats) {
        self.decrease_strength(stats.strength);
        self.decrease_dexterity(stats.dexterity);
        self.decrease_vitality(stats.vitality);
        self.decrease_charisma(stats.charisma);
        self.decrease_intelligence(stats.intelligence);
        self.decrease_wisdom(stats.wisdom);
    }

    // @notice This function adds a boost to an adventurer's attributes based on a provided suffix.
    // Each suffix corresponds to a unique combination of attribute enhancements.
    //
    // The following enhancements are available:
    // - of_Power: Increases the adventurer's Strength by 3 points.
    // - of_Giant: Increases the adventurer's Vitality by 3 points.
    // - of_Titans: Increases the adventurer's Strength by 2 points and Charisma by 1 point.
    // - of_Skill: Increases the adventurer's Dexterity by 3 points.
    // - of_Perfection: Increases the adventurer's Strength, Dexterity, and Vitality by 1 point each.
    // - of_Brilliance: Increases the adventurer's Intelligence by 3 points.
    // - of_Enlightenment: Increases the adventurer's Wisdom by 3 points.
    // - of_Protection: Increases the adventurer's Vitality by 2 points and Dexterity by 1 point.
    // - of_Anger: Increases the adventurer's Strength by 2 points and Dexterity by 1 point.
    // - of_Rage: Increases the adventurer's Strength, Charisma, and Wisdom by 1 point each.
    // - of_Fury: Increases the adventurer's Vitality, Charisma, and Intelligence by 1 point each.
    // - of_Vitriol: Increases the adventurer's Intelligence by 2 points and Wisdom by 1 point.
    // - of_the_Fox: Increases the adventurer's Dexterity by 2 points and Charisma by 1 point.
    // - of_Detection: Increases the adventurer's Wisdom by 2 points and Dexterity by 1 point.
    // - of_Reflection: Increases the adventurer's Intelligence by 1 point and Wisdom by 2 points.
    // - of_the_Twins: Increases the adventurer's Charisma by 3 points.
    //
    // @param self A mutable reference to the Adventurer Stats on which the function operates.
    // @param suffix A u8 value representing the suffix tied to the attribute enhancement.
    fn apply_suffix_boost(ref self: Stats, suffix: u8) {
        if (suffix == ItemSuffix::of_Power) {
            self.increase_strength(3);
        } else if (suffix == ItemSuffix::of_Giant) {
            self.increase_vitality(3);
        } else if (suffix == ItemSuffix::of_Titans) {
            self.increase_strength(2);
            self.increase_charisma(1);
        } else if (suffix == ItemSuffix::of_Skill) {
            self.increase_dexterity(3);
        } else if (suffix == ItemSuffix::of_Perfection) {
            self.increase_strength(1);
            self.increase_dexterity(1);
            self.increase_vitality(1);
        } else if (suffix == ItemSuffix::of_Brilliance) {
            self.increase_intelligence(3);
        } else if (suffix == ItemSuffix::of_Enlightenment) {
            self.increase_wisdom(3);
        } else if (suffix == ItemSuffix::of_Protection) {
            self.increase_vitality(2);
            self.increase_dexterity(1);
        } else if (suffix == ItemSuffix::of_Anger) {
            self.increase_strength(2);
            self.increase_dexterity(1);
        } else if (suffix == ItemSuffix::of_Rage) {
            self.increase_strength(1);
            self.increase_charisma(1);
            self.increase_wisdom(1);
        } else if (suffix == ItemSuffix::of_Fury) {
            self.increase_vitality(1);
            self.increase_charisma(1);
            self.increase_intelligence(1);
        } else if (suffix == ItemSuffix::of_Vitriol) {
            self.increase_intelligence(2);
            self.increase_wisdom(1);
        } else if (suffix == ItemSuffix::of_the_Fox) {
            self.increase_dexterity(2);
            self.increase_charisma(1);
        } else if (suffix == ItemSuffix::of_Detection) {
            self.increase_wisdom(2);
            self.increase_dexterity(1);
        } else if (suffix == ItemSuffix::of_Reflection) {
            self.increase_intelligence(1);
            self.increase_wisdom(2);
        } else if (suffix == ItemSuffix::of_the_Twins) {
            self.increase_charisma(3);
        }
    }

    /// @notice removes stat boosts from adventurer
    /// @param self The Stats to remove stat boosts from.
    /// @param suffix The suffix to remove from the adventurer's stats.
    fn remove_suffix_boost(ref self: Stats, suffix: u8) {
        if (suffix == ItemSuffix::of_Power) {
            self.decrease_strength(3);
        } else if (suffix == ItemSuffix::of_Giant) {
            self.decrease_vitality(3);
        } else if (suffix == ItemSuffix::of_Titans) {
            self.decrease_strength(2);
            self.decrease_charisma(1);
        } else if (suffix == ItemSuffix::of_Skill) {
            self.decrease_dexterity(3);
        } else if (suffix == ItemSuffix::of_Perfection) {
            self.decrease_strength(1);
            self.decrease_dexterity(1);
            self.decrease_vitality(1);
        } else if (suffix == ItemSuffix::of_Brilliance) {
            self.decrease_intelligence(3);
        } else if (suffix == ItemSuffix::of_Enlightenment) {
            self.decrease_wisdom(3);
        } else if (suffix == ItemSuffix::of_Protection) {
            self.decrease_vitality(2);
            self.decrease_dexterity(1);
        } else if (suffix == ItemSuffix::of_Anger) {
            self.decrease_strength(2);
            self.decrease_dexterity(1);
        } else if (suffix == ItemSuffix::of_Rage) {
            self.decrease_strength(1);
            self.decrease_charisma(1);
            self.decrease_wisdom(1);
        } else if (suffix == ItemSuffix::of_Fury) {
            self.decrease_vitality(1);
            self.decrease_charisma(1);
            self.decrease_intelligence(1);
        } else if (suffix == ItemSuffix::of_Vitriol) {
            self.decrease_intelligence(2);
            self.decrease_wisdom(1);
        } else if (suffix == ItemSuffix::of_the_Fox) {
            self.decrease_dexterity(2);
            self.decrease_charisma(1);
        } else if (suffix == ItemSuffix::of_Detection) {
            self.decrease_wisdom(2);
            self.decrease_dexterity(1);
        } else if (suffix == ItemSuffix::of_Reflection) {
            self.decrease_intelligence(1);
            self.decrease_wisdom(2);
        } else if (suffix == ItemSuffix::of_the_Twins) {
            self.decrease_charisma(3);
        }
    }

    /// @notice increases the strength stat
    /// @param self The Stats to increase the strength stat of.
    /// @param amount The amount to increase the strength stat by.
    #[inline(always)]
    fn increase_strength(ref self: Stats, amount: u8) {
        self.strength += amount;
    }

    /// @notice increases the dexterity stat
    /// @param self The Stats to increase the dexterity stat of.
    /// @param amount The amount to increase the dexterity stat by.
    #[inline(always)]
    fn increase_dexterity(ref self: Stats, amount: u8) {
        self.dexterity += amount;
    }

    /// @notice increases the vitality stat
    /// @param self The Stats to increase the vitality stat of.
    /// @param amount The amount to increase the vitality stat by.
    #[inline(always)]
    fn increase_vitality(ref self: Stats, amount: u8) {
        self.vitality += amount;
    }

    /// @notice increases the intelligence stat
    /// @param self The Stats to increase the intelligence stat of.
    /// @param amount The amount to increase the intelligence stat by.
    #[inline(always)]
    fn increase_intelligence(ref self: Stats, amount: u8) {
        self.intelligence += amount;
    }

    /// @notice increases the wisdom stat
    /// @param self The Stats to increase the wisdom stat of.
    /// @param amount The amount to increase the wisdom stat by.
    #[inline(always)]
    fn increase_wisdom(ref self: Stats, amount: u8) {
        self.wisdom += amount;
    }

    /// @notice increases the charisma stat
    /// @param self The Stats to increase the charisma stat of.
    /// @param amount The amount to increase the charisma stat by.
    #[inline(always)]
    fn increase_charisma(ref self: Stats, amount: u8) {
        self.charisma += amount;
    }

    /// @notice decreases the strength stat
    /// @param self The Stats to decrease the strength stat of.
    /// @param amount The amount to decrease the strength stat by.
    #[inline(always)]
    fn decrease_strength(ref self: Stats, amount: u8) {
        assert(amount <= self.strength, 'strength underflow');
        self.strength -= amount;
    }

    /// @notice decreases the dexterity stat
    /// @param self The Stats to decrease the dexterity stat of.
    /// @param amount The amount to decrease the dexterity stat by.
    #[inline(always)]
    fn decrease_dexterity(ref self: Stats, amount: u8) {
        assert(amount <= self.dexterity, 'dexterity underflow');
        self.dexterity -= amount;
    }

    /// @notice decreases the vitality stat
    /// @param self The Stats to decrease the vitality stat of.
    /// @param amount The amount to decrease the vitality stat by.
    #[inline(always)]
    fn decrease_vitality(ref self: Stats, amount: u8) {
        assert(amount <= self.vitality, 'vitality underflow');
        self.vitality -= amount;
    }

    /// @notice decreases the intelligence stat
    /// @param self The Stats to decrease the intelligence stat of.
    /// @param amount The amount to decrease the intelligence stat by.
    #[inline(always)]
    fn decrease_intelligence(ref self: Stats, amount: u8) {
        assert(amount <= self.intelligence, 'intelligence underflow');
        self.intelligence -= amount;
    }

    /// @notice decreases the wisdom stat
    /// @param self The Stats to decrease the wisdom stat of.
    /// @param amount The amount to decrease the wisdom stat by.
    #[inline(always)]
    fn decrease_wisdom(ref self: Stats, amount: u8) {
        assert(amount <= self.wisdom, 'wisdom underflow');
        self.wisdom -= amount;
    }

    /// @notice decreases the charisma stat
    /// @param self The Stats to decrease the charisma stat of.
    /// @param amount The amount to decrease the charisma stat by.
    #[inline(always)]
    fn decrease_charisma(ref self: Stats, amount: u8) {
        assert(amount <= self.charisma, 'charisma underflow');
        self.charisma -= amount;
    }

    /// @notice Generates starting stats for the Adventurer.
    /// @param seed The seed to generate the stats from.
    /// @return The starting stats.
    fn generate_starting_stats(seed: u64) -> Stats {
        let (entropy, stat1) = integer::u64_safe_divmod(seed, SIX_NZ);
        let (entropy, stat2) = integer::u64_safe_divmod(entropy, SIX_NZ);
        let (entropy, stat3) = integer::u64_safe_divmod(entropy, SIX_NZ);
        let (entropy, stat4) = integer::u64_safe_divmod(entropy, SIX_NZ);
        let (entropy, stat5) = integer::u64_safe_divmod(entropy, SIX_NZ);
        let (entropy, stat6) = integer::u64_safe_divmod(entropy, SIX_NZ);
        let (entropy, stat7) = integer::u64_safe_divmod(entropy, SIX_NZ);
        let (entropy, stat8) = integer::u64_safe_divmod(entropy, SIX_NZ);
        let (_, stat9) = integer::u64_safe_divmod(entropy, SIX_NZ);
        let mut stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0, luck: 0
        };
        stats.apply_stat(stat1.try_into().unwrap());
        stats.apply_stat(stat2.try_into().unwrap());
        stats.apply_stat(stat3.try_into().unwrap());
        stats.apply_stat(stat4.try_into().unwrap());
        stats.apply_stat(stat5.try_into().unwrap());
        stats.apply_stat(stat6.try_into().unwrap());
        stats.apply_stat(stat7.try_into().unwrap());
        stats.apply_stat(stat8.try_into().unwrap());
        stats.apply_stat(stat9.try_into().unwrap());
        stats
    }

    /// @notice applies a stat to the adventurer
    /// @param self The Stats to apply the stat to.
    /// @param stat The stat to apply.
    #[inline(always)]
    fn apply_stat(ref self: Stats, stat: u8) {
        if (stat == 0) {
            self.strength += 1
        } else if (stat == 1) {
            self.dexterity += 1
        } else if (stat == 2) {
            self.vitality += 1
        } else if (stat == 3) {
            self.intelligence += 1
        } else if (stat == 4) {
            self.wisdom += 1
        } else if (stat == 5) {
            self.charisma += 1
        } else {
            panic_with_felt252('stat out of range');
        }
    }
}

const SIX_NZ: NonZero<u64> = 6;
const TWO_POW_5: u256 = 0x20;
const TWO_POW_5_NZ: NonZero<u256> = 0x20;
const TWO_POW_10: u256 = 0x400;
const TWO_POW_15: u256 = 0x8000;
const TWO_POW_20: u256 = 0x100000;
const TWO_POW_25: u256 = 0x2000000;

// ---------------------------
// ---------- Tests ----------
// ---------------------------
#[cfg(test)]
mod tests {
    use adventurer::stats::{Stats, ImplStats, StatsPacking, MAX_STAT_VALUE};

    #[test]
    #[available_gas(1039260)]
    fn test_stats_packing() {
        // zero case
        let stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0, luck: 0
        };

        let packed = StatsPacking::pack(stats);
        let unpacked = StatsPacking::unpack(packed);
        assert(stats.strength == unpacked.strength, 'strength zero case');
        assert(stats.dexterity == unpacked.dexterity, 'dexterity zero case');
        assert(stats.vitality == unpacked.vitality, 'vitality zero case');
        assert(stats.intelligence == unpacked.intelligence, 'intelligence zero case');
        assert(stats.wisdom == unpacked.wisdom, 'wisdom zero case');
        assert(stats.charisma == unpacked.charisma, 'charisma zero case');
        assert(unpacked.luck == 0, 'luck is zero from storage');

        // storage limit test
        let stats = Stats {
            strength: 31,
            dexterity: 31,
            vitality: 31,
            intelligence: 31,
            wisdom: 31,
            charisma: 31,
            luck: 31
        };

        let packed = StatsPacking::pack(stats);
        let unpacked = StatsPacking::unpack(packed);
        assert(stats.strength == unpacked.strength, 'strength storage limit');
        assert(stats.dexterity == unpacked.dexterity, 'dexterity storage limit');
        assert(stats.vitality == unpacked.vitality, 'vitality storage limit');
        assert(stats.intelligence == unpacked.intelligence, 'intelligence storage limit');
        assert(stats.wisdom == unpacked.wisdom, 'wisdom storage limit');
        assert(stats.charisma == unpacked.charisma, 'charisma storage limit');
        assert(unpacked.luck == 0, 'luck is zero from storage');
    }

    #[test]
    #[should_panic(expected: ('strength pack overflow',))]
    #[available_gas(142010)]
    fn test_pack_protection_overflow_strength() {
        StatsPacking::pack(
            Stats {
                strength: MAX_STAT_VALUE + 1,
                dexterity: 0,
                vitality: 0,
                intelligence: 0,
                wisdom: 0,
                charisma: 0,
                luck: 0
            }
        );
    }

    #[test]
    #[should_panic(expected: ('dexterity pack overflow',))]
    #[available_gas(142010)]
    fn test_pack_protection_overflow_dexterity() {
        StatsPacking::pack(
            Stats {
                strength: 0,
                dexterity: MAX_STAT_VALUE + 1,
                vitality: 0,
                intelligence: 0,
                wisdom: 0,
                charisma: 0,
                luck: 0
            }
        );
    }

    #[test]
    #[should_panic(expected: ('vitality pack overflow',))]
    #[available_gas(142010)]
    fn test_pack_protection_overflow_vitality() {
        StatsPacking::pack(
            Stats {
                strength: 0,
                dexterity: 0,
                vitality: MAX_STAT_VALUE + 1,
                intelligence: 0,
                wisdom: 0,
                charisma: 0,
                luck: 0
            }
        );
    }

    #[test]
    #[should_panic(expected: ('intelligence pack overflow',))]
    #[available_gas(142010)]
    fn test_pack_protection_overflow_intelligence() {
        StatsPacking::pack(
            Stats {
                strength: 0,
                dexterity: 0,
                vitality: 0,
                intelligence: MAX_STAT_VALUE + 1,
                wisdom: 0,
                charisma: 0,
                luck: 0
            }
        );
    }

    #[test]
    #[should_panic(expected: ('wisdom pack overflow',))]
    #[available_gas(142010)]
    fn test_pack_protection_overflow_wisdom() {
        StatsPacking::pack(
            Stats {
                strength: 0,
                dexterity: 0,
                vitality: 0,
                intelligence: 0,
                wisdom: MAX_STAT_VALUE + 1,
                charisma: 0,
                luck: 0
            }
        );
    }

    #[test]
    fn test_generate_starting_stats_gas() {
        let seed = 12345_u64;
        ImplStats::generate_starting_stats(seed);
    }

    #[test]
    fn test_apply_stats_all_positive() {
        let mut base_stats = Stats {
            strength: 5, dexterity: 5, vitality: 5, intelligence: 5, wisdom: 5, charisma: 5, luck: 0
        };
        let apply_stats = Stats {
            strength: 2, dexterity: 3, vitality: 1, intelligence: 4, wisdom: 2, charisma: 3, luck: 0
        };

        base_stats.apply_stats(apply_stats);

        assert(base_stats.strength == 7, 'strength should be 7');
        assert(base_stats.dexterity == 8, 'dexterity should be 8');
        assert(base_stats.vitality == 6, 'vitality should be 6');
        assert(base_stats.intelligence == 9, 'intelligence should be 9');
        assert(base_stats.wisdom == 7, 'wisdom should be 7');
        assert(base_stats.charisma == 8, 'charisma should be 8');
        assert(base_stats.luck == 0, 'luck should remain 0');
    }

    #[test]
    fn test_apply_stats_some_zero() {
        let mut base_stats = Stats {
            strength: 5, dexterity: 5, vitality: 5, intelligence: 5, wisdom: 5, charisma: 5, luck: 0
        };
        let apply_stats = Stats {
            strength: 0, dexterity: 3, vitality: 0, intelligence: 4, wisdom: 0, charisma: 2, luck: 0
        };

        base_stats.apply_stats(apply_stats);

        assert(base_stats.strength == 5, 'strength should remain 5');
        assert(base_stats.dexterity == 8, 'dexterity should be 8');
        assert(base_stats.vitality == 5, 'vitality should remain 5');
        assert(base_stats.intelligence == 9, 'intelligence should be 9');
        assert(base_stats.wisdom == 5, 'wisdom should remain 5');
        assert(base_stats.charisma == 7, 'charisma should be 7');
        assert(base_stats.luck == 0, 'luck should remain 0');
    }

    #[test]
    fn test_apply_stats_all_zero() {
        let mut base_stats = Stats {
            strength: 5, dexterity: 5, vitality: 5, intelligence: 5, wisdom: 5, charisma: 5, luck: 0
        };
        let apply_stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0, luck: 0
        };

        base_stats.apply_stats(apply_stats);

        assert(base_stats.strength == 5, 'strength should remain 5');
        assert(base_stats.dexterity == 5, 'dexterity should remain 5');
        assert(base_stats.vitality == 5, 'vitality should remain 5');
        assert(base_stats.intelligence == 5, 'intelligence should remain 5');
        assert(base_stats.wisdom == 5, 'wisdom should remain 5');
        assert(base_stats.charisma == 5, 'charisma should remain 5');
        assert(base_stats.luck == 0, 'luck should remain 0');
    }

    #[test]
    #[available_gas(1470)]
    fn test_increase_strength_gas() {
        let mut stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0, luck: 0
        };
        stats.increase_strength(1);
    }

    #[test]
    #[available_gas(1470)]
    fn test_increase_dexterity_gas() {
        let mut stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0, luck: 0
        };
        stats.increase_dexterity(1);
    }

    #[test]
    #[available_gas(1470)]
    fn test_increase_vitality_gas() {
        let mut stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0, luck: 0
        };
        stats.increase_vitality(1);
    }

    #[test]
    #[available_gas(1470)]
    fn test_increase_intelligence_gas() {
        let mut stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0, luck: 0
        };
        stats.increase_intelligence(1);
    }

    #[test]
    #[available_gas(1470)]
    fn test_increase_wisdom_gas() {
        let mut stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0, luck: 0
        };
        stats.increase_wisdom(1);
    }

    #[test]
    #[available_gas(1470)]
    fn test_increase_charisma_gas() {
        let mut stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0, luck: 0
        };
        stats.increase_charisma(1);
    }

    #[test]
    fn test_increase_strength() {
        let mut stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0, luck: 0
        };
        // basic case
        stats.increase_strength(1);
        assert(stats.strength == 1, 'strength should be 1');
        // exceed max stat case
        stats.increase_strength(50);
        assert(stats.strength == 51, 'strength should be 51');
    }

    #[test]
    fn test_increase_dexterity() {
        let mut stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0, luck: 0
        };
        // basic case
        stats.increase_dexterity(1);
        assert(stats.dexterity == 1, 'dexterity should be 1');
        // overflow case
        stats.increase_dexterity(50);
        assert(stats.dexterity == 51, 'dexterity should be 51');
    }

    #[test]
    fn test_increase_vitality() {
        let mut stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0, luck: 0
        };
        // basic case
        stats.increase_vitality(1);
        assert(stats.vitality == 1, 'vitality should be 1');
        // overflow case
        stats.increase_vitality(50);
        assert(stats.vitality == 51, 'vitality should be 51');
    }

    #[test]
    fn test_increase_intelligence() {
        let mut stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0, luck: 0
        };
        // basic case
        stats.increase_intelligence(1);
        assert(stats.intelligence == 1, 'intelligence should be 1');
        // overflow case
        stats.increase_intelligence(50);
        assert(stats.intelligence == 51, 'intelligence should be 51');
    }

    #[test]
    fn test_increase_wisdom() {
        let mut stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0, luck: 0
        };
        // basic case
        stats.increase_wisdom(1);
        assert(stats.wisdom == 1, 'wisdom should be 1');
        // overflow case
        stats.increase_wisdom(50);
        assert(stats.wisdom == 51, 'wisdom should be 51');
    }

    #[test]
    fn test_increase_charisma() {
        let mut stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0, luck: 0
        };
        // basic case
        stats.increase_charisma(1);
        assert(stats.charisma == 1, 'charisma should be 1');
        // overflow case
        stats.increase_charisma(50);
        assert(stats.charisma == 51, 'charisma should be 51');
    }

    #[test]
    #[available_gas(2440)]
    fn test_decrease_strength_gas() {
        let mut stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0, luck: 0
        };
        stats.decrease_strength(0);
    }

    #[test]
    #[available_gas(2440)]
    fn test_decrease_dexterity_gas() {
        let mut stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0, luck: 0
        };
        stats.decrease_dexterity(0);
    }

    #[test]
    #[available_gas(2440)]
    fn test_decrease_vitality_gas() {
        let mut stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0, luck: 0
        };
        stats.decrease_vitality(0);
    }

    #[test]
    #[available_gas(2440)]
    fn test_decrease_intelligence_gas() {
        let mut stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0, luck: 0
        };
        stats.decrease_intelligence(0);
    }

    #[test]
    #[available_gas(2440)]
    fn test_decrease_wisdom_gas() {
        let mut stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0, luck: 0
        };
        stats.decrease_wisdom(0);
    }

    #[test]
    #[available_gas(2440)]
    fn test_decrease_charisma_gas() {
        let mut stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0, luck: 0
        };
        stats.decrease_charisma(0);
    }

    #[test]
    fn test_decrease_strength() {
        let mut stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0, luck: 0
        };
        stats.increase_strength(2);
        assert(stats.strength == 2, 'strength should be 2');
        stats.decrease_strength(1);
        assert(stats.strength == 1, 'strength should be 1');
    }

    #[test]
    #[should_panic(expected: ('strength underflow',))]
    fn test_decrease_strength_underflow() {
        let mut stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0, luck: 0
        };
        stats.increase_strength(5);
        stats.decrease_strength(6);
    }

    #[test]
    fn test_decrease_dexterity() {
        let mut stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0, luck: 0
        };
        stats.increase_dexterity(2);
        assert(stats.dexterity == 2, 'dexterity should be 2');
        stats.decrease_dexterity(1);
        assert(stats.dexterity == 1, 'dexterity should be 1');
    }

    #[test]
    #[should_panic(expected: ('dexterity underflow',))]
    fn test_decrease_dexterity_underflow() {
        let mut stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0, luck: 0
        };
        stats.increase_dexterity(5);
        stats.decrease_dexterity(6);
    }

    #[test]
    fn test_decrease_vitality() {
        let mut stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0, luck: 0
        };
        stats.increase_vitality(2);
        assert(stats.vitality == 2, 'vitality should be 2');
        stats.decrease_vitality(1);
        assert(stats.vitality == 1, 'vitality should be 1');
    }

    #[test]
    #[should_panic(expected: ('vitality underflow',))]
    fn test_decrease_vitality_underflow() {
        let mut stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0, luck: 0
        };
        stats.increase_vitality(5);
        stats.decrease_vitality(6);
    }

    #[test]
    fn test_decrease_intelligence() {
        let mut stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0, luck: 0
        };
        stats.increase_intelligence(2);
        assert(stats.intelligence == 2, 'intelligence should be 2');
        stats.decrease_intelligence(1);
        assert(stats.intelligence == 1, 'intelligence should be 1');
    }

    #[test]
    #[should_panic(expected: ('intelligence underflow',))]
    fn test_decrease_intelligence_underflow() {
        let mut stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0, luck: 0
        };
        stats.increase_intelligence(5);
        stats.decrease_intelligence(6);
    }


    #[test]
    fn test_decrease_wisdom() {
        let mut stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0, luck: 0
        };
        stats.increase_wisdom(2);
        assert(stats.wisdom == 2, 'wisdom should be 2');
        stats.decrease_wisdom(1);
        assert(stats.wisdom == 1, 'wisdom should be 1');
    }

    #[test]
    #[should_panic(expected: ('wisdom underflow',))]
    fn test_decrease_wisdom_underflow() {
        let mut stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0, luck: 0
        };
        stats.increase_wisdom(5);
        stats.decrease_wisdom(6);
    }


    #[test]
    fn test_decrease_charisma() {
        let mut stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0, luck: 0
        };
        stats.increase_charisma(2);
        assert(stats.charisma == 2, 'charisma should be 2');
        stats.decrease_charisma(1);
        assert(stats.charisma == 1, 'charisma should be 1');
    }

    #[test]
    #[should_panic(expected: ('charisma underflow',))]
    fn test_decrease_charisma_underflow() {
        let mut stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0, luck: 0
        };
        stats.increase_charisma(5);
        stats.decrease_charisma(6);
    }
}
