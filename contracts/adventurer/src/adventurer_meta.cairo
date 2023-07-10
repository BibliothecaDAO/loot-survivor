use option::OptionTrait;
use traits::{TryInto, Into};

use pack::constants::pow;
use pack::pack::{Packing, rshift_split};

#[derive(Drop, Copy, Serde)]
struct AdventurerMetadata {
    name: u64,
    home_realm: u16,
    race: u8,
    order: u8,
    entropy: u128,
}

impl PackingAdventurerMetadata of Packing<AdventurerMetadata> {
    fn pack(self: AdventurerMetadata) -> felt252 {
        (self.name.into()
            + self.home_realm.into() * pow::TWO_POW_64
            + self.race.into() * pow::TWO_POW_80
            + self.order.into() * pow::TWO_POW_88
            + self.entropy.into() * pow::TWO_POW_96)
            .try_into()
            .expect('pack AdventurerMetadata')
    }
    fn unpack(packed: felt252) -> AdventurerMetadata {
        let packed = packed.into();
        let (packed, name) = rshift_split(packed, pow::TWO_POW_64);
        let (packed, home_realm) = rshift_split(packed, pow::TWO_POW_16);
        let (packed, race) = rshift_split(packed, pow::TWO_POW_8);
        let (packed, order) = rshift_split(packed, pow::TWO_POW_8);
        let (_, entropy) = rshift_split(packed, pow::TWO_POW_128);

        AdventurerMetadata {
            name: name.try_into().expect('unpack AdvMetadata name'),
            home_realm: home_realm.try_into().expect('unpack AdvMetadata home_realm'),
            race: race.try_into().expect('unpack AdvMetadata race'),
            order: order.try_into().expect('unpack AdvMetadata order'),
            entropy: entropy.try_into().expect('unpack AdvMetadata entropy')
        }
    }
}

#[cfg(test)]
#[test]
#[available_gas(50000000)]
fn test_meta() {
    let meta = AdventurerMetadata {
        name: 'test1234',
        home_realm: 8000,
        race: 28,
        order: 6,
        entropy: 340282366920938463463374607431768211455
    };

    let packed = meta.pack();
    let unpacked: AdventurerMetadata = Packing::unpack(packed);
    assert(meta.name == unpacked.name, 'name');
    assert(meta.home_realm == unpacked.home_realm, 'home_realm');
    assert(meta.race == unpacked.race, 'race');
    assert(meta.order == unpacked.order, 'order');
    assert(meta.entropy == unpacked.entropy, 'entropy');
}
