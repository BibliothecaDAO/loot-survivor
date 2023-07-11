use core::serde::Serde;
use integer::{
    U128IntoFelt252, Felt252IntoU256, Felt252TryIntoU64, U256TryIntoFelt252, u256_from_felt252,
    U8IntoU16, U8IntoU64, U64TryIntoU8, U128TryIntoU8, U8IntoU128, U128TryIntoU16,
};
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
        Skeleton, MAX_ID
    },
    BeastSettings::{
        STARTER_BEAST_HEALTH, MINIMUM_HEALTH, BEAST_SPECIAL_NAME_UNLOCK_LEVEL, MINIMUM_DAMAGE,
        STRENGTH_BONUS, MINIMUM_XP_REWARD, GOLD_REWARD_BASE_MINIMUM, GOLD_BASE_REWARD_DIVISOR,
        GOLD_REWARD_BONUS_DIVISOR, GOLD_REWARD_BONUS_MAX_MULTPLIER, STARTER_BEAST_LEVEL_THRESHOLD
    }
};

use combat::{
    constants::{CombatSettings, CombatEnums::{Type, Tier, Slot}},
    combat::{ICombat, ImplCombat, CombatSpec, SpecialPowers}
};

#[derive(Drop, Copy, Serde)] // 24 bits
struct Beast {
    id: u8, // beast id 1 - 75
    starting_health: u16, // health of the beast (stored on adventurer)
    combat_spec: CombatSpec, // Combat Spec
}

#[generate_trait]
impl ImplBeast of IBeast {
    //@notice This function generates a Beast instance based on the given adventurer's level, their special powers, a seed for randomness, and their weapon type.
    //@dev If the adventurer's level exceeds the STARTER_BEAST_LEVEL_THRESHOLD, the beast is generated with attributes (id, starting_health, combat_spec) based on the adventurer's level and the provided seed. 
    //Otherwise, a starter beast is generated according to the adventurer's weapon type.
    //@param adventurer_level The level of the adventurer, represented as a u8 (unsigned 8-bit integer). 
    //@param special_names A SpecialPowers type value indicating the adventurer's special powers.
    //@param seed A u128 (unsigned 128-bit integer) value used to generate randomness in the Beast's attributes.
    //@param weapon_type A Type value indicating the type of weapon that the adventurer uses.
    //@return A Beast instance with either generated attributes or the default starter attributes, based on the adventurer's level.
    fn get_beast(
        adventurer_level: u8, special_names: SpecialPowers, seed: u128, weapon_type: Type
    ) -> Beast {
        // if the adventurer has passed the starter beast level threshold
        if (adventurer_level > STARTER_BEAST_LEVEL_THRESHOLD) {
            // generate a beast based on the provided seed
            let beast_id = ImplBeast::get_beast_id(seed);
            Beast {
                id: beast_id,
                starting_health: ImplBeast::get_starting_health(adventurer_level, seed),
                combat_spec: CombatSpec {
                    tier: ImplBeast::get_tier(beast_id),
                    item_type: ImplBeast::get_type(beast_id),
                    level: U8IntoU16::into(ImplBeast::get_level(adventurer_level, seed)),
                    special_powers: special_names
                }
            }
        } else {
            // if the adventurer has not passed the starter beast level threshold
            // generate a starter beast
            ImplBeast::get_starter_beast(weapon_type)
        }
    }

