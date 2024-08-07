use core::{integer::u16_sqrt};
use super::constants::{
    CombatEnums::{Tier, Type, Slot, WeaponEffectiveness},
    CombatSettings::{
        XP_MULTIPLIER, XP_REWARD_DIVISOR, TIER_DAMAGE_MULTIPLIER,
        ELEMENTAL_DAMAGE_BONUS, STRENGTH_DAMAGE_BONUS, MAX_XP_DECAY, SPECIAL2_DAMAGE_MULTIPLIER,
        SPECIAL3_DAMAGE_MULTIPLIER
    }
};

/// @dev this is a struct for providing special item abilities
#[derive(Drop, Copy, Serde)]
struct SpecialPowers {
    special1: u8,
    special2: u8,
    special3: u8
}

/// @dev this is a struct for providing combat specifications
#[derive(Drop, Copy, Serde)]
struct CombatSpec {
    tier: Tier,
    item_type: Type,
    level: u16,
    specials: SpecialPowers,
}

/// Used for providing combat results
/// @dev this is a struct for returning the results of a combat calculation
#[derive(Drop, Serde)]
struct CombatResult {
    base_attack: u16,
    base_armor: u16,
    elemental_adjusted_damage: u16,
    strength_bonus: u16,
    critical_hit_bonus: u16,
    weapon_special_bonus: u16,
    total_damage: u16,
}

#[generate_trait]
impl ImplCombat of ICombat {
    /// @notice Calculates the damage dealt to a defender based on various combat specifications and statistics
    /// @dev This function computes elemental adjusted damage, strength bonus, critical hit bonus, and weapon special bonus to find out the total damage.
    /// @param weapon The weapon CombatSpec of the attacker
    /// @param armor The armor CombatSpec of the defender
    /// @param minimum_damage The minimum damage the attacker can inflict
    /// @param attacker_strength The strength statistic of the attacker
    /// @param defender_strength The strength statistic of the defender (Note: unused in this function, can potentially be removed if not needed elsewhere)
    /// @param critical_hit_chance The probability for a critical hit expressed as an integer between 0 and 100
    /// @param entropy A random value to determine certain random aspects of the combat, like critical hits
    /// @return Returns a CombatResult object containing detailed damage calculations, including base attack, base armor, elemental adjusted damage, strength bonus, critical hit bonus, weapon special bonus, and total damage inflicted.
    fn calculate_damage(
        weapon: CombatSpec,
        armor: CombatSpec,
        minimum_damage: u8,
        attacker_strength: u8,
        defender_strength: u8,
        critical_hit_chance: u8,
        critical_hit_rnd: u8,
    ) -> CombatResult {
        // get base attack and armor
        let base_attack = ImplCombat::get_attack_hp(weapon);
        let base_armor = ImplCombat::get_armor_hp(armor);

        // get damage adjusted for elemental
        let elemental_adjusted_damage = ImplCombat::elemental_adjusted_damage(
            base_attack, weapon.item_type, armor.item_type
        );

        // get strength bonus
        let strength_bonus = ImplCombat::strength_bonus(
            elemental_adjusted_damage, attacker_strength
        );

        // get critical hit bonus using strength adjusted elemental damage
        let critical_hit_bonus = ImplCombat::critical_hit_bonus(
            elemental_adjusted_damage, critical_hit_chance, critical_hit_rnd
        );

        // get weapon special damage bonus using strength adjusted elemental damage
        // @dev this is a name prefix match for Loot Survivor
        let weapon_special_bonus = ImplCombat::weapon_special_bonus(
            elemental_adjusted_damage, weapon.specials, armor.specials
        );

        // total the damage
        let total_attack = elemental_adjusted_damage
            + strength_bonus
            + critical_hit_bonus
            + weapon_special_bonus;

        let mut total_damage: u16 = minimum_damage.into();
        if total_attack > base_armor + minimum_damage.into() {
            total_damage = total_attack - base_armor;
        }

        // return the resulting damages
        CombatResult {
            base_attack,
            base_armor,
            elemental_adjusted_damage,
            strength_bonus,
            critical_hit_bonus,
            weapon_special_bonus,
            total_damage
        }
    }

    /// @notice gets the attack HP of a weapon
    /// @param weapon: the weapon used to attack
    /// @return u16: the attack HP of the weapon
    fn get_attack_hp(weapon: CombatSpec) -> u16 {
        match weapon.tier {
            Tier::None => 0,
            Tier::T1 => { weapon.level * TIER_DAMAGE_MULTIPLIER::T1.into() },
            Tier::T2 => { weapon.level * TIER_DAMAGE_MULTIPLIER::T2.into() },
            Tier::T3 => { weapon.level * TIER_DAMAGE_MULTIPLIER::T3.into() },
            Tier::T4 => { weapon.level * TIER_DAMAGE_MULTIPLIER::T4.into() },
            Tier::T5 => { weapon.level * TIER_DAMAGE_MULTIPLIER::T5.into() }
        }
    }

    /// @notice gets the armor HP of a piece of armor
    /// @param armor: the armor worn by the defender
    /// @return u16: the armor HP of the armor
    fn get_armor_hp(armor: CombatSpec) -> u16 {
        match armor.tier {
            Tier::None => 0,
            Tier::T1 => { armor.level * TIER_DAMAGE_MULTIPLIER::T1.into() },
            Tier::T2 => { armor.level * TIER_DAMAGE_MULTIPLIER::T2.into() },
            Tier::T3 => { armor.level * TIER_DAMAGE_MULTIPLIER::T3.into() },
            Tier::T4 => { armor.level * TIER_DAMAGE_MULTIPLIER::T4.into() },
            Tier::T5 => { armor.level * TIER_DAMAGE_MULTIPLIER::T5.into() }
        }
    }

    /// @notice Adjusts the damage dealt based on the elemental compatibility of the weapon and armor types
    /// @param damage: the initial damage value
    /// @param weapon_type: the elemental type of the weapon
    /// @param armor_type: the elemental type of the armor
    /// @return u16: the adjusted damage value after considering the elemental effectiveness
    fn elemental_adjusted_damage(damage: u16, weapon_type: Type, armor_type: Type) -> u16 {
        let elemental_effect = damage / ELEMENTAL_DAMAGE_BONUS.into();
        let weapon_effectiveness = ImplCombat::get_elemental_effectiveness(weapon_type, armor_type);
        match weapon_effectiveness {
            WeaponEffectiveness::Weak => { damage - elemental_effect },
            WeaponEffectiveness::Fair => { damage },
            WeaponEffectiveness::Strong => { damage + elemental_effect }
        }
    }

