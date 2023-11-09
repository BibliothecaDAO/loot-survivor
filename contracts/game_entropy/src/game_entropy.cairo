use poseidon::poseidon_hash_span;
use starknet::{StorePacking};
use super::constants;

#[derive(Drop, Copy, Serde)]
struct GameEntropy {
    hash: felt252, // not stored
    last_updated_block: u64, // 64 bits in storage
    last_updated_time: u64, // 64 bits in storage
    next_update_block: u64, // 64 bits in storage
}

impl GameEntropyPacking of StorePacking<GameEntropy, felt252> {
    // @notice: packs a GameEntropy struct into a felt252
    // @dev: we don't store hash since it can be calculated dynamically
    // @param value: the GameEntropy struct to pack
    fn pack(value: GameEntropy) -> felt252 {
        (value.last_updated_block.into()
            + (value.last_updated_time.into() * TWO_POW_64)
            + (value.next_update_block.into() * TWO_POW_128))
            .try_into()
            .unwrap()
    }

    // @notice: unpacks a felt252 into a GameEntropy struct
    // @dev: entropy hash is calculated during unpack
    // @param value: the felt252 to unpack
    fn unpack(value: felt252) -> GameEntropy {
        let packed = value.into();
        let (packed, last_updated_block) = integer::U256DivRem::div_rem(
            packed, TWO_POW_64.try_into().unwrap()
        );
        let (packed, last_updated_time) = integer::U256DivRem::div_rem(
            packed, TWO_POW_64.try_into().unwrap()
        );
        let (_, next_update_block) = integer::U256DivRem::div_rem(
            packed, TWO_POW_64.try_into().unwrap()
        );

        let last_updated_block = last_updated_block.try_into().unwrap();
        let last_updated_time = last_updated_time.try_into().unwrap();
        let next_update_block = next_update_block.try_into().unwrap();
        ImplGameEntropy::new(last_updated_block, last_updated_time, next_update_block)
    }
}

#[generate_trait]
impl ImplGameEntropy of IGameEntropy {
    /// @notice Create a new instance of the GameEntropy struct
    /// @param last_updated_block The block number when the game was last updated.
    /// @param last_updated_time The timestamp when the game was last updated.
    /// @param next_update_block The block number for the next scheduled update.
    /// @return A new instance of GameEntropy.
    fn new(last_updated_block: u64, last_updated_time: u64, next_update_block: u64) -> GameEntropy {
        let hash = ImplGameEntropy::get_hash(
            last_updated_block, last_updated_time, next_update_block
        );
        GameEntropy { hash, last_updated_block, last_updated_time, next_update_block }
    }

    /// @notice Calculate a hash based on the properties of the GameEntropy struct
    /// @return A 252-bit hash value
    fn get_hash(
        last_updated_block: u64, last_updated_time: u64, next_update_block: u64
    ) -> felt252 {
        let mut hash_span = ArrayTrait::<felt252>::new();
        hash_span.append(last_updated_block.into());
        hash_span.append(last_updated_time.into());
        hash_span.append(next_update_block.into());
        poseidon_hash_span(hash_span.span())
    }

    /// @notice Calculate the number of blocks produced per hour
    /// @param previous_block_number The previous block's number.
    /// @param previous_block_timestamp The timestamp of the previous block.
    /// @param current_block_number The current block's number.
    /// @param current_block_timestamp The timestamp of the current block.
    /// @return The number of blocks produced per hour.
    fn calculate_blocks_per_hour(
        previous_block_number: u64,
        previous_block_timestamp: u64,
        current_block_number: u64,
        current_block_timestamp: u64
    ) -> u64 {
        let block_number_diff = current_block_number - previous_block_number;
        let block_timestamp_diff = current_block_timestamp - previous_block_timestamp;
        block_number_diff * 3600 / block_timestamp_diff
    }

    /// @notice Calculate the current rate of blocks produced per hour, based on a ten-minute window.
    /// @return The number of blocks produced per hour.
    #[inline(always)]
    fn current_blocks_per_hour(self: GameEntropy) -> u64 {
        (self.next_update_block - self.last_updated_block) * 2
    }

