use option::OptionTrait;
use traits::{TryInto, Into};

use pack::constants::pow;
use pack::pack::{Packing, rshift_split};

#[derive(Drop, Copy, Serde)]
struct AdventurerMetadata {
    name: u128,
    home_realm: u16,
    race: u8,
    entropy: u128,
}

impl PackingAdventurerMetadata of Packing<AdventurerMetadata> {
    fn pack(self: AdventurerMetadata) -> felt252 {
        (self.entropy.into()
            + self.home_realm.into() * pow::TWO_POW_128
            + self.race.into() * pow::TWO_POW_141
            + self.name.into() * pow::TWO_POW_145)
            .try_into()
            .expect('pack AdventurerMetadata')
    }
    fn unpack(packed: felt252) -> AdventurerMetadata {
        let packed = packed.into();
        let (packed, entropy) = rshift_split(packed, pow::TWO_POW_128);
        let (packed, home_realm) = rshift_split(packed, pow::TWO_POW_13);
        let (packed, race) = rshift_split(packed, pow::TWO_POW_4);
        let (_, name) = rshift_split(packed, pow::TWO_POW_107);

        AdventurerMetadata {
            name: name.try_into().expect('unpack AdvMetadata name'),
            home_realm: home_realm.try_into().expect('unpack AdvMetadata home_realm'),
            race: race.try_into().expect('unpack AdvMetadata race'),
            entropy: entropy.try_into().expect('unpack AdvMetadata entropy')
        }
    }

    // TODO: add overflow pack protection
    fn overflow_pack_protection(self: AdventurerMetadata) -> AdventurerMetadata {
        self
    }
}

#[cfg(test)]
#[test]
#[available_gas(50000000)]
fn test_meta() {
    let meta = AdventurerMetadata {
        name: 'abcdefghijklm',
        home_realm: 8000,
        race: 15,
        entropy: 340282366920938463463374607431768211455
    };

    let packed = meta.pack();
    let unpacked: AdventurerMetadata = Packing::unpack(packed);
    assert(meta.name == unpacked.name, 'name');
    assert(meta.home_realm == unpacked.home_realm, 'home_realm');
    assert(meta.race == unpacked.race, 'race');
    assert(meta.entropy == unpacked.entropy, 'entropy');
}