    // get_starter_beast returns a beast intended for the first battle of the game
    // the beast is chosen based on the type of weapon the adventurer starts with
    // the beast is chosen to be weak against the weapon type
    // @param starter_weapon_type: the type of weapon the adventurer starts with
    // @return: a beast that is weak against the weapon type
    fn get_starter_beast(starter_weapon_type: Type) -> Beast {
        let mut beast_id: u8 = Gnome;

        match starter_weapon_type {
            // if adventurer starts with a magical weapon, they face a troll as their first beast
            Type::Magic_or_Cloth(()) => beast_id = Troll,
            // if the adventurer starts with a blade or hide weapon, they face a rat as their first beast
            Type::Blade_or_Hide(()) => beast_id = Gnome,
            // if the adventurer starts with a bludgeon or metal weapon, they face a troll as their first beast
            Type::Bludgeon_or_Metal(()) => beast_id = Rat,
            // starter weapon should never be a necklace or ring
            // but cairo needs us to define all cases so just default to troll
            Type::Necklace(()) => beast_id = Troll,
            Type::Ring(()) => beast_id = Troll,
        }

        return Beast {
            id: beast_id, starting_health: STARTER_BEAST_HEALTH, combat_spec: CombatSpec {
                tier: ImplBeast::get_tier(beast_id),
                item_type: ImplBeast::get_type(beast_id),
                level: 1,
                special_powers: SpecialPowers {
                    prefix1: 0, prefix2: 0, suffix: 0
                }
            }
        };
    }

    fn beast_encounter(
        adventurer_level: u8,
        adventurer_wisdom: u8,
        special1_size: u8,
        special2_size: u8,
        battle_fixed_seed: u128
    ) -> (Beast, bool) {
        // assign special powers to the beast
        let special1 = U128TryIntoU8::try_into(battle_fixed_seed % U8IntoU128::into(special1_size))
            .unwrap();
        let special2 = U128TryIntoU8::try_into(battle_fixed_seed % U8IntoU128::into(special2_size))
            .unwrap();
        let special3 = 0; // unused for now

        let special_powers = SpecialPowers {
            prefix1: special1, prefix2: special2, suffix: special3
        };

        // generate a beast based on the seed
        // @dev: since we don't have default values for func parameters in cairo
        //       we need to pass in a dummy value for the unused type param
        let unused_type_param = Type::Ring(());
        let beast = ImplBeast::get_beast(
            adventurer_level, special_powers, battle_fixed_seed, unused_type_param
        );

        // check if beast ambushed adventurer
        let ambushed_adventurer = ImplBeast::ambush(
            adventurer_level, adventurer_wisdom, battle_fixed_seed
        );

        // return beast and whether or not the adventurer was ambushed
        return (beast, ambushed_adventurer);
    }

    fn get_beast_id(seed: u128) -> u8 {
        // get a beast id between 1 and max beast id (inclusive)
        // we specify "seed" as the input instead of "entropy" because
        // we want to advertise that this function is intended
        // to be used to generate deterministic beasts.
        // The value of this is an adventurer can battle
        // the same beast across multiple contract calls
        // without having to pay for gas to store the beast
        let beast_id = (seed % MAX_ID) + 1;

        // return beast id as a u8
        return U128TryIntoU8::try_into(beast_id).unwrap();
    }


    fn get_starting_health(adventurer_level: u8, entropy: u128, ) -> u16 {
        // Delete this function to combat system but pass in difficulty parameters
        // which control when and how quickly beasts health increases
        ImplCombat::get_enemy_starting_health(
            adventurer_level,
            MINIMUM_HEALTH,
            entropy,
            CombatSettings::DIFFICULTY_CLIFF::NORMAL,
            CombatSettings::HEALTH_MULTIPLIER::NORMAL
        )
    }

    fn get_special_names(
        adventurer_level: u8, seed: u128, prefix1_size: u128, prefix2_size: u128
    ) -> SpecialPowers {
        // if adventurer is below level 10, beasts don't get any special powers
        if (adventurer_level < BEAST_SPECIAL_NAME_UNLOCK_LEVEL) {
            SpecialPowers { prefix1: 0, prefix2: 0, suffix: 0 }
        } else {
            let beast_prefix1 = U128TryIntoU8::try_into(seed % prefix1_size).unwrap();
            let beast_prefix2 = U128TryIntoU8::try_into(seed % prefix2_size).unwrap();

            // beast suffix is always 0 for now
            SpecialPowers { prefix1: beast_prefix1, prefix2: beast_prefix2, suffix: 0 }
        }
    }
    fn get_level(adventurer_level: u8, seed: u128) -> u8 {
        // Delegate level generation to combat system but pass in difficulty parameters
        // which control when and how quickly beasts level increases
        // For the purposes of beasts, we pass in a seed instead of entropy which will
        // result in deterministic beasts
        ImplCombat::get_random_level(
            adventurer_level,
            seed,
            CombatSettings::DIFFICULTY_CLIFF::NORMAL,
            CombatSettings::LEVEL_MULTIPLIER::NORMAL,
        )
    }

