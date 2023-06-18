use option::OptionTrait;
use integer::{U64TryIntoU8, U8IntoU16, U8IntoU64};
use super::constants::{ObstacleId, ObstacleSettings};
use combat::combat::{ImplCombat, CombatSpec, SpecialPowers};
use combat::constants::CombatSettings;
use combat::constants::CombatEnums::{Type, Tier, Slot};


#[derive(Drop, Copy)]
struct Obstacle {
    combat_specs: CombatSpec,
    damage_location: Slot,
}

trait ObstacleTrait {
    fn get_damage(obstacle: Obstacle, armor_combat_spec: CombatSpec, entropy: u64) -> u16;
    fn dodged(adventurer_level: u8, adventurer_intelligence: u8, entropy: u64) -> bool;
    fn get_random_obstacle(adventurer_level: u8, entropy: u64) -> Obstacle;
    fn get_obstacle(id: u8, level: u8, damage_location: Slot) -> Obstacle;
    fn get_random_level(adventurer_level: u8, entropy: u64) -> u8;
    fn get_random_damage_location(entropy: u64) -> Slot;
    fn get_random_obstacle_id(entropy: u64) -> u8;
    fn get_xp_reward(obstacle: Obstacle) -> u16;
    fn get_tier(id: u8) -> Tier;
    fn get_type(id: u8) -> Type;
}

impl ObstacleUtils of ObstacleTrait {
    // get_random_obstacle returns a random obstacle based on the adventurer level and entropy
    // @param adventurer_level: u8 - the adventurer level
    // @param entropy: u64 - entropy for level generation
    fn get_random_obstacle(adventurer_level: u8, entropy: u64) -> Obstacle {
        // get random obstacle id
        let obstacle_id = ObstacleUtils::get_random_obstacle_id(entropy);
        // get random obstacle level
        let obstacle_level = ObstacleUtils::get_random_level(adventurer_level, entropy);
        // get random damage location
        let damage_location = ObstacleUtils::get_random_damage_location(entropy);
        // return obstacle
        return ObstacleUtils::get_obstacle(obstacle_id, obstacle_level, damage_location);
    }

    // get_random_obstacle_id returns a random obstacle id based on adventurer, adventurer entropy, and game entropy
    // the obstacle id will be between 1 and the max obstacle id (inclusive)
    // @param entropy: u64 - entropy from random id generation
    // @return u8 - the obstacle id
    fn get_random_obstacle_id(entropy: u64) -> u8 {
        // select an obstacle between 1 and max obstacle id (inclusive)
        let obstacle_id = (entropy % ObstacleId::MAX_ID) + 1;

        // return obstacle id as a u8
        return U64TryIntoU8::try_into(obstacle_id).unwrap();
    }
    // get_obstacle returns an obstacle based on the provided obstacle id and level
    // @param id: u8 - the obstacle id
    // @param level: u8 - the obstacle level
    // @return Obstacle - the obstacle
    fn get_obstacle(id: u8, level: u8, damage_location: Slot) -> Obstacle {
        let combat_specs = CombatSpec {
            tier: ObstacleUtils::get_tier(id),
            item_type: ObstacleUtils::get_type(id),
            level: U8IntoU16::into(level),
            special_powers: SpecialPowers {
                prefix1: 0, prefix2: 0, suffix: 0, 
            }
        };

        Obstacle { combat_specs: combat_specs, damage_location: damage_location,  }
    }

    // get_level uses the combat lib to generate a random level scoped for the adventurer level
    // @param adventurer_level: the level of adventurer ()
    // @param entropy: entropy for random level generation
    // @return u8 - the obstacle level
    fn get_random_level(adventurer_level: u8, entropy: u64) -> u8 {
        ImplCombat::get_random_level(
            adventurer_level,
            entropy,
            CombatSettings::DIFFICULTY_CLIFF::NORMAL,
            CombatSettings::LEVEL_MULTIPLIER::NORMAL,
        )
    }

