use combat::constants::{CombatEnums, CombatSettings};

mod ObstacleSettings {
    // Determines the minimum damage an obstacle can do
    const MINIMUM_DAMAGE: u16 = 1;
    const DAMAGE_BOOST: u16 = 0;
}

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
