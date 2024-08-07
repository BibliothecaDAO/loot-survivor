use core::serde::Serde;
use traits::{TryInto, Into};
use option::OptionTrait;
use super::constants::{
    BeastId::{
        Warlock, Typhon, Jiangshi, Anansi, Basilisk, Gorgon, Kitsune, Lich, Chimera, Wendigo,
        Rakshasa, Werewolf, Banshee, Draugr, Vampire, Goblin, Ghoul, Wraith, Sprite, Kappa, Fairy,
        Leprechaun, Kelpie, Pixie, Gnome, Griffin, Manticore, Phoenix, Dragon, Minotaur, Qilin,
        Ammit, Nue, Skinwalker, Chupacabra, Weretiger, Wyvern, Roc, Harpy, Pegasus, Hippogriff,
        Fenrir, Jaguar, Satori, DireWolf, Bear, Wolf, Mantis, Spider, Rat, Kraken, Colossus, Balrog,
        Leviathan, Tarrasque, Titan, Nephilim, Behemoth, Hydra, Juggernaut, Oni, Jotunn, Ettin,
        Cyclops, Giant, NemeanLion, Berserker, Yeti, Golem, Ent, Troll, Bigfoot, Ogre, Orc,
        Skeleton, MAX_ID,
    },
    BeastSettings::{
        STARTER_BEAST_HEALTH, MINIMUM_XP_REWARD, MAXIMUM_HEALTH, CRITICAL_HIT_LEVEL_MULTIPLIER,
        CRITICAL_HIT_AMBUSH_MULTIPLIER, GOLD_MULTIPLIER, GOLD_REWARD_DIVISOR, MAX_SPECIAL2,
        MAX_SPECIAL3
    }
};

use combat::{
    constants::{CombatSettings, CombatEnums::{Type, Tier, Slot}},
    combat::{ICombat, ImplCombat, CombatSpec, SpecialPowers, CombatResult}
};

#[derive(Drop, Copy, Serde)]
struct Beast {
    id: u8, // beast id 1 - 75
    starting_health: u16, // health of the beast (stored on adventurer)
    combat_spec: CombatSpec, // Combat Spec
}

#[generate_trait]
impl ImplBeast of IBeast {
    /// @notice gets the starter beast
    /// @param starter_weapon_type: the type of weapon the adventurer starts with
    /// @param seed: the random seed
    /// @return: a beast that is weak against the weapon type
    fn get_starter_beast(starter_weapon_type: Type, seed: u32) -> Beast {
        let mut beast_id: u8 = Gnome;

        match starter_weapon_type {
            Type::None(()) => { panic_with_felt252('weapon cannot be None'); },
            Type::Magic_or_Cloth(()) => { beast_id = (seed % 5).try_into().unwrap() + Troll; },
            Type::Blade_or_Hide(()) => { beast_id = (seed % 5).try_into().unwrap() + Fairy; },
            Type::Bludgeon_or_Metal(()) => { beast_id = (seed % 5).try_into().unwrap() + Bear; },
            Type::Necklace(()) => { panic_with_felt252('weapon cannot be necklace'); },
            Type::Ring(()) => { panic_with_felt252('weapon cannot be ring'); },
        }

        Beast {
            id: beast_id,
            starting_health: STARTER_BEAST_HEALTH.into(),
            combat_spec: CombatSpec {
                tier: ImplBeast::get_tier(beast_id),
                item_type: ImplBeast::get_type(beast_id),
                level: 1,
                specials: SpecialPowers { special1: 0, special2: 0, special3: 0 }
            }
        }
    }

    /// @notice gets the beast id
    /// @param seed: the random seed
    /// @return: the beast id
    #[inline(always)]
    fn get_beast_id(seed: u32) -> u8 {
        ((seed % MAX_ID.into()) + 1).try_into().unwrap()
    }

    /// @notice gets the starting health of the beast
    /// @param adventurer_level: the level of the adventurer
    /// @param rnd: the random value used to generate the random number
    /// @return: the starting health of the beast
    fn get_starting_health(adventurer_level: u8, rnd: u16) -> u16 {
        let beast_health = ImplCombat::get_random_starting_health(adventurer_level, rnd);
        if beast_health > MAXIMUM_HEALTH {
            MAXIMUM_HEALTH
        } else {
            beast_health
        }
    }

    /// @notice gets the specials for the beast
    /// @param special2_seed: the random seed for the second special
    /// @param special3_seed: the random seed for the third special
    /// @return: the specials for the beast
    fn get_specials(special2_seed: u8, special3_seed: u8) -> SpecialPowers {
        SpecialPowers {
            special1: 0,
            special2: 1 + (special2_seed % MAX_SPECIAL2),
            special3: 1 + (special3_seed % MAX_SPECIAL3)
        }
    }

