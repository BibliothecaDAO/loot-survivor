use core::option::OptionTrait;
use integer::{
    U8IntoU16, U16IntoU64, U8IntoU64, U64TryIntoU16, U64TryIntoU8, U8IntoU128, U128TryIntoU8,
    U128TryIntoU16, u16_sqrt
};
use core::traits::{TryInto, Into, DivEq};
use super::constants::{
    CombatEnums::{Tier, Type, Slot, WeaponEffectiveness},
    CombatSettings::{
        XP_MULTIPLIER, DIFFICULTY_CLIFF, XP_REWARD_DIVISOR, WEAPON_TIER_DAMAGE_MULTIPLIER,
        ARMOR_TIER_DAMAGE_MULTIPLIER, ELEMENTAL_DAMAGE_BONUS, STRONG_ELEMENTAL_BONUS_MIN,
        MAX_CRITICAL_HIT_LUCK, LEVEL_MULTIPLIER
    }
};

// SpecialPowers contains special names for combat items
#[derive(Drop, Copy, Serde)]
struct SpecialPowers {
    prefix1: u8,
    prefix2: u8,
    suffix: u8,
}

// CombatSpec is used for combat calculations 
#[derive(Drop, Copy, Serde)]
struct CombatSpec {
    tier: Tier,
    item_type: Type,
    level: u16,
    special_powers: SpecialPowers,
}

