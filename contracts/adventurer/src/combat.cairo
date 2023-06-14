use core::option::OptionTrait;
use integer::{U8IntoU16, U16IntoU64, U8IntoU64, U64TryIntoU16};
use core::traits::DivEq;
use survivor::adventurer::{Adventurer, AdventurerActions};
use lootitems::statistics::constants::{Type};
use survivor::constants::combat_constants::{WeaponEffectiveness, CombatSettings};

#[derive(Drop, Copy)]
struct CombatItemName {
    prefix: u8,
    suffix: u8,
}

#[derive(Drop, Copy)]
struct CombatItem {
    item_type: u8,
    tier: u16, // using u16 because this is commonly used for combat calculations where u8 is too small
    level: u16, // using u16 because this is commonly used for combat calculations where u8 is too small
    name: CombatItemName,
    suffix: u8,
}

// Combat is a trait that provides functions for calculating combat damage
trait Combat {
    fn calculate_damage(
        weapon: CombatItem,
        armor: CombatItem,
        adventurer: Adventurer,
        adventurer_entropy: u64,
        game_entropy: u64
    ) -> u16;
    fn get_base_damage(adventurer_level: u8, weapon: CombatItem, armor: CombatItem) -> u16;
    fn adjust_damage_for_elemental(base_damage: u16, weapon_type: u8, armor_type: u8) -> u16;
    fn get_weapon_effectiveness(weapon_type: u8, armor_type: u8) -> WeaponEffectiveness;
    fn is_critical_hit(
        adventurer_luck: u8, adventurer_health: u16, adventurer_entropy: u64, game_entropy: u64
    ) -> bool;
    fn get_critical_hit_damage_bonus(
        base_damage: u16,
        adventurer_luck: u8,
        adventurer_health: u16,
        adventurer_entropy: u64,
        game_entropy: u64
    ) -> u16;

    fn get_name_prefix_damage_bonus(
        base_damage: u16,
        weapon_name: CombatItemName,
        armor_name: CombatItemName,
        adventurer_entropy: u64,
        game_entropy: u64
    ) -> u16;

    fn get_name_suffix_damage_bonus(
        base_damage: u16,
        weapon_name: CombatItemName,
        armor_name: CombatItemName,
        adventurer_entropy: u64,
        game_entropy: u64
    ) -> u16;

    fn get_special_name_damage_bonus(
        base_damage: u16,
        weapon_name: CombatItemName,
        armor_name: CombatItemName,
        adventurer_entropy: u64,
        game_entropy: u64
    ) -> u16;
    fn get_adventurer_strength_bonus(adventurer: Adventurer, original_damage: u16) -> u16;
}

// CombatUtils is an implementation of the Combat trait
// It provides functions for calculating combat damage
impl CombatUtils of Combat {
    // calculate_damage calculates the damage done by an entity wielding a weapon against an entity wearing armor
    // @param weapon: the weapon used to attack
    // @param armor: the armor worn by the defender
    // @param adventurer: the adventurer attacking
    // @param adventurer_entropy: the adventurer's entropy
    // @param game_entropy: the game's entropy
    // @return u16: the damage done by the attacker
    fn calculate_damage(
        weapon: CombatItem,
        armor: CombatItem,
        adventurer: Adventurer,
        adventurer_entropy: u64,
        game_entropy: u64
    ) -> u16 {
        // get adventurer level
        let adventurer_level = AdventurerActions::get_level(adventurer);

        // get base damage
        let base_damage_with_elemental = CombatUtils::get_base_damage(
            adventurer_level, weapon, armor
        );

        // get critical hit damage bonus
        let critical_hit_damage_bonus = CombatUtils::get_critical_hit_damage_bonus(
            base_damage_with_elemental,
            AdventurerActions::luck(adventurer),
            adventurer.health,
            adventurer_entropy,
            game_entropy
        );

        // get special name damage bonus
        let special_name_damage_bonus = CombatUtils::get_special_name_damage_bonus(
            base_damage_with_elemental, weapon.name, armor.name, adventurer_entropy, game_entropy
        );

        // get adventurer strength bonus
        let adventurer_strength_bonus = CombatUtils::get_adventurer_strength_bonus(
            adventurer, base_damage_with_elemental
        );

        // sum damages
        let total_damage = base_damage_with_elemental
            + critical_hit_damage_bonus
            + special_name_damage_bonus
            + adventurer_strength_bonus;

        // return total damage
        return total_damage;
    }