    // get_tier returns the tier of the obstacle based on the provided obstacle id
    // @param id: u8 - the obstacle id
    // @return u8 - the obstacle tier
    fn get_tier(id: u8) -> Tier {
        if id == ObstacleId::DemonicAlter {
            return Tier::T1(());
        } else if id == ObstacleId::Curse {
            return Tier::T2(());
        } else if id == ObstacleId::Hex {
            return Tier::T3(());
        } else if id == ObstacleId::MagicLock {
            return Tier::T4(());
        } else if id == ObstacleId::DarkMist {
            return Tier::T5(());
        } else if id == ObstacleId::CollapsingCeiling {
            return Tier::T1(());
        } else if id == ObstacleId::CrushingWalls {
            return Tier::T2(());
        } else if id == ObstacleId::Rockslide {
            return Tier::T3(());
        } else if id == ObstacleId::TumblingBoulders {
            return Tier::T4(());
        } else if id == ObstacleId::SwingingLogs {
            return Tier::T5(());
        } else if id == ObstacleId::PendulumBlades {
            return Tier::T1(());
        } else if id == ObstacleId::FlameJet {
            return Tier::T2(());
        } else if id == ObstacleId::PoisonDart {
            return Tier::T3(());
        } else if id == ObstacleId::SpikedPit {
            return Tier::T4(());
        } else if id == ObstacleId::HiddenArrow {
            return Tier::T5(());
        }

        // fall through for unknown obstacle id return T5
        return Tier::T5(());
    }

    // get_type returns the type of the obstacle based on the provided obstacle id
    // @param id: u8 - the obstacle id
    // @return u8 - the obstacle type
    fn get_type(id: u8) -> Type {
        if id == ObstacleId::DemonicAlter {
            return Type::Magic_or_Cloth(());
        } else if id == ObstacleId::Curse {
            return Type::Magic_or_Cloth(());
        } else if id == ObstacleId::Hex {
            return Type::Magic_or_Cloth(());
        } else if id == ObstacleId::MagicLock {
            return Type::Magic_or_Cloth(());
        } else if id == ObstacleId::DarkMist {
            return Type::Magic_or_Cloth(());
        } else if id == ObstacleId::CollapsingCeiling {
            return Type::Bludgeon_or_Metal(());
        } else if id == ObstacleId::CrushingWalls {
            return Type::Bludgeon_or_Metal(());
        } else if id == ObstacleId::Rockslide {
            return Type::Bludgeon_or_Metal(());
        } else if id == ObstacleId::TumblingBoulders {
            return Type::Bludgeon_or_Metal(());
        } else if id == ObstacleId::SwingingLogs {
            return Type::Bludgeon_or_Metal(());
        } else if id == ObstacleId::PendulumBlades {
            return Type::Blade_or_Hide(());
        } else if id == ObstacleId::FlameJet {
            return Type::Blade_or_Hide(());
        } else if id == ObstacleId::PoisonDart {
            return Type::Blade_or_Hide(());
        } else if id == ObstacleId::SpikedPit {
            return Type::Blade_or_Hide(());
        } else if id == ObstacleId::HiddenArrow {
            return Type::Blade_or_Hide(());
        } else {
            // should not happen
            return Type::Blade_or_Hide(());
        }
    }

    // get_attack_location returns the attack location of the obstacle based on the provided obstacle id
    // @param id: u8 - the obstacle id
    // @return u8 - the obstacle attack location
    fn get_random_damage_location(entropy: u64) -> Slot {
        return ImplCombat::get_random_damage_location(entropy);
    }

    // get_damage returns the damage of the obstacle based on the provided obstacle id
    fn get_damage(obstacle: Obstacle, armor_combat_spec: CombatSpec, entropy: u64) -> u16 {
        // no critical hits for obstacles
        let is_critical_hit = false;

        return ImplCombat::calculate_damage(
            obstacle.combat_specs,
            armor_combat_spec,
            ObstacleSettings::MINIMUM_DAMAGE,
            ObstacleSettings::DAMAGE_BOOST,
            is_critical_hit,
            entropy
        );
    }

