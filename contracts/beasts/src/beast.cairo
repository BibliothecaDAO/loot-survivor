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
        STARTER_BEAST_HEALTH, MINIMUM_HEALTH, BEAST_SPECIAL_NAME_UNLOCK_LEVEL, MINIMUM_DAMAGE,
        STRENGTH_BONUS, MINIMUM_XP_REWARD, GOLD_REWARD_BASE_MINIMUM, GOLD_BASE_REWARD_DIVISOR,
        GOLD_REWARD_BONUS_DIVISOR, GOLD_REWARD_BONUS_MAX_MULTPLIER, STARTER_BEAST_LEVEL_THRESHOLD,
        MAXIMUM_HEALTH
    }
};

use combat::{
    constants::{CombatSettings, CombatEnums::{Type, Tier, Slot}},
    combat::{ICombat, ImplCombat, CombatSpec, SpecialPowers, CombatResult}
};

// TODO: Consider prepopulating a map for Beast ID -> {Type, Tier} to speed up this lookup
#[derive(Drop, Copy, Serde)] // 24 bits
struct Beast {
    id: u8, // beast id 1 - 75
    starting_health: u16, // health of the beast (stored on adventurer)
    combat_spec: CombatSpec, // Combat Spec
}

#[generate_trait]
impl ImplBeast of IBeast {
    // get_starter_beast returns a beast intended for the first battle of the game
    // the beast is chosen based on the type of weapon the adventurer starts with
    // the beast is chosen to be weak against the weapon type
    // @param starter_weapon_type: the type of weapon the adventurer starts with
    // @return: a beast that is weak against the weapon type
    fn get_starter_beast(starter_weapon_type: Type, entropy: u128) -> Beast {
        let mut beast_id: u8 = Gnome;

        match starter_weapon_type {
            Type::None(()) => beast_id = Troll,
            // if adventurer starts with a magical weapon, they start against T5 brute
            Type::Magic_or_Cloth(()) => {
                let rnd_brute: u8 = (entropy % 5).try_into().unwrap() + Troll;
                beast_id = rnd_brute
            },
            // if the adventurer starts with a bladed weapon, they start against T5 magical
            Type::Blade_or_Hide(()) => {
                let rnd_magical: u8 = (entropy % 5).try_into().unwrap() + Fairy;
                beast_id = rnd_magical
            },
            // if the adventurer starts with a bludgeon weapon, they start against T5 hunter
            Type::Bludgeon_or_Metal(()) => {
                let rnd_hunter: u8 = (entropy % 5).try_into().unwrap() + Bear;
                beast_id = rnd_hunter
            },
            // starter weapon should never be a necklace or ring
            // but cairo needs us to define all cases so just default to troll
            Type::Necklace(()) => beast_id = Troll,
            Type::Ring(()) => beast_id = Troll,
        }

        Beast {
            id: beast_id,
            starting_health: STARTER_BEAST_HEALTH,
            combat_spec: CombatSpec {
                tier: ImplBeast::get_tier(beast_id),
                item_type: ImplBeast::get_type(beast_id),
                level: 1,
                specials: SpecialPowers { special1: 0, special2: 0, special3: 0 }
            }
        }
    }

    fn get_beast_id(seed: u128) -> u8 {
        // get a beast id between 1 and max beast id (inclusive)
        // we specify "seed" as the input instead of "entropy" because
        // we want to advertise that this function is intended
        // to be used to generate deterministic beasts.
        // The value of this is an adventurer can battle
        // the same beast across multiple contract calls
        // without having to pay for gas to store the beast
        let beast_id = (seed % MAX_ID.into()) + 1;

        // return beast id as a u8
        beast_id.try_into().unwrap()
    }


