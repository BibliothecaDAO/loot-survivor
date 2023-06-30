use core::serde::Serde;
use integer::{
    U128IntoFelt252, Felt252IntoU256, Felt252TryIntoU64, U256TryIntoFelt252, u256_from_felt252,
    U256TryIntoU32, U256TryIntoU128, U256TryIntoU16, U256TryIntoU8, U256TryIntoU64
};
use traits::{TryInto, Into};
use option::OptionTrait;
use debug::PrintTrait;

use pack::pack::{Packing, pack_value, unpack_value};
use pack::constants::{pow, mask};

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
        (pack_value(self.name.into(), pow::TWO_POW_218) +
         pack_value(self.home_realm.into(), pow::TWO_POW_210) +
         pack_value(self.race.into(), pow::TWO_POW_202) +
         pack_value(self.order.into(), pow::TWO_POW_194) +
         pack_value(self.entropy.into(), pow::TWO_POW_130)).try_into().unwrap()
    }
    fn unpack(packed: felt252) -> AdventurerMetadata {
        let packed = packed.into();
        AdventurerMetadata {
            name: unpack_value(packed, pow::TWO_POW_218, mask::MASK_32).try_into().unwrap(),
            home_realm: unpack_value(packed, pow::TWO_POW_210, mask::MASK_8).try_into().unwrap(),
            race: unpack_value(packed, pow::TWO_POW_202, mask::MASK_8).try_into().unwrap(),
            order: unpack_value(packed, pow::TWO_POW_194, mask::MASK_8).try_into().unwrap(),
            entropy: unpack_value(packed, pow::TWO_POW_130, mask::MASK_64).try_into().unwrap()
        }
    }
}

#[test]
#[available_gas(50000000)]
fn test_meta() {
    let mut meta = AdventurerMetadata {
        name: 4294962295, home_realm: 45, race: 28, order: 6, entropy: 4294937295
    };

    let packed = meta.pack();
    //let unpacked = ImplAdventurerMetadata::unpack(packed);
    let unpacked: AdventurerMetadata = Packing::unpack(packed);
    assert(meta.name == unpacked.name, 'name');
    assert(meta.home_realm == unpacked.home_realm, 'home_realm');
    assert(meta.race == unpacked.race, 'race');
    assert(meta.order == unpacked.order, 'order');
    assert(meta.entropy == unpacked.entropy, 'entropy');
}
