use core::{option::OptionTrait, starknet::{StorePacking}, traits::{TryInto, Into}};
use core::integer::u8_overflowing_add;
use loot::constants::ItemSuffix;

const MAX_STAT_VALUE: u8 = 31;

#[derive(Drop, Copy, Serde, PartialEq)]
struct Stats { // 30 storage bits
    strength: u8, // 5 bits each
    dexterity: u8,
    vitality: u8,
    intelligence: u8,
    wisdom: u8,
    charisma: u8,
    luck: u8 // dynamically generated, not stored.
}

impl StatsPacking of StorePacking<Stats, felt252> {
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

    fn unpack(value: felt252) -> Stats {
        let packed = value.into();
        let (packed, strength) = integer::U256DivRem::div_rem(
            packed, TWO_POW_5.try_into().unwrap()
        );
        let (packed, dexterity) = integer::U256DivRem::div_rem(
            packed, TWO_POW_5.try_into().unwrap()
        );
        let (packed, vitality) = integer::U256DivRem::div_rem(
            packed, TWO_POW_5.try_into().unwrap()
        );
        let (packed, intelligence) = integer::U256DivRem::div_rem(
            packed, TWO_POW_5.try_into().unwrap()
        );
        let (packed, wisdom) = integer::U256DivRem::div_rem(packed, TWO_POW_5.try_into().unwrap());
        let (_, charisma) = integer::U256DivRem::div_rem(packed, TWO_POW_5.try_into().unwrap());

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
    fn new() -> Stats {
        Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0, luck: 0
        }
    }

    // @notice applies stat boosts to adventurer
    // @param self The Adventurer to apply stat boosts to.
    // @param stats The stat boosts to apply to the adventurer.
    // @dev overflow protection is handled further up the stack
    #[inline(always)]
    fn apply_stats(ref self: Stats, stats: Stats) {
        self.increase_strength(stats.strength);
        self.increase_dexterity(stats.dexterity);
        self.increase_vitality(stats.vitality);
        self.increase_charisma(stats.charisma);
        self.increase_intelligence(stats.intelligence);
        self.increase_wisdom(stats.wisdom);
    }

    // @notice removes stat boosts from adventurer
    // @param self The Stats to remove stat boosts from.
    // @param stats The stat boosts to remove from the adventurer.
    // @dev underflow protection is handled further up the stack
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

    // @notice Removes a specified suffix boost from an adventurer's stats.
    // @param self The instance of the Stats struct which contains the adventurer's stats.
    // @param suffix The suffix to be removed from the adventurer's stats.
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

    // @notice Increase the Adventurer's strength stat.
    // @dev The function will add the specified amount to the strength stat up to the maximum limit of MAX_STAT_VALUE.
    // @param amount The amount to be added to the strength stat.
    #[inline(always)]
    fn increase_strength(ref self: Stats, amount: u8) {
        self.strength.overflow_protected_stat_increase(amount)
    }

    // @notice Increase the Adventurer's dexterity stat.
    // @dev The function will add the specified amount to the dexterity stat up to the maximum limit of MAX_STAT_VALUE.
    // @param amount The amount to be added to the dexterity stat.
    #[inline(always)]
    fn increase_dexterity(ref self: Stats, amount: u8) {
        self.dexterity.overflow_protected_stat_increase(amount)
    }

    // @notice Increase the Adventurer's vitality stat.
    // @dev The function will add the specified amount to the vitality stat up to the maximum limit of MAX_STAT_VALUE.
    // @param amount The amount to be added to the vitality stat.
    #[inline(always)]
    fn increase_vitality(ref self: Stats, amount: u8) {
        self.vitality.overflow_protected_stat_increase(amount)
    }

    // @notice Increase the Adventurer's intelligence stat.
    // @dev The function will add the specified amount to the intelligence stat up to the maximum limit of MAX_STAT_VALUE.
    // @param amount The amount to be added to the intelligence stat.
    #[inline(always)]
    fn increase_intelligence(ref self: Stats, amount: u8) {
        self.intelligence.overflow_protected_stat_increase(amount)
    }

