use combat::constants::{CombatEnums, CombatSettings};

mod ObstacleSettings {
    // Determines the minimum damage an obstacle can do
    const MINIMUM_DAMAGE: u16 = 4;
    const DAMAGE_BOOST: u16 = 0;
    const MINIMUM_XP_REWARD: u16 = 4;
}

mod ObstacleId {
    // Magical Obstacles
    const DemonicAlter: u8 = 1; //T1
    const VortexOfDespair: u8 = 2; //T1
    const EldritchBarrier: u8 = 3; //T1
    const SoulTrap: u8 = 4; //T1
    const PhantomVortex: u8 = 5; //T1
    const EctoplasmicWeb: u8 = 6; //T2
    const SpectralChains: u8 = 7; //T2
    const InfernalPact: u8 = 8; //T2
    const ArcaneExplosion: u8 = 9; //T2
    const HypnoticEssence: u8 = 10; // T2
    const MischievousSprites: u8 = 11; //T3
    const SoulDrainingStatue: u8 = 12; //T3
    const PetrifyingGaze: u8 = 13; //T3
    const SummoningCircle: u8 = 14; //T3
    const EtherealVoid: u8 = 15; //T3
    const MagicLock: u8 = 16; //T4
    const BewitchingFog: u8 = 17; //T4
    const IllusionaryMaze: u8 = 18; //T4
    const SpellboundMirror: u8 = 19; //T4
    const EnsnaringShadow: u8 = 20; //T4
    const DarkMist: u8 = 21; //T5
    const Curse: u8 = 22; //T5
    const HauntingEcho: u8 = 23; //T5
    const Hex: u8 = 24; //T5
    const GhostlyWhispers: u8 = 25; //T5

    // Sharp Obstacles
    const PendulumBlades: u8 = 26; //T1
    const IcyRazorWinds: u8 = 27; //T1
    const AcidicThorns: u8 = 28; //T1
    const DragonsBreath: u8 = 29; //T1
    const PendulumScythe: u8 = 30; //T1
    const FlameJet: u8 = 31; // T2
    const PiercingIceDarts: u8 = 32; //T2
    const GlassSandStorm: u8 = 33; //T2
    const PoisonedDartWall: u8 = 34; //T2
    const SpinningBladeWheel: u8 = 35; //T2
    const PoisonDart: u8 = 36; // T3
    const SpikedTumbleweed: u8 = 37; //T3
    const Thunderbolt: u8 = 38; //T3
    const GiantBearTrap: u8 = 39; //T3
    const SteelNeedleRain: u8 = 40; //T3
    const SpikedPit: u8 = 41; // T4
    const DiamondDustStorm: u8 = 42; //T4
    const TrapdoorScorpionPit: u8 = 43; //T4
    const BladedFan: u8 = 44; //T4
    const BearTrap: u8 = 45; //T4
    const PorcupineQuill: u8 = 46; //T5
    const HiddenArrow: u8 = 47; // T5
    const GlassShard: u8 = 48; //T5
    const ThornBush: u8 = 49; //T5
    const JaggedRocks: u8 = 50; //T5

    // Crushing Obstacles
    const CollapsingCeiling: u8 = 51; //T1
    const Rockslide: u8 = 52; //T1
    const FlashFlood: u8 = 53; //T1
    const ClingingRoots: u8 = 54; //T1
    const CollapsingCavern: u8 = 55; //T1
    const CrushingWalls: u8 = 56; //T2
    const SmashingPillars: u8 = 57; //T2
    const RumblingCatacomb: u8 = 58; //T2
    const WhirlingCyclone: u8 = 59; //T2
    const EruptingEarth: u8 = 60; //T2
    const SubterraneanTremor: u8 = 61; //T3
    const FallingChandelier: u8 = 62; //T3
    const CollapsingBridge: u8 = 63; //T3
    const RagingSandstorm: u8 = 64; //T3
    const AvalanchingRocks: u8 = 65; //T3
    const TumblingBoulders: u8 = 66; // T4
    const SlammingIronGate: u8 = 67; //T4
    const ShiftingSandtrap: u8 = 68; //T4
    const EruptingMudGeyser: u8 = 69; //T4
    const CrumblingStaircase: u8 = 70; //T4
    const SwingingLogs: u8 = 71; //T5
    const UnstableCliff: u8 = 72; //T5
    const TopplingStatue: u8 = 73; //T5
    const TumblingBarrels: u8 = 74; //T5
    const RollingBoulder: u8 = 75; //T5

    // If you add obstacle, make sure to update MAX_ID below
    const MAX_ID: u8 = 75;
}