    // attack is used to calculate the damage dealt to a beast
    // @param adventurer_luck: the luck of the adventurer
    // @param adventurer_strength: the strength of the adventurer
    // @param weapon: the weapon of the adventurer
    // @param beast: the beast being attacked
    // @param entropy: the entropy used to generate the random number
    // @return: the damage dealt to the beast
    fn attack(
        self: Beast, weapon: CombatSpec, adventurer_luck: u8, adventurer_strength: u8, entropy: u128
    ) -> u16 {
        // check if the attack is a critical hit
        let is_critical_hit = ImplCombat::is_critical_hit(adventurer_luck, entropy);

        // delegate damage calculation to combat system
        return ImplCombat::calculate_damage(
            weapon,
            self.combat_spec,
            MINIMUM_DAMAGE,
            U8IntoU16::into(adventurer_strength),
            is_critical_hit,
            entropy
        );
    }

    // counter_attack is used to calculate the damage dealt to an adventurer when a beast counter attacks
    // @param beast: the beast counter attacking
    // @param armor: the armor of the adventurer
    // @param entropy: the entropy used to generate the random number
    // @return: the damage dealt to the adventurer
    fn counter_attack(self: Beast, armor: CombatSpec, entropy: u128) -> u16 {
        // beast have a fixed 1/6 chance of critical hit
        let is_critical_hit = (entropy % 6) == 0;

        // delegate damage calculation to combat system
        return ImplCombat::calculate_damage(
            self.combat_spec, armor, MINIMUM_DAMAGE, STRENGTH_BONUS, is_critical_hit, entropy
        );
    }

    // ambush is used to determine if an adventurer avoided a beast ambush
    // @param adventurer_level: the level of the adventurer
    // @param adventurer_wisdom: the wisdom of the adventurer
    // @param entropy: the entropy used to generate the random number
    // @return: true if the ambush was successful, false otherwise
    fn ambush(adventurer_level: u8, adventurer_wisdom: u8, battle_fixed_entropy: u128) -> bool {
        // Delegate ambushed calculation to combat system which uses an avoidance formula
        // so we invert the result and use wisdom for the trait to avoid
        return !ImplCombat::ability_based_avoid_threat(
            adventurer_level, adventurer_wisdom, battle_fixed_entropy
        );
    }

    // attempt_flee is used to determine if an adventurer is able to flee from a beast
    // @param adventurer_level: the level of the adventurer
    // @param adventurer_dexterity: the dexterity of the adventurer
    // @param entropy: the entropy used to generate the random number
    // @return: true if the adventurer avoided the ambush, false otherwise
    fn attempt_flee(adventurer_level: u8, adventurer_dexterity: u8, entropy: u128) -> bool {
        // Delegate ambushed calculation to combat system
        // avoiding beast ambush requires wisdom
        return ImplCombat::ability_based_avoid_threat(
            adventurer_level, adventurer_dexterity, entropy
        );
    }

    // get_xp_reward is used to determine the xp reward for defeating a beast
    // @param beast: the beast being defeated
    // @return: the xp reward for defeating the beast
    fn get_xp_reward(self: Beast) -> u16 {
        let xp_reward = self.combat_spec.get_xp_reward();
        if (xp_reward < MINIMUM_XP_REWARD) {
            return MINIMUM_XP_REWARD;
        } else {
            return xp_reward;
        }
    }