    /// @notice gets the level of the beast
    /// @param adventurer_level: the level of the adventurer
    /// @param rnd: the random value used to generate the random number
    /// @return: the level of the beast
    fn get_level(adventurer_level: u8, rnd: u16) -> u16 {
        ImplCombat::get_random_level(adventurer_level, rnd)
    }

    /// @notice attempts to flee from the beast
    /// @param adventurer_level: the level of the adventurer
    /// @param adventurer_dexterity: the dexterity of the adventurer
    /// @param rnd: the random value used to generate the random number
    /// @return: true if the adventurer avoided the ambush, false otherwise
    fn attempt_flee(adventurer_level: u8, adventurer_dexterity: u8, rnd: u8) -> bool {
        ImplCombat::ability_based_avoid_threat(adventurer_level, adventurer_dexterity, rnd)
    }

    /// @notice gets the xp reward for defeating a beast
    /// @param self: the beast being defeated
    /// @param adventurer_level: the level of the adventurer
    /// @return: the xp reward for defeating the beast
    fn get_xp_reward(self: Beast, adventurer_level: u8) -> u16 {
        let xp_reward = self.combat_spec.get_base_reward(adventurer_level);
        if (xp_reward < MINIMUM_XP_REWARD) {
            MINIMUM_XP_REWARD
        } else {
            xp_reward
        }
    }

    /// @notice gets the gold reward for defeating a beast
    /// @param self: the beast being defeated
    /// @return: the gold reward for defeating the beast
    fn get_gold_reward(self: Beast) -> u16 {
        match self.combat_spec.tier {
            Tier::None(()) => { panic_with_felt252('Beast tier is None') },
            Tier::T1(()) => {
                (GOLD_MULTIPLIER::T1.into() * self.combat_spec.level) / GOLD_REWARD_DIVISOR.into()
            },
            Tier::T2(()) => {
                (GOLD_MULTIPLIER::T2.into() * self.combat_spec.level) / GOLD_REWARD_DIVISOR.into()
            },
            Tier::T3(()) => {
                (GOLD_MULTIPLIER::T3.into() * self.combat_spec.level) / GOLD_REWARD_DIVISOR.into()
            },
            Tier::T4(()) => {
                (GOLD_MULTIPLIER::T4.into() * self.combat_spec.level) / GOLD_REWARD_DIVISOR.into()
            },
            Tier::T5(()) => {
                (GOLD_MULTIPLIER::T5.into() * self.combat_spec.level) / GOLD_REWARD_DIVISOR.into()
            }
        }
    }

    /// @notice gets the type of a beast
    /// @param id: the id of the beast
    /// @return: the type of the beast
    fn get_type(id: u8) -> Type {
        if (id >= 0 && id < 26) {
            Type::Magic_or_Cloth
        } else if id < 51 {
            Type::Blade_or_Hide
        } else if id < 76 {
            Type::Bludgeon_or_Metal
        } else {
            Type::None
        }
    }

    /// @notice gets the tier of a beast
    /// @param id: the id of the beast
    /// @return: the tier of the beast
    fn get_tier(id: u8) -> Tier {
        if ImplBeast::is_t1(id) {
            Tier::T1
        } else if ImplBeast::is_t2(id) {
            Tier::T2
        } else if ImplBeast::is_t3(id) {
            Tier::T3
        } else if ImplBeast::is_t4(id) {
            Tier::T4
        } else {
            Tier::T5
        }
    }

    /// @notice gets the critical hit chance for a beast
    /// @param adventurer_level: the level of the adventurer
    /// @param is_ambush: whether the beast is being ambushed
    /// @return: the critical hit chance for the beast
    fn get_critical_hit_chance(adventurer_level: u8, is_ambush: bool) -> u8 {
        let mut chance: u16 = 0;

        // critical hit chance is higher on ambush
        if is_ambush {
            chance = adventurer_level.into() * CRITICAL_HIT_AMBUSH_MULTIPLIER.into();
        } else {
            chance = adventurer_level.into() * CRITICAL_HIT_LEVEL_MULTIPLIER.into();
        }

        // cap chance at 100%
        if chance > 100 {
            100
        } else {
            chance.try_into().unwrap()
        }
    }