    /// @notice Calculate the next scheduled update block based on the current block and block production rate.
    /// @param current_block The current block number.
    /// @param blocks_per_hour The estimated block production rate per hour.
    /// @return The block number for the next update.
    #[inline(always)]
    fn calculate_next_update_block(current_block: u64, blocks_per_hour: u64) -> u64 {
        current_block + (blocks_per_hour / 2)
    }

    /// @notice Get the rate limit based on the current block production rate.
    /// @return The rate limit.
    #[inline(always)]
    fn get_rate_limit(self: GameEntropy) -> u64 {
        let blocks_per_hour = self.current_blocks_per_hour();
        if blocks_per_hour < constants::RATE_LIMIT_ACTIONS_PER_HOUR.into() {
            constants::RATE_LIMIT_ACTIONS_PER_HOUR.into() / blocks_per_hour
        } else {
            // if the current blocks per hour exceeds the rate limit, we return 1
            // which means 1 action per block
            1
        }
    }

    /// @notice Determine if an adventurer is idle based on the number of idle blocks.
    /// @param idle_blocks The number of blocks the adventurer has been idle.
    /// @return True if the adventurer is idle, false otherwise.
    #[inline(always)]
    fn is_adventurer_idle(self: GameEntropy, idle_blocks: u64) -> bool {
        idle_blocks > self.get_idle_penalty_blocks()
    }

    /// @notice Get the number of penalty blocks for being idle.
    /// @return The number of penalty blocks.
    #[inline(always)]
    fn get_idle_penalty_blocks(self: GameEntropy) -> u64 {
        (self.next_update_block - self.last_updated_block) / 3 - 1
    }
}

const TWO_POW_64: u256 = 0x10000000000000000;
const TWO_POW_123: u256 = 0x8000000000000000000000000000000;
const TWO_POW_128: u256 = 0x100000000000000000000000000000000;
const TWO_POW_187: u256 = 0x80000000000000000000000000000000000000000000000;
const U128_MAX: u128 = 340282366920938463463374607431768211455;

// ---------------------------
// ---------- Tests ----------
// ---------------------------
#[cfg(test)]
mod tests {
    use game_entropy::game_entropy::{GameEntropy, ImplGameEntropy, GameEntropyPacking};
    #[test]
    #[available_gas(22080)]
    fn test_new_entropy() {
        let last_updated_block = 282360;
        let last_updated_time = 1696209920;
        let next_update_block = 282364;

        let game_entropy = ImplGameEntropy::new(
            last_updated_block, last_updated_time, next_update_block
        );
        assert(game_entropy.hash != 0, 'hash should be set');
        assert(game_entropy.last_updated_block == last_updated_block, 'wrong last_updated_block');
        assert(game_entropy.last_updated_time == last_updated_time, 'wrong last_updated_time');
        assert(game_entropy.next_update_block == next_update_block, 'wrong next_update_block');
    }

    #[test]
    #[available_gas(18580)]
    fn test_get_hash() {
        // zero case
        let last_updated_block = 0;
        let last_updated_time = 0;
        let next_update_block = 0;
        let hash = ImplGameEntropy::get_hash(
            last_updated_block, last_updated_time, next_update_block
        );
    }

    #[test]
    #[available_gas(14280)]
    fn test_is_adventurer_idle() {
        let hash = 0x123;
        let last_updated_block = 282360;
        let last_updated_time = 1696209920;
        let next_update_block = 282364;

        let game_entropy = GameEntropy {
            hash, last_updated_block, last_updated_time, next_update_block,
        };

        let adventurer_idle_blocks = 3;
        let is_idle = game_entropy.is_adventurer_idle(adventurer_idle_blocks);
        assert(!is_idle, 'should not be idle');

        let adventurer_idle_blocks = 4;
        let is_idle = game_entropy.is_adventurer_idle(adventurer_idle_blocks);
        assert(is_idle, 'should be idle');
    }