    // get_base_damage calculates the base damage done by an entity wielding a weapon against an entity wearing armor
    // @param adventurer_level: the level of the adventurer
    // @param weapon: the weapon used to attack
    // @param armor: the armor worn by the defender
    // @return u16: the base damage done by the attacker
    fn get_base_damage(adventurer_level: u8, weapon: CombatItem, armor: CombatItem) -> u16 {
        // TODO: figure out where to put this const
        let item_tier_cap = 6;
        let adventurer_level_u16 = U8IntoU16::into(adventurer_level);

        // base damage is attack HP minus defense HP
        let base_attack_hp = (item_tier_cap - weapon.tier) * weapon.level;
        let elemental_adjusted_attack_hp = CombatUtils::adjust_damage_for_elemental(
            base_attack_hp, weapon.item_type, armor.item_type
        );

        let armor_hp = (item_tier_cap - armor.tier) * armor.level;
        let mut base_damage = 0;

        // if attack_hp is greater than armor_hp + adventurer_level
        if (elemental_adjusted_attack_hp > armor_hp + adventurer_level_u16) {
            // we know we don't have an underflow issue and that this will result in more than minimum of adventurer level
            return elemental_adjusted_attack_hp - armor_hp;
        } else {
            // otherwise we use adventurer level as the minimum 
            return adventurer_level_u16;
        }
    }

    // adjust_damage_for_elemental adjusts the base damage for elemental effects
    // @param base_damage: the base damage done by the attacker
    // @param weapon_type: the type of weapon used by the attacker
    // @param armor_type: the type of armor worn by the defender
    // @return u16: the base damage done by the attacker adjusted for elemental effects
    fn adjust_damage_for_elemental(base_damage: u16, weapon_type: u8, armor_type: u8) -> u16 {
        // CombatSettings::ElementalDamageBonus determines impact of elemental damage
        // default setting is 2 which results in -50%, 0%, or 50% damage bonus for elemental
        let elemental_damage_effect = base_damage / CombatSettings::ElementalDamageBonus;

        // get weapon effectiveness
        let weapon_effectiveness = CombatUtils::get_weapon_effectiveness(weapon_type, armor_type);

        // adjust base damage based on weapon effectiveness
        match weapon_effectiveness {
            WeaponEffectiveness::Weak(()) => {
                return base_damage - elemental_damage_effect;
            },
            WeaponEffectiveness::Fair(()) => {
                return base_damage;
            },
            WeaponEffectiveness::Strong(()) => {
                return base_damage + elemental_damage_effect;
            }
        }
    }

    // get_weapon_effectiveness returns a WeaponEffectiveness enum indicating the effectiveness of the weapon against the armor
    // the effectiveness is determined by the weapon type and the armor type
    // @param weapon_type: the type of the weapon
    // @param armor_type: the type of the armor
    // @return WeaponEffectiveness: the effectiveness of the weapon against the armor
    fn get_weapon_effectiveness(weapon_type: u8, armor_type: u8) -> WeaponEffectiveness {
        if (weapon_type == Type::Weapon::Magic) {
            if (armor_type == Type::Armor::Metal) {
                return WeaponEffectiveness::Strong(());
            } else if (armor_type == Type::Armor::Cloth) {
                return WeaponEffectiveness::Fair(());
            } else if (armor_type == Type::Armor::Hide) {
                return WeaponEffectiveness::Weak(());
            }
        } else if (weapon_type == Type::Weapon::Blade) {
            if (armor_type == Type::Armor::Cloth) {
                return WeaponEffectiveness::Strong(());
            } else if (armor_type == Type::Armor::Hide) {
                return WeaponEffectiveness::Fair(());
            } else if (armor_type == Type::Armor::Metal) {
                return WeaponEffectiveness::Weak(());
            }
        } else if (weapon_type == Type::Weapon::Bludgeon) {
            if (armor_type == Type::Armor::Hide) {
                return WeaponEffectiveness::Strong(());
            } else if (armor_type == Type::Armor::Metal) {
                return WeaponEffectiveness::Fair(());
            } else if (armor_type == Type::Armor::Cloth) {
                return WeaponEffectiveness::Weak(());
            }
        }

        return WeaponEffectiveness::Weak(());
    }