    fn get_gold_reward(self: Beast, entropy: u128) -> u16 {
        // base for the gold reward is XP which uses beast tier and level
        let mut base_reward = self.combat_spec.get_xp_reward() / GOLD_BASE_REWARD_DIVISOR;
        if (base_reward < GOLD_REWARD_BASE_MINIMUM) {
            base_reward = GOLD_REWARD_BASE_MINIMUM;
        }

        // gold bonus will be based on 10% increments
        let bonus_base = base_reward / GOLD_REWARD_BONUS_DIVISOR;

        // multiplier will be 0-10 inclusive, providing
        // a maximum gold bonus of 100%
        let bonus_multiplier = U128TryIntoU16::try_into(
            entropy % (1 + GOLD_REWARD_BONUS_MAX_MULTPLIER)
        )
            .unwrap();

        // return base reward + bonus
        return base_reward + (bonus_base * bonus_multiplier);
    }

    fn get_type(id: u8) -> Type {
        if id == Warlock
            || id == Typhon
            || id == Jiangshi
            || id == Anansi
            || id == Basilisk
            || id == Gorgon
            || id == Kitsune
            || id == Lich
            || id == Chimera
            || id == Wendigo
            || id == Rakshasa
            || id == Werewolf
            || id == Banshee
            || id == Draugr
            || id == Vampire
            || id == Goblin
            || id == Ghoul
            || id == Wraith
            || id == Sprite
            || id == Kappa
            || id == Fairy
            || id == Leprechaun
            || id == Kelpie
            || id == Pixie
            || id == Gnome {
            return Type::Magic_or_Cloth(());
        } else if id == Griffin
            || id == Manticore
            || id == Phoenix
            || id == Dragon
            || id == Minotaur
            || id == Qilin
            || id == Ammit
            || id == Nue
            || id == Skinwalker
            || id == Chupacabra
            || id == Weretiger
            || id == Wyvern
            || id == Roc
            || id == Harpy
            || id == Pegasus
            || id == Hippogriff
            || id == Fenrir
            || id == Jaguar
            || id == Satori
            || id == DireWolf
            || id == Bear
            || id == Wolf
            || id == Mantis
            || id == Spider
            || id == Rat {
            return Type::Blade_or_Hide(());
        } else if id == Kraken
            || id == Colossus
            || id == Balrog
            || id == Leviathan
            || id == Tarrasque
            || id == Titan
            || id == Nephilim
            || id == Behemoth
            || id == Hydra
            || id == Juggernaut
            || id == Oni
            || id == Jotunn
            || id == Ettin
            || id == Cyclops
            || id == Giant
            || id == NemeanLion
            || id == Berserker
            || id == Yeti
            || id == Golem
            || id == Ent
            || id == Troll
            || id == Bigfoot
            || id == Ogre
            || id == Orc
            || id == Skeleton {
            return Type::Bludgeon_or_Metal(());
        }
        // unknown id gets type bludgeon/metal
        return Type::Bludgeon_or_Metal(());
    }

    fn get_tier(id: u8) -> Tier {
        if id == Warlock
            || id == Typhon
            || id == Jiangshi
            || id == Anansi
            || id == Basilisk
            || id == Griffin
            || id == Manticore
            || id == Phoenix
            || id == Dragon
            || id == Minotaur
            || id == Kraken
            || id == Colossus
            || id == Balrog
            || id == Leviathan
            || id == Tarrasque {
            return Tier::T1(());
        } else if id == Gorgon
            || id == Kitsune
            || id == Lich
            || id == Chimera
            || id == Wendigo
            || id == Qilin
            || id == Ammit
            || id == Nue
            || id == Skinwalker
            || id == Chupacabra
            || id == Titan
            || id == Nephilim
            || id == Behemoth
            || id == Hydra
            || id == Juggernaut {
            return Tier::T2(());
        } else if id == Rakshasa
            || id == Werewolf
            || id == Banshee
            || id == Draugr
            || id == Vampire
            || id == Weretiger
            || id == Wyvern
            || id == Roc
            || id == Harpy
            || id == Pegasus
            || id == Oni
            || id == Jotunn
            || id == Ettin
            || id == Cyclops
            || id == Giant {
            return Tier::T3(());
        } else if id == Goblin
            || id == Ghoul
            || id == Wraith
            || id == Sprite
            || id == Kappa
            || id == Hippogriff
            || id == Fenrir
            || id == Jaguar
            || id == Satori
            || id == DireWolf
            || id == NemeanLion
            || id == Berserker
            || id == Yeti
            || id == Golem
            || id == Ent {
            return Tier::T4(());
        } else if id == Fairy
            || id == Leprechaun
            || id == Kelpie
            || id == Pixie
            || id == Gnome
            || id == Bear
            || id == Wolf
            || id == Mantis
            || id == Spider
            || id == Rat
            || id == Troll
            || id == Bigfoot
            || id == Ogre
            || id == Orc
            || id == Skeleton {
            return Tier::T5(());
        }

        // fall through for unknown obstacle id return T5
        return Tier::T5(());
    }
}

