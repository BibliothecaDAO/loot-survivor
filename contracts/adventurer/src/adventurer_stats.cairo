use option::OptionTrait;
use traits::{TryInto, Into};
use pack::{pack::{Packing, rshift_split}, constants::pow};
use survivor::constants::adventurer_constants::MAX_STAT_VALUE;

#[derive(Drop, Copy, Serde)]
struct Stats { // 5 bits each
    // Physical
    strength: u8, // increases attack damage
    dexterity: u8, // increases flee chance
    vitality: u8, // increases health
    // Mental
    intelligence: u8, // increases obstacle avoidance
    wisdom: u8, // increase ambush avoidance
    charisma: u8, // provides shop discount
}

impl StatsPacking of Packing<Stats> {
    fn pack(self: Stats) -> felt252 {
        let overflow_protected = self.overflow_pack_protection();

        (overflow_protected.strength.into()
            + overflow_protected.dexterity.into() * pow::TWO_POW_5
            + overflow_protected.vitality.into() * pow::TWO_POW_10
            + overflow_protected.intelligence.into() * pow::TWO_POW_15
            + overflow_protected.wisdom.into() * pow::TWO_POW_20
            + overflow_protected.charisma.into() * pow::TWO_POW_25)
            .try_into()
            .expect('pack Stats')
    }

    fn unpack(packed: felt252) -> Stats {
        let packed = packed.into();
        let (packed, strength) = rshift_split(packed, pow::TWO_POW_5);
        let (packed, dexterity) = rshift_split(packed, pow::TWO_POW_5);
        let (packed, vitality) = rshift_split(packed, pow::TWO_POW_5);
        let (packed, intelligence) = rshift_split(packed, pow::TWO_POW_5);
        let (packed, wisdom) = rshift_split(packed, pow::TWO_POW_5);
        let (_, charisma) = rshift_split(packed, pow::TWO_POW_5);

        Stats {
            strength: strength.try_into().expect('unpack Stats strength'),
            dexterity: dexterity.try_into().expect('unpack Stats dexterity'),
            vitality: vitality.try_into().expect('unpack Stats vitality'),
            intelligence: intelligence.try_into().expect('unpack Stats intelligence'),
            wisdom: wisdom.try_into().expect('unpack Stats wisdom'),
            charisma: charisma.try_into().expect('unpack Stats charisma')
        }
    }

    fn overflow_pack_protection(self: Stats) -> Stats {
        let mut overflow_protected_stats = self;

        if self.strength > MAX_STAT_VALUE {
            overflow_protected_stats.strength = MAX_STAT_VALUE;
        };
        if self.dexterity > MAX_STAT_VALUE {
            overflow_protected_stats.dexterity = MAX_STAT_VALUE;
        }
        if self.vitality > MAX_STAT_VALUE {
            overflow_protected_stats.vitality = MAX_STAT_VALUE;
        }
        if self.intelligence > MAX_STAT_VALUE {
            overflow_protected_stats.intelligence = MAX_STAT_VALUE;
        }
        if self.wisdom > MAX_STAT_VALUE {
            overflow_protected_stats.wisdom = MAX_STAT_VALUE;
        }
        if self.charisma > MAX_STAT_VALUE {
            overflow_protected_stats.charisma = MAX_STAT_VALUE;
        }

        overflow_protected_stats
    }
}

#[test]
#[available_gas(1500000)]
fn test_stats_packing() {
    // zero case
    let stats = Stats {
        strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0
    };

    let packed = stats.pack();
    let unpacked = StatsPacking::unpack(packed);
    assert(stats.strength == unpacked.strength, 'strength zero case');
    assert(stats.dexterity == unpacked.dexterity, 'dexterity zero case');
    assert(stats.vitality == unpacked.vitality, 'vitality zero case');
    assert(stats.intelligence == unpacked.intelligence, 'intelligence zero case');
    assert(stats.wisdom == unpacked.wisdom, 'wisdom zero case');
    assert(stats.charisma == unpacked.charisma, 'charisma zero case');

    // storage limit test (2^5 - 1 = 31)
    let stats = Stats {
        strength: 31, dexterity: 31, vitality: 31, intelligence: 31, wisdom: 31, charisma: 31
    };

    let packed = stats.pack();
    let unpacked = StatsPacking::unpack(packed);
    assert(stats.strength == unpacked.strength, 'strength storage limit');
    assert(stats.dexterity == unpacked.dexterity, 'dexterity storage limit');
    assert(stats.vitality == unpacked.vitality, 'vitality storage limit');
    assert(stats.intelligence == unpacked.intelligence, 'intelligence storage limit');
    assert(stats.wisdom == unpacked.wisdom, 'wisdom storage limit');
    assert(stats.charisma == unpacked.charisma, 'charisma storage limit');

    // overflow storage limit using max u8
    let stats = Stats {
        strength: 255, dexterity: 255, vitality: 255, intelligence: 255, wisdom: 255, charisma: 255
    };

    let packed = stats.pack();
    let unpacked = StatsPacking::unpack(packed);

    // assert packing function prevented overflow
    assert(unpacked.strength == MAX_STAT_VALUE, 'strength pack overflow');
    assert(unpacked.dexterity == MAX_STAT_VALUE, 'dexterity pack overflow');
    assert(unpacked.vitality == MAX_STAT_VALUE, 'vitality pack overflow');
    assert(unpacked.intelligence == MAX_STAT_VALUE, 'intelligence pack overflow');
    assert(unpacked.wisdom == MAX_STAT_VALUE, 'wisdom pack overflow');
    assert(unpacked.charisma == MAX_STAT_VALUE, 'charisma pack overflow');
}
