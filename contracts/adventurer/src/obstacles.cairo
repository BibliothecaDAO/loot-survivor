use option::OptionTrait;
use integer::{U64TryIntoU8, U16IntoU64, U8IntoU64, U8IntoU16};
use survivor::bag::Item;
use survivor::adventurer::{Adventurer, AdventurerActions};
use lootitems::statistics::constants::{Type, Slot};
use survivor::constants::obstacle_constants::{
    ObstacleId, ObstacleTier, ObstacleType, ObstacleAttackLocation, ObstacleSettings
};

#[derive(Drop, Copy)] // 24 bits
struct Obstacle {
    level: u8, // level of obstacle
    tier: u8, // same as Loot weapons: T1 is strongest
    damage_type: u8, // same as Loot weapons: magic, bludgeon, blade
    damage_location: u8, // correspond with loot armor: {head, chest, legs, feet, etc}
}

trait ObstacleTrait {
    fn get_random_obstacle(
        adventurer: Adventurer, adventurer_entropy: u64, game_entropy: u64
    ) -> Obstacle;
    fn get_random_obstacle_id(
        adventurer: Adventurer, adventurer_entropy: u64, game_entropy: u64
    ) -> u8;
    fn get_obstacle(id: u8, level: u8) -> Obstacle;
    fn get_level(adventurer: Adventurer, adventurer_entropy_seed: u64, game_entropy: u64) -> u8;
    fn get_tier(id: u8) -> u8;
    fn get_type(id: u8) -> u8;
    fn get_attack_location(id: u8) -> u8;
    fn get_damage(adventurer: Adventurer, obstacle: Obstacle) -> (bool, u16);
    fn get_xp_reward(obstacle: Obstacle) -> u16;
}

impl ObstacleUtils of ObstacleTrait {
    // get_random_obstacle returns a random obstacle based on the adventurer, adventurer entropy, and game entropy
    // @param adventurer: Adventurer - the adventurer
    // @param adventurer_entropy: u64 - the adventurer entropy
    // @param game_entropy: u64 - the game entropy
    // @return Obstacle - the obstacle
    fn get_random_obstacle(
        adventurer: Adventurer, adventurer_entropy: u64, game_entropy: u64
    ) -> Obstacle {
        // get random obstacle id
        let obstacle_id = ObstacleUtils::get_random_obstacle_id(
            adventurer, adventurer_entropy, game_entropy
        );

        // get random obstacle level
        let obstacle_level = ObstacleUtils::get_level(adventurer, adventurer_entropy, game_entropy);

        // return obstacle
        return ObstacleUtils::get_obstacle(obstacle_id, obstacle_level);
    }

    // get_random_obstacle_id returns a random obstacle id based on adventurer, adventurer entropy, and game entropy
    // the obstacle id will be between 1 and the max obstacle id (inclusive)
    // @param adventurer: Adventurer - the adventurer
    // @param adventurer_entropy: u64 - the adventurer entropy
    // @param game_entropy: u64 - the game entropy
    // @return u8 - the obstacle id
    fn get_random_obstacle_id(
        adventurer: Adventurer, adventurer_entropy: u64, game_entropy: u64
    ) -> u8 {
        // generate obstacle entropy
        let obstacle_entropy = adventurer_entropy + game_entropy;

        // select an obstacle between 1 and max obstacle id (inclusive)
        let obstacle_id = (obstacle_entropy % ObstacleId::MAX_ID) + 1;

        // return obstacle id as a u8
        return U64TryIntoU8::try_into(obstacle_id).unwrap();
    }
    // get_obstacle returns an obstacle based on the provided obstacle id and level
    // @param id: u8 - the obstacle id
    // @param level: u8 - the obstacle level
    // @return Obstacle - the obstacle
    fn get_obstacle(id: u8, level: u8) -> Obstacle {
        Obstacle {
            level: level,
            tier: ObstacleUtils::get_tier(id),
            damage_type: ObstacleUtils::get_type(id),
            damage_location: ObstacleUtils::get_attack_location(id),
        }
    }

