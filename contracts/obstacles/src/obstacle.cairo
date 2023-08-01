use option::OptionTrait;
use core::traits::{Into, TryInto};
use super::constants::{ObstacleId, ObstacleSettings};
use combat::{
    combat::{ICombat, ImplCombat, CombatSpec, SpecialPowers},
    constants::{CombatSettings, CombatEnums::{Type, Tier, Slot}}
};

#[derive(Drop, Copy)]
struct Obstacle {
    id: u8,
    combat_specs: CombatSpec,
}

#[generate_trait]
impl ImplObstacle of IObstacle {
    // obstacle_encounter returns a random obstacle based on the adventurer level and entropy
    // @param adventurer_level: u8 - the adventurer level
    // @param entropy: u128 - entropy for level generation
    fn obstacle_encounter(
        adventurer_level: u8, adventurer_intelligence: u8, entropy: u128
    ) -> (Obstacle, bool) {
        // get random obstacle id
        let obstacle_id = ImplObstacle::obstacle_encounter_id(entropy);
        // get random obstacle level
        let obstacle_level = ImplObstacle::get_random_level(adventurer_level, entropy);
        // return obstacle
        let obstacle = ImplObstacle::get_obstacle(obstacle_id, obstacle_level);
        let dodged = ImplObstacle::dodged(adventurer_level, adventurer_intelligence, entropy);
        return (obstacle, dodged);
    }

    // obstacle_encounter_id returns a random obstacle id based on adventurer, adventurer entropy, and game entropy
    // the obstacle id will be between 1 and the max obstacle id (inclusive)
    // @param entropy: u128 - entropy from random id generation
    // @return u8 - the obstacle id
    fn obstacle_encounter_id(entropy: u128) -> u8 {
        // select an obstacle between 1 and max obstacle id (inclusive)
        let obstacle_id = (entropy % ObstacleId::MAX_ID.into()) + 1;

        // return obstacle id as a u8
        obstacle_id.try_into().unwrap()
    }
    // get_obstacle returns an obstacle based on the provided obstacle id and level
    // @param id: u8 - the obstacle id
    // @param level: u16 - the obstacle level
    // @return Obstacle - the obstacle
    fn get_obstacle(id: u8, _level: u16) -> Obstacle {
        let combat_specs = CombatSpec {
            tier: ImplObstacle::get_tier(id),
            item_type: ImplObstacle::get_type(id),
            level: _level,
            specials: SpecialPowers {
                special1: 0, special2: 0, special3: 0, 
            }
        };

        Obstacle { id: id, combat_specs: combat_specs }
    }

