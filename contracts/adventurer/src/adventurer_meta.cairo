use core::integer::u256_try_as_non_zero;
use starknet::{StorePacking};
use traits::{TryInto, Into};
use super::stats::{Stats, StatsPacking, StatUtils};

#[derive(Drop, Copy, Serde)]
struct AdventurerMetadata {
    start_entropy: u64, // 64 bits in storage
    starting_stats: Stats, // 24 bits in storage
    name: u128, // 128 bits in storage
    interface_camel: bool, // 1 bit bool in storage
}

impl PackingAdventurerMetadata of StorePacking<AdventurerMetadata, felt252> {
    fn pack(value: AdventurerMetadata) -> felt252 {
        let interface_camel_u256: u256 = if value.interface_camel {
            1
        } else {
            0
        };

        (value.start_entropy.into()
            + StatsPacking::pack(value.starting_stats).into() * TWO_POW_64
            + interface_camel_u256 * TWO_POW_91
            + value.name.into() * TWO_POW_92)
            .try_into()
            .unwrap()
    }
    fn unpack(value: felt252) -> AdventurerMetadata {
        let packed = value.into();
        let (packed, start_entropy) = integer::U256DivRem::div_rem(
            packed, TWO_POW_64.try_into().unwrap()
        );
        let (packed, starting_stats) = integer::U256DivRem::div_rem(
            packed, TWO_POW_27.try_into().unwrap()
        );
        let (packed, interface_camel_u256) = integer::U256DivRem::div_rem(
            packed, TWO_POW_1.try_into().unwrap()
        );
        let (_, name) = integer::U256DivRem::div_rem(packed, TWO_POW_128.try_into().unwrap());

        let interface_camel = interface_camel_u256 == 1;

        AdventurerMetadata {
            start_entropy: start_entropy.try_into().unwrap(),
            starting_stats: StatsPacking::unpack(starting_stats.try_into().unwrap()),
            name: name.try_into().unwrap(),
            interface_camel
        }
    }
}

#[generate_trait]
impl ImplAdventurerMetadata of IAdventurerMetadata {
    // @notice: Creates a new AdventurerMetadata struct
    // @dev: AdventurerMetadata is initialized without any starting stats
    // @param name: The name of the adventurer
    // @param interface_camel: Whether the players account is using a camelcase interface
    // @return: The newly created AdventurerMetadata struct
    fn new(name: u128, interface_camel: bool) -> AdventurerMetadata {
        AdventurerMetadata { name, start_entropy: 0, starting_stats: StatUtils::new(), interface_camel }
    }

    fn generate_start_entropy(adventurer_entropy: felt252) -> u64 {
        let (_, r) = integer::U256DivRem::div_rem(
            adventurer_entropy.into(), u256_try_as_non_zero(U64_MAX.into()).unwrap()
        );
        r.try_into().unwrap()
    }
}

const TWO_POW_1: u256 = 0x2;
const TWO_POW_24: u256 = 0x1000000;
const TWO_POW_64: u256 = 0x10000000000000000;
const TWO_POW_88: u256 = 0x10000000000000000000000;
const TWO_POW_89: u256 = 0x20000000000000000000000;
const TWO_POW_128: u256 = 0x100000000000000000000000000000000;
const TWO_POW_91: u256 = 0x80000000000000000000000; // 2^91
const TWO_POW_92: u256 = 0x100000000000000000000000; // 2^92
const TWO_POW_27: u256 = 0x8000000; // 2^27
const U64_MAX: u64 = 18446744073709551615;


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
        luck: 0
    };
    let interface_camel = true;

    let meta = AdventurerMetadata {
        start_entropy: max_u64,
        starting_stats: max_starting_stats,
        name: max_name_length,
        interface_camel
    };

    let packed = PackingAdventurerMetadata::pack(meta);
    let unpacked: AdventurerMetadata = PackingAdventurerMetadata::unpack(packed);
    assert(meta.name == unpacked.name, 'name should be max');
    assert(meta.start_entropy == unpacked.start_entropy, 'sblock should be max u64');
    assert(
        meta.starting_stats.strength == unpacked.starting_stats.strength, 'strength should be max'
    );
    assert(
        meta.starting_stats.dexterity == unpacked.starting_stats.dexterity,
        'dexterity should be max'
    );
    assert(
        meta.starting_stats.vitality == unpacked.starting_stats.vitality, 'vitality should be max'
    );
    assert(
        meta.starting_stats.intelligence == unpacked.starting_stats.intelligence,
        'intelligence should be max'
    );
    assert(meta.starting_stats.wisdom == unpacked.starting_stats.wisdom, 'wisdom should be max');
    assert(
        meta.starting_stats.charisma == unpacked.starting_stats.charisma, 'charisma should be max'
    );
    assert(meta.interface_camel == unpacked.interface_camel, 'interface_camel should be true');

    // zero case
    let zero_starting_stats = Stats {
        strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0, luck: 0
    };
    let interface_camel = false;
    let meta = AdventurerMetadata {
        start_entropy: 0, starting_stats: zero_starting_stats, name: 0, interface_camel
    };
    let packed = PackingAdventurerMetadata::pack(meta);
    let unpacked: AdventurerMetadata = PackingAdventurerMetadata::unpack(packed);
    assert(unpacked.name == 0, 'name should be 0');
    assert(unpacked.start_entropy == 0, 'entropy should be 0');
    assert(
        meta.starting_stats.strength == unpacked.starting_stats.strength, 'strength should be 0'
    );
    assert(
        meta.starting_stats.dexterity == unpacked.starting_stats.dexterity, 'dexterity should be 0'
    );
    assert(
        meta.starting_stats.vitality == unpacked.starting_stats.vitality, 'vitality should be 0'
    );
    assert(
        meta.starting_stats.intelligence == unpacked.starting_stats.intelligence,
        'intelligence should be 0'
    );
    assert(meta.starting_stats.wisdom == unpacked.starting_stats.wisdom, 'wisdom should be 0');
    assert(
        meta.starting_stats.charisma == unpacked.starting_stats.charisma, 'charisma should be 0'
    );
    assert(unpacked.interface_camel == interface_camel, 'interface_camel should be false');
}