    // get_level returns the level of the obstacle based on the adventurer, adventurer entropy, and game entropy
    // @param adventurer: Adventurer - the adventurer
    // @param adventurer_entropy_seed: u64 - the adventurer entropy seed
    // @param game_entropy: u64 - the game entropy
    // @return u8 - the obstacle level
    fn get_level(adventurer: Adventurer, adventurer_entropy_seed: u64, game_entropy: u64) -> u8 {
        // get adventurer level
        let adventurer_level = AdventurerActions::get_level(adventurer);

        // if adventurer level is less than or equal to the obstacle base level
        if (adventurer_level <= ObstacleSettings::DifficultyCliff) {
            // use the adventurer level for the obstacle level
            return adventurer_level;
        }

        // if the adventurere level is higher than the obstacle base level

        // divide adventurer level by 5 and store whole number which will be used as a level multiplier
        let obstacle_level_multplier = AdventurerActions::get_level(adventurer)
            / ObstacleSettings::DifficultyCliff;

        // maximum range of the obstacle level will be the above multplier * the obstacle difficulty
        let obstacle_level_range = U8IntoU64::into(
            obstacle_level_multplier * ObstacleSettings::ObstacleDifficulty
        );

        // generate an rnd base don adventurer entropy seed, game entropy, and adventurer xp
        let rnd = adventurer_entropy_seed + game_entropy + U16IntoU64::into(adventurer.xp);

        // calculate the obstacle level which will be between 
        let obstacle_level_boost = rnd % obstacle_level_range;

        // add the obstacle level boost to the adventurer level - difficulty cliff
        // this will produce a level between (adventurer level - difficulty cliff) and obstacle_level_multplier * obstacle_constants::Settings::ObstacleDifficulty
        let obstacle_level = obstacle_level_boost
            + U8IntoU64::into((adventurer_level - ObstacleSettings::DifficultyCliff));

        // return the obstacle level as a u16
        return U64TryIntoU8::try_into(obstacle_level).unwrap();
    }

    // get_tier returns the tier of the obstacle based on the provided obstacle id
    // @param id: u8 - the obstacle id
    // @return u8 - the obstacle tier
    fn get_tier(id: u8) -> u8 {
        if id == ObstacleId::DemonicAlter {
            return ObstacleTier::DemonicAlter;
        } else if id == ObstacleId::Curse {
            return ObstacleTier::Curse;
        } else if id == ObstacleId::Hex {
            return ObstacleTier::Hex;
        } else if id == ObstacleId::MagicLock {
            return ObstacleTier::MagicLock;
        } else if id == ObstacleId::DarkMist {
            return ObstacleTier::DarkMist;
        } else if id == ObstacleId::CollapsingCeiling {
            return ObstacleTier::CollapsingCeiling;
        } else if id == ObstacleId::CrushingWalls {
            return ObstacleTier::CrushingWalls;
        } else if id == ObstacleId::Rockslide {
            return ObstacleTier::Rockslide;
        } else if id == ObstacleId::TumblingBoulders {
            return ObstacleTier::TumblingBoulders;
        } else if id == ObstacleId::SwingingLogs {
            return ObstacleTier::SwingingLogs;
        } else if id == ObstacleId::PendulumBlades {
            return ObstacleTier::PendulumBlades;
        } else if id == ObstacleId::FlameJet {
            return ObstacleTier::FlameJet;
        } else if id == ObstacleId::PoisonDart {
            return ObstacleTier::PoisonDart;
        } else if id == ObstacleId::SpikedPit {
            return ObstacleTier::SpikedPit;
        } else if id == ObstacleId::HiddenArrow {
            return ObstacleTier::HiddenArrow;
        } else {
            return 0;
        }
    }

