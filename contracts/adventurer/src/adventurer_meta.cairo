use starknet::{StorePacking};

#[derive(Drop, Copy, Serde)]
struct AdventurerMetadata {
    birth_date: u64, // 64 bits in storage
    death_date: u64, // 64 bits in storage
    level_seed: u64, // 64 bits in storage
    item_specials_seed: u16, // 16 bits in storage
    delay_stat_reveal: bool, // 1 bit in storage
}

impl PackingAdventurerMetadata of StorePacking<AdventurerMetadata, felt252> {
    /// @notice: Packs an AdventurerMetadata struct into a felt252
    /// @param value: The AdventurerMetadata struct to pack
    /// @return: The packed felt252
    fn pack(value: AdventurerMetadata) -> felt252 {
        let delay_stat_reveal = if value.delay_stat_reveal {
            1
        } else {
            0
        };

        (value.birth_date.into()
            + value.death_date.into() * TWO_POW_64
            + value.level_seed.into() * TWO_POW_128
            + value.item_specials_seed.into() * TWO_POW_192
            + delay_stat_reveal * TWO_POW_208)
            .try_into()
            .unwrap()
    }

    /// @notice: Unpacks a felt252 into an AdventurerMetadata struct
    /// @param value: The felt252 to unpack
    /// @return: The unpacked AdventurerMetadata struct
    fn unpack(value: felt252) -> AdventurerMetadata {
        let packed = value.into();

        let (packed, birth_date) = integer::U256DivRem::div_rem(packed, TWO_POW_64_NZ);
        let (packed, death_date) = integer::U256DivRem::div_rem(packed, TWO_POW_64_NZ);
        let (packed, level_seed) = integer::U256DivRem::div_rem(packed, TWO_POW_64_NZ);
        let (packed, item_specials_seed) = integer::U256DivRem::div_rem(packed, TWO_POW_16_NZ);
        let (_, delay_stat_reveal_u256) = integer::U256DivRem::div_rem(packed, TWO_POW_1_NZ);

        let delay_stat_reveal = delay_stat_reveal_u256 != 0;
        let birth_date = birth_date.try_into().unwrap();
        let death_date = death_date.try_into().unwrap();
        let level_seed = level_seed.try_into().unwrap();
        let item_specials_seed = item_specials_seed.try_into().unwrap();

        AdventurerMetadata {
            birth_date, death_date, level_seed, item_specials_seed, delay_stat_reveal,
        }
    }
}

#[generate_trait]
impl ImplAdventurerMetadata of IAdventurerMetadata {
    /// @notice: Creates a new AdventurerMetadata struct
    /// @dev: AdventurerMetadata is initialized without any starting stats
    /// @param birth_date: The start time of the adventurer
    /// @param delay_reveal: Whether the adventurer should delay reveal
    /// @return: The newly created AdventurerMetadata struct
    fn new(birth_date: u64, delay_stat_reveal: bool) -> AdventurerMetadata {
        AdventurerMetadata {
            birth_date, death_date: 0, level_seed: 0, item_specials_seed: 0, delay_stat_reveal
        }
    }
}

const TWO_POW_1: u256 = 0x2;
const TWO_POW_1_NZ: NonZero<u256> = 0x2;
const TWO_POW_16: u256 = 0x10000;
const TWO_POW_16_NZ: NonZero<u256> = 0x10000;
const TWO_POW_64: u256 = 0x10000000000000000;
const TWO_POW_64_NZ: NonZero<u256> = 0x10000000000000000;
const TWO_POW_128: u256 = 0x100000000000000000000000000000000;
const TWO_POW_192: u256 = 0x1000000000000000000000000000000000000000000000000;
const TWO_POW_208: u256 = 0x10000000000000000000000000000000000000000000000000000;

// ---------------------------
// ---------- Tests ----------
// ---------------------------
#[cfg(test)]
mod tests {
    use super::{AdventurerMetadata, PackingAdventurerMetadata, ImplAdventurerMetadata};
    const U64_MAX: u64 = 0xffffffffffffffff;
    const U16_MAX: u16 = 0xffff;

    #[test]
    #[available_gas(111090)]
    fn test_adventurer_metadata_pack_unpack_gas() {
        let meta = AdventurerMetadata {
            birth_date: U64_MAX,
            death_date: U64_MAX,
            level_seed: U64_MAX,
            item_specials_seed: U16_MAX,
            delay_stat_reveal: true,
        };
        PackingAdventurerMetadata::unpack(PackingAdventurerMetadata::pack(meta));
    }

    #[test]
    fn test_adventurer_metadata_packing() {
        // max value case
        let meta = AdventurerMetadata {
            birth_date: U64_MAX,
            death_date: U64_MAX,
            level_seed: U64_MAX,
            item_specials_seed: U16_MAX,
            delay_stat_reveal: true,
        };
        let packed = PackingAdventurerMetadata::pack(meta);
        let unpacked: AdventurerMetadata = PackingAdventurerMetadata::unpack(packed);
        assert(meta.birth_date == unpacked.birth_date, 'start time should be max u64');
        assert(meta.death_date == unpacked.death_date, 'end time should be max u64');
        assert(meta.level_seed == unpacked.level_seed, 'level seed should be max u64');
        assert(
            meta.item_specials_seed == unpacked.item_specials_seed,
            'item specials should be max u16'
        );
        assert(meta.delay_stat_reveal == unpacked.delay_stat_reveal, 'delay reveal should be true');

        // zero case
        let meta = AdventurerMetadata {
            birth_date: 0,
            death_date: 0,
            level_seed: 0,
            item_specials_seed: 0,
            delay_stat_reveal: false
        };
        let packed = PackingAdventurerMetadata::pack(meta);
        let unpacked: AdventurerMetadata = PackingAdventurerMetadata::unpack(packed);
        assert(unpacked.birth_date == 0, 'start time should be 0');
        assert(unpacked.death_date == 0, 'end time should be 0');
        assert(unpacked.level_seed == 0, 'level seed should be 0');
        assert(unpacked.item_specials_seed == 0, 'item specials seed should be 0');
        assert(unpacked.delay_stat_reveal == false, 'delay reveal should be false');
    }

    #[test]
    #[available_gas(1)]
    fn test_new_adventurer_metadata_gas() {
        ImplAdventurerMetadata::new(12345, false);
    }

    #[test]
    fn test_new_adventurer_metadata() {
        let birthdate = 12345;
        let meta = ImplAdventurerMetadata::new(birthdate, false);
        assert(meta.birth_date == birthdate, 'start time should be 12345');
        assert(meta.death_date == 0, 'end time should be 0');
        assert(meta.level_seed == 0, 'level seed should be 0');
        assert(meta.item_specials_seed == 0, 'item specials seed should be 0');
        assert(meta.delay_stat_reveal == false, 'delay reveal should be false');
    }
}
