use integer::{U8IntoU16, U16IntoU64};
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

    fn is_critical_hit(
        adventurer_luck: u8, adventurer_health: u16, adventurer_entropy: u64, game_entropy: u64
    ) -> bool {
        // critical hit chance is whole number of luck / 10
        let critical_hit_chance = adventurer_luck / 10;

        // critical hit random number is adventurer entropy + game entropy + adventurer health
        // this is intended to remain fixed between game entropy changes to prevent bots from simulating critical hits
        let critical_hit_rnd = adventurer_entropy
            + game_entropy
            + U16IntoU64::into(adventurer_health);


        // if critical hit random number is less than critical hit chance
        if (critical_hit_rnd < U8IntoU64::into(critical_hit_chance)) {
            // return true
            return true;
        } else {
            // otherwise return false
            return false;
        }
        
    // let (critical_hit_chance, _) = unsigned_div_rem(luck, 10);
    // // there is no implied cap on item greatness so luck is unbound
    // // but for purposes of critical damage calculation, the max critical hit chance is 5
    // let critical_hit_chance_within_range = is_le(critical_hit_chance, MAX_CRITICAL_HIT_CHANCE);
    // // if the critical hit chance is 5 or less
    // if (critical_hit_chance_within_range == TRUE) {
    //     // use the unalterted critical hit chance
    //     tempvar
    //     temp_critical_hit_chance = critical_hit_chance;
    // } else {
    //     // if it is above 5, then set it to 5
    //     tempvar
    //     temp_critical_hit_chance = MAX_CRITICAL_HIT_CHANCE;
    // }
    // let critical_hit_chance = temp_critical_hit_chance;
    // 
    // let (_, critical_rand) = unsigned_div_rem(rnd, (6 - critical_hit_chance));
    // let critical_hit = is_le(critical_rand, 0);
    // return (critical_hit, );
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
        let (is_critical_hit_) = is_critical_hit(luck, rnd);

        return 0;
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
        return 0;
    }

    // get_adventurer_strength_bonus returns the bonus damage for adventurer strength
    // @param adventurer: the adventurer
    // @param original_damage: the original damage done by the attacker
    // @return u16: the bonus damage done by adventurer strength
    fn get_adventurer_strength_bonus(adventurer: Adventurer, original_damage: u16) -> u16 {
        return 0;
    }
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
