use core::result::ResultTrait;
use core::serde::Serde;
use integer::{
    U64IntoU128, U16IntoU128, U128TryIntoU8, U8IntoU128, u16_overflowing_sub, u16_overflowing_add, U256TryIntoU32, U256TryIntoU16, U256TryIntoU8, U256TryIntoU64,
};
use traits::{TryInto, Into};
use option::OptionTrait;

use pack::pack::{
    pack_value, unpack_value
};
use pack::constants::{MASK_16, pow, MASK_8, MASK_BOOL, mask};

use lootitems::loot::{Loot, ILoot, ImplLoot};
use lootitems::statistics::{
    constants, item_tier, item_type, constants::Settings, constants::ItemSuffix
};

use super::exploration::ExploreUtils;
use super::constants::adventurer_constants::{
    STARTING_GOLD, StatisticIndex, POTION_PRICE, STARTING_HEALTH, CHARISMA_DISCOUNT,
    MINIMUM_ITEM_PRICE, MINIMUM_POTION_PRICE, ITEM_XP_MULTIPLIER
};
use super::constants::discovery_constants::DiscoveryEnums::{ExploreResult, TreasureDiscovery};
use super::item_meta::{
    LootStatistics, LootItemSpecialNames, LootItemSpecialNamesStorage, ImplLootItemSpecialNames
};

use combat::combat::{ImplCombat, CombatSpec, SpecialPowers};
use combat::constants::CombatEnums::{Type, Tier, Slot};
use obstacles::obstacle::{ImplObstacle, Obstacle};
use beasts::beast::{ImplBeast, Beast};
use beasts::constants::BeastSettings;

#[derive(Drop, Copy, Serde)]
struct Stats { // 5 bits each
    // Physical
    strength: u8, // increases attack damage
    dexterity: u8, // increases flee chance
    vitality: u8, // increases health
    // Mental
    intelligence: u8, // increases obstacle avoidance
    wisdom: u8, // increase ambush avoidance
    charisma: u8, // provides shop discount
}

#[derive(Drop, Copy, Serde)]
struct Adventurer {
    last_action: u16, // 3 bits
    health: u16, // 9 bits     
    xp: u16, // 13 bits
    stats: Stats,
    gold: u16, // 9 bits
    weapon: LootStatistics, // 24 bits
    chest: LootStatistics, // 24 bits
    head: LootStatistics, // 24 bits
    waist: LootStatistics, // 24 bits
    foot: LootStatistics, // 24 bits
    hand: LootStatistics, // 24 bits
    neck: LootStatistics, // 24 bits
    ring: LootStatistics, // 24 bits
    // Beast health
    beast_health: u16,
    stat_upgrade_available: u8, // 3 bits
}

#[generate_trait]
impl ImplAdventurer of IAdventurer {
    fn charisma_potion_discount(self: Adventurer, item_stat_boost: u8) -> u16 {
        CHARISMA_DISCOUNT * self.stats.charisma.into()
    }

    fn charisma_item_discount(self: Adventurer, item_stat_boost: u8) -> u16 {
        CHARISMA_DISCOUNT * self.stats.charisma.into()
    }

    fn get_item_cost(self: Adventurer, item_cost: u16, item_stat_boost: u8) -> u16 {
        if (u16_overflowing_sub(item_cost, self.charisma_item_discount(item_stat_boost)).is_ok()) {
            let cost = item_cost - self.charisma_item_discount(item_stat_boost);

            if (cost < MINIMUM_ITEM_PRICE) {
                MINIMUM_ITEM_PRICE
            } else {
                cost
            }
        } else {
            MINIMUM_ITEM_PRICE
        }
    }

    fn get_potion_cost(ref self: Adventurer, item_stat_boost: u8) -> u16 {
        // check if we overflow
        if (u16_overflowing_sub(
            POTION_PRICE * self.get_level().into(), self.charisma_potion_discount(item_stat_boost)
        )
            .is_ok()) {
            let price = POTION_PRICE * self.get_level().into()
                - self.charisma_potion_discount(item_stat_boost);

            // check if less than the base price - this can only happen rarely
            if (price < MINIMUM_POTION_PRICE) {
                MINIMUM_POTION_PRICE
            } else {
                price
            }
        } else {
            MINIMUM_POTION_PRICE
        }
    }
    fn add_statistic(ref self: Adventurer, value: u8) -> Adventurer {
        assert(value < 6, 'Index out of bounds');
        if (value == StatisticIndex::STRENGTH) {
            self.add_strength(1)
        } else if (value == StatisticIndex::DEXTERITY) {
            self.add_dexterity(1)
        } else if (value == StatisticIndex::VITALITY) {
            self.add_vitality(1)
        } else if (value == StatisticIndex::INTELLIGENCE) {
            self.add_intelligence(1)
        } else if (value == StatisticIndex::WISDOM) {
            self.add_wisdom(1)
        } else {
            self.add_charisma(1)
        }
    }
    // get_random_explore returns a random number between 0 and 3 based on provided entropy
    // @param entropy: entropy for generating random explore
    // @return u64: A random number between 0 and 3 denoting the outcome of the explore
    fn get_random_explore(entropy: u128) -> ExploreResult {
        let result = entropy % 3;
        if (result == 0) {
            return ExploreResult::Beast(());
        } else if (result == 1) {
            return ExploreResult::Obstacle(());
        } else {
            return ExploreResult::Treasure(());
        }
    }
    fn deduct_gold(ref self: Adventurer, value: u16) -> Adventurer {
        self.gold -= value;

        if (self.gold < 0) {
            self.gold = 0;
        }

        self
    }
    fn check_gold(self: Adventurer, value: u16) -> bool {
        self.gold >= value
    }

    // get_item_at_slot returns the item at a given item slot
    // @param self: Adventurer to check
    // @param slot: Slot to check
    // @return LootStatistics: Item at slot
    fn get_item_at_slot(self: Adventurer, slot: Slot) -> LootStatistics {
        match slot {
            Slot::Weapon(()) => self.weapon,
            Slot::Chest(()) => self.chest,
            Slot::Head(()) => self.head,
            Slot::Waist(()) => self.waist,
            Slot::Foot(()) => self.foot,
            Slot::Hand(()) => self.hand,
            Slot::Neck(()) => self.neck,
            Slot::Ring(()) => self.ring,
        }
    }

    // is_slot_free checks if an item slot is free for an adventurer
    // @param self: Adventurer to check
    // @param item: Item to check
    // @return bool: True if slot is free, false if not
    fn is_slot_free(self: Adventurer, item: LootStatistics) -> bool {
        let slot = ImplLoot::get_slot(item.id);
        match slot {
            Slot::Weapon(()) => self.weapon.id == 0,
            Slot::Chest(()) => self.chest.id == 0,
            Slot::Head(()) => self.head.id == 0,
            Slot::Waist(()) => self.waist.id == 0,
            Slot::Foot(()) => self.foot.id == 0,
            Slot::Hand(()) => self.hand.id == 0,
            Slot::Neck(()) => self.neck.id == 0,
            Slot::Ring(()) => self.ring.id == 0,
        }
    }
    fn get_beast(self: Adventurer) -> u8 {
        // TODO: return Beast struct generated from xp
        return 1;
    }

    fn get_level(self: Adventurer) -> u8 {
        return ImplCombat::get_level_from_xp(self.xp);
    }

    // beast_encounter psuedo discovers a beast for an adventurer
    // since the beast is generated at runtime, we simply need to set the
    // beasts health which will enable the contract to detect the adventurer is in a battle
    // allowing adventurer to call "attack"
    // @param self: Adventurer to discover beast for
    // @param entropy: Entropy for generating beast
    // @return Adventurer: Adventurer with beast discovered
    fn beast_encounter(ref self: Adventurer, battle_fixed_seed: u128) -> Beast {
        // generate battle fixed entropy by combining adventurer xp and adventurer entropy
        let battle_fixed_entropy: u128 = self
            .get_battle_fixed_entropy(U128TryIntoU64::try_into(battle_fixed_seed).unwrap());

        // generate special names for beast using Loot name schema. 
        // We use Loot names because the combat system will deal bonus damage for matching names (these are the items super powers)
        // We do this here instead of in beast to prevent beast from depending on Loot
        let prefix1 = U128TryIntoU8::try_into(
            battle_fixed_entropy % U8IntoU128::into(constants::NamePrefixLength)
        )
            .unwrap();
        let prefix2 = U128TryIntoU8::try_into(
            battle_fixed_entropy % U8IntoU128::into(constants::NameSuffixLength)
        )
            .unwrap();

        // use the randomly generated prefixes but set suffic to 0
        let special_names = SpecialPowers { prefix1: prefix1, prefix2: prefix2, suffix: 0 };

        // get beast using battle fixed seed
        // this is important because in the context of this call
        // the player has just encountered the beast and will 
        // subsequently be calling "attack" to attack the beast
        // to enable the adventurer state to fit in a single 252felt, we
        // don't store anything about the beast in the adventurer state
        // except it's health. Instead the beast is generated at run-time
        // via the battle_fixed_seed
        let beast = ImplBeast::get_beast(self.get_level(), special_names, battle_fixed_seed);

        // otherwise generate random starting health for the beast
        self.add_beast(beast.starting_health);

        // return beast
        return beast;
    }