    /// @notice checks if a beast is T1
    /// @param id: the id of the beast
    /// @return: true if the beast is T1, false otherwise
    #[inline(always)]
    fn is_t1(id: u8) -> bool {
        (id >= 1 && id <= 5) || (id >= 26 && id < 31) || (id >= 51 && id < 56)
    }

    /// @notice checks if a beast is T2
    /// @param id: the id of the beast
    /// @return: true if the beast is T2, false otherwise
    #[inline(always)]
    fn is_t2(id: u8) -> bool {
        (id >= 6 && id < 11) || (id >= 31 && id < 36) || (id >= 56 && id < 61)
    }

    /// @notice checks if a beast is T3
    /// @param id: the id of the beast
    /// @return: true if the beast is T3, false otherwise
    #[inline(always)]
    fn is_t3(id: u8) -> bool {
        (id >= 11 && id < 16) || (id >= 36 && id < 41) || (id >= 61 && id < 66)
    }

    /// @notice checks if a beast is T4
    /// @param id: the id of the beast
    /// @return: true if the beast is T4, false otherwise
    #[inline(always)]
    fn is_t4(id: u8) -> bool {
        (id >= 16 && id < 21) || (id >= 41 && id < 46) || (id >= 66 && id < 71)
    }
}

// ---------------------------
// ---------- Tests ----------
// ---------------------------
#[cfg(test)]
mod tests {
    use debug::PrintTrait;
    use core::serde::Serde;
    use traits::{TryInto, Into};
    use option::OptionTrait;
    use beasts::{
        beast::{ImplBeast, IBeast, Beast},
        constants::{
            BeastId::{
                Warlock, Typhon, Jiangshi, Anansi, Basilisk, Gorgon, Kitsune, Lich, Chimera,
                Wendigo, Rakshasa, Werewolf, Banshee, Draugr, Vampire, Goblin, Ghoul, Wraith,
                Sprite, Kappa, Fairy, Leprechaun, Kelpie, Pixie, Gnome, Griffin, Manticore, Phoenix,
                Dragon, Minotaur, Qilin, Ammit, Nue, Skinwalker, Chupacabra, Weretiger, Wyvern, Roc,
                Harpy, Pegasus, Hippogriff, Fenrir, Jaguar, Satori, DireWolf, Bear, Wolf, Mantis,
                Spider, Rat, Kraken, Colossus, Balrog, Leviathan, Tarrasque, Titan, Nephilim,
                Behemoth, Hydra, Juggernaut, Oni, Jotunn, Ettin, Cyclops, Giant, NemeanLion,
                Berserker, Yeti, Golem, Ent, Troll, Bigfoot, Ogre, Orc, Skeleton, MAX_ID,
            },
            BeastSettings::{
                STARTER_BEAST_HEALTH, MINIMUM_XP_REWARD, MAXIMUM_HEALTH,
                CRITICAL_HIT_LEVEL_MULTIPLIER, CRITICAL_HIT_AMBUSH_MULTIPLIER
            }
        }
    };

    use combat::{
        constants::{CombatSettings, CombatEnums::{Type, Tier, Slot}},
        combat::{ICombat, ImplCombat, CombatSpec, SpecialPowers}
    };

    #[test]
    #[available_gas(21800)]
    fn test_get_tier_gas() {
        ImplBeast::get_tier(MAX_ID);
    }

    #[test]
    #[available_gas(70000)]
    fn test_get_tier_unknown_id() {
        assert(ImplBeast::get_tier(MAX_ID + 1) == Tier::T5(()), 'unknown id gets T5');
    }

    #[test]
    #[available_gas(70000)]
    fn test_get_tier_max_value() {
        assert(ImplBeast::get_tier(255) == Tier::T5(()), 'should be unknown / T5');
    }

    #[test]
    #[available_gas(400000)]
    fn test_get_tier() {
        let warlock = Warlock;
        let warlock_tier = ImplBeast::get_tier(warlock);
        assert(warlock_tier == Tier::T1(()), 'Warlock should be T1');

        let juggernaut = Juggernaut;
        let juggernaut_tier = ImplBeast::get_tier(juggernaut);
        assert(juggernaut_tier == Tier::T2(()), 'Juggernaut should be T2');

        let pegasus = Pegasus;
        let pegasus_tier = ImplBeast::get_tier(pegasus);
        assert(pegasus_tier == Tier::T3(()), 'Pegasus should be T3');

        let goblin = Goblin;
        let goblin_tier = ImplBeast::get_tier(goblin);
        assert(goblin_tier == Tier::T4(()), 'Goblin should be T4');

        let bear = Bear;
        let bear_tier = ImplBeast::get_tier(bear);
        assert(bear_tier == Tier::T5(()), 'Bear should be T5');
    }