#[test]
#[available_gas(300000)]
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
#[available_gas(300000)]
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
#[available_gas(200000)]
fn test_ambush() {
    // verify that below difficulty cliff, adventurers are immune to ambushes
    let mut adventurer_level = CombatSettings::DIFFICULTY_CLIFF::NORMAL - 1;
    let mut adventurer_wisdom = 0;
    let mut entropy = 1;
    assert(
        ImplBeast::ambush(adventurer_level, adventurer_wisdom, entropy) == false,
        'no ambush below difficult cliff'
    );
    entropy = 2;
    assert(
        ImplBeast::ambush(adventurer_level, adventurer_wisdom, entropy) == false,
        'no ambush below difficult cliff'
    );
    entropy = 3;
    assert(
        ImplBeast::ambush(adventurer_level, adventurer_wisdom, entropy) == false,
        'no ambush below difficult cliff'
    );
    entropy = 4;
    assert(
        ImplBeast::ambush(adventurer_level, adventurer_wisdom, entropy) == false,
        'no ambush below difficult cliff'
    );
    entropy = 5;
    assert(
        ImplBeast::ambush(adventurer_level, adventurer_wisdom, entropy) == false,
        'no ambush below difficult cliff'
    );

    // go above difficulty cliff
    adventurer_level = CombatSettings::DIFFICULTY_CLIFF::NORMAL + 1;
    // worst entropy is one less than adventurer_level
    // since this adventurer has no wisdom, this will result in them getting ambushed
    entropy = U8IntoU128::into(adventurer_level) - 1;
    assert(
        ImplBeast::ambush(adventurer_level, adventurer_wisdom, entropy) == true,
        'unwise adventurer gets ambushed'
    );

    // if adventurer has at least one wisdom stat after the difficult cliff
    // they remain immune to ambushes
    adventurer_wisdom = 1;
    assert(
        ImplBeast::ambush(adventurer_level, adventurer_wisdom, entropy) == false,
        'wise adventurer avoids ambush'
    );
    entropy = 1;
    assert(
        ImplBeast::ambush(adventurer_level, adventurer_wisdom, entropy) == false,
        'wise adventurer avoids ambush'
    );
    entropy = 2;
    assert(
        ImplBeast::ambush(adventurer_level, adventurer_wisdom, entropy) == false,
        'wise adventurer avoids ambush'
    );
    entropy = 3;
    assert(
        ImplBeast::ambush(adventurer_level, adventurer_wisdom, entropy) == false,
        'wise adventurer avoids ambush'
    );
    entropy = 4;
    assert(
        ImplBeast::ambush(adventurer_level, adventurer_wisdom, entropy) == false,
        'wise adventurer avoids ambush'
    );
    entropy = 5;
    assert(
        ImplBeast::ambush(adventurer_level, adventurer_wisdom, entropy) == false,
        'wise adventurer avoids ambush'
    );
}

