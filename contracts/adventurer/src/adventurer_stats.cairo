use option::OptionTrait;
use traits::{TryInto, Into};
use pack::{pack::{Packing, rshift_split}, constants::pow};

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
        (self.strength.into()
            + self.dexterity.into() * pow::TWO_POW_5
            + self.vitality.into() * pow::TWO_POW_10
            + self.intelligence.into() * pow::TWO_POW_15
            + self.wisdom.into() * pow::TWO_POW_20
            + self.charisma.into() * pow::TWO_POW_25)
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
}

#[test]
#[available_gas(1500000)]
fn test_stats_packing() {

    // zero case
    let stats = Stats {
        strength: 0,
        dexterity: 0,
        vitality: 0,
        intelligence: 0,
        wisdom: 0,
        charisma: 0
    };

    let packed = stats.pack();
    let unpacked = StatsPacking::unpack(packed);
    
    assert(stats.strength ==  unpacked.strength, 'strength should be the same');
    assert(stats.dexterity ==  unpacked.dexterity, 'dexterity should be the same');
    assert(stats.vitality ==  unpacked.vitality, 'vitality should be the same');
    assert(stats.intelligence ==  unpacked.intelligence, 'intelligence should be the same');
    assert(stats.wisdom ==  unpacked.wisdom, 'wisdom should be the same');
    assert(stats.charisma ==  unpacked.charisma, 'charisma should be the same');

    // max stat case (2^5 - 1 = 31)
    let stats = Stats {
        strength: 31,
        dexterity: 31,
        vitality: 31,
        intelligence: 31,
        wisdom: 31,
        charisma: 31
    };

    let packed = stats.pack();
    let unpacked = StatsPacking::unpack(packed);

    assert(stats.strength ==  unpacked.strength, 'strength should be the same');
    assert(stats.dexterity ==  unpacked.dexterity, 'dexterity should be the same');
    assert(stats.vitality ==  unpacked.vitality, 'vitality should be the same');
    assert(stats.intelligence ==  unpacked.intelligence, 'intelligence should be the same');
    assert(stats.wisdom ==  unpacked.wisdom, 'wisdom should be the same');
    assert(stats.charisma ==  unpacked.charisma, 'charisma should be the same');

    //overflow case - should overflow back to 0
    let stats = Stats {
        strength: 32,
        dexterity: 32,
        vitality: 32,
        intelligence: 32,
        wisdom: 32,
        charisma: 32
    };

    let packed = stats.pack();
    let unpacked = StatsPacking::unpack(packed);

    // strength will overflow to zero
    assert(unpacked.strength == 0, 'strength should overflow to 0');

    // strength will overflow 1 into dexterity
    assert(unpacked.dexterity == 1, 'dexterity should overflow to 1');

    // dexterity will overflow 1 into vitality
    assert(unpacked.vitality == 1, 'vitality should overflow to 1');

    // vitality will overflow 1 into intelligence
    assert(unpacked.intelligence == 1, 'intelligence should ovrflw to 1');

    // intelligence will overflow 1 into wisdom
    assert(unpacked.wisdom == 1, 'wisdom should overflow to 1');

    // wisdom will overflow 1 into charisma
    assert(unpacked.charisma == 1, 'charisma should overflow to 1');
}