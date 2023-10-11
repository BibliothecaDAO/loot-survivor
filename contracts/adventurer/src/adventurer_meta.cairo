use starknet::{StorePacking};
use traits::{TryInto, Into};
use super::stats::{Stats, StatsPacking};

#[derive(Drop, Copy, Serde)]
struct AdventurerMetadata {
    start_block: u64, // 64 bits
    starting_stats: Stats, // 24 bits
    name: u128, // 128 bits
}

impl PackingAdventurerMetadata of StorePacking<AdventurerMetadata, felt252> {
    fn pack(value: AdventurerMetadata) -> felt252 {
        (value.start_block.into()
            + StatsPacking::pack(value.starting_stats).into() * TWO_POW_64
            + value.name.into() * TWO_POW_88)
            .try_into()
            .unwrap()
    }
    fn unpack(value: felt252) -> AdventurerMetadata {
        let packed = value.into();
        let (packed, start_block) = integer::U256DivRem::div_rem(
            packed, TWO_POW_64.try_into().unwrap()
        );
        let (packed, starting_stats) = integer::U256DivRem::div_rem(
            packed, TWO_POW_24.try_into().unwrap()
        );
        let (_, name) = integer::U256DivRem::div_rem(packed, TWO_POW_128.try_into().unwrap());
        AdventurerMetadata {
            start_block: start_block.try_into().unwrap(),
            starting_stats: StatsPacking::unpack(starting_stats.try_into().unwrap()),
            name: name.try_into().unwrap()
        }
    }
}

const TWO_POW_24: u256 = 0x1000000;
const TWO_POW_64: u256 = 0x10000000000000000;
const TWO_POW_88: u256 = 0x10000000000000000000000;
const TWO_POW_128: u256 = 0x100000000000000000000000000000000;

#[cfg(test)]
#[test]
#[available_gas(1187400)]
fn test_adventurer_metadata_packing() {
    // max value case
    let max_u64 = 0xffffffffffffffff;
    let max_name_length = 'abcdefghijklmnop';
    let max_starting_stats = Stats {
        strength: 15,
        dexterity: 15,
        vitality: 15,
        intelligence: 15,
        wisdom: 15,
        charisma: 15,
        luck: 15
    };

    let meta = AdventurerMetadata {
        start_block: max_u64, starting_stats: max_starting_stats, name: max_name_length
    };

    let packed = PackingAdventurerMetadata::pack(meta);
    let unpacked: AdventurerMetadata = PackingAdventurerMetadata::unpack(packed);
    assert(meta.name == unpacked.name, 'name should be max');
    assert(meta.start_block == unpacked.start_block, 'sblock should be max u64');

    // zero case
    let zero_starting_stats = Stats {
        strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0, luck: 0
    };
    let meta = AdventurerMetadata { start_block: 0, starting_stats: zero_starting_stats, name: 0 };
    let packed = PackingAdventurerMetadata::pack(meta);
    let unpacked: AdventurerMetadata = PackingAdventurerMetadata::unpack(packed);
    assert(unpacked.name == 0, 'name should be 0');
    assert(unpacked.start_block == 0, 'entropy should be 0');
}