    fn discover_treasure(ref self: Adventurer, entropy: u128) -> (TreasureDiscovery, u16) {
        // generate random item discovery
        let item_type = ExploreUtils::get_random_treasury_discovery(self, entropy);

        match item_type {
            TreasureDiscovery::Gold(()) => {
                let gold_amount = ExploreUtils::get_gold_discovery(self, entropy);
                // add the gold to the adventurer
                self.increase_gold(gold_amount);
                return (TreasureDiscovery::Gold(()), gold_amount);
            },
            TreasureDiscovery::XP(()) => {
                let xp_amount = ExploreUtils::get_xp_discovery(
                    self, entropy
                ); // add the xp to the adventurer
                self.increase_adventurer_xp(xp_amount); // if the discovery is an item
                return (TreasureDiscovery::XP(()), xp_amount);
            },
            TreasureDiscovery::Health(()) => {
                let health_amount = ExploreUtils::get_health_discovery(
                    self, entropy
                ); // add the health to the adventurer
                self.add_health(health_amount);
                return (TreasureDiscovery::Health(()), health_amount);
            },
        }
    }

    // TODO: implement this function
    fn attack(ref self: Adventurer, entropy: u128) -> Adventurer {
        // get beast from adventurer
        // combat::calculate_damage_to_beast(adventurer, beast, adventurer_entropy, game_entropy);
        // if beast is dead, add xp to adventurer and items
        // if beast is not dead, calculate damage to adventurer and return adventurer
        //      the adventurer will have updated health for both adventurer and beast
        return self;
    }

    // TODO: implement this function
    fn flee(ref self: Adventurer, entropy: u128) -> Adventurer {
        // combat::attempt_flee(adventurer, adventurer_entropy, game_entropy;
        // if successful, return adventurer with adventurer.beast_health = 0;
        // if not successful, process beast counter_attack and return adventurer
        return self;
    }


    // luck 
    fn get_luck(self: Adventurer) -> u8 {
        // get greatness of aventurers equipped necklace
        let necklace_greatness = ImplLoot::get_greatness_level(self.neck.xp);
        // get greatness of aventurers equipped ring
        let ring_greatness = ImplLoot::get_greatness_level(self.neck.xp);

        // luck is combined greatness of equipped jewlery
        return necklace_greatness + ring_greatness;
    }

    // in_battle returns true if the adventurer is in battle
    // @param self: Adventurer the adventurer to check if in battle
    // @return bool true if the adventurer is in battle, false otherwise
    fn in_battle(self: Adventurer) -> bool {
        if self.beast_health > 0 {
            true
        } else {
            false
        }
    }

    // deduct_beast_health deducts the beast health from the adventurer
    // if the beast health is less than 0, it sets the beast health to 0
    // @param self: Adventurer the adventurer to deduct the beast health from
    // @param value: u16 the amount to deduct from the beast health
    // @return Adventurer the adventurer with the beast health deducted
    fn deduct_beast_health(ref self: Adventurer, amount: u16) -> Adventurer {
        let mut new_beast_health = self.beast_health - amount;

        // check if killed
        if new_beast_health < 0 {
            self.beast_health = 0;
        } else {
            self.beast_health = new_beast_health;
        }
        self
    }
    fn add_beast(ref self: Adventurer, value: u16) -> Adventurer {
        self.beast_health = value;
        self
    }
    fn add_health(ref self: Adventurer, value: u16) -> Adventurer {
        // TODO: overflow check
        self.health = self.health + value;

        self
    }

    fn increase_gold(ref self: Adventurer, value: u16) -> Adventurer {
        // TODO: overflow check
        self.gold = self.gold + value;

        self
    }
    fn deduct_health(ref self: Adventurer, value: u16) -> Adventurer {
        // if amount to deduct is greater than or equal to health of adventurer
        if value >= self.health {
            // set adventurer health to zero
            self.health = 0;
        } else {
            // otherwise deduct amount
            self.health -= value;
        }

        // return adventurer
        self
    }
    fn increase_adventurer_xp(ref self: Adventurer, value: u16) -> Adventurer {
        let previous_level = self.get_level();
        self.xp = self.xp + value;
        let new_level = self.get_level();
        // add the difference between previous level and new level to stat upgrades
        self.stat_upgrade_available += (new_level - previous_level);
        self
    }
    fn add_strength(ref self: Adventurer, value: u8) -> Adventurer {
        self.stats.strength = self.stats.strength + value;
        self
    }
    fn add_dexterity(ref self: Adventurer, value: u8) -> Adventurer {
        self.stats.dexterity = self.stats.dexterity + value;
        self
    }
    fn add_vitality(ref self: Adventurer, value: u8) -> Adventurer {
        self.stats.vitality = self.stats.vitality + value;
        self
    }
    fn add_intelligence(ref self: Adventurer, value: u8) -> Adventurer {
        self.stats.intelligence = self.stats.intelligence + value;
        self
    }
    fn add_wisdom(ref self: Adventurer, value: u8) -> Adventurer {
        self.stats.wisdom = self.stats.wisdom + value;
        self
    }
    fn add_charisma(ref self: Adventurer, value: u8) -> Adventurer {
        self.stats.charisma = self.stats.charisma + value;
        self
    }
    fn add_item(ref self: Adventurer, value: LootStatistics) -> Adventurer {
        // TODO: @loaf does this need to check to ensure an item isn't
        // already assigned to that slot? The other consideration I 
        // thought of while writing test cases is dealing with 
        // two items having the same meta data id. Is this handled somewhere?
        let slot = ImplLoot::get_slot(value.id);
        match slot {
            Slot::Weapon(()) => self.add_weapon(value),
            Slot::Chest(()) => self.add_chest(value),
            Slot::Head(()) => self.add_head(value),
            Slot::Waist(()) => self.add_waist(value),
            Slot::Foot(()) => self.add_foot(value),
            Slot::Hand(()) => self.add_hand(value),
            Slot::Neck(()) => self.add_neck(value),
            Slot::Ring(()) => self.add_ring(value),
        }
        self
    }
    fn add_weapon(ref self: Adventurer, value: LootStatistics) -> Adventurer {
        self.weapon = value;
        self
    }
    fn add_chest(ref self: Adventurer, value: LootStatistics) -> Adventurer {
        self.chest = value;
        self
    }
    fn add_head(ref self: Adventurer, value: LootStatistics) -> Adventurer {
        self.head = value;
        self
    }
    fn add_waist(ref self: Adventurer, value: LootStatistics) -> Adventurer {
        self.waist = value;
        self
    }
    fn add_foot(ref self: Adventurer, value: LootStatistics) -> Adventurer {
        self.foot = value;
        self
    }
    fn add_hand(ref self: Adventurer, value: LootStatistics) -> Adventurer {
        self.hand = value;
        self
    }
    fn add_neck(ref self: Adventurer, value: LootStatistics) -> Adventurer {
        self.neck = value;
        self
    }
    fn add_ring(ref self: Adventurer, value: LootStatistics) -> Adventurer {
        self.ring = value;
        self
    }

    // @title Increase Item Experience
    // @notice This function is used to increase the experience points of a particular item.
    // @dev This function calls the grant_xp_and_check_for_greatness_increase function to execute its logic.
    //
    // @param self A reference to the LootStatistics object which represents the item.
    // @param amount The amount of experience points to be added to the item.
    // @param name_storage A reference to the LootItemSpecialNamesStorage object.
    // @param entropy A number used for randomization.
    //
    // @return Returns a tuple containing the original item level, new level, 
    //         boolean indicating if a suffix was assigned, boolean indicating if a prefix was assigned,
    //         and a LootItemSpecialNames object storing the special names for the item.
    fn increase_item_xp(
        ref self: LootStatistics,
        amount: u16,
        ref name_storage: LootItemSpecialNamesStorage,
        entropy: u128
    ) -> (u8, u8, bool, bool, LootItemSpecialNames) {
        return self.grant_xp_and_check_for_greatness_increase(amount, ref name_storage, entropy);
    }