    #[test]
    #[available_gas(15960)]
    fn test_calculate_next_update_block() {
        let current_block = 1;

        // currently starknet blockspeed
        let blocks_per_hour = 20;

        let next_entropy_rotation = ImplGameEntropy::calculate_next_update_block(
            current_block, blocks_per_hour
        );

        // next entropy rotation is in 3 blocks which is 10 minutes
        // at 1 block per 3mins (20 blocks per hour)
        assert(next_entropy_rotation == 4, 'wrong rotation, slow speed');

        // starknet expects to eventually be producing blocks every 30s (2 per min, 120 per hour)
        let blocks_per_hour = 120;
        let next_entropy_rotation = ImplGameEntropy::calculate_next_update_block(
            current_block, blocks_per_hour
        );
        // after this blockspeed, ten minutes is now 20 blocks in the future
        assert(next_entropy_rotation == 21, 'wrong rotation, fast speed');
    }

    #[test]
    #[available_gas(6350)]
    fn test_current_blocks_per_hour() {
        let game_entropy = GameEntropy {
            hash: 0x123,
            last_updated_block: 282465,
            last_updated_time: 1696214108,
            next_update_block: 282481,
        };
        let blocks_per_hour = game_entropy.current_blocks_per_hour();
        assert(blocks_per_hour == 96, 'wrong blocks per hour')
    }

    #[test]
    #[available_gas(29280)]
    fn test_calculate_blocks_per_hour() {
        // normal case using current starknet goerli data
        let previous_block_number = 876324;
        let previous_block_timestamp = 1696190267;
        let current_block_number = 876332;
        let current_block_timestamp = 1696191730;

        let blocks_per_hour = ImplGameEntropy::calculate_blocks_per_hour(
            previous_block_number,
            previous_block_timestamp,
            current_block_number,
            current_block_timestamp
        );
        assert(blocks_per_hour == 19, 'wrong blocks per hour standard');

        // extreme value case, 10 blocks a second
        let previous_block_number = 1;
        let previous_block_timestamp = 1;
        let current_block_number = 10;
        let current_block_timestamp = 2;
        let blocks_per_hour = ImplGameEntropy::calculate_blocks_per_hour(
            previous_block_number,
            previous_block_timestamp,
            current_block_number,
            current_block_timestamp
        );
        assert(blocks_per_hour == 32400, 'wrong blocks per hour xtreme');
    }

    #[test]
    #[available_gas(243220)]
    fn test_game_entropy_packing() {
        // max value case

        let game_entropy = GameEntropy {
            hash: 0x123,
            last_updated_block: 0xFFFFFFFFFFFFFFFF,
            last_updated_time: 0xFFFFFFFFFFFFFFFF,
            next_update_block: 0xFFFFFFFFFFFFFFFF,
        };
        let unpacked: GameEntropy = GameEntropyPacking::unpack(
            GameEntropyPacking::pack(game_entropy)
        );
        assert(
            unpacked.last_updated_block == game_entropy.last_updated_block,
            'wrong last update block max'
        );
        assert(
            unpacked.last_updated_time == game_entropy.last_updated_time,
            'wrong last update time max'
        );
        assert(
            unpacked.next_update_block == game_entropy.next_update_block,
            'wrong next update block max'
        );

        // zero case
        let game_entropy = GameEntropy {
            hash: 0, last_updated_block: 0, last_updated_time: 0, next_update_block: 0
        };
        let unpacked: GameEntropy = GameEntropyPacking::unpack(
            GameEntropyPacking::pack(game_entropy)
        );
        assert(
            unpacked.last_updated_block == game_entropy.last_updated_block,
            'wrong last_updated_block zero'
        );
        assert(
            unpacked.last_updated_time == game_entropy.last_updated_time,
            'wrong last_updated_time zero'
        );
        assert(
            unpacked.next_update_block == game_entropy.next_update_block,
            'wrong next_update_block zero'
        );
    }
}
