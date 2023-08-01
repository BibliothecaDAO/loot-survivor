// Starting Setting
const STARTING_GOLD: u16 = 25;
const MAX_GOLD: u16 = 511; // 2^9 - 1

const STARTING_HEALTH: u16 = 100;
const MAX_ADVENTURER_HEALTH: u16 = 511; // 2^9 - 1

// Potion Settings
const POTION_PRICE: u16 = 1;
const POTION_HEALTH_AMOUNT: u16 = 10;
const MINIMUM_POTION_PRICE: u16 = 1;
const CHARISMA_POTION_DISCOUNT: u16 = 2;

// Item Settings
const CHARISMA_ITEM_DISCOUNT: u16 = 2;
const MINIMUM_ITEM_PRICE: u16 = 2;
const ITEM_MAX_GREATNESS: u8 = 20;
const ITEM_MAX_XP: u16 = 400;
const MAX_GREATNESS_STAT_BONUS: u8 = 1;

// Stat Settings
const MAX_STAT_VALUE: u8 = 31; // 2^5 - 1
const MAX_STAT_UPGRADES: u8 = 7; // 2^3 - 1
const VITALITY_HEALTH_CAP_INCREASE: u8 = 10;
const VITALITY_INSTANT_HEALTH_BONUS: u16 = 10;

// Misc Settings
const MAX_XP: u16 = 8191; // 2^13 - 1
const MAX_ADVENTURER_BLOCKS: u16 = 512; // 2^9

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

mod ClassStatBoosts {
    mod Cleric {
        const STRENGTH: u8 = 0;
        const DEXTERITY: u8 = 0;
        const VITALITY: u8 = 3;
        const INTELLIGENCE: u8 = 0;
        const WISDOM: u8 = 0;
        const CHARISMA: u8 = 3;
    }
    mod Scout {
        const STRENGTH: u8 = 0;
        const DEXTERITY: u8 = 2;
        const VITALITY: u8 = 0;
        const INTELLIGENCE: u8 = 2;
        const WISDOM: u8 = 2;
        const CHARISMA: u8 = 0;
    }
    mod Hunter {
        const STRENGTH: u8 = 3;
        const DEXTERITY: u8 = 0;
        const VITALITY: u8 = 0;
        const INTELLIGENCE: u8 = 3;
        const WISDOM: u8 = 0;
        const CHARISMA: u8 = 0;
    }
    mod Warrior {
        const STRENGTH: u8 = 1;
        const DEXTERITY: u8 = 1;
        const VITALITY: u8 = 1;
        const INTELLIGENCE: u8 = 1;
        const WISDOM: u8 = 1;
        const CHARISMA: u8 = 1;
    }
}

const U128_MAX: u128 = 340282366920938463463374607431768211455;
const MAX_U128_PRIME: u128 = 340282366920938463463374607431768211383;
