use core::option::OptionTrait;
use integer::{U8IntoU16, U16IntoU64, U8IntoU64, U64TryIntoU16};
use core::traits::DivEq;
use super::constants::{WeaponEffectiveness, CombatSettings, WeaponType, ArmorType};
use core::debug::PrintTrait;

// CombatItemSpecialNames contains special names for combat items
#[derive(Drop, Copy)]
struct CombatItemSpecialNames {
    prefix1: u8,
    prefix2: u8,
    suffix: u8,
}

// CombatItem used for both CombatWeapons and CombatArmor
#[derive(Drop, Copy)]
struct CombatItem {
    tier: u16, // using u16 because this is commonly used for combat calculations where u8 is too small
    level: u16, // using u16 because this is commonly used for combat calculations where u8 is too small
    special_names: CombatItemSpecialNames,
}

// CombatWeapon is used for combat calculations
#[derive(Drop, Copy)]
struct CombatWeapon {
    item_type: WeaponType,
    details: CombatItem
}

// CombatArmor is used for combat calculations
#[derive(Drop, Copy)]
struct CombatArmor {
    item_type: ArmorType,
    details: CombatItem,
}

// Combat is a trait that provides functions for calculating damage during on-chain combat
trait Combat {
    fn calculate_damage(
        weapon: CombatWeapon,
        armor: CombatArmor,
        minimum_damage: u16,
        strength_boost: u16,
        is_critical_hit: bool,
        weapon_effectiveness: WeaponEffectiveness,
        entropy: u64,
    ) -> u16;

    fn get_attack_hp(weapon: CombatWeapon) -> u16;
    fn get_armor_hp(armor: CombatArmor) -> u16;

    fn get_weapon_effectiveness(
        weapon_type: WeaponType, armor_type: ArmorType
    ) -> WeaponEffectiveness;
    fn get_elemental_bonus(damage: u16, weapon_effectiveness: WeaponEffectiveness) -> u16;

    fn is_critical_hit(luck: u8, entropy: u64) -> bool;
    fn critical_hit_bonus(damage: u16, entropy: u64) -> u16;

    fn get_name_prefix1_bonus(
        damage: u16, weapon_prefix1: u8, armor_prefix1: u8, entropy: u64, 
    ) -> u16;
    fn get_name_prefix2_bonus(
        base_damage: u16, weapon_prefix2: u8, armor_prefix2: u8, entropy: u64, 
    ) -> u16;
    fn get_name_damage_bonus(
        base_damage: u16,
        weapon_name: CombatItemSpecialNames,
        armor_name: CombatItemSpecialNames,
        entropy: u64
    ) -> u16;

    fn get_strength_bonus(damage: u16, strength: u16) -> u16;
}

// CombatUtils is an implementation of the Combat trait
// It provides functions for calculating combat damage
impl CombatUtils of Combat {
    // calculate_damage calculates the damage done by an entity wielding a weapon against an entity wearing armor
    // @param weapon: the weapon used to attack
    // @param armor: the armor worn by the defender
    // @param minimum_damage: the minimum damage that can be done
    // @param strength_boost: the strength boost of the attacker
    // @param is_critical_hit: whether or not the attack was a critical hit
    // @param weapon_effectiveness: the effectiveness of the weapon against the armor
    // @param entropy: the entropy used to calculate critical hit bonus and name prefix bonus
    // @return u16: the damage done by the attacker
    fn calculate_damage(
        weapon: CombatWeapon,
        armor: CombatArmor,
        minimum_damage: u16,
        strength_boost: u16,
        is_critical_hit: bool,
        weapon_effectiveness: WeaponEffectiveness,
        entropy: u64,
    ) -> u16 {
        // get base damage
        let base_attack_hp = CombatUtils::get_attack_hp(weapon);
        let armor_hp = CombatUtils::get_armor_hp(armor);

        // get elemental adjusted attack
        let elemental_adjusted_attack = CombatUtils::get_elemental_bonus(
            base_attack_hp, weapon_effectiveness
        );

        // if attack was critical hit
        let mut critical_hit_bonus = 0;
        if (is_critical_hit) {
            // add critical hit bonus
            critical_hit_bonus = CombatUtils::critical_hit_bonus(base_attack_hp, entropy);
        }

        // get special name damage bonus
        let name_prefix_bonus = CombatUtils::get_name_damage_bonus(
            base_attack_hp, weapon.details.special_names, armor.details.special_names, entropy
        );

        // get adventurer strength bonus
        let strength_bonus = CombatUtils::get_strength_bonus(base_attack_hp, strength_boost);

        // total attack hit points
        let total_attack = elemental_adjusted_attack
            + critical_hit_bonus
            + name_prefix_bonus
            + strength_bonus;

        // if the total attack is greater than the armor HP plus the minimum damage
        // this is both to prevent underflow of attack-armor but also to ensure
        // that the minimum damage is always done
        if (total_attack > (armor_hp + minimum_damage)) {
            // return total attack
            return total_attack - armor_hp;
        } else {
            // otreturn total attack
            return minimum_damage;
        }
    }

    // get_attack_hp calculates the attack HP of a weapon
    // @param weapon: the weapon used to attack
    // @return u16: the attack HP of the weapon
    fn get_attack_hp(weapon: CombatWeapon) -> u16 {
        return (CombatSettings::LowestItemTierPlusOne - weapon.details.tier) * weapon.details.level;
    }