    /// @notice gets the effectiveness of a weapon against armor
    /// @param weapon_type: the type of weapon used to attack
    /// @param armor_type: the type of armor worn by the defender
    /// @return WeaponEffectiveness: the effectiveness of the weapon against the armor
    fn get_elemental_effectiveness(weapon_type: Type, armor_type: Type) -> WeaponEffectiveness {
        match weapon_type {
            Type::None => { WeaponEffectiveness::Fair },
            // Magic is strong against metal, fair against cloth, and weak against hide
            Type::Magic_or_Cloth => {
                match armor_type {
                    // weapon is strong against no armor
                    Type::None => { WeaponEffectiveness::Strong },
                    Type::Magic_or_Cloth => { WeaponEffectiveness::Fair },
                    Type::Blade_or_Hide => { WeaponEffectiveness::Weak },
                    Type::Bludgeon_or_Metal => { WeaponEffectiveness::Strong },
                    // should not happen but compiler requires exhaustive match
                    Type::Necklace => { WeaponEffectiveness::Fair },
                    // should not happen but compiler requires exhaustive match
                    Type::Ring => { WeaponEffectiveness::Fair }
                }
            },
            // Blade is strong against cloth, fair against hide, and weak against metal
            Type::Blade_or_Hide => {
                match armor_type {
                    // weapon is strong against no armor
                    Type::None => { WeaponEffectiveness::Strong },
                    Type::Magic_or_Cloth => { WeaponEffectiveness::Strong },
                    Type::Blade_or_Hide => { WeaponEffectiveness::Fair },
                    Type::Bludgeon_or_Metal => { WeaponEffectiveness::Weak },
                    // should not happen but compiler requires exhaustive match
                    Type::Necklace => { WeaponEffectiveness::Fair },
                    // should not happen but compiler requires exhaustive match
                    Type::Ring => { WeaponEffectiveness::Fair }
                }
            },
            // Bludgeon is strong against hide, fair against metal, and weak against cloth
            Type::Bludgeon_or_Metal => {
                match armor_type {
                    // weapon is strong against no armor
                    Type::None => { WeaponEffectiveness::Strong },
                    Type::Magic_or_Cloth => { WeaponEffectiveness::Weak },
                    Type::Blade_or_Hide => { WeaponEffectiveness::Strong },
                    Type::Bludgeon_or_Metal => { WeaponEffectiveness::Fair },
                    // should not happen but compiler requires exhaustive match
                    Type::Necklace => { WeaponEffectiveness::Fair },
                    // should not happen but compiler requires exhaustive match
                    Type::Ring => { WeaponEffectiveness::Fair }
                }
            },
            Type::Necklace => { WeaponEffectiveness::Fair },
            Type::Ring => { WeaponEffectiveness::Fair },
        }
    }

    #[inline(always)]
    /// @notice determines if the attack is a critical hit
    /// @param chance: the chance of a critical hit
    /// @param rnd: the random value used to determine if the attack is a critical hit
    /// @return bool: true if the attack is a critical hit, false otherwise
    /// @dev this function scales the chance around a u8 (1-255) for uniform distribution
    fn is_critical_hit(chance: u8, rnd: u8) -> bool {
        let scaled_chance: u16 = (chance.into() * 255) / 100;
        scaled_chance > rnd.into()
    }

    /// @notice calculates the bonus damage done by a critical hit
    /// @param base_damage: the base damage done by the attacker
    /// @param critical_hit_chance: the chance of a critical hit
    /// @param rnd: the random value used to determine if the attack is a critical hit
    /// @return u16: the bonus damage done by a critical hit
    fn critical_hit_bonus(base_damage: u16, critical_hit_chance: u8, rnd: u8) -> u16 {
        let is_critical_hit = ImplCombat::is_critical_hit(critical_hit_chance, rnd);
        if (is_critical_hit) {
            base_damage
        } else {
            0
        }
    }

    /// @notice calculates the bonus damage done by a weapon as a result of the weapon special2
    /// @param base_damage: the base damage done by the attacker
    /// @param weapon_prefix1: the prefix of the weapon used to attack
    /// @param armor_prefix1: the prefix of the armor worn by the defender
    /// @return u16: the bonus damage done by a special item
    fn get_special2_bonus(base_damage: u16, weapon_prefix1: u8, armor_prefix1: u8) -> u16 {
        if (weapon_prefix1 != 0 && weapon_prefix1 == armor_prefix1) {
            base_damage * SPECIAL2_DAMAGE_MULTIPLIER.into()
        } else {
            0
        }
    }

    /// @notice calculates the bonus damage done by a weapon as a result of the weapon special3
    /// @param base_damage: the base damage done by the attacker
    /// @param weapon_prefix2: the prefix of the weapon used to attack
    /// @param armor_prefix2: the prefix of the armor worn by the defender
    /// @return u16: the bonus damage done by a special item
    fn get_special3_bonus(base_damage: u16, weapon_prefix2: u8, armor_prefix2: u8) -> u16 {
        if (weapon_prefix2 != 0 && weapon_prefix2 == armor_prefix2) {
            base_damage * SPECIAL3_DAMAGE_MULTIPLIER.into()
        } else {
            0
        }
    }

    /// @notice calculates the bonus damage done by a weapon as a result of the weapon special2 and special3
    /// @param base_damage: the base damage done by the attacker
    /// @param weapon_special2: the special2 of the weapon used to attack
    /// @param armor_special2: the special2 of the armor worn by the defender
    /// @return u16: the bonus damage done by a special item
    fn weapon_special_bonus(
        base_damage: u16, weapon_name: SpecialPowers, armor_name: SpecialPowers
    ) -> u16 {
        let special2_bonus = ImplCombat::get_special2_bonus(
            base_damage, weapon_name.special2, armor_name.special2
        );

        let special3_bonus = ImplCombat::get_special3_bonus(
            base_damage, weapon_name.special3, armor_name.special3
        );

        special2_bonus + special3_bonus
    }

    /// @notice calculates the bonus damage done by adventurer strength
    /// @param damage: the base damage done by the attacker
    /// @param strength: the strength stat of the adventurer
    /// @return u16: the bonus damage done by adventurer strength
    fn strength_bonus(damage: u16, strength: u8) -> u16 {
        if strength == 0 {
            0
        } else {
            damage * strength.into() * STRENGTH_DAMAGE_BONUS.into() / 100
        }
    }


    /// @notice: gets random level for enemy
    /// @param adventurer_level: the level of the adventurer
    /// @param seed: a random value used to determine the level
    /// @return u16: the random level
    fn get_random_level(adventurer_level: u8, seed: u16) -> u16 {
        let base_level = 1 + (seed % (adventurer_level.into() * 3)).try_into().unwrap();

        // add discrete difficulty increases based on adventurer level
        if (adventurer_level >= 50) {
            base_level + 80
        } else if (adventurer_level >= 40) {
            base_level + 40
        } else if (adventurer_level >= 30) {
            base_level + 20
        } else if (adventurer_level >= 20) {
            base_level + 10
        } else {
            base_level
        }
    }

    /// @notice: gets enemy starting health
    /// @param adventurer_level: the level of the adventurer
    /// @param seed: a random value used to determine the enemy's starting health
    /// @return u16: the enemy's starting health
    fn get_random_starting_health(adventurer_level: u8, seed: u16) -> u16 {
        let health = 1 + (seed % (adventurer_level.into() * 20)).try_into().unwrap();

        // add discrete difficulty increases based on adventurer level
        if (adventurer_level >= 50) {
            health + 500
        } else if (adventurer_level >= 40) {
            health + 400
        } else if (adventurer_level >= 30) {
            health + 200
        } else if (adventurer_level >= 20) {
            health + 100
        } else {
            health + 10
        }
    }

    /// @notice: gets level from xp
    /// @param xp: the xp to get the level for
    /// @return u8: the level for the given xp
    #[inline(always)]
    fn get_level_from_xp(xp: u16) -> u8 {
        if (xp == 0) {
            1
        } else {
            u16_sqrt(xp)
        }
    }