    // @title Grant Experience and Check for Greatness Increase
    // @notice This function increases the experience points of an item and checks for possible level ups, assigning prefixes and suffixes as necessary.
    // @dev The function should only be used internally within the smart contract.
    //
    // @param self A reference to the LootStatistics object which represents the item.
    // @param value The amount of experience points to be added to the item.
    // @param name_storage A reference to the LootItemSpecialNamesStorage object.
    // @param entropy A number used for randomization.
    //
    // @return Returns a tuple containing the original item level, new level, 
    //         boolean indicating if a suffix was assigned, boolean indicating if a prefix was assigned,
    //         and a LootItemSpecialNames object storing the special names for the item.
    fn grant_xp_and_check_for_greatness_increase(
        ref self: LootStatistics,
        value: u16,
        ref name_storage: LootItemSpecialNamesStorage,
        entropy: u128
    ) -> (u8, u8, bool, bool, LootItemSpecialNames) {
        // get the previous level of the item
        let original_level = ImplLoot::get_greatness_level(self.xp);

        if (u16_overflowing_add(self.xp, value).is_ok()) {
            self.xp += value;
        } else {
            self.xp = 65535;
        }

        // get the new level of the item
        let new_level = ImplLoot::get_greatness_level(self.xp);

        // initialize return bools to false
        let mut prefix_assigned = false;
        let mut suffix_assigned = false;

        // if the level is the same
        if (original_level == new_level) {
            // no additional work required, return false for item changed and empty LootItemSpecialNames
            return (
                original_level, new_level, suffix_assigned, prefix_assigned, LootItemSpecialNames {
                    name_prefix: 0, name_suffix: 0, item_suffix: 0
                }
            );
        }

        // If the item leveled up, we need to check if it has reached G15 or G19 and
        // unlocked a name suffix or prefix

        // if the item was able to level up from below greatness 15 to 19 (unlikely but possible)
        if (original_level < 15 && new_level >= 19) {
            // set return bools both to true
            suffix_assigned = true;
            prefix_assigned = true;
            // we assign the item it's prefixes and suffix
            let special_names = LootItemSpecialNames {
                name_prefix: ImplLoot::get_name_prefix(self.id, entropy),
                name_suffix: ImplLoot::get_name_suffix(self.id, entropy),
                item_suffix: ImplLoot::get_item_suffix(self.id, entropy),
            };

            ImplLootItemSpecialNames::set_loot_special_names(
                ref name_storage, self, special_names, 
            );
            return (original_level, new_level, suffix_assigned, prefix_assigned, special_names);
        } // a more likely scenario is the item was previously below greatness 15 and is now at 15 or above
        // in this case we only need to assign the name suffix (Of Power)
        else if (original_level < 15 && new_level >= 15) {
            // return bool suffix assigned is now true
            suffix_assigned = true;
            // return bool of prefix assigned will remain 

            let special_names = LootItemSpecialNames {
                name_prefix: 0,
                name_suffix: 0,
                item_suffix: ImplLoot::get_item_suffix(self.id, entropy), // set item suffix
            };
            ImplLootItemSpecialNames::set_loot_special_names(ref name_storage, self, special_names);
            return (original_level, new_level, suffix_assigned, prefix_assigned, special_names);
        } // lastly, we check for the transition from below G19 to G19 or higher which results
        // in the item receiving a name prefix (Demon Grasp)
        else if (original_level < 19 && new_level >= 19) {
            // return bool prefix assigned is now true
            prefix_assigned = true;
            // return bool suffix will keep default of false

            // When handling the greatness upgrade to G19 we need to ensure we preserve
            // the item name suffix applied at G15.
            let special_names = LootItemSpecialNames {
                name_prefix: ImplLoot::get_name_prefix(self.id, entropy),
                name_suffix: ImplLoot::get_name_suffix(self.id, entropy),
                item_suffix: ImplLootItemSpecialNames::get_loot_special_names(name_storage, self)
                    .item_suffix, // preserve previous item suffix from G15
            };

            ImplLootItemSpecialNames::set_loot_special_names(ref name_storage, self, special_names);

            return (original_level, new_level, suffix_assigned, prefix_assigned, special_names);
        }

        // level up should be true here but suffix and prefix assigned false
        return (
            original_level, new_level, suffix_assigned, prefix_assigned, LootItemSpecialNames {
                name_prefix: 0, name_suffix: 0, item_suffix: 0
            }
        );
    }

    // create a new adventurer from a starting item and a block number
    // the block number is used to set the last action
    // the starting item is used to set the starting weapon
    // @param starting_item: the id of the starting item
    // @param block_number: the block number of the block that the adventurer was created in
    // @return Adventurer: the new adventurer
    fn new(starting_item: u8, block_number: u64) -> Adventurer {
        let last_action: u16 = (block_number % 512).try_into().unwrap();

        return Adventurer {
            last_action: last_action, health: STARTING_HEALTH, xp: 0, stats: Stats {
                strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0
                }, gold: STARTING_GOLD, weapon: LootStatistics {
                id: starting_item, xp: 0, metadata: 1, 
                }, chest: LootStatistics {
                id: 0, xp: 0, metadata: 0, 
                }, head: LootStatistics {
                id: 0, xp: 0, metadata: 0, 
                }, waist: LootStatistics {
                id: 0, xp: 0, metadata: 0, 
                }, foot: LootStatistics {
                id: 0, xp: 0, metadata: 0, 
                }, hand: LootStatistics {
                id: 0, xp: 0, metadata: 0, 
                }, neck: LootStatistics {
                id: 0, xp: 0, metadata: 0, 
                }, ring: LootStatistics {
                id: 0, xp: 0, metadata: 0, 
            }, beast_health: BeastSettings::STARTER_BEAST_HEALTH, stat_upgrade_available: 0,
        };
    }


    // get_battle_fixed_entropy provides an entropy source that is fixed during battle
    // it intentionally does not use game_entropy as that could change during battle and this
    // entropy allows us to simulate a persistent battle without having to store beast
    // details on-chain.
    fn get_battle_fixed_entropy(self: Adventurer, adventurer_entropy: u64) -> u128 {
        return U16IntoU128::into(self.xp) + U64IntoU128::into(adventurer_entropy);
    }

    fn get_random_armor_slot(entropy: u128) -> Slot {
        // get a number between 0 and 5 inclusive
        let slot = entropy % 6;

        // return slot for each outcome
        if (slot == 1) {
            return Slot::Chest(());
        } else if (slot == 2) {
            return Slot::Head(());
        } else if (slot == 3) {
            return Slot::Waist(());
        } else if (slot == 4) {
            return Slot::Foot(());
        } else if (slot == 5) {
            return Slot::Hand(());
        }

        // fall through to Hand
        return Slot::Hand(());
    }

    fn add_suffix_boost(ref self: Stats, suffix: u8, ) {
        if (suffix == ItemSuffix::of_Power) {
            self.strength += 3;
        } else if (suffix == ItemSuffix::of_Giant) {
            self.vitality += 3;
        } else if (suffix == ItemSuffix::of_Titans) {
            self.strength += 2;
            self.charisma += 1;
        } else if (suffix == ItemSuffix::of_Skill) {
            self.dexterity += 3;
        } else if (suffix == ItemSuffix::of_Perfection) {
            self.strength += 1;
            self.dexterity += 1;
            self.vitality += 1;
        } else if (suffix == ItemSuffix::of_Brilliance) {
            self.intelligence += 3;
        } else if (suffix == ItemSuffix::of_Enlightenment) {
            self.wisdom += 3;
        } else if (suffix == ItemSuffix::of_Protection) {
            self.vitality += 2;
            self.dexterity += 1;
        } else if (suffix == ItemSuffix::of_Anger) {
            self.strength += 2;
            self.dexterity += 1;
        } else if (suffix == ItemSuffix::of_Rage) {
            self.strength += 1;
            self.charisma += 1;
            self.wisdom += 1;
        } else if (suffix == ItemSuffix::of_Fury) {
            self.vitality += 1;
            self.charisma += 1;
            self.intelligence += 1;
        } else if (suffix == ItemSuffix::of_Vitriol) {
            self.intelligence += 2;
            self.wisdom += 1;
        } else if (suffix == ItemSuffix::of_the_Fox) {
            self.dexterity += 2;
            self.charisma += 1;
        } else if (suffix == ItemSuffix::of_Detection) {
            self.wisdom += 2;
            self.dexterity += 1;
        } else if (suffix == ItemSuffix::of_Reflection) {
            self.intelligence += 1;
            self.wisdom += 2;
        } else if (suffix == ItemSuffix::of_the_Twins) {
            self.charisma += 3;
        }
    }