    // @notice Increase the Adventurer's wisdom stat.
    // @dev The function will add the specified amount to the wisdom stat up to the maximum limit of MAX_STAT_VALUE.
    // @param amount The amount to be added to the wisdom stat.
    #[inline(always)]
    fn increase_wisdom(ref self: Stats, amount: u8) {
        self.wisdom.overflow_protected_stat_increase(amount)
    }

    // @notice Increase the Adventurer's charisma stat.
    // @dev The function will add the specified amount to the charisma stat up to the maximum limit of MAX_STAT_VALUE.
    // @param amount The amount to be added to the charisma stat.
    #[inline(always)]
    fn increase_charisma(ref self: Stats, amount: u8) {
        self.charisma.overflow_protected_stat_increase(amount)
    }

    #[inline(always)]
    fn overflow_protected_stat_increase(ref self: u8, amount: u8) {
        if (u8_overflowing_add(self, amount).is_ok()) {
            self += amount
        } else {
            self = MAX_STAT_VALUE
        }
    }

    // @notice Decrease the Adventurer's strength stat.
    // @dev The function will subtract the specified amount from the strength stat without allowing it to fall below 0.
    // @param amount The amount to be subtracted from the strength stat.
    #[inline(always)]
    fn decrease_strength(ref self: Stats, amount: u8) {
        assert(amount <= self.strength, 'strength underflow');
        self.strength -= amount;
    }

    // @notice Decrease the Adventurer's dexterity stat.
    // @dev The function will subtract the specified amount from the dexterity stat without allowing it to fall below 0.
    // @param amount The amount to be deducted from the dexterity stat.
    #[inline(always)]
    fn decrease_dexterity(ref self: Stats, amount: u8) {
        assert(amount <= self.dexterity, 'dexterity underflow');
        self.dexterity -= amount;
    }

    // @notice Decrease the Adventurer's vitality stat.
    // @dev The function will subtract the specified amount from the vitality stat without allowing it to fall below 0.
    // @param amount The amount to be deducted from the vitality stat.
    #[inline(always)]
    fn decrease_vitality(ref self: Stats, amount: u8) {
        assert(amount <= self.vitality, 'vitality underflow');
        self.vitality -= amount;
    }

    // @notice Decrease the Adventurer's intelligence stat.
    // @dev The function will subtract the specified amount from the intelligence stat without allowing it to fall below 0.
    // @param amount The amount to be deducted from the intelligence stat.
    #[inline(always)]
    fn decrease_intelligence(ref self: Stats, amount: u8) {
        assert(amount <= self.intelligence, 'intelligence underflow');
        self.intelligence -= amount;
    }

    // @notice Decrease the Adventurer's wisdom stat.
    // @dev The function will subtract the specified amount from the wisdom stat without allowing it to fall below 0.
    // @param amount The amount to be deducted from the wisdom stat.
    #[inline(always)]
    fn decrease_wisdom(ref self: Stats, amount: u8) {
        assert(amount <= self.wisdom, 'wisdom underflow');
        self.wisdom -= amount;
    }

    // @notice Decrease the Adventurer's charisma stat.
    // @dev The function will subtract the specified amount from the charisma stat without allowing it to fall below 0.
    // @param amount The amount to be deducted from the charisma stat.
    #[inline(always)]
    fn decrease_charisma(ref self: Stats, amount: u8) {
        assert(amount <= self.charisma, 'charisma underflow');
        self.charisma -= amount;
    }

    /// @notice Apply starting stats to the adventurer.
    /// @param self The adventurer.
    /// @param entropy Randomness input for the stat application.
    /// @param starting_stat_count The number of starting stats to apply.
    fn apply_starting_stats(ref self: Stats, entropy: u256, starting_stat_count: u8) {
        let mut random_stats = ImplStats::generate_random_stats(entropy);

        assert(starting_stat_count.into() <= random_stats.len(), 'stat count out of bounds');

        let mut i = 0;
        loop {
            if i == starting_stat_count.into() {
                break;
            }
            let random_u8 = *random_stats.at(i);
            let random_stat_index = random_u8 % 6;
            if random_stat_index == 0 {
                self.strength += 1;
            } else if random_stat_index == 1 {
                self.dexterity += 1;
            } else if random_stat_index == 2 {
                self.vitality += 1;
            } else if random_stat_index == 3 {
                self.charisma += 1;
            } else if random_stat_index == 4 {
                self.intelligence += 1;
            } else if random_stat_index == 5 {
                self.wisdom += 1;
            } else {
                panic_with_felt252('stat out of range');
            }

            i += 1;
        };
    }