// ImplCombat is an implementation of the Combat trait
// It provides functions for calculating combat damage
#[generate_trait]
impl ImplCombat of ICombat {
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
        weapon: CombatSpec,
        armor: CombatSpec,
        minimum_damage: u16,
        strength_boost: u16,
        is_critical_hit: bool,
        entropy: u128,
    ) -> u16 {
        // get base damage
        let base_attack_hp = ImplCombat::get_attack_hp(weapon);
        let armor_hp = ImplCombat::get_armor_hp(armor);

        let weapon_effectiveness = ImplCombat::get_weapon_effectiveness(
            weapon.item_type, armor.item_type
        );

        // get elemental adjusted attack
        let elemental_adjusted_attack = ImplCombat::get_elemental_bonus(
            base_attack_hp, weapon_effectiveness
        );

        // if attack was critical hit
        let mut critical_hit_bonus = 0;
        if (is_critical_hit) {
            // add critical hit bonus
            critical_hit_bonus = ImplCombat::critical_hit_bonus(base_attack_hp, entropy);
        }

        // get special name damage bonus
        let special2_bonus = ImplCombat::get_name_damage_bonus(
            base_attack_hp, weapon.special_powers, armor.special_powers, entropy
        );

        // get adventurer strength bonus
        let strength_bonus = ImplCombat::get_strength_bonus(base_attack_hp, strength_boost);

        // total attack hit points
        let total_attack = elemental_adjusted_attack
            + critical_hit_bonus
            + special2_bonus
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
    fn get_attack_hp(weapon: CombatSpec) -> u16 {
        match weapon.tier {
            Tier::T1(()) => {
                return weapon.level * WEAPON_TIER_DAMAGE_MULTIPLIER::T1;
            },
            Tier::T2(()) => {
                return weapon.level * WEAPON_TIER_DAMAGE_MULTIPLIER::T2;
            },
            Tier::T3(()) => {
                return weapon.level * WEAPON_TIER_DAMAGE_MULTIPLIER::T3;
            },
            Tier::T4(()) => {
                return weapon.level * WEAPON_TIER_DAMAGE_MULTIPLIER::T4;
            },
            Tier::T5(()) => {
                return weapon.level * WEAPON_TIER_DAMAGE_MULTIPLIER::T5;
            }
        }
    }

    // get_armor_hp calculates the armor HP of a piece of armor
    // @param armor: the armor worn by the defender
    // @return u16: the armor HP of the armor
    fn get_armor_hp(armor: CombatSpec) -> u16 {
        match armor.tier {
            Tier::T1(()) => {
                return armor.level * ARMOR_TIER_DAMAGE_MULTIPLIER::T1;
            },
            Tier::T2(()) => {
                return armor.level * ARMOR_TIER_DAMAGE_MULTIPLIER::T2;
            },
            Tier::T3(()) => {
                return armor.level * ARMOR_TIER_DAMAGE_MULTIPLIER::T3;
            },
            Tier::T4(()) => {
                return armor.level * ARMOR_TIER_DAMAGE_MULTIPLIER::T4;
            },
            Tier::T5(()) => {
                return armor.level * ARMOR_TIER_DAMAGE_MULTIPLIER::T5;
            }
        }
    }

    // adjust_damage_for_elemental adjusts the base damage for elemental effects
    // @param damage: the base damage done by the attacker
    // @param weapon_effectiveness: the effectiveness of the weapon against the armor
    // @return u16: the base damage done by the attacker adjusted for elemental effects
    fn get_elemental_bonus(damage: u16, weapon_effectiveness: WeaponEffectiveness) -> u16 {
        // CombatSettings::ELEMENTAL_DAMAGE_BONUS determines impact of elemental damage
        // default setting is 2 which results in -50%, 0%, or 50% damage bonus for elemental
        let elemental_damage_effect = damage / ELEMENTAL_DAMAGE_BONUS;

        // adjust base damage based on weapon effectiveness
        match weapon_effectiveness {
            WeaponEffectiveness::Weak(()) => {
                return damage - elemental_damage_effect;
            },
            WeaponEffectiveness::Fair(()) => {
                return damage;
            },
            WeaponEffectiveness::Strong(()) => {
                let elemental_adjusted_damage = damage + elemental_damage_effect;
                if (elemental_adjusted_damage < STRONG_ELEMENTAL_BONUS_MIN) {
                    return STRONG_ELEMENTAL_BONUS_MIN;
                } else {
                    return elemental_adjusted_damage;
                }
            }
        }
    }

    // get_weapon_effectiveness returns a WeaponEffectiveness enum indicating the effectiveness of the weapon against the armor
    // the effectiveness is determined by the weapon type and the armor type
    // @param weapon_type: the type of weapon used to attack
    // @param armor_type: the type of armor worn by the defender
    // @return WeaponEffectiveness: the effectiveness of the weapon against the armor
    fn get_weapon_effectiveness(weapon_type: Type, armor_type: Type) -> WeaponEffectiveness {
        match weapon_type {
            // Magic is strong against metal, fair against cloth, and weak against hide
            Type::Magic_or_Cloth(()) => {
                match armor_type {
                    Type::Magic_or_Cloth(()) => {
                        return WeaponEffectiveness::Fair(());
                    },
                    Type::Blade_or_Hide(()) => {
                        return WeaponEffectiveness::Weak(());
                    },
                    Type::Bludgeon_or_Metal(()) => {
                        return WeaponEffectiveness::Strong(());
                    },
                    // should not happen but compiler requires exhaustive match
                    Type::Necklace(()) => {
                        return WeaponEffectiveness::Fair(());
                    },
                    // should not happen but compiler requires exhaustive match
                    Type::Ring(()) => {
                        return WeaponEffectiveness::Fair(());
                    }
                }
            },
            // Blade is strong against cloth, fair against hide, and weak against metal
            Type::Blade_or_Hide(()) => {
                match armor_type {
                    Type::Magic_or_Cloth(()) => {
                        return WeaponEffectiveness::Strong(());
                    },
                    Type::Blade_or_Hide(()) => {
                        return WeaponEffectiveness::Fair(());
                    },
                    Type::Bludgeon_or_Metal(()) => {
                        return WeaponEffectiveness::Weak(());
                    },
                    // should not happen but compiler requires exhaustive match
                    Type::Necklace(()) => {
                        return WeaponEffectiveness::Fair(());
                    },
                    // should not happen but compiler requires exhaustive match
                    Type::Ring(()) => {
                        return WeaponEffectiveness::Fair(());
                    }
                }
            },
            // Bludgeon is strong against hide, fair against metal, and weak against cloth
            Type::Bludgeon_or_Metal(()) => {
                match armor_type {
                    Type::Magic_or_Cloth(()) => {
                        return WeaponEffectiveness::Weak(());
                    },
                    Type::Blade_or_Hide(()) => {
                        return WeaponEffectiveness::Strong(());
                    },
                    Type::Bludgeon_or_Metal(()) => {
                        return WeaponEffectiveness::Fair(());
                    },
                    // should not happen but compiler requires exhaustive match
                    Type::Necklace(()) => {
                        return WeaponEffectiveness::Fair(());
                    },
                    // should not happen but compiler requires exhaustive match
                    Type::Ring(()) => {
                        return WeaponEffectiveness::Fair(());
                    }
                }
            },
            Type::Necklace(()) => {
                return WeaponEffectiveness::Fair(());
            },
            Type::Ring(()) => {
                return WeaponEffectiveness::Fair(());
            },
        }
    }

    // is_critical_hit determines if an attack is a critical hit
    // @param luck: the luck of the adventurer
    // @param entropy: the entropy used to create random outcome
    // @return bool: true if the attack is a critical hit, false otherwise
    fn is_critical_hit(luck: u8, entropy: u128) -> bool {
        // maximum luck is governed by CombatSettings::MAX_CRITICAL_HIT_LUCK
        // current setting is 50. With Luck at 50, player has 50% chance of critical hit
        let mut effective_luck = luck;
        if (luck > MAX_CRITICAL_HIT_LUCK) {
            effective_luck = MAX_CRITICAL_HIT_LUCK;
        }

        // critical hit chance is whole number of luck / 10
        // so the chance of getting a critical hit increases every 10 luck
        let mut critical_hit_chance: u8 = effective_luck / 10;

        // critical hit random number is modulo the max critical hit chance
        // this will result in a number between 0 and 5
        let critical_hit_outcome = entropy % U8IntoU128::into((6 - critical_hit_chance));

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
    fn critical_hit_bonus(damage: u16, entropy: u128) -> u16 {
        // divide base damage by 4 to get 25% of original damage
        let damage_boost_base = damage / 4;

        // damage multplier is 1-4 which will equate to a 25-100% damage boost
        let damage_multplier = U128TryIntoU16::try_into(entropy % 4).unwrap();

        // multiply base damage boost (25% of original damage) by damage multiplier (1-4)
        return damage_boost_base * (damage_multplier + 1);
    }

    // get_special21_bonus returns the bonus damage done by a weapon as a result of the first part of its name
    // @param damage: the base damage done by the attacker
    // @param weapon_name: the name of the weapon used to attack
    // @param armor_name: the name of the armor worn by the defender
    // @param entropy: entropy for randomizing name prefix damage bonus
    // @return u16: the bonus damage done by a name prefix
    fn get_special21_bonus(
        damage: u16, weapon_prefix1: u8, armor_prefix1: u8, entropy: u128, 
    ) -> u16 {
        // is the weapon does not have a prefix
        if (weapon_prefix1 == 0) {
            // return zero
            return 0;
        // if the weapon prefix is the same as the armor prefix
        } else if (weapon_prefix1 == armor_prefix1) {
            let damage_multplier = U128TryIntoU16::try_into(entropy % 4).unwrap();

            // result will be base damage * (4-7) which will equate to a 4-7x damage bonus
            return damage * (damage_multplier + 4);
        }

        // fall through return zero
        0
    }

    // get_special22_bonus returns the bonus damage done by a weapon as a result of the second part of its name
    // @param base_damage: the base damage done by the attacker
    // @param weapon_name: the name of the weapon used by the attacker
    // @param armor_name: the name of the armor worn by the defender
    // @param entropy: entropy for randomizing name prefix 2 damage bonus
    // @return u16: the bonus damage done by a weapon as a result of the second part of its name
    fn get_special22_bonus(
        base_damage: u16, weapon_prefix2: u8, armor_prefix2: u8, entropy: u128, 
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
            let damage_multplier = U128TryIntoU16::try_into(entropy % 4).unwrap();

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
        base_damage: u16, weapon_name: SpecialPowers, armor_name: SpecialPowers, entropy: u128
    ) -> u16 {
        let special21_bonus = ImplCombat::get_special21_bonus(
            base_damage, weapon_name.prefix1, armor_name.prefix1, entropy
        );

        let special22_bonus = ImplCombat::get_special22_bonus(
            base_damage, weapon_name.prefix2, armor_name.prefix2, entropy
        );

        // return the sum of the name prefix and name suffix bonuses
        return special21_bonus + special22_bonus;
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

    // get_random_level returns a random level scoped for the adventurere Level
    // @param adventurer_level: the level of the adventurer
    // @param entropy: entropy for randomizing entity level
    // @param range_increase_interval: the interval at which the max level of entitys will increase
    // @param level_multiplier: the multiplier for the entity level
    // @return u8: the random level scoped for the adventurer level
    fn get_random_level(
        adventurer_level: u8, entropy: u128, range_increase_interval: u8, level_multiplier: u8
    ) -> u8 {
        // If adventurer has not exceeded the difficult cliff level
        if (adventurer_level <= range_increase_interval) {
            // return the adventurer level
            return adventurer_level;
        }

        // If adventurer has exceeded the difficult cliff level
        // the entity level will be randomnly scoped around the adventurer level
        // the max level of entitys will increase every N levels based on 
        // the DIFFICULTY_CLIFF setting. The higher this setting, the less frequently the max level will increase
        let entity_level_multplier = 1 + (adventurer_level / range_increase_interval);

        // maximum range of the entity level will be the above multplier * the entity difficulty
        let entity_level_range = U8IntoU128::into(entity_level_multplier * level_multiplier);

        // calculate the entity level 
        let entity_level_boost = entropy % entity_level_range;

        // add the entity level boost to the adventurer level - difficulty cliff
        // this will produce a level between (adventurer level - difficulty cliff) and entity_level_multplier * entity_constants::Settings::entity_LEVEL_RANGE
        let entity_level = entity_level_boost
            + U8IntoU128::into((adventurer_level - entity_level_multplier));

        // return the entity level as a u16
        return U128TryIntoU8::try_into(entity_level).unwrap();
    }

    // get_enemy_starting_health returns the starting health for an entity
    // @param 
    fn get_enemy_starting_health(
        adventurer_level: u8,
        minimum_health: u8,
        entropy: u128,
        range_increase_interval: u8,
        level_multiplier: u8
    ) -> u16 {
        // enemy starting health increases every N adventurer levels
        let health_multiplier = adventurer_level / range_increase_interval;

        // max health is based on adventurer level and the level multplier
        // if the range_increase_interval is 5 for example and the adventurer is on
        // level 20, the max enemy health will be 5 * (level multiplier)
        let max_health = U8IntoU128::into((1 + health_multiplier) * level_multiplier);

        // the remainder of entropy divided by max_health provides entity health
        // we then add 1 to minimum_health to prevent starting health of zero
        return U128TryIntoU16::try_into(
            U8IntoU128::into(adventurer_level + minimum_health) + (entropy % max_health)
        )
            .unwrap();
    }


    // get_level_from_xp returns the level for a given xp
    // @param xp: the xp to get the level for
    // @return u8: the level for the given xp
    fn get_level_from_xp(xp: u16) -> u8 {
        if (xp > 0) {
            return u16_sqrt(xp);
        } else {
            return 1;
        }
    }

    // get_xp_reward returns the xp reward for defeating an entity
    // @param defeated_entity: the entity that was defeated
    // @return u16: the xp reward for defeating the entity
    fn get_xp_reward(self: CombatSpec) -> u16 {
        match self.tier {
            Tier::T1(()) => {
                (XP_MULTIPLIER::T1 * self.level) / XP_REWARD_DIVISOR
            },
            Tier::T2(()) => {
                (XP_MULTIPLIER::T2 * self.level) / XP_REWARD_DIVISOR
            },
            Tier::T3(()) => {
                (XP_MULTIPLIER::T3 * self.level) / XP_REWARD_DIVISOR
            },
            Tier::T4(()) => {
                (XP_MULTIPLIER::T4 * self.level) / XP_REWARD_DIVISOR
            },
            Tier::T5(()) => {
                (XP_MULTIPLIER::T5 * self.level) / XP_REWARD_DIVISOR
            }
        }
    }

    fn get_random_damage_location(entropy: u128, ) -> Slot {
        // generate random damage location based on Item Slot which has
        // armor in slots 2-6 inclusive
        let damage_location = 2 + (entropy % 6);
        return ImplCombat::u8_to_slot(U128TryIntoU8::try_into(damage_location).unwrap());
    }

    fn tier_to_u8(tier: Tier) -> u8 {
        match tier {
            Tier::T1(()) => 1,
            Tier::T2(()) => 2,
            Tier::T3(()) => 3,
            Tier::T4(()) => 4,
            Tier::T5(()) => 5,
        }
    }
    fn type_to_u8(item_type: Type) -> u8 {
        match item_type {
            Type::Magic_or_Cloth(()) => 1,
            Type::Blade_or_Hide(()) => 2,
            Type::Bludgeon_or_Metal(()) => 3,
            Type::Necklace(()) => 4,
            Type::Ring(()) => 5,
        }
    }
    fn u8_to_type(item_type: u8) -> Type {
        if (item_type == 1) {
            return Type::Magic_or_Cloth(());
        } else if (item_type == 2) {
            return Type::Blade_or_Hide(());
        } else if (item_type == 3) {
            return Type::Bludgeon_or_Metal(());
        } else if (item_type == 4) {
            return Type::Necklace(());
        }
        return Type::Ring(());
    }
    fn u8_to_tier(item_type: u8) -> Tier {
        if (item_type == 1) {
            return Tier::T1(());
        } else if (item_type == 2) {
            return Tier::T2(());
        } else if (item_type == 3) {
            return Tier::T3(());
        } else if (item_type == 4) {
            return Tier::T4(());
        }
        return Tier::T5(());
    }
    fn slot_to_u8(slot: Slot) -> u8 {
        match slot {
            Slot::Weapon(()) => 1,
            Slot::Chest(()) => 2,
            Slot::Head(()) => 3,
            Slot::Waist(()) => 4,
            Slot::Foot(()) => 5,
            Slot::Hand(()) => 6,
            Slot::Neck(()) => 7,
            Slot::Ring(()) => 8,
        }
    }
    fn u8_to_slot(item_type: u8) -> Slot {
        if (item_type == 1) {
            return Slot::Weapon(());
        } else if (item_type == 2) {
            return Slot::Chest(());
        } else if (item_type == 3) {
            return Slot::Head(());
        } else if (item_type == 4) {
            return Slot::Waist(());
        } else if (item_type == 5) {
            return Slot::Foot(());
        } else if (item_type == 6) {
            return Slot::Hand(());
        } else if (item_type == 7) {
            return Slot::Neck(());
        } else {
            return Slot::Ring(());
        }
    }

    // ability_based_avoid_threat returns whether or not the adventurer can avoid the threat
    // @param adventurer_level: the level of the adventurer
    // @param relevant_stat: the stat that is relevant to the threat
    // @param entropy: the entropy to use for the random number generator
    // @return bool: whether or not the adventurer can avoid the threat
    fn ability_based_avoid_threat(adventurer_level: u8, relevant_stat: u8, entropy: u128) -> bool {
        // number of sides of the die will be based on adventurer_level
        // so the higher the adventurer level, the more sides the die has
        let dice_roll = 1 + (U128TryIntoU8::try_into(entropy % adventurer_level.into()).unwrap());

        // in order to avoid the threat, the adventurer must roll a number less than or equal
        // to the the relevant stat + difficulty cliff.
        // The difficulty cliff serves as a starting cushion for the adventurer before which
        // they can avoid all threats. Once the difficulty cliff has been passed, the adventurer
        // must invest in the proper stats to avoid threats.{Intelligence for obstalce, Wisdom for beast ambushes}
        return (dice_roll <= (relevant_stat + DIFFICULTY_CLIFF::NORMAL));
    }
}

#[test]
#[available_gas(170000)]
fn test_get_level_from_xp() {
    assert(ImplCombat::get_level_from_xp(0) == 1, 'XP 0 should return Level 1');
    assert(ImplCombat::get_level_from_xp(1) == 1, 'XP 1 should return Level 1');
    assert(ImplCombat::get_level_from_xp(2) == 1, 'XP 2 should return Level 1');
    assert(ImplCombat::get_level_from_xp(3) == 1, 'XP 3 should return Level 1');
    assert(ImplCombat::get_level_from_xp(4) == 2, 'XP 4 should return Level 2');
    assert(ImplCombat::get_level_from_xp(8) == 2, 'XP 8 should return Level 2');
    assert(ImplCombat::get_level_from_xp(9) == 3, 'XP 9 should return Level 3');
    assert(ImplCombat::get_level_from_xp(15) == 3, 'XP 15 should return Level 3');
    assert(ImplCombat::get_level_from_xp(16) == 4, 'XP 16 should return Level 4');
    assert(ImplCombat::get_level_from_xp(24) == 4, 'XP 24 should return Level 4');
    assert(ImplCombat::get_level_from_xp(25) == 5, 'XP 25 should return Level 5');
    assert(ImplCombat::get_level_from_xp(35) == 5, 'XP 35 should return Level 5');
    assert(ImplCombat::get_level_from_xp(36) == 6, 'XP 36 should return Level 6');
    assert(ImplCombat::get_level_from_xp(48) == 6, 'XP 48 should return Level 6');
    assert(ImplCombat::get_level_from_xp(49) == 7, 'XP 49 should return Level 7');
    assert(ImplCombat::get_level_from_xp(63) == 7, 'XP 63 should return Level 7');
    assert(ImplCombat::get_level_from_xp(64) == 8, 'XP 64 should return Level 8');
    assert(ImplCombat::get_level_from_xp(80) == 8, 'XP 80 should return Level 8');
    assert(ImplCombat::get_level_from_xp(81) == 9, 'XP 81 should return Level 9');
    assert(ImplCombat::get_level_from_xp(99) == 9, 'XP 99 should return Level 9');
    assert(ImplCombat::get_level_from_xp(100) == 10, 'XP 100 should return Level 10');
    assert(ImplCombat::get_level_from_xp(120) == 10, 'XP 120 should return Level 10');
    assert(ImplCombat::get_level_from_xp(121) == 11, 'XP 121 should return Level 11');
    assert(ImplCombat::get_level_from_xp(143) == 11, 'XP 143 should return Level 11');
    assert(ImplCombat::get_level_from_xp(144) == 12, 'XP 144 should return Level 12');
    assert(ImplCombat::get_level_from_xp(167) == 12, 'XP 167 should return Level 12');
    assert(ImplCombat::get_level_from_xp(192) == 13, 'XP 192 should return Level 13');
    assert(ImplCombat::get_level_from_xp(219) == 14, 'XP 219 should return Level 14');
    assert(ImplCombat::get_level_from_xp(247) == 15, 'XP 247 should return Level 15');
    assert(ImplCombat::get_level_from_xp(276) == 16, 'XP 276 should return Level 16');
    assert(ImplCombat::get_level_from_xp(306) == 17, 'XP 306 should return Level 17');
    assert(ImplCombat::get_level_from_xp(337) == 18, 'XP 337 should return Level 18');
    assert(ImplCombat::get_level_from_xp(369) == 19, 'XP 369 should return Level 19');
    assert(ImplCombat::get_level_from_xp(400) == 20, 'XP 400 should return Level 20');
    assert(ImplCombat::get_level_from_xp(440) == 20, 'XP 440 should return Level 20');
    assert(ImplCombat::get_level_from_xp(441) == 21, 'XP 441 should return Level 20');
    assert(ImplCombat::get_level_from_xp(65535) == 255, 'XP 65535 should be Level 255');
}

#[test]
#[available_gas(170000)]
fn test_get_attack_hp() {
    // Initialize weapon struct
    // for this test we just need item tier and level so we can ignore other properties
    let weapon_special_names = SpecialPowers { prefix1: 0, prefix2: 0, suffix: 0,  };
    let mut weapon = CombatSpec {
        item_type: Type::Blade_or_Hide(()),
        tier: Tier::T5(()),
        level: 0,
        special_powers: weapon_special_names
    };

    // T5 Level 0 Weapon Deals 0HP of Damage
    weapon.tier = Tier::T5(());
    weapon.level = 0;
    let attack_hp = ImplCombat::get_attack_hp(weapon);
    assert(attack_hp == 0, 'T5 LVL0 should deal 0HP');

    // T5 Level 1 Weapon Deals 1HP of Damage
    weapon.tier = Tier::T5(());
    weapon.level = 1;
    let attack_hp = ImplCombat::get_attack_hp(weapon);
    assert(attack_hp == 1, 'T5 LVL1 should deal 1HP');

    // T5 Level 2 Weapon Deals 1HP of Damage
    weapon.tier = Tier::T5(());
    weapon.level = 2;
    let attack_hp = ImplCombat::get_attack_hp(weapon);
    assert(attack_hp == 2, 'T5 LVL2 should deal 2HP');

    // T5 Level 20 Weapon Deals 20HP of Damage
    weapon.tier = Tier::T5(());
    weapon.level = 20;
    let attack_hp = ImplCombat::get_attack_hp(weapon);
    assert(attack_hp == 20, 'T5 LVL20 should deal 20HP');

    // T4 Level 0 Weapon Deals 0HP of Damage
    weapon.tier = Tier::T4(());
    weapon.level = 0;
    let attack_hp = ImplCombat::get_attack_hp(weapon);
    assert(attack_hp == 0, 'T4 LVL0 should deal 0HP');

    // T4 Level 1 Weapon Deals 2HP of Damage
    weapon.tier = Tier::T4(());
    weapon.level = 1;
    let attack_hp = ImplCombat::get_attack_hp(weapon);
    assert(attack_hp == 2, 'T4 LVL1 should deal 2HP');

    // T4 Level 2 Weapon Deals 4HP of Damage
    weapon.tier = Tier::T4(());
    weapon.level = 2;
    let attack_hp = ImplCombat::get_attack_hp(weapon);
    assert(attack_hp == 4, 'T4 LVL2 should deal 4HP');

    // T4 Level 20 Weapon Deals 40HP of Damage
    weapon.tier = Tier::T4(());
    weapon.level = 20;
    let attack_hp = ImplCombat::get_attack_hp(weapon);
    assert(attack_hp == 40, 'T4 LVL20 should deal 40HP');

    // T3 Level 0 Weapon Deals 0HP of Damage
    weapon.tier = Tier::T3(());
    weapon.level = 0;
    let attack_hp = ImplCombat::get_attack_hp(weapon);
    assert(attack_hp == 0, 'T3 LVL0 should deal 0HP');

    // T3 Level 1 Weapon Deals 3HP of Damage
    weapon.tier = Tier::T3(());
    weapon.level = 1;
    let attack_hp = ImplCombat::get_attack_hp(weapon);
    assert(attack_hp == 3, 'T3 LVL1 should deal 3HP');

    // T3 Level 2 Weapon Deals 6HP of Damage
    weapon.tier = Tier::T3(());
    weapon.level = 2;
    let attack_hp = ImplCombat::get_attack_hp(weapon);
    assert(attack_hp == 6, 'T3 LVL2 should deal 6HP');

    // T3 Level 20 Weapon Deals 60HP of Damage
    weapon.tier = Tier::T3(());
    weapon.level = 20;
    let attack_hp = ImplCombat::get_attack_hp(weapon);
    assert(attack_hp == 60, 'T3 LVL20 should deal 60HP');

    // T2 Level 0 Weapon Deals 0HP of Damage
    weapon.tier = Tier::T2(());
    weapon.level = 0;
    let attack_hp = ImplCombat::get_attack_hp(weapon);
    assert(attack_hp == 0, 'T2 LVL0 should deal 0HP');

    // T2 Level 1 Weapon Deals 4HP of Damage
    weapon.tier = Tier::T2(());
    weapon.level = 1;
    let attack_hp = ImplCombat::get_attack_hp(weapon);
    assert(attack_hp == 4, 'T2 LVL1 should deal 4HP');

    // T2 Level 2 Weapon Deals 8HP of Damage
    weapon.tier = Tier::T2(());
    weapon.level = 2;
    let attack_hp = ImplCombat::get_attack_hp(weapon);
    assert(attack_hp == 8, 'T2 LVL2 should deal 8HP');

    // T2 Level 20 Weapon Deals 80HP of Damage
    weapon.tier = Tier::T2(());
    weapon.level = 20;
    let attack_hp = ImplCombat::get_attack_hp(weapon);
    assert(attack_hp == 80, 'T2 LVL20 should deal 80HP');

    // T1 Level 0 Weapon Deals 0HP of Damage
    weapon.tier = Tier::T1(());
    weapon.level = 0;
    let attack_hp = ImplCombat::get_attack_hp(weapon);
    assert(attack_hp == 0, 'T1 LVL0 should deal 0HP');

    // T1 Level 1 Weapon Deals 5HP of Damage
    weapon.tier = Tier::T1(());
    weapon.level = 1;
    let attack_hp = ImplCombat::get_attack_hp(weapon);
    assert(attack_hp == 5, 'T1 LVL1 should deal 5HP');

    // T1 Level 2 Weapon Deals 10HP of Damage
    weapon.tier = Tier::T1(());
    weapon.level = 2;
    let attack_hp = ImplCombat::get_attack_hp(weapon);
    assert(attack_hp == 10, 'T1 LVL2 should deal 10HP');

    // T1 Level 20 Weapon Deals 100HP of Damage
    weapon.tier = Tier::T1(());
    weapon.level = 20;
    let attack_hp = ImplCombat::get_attack_hp(weapon);
    assert(attack_hp == 100, 'T1 LVL20 should deal 100HP');
}

#[test]
#[available_gas(170000)]
fn test_get_armor_hp() {
    // T1 Level 20 Armor
    let armor_special_names = SpecialPowers { prefix1: 0, prefix2: 0, suffix: 0,  };
    let mut armor = CombatSpec {
        item_type: Type::Blade_or_Hide(()),
        tier: Tier::T1(()),
        level: 20,
        special_powers: armor_special_names
    };

    // T5 Level 0 Weapon Deals 0HP of Damage
    armor.tier = Tier::T5(());
    armor.level = 0;
    let attack_hp = ImplCombat::get_armor_hp(armor);
    assert(attack_hp == 0, 'T5 LVL0 should deal 0HP');

    // T5 Level 1 Weapon Deals 1HP of Damage
    armor.tier = Tier::T5(());
    armor.level = 1;
    let attack_hp = ImplCombat::get_armor_hp(armor);
    assert(attack_hp == 1, 'T5 LVL1 should deal 1HP');

    // T5 Level 2 Weapon Deals 1HP of Damage
    armor.tier = Tier::T5(());
    armor.level = 2;
    let attack_hp = ImplCombat::get_armor_hp(armor);
    assert(attack_hp == 2, 'T5 LVL2 should deal 2HP');

    // T5 Level 20 Weapon Deals 20HP of Damage
    armor.tier = Tier::T5(());
    armor.level = 20;
    let attack_hp = ImplCombat::get_armor_hp(armor);
    assert(attack_hp == 20, 'T5 LVL20 should deal 20HP');

    // T4 Level 0 Armor Provides 0HP
    armor.tier = Tier::T4(());
    armor.level = 0;
    let armor_hp = ImplCombat::get_armor_hp(armor);
    assert(armor_hp == 0, 'T4 LVL0 should provide 0HP');

    // T4 Level 1 Armor Provides 2HP
    armor.tier = Tier::T4(());
    armor.level = 1;
    let armor_hp = ImplCombat::get_armor_hp(armor);
    assert(armor_hp == 2, 'T4 LVL1 should provide 2HP');

    // T4 Level 2 Armor Provides 4HP
    armor.tier = Tier::T4(());
    armor.level = 2;
    let armor_hp = ImplCombat::get_armor_hp(armor);
    assert(armor_hp == 4, 'T4 LVL2 should provide 4HP');

    // T4 Level 20 Armor Provides 40HP
    armor.tier = Tier::T4(());
    armor.level = 20;
    let armor_hp = ImplCombat::get_armor_hp(armor);
    assert(armor_hp == 40, 'T4 LVL20 should provide 40HP');

    // T3 Level 0 Armor Provides 0HP
    armor.tier = Tier::T3(());
    armor.level = 0;
    let armor_hp = ImplCombat::get_armor_hp(armor);
    assert(armor_hp == 0, 'T3 LVL0 should provide 0HP');

    // T3 Level 1 Armor Provides 3HP
    armor.tier = Tier::T3(());
    armor.level = 1;
    let armor_hp = ImplCombat::get_armor_hp(armor);
    assert(armor_hp == 3, 'T3 LVL1 should provide 3HP');

    // T3 Level 2 Armor Provides 6HP
    armor.tier = Tier::T3(());
    armor.level = 2;
    let armor_hp = ImplCombat::get_armor_hp(armor);
    assert(armor_hp == 6, 'T3 LVL2 should provide 6HP');

    // T3 Level 20 Armor Provides 60HP
    armor.tier = Tier::T3(());
    armor.level = 20;
    let armor_hp = ImplCombat::get_armor_hp(armor);
    assert(armor_hp == 60, 'T3 LVL20 should provide 60HP');

    // T2 Level 0 Armor Provides 0HP
    armor.tier = Tier::T2(());
    armor.level = 0;
    let armor_hp = ImplCombat::get_armor_hp(armor);
    assert(armor_hp == 0, 'T2 LVL0 should provide 0HP');

    // T2 Level 1 Armor Provides 4HP
    armor.tier = Tier::T2(());
    armor.level = 1;
    let armor_hp = ImplCombat::get_armor_hp(armor);
    assert(armor_hp == 4, 'T2 LVL1 should provide 4HP');

    // T2 Level 2 Armor Provides 8HP
    armor.tier = Tier::T2(());
    armor.level = 2;
    let armor_hp = ImplCombat::get_armor_hp(armor);
    assert(armor_hp == 8, 'T2 LVL2 should provide 8HP');

    // T2 Level 20 Armor Provides 80HP
    armor.tier = Tier::T2(());
    armor.level = 20;
    let armor_hp = ImplCombat::get_armor_hp(armor);
    assert(armor_hp == 80, 'T2 LVL20 should provide 80HP');

    // T1 Level 0 Armor Provides 0HP
    armor.tier = Tier::T1(());
    armor.level = 0;
    let armor_hp = ImplCombat::get_armor_hp(armor);
    assert(armor_hp == 0, 'T1 LVL0 should provide 0HP');

    // T1 Level 1 Armor Provides 5HP
    armor.tier = Tier::T1(());
    armor.level = 1;
    let armor_hp = ImplCombat::get_armor_hp(armor);
    assert(armor_hp == 5, 'T1 LVL1 should provide 5HP');

    // T1 Level 2 Armor Provides 10HP
    armor.tier = Tier::T1(());
    armor.level = 2;
    let armor_hp = ImplCombat::get_armor_hp(armor);
    assert(armor_hp == 10, 'T1 LVL2 should provide 10HP');

    // T1 Level 20 Armor Provides 100HP
    armor.tier = Tier::T1(());
    armor.level = 20;
    let armor_hp = ImplCombat::get_armor_hp(armor);
    assert(armor_hp == 100, 'T1 LVL20 should provide 100HP');
}

#[test]
#[available_gas(90000)]
fn test_critical_hit_bonus() {
    let base_damage = 100;

    // low critical hit damage (25)
    let mut entropy = 0;
    let critical_hit_damage_bonus = ImplCombat::critical_hit_bonus(base_damage, entropy);
    assert(critical_hit_damage_bonus == 25, 'should be 25hp bonus');

    // medium-low critical hit damage (50)
    entropy = 1;
    let critical_hit_damage_bonus = ImplCombat::critical_hit_bonus(base_damage, entropy);
    assert(critical_hit_damage_bonus == 50, 'should be 50 crit hit bonus');

    // medium-high critical hit damage (75)
    entropy = 2;
    let critical_hit_damage_bonus = ImplCombat::critical_hit_bonus(base_damage, entropy);
    assert(critical_hit_damage_bonus == 75, 'should be 75 crit hit bonus');

    // high critical hit damage (100)
    entropy = 3;
    let critical_hit_damage_bonus = ImplCombat::critical_hit_bonus(base_damage, entropy);
    assert(critical_hit_damage_bonus == 100, 'should be 100 crit hit bonus');
}

#[test]
#[available_gas(90000)]
fn test_is_critical_hit() {
    // no entropy or luck is a critical hit
    let mut luck = 0;
    let mut entropy = 0;
    let is_critical_hit = ImplCombat::is_critical_hit(luck, entropy);
    assert(is_critical_hit, 'should be critical hit');

    // no luck with 1 entropy is not a critical hit
    luck = 0;
    entropy = 2;
    let is_critical_hit = ImplCombat::is_critical_hit(luck, entropy);
    assert(!is_critical_hit, 'should not be critical hit');

    // same entropy but with max luck is a critical hit
    luck = 40;
    entropy = 2;
    let is_critical_hit = ImplCombat::is_critical_hit(luck, entropy);
    assert(is_critical_hit, 'should be critical hit');

    // test max luck does not overflow and can critical hit
    luck = 255;
    entropy = 0;
    let is_critical_hit = ImplCombat::is_critical_hit(luck, entropy);
    assert(is_critical_hit, 'should be critical hit');

    // test max luck can miss critical hit
    luck = 255;
    entropy = 1;
    let is_critical_hit = ImplCombat::is_critical_hit(luck, entropy);
    assert(!is_critical_hit, 'should not be critical hit');
}

#[test]
#[available_gas(40000)]
fn test_get_weapon_effectiveness() {
    let weapon_type = Type::Magic_or_Cloth(());
    let armor_type = Type::Bludgeon_or_Metal(());
    let effectiveness = ImplCombat::get_weapon_effectiveness(weapon_type, armor_type);
    assert(effectiveness == WeaponEffectiveness::Strong(()), 'magic is strong against metal');

    let weapon_type = Type::Magic_or_Cloth(());
    let armor_type = Type::Magic_or_Cloth(());
    let effectiveness = ImplCombat::get_weapon_effectiveness(weapon_type, armor_type);
    assert(effectiveness == WeaponEffectiveness::Fair(()), 'magic is fair against cloth');

    let weapon_type = Type::Magic_or_Cloth(());
    let armor_type = Type::Blade_or_Hide(());
    let effectiveness = ImplCombat::get_weapon_effectiveness(weapon_type, armor_type);
    assert(effectiveness == WeaponEffectiveness::Weak(()), 'magic is weak against cloth');

    let weapon_type = Type::Blade_or_Hide(());
    let armor_type = Type::Magic_or_Cloth(());
    let effectiveness = ImplCombat::get_weapon_effectiveness(weapon_type, armor_type);
    assert(effectiveness == WeaponEffectiveness::Strong(()), 'blade is strong against cloth');

    let weapon_type = Type::Blade_or_Hide(());
    let armor_type = Type::Blade_or_Hide(());
    let effectiveness = ImplCombat::get_weapon_effectiveness(weapon_type, armor_type);
    assert(effectiveness == WeaponEffectiveness::Fair(()), 'blade is fair against hide');

    let weapon_type = Type::Blade_or_Hide(());
    let armor_type = Type::Bludgeon_or_Metal(());
    let effectiveness = ImplCombat::get_weapon_effectiveness(weapon_type, armor_type);
    assert(effectiveness == WeaponEffectiveness::Weak(()), 'blade is weak against metal');

    let weapon_type = Type::Bludgeon_or_Metal(());
    let armor_type = Type::Blade_or_Hide(());
    let effectiveness = ImplCombat::get_weapon_effectiveness(weapon_type, armor_type);
    assert(effectiveness == WeaponEffectiveness::Strong(()), 'bludgeon is strong against hide');

    let weapon_type = Type::Bludgeon_or_Metal(());
    let armor_type = Type::Bludgeon_or_Metal(());
    let effectiveness = ImplCombat::get_weapon_effectiveness(weapon_type, armor_type);
    assert(effectiveness == WeaponEffectiveness::Fair(()), 'bludgeon is fair against metal');

    let weapon_type = Type::Bludgeon_or_Metal(());
    let armor_type = Type::Magic_or_Cloth(());
    let effectiveness = ImplCombat::get_weapon_effectiveness(weapon_type, armor_type);
    assert(effectiveness == WeaponEffectiveness::Weak(()), 'bludgeon is weak against cloth');
}

#[test]
#[available_gas(130000)]
fn test_get_elemental_bonus() {
    // use 100 damage for easy math
    let base_damage = 100;

    // Magic deals +50% against metal
    let elemental_damage_bonus = ImplCombat::get_elemental_bonus(
        base_damage, WeaponEffectiveness::Strong(())
    );
    assert(elemental_damage_bonus == base_damage + 50, 'strong bonus should be +50%');

    // Magic deals +0% against cloth
    let elemental_damage_bonus = ImplCombat::get_elemental_bonus(
        base_damage, WeaponEffectiveness::Fair(())
    );
    assert(elemental_damage_bonus == base_damage, 'fair bonus should be +0%');

    // Magic deals -50% against hide
    let elemental_damage_bonus = ImplCombat::get_elemental_bonus(
        base_damage, WeaponEffectiveness::Weak(())
    );
    assert(elemental_damage_bonus == base_damage - 50, 'weak bonus should be -50%');
}

#[test]
#[available_gas(90000)]
fn test_get_special21_bonus() {
    let base_damage = 100;
    let mut entropy = 0;

    let mut weapon_special_names = SpecialPowers { prefix1: 0, prefix2: 0, suffix: 0,  };
    let mut armor_special_names = SpecialPowers { prefix1: 0, prefix2: 0, suffix: 0,  };

    // weapon without special name should have no bonus
    let special21_bonus = ImplCombat::get_special21_bonus(
        base_damage, weapon_special_names.prefix1, armor_special_names.prefix1, entropy
    );
    assert(special21_bonus == 0, 'should be no bonus');

    // assign armor a prefix1 name and ensure lack of weapon special name still results in no bonus
    armor_special_names.prefix1 = 1;
    let special21_bonus = ImplCombat::get_special21_bonus(
        base_damage, weapon_special_names.prefix1, armor_special_names.prefix1, entropy
    );
    assert(special21_bonus == 0, 'should be no bonus');

    // give weapon matching prefix1 to qualify it for bonus
    // actual amount (4x-7x) will depend on entropy
    // entropy 0: 4x
    weapon_special_names.prefix1 = 1;
    let special21_bonus = ImplCombat::get_special21_bonus(
        base_damage, weapon_special_names.prefix1, armor_special_names.prefix1, entropy
    );
    assert(special21_bonus == 400, 'should be +400hp bonus');

    // entropy 1: 5x
    entropy = 1;
    let special21_bonus = ImplCombat::get_special21_bonus(
        base_damage, weapon_special_names.prefix1, armor_special_names.prefix1, entropy
    );
    assert(special21_bonus == 500, 'should be +500hp bonus');

    // entropy 2: 6x
    entropy = 2;
    let special21_bonus = ImplCombat::get_special21_bonus(
        base_damage, weapon_special_names.prefix1, armor_special_names.prefix1, entropy
    );
    assert(special21_bonus == 600, 'should be +600hp bonus');

    // entropy 3: 7x
    entropy = 3;
    let special21_bonus = ImplCombat::get_special21_bonus(
        base_damage, weapon_special_names.prefix1, armor_special_names.prefix1, entropy
    );
    assert(special21_bonus == 700, 'should be +700hp bonus');
}

#[test]
#[available_gas(130000)]
fn test_get_special22_bonus() {
    let base_damage = 100;
    let mut entropy = 0;

    let mut weapon_special_names = SpecialPowers { prefix1: 0, prefix2: 0, suffix: 0,  };
    let mut armor_special_names = SpecialPowers { prefix1: 0, prefix2: 0, suffix: 0,  };

    // weapon without special name should have no bonus
    let special22_bonus = ImplCombat::get_special22_bonus(
        base_damage, weapon_special_names.prefix2, armor_special_names.prefix2, entropy
    );
    assert(special22_bonus == 0, 'no prefix2 == no bonus');

    // assign armor a prefix2 name and ensure lack of weapon special name still results in no bonus
    armor_special_names.prefix2 = 1;
    let special22_bonus = ImplCombat::get_special22_bonus(
        base_damage, weapon_special_names.prefix2, armor_special_names.prefix2, entropy
    );
    assert(special22_bonus == 0, 'no prefix2 == no bonus');

    // give weapon matching prefix2 to qualify it for bonus
    // actual amount (25% - 100%) will depend on entropy
    // entropy 0: 25%
    weapon_special_names.prefix2 = 1;
    let special22_bonus = ImplCombat::get_special22_bonus(
        base_damage, weapon_special_names.prefix2, armor_special_names.prefix2, entropy
    );
    assert(special22_bonus == 25, 'should be +25hp bonus');

    // entropy 1: 50%
    entropy = 1;
    let special22_bonus = ImplCombat::get_special22_bonus(
        base_damage, weapon_special_names.prefix2, armor_special_names.prefix2, entropy
    );
    assert(special22_bonus == 50, 'should be +50hp bonus');

    // entropy 2: 75%
    entropy = 2;
    let special22_bonus = ImplCombat::get_special22_bonus(
        base_damage, weapon_special_names.prefix2, armor_special_names.prefix2, entropy
    );
    assert(special22_bonus == 75, 'should be +75hp bonus');

    // entropy 3: 100%
    entropy = 3;
    let special22_bonus = ImplCombat::get_special22_bonus(
        base_damage, weapon_special_names.prefix2, armor_special_names.prefix2, entropy
    );
    assert(special22_bonus == 100, 'should be +100hp bonus');
}

#[test]
#[available_gas(50000)]
fn test_get_strength_bonus() {
    // use 100 base damage for easy math
    let base_damage = 100;

    // start with zero strength which should generate no bonus
    let mut strength = 0;
    let strength_bonus = ImplCombat::get_strength_bonus(base_damage, strength);
    assert(strength_bonus == 0, 'no strength == no bonus');

    // increase strength stat to 1 which should generate 20% bonus
    strength = 1;
    let strength_bonus = ImplCombat::get_strength_bonus(base_damage, strength);
    assert(strength_bonus == 20, '1 strength == 20% bonus');

    // increase strength stat to 2 which should generate 40% bonus
    strength = 2;
    let strength_bonus = ImplCombat::get_strength_bonus(base_damage, strength);
    assert(strength_bonus == 40, '1 strength == 40% bonus');

    // test max strength for loot survivor
    strength = 31;
    let strength_bonus = ImplCombat::get_strength_bonus(base_damage, strength);
    assert(strength_bonus == 620, '31 strength == 620% bonus');
}

#[test]
#[available_gas(1100000)]
fn test_calculate_damage() {
    // initialize weapon
    let weapon_special_names = SpecialPowers { prefix1: 0, prefix2: 0, suffix: 0,  };
    let mut weapon = CombatSpec {
        item_type: Type::Blade_or_Hide(()),
        tier: Tier::T5(()),
        level: 1,
        special_powers: weapon_special_names
    };

    // initialize armor
    let armor_special_names = SpecialPowers { prefix1: 0, prefix2: 0, suffix: 0,  };
    let mut armor = CombatSpec {
        item_type: Type::Blade_or_Hide(()),
        tier: Tier::T5(()),
        level: 1,
        special_powers: armor_special_names
    };

    // initialize other combat parameters
    // start with simplest values to reduce number of variables to track
    let mut minimum_damage = 0;
    let mut strength_boost = 0;
    let mut is_critical_hit = false;
    let mut entropy = 0;

    // We'll start by simulating the starter beast battle
    // adventurer selects a T5 Blade (Short Sword) and it'll be greatness/level 1
    weapon.tier = Tier::T5(());
    weapon.level = 1;

    // beast is going to be a T5 wearing cloth and it'll be greatness/level 1
    armor.tier = Tier::T5(());
    armor.level = 1;

    let damage = ImplCombat::calculate_damage(
        weapon, armor, minimum_damage, strength_boost, is_critical_hit, entropy
    );

    // adventurer isn't able to deal any damage to the beast (not good)
    assert(damage == 0, 'equally matched: 0HP');

    // client can use minimum damage setting to ensure adventurer always does at least some damage
    minimum_damage = 2;
    let damage = ImplCombat::calculate_damage(
        weapon, armor, minimum_damage, strength_boost, is_critical_hit, entropy
    );
    assert(damage == 2, 'minimum damage: 2hp');

    // adventurer levels up their weapon to level 4
    // and encounters another T5 beast wearing cloth
    weapon.level = 4;
    let damage = ImplCombat::calculate_damage(
        weapon, armor, minimum_damage, strength_boost, is_critical_hit, entropy
    );

    // they can now deal more than the minimum damage
    assert(damage == 3, 'upgrade to lvl3: 3HP');

    // they then go to the store and upgrade to a Katana (will be level 1)
    weapon.tier = Tier::T1(());
    weapon.level = 1;
    let damage = ImplCombat::calculate_damage(
        weapon, armor, minimum_damage, strength_boost, is_critical_hit, entropy
    );
    // even on level 1, it deals more damage than their starter short sword
    assert(damage == 4, 'upgrade to katana: 6HP');

    // enable critical hit for that last attack
    is_critical_hit = true;
    let damage = ImplCombat::calculate_damage(
        weapon, armor, minimum_damage, strength_boost, is_critical_hit, entropy
    );
    // user picks up a critical hit but gets minimum bonus of 1
    assert(damage == 5, 'critical hit min bonus: 5HP');

    // we can manipulate entropy to get different results
    // entropy 3 will produce max bonus of 100% of the base damage (5)
    entropy = 3;
    let damage = ImplCombat::calculate_damage(
        weapon, armor, minimum_damage, strength_boost, is_critical_hit, entropy
    );
    assert(damage == 8, 'good critical hit: 8HP');

    // switch to weak elemental
    weapon.item_type = Type::Blade_or_Hide(());
    armor.item_type = Type::Bludgeon_or_Metal(());
    let damage = ImplCombat::calculate_damage(
        weapon, armor, minimum_damage, strength_boost, is_critical_hit, entropy
    );
    // verify damage drops by ~50%
    assert(damage == 6, 'weak elemental penalty: 6HP');

    // adventurer invests in two strength stat points to get a 40% bonus on base damage (5)
    strength_boost = 2;
    let damage = ImplCombat::calculate_damage(
        weapon, armor, minimum_damage, strength_boost, is_critical_hit, entropy
    );
    // verify damage drops by ~50%
    assert(damage == 8, 'attack should be 9HP');

    // fast forward to late game (G20 Katana)
    weapon.level = 20;
    weapon.tier = Tier::T1(());
    // against a Level 30 T3 beast wearing Metal (strong against blade)
    armor.level = 40;
    armor.tier = Tier::T2(());
    let damage = ImplCombat::calculate_damage(
        weapon, armor, minimum_damage, strength_boost, is_critical_hit, entropy
    );
    assert(damage == 30, 'T1 G20 vs T3 G30: 30hp');

    // Same battle against a magical beast (cloth)
    weapon.item_type = Type::Blade_or_Hide(());
    armor.item_type = Type::Magic_or_Cloth(());
    let damage = ImplCombat::calculate_damage(
        weapon, armor, minimum_damage, strength_boost, is_critical_hit, entropy
    );
    // deals significantly more damage because elemental is applied
    // to raw attack damage
    assert(damage == 130, 'T1 G20 vs T3 G30: 130hp');
}

#[test]
#[available_gas(550000)]
fn test_get_random_level() {
    let mut adventurer_level = 1;

    let range_level_increase = DIFFICULTY_CLIFF::NORMAL;
    let level_multiplier = LEVEL_MULTIPLIER::NORMAL;

    // entity level and adventurer level will be equivalent up to the difficulty cliff
    let entity_level = ImplCombat::get_random_level(
        adventurer_level, 0, range_level_increase, level_multiplier
    );
    assert(entity_level == adventurer_level, 'lvl should eql advr lvl');

    // test at just before the difficult level cliff
    adventurer_level = DIFFICULTY_CLIFF::NORMAL - 1;
    let entity_level = ImplCombat::get_random_level(
        adventurer_level, 0, range_level_increase, level_multiplier
    );
    // entity level should still be the same as adventurer level
    assert(entity_level == adventurer_level, 'lvl should eql advr lvl');

    // test above difficult cliff (we should start to see a range of levels now based on entropy)
    // using defualts, adventurer will now be level 5
    // entropy 0 will generate the minimum entity level which will be:
    // 1 + (adventurer level - difficulty cliff)
    // min_level: 1 + (5 - 3) = 3
    // the max level will be: adventurer_level + (1 + (LEVEL_MULTIPLIER * number of level increases))
    // for current settings that will be: 5 + (1 + (4*1) = 10
    adventurer_level = DIFFICULTY_CLIFF::NORMAL + 1;
    let entity_level = ImplCombat::get_random_level(
        adventurer_level, 0, range_level_increase, level_multiplier
    );
    assert(entity_level == 3, 'entity lvl should be 3');

    let entity_level = ImplCombat::get_random_level(
        adventurer_level, 1, range_level_increase, level_multiplier
    );
    assert(entity_level == 4, 'entity lvl should be 4');

    let entity_level = ImplCombat::get_random_level(
        adventurer_level, 2, range_level_increase, level_multiplier
    );
    assert(entity_level == 5, 'entity lvl should be 5');

    let entity_level = ImplCombat::get_random_level(
        adventurer_level, 3, range_level_increase, level_multiplier
    );
    assert(entity_level == 6, 'entity lvl should be 6');

    let entity_level = ImplCombat::get_random_level(
        adventurer_level, 4, range_level_increase, level_multiplier
    );
    assert(entity_level == 7, 'entity lvl should be 7');

    let entity_level = ImplCombat::get_random_level(
        adventurer_level, 5, range_level_increase, level_multiplier
    );
    assert(entity_level == 8, 'entity lvl should be 8');

    let entity_level = ImplCombat::get_random_level(
        adventurer_level, 6, range_level_increase, level_multiplier
    );
    assert(entity_level == 9, 'entity lvl should be 9');

    let entity_level = ImplCombat::get_random_level(
        adventurer_level, 7, range_level_increase, level_multiplier
    );
    assert(entity_level == 10, 'entity lvl should be 10');

    // verify we roll over back to entity level 1
    let entity_level = ImplCombat::get_random_level(
        adventurer_level, 8, range_level_increase, level_multiplier
    );
    assert(entity_level == 3, 'entity lvl should be 3');

    // test 6 * the difficulty cliff for mid-late game
    // difficulty cliff default is 4 so adventurer_level here would be 24
    adventurer_level = DIFFICULTY_CLIFF::NORMAL * 6;
    let entity_level = ImplCombat::get_random_level(
        adventurer_level, 0, range_level_increase, level_multiplier
    );
    // at this stage, the minimum entity level is 17
    assert(entity_level == 17, 'entity lvl should be 17');

    // but we'll have 27 levels of range so top end should be 52
    let entity_level = ImplCombat::get_random_level(
        adventurer_level, 27, range_level_increase, level_multiplier
    );
    assert(entity_level == 44, 'entity lvl should be 44');
}
