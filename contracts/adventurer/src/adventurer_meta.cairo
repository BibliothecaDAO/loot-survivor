use option::OptionTrait;
use traits::{TryInto, Into};

use pack::constants::pow;
use pack::pack::{Packing, rshift_split};

#[derive(Drop, Copy, Serde)]
struct AdventurerMetadata {
    name: u32,
    home_realm: u8,
    race: u8,
    order: u8,
    entropy: u64,
}

impl PackingAdventurerMetadata of Packing<AdventurerMetadata> {
    fn pack(self: AdventurerMetadata) -> felt252 {
        (self.name.into()
         + self.home_realm.into() * pow::TWO_POW_32
         + self.race.into() * pow::TWO_POW_40
         + self.order.into() * pow::TWO_POW_48
         + self.entropy.into() * pow::TWO_POW_56
        ).try_into().unwrap()
    }
    fn unpack(packed: felt252) -> AdventurerMetadata {
        let packed = packed.into();
        let (packed, name) = rshift_split(packed, pow::TWO_POW_32);
        let (packed, home_realm) = rshift_split(packed, pow::TWO_POW_8);
        let (packed, race) = rshift_split(packed, pow::TWO_POW_8);
        let (packed, order) = rshift_split(packed, pow::TWO_POW_8);
        let (_, entropy) = rshift_split(packed, pow::TWO_POW_64);

        AdventurerMetadata {
            name: name.try_into().unwrap(),
            home_realm: home_realm.try_into().unwrap(),
            race: race.try_into().unwrap(),
            order: order.try_into().unwrap(),
            entropy: entropy.try_into().unwrap()
        }
    }
}

#[cfg(test)]
#[test]
#[available_gas(50000000)]
fn test_meta() {
    let meta = AdventurerMetadata {
        name: 4294962295, home_realm: 45, race: 28, order: 6, entropy: 4294937295
    };

    let packed = meta.pack();
    let unpacked: AdventurerMetadata = Packing::unpack(packed);
    assert(meta.name == unpacked.name, 'name');
    assert(meta.home_realm == unpacked.home_realm, 'home_realm');
    assert(meta.race == unpacked.race, 'race');
    assert(meta.order == unpacked.order, 'order');
    assert(meta.entropy == unpacked.entropy, 'entropy');
}