    // is_critical_hit determines if an attack is a critical hit
    // @param adventurer_luck: the luck of the adventurer
    // @param adventurer_health: the health of the adventurer
    // @param adventurer_entropy: the adventurer entropy
    // @param game_entropy: the game entropy
    // @return bool: true if the attack is a critical hit, false otherwise
    fn is_critical_hit(
        adventurer_luck: u8, adventurer_health: u16, adventurer_entropy: u64, game_entropy: u64
    ) -> bool {
        // TODO: move this to combat settings;
        let MAX_CRITICAL_HIT_CHANCE: u16 = 4;

        // critical hit chance is whole number of luck / 10
        // so the chance of getting a critical hit increases every 10 luck
        let mut critical_hit_chance: u16 = U8IntoU16::into(adventurer_luck) / 10;

        // critical hit random number is adventurer entropy + game entropy + adventurer health
        // using health in this calculation is essential to have this change each attack
        let mut critical_hit_rnd = adventurer_entropy
            + game_entropy
            + U16IntoU64::into(adventurer_health);

        // critical hit chance is capped at 4 which will result in 50% chance of critical hit
        if (critical_hit_chance >= MAX_CRITICAL_HIT_CHANCE) {
            critical_hit_chance = MAX_CRITICAL_HIT_CHANCE;
        }

        // critical hit random number is modulo the max critical hit chance
        // this will result in a number between 0 and 5
        critical_hit_rnd %= U16IntoU64::into((6 - critical_hit_chance));

        // if the critical hit random number is 0 (no remainder)
        if (critical_hit_rnd == 0) {
            // return true
            return true;
        } else {
            // otherwise return false
            return false;
        }
    }

    // get_critical_hit_damage_bonus returns the bonus damage done by a critical hit
    // @param base_damage: the base damage done by the attacker
    // @param adventurer_luck: the luck of the adventurer
    // @param adventurer_entropy: the adventurer's entropy
    // @param game_entropy: the game's entropy
    // @return u16: the bonus damage done by a critical hit
    // @dev from a randomness perspective, the thing to keep in mind with critical hits is that
    //      we need the outcome to be fixed so that bots can't simulate txs and wait for favorable
    //      outcomes but we need this to change with each attack. The solution is to use the advneturers 
    //      health as an extra source of entropy as this will be fixed for each attack but will change
    //      after each attack.
    fn get_critical_hit_damage_bonus(
        base_damage: u16,
        adventurer_luck: u8,
        adventurer_health: u16,
        adventurer_entropy: u64,
        game_entropy: u64
    ) -> u16 {
        // check if the attack is a critical hit
        let is_critical_hit = CombatUtils::is_critical_hit(
            adventurer_luck, adventurer_health, adventurer_entropy, game_entropy
        );

        // if the attack is a critical hit
        if (is_critical_hit == true) {
            // divide base damage by 4 to get 25% of original damage
            let damage_boost_base = base_damage / 4;

            // critical hit random number is adventurer entropy + game entropy + base_damage
            let rnd = adventurer_entropy + game_entropy + U16IntoU64::into(adventurer_health);

            // damage multplier is 1-4 which will equate to a 25-100% damage boost
            let damage_multplier = U64TryIntoU16::try_into(rnd % 4).unwrap();

            // multiply base damage boost (25% of original damage) by damage multiplier (1-4)
            return damage_boost_base * (damage_multplier + 1);
        }
        // otherwise return 0
        0
    }