    /// @notice gets the base reward for defeating an entity. 
    /// @param self: the combat spec for the defeated entity
    /// @param adventurer_level: the level of the adventurer
    /// @return u16: the base reward
    fn get_base_reward(self: CombatSpec, adventurer_level: u8) -> u16 {
        let mut level_decay_percentage: u16 = adventurer_level.into() * 2;
        if (level_decay_percentage >= MAX_XP_DECAY.into()) {
            level_decay_percentage = MAX_XP_DECAY.into();
        }

        let mut tier_multiplier = 0;

        match self.tier {
            Tier::None => { panic_with_felt252('get_base_reward: tier is none'); },
            Tier::T1 => { tier_multiplier = XP_MULTIPLIER::T1.into(); },
            Tier::T2 => { tier_multiplier = XP_MULTIPLIER::T2.into(); },
            Tier::T3 => { tier_multiplier = XP_MULTIPLIER::T3.into(); },
            Tier::T4 => { tier_multiplier = XP_MULTIPLIER::T4.into(); },
            Tier::T5 => { tier_multiplier = XP_MULTIPLIER::T5.into(); },
        }

        let reward_amount: u16 = (tier_multiplier * self.level) / XP_REWARD_DIVISOR.into();

        // apply level decay percentage on reward_amount and return
        reward_amount * (100 - level_decay_percentage) / 100
    }

    /// @notice: converts a tier to a u8
    /// @param tier: the tier to convert
    /// @return u8: the u8 value of the tier
    fn tier_to_u8(tier: Tier) -> u8 {
        match tier {
            Tier::None => 0,
            Tier::T1 => 1,
            Tier::T2 => 2,
            Tier::T3 => 3,
            Tier::T4 => 4,
            Tier::T5 => 5,
        }
    }

    /// @notice: converts an item type to a u8
    /// @param item_type: the item type to convert
    /// @return u8: the u8 value of the item type
    fn type_to_u8(item_type: Type) -> u8 {
        match item_type {
            Type::None => 0,
            Type::Magic_or_Cloth => 1,
            Type::Blade_or_Hide => 2,
            Type::Bludgeon_or_Metal => 3,
            Type::Necklace => 4,
            Type::Ring => 5,
        }
    }

    /// @notice: converts a u8 to an item type
    /// @param item_type: the u8 value to convert
    /// @return Type: the item type of the u8 value
    fn u8_to_type(item_type: u8) -> Type {
        if (item_type == 1) {
            Type::Magic_or_Cloth
        } else if (item_type == 2) {
            Type::Blade_or_Hide
        } else if (item_type == 3) {
            Type::Bludgeon_or_Metal
        } else if (item_type == 4) {
            Type::Necklace
        } else if (item_type == 5) {
            Type::Ring
        } else {
            Type::None
        }
    }

    /// @notice: converts a u8 to a tier
    /// @param item_type: the u8 value to convert
    /// @return Tier: the tier of the u8 value
    fn u8_to_tier(item_type: u8) -> Tier {
        if (item_type == 1) {
            Tier::T1
        } else if (item_type == 2) {
            Tier::T2
        } else if (item_type == 3) {
            Tier::T3
        } else if (item_type == 4) {
            Tier::T4
        } else if (item_type == 5) {
            Tier::T5
        } else {
            Tier::None
        }
    }

    /// @notice: converts a slot to a u8
    /// @param slot: the slot to convert
    /// @return u8: the u8 value of the slot
    fn slot_to_u8(slot: Slot) -> u8 {
        match slot {
            Slot::None => 0,
            Slot::Weapon => 1,
            Slot::Chest => 2,
            Slot::Head => 3,
            Slot::Waist => 4,
            Slot::Foot => 5,
            Slot::Hand => 6,
            Slot::Neck => 7,
            Slot::Ring => 8,
        }
    }

    /// @notice: converts a u8 to a slot
    /// @param item_type: the u8 value to convert
    /// @return Slot: the slot of the u8 value
    fn u8_to_slot(item_type: u8) -> Slot {
        if (item_type == 1) {
            Slot::Weapon
        } else if (item_type == 2) {
            Slot::Chest
        } else if (item_type == 3) {
            Slot::Head
        } else if (item_type == 4) {
            Slot::Waist
        } else if (item_type == 5) {
            Slot::Foot
        } else if (item_type == 6) {
            Slot::Hand
        } else if (item_type == 7) {
            Slot::Neck
        } else if (item_type == 8) {
            Slot::Ring
        } else {
            Slot::None
        }
    }

    /// @notice: determines if the adventurer can avoid the threat based on their level and relevant stat
    /// @param adventurer_level: the level of the adventurer
    /// @param relevant_stat: the stat that is relevant to the threat
    /// @param rnd: a u8 random value used to determine if the adventurer can avoid the threat
    /// @return bool: whether or not the adventurer can avoid the threat
    fn ability_based_avoid_threat(adventurer_level: u8, relevant_stat: u8, rnd: u8) -> bool {
        if relevant_stat >= adventurer_level {
            true
        } else {
            let scaled_chance: u16 = (adventurer_level.into() * rnd.into()) / 255;
            relevant_stat.into() > scaled_chance
        }
    }
}

// ---------------------------
// ---------- Tests ----------
// ---------------------------
#[cfg(test)]
mod tests {
    use core::option::OptionTrait;
    use integer::{u16_sqrt};
    use core::traits::{TryInto, Into};
    use combat::{
        combat::{ImplCombat, ICombat, CombatSpec, SpecialPowers},
        constants::{
            CombatEnums::{Tier, Type, Slot, WeaponEffectiveness},
            CombatSettings::{STRENGTH_DAMAGE_BONUS}
        }
    };

    const U16_MAX: u16 = 65535;

    #[test]
    #[available_gas(50000)]
    fn test_get_random_starting_health_max_values() {
        // test max value case
        // no need to assert result just make sure it doesn't panic
        let _enemy_starting_health = ImplCombat::get_random_starting_health(255, U16_MAX);
    }

    #[test]
    #[available_gas(500000)]
    fn test_get_random_starting_health_new() {
        let enemy_starting_health = ImplCombat::get_random_starting_health(1, 0);
        assert(enemy_starting_health == 11, 'lvl1, min beast heatlh is 11');
    }

