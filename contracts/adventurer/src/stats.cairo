use core::{option::OptionTrait, starknet::{StorePacking}, traits::{TryInto, Into}};

#[derive(Drop, Copy, Serde)]
struct Stats { // 24 storage bits
    strength: u8, // 4 bits
    dexterity: u8, // 4 bits
    vitality: u8, // 4 bits
    intelligence: u8, // 4 bits
    wisdom: u8, // 4 bits
    charisma: u8, // 4 bits
    luck: u8 // // dynamically generated, not stored.
}

#[generate_trait]
impl StatUtils of IStat {
    fn new() -> Stats {
        Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0, luck: 0
        }
    }
}

impl StatsPacking of StorePacking<Stats, felt252> {
    fn pack(value: Stats) -> felt252 {
        (value.strength.into()
            + value.dexterity.into() * TWO_POW_4
            + value.vitality.into() * TWO_POW_8
            + value.intelligence.into() * TWO_POW_12
            + value.wisdom.into() * TWO_POW_16
            + value.charisma.into() * TWO_POW_20)
            .try_into()
            .unwrap()
    }

    fn unpack(value: felt252) -> Stats {
        let packed = value.into();
        let (packed, strength) = integer::U256DivRem::div_rem(
            packed, TWO_POW_4.try_into().unwrap()
        );
        let (packed, dexterity) = integer::U256DivRem::div_rem(
            packed, TWO_POW_4.try_into().unwrap()
        );
        let (packed, vitality) = integer::U256DivRem::div_rem(
            packed, TWO_POW_4.try_into().unwrap()
        );
        let (packed, intelligence) = integer::U256DivRem::div_rem(
            packed, TWO_POW_4.try_into().unwrap()
        );
        let (packed, wisdom) = integer::U256DivRem::div_rem(packed, TWO_POW_4.try_into().unwrap());
        let (_, charisma) = integer::U256DivRem::div_rem(packed, TWO_POW_4.try_into().unwrap());

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

const TWO_POW_4: u256 = 0x10;
const TWO_POW_8: u256 = 0x100;
const TWO_POW_12: u256 = 0x1000;
const TWO_POW_16: u256 = 0x10000;
const TWO_POW_20: u256 = 0x100000;
const TWO_POW_24: u256 = 0x1000000;

// ---------------------------
// ---------- Tests ----------
// ---------------------------
#[cfg(test)]
mod tests {
    use survivor::stats::{Stats, StatsPacking};

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

        // storage limit test (2^4 - 1 = 15)
        let stats = Stats {
            strength: 15,
            dexterity: 15,
            vitality: 15,
            intelligence: 15,
            wisdom: 15,
            charisma: 15,
            luck: 15
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
}
