use traits::{TryInto, Into};
use pack::constants::pow;
use pack::pack::{Packing, rshift_split};

#[derive(Drop, Copy, Serde)]
struct AdventurerMetadata {
    name: u128,
    entropy: u128,
}

impl PackingAdventurerMetadata of Packing<AdventurerMetadata> {
    fn pack(self: AdventurerMetadata) -> felt252 {
        (self.entropy.into()
            + self.name.into() * pow::TWO_POW_128)
            .try_into()
            .expect('pack AdventurerMetadata')
    }
    fn unpack(packed: felt252) -> AdventurerMetadata {
        let packed = packed.into();
        let (packed, entropy) = rshift_split(packed, pow::TWO_POW_128);
        let (_, name) = rshift_split(packed, pow::TWO_POW_128);
        AdventurerMetadata {
            name: name.try_into().expect('unpack AdvMetadata name'),
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
#[available_gas(96380)]
fn test_pack_unpack_adventurer_meta() {
    let meta = AdventurerMetadata {
        name: 'abcdefghijklmno',
        entropy: 340282366920938463463374607431768211455
    };

    let packed = meta.pack();
    let unpacked: AdventurerMetadata = Packing::unpack(packed);
    assert(meta.name == unpacked.name, 'name');
    assert(meta.entropy == unpacked.entropy, 'entropy');
}
