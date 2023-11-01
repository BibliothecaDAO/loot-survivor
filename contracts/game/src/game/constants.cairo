mod messages {
    const NOT_ENOUGH_GOLD: felt252 = 'Not enough gold';
    const ITEM_DOES_NOT_EXIST: felt252 = 'Market item does not exist';
    const MARKET_CLOSED: felt252 = 'Market is closed';
    const NOT_OWNER: felt252 = 'Not authorized to act';
    const ITEM_NOT_IN_BAG: felt252 = 'Item not in bag';
    const INVALID_STARTING_WEAPON: felt252 = 'Invalid starting weapon';
    const STAT_POINT_NOT_AVAILABLE: felt252 = 'Stat point not available';
    const NOT_IN_BATTLE: felt252 = 'Not in battle';
    const ACTION_NOT_ALLOWED_DURING_BATTLE: felt252 = 'Action not allowed in battle';
    const CANT_FLEE_STARTER_BEAST: felt252 = 'Cant flee starter beast';
    const STAT_UPGRADES_AVAILABLE: felt252 = 'Stat upgrade available';
    const BLOCK_NUMBER_ERROR: felt252 = 'Too soon update';
    const DEAD_ADVENTURER: felt252 = 'Adventurer is dead';
    const HEALTH_FULL: felt252 = 'Health already full';
    const ADVENTURER_NOT_IDLE: felt252 = 'Adventurer is not idle';
    const ONE_EXPLORE_PER_BLOCK: felt252 = 'One explore per block';
    const INSUFFICIENT_STAT_UPGRADES: felt252 = 'insufficient stat upgrades';
    const TOO_MANY_ITEMS: felt252 = 'Too many items';
    const ITEM_ALREADY_OWNED: felt252 = 'Item already owned';
    const ADVENTURER_DOESNT_OWN_ITEM: felt252 = 'Adventurer doesnt own item';
    const ZERO_DEXTERITY: felt252 = 'Cant flee, no dexterity';
    const WRONG_NUM_STARTING_STATS: felt252 = 'Wrong starting stat count';
    const MUST_USE_ALL_STATS: felt252 = 'Must use all stats';
    const NO_ITEMS: felt252 = 'Must provide item ids';
    const NON_ZERO_STARTING_LUCK: felt252 = 'Luck must be zero';
    const RATE_LIMIT_EXCEEDED: felt252 = 'rate limit exceeded';
    const NOT_ON_LEADERBOARD: felt252 = 'Not on leaderboard';
    const TIME_NOT_REACHED: felt252 = 'Time not reached';
    const CANNOT_PLAY_WITH_TOKEN: felt252 = 'Token already used today';
    const NOT_OWNER_OF_TOKEN: felt252 = 'Not owner of token';
    const MA_PERIOD_LESS_THAN_WEEK: felt252 = 'MA period too small';
    const TERMINAL_TIME_REACHED: felt252 = 'terminal time reached';
}

// TODO: Update for mainnet
const BLOCKS_IN_A_WEEK: u64 = 1000;
const COST_TO_PLAY: u128 = 25000000000000000000;
const NUM_STARTING_STATS: u8 = 9;
const STARTING_GAME_ENTROPY_ROTATION_INTERVAL: u8 = 6;
const MINIMUM_DAMAGE_FROM_BEASTS: u8 = 2;
const MAINNET_REVEAL_DELAY_BLOCKS: u8 = 11;

const U64_MAX: u64 = 18446744073709551615;
const U128_MAX: u128 = 340282366920938463463374607431768211455;

#[derive(Drop, Copy)]
struct Rewards {
    DAO: u256,
    INTERFACE: u256,
    FIRST_PLACE: u256,
    SECOND_PLACE: u256,
    THIRD_PLACE: u256,
}

mod REWARD_DISTRIBUTIONS_PHASE1_BP {
    const DAO: u256 = 0;
    const INTERFACE: u256 = 0;
    const FIRST_PLACE: u256 = 480;
    const SECOND_PLACE: u256 = 320;
    const THIRD_PLACE: u256 = 200;
}

mod REWARD_DISTRIBUTIONS_PHASE2_BP {
    const DAO: u256 = 0;
    const INTERFACE: u256 = 280;
    const FIRST_PLACE: u256 = 320;
    const SECOND_PLACE: u256 = 240;
    const THIRD_PLACE: u256 = 160;
}

mod REWARD_DISTRIBUTIONS_PHASE3_BP {
    const DAO: u256 = 200;
    const INTERFACE: u256 = 240;
    const FIRST_PLACE: u256 = 280;
    const SECOND_PLACE: u256 = 160;
    const THIRD_PLACE: u256 = 120;
}

const STARTER_BEAST_ATTACK_DAMAGE: u16 = 10;
