use starknet::{StorePacking};

#[derive(Drop, Copy, Serde)]
struct GamesPlayedSnapshot {
    timestamp: u64, // 64 bits in storage
    game_count: u64, // 64 bits in storage
    locked: u8, // 1 bit in storage
}

impl GamesPlayedSnapshotPacking of StorePacking<GamesPlayedSnapshot, felt252> {
    fn pack(value: GamesPlayedSnapshot) -> felt252 {
        (value.timestamp.into()
            + (value.game_count.into() * TWO_POW_64)
            + (value.locked.into() * TWO_POW_128))
            .try_into()
            .unwrap()
    }
    fn unpack(value: felt252) -> GamesPlayedSnapshot {
        let packed = value.into();
        let (packed, timestamp) = integer::U256DivRem::div_rem(
            packed, TWO_POW_64.try_into().unwrap()
        );
        let (packed, game_count) = integer::U256DivRem::div_rem(
            packed, TWO_POW_64.try_into().unwrap()
        );
        let (_, locked) = integer::U256DivRem::div_rem(packed, TWO_POW_1.try_into().unwrap());

        let timestamp = timestamp.try_into().unwrap();
        let game_count = game_count.try_into().unwrap();
        let locked = locked.try_into().unwrap();
        GamesPlayedSnapshot { timestamp, game_count, locked }
    }
}

#[generate_trait]
impl GamesPlayedSnapshotImpl of IGamesPlayedSnapshot {
    fn games_per_day(
        self: GamesPlayedSnapshot, current_game_count: felt252, current_time: u64
    ) -> u64 {
        let games_played = current_game_count.try_into().unwrap() - self.game_count;
        let time_period = current_time - self.timestamp;
        games_played * DAY.into() / time_period
    }

    fn get_price_adjustment(
        current_price: u128, global_games_per_day: u64, snapshot_games_per_day: u64
    ) -> u128 {
        let buffer = global_games_per_day / BUFFER_PERCENTAGE;
        if snapshot_games_per_day > (global_games_per_day + buffer) {
            current_price * 11 / 10
        } else if snapshot_games_per_day < (global_games_per_day.into() - buffer) {
            current_price * 9 / 10
        } else {
            current_price
        }
    }
    fn unlock(self: GamesPlayedSnapshot) -> GamesPlayedSnapshot {
        GamesPlayedSnapshot { timestamp: self.timestamp, game_count: self.game_count, locked: 0 }
    }
}

const BUFFER_PERCENTAGE: u64 = 10;
const DAY: u32 = 86400;
const TWO_POW_1: u256 = 0x2;
const TWO_POW_64: u256 = 0x10000000000000000;
const TWO_POW_128: u256 = 0x100000000000000000000000000000000;

// ---------------------------
// ---------- Tests ----------
// ---------------------------
#[cfg(test)]
mod tests {
    use super::{GamesPlayedSnapshot, GamesPlayedSnapshotImpl, GamesPlayedSnapshotPacking, DAY};

    #[test]
    #[available_gas(101380)]
    fn test_pack_and_unpack_gas() {
        let timestamp = 1;
        let game_count = 1;
        let locked = 1;
        let games_played_snapshot = GamesPlayedSnapshot { timestamp, game_count, locked };
        let unpacked: GamesPlayedSnapshot = GamesPlayedSnapshotPacking::unpack(
            GamesPlayedSnapshotPacking::pack(games_played_snapshot)
        );

        assert(unpacked.timestamp == games_played_snapshot.timestamp, 'wrong unpacked timestamp');
        assert(
            unpacked.game_count == games_played_snapshot.game_count, 'wrong unpacked game count'
        );
        assert(unpacked.locked == games_played_snapshot.locked, 'wrong unpacked locked')
    }

    #[test]
    fn test_pack_and_unpack_zero() {
        let timestamp = 0;
        let game_count = 0;
        let locked = 0;

        let games_played_snapshot = GamesPlayedSnapshot { timestamp, game_count, locked };

        let unpacked: GamesPlayedSnapshot = GamesPlayedSnapshotPacking::unpack(
            GamesPlayedSnapshotPacking::pack(games_played_snapshot)
        );

        assert(unpacked.timestamp == games_played_snapshot.timestamp, 'wrong unpacked timestamp');
        assert(
            unpacked.game_count == games_played_snapshot.game_count, 'wrong unpacked game count'
        );
        assert(unpacked.locked == games_played_snapshot.locked, 'wrong unpacked locked')
    }

