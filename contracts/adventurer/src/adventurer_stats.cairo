use starknet::{StorePacking};
use option::OptionTrait;
use traits::{TryInto, Into};
use survivor::constants::adventurer_constants::MAX_STAT_VALUE;

#[derive(Drop, Copy, Serde)]
struct Stats { // 5 bits each
    // Physical
    strength: u8, // 5 bits
    dexterity: u8, // 5 bits
    vitality: u8, // 5 bits
    // Mental
    intelligence: u8, // 5 bits
    wisdom: u8, // 5 bits
    charisma: u8, // 5 bits
    // Metaphysical
    luck: u8 // // not stored - dynamically generated
}

#[generate_trait]
impl StatUtils of IStat {
    fn new() -> Stats {
        Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0, luck: 0
        }
    }
}

const TWO_POW_5: u256 = 0x20;
const TWO_POW_10: u256 = 0x400;
const TWO_POW_15: u256 = 0x8000;
const TWO_POW_20: u256 = 0x100000;
const TWO_POW_25: u256 = 0x2000000;

impl StatsPacking of StorePacking<Stats, felt252> {
    fn pack(value: Stats) -> felt252 {
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

// ---------------------------
// ---------- Tests ----------
// ---------------------------
#[cfg(test)]
mod tests {
    use survivor::{
        constants::adventurer_constants::MAX_STAT_VALUE, adventurer_stats::{Stats, StatsPacking}
    };

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

        // storage limit test (2^5 - 1 = 31)
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

        // overflow storage limit using max u8
        let stats = Stats {
            strength: 255,
            dexterity: 255,
            vitality: 255,
            intelligence: 255,
            wisdom: 255,
            charisma: 255,
            luck: 255
        };

        let packed = StatsPacking::pack(stats);
        let unpacked = StatsPacking::unpack(packed);

        // assert packing function prevented overflow
        assert(unpacked.strength == MAX_STAT_VALUE, 'strength pack overflow');
        assert(unpacked.dexterity == MAX_STAT_VALUE, 'dexterity pack overflow');
        assert(unpacked.vitality == MAX_STAT_VALUE, 'vitality pack overflow');
        assert(unpacked.intelligence == MAX_STAT_VALUE, 'intelligence pack overflow');
        assert(unpacked.wisdom == MAX_STAT_VALUE, 'wisdom pack overflow');
        assert(unpacked.charisma == MAX_STAT_VALUE, 'charisma pack overflow');
        assert(unpacked.luck == 0, 'luck is zero from storage');
    }
}