    #[test]
    #[available_gas(2980)]
    fn test_get_type_gas() {
        ImplBeast::get_type(MAX_ID);
    }

    #[test]
    #[available_gas(7750)]
    fn test_get_type_invalid_id() {
        assert(ImplBeast::get_type(MAX_ID + 1) == Type::None(()), 'unknown id is Type None');
    }

    #[test]
    #[available_gas(7750)]
    fn test_get_type_zero() {
        assert(ImplBeast::get_type(MAX_ID + 1) == Type::None(()), 'zero is unknown / Type None');
    }

    #[test]
    #[available_gas(4880)]
    fn test_get_type_max_value() {
        assert(ImplBeast::get_type(255) == Type::None(()), 'max is unknown / Type None');
    }

    #[test]
    #[available_gas(21600)]
    fn test_get_type() {
        let warlock_type = ImplBeast::get_type(Warlock);
        assert(warlock_type == Type::Magic_or_Cloth(()), 'Warlock is magical');

        let juggernaut_type = ImplBeast::get_type(Juggernaut);
        assert(juggernaut_type == Type::Bludgeon_or_Metal(()), 'Juggernaut is a brute ');

        let pegasus_type = ImplBeast::get_type(Pegasus);
        assert(pegasus_type == Type::Blade_or_Hide(()), 'Pegasus is a hunter');

        let goblin_type = ImplBeast::get_type(Goblin);
        assert(goblin_type == Type::Magic_or_Cloth(()), 'Goblin is magical');

        let bear_type = ImplBeast::get_type(Bear);
        assert(bear_type == Type::Blade_or_Hide(()), 'Bear is a hunter');
    }

    #[test]
    #[available_gas(500000)]
    fn test_get_level() {
        let mut adventurer_level = 1;

        // at level 1, we'll get a beast with level 1 or 2
        assert(ImplBeast::get_level(adventurer_level, 0) == 1, 'lvl should eql advr lvl');
        assert(ImplBeast::get_level(adventurer_level, 1) == 2, 'lvl should eql advr lvl');
        assert(ImplBeast::get_level(adventurer_level, 2) == 3, 'lvl should eql advr lvl');
        assert(ImplBeast::get_level(adventurer_level, 3) == 1, 'lvl should eql advr lvl');

        // advance adventurer to level 4
        adventurer_level = 4;
        assert(ImplBeast::get_level(adventurer_level, 0) == 1, 'beast lvl should be 1');
        assert(ImplBeast::get_level(adventurer_level, 1) == 2, 'beast lvl should be 2');
        assert(ImplBeast::get_level(adventurer_level, 2) == 3, 'beast lvl should be 3');
        assert(ImplBeast::get_level(adventurer_level, 3) == 4, 'beast lvl should be 4');
        assert(ImplBeast::get_level(adventurer_level, 4) == 5, 'beast lvl should be 5');
        assert(ImplBeast::get_level(adventurer_level, 5) == 6, 'beast lvl should be 6');
        assert(ImplBeast::get_level(adventurer_level, 6) == 7, 'beast lvl should be 7');
        assert(ImplBeast::get_level(adventurer_level, 7) == 8, 'beast lvl should be 8');
        assert(ImplBeast::get_level(adventurer_level, 8) == 9, 'beast lvl should be 9');
        assert(ImplBeast::get_level(adventurer_level, 9) == 10, 'beast lvl should be 10');
        assert(ImplBeast::get_level(adventurer_level, 10) == 11, 'beast lvl should be 11');
        assert(ImplBeast::get_level(adventurer_level, 11) == 12, 'beast lvl should be 12');

        // verify we rollover back to 1 for our lvl4 adventurer
        assert(ImplBeast::get_level(adventurer_level, 12) == 1, 'beast lvl should be 1');
    }

    #[test]
    #[available_gas(200000)]
    fn test_get_starting_health() {
        let adventurer_level = 1;

        // test level 1 adventurer
        assert(
            ImplBeast::get_starting_health(adventurer_level, 0) == 11, 'minimum beast health is 11'
        );

        // test with adventurer at 4x difficulty cliff
        // entropy 0 gives us minimum beast health
        let adventurer_level = 12;
        assert(
            ImplBeast::get_starting_health(adventurer_level, 0) == 11, 'beast health should be 11'
        );

        // test upper end up beast health at 4x difficulty cliff
        assert(
            ImplBeast::get_starting_health(adventurer_level, 74) == 85, 'beast health should be 85'
        );

        // test extremes
        let adventurer_level = 255; // max u8
        assert(
            ImplBeast::get_starting_health(adventurer_level, 1022) == MAXIMUM_HEALTH,
            'beast health should be max'
        );
    }