    fn get_name_prefix_damage_bonus(
        base_damage: u16,
        weapon_name: CombatItemName,
        armor_name: CombatItemName,
        adventurer_entropy: u64,
        game_entropy: u64
    ) -> u16 {
        // is the weapon does not have a prefix
        if (weapon_name.prefix == 0) {
            // return zero
            return 0;
        // if the weapon prefix is the same as the armor prefix
        } else if (weapon_name.prefix == armor_name.prefix) {
            let damage_multplier = U64TryIntoU16::try_into((adventurer_entropy + game_entropy) % 4)
                .unwrap();

            // result will be base damage * (4-7) which will equate to a 4-7x damage bonus
            return base_damage * (damage_multplier + 4);
        }

        // fall through return zero
        0
    }

    fn get_name_suffix_damage_bonus(
        base_damage: u16,
        weapon_name: CombatItemName,
        armor_name: CombatItemName,
        adventurer_entropy: u64,
        game_entropy: u64
    ) -> u16 {
        // is the weapon does not have a prefix
        if (weapon_name.suffix == 0) {
            // return zero
            return 0;
        // if the weapon prefix is the same as the armor prefix
        } else if (weapon_name.suffix == armor_name.suffix) {
            // divide base damage by 4 to get 25% of original damage
            let damage_boost_base = base_damage / 4;

            // damage multplier is 1-4 which will equate to a 25-100% damage boost
            let damage_multplier = U64TryIntoU16::try_into((adventurer_entropy + game_entropy) % 4)
                .unwrap();

            // multiply base damage boost (25% of original damage) by damage multiplier (1-4)
            return damage_boost_base * (damage_multplier + 1);
        }

        // fall through return zero
        0
    }

    // get_special_name_damage_bonus returns the bonus damage for special item
    // @param base_damage: the base damage done by the attacker
    // @param weapon_name: the name of the weapon used by the attacker
    // @param armor_name: the name of the armor worn by the defender
    // @param adventurer_entropy: the adventurer's entropy
    // @param game_entropy: the game's entropy
    // @return u16: the bonus damage done by a special item
    fn get_special_name_damage_bonus(
        base_damage: u16,
        weapon_name: CombatItemName,
        armor_name: CombatItemName,
        adventurer_entropy: u64,
        game_entropy: u64
    ) -> u16 {
        let name_prefix_bonus = CombatUtils::get_name_prefix_damage_bonus(
            base_damage, weapon_name, armor_name, adventurer_entropy, game_entropy
        );

        let name_suffix_bonus = CombatUtils::get_name_suffix_damage_bonus(
            base_damage, weapon_name, armor_name, adventurer_entropy, game_entropy
        );

        // return the sum of the name prefix and name suffix bonuses
        return name_prefix_bonus + name_suffix_bonus;
    }

    // get_adventurer_strength_bonus returns the bonus damage for adventurer strength
    // @param adventurer: the adventurer
    // @param original_damage: the original damage done by the attacker
    // @return u16: the bonus damage done by adventurer strength
    fn get_adventurer_strength_bonus(adventurer: Adventurer, original_damage: u16) -> u16 {
        // each strength stat point is worth 10% of the original damage
        let strength_boost = original_damage * (90 + (U8IntoU16::into(adventurer.strength) * 10));
        let strength_bonus_damage = strength_boost / 100;
        return strength_bonus_damage;
    }
}

#[test]
#[available_gas(200000)]
fn test_get_critical_hit_damage_bonus() {
    // no critical hit
    let mut adventurer_luck = 40;
    let mut adventurer_health = 0;
    let mut adventurer_entropy = 3;
    let mut game_entropy = 0;
    let mut base_damage = 100;
    let critical_hit_damage_bonus = CombatUtils::get_critical_hit_damage_bonus(
        base_damage, adventurer_luck, adventurer_health, adventurer_entropy, game_entropy
    );
    assert(critical_hit_damage_bonus == 0, 'should be 0 crit hit bonus');

    // critical hit low damage
    adventurer_luck = 0;
    adventurer_health = 0;
    adventurer_entropy = 0;
    game_entropy = 0;
    base_damage = 100;
    let critical_hit_damage_bonus = CombatUtils::get_critical_hit_damage_bonus(
        base_damage, adventurer_luck, adventurer_health, adventurer_entropy, game_entropy
    );
    assert(critical_hit_damage_bonus == 25, 'should be 25 crit hit bonus');

    // Medium high damage
    adventurer_luck = 40;
    adventurer_health = 0;
    adventurer_entropy = 2;
    game_entropy = 0;
    base_damage = 100;
    let critical_hit_damage_bonus = CombatUtils::get_critical_hit_damage_bonus(
        base_damage, adventurer_luck, adventurer_health, adventurer_entropy, game_entropy
    );
    assert(critical_hit_damage_bonus == 75, 'should be 75 crit hit bonus');
}