#[test]
#[available_gas(250000)]
fn test_counter_attack() {
    // initialize warlock beast
    let warlock = Warlock;
    let mut beast = Beast {
        id: warlock, starting_health: 100, combat_spec: CombatSpec {
            item_type: ImplBeast::get_type(warlock),
            tier: ImplBeast::get_tier(warlock),
            level: 5,
            special_powers: SpecialPowers {
                prefix1: 0, prefix2: 0, suffix: 0, 
            }
        }
    };

    // initialize adventurer armor (T5 metal, G1)
    let mut armor = CombatSpec {
        item_type: Type::Bludgeon_or_Metal(()),
        tier: Tier::T5(()),
        level: 1,
        special_powers: SpecialPowers {
            prefix1: 0, prefix2: 0, suffix: 0
        }
    };

    let entropy = 0;

    let damage = beast.counter_attack(armor, entropy);
    assert(damage == 42, 'warlock wrecks scrub brute');
}

#[test]
#[available_gas(500000)]
fn test_attack() {
    let mut adventurer_strength = 0;
    let mut adventurer_luck = 0;
    let entropy = 2;

    // initialize adventurer weapon (G20 Katana)
    let mut weapon = CombatSpec {
        item_type: Type::Blade_or_Hide(()),
        tier: Tier::T1(()),
        level: 20,
        special_powers: SpecialPowers {
            prefix1: 0, prefix2: 0, suffix: 0
        }
    };

    // initialize goblin beast
    let goblin = Goblin;
    let beast = Beast {
        id: goblin, starting_health: 100, combat_spec: CombatSpec {
            item_type: ImplBeast::get_type(goblin),
            tier: ImplBeast::get_tier(goblin),
            level: 5,
            special_powers: SpecialPowers {
                prefix1: 0, prefix2: 0, suffix: 0, 
            }
        }
    };

    let damage = beast.attack(weapon, adventurer_luck, adventurer_strength, entropy);
    assert(damage == 140, 'g20 katana ruins lvl5 goblin');

    // bump adventurer strength by 1 which gives a +20% on base attack damage
    // T1 G20 is 100 base HP so they gain an extra 20HP for their strength stat
    adventurer_strength = 1;
    let damage = beast.attack(weapon, adventurer_luck, adventurer_strength, entropy);
    assert(damage == 160, 'strength gives extra damage');

    // boost luck to generate a critical hit (sorry gobblin)
    adventurer_luck = 40;
    let damage = beast.attack(weapon, adventurer_luck, adventurer_strength, entropy);
    assert(damage == 235, 'critical hit gives extra damage');
}

#[test]
#[available_gas(500000)]
fn test_get_level() {
    let mut adventurer_level = 1;
    let range_level_increase = CombatSettings::DIFFICULTY_CLIFF::NORMAL;
    let level_multiplier = CombatSettings::LEVEL_MULTIPLIER::NORMAL;

    // beast level and adventurer level will be same up to the difficulty cliff
    let entity_level = ImplBeast::get_level(adventurer_level, 0);
    assert(entity_level == adventurer_level, 'lvl should eql advr lvl');

    // test at just before the difficult level cliff
    adventurer_level = CombatSettings::DIFFICULTY_CLIFF::NORMAL - 1;
    let entity_level = ImplBeast::get_level(adventurer_level, 0);
    // entity level should still be the same as adventurer level
    assert(entity_level == adventurer_level, 'lvl should eql advr lvl');

    // As we exceed difficult cliff, beast level will start to range
    // based on entropy
    adventurer_level = CombatSettings::DIFFICULTY_CLIFF::NORMAL + 1;
    let entity_level = ImplBeast::get_level(adventurer_level, 0);
    assert(entity_level == 3, 'beast lvl should be 3');

    let entity_level = ImplBeast::get_level(adventurer_level, 1);
    assert(entity_level == 4, 'beast lvl should be 4');

    let entity_level = ImplBeast::get_level(adventurer_level, 2);
    assert(entity_level == 5, 'beast lvl should be 5');

    let entity_level = ImplBeast::get_level(adventurer_level, 3);
    assert(entity_level == 6, 'beast lvl should be 6');

    let entity_level = ImplBeast::get_level(adventurer_level, 4);
    assert(entity_level == 7, 'beast lvl should be 7');

    let entity_level = ImplBeast::get_level(adventurer_level, 5);
    assert(entity_level == 8, 'beast lvl should be 8');

    let entity_level = ImplBeast::get_level(adventurer_level, 6);
    assert(entity_level == 9, 'beast lvl should be 9');

    let entity_level = ImplBeast::get_level(adventurer_level, 7);
    assert(entity_level == 10, 'beast lvl should be 10');

    // verify we roll over back to beast level 1
    let entity_level = ImplBeast::get_level(adventurer_level, 8);
    assert(entity_level == 3, 'entity lvl should be 3');
}

