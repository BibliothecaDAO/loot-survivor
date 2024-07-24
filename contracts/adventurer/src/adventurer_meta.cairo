use core::integer::u256_try_as_non_zero;
use starknet::{StorePacking};
use traits::{TryInto, Into};
use super::stats::{Stats, StatsPacking, ImplStats};

#[derive(Drop, Copy, Serde)]
struct AdventurerMetadata {
    birth_date: u64, // 64 bits in storage
    death_date: u64, // 64 bits in storage
    delay_stat_reveal: bool, // 1 bit in storage
}

impl PackingAdventurerMetadata of StorePacking<AdventurerMetadata, felt252> {
    fn pack(value: AdventurerMetadata) -> felt252 {
        let mut delay_stat_reveal = 0;
        if value.delay_stat_reveal {
            delay_stat_reveal = 1;
        }

        (value.birth_date.into()
            + value.death_date.into() * TWO_POW_64
            + delay_stat_reveal.into() * TWO_POW_128)
            .try_into()
            .unwrap()
    }
    fn unpack(value: felt252) -> AdventurerMetadata {
        let packed = value.into();
        let (packed, birth_date) = integer::U256DivRem::div_rem(
            packed, TWO_POW_64.try_into().unwrap()
        );
        let (packed, death_date) = integer::U256DivRem::div_rem(
            packed, TWO_POW_64.try_into().unwrap()
        );
        let (_, delay_stat_reveal) = integer::U256DivRem::div_rem(
            packed, TWO_POW_1.try_into().unwrap()
        );

        let mut delay_stat_reveal_bool = false;
        if delay_stat_reveal == 1 {
            delay_stat_reveal_bool = true;
        }

        AdventurerMetadata {
            birth_date: birth_date.try_into().unwrap(),
            death_date: death_date.try_into().unwrap(),
            delay_stat_reveal: delay_stat_reveal_bool,
        }
    }
}

#[generate_trait]
impl ImplAdventurerMetadata of IAdventurerMetadata {
    // @notice: Creates a new AdventurerMetadata struct
    // @dev: AdventurerMetadata is initialized without any starting stats
    // @param birth_date: The start time of the adventurer
    // @param delay_reveal: Whether the adventurer should delay reveal
    // @return: The newly created AdventurerMetadata struct
    fn new(birth_date: u64, delay_stat_reveal: bool) -> AdventurerMetadata {
        AdventurerMetadata { birth_date, death_date: 0, delay_stat_reveal }
    }

    // @notice: Generates a start entropy for the adventurer
    // @dev: The start entropy is used for game fixed entropy such as generating item specials
    // @param adventurer_entropy: The entropy of the adventurer
    // @return: The start entropy
    fn generate_start_entropy(adventurer_entropy: felt252) -> u64 {
        let (_, r) = integer::U256DivRem::div_rem(
            adventurer_entropy.into(), u256_try_as_non_zero(U64_MAX.into()).unwrap()
        );
        r.try_into().unwrap()
    }
}

const TWO_POW_1: u256 = 0x2;
const TWO_POW_64: u256 = 0x10000000000000000;
const TWO_POW_128: u256 = 0x100000000000000000000000000000000;
const U64_MAX: u64 = 18446744073709551615;

#[cfg(test)]
#[test]
#[available_gas(1187400)]
fn test_adventurer_metadata_packing() {
    // max value case
    let meta = AdventurerMetadata {
        birth_date: U64_MAX, death_date: U64_MAX, delay_stat_reveal: true,
    };
    let packed = PackingAdventurerMetadata::pack(meta);
    let unpacked: AdventurerMetadata = PackingAdventurerMetadata::unpack(packed);
    assert(meta.birth_date == unpacked.birth_date, 'start time should be max u64');
    assert(meta.death_date == unpacked.death_date, 'end time should be max u64');
    assert(meta.delay_stat_reveal == unpacked.delay_stat_reveal, 'delay reveal should be true');

    // zero case
    let meta = AdventurerMetadata { birth_date: 0, death_date: 0, delay_stat_reveal: false };
    let packed = PackingAdventurerMetadata::pack(meta);
    let unpacked: AdventurerMetadata = PackingAdventurerMetadata::unpack(packed);
    assert(unpacked.birth_date == 0, 'start time should be 0');
    assert(unpacked.death_date == 0, 'end time should be 0');
    assert(unpacked.delay_stat_reveal == false, 'delay reveal should be false');
}
