mod ObstacleId {
    const DemonicAlter: u8 = 1;
    const Curse: u8 = 2;
    const Hex: u8 = 3;
    const MagicLock: u8 = 4;
    const DarkMist: u8 = 5;

    const CollapsingCeiling: u8 = 6;
    const CrushingWalls: u8 = 7;
    const Rockslide: u8 = 8;
    const TumblingBoulders: u8 = 9;
    const SwingingLogs: u8 = 10;

    const PendulumBlades: u8 = 11;
    const FlameJet: u8 = 12;
    const PoisonDart: u8 = 13;
    const SpikedPit: u8 = 14;
    const HiddenArrow: u8 = 15;

    // If you add obstacle, make sure to update MAX_ID below
    // making this u64 as it's commonly used to select a random obstacle based
    // on entropy variables which are u64 based
    const MAX_ID: u64 = 15;
}

mod ObstacleTier {
    const DemonicAlter: u8 = 1;
    const Curse: u8 = 2;
    const Hex: u8 = 3;
    const MagicLock: u8 = 4;
    const DarkMist: u8 = 5;

    const CollapsingCeiling: u8 = 1;
    const CrushingWalls: u8 = 2;
    const Rockslide: u8 = 3;
    const TumblingBoulders: u8 = 4;
    const SwingingLogs: u8 = 5;

    const PendulumBlades: u8 = 1;
    const FlameJet: u8 = 2;
    const PoisonDart: u8 = 3;
    const SpikedPit: u8 = 4;
    const HiddenArrow: u8 = 5;
}

// TODO: Ideally these would use loot::statistics::constants::Type;
// @loaf to look into "Only literal constants are currently supported." atm
mod ObstacleType {
    const DemonicAlter: u8 = 1;
    const Curse: u8 = 1;
    const Hex: u8 = 1;
    const MagicLock: u8 = 1;
    const DarkMist: u8 = 1;

    const CollapsingCeiling: u8 = 3;
    const CrushingWalls: u8 = 3;
    const Rockslide: u8 = 3;
    const TumblingBoulders: u8 = 3;
    const SwingingLogs: u8 = 3;

    const PendulumBlades: u8 = 2;
    const FlameJet: u8 = 2;
    const PoisonDart: u8 = 2;
    const SpikedPit: u8 = 2;
    const HiddenArrow: u8 = 2;
}

// TODO: Ideally these would use loot::statistics::constants::Slot;
// @loaf to look into "Only literal constants are currently supported." atm
mod ObstacleAttackLocation {
    const DemonicAlter: u8 = 2;
    const Curse: u8 = 3;
    const Hex: u8 = 6;
    const MagicLock: u8 = 4;
    const DarkMist: u8 = 5;

    const CollapsingCeiling: u8 = 3;
    const CrushingWalls: u8 = 2;
    const Rockslide: u8 = 4;
    const TumblingBoulders: u8 = 5;
    const SwingingLogs: u8 = 6;

    const PendulumBlades: u8 = 4;
    const FlameJet: u8 = 5;
    const PoisonDart: u8 = 6;
    const SpikedPit: u8 = 2;
    const HiddenArrow: u8 = 3;
}

mod Slot {
    const Weapon: u8 = 1;
    const Chest: u8 = 2;
    const Head: u8 = 3;
    const Waist: u8 = 4;
    const Foot: u8 = 5;
    const Hand: u8 = 6;
    const Neck: u8 = 7;
    const Ring: u8 = 8;
}

mod ObstacleSettings {
    // Determines at what adventurer level do obstalces start receiveing a level boost
    // prior to this level, obstacle leve will always be equal to adventurer level
    // The difficulty cliff also controls the rate at which obstacle max level increases
    // if this is set to 5 for example, obstacles will begin to receive a rnd level boost at level 6
    // and that boost will increase every 6 levels
    // increase this setting to give adventurers more breathing room in the early game_entropy
    // decrease this setting to make the game more difficult early on
    const DifficultyCliff: u8 = 5;

    // Determines the maximum level boost an obstacle can receive
    // increase this setting to make obstacles more difficult
    const ObstacleDifficulty: u8 = 4;
}
