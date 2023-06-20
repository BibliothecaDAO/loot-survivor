use core::serde::Serde;
use integer::{
    U128IntoFelt252, Felt252IntoU256, Felt252TryIntoU64, U256TryIntoFelt252, u256_from_felt252,
    U8IntoU16, U8IntoU64, U64TryIntoU8
};
use traits::{TryInto, Into};
use option::OptionTrait;
use debug::PrintTrait;
use super::constants::{BeastId, BeastSettings};
use combat::constants::{CombatSettings, CombatEnums::{Type, Tier, Slot}};
use combat::combat::{ImplCombat, CombatSpec, SpecialPowers};

#[derive(Drop, Copy, Serde)] // 24 bits
struct Beast {
    id: u8, // beast id 1 - 75
    starting_health: u16, // health of the beast (stored on adventurer)
    combat_spec: CombatSpec, // Combat Spec
}

trait BeastTrait {
    fn get_beast(adventurer_level: u8, special_names: SpecialPowers, seed: u64) -> Beast;
    fn attack(
        adventurer_luck: u8, adventurer_strength: u8, weapon: CombatSpec, beast: Beast, entropy: u64
    ) -> u16;
    fn counter_attack(beast: Beast, armor: CombatSpec, entropy: u64) -> u16;
    fn avoided_ambushed(adventurer_level: u8, adventurer_wisdom: u8, entropy: u64) -> bool;
    fn get_level(adventurer_level: u8, seed: u64) -> u8;
    fn get_starting_health(adventurer_level: u8, entropy: u64) -> u16;
    fn get_beast_id(seed: u64) -> u8;
    fn get_tier(id: u8) -> Tier;
    fn get_type(id: u8) -> Type;
}

impl ImplBeast of BeastTrait {
    fn get_beast(adventurer_level: u8, special_names: SpecialPowers, seed: u64) -> Beast {
        // TODO: Generate a deterministic beast using the details of the adventurer
        let beast_id = ImplBeast::get_beast_id(seed);

        return Beast {
            id: beast_id,
            starting_health: ImplBeast::get_starting_health(adventurer_level, seed),
            combat_spec: CombatSpec {
                tier: ImplBeast::get_tier(beast_id),
                item_type: ImplBeast::get_type(beast_id),
                level: U8IntoU16::into(ImplBeast::get_level(adventurer_level, seed)),
                special_powers: special_names
            }
        };
    }

    fn get_beast_id(seed: u64) -> u8 {
        // get a beast id between 1 and max beast id (inclusive)
        // we specify "seed" as the input instead of "entropy" because
        // we want to advertise that this function is intended
        // to be used to generate deterministic beasts.
        // The value of this is an adventurer can battle
        // the same beast across multiple contract calls
        // without having to pay for gas to store the beast
        let beast_id = (seed % BeastId::MAX_ID) + 1;

        // return beast id as a u8
        return U64TryIntoU8::try_into(beast_id).unwrap();
    }