    // get_xp_reward returns the xp reward from encountering the obstacle
    // @param obstacle: Obstacle - the obstacle
    // @return u16 - the xp reward
    fn get_xp_reward(obstacle: Obstacle) -> u16 {
        ImplCombat::get_xp_reward(obstacle.combat_specs)
    }

    fn dodged(adventurer_level: u8, adventurer_intelligence: u8, entropy: u64) -> bool {
        // number of sides of the die will be 1 - adventurer_level
        let dodge_dice_roll = entropy % U8IntoU64::into(adventurer_level);

        // adventurer dodges obstacle if they roll a number less than or equal to
        // their intelligence + difficulty cliff
        // This means that prior to the difficulty cliff, adventurers will have 100% chance of dodging
        return (dodge_dice_roll <= U8IntoU64::into(
            adventurer_intelligence + CombatSettings::DIFFICULTY_CLIFF::NORMAL
        ));
    }
}

#[test]
#[available_gas(100000)]
fn test_get_obstacle_tier() {
    let demonic_alter = ObstacleId::DemonicAlter;
    let demonic_alter_tier = ObstacleUtils::get_tier(demonic_alter);
    assert(demonic_alter_tier == Tier::T1(()), 'demonic_alter should be T1');

    let curse = ObstacleId::Curse;
    let curse_tier = ObstacleUtils::get_tier(curse);
    assert(curse_tier == Tier::T2(()), 'curse should be T2');

    let hex = ObstacleId::Hex;
    let hex_tier = ObstacleUtils::get_tier(hex);
    assert(hex_tier == Tier::T3(()), 'hex should be T3');

    let magic_lock = ObstacleId::MagicLock;
    let magic_lock_tier = ObstacleUtils::get_tier(magic_lock);
    assert(magic_lock_tier == Tier::T4(()), 'magic_lock should be T4');

    let dark_mist = ObstacleId::DarkMist;
    let dark_mist_tier = ObstacleUtils::get_tier(dark_mist);
    assert(dark_mist_tier == Tier::T5(()), 'dark_mist should be T5');

    let collapsing_ceiling = ObstacleId::CollapsingCeiling;
    let collapsing_ceiling_tier = ObstacleUtils::get_tier(collapsing_ceiling);
    assert(collapsing_ceiling_tier == Tier::T1(()), 'collapsing_ceiling should be T1');

    let crushing_walls = ObstacleId::CrushingWalls;
    let crushing_walls_tier = ObstacleUtils::get_tier(crushing_walls);
    assert(crushing_walls_tier == Tier::T2(()), 'crushing_walls should be T2');

    let rockslide = ObstacleId::Rockslide;
    let rockslide_tier = ObstacleUtils::get_tier(rockslide);
    assert(rockslide_tier == Tier::T3(()), 'rockslide should be T3');

    let tumbling_boulders = ObstacleId::TumblingBoulders;
    let tumbling_boulders_tier = ObstacleUtils::get_tier(tumbling_boulders);
    assert(tumbling_boulders_tier == Tier::T4(()), 'tumbling_boulders should be T4');

    let swinging_logs = ObstacleId::SwingingLogs;
    let swinging_logs_tier = ObstacleUtils::get_tier(swinging_logs);
    assert(swinging_logs_tier == Tier::T5(()), 'swinging_logs should be T5');

    let pendulum_blades = ObstacleId::PendulumBlades;
    let pendulum_blades_tier = ObstacleUtils::get_tier(pendulum_blades);
    assert(pendulum_blades_tier == Tier::T1(()), 'pendulum_blades should be T1');

    let flame_jet = ObstacleId::FlameJet;
    let flame_jet_tier = ObstacleUtils::get_tier(flame_jet);
    assert(flame_jet_tier == Tier::T2(()), 'flame_jet should be T2');

    let poison_dart = ObstacleId::PoisonDart;
    let poison_dart_tier = ObstacleUtils::get_tier(poison_dart);
    assert(poison_dart_tier == Tier::T3(()), 'poison_dart should be T3');

    let spiked_pit = ObstacleId::SpikedPit;
    let spiked_pit_tier = ObstacleUtils::get_tier(spiked_pit);
    assert(spiked_pit_tier == Tier::T4(()), 'spiked_pit should be T4');

    let hidden_arrow = ObstacleId::HiddenArrow;
    let hidden_arrow_tier = ObstacleUtils::get_tier(hidden_arrow);
    assert(hidden_arrow_tier == Tier::T5(()), 'hidden_arrow should be T5');
}