    // get_armor_hp calculates the armor HP of a piece of armor
    // @param armor: the armor worn by the defender
    // @return u16: the armor HP of the armor
    fn get_armor_hp(armor: CombatArmor) -> u16 {
        return (CombatSettings::LowestItemTierPlusOne - armor.details.tier) * armor.details.level;
    }

    // adjust_damage_for_elemental adjusts the base damage for elemental effects
    // @param damage: the base damage done by the attacker
    // @param weapon_effectiveness: the effectiveness of the weapon against the armor
    // @return u16: the base damage done by the attacker adjusted for elemental effects
    fn get_elemental_bonus(damage: u16, weapon_effectiveness: WeaponEffectiveness) -> u16 {
        // CombatSettings::ElementalDamageBonus determines impact of elemental damage
        // default setting is 2 which results in -50%, 0%, or 50% damage bonus for elemental
        let elemental_damage_effect = damage / CombatSettings::ElementalDamageBonus;

        // adjust base damage based on weapon effectiveness
        match weapon_effectiveness {
            WeaponEffectiveness::Weak(()) => {
                return damage - elemental_damage_effect;
            },
            WeaponEffectiveness::Fair(()) => {
                return damage;
            },
            WeaponEffectiveness::Strong(()) => {
                return damage + elemental_damage_effect;
            }
        }
    }

    // get_weapon_effectiveness returns a WeaponEffectiveness enum indicating the effectiveness of the weapon against the armor
    // the effectiveness is determined by the weapon type and the armor type
    // @param weapon_type: the type of weapon used to attack
    // @param armor_type: the type of armor worn by the defender
    // @return WeaponEffectiveness: the effectiveness of the weapon against the armor
    fn get_weapon_effectiveness(
        weapon_type: WeaponType, armor_type: ArmorType
    ) -> WeaponEffectiveness {
        match weapon_type {
            // Magic is strong against metal, fair against cloth, and weak against hide
            WeaponType::Magic(()) => {
                match armor_type {
                    ArmorType::Cloth(()) => {
                        return WeaponEffectiveness::Fair(());
                    },
                    ArmorType::Hide(()) => {
                        return WeaponEffectiveness::Weak(());
                    },
                    ArmorType::Metal(()) => {
                        return WeaponEffectiveness::Strong(());
                    }
                }
            },
            // Blade is strong against cloth, fair against hide, and weak against metal
            WeaponType::Blade(()) => {
                match armor_type {
                    ArmorType::Cloth(()) => {
                        return WeaponEffectiveness::Strong(());
                    },
                    ArmorType::Hide(()) => {
                        return WeaponEffectiveness::Fair(());
                    },
                    ArmorType::Metal(()) => {
                        return WeaponEffectiveness::Weak(());
                    }
                }
            },
            // Bludgeon is strong against hide, fair against metal, and weak against cloth
            WeaponType::Bludgeon(()) => {
                match armor_type {
                    ArmorType::Cloth(()) => {
                        return WeaponEffectiveness::Weak(());
                    },
                    ArmorType::Hide(()) => {
                        return WeaponEffectiveness::Strong(());
                    },
                    ArmorType::Metal(()) => {
                        return WeaponEffectiveness::Fair(());
                    }
                }
            }
        }
    }

    // is_critical_hit determines if an attack is a critical hit
    // @param luck: the luck of the adventurer
    // @param entropy: the entropy used to create random outcome
    // @return bool: true if the attack is a critical hit, false otherwise
    fn is_critical_hit(luck: u8, entropy: u64) -> bool {
        // maximum luck is governed by CombatSettings::MaxLuckForCriticalHit
        // current setting is 50. With Luck at 50, player has 50% chance of critical hit
        let mut effective_luck = luck;
        if (luck > CombatSettings::MaxLuckForCriticalHit) {
            effective_luck = CombatSettings::MaxLuckForCriticalHit;
        }

        // critical hit chance is whole number of luck / 10
        // so the chance of getting a critical hit increases every 10 luck
        let mut critical_hit_chance: u8 = effective_luck / 10;

        // critical hit random number is modulo the max critical hit chance
        // this will result in a number between 0 and 5
        let critical_hit_outcome = entropy % U8IntoU64::into((6 - critical_hit_chance));

        // if the critical hit random number is 0 (no remainder)
        if (critical_hit_outcome == 0) {
            // return true
            return true;
        } else {
            // otherwise return false
            return false;
        }
    }

    // get_critical_hit_damage_bonus returns the bonus damage done by a critical hit
    // @param base_damage: the base damage done by the attacker
    // @param entropy: entropy for randomizing critical hit damage bonus
    // @return u16: the bonus damage done by a critical hit
    fn critical_hit_bonus(damage: u16, entropy: u64) -> u16 {
        // divide base damage by 4 to get 25% of original damage
        let damage_boost_base = damage / 4;

        // damage multplier is 1-4 which will equate to a 25-100% damage boost
        let damage_multplier = U64TryIntoU16::try_into(entropy % 4).unwrap();

        // multiply base damage boost (25% of original damage) by damage multiplier (1-4)
        return damage_boost_base * (damage_multplier + 1);
    }