    fn get_starting_health(adventurer_level: u8, entropy: u64, ) -> u16 {
        // Delete this function to combat system but pass in difficulty parameters
        // which control when and how quickly beasts health increases
        ImplCombat::get_enemy_starting_health(
            adventurer_level,
            BeastSettings::MINIMUM_HEALTH,
            entropy,
            CombatSettings::DIFFICULTY_CLIFF::NORMAL,
            CombatSettings::HEALTH_MULTIPLIER::NORMAL
        )
    }
    fn get_level(adventurer_level: u8, seed: u64) -> u8 {
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
        adventurer_luck: u8, adventurer_strength: u8, weapon: CombatSpec, beast: Beast, entropy: u64
    ) -> u16 {
        // check if the attack is a critical hit
        let is_critical_hit = ImplCombat::is_critical_hit(adventurer_luck, entropy);

        // minimum damage when adventurer attacks is equal to the adventurer's strength
        let minimum_damage = U8IntoU16::into(adventurer_strength);

        // delegate damage calculation to combat system
        return ImplCombat::calculate_damage(
            weapon,
            beast.combat_spec,
            minimum_damage,
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
    fn counter_attack(beast: Beast, armor: CombatSpec, entropy: u64) -> u16 {
        let is_critical_hit = false;

        // delegate damage calculation to combat system
        return ImplCombat::calculate_damage(
            beast.combat_spec,
            armor,
            BeastSettings::MINIMUM_DAMAGE,
            BeastSettings::STRENGTH_BONUS,
            is_critical_hit,
            entropy
        );
    }

    // avoid_ambushed is used to determine if an adventurer avoided a beast ambush
    // @param adventurer_level: the level of the adventurer
    // @param adventurer_wisdom: the wisdom of the adventurer
    // @param entropy: the entropy used to generate the random number
    // @return: true if the adventurer avoided the ambush, false otherwise
    fn avoided_ambushed(adventurer_level: u8, adventurer_wisdom: u8, entropy: u64) -> bool {
        // Delegate ambushed calculation to combat system
        // avoiding beast ambush requires wisdom
        return ImplCombat::ability_based_avoid_threat(adventurer_level, adventurer_wisdom, entropy);
    }

    fn get_type(id: u8) -> Type {
        if id == BeastId::Warlock {
            return Type::Magic_or_Cloth(());
        } else if id == BeastId::Rakshasa {
            return Type::Magic_or_Cloth(());
        } else if id == BeastId::Jiangshi {
            return Type::Magic_or_Cloth(());
        } else if id == BeastId::Kitsune {
            return Type::Magic_or_Cloth(());
        } else if id == BeastId::Basilisk {
            return Type::Magic_or_Cloth(());
        } else if id == BeastId::Gorgon {
            return Type::Magic_or_Cloth(());
        } else if id == BeastId::Anansi {
            return Type::Magic_or_Cloth(());
        } else if id == BeastId::Lich {
            return Type::Magic_or_Cloth(());
        } else if id == BeastId::Chimera {
            return Type::Magic_or_Cloth(());
        } else if id == BeastId::Wendigo {
            return Type::Magic_or_Cloth(());
        } else if id == BeastId::Cerberus {
            return Type::Magic_or_Cloth(());
        } else if id == BeastId::Werewolf {
            return Type::Magic_or_Cloth(());
        } else if id == BeastId::Banshee {
            return Type::Magic_or_Cloth(());
        } else if id == BeastId::Draugr {
            return Type::Magic_or_Cloth(());
        } else if id == BeastId::Vampire {
            return Type::Magic_or_Cloth(());
        } else if id == BeastId::Goblin {
            return Type::Magic_or_Cloth(());
        } else if id == BeastId::Ghoul {
            return Type::Magic_or_Cloth(());
        } else if id == BeastId::Pixie {
            return Type::Magic_or_Cloth(());
        } else if id == BeastId::Sprite {
            return Type::Magic_or_Cloth(());
        } else if id == BeastId::Kappa {
            return Type::Magic_or_Cloth(());
        } else if id == BeastId::Fairy {
            return Type::Magic_or_Cloth(());
        } else if id == BeastId::Leprechaun {
            return Type::Magic_or_Cloth(());
        } else if id == BeastId::Kelpie {
            return Type::Magic_or_Cloth(());
        } else if id == BeastId::Wraith {
            return Type::Magic_or_Cloth(());
        } else if id == BeastId::Gnome {
            return Type::Magic_or_Cloth(());
        } else if id == BeastId::Griffin {
            return Type::Blade_or_Hide(());
        } else if id == BeastId::Manticore {
            return Type::Blade_or_Hide(());
        } else if id == BeastId::Phoenix {
            return Type::Blade_or_Hide(());
        } else if id == BeastId::Dragon {
            return Type::Blade_or_Hide(());
        } else if id == BeastId::Minotaur {
            return Type::Blade_or_Hide(());
        } else if id == BeastId::Harpy {
            return Type::Blade_or_Hide(());
        } else if id == BeastId::Arachne {
            return Type::Blade_or_Hide(());
        } else if id == BeastId::Nue {
            return Type::Blade_or_Hide(());
        } else if id == BeastId::Skinwalker {
            return Type::Blade_or_Hide(());
        } else if id == BeastId::Chupacabra {
            return Type::Blade_or_Hide(());
        } else if id == BeastId::Weretiger {
            return Type::Blade_or_Hide(());
        } else if id == BeastId::Wyvern {
            return Type::Blade_or_Hide(());
        } else if id == BeastId::Roc {
            return Type::Blade_or_Hide(());
        } else if id == BeastId::Qilin {
            return Type::Blade_or_Hide(());
        } else if id == BeastId::Pegasus {
            return Type::Blade_or_Hide(());
        } else if id == BeastId::Hippogriff {
            return Type::Blade_or_Hide(());
        } else if id == BeastId::Fenrir {
            return Type::Blade_or_Hide(());
        } else if id == BeastId::Jaguar {
            return Type::Blade_or_Hide(());
        } else if id == BeastId::Ammit {
            return Type::Blade_or_Hide(());
        } else if id == BeastId::DireWolf {
            return Type::Blade_or_Hide(());
        } else if id == BeastId::Bear {
            return Type::Blade_or_Hide(());
        } else if id == BeastId::Wolf {
            return Type::Blade_or_Hide(());
        } else if id == BeastId::Scorpion {
            return Type::Blade_or_Hide(());
        } else if id == BeastId::Spider {
            return Type::Blade_or_Hide(());
        } else if id == BeastId::Rat {
            return Type::Blade_or_Hide(());
        } else if id == BeastId::Cyclops {
            return Type::Bludgeon_or_Metal(());
        } else if id == BeastId::Golem {
            return Type::Bludgeon_or_Metal(());
        } else if id == BeastId::Titan {
            return Type::Bludgeon_or_Metal(());
        } else if id == BeastId::Yeti {
            return Type::Bludgeon_or_Metal(());
        } else if id == BeastId::Troll {
            return Type::Bludgeon_or_Metal(());
        } else if id == BeastId::Oni {
            return Type::Bludgeon_or_Metal(());
        } else if id == BeastId::Ogre {
            return Type::Bludgeon_or_Metal(());
        } else if id == BeastId::Juggernaut {
            return Type::Bludgeon_or_Metal(());
        } else if id == BeastId::Bigfoot {
            return Type::Bludgeon_or_Metal(());
        } else if id == BeastId::Orc {
            return Type::Bludgeon_or_Metal(());
        } else if id == BeastId::Behemoth {
            return Type::Bludgeon_or_Metal(());
        } else if id == BeastId::Ent {
            return Type::Bludgeon_or_Metal(());
        } else if id == BeastId::Giant {
            return Type::Bludgeon_or_Metal(());
        } else if id == BeastId::Kraken {
            return Type::Bludgeon_or_Metal(());
        } else if id == BeastId::Leviathan {
            return Type::Bludgeon_or_Metal(());
        } else if id == BeastId::Skeleton {
            return Type::Bludgeon_or_Metal(());
        } else if id == BeastId::Nephilim {
            return Type::Bludgeon_or_Metal(());
        } else if id == BeastId::Tarrasque {
            return Type::Bludgeon_or_Metal(());
        } else if id == BeastId::Beserker {
            return Type::Bludgeon_or_Metal(());
        } else if id == BeastId::Balrog {
            return Type::Bludgeon_or_Metal(());
        } else if id == BeastId::Ettin {
            return Type::Bludgeon_or_Metal(());
        } else if id == BeastId::Jotunn {
            return Type::Bludgeon_or_Metal(());
        } else if id == BeastId::Hydra {
            return Type::Bludgeon_or_Metal(());
        } else if id == BeastId::NemeanLion {
            return Type::Bludgeon_or_Metal(());
        } else if id == BeastId::Colossus {
            return Type::Bludgeon_or_Metal(());
        }

        // unknown id gets type bludgeon/metal
        return Type::Bludgeon_or_Metal(());
    }


    fn get_tier(id: u8) -> Tier {
        if id == BeastId::Warlock {
            return Tier::T1(());
        } else if id == BeastId::Rakshasa {
            return Tier::T1(());
        } else if id == BeastId::Jiangshi {
            return Tier::T1(());
        } else if id == BeastId::Kitsune {
            return Tier::T1(());
        } else if id == BeastId::Basilisk {
            return Tier::T1(());
        } else if id == BeastId::Gorgon {
            return Tier::T2(());
        } else if id == BeastId::Anansi {
            return Tier::T2(());
        } else if id == BeastId::Lich {
            return Tier::T2(());
        } else if id == BeastId::Chimera {
            return Tier::T2(());
        } else if id == BeastId::Wendigo {
            return Tier::T2(());
        } else if id == BeastId::Cerberus {
            return Tier::T3(());
        } else if id == BeastId::Werewolf {
            return Tier::T3(());
        } else if id == BeastId::Banshee {
            return Tier::T3(());
        } else if id == BeastId::Draugr {
            return Tier::T3(());
        } else if id == BeastId::Vampire {
            return Tier::T3(());
        } else if id == BeastId::Goblin {
            return Tier::T4(());
        } else if id == BeastId::Ghoul {
            return Tier::T4(());
        } else if id == BeastId::Pixie {
            return Tier::T4(());
        } else if id == BeastId::Sprite {
            return Tier::T4(());
        } else if id == BeastId::Kappa {
            return Tier::T4(());
        } else if id == BeastId::Fairy {
            return Tier::T5(());
        } else if id == BeastId::Leprechaun {
            return Tier::T5(());
        } else if id == BeastId::Kelpie {
            return Tier::T5(());
        } else if id == BeastId::Wraith {
            return Tier::T5(());
        } else if id == BeastId::Gnome {
            return Tier::T5(());
        } else if id == BeastId::Griffin {
            return Tier::T1(());
        } else if id == BeastId::Manticore {
            return Tier::T1(());
        } else if id == BeastId::Phoenix {
            return Tier::T1(());
        } else if id == BeastId::Dragon {
            return Tier::T1(());
        } else if id == BeastId::Minotaur {
            return Tier::T1(());
        } else if id == BeastId::Harpy {
            return Tier::T2(());
        } else if id == BeastId::Arachne {
            return Tier::T2(());
        } else if id == BeastId::Nue {
            return Tier::T2(());
        } else if id == BeastId::Skinwalker {
            return Tier::T2(());
        } else if id == BeastId::Chupacabra {
            return Tier::T2(());
        } else if id == BeastId::Weretiger {
            return Tier::T3(());
        } else if id == BeastId::Wyvern {
            return Tier::T3(());
        } else if id == BeastId::Roc {
            return Tier::T3(());
        } else if id == BeastId::Qilin {
            return Tier::T3(());
        } else if id == BeastId::Pegasus {
            return Tier::T3(());
        } else if id == BeastId::Hippogriff {
            return Tier::T4(());
        } else if id == BeastId::Fenrir {
            return Tier::T4(());
        } else if id == BeastId::Jaguar {
            return Tier::T4(());
        } else if id == BeastId::Ammit {
            return Tier::T4(());
        } else if id == BeastId::DireWolf {
            return Tier::T4(());
        } else if id == BeastId::Bear {
            return Tier::T5(());
        } else if id == BeastId::Wolf {
            return Tier::T5(());
        } else if id == BeastId::Scorpion {
            return Tier::T5(());
        } else if id == BeastId::Spider {
            return Tier::T5(());
        } else if id == BeastId::Rat {
            return Tier::T5(());
        } else if id == BeastId::Cyclops {
            return Tier::T1(());
        } else if id == BeastId::Golem {
            return Tier::T1(());
        } else if id == BeastId::Titan {
            return Tier::T1(());
        } else if id == BeastId::Yeti {
            return Tier::T1(());
        } else if id == BeastId::Troll {
            return Tier::T1(());
        } else if id == BeastId::Oni {
            return Tier::T2(());
        } else if id == BeastId::Ogre {
            return Tier::T2(());
        } else if id == BeastId::Juggernaut {
            return Tier::T2(());
        } else if id == BeastId::Bigfoot {
            return Tier::T2(());
        } else if id == BeastId::Orc {
            return Tier::T2(());
        } else if id == BeastId::Behemoth {
            return Tier::T3(());
        } else if id == BeastId::Ent {
            return Tier::T3(());
        } else if id == BeastId::Giant {
            return Tier::T3(());
        } else if id == BeastId::Kraken {
            return Tier::T3(());
        } else if id == BeastId::Leviathan {
            return Tier::T3(());
        } else if id == BeastId::Skeleton {
            return Tier::T4(());
        } else if id == BeastId::Nephilim {
            return Tier::T4(());
        } else if id == BeastId::Tarrasque {
            return Tier::T4(());
        } else if id == BeastId::Beserker {
            return Tier::T4(());
        } else if id == BeastId::Balrog {
            return Tier::T4(());
        } else if id == BeastId::Ettin {
            return Tier::T5(());
        } else if id == BeastId::Jotunn {
            return Tier::T5(());
        } else if id == BeastId::Hydra {
            return Tier::T5(());
        } else if id == BeastId::NemeanLion {
            return Tier::T5(());
        } else if id == BeastId::Colossus {
            return Tier::T5(());
        }

        // fall through for unknown obstacle id return T5
        return Tier::T5(());
    }
}

#[test]
#[available_gas(90000)]
fn test_get_tier() {
    let warlock = BeastId::Warlock;
    let warlock_tier = ImplBeast::get_tier(warlock);
    assert(warlock_tier == Tier::T1(()), 'Warlock should be T1');

    let juggernaut = BeastId::Juggernaut;
    let juggernaut_tier = ImplBeast::get_tier(juggernaut);
    assert(juggernaut_tier == Tier::T2(()), 'Juggernaut should be T2');

    let pegasus = BeastId::Pegasus;
    let pegasus_tier = ImplBeast::get_tier(pegasus);
    assert(pegasus_tier == Tier::T3(()), 'Pegasus should be T3');

    let goblin = BeastId::Goblin;
    let goblin_tier = ImplBeast::get_tier(goblin);
    assert(goblin_tier == Tier::T4(()), 'Goblin should be T4');

    let bear = BeastId::Bear;
    let bear_tier = ImplBeast::get_tier(bear);
    assert(bear_tier == Tier::T5(()), 'Bear should be T5');
}

#[test]
#[available_gas(90000)]
fn test_get_type() {
    let warlock_type = ImplBeast::get_type(BeastId::Warlock);
    assert(warlock_type == Type::Magic_or_Cloth(()), 'Warlock is magical');

    let juggernaut_type = ImplBeast::get_type(BeastId::Juggernaut);
    assert(juggernaut_type == Type::Bludgeon_or_Metal(()), 'Juggernaut is a brute ');

    let pegasus_type = ImplBeast::get_type(BeastId::Pegasus);
    assert(pegasus_type == Type::Blade_or_Hide(()), 'Pegasus is a hunter');

    let goblin_type = ImplBeast::get_type(BeastId::Goblin);
    assert(goblin_type == Type::Magic_or_Cloth(()), 'Goblin is magical');

    let bear_type = ImplBeast::get_type(BeastId::Bear);
    assert(bear_type == Type::Blade_or_Hide(()), 'Bear is a hunter');
}

#[test]
#[available_gas(180000)]
fn test_avoided_ambushed() {
    // verify that below difficulty cliff, adventurers are immune to ambushes
    let mut adventurer_level = CombatSettings::DIFFICULTY_CLIFF::NORMAL - 1;
    let mut adventurer_wisdom = 0;
    let mut entropy = 1;
    assert(
        ImplBeast::avoided_ambushed(adventurer_level, adventurer_wisdom, entropy) == true,
        'no ambush below difficult cliff'
    );
    entropy = 2;
    assert(
        ImplBeast::avoided_ambushed(adventurer_level, adventurer_wisdom, entropy) == true,
        'no ambush below difficult cliff'
    );
    entropy = 3;
    assert(
        ImplBeast::avoided_ambushed(adventurer_level, adventurer_wisdom, entropy) == true,
        'no ambush below difficult cliff'
    );
    entropy = 4;
    assert(
        ImplBeast::avoided_ambushed(adventurer_level, adventurer_wisdom, entropy) == true,
        'no ambush below difficult cliff'
    );
    entropy = 5;
    assert(
        ImplBeast::avoided_ambushed(adventurer_level, adventurer_wisdom, entropy) == true,
        'no ambush below difficult cliff'
    );

    // go above difficulty cliff
    adventurer_level = CombatSettings::DIFFICULTY_CLIFF::NORMAL + 1;
    // worst entropy is one less than adventurer_level
    // since this adventurer has no wisdom, this will result in them getting ambushed
    entropy = U8IntoU64::into(adventurer_level) - 1;
    assert(
        ImplBeast::avoided_ambushed(adventurer_level, adventurer_wisdom, entropy) == false,
        'unwise adventurer gets ambushed'
    );

    // if adventurer has at least one wisdom stat after the difficult cliff
    // they remain immune to ambushes
    adventurer_wisdom = 1;
    assert(
        ImplBeast::avoided_ambushed(adventurer_level, adventurer_wisdom, entropy) == true,
        'wise adventurer avoids ambush'
    );
    entropy = 1;
    assert(
        ImplBeast::avoided_ambushed(adventurer_level, adventurer_wisdom, entropy) == true,
        'wise adventurer avoids ambush'
    );
    entropy = 2;
    assert(
        ImplBeast::avoided_ambushed(adventurer_level, adventurer_wisdom, entropy) == true,
        'wise adventurer avoids ambush'
    );
    entropy = 3;
    assert(
        ImplBeast::avoided_ambushed(adventurer_level, adventurer_wisdom, entropy) == true,
        'wise adventurer avoids ambush'
    );
    entropy = 4;
    assert(
        ImplBeast::avoided_ambushed(adventurer_level, adventurer_wisdom, entropy) == true,
        'wise adventurer avoids ambush'
    );
    entropy = 5;
    assert(
        ImplBeast::avoided_ambushed(adventurer_level, adventurer_wisdom, entropy) == true,
        'wise adventurer avoids ambush'
    );
}

#[test]
#[available_gas(180000)]
fn test_counter_attack() {
    // initialize warlock beast
    let warlock = BeastId::Warlock;
    let beast = Beast {
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

    let damage = ImplBeast::counter_attack(beast, armor, entropy);
    assert(damage == 36, 'warlock wrecks scrub brute');
}

#[test]
#[available_gas(400000)]
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
    let goblin = BeastId::Goblin;
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

    let damage = ImplBeast::attack(adventurer_luck, adventurer_strength, weapon, beast, entropy);
    assert(damage == 140, 'g20 katana ruins lvl5 goblin');

    // bump adventurer strength by 1 which gives a +20% on base attack damage
    // T1 G20 is 100 base HP so they gain an extra 20HP for their strength stat
    adventurer_strength = 1;
    let damage = ImplBeast::attack(adventurer_luck, adventurer_strength, weapon, beast, entropy);
    assert(damage == 160, 'strength gives extra damage');

    // boost luck to generate a critical hit (sorry gobblin)
    adventurer_luck = 40;
    let damage = ImplBeast::attack(adventurer_luck, adventurer_strength, weapon, beast, entropy);
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
    assert(
        beast_id <= U64TryIntoU8::try_into(BeastId::MAX_ID).unwrap(),
        'beast higher than max beastid'
    );

    let max_beast_id = BeastId::MAX_ID;
    let beast_id = ImplBeast::get_beast_id(max_beast_id);
    assert(beast_id != 0, 'beast should not be zero');
    assert(
        beast_id <= U64TryIntoU8::try_into(BeastId::MAX_ID).unwrap(),
        'beast higher than max beastid'
    );

    let above_max_beast_id = BeastId::MAX_ID + 1;
    let beast_id = ImplBeast::get_beast_id(max_beast_id);
    assert(beast_id != 0, 'beast should not be zero');
    assert(
        beast_id <= U64TryIntoU8::try_into(BeastId::MAX_ID).unwrap(),
        'beast higher than max beastid'
    );
}

#[test]
#[available_gas(190000)]
fn test_get_beast() {
    let adventurer_level = 1;
    let special_names = SpecialPowers { prefix1: 0, prefix2: 0, suffix: 0 };
    let seed = 1;

    // generate beast for seed
    let original_beast = ImplBeast::get_beast(adventurer_level, special_names, seed);

    // adjust the other input paramters
    let adventurer_level = 3;
    let special_names = SpecialPowers { prefix1: 1, prefix2: 1, suffix: 1 };
    let new_beast = ImplBeast::get_beast(adventurer_level, special_names, seed);

    // verify beasts are the same since the seed did not change
    assert(original_beast.id == new_beast.id, 'seed produced two diff beastIds');
}