    #[test]
    #[available_gas(500000)]
    fn test_get_random_starting_health() {
        let mut adventurer_level = 2;
        let min_beast_level = ImplCombat::get_random_starting_health(adventurer_level, 0);
        let max_beast_level = ImplCombat::get_random_starting_health(adventurer_level, 29);
        assert(min_beast_level == 11, 'lvl2, min beast heatlh is 11');
        assert(max_beast_level == 40, 'lvl2, max beast lvl is 40');

        adventurer_level = 3;
        let min_beast_level = ImplCombat::get_random_starting_health(adventurer_level, 0);
        let max_beast_level = ImplCombat::get_random_starting_health(adventurer_level, 44);
        assert(min_beast_level == 11, 'lvl3, min beast heatlh is 11');
        assert(max_beast_level == 55, 'lvl3, max beast lvl is 55');

        adventurer_level = 4;
        let min_beast_level = ImplCombat::get_random_starting_health(adventurer_level, 0);
        let max_beast_level = ImplCombat::get_random_starting_health(adventurer_level, 59);
        assert(min_beast_level == 11, 'lvl4, min beast heatlh is 11');
        assert(max_beast_level == 70, 'lvl4, max beast lvl is 70');

        adventurer_level = 5;
        let min_beast_level = ImplCombat::get_random_starting_health(adventurer_level, 0);
        let max_beast_level = ImplCombat::get_random_starting_health(adventurer_level, 74);
        assert(min_beast_level == 11, 'lvl5, min beast heatlh is 11');
        assert(max_beast_level == 85, 'lvl5, max beast lvl is 85');

        adventurer_level = 19;
        let min_beast_level = ImplCombat::get_random_starting_health(adventurer_level, 0);
        let max_beast_level = ImplCombat::get_random_starting_health(adventurer_level, 284);
        assert(min_beast_level == 11, 'lvl19, min beast heatlh is 11');
        assert(max_beast_level == 295, 'lvl19, max beast lvl is 295');

        adventurer_level = 20;
        let min_beast_level = ImplCombat::get_random_starting_health(adventurer_level, 0);
        let max_beast_level = ImplCombat::get_random_starting_health(adventurer_level, 299);
        assert(min_beast_level == 101, 'lvl20, min beast heatlh is 101');
        assert(max_beast_level == 400, 'lvl20, max beast lvl is 310');

        adventurer_level = 29;
        let min_beast_level = ImplCombat::get_random_starting_health(adventurer_level, 0);
        let max_beast_level = ImplCombat::get_random_starting_health(adventurer_level, 434);
        assert(min_beast_level == 101, 'lvl29, min beast heatlh is 101');
        // combat module will return higher health than LS beasts can handle
        // this is fine as Beast module will cap the health at 511
        assert(max_beast_level == 535, 'lvl29, max beast lvl is 535');

        adventurer_level = 30;
        let min_beast_level = ImplCombat::get_random_starting_health(adventurer_level, 0);
        let max_beast_level = ImplCombat::get_random_starting_health(adventurer_level, 449);
        assert(min_beast_level == 201, 'lvl30, min beast heatlh is 201');
        assert(max_beast_level == 650, 'lvl30, max beast lvl is 650');

        adventurer_level = 40;
        let min_beast_level = ImplCombat::get_random_starting_health(adventurer_level, 0);
        let max_beast_level = ImplCombat::get_random_starting_health(adventurer_level, 599);
        assert(min_beast_level == 401, 'lvl40, min beast heatlh is 401');
        assert(max_beast_level == 1000, 'lvl40, max beast lvl is 1000');

        adventurer_level = 50;
        let min_beast_level = ImplCombat::get_random_starting_health(adventurer_level, 0);
        let max_beast_level = ImplCombat::get_random_starting_health(adventurer_level, 749);
        assert(min_beast_level == 501, 'lvl50, min beast heatlh is 501');
        assert(max_beast_level == 1250, 'lvl50, max beast lvl is 1250');
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
        let mut weapon = CombatSpec {
            item_type: Type::Blade_or_Hide,
            tier: Tier::T5,
            level: 0,
            specials: SpecialPowers { special1: 0, special2: 0, special3: 0 }
        };

        // T5 Level 0 Weapon Deals 0HP of Damage
        weapon.tier = Tier::T5;
        weapon.level = 0;
        let attack_hp = ImplCombat::get_attack_hp(weapon);
        assert(attack_hp == 0, 'T5 LVL0 should deal 0HP');

        // T5 Level 1 Weapon Deals 1HP of Damage
        weapon.tier = Tier::T5;
        weapon.level = 1;
        let attack_hp = ImplCombat::get_attack_hp(weapon);
        assert(attack_hp == 1, 'T5 LVL1 should deal 1HP');

        // T5 Level 2 Weapon Deals 1HP of Damage
        weapon.tier = Tier::T5;
        weapon.level = 2;
        let attack_hp = ImplCombat::get_attack_hp(weapon);
        assert(attack_hp == 2, 'T5 LVL2 should deal 2HP');

        // T5 Level 20 Weapon Deals 20HP of Damage
        weapon.tier = Tier::T5;
        weapon.level = 20;
        let attack_hp = ImplCombat::get_attack_hp(weapon);
        assert(attack_hp == 20, 'T5 LVL20 should deal 20HP');

        // T4 Level 0 Weapon Deals 0HP of Damage
        weapon.tier = Tier::T4;
        weapon.level = 0;
        let attack_hp = ImplCombat::get_attack_hp(weapon);
        assert(attack_hp == 0, 'T4 LVL0 should deal 0HP');

        // T4 Level 1 Weapon Deals 2HP of Damage
        weapon.tier = Tier::T4;
        weapon.level = 1;
        let attack_hp = ImplCombat::get_attack_hp(weapon);
        assert(attack_hp == 2, 'T4 LVL1 should deal 2HP');

        // T4 Level 2 Weapon Deals 4HP of Damage
        weapon.tier = Tier::T4;
        weapon.level = 2;
        let attack_hp = ImplCombat::get_attack_hp(weapon);
        assert(attack_hp == 4, 'T4 LVL2 should deal 4HP');

        // T4 Level 20 Weapon Deals 40HP of Damage
        weapon.tier = Tier::T4;
        weapon.level = 20;
        let attack_hp = ImplCombat::get_attack_hp(weapon);
        assert(attack_hp == 40, 'T4 LVL20 should deal 40HP');

        // T3 Level 0 Weapon Deals 0HP of Damage
        weapon.tier = Tier::T3;
        weapon.level = 0;
        let attack_hp = ImplCombat::get_attack_hp(weapon);
        assert(attack_hp == 0, 'T3 LVL0 should deal 0HP');

        // T3 Level 1 Weapon Deals 3HP of Damage
        weapon.tier = Tier::T3;
        weapon.level = 1;
        let attack_hp = ImplCombat::get_attack_hp(weapon);
        assert(attack_hp == 3, 'T3 LVL1 should deal 3HP');

        // T3 Level 2 Weapon Deals 6HP of Damage
        weapon.tier = Tier::T3;
        weapon.level = 2;
        let attack_hp = ImplCombat::get_attack_hp(weapon);
        assert(attack_hp == 6, 'T3 LVL2 should deal 6HP');

        // T3 Level 20 Weapon Deals 60HP of Damage
        weapon.tier = Tier::T3;
        weapon.level = 20;
        let attack_hp = ImplCombat::get_attack_hp(weapon);
        assert(attack_hp == 60, 'T3 LVL20 should deal 60HP');

        // T2 Level 0 Weapon Deals 0HP of Damage
        weapon.tier = Tier::T2;
        weapon.level = 0;
        let attack_hp = ImplCombat::get_attack_hp(weapon);
        assert(attack_hp == 0, 'T2 LVL0 should deal 0HP');

        // T2 Level 1 Weapon Deals 4HP of Damage
        weapon.tier = Tier::T2;
        weapon.level = 1;
        let attack_hp = ImplCombat::get_attack_hp(weapon);
        assert(attack_hp == 4, 'T2 LVL1 should deal 4HP');

        // T2 Level 2 Weapon Deals 8HP of Damage
        weapon.tier = Tier::T2;
        weapon.level = 2;
        let attack_hp = ImplCombat::get_attack_hp(weapon);
        assert(attack_hp == 8, 'T2 LVL2 should deal 8HP');

        // T2 Level 20 Weapon Deals 80HP of Damage
        weapon.tier = Tier::T2;
        weapon.level = 20;
        let attack_hp = ImplCombat::get_attack_hp(weapon);
        assert(attack_hp == 80, 'T2 LVL20 should deal 80HP');

        // T1 Level 0 Weapon Deals 0HP of Damage
        weapon.tier = Tier::T1;
        weapon.level = 0;
        let attack_hp = ImplCombat::get_attack_hp(weapon);
        assert(attack_hp == 0, 'T1 LVL0 should deal 0HP');

        // T1 Level 1 Weapon Deals 5HP of Damage
        weapon.tier = Tier::T1;
        weapon.level = 1;
        let attack_hp = ImplCombat::get_attack_hp(weapon);
        assert(attack_hp == 5, 'T1 LVL1 should deal 5HP');

        // T1 Level 2 Weapon Deals 10HP of Damage
        weapon.tier = Tier::T1;
        weapon.level = 2;
        let attack_hp = ImplCombat::get_attack_hp(weapon);
        assert(attack_hp == 10, 'T1 LVL2 should deal 10HP');

        // T1 Level 20 Weapon Deals 100HP of Damage
        weapon.tier = Tier::T1;
        weapon.level = 20;
        let attack_hp = ImplCombat::get_attack_hp(weapon);
        assert(attack_hp == 100, 'T1 LVL20 should deal 100HP');
    }