    #[test]
    #[available_gas(50000)]
    fn test_get_beast_id() {
        let zero_check = 0;
        let beast_id = ImplBeast::get_beast_id(zero_check);
        assert(beast_id != 0, 'beast should not be zero');
        assert(beast_id <= MAX_ID, 'beast higher than max beastid');

        let max_beast_id = MAX_ID.into();
        let beast_id = ImplBeast::get_beast_id(max_beast_id);
        assert(beast_id != 0, 'beast should not be zero');
        assert(beast_id <= MAX_ID, 'beast higher than max beastid');

        let _above_max_beast_id = MAX_ID + 1;
        let beast_id = ImplBeast::get_beast_id(max_beast_id);
        assert(beast_id != 0, 'beast should not be zero');
        assert(beast_id <= MAX_ID, 'beast higher than max beastid');
    }

    #[test]
    #[available_gas(3980)]
    fn test_get_gold_reward_gas() {
        let beast = Beast {
            id: 1,
            starting_health: 100,
            combat_spec: CombatSpec {
                tier: Tier::T1(()),
                item_type: Type::Magic_or_Cloth(()),
                level: 10,
                specials: SpecialPowers { special1: 3, special2: 1, special3: 2 },
            },
        };

        beast.get_gold_reward();
    }

    #[test]
    fn test_get_gold_reward() {
        let mut beast = Beast {
            id: 1,
            starting_health: 100,
            combat_spec: CombatSpec {
                tier: Tier::T1(()),
                item_type: Type::Magic_or_Cloth(()),
                level: 1,
                specials: SpecialPowers { special1: 3, special2: 1, special3: 2 },
            },
        };
        let gold_reward = beast.get_gold_reward();
        assert(gold_reward == 2, 'gold reward should be 2');

        // increase beast to level 10
        beast.combat_spec.level = 10;
        let gold_reward = beast.get_gold_reward();
        assert(gold_reward == 25, 'gold reward should be 25');

        // increase beast to level 15
        beast.combat_spec.level = 15;
        let gold_reward = beast.get_gold_reward();
        assert(gold_reward == 37, 'gold reward should be 37');

        // increase beast to level 20
        beast.combat_spec.level = 20;
        let gold_reward = beast.get_gold_reward();
        assert(gold_reward == 50, 'gold reward should be 50');
    }

    #[test]
    #[available_gas(3510)]
    fn test_get_critical_hit_chance_gas() {
        ImplBeast::get_critical_hit_chance(10, false);
    }

    #[test]
    fn test_get_critical_hit_chance_no_ambush() {
        let adventurer_level = 10;
        let is_ambush = false;
        let chance = ImplBeast::get_critical_hit_chance(adventurer_level, is_ambush);
        assert(
            chance == (adventurer_level.into() * CRITICAL_HIT_LEVEL_MULTIPLIER).try_into().unwrap(),
            'crit hit chance no ambush'
        );
    }

    #[test]
    fn test_get_critical_hit_chance_with_ambush() {
        let adventurer_level = 10;
        let is_ambush = true;
        let chance = ImplBeast::get_critical_hit_chance(adventurer_level, is_ambush);
        assert(
            chance == (adventurer_level.into() * CRITICAL_HIT_AMBUSH_MULTIPLIER)
                .try_into()
                .unwrap(),
            'crit hit chance for ambush'
        );
    }

    #[test]
    fn test_get_critical_hit_chance_cap() {
        let adventurer_level = 105;
        let is_ambush = true;
        let chance = ImplBeast::get_critical_hit_chance(adventurer_level, is_ambush);
        assert(chance == 100, 'crit hit exceeded 100');
    }

    #[test]
    fn test_get_critical_hit_chance_no_ambush_cap() {
        let adventurer_level = 105;
        let is_ambush = false;
        let chance = ImplBeast::get_critical_hit_chance(adventurer_level, is_ambush);
        assert(chance == 100, 'crit hit ambush exceeded 100');
    }

    #[test]
    fn test_get_critical_hit_chance_mul_overflow() {
        let adventurer_level = 255;
        let is_ambush = false;
        let chance = ImplBeast::get_critical_hit_chance(adventurer_level, is_ambush);
        assert(chance == 100, 'crit hit ambush exceeded 100');
    }

    #[test]
    #[available_gas(5360)]
    fn test_get_specials_gas() {
        ImplBeast::get_specials(1, 2);
    }
}
