use pack::{constants::pow, pack::{Packing, rshift_split}};

#[derive(Drop, Copy, Serde)]
struct GameEntropy {
    entropy: u128,
    last_updated: u64,
}

impl GameEntropyPacking of Packing<GameEntropy> {
    fn pack(self: GameEntropy) -> felt252 {
        (self.entropy.into()
            + self.last_updated.into() * pow::TWO_POW_128)
            .try_into()
            .expect('pack GameEntropy')
    }

    fn unpack(packed: felt252) -> GameEntropy {
        let packed = packed.into();
        let (packed, entropy) = rshift_split(packed, pow::TWO_POW_128);
        let (_, last_updated) = rshift_split(packed, pow::TWO_POW_128);

        GameEntropy {
            entropy: entropy.try_into().unwrap(), last_updated: last_updated.try_into().unwrap(),
        }
    }
    // Not used for game entropy
    fn overflow_pack_protection(self: GameEntropy) -> GameEntropy {
        self
    }
}

// ---------------------------
// ---------- Tests ----------
// ---------------------------
#[cfg(test)]
mod tests {
    use game::game::game_entropy::{GameEntropy, GameEntropyPacking};
    use pack::{pack::{Packing}};

    #[test]
    #[available_gas(3000000)]
    fn test_packing_and_unpacking_game_entropy() {
        let game_entropy = GameEntropy { entropy: 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF, last_updated: 0xFFFFFFFFFFFFFFFF };
        let unpacked: GameEntropy = Packing::unpack(game_entropy.pack());

        assert(unpacked.entropy == game_entropy.entropy, 'wrong entropy max value');
        assert(unpacked.last_updated == game_entropy.last_updated, 'wrong last_updated max value');

        let game_entropy = GameEntropy { entropy: 0, last_updated: 0 };
        let unpacked: GameEntropy = Packing::unpack(game_entropy.pack());

        assert(unpacked.entropy == game_entropy.entropy, 'wrong entropy zero');
        assert(unpacked.last_updated == game_entropy.last_updated, 'wrong last_updated zero');
    }
}