#[test]
#[available_gas(80000)]
fn test_is_critical_hit() {
    // in order to produce a critical hit, we need the remainder of 
    // the summation of entropy and (6 - critical_hit_chance) to be 0
    // where critical_hit_chance is adventurer_luck / 10

    // an easy way to simulate this outcome is to use
    // all zero for entropy, adventurer_luck, and adventurer_health
    let mut adventurer_luck = 0;
    let mut adventurer_health = 0;
    let adventurer_entropy = 0;
    let game_entropy = 0;
    let is_critical_hit = CombatUtils::is_critical_hit(
        adventurer_luck, adventurer_health, adventurer_entropy, game_entropy
    );
    assert(is_critical_hit, 'should be critical hit');

    // by reducing adventurer health to 3, we should no longer get a critical hit
    // because we'll be doing 3 % 8 which is 2 and not 0
    adventurer_health = 3;
    let is_critical_hit = CombatUtils::is_critical_hit(
        adventurer_luck, adventurer_health, adventurer_entropy, game_entropy
    );
    assert(!is_critical_hit, 'should not be critical hit');

    // next we increase adventurer luck to max of 40 which will result
    // in critical hit being the remainder of entropy / 2 which is a 50% chance
    adventurer_luck = 40;

    // entropy is currently still 3 however (just health) so we should not get a critical hit
    let is_critical_hit = CombatUtils::is_critical_hit(
        adventurer_luck, adventurer_health, adventurer_entropy, game_entropy
    );
    assert(!is_critical_hit, 'should not be critical hit');

    // by increasing adventurer health to 4 we increase total entropy to 4
    // which will result in a 0 remainder and a critical hit
    adventurer_health = 4;
    let is_critical_hit = CombatUtils::is_critical_hit(
        adventurer_luck, adventurer_health, adventurer_entropy, game_entropy
    );
    assert(is_critical_hit, 'should be critical hit');
}

#[test]
#[available_gas(40000)]
fn test_get_weapon_effectiveness() {
    let weapon_type = Type::Weapon::Magic;
    let armor_type = Type::Armor::Metal;
    let effectiveness = CombatUtils::get_weapon_effectiveness(weapon_type, armor_type);
    assert(effectiveness == WeaponEffectiveness::Strong(()), 'magic is strong against metal');

    let weapon_type = Type::Weapon::Magic;
    let armor_type = Type::Armor::Cloth;
    let effectiveness = CombatUtils::get_weapon_effectiveness(weapon_type, armor_type);
    assert(effectiveness == WeaponEffectiveness::Fair(()), 'magic is fair against cloth');

    let weapon_type = Type::Weapon::Magic;
    let armor_type = Type::Armor::Hide;
    let effectiveness = CombatUtils::get_weapon_effectiveness(weapon_type, armor_type);
    assert(effectiveness == WeaponEffectiveness::Weak(()), 'magic is weak against cloth');

    let weapon_type = Type::Weapon::Blade;
    let armor_type = Type::Armor::Cloth;
    let effectiveness = CombatUtils::get_weapon_effectiveness(weapon_type, armor_type);
    assert(effectiveness == WeaponEffectiveness::Strong(()), 'blade is strong against cloth');

    let weapon_type = Type::Weapon::Blade;
    let armor_type = Type::Armor::Hide;
    let effectiveness = CombatUtils::get_weapon_effectiveness(weapon_type, armor_type);
    assert(effectiveness == WeaponEffectiveness::Fair(()), 'blade is fair against hide');

    let weapon_type = Type::Weapon::Blade;
    let armor_type = Type::Armor::Metal;
    let effectiveness = CombatUtils::get_weapon_effectiveness(weapon_type, armor_type);
    assert(effectiveness == WeaponEffectiveness::Weak(()), 'blade is weak against metal');

    let weapon_type = Type::Weapon::Bludgeon;
    let armor_type = Type::Armor::Hide;
    let effectiveness = CombatUtils::get_weapon_effectiveness(weapon_type, armor_type);
    assert(effectiveness == WeaponEffectiveness::Strong(()), 'bludgeon is strong against hide');

    let weapon_type = Type::Weapon::Bludgeon;
    let armor_type = Type::Armor::Metal;
    let effectiveness = CombatUtils::get_weapon_effectiveness(weapon_type, armor_type);
    assert(effectiveness == WeaponEffectiveness::Fair(()), 'bludgeon is fair against metal');

    let weapon_type = Type::Weapon::Bludgeon;
    let armor_type = Type::Armor::Cloth;
    let effectiveness = CombatUtils::get_weapon_effectiveness(weapon_type, armor_type);
    assert(effectiveness == WeaponEffectiveness::Weak(()), 'bludgeon is weak against cloth');
}