    fn get_suffix_stat_boosts(
        self: Adventurer,
        name_storage1: LootItemSpecialNamesStorage,
        name_storage2: LootItemSpecialNamesStorage
    ) -> Stats {
        let mut boosted_stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0, 
        };

        if (ImplLoot::get_greatness_level(self.weapon.xp) >= 15) {
            if (ImplAdventurer::get_storage_index(self.weapon.metadata) == 0) {
                let weapon_names = ImplLootItemSpecialNames::get_loot_special_names(
                    name_storage1, self.weapon
                );
                boosted_stats.add_suffix_boost(weapon_names.item_suffix, );
            } else {
                let weapon_names = ImplLootItemSpecialNames::get_loot_special_names(
                    name_storage2, self.weapon
                );
                boosted_stats.add_suffix_boost(weapon_names.item_suffix, );
            }
        }
        if (ImplLoot::get_greatness_level(self.chest.xp) >= 15) {
            if (ImplAdventurer::get_storage_index(self.chest.metadata) == 0) {
                let chest_names = ImplLootItemSpecialNames::get_loot_special_names(
                    name_storage1, self.chest
                );
                boosted_stats.add_suffix_boost(chest_names.item_suffix, );
            } else {
                let chest_names = ImplLootItemSpecialNames::get_loot_special_names(
                    name_storage2, self.chest
                );

                boosted_stats.add_suffix_boost(chest_names.item_suffix, );
            }
        }
        if (ImplLoot::get_greatness_level(self.head.xp) >= 15) {
            if (ImplAdventurer::get_storage_index(self.head.metadata) == 0) {
                let head_names = ImplLootItemSpecialNames::get_loot_special_names(
                    name_storage1, self.head
                );
                boosted_stats.add_suffix_boost(head_names.item_suffix, );
            } else {
                let head_names = ImplLootItemSpecialNames::get_loot_special_names(
                    name_storage2, self.head
                );
                boosted_stats.add_suffix_boost(head_names.item_suffix, );
            }
        }
        if (ImplLoot::get_greatness_level(self.waist.xp) >= 15) {
            if (ImplAdventurer::get_storage_index(self.waist.metadata) == 0) {
                let waist_names = ImplLootItemSpecialNames::get_loot_special_names(
                    name_storage1, self.waist
                );
                boosted_stats.add_suffix_boost(waist_names.item_suffix, );
            } else {
                let waist_names = ImplLootItemSpecialNames::get_loot_special_names(
                    name_storage2, self.waist
                );
                boosted_stats.add_suffix_boost(waist_names.item_suffix, );
            }
        }

        if (ImplLoot::get_greatness_level(self.foot.xp) >= 15) {
            if (ImplAdventurer::get_storage_index(self.foot.metadata) == 0) {
                let foot_names = ImplLootItemSpecialNames::get_loot_special_names(
                    name_storage1, self.foot
                );
                boosted_stats.add_suffix_boost(foot_names.item_suffix, );
            } else {
                let foot_names = ImplLootItemSpecialNames::get_loot_special_names(
                    name_storage2, self.foot
                );
                boosted_stats.add_suffix_boost(foot_names.item_suffix, );
            }
        }

        if (ImplLoot::get_greatness_level(self.hand.xp) >= 15) {
            if (ImplAdventurer::get_storage_index(self.hand.metadata) == 0) {
                let hand_names = ImplLootItemSpecialNames::get_loot_special_names(
                    name_storage1, self.hand
                );
                boosted_stats.add_suffix_boost(hand_names.item_suffix, );
            } else {
                let hand_names = ImplLootItemSpecialNames::get_loot_special_names(
                    name_storage2, self.hand
                );

                boosted_stats.add_suffix_boost(hand_names.item_suffix, );
            }
        }

        if (ImplLoot::get_greatness_level(self.neck.xp) >= 15) {
            if (ImplAdventurer::get_storage_index(self.neck.metadata) == 0) {
                let neck_names = ImplLootItemSpecialNames::get_loot_special_names(
                    name_storage1, self.neck
                );

                boosted_stats.add_suffix_boost(neck_names.item_suffix, );
            } else {
                let neck_names = ImplLootItemSpecialNames::get_loot_special_names(
                    name_storage2, self.neck
                );

                boosted_stats.add_suffix_boost(neck_names.item_suffix, );
            }
        }

