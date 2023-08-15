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
        let obstacle_id = ImplObstacle::get_random_id(entropy);
        // get random obstacle level
        let obstacle_level = ImplObstacle::get_random_level(adventurer_level, entropy);
        // return obstacle
        let obstacle = ImplObstacle::get_obstacle(obstacle_id, obstacle_level);
        let dodged = ImplObstacle::dodged(adventurer_level, adventurer_intelligence, entropy);
        (obstacle, dodged)
    }

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
        if id == ObstacleId::DemonicAlter {
            Tier::T1(())
        } else if id == ObstacleId::VortexOfDespair {
            Tier::T1(())
        } else if id == ObstacleId::EldritchBarrier {
            Tier::T1(())
        } else if id == ObstacleId::SoulTrap {
            Tier::T1(())
        } else if id == ObstacleId::PhantomVortex {
            Tier::T1(())
        } else if id == ObstacleId::EctoplasmicWeb {
            Tier::T2(())
        } else if id == ObstacleId::SpectralChains {
            Tier::T2(())
        } else if id == ObstacleId::InfernalPact {
            Tier::T2(())
        } else if id == ObstacleId::ArcaneExplosion {
            Tier::T2(())
        } else if id == ObstacleId::HypnoticEssence {
            Tier::T2(())
        } else if id == ObstacleId::MischievousSprites {
            Tier::T3(())
        } else if id == ObstacleId::SoulDrainingStatue {
            Tier::T3(())
        } else if id == ObstacleId::PetrifyingGaze {
            Tier::T3(())
        } else if id == ObstacleId::SummoningCircle {
            Tier::T3(())
        } else if id == ObstacleId::EtherealVoid {
            Tier::T3(())
        } else if id == ObstacleId::MagicLock {
            Tier::T4(())
        } else if id == ObstacleId::BewitchingFog {
            Tier::T4(())
        } else if id == ObstacleId::IllusionaryMaze {
            Tier::T4(())
        } else if id == ObstacleId::SpellboundMirror {
            Tier::T4(())
        } else if id == ObstacleId::EnsnaringShadow {
            Tier::T4(())
        } else if id == ObstacleId::DarkMist {
            Tier::T5(())
        } else if id == ObstacleId::Curse {
            Tier::T5(())
        } else if id == ObstacleId::HauntingEcho {
            Tier::T5(())
        } else if id == ObstacleId::Hex {
            Tier::T5(())
        } else if id == ObstacleId::GhostlyWhispers {
            Tier::T5(())
        } else if id == ObstacleId::PendulumBlades {
            Tier::T1(())
        } else if id == ObstacleId::IcyRazorWinds {
            Tier::T1(())
        } else if id == ObstacleId::AcidicThorns {
            Tier::T1(())
        } else if id == ObstacleId::DragonsBreath {
            Tier::T1(())
        } else if id == ObstacleId::PendulumScythe {
            Tier::T1(())
        } else if id == ObstacleId::FlameJet {
            Tier::T2(())
        } else if id == ObstacleId::PiercingIceDarts {
            Tier::T2(())
        } else if id == ObstacleId::GlassSandStorm {
            Tier::T2(())
        } else if id == ObstacleId::PoisonedDartWall {
            Tier::T2(())
        } else if id == ObstacleId::SpinningBladeWheel {
            Tier::T2(())
        } else if id == ObstacleId::PoisonDart {
            Tier::T3(())
        } else if id == ObstacleId::SpikedTumbleweed {
            Tier::T3(())
        } else if id == ObstacleId::Thunderbolt {
            Tier::T3(())
        } else if id == ObstacleId::GiantBearTrap {
            Tier::T3(())
        } else if id == ObstacleId::SteelNeedleRain {
            Tier::T3(())
        } else if id == ObstacleId::SpikedPit {
            Tier::T4(())
        } else if id == ObstacleId::DiamondDustStorm {
            Tier::T4(())
        } else if id == ObstacleId::TrapdoorScorpionPit {
            Tier::T4(())
        } else if id == ObstacleId::BladedFan {
            Tier::T4(())
        } else if id == ObstacleId::BearTrap {
            Tier::T4(())
        } else if id == ObstacleId::PorcupineQuill {
            Tier::T5(())
        } else if id == ObstacleId::HiddenArrow {
            Tier::T5(())
        } else if id == ObstacleId::GlassShard {
            Tier::T5(())
        } else if id == ObstacleId::ThornBush {
            Tier::T5(())
        } else if id == ObstacleId::JaggedRocks {
            Tier::T5(())
        } else if id == ObstacleId::CollapsingCeiling {
            Tier::T1(())
        } else if id == ObstacleId::Rockslide {
            Tier::T1(())
        } else if id == ObstacleId::FlashFlood {
            Tier::T1(())
        } else if id == ObstacleId::ClingingRoots {
            Tier::T1(())
        } else if id == ObstacleId::CollapsingCavern {
            Tier::T1(())
        } else if id == ObstacleId::CrushingWalls {
            Tier::T2(())
        } else if id == ObstacleId::SmashingPillars {
            Tier::T2(())
        } else if id == ObstacleId::RumblingCatacomb {
            Tier::T2(())
        } else if id == ObstacleId::WhirlingCyclone {
            Tier::T2(())
        } else if id == ObstacleId::EruptingEarth {
            Tier::T2(())
        } else if id == ObstacleId::SubterraneanTremor {
            Tier::T3(())
        } else if id == ObstacleId::FallingChandelier {
            Tier::T3(())
        } else if id == ObstacleId::CollapsingBridge {
            Tier::T3(())
        } else if id == ObstacleId::RagingSandstorm {
            Tier::T3(())
        } else if id == ObstacleId::AvalanchingRocks {
            Tier::T3(())
        } else if id == ObstacleId::TumblingBoulders {
            Tier::T4(())
        } else if id == ObstacleId::SlammingIronGate {
            Tier::T4(())
        } else if id == ObstacleId::ShiftingSandtrap {
            Tier::T4(())
        } else if id == ObstacleId::EruptingMudGeyser {
            Tier::T4(())
        } else if id == ObstacleId::CrumblingStaircase {
            Tier::T4(())
        } else if id == ObstacleId::SwingingLogs {
            Tier::T5(())
        } else if id == ObstacleId::UnstableCliff {
            Tier::T5(())
        } else if id == ObstacleId::TopplingStatue {
            Tier::T5(())
        } else if id == ObstacleId::TumblingBarrels {
            Tier::T5(())
        } else if id == ObstacleId::RollingBoulder {
            Tier::T5(())
        } else {
            panic_with_felt252('unknown obstacle id')
        }
    }

    // @notice returns the type of the obstacle based on the provided obstacle id
    // @param id: u8 - the obstacle id
    // @return u8 - the obstacle type
    fn get_type(id: u8) -> Type {
        if id == ObstacleId::DemonicAlter {
            Type::Magic_or_Cloth(())
        } else if id == ObstacleId::VortexOfDespair {
            Type::Magic_or_Cloth(())
        } else if id == ObstacleId::EldritchBarrier {
            Type::Magic_or_Cloth(())
        } else if id == ObstacleId::SoulTrap {
            Type::Magic_or_Cloth(())
        } else if id == ObstacleId::PhantomVortex {
            Type::Magic_or_Cloth(())
        } else if id == ObstacleId::EctoplasmicWeb {
            Type::Magic_or_Cloth(())
        } else if id == ObstacleId::SpectralChains {
            Type::Magic_or_Cloth(())
        } else if id == ObstacleId::InfernalPact {
            Type::Magic_or_Cloth(())
        } else if id == ObstacleId::ArcaneExplosion {
            Type::Magic_or_Cloth(())
        } else if id == ObstacleId::HypnoticEssence {
            Type::Magic_or_Cloth(())
        } else if id == ObstacleId::MischievousSprites {
            Type::Magic_or_Cloth(())
        } else if id == ObstacleId::SoulDrainingStatue {
            Type::Magic_or_Cloth(())
        } else if id == ObstacleId::PetrifyingGaze {
            Type::Magic_or_Cloth(())
        } else if id == ObstacleId::SummoningCircle {
            Type::Magic_or_Cloth(())
        } else if id == ObstacleId::EtherealVoid {
            Type::Magic_or_Cloth(())
        } else if id == ObstacleId::MagicLock {
            Type::Magic_or_Cloth(())
        } else if id == ObstacleId::BewitchingFog {
            Type::Magic_or_Cloth(())
        } else if id == ObstacleId::IllusionaryMaze {
            Type::Magic_or_Cloth(())
        } else if id == ObstacleId::SpellboundMirror {
            Type::Magic_or_Cloth(())
        } else if id == ObstacleId::EnsnaringShadow {
            Type::Magic_or_Cloth(())
        } else if id == ObstacleId::DarkMist {
            Type::Magic_or_Cloth(())
        } else if id == ObstacleId::Curse {
            Type::Magic_or_Cloth(())
        } else if id == ObstacleId::HauntingEcho {
            Type::Magic_or_Cloth(())
        } else if id == ObstacleId::Hex {
            Type::Magic_or_Cloth(())
        } else if id == ObstacleId::GhostlyWhispers {
            Type::Magic_or_Cloth(())
        } else if id == ObstacleId::PendulumBlades {
            Type::Blade_or_Hide(())
        } else if id == ObstacleId::IcyRazorWinds {
            Type::Blade_or_Hide(())
        } else if id == ObstacleId::AcidicThorns {
            Type::Blade_or_Hide(())
        } else if id == ObstacleId::DragonsBreath {
            Type::Blade_or_Hide(())
        } else if id == ObstacleId::PendulumScythe {
            Type::Blade_or_Hide(())
        } else if id == ObstacleId::FlameJet {
            Type::Blade_or_Hide(())
        } else if id == ObstacleId::PiercingIceDarts {
            Type::Blade_or_Hide(())
        } else if id == ObstacleId::GlassSandStorm {
            Type::Blade_or_Hide(())
        } else if id == ObstacleId::PoisonedDartWall {
            Type::Blade_or_Hide(())
        } else if id == ObstacleId::SpinningBladeWheel {
            Type::Blade_or_Hide(())
        } else if id == ObstacleId::PoisonDart {
            Type::Blade_or_Hide(())
        } else if id == ObstacleId::SpikedTumbleweed {
            Type::Blade_or_Hide(())
        } else if id == ObstacleId::Thunderbolt {
            Type::Blade_or_Hide(())
        } else if id == ObstacleId::GiantBearTrap {
            Type::Blade_or_Hide(())
        } else if id == ObstacleId::SteelNeedleRain {
            Type::Blade_or_Hide(())
        } else if id == ObstacleId::SpikedPit {
            Type::Blade_or_Hide(())
        } else if id == ObstacleId::DiamondDustStorm {
            Type::Blade_or_Hide(())
        } else if id == ObstacleId::TrapdoorScorpionPit {
            Type::Blade_or_Hide(())
        } else if id == ObstacleId::BladedFan {
            Type::Blade_or_Hide(())
        } else if id == ObstacleId::BearTrap {
            Type::Blade_or_Hide(())
        } else if id == ObstacleId::PorcupineQuill {
            Type::Blade_or_Hide(())
        } else if id == ObstacleId::HiddenArrow {
            Type::Blade_or_Hide(())
        } else if id == ObstacleId::GlassShard {
            Type::Blade_or_Hide(())
        } else if id == ObstacleId::ThornBush {
            Type::Blade_or_Hide(())
        } else if id == ObstacleId::JaggedRocks {
            Type::Blade_or_Hide(())
        } else if id == ObstacleId::CollapsingCeiling {
            Type::Bludgeon_or_Metal(())
        } else if id == ObstacleId::Rockslide {
            Type::Bludgeon_or_Metal(())
        } else if id == ObstacleId::FlashFlood {
            Type::Bludgeon_or_Metal(())
        } else if id == ObstacleId::ClingingRoots {
            Type::Bludgeon_or_Metal(())
        } else if id == ObstacleId::CollapsingCavern {
            Type::Bludgeon_or_Metal(())
        } else if id == ObstacleId::CrushingWalls {
            Type::Bludgeon_or_Metal(())
        } else if id == ObstacleId::SmashingPillars {
            Type::Bludgeon_or_Metal(())
        } else if id == ObstacleId::RumblingCatacomb {
            Type::Bludgeon_or_Metal(())
        } else if id == ObstacleId::WhirlingCyclone {
            Type::Bludgeon_or_Metal(())
        } else if id == ObstacleId::EruptingEarth {
            Type::Bludgeon_or_Metal(())
        } else if id == ObstacleId::SubterraneanTremor {
            Type::Bludgeon_or_Metal(())
        } else if id == ObstacleId::FallingChandelier {
            Type::Bludgeon_or_Metal(())
        } else if id == ObstacleId::CollapsingBridge {
            Type::Bludgeon_or_Metal(())
        } else if id == ObstacleId::RagingSandstorm {
            Type::Bludgeon_or_Metal(())
        } else if id == ObstacleId::AvalanchingRocks {
            Type::Bludgeon_or_Metal(())
        } else if id == ObstacleId::TumblingBoulders {
            Type::Bludgeon_or_Metal(())
        } else if id == ObstacleId::SlammingIronGate {
            Type::Bludgeon_or_Metal(())
        } else if id == ObstacleId::ShiftingSandtrap {
            Type::Bludgeon_or_Metal(())
        } else if id == ObstacleId::EruptingMudGeyser {
            Type::Bludgeon_or_Metal(())
        } else if id == ObstacleId::CrumblingStaircase {
            Type::Bludgeon_or_Metal(())
        } else if id == ObstacleId::SwingingLogs {
            Type::Bludgeon_or_Metal(())
        } else if id == ObstacleId::UnstableCliff {
            Type::Bludgeon_or_Metal(())
        } else if id == ObstacleId::TopplingStatue {
            Type::Bludgeon_or_Metal(())
        } else if id == ObstacleId::TumblingBarrels {
            Type::Bludgeon_or_Metal(())
        } else if id == ObstacleId::RollingBoulder {
            Type::Bludgeon_or_Metal(())
        } else {
            panic_with_felt252('unknown obstacle id')
        }
    }

    // @notice Calculates the damage dealt by an obstacle to an armor based on specific combat specifications.
    // @param obstacle The obstacle whose damage is being calculated.
    // @param armor_combat_spec The combat specifications of the armor.
    // @param entropy A value used to introduce randomness in the damage calculation.
    // @return The calculated damage as a 16-bit unsigned integer.
    // @dev Note that critical hits are not considered for obstacles in this calculation.
    fn get_damage(obstacle: Obstacle, armor_combat_spec: CombatSpec, entropy: u128) -> u16 {
        // no critical hits for obstacles
        let is_critical_hit = false;

        ImplCombat::calculate_damage(
            obstacle.combat_specs,
            armor_combat_spec,
            ObstacleSettings::MINIMUM_DAMAGE,
            ObstacleSettings::DAMAGE_BOOST,
            is_critical_hit,
            entropy
        )
    }

    // @notice get_xp_reward returns the xp reward from encountering the obstacle
    // @param obstacle: Obstacle - the obstacle
    // @return u16 - the xp reward
    fn get_xp_reward(self: Obstacle) -> u16 {
        let xp_reward = self.combat_specs.get_xp_reward();
        if (xp_reward < ObstacleSettings::MINIMUM_XP_REWARD) {
            ObstacleSettings::MINIMUM_XP_REWARD
        } else {
            xp_reward
        }
    }

    // @notice dodged returns true if the adventurer dodged the obstacle
    // @param adventurer_level: u8 - the adventurer level
    // @param adventurer_intelligence: u8 - the adventurer intelligence
    // @param entropy: u128 - the entropy
    // @return bool - true if the adventurer dodged the obstacle
    fn dodged(adventurer_level: u8, adventurer_intelligence: u8, entropy: u128) -> bool {
        // Delegate ambushed calculation to combat system
        // avoiding beast ambush requires wisdom
        ImplCombat::ability_based_avoid_threat(adventurer_level, adventurer_intelligence, entropy)
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
    #[available_gas(5000000)]
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
    #[available_gas(5000000)]
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
    #[available_gas(5000000)]
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
    #[available_gas(500000)]
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
    #[available_gas(400000)]
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
