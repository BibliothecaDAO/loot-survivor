const COST_TO_PLAY: u128 = 50000000000000000000;
const MINIMUM_DAMAGE_FROM_BEASTS: u8 = 2;
const MAINNET_CHAIN_ID: felt252 = 0x534e5f4d41494e;
const SEPOLIA_CHAIN_ID: felt252 = 0x534e5f5345504f4c4941;
const KATANA_CHAIN_ID: felt252 = 0x4b4154414e41;
const MINIMUM_SCORE_FOR_PAYOUTS: u16 = 50;
const SECONDS_IN_DAY: u32 = 86400;
const TARGET_PRICE_USD_CENTS: u16 = 300;
const VRF_COST_PER_GAME: u32 = 100000000; // 1$ with 8 decimals
const VRF_MAX_CALLBACK_MAINNET: u32 = 5000000; // $0.05
const VRF_MAX_CALLBACK_TESTNET: u32 = 100000000; // 1$ with 8 decimals
const PRAGMA_LORDS_KEY: felt252 = 'LORDS/USD'; // felt252 conversion of "LORDS/USD"
const PRAGMA_PUBLISH_DELAY: u8 = 0;
const PRAGMA_NUM_WORDS: u8 = 1;
const GAME_EXPIRY_DAYS: u8 = 10;
const OBITUARY_EXPIRY_DAYS: u8 = 10;
const MAX_U64: u64 = 0xffffffffffffffff;
const STARTER_BEAST_ATTACK_DAMAGE: u16 = 10;

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
    const CANT_DROP_DURING_STARTER_BEAST: felt252 = 'Cant drop during starter beast';
    const STAT_UPGRADES_AVAILABLE: felt252 = 'Stat upgrade available';
    const BLOCK_NUMBER_ERROR: felt252 = 'Too soon update';
    const DEAD_ADVENTURER: felt252 = 'Adventurer is dead';
    const ADVENTURER_IS_ALIVE: felt252 = 'Adventurer is still alive';
    const HEALTH_FULL: felt252 = 'Health already full';
    const ADVENTURER_NOT_EXPIRED: felt252 = 'Adventurer not expired';
    const GAME_EXPIRED: felt252 = 'Game has expired';
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
    const STARTING_ENTROPY_ALREADY_SET: felt252 = 'starting entropy already set';
    const STARTING_ENTROPY_ZERO: felt252 = 'block hash should not be zero';
    const GAME_ALREADY_STARTED: felt252 = 'game already started';
    const STARTING_ENTROPY_IS_VALID: felt252 = 'starting entropy is valid';
    const VALID_BLOCK_HASH_UNAVAILABLE: felt252 = 'valid hash not yet available';
    const LEVEL_SEED_NOT_SET: felt252 = 'level seed not set';
    const WAITING_FOR_ITEM_SPECIALS: felt252 = 'waiting for item specials';
    const FETCHING_ETH_PRICE_ERROR: felt252 = 'error fetching eth price';
    const OBITUARY_ALREADY_SET: felt252 = 'obituary already set';
    const OBITUARY_WINDOW_CLOSED: felt252 = 'obituary window closed';
    const INVALID_ITEM_ID: felt252 = 'invalid item id';
}

#[derive(Drop, Copy)]
struct Rewards {
    BIBLIO: u256,
    PG: u256,
    CLIENT_PROVIDER: u256,
    FIRST_PLACE: u256,
    SECOND_PLACE: u256,
    THIRD_PLACE: u256,
}

mod REWARD_DISTRIBUTIONS_BP {
    const CLIENT_PROVIDER: u256 = 270;
    const FIRST_PLACE: u256 = 270;
    const SECOND_PLACE: u256 = 160;
    const THIRD_PLACE: u256 = 100;
    const CREATOR: u256 = 200;
}