        if (ImplLoot::get_greatness_level(self.ring.xp) >= 15) {
            // we need to get the suffix which is in one of the two meta data storages
            if (ImplAdventurer::get_storage_index(self.ring.metadata) == 0) {
                // it's in storage slot 1
                let ring_names = ImplLootItemSpecialNames::get_loot_special_names(
                    name_storage1, self.ring
                );

                boosted_stats.add_suffix_boost(ring_names.item_suffix, );
            } else {
                // it's in storage slot 2
                let ring_names = ImplLootItemSpecialNames::get_loot_special_names(
                    name_storage2, self.ring
                );

                boosted_stats.add_suffix_boost(ring_names.item_suffix, );
            }
        }
        return boosted_stats;
    }

    fn get_storage_index(meta_data_id: u8) -> u256 {
        if (meta_data_id <= 10) {
            return 0;
        } else {
            return 1;
        }
    }


    // pack the adventurer into a single felt252
    // this is used to store the adventurer in the contract
    // @return the packed adventurer
    fn pack(self: Adventurer) -> felt252 {
        let mut packed = 0;
        packed = packed | pack_value(self.last_action.into(), pow::TWO_POW_242);
        packed = packed | pack_value(self.health.into(), pow::TWO_POW_233);
        packed = packed | pack_value(self.xp.into(), pow::TWO_POW_220);
        packed = packed | pack_value(self.stats.strength.into(), pow::TWO_POW_215);
        packed = packed | pack_value(self.stats.dexterity.into(), pow::TWO_POW_210);
        packed = packed | pack_value(self.stats.vitality.into(), pow::TWO_POW_205);
        packed = packed | pack_value(self.stats.intelligence.into(), pow::TWO_POW_200);
        packed = packed | pack_value(self.stats.wisdom.into(), pow::TWO_POW_195);
        packed = packed | pack_value(self.stats.charisma.into(), pow::TWO_POW_190);
        packed = packed | pack_value(self.gold.into(), pow::TWO_POW_181);

        packed = packed | pack_value(self.weapon.id.into(), pow::TWO_POW_174);
        packed = packed | pack_value(self.weapon.xp.into(), pow::TWO_POW_165);
        packed = packed | pack_value(self.weapon.metadata.into(), pow::TWO_POW_160);

        packed = packed | pack_value(self.chest.id.into(), pow::TWO_POW_153);
        packed = packed | pack_value(self.chest.xp.into(), pow::TWO_POW_144);
        packed = packed | pack_value(self.chest.metadata.into(), pow::TWO_POW_139);

        packed = packed | pack_value(self.head.id.into(), pow::TWO_POW_132);
        packed = packed | pack_value(self.head.xp.into(), pow::TWO_POW_123);
        packed = packed | pack_value(self.head.metadata.into(), pow::TWO_POW_118);

        packed = packed | pack_value(self.waist.id.into(), pow::TWO_POW_111);
        packed = packed | pack_value(self.waist.xp.into(), pow::TWO_POW_102);
        packed = packed | pack_value(self.waist.metadata.into(), pow::TWO_POW_97);

        packed = packed | pack_value(self.foot.id.into(), pow::TWO_POW_90);
        packed = packed | pack_value(self.foot.xp.into(), pow::TWO_POW_81);
        packed = packed | pack_value(self.foot.metadata.into(), pow::TWO_POW_76);

        packed = packed | pack_value(self.hand.id.into(), pow::TWO_POW_69);
        packed = packed | pack_value(self.hand.xp.into(), pow::TWO_POW_60);
        packed = packed | pack_value(self.hand.metadata.into(), pow::TWO_POW_55);

        packed = packed | pack_value(self.neck.id.into(), pow::TWO_POW_48);
        packed = packed | pack_value(self.neck.xp.into(), pow::TWO_POW_39);
        packed = packed | pack_value(self.neck.metadata.into(), pow::TWO_POW_34);

        packed = packed | pack_value(self.ring.id.into(), pow::TWO_POW_27);
        packed = packed | pack_value(self.ring.xp.into(), pow::TWO_POW_18);
        packed = packed | pack_value(self.ring.metadata.into(), pow::TWO_POW_13);

        packed = packed | pack_value(self.beast_health.into(), pow::TWO_POW_3);

        packed = packed | pack_value(self.stat_upgrade_available.into(), 1);

        packed.try_into().unwrap()
    }

    // unpack a felt252 into an Adventurer
    // @param packed: felt252
    // @return Adventurer
    fn unpack(packed: felt252) -> Adventurer {
        let packed = packed.into();

        Adventurer {
            last_action: U256TryIntoU16::try_into(
                unpack_value(packed, pow::TWO_POW_242, mask::MASK_9)
            )
                .unwrap(),
            health: U256TryIntoU16::try_into(unpack_value(packed, pow::TWO_POW_233, mask::MASK_10))
                .unwrap(),
            xp: U256TryIntoU16::try_into(unpack_value(packed, pow::TWO_POW_220, mask::MASK_13))
                .unwrap(),
            stats: Stats {
                strength: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_215, mask::MASK_5)
                )
                    .unwrap(),
                dexterity: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_210, mask::MASK_5)
                )
                    .unwrap(),
                vitality: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_205, mask::MASK_5)
                )
                    .unwrap(),
                intelligence: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_200, mask::MASK_5)
                )
                    .unwrap(),
                wisdom: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_195, mask::MASK_5)
                )
                    .unwrap(),
                charisma: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_190, mask::MASK_5)
                )
                    .unwrap()
                },
                gold: U256TryIntoU16::try_into(unpack_value(packed, pow::TWO_POW_181, mask::MASK_9))
                    .unwrap(),
                weapon: LootStatistics {
                id: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_174, mask::MASK_7))
                    .unwrap(),
                xp: U256TryIntoU16::try_into(unpack_value(packed, pow::TWO_POW_165, mask::MASK_9))
                    .unwrap(),
                metadata: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_160, mask::MASK_5)
                )
                    .unwrap(),
                }, chest: LootStatistics {
                id: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_153, mask::MASK_7))
                    .unwrap(),
                xp: U256TryIntoU16::try_into(unpack_value(packed, pow::TWO_POW_144, mask::MASK_9))
                    .unwrap(),
                metadata: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_139, mask::MASK_5)
                )
                    .unwrap(),
                }, head: LootStatistics {
                id: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_132, mask::MASK_7))
                    .unwrap(),
                xp: U256TryIntoU16::try_into(unpack_value(packed, pow::TWO_POW_123, mask::MASK_9))
                    .unwrap(),
                metadata: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_118, mask::MASK_5)
                )
                    .unwrap(),
                }, waist: LootStatistics {
                id: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_111, mask::MASK_7))
                    .unwrap(),
                xp: U256TryIntoU16::try_into(unpack_value(packed, pow::TWO_POW_102, mask::MASK_9))
                    .unwrap(),
                metadata: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_97, mask::MASK_5)
                )
                    .unwrap(),
                }, foot: LootStatistics {
                id: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_90, mask::MASK_7))
                    .unwrap(),
                xp: U256TryIntoU16::try_into(unpack_value(packed, pow::TWO_POW_81, mask::MASK_9))
                    .unwrap(),
                metadata: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_76, mask::MASK_5)
                )
                    .unwrap(),
                }, hand: LootStatistics {
                id: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_69, mask::MASK_7))
                    .unwrap(),
                xp: U256TryIntoU16::try_into(unpack_value(packed, pow::TWO_POW_60, mask::MASK_9))
                    .unwrap(),
                metadata: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_55, mask::MASK_5)
                )
                    .unwrap(),
                }, neck: LootStatistics {
                id: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_48, mask::MASK_7))
                    .unwrap(),
                xp: U256TryIntoU16::try_into(unpack_value(packed, pow::TWO_POW_39, mask::MASK_9))
                    .unwrap(),
                metadata: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_34, mask::MASK_5)
                )
                    .unwrap(),
                }, ring: LootStatistics {
                id: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_27, mask::MASK_7))
                    .unwrap(),
                xp: U256TryIntoU16::try_into(unpack_value(packed, pow::TWO_POW_18, mask::MASK_9))
                    .unwrap(),
                metadata: U256TryIntoU8::try_into(
                    unpack_value(packed, pow::TWO_POW_13, mask::MASK_5)
                )
                    .unwrap(),
            },
            beast_health: U256TryIntoU16::try_into(
                unpack_value(packed, pow::TWO_POW_3, mask::MASK_10)
            )
                .unwrap(),
            stat_upgrade_available: U256TryIntoU8::try_into(unpack_value(packed, 1, mask::MASK_3))
                .unwrap(),
        }
    }
}
#[test]
#[available_gas(5000000)]
fn test_adventurer() {
    let adventurer = Adventurer {
        last_action: 511, health: 1023, xp: 8191, stats: Stats {
            strength: 31, dexterity: 31, vitality: 31, intelligence: 31, wisdom: 31, charisma: 31, 
            }, gold: 511, weapon: LootStatistics {
            id: 100, xp: 511, metadata: 1, 
            }, chest: LootStatistics {
            id: 99, xp: 511, metadata: 2, 
            }, head: LootStatistics {
            id: 98, xp: 511, metadata: 3, 
            }, waist: LootStatistics {
            id: 87, xp: 511, metadata: 4, 
            }, foot: LootStatistics {
            id: 78, xp: 511, metadata: 5, 
            }, hand: LootStatistics {
            id: 34, xp: 511, metadata: 6, 
            }, neck: LootStatistics {
            id: 32, xp: 511, metadata: 7, 
            }, ring: LootStatistics {
            id: 1, xp: 511, metadata: 8, 
        }, beast_health: 1023, stat_upgrade_available: 1,
    };
    let packed = adventurer.pack();
    let unpacked = ImplAdventurer::unpack(packed);
    assert(adventurer.last_action == unpacked.last_action, 'last_action');
    assert(adventurer.health == unpacked.health, 'health');
    assert(adventurer.xp == unpacked.xp, 'xp');
    assert(adventurer.stats.strength == unpacked.stats.strength, 'strength');
    assert(adventurer.stats.dexterity == unpacked.stats.dexterity, 'dexterity');
    assert(adventurer.stats.vitality == unpacked.stats.vitality, 'vitality');
    assert(adventurer.stats.intelligence == unpacked.stats.intelligence, 'intelligence');
    assert(adventurer.stats.wisdom == unpacked.stats.wisdom, 'wisdom');
    assert(adventurer.stats.charisma == unpacked.stats.charisma, 'charisma');
    assert(adventurer.gold == unpacked.gold, 'luck');
    assert(adventurer.weapon.id == unpacked.weapon.id, 'weapon.id');
    assert(adventurer.weapon.xp == unpacked.weapon.xp, 'weapon.xp');
    assert(adventurer.weapon.metadata == unpacked.weapon.metadata, 'weapon.metadata');
    assert(adventurer.chest.id == unpacked.chest.id, 'chest.id');
    assert(adventurer.chest.xp == unpacked.chest.xp, 'chest.xp');
    assert(adventurer.chest.metadata == unpacked.chest.metadata, 'chest.metadata');
    assert(adventurer.head.id == unpacked.head.id, 'head.id');
    assert(adventurer.head.xp == unpacked.head.xp, 'head.xp');
    assert(adventurer.head.metadata == unpacked.head.metadata, 'head.metadata');
    assert(adventurer.waist.id == unpacked.waist.id, 'waist.id');
    assert(adventurer.waist.xp == unpacked.waist.xp, 'waist.xp');
    assert(adventurer.waist.metadata == unpacked.waist.metadata, 'waist.metadata');
    assert(adventurer.foot.id == unpacked.foot.id, 'foot.id');
    assert(adventurer.foot.xp == unpacked.foot.xp, 'foot.xp');
    assert(adventurer.foot.metadata == unpacked.foot.metadata, 'foot.metadata');
    assert(adventurer.hand.id == unpacked.hand.id, 'hand.id');
    assert(adventurer.hand.xp == unpacked.hand.xp, 'hand.xp');
    assert(adventurer.hand.metadata == unpacked.hand.metadata, 'hand.metadata');
    assert(adventurer.neck.id == unpacked.neck.id, 'neck.id');
    assert(adventurer.neck.xp == unpacked.neck.xp, 'neck.xp');
    assert(adventurer.neck.metadata == unpacked.neck.metadata, 'neck.metadata');
    assert(adventurer.ring.id == unpacked.ring.id, 'ring.id');
    assert(adventurer.ring.xp == unpacked.ring.xp, 'ring.xp');
    assert(adventurer.ring.metadata == unpacked.ring.metadata, 'ring.metadata');
    assert(adventurer.beast_health == unpacked.beast_health, 'beast_health');
    assert(
        adventurer.stat_upgrade_available == unpacked.stat_upgrade_available,
        'stat_upgrade_available'
    );
}

