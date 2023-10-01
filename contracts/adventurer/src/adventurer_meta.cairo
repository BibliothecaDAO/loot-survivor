use starknet::{StorePacking};
use traits::{TryInto, Into};

#[derive(Drop, Copy, Serde)]
struct AdventurerMetadata {
    name: u128,
    entropy: u128,
}

const TWO_POW_128: u256 = 0x100000000000000000000000000000000;

impl PackingAdventurerMetadata of StorePacking<AdventurerMetadata, felt252> {
    fn pack(value: AdventurerMetadata) -> felt252 {
        (value.entropy.into() + value.name.into() * TWO_POW_128).try_into().unwrap()
    }
    fn unpack(value: felt252) -> AdventurerMetadata {
        let packed = value.into();
        let (packed, entropy) = integer::U256DivRem::div_rem(
            packed, TWO_POW_128.try_into().unwrap()
        );
        let (_, name) = integer::U256DivRem::div_rem(packed, TWO_POW_128.try_into().unwrap());
        AdventurerMetadata { name: name.try_into().unwrap(), entropy: entropy.try_into().unwrap() }
    }
}

#[cfg(test)]
#[test]
#[available_gas(116600)]
fn test_pack_unpack_adventurer_meta() {
    // max value case
    let max_u128 = 340282366920938463463374607431768211455;
    let name_length = 'abcdefghijklmno';

    let meta = AdventurerMetadata { name: name_length, entropy: max_u128 };
    
    let packed = PackingAdventurerMetadata::pack(meta);
    let unpacked: AdventurerMetadata = PackingAdventurerMetadata::unpack(packed);
    assert(meta.name == unpacked.name, 'name should be max');
    assert(meta.entropy == unpacked.entropy, 'entropy should be max u128');

    // zero case
    let meta = AdventurerMetadata { name: 0, entropy: 0 };
    let packed = PackingAdventurerMetadata::pack(meta);
    let unpacked: AdventurerMetadata = PackingAdventurerMetadata::unpack(packed);
    assert(unpacked.name == 0, 'name should be 0');
    assert(unpacked.entropy == 0, 'entropy should be 0');
}