    fn get_starting_health(adventurer_level: u8, entropy: u128,) -> u16 {
        // Delete this function to combat system but pass in difficulty parameters
        // which control when and how quickly beasts health increases
        let beast_health = ImplCombat::get_enemy_starting_health(adventurer_level, entropy);

        // if the beast health provdied by combat library
        // is higher than the max allowed for a beast
        if beast_health > MAXIMUM_HEALTH {
            // return max
            MAXIMUM_HEALTH
        } else {
            // else return health from combat lib
            beast_health
        }
    }

    fn get_special_names(seed: u128, special2_size: u128, special3_size: u128) -> SpecialPowers {
        SpecialPowers {
            special1: 0,
            special2: (1 + (seed % special2_size)).try_into().unwrap(),
            special3: (1 + (seed % special3_size)).try_into().unwrap()
        }
    }
    fn get_level(adventurer_level: u8, seed: u128) -> u16 {
        // Delegate level generation to combat system but pass in difficulty parameters
        // which control when and how quickly beasts level increases
        // For the purposes of beasts, we pass in a seed instead of entropy which will
        // result in deterministic beasts
        ImplCombat::get_random_level(adventurer_level, seed)
    }

    // attempt_flee is used to determine if an adventurer is able to flee from a beast
    // @param adventurer_level: the level of the adventurer
    // @param adventurer_dexterity: the dexterity of the adventurer
    // @param entropy: the entropy used to generate the random number
    // @return: true if the adventurer avoided the ambush, false otherwise
    fn attempt_flee(adventurer_level: u8, adventurer_dexterity: u8, entropy: u128) -> bool {
        // Delegate ambushed calculation to combat system
        // avoiding beast ambush requires wisdom
        ImplCombat::ability_based_avoid_threat(adventurer_level, adventurer_dexterity, entropy)
    }

    // get_xp_reward is used to determine the xp reward for defeating a beast
    // @param beast: the beast being defeated
    // @return: the xp reward for defeating the beast
    fn get_xp_reward(self: Beast) -> u16 {
        let xp_reward = self.combat_spec.get_base_reward();
        if (xp_reward < MINIMUM_XP_REWARD) {
            MINIMUM_XP_REWARD
        } else {
            xp_reward
        }
    }

    fn get_gold_reward(self: Beast, entropy: u128) -> u16 {
        // base for the gold reward is XP which uses beast tier and level
        let mut base_reward = self.combat_spec.get_base_reward() / GOLD_BASE_REWARD_DIVISOR;
        if (base_reward < GOLD_REWARD_BASE_MINIMUM) {
            base_reward = GOLD_REWARD_BASE_MINIMUM;
        }

        // gold bonus will be based on 25% increments
        let bonus_base = base_reward / GOLD_REWARD_BONUS_DIVISOR;

        // multiplier will be 0-4 inclusive, providing a bonus range of (25%, 50%, 75%, 100%)
        let bonus_multiplier = (entropy % (1 + GOLD_REWARD_BONUS_MAX_MULTPLIER))
            .try_into()
            .unwrap();

        // return base reward + bonus
        base_reward + (bonus_base * bonus_multiplier)
    }

    // @notice gets the type of a beast
    // @param id: the id of the beast
    // @return: the type of the beast
    fn get_type(id: u8) -> Type {
        if (id >= 0 && id < 26) {
            return Type::Magic_or_Cloth(());
        } else if id < 51 {
            return Type::Blade_or_Hide(());
        } else if id < 76 {
            return Type::Bludgeon_or_Metal(());
        } else {
            return Type::None(());
        }
    }

    // @notice gets the tier of a beast
    // @param id: the id of the beast
    // @return: the tier of the beast
    fn get_tier(id: u8) -> Tier {
        if ImplBeast::is_t1(id) {
            return Tier::T1(());
        } else if ImplBeast::is_t2(id) {
            return Tier::T2(());
        } else if ImplBeast::is_t3(id) {
            return Tier::T3(());
        } else if ImplBeast::is_t4(id) {
            return Tier::T4(());
        } else {
            return Tier::T5(());
        }
    }