#[test]
#[available_gas(5000000)]
fn test_new_adventurer() {
    let new_adventurer = ImplAdventurer::new(1, 1);

    new_adventurer.pack();

    assert(new_adventurer.health == 100, 'health');
}

#[test]
#[available_gas(5000000)]
fn test_health() {
    let mut adventurer = ImplAdventurer::new(1, 1);

    adventurer.add_health(5);

    assert(adventurer.health == 105, 'health');
}

#[test]
#[available_gas(5000000)]
fn test_deduct_health() {
    let mut adventurer = ImplAdventurer::new(1, 1);

    adventurer.deduct_health(5);

    assert(adventurer.health == 95, 'strength');
}

#[test]
#[available_gas(5000000)]
fn test_xp() {
    let mut adventurer = ImplAdventurer::new(1, 1);

    adventurer.increase_adventurer_xp(5);

    assert(adventurer.xp == 5, 'xp');
}

#[test]
#[available_gas(5000000)]
fn test_strength() {
    let mut adventurer = ImplAdventurer::new(1, 1);

    adventurer.add_strength(1);

    assert(adventurer.stats.strength == 1, 'strength');
}

#[test]
#[available_gas(5000000)]
fn test_add_weapon() {
    let mut adventurer = ImplAdventurer::new(1, 1);

    let item = LootStatistics { id: 1, xp: 1, metadata: 0 };

    adventurer.add_weapon(item);

    assert(adventurer.weapon.id == 1, 'weapon.id');
    assert(adventurer.weapon.xp == 1, 'weapon.xp');
    assert(adventurer.weapon.metadata == 0, 'weapon.metadata');
}

#[test]
#[available_gas(5000000)]
fn test_increase_item_xp() {
    let mut adventurer = ImplAdventurer::new(1, 1);
    let entropy = 1;
    let item_ghost_wand = LootStatistics { id: constants::ItemId::GhostWand, xp: 1, metadata: 1 };
    adventurer.add_item(item_ghost_wand);

    let blank_special_name = LootItemSpecialNames {
        name_prefix: 0, name_suffix: 0, item_suffix: 0
    };

    let ghost_wand_special_name = LootItemSpecialNames {
        name_prefix: 0, name_suffix: 0, item_suffix: 0
    };

    let mut loot_item_name_storage = LootItemSpecialNamesStorage {
        item_1: ghost_wand_special_name,
        item_2: blank_special_name,
        item_3: blank_special_name,
        item_4: blank_special_name,
        item_5: blank_special_name,
        item_6: blank_special_name,
        item_7: blank_special_name,
        item_8: blank_special_name,
        item_9: blank_special_name,
        item_10: blank_special_name,
    };

    let original_level = ImplLoot::get_greatness_level(adventurer.weapon.xp);

    // verify weapon starts on level 1
    assert(original_level == 1, 'weapon should start on lvl 1');

    // grant weapon 1XP
    let (previous_level, new_level, suffix_assigned, prefix_assigned, special_names) = adventurer
        .weapon
        .increase_item_xp(1, ref loot_item_name_storage, 1);

    // weapon should now have 2XP
    assert(adventurer.weapon.xp == 2, 'weapon should have 2xp');

    // call should return previous level of 1 (level 2 requires 4xp)
    assert(previous_level == 1, 'weapon prev level should be 1');

    // new level should be 2
    assert(new_level == 1, 'weapon new level should be 1');

    // item should not have received a suffix or prefix
    assert(suffix_assigned == false, 'weapon should not recv suffix');
    assert(prefix_assigned == false, 'weapon should not recv prefix');

    // grant weapon another 2XP (should be enough to level up)
    let (previous_level, new_level, suffix_assigned, prefix_assigned, special_names) = adventurer
        .weapon
        .increase_item_xp(2, ref loot_item_name_storage, 1);
    assert(adventurer.weapon.xp == 4, 'weapon should have 4xp');
    assert(previous_level == 1, 'weapon prev level should be 1');
    assert(new_level == 2, 'weapon new level should be 2');
    assert(suffix_assigned == false, 'weapon should not recv suffix');
    assert(prefix_assigned == false, 'weapon should not recv prefix');

    // grant weapon 192 more xp, bringing it to 196xp total (level 14)
    let (previous_level, new_level, suffix_assigned, prefix_assigned, special_names) = adventurer
        .weapon
        .increase_item_xp(192, ref loot_item_name_storage, 1);
    assert(adventurer.weapon.xp == 196, 'weapon should have 196xp');
    assert(previous_level == 2, 'weapon prev level should be 1');
    assert(new_level == 14, 'weapon new level should be 14');
    assert(suffix_assigned == false, 'weapon should not recv suffix');
    assert(prefix_assigned == false, 'weapon should not recv prefix');

    // grant weapon 29 more xp, bringing it to 225 total (level 15 - suffix assigned)
    let (previous_level, new_level, suffix_assigned, prefix_assigned, special_names) = adventurer
        .weapon
        .increase_item_xp(29, ref loot_item_name_storage, 1);
    assert(adventurer.weapon.xp == 225, 'weapon should have 225');
    assert(previous_level == 14, 'weapon prev level should be 14');
    assert(new_level == 15, 'weapon new level should be 15');
    assert(suffix_assigned == true, 'weapon should recv suffix');
    assert(prefix_assigned == false, 'weapon should not recv prefix');

    assert(special_names.item_suffix != 0, 'suffix should be set');
    assert(special_names.name_prefix == 0, 'name prefix should be 0');
    assert(special_names.name_suffix == 0, 'name suffix should be 0');
    // verify name was updated in storage
    assert(loot_item_name_storage.item_1.item_suffix != 0, 'suffix should be set');

    // save the suffix the item received at G15 to ensure it is persisted when prefixes get unlocked at G19
    let original_weapon_suffix = loot_item_name_storage.item_1.item_suffix;
    // grant weapon 136 more xp, bringing it to 361 total (level 19 - prefixes assigned)
    let (previous_level, new_level, suffix_assigned, prefix_assigned, special_names) = adventurer
        .weapon
        .increase_item_xp(136, ref loot_item_name_storage, 1);
    assert(adventurer.weapon.xp == 361, 'weapon should have 361');
    assert(previous_level == 15, 'weapon prev level should be 15');
    assert(new_level == 19, 'weapon new level should be 19');
    assert(suffix_assigned == false, 'weapon should not recv suffix');
    assert(prefix_assigned == true, 'weapon should recv prefixes');

    assert(special_names.item_suffix == original_weapon_suffix, 'suffix should not have changed');
    assert(special_names.name_prefix != 0, 'name prefix should be set');
    assert(special_names.name_suffix != 0, 'name suffix should be set');
    // verify storage data was updated properly
    assert(
        loot_item_name_storage.item_1.item_suffix == original_weapon_suffix,
        'suffix should not have changed'
    );
    assert(loot_item_name_storage.item_1.name_prefix != 0, 'name prefix should be set');
    assert(loot_item_name_storage.item_1.name_suffix != 0, 'name suffix should be set');
    let original_name_prefix = loot_item_name_storage.item_1.name_prefix;
    let original_name_suffix = loot_item_name_storage.item_1.name_suffix;

    // level weapon to 20
    let (previous_level, new_level, suffix_assigned, prefix_assigned, special_names) = adventurer
        .weapon
        .increase_item_xp(39, ref loot_item_name_storage, 1);
    assert(adventurer.weapon.xp == 400, 'weapon should have 400');
    assert(previous_level == 19, 'weapon prev level should be 19');
    assert(new_level == 20, 'weapon new level should be 20');
    assert(suffix_assigned == false, 'weapon should not recv suffix');
    assert(prefix_assigned == false, 'weapon should not recv prefixes');
    // verify storage data was not updated
    assert(
        loot_item_name_storage.item_1.item_suffix == original_weapon_suffix,
        'item suffix should be same'
    );
    assert(
        loot_item_name_storage.item_1.name_prefix == original_name_prefix,
        'name prefix should be same'
    );
    assert(
        loot_item_name_storage.item_1.name_suffix == original_name_suffix,
        'name suffix should be same'
    );

    // test with max XP input (2^16) - 1 = 65535;
    let (previous_level, new_level, suffix_assigned, prefix_assigned, special_names) = adventurer
        .weapon
        .increase_item_xp(65535, ref loot_item_name_storage, 1);
    assert(adventurer.weapon.xp == 65535, 'weapon should have 400');
    assert(previous_level == 20, 'weapon prev level should be 20');
    assert(new_level == Settings::ITEM_MAX_GREATNESS, 'weapon new lvl should be max');
    assert(suffix_assigned == false, 'weapon should not recv suffix');
    assert(prefix_assigned == false, 'weapon should not recv prefixes');
    // verify storage data was not updated
    assert(
        loot_item_name_storage.item_1.item_suffix == original_weapon_suffix,
        'item suffix should be same'
    );
    assert(
        loot_item_name_storage.item_1.name_prefix == original_name_prefix,
        'name prefix should be same'
    );
    assert(
        loot_item_name_storage.item_1.name_suffix == original_name_suffix,
        'name suffix should be same'
    );

    // There is one more variant to test when it comes to item leveling and name assignment
    // which is an item going from < G15 to G19 in a single hop. This is highly unlikely
    // but technically possible so the contract needs to be able to handle it

    // to test this lets create a new item
    let divine_robe = LootStatistics { id: constants::ItemId::DivineRobe, xp: 1, metadata: 2 };
    adventurer.add_item(divine_robe);

    // verify starting state
    assert(adventurer.chest.id == constants::ItemId::DivineRobe, 'advntr should have divine robe');
    assert(adventurer.chest.xp == 1, 'divine robe should have 1 xp');
    assert(adventurer.chest.metadata == 2, 'advntr should have divine robe');
    let divine_robe_starting_level = ImplLoot::get_greatness_level(adventurer.chest.xp);
    assert(divine_robe_starting_level == 1, 'divine robe should be level 1');

    // give divine robe max XP 65535
    let (previous_level, new_level, suffix_assigned, prefix_assigned, special_names) = adventurer
        .chest
        .increase_item_xp(65535, ref loot_item_name_storage, 1);
    assert(adventurer.chest.xp == 65535, 'divine robe should have 65535xp');
    assert(previous_level == divine_robe_starting_level, 'DR prev level should be 1');
    assert(new_level == Settings::ITEM_MAX_GREATNESS, 'DR new level should be MAX');
    assert(suffix_assigned == true, 'DR should have recv suffix');
    assert(prefix_assigned == true, 'DR should have recv prefix');

    assert(special_names.item_suffix != 0, 'suffix should be set');
    assert(special_names.name_prefix != 0, 'name prefix should be set');
    assert(special_names.name_suffix != 0, 'name suffix should be set');
    // verify storage data was updated properly
    assert(
        special_names.item_suffix == loot_item_name_storage.item_2.item_suffix,
        'storage suffix should be set'
    );
    assert(
        special_names.name_prefix == loot_item_name_storage.item_2.name_prefix,
        'storage prefix1 should be set'
    );
    assert(
        special_names.name_suffix == loot_item_name_storage.item_2.item_suffix,
        'storage prefix2 should be set'
    );
}

