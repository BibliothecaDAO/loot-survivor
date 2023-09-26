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
    combat_spec: CombatSpec,
}

#[generate_trait]
impl ImplObstacle of IObstacle {
    // @notice returns a random obstacle id based on the provided entropy
    // @param entropy: u128 - entropy from random id generation
    // @return u8 - the obstacle id
    fn get_random_id(entropy: u128) -> u8 {
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
        let combat_spec = CombatSpec {
            tier: ImplObstacle::get_tier(id),
            item_type: ImplObstacle::get_type(id),
            level: _level,
            specials: SpecialPowers { special1: 0, special2: 0, special3: 0, }
        };

        Obstacle { id: id, combat_spec: combat_spec }
    }

    // @notice uses the combat lib to generate a random level scoped for the adventurer level
    // @param adventurer_level: the level of adventurer ()
    // @param entropy: entropy for random level generation
    // @return u8 - the obstacle level
    fn get_random_level(adventurer_level: u8, entropy: u128) -> u16 {
        ImplCombat::get_random_level(adventurer_level, entropy)
    }

    // @notice returns the tier of the obstacle based on the provided obstacle id
    // @param id: u8 - the obstacle id
    // @return u8 - the obstacle tier
    fn get_tier(id: u8) -> Tier {
        if ImplObstacle::is_t1(id) {
            return Tier::T1(());
        } else if ImplObstacle::is_t2(id){
            return Tier::T2(());
        } else if ImplObstacle::is_t3(id) {
            return Tier::T3(());
        } else if ImplObstacle::is_t4(id) {
            return Tier::T4(());
        } else {
            return Tier::T5(());
        }
    }

    #[inline(always)]
    fn is_t1(id: u8) -> bool {
        (id >= 1 && id < 6) || (id >= 26 && id < 31) || (id >= 51 && id < 56)
    }
    #[inline(always)]
    fn is_t2(id: u8) -> bool {
        (id >= 6 && id < 11) || (id >= 31 && id < 36) || (id >= 56 && id < 61)
    }
    #[inline(always)]
    fn is_t3(id: u8) -> bool {
        (id >= 11 && id < 16) || (id >= 36 && id < 41) || (id >= 61 && id < 66)
    }
    #[inline(always)]
    fn is_t4(id: u8) -> bool {
        (id >= 16 && id < 21) || (id >= 41 && id < 46) || (id >= 66 && id < 71)
    }

    // @notice returns the type of the obstacle based on the provided obstacle id
    // @param id: u8 - the obstacle id
    // @return u8 - the obstacle type
    fn get_type(id: u8) -> Type {
        if id < ObstacleId::PendulumBlades {
            return Type::Magic_or_Cloth(());
        } else if id < ObstacleId::CollapsingCeiling {
            return Type::Blade_or_Hide(());
        } else {
            return Type::Bludgeon_or_Metal(());
        }
    }

    // @notice get_xp_reward returns the xp reward from encountering the obstacle
    // @param obstacle: Obstacle - the obstacle
    // @return u16 - the xp reward
    fn get_xp_reward(self: Obstacle) -> u16 {
        let xp_reward = self.combat_spec.get_base_reward();
        if (xp_reward < ObstacleSettings::MINIMUM_XP_REWARD) {
            ObstacleSettings::MINIMUM_XP_REWARD
        } else {
            xp_reward
        }
    }
}

// ---------------------------
// ---------- Tests ----------
// ---------------------------
#[cfg(test)]
mod tests {
    use option::OptionTrait;
    use core::traits::{Into, TryInto};
    use obstacles::{obstacle::{ImplObstacle, IObstacle}, constants::{ObstacleId, ObstacleSettings}};
    use combat::{
        combat::{ICombat, ImplCombat, CombatSpec, SpecialPowers},
        constants::{CombatSettings, CombatEnums::{Type, Tier, Slot}}
    };

    #[test]
    #[available_gas(14390)]
    fn test_get_tier_gas() {
        ImplObstacle::get_tier(75);
    }

    #[test]
    #[available_gas(1840)]
    fn test_get_type_gas() {
        ImplObstacle::get_type(75);
    }

    #[test]
    #[available_gas(1666510)]
    fn test_get_obstacle_tier_range_check() {
        // iterate over all obstacles and make sure we aren't missing any
        let mut obstacle_id = 1;
        loop {
            if obstacle_id > ObstacleId::MAX_ID {
                break ();
            }

            // no need to assert something, get_tier will throw a 'unknown obstacle id' if an obstacle is undefined
            ImplObstacle::get_tier(obstacle_id);
            obstacle_id += 1;
        }
    }

    #[test]
    #[available_gas(531070)]
    fn test_get_obstacle_type_range_check() {
        // iterate over all obstacles and make sure we aren't missing any
        let mut obstacle_id = 1;
        loop {
            if obstacle_id > ObstacleId::MAX_ID {
                break ();
            }
            // no need to assert something, get_tier will throw a 'unknown obstacle id' if an obstacle is undefined
            ImplObstacle::get_type(obstacle_id);
            obstacle_id += 1;
        }
    }

    #[test]
    #[available_gas(1897550)]
    fn test_get_obstacle_range_check() {
        // iterate over all obstacles and make sure we aren't missing any
        let mut obstacle_id = 1;
        loop {
            if obstacle_id > ObstacleId::MAX_ID {
                break ();
            }
            // no need to assert something, get_tier will throw a 'unknown obstacle id' if an obstacle is undefined
            ImplObstacle::get_obstacle(obstacle_id, 1);
            obstacle_id += 1;
        }
    }

    #[test]
    #[available_gas(270400)]
    fn test_get_obstacle_tier() {
        let demonic_alter = ObstacleId::DemonicAlter;
        let demonic_alter_tier = ImplObstacle::get_tier(demonic_alter);
        assert(demonic_alter_tier == Tier::T1(()), 'demonic_alter should be T1');

        let curse = ObstacleId::Curse;
        let curse_tier = ImplObstacle::get_tier(curse);
        assert(curse_tier == Tier::T5(()), 'curse should be T5');

        let hex = ObstacleId::Hex;
        let hex_tier = ImplObstacle::get_tier(hex);
        assert(hex_tier == Tier::T5(()), 'hex should be T5');

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
        assert(rockslide_tier == Tier::T1(()), 'rockslide should be T1');

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
    #[available_gas(46300)]
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
}