    // get_type returns the type of the obstacle based on the provided obstacle id
    // @param id: u8 - the obstacle id
    // @return u8 - the obstacle type
    fn get_type(id: u8) -> u8 {
        if id == ObstacleId::DemonicAlter {
            return ObstacleType::DemonicAlter;
        } else if id == ObstacleId::Curse {
            return ObstacleType::Curse;
        } else if id == ObstacleId::Hex {
            return ObstacleType::Hex;
        } else if id == ObstacleId::MagicLock {
            return ObstacleType::MagicLock;
        } else if id == ObstacleId::DarkMist {
            return ObstacleType::DarkMist;
        } else if id == ObstacleId::CollapsingCeiling {
            return ObstacleType::CollapsingCeiling;
        } else if id == ObstacleId::CrushingWalls {
            return ObstacleType::CrushingWalls;
        } else if id == ObstacleId::Rockslide {
            return ObstacleType::Rockslide;
        } else if id == ObstacleId::TumblingBoulders {
            return ObstacleType::TumblingBoulders;
        } else if id == ObstacleId::SwingingLogs {
            return ObstacleType::SwingingLogs;
        } else if id == ObstacleId::PendulumBlades {
            return ObstacleType::PendulumBlades;
        } else if id == ObstacleId::FlameJet {
            return ObstacleType::FlameJet;
        } else if id == ObstacleId::PoisonDart {
            return ObstacleType::PoisonDart;
        } else if id == ObstacleId::SpikedPit {
            return ObstacleType::SpikedPit;
        } else if id == ObstacleId::HiddenArrow {
            return ObstacleType::HiddenArrow;
        } else {
            return 0;
        }
    }

    // get_attack_location returns the attack location of the obstacle based on the provided obstacle id
    // @param id: u8 - the obstacle id
    // @return u8 - the obstacle attack location
    fn get_attack_location(id: u8) -> u8 {
        if id == ObstacleId::DemonicAlter {
            return ObstacleAttackLocation::DemonicAlter;
        } else if id == ObstacleId::Curse {
            return ObstacleAttackLocation::Curse;
        } else if id == ObstacleId::Hex {
            return ObstacleAttackLocation::Hex;
        } else if id == ObstacleId::MagicLock {
            return ObstacleAttackLocation::MagicLock;
        } else if id == ObstacleId::DarkMist {
            return ObstacleAttackLocation::DarkMist;
        } else if id == ObstacleId::CollapsingCeiling {
            return ObstacleAttackLocation::CollapsingCeiling;
        } else if id == ObstacleId::CrushingWalls {
            return ObstacleAttackLocation::CrushingWalls;
        } else if id == ObstacleId::Rockslide {
            return ObstacleAttackLocation::Rockslide;
        } else if id == ObstacleId::TumblingBoulders {
            return ObstacleAttackLocation::TumblingBoulders;
        } else if id == ObstacleId::SwingingLogs {
            return ObstacleAttackLocation::SwingingLogs;
        } else if id == ObstacleId::PendulumBlades {
            return ObstacleAttackLocation::PendulumBlades;
        } else if id == ObstacleId::FlameJet {
            return ObstacleAttackLocation::FlameJet;
        } else if id == ObstacleId::PoisonDart {
            return ObstacleAttackLocation::PoisonDart;
        } else if id == ObstacleId::SpikedPit {
            return ObstacleAttackLocation::SpikedPit;
        } else if id == ObstacleId::HiddenArrow {
            return ObstacleAttackLocation::HiddenArrow;
        } else {
            return 0;
        }
    }

    // get_damage returns the damage of the obstacle based on the provided obstacle id
    fn get_damage(adventurer: Adventurer, obstacle: Obstacle) -> (bool, u16) {
        // get deterministic obstacle based on adventurer
        return (false, 10);
    }

    // get_xp_reward returns the xp reward from encountering the obstacle
    // @param obstacle: Obstacle - the obstacle
    // @return u16 - the xp reward
    fn get_xp_reward(obstacle: Obstacle) -> u16 {
        let obstacle_tier = U8IntoU16::into(obstacle.tier);
        let obstacle_level = U8IntoU16::into(obstacle.level);
        let tier_cap: u16 = 6;
        let xp_reward: u16 = (tier_cap - obstacle_tier) * obstacle_level;
        return xp_reward;
    }
}