#[test]
#[available_gas(100000)]
fn test_get_obstacle_type() {
    let demonic_alter = ObstacleId::DemonicAlter;
    let demonic_alter_type = ObstacleUtils::get_type(demonic_alter);
    assert(demonic_alter_type == Type::Magic_or_Cloth(()), 'demonic_alter should be magic');

    let curse = ObstacleId::Curse;
    let curse_type = ObstacleUtils::get_type(curse);
    assert(curse_type == Type::Magic_or_Cloth(()), 'curse should be magic');

    let hex = ObstacleId::Hex;
    let hex_type = ObstacleUtils::get_type(hex);
    assert(hex_type == Type::Magic_or_Cloth(()), 'hex should be magic');

    let magic_lock = ObstacleId::MagicLock;
    let magic_lock_type = ObstacleUtils::get_type(magic_lock);
    assert(magic_lock_type == Type::Magic_or_Cloth(()), 'magic_lock should be magic');

    let dark_mist = ObstacleId::DarkMist;
    let dark_mist_type = ObstacleUtils::get_type(dark_mist);
    assert(dark_mist_type == Type::Magic_or_Cloth(()), 'dark_mist should be magic');

    let collapsing_ceiling = ObstacleId::CollapsingCeiling;
    let collapsing_ceiling_type = ObstacleUtils::get_type(collapsing_ceiling);
    assert(
        collapsing_ceiling_type == Type::Bludgeon_or_Metal(()), 'collapsing_ceiling is bludgeon'
    );

    let crushing_walls = ObstacleId::CrushingWalls;
    let crushing_walls_type = ObstacleUtils::get_type(crushing_walls);
    assert(crushing_walls_type == Type::Bludgeon_or_Metal(()), 'crushing_walls is bludgeon');

    let rockslide = ObstacleId::Rockslide;
    let rockslide_type = ObstacleUtils::get_type(rockslide);
    assert(rockslide_type == Type::Bludgeon_or_Metal(()), 'rockslide should be bludgeon');

    let tumbling_boulders = ObstacleId::TumblingBoulders;
    let tumbling_boulders_type = ObstacleUtils::get_type(tumbling_boulders);
    assert(tumbling_boulders_type == Type::Bludgeon_or_Metal(()), 'tumbling_boulders type ');

    let swinging_logs = ObstacleId::SwingingLogs;
    let swinging_logs_type = ObstacleUtils::get_type(swinging_logs);
    assert(swinging_logs_type == Type::Bludgeon_or_Metal(()), 'swinging_logs is bludgeon');

    let pendulum_blades = ObstacleId::PendulumBlades;
    let pendulum_blades_type = ObstacleUtils::get_type(pendulum_blades);
    assert(pendulum_blades_type == Type::Blade_or_Hide(()), 'pendulum_blades should be blade');

    let flame_jet = ObstacleId::FlameJet;
    let flame_jet_type = ObstacleUtils::get_type(flame_jet);
    assert(flame_jet_type == Type::Blade_or_Hide(()), 'flame_jet should be blade');

    let poison_dart = ObstacleId::PoisonDart;
    let poison_dart_type = ObstacleUtils::get_type(poison_dart);
    assert(poison_dart_type == Type::Blade_or_Hide(()), 'poison_dart should be blade');

    let spiked_pit = ObstacleId::SpikedPit;
    let spiked_pit_type = ObstacleUtils::get_type(spiked_pit);
    assert(spiked_pit_type == Type::Blade_or_Hide(()), 'spiked_pit should be blade');

    let hidden_arrow = ObstacleId::HiddenArrow;
    let hidden_arrow_type = ObstacleUtils::get_type(hidden_arrow);
    assert(hidden_arrow_type == Type::Blade_or_Hide(()), 'hidden_arrow should be blade');
}

