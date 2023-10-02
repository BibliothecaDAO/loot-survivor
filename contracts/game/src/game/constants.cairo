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
}

// TODO: Update for mainnet
const BLOCKS_IN_A_WEEK: u64 = 1000;
const COST_TO_PLAY: u8 = 25;
const NUM_STARTING_STATS: u8 = 9;
const STARTING_GAME_ENTROPY_ROTATION_INTERVAL: u8 = 6;
const MINIMUM_DAMAGE_FROM_BEASTS: u8 = 2;

const U64_MAX: u64 = 18446744073709551615;
const U128_MAX: u128 = 340282366920938463463374607431768211455;

#[derive(Drop, Copy)]
struct Week {
    DAO: u256,
    INTERFACE: u256,
    FIRST_PLACE: u256,
    SECOND_PLACE: u256,
    THIRD_PLACE: u256,
}

mod REWARD_DISTRIBUTIONS_PHASE1 {
    const DAO: u256 = 0;
    const INTERFACE: u256 = 0;
    const FIRST_PLACE: u256 = 12;
    const SECOND_PLACE: u256 = 8;
    const THIRD_PLACE: u256 = 5;
}

mod REWARD_DISTRIBUTIONS_PHASE2 {
    const DAO: u256 = 5;
    const INTERFACE: u256 = 0;
    const FIRST_PLACE: u256 = 10;
    const SECOND_PLACE: u256 = 6;
    const THIRD_PLACE: u256 = 4;
}

mod REWARD_DISTRIBUTIONS_PHASE3 {
    const DAO: u256 = 5;
    const INTERFACE: u256 = 4;
    const FIRST_PLACE: u256 = 9;
    const SECOND_PLACE: u256 = 4;
    const THIRD_PLACE: u256 = 3;
}

const STARTER_BEAST_ATTACK_DAMAGE: u16 = 10;