#[test]
#[available_gas(120000)]
fn test_adjust_damage_for_elemental() {
    // init weapons
    let magic_weapon = Type::Weapon::Magic;
    let blade_weapon = Type::Weapon::Blade;
    let bludgeon_weapon = Type::Weapon::Bludgeon;

    // init armor
    let metal_armor = Type::Armor::Metal;
    let cloth_armor = Type::Armor::Cloth;
    let hide_armor = Type::Armor::Hide;

    // use 100 damage for easy math
    let base_damage = 100;

    // Magic deals +50% against metal
    let elemental_damage_bonus = CombatUtils::adjust_damage_for_elemental(
        base_damage, magic_weapon, metal_armor
    );
    assert(elemental_damage_bonus == base_damage + 50, 'magic is strong against metal');

    // Magic deals +0% against cloth
    let elemental_damage_bonus = CombatUtils::adjust_damage_for_elemental(
        base_damage, magic_weapon, cloth_armor
    );
    assert(elemental_damage_bonus == base_damage, 'magic is neutral vs cloth');

    // Magic deals -50% against hide
    let elemental_damage_bonus = CombatUtils::adjust_damage_for_elemental(
        base_damage, magic_weapon, hide_armor
    );
    assert(elemental_damage_bonus == base_damage - 50, 'magic is weak vs hide');

    // Blade deals +50% against cloth
    let elemental_damage_bonus = CombatUtils::adjust_damage_for_elemental(
        base_damage, blade_weapon, cloth_armor
    );
    assert(elemental_damage_bonus == base_damage + 50, 'blade is strong vs cloth');

    // Blade deals +0% against hide
    let elemental_damage_bonus = CombatUtils::adjust_damage_for_elemental(
        base_damage, blade_weapon, hide_armor
    );
    assert(elemental_damage_bonus == base_damage, 'blade is neutral vs hide');

    // Blade deals -50% against metal
    let elemental_damage_bonus = CombatUtils::adjust_damage_for_elemental(
        base_damage, blade_weapon, metal_armor
    );
    assert(elemental_damage_bonus == base_damage - 50, 'blade is weak vs metal');

    // Bludgeon deals +50% against hide
    let elemental_damage_bonus = CombatUtils::adjust_damage_for_elemental(
        base_damage, bludgeon_weapon, hide_armor
    );
    assert(elemental_damage_bonus == base_damage + 50, 'bludgeon is strong vs hide');

    // Bludgeon deals +0% against metal
    let elemental_damage_bonus = CombatUtils::adjust_damage_for_elemental(
        base_damage, bludgeon_weapon, metal_armor
    );
    assert(elemental_damage_bonus == base_damage, 'bludgeon is neutral vs metal');

    // Bludgeon deals -50% against cloth
    let elemental_damage_bonus = CombatUtils::adjust_damage_for_elemental(
        base_damage, bludgeon_weapon, cloth_armor
    );
    assert(elemental_damage_bonus == base_damage - 50, 'bludgeon is weak vs cloth');
}