#[test]
#[available_gas(5000000)]
fn test_deduct_beast_health() {
    let mut adventurer = ImplAdventurer::new(1, 1);
    let mut adventurer = ImplAdventurer::new(1, 1);

    adventurer.add_beast(100);
    assert(adventurer.beast_health == 100, 'beast_health');

    adventurer.deduct_beast_health(5);
    assert(adventurer.beast_health == 95, 'beast_health');
}

#[test]
#[available_gas(5000000)]
fn test_get_random_explore() {
    // exploring with zero entropy will result in a beast discovery
    let entropy = 0;
    let discovery = ImplAdventurer::get_random_explore(entropy);
    assert(discovery == ExploreResult::Beast(()), 'adventurer should find beast');

    let entropy = 1;
    let discovery = ImplAdventurer::get_random_explore(entropy);
    assert(discovery == ExploreResult::Obstacle(()), 'adventurer should find obstacle');

    let entropy = 2;
    let discovery = ImplAdventurer::get_random_explore(entropy);
    assert(discovery == ExploreResult::Treasure(()), 'adventurer should find treasure');
}

#[test]
#[available_gas(500000)]
fn test_explore_health_discovery() { //TODO: test health discovery
}

#[test]
#[available_gas(500000)]
fn test_explore_gold_discovery() { //TODO: test health discovery
}

#[test]
#[available_gas(500000)]
fn test_explore_xp_discovery() { // TODO: test xp discovery
}

#[test]
#[available_gas(500000)]
fn test_add_statistic() {
    let mut adventurer = ImplAdventurer::new(1, 1);

    adventurer.add_statistic(StatisticIndex::STRENGTH);
    assert(adventurer.stats.strength == 1, 'strength');

    adventurer.add_statistic(StatisticIndex::DEXTERITY);
    assert(adventurer.stats.dexterity == 1, 'dexterity');

    adventurer.add_statistic(StatisticIndex::INTELLIGENCE);
    assert(adventurer.stats.intelligence == 1, 'intelligence');

    adventurer.add_statistic(StatisticIndex::VITALITY);
    assert(adventurer.stats.vitality == 1, 'vitality');

    adventurer.add_statistic(StatisticIndex::WISDOM);
    assert(adventurer.stats.wisdom == 1, 'wisdom');
}


#[test]
#[available_gas(500000)]
fn test_charisma_health_discount_overflow() {
    let mut adventurer = Adventurer {
        last_action: 511, health: 1023, xp: 0, stats: Stats {
            strength: 31, dexterity: 31, vitality: 31, intelligence: 31, wisdom: 31, charisma: 100, 
            }, gold: 1, weapon: LootStatistics {
            id: 100, xp: 511, metadata: 1, 
            }, chest: LootStatistics {
            id: 99, xp: 511, metadata: 2, 
            }, head: LootStatistics {
            id: 98, xp: 511, metadata: 3, 
            }, waist: LootStatistics {
            id: 87, xp: 511, metadata: 4, 
            }, foot: LootStatistics {
            id: 78, xp: 511, metadata: 5, 
            }, hand: LootStatistics {
            id: 34, xp: 511, metadata: 6, 
            }, neck: LootStatistics {
            id: 32, xp: 511, metadata: 7, 
            }, ring: LootStatistics {
            id: 1, xp: 511, metadata: 8, 
        }, beast_health: 1023, stat_upgrade_available: 1,
    };

    let discount = adventurer.get_potion_cost(0);

    assert(discount == MINIMUM_POTION_PRICE, 'discount');

    // set to 0
    adventurer.stats.charisma = 0;

    let discount = adventurer.get_potion_cost(0);

    assert(discount == MINIMUM_POTION_PRICE * adventurer.get_level().into(), 'no charisma potion');
}

#[test]
#[available_gas(500000)]
fn test_charisma_item_discount_overflow() {
    let mut adventurer = Adventurer {
        last_action: 511, health: 1023, xp: 100, stats: Stats {
            strength: 31, dexterity: 31, vitality: 31, intelligence: 31, wisdom: 31, charisma: 10, 
            }, gold: 40, weapon: LootStatistics {
            id: 100, xp: 511, metadata: 1, 
            }, chest: LootStatistics {
            id: 99, xp: 511, metadata: 2, 
            }, head: LootStatistics {
            id: 98, xp: 511, metadata: 3, 
            }, waist: LootStatistics {
            id: 87, xp: 511, metadata: 4, 
            }, foot: LootStatistics {
            id: 78, xp: 511, metadata: 5, 
            }, hand: LootStatistics {
            id: 34, xp: 511, metadata: 6, 
            }, neck: LootStatistics {
            id: 32, xp: 511, metadata: 7, 
            }, ring: LootStatistics {
            id: 1, xp: 511, metadata: 8, 
        }, beast_health: 1023, stat_upgrade_available: 1,
    };

    let max_item_price = 15;

    let item_price = adventurer.get_item_cost(max_item_price, 0);

    assert(item_price == MINIMUM_ITEM_PRICE, 'min_item_price');

    adventurer.stats.charisma = 0;

    let item_price = adventurer.get_item_cost(max_item_price, 0);

    assert(item_price == max_item_price, 'max_item_price');
}