#[test]
#[available_gas(70000)]
fn test_get_obstacle_tier() {
    let demonic_alter = ObstacleId::DemonicAlter;
    let demonic_alter_tier = ObstacleUtils::get_tier(demonic_alter);
    assert(demonic_alter_tier == 1, 'demonic_alter should be T1');

    let curse = ObstacleId::Curse;
    let curse_tier = ObstacleUtils::get_tier(curse);
    assert(curse_tier == 2, 'curse should be T2');

    let hex = ObstacleId::Hex;
    let hex_tier = ObstacleUtils::get_tier(hex);
    assert(hex_tier == 3, 'hex should be T3');

    let magic_lock = ObstacleId::MagicLock;
    let magic_lock_tier = ObstacleUtils::get_tier(magic_lock);
    assert(magic_lock_tier == 4, 'magic_lock should be T4');

    let dark_mist = ObstacleId::DarkMist;
    let dark_mist_tier = ObstacleUtils::get_tier(dark_mist);
    assert(dark_mist_tier == 5, 'dark_mist should be T5');

    let collapsing_ceiling = ObstacleId::CollapsingCeiling;
    let collapsing_ceiling_tier = ObstacleUtils::get_tier(collapsing_ceiling);
    assert(collapsing_ceiling_tier == 1, 'collapsing_ceiling should be T1');

    let crushing_walls = ObstacleId::CrushingWalls;
    let crushing_walls_tier = ObstacleUtils::get_tier(crushing_walls);
    assert(crushing_walls_tier == 2, 'crushing_walls should be T2');

    let rockslide = ObstacleId::Rockslide;
    let rockslide_tier = ObstacleUtils::get_tier(rockslide);
    assert(rockslide_tier == 3, 'rockslide should be T3');

    let tumbling_boulders = ObstacleId::TumblingBoulders;
    let tumbling_boulders_tier = ObstacleUtils::get_tier(tumbling_boulders);
    assert(tumbling_boulders_tier == 4, 'tumbling_boulders should be T4');

    let swinging_logs = ObstacleId::SwingingLogs;
    let swinging_logs_tier = ObstacleUtils::get_tier(swinging_logs);
    assert(swinging_logs_tier == 5, 'swinging_logs should be T5');

    let pendulum_blades = ObstacleId::PendulumBlades;
    let pendulum_blades_tier = ObstacleUtils::get_tier(pendulum_blades);
    assert(pendulum_blades_tier == 1, 'pendulum_blades should be T1');

    let flame_jet = ObstacleId::FlameJet;
    let flame_jet_tier = ObstacleUtils::get_tier(flame_jet);
    assert(flame_jet_tier == 2, 'flame_jet should be T2');

    let poison_dart = ObstacleId::PoisonDart;
    let poison_dart_tier = ObstacleUtils::get_tier(poison_dart);
    assert(poison_dart_tier == 3, 'poison_dart should be T3');

    let spiked_pit = ObstacleId::SpikedPit;
    let spiked_pit_tier = ObstacleUtils::get_tier(spiked_pit);
    assert(spiked_pit_tier == 4, 'spiked_pit should be T4');

    let hidden_arrow = ObstacleId::HiddenArrow;
    let hidden_arrow_tier = ObstacleUtils::get_tier(hidden_arrow);
    assert(hidden_arrow_tier == 5, 'hidden_arrow should be T5');
}