    #[test]
    #[available_gas(170000)]
    fn test_get_armor_hp() {
        // T1 Level 20 Armor (no special powers)
        let mut armor = CombatSpec {
            item_type: Type::Blade_or_Hide,
            tier: Tier::T1,
            level: 20,
            specials: SpecialPowers { special2: 0, special3: 0, special1: 0 }
        };

        // T5 Level 0 Weapon Deals 0HP of Damage
        armor.tier = Tier::T5;
        armor.level = 0;
        let attack_hp = ImplCombat::get_armor_hp(armor);
        assert(attack_hp == 0, 'T5 LVL0 should deal 0HP');

        // T5 Level 1 Weapon Deals 1HP of Damage
        armor.tier = Tier::T5;
        armor.level = 1;
        let attack_hp = ImplCombat::get_armor_hp(armor);
        assert(attack_hp == 1, 'T5 LVL1 should deal 1HP');

        // T5 Level 2 Weapon Deals 1HP of Damage
        armor.tier = Tier::T5;
        armor.level = 2;
        let attack_hp = ImplCombat::get_armor_hp(armor);
        assert(attack_hp == 2, 'T5 LVL2 should deal 2HP');

        // T5 Level 20 Weapon Deals 20HP of Damage
        armor.tier = Tier::T5;
        armor.level = 20;
        let attack_hp = ImplCombat::get_armor_hp(armor);
        assert(attack_hp == 20, 'T5 LVL20 should deal 20HP');

        // T4 Level 0 Armor Provides 0HP
        armor.tier = Tier::T4;
        armor.level = 0;
        let armor_hp = ImplCombat::get_armor_hp(armor);
        assert(armor_hp == 0, 'T4 LVL0 should provide 0HP');

        // T4 Level 1 Armor Provides 2HP
        armor.tier = Tier::T4;
        armor.level = 1;
        let armor_hp = ImplCombat::get_armor_hp(armor);
        assert(armor_hp == 2, 'T4 LVL1 should provide 2HP');

        // T4 Level 2 Armor Provides 4HP
        armor.tier = Tier::T4;
        armor.level = 2;
        let armor_hp = ImplCombat::get_armor_hp(armor);
        assert(armor_hp == 4, 'T4 LVL2 should provide 4HP');

        // T4 Level 20 Armor Provides 40HP
        armor.tier = Tier::T4;
        armor.level = 20;
        let armor_hp = ImplCombat::get_armor_hp(armor);
        assert(armor_hp == 40, 'T4 LVL20 should provide 40HP');

        // T3 Level 0 Armor Provides 0HP
        armor.tier = Tier::T3;
        armor.level = 0;
        let armor_hp = ImplCombat::get_armor_hp(armor);
        assert(armor_hp == 0, 'T3 LVL0 should provide 0HP');

        // T3 Level 1 Armor Provides 3HP
        armor.tier = Tier::T3;
        armor.level = 1;
        let armor_hp = ImplCombat::get_armor_hp(armor);
        assert(armor_hp == 3, 'T3 LVL1 should provide 3HP');

        // T3 Level 2 Armor Provides 6HP
        armor.tier = Tier::T3;
        armor.level = 2;
        let armor_hp = ImplCombat::get_armor_hp(armor);
        assert(armor_hp == 6, 'T3 LVL2 should provide 6HP');

        // T3 Level 20 Armor Provides 60HP
        armor.tier = Tier::T3;
        armor.level = 20;
        let armor_hp = ImplCombat::get_armor_hp(armor);
        assert(armor_hp == 60, 'T3 LVL20 should provide 60HP');

        // T2 Level 0 Armor Provides 0HP
        armor.tier = Tier::T2;
        armor.level = 0;
        let armor_hp = ImplCombat::get_armor_hp(armor);
        assert(armor_hp == 0, 'T2 LVL0 should provide 0HP');

        // T2 Level 1 Armor Provides 4HP
        armor.tier = Tier::T2;
        armor.level = 1;
        let armor_hp = ImplCombat::get_armor_hp(armor);
        assert(armor_hp == 4, 'T2 LVL1 should provide 4HP');

        // T2 Level 2 Armor Provides 8HP
        armor.tier = Tier::T2;
        armor.level = 2;
        let armor_hp = ImplCombat::get_armor_hp(armor);
        assert(armor_hp == 8, 'T2 LVL2 should provide 8HP');

        // T2 Level 20 Armor Provides 80HP
        armor.tier = Tier::T2;
        armor.level = 20;
        let armor_hp = ImplCombat::get_armor_hp(armor);
        assert(armor_hp == 80, 'T2 LVL20 should provide 80HP');

        // T1 Level 0 Armor Provides 0HP
        armor.tier = Tier::T1;
        armor.level = 0;
        let armor_hp = ImplCombat::get_armor_hp(armor);
        assert(armor_hp == 0, 'T1 LVL0 should provide 0HP');

        // T1 Level 1 Armor Provides 5HP
        armor.tier = Tier::T1;
        armor.level = 1;
        let armor_hp = ImplCombat::get_armor_hp(armor);
        assert(armor_hp == 5, 'T1 LVL1 should provide 5HP');

        // T1 Level 2 Armor Provides 10HP
        armor.tier = Tier::T1;
        armor.level = 2;
        let armor_hp = ImplCombat::get_armor_hp(armor);
        assert(armor_hp == 10, 'T1 LVL2 should provide 10HP');

        // T1 Level 20 Armor Provides 100HP
        armor.tier = Tier::T1;
        armor.level = 20;
        let armor_hp = ImplCombat::get_armor_hp(armor);
        assert(armor_hp == 100, 'T1 LVL20 should provide 100HP');
    }