    #[inline(always)]
    fn is_t1(id: u8) -> bool {
        (id >= 1 && id <= 5) || (id >= 26 && id < 31) || (id >= 51 && id < 56)
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
                STARTER_BEAST_HEALTH, MINIMUM_HEALTH, BEAST_SPECIAL_NAME_UNLOCK_LEVEL,
                MINIMUM_DAMAGE, STRENGTH_BONUS, MINIMUM_XP_REWARD, GOLD_REWARD_BASE_MINIMUM,
                GOLD_BASE_REWARD_DIVISOR, GOLD_REWARD_BONUS_DIVISOR,
                GOLD_REWARD_BONUS_MAX_MULTPLIER, STARTER_BEAST_LEVEL_THRESHOLD, MAXIMUM_HEALTH
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
        assert(ImplBeast::get_level(adventurer_level, 2) == 1, 'lvl should eql advr lvl');
        assert(ImplBeast::get_level(adventurer_level, 3) == 2, 'lvl should eql advr lvl');

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
        // verify we rollover back to 1 for our lvl4 adventurer
        assert(ImplBeast::get_level(adventurer_level, 8) == 1, 'beast lvl should be 1');
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
        let adventurer_level = CombatSettings::DIFFICULTY_INCREASE_RATE::NORMAL * 4;
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
            ImplBeast::get_starting_health(
                adventurer_level, 340282366920938463463374607431768211455
            ) == MAXIMUM_HEALTH,
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

        let above_max_beast_id = MAX_ID + 1;
        let beast_id = ImplBeast::get_beast_id(max_beast_id);
        assert(beast_id != 0, 'beast should not be zero');
        assert(beast_id <= MAX_ID, 'beast higher than max beastid');
    }

    #[test]
    #[available_gas(250000)]
    fn test_get_gold_reward() {
        let mut beast = Beast {
            id: 1,
            starting_health: 100,
            combat_spec: CombatSpec {
                tier: Tier::T1(()),
                item_type: Type::Magic_or_Cloth(()),
                level: 10,
                specials: SpecialPowers { special1: 3, special2: 1, special3: 2 },
            },
        };

        // T1, LVL10 beast will produce a base reward of 50
        // We will divide this by GOLD_BASE_REWARD_DIVISOR which is currently 2
        // to create a base reward of 25. We'll then calculate a gold bonus
        // based on GOLD_REWARD_BONUS_DIVISOR and GOLD_REWARD_BONUS_MAX_MULTPLIER
        // with the current settings, there will be 10 discrete gold bonuses
        // 0%, 10%, 20%, ..., 100%
        // with entropy 0 we hit the 0% bonus case so reward should be 25
        let mut entropy: u128 = 0;
        let gold_reward = beast.get_gold_reward(entropy);
        assert(gold_reward == 12, 'gold reward should be 12');

        // increasing entropy to 1 should produce ~10% bonus
        entropy = 1;
        let gold_reward = beast.get_gold_reward(entropy);
        assert(gold_reward == 15, 'gold reward should be 15');

        // increasing entropy to 2 should produce ~20% bonus from base
        entropy = 2;
        let gold_reward = beast.get_gold_reward(entropy);
        assert(gold_reward == 18, 'gold reward should be 18');

        // increasing entropy to 3 produces maximum bonus with current settings
        // which will be ~100% of the base
        entropy = 3;
        let gold_reward = beast.get_gold_reward(entropy);
        assert(gold_reward == 21, 'gold reward should be 21');

        // if we double the beast level, we approximately double the reward
        beast.combat_spec.level = 20;
        let gold_reward = beast.get_gold_reward(entropy);
        assert(gold_reward == 43, 'lvl 20 max gold reward is 43');

        // dropping beast from T1 to T5, significantly drops the gold reward
        beast.combat_spec.tier = Tier::T5(());
        let gold_reward = beast.get_gold_reward(entropy);
        assert(gold_reward == 8, 'lvl20 t5 max gold reward is 8');
    }
}