    // get_level uses the combat lib to generate a random level scoped for the adventurer level
    // @param adventurer_level: the level of adventurer ()
    // @param entropy: entropy for random level generation
    // @return u8 - the obstacle level
    fn get_random_level(adventurer_level: u8, entropy: u128) -> u16 {
        ImplCombat::get_random_level(adventurer_level, entropy)
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

    // get_damage returns the damage of the obstacle based on the provided obstacle id
    fn get_damage(obstacle: Obstacle, armor_combat_spec: CombatSpec, entropy: u128) -> u16 {
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
    fn get_xp_reward(self: Obstacle) -> u16 {
        let xp_reward = self.combat_specs.get_xp_reward();
        if (xp_reward < ObstacleSettings::MINIMUM_XP_REWARD) {
            return ObstacleSettings::MINIMUM_XP_REWARD;
        } else {
            return xp_reward;
        }
    }

    // dodged returns true if the adventurer dodged the obstacle
    // @param adventurer_level: u8 - the adventurer level
    // @param adventurer_intelligence: u8 - the adventurer intelligence
    // @param entropy: u128 - the entropy
    // @return bool - true if the adventurer dodged the obstacle
    fn dodged(adventurer_level: u8, adventurer_intelligence: u8, entropy: u128) -> bool {
        // Delegate ambushed calculation to combat system
        // avoiding beast ambush requires wisdom
        return ImplCombat::ability_based_avoid_threat(
            adventurer_level, adventurer_intelligence, entropy
        );
    }
}

#[test]
#[available_gas(100000)]
fn test_get_obstacle_tier() {
    let demonic_alter = ObstacleId::DemonicAlter;
    let demonic_alter_tier = ImplObstacle::get_tier(demonic_alter);
    assert(demonic_alter_tier == Tier::T1(()), 'demonic_alter should be T1');

    let curse = ObstacleId::Curse;
    let curse_tier = ImplObstacle::get_tier(curse);
    assert(curse_tier == Tier::T2(()), 'curse should be T2');

    let hex = ObstacleId::Hex;
    let hex_tier = ImplObstacle::get_tier(hex);
    assert(hex_tier == Tier::T3(()), 'hex should be T3');

    let magic_lock = ObstacleId::MagicLock;
    let magic_lock_tier = ImplObstacle::get_tier(magic_lock);
    assert(magic_lock_tier == Tier::T4(()), 'magic_lock should be T4');

    let dark_mist = ObstacleId::DarkMist;
    let dark_mist_tier = ImplObstacle::get_tier(dark_mist);
    assert(dark_mist_tier == Tier::T5(()), 'dark_mist should be T5');

    let collapsing_ceiling = ObstacleId::CollapsingCeiling;
    let collapsing_ceiling_tier = ImplObstacle::get_tier(collapsing_ceiling);
    assert(collapsing_ceiling_tier == Tier::T1(()), 'collapsing_ceiling should be T1');

    let crushing_walls = ObstacleId::CrushingWalls;
    let crushing_walls_tier = ImplObstacle::get_tier(crushing_walls);
    assert(crushing_walls_tier == Tier::T2(()), 'crushing_walls should be T2');

    let rockslide = ObstacleId::Rockslide;
    let rockslide_tier = ImplObstacle::get_tier(rockslide);
    assert(rockslide_tier == Tier::T3(()), 'rockslide should be T3');

    let tumbling_boulders = ObstacleId::TumblingBoulders;
    let tumbling_boulders_tier = ImplObstacle::get_tier(tumbling_boulders);
    assert(tumbling_boulders_tier == Tier::T4(()), 'tumbling_boulders should be T4');

    let swinging_logs = ObstacleId::SwingingLogs;
    let swinging_logs_tier = ImplObstacle::get_tier(swinging_logs);
    assert(swinging_logs_tier == Tier::T5(()), 'swinging_logs should be T5');

    let pendulum_blades = ObstacleId::PendulumBlades;
    let pendulum_blades_tier = ImplObstacle::get_tier(pendulum_blades);
    assert(pendulum_blades_tier == Tier::T1(()), 'pendulum_blades should be T1');

    let flame_jet = ObstacleId::FlameJet;
    let flame_jet_tier = ImplObstacle::get_tier(flame_jet);
    assert(flame_jet_tier == Tier::T2(()), 'flame_jet should be T2');

    let poison_dart = ObstacleId::PoisonDart;
    let poison_dart_tier = ImplObstacle::get_tier(poison_dart);
    assert(poison_dart_tier == Tier::T3(()), 'poison_dart should be T3');

    let spiked_pit = ObstacleId::SpikedPit;
    let spiked_pit_tier = ImplObstacle::get_tier(spiked_pit);
    assert(spiked_pit_tier == Tier::T4(()), 'spiked_pit should be T4');

    let hidden_arrow = ObstacleId::HiddenArrow;
    let hidden_arrow_tier = ImplObstacle::get_tier(hidden_arrow);
    assert(hidden_arrow_tier == Tier::T5(()), 'hidden_arrow should be T5');
}

#[test]
#[available_gas(100000)]
fn test_get_obstacle_type() {
    let demonic_alter = ObstacleId::DemonicAlter;
    let demonic_alter_type = ImplObstacle::get_type(demonic_alter);
    assert(demonic_alter_type == Type::Magic_or_Cloth(()), 'demonic_alter should be magic');

    let curse = ObstacleId::Curse;
    let curse_type = ImplObstacle::get_type(curse);
    assert(curse_type == Type::Magic_or_Cloth(()), 'curse should be magic');

    let hex = ObstacleId::Hex;
    let hex_type = ImplObstacle::get_type(hex);
    assert(hex_type == Type::Magic_or_Cloth(()), 'hex should be magic');

    let magic_lock = ObstacleId::MagicLock;
    let magic_lock_type = ImplObstacle::get_type(magic_lock);
    assert(magic_lock_type == Type::Magic_or_Cloth(()), 'magic_lock should be magic');

    let dark_mist = ObstacleId::DarkMist;
    let dark_mist_type = ImplObstacle::get_type(dark_mist);
    assert(dark_mist_type == Type::Magic_or_Cloth(()), 'dark_mist should be magic');

    let collapsing_ceiling = ObstacleId::CollapsingCeiling;
    let collapsing_ceiling_type = ImplObstacle::get_type(collapsing_ceiling);
    assert(
        collapsing_ceiling_type == Type::Bludgeon_or_Metal(()), 'collapsing_ceiling is bludgeon'
    );

    let crushing_walls = ObstacleId::CrushingWalls;
    let crushing_walls_type = ImplObstacle::get_type(crushing_walls);
    assert(crushing_walls_type == Type::Bludgeon_or_Metal(()), 'crushing_walls is bludgeon');

    let rockslide = ObstacleId::Rockslide;
    let rockslide_type = ImplObstacle::get_type(rockslide);
    assert(rockslide_type == Type::Bludgeon_or_Metal(()), 'rockslide should be bludgeon');

    let tumbling_boulders = ObstacleId::TumblingBoulders;
    let tumbling_boulders_type = ImplObstacle::get_type(tumbling_boulders);
    assert(tumbling_boulders_type == Type::Bludgeon_or_Metal(()), 'tumbling_boulders type ');

    let swinging_logs = ObstacleId::SwingingLogs;
    let swinging_logs_type = ImplObstacle::get_type(swinging_logs);
    assert(swinging_logs_type == Type::Bludgeon_or_Metal(()), 'swinging_logs is bludgeon');

    let pendulum_blades = ObstacleId::PendulumBlades;
    let pendulum_blades_type = ImplObstacle::get_type(pendulum_blades);
    assert(pendulum_blades_type == Type::Blade_or_Hide(()), 'pendulum_blades should be blade');

    let flame_jet = ObstacleId::FlameJet;
    let flame_jet_type = ImplObstacle::get_type(flame_jet);
    assert(flame_jet_type == Type::Blade_or_Hide(()), 'flame_jet should be blade');

    let poison_dart = ObstacleId::PoisonDart;
    let poison_dart_type = ImplObstacle::get_type(poison_dart);
    assert(poison_dart_type == Type::Blade_or_Hide(()), 'poison_dart should be blade');

    let spiked_pit = ObstacleId::SpikedPit;
    let spiked_pit_type = ImplObstacle::get_type(spiked_pit);
    assert(spiked_pit_type == Type::Blade_or_Hide(()), 'spiked_pit should be blade');

    let hidden_arrow = ObstacleId::HiddenArrow;
    let hidden_arrow_type = ImplObstacle::get_type(hidden_arrow);
    assert(hidden_arrow_type == Type::Blade_or_Hide(()), 'hidden_arrow should be blade');
}