    #[test]
    #[available_gas(123700)]
    fn test_critical_hit_bonus() {
        let base_damage = 100;
        let mut critical_hit_chance = 0;
        let mut rnd = 0;

        // no critical hit
        let critical_hit_damage_bonus = ImplCombat::critical_hit_bonus(
            base_damage, critical_hit_chance, rnd
        );
        assert(critical_hit_damage_bonus == 0, 'should be no crit hit bonus');

        // 100% critical hit
        critical_hit_chance = 100;
        let critical_hit_damage_bonus = ImplCombat::critical_hit_bonus(
            base_damage, critical_hit_chance, rnd
        );
        assert(critical_hit_damage_bonus == 100, 'should be crit hit bonus');

        // With a 1% chance, critical hit only works if rnd % 100 == 0
        critical_hit_chance = 1;
        rnd = 0;
        let critical_hit_damage_bonus = ImplCombat::critical_hit_bonus(
            base_damage, critical_hit_chance, rnd
        );
        assert(critical_hit_damage_bonus == 100, 'should be crit hit bonus');

        rnd = 2;
        let critical_hit_damage_bonus = ImplCombat::critical_hit_bonus(
            base_damage, critical_hit_chance, rnd
        );
        assert(critical_hit_damage_bonus == 0, 'should be no crit hit bonus');

        rnd = 99;
        let critical_hit_damage_bonus = ImplCombat::critical_hit_bonus(
            base_damage, critical_hit_chance, rnd
        );
        assert(critical_hit_damage_bonus == 0, 'should be no crit hit bonus');
    }

    #[test]
    #[available_gas(2860)]
    fn test_is_critical_hit_gas() {
        ImplCombat::is_critical_hit(100, 0);
    }

    #[test]
    fn test_is_critical_hit() {
        // no critical hit without luck
        let mut luck = 0;
        let mut rnd = 0;
        let is_critical_hit = ImplCombat::is_critical_hit(luck, rnd);
        assert(is_critical_hit == false, 'no critical hit without luck');

        // 1 luck gets us a critical hit with 0 entropy
        luck = 1;
        let is_critical_hit = ImplCombat::is_critical_hit(luck, rnd);
        assert(is_critical_hit, 'should be critical hit');

        // rnd is a u8 so range is 0-255
        // at rnd 2 and above, 1 luck does not provide critical hit
        rnd = 2;
        let is_critical_hit = ImplCombat::is_critical_hit(luck, rnd);
        assert(!is_critical_hit, 'should not be critical hit');

        // check for multiplication overflow errors with max u8 luck
        luck = 255;
        rnd = 0;
        let is_critical_hit = ImplCombat::is_critical_hit(luck, rnd);
        assert(is_critical_hit, 'should be critical hit');

        // with max luck, every attack is critical hit
        rnd = 255;
        let is_critical_hit = ImplCombat::is_critical_hit(luck, rnd);
        assert(is_critical_hit, 'should be critical hit');
    }

    #[test]
    #[available_gas(22200)]
    fn test_get_elemental_effectiveness() {
        let weapon_type = Type::Magic_or_Cloth;
        let armor_type = Type::Bludgeon_or_Metal;
        let effectiveness = ImplCombat::get_elemental_effectiveness(weapon_type, armor_type);
        assert(effectiveness == WeaponEffectiveness::Strong, 'magic is strong against metal');

        let weapon_type = Type::Magic_or_Cloth;
        let armor_type = Type::Magic_or_Cloth;
        let effectiveness = ImplCombat::get_elemental_effectiveness(weapon_type, armor_type);
        assert(effectiveness == WeaponEffectiveness::Fair, 'magic is fair against cloth');

        let weapon_type = Type::Magic_or_Cloth;
        let armor_type = Type::Blade_or_Hide;
        let effectiveness = ImplCombat::get_elemental_effectiveness(weapon_type, armor_type);
        assert(effectiveness == WeaponEffectiveness::Weak, 'magic is weak against cloth');

        let weapon_type = Type::Blade_or_Hide;
        let armor_type = Type::Magic_or_Cloth;
        let effectiveness = ImplCombat::get_elemental_effectiveness(weapon_type, armor_type);
        assert(effectiveness == WeaponEffectiveness::Strong, 'blade is strong against cloth');

        let weapon_type = Type::Blade_or_Hide;
        let armor_type = Type::Blade_or_Hide;
        let effectiveness = ImplCombat::get_elemental_effectiveness(weapon_type, armor_type);
        assert(effectiveness == WeaponEffectiveness::Fair, 'blade is fair against hide');

        let weapon_type = Type::Blade_or_Hide;
        let armor_type = Type::Bludgeon_or_Metal;
        let effectiveness = ImplCombat::get_elemental_effectiveness(weapon_type, armor_type);
        assert(effectiveness == WeaponEffectiveness::Weak, 'blade is weak against metal');

        let weapon_type = Type::Bludgeon_or_Metal;
        let armor_type = Type::Blade_or_Hide;
        let effectiveness = ImplCombat::get_elemental_effectiveness(weapon_type, armor_type);
        assert(effectiveness == WeaponEffectiveness::Strong, 'bludgeon is strong against hide');

        let weapon_type = Type::Bludgeon_or_Metal;
        let armor_type = Type::Bludgeon_or_Metal;
        let effectiveness = ImplCombat::get_elemental_effectiveness(weapon_type, armor_type);
        assert(effectiveness == WeaponEffectiveness::Fair, 'bludgeon is fair against metal');

        let weapon_type = Type::Bludgeon_or_Metal;
        let armor_type = Type::Magic_or_Cloth;
        let effectiveness = ImplCombat::get_elemental_effectiveness(weapon_type, armor_type);
        assert(effectiveness == WeaponEffectiveness::Weak, 'bludgeon is weak against cloth');
    }

    #[test]
    #[available_gas(37220)]
    fn test_elemental_adjusted_damage() {
        // use 100 damage for easy math
        let base_damage = 100;

        // Magic deals +50% against metal
        let elemental_damage_bonus = ImplCombat::elemental_adjusted_damage(
            base_damage, Type::Magic_or_Cloth, Type::Bludgeon_or_Metal
        );
        assert(elemental_damage_bonus == base_damage + 50, 'strong bonus should be +50%');

        // Magic deals +0% against cloth
        let elemental_damage_bonus = ImplCombat::elemental_adjusted_damage(
            base_damage, Type::Magic_or_Cloth, Type::Magic_or_Cloth
        );
        assert(elemental_damage_bonus == base_damage, 'fair bonus should be +0%');

        // Magic deals -50% against hide
        let elemental_damage_bonus = ImplCombat::elemental_adjusted_damage(
            base_damage, Type::Magic_or_Cloth, Type::Blade_or_Hide
        );
        assert(elemental_damage_bonus == base_damage - 50, 'weak bonus should be -50%');
    }

    #[test]
    fn test_get_special2_bonus() {
        let base_damage = 100;

        let mut weapon_specials = SpecialPowers { special1: 0, special2: 0, special3: 0 };
        let mut armor_specials = SpecialPowers { special1: 0, special2: 0, special3: 0 };

        // weapon without special name should have no bonus
        let special2_bonus = ImplCombat::get_special2_bonus(
            base_damage, weapon_specials.special2, armor_specials.special2
        );
        assert(special2_bonus == 0, 'should be no bonus');

        // assign armor a special2 name and ensure lack of weapon special name still results in no bonus
        armor_specials.special2 = 1;
        let special2_bonus = ImplCombat::get_special2_bonus(
            base_damage, weapon_specials.special2, armor_specials.special2
        );
        assert(special2_bonus == 0, 'should be no bonus');

        // give weapon matching special2 to qualify it for bonus (gg beast)
        weapon_specials.special2 = 1;
        let special2_bonus = ImplCombat::get_special2_bonus(
            base_damage, weapon_specials.special2, armor_specials.special2
        );
        assert(special2_bonus == 800, 'wrong special2 bonus');
    }

