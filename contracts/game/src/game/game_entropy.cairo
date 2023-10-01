use integer::u256_try_as_non_zero;
use poseidon::poseidon_hash_span;
use starknet::{StorePacking};

#[derive(Drop, Copy, Serde)]
struct GameEntropy {
    hash: felt252,
    last_updated_block: u64,
    last_updated_time: u64,
}

impl GameEntropyPacking of StorePacking<GameEntropy, felt252> {
    fn pack(value: GameEntropy) -> felt252 {
        (value.hash.into()
            + (value.last_updated_block.into() * TWO_POW_123)
            + (value.last_updated_time.into() * TWO_POW_187))
            .try_into()
            .unwrap()
    }

    fn unpack(value: felt252) -> GameEntropy {
        let packed = value.into();
        let (packed, entropy) = integer::U256DivRem::div_rem(
            packed, TWO_POW_123.try_into().unwrap()
        );
        let (packed, last_updated_block) = integer::U256DivRem::div_rem(
            packed, TWO_POW_64.try_into().unwrap()
        );
        let (_, last_updated_time) = integer::U256DivRem::div_rem(
            packed, TWO_POW_64.try_into().unwrap()
        );

        GameEntropy {
            hash: entropy.try_into().unwrap(),
            last_updated_block: last_updated_block.try_into().unwrap(),
            last_updated_time: last_updated_time.try_into().unwrap(),
        }
    }
}

#[generate_trait]
impl ImplGameEntropy of IGameEntropy {
    fn generate_entropy(block_number: u64, block_timestamp: u64) -> felt252 {
        let mut hash_span = ArrayTrait::<felt252>::new();
        hash_span.append(block_timestamp.into());
        hash_span.append(block_number.into());
        poseidon_hash_span(hash_span.span())
    }
}

const TWO_POW_64: u256 = 0x10000000000000000;
const TWO_POW_123: u256 = 0x8000000000000000000000000000000;
const TWO_POW_187: u256 = 0x80000000000000000000000000000000000000000000000;
const U128_MAX: u128 = 340282366920938463463374607431768211455;

// ---------------------------
// ---------- Tests ----------
// ---------------------------
#[cfg(test)]
mod tests {
    use game::game::game_entropy::{GameEntropy, GameEntropyPacking};

    #[test]
    #[available_gas(199420)]
    fn test_packing_and_unpacking_game_entropy() {
        // max value case
        let game_entropy = GameEntropy {
            hash: 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFF,
            last_updated_block: 0xFFFFFFFFFFFFFFFF,
            last_updated_time: 0xFFFFFFFFFFFFFFFF
        };
        let unpacked: GameEntropy = GameEntropyPacking::unpack(
            GameEntropyPacking::pack(game_entropy)
        );

        assert(unpacked.hash == game_entropy.hash, 'wrong entropy max value');
        assert(
            unpacked.last_updated_block == game_entropy.last_updated_block,
            'wrong last update block max'
        );

        // zero case
        let game_entropy = GameEntropy { hash: 0, last_updated_block: 0, last_updated_time: 0 };
        let unpacked: GameEntropy = GameEntropyPacking::unpack(
            GameEntropyPacking::pack(game_entropy)
        );

        assert(unpacked.hash == game_entropy.hash, 'wrong entropy zero');
        assert(
            unpacked.last_updated_block == game_entropy.last_updated_block,
            'wrong last_updated_block zero'
        );
    }
}
