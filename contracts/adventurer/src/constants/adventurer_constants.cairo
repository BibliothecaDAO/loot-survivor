// Starting Setting
const STARTING_GOLD: u16 = 25;
const STARTING_HEALTH: u16 = 100;

// Adventurer Max Values
const MAX_ADVENTURER_HEALTH: u16 = 511; // 9 bits
const MAX_XP: u16 = 8191; // 13 bits
const MAX_STAT_VALUE: u8 = 15; // 4 bits
const MAX_GOLD: u16 = 511; // 9 bits
const MAX_PACKABLE_ITEM_XP: u16 = 511; // 9 bits
const MAX_PACKABLE_BEAST_HEALTH: u16 = 511; // 9 bits
const MAX_STAT_UPGRADE_POINTS: u8 = 7; // 3 bits
const MAX_LAST_ACTION_BLOCK: u16 = 511; // 9 bits
const MAX_ACTIONS_PER_BLOCK: u8 = 15; // 4 bits

const ITEM_MAX_XP: u16 = 400;

// Potion Settings
const POTION_PRICE: u16 = 1;
const POTION_HEALTH_AMOUNT: u16 = 10;
const MINIMUM_POTION_PRICE: u16 = 1;
const CHARISMA_POTION_DISCOUNT: u16 = 2;

// Item Settings
const CHARISMA_ITEM_DISCOUNT: u16 = 1;
const MINIMUM_ITEM_PRICE: u16 = 1;
const ITEM_MAX_GREATNESS: u8 = 20;
const MAX_GREATNESS_STAT_BONUS: u8 = 1;
const NECKLACE_G20_BONUS_STATS: u8 = 1;
const SILVER_RING_G20_LUCK_BONUS: u8 = 20;

const SILVER_RING_LUCK_BONUS_PER_GREATNESS: u8 = 1;
const JEWELRY_BONUS_BEAST_GOLD_PERCENT: u8 = 3;
const JEWELRY_BONUS_CRITICAL_HIT_PERCENT_PER_GREATNESS: u8 = 3;
const JEWELRY_BONUS_NAME_MATCH_PERCENT_PER_GREATNESS: u8 = 3;
const NECKLACE_ARMOR_BONUS: u8 = 3;

// Stat Settings
const HEALTH_INCREASE_PER_VITALITY: u8 = 10;
const VITALITY_INSTANT_HEALTH_BONUS: u16 = 10;

// Combat Settings
const MINIMUM_DAMAGE_TO_BEASTS: u8 = 4;
const MINIMUM_DAMAGE_FROM_BEASTS: u8 = 2;
const MINIMUM_DAMAGE_FROM_OBSTACLES: u8 = 2;
const BEAST_CRITICAL_HIT_CHANCE: u8 = 10;
const OBSTACLE_CRITICAL_HIT_CHANCE: u8 = 10;

// Misc Settings
const MAX_ADVENTURER_BLOCKS: u16 = 512; // 2^9
const STAT_UPGRADE_POINTS_PER_LEVEL: u8 = 1;
const BEAST_SPECIAL_NAME_LEVEL_UNLOCK: u16 = 19;
const XP_FOR_DISCOVERIES: u16 = 1;

// controls how much faster items level up compared to the player
const ITEM_XP_MULTIPLIER_BEASTS: u16 = 2;
const ITEM_XP_MULTIPLIER_OBSTACLES: u16 = 1;

// Maximum number of blocks we can keep track of on the Adventurer
// this is used for calculating idle damage penalty
const MAX_BLOCK_COUNT: u64 = 512;

mod StatisticIndex {
    const STRENGTH: u8 = 0;
    const DEXTERITY: u8 = 1;
    const VITALITY: u8 = 2;
    const INTELLIGENCE: u8 = 3;
    const WISDOM: u8 = 4;
    const CHARISMA: u8 = 5;
}

const U128_MAX: u128 = 340282366920938463463374607431768211455;
const MAX_U128_PRIME: u128 = 340282366920938463463374607431768211383;

const TWO_POW_8: u128 = 0x100;
const TWO_POW_40: u128 = 0x10000000000;

const MASK_8: u128 = 0xff;
const MASK_32: u128 = 0xffffffff;