    #[test]
    fn test_pack_and_unpack_max() {
        let timestamp = 0xffffffffffffffff;
        let game_count = 0xffffffffffffffff;
        let locked = 1;

        let games_played_snapshot = GamesPlayedSnapshot { timestamp, game_count, locked };

        let unpacked: GamesPlayedSnapshot = GamesPlayedSnapshotPacking::unpack(
            GamesPlayedSnapshotPacking::pack(games_played_snapshot)
        );

        assert(unpacked.timestamp == games_played_snapshot.timestamp, 'wrong unpacked timestamp');
        assert(
            unpacked.game_count == games_played_snapshot.game_count, 'wrong unpacked game count'
        );
        assert(unpacked.locked == games_played_snapshot.locked, 'wrong unpacked locked')
    }

    #[test]
    fn test_unlock() {
        let locked_snapshot = GamesPlayedSnapshot { timestamp: 123, game_count: 50, locked: 1 };

        let unlocked_snapshot = locked_snapshot.unlock();

        assert(
            unlocked_snapshot.timestamp == locked_snapshot.timestamp, 'timestamp should not change'
        );
        assert(
            unlocked_snapshot.game_count == locked_snapshot.game_count,
            'game count should not change'
        );
        assert(unlocked_snapshot.locked == 0, 'locked should be 0');
    }

    #[test]
    fn test_games_per_day() {
        let snapshot_timestamp = 0;
        let snapshot_game_count = 0;
        let snapshot = GamesPlayedSnapshot {
            timestamp: snapshot_timestamp, game_count: snapshot_game_count, locked: 0
        };
        let current_time = snapshot_timestamp + (DAY * 1).into();
        let current_game_count = (snapshot_game_count + 100).into();

        // 100 games in a day should be an average of 100 games per day
        let result = snapshot.games_per_day(current_game_count, current_time);
        assert(result == 100, 'wrong games per day calculation');

        // start next time after a week with 1000 games playe
        let snapshot_timestamp = (DAY * 7).into();
        let snapshot_game_count = 100;
        let snapshot = GamesPlayedSnapshot {
            timestamp: snapshot_timestamp, game_count: snapshot_game_count, locked: 0
        };

        // one week snapshot
        let current_time = snapshot_timestamp + (DAY * 7).into();
        // with 1400 games added
        let current_game_count = (snapshot_game_count + 1400).into();
        let result = snapshot.games_per_day(current_game_count, current_time);
        // should be 200 games per day
        assert(result == 200, 'wrong games per day calculation');
    }

    #[test]
    fn test_get_price_adjustment_increase() {
        let current_price: u128 = 100;
        let global_games_per_day: u64 = 50;
        let snapshot_games_per_day: u64 =
            56; // 50 + 10% of 50 (BUFFER_PERCENTAGE should be 10% for this example)

        let result = GamesPlayedSnapshotImpl::get_price_adjustment(
            current_price, global_games_per_day, snapshot_games_per_day
        );

        assert(result == 110, 'price should increase by 10%');
    }

    #[test]
    fn test_get_price_adjustment_decrease() {
        let current_price: u128 = 100;
        let global_games_per_day: u64 = 50;
        let snapshot_games_per_day: u64 =
            44; // 50 - 10% of 50 (BUFFER_PERCENTAGE should be 10% for this example)

        let result = GamesPlayedSnapshotImpl::get_price_adjustment(
            current_price, global_games_per_day, snapshot_games_per_day
        );

        assert(result == 90, 'price should decrease by 10%');
    }

    #[test]
    fn test_get_price_adjustment_no_change() {
        let current_price: u128 = 100;
        let global_games_per_day: u64 = 50;
        let snapshot_games_per_day: u64 = 50;

        let result = GamesPlayedSnapshotImpl::get_price_adjustment(
            current_price, global_games_per_day, snapshot_games_per_day
        );

        assert(result == 100, 'price should remain unchanged');
    }
}