#[test]
#[available_gas(80000)]
fn test_get_starting_health() {
    let mut adventurer_level = 1;
    let mut entropy = 0;

    // lowest beast starting health is 6
    let starting_health = ImplBeast::get_starting_health(adventurer_level, entropy);
    assert(starting_health == 6, 'minimum beast health is 6');

    // with adventurer at 4x difficulty cliff
    // beast health will start to increase
    // entropy 0 gives us lower end
    adventurer_level = CombatSettings::DIFFICULTY_CLIFF::NORMAL * 4;
    let starting_health = ImplBeast::get_starting_health(adventurer_level, entropy);
    assert(starting_health == 21, 'beast health should be 21');

    // test upper end up health
    // with our default settings, the above tests demonstrate that an adventurer on level 16 will discover beasts
    // with health between 21 and 74. When they hit level 20, max health will increase by an additional 15 to 89
    entropy = 74;
    let starting_health = ImplBeast::get_starting_health(adventurer_level, entropy);
    assert(starting_health == 95, 'beast health should be 95');
}

#[test]
#[available_gas(50000)]
fn test_get_beast_id() {
    let zero_check = 0;
    let beast_id = ImplBeast::get_beast_id(zero_check);
    assert(beast_id != 0, 'beast should not be zero');
    assert(beast_id <= U128TryIntoU8::try_into(MAX_ID).unwrap(), 'beast higher than max beastid');

    let max_beast_id = MAX_ID;
    let beast_id = ImplBeast::get_beast_id(max_beast_id);
    assert(beast_id != 0, 'beast should not be zero');
    assert(beast_id <= U128TryIntoU8::try_into(MAX_ID).unwrap(), 'beast higher than max beastid');

    let above_max_beast_id = MAX_ID + 1;
    let beast_id = ImplBeast::get_beast_id(max_beast_id);
    assert(beast_id != 0, 'beast should not be zero');
    assert(beast_id <= U128TryIntoU8::try_into(MAX_ID).unwrap(), 'beast higher than max beastid');
}

#[test]
#[available_gas(360000)]
fn test_get_beast() {
    let adventurer_level = 2;
    let special_names = SpecialPowers { prefix1: 0, prefix2: 0, suffix: 0 };
    let seed = 1;

    // generate beast for seed
    let starting_weapon = Type::Magic_or_Cloth(());
    let original_beast = ImplBeast::get_beast(
        adventurer_level, special_names, seed, starting_weapon
    );

    // adjust the other input paramters
    let adventurer_level = 3;
    let special_names = SpecialPowers { prefix1: 1, prefix2: 1, suffix: 1 };
    let new_beast = ImplBeast::get_beast(adventurer_level, special_names, seed, starting_weapon);

    // verify beasts are the same since the seed did not change
    assert(original_beast.id == new_beast.id, 'seed produced two diff beastIds');
}
#[test]
#[available_gas(250000)]
fn test_get_gold_reward() {
    let mut beast = Beast {
        id: 1, starting_health: 100, combat_spec: CombatSpec {
            tier: Tier::T1(()),
            item_type: Type::Magic_or_Cloth(()),
            level: 10,
            special_powers: SpecialPowers {
                prefix1: 1, prefix2: 2, suffix: 3, 
            },
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