    #[test]
    #[available_gas(130000)]
    fn test_get_special3_bonus() {
        let base_damage = 100;

        let mut weapon_specials = SpecialPowers { special1: 0, special2: 0, special3: 0 };
        let mut armor_specials = SpecialPowers { special1: 0, special2: 0, special3: 0 };

        // weapon without special name should have no bonus
        let special3_bonus = ImplCombat::get_special3_bonus(
            base_damage, weapon_specials.special3, armor_specials.special3
        );
        assert(special3_bonus == 0, 'no prefix2 == no bonus');

        // assign armor a prefix2 name and ensure lack of weapon special name still results in no bonus
        armor_specials.special3 = 1;
        let special3_bonus = ImplCombat::get_special3_bonus(
            base_damage, weapon_specials.special3, armor_specials.special3
        );
        assert(special3_bonus == 0, 'no prefix2 == no bonus');

        // give weapon matching prefix2 to qualify it for bonus
        weapon_specials.special3 = 1;
        let special3_bonus = ImplCombat::get_special3_bonus(
            base_damage, weapon_specials.special3, armor_specials.special3
        );
        assert(special3_bonus == 200, 'wrong special3 bonus');
    }

    #[test]
    #[available_gas(54110)]
    fn test_strength_bonus() {
        // use 100 base damage for easy math
        let base_damage = 100;

        // start with zero strength which should generate no bonus
        let mut strength = 0;
        let strength_bonus = ImplCombat::strength_bonus(base_damage, strength);
        assert(strength_bonus == 0, 'no strength, no bonus');

        // increase strength stat to 1 which should generate 20% bonus
        strength = 1;
        let strength_bonus = ImplCombat::strength_bonus(base_damage, strength);
        assert(
            strength_bonus == STRENGTH_DAMAGE_BONUS.into() * strength.into(), 'wrong 1 strength'
        );

        // increase strength stat to 2 which should generate 40% bonus
        strength = 2;
        let strength_bonus = ImplCombat::strength_bonus(base_damage, strength);
        assert(
            strength_bonus == STRENGTH_DAMAGE_BONUS.into() * strength.into(), 'wrong 2 strength'
        );

        // test max strength for loot survivor
        strength = 31;
        let strength_bonus = ImplCombat::strength_bonus(base_damage, strength);
        assert(
            strength_bonus == STRENGTH_DAMAGE_BONUS.into() * strength.into(), 'wrong 31 strength'
        );
    }

    #[test]
    #[available_gas(764930)]
    fn test_calculate_damage() {
        let minimum_damage = 4;

        let _min_critical_hit_bonus = 0;
        let medium_critical_hit_bonus = 1;
        let _high_critical_hit_bonus = 2;
        let _max_critical_hit_bonus = 3;

        // initialize other combat parameters
        // start with simplest values to reduce number of variables to track
        let mut attacker_strength = 0;
        let defender_strength = 0;
        let mut critical_hit_chance = 0;
        let mut entropy = 0;

        // Start by simulating the starter beast battle
        let mut weapon = CombatSpec {
            item_type: Type::Blade_or_Hide,
            tier: Tier::T5,
            level: 1,
            specials: SpecialPowers { special1: 0, special2: 0, special3: 0 }
        };

        let mut armor = CombatSpec {
            item_type: Type::Magic_or_Cloth,
            tier: Tier::T5,
            level: 1,
            specials: SpecialPowers { special1: 0, special2: 0, special3: 0 }
        };

        let damage_results = ImplCombat::calculate_damage(
            weapon, armor, 4, 0, defender_strength, critical_hit_chance, entropy
        );

        // damage should be minimum plus elemental
        assert(damage_results.total_damage == 4, 'should be 4hp');

        // adventurer levels up their weapon to level 4
        weapon.level = 4;
        let damage_results = ImplCombat::calculate_damage(
            weapon,
            armor,
            minimum_damage,
            attacker_strength,
            defender_strength,
            critical_hit_chance,
            entropy
        );

        // this still produces an attack below the minimum so result is the same
        assert(damage_results.total_damage == 5, 'upgrade to lvl4: 5HP');

        // they then go to the store and upgrade to a Katana (will be level 1)
        weapon.tier = Tier::T1;
        weapon.level = 1;
        let damage_results = ImplCombat::calculate_damage(
            weapon,
            armor,
            minimum_damage,
            attacker_strength,
            defender_strength,
            critical_hit_chance,
            entropy
        );
        // even on level 1, it deals more damage than their starter short sword
        assert(damage_results.total_damage == 6, 'upgrade to T1: 6HP');

        // same weapon but now with ineffective elemental
        weapon.item_type = Type::Blade_or_Hide;
        armor.item_type = Type::Bludgeon_or_Metal;
        let damage_results = ImplCombat::calculate_damage(
            weapon,
            armor,
            minimum_damage,
            attacker_strength,
            defender_strength,
            critical_hit_chance,
            entropy
        );
        // drops damage down to minimum
        assert(damage_results.total_damage == 4, 'weak elemental: 4HP');

        // fast forward to late game

        // Adventurer has 5 strength
        let attacker_strength = 5;
        weapon.level = 20;
        weapon.tier = Tier::T1;
        weapon.item_type = Type::Blade_or_Hide;

        // Beast is T2 LVL 40 with Metal Armor (Strong against Blade)
        armor.level = 40;
        armor.tier = Tier::T2;
        armor.item_type = Type::Bludgeon_or_Metal;

        let critical_hit_chance = 100;
        let damage_results = ImplCombat::calculate_damage(
            weapon,
            armor,
            minimum_damage,
            attacker_strength,
            defender_strength,
            critical_hit_chance,
            medium_critical_hit_bonus
        );

        // G20 Katana does minimum damage against the T2 LVL40 Metal armor 
        assert(damage_results.total_damage == 4, 'T1 G20 vs T3 G30: 4hp');

        // Same battle but against a magical beast (cloth)
        armor.item_type = Type::Magic_or_Cloth;
        let damage_results = ImplCombat::calculate_damage(
            weapon,
            armor,
            minimum_damage,
            attacker_strength,
            defender_strength,
            critical_hit_chance,
            entropy
        );
        // deals significantly more damage
        assert(damage_results.total_damage == 215, 'T1 G20 vs T3 G30: 215hp');
    }