#[test]
#[available_gas(90000)]
fn test_increase_xp() {
    // initialize lvl 1 adventurer with no stat points available
    let mut adventurer = Adventurer {
        last_action: 511, health: 1023, xp: 1, stats: Stats {
            strength: 31, dexterity: 31, vitality: 31, intelligence: 31, wisdom: 31, charisma: 10, 
            }, gold: 40, weapon: LootStatistics {
            id: 100, xp: 511, metadata: 1, 
            }, chest: LootStatistics {
            id: 99, xp: 511, metadata: 2, 
            }, head: LootStatistics {
            id: 98, xp: 511, metadata: 3, 
            }, waist: LootStatistics {
            id: 87, xp: 511, metadata: 4, 
            }, foot: LootStatistics {
            id: 78, xp: 511, metadata: 5, 
            }, hand: LootStatistics {
            id: 34, xp: 511, metadata: 6, 
            }, neck: LootStatistics {
            id: 32, xp: 511, metadata: 7, 
            }, ring: LootStatistics {
            id: 1, xp: 511, metadata: 8, 
        }, beast_health: 1023, stat_upgrade_available: 0,
    };

    // increase adventurer xp by 3 which should level up the adventurer
    adventurer.increase_adventurer_xp(3);
    assert(adventurer.get_level() == 2, 'advtr should be lvl 2');
    assert(adventurer.stat_upgrade_available == 1, 'advtr should have 1 stat avlbl');

    // double level up without spending previous stat point
    adventurer.increase_adventurer_xp(12);
    assert(adventurer.get_level() == 4, 'advtr should be lvl 4');
    assert(adventurer.stat_upgrade_available == 3, 'advtr should have 3 stat avlbl');
}

#[test]
#[available_gas(100000)]
fn test_add_suffix_boost() {
    let mut stats = Stats {
        strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0, 
    };

    stats.add_suffix_boost(ItemSuffix::of_Power);
    assert(stats.strength == 3, 'strength should be 3');
    assert(stats.dexterity == 0, 'dexterity should be 0');
    assert(stats.vitality == 0, 'vitality should be 0');
    assert(stats.intelligence == 0, 'intelligence should be 0');
    assert(stats.wisdom == 0, 'wisdom should be 0');
    assert(stats.charisma == 0, 'charisma should be 0');

    stats.add_suffix_boost(ItemSuffix::of_Giant);
    assert(stats.strength == 3, 'strength should be 3');
    assert(stats.vitality == 3, 'vitality should be 3');
    assert(stats.dexterity == 0, 'dexterity should be 0');
    assert(stats.intelligence == 0, 'intelligence should be 0');
    assert(stats.wisdom == 0, 'wisdom should be 0');
    assert(stats.charisma == 0, 'charisma should be 0');

    stats.add_suffix_boost(ItemSuffix::of_Perfection);
    assert(stats.strength == 4, 'strength should be 4');
    assert(stats.vitality == 4, 'vitality should be 4');
    assert(stats.dexterity == 1, 'dexterity should be 1');
    assert(stats.intelligence == 0, 'intelligence should be 0');
    assert(stats.wisdom == 0, 'wisdom should be 0');
    assert(stats.charisma == 0, 'charisma should be 0');

    stats.add_suffix_boost(ItemSuffix::of_Rage);
    assert(stats.strength == 5, 'strength should be 5');
    assert(stats.vitality == 4, 'vitality should be 4');
    assert(stats.dexterity == 1, 'dexterity should be 1');
    assert(stats.intelligence == 0, 'intelligence should be 0');
    assert(stats.wisdom == 1, 'wisdom should be 1');
    assert(stats.charisma == 1, 'charisma should be 1');

    stats.add_suffix_boost(ItemSuffix::of_Fury);
    assert(stats.strength == 5, 'strength should be 5');
    assert(stats.vitality == 5, 'vitality should be 5');
    assert(stats.dexterity == 1, 'dexterity should be 1');
    assert(stats.intelligence == 1, 'intelligence should be 1');
    assert(stats.wisdom == 1, 'wisdom should be 1');
    assert(stats.charisma == 2, 'charisma should be 2');
}

#[test]
#[available_gas(300000)]
fn test_get_suffix_stat_boosts() {
    let adventurer = Adventurer {
        last_action: 511, health: 100, xp: 1, stats: Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0, 
            }, gold: 40, weapon: LootStatistics {
            id: 1, xp: 225, metadata: 1, 
            }, chest: LootStatistics {
            id: 2, xp: 65535, metadata: 2, 
            }, head: LootStatistics {
            id: 3, xp: 225, metadata: 3, 
            }, waist: LootStatistics {
            id: 4, xp: 225, metadata: 4, 
            }, foot: LootStatistics {
            id: 5, xp: 1000, metadata: 5, 
            }, hand: LootStatistics {
            id: 6, xp: 224, metadata: 6, 
            }, neck: LootStatistics {
            id: 7, xp: 1, metadata: 7, 
            }, ring: LootStatistics {
            id: 8, xp: 1, metadata: 8, 
        }, beast_health: 20, stat_upgrade_available: 0,
    };

    let item1_names = LootItemSpecialNames {
        name_prefix: 0, name_suffix: 0, item_suffix: ItemSuffix::of_Power, 
    };
    let item2_names = LootItemSpecialNames {
        name_prefix: 0, name_suffix: 0, item_suffix: ItemSuffix::of_Giant, 
    };
    let item3_names = LootItemSpecialNames {
        name_prefix: 0, name_suffix: 0, item_suffix: ItemSuffix::of_Perfection, 
    };
    let item4_names = LootItemSpecialNames {
        name_prefix: 0, name_suffix: 0, item_suffix: ItemSuffix::of_Rage, 
    };
    let item5_names = LootItemSpecialNames {
        name_prefix: 0, name_suffix: 0, item_suffix: ItemSuffix::of_Fury, 
    };
    let item6_names = LootItemSpecialNames {
        name_prefix: 0, name_suffix: 0, item_suffix: ItemSuffix::of_Skill, 
    };
    let item7_names = LootItemSpecialNames {
        name_prefix: 0, name_suffix: 0, item_suffix: ItemSuffix::of_Vitriol, 
    };
    let item8_names = LootItemSpecialNames {
        name_prefix: 0, name_suffix: 0, item_suffix: ItemSuffix::of_the_Fox, 
    };
    let item9_names = LootItemSpecialNames { name_prefix: 0, name_suffix: 0, item_suffix: 0,  };
    let item10_names = LootItemSpecialNames { name_prefix: 0, name_suffix: 0, item_suffix: 0,  };

    let name_storage1 = LootItemSpecialNamesStorage {
        item_1: item1_names,
        item_2: item2_names,
        item_3: item3_names,
        item_4: item4_names,
        item_5: item5_names,
        item_6: item6_names,
        item_7: item7_names,
        item_8: item8_names,
        item_9: item9_names,
        item_10: item10_names,
    };

    let name_storage2 = LootItemSpecialNamesStorage {
        item_1: item1_names,
        item_2: item2_names,
        item_3: item3_names,
        item_4: item4_names,
        item_5: item5_names,
        item_6: item6_names,
        item_7: item7_names,
        item_8: item8_names,
        item_9: item9_names,
        item_10: item10_names,
    };

    let boost_stats = ImplAdventurer::get_suffix_stat_boosts(
        adventurer, name_storage1, name_storage2
    );
    assert(boost_stats.strength == 5, 'strength should be 5');
    assert(boost_stats.vitality == 5, 'vitality should be 5');
    assert(boost_stats.dexterity == 1, 'dexterity should be 1');
    assert(boost_stats.intelligence == 1, 'intelligence should be 1');
    assert(boost_stats.wisdom == 1, 'wisdom should be 1');
    assert(boost_stats.charisma == 2, 'charisma should be 2');
}