#[test]
#[available_gas(70000)]
fn test_get_obstacle_type() {
    let demonic_alter = ObstacleId::DemonicAlter;
    let demonic_alter_type = ObstacleUtils::get_type(demonic_alter);
    assert(demonic_alter_type == Type::Weapon::Magic, 'demonic_alter should be magic');

    let curse = ObstacleId::Curse;
    let curse_type = ObstacleUtils::get_type(curse);
    assert(curse_type == Type::Weapon::Magic, 'curse should be magic');

    let hex = ObstacleId::Hex;
    let hex_type = ObstacleUtils::get_type(hex);
    assert(hex_type == Type::Weapon::Magic, 'hex should be magic');

    let magic_lock = ObstacleId::MagicLock;
    let magic_lock_type = ObstacleUtils::get_type(magic_lock);
    assert(magic_lock_type == Type::Weapon::Magic, 'magic_lock should be magic');

    let dark_mist = ObstacleId::DarkMist;
    let dark_mist_type = ObstacleUtils::get_type(dark_mist);
    assert(dark_mist_type == Type::Weapon::Magic, 'dark_mist should be magic');

    let collapsing_ceiling = ObstacleId::CollapsingCeiling;
    let collapsing_ceiling_type = ObstacleUtils::get_type(collapsing_ceiling);
    assert(collapsing_ceiling_type == Type::Weapon::Bludgeon, 'collapsing_ceiling is bludgeon');

    let crushing_walls = ObstacleId::CrushingWalls;
    let crushing_walls_type = ObstacleUtils::get_type(crushing_walls);
    assert(crushing_walls_type == Type::Weapon::Bludgeon, 'crushing_walls is bludgeon');

    let rockslide = ObstacleId::Rockslide;
    let rockslide_type = ObstacleUtils::get_type(rockslide);
    assert(rockslide_type == Type::Weapon::Bludgeon, 'rockslide should be bludgeon');

    let tumbling_boulders = ObstacleId::TumblingBoulders;
    let tumbling_boulders_type = ObstacleUtils::get_type(tumbling_boulders);
    assert(tumbling_boulders_type == Type::Weapon::Bludgeon, 'tumbling_boulders type ');

    let swinging_logs = ObstacleId::SwingingLogs;
    let swinging_logs_type = ObstacleUtils::get_type(swinging_logs);
    assert(swinging_logs_type == Type::Weapon::Bludgeon, 'swinging_logs is bludgeon');

    let pendulum_blades = ObstacleId::PendulumBlades;
    let pendulum_blades_type = ObstacleUtils::get_type(pendulum_blades);
    assert(pendulum_blades_type == Type::Weapon::Blade, 'pendulum_blades should be blade');

    let flame_jet = ObstacleId::FlameJet;
    let flame_jet_type = ObstacleUtils::get_type(flame_jet);
    assert(flame_jet_type == Type::Weapon::Blade, 'flame_jet should be blade');

    let poison_dart = ObstacleId::PoisonDart;
    let poison_dart_type = ObstacleUtils::get_type(poison_dart);
    assert(poison_dart_type == Type::Weapon::Blade, 'poison_dart should be blade');

    let spiked_pit = ObstacleId::SpikedPit;
    let spiked_pit_type = ObstacleUtils::get_type(spiked_pit);
    assert(spiked_pit_type == Type::Weapon::Blade, 'spiked_pit should be blade');

    let hidden_arrow = ObstacleId::HiddenArrow;
    let hidden_arrow_type = ObstacleUtils::get_type(hidden_arrow);
    assert(hidden_arrow_type == Type::Weapon::Blade, 'hidden_arrow should be blade');
}

