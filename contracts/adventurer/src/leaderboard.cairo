use starknet::StorePacking;

#[derive(Drop, Copy, Serde)]
struct Leaderboard { // 242 bits of storage
    first: Score, // 83 bits
    second: Score, // 83 bits
    third: Score, // 83 bits
}

#[derive(Drop, Copy, Serde)]
struct Score { // 83 bits of storage
    adventurer_id: u64, // 61 bits
    xp: u16, // 13 bits
    gold: u16, // 9 bits
}

impl ScorePacking of StorePacking<Score, felt252> {
    fn pack(value: Score) -> felt252 {
        (value.adventurer_id.into()
            + (value.xp.into() * TWO_POW_61)
            + (value.gold.into() * TWO_POW_74))
            .try_into()
            .unwrap()
    }

    fn unpack(value: felt252) -> Score {
        let packed = value.into();
        let (packed, adventuer_id) = integer::U256DivRem::div_rem(
            packed, TWO_POW_61.try_into().unwrap()
        );
        let (packed, xp) = integer::U256DivRem::div_rem(packed, TWO_POW_13.try_into().unwrap());
        let (_, gold) = integer::U256DivRem::div_rem(packed, TWO_POW_9.try_into().unwrap());
        Score {
            adventurer_id: adventuer_id.try_into().unwrap(),
            xp: xp.try_into().unwrap(),
            gold: gold.try_into().unwrap()
        }
    }
}

impl LeaderboardPacking of StorePacking<Leaderboard, felt252> {
    fn pack(value: Leaderboard) -> felt252 {
        (ScorePacking::pack(value.first).into()
            + (ScorePacking::pack(value.second).into() * TWO_POW_83)
            + (ScorePacking::pack(value.third).into() * TWO_POW_166))
            .try_into()
            .unwrap()
    }

    fn unpack(value: felt252) -> Leaderboard {
        let mut packed = value.into();
        let (packed, first) = integer::U256DivRem::div_rem(packed, TWO_POW_83.try_into().unwrap());
        let (packed, second) = integer::U256DivRem::div_rem(packed, TWO_POW_83.try_into().unwrap());
        let (packed, third) = integer::U256DivRem::div_rem(packed, TWO_POW_83.try_into().unwrap());

        Leaderboard {
            first: ScorePacking::unpack(first.try_into().unwrap()),
            second: ScorePacking::unpack(second.try_into().unwrap()),
            third: ScorePacking::unpack(third.try_into().unwrap()),
        }
    }
}

const TWO_POW_9: u256 = 0x200;
const TWO_POW_13: u256 = 0x2000;
const TWO_POW_22: u256 = 0x400000;
const TWO_POW_44: u256 = 0x100000000000;
const TWO_POW_61: u256 = 0x2000000000000000;
const TWO_POW_66: u256 = 0x40000000000000000;
const TWO_POW_74: u256 = 0x4000000000000000000;
const TWO_POW_83: u256 = 0x800000000000000000000;
const TWO_POW_88: u256 = 0x10000000000000000000000;
const TWO_POW_110: u256 = 0x4000000000000000000000000000;
const TWO_POW_132: u256 = 0x1000000000000000000000000000000000;
const TWO_POW_154: u256 = 0x400000000000000000000000000000000000000;
const TWO_POW_166: u256 = 0x400000000000000000000000000000000000000000;
const TWO_POW_176: u256 = 0x100000000000000000000000000000000000000000000;
const TWO_POW_198: u256 = 0x40000000000000000000000000000000000000000000000000;
const TWO_POW_220: u256 = 0x10000000000000000000000000000000000000000000000000000000;

// ---------------------------
// ---------- Tests ----------
// ---------------------------
#[cfg(test)]
mod tests {
    use survivor::leaderboard::{Score, ScorePacking, Leaderboard, LeaderboardPacking};

    #[test]
    #[available_gas(201560)]
    fn test_score_packing() {
        // max value case
        let max_adventurer_id = 2305843009213693951;
        let max_xp = 8191;
        let max_gold = 511;

        let score = Score { adventurer_id: max_adventurer_id, xp: max_xp, gold: max_gold };
        let packed = ScorePacking::pack(score);
        let unpacked: Score = ScorePacking::unpack(packed);
        assert(unpacked.xp == score.xp, 'xp should be max');
        assert(unpacked.gold == score.gold, 'gold should be max');

        // zero case
        let score = Score { adventurer_id: 0, xp: 0, gold: 0 };
        let packed = ScorePacking::pack(score);
        let unpacked: Score = ScorePacking::unpack(packed);
        assert(unpacked.xp == score.xp, 'xp should be 0');
        assert(unpacked.gold == score.gold, 'gold should be 0');
    }

    #[test]
    #[available_gas(425830)]
    fn test_leaderboard_packing() {
        // max value case
        let max_adventurer_id = 2305843009213693951;
        let max_xp = 8191;
        let max_gold = 511;

        let leaderboard = Leaderboard {
            first: Score { adventurer_id: max_adventurer_id, xp: max_xp, gold: max_gold },
            second: Score {
                adventurer_id: max_adventurer_id - 1, xp: max_xp - 1, gold: max_gold - 1
            },
            third: Score {
                adventurer_id: max_adventurer_id - 2, xp: max_xp - 2, gold: max_gold - 2
            },
        };
        let packed = LeaderboardPacking::pack(leaderboard);
        let unpacked: Leaderboard = LeaderboardPacking::unpack(packed);
        assert(
            unpacked.first.adventurer_id == leaderboard.first.adventurer_id,
            'wrong first adventurer_id'
        );
        assert(unpacked.first.xp == leaderboard.first.xp, 'wrong first xp');
        assert(unpacked.first.gold == leaderboard.first.gold, 'wrong first gold');
        assert(
            unpacked.second.adventurer_id == leaderboard.second.adventurer_id,
            'wrong second adventurer_id'
        );
        assert(unpacked.second.xp == leaderboard.second.xp, 'wrong second xp');
        assert(unpacked.second.gold == leaderboard.second.gold, 'wrong second gold');
        assert(
            unpacked.third.adventurer_id == leaderboard.third.adventurer_id,
            'wrong third adventurer_id'
        );
        assert(unpacked.third.xp == leaderboard.third.xp, 'wrong third xp');
        assert(unpacked.third.gold == leaderboard.third.gold, 'wrong third gold');
    }
}