    #[test]
    #[available_gas(750000)]
    fn test_get_random_level() {
        let mut adventurer_level = 1;
        let _range_level_increase = 4;
        let _level_multiplier = 6;
        let _beast_level = ImplCombat::get_random_level(adventurer_level, 0);

        adventurer_level = 2;
        let min_beast_level = ImplCombat::get_random_level(adventurer_level, 0);
        let max_beast_level = ImplCombat::get_random_level(adventurer_level, 3);
        assert(min_beast_level == 1, 'on lvl2, min beast lvl is 1');
        assert(max_beast_level == 4, 'on lvl2, max beast lvl is 4');

        adventurer_level = 3;
        let min_beast_level = ImplCombat::get_random_level(adventurer_level, 0);
        let max_beast_level = ImplCombat::get_random_level(adventurer_level, 5);
        assert(min_beast_level == 1, 'on lvl3, min beast lvl is 1');
        assert(max_beast_level == 6, 'on lvl3, max beast lvl is 6');

        adventurer_level = 19;
        let min_beast_level = ImplCombat::get_random_level(adventurer_level, 0);
        let max_beast_level = ImplCombat::get_random_level(adventurer_level, 37);
        assert(min_beast_level == 1, 'on lvl19, min beast lvl is 1');
        assert(max_beast_level == 38, 'on lvl19, max beast lvl is 38');

        adventurer_level = 20;
        let max_beast_level = ImplCombat::get_random_level(adventurer_level, 39);
        let min_beast_level = ImplCombat::get_random_level(adventurer_level, 0);
        assert(min_beast_level == 11, 'on lvl20, min beast lvl is 11');
        assert(max_beast_level == 50, 'on lvl20, max beast lvl is 50');

        adventurer_level = 30;
        let max_beast_level = ImplCombat::get_random_level(adventurer_level, 59);
        let min_beast_level = ImplCombat::get_random_level(adventurer_level, 0);
        assert(min_beast_level == 21, 'on lvl30, min beast lvl is 21');
        assert(max_beast_level == 80, 'on lvl30, max beast lvl is 80');

        adventurer_level = 40;
        let max_beast_level = ImplCombat::get_random_level(adventurer_level, 79);
        let min_beast_level = ImplCombat::get_random_level(adventurer_level, 0);
        assert(min_beast_level == 41, 'on lvl40, min beast lvl is 31');
        assert(max_beast_level == 120, 'on lvl40, max beast lvl is 120');

        adventurer_level = 50;
        let max_beast_level = ImplCombat::get_random_level(adventurer_level, 99);
        let min_beast_level = ImplCombat::get_random_level(adventurer_level, 0);
        assert(min_beast_level == 81, 'on lvl50, min beast lvl is 51');
        assert(max_beast_level == 180, 'on lvl50, max beast lvl is 180');
    }

    #[test]
    #[available_gas(7480)]
    fn test_get_base_reward_gas() {
        let combat_spec = CombatSpec {
            item_type: Type::Blade_or_Hide,
            tier: Tier::T1,
            level: 1,
            specials: SpecialPowers { special1: 0, special2: 0, special3: 0 }
        };

        combat_spec.get_base_reward(1);
    }

    #[test]
    fn test_get_base_reward_overflow() {
        let combat_spec = CombatSpec {
            item_type: Type::Blade_or_Hide,
            tier: Tier::T1,
            level: 1,
            specials: SpecialPowers { special1: 0, special2: 0, special3: 0 }
        };

        combat_spec.get_base_reward(255);
    }

    #[test]
    fn test_get_base_reward() {
        // Initialize CombatSpec struct
        let mut combat_spec = CombatSpec {
            item_type: Type::Blade_or_Hide,
            tier: Tier::T1,
            level: 10,
            specials: SpecialPowers { special1: 0, special2: 0, special3: 0 }
        };

        // the xp reward for defeating a T1 level 10 beasts will decrease as the adventurer
        // increases in level
        let mut adventurer_level = 1;
        let base_reward = combat_spec.get_base_reward(adventurer_level);
        // println!("base reward: {}", base_reward);
        assert(base_reward == 24, 'base reward should be 24');

        adventurer_level = 5;
        let base_reward = combat_spec.get_base_reward(adventurer_level);
        // println!("base reward: {}", base_reward);
        assert(base_reward == 22, 'base reward should be 22');

        adventurer_level = 10;
        let base_reward = combat_spec.get_base_reward(adventurer_level);
        // println!("base reward: {}", base_reward);
        assert(base_reward == 20, 'base reward should be 20');

        adventurer_level = 15;
        let base_reward = combat_spec.get_base_reward(adventurer_level);
        // println!("base reward: {}", base_reward);
        assert(base_reward == 17, 'base reward should be 17');

        adventurer_level = 20;
        let base_reward = combat_spec.get_base_reward(adventurer_level);
        // println!("base reward: {}", base_reward);
        assert(base_reward == 15, 'base reward should be 15');

        adventurer_level = 25;
        let base_reward = combat_spec.get_base_reward(adventurer_level);
        // println!("base reward: {}", base_reward);
        assert(base_reward == 12, 'base reward should be 12');

        adventurer_level = 30;
        let base_reward = combat_spec.get_base_reward(adventurer_level);
        // println!("base reward: {}", base_reward);
        assert(base_reward == 10, 'base reward should be 10');

        adventurer_level = 35;
        let base_reward = combat_spec.get_base_reward(adventurer_level);
        // println!("base reward: {}", base_reward);
        assert(base_reward == 7, 'base reward should be 7');

        adventurer_level = 40;
        let base_reward = combat_spec.get_base_reward(adventurer_level);
        // println!("base reward: {}", base_reward);
        assert(base_reward == 5, 'base reward should be 5');

        adventurer_level = 45;
        let base_reward = combat_spec.get_base_reward(adventurer_level);
        // println!("base reward: {}", base_reward);
        assert(base_reward == 2, 'base reward should be 2');

        adventurer_level = 50;
        let base_reward = combat_spec.get_base_reward(adventurer_level);
        // println!("base reward: {}", base_reward);
        assert(base_reward == 1, 'base reward should be 1');
    }

    #[test]
    fn test_ability_based_avoid_threat() {
        let mut adventurer_level = 10;
        let mut relevant_stat = 10;
        let mut rnd = 0;

        // Test case 1: Relevant stat is greater than or equal to adventurer level
        assert(
            ImplCombat::ability_based_avoid_threat(adventurer_level, relevant_stat, rnd) == true,
            'Should avoidm stat equals lvl'
        );

        adventurer_level = 10;
        relevant_stat = 11;
        rnd = 0;
        assert(
            ImplCombat::ability_based_avoid_threat(adventurer_level, relevant_stat, rnd) == true,
            'Should avoid, stat exceeds lvl'
        );

        // Test case 2: Relevant stat is less than adventurer level, but avoids threat
        adventurer_level = 10;
        relevant_stat = 9;
        rnd = 0;
        assert(
            ImplCombat::ability_based_avoid_threat(adventurer_level, relevant_stat, rnd) == true,
            'Should avoid, low rnd'
        );

        // Test case 3: Relevant stat is less than adventurer level and fails to avoid threat
        adventurer_level = 10;
        relevant_stat = 5;
        rnd = 255;
        assert(
            ImplCombat::ability_based_avoid_threat(adventurer_level, relevant_stat, rnd) == false,
            'Should not avoid, max rnd'
        );

        // Test case 4: Edge case with minimum values
        adventurer_level = 1;
        relevant_stat = 1;
        rnd = 0;
        assert(
            ImplCombat::ability_based_avoid_threat(adventurer_level, relevant_stat, rnd) == true,
            'Should avoid, min values'
        );

        // Test case 5: Edge case with maximum adventurer level
        adventurer_level = 255;
        relevant_stat = 31;
        rnd = 128;
        assert(
            ImplCombat::ability_based_avoid_threat(adventurer_level, relevant_stat, rnd) == false,
            'Should not avoid, max lvl'
        );

        // Test case 6: Random middle ground test, with odds at 50%
        // 128 is the middle ground for a 50% chance
        adventurer_level = 50;
        relevant_stat = 25;
        rnd = 128;
        assert(
            ImplCombat::ability_based_avoid_threat(adventurer_level, relevant_stat, rnd) == false,
            'Should not avoid, middle ground'
        );
        rnd = 127;
        assert(
            ImplCombat::ability_based_avoid_threat(adventurer_level, relevant_stat, rnd) == true,
            'Should avoid, middle ground'
        );
    }
}