    // @notice generates random array of stats from a u256 value
    // @param value: value to convert
    // @return Array<u8>: u8 array
    fn generate_random_stats(value: u256) -> Array<u8> {
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
const TWO_POW_5: u256 = 0x20;
const TWO_POW_8: u256 = 0x100;
const TWO_POW_10: u256 = 0x400;
const TWO_POW_15: u256 = 0x8000;
const TWO_POW_16: u256 = 0x10000;
const TWO_POW_20: u256 = 0x100000;
const TWO_POW_24: u256 = 0x1000000;
const TWO_POW_25: u256 = 0x2000000;
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
    #[available_gas(30000)]
    fn test_overflow_protected_stat_increase() {
        let mut stat: u8 = 1;

        // base case
        stat.overflow_protected_stat_increase(1);
        assert(stat == 2, 'stat should increase by 1');

        // u8 overflow case
        stat.overflow_protected_stat_increase(255);
        assert(stat == MAX_STAT_VALUE, 'stat should not overflow');
    }

    #[test]
    #[available_gas(249718)]
    fn test_apply_starting_stats_gas() {
        let mut stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, charisma: 0, intelligence: 0, wisdom: 0, luck: 0
        };
        stats.apply_starting_stats(0, 9);
    }

    #[test]
    #[should_panic(expected: ('stat count out of bounds',))]
    fn test_apply_starting_stats_too_many_stats() {
        let mut stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, charisma: 0, intelligence: 0, wisdom: 0, luck: 0
        };
        stats.apply_starting_stats(0, 17);
    }

    #[test]
    fn test_apply_starting_stats() {
        // Test case 1: Basic functionality
        let mut stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, charisma: 0, intelligence: 0, wisdom: 0, luck: 0
        };
        let entropy = 0x123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef;
        stats.apply_starting_stats(entropy, 6);
        assert(
            stats.strength
                + stats.dexterity
                + stats.vitality
                + stats.charisma
                + stats.intelligence
                + stats.wisdom == 6,
            'Total stats should be 6'
        );

        // Test case 2: Zero starting stats
        let mut stats2 = Stats {
            strength: 0, dexterity: 0, vitality: 0, charisma: 0, intelligence: 0, wisdom: 0, luck: 0
        };
        stats2.apply_starting_stats(entropy, 0);
        assert(
            stats2.strength
                + stats2.dexterity
                + stats2.vitality
                + stats2.charisma
                + stats2.intelligence
                + stats2.wisdom == 0,
            'No stats should be applied'
        );

        // Test case 3: Maximum starting stats
        let mut stats3 = Stats {
            strength: 0, dexterity: 0, vitality: 0, charisma: 0, intelligence: 0, wisdom: 0, luck: 0
        };
        stats3.apply_starting_stats(entropy, 16);
        assert(
            stats3.strength
                + stats3.dexterity
                + stats3.vitality
                + stats3.charisma
                + stats3.intelligence
                + stats3.wisdom == 16,
            'Total stats should be 16'
        );

        // Test case 4: Different entropy produces different stat distribution
        let mut stats4 = Stats {
            strength: 0, dexterity: 0, vitality: 0, charisma: 0, intelligence: 0, wisdom: 0, luck: 0
        };
        let mut stats5 = Stats {
            strength: 0, dexterity: 0, vitality: 0, charisma: 0, intelligence: 0, wisdom: 0, luck: 0
        };
        stats4.apply_starting_stats(1, 6);
        stats5.apply_starting_stats(2, 6);
        assert(stats4 != stats5, 'Stats should be different');
    }

    #[test]
    #[available_gas(1448412)]
    fn test_generate_random_stats() {
        // zero case
        let value = 0;
        let values = ImplStats::generate_random_stats(value);
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
        let values = ImplStats::generate_random_stats(value);
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

        let values = ImplStats::generate_random_stats(value);
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
}