    // get_name_prefix1_bonus returns the bonus damage done by a weapon as a result of the first part of its name
    // @param damage: the base damage done by the attacker
    // @param weapon_name: the name of the weapon used to attack
    // @param armor_name: the name of the armor worn by the defender
    // @param entropy: entropy for randomizing name prefix damage bonus
    // @return u16: the bonus damage done by a name prefix
    fn get_name_prefix1_bonus(
        damage: u16, weapon_prefix1: u8, armor_prefix1: u8, entropy: u64, 
    ) -> u16 {
        // is the weapon does not have a prefix
        if (weapon_prefix1 == 0) {
            // return zero
            return 0;
        // if the weapon prefix is the same as the armor prefix
        } else if (weapon_prefix1 == armor_prefix1) {
            let damage_multplier = U64TryIntoU16::try_into(entropy % 4).unwrap();

            // result will be base damage * (4-7) which will equate to a 4-7x damage bonus
            return damage * (damage_multplier + 4);
        }

        // fall through return zero
        0
    }

    // get_name_prefix2_bonus returns the bonus damage done by a weapon as a result of the second part of its name
    // @param base_damage: the base damage done by the attacker
    // @param weapon_name: the name of the weapon used by the attacker
    // @param armor_name: the name of the armor worn by the defender
    // @param entropy: entropy for randomizing name prefix 2 damage bonus
    // @return u16: the bonus damage done by a weapon as a result of the second part of its name
    fn get_name_prefix2_bonus(
        base_damage: u16, weapon_prefix2: u8, armor_prefix2: u8, entropy: u64, 
    ) -> u16 {
        // is the weapon does not have a prefix
        if (weapon_prefix2 == 0) {
            // return zero
            return 0;
        // if the weapon prefix is the same as the armor prefix
        } else if (weapon_prefix2 == armor_prefix2) {
            // divide base damage by 4 to get 25% of original damage
            let damage_boost_base = base_damage / 4;

            // damage multplier is 1-4 which will equate to a 25-100% damage boost
            let damage_multplier = U64TryIntoU16::try_into(entropy % 4).unwrap();

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
    // @param entropy: entropy for randomizing special item damage bonus
    // @return u16: the bonus damage done by a special item
    fn get_name_damage_bonus(
        base_damage: u16,
        weapon_name: CombatItemSpecialNames,
        armor_name: CombatItemSpecialNames,
        entropy: u64
    ) -> u16 {
        let name_prefix1_bonus = CombatUtils::get_name_prefix1_bonus(
            base_damage, weapon_name.prefix1, armor_name.prefix1, entropy
        );

        let name_prefix2_bonus = CombatUtils::get_name_prefix2_bonus(
            base_damage, weapon_name.prefix2, armor_name.prefix2, entropy
        );

        // return the sum of the name prefix and name suffix bonuses
        return name_prefix1_bonus + name_prefix2_bonus;
    }

    // get_adventurer_strength_bonus returns the bonus damage for adventurer strength
    // @param strength: the strength stat of the adventurer
    // @param damage: the original damage done by the attacker
    // @return u16: the bonus damage done by adventurer strength
    fn get_strength_bonus(damage: u16, strength: u16) -> u16 {
        if (strength == 0) {
            // if the adventurer has no strength, return zero
            return 0;
        } else {
            // each strength stat point is worth 20% of the original damage
            return (damage * strength * 20) / 100;
        }
    }
}

#[test]
#[available_gas(170000)]
fn test_get_attack_hp() {
    // Initialize weapon struct
    // for this test we just need item tier and level so we can ignore other properties
    let weapon_special_names = CombatItemSpecialNames { prefix1: 0, prefix2: 0, suffix: 0,  };
    let weapon_definition = CombatItem { tier: 5, level: 0, special_names: weapon_special_names };
    let mut weapon = CombatWeapon { item_type: WeaponType::Blade(()), details: weapon_definition };

    // T5 Level 0 Weapon Deals 0HP of Damage
    weapon.details.tier = 5;
    weapon.details.level = 0;
    let attack_hp = CombatUtils::get_attack_hp(weapon);
    assert(attack_hp == 0, 'T5 LVL0 should deal 0HP');

    // T5 Level 1 Weapon Deals 1HP of Damage
    weapon.details.tier = 5;
    weapon.details.level = 1;
    let attack_hp = CombatUtils::get_attack_hp(weapon);
    assert(attack_hp == 1, 'T5 LVL1 should deal 1HP');

    // T5 Level 2 Weapon Deals 1HP of Damage
    weapon.details.tier = 5;
    weapon.details.level = 2;
    let attack_hp = CombatUtils::get_attack_hp(weapon);
    assert(attack_hp == 2, 'T5 LVL2 should deal 2HP');

    // T5 Level 20 Weapon Deals 20HP of Damage
    weapon.details.tier = 5;
    weapon.details.level = 20;
    let attack_hp = CombatUtils::get_attack_hp(weapon);
    assert(attack_hp == 20, 'T5 LVL20 should deal 20HP');

    // T4 Level 0 Weapon Deals 0HP of Damage
    weapon.details.tier = 4;
    weapon.details.level = 0;
    let attack_hp = CombatUtils::get_attack_hp(weapon);
    assert(attack_hp == 0, 'T4 LVL0 should deal 0HP');

    // T4 Level 1 Weapon Deals 2HP of Damage
    weapon.details.tier = 4;
    weapon.details.level = 1;
    let attack_hp = CombatUtils::get_attack_hp(weapon);
    assert(attack_hp == 2, 'T4 LVL1 should deal 2HP');

    // T4 Level 2 Weapon Deals 4HP of Damage
    weapon.details.tier = 4;
    weapon.details.level = 2;
    let attack_hp = CombatUtils::get_attack_hp(weapon);
    assert(attack_hp == 4, 'T4 LVL2 should deal 4HP');

    // T4 Level 20 Weapon Deals 40HP of Damage
    weapon.details.tier = 4;
    weapon.details.level = 20;
    let attack_hp = CombatUtils::get_attack_hp(weapon);
    assert(attack_hp == 40, 'T4 LVL20 should deal 40HP');

    // T3 Level 0 Weapon Deals 0HP of Damage
    weapon.details.tier = 3;
    weapon.details.level = 0;
    let attack_hp = CombatUtils::get_attack_hp(weapon);
    assert(attack_hp == 0, 'T3 LVL0 should deal 0HP');

    // T3 Level 1 Weapon Deals 3HP of Damage
    weapon.details.tier = 3;
    weapon.details.level = 1;
    let attack_hp = CombatUtils::get_attack_hp(weapon);
    assert(attack_hp == 3, 'T3 LVL1 should deal 3HP');

    // T3 Level 2 Weapon Deals 6HP of Damage
    weapon.details.tier = 3;
    weapon.details.level = 2;
    let attack_hp = CombatUtils::get_attack_hp(weapon);
    assert(attack_hp == 6, 'T3 LVL2 should deal 6HP');

    // T3 Level 20 Weapon Deals 60HP of Damage
    weapon.details.tier = 3;
    weapon.details.level = 20;
    let attack_hp = CombatUtils::get_attack_hp(weapon);
    assert(attack_hp == 60, 'T3 LVL20 should deal 60HP');

    // T2 Level 0 Weapon Deals 0HP of Damage
    weapon.details.tier = 2;
    weapon.details.level = 0;
    let attack_hp = CombatUtils::get_attack_hp(weapon);
    assert(attack_hp == 0, 'T2 LVL0 should deal 0HP');

    // T2 Level 1 Weapon Deals 4HP of Damage
    weapon.details.tier = 2;
    weapon.details.level = 1;
    let attack_hp = CombatUtils::get_attack_hp(weapon);
    assert(attack_hp == 4, 'T2 LVL1 should deal 4HP');

    // T2 Level 2 Weapon Deals 8HP of Damage
    weapon.details.tier = 2;
    weapon.details.level = 2;
    let attack_hp = CombatUtils::get_attack_hp(weapon);
    assert(attack_hp == 8, 'T2 LVL2 should deal 8HP');

    // T2 Level 20 Weapon Deals 80HP of Damage
    weapon.details.tier = 2;
    weapon.details.level = 20;
    let attack_hp = CombatUtils::get_attack_hp(weapon);
    assert(attack_hp == 80, 'T2 LVL20 should deal 80HP');

    // T1 Level 0 Weapon Deals 0HP of Damage
    weapon.details.tier = 1;
    weapon.details.level = 0;
    let attack_hp = CombatUtils::get_attack_hp(weapon);
    assert(attack_hp == 0, 'T1 LVL0 should deal 0HP');

    // T1 Level 1 Weapon Deals 5HP of Damage
    weapon.details.tier = 1;
    weapon.details.level = 1;
    let attack_hp = CombatUtils::get_attack_hp(weapon);
    assert(attack_hp == 5, 'T1 LVL1 should deal 5HP');

    // T1 Level 2 Weapon Deals 10HP of Damage
    weapon.details.tier = 1;
    weapon.details.level = 2;
    let attack_hp = CombatUtils::get_attack_hp(weapon);
    assert(attack_hp == 10, 'T1 LVL2 should deal 10HP');

    // T1 Level 20 Weapon Deals 100HP of Damage
    weapon.details.tier = 1;
    weapon.details.level = 20;
    let attack_hp = CombatUtils::get_attack_hp(weapon);
    assert(attack_hp == 100, 'T1 LVL20 should deal 100HP');
}

#[test]
#[available_gas(170000)]
fn test_get_armor_hp() {
    // T1 Level 20 Armor
    let armor_special_names = CombatItemSpecialNames { prefix1: 0, prefix2: 0, suffix: 0,  };
    let armor_details = CombatItem { tier: 1, level: 20, special_names: armor_special_names };
    let mut armor = CombatArmor { item_type: ArmorType::Hide(()), details: armor_details };

    // T5 Level 0 Weapon Deals 0HP of Damage
    armor.details.tier = 5;
    armor.details.level = 0;
    let attack_hp = CombatUtils::get_armor_hp(armor);
    assert(attack_hp == 0, 'T5 LVL0 should deal 0HP');

    // T5 Level 1 Weapon Deals 1HP of Damage
    armor.details.tier = 5;
    armor.details.level = 1;
    let attack_hp = CombatUtils::get_armor_hp(armor);
    assert(attack_hp == 1, 'T5 LVL1 should deal 1HP');

    // T5 Level 2 Weapon Deals 1HP of Damage
    armor.details.tier = 5;
    armor.details.level = 2;
    let attack_hp = CombatUtils::get_armor_hp(armor);
    assert(attack_hp == 2, 'T5 LVL2 should deal 2HP');

    // T5 Level 20 Weapon Deals 20HP of Damage
    armor.details.tier = 5;
    armor.details.level = 20;
    let attack_hp = CombatUtils::get_armor_hp(armor);
    assert(attack_hp == 20, 'T5 LVL20 should deal 20HP');

    // T4 Level 0 Armor Provides 0HP
    armor.details.tier = 4;
    armor.details.level = 0;
    let armor_hp = CombatUtils::get_armor_hp(armor);
    assert(armor_hp == 0, 'T4 LVL0 should provide 0HP');

    // T4 Level 1 Armor Provides 2HP
    armor.details.tier = 4;
    armor.details.level = 1;
    let armor_hp = CombatUtils::get_armor_hp(armor);
    assert(armor_hp == 2, 'T4 LVL1 should provide 2HP');

    // T4 Level 2 Armor Provides 4HP
    armor.details.tier = 4;
    armor.details.level = 2;
    let armor_hp = CombatUtils::get_armor_hp(armor);
    assert(armor_hp == 4, 'T4 LVL2 should provide 4HP');

    // T4 Level 20 Armor Provides 40HP
    armor.details.tier = 4;
    armor.details.level = 20;
    let armor_hp = CombatUtils::get_armor_hp(armor);
    assert(armor_hp == 40, 'T4 LVL20 should provide 40HP');

    // T3 Level 0 Armor Provides 0HP
    armor.details.tier = 3;
    armor.details.level = 0;
    let armor_hp = CombatUtils::get_armor_hp(armor);
    assert(armor_hp == 0, 'T3 LVL0 should provide 0HP');

    // T3 Level 1 Armor Provides 3HP
    armor.details.tier = 3;
    armor.details.level = 1;
    let armor_hp = CombatUtils::get_armor_hp(armor);
    assert(armor_hp == 3, 'T3 LVL1 should provide 3HP');

    // T3 Level 2 Armor Provides 6HP
    armor.details.tier = 3;
    armor.details.level = 2;
    let armor_hp = CombatUtils::get_armor_hp(armor);
    assert(armor_hp == 6, 'T3 LVL2 should provide 6HP');

    // T3 Level 20 Armor Provides 60HP
    armor.details.tier = 3;
    armor.details.level = 20;
    let armor_hp = CombatUtils::get_armor_hp(armor);
    assert(armor_hp == 60, 'T3 LVL20 should provide 60HP');

    // T2 Level 0 Armor Provides 0HP
    armor.details.tier = 2;
    armor.details.level = 0;
    let armor_hp = CombatUtils::get_armor_hp(armor);
    assert(armor_hp == 0, 'T2 LVL0 should provide 0HP');

    // T2 Level 1 Armor Provides 4HP
    armor.details.tier = 2;
    armor.details.level = 1;
    let armor_hp = CombatUtils::get_armor_hp(armor);
    assert(armor_hp == 4, 'T2 LVL1 should provide 4HP');

    // T2 Level 2 Armor Provides 8HP
    armor.details.tier = 2;
    armor.details.level = 2;
    let armor_hp = CombatUtils::get_armor_hp(armor);
    assert(armor_hp == 8, 'T2 LVL2 should provide 8HP');

    // T2 Level 20 Armor Provides 80HP
    armor.details.tier = 2;
    armor.details.level = 20;
    let armor_hp = CombatUtils::get_armor_hp(armor);
    assert(armor_hp == 80, 'T2 LVL20 should provide 80HP');

    // T1 Level 0 Armor Provides 0HP
    armor.details.tier = 1;
    armor.details.level = 0;
    let armor_hp = CombatUtils::get_armor_hp(armor);
    assert(armor_hp == 0, 'T1 LVL0 should provide 0HP');

    // T1 Level 1 Armor Provides 5HP
    armor.details.tier = 1;
    armor.details.level = 1;
    let armor_hp = CombatUtils::get_armor_hp(armor);
    assert(armor_hp == 5, 'T1 LVL1 should provide 5HP');

    // T1 Level 2 Armor Provides 10HP
    armor.details.tier = 1;
    armor.details.level = 2;
    let armor_hp = CombatUtils::get_armor_hp(armor);
    assert(armor_hp == 10, 'T1 LVL2 should provide 10HP');

    // T1 Level 20 Armor Provides 100HP
    armor.details.tier = 1;
    armor.details.level = 20;
    let armor_hp = CombatUtils::get_armor_hp(armor);
    assert(armor_hp == 100, 'T1 LVL20 should provide 100HP');
}

#[test]
#[available_gas(90000)]
fn test_critical_hit_bonus() {
    let base_damage = 100;

    // low critical hit damage (25)
    let mut entropy = 0;
    let critical_hit_damage_bonus = CombatUtils::critical_hit_bonus(base_damage, entropy);
    assert(critical_hit_damage_bonus == 25, 'should be 25hp bonus');

    // medium-low critical hit damage (50)
    entropy = 1;
    let critical_hit_damage_bonus = CombatUtils::critical_hit_bonus(base_damage, entropy);
    assert(critical_hit_damage_bonus == 50, 'should be 50 crit hit bonus');

    // medium-high critical hit damage (75)
    entropy = 2;
    let critical_hit_damage_bonus = CombatUtils::critical_hit_bonus(base_damage, entropy);
    assert(critical_hit_damage_bonus == 75, 'should be 75 crit hit bonus');

    // high critical hit damage (100)
    entropy = 3;
    let critical_hit_damage_bonus = CombatUtils::critical_hit_bonus(base_damage, entropy);
    assert(critical_hit_damage_bonus == 100, 'should be 100 crit hit bonus');
}

#[test]
#[available_gas(90000)]
fn test_is_critical_hit() {
    // no entropy or luck is a critical hit
    let mut luck = 0;
    let mut entropy = 0;
    let is_critical_hit = CombatUtils::is_critical_hit(luck, entropy);
    assert(is_critical_hit, 'should be critical hit');

    // no luck with 1 entropy is not a critical hit
    luck = 0;
    entropy = 2;
    let is_critical_hit = CombatUtils::is_critical_hit(luck, entropy);
    assert(!is_critical_hit, 'should not be critical hit');

    // same entropy but with max luck is a critical hit
    luck = 40;
    entropy = 2;
    let is_critical_hit = CombatUtils::is_critical_hit(luck, entropy);
    assert(is_critical_hit, 'should be critical hit');

    // test max luck does not overflow and can critical hit
    luck = 255;
    entropy = 0;
    let is_critical_hit = CombatUtils::is_critical_hit(luck, entropy);
    assert(is_critical_hit, 'should be critical hit');

    // test max luck can miss critical hit
    luck = 255;
    entropy = 1;
    let is_critical_hit = CombatUtils::is_critical_hit(luck, entropy);
    assert(!is_critical_hit, 'should not be critical hit');
}

#[test]
#[available_gas(40000)]
fn test_get_weapon_effectiveness() {
    let weapon_type = WeaponType::Magic(());
    let armor_type = ArmorType::Metal(());
    let effectiveness = CombatUtils::get_weapon_effectiveness(weapon_type, armor_type);
    assert(effectiveness == WeaponEffectiveness::Strong(()), 'magic is strong against metal');

    let weapon_type = WeaponType::Magic(());
    let armor_type = ArmorType::Cloth(());
    let effectiveness = CombatUtils::get_weapon_effectiveness(weapon_type, armor_type);
    assert(effectiveness == WeaponEffectiveness::Fair(()), 'magic is fair against cloth');

    let weapon_type = WeaponType::Magic(());
    let armor_type = ArmorType::Hide(());
    let effectiveness = CombatUtils::get_weapon_effectiveness(weapon_type, armor_type);
    assert(effectiveness == WeaponEffectiveness::Weak(()), 'magic is weak against cloth');

    let weapon_type = WeaponType::Blade(());
    let armor_type = ArmorType::Cloth(());
    let effectiveness = CombatUtils::get_weapon_effectiveness(weapon_type, armor_type);
    assert(effectiveness == WeaponEffectiveness::Strong(()), 'blade is strong against cloth');

    let weapon_type = WeaponType::Blade(());
    let armor_type = ArmorType::Hide(());
    let effectiveness = CombatUtils::get_weapon_effectiveness(weapon_type, armor_type);
    assert(effectiveness == WeaponEffectiveness::Fair(()), 'blade is fair against hide');

    let weapon_type = WeaponType::Blade(());
    let armor_type = ArmorType::Metal(());
    let effectiveness = CombatUtils::get_weapon_effectiveness(weapon_type, armor_type);
    assert(effectiveness == WeaponEffectiveness::Weak(()), 'blade is weak against metal');

    let weapon_type = WeaponType::Bludgeon(());
    let armor_type = ArmorType::Hide(());
    let effectiveness = CombatUtils::get_weapon_effectiveness(weapon_type, armor_type);
    assert(effectiveness == WeaponEffectiveness::Strong(()), 'bludgeon is strong against hide');

    let weapon_type = WeaponType::Bludgeon(());
    let armor_type = ArmorType::Metal(());
    let effectiveness = CombatUtils::get_weapon_effectiveness(weapon_type, armor_type);
    assert(effectiveness == WeaponEffectiveness::Fair(()), 'bludgeon is fair against metal');

    let weapon_type = WeaponType::Bludgeon(());
    let armor_type = ArmorType::Cloth(());
    let effectiveness = CombatUtils::get_weapon_effectiveness(weapon_type, armor_type);
    assert(effectiveness == WeaponEffectiveness::Weak(()), 'bludgeon is weak against cloth');
}

#[test]
#[available_gas(130000)]
fn test_get_elemental_bonus() {
    // use 100 damage for easy math
    let base_damage = 100;

    // Magic deals +50% against metal
    let elemental_damage_bonus = CombatUtils::get_elemental_bonus(
        base_damage, WeaponEffectiveness::Strong(())
    );
    assert(elemental_damage_bonus == base_damage + 50, 'strong bonus should be +50%');

    // Magic deals +0% against cloth
    let elemental_damage_bonus = CombatUtils::get_elemental_bonus(
        base_damage, WeaponEffectiveness::Fair(())
    );
    assert(elemental_damage_bonus == base_damage, 'fair bonus should be +0%');

    // Magic deals -50% against hide
    let elemental_damage_bonus = CombatUtils::get_elemental_bonus(
        base_damage, WeaponEffectiveness::Weak(())
    );
    assert(elemental_damage_bonus == base_damage - 50, 'weak bonus should be -50%');
}

#[test]
#[available_gas(90000)]
fn test_get_name_prefix1_bonus() {
    let base_damage = 100;
    let mut entropy = 0;

    let mut weapon_special_names = CombatItemSpecialNames { prefix1: 0, prefix2: 0, suffix: 0,  };
    let mut armor_special_names = CombatItemSpecialNames { prefix1: 0, prefix2: 0, suffix: 0,  };

    // weapon without special name should have no bonus
    let name_prefix1_bonus = CombatUtils::get_name_prefix1_bonus(
        base_damage, weapon_special_names.prefix1, armor_special_names.prefix1, entropy
    );
    assert(name_prefix1_bonus == 0, 'should be no bonus');

    // assign armor a prefix1 name and ensure lack of weapon special name still results in no bonus
    armor_special_names.prefix1 = 1;
    let name_prefix1_bonus = CombatUtils::get_name_prefix1_bonus(
        base_damage, weapon_special_names.prefix1, armor_special_names.prefix1, entropy
    );
    assert(name_prefix1_bonus == 0, 'should be no bonus');

    // give weapon matching prefix1 to qualify it for bonus
    // actual amount (4x-7x) will depend on entropy
    // entropy 0: 4x
    weapon_special_names.prefix1 = 1;
    let name_prefix1_bonus = CombatUtils::get_name_prefix1_bonus(
        base_damage, weapon_special_names.prefix1, armor_special_names.prefix1, entropy
    );
    assert(name_prefix1_bonus == 400, 'should be +400hp bonus');

    // entropy 1: 5x
    entropy = 1;
    let name_prefix1_bonus = CombatUtils::get_name_prefix1_bonus(
        base_damage, weapon_special_names.prefix1, armor_special_names.prefix1, entropy
    );
    assert(name_prefix1_bonus == 500, 'should be +500hp bonus');

    // entropy 2: 6x
    entropy = 2;
    let name_prefix1_bonus = CombatUtils::get_name_prefix1_bonus(
        base_damage, weapon_special_names.prefix1, armor_special_names.prefix1, entropy
    );
    assert(name_prefix1_bonus == 600, 'should be +600hp bonus');

    // entropy 3: 7x
    entropy = 3;
    let name_prefix1_bonus = CombatUtils::get_name_prefix1_bonus(
        base_damage, weapon_special_names.prefix1, armor_special_names.prefix1, entropy
    );
    assert(name_prefix1_bonus == 700, 'should be +700hp bonus');
}

#[test]
#[available_gas(130000)]
fn test_get_name_prefix2_bonus() {
    let base_damage = 100;
    let mut entropy = 0;

    let mut weapon_special_names = CombatItemSpecialNames { prefix1: 0, prefix2: 0, suffix: 0,  };
    let mut armor_special_names = CombatItemSpecialNames { prefix1: 0, prefix2: 0, suffix: 0,  };

    // weapon without special name should have no bonus
    let name_prefix2_bonus = CombatUtils::get_name_prefix2_bonus(
        base_damage, weapon_special_names.prefix2, armor_special_names.prefix2, entropy
    );
    assert(name_prefix2_bonus == 0, 'no prefix2 == no bonus');

    // assign armor a prefix2 name and ensure lack of weapon special name still results in no bonus
    armor_special_names.prefix2 = 1;
    let name_prefix2_bonus = CombatUtils::get_name_prefix2_bonus(
        base_damage, weapon_special_names.prefix2, armor_special_names.prefix2, entropy
    );
    assert(name_prefix2_bonus == 0, 'no prefix2 == no bonus');

    // give weapon matching prefix2 to qualify it for bonus
    // actual amount (25% - 100%) will depend on entropy
    // entropy 0: 25%
    weapon_special_names.prefix2 = 1;
    let name_prefix2_bonus = CombatUtils::get_name_prefix2_bonus(
        base_damage, weapon_special_names.prefix2, armor_special_names.prefix2, entropy
    );
    assert(name_prefix2_bonus == 25, 'should be +25hp bonus');

    // entropy 1: 50%
    entropy = 1;
    let name_prefix2_bonus = CombatUtils::get_name_prefix2_bonus(
        base_damage, weapon_special_names.prefix2, armor_special_names.prefix2, entropy
    );
    assert(name_prefix2_bonus == 50, 'should be +50hp bonus');

    // entropy 2: 75%
    entropy = 2;
    let name_prefix2_bonus = CombatUtils::get_name_prefix2_bonus(
        base_damage, weapon_special_names.prefix2, armor_special_names.prefix2, entropy
    );
    assert(name_prefix2_bonus == 75, 'should be +75hp bonus');

    // entropy 3: 100%
    entropy = 3;
    let name_prefix2_bonus = CombatUtils::get_name_prefix2_bonus(
        base_damage, weapon_special_names.prefix2, armor_special_names.prefix2, entropy
    );
    assert(name_prefix2_bonus == 100, 'should be +100hp bonus');
}

#[test]
#[available_gas(50000)]
fn test_get_strength_bonus() {
    // use 100 base damage for easy math
    let base_damage = 100;

    // start with zero strength which should generate no bonus
    let mut strength = 0;
    let strength_bonus = CombatUtils::get_strength_bonus(base_damage, strength);
    assert(strength_bonus == 0, 'no strength == no bonus');

    // increase strength stat to 1 which should generate 20% bonus
    strength = 1;
    let strength_bonus = CombatUtils::get_strength_bonus(base_damage, strength);
    assert(strength_bonus == 20, '1 strength == 20% bonus');

    // increase strength stat to 2 which should generate 40% bonus
    strength = 2;
    let strength_bonus = CombatUtils::get_strength_bonus(base_damage, strength);
    assert(strength_bonus == 40, '1 strength == 40% bonus');

    // test max strength for loot survivor
    strength = 31;
    let strength_bonus = CombatUtils::get_strength_bonus(base_damage, strength);
    assert(strength_bonus == 620, '31 strength == 620% bonus');
}

#[test]
#[available_gas(1100000)]
fn test_calculate_damage() {
    // initialize weapon
    let weapon_special_names = CombatItemSpecialNames { prefix1: 0, prefix2: 0, suffix: 0,  };
    let weapon_definition = CombatItem { tier: 5, level: 1, special_names: weapon_special_names };
    let mut weapon = CombatWeapon { item_type: WeaponType::Blade(()), details: weapon_definition };

    // initialize armor
    let armor_special_names = CombatItemSpecialNames { prefix1: 0, prefix2: 0, suffix: 0,  };
    let armor_details = CombatItem { tier: 5, level: 1, special_names: armor_special_names };
    let mut armor = CombatArmor { item_type: ArmorType::Cloth(()), details: armor_details };

    // initialize other combat parameters
    // start with simplest values to reduce number of variables to track
    let mut minimum_damage = 0;
    let mut strength_boost = 0;
    let mut is_critical_hit = false;
    let mut weapon_effectiveness = WeaponEffectiveness::Strong(());
    let mut entropy = 0;

    // We'll start by simulating the starter beast battle
    // adventurer selects a T5 Blade (Short Sword) and it'll be greatness/level 1
    weapon.details.tier = 5;
    weapon.details.level = 1;

    // beast is going to be a T5 wearing cloth and it'll be greatness/level 1
    armor.details.tier = 5;
    armor.details.level = 1;

    let damage = CombatUtils::calculate_damage(
        weapon,
        armor,
        minimum_damage,
        strength_boost,
        is_critical_hit,
        weapon_effectiveness,
        entropy
    );

    // adventurer isn't able to deal any damage to the beast (not good)
    assert(damage == 0, 'equally matched: 0HP');

    // client can use minimum damage setting to ensure adventurer always does at least some damage
    minimum_damage = 2;
    let damage = CombatUtils::calculate_damage(
        weapon,
        armor,
        minimum_damage,
        strength_boost,
        is_critical_hit,
        weapon_effectiveness,
        entropy
    );
    assert(damage == 2, 'minimum damage: 2hp');

    // adventurer levels up their weapon to level 3
    // and encounters another T5 beast wearing cloth
    weapon.details.level = 3;
    let damage = CombatUtils::calculate_damage(
        weapon,
        armor,
        minimum_damage,
        strength_boost,
        is_critical_hit,
        weapon_effectiveness,
        entropy
    );

    // they can now deal more than the minimum damage
    assert(damage == 3, 'upgrade to lvl3: 3HP');

    // they then go to the store and upgrade to a Katana (will be level 1)
    weapon.details.tier = 1;
    weapon.details.level = 1;
    let damage = CombatUtils::calculate_damage(
        weapon,
        armor,
        minimum_damage,
        strength_boost,
        is_critical_hit,
        weapon_effectiveness,
        entropy
    );
    // even on level 1, it can deal a lot more damage than the short sword
    assert(damage == 6, 'upgrade to katana: 6HP');

    // enable critical hit for that last attack
    is_critical_hit = true;
    let damage = CombatUtils::calculate_damage(
        weapon,
        armor,
        minimum_damage,
        strength_boost,
        is_critical_hit,
        weapon_effectiveness,
        entropy
    );
    // user picks up a critical hit but gets minimum bonus of 1
    assert(damage == 7, 'critical hit min bonus: 7HP');

    // we can manipulate entropy to get different results
    // entropy 3 will produce max bonus of 100% of the base damage (5)
    entropy = 3;
    let damage = CombatUtils::calculate_damage(
        weapon,
        armor,
        minimum_damage,
        strength_boost,
        is_critical_hit,
        weapon_effectiveness,
        entropy
    );
    assert(damage == 10, 'good critical hit: 10HP');

    // switch to weak elemental
    weapon_effectiveness = WeaponEffectiveness::Weak(());
    let damage = CombatUtils::calculate_damage(
        weapon,
        armor,
        minimum_damage,
        strength_boost,
        is_critical_hit,
        weapon_effectiveness,
        entropy
    );
    // verify damage drops by ~50%
    assert(damage == 6, 'weak elemental penalty: 6HP');

    // adventurer invests in two strength stat points to get a 40% bonus on base damage (5)
    strength_boost = 2;
    // switch to weak elemental
    weapon_effectiveness = WeaponEffectiveness::Weak(());
    let damage = CombatUtils::calculate_damage(
        weapon,
        armor,
        minimum_damage,
        strength_boost,
        is_critical_hit,
        weapon_effectiveness,
        entropy
    );
    // verify damage drops by ~50%
    assert(damage == 8, 'attack should be 9HP');

    // fast forward to late game (G20 Katana)
    weapon.details.level = 20;
    weapon.details.tier = 1;

    // against a Level 30 T3 beast wearing Metal (strong against blade)
    armor.details.level = 40;
    armor.details.tier = 2;
    weapon_effectiveness = WeaponEffectiveness::Weak(());

    let damage = CombatUtils::calculate_damage(
        weapon,
        armor,
        minimum_damage,
        strength_boost,
        is_critical_hit,
        weapon_effectiveness,
        entropy
    );
    assert(damage == 30, 'T1 G20 vs T3 G30: 30hp');

    // Same battle against a magical beast (cloth)
    weapon_effectiveness = WeaponEffectiveness::Strong(());
    let damage = CombatUtils::calculate_damage(
        weapon,
        armor,
        minimum_damage,
        strength_boost,
        is_critical_hit,
        weapon_effectiveness,
        entropy
    );
    // deals significantly more damage because elemental is applied
    // to raw attack damage
    assert(damage == 130, 'T1 G20 vs T3 G30: 130hp');
}
