use starknet::{StorePacking};

#[derive(Drop, Copy, Serde)]
struct GameEntropy {
    entropy: u128,
    last_updated: u64,
}

const TWO_POW_128: u256 = 0x100000000000000000000000000000000;

impl GameEntropyPacking of StorePacking<GameEntropy, felt252> {
    fn pack(value: GameEntropy) -> felt252 {
        (value.entropy.into() + (value.last_updated.into() * TWO_POW_128)).try_into().unwrap()
    }

    fn unpack(value: felt252) -> GameEntropy {
        let packed = value.into();
        let (packed, entropy) = integer::U256DivRem::div_rem(packed, TWO_POW_128.try_into().unwrap());
        let (_, last_updated) = integer::U256DivRem::div_rem(packed, TWO_POW_128.try_into().unwrap());

        GameEntropy {
            entropy: entropy.try_into().unwrap(), 
            last_updated: last_updated.try_into().unwrap(),
        }
    }
}

// ---------------------------
// ---------- Tests ----------
// ---------------------------
#[cfg(test)]
mod tests {
    use game::game::game_entropy::{GameEntropy, GameEntropyPacking};

    #[test]
    #[available_gas(3000000)]
    fn test_packing_and_unpacking_game_entropy() {
        // max value case
        let game_entropy = GameEntropy { entropy: 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF, last_updated: 0xFFFFFFFFFFFFFFFF };
        let unpacked: GameEntropy = GameEntropyPacking::unpack(GameEntropyPacking::pack(game_entropy));

        assert(unpacked.entropy == game_entropy.entropy, 'wrong entropy max value');
        assert(unpacked.last_updated == game_entropy.last_updated, 'wrong last_updated max value');

        // zero case
        let game_entropy = GameEntropy { entropy: 0, last_updated: 0 };
        let unpacked: GameEntropy = GameEntropyPacking::unpack(GameEntropyPacking::pack(game_entropy));

        assert(unpacked.entropy == game_entropy.entropy, 'wrong entropy zero');
        assert(unpacked.last_updated == game_entropy.last_updated, 'wrong last_updated zero');
    }
}