#[test]
#[available_gas(70000)]
fn test_get_obstacle_location() {
    let demonic_alter = ObstacleId::DemonicAlter;
    let demonic_alter_loc = ObstacleUtils::get_attack_location(demonic_alter);
    assert(demonic_alter_loc == Slot::Chest, 'demonic_alter damages chest');

    let curse = ObstacleId::Curse;
    let curse_loc = ObstacleUtils::get_attack_location(curse);
    assert(curse_loc == Slot::Head, 'curse damages head');

    let hex = ObstacleId::Hex;
    let hex_loc = ObstacleUtils::get_attack_location(hex);
    assert(hex_loc == Slot::Hand, 'hex damages hands');

    let magic_lock = ObstacleId::MagicLock;
    let magic_lock_loc = ObstacleUtils::get_attack_location(magic_lock);
    assert(magic_lock_loc == Slot::Waist, 'magic_lock damages waist');

    let dark_mist = ObstacleId::DarkMist;
    let dark_mist_loc = ObstacleUtils::get_attack_location(dark_mist);
    assert(dark_mist_loc == Slot::Foot, 'dark_mist damages feet');

    let collapsing_ceiling = ObstacleId::CollapsingCeiling;
    let collapsing_ceiling_loc = ObstacleUtils::get_attack_location(collapsing_ceiling);
    assert(collapsing_ceiling_loc == Slot::Head, 'collapsing_ceiling damages head');

    let crushing_walls = ObstacleId::CrushingWalls;
    let crushing_walls_loc = ObstacleUtils::get_attack_location(crushing_walls);
    assert(crushing_walls_loc == Slot::Chest, 'crushing_walls damages chest');

    let rockslide = ObstacleId::Rockslide;
    let rockslide_loc = ObstacleUtils::get_attack_location(rockslide);
    assert(rockslide_loc == Slot::Waist, 'rockslide damages waist');

    let tumbling_boulders = ObstacleId::TumblingBoulders;
    let tumbling_boulders_loc = ObstacleUtils::get_attack_location(tumbling_boulders);
    assert(tumbling_boulders_loc == Slot::Foot, 'tumbling_boulders damages feet');

    let swinging_logs = ObstacleId::SwingingLogs;
    let swinging_logs_loc = ObstacleUtils::get_attack_location(swinging_logs);
    assert(swinging_logs_loc == Slot::Hand, 'swinging_logs damages hands');

    let pendulum_blades = ObstacleId::PendulumBlades;
    let pendulum_blades_loc = ObstacleUtils::get_attack_location(pendulum_blades);
    assert(pendulum_blades_loc == Slot::Waist, 'pendulum_blades damages waist');

    let flame_jet = ObstacleId::FlameJet;
    let flame_jet_loc = ObstacleUtils::get_attack_location(flame_jet);
    assert(flame_jet_loc == Slot::Foot, 'flame_jet damages feet');

    let poison_dart = ObstacleId::PoisonDart;
    let poison_dart_loc = ObstacleUtils::get_attack_location(poison_dart);
    assert(poison_dart_loc == Slot::Hand, 'poison_dart damages hands');

    let spiked_pit = ObstacleId::SpikedPit;
    let spiked_pit_loc = ObstacleUtils::get_attack_location(spiked_pit);
    assert(spiked_pit_loc == Slot::Chest, 'spiked_pit damages chest');

    let hidden_arrow = ObstacleId::HiddenArrow;
    let hidden_arrow_loc = ObstacleUtils::get_attack_location(hidden_arrow);
    assert(hidden_arrow_loc == Slot::Head, 'hidden_arrow damages head');
}

#[test]
#[available_gas(100000)]
fn test_get_obstacle_level() {
    let mut adventurer = Adventurer {
        last_action: 0,
        health: 100,
        xp: 1,
        strength: 0,
        dexterity: 0,
        vitality: 0,
        intelligence: 0,
        wisdom: 0,
        charisma: 0,
        gold: 0,
        weapon: Item {
            id: 12, xp: 0, metadata: 1, 
            }, chest: Item {
            id: 0, xp: 0, metadata: 0, 
            }, head: Item {
            id: 0, xp: 0, metadata: 0, 
            }, waist: Item {
            id: 0, xp: 0, metadata: 0, 
            }, foot: Item {
            id: 0, xp: 0, metadata: 0, 
            }, hand: Item {
            id: 0, xp: 0, metadata: 0, 
            }, neck: Item {
            id: 0, xp: 0, metadata: 0, 
            }, ring: Item {
            id: 0, xp: 0, metadata: 0, 
        }, beast_health: 10, stat_upgrade_available: 0,
    };

    // obstacle level and adventurer level will be equivalent up to the difficulty cliff
    let obstacle_level = ObstacleUtils::get_level(adventurer, 0, 0);
    assert(
        AdventurerActions::get_level(adventurer) == obstacle_level, 'obstcl lvl should eql advr lvl'
    );

    // continue to test at difficult cliff and beyond
    // currently we need to implement adventurer.get_level() for this to work
    adventurer.xp = 10;
    let obstacle_level = ObstacleUtils::get_level(adventurer, 0, 0);
    assert(AdventurerActions::get_level(adventurer) == 1, 'fail is expected - tdd');
}
