use core::{
    array::ArrayTrait,
    integer::{u8_overflowing_add, u16_overflowing_add, u16_overflowing_sub, u256_try_as_non_zero},
    option::OptionTrait, poseidon::poseidon_hash_span, result::ResultTrait,
    starknet::{StorePacking}, traits::{TryInto, Into}
};

use super::{
    stats::{Stats, StatsPacking}, item::{Item, ImplItem, ItemPacking},
    equipment::{Equipment, EquipmentPacking}, adventurer_utils::{AdventurerUtils},
    bag::{Bag, IBag, ImplBag},
    constants::{
        adventurer_constants::{
            STARTING_GOLD, StatisticIndex, POTION_PRICE, STARTING_HEALTH, CHARISMA_POTION_DISCOUNT,
            MINIMUM_ITEM_PRICE, MINIMUM_POTION_PRICE, HEALTH_INCREASE_PER_VITALITY, MAX_GOLD,
            MAX_STAT_UPGRADES_AVAILABLE, MAX_ADVENTURER_XP, MAX_ADVENTURER_BLOCKS,
            ITEM_MAX_GREATNESS, ITEM_MAX_XP, MAX_ADVENTURER_HEALTH, CHARISMA_ITEM_DISCOUNT,
            MAX_BLOCK_COUNT, STAT_UPGRADE_POINTS_PER_LEVEL, NECKLACE_G20_BONUS_STATS,
            SILVER_RING_G20_LUCK_BONUS, BEAST_SPECIAL_NAME_LEVEL_UNLOCK, U128_MAX, U64_MAX,
            JEWELRY_BONUS_BEAST_GOLD_PERCENT, JEWELRY_BONUS_CRITICAL_HIT_PERCENT_PER_GREATNESS,
            JEWELRY_BONUS_NAME_MATCH_PERCENT_PER_GREATNESS, NECKLACE_ARMOR_BONUS,
            MINIMUM_DAMAGE_FROM_BEASTS, SILVER_RING_LUCK_BONUS_PER_GREATNESS,
            MINIMUM_DAMAGE_FROM_OBSTACLES, MINIMUM_DAMAGE_TO_BEASTS, MAX_PACKABLE_BEAST_HEALTH,
            CRITICAL_HIT_LEVEL_MULTIPLIER
        },
        discovery_constants::DiscoveryEnums::{ExploreResult, DiscoveryType}
    },
    stats::{ImplStats}
};
use loot::{
    loot::{Loot, ILoot, ImplLoot},
    constants::{ItemSuffix, ItemId, NamePrefixLength, NameSuffixLength, SUFFIX_UNLOCK_GREATNESS},
    utils::{ItemUtils}
};
use combat::{
    combat::{ImplCombat, CombatSpec, SpecialPowers, CombatResult},
    constants::CombatEnums::{Type, Tier, Slot}
};
use obstacles::obstacle::{ImplObstacle, Obstacle};
use beasts::{beast::{ImplBeast, Beast}, constants::BeastSettings};

#[derive(Drop, Copy, Serde)]
struct Adventurer {
    health: u16, // 10 bits
    xp: u16, // 15 bits
    gold: u16, // 9 bits
    beast_health: u16, // 10 bits
    stat_upgrades_available: u8, // 4 bits
    stats: Stats, // 30 bits
    equipment: Equipment, // 128 bits
    mutated: bool, // not packed
    awaiting_item_specials: bool, // not packed
}

impl AdventurerPacking of StorePacking<Adventurer, felt252> {
    fn pack(value: Adventurer) -> felt252 {
        assert(value.health <= MAX_ADVENTURER_HEALTH, 'health overflow');
        assert(value.xp <= MAX_ADVENTURER_XP, 'xp overflow');
        assert(value.gold <= MAX_GOLD, 'gold overflow');
        assert(value.beast_health <= MAX_PACKABLE_BEAST_HEALTH, 'beast health overflow');
        assert(
            value.stat_upgrades_available <= MAX_STAT_UPGRADES_AVAILABLE,
            'stat upgrades avail overflow'
        );

        (value.health.into()
            + value.xp.into() * TWO_POW_10
            + value.gold.into() * TWO_POW_25
            + value.beast_health.into() * TWO_POW_34
            + value.stat_upgrades_available.into() * TWO_POW_44
            + StatsPacking::pack(value.stats).into() * TWO_POW_48
            + EquipmentPacking::pack(value.equipment).into() * TWO_POW_78)
            .try_into()
            .unwrap()
    }


    fn unpack(value: felt252) -> Adventurer {
        let packed = value.into();
        let (packed, health) = integer::U256DivRem::div_rem(packed, TWO_POW_10.try_into().unwrap());
        let (packed, xp) = integer::U256DivRem::div_rem(packed, TWO_POW_15.try_into().unwrap());
        let (packed, gold) = integer::U256DivRem::div_rem(packed, TWO_POW_9.try_into().unwrap());
        let (packed, beast_health) = integer::U256DivRem::div_rem(
            packed, TWO_POW_10.try_into().unwrap()
        );
        let (packed, stat_upgrades_available) = integer::U256DivRem::div_rem(
            packed, TWO_POW_4.try_into().unwrap()
        );
        let (packed, stats) = integer::U256DivRem::div_rem(packed, TWO_POW_30.try_into().unwrap());
        let (_, equipment) = integer::U256DivRem::div_rem(packed, TWO_POW_128.try_into().unwrap());

        Adventurer {
            health: health.try_into().unwrap(),
            xp: xp.try_into().unwrap(),
            gold: gold.try_into().unwrap(),
            beast_health: beast_health.try_into().unwrap(),
            stat_upgrades_available: stat_upgrades_available.try_into().unwrap(),
            stats: StatsPacking::unpack(stats.try_into().unwrap()),
            equipment: EquipmentPacking::unpack(equipment.try_into().unwrap()),
            mutated: false, // This field is not packed/unpacked
            awaiting_item_specials: false
        }
    }
}

#[generate_trait]
impl ImplAdventurer of IAdventurer {
    /// @title Adventurer Creation Function
    /// @notice This function initializes and returns a new Adventurer struct.
    ///
    /// @dev The function takes a `u8` parameter for the starting weapon item and
    /// initializes various character stats and items with default and provided values.
    ///
    /// @param starting_item The ID of the starting weapon item.
    /// @return An Adventurer struct initialized with default and provided values.
    fn new(starting_item: u8) -> Adventurer {
        Adventurer {
            health: STARTING_HEALTH,
            xp: 0,
            stats: ImplStats::new(),
            gold: STARTING_GOLD,
            equipment: Equipment {
                weapon: Item { id: starting_item, xp: 0 },
                chest: Item { id: 0, xp: 0 },
                head: Item { id: 0, xp: 0 },
                waist: Item { id: 0, xp: 0 },
                foot: Item { id: 0, xp: 0 },
                hand: Item { id: 0, xp: 0 },
                neck: Item { id: 0, xp: 0 },
                ring: Item { id: 0, xp: 0 }
            },
            beast_health: BeastSettings::STARTER_BEAST_HEALTH,
            stat_upgrades_available: 0,
            mutated: false,
            awaiting_item_specials: false
        }
    }

    // @notice Calculates the charisma potion discount for the adventurer based on their charisma stat.
    // @return The charisma potion discount.
    #[inline(always)]
    fn charisma_potion_discount(self: Stats) -> u16 {
        CHARISMA_POTION_DISCOUNT * self.charisma.into()
    }

    // @notice Calculates the charisma item discount for the adventurer based on their charisma stat.
    // @return The charisma item discount.
    #[inline(always)]
    fn charisma_item_discount(self: Stats) -> u16 {
        CHARISMA_ITEM_DISCOUNT * self.charisma.into()
    }

    // @notice Gets the item cost for the adventurer after applying any charisma discounts.
    // @param item_cost The original cost of the item.
    // @return The final cost of the item after applying discounts. If the discount exceeds the original cost, returns the MINIMUM_ITEM_PRICE.
    fn charisma_adjusted_item_price(self: Adventurer, item_cost: u16) -> u16 {
        if (u16_overflowing_sub(item_cost, self.stats.charisma_item_discount()).is_ok()) {
            if (item_cost - self.stats.charisma_item_discount() > MINIMUM_ITEM_PRICE) {
                return (item_cost - self.stats.charisma_item_discount());
            }
        }

        // if we underflow, or the discount exceeds the original cost, return the minimum item price
        MINIMUM_ITEM_PRICE
    }

    // @notice Gets the potion cost for the adventurer after applying any charisma discounts.
    // @return The final cost of the potion after applying discounts. If the discount exceeds the original cost, returns the MINIMUM_POTION_PRICE.
    fn charisma_adjusted_potion_price(self: Adventurer) -> u16 {
        // check if we overflow
        if (u16_overflowing_sub(
            POTION_PRICE * self.get_level().into(), self.stats.charisma_potion_discount()
        )
            .is_ok()) {
            let potion_price = POTION_PRICE * self.get_level().into()
                - self.stats.charisma_potion_discount();
            if (potion_price > MINIMUM_POTION_PRICE) {
                return potion_price;
            }
        }

        // if we underflow, or the discount exceeds the minimum cost, return the minimum potion price
        MINIMUM_POTION_PRICE
    }

    // @notice Deducts a specified amount of gold from the adventurer, preventing underflow.
    // @param amount The amount of gold to be deducted.
    #[inline(always)]
    fn deduct_gold(ref self: Adventurer, amount: u16) {
        // underflow protection
        if amount > self.gold {
            self.gold = 0;
        } else {
            self.gold -= amount;
        }
    }

    // get_item_at_slot returns the item at a given item slot
    // @param self: Equipment to check
    // @param slot: Slot to check
    // @return Item: Item at slot
    #[inline(always)]
    fn get_item_at_slot(self: Equipment, slot: Slot) -> Item {
        match slot {
            Slot::None(()) => Item { id: 0, xp: 0 },
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

    // @notice gets the item at a given item slot
    // @param self: Equipment to check
    // @param item_id: ID of the item to get
    // @return Item: Item at slot, returns an empty item if the item is not found
    #[inline(always)]
    fn get_item(self: Equipment, item_id: u8) -> Item {
        if item_id == self.weapon.id {
            self.weapon
        } else if item_id == self.chest.id {
            self.chest
        } else if item_id == self.head.id {
            self.head
        } else if item_id == self.waist.id {
            self.waist
        } else if item_id == self.foot.id {
            self.foot
        } else if item_id == self.hand.id {
            self.hand
        } else if item_id == self.neck.id {
            self.neck
        } else if item_id == self.ring.id {
            self.ring
        } else {
            Item { id: 0, xp: 0 }
        }
    }

    // is_slot_free checks if an item slot is free for an adventurer
    // @param self: Equipment to check
    // @param item: Item to check
    // @return bool: True if slot is free, false if not
    #[inline(always)]
    fn is_slot_free(self: Equipment, item: Item) -> bool {
        let slot = ImplLoot::get_slot(item.id);
        match slot {
            Slot::None(()) => false,
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

    fn is_slot_free_item_id(self: Equipment, item_id: u8) -> bool {
        let slot = ImplLoot::get_slot(item_id);
        match slot {
            Slot::None(()) => false,
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

    // Returns the current level of the adventurer based on their XP.
    // @param self: Adventurer to get level for
    // @return The current level of the adventurer.
    #[inline(always)]
    fn get_level(self: Adventurer) -> u8 {
        ImplCombat::get_level_from_xp(self.xp)
    }

    fn get_beast(
        self: Adventurer, adventurer_id: felt252, adventurer_entropy: felt252
    ) -> (Beast, u128) {
        let adventurer_level = self.get_level();

        // @dev ideally this would be a setting but to minimize gas we're using hardcoded value so we can use cheaper equal operator
        if (adventurer_level == 1) {
            let beast_seed: u128 = adventurer_id.try_into().unwrap();
            (
                ImplBeast::get_starter_beast(
                    ImplLoot::get_type(self.equipment.weapon.id), beast_seed
                ),
                beast_seed
            )
        } else {
            let beast_seed: u128 = self.get_beast_seed(adventurer_entropy);
            let beast_id = ImplBeast::get_beast_id(beast_seed);
            let starting_health = ImplBeast::get_starting_health(adventurer_level, beast_seed);
            let beast_tier = ImplBeast::get_tier(beast_id);
            let beast_type = ImplBeast::get_type(beast_id);
            let beast_level = ImplBeast::get_level(adventurer_level, beast_seed);
            let mut special_names = SpecialPowers { special1: 0, special2: 0, special3: 0 };

            if (beast_level >= BEAST_SPECIAL_NAME_LEVEL_UNLOCK) {
                special_names =
                    ImplBeast::get_special_names(
                        beast_seed, NamePrefixLength.into(), NameSuffixLength.into()
                    );
            }

            let beast = Beast {
                id: beast_id,
                starting_health: starting_health,
                combat_spec: CombatSpec {
                    tier: beast_tier,
                    item_type: beast_type,
                    level: beast_level,
                    specials: special_names
                }
            };

            (beast, beast_seed)
        }
    }

    // @notice checks if the adventurer was ambushed
    // @param self: Adventurer to check
    // @param entropy: Entropy for determining if the adventurer was ambushed
    // @return bool: True if the adventurer was ambushed, false if not
    #[inline(always)]
    fn is_ambushed(self: Adventurer, entropy: u128) -> bool {
        !ImplCombat::ability_based_avoid_threat(self.get_level(), self.stats.wisdom, entropy)
    }

    // Attempts to discover treasure during an adventure.
    // The discovered treasure type and amount are determined based on a given entropy.
    // Possible discoveries include gold, XP, and health.
    // @param self: Adventurer to discover treasure for
    // @param entropy: Entropy for generating treasure
    // @return DiscoveryType: The type of treasure discovered.
    // @return u16: The amount of treasure discovered.
    fn get_discovery(adventurer_level: u8, entropy: u128) -> DiscoveryType {
        let (discovery_entropy, discovery_type) = DivRem::div_rem(entropy, 100);
        if discovery_type < 45 {
            DiscoveryType::Gold(
                ImplAdventurer::get_gold_discovery(adventurer_level, discovery_entropy)
            )
        } else if discovery_type < 90 {
            DiscoveryType::Health(
                ImplAdventurer::get_health_discovery(adventurer_level, discovery_entropy)
            )
        } else {
            DiscoveryType::Loot(ImplAdventurer::get_loot_discovery(discovery_entropy))
        }
    }

    fn get_gold_discovery(adventurer_level: u8, entropy: u128) -> u16 {
        (entropy % adventurer_level.into()).try_into().unwrap() + 1
    }

    fn get_health_discovery(adventurer_level: u8, entropy: u128) -> u16 {
        ((entropy % adventurer_level.into()).try_into().unwrap() + 1) * 2
    }

    fn get_loot_discovery(entropy: u128) -> u8 {
        let roll = entropy % 100;

        // 50% chance of T5
        if roll < 50 {
            let t5_items = ItemUtils::get_t5_items();
            let item_index = (entropy % t5_items.len().into()).try_into().unwrap();
            *t5_items.at(item_index)
        // 30% chance of T4
        } else if roll < 80 {
            let t4_items = ItemUtils::get_t4_items();
            let item_index = (entropy % t4_items.len().into()).try_into().unwrap();
            *t4_items.at(item_index)
        // 12% chance of T3
        } else if roll < 92 {
            let t3_items = ItemUtils::get_t3_items();
            let item_index = (entropy % t3_items.len().into()).try_into().unwrap();
            *t3_items.at(item_index)
        // 6% chance of T2
        } else if roll < 98 {
            let t2_items = ItemUtils::get_t2_items();
            let item_index = (entropy % t2_items.len().into()).try_into().unwrap();
            *t2_items.at(item_index)
        // 2% chance of T1
        } else {
            let t1_items = ItemUtils::get_t1_items();
            let item_index = (entropy % t1_items.len().into()).try_into().unwrap();
            *t1_items.at(item_index)
        }
    }

    // @notice Calculates the adventurer's luck based on the greatness of their jewelry
    // @dev Adventurer gets luck from three sources:
    //      1. Greatness of equipped jewlery
    //      2. Greatness of bagged jewlery
    //      3. Bonus luck, currently an equipped G20 Silver Ring
    // @param self: Equipment to calculate luck for
    // @param bag: Bag to calculate luck for
    // @return The adventurer's luck.
    #[inline(always)]
    fn calculate_luck(self: Equipment, bag: Bag) -> u8 {
        let equipped_necklace_luck = self.neck.get_greatness();
        let equipped_ring_luck = self.ring.get_greatness();
        let bonus_luck = self.ring.jewelry_bonus_luck();
        let bagged_jewelry_luck = bag.get_jewelry_greatness();
        equipped_necklace_luck + equipped_ring_luck + bonus_luck + bagged_jewelry_luck
    }

    // @notice sets the luck statt of the adventurer
    // @param self: Adventurer to set luck for
    // @param bag: Bag needed for calculating luck
    #[inline(always)]
    fn set_luck(ref self: Adventurer, bag: Bag) {
        self.stats.luck = self.equipment.calculate_luck(bag);
    }

    // in_battle returns true if the adventurer is in battle
    // @param self: Adventurer the adventurer to check if in battle
    // @return bool true if the adventurer is in battle, false otherwise
    #[inline(always)]
    fn in_battle(self: Adventurer) -> bool {
        if self.beast_health == 0 {
            false
        } else {
            true
        }
    }

    // Deducts a specified amount of health from the adventurer's beast, preventing underflow.
    // @param self: Adventurer to deduct beast health from
    // @param amount: Amount of health to deduct from the beast
    #[inline(always)]
    fn deduct_beast_health(ref self: Adventurer, amount: u16) {
        // underflow protection
        if amount > self.beast_health {
            self.beast_health = 0;
        } else {
            self.beast_health -= amount;
        }
    }

    // Sets the beast's health to a specified amount, preventing overflow.
    // @param self: Adventurer to set beast health for
    // @param amount: Amount of health to set the beast's health to
    #[inline(always)]
    fn set_beast_health(ref self: Adventurer, amount: u16) {
        // check for overflow
        // we currently use 9 bits for beast health so MAX HEALTH is 2^9 - 1
        if (amount > BeastSettings::MAXIMUM_HEALTH) {
            self.beast_health = BeastSettings::MAXIMUM_HEALTH;
        } else {
            self.beast_health = amount;
        }
    }

    // @notice Adds health to the adventurer, preventing overflow and capping at max health.
    // @param self a reference to the Adventurer to increase health.
    // @param amount: Amount of health to add to the adventurer
    #[inline(always)]
    fn increase_health(ref self: Adventurer, amount: u16) {
        if (u16_overflowing_add(self.health, amount).is_ok()) {
            if (self.health + amount <= AdventurerUtils::get_max_health(self.stats.vitality)) {
                self.health += amount;
                return;
            }
        }

        // fall through is to set health to max health
        self.health = AdventurerUtils::get_max_health(self.stats.vitality)
    }

    // @notice Decreases health of Adventurer with underflow protection.
    // @param self a reference to the Adventurer to deduct health from.
    // @param value The amount of health to be deducted from the Adventurer.
    #[inline(always)]
    fn decrease_health(ref self: Adventurer, value: u16) {
        // underflow protection
        if value > self.health {
            self.health = 0;
        } else {
            self.health -= value;
        }
    }

    // @notice Increases the Adventurer's gold by the given value, with overflow protection.
    // @param amount The amount of gold to add as a u16.
    #[inline(always)]
    fn increase_gold(ref self: Adventurer, amount: u16) {
        // Check if adding gold would result in overflow
        if (u16_overflowing_add(self.gold, amount).is_ok()) {
            // If it does not cause overflow, check if adding this amount would exceed max gold limit
            if (self.gold + amount <= MAX_GOLD) {
                // If it does not exceed, add gold to the adventurer balance
                self.gold += amount;
                return;
            }
        }

        // In the case of potential overflow or exceeding max gold, set gold to max gold
        self.gold = MAX_GOLD;
    }

    // @notice Increases the Adventurer's experience points by the given value and returns the previous and new level.
    // @dev The function calculates the new level after adding the experience points and returns the previous and new levels as a tuple.
    // @param value The amount of experience to be added to the Adventurer.
    // @return A tuple containing the Adventurer's level before and after the XP addition.
    fn increase_adventurer_xp(ref self: Adventurer, amount: u16) -> (u8, u8) {
        // get the previous level
        let previous_level = self.get_level();

        // check for u16 overflow
        if (u16_overflowing_add(self.xp, amount).is_ok()) {
            // if overflow is ok
            // check if added amount is less than or equal to max xp
            if (self.xp + amount <= MAX_ADVENTURER_XP) {
                // if it is, add xp
                self.xp += amount;
            } else {
                // if amount to add exceeds max xp, set xp to max
                self.xp = MAX_ADVENTURER_XP;
            }
        } else {
            // if we overflow u16, set xp to max xp
            self.xp = MAX_ADVENTURER_XP;
        }

        // get the new level
        let new_level = self.get_level();

        // if adventurer reached a new level
        if (new_level > previous_level) {
            // add stat upgrade points
            let stat_upgrade_points = (new_level - previous_level) * STAT_UPGRADE_POINTS_PER_LEVEL;
            self.increase_stat_upgrades_available(stat_upgrade_points);
        }

        // return the previous and new levels
        (previous_level, new_level)
    }

    // @notice Grants stat upgrades to the Adventurer.
    // @dev The function will add the specified value to the stat_upgrades_available up to the maximum limit of MAX_STAT_UPGRADES_AVAILABLE.
    // @param value The amount of stat points to be added to the Adventurer.
    #[inline(always)]
    fn increase_stat_upgrades_available(ref self: Adventurer, amount: u8) {
        // check for u8 overflow
        if (u8_overflowing_add(self.stat_upgrades_available, amount).is_ok()) {
            // if overflow is ok
            // check if added amount is less than or equal to max upgrade points
            if (self.stat_upgrades_available + amount <= MAX_STAT_UPGRADES_AVAILABLE) {
                // if it is, add upgrade points to adventurer and return
                self.stat_upgrades_available += amount;
                return;
            }
        }

        // fall through is to return MAX_STAT_UPGRADES_AVAILABLE
        // this will happen either in a u8 overflow case
        // or if the upgrade points being added exceeds max upgrade points
        self.stat_upgrades_available = MAX_STAT_UPGRADES_AVAILABLE
    }

    // @dev This function checks if the adventurer has a given item equipped
    // @param item_id The id of the item to check
    // @return A boolean indicating if the item is equipped by the adventurer. Returns true if the item is equipped, false otherwise.
    #[inline(always)]
    fn is_equipped(self: Equipment, item_id: u8) -> bool {
        if (self.weapon.id == item_id) {
            true
        } else if (self.chest.id == item_id) {
            true
        } else if (self.head.id == item_id) {
            true
        } else if (self.waist.id == item_id) {
            true
        } else if (self.foot.id == item_id) {
            true
        } else if (self.hand.id == item_id) {
            true
        } else if (self.neck.id == item_id) {
            true
        } else if (self.ring.id == item_id) {
            true
        } else {
            false
        }
    }


    // @notice determines if a level up resulted in item specials being unlocked
    // @param previous_level: the level of the item before the level up
    // @param new_level: the level of the item after the level up
    // @return (bool, bool): a tuple containing a boolean indicating which item specials were unlocked
    //                            (suffix, prefixes)
    fn unlocked_specials(previous_level: u8, new_level: u8) -> (bool, bool) {
        if (previous_level < 15 && new_level >= 19) {
            // if previous level was below G15 and new level is G19+, sufix and prefixes were unlocked
            return (true, true);
        } else if (previous_level < SUFFIX_UNLOCK_GREATNESS
            && new_level >= SUFFIX_UNLOCK_GREATNESS) {
            // if previous level was below G15 and new level is G15+, suffix was unlocked
            return (true, false);
        } else if (previous_level < 19 && new_level >= 19) {
            // if previous level was below G19 and new level is G19+, prefixes were unlocked
            return (false, true);
        } else {
            // else the level up did not unlock any specials
            return (false, false);
        }
    }

    // @notice provides a a beast seed that is fixed during battle. This function does not use 
    // game entropy as that could change during battle resulting in the beast changing
    // @param self A reference to the Adventurer to get the beast seed for.
    // @param adventurer_entropy A u128 used to randomize the beast seed
    // @return Returns a number used for generated a random beast.
    fn get_beast_seed(self: Adventurer, adventurer_entropy: felt252) -> u128 {
        if self.get_level() > 1 {
            let mut hash_span = ArrayTrait::new();
            hash_span.append(self.xp.into());
            hash_span.append(adventurer_entropy);
            let poseidon = poseidon_hash_span(hash_span.span());
            let (d, _) = integer::U256DivRem::div_rem(
                poseidon.into(), u256_try_as_non_zero(U128_MAX.into()).unwrap()
            );
            d.try_into().unwrap()
        } else {
            0
        }
    }

    // @notice Calculates the bonus luck provided by the jewelry.
    // @param self The item for which the luck bonus is to be calculated.
    // @return Returns the amount of bonus luck, or 0 if the item does not provide a luck bonus.
    #[inline(always)]
    fn jewelry_bonus_luck(self: Item) -> u8 {
        if (self.id == ItemId::SilverRing) {
            self.get_greatness() * SILVER_RING_LUCK_BONUS_PER_GREATNESS
        } else {
            0
        }
    }

    // @notice Calculates the gold bonus provided by the jewelry based on a given base gold amount.
    // @param self The item for which the gold bonus is to be calculated.
    // @param base_gold_amount Base gold amount before the jewelry bonus is applied.
    // @return Returns the amount of bonus gold, or 0 if the item does not provide a gold bonus.
    #[inline(always)]
    fn jewelry_gold_bonus(self: Item, base_gold_amount: u16) -> u16 {
        if (self.id == ItemId::GoldRing) {
            base_gold_amount
                * JEWELRY_BONUS_BEAST_GOLD_PERCENT.into()
                * self.get_greatness().into()
                / 100
        } else {
            0
        }
    }

    /// @notice Calculates the bonus damage provided by the jewelry when the attacker's 
    /// name matches the target's name.
    ///
    /// @param self The item for which the name match bonus damage is to be calculated.
    /// @param base_damage Base damage amount before the jewelry bonus is applied.
    ///
    /// @return Returns the amount of bonus damage, or 0 if the item does not provide a 
    /// name match damage bonus.
    #[inline(always)]
    fn name_match_bonus_damage(self: Item, base_damage: u16) -> u16 {
        if (self.id == ItemId::PlatinumRing) {
            base_damage
                * JEWELRY_BONUS_NAME_MATCH_PERCENT_PER_GREATNESS.into()
                * self.get_greatness().into()
                / 100
        } else {
            0
        }
    }

    /// @notice Calculates the bonus damage provided by the jewelry for critical hits.
    ///
    /// @param self The item for which the critical hit bonus damage is to be calculated.
    /// @param base_damage Base damage amount before the jewelry bonus is applied.
    ///
    /// @return Returns the amount of bonus damage, or 0 if the item does not provide a 
    /// critical hit damage bonus.
    #[inline(always)]
    fn critical_hit_bonus_damage(self: Item, base_damage: u16) -> u16 {
        if (self.id == ItemId::TitaniumRing) {
            base_damage
                * JEWELRY_BONUS_CRITICAL_HIT_PERCENT_PER_GREATNESS.into()
                * self.get_greatness().into()
                / 100
        } else {
            0
        }
    }

    // @notice get the adventurer's equipped items
    // @param adventurer the Adventurer to get equipped items for
    // @return Array<Item>: the adventurer's equipped items
    fn get_equipped_items(self: Adventurer) -> Array<Item> {
        let mut equipped_items = ArrayTrait::<Item>::new();
        if self.equipment.weapon.id != 0 {
            equipped_items.append(self.equipment.weapon);
        }
        if self.equipment.chest.id != 0 {
            equipped_items.append(self.equipment.chest);
        }
        if self.equipment.head.id != 0 {
            equipped_items.append(self.equipment.head);
        }
        if self.equipment.waist.id != 0 {
            equipped_items.append(self.equipment.waist);
        }
        if self.equipment.foot.id != 0 {
            equipped_items.append(self.equipment.foot);
        }
        if self.equipment.hand.id != 0 {
            equipped_items.append(self.equipment.hand);
        }
        if self.equipment.neck.id != 0 {
            equipped_items.append(self.equipment.neck);
        }
        if self.equipment.ring.id != 0 {
            equipped_items.append(self.equipment.ring);
        }
        equipped_items
    }

    fn get_vrf_seed(self: Adventurer, adventurer_id: felt252, adventurer_entropy: felt252) -> u64 {
        let mut hash_span = ArrayTrait::<felt252>::new();
        hash_span.append(self.xp.into());
        hash_span.append(adventurer_id);
        hash_span.append(adventurer_entropy);
        let poseidon = poseidon_hash_span(hash_span.span());
        let (_, r) = integer::U256DivRem::div_rem(
            poseidon.into(), u256_try_as_non_zero(U64_MAX.into()).unwrap()
        );
        return r.try_into().unwrap();
    }

    #[inline(always)]
    fn can_explore(self: Adventurer) -> bool {
        self.health != 0
            && self.beast_health == 0
            && self.stat_upgrades_available == 0
            && !self.awaiting_item_specials
    }


    /// @notice Executes an attack from an Adventurer to a Beast.
    /// 
    /// @dev The function calculates the damage dealt to the Beast using a combination 
    /// of the adventurer's weapon, stats, jewelry bonuses, and entropy to influence 
    /// critical hits. Note: Beasts do not have strength in this version.
    ///
    /// @param self The Adventurer executing the attack.
    /// @param weapon_combat_spec Combat specifications of the weapon being used.
    /// @param beast The Beast that is being attacked.
    /// @param entropy A u128 entropy value used to determine critical hits and other 
    /// random outcomes.
    ///
    /// @return Returns a CombatResult object containing the details of the attack's 
    /// outcome.
    fn attack(
        self: Adventurer, weapon_combat_spec: CombatSpec, beast: Beast, entropy: u128
    ) -> CombatResult {
        // no strength for beasts in this version
        let beast_strength = 0;

        // calculate attack damage
        let mut combat_results = ImplCombat::calculate_damage(
            weapon_combat_spec,
            beast.combat_spec,
            MINIMUM_DAMAGE_TO_BEASTS,
            self.stats.strength,
            beast_strength,
            self.stats.luck,
            entropy
        );

        // get jewelry bonus for name match damage
        let name_match_jewelry_bonus = self
            .equipment
            .ring
            .name_match_bonus_damage(combat_results.weapon_special_bonus);

        // get jewelry bonus for name match damage
        let critical_hit_jewelry_bonus = self
            .equipment
            .ring
            .critical_hit_bonus_damage(combat_results.critical_hit_bonus);

        // add jewelry bonus damage to combat results
        combat_results.total_damage += name_match_jewelry_bonus + critical_hit_jewelry_bonus;

        // return result
        combat_results
    }

    // @notice Defend against a beast attack
    // @param self The adventurer.
    // @param beast The beast against which the adventurer is defending.
    // @param armor The armor item the adventurer is using.
    // @param armor_specials Special attributes associated with the armor.
    // @param entropy Randomness input for the function's calculations.
    // @return A tuple containing the combat result and jewelry armor bonus.
    fn defend(
        self: Adventurer,
        beast: Beast,
        armor: Item,
        armor_specials: SpecialPowers,
        entropy: u128,
        is_ambush: bool
    ) -> (CombatResult, u16) {
        // adventurer strength isn't used for defense
        let attacker_strength = 0;
        let beast_strength = 0;

        // get armor details
        let armor_details = ImplLoot::get_item(armor.id);

        // get combat spec for armor
        let armor_combat_spec = CombatSpec {
            tier: armor_details.tier,
            item_type: armor_details.item_type,
            level: armor.get_greatness().into(),
            specials: armor_specials
        };

        let critical_hit_chance = ImplBeast::get_critical_hit_chance(self.get_level(), is_ambush);

        // calculate damage
        let mut combat_result = ImplCombat::calculate_damage(
            beast.combat_spec,
            armor_combat_spec,
            MINIMUM_DAMAGE_FROM_BEASTS,
            attacker_strength,
            beast_strength,
            critical_hit_chance,
            entropy
        );

        // get jewelry armor bonus
        let jewelry_armor_bonus = self
            .equipment
            .neck
            .jewelry_armor_bonus(armor_details.item_type, combat_result.base_armor);

        // adjust combat result for jewelry armor bonus
        if combat_result.total_damage > (jewelry_armor_bonus + MINIMUM_DAMAGE_FROM_BEASTS.into()) {
            combat_result.total_damage -= jewelry_armor_bonus;
        } else {
            combat_result.total_damage = MINIMUM_DAMAGE_FROM_BEASTS.into();
        }

        // return combat_result and jewelry_armor_bonus
        (combat_result, jewelry_armor_bonus)
    }

    // @notice Get a random obstacle based on adventurer level and entropy.
    // @param self The adventurer.
    // @param entropy Randomness input for the obstacle selection.
    // @return The selected obstacle.
    fn get_random_obstacle(self: Adventurer, entropy: u128) -> Obstacle {
        let obstacle_id = ImplObstacle::get_random_id(entropy);
        let obstacle_level = ImplObstacle::get_random_level(self.get_level(), entropy);
        ImplObstacle::get_obstacle(obstacle_id, obstacle_level)
    }

    // @notice Calculate damage from an obstacle while considering armor.
    // @param self The adventurer.
    // @param obstacle The obstacle the adventurer is facing.
    // @param armor The armor item the adventurer is using.
    // @param entropy Randomness input for the damage calculation.
    // @return A tuple containing the combat result and jewelry armor bonus.
    fn get_obstacle_damage(
        self: Adventurer, obstacle: Obstacle, armor: Item, entropy: u128,
    ) -> (CombatResult, u16) {
        // adventurer strength isn't used for obstacle encounters
        let attacker_strength = 0;
        let beast_strength = 0;

        // get armor details
        let armor_details = ImplLoot::get_item(armor.id);

        // get combat spec for armor, no need to fetch armor specials since they don't apply to obstacles
        let armor_combat_spec = CombatSpec {
            tier: armor_details.tier,
            item_type: armor_details.item_type,
            level: armor.get_greatness().into(),
            specials: SpecialPowers { special1: 0, special2: 0, special3: 0 }
        };

        let critical_hit_chance = ImplAdventurer::get_dynamic_critical_hit_chance(self.get_level());

        // calculate damage
        let mut combat_result = ImplCombat::calculate_damage(
            obstacle.combat_spec,
            armor_combat_spec,
            MINIMUM_DAMAGE_FROM_OBSTACLES,
            attacker_strength,
            beast_strength,
            critical_hit_chance,
            entropy
        );

        // get jewelry armor bonus
        let jewelry_armor_bonus = self
            .equipment
            .neck
            .jewelry_armor_bonus(armor_details.item_type, combat_result.base_armor);

        // adjust damage for jewelry armor bonus
        if combat_result
            .total_damage > (jewelry_armor_bonus + MINIMUM_DAMAGE_FROM_OBSTACLES.into()) {
            combat_result.total_damage -= jewelry_armor_bonus;
        } else {
            combat_result.total_damage = MINIMUM_DAMAGE_FROM_OBSTACLES.into();
        }

        // return combat_result and jewelry_armor_bonus
        (combat_result, jewelry_armor_bonus)
    }

    fn get_dynamic_critical_hit_chance(level: u8) -> u8 {
        let chance = level * CRITICAL_HIT_LEVEL_MULTIPLIER;
        if (chance > 100) {
            100
        } else {
            chance
        }
    }

    /// @title Jewelry Armor Bonus Calculation
    /// @notice Calculate the bonus provided by a jewelry item to a particular armor type.
    ///
    /// @dev The function uses a matching system to determine if a particular jewelry item 
    /// (like an amulet, pendant, or necklace) provides a bonus to a given armor type.
    /// The bonus is computed by multiplying the base armor value with the greatness of 
    /// the jewelry and a constant bonus factor.
    ///
    /// @param self The jewelry item under consideration.
    /// @param armor_type The type of armor to which the jewelry may or may not provide a bonus.
    /// @param base_armor The base armor value to which the bonus would be applied if applicable.
    ///
    /// @return The bonus armor value provided by the jewelry to the armor. Returns 0 if no bonus.
    fn jewelry_armor_bonus(self: Item, armor_type: Type, base_armor: u16) -> u16 {
        // qualify no bonus outcomes and return 0
        match armor_type {
            Type::None(()) => { return 0; },
            Type::Magic_or_Cloth(()) => { if (self.id != ItemId::Amulet) {
                return 0;
            } },
            Type::Blade_or_Hide(()) => { if (self.id != ItemId::Pendant) {
                return 0;
            } },
            Type::Bludgeon_or_Metal(()) => { if (self.id != ItemId::Necklace) {
                return 0;
            } },
            Type::Necklace(()) => { return 0; },
            Type::Ring(()) => { return 0; }
        }

        // if execution reaches here, the necklace provides a bonus for the armor type
        base_armor * (self.get_greatness() * NECKLACE_ARMOR_BONUS).into() / 100
    }
}

const TWO_POW_4: u256 = 0x10;
const TWO_POW_9: u256 = 0x200;
const TWO_POW_10: u256 = 0x400;
const TWO_POW_15: u256 = 0x8000;
const TWO_POW_25: u256 = 0x2000000;
const TWO_POW_30: u256 = 0x40000000;
const TWO_POW_34: u256 = 0x400000000;
const TWO_POW_44: u256 = 0x100000000000;
const TWO_POW_48: u256 = 0x1000000000000;
const TWO_POW_78: u256 = 0x40000000000000000000;
const TWO_POW_128: u256 = 0x100000000000000000000000000000000;

// ---------------------------
// ---------- Tests ----------
// ---------------------------
#[cfg(test)]
mod tests {
    use core::result::ResultTrait;
    use integer::{u8_overflowing_add, u16_overflowing_add, u16_overflowing_sub};
    use traits::{TryInto, Into};
    use option::OptionTrait;
    use poseidon::poseidon_hash_span;
    use array::ArrayTrait;
    use loot::{loot::{Loot, ILoot, ImplLoot}, constants::{ItemSuffix, ItemId}, utils::{ItemUtils}};
    use combat::{constants::CombatEnums::{Slot, Type}};
    use beasts::{beast::{ImplBeast, Beast}, constants::{BeastSettings, BeastId}};
    use adventurer::{
        adventurer::{IAdventurer, ImplAdventurer, Adventurer, AdventurerPacking},
        stats::{Stats, ImplStats, MAX_STAT_VALUE}, equipment::{Equipment, ImplEquipment},
        item::{Item, MAX_PACKABLE_XP}, adventurer_utils::{AdventurerUtils}, bag::{Bag, ImplBag},
        constants::{
            adventurer_constants::{
                STARTING_GOLD, StatisticIndex, POTION_PRICE, STARTING_HEALTH,
                CHARISMA_POTION_DISCOUNT, MINIMUM_ITEM_PRICE, MINIMUM_POTION_PRICE,
                HEALTH_INCREASE_PER_VITALITY, MAX_GOLD, MAX_STAT_UPGRADES_AVAILABLE,
                MAX_ADVENTURER_XP, MAX_ADVENTURER_BLOCKS, ITEM_MAX_GREATNESS, ITEM_MAX_XP,
                MAX_ADVENTURER_HEALTH, CHARISMA_ITEM_DISCOUNT, MAX_BLOCK_COUNT,
                SILVER_RING_G20_LUCK_BONUS, JEWELRY_BONUS_NAME_MATCH_PERCENT_PER_GREATNESS,
                NECKLACE_ARMOR_BONUS, SILVER_RING_LUCK_BONUS_PER_GREATNESS,
                MAX_PACKABLE_BEAST_HEALTH,
            },
            discovery_constants::DiscoveryEnums::{ExploreResult, DiscoveryType}
        }
    };

    #[test]
    #[available_gas(30020000)]
    fn test_adventurer_packing() {
        let weapon = Item { id: ItemId::Wand, xp: MAX_PACKABLE_XP };
        let chest = Item { id: ItemId::DivineRobe, xp: MAX_PACKABLE_XP };
        let head = Item { id: ItemId::DivineHood, xp: MAX_PACKABLE_XP };
        let waist = Item { id: ItemId::BrightsilkSash, xp: MAX_PACKABLE_XP };
        let foot = Item { id: ItemId::DivineSlippers, xp: MAX_PACKABLE_XP };
        let hand = Item { id: ItemId::DivineGloves, xp: MAX_PACKABLE_XP };
        let neck = Item { id: ItemId::Amulet, xp: MAX_PACKABLE_XP };
        let ring = Item { id: ItemId::GoldRing, xp: MAX_PACKABLE_XP };
        let equipment = Equipment { weapon, chest, head, waist, foot, hand, neck, ring };

        let strength = MAX_STAT_VALUE;
        let dexterity = MAX_STAT_VALUE;
        let vitality = MAX_STAT_VALUE;
        let intelligence = MAX_STAT_VALUE;
        let wisdom = MAX_STAT_VALUE;
        let charisma = MAX_STAT_VALUE;
        let luck = 0;
        let stats = Stats { strength, dexterity, vitality, intelligence, wisdom, charisma, luck };

        let adventurer = Adventurer {
            health: MAX_ADVENTURER_HEALTH,
            xp: MAX_ADVENTURER_XP,
            gold: MAX_GOLD,
            stats,
            equipment,
            beast_health: MAX_PACKABLE_BEAST_HEALTH,
            stat_upgrades_available: MAX_STAT_UPGRADES_AVAILABLE,
            mutated: false,
            awaiting_item_specials: false
        };
        let unpacked: Adventurer = AdventurerPacking::unpack(AdventurerPacking::pack(adventurer));
        assert(adventurer.health == unpacked.health, 'health');
        assert(adventurer.xp == unpacked.xp, 'xp');
        assert(adventurer.gold == unpacked.gold, 'luck');
        assert(adventurer.beast_health == unpacked.beast_health, 'wrong beast health');
        assert(
            adventurer.stat_upgrades_available == unpacked.stat_upgrades_available,
            'stat_upgrades_available'
        );
        assert(adventurer.stats == unpacked.stats, 'wrong unpacked stats');
        assert(adventurer.equipment == unpacked.equipment, 'equipment mistmatch');

        let adventurer = Adventurer {
            health: MAX_ADVENTURER_HEALTH,
            xp: MAX_ADVENTURER_XP,
            gold: MAX_GOLD,
            stats: Stats {
                strength: MAX_STAT_VALUE,
                dexterity: 0,
                vitality: MAX_STAT_VALUE,
                intelligence: 1,
                wisdom: MAX_STAT_VALUE,
                charisma: 2,
                luck: 0
            },
            equipment: Equipment {
                weapon: Item { id: 127, xp: 511 },
                chest: Item { id: 1, xp: 0 },
                head: Item { id: 127, xp: 511 },
                waist: Item { id: 87, xp: 1 },
                foot: Item { id: 78, xp: 511 },
                hand: Item { id: 34, xp: 2 },
                neck: Item { id: 32, xp: 511 },
                ring: Item { id: 1, xp: 3 }
            },
            beast_health: MAX_PACKABLE_BEAST_HEALTH,
            stat_upgrades_available: MAX_STAT_UPGRADES_AVAILABLE,
            mutated: false,
            awaiting_item_specials: false
        };
        let packed = AdventurerPacking::pack(adventurer);
        let unpacked: Adventurer = AdventurerPacking::unpack(packed);
        assert(adventurer.health == unpacked.health, 'health');
        assert(adventurer.xp == unpacked.xp, 'xp');
        assert(adventurer.stats.strength == unpacked.stats.strength, 'strength');
        assert(adventurer.stats.dexterity == unpacked.stats.dexterity, 'dexterity');
        assert(adventurer.stats.vitality == unpacked.stats.vitality, 'vitality');
        assert(adventurer.stats.intelligence == unpacked.stats.intelligence, 'intelligence');
        assert(adventurer.stats.wisdom == unpacked.stats.wisdom, 'wisdom');
        assert(adventurer.stats.charisma == unpacked.stats.charisma, 'charisma');
        assert(adventurer.gold == unpacked.gold, 'luck');
        assert(adventurer.equipment.weapon.id == unpacked.equipment.weapon.id, 'weapon.id');
        assert(adventurer.equipment.weapon.xp == unpacked.equipment.weapon.xp, 'weapon.xp');
        assert(adventurer.equipment.chest.id == unpacked.equipment.chest.id, 'chest.id');
        assert(adventurer.equipment.chest.xp == unpacked.equipment.chest.xp, 'chest.xp');
        assert(adventurer.equipment.head.id == unpacked.equipment.head.id, 'head.id');
        assert(adventurer.equipment.head.xp == unpacked.equipment.head.xp, 'head.xp');
        assert(adventurer.equipment.waist.id == unpacked.equipment.waist.id, 'waist.id');
        assert(adventurer.equipment.waist.xp == unpacked.equipment.waist.xp, 'waist.xp');
        assert(adventurer.equipment.foot.id == unpacked.equipment.foot.id, 'foot.id');
        assert(adventurer.equipment.foot.xp == unpacked.equipment.foot.xp, 'foot.xp');
        assert(adventurer.equipment.hand.id == unpacked.equipment.hand.id, 'hand.id');
        assert(adventurer.equipment.hand.xp == unpacked.equipment.hand.xp, 'hand.xp2');
        assert(adventurer.equipment.neck.id == unpacked.equipment.neck.id, 'neck.id');
        assert(adventurer.equipment.neck.xp == unpacked.equipment.neck.xp, 'neck.xp');
        assert(adventurer.equipment.ring.id == unpacked.equipment.ring.id, 'ring.id');
        assert(adventurer.equipment.ring.xp == unpacked.equipment.ring.xp, 'ring.xp');
        //assert(adventurer.beast_health == unpacked.beast_health, 'beast_health');
        assert(
            adventurer.stat_upgrades_available == unpacked.stat_upgrades_available,
            'stat_upgrades_available'
        );
    }

    #[test]
    #[available_gas(184194)]
    fn test_jewelry_gold_bonus_gas() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        adventurer.equipment.ring.jewelry_gold_bonus(1);
    }

    #[test]
    #[available_gas(1914024)]
    fn test_jewelry_gold_bonus() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        let base_gold_amount = 100;

        // no gold ring equipped gets no bonus
        assert(
            adventurer.equipment.ring.jewelry_gold_bonus(base_gold_amount) == 0,
            'no bonus with gold gold ring'
        );

        // equip gold ring with G1
        let gold_ring = Item { id: ItemId::GoldRing, xp: 1 };
        adventurer.equipment.ring = gold_ring;
        let _bonus = adventurer.equipment.ring.jewelry_gold_bonus(base_gold_amount);
        assert(
            adventurer.equipment.ring.jewelry_gold_bonus(base_gold_amount) == 3, 'bonus should be 3'
        );

        // increase greatness of gold ring to 10
        adventurer.equipment.ring.xp = 100;
        assert(
            adventurer.equipment.ring.jewelry_gold_bonus(base_gold_amount) == 30,
            'bonus should be 30'
        );

        // increase greatness of gold ring to 20
        adventurer.equipment.ring.xp = 400;
        assert(
            adventurer.equipment.ring.jewelry_gold_bonus(base_gold_amount) == 60,
            'bonus should be 60'
        );

        // zero case
        assert(adventurer.equipment.ring.jewelry_gold_bonus(0) == 0, 'bonus should be 0');

        // change to platinum ring
        let platinum_ring = Item { id: ItemId::PlatinumRing, xp: 1 };
        adventurer.equipment.ring = platinum_ring;
        assert(adventurer.equipment.ring.jewelry_gold_bonus(0) == 0, 'no bonus with plat ring');
    }

    #[test]
    #[available_gas(173744)]
    fn test_get_bonus_luck_gas() {
        // instantiate silver ring
        let silver_ring = Item { id: ItemId::SilverRing, xp: 1 };
        let _bonus_luck = silver_ring.jewelry_bonus_luck();
    }

    #[test]
    #[available_gas(194024)]
    fn test_get_bonus_luck() {
        // equip silver ring
        let mut silver_ring = Item { id: ItemId::SilverRing, xp: 1 };
        assert(
            silver_ring.jewelry_bonus_luck() == SILVER_RING_LUCK_BONUS_PER_GREATNESS,
            'wrong g1 bonus luck'
        );

        // increase greatness to 20
        silver_ring.xp = 400;
        assert(
            silver_ring.jewelry_bonus_luck() == SILVER_RING_LUCK_BONUS_PER_GREATNESS * 20,
            'wrong g20 bonus luck'
        );

        // verify none of the other rings provide a luck bonus
        let gold_ring = Item { id: ItemId::GoldRing, xp: 400 };
        let bronze_ring = Item { id: ItemId::BronzeRing, xp: 400 };
        let platinum_ring = Item { id: ItemId::PlatinumRing, xp: 400 };
        let titanium_ring = Item { id: ItemId::TitaniumRing, xp: 400 };

        assert(gold_ring.jewelry_bonus_luck() == 0, 'no bonus luck for gold ring');
        assert(bronze_ring.jewelry_bonus_luck() == 0, 'no bonus luck for bronze ring');
        assert(platinum_ring.jewelry_bonus_luck() == 0, 'no bonus luck for platinum ring');
        assert(titanium_ring.jewelry_bonus_luck() == 0, 'no bonus luck for titanium ring');
    }

    #[test]
    #[available_gas(44860)]
    fn test_unlocked_specials() {
        let previous_level = 0;
        let new_level = 0;
        let (suffix_unlocked, prefixes_unlocked) = ImplAdventurer::unlocked_specials(
            previous_level, new_level
        );
        assert(!suffix_unlocked, 'suffix should not be unlocked');
        assert(!prefixes_unlocked, 'prefixes should not be unlocked');

        let previous_level = 0;
        let new_level = 1;
        let (suffix_unlocked, prefixes_unlocked) = ImplAdventurer::unlocked_specials(
            previous_level, new_level
        );
        assert(!suffix_unlocked, 'suffix should not be unlocked');
        assert(!prefixes_unlocked, 'prefixes should not be unlocked');

        let previous_level = 1;
        let new_level = 14;
        let (suffix_unlocked, prefixes_unlocked) = ImplAdventurer::unlocked_specials(
            previous_level, new_level
        );
        assert(!suffix_unlocked, 'suffix should not be unlocked');
        assert(!prefixes_unlocked, 'prefixes should not be unlocked');

        let previous_level = 14;
        let new_level = 15;
        let (suffix_unlocked, prefixes_unlocked) = ImplAdventurer::unlocked_specials(
            previous_level, new_level
        );
        assert(suffix_unlocked, 'suffix should be unlocked');
        assert(!prefixes_unlocked, 'prefixes should not be unlocked');

        let previous_level = 15;
        let new_level = 18;
        let (suffix_unlocked, prefixes_unlocked) = ImplAdventurer::unlocked_specials(
            previous_level, new_level
        );
        assert(!suffix_unlocked, 'suffix should not be unlocked');
        assert(!prefixes_unlocked, 'prefixes should not be unlocked');

        let previous_level = 18;
        let new_level = 19;
        let (suffix_unlocked, prefixes_unlocked) = ImplAdventurer::unlocked_specials(
            previous_level, new_level
        );
        assert(!suffix_unlocked, 'suffix should not be unlocked');
        assert(prefixes_unlocked, 'prefixes should be unlocked');

        let previous_level = 19;
        let new_level = 20;
        let (suffix_unlocked, prefixes_unlocked) = ImplAdventurer::unlocked_specials(
            previous_level, new_level
        );
        assert(!suffix_unlocked, 'suffix should not be unlocked');
        assert(!prefixes_unlocked, 'prefixes should not be unlocked');

        let previous_level = 14;
        let new_level = 19;
        let (suffix_unlocked, prefixes_unlocked) = ImplAdventurer::unlocked_specials(
            previous_level, new_level
        );
        assert(suffix_unlocked, 'suffix should be unlocked');
        assert(prefixes_unlocked, 'prefixes should be unlocked');
    }

    #[test]
    #[available_gas(14610)]
    fn test_jewelry_armor_bonus_gas() {
        let amulet = Item { id: ItemId::Amulet, xp: 400 };
        amulet.jewelry_armor_bonus(Type::Magic_or_Cloth(()), 100);
    }

    #[test]
    #[available_gas(284000)]
    fn test_jewelry_armor_bonus() {
        // amulet test cases
        let amulet = Item { id: ItemId::Amulet, xp: 400 };
        assert(amulet.jewelry_armor_bonus(Type::None(()), 100) == 0, 'None Type gets 0 bonus');
        assert(
            amulet.jewelry_armor_bonus(Type::Magic_or_Cloth(()), 100) == NECKLACE_ARMOR_BONUS.into()
                * 20,
            'Amulet provide cloth bonus'
        );
        assert(
            amulet.jewelry_armor_bonus(Type::Blade_or_Hide(()), 100) == 0,
            'Amulet does not boost hide'
        );
        assert(
            amulet.jewelry_armor_bonus(Type::Bludgeon_or_Metal(()), 100) == 0,
            'Amulet does not boost metal'
        );
        assert(
            amulet.jewelry_armor_bonus(Type::Necklace(()), 100) == 0, 'Necklace Type gets 0 bonus'
        );
        assert(amulet.jewelry_armor_bonus(Type::Ring(()), 100) == 0, 'Ring Type gets 0 bonus');

        // pendant test cases
        let pendant = Item { id: ItemId::Pendant, xp: 400 };
        assert(pendant.jewelry_armor_bonus(Type::None(()), 100) == 0, 'None Type gets 0 bonus');
        assert(
            pendant.jewelry_armor_bonus(Type::Magic_or_Cloth(()), 100) == 0,
            'Pendant does not boost cloth'
        );
        assert(
            pendant.jewelry_armor_bonus(Type::Blade_or_Hide(()), 100) == NECKLACE_ARMOR_BONUS.into()
                * 20,
            'Pendant boosts hide'
        );
        assert(
            pendant.jewelry_armor_bonus(Type::Bludgeon_or_Metal(()), 100) == 0,
            'Pendant does not boost metal'
        );
        assert(
            pendant.jewelry_armor_bonus(Type::Necklace(()), 100) == 0, 'Necklace Type gets 0 bonus'
        );
        assert(pendant.jewelry_armor_bonus(Type::Ring(()), 100) == 0, 'Ring Type gets 0 bonus');

        // necklace test cases
        let necklace = Item { id: ItemId::Necklace, xp: 400 };
        assert(necklace.jewelry_armor_bonus(Type::None(()), 100) == 0, 'None Type gets 0 bonus');
        assert(
            necklace.jewelry_armor_bonus(Type::Magic_or_Cloth(()), 100) == 0,
            'Necklace does not boost cloth'
        );
        assert(
            necklace.jewelry_armor_bonus(Type::Blade_or_Hide(()), 100) == 0,
            'Necklace does not boost hide'
        );
        assert(
            necklace
                .jewelry_armor_bonus(Type::Bludgeon_or_Metal(()), 100) == NECKLACE_ARMOR_BONUS
                .into()
                * 20,
            'Necklace boosts metal'
        );
        assert(
            necklace.jewelry_armor_bonus(Type::Necklace(()), 100) == 0, 'Necklace Type gets 0 bonus'
        );
        assert(necklace.jewelry_armor_bonus(Type::Ring(()), 100) == 0, 'Ring Type gets 0 bonus');

        // test non jewelry item
        let katana = Item { id: ItemId::Katana, xp: 400 };
        assert(katana.jewelry_armor_bonus(Type::None(()), 100) == 0, 'Katan does not boost armor');
    }

    // gas baseline
    #[test]
    #[available_gas(13510)]
    fn test_name_match_bonus_damage_gas() {
        let platinum_ring = Item { id: ItemId::PlatinumRing, xp: 400 };
        platinum_ring.name_match_bonus_damage(0);
    }

    #[test]
    #[available_gas(60180)]
    fn test_name_match_bonus_damage() {
        let base_damage = 100;

        let titanium_ring = Item { id: ItemId::TitaniumRing, xp: 400 };
        assert(
            titanium_ring.name_match_bonus_damage(base_damage) == 0, 'no bonus for titanium ring'
        );

        let platinum_ring = Item { id: ItemId::PlatinumRing, xp: 0 };
        assert(
            platinum_ring
                .name_match_bonus_damage(
                    base_damage
                ) == JEWELRY_BONUS_NAME_MATCH_PERCENT_PER_GREATNESS
                .into(),
            'should be 3hp name bonus'
        );

        let platinum_ring = Item { id: ItemId::PlatinumRing, xp: 100 };
        assert(
            platinum_ring
                .name_match_bonus_damage(
                    base_damage
                ) == (JEWELRY_BONUS_NAME_MATCH_PERCENT_PER_GREATNESS * 10)
                .into(),
            'should be 30hp name bonus'
        );

        let platinum_ring = Item { id: ItemId::PlatinumRing, xp: 400 };
        assert(
            platinum_ring
                .name_match_bonus_damage(
                    base_damage
                ) == (JEWELRY_BONUS_NAME_MATCH_PERCENT_PER_GREATNESS * 20)
                .into(),
            'should be 60hp name bonus'
        );
    }

    #[test]
    #[available_gas(275934)]
    fn test_get_beast_seed_gas() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        let adventurer_entropy = 1;
        ImplAdventurer::get_beast_seed(adventurer, adventurer_entropy);
        adventurer.xp = 100;
        ImplAdventurer::get_beast_seed(adventurer, adventurer_entropy);
    }

    #[test]
    #[available_gas(1064170)]
    fn test_get_beast() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);

        let entropy = 1;
        // check new adventurer (level 1) gets a starter beast
        let (beast, _) = adventurer.get_beast(1, entropy);
        assert(beast.combat_spec.level == 1, 'beast should be lvl1');
        assert(beast.combat_spec.specials.special1 == 0, 'beast should have no special1');
        assert(beast.combat_spec.specials.special2 == 0, 'beast should have no special2');
        assert(beast.combat_spec.specials.special3 == 0, 'beast should have no special3');

        let entropy = 2;
        // check beast is still starter beast with different entropy source
        let (beast, _) = adventurer.get_beast(1, entropy);
        assert(beast.combat_spec.level == 1, 'beast should be lvl1');
        assert(beast.combat_spec.specials.special1 == 0, 'beast should have no special1');
        assert(beast.combat_spec.specials.special2 == 0, 'beast should have no special2');
        assert(beast.combat_spec.specials.special3 == 0, 'beast should have no special3');

        // advance adventurer to level 2
        adventurer.xp = 4;
        let entropy = 1;
        let (beast1, _) = adventurer.get_beast(1, entropy);
        let entropy = 2;
        let (beast2, _) = adventurer.get_beast(1, entropy);

        // verify beasts are the same since the seed did not change
        assert(beast1.id != beast2.id, 'beasts not unique');
    }

    #[test]
    fn test_get_beast_distribution_fixed_entropy() {
        let mut warlock_count: u32 = 0;
        let mut typhon_count: u32 = 0;
        let mut jiangshi_count: u32 = 0;
        let mut anansi_count: u32 = 0;
        let mut basilisk_count: u32 = 0;
        let mut gorgon_count: u32 = 0;
        let mut kitsune_count: u32 = 0;
        let mut lich_count: u32 = 0;
        let mut chimera_count: u32 = 0;
        let mut wendigo_count: u32 = 0;
        let mut raksasa_count: u32 = 0;
        let mut werewolf_count: u32 = 0;
        let mut banshee_count: u32 = 0;
        let mut draugr_count: u32 = 0;
        let mut vampire_count: u32 = 0;
        let mut goblin_count: u32 = 0;
        let mut ghoul_count: u32 = 0;
        let mut wraith_count: u32 = 0;
        let mut sprite_count: u32 = 0;
        let mut kappa_count: u32 = 0;
        let mut fairy_count: u32 = 0;
        let mut leprechaun_count: u32 = 0;
        let mut kelpie_count: u32 = 0;
        let mut pixie_count: u32 = 0;
        let mut gnome_count: u32 = 0;
        let mut griffin_count: u32 = 0;
        let mut manticore_count: u32 = 0;
        let mut phoenix_count: u32 = 0;
        let mut dragon_count: u32 = 0;
        let mut minotaur_count: u32 = 0;
        let mut qilin_count: u32 = 0;
        let mut ammit_count: u32 = 0;
        let mut nue_count: u32 = 0;
        let mut skinwalker_count: u32 = 0;
        let mut chupacabra_count: u32 = 0;
        let mut weretiger_count: u32 = 0;
        let mut wyvern_count: u32 = 0;
        let mut roc_count: u32 = 0;
        let mut harpy_count: u32 = 0;
        let mut pegasus_count: u32 = 0;
        let mut hippogriff_count: u32 = 0;
        let mut fenrir_count: u32 = 0;
        let mut jaguar_count: u32 = 0;
        let mut satori_count: u32 = 0;
        let mut direwolf_count: u32 = 0;
        let mut bear_count: u32 = 0;
        let mut wolf_count: u32 = 0;
        let mut mantis_count: u32 = 0;
        let mut spider_count: u32 = 0;
        let mut rat_count: u32 = 0;
        let mut kraken_count: u32 = 0;
        let mut colossus_count: u32 = 0;
        let mut balrog_count: u32 = 0;
        let mut leviathan_count: u32 = 0;
        let mut tarrasque_count: u32 = 0;
        let mut titan_count: u32 = 0;
        let mut nephilim_count: u32 = 0;
        let mut behemoth_count: u32 = 0;
        let mut hydra_count: u32 = 0;
        let mut juggernaut_count: u32 = 0;
        let mut oni_count: u32 = 0;
        let mut jotunn_count: u32 = 0;
        let mut ettin_count: u32 = 0;
        let mut cyclops_count: u32 = 0;
        let mut giant_count: u32 = 0;
        let mut nemean_lion_count: u32 = 0;
        let mut berserker_count: u32 = 0;
        let mut yeti_count: u32 = 0;
        let mut golem_count: u32 = 0;
        let mut ent_count: u32 = 0;
        let mut troll_count: u32 = 0;
        let mut bigfoot_count: u32 = 0;
        let mut ogre_count: u32 = 0;
        let mut orc_count: u32 = 0;
        let mut skeleton_count: u32 = 0;

        let mut total_beasts = 0;

        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        let mut xp = 1;

        let adventurer_entropy: felt252 = 123456789;
        loop {
            if xp == 7500 {
                break;
            }

            adventurer.xp = xp;

            let (r, _) = AdventurerUtils::get_randomness(xp, adventurer_entropy);

            match AdventurerUtils::get_random_explore(r) {
                ExploreResult::Beast(()) => {
                    total_beasts += 1;
                    let (beast, _seed) = adventurer.get_beast(1, adventurer_entropy);
                    if beast.id == BeastId::Warlock {
                        warlock_count += 1;
                    } else if beast.id == BeastId::Typhon {
                        typhon_count += 1;
                    } else if beast.id == BeastId::Jiangshi {
                        jiangshi_count += 1;
                    } else if beast.id == BeastId::Anansi {
                        anansi_count += 1;
                    } else if beast.id == BeastId::Basilisk {
                        basilisk_count += 1;
                    } else if beast.id == BeastId::Gorgon {
                        gorgon_count += 1;
                    } else if beast.id == BeastId::Kitsune {
                        kitsune_count += 1;
                    } else if beast.id == BeastId::Lich {
                        lich_count += 1;
                    } else if beast.id == BeastId::Chimera {
                        chimera_count += 1;
                    } else if beast.id == BeastId::Wendigo {
                        wendigo_count += 1;
                    } else if beast.id == BeastId::Rakshasa {
                        raksasa_count += 1;
                    } else if beast.id == BeastId::Werewolf {
                        werewolf_count += 1;
                    } else if beast.id == BeastId::Banshee {
                        banshee_count += 1;
                    } else if beast.id == BeastId::Draugr {
                        draugr_count += 1;
                    } else if beast.id == BeastId::Vampire {
                        vampire_count += 1;
                    } else if beast.id == BeastId::Goblin {
                        goblin_count += 1;
                    } else if beast.id == BeastId::Ghoul {
                        ghoul_count += 1;
                    } else if beast.id == BeastId::Wraith {
                        wraith_count += 1;
                    } else if beast.id == BeastId::Sprite {
                        sprite_count += 1;
                    } else if beast.id == BeastId::Kappa {
                        kappa_count += 1;
                    } else if beast.id == BeastId::Fairy {
                        fairy_count += 1;
                    } else if beast.id == BeastId::Leprechaun {
                        leprechaun_count += 1;
                    } else if beast.id == BeastId::Kelpie {
                        kelpie_count += 1;
                    } else if beast.id == BeastId::Pixie {
                        pixie_count += 1;
                    } else if beast.id == BeastId::Gnome {
                        gnome_count += 1;
                    } else if beast.id == BeastId::Griffin {
                        griffin_count += 1;
                    } else if beast.id == BeastId::Manticore {
                        manticore_count += 1;
                    } else if beast.id == BeastId::Phoenix {
                        phoenix_count += 1;
                    } else if beast.id == BeastId::Dragon {
                        dragon_count += 1;
                    } else if beast.id == BeastId::Minotaur {
                        minotaur_count += 1;
                    } else if beast.id == BeastId::Qilin {
                        qilin_count += 1;
                    } else if beast.id == BeastId::Ammit {
                        ammit_count += 1;
                    } else if beast.id == BeastId::Nue {
                        nue_count += 1;
                    } else if beast.id == BeastId::Skinwalker {
                        skinwalker_count += 1;
                    } else if beast.id == BeastId::Chupacabra {
                        chupacabra_count += 1;
                    } else if beast.id == BeastId::Weretiger {
                        weretiger_count += 1;
                    } else if beast.id == BeastId::Wyvern {
                        wyvern_count += 1;
                    } else if beast.id == BeastId::Roc {
                        roc_count += 1;
                    } else if beast.id == BeastId::Harpy {
                        harpy_count += 1;
                    } else if beast.id == BeastId::Pegasus {
                        pegasus_count += 1;
                    } else if beast.id == BeastId::Hippogriff {
                        hippogriff_count += 1;
                    } else if beast.id == BeastId::Fenrir {
                        fenrir_count += 1;
                    } else if beast.id == BeastId::Jaguar {
                        jaguar_count += 1;
                    } else if beast.id == BeastId::Satori {
                        satori_count += 1;
                    } else if beast.id == BeastId::DireWolf {
                        direwolf_count += 1;
                    } else if beast.id == BeastId::Bear {
                        bear_count += 1;
                    } else if beast.id == BeastId::Wolf {
                        wolf_count += 1;
                    } else if beast.id == BeastId::Mantis {
                        mantis_count += 1;
                    } else if beast.id == BeastId::Spider {
                        spider_count += 1;
                    } else if beast.id == BeastId::Rat {
                        rat_count += 1;
                    } else if beast.id == BeastId::Kraken {
                        kraken_count += 1;
                    } else if beast.id == BeastId::Colossus {
                        colossus_count += 1;
                    } else if beast.id == BeastId::Balrog {
                        balrog_count += 1;
                    } else if beast.id == BeastId::Leviathan {
                        leviathan_count += 1;
                    } else if beast.id == BeastId::Tarrasque {
                        tarrasque_count += 1;
                    } else if beast.id == BeastId::Titan {
                        titan_count += 1;
                    } else if beast.id == BeastId::Nephilim {
                        nephilim_count += 1;
                    } else if beast.id == BeastId::Behemoth {
                        behemoth_count += 1;
                    } else if beast.id == BeastId::Hydra {
                        hydra_count += 1;
                    } else if beast.id == BeastId::Juggernaut {
                        juggernaut_count += 1;
                    } else if beast.id == BeastId::Oni {
                        oni_count += 1;
                    } else if beast.id == BeastId::Jotunn {
                        jotunn_count += 1;
                    } else if beast.id == BeastId::Ettin {
                        ettin_count += 1;
                    } else if beast.id == BeastId::Cyclops {
                        cyclops_count += 1;
                    } else if beast.id == BeastId::Giant {
                        giant_count += 1;
                    } else if beast.id == BeastId::NemeanLion {
                        nemean_lion_count += 1;
                    } else if beast.id == BeastId::Berserker {
                        berserker_count += 1;
                    } else if beast.id == BeastId::Yeti {
                        yeti_count += 1;
                    } else if beast.id == BeastId::Golem {
                        golem_count += 1;
                    } else if beast.id == BeastId::Ent {
                        ent_count += 1;
                    } else if beast.id == BeastId::Troll {
                        troll_count += 1;
                    } else if beast.id == BeastId::Bigfoot {
                        bigfoot_count += 1;
                    } else if beast.id == BeastId::Ogre {
                        ogre_count += 1;
                    } else if beast.id == BeastId::Orc {
                        orc_count += 1;
                    } else if beast.id == BeastId::Skeleton {
                        skeleton_count += 1;
                    }
                },
                ExploreResult::Obstacle(()) => {},
                ExploreResult::Discovery(()) => {}
            }

            xp += 1;
        };

        // assert beasts distributions are reasonably uniform
        let warlock_percentage = (warlock_count * 1000) / total_beasts;
        assert(warlock_percentage >= 7 && warlock_percentage <= 21, 'warlock distribution');

        let typhon_percentage = (typhon_count * 1000) / total_beasts;
        assert(typhon_percentage >= 7 && typhon_percentage <= 21, 'typhon distribution');

        let jiangshi_percentage = (jiangshi_count * 1000) / total_beasts;
        assert(jiangshi_percentage >= 7 && jiangshi_percentage <= 21, 'jiangshi distribution');

        let anansi_percentage = (anansi_count * 1000) / total_beasts;
        assert(anansi_percentage >= 7 && anansi_percentage <= 21, 'anansi distribution');

        let basilisk_percentage = (basilisk_count * 1000) / total_beasts;
        assert(basilisk_percentage >= 7 && basilisk_percentage <= 21, 'basilisk distribution');

        let gorgon_percentage = (gorgon_count * 1000) / total_beasts;
        assert(gorgon_percentage >= 7 && gorgon_percentage <= 21, 'gorgon distribution');

        let kitsune_percentage = (kitsune_count * 1000) / total_beasts;
        assert(kitsune_percentage >= 7 && kitsune_percentage <= 21, 'kitsune distribution');

        let lich_percentage = (lich_count * 1000) / total_beasts;
        assert(lich_percentage >= 7 && lich_percentage <= 21, 'lich distribution');

        let chimera_percentage = (chimera_count * 1000) / total_beasts;
        assert(chimera_percentage >= 7 && chimera_percentage <= 21, 'chimera distribution');

        let wendigo_percentage = (wendigo_count * 1000) / total_beasts;
        assert(wendigo_percentage >= 7 && wendigo_percentage <= 21, 'wendigo distribution');

        let raksasa_percentage = (raksasa_count * 1000) / total_beasts;
        assert(raksasa_percentage >= 7 && raksasa_percentage <= 21, 'raksasa distribution');

        let werewolf_percentage = (werewolf_count * 1000) / total_beasts;
        assert(werewolf_percentage >= 7 && werewolf_percentage <= 21, 'werewolf distribution');

        let banshee_percentage = (banshee_count * 1000) / total_beasts;
        assert(banshee_percentage >= 7 && banshee_percentage <= 21, 'banshee distribution');

        let draugr_percentage = (draugr_count * 1000) / total_beasts;
        assert(draugr_percentage >= 7 && draugr_percentage <= 21, 'draugr distribution');

        let vampire_percentage = (vampire_count * 1000) / total_beasts;
        assert(vampire_percentage >= 7 && vampire_percentage <= 21, 'vampire distribution');

        let goblin_percentage = (goblin_count * 1000) / total_beasts;
        assert(goblin_percentage >= 7 && goblin_percentage <= 21, 'goblin distribution');

        let ghoul_percentage = (ghoul_count * 1000) / total_beasts;
        assert(ghoul_percentage >= 7 && ghoul_percentage <= 21, 'ghoul distribution');

        let wraith_percentage = (wraith_count * 1000) / total_beasts;
        assert(wraith_percentage >= 7 && wraith_percentage <= 21, 'wraith distribution');

        let sprite_percentage = (sprite_count * 1000) / total_beasts;
        assert(sprite_percentage >= 7 && sprite_percentage <= 21, 'sprite distribution');

        let kappa_percentage = (kappa_count * 1000) / total_beasts;
        assert(kappa_percentage >= 7 && kappa_percentage <= 21, 'kappa distribution');

        let fairy_percentage = (fairy_count * 1000) / total_beasts;
        assert(fairy_percentage >= 7 && fairy_percentage <= 21, 'fairy distribution');

        let leprechaun_percentage = (leprechaun_count * 1000) / total_beasts;
        assert(
            leprechaun_percentage >= 7 && leprechaun_percentage <= 21, 'leprechaun distribution'
        );

        let kelpie_percentage = (kelpie_count * 1000) / total_beasts;
        assert(kelpie_percentage >= 7 && kelpie_percentage <= 21, 'kelpie distribution');

        let pixie_percentage = (pixie_count * 1000) / total_beasts;
        assert(pixie_percentage >= 7 && pixie_percentage <= 21, 'pixie distribution');

        let gnome_percentage = (gnome_count * 1000) / total_beasts;
        assert(gnome_percentage >= 7 && gnome_percentage <= 21, 'gnome distribution');

        let griffin_percentage = (griffin_count * 1000) / total_beasts;
        assert(griffin_percentage >= 7 && griffin_percentage <= 21, 'griffin distribution');

        let manticore_percentage = (manticore_count * 1000) / total_beasts;
        assert(manticore_percentage >= 7 && manticore_percentage <= 21, 'manticore distribution');

        let phoenix_percentage = (phoenix_count * 1000) / total_beasts;
        assert(phoenix_percentage >= 7 && phoenix_percentage <= 21, 'phoenix distribution');

        let dragon_percentage = (dragon_count * 1000) / total_beasts;
        assert(dragon_percentage >= 7 && dragon_percentage <= 21, 'dragon distribution');

        let minotaur_percentage = (minotaur_count * 1000) / total_beasts;
        assert(minotaur_percentage >= 7 && minotaur_percentage <= 21, 'minotaur distribution');

        let qilin_percentage = (qilin_count * 1000) / total_beasts;
        assert(qilin_percentage >= 7 && qilin_percentage <= 21, 'qilin distribution');

        let ammit_percentage = (ammit_count * 1000) / total_beasts;
        assert(ammit_percentage >= 7 && ammit_percentage <= 21, 'ammit distribution');

        let nue_percentage = (nue_count * 1000) / total_beasts;
        assert(nue_percentage >= 7 && nue_percentage <= 21, 'nue distribution');

        let skinwalker_percentage = (skinwalker_count * 1000) / total_beasts;
        assert(
            skinwalker_percentage >= 7 && skinwalker_percentage <= 21, 'skinwalker distribution'
        );

        let chupacabra_percentage = (chupacabra_count * 1000) / total_beasts;
        assert(
            chupacabra_percentage >= 7 && chupacabra_percentage <= 21, 'chupacabra distribution'
        );

        let weretiger_percentage = (weretiger_count * 1000) / total_beasts;
        assert(weretiger_percentage >= 7 && weretiger_percentage <= 21, 'weretiger distribution');

        let wyvern_percentage = (wyvern_count * 1000) / total_beasts;
        assert(wyvern_percentage >= 7 && wyvern_percentage <= 21, 'wyvern distribution');

        let roc_percentage = (roc_count * 1000) / total_beasts;
        assert(roc_percentage >= 7 && roc_percentage <= 21, 'roc distribution');

        let harpy_percentage = (harpy_count * 1000) / total_beasts;
        assert(harpy_percentage >= 7 && harpy_percentage <= 21, 'harpy distribution');

        let pegasus_percentage = (pegasus_count * 1000) / total_beasts;
        assert(pegasus_percentage >= 7 && pegasus_percentage <= 21, 'pegasus distribution');

        let hippogriff_percentage = (hippogriff_count * 1000) / total_beasts;
        assert(
            hippogriff_percentage >= 7 && hippogriff_percentage <= 21, 'hippogriff distribution'
        );

        let fenrir_percentage = (fenrir_count * 1000) / total_beasts;
        assert(fenrir_percentage >= 7 && fenrir_percentage <= 21, 'fenrir distribution');

        let jaguar_percentage = (jaguar_count * 1000) / total_beasts;
        assert(jaguar_percentage >= 7 && jaguar_percentage <= 21, 'jaguar distribution');

        let satori_percentage = (satori_count * 1000) / total_beasts;
        assert(satori_percentage >= 7 && satori_percentage <= 21, 'satori distribution');

        let direwolf_percentage = (direwolf_count * 1000) / total_beasts;
        assert(direwolf_percentage >= 7 && direwolf_percentage <= 21, 'direwolf distribution');

        let bear_percentage = (bear_count * 1000) / total_beasts;
        assert(bear_percentage >= 7 && bear_percentage <= 21, 'bear distribution');

        let wolf_percentage = (wolf_count * 1000) / total_beasts;
        assert(wolf_percentage >= 7 && wolf_percentage <= 21, 'wolf distribution');

        let mantis_percentage = (mantis_count * 1000) / total_beasts;
        assert(mantis_percentage >= 7 && mantis_percentage <= 21, 'mantis distribution');

        let spider_percentage = (spider_count * 1000) / total_beasts;
        assert(spider_percentage >= 7 && spider_percentage <= 21, 'spider distribution');

        let rat_percentage = (rat_count * 1000) / total_beasts;
        assert(rat_percentage >= 7 && rat_percentage <= 21, 'rat distribution');

        let kraken_percentage = (kraken_count * 1000) / total_beasts;
        assert(kraken_percentage >= 7 && kraken_percentage <= 21, 'kraken distribution');

        let colossus_percentage = (colossus_count * 1000) / total_beasts;
        assert(colossus_percentage >= 7 && colossus_percentage <= 21, 'colossus distribution');

        let balrog_percentage = (balrog_count * 1000) / total_beasts;
        assert(balrog_percentage >= 7 && balrog_percentage <= 21, 'balrog distribution');

        let leviathan_percentage = (leviathan_count * 1000) / total_beasts;
        assert(leviathan_percentage >= 7 && leviathan_percentage <= 21, 'leviathan distribution');

        let tarrasque_percentage = (tarrasque_count * 1000) / total_beasts;
        assert(tarrasque_percentage >= 7 && tarrasque_percentage <= 21, 'tarrasque distribution');

        let titan_percentage = (titan_count * 1000) / total_beasts;
        assert(titan_percentage >= 7 && titan_percentage <= 21, 'titan distribution');

        let nephilim_percentage = (nephilim_count * 1000) / total_beasts;
        assert(nephilim_percentage >= 7 && nephilim_percentage <= 21, 'nephilim distribution');

        let behemoth_percentage = (behemoth_count * 1000) / total_beasts;
        assert(behemoth_percentage >= 7 && behemoth_percentage <= 21, 'behemoth distribution');

        let hydra_percentage = (hydra_count * 1000) / total_beasts;
        assert(hydra_percentage >= 7 && hydra_percentage <= 21, 'hydra distribution');

        let juggernaut_percentage = (juggernaut_count * 1000) / total_beasts;
        assert(
            juggernaut_percentage >= 7 && juggernaut_percentage <= 21, 'juggernaut distribution'
        );

        let oni_percentage = (oni_count * 1000) / total_beasts;
        assert(oni_percentage >= 7 && oni_percentage <= 21, 'oni distribution');

        let jotunn_percentage = (jotunn_count * 1000) / total_beasts;
        assert(jotunn_percentage >= 7 && jotunn_percentage <= 21, 'jotunn distribution');

        let ettin_percentage = (ettin_count * 1000) / total_beasts;
        assert(ettin_percentage >= 7 && ettin_percentage <= 21, 'ettin distribution');

        let cyclops_percentage = (cyclops_count * 1000) / total_beasts;
        assert(cyclops_percentage >= 7 && cyclops_percentage <= 21, 'cyclops distribution');

        let giant_percentage = (giant_count * 1000) / total_beasts;
        assert(giant_percentage >= 7 && giant_percentage <= 21, 'giant distribution');

        let nemean_lion_percentage = (nemean_lion_count * 1000) / total_beasts;
        assert(
            nemean_lion_percentage >= 7 && nemean_lion_percentage <= 21, 'nemean_lion distribution'
        );

        let berserker_percentage = (berserker_count * 1000) / total_beasts;
        assert(berserker_percentage >= 7 && berserker_percentage <= 21, 'berserker distribution');

        let yeti_percentage = (yeti_count * 1000) / total_beasts;
        assert(yeti_percentage >= 7 && yeti_percentage <= 21, 'yeti distribution');

        let golem_percentage = (golem_count * 1000) / total_beasts;
        assert(golem_percentage >= 7 && golem_percentage <= 21, 'golem distribution');

        let ent_percentage = (ent_count * 1000) / total_beasts;
        assert(ent_percentage >= 7 && ent_percentage <= 21, 'ent distribution');

        let troll_percentage = (troll_count * 1000) / total_beasts;
        assert(troll_percentage >= 7 && troll_percentage <= 21, 'troll distribution');

        let bigfoot_percentage = (bigfoot_count * 1000) / total_beasts;
        assert(bigfoot_percentage >= 7 && bigfoot_percentage <= 21, 'bigfoot distribution');

        let ogre_percentage = (ogre_count * 1000) / total_beasts;
        assert(ogre_percentage >= 7 && ogre_percentage <= 21, 'ogre distribution');

        let orc_percentage = (orc_count * 1000) / total_beasts;
        assert(orc_percentage >= 7 && orc_percentage <= 21, 'orc distribution');

        let skeleton_percentage = (skeleton_count * 1000) / total_beasts;
        assert(skeleton_percentage >= 7 && skeleton_percentage <= 21, 'skeleton distribution');
    }

    #[test]
    fn test_get_beast_distribution_fixed_xp() {
        let mut warlock_count: u32 = 0;
        let mut typhon_count: u32 = 0;
        let mut jiangshi_count: u32 = 0;
        let mut anansi_count: u32 = 0;
        let mut basilisk_count: u32 = 0;
        let mut gorgon_count: u32 = 0;
        let mut kitsune_count: u32 = 0;
        let mut lich_count: u32 = 0;
        let mut chimera_count: u32 = 0;
        let mut wendigo_count: u32 = 0;
        let mut raksasa_count: u32 = 0;
        let mut werewolf_count: u32 = 0;
        let mut banshee_count: u32 = 0;
        let mut draugr_count: u32 = 0;
        let mut vampire_count: u32 = 0;
        let mut goblin_count: u32 = 0;
        let mut ghoul_count: u32 = 0;
        let mut wraith_count: u32 = 0;
        let mut sprite_count: u32 = 0;
        let mut kappa_count: u32 = 0;
        let mut fairy_count: u32 = 0;
        let mut leprechaun_count: u32 = 0;
        let mut kelpie_count: u32 = 0;
        let mut pixie_count: u32 = 0;
        let mut gnome_count: u32 = 0;
        let mut griffin_count: u32 = 0;
        let mut manticore_count: u32 = 0;
        let mut phoenix_count: u32 = 0;
        let mut dragon_count: u32 = 0;
        let mut minotaur_count: u32 = 0;
        let mut qilin_count: u32 = 0;
        let mut ammit_count: u32 = 0;
        let mut nue_count: u32 = 0;
        let mut skinwalker_count: u32 = 0;
        let mut chupacabra_count: u32 = 0;
        let mut weretiger_count: u32 = 0;
        let mut wyvern_count: u32 = 0;
        let mut roc_count: u32 = 0;
        let mut harpy_count: u32 = 0;
        let mut pegasus_count: u32 = 0;
        let mut hippogriff_count: u32 = 0;
        let mut fenrir_count: u32 = 0;
        let mut jaguar_count: u32 = 0;
        let mut satori_count: u32 = 0;
        let mut direwolf_count: u32 = 0;
        let mut bear_count: u32 = 0;
        let mut wolf_count: u32 = 0;
        let mut mantis_count: u32 = 0;
        let mut spider_count: u32 = 0;
        let mut rat_count: u32 = 0;
        let mut kraken_count: u32 = 0;
        let mut colossus_count: u32 = 0;
        let mut balrog_count: u32 = 0;
        let mut leviathan_count: u32 = 0;
        let mut tarrasque_count: u32 = 0;
        let mut titan_count: u32 = 0;
        let mut nephilim_count: u32 = 0;
        let mut behemoth_count: u32 = 0;
        let mut hydra_count: u32 = 0;
        let mut juggernaut_count: u32 = 0;
        let mut oni_count: u32 = 0;
        let mut jotunn_count: u32 = 0;
        let mut ettin_count: u32 = 0;
        let mut cyclops_count: u32 = 0;
        let mut giant_count: u32 = 0;
        let mut nemean_lion_count: u32 = 0;
        let mut berserker_count: u32 = 0;
        let mut yeti_count: u32 = 0;
        let mut golem_count: u32 = 0;
        let mut ent_count: u32 = 0;
        let mut troll_count: u32 = 0;
        let mut bigfoot_count: u32 = 0;
        let mut ogre_count: u32 = 0;
        let mut orc_count: u32 = 0;
        let mut skeleton_count: u32 = 0;
        let mut total_beasts = 0;

        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        adventurer.xp = 200;

        let mut adventurer_entropy: felt252 = 1;
        loop {
            if adventurer_entropy == 7500 {
                break;
            }
            let (r, _) = AdventurerUtils::get_randomness(adventurer.xp, adventurer_entropy);

            match AdventurerUtils::get_random_explore(r) {
                ExploreResult::Beast(()) => {
                    total_beasts += 1;
                    let (beast, _seed) = adventurer.get_beast(1, adventurer_entropy);
                    if beast.id == BeastId::Warlock {
                        warlock_count += 1;
                    } else if beast.id == BeastId::Typhon {
                        typhon_count += 1;
                    } else if beast.id == BeastId::Jiangshi {
                        jiangshi_count += 1;
                    } else if beast.id == BeastId::Anansi {
                        anansi_count += 1;
                    } else if beast.id == BeastId::Basilisk {
                        basilisk_count += 1;
                    } else if beast.id == BeastId::Gorgon {
                        gorgon_count += 1;
                    } else if beast.id == BeastId::Kitsune {
                        kitsune_count += 1;
                    } else if beast.id == BeastId::Lich {
                        lich_count += 1;
                    } else if beast.id == BeastId::Chimera {
                        chimera_count += 1;
                    } else if beast.id == BeastId::Wendigo {
                        wendigo_count += 1;
                    } else if beast.id == BeastId::Rakshasa {
                        raksasa_count += 1;
                    } else if beast.id == BeastId::Werewolf {
                        werewolf_count += 1;
                    } else if beast.id == BeastId::Banshee {
                        banshee_count += 1;
                    } else if beast.id == BeastId::Draugr {
                        draugr_count += 1;
                    } else if beast.id == BeastId::Vampire {
                        vampire_count += 1;
                    } else if beast.id == BeastId::Goblin {
                        goblin_count += 1;
                    } else if beast.id == BeastId::Ghoul {
                        ghoul_count += 1;
                    } else if beast.id == BeastId::Wraith {
                        wraith_count += 1;
                    } else if beast.id == BeastId::Sprite {
                        sprite_count += 1;
                    } else if beast.id == BeastId::Kappa {
                        kappa_count += 1;
                    } else if beast.id == BeastId::Fairy {
                        fairy_count += 1;
                    } else if beast.id == BeastId::Leprechaun {
                        leprechaun_count += 1;
                    } else if beast.id == BeastId::Kelpie {
                        kelpie_count += 1;
                    } else if beast.id == BeastId::Pixie {
                        pixie_count += 1;
                    } else if beast.id == BeastId::Gnome {
                        gnome_count += 1;
                    } else if beast.id == BeastId::Griffin {
                        griffin_count += 1;
                    } else if beast.id == BeastId::Manticore {
                        manticore_count += 1;
                    } else if beast.id == BeastId::Phoenix {
                        phoenix_count += 1;
                    } else if beast.id == BeastId::Dragon {
                        dragon_count += 1;
                    } else if beast.id == BeastId::Minotaur {
                        minotaur_count += 1;
                    } else if beast.id == BeastId::Qilin {
                        qilin_count += 1;
                    } else if beast.id == BeastId::Ammit {
                        ammit_count += 1;
                    } else if beast.id == BeastId::Nue {
                        nue_count += 1;
                    } else if beast.id == BeastId::Skinwalker {
                        skinwalker_count += 1;
                    } else if beast.id == BeastId::Chupacabra {
                        chupacabra_count += 1;
                    } else if beast.id == BeastId::Weretiger {
                        weretiger_count += 1;
                    } else if beast.id == BeastId::Wyvern {
                        wyvern_count += 1;
                    } else if beast.id == BeastId::Roc {
                        roc_count += 1;
                    } else if beast.id == BeastId::Harpy {
                        harpy_count += 1;
                    } else if beast.id == BeastId::Pegasus {
                        pegasus_count += 1;
                    } else if beast.id == BeastId::Hippogriff {
                        hippogriff_count += 1;
                    } else if beast.id == BeastId::Fenrir {
                        fenrir_count += 1;
                    } else if beast.id == BeastId::Jaguar {
                        jaguar_count += 1;
                    } else if beast.id == BeastId::Satori {
                        satori_count += 1;
                    } else if beast.id == BeastId::DireWolf {
                        direwolf_count += 1;
                    } else if beast.id == BeastId::Bear {
                        bear_count += 1;
                    } else if beast.id == BeastId::Wolf {
                        wolf_count += 1;
                    } else if beast.id == BeastId::Mantis {
                        mantis_count += 1;
                    } else if beast.id == BeastId::Spider {
                        spider_count += 1;
                    } else if beast.id == BeastId::Rat {
                        rat_count += 1;
                    } else if beast.id == BeastId::Kraken {
                        kraken_count += 1;
                    } else if beast.id == BeastId::Colossus {
                        colossus_count += 1;
                    } else if beast.id == BeastId::Balrog {
                        balrog_count += 1;
                    } else if beast.id == BeastId::Leviathan {
                        leviathan_count += 1;
                    } else if beast.id == BeastId::Tarrasque {
                        tarrasque_count += 1;
                    } else if beast.id == BeastId::Titan {
                        titan_count += 1;
                    } else if beast.id == BeastId::Nephilim {
                        nephilim_count += 1;
                    } else if beast.id == BeastId::Behemoth {
                        behemoth_count += 1;
                    } else if beast.id == BeastId::Hydra {
                        hydra_count += 1;
                    } else if beast.id == BeastId::Juggernaut {
                        juggernaut_count += 1;
                    } else if beast.id == BeastId::Oni {
                        oni_count += 1;
                    } else if beast.id == BeastId::Jotunn {
                        jotunn_count += 1;
                    } else if beast.id == BeastId::Ettin {
                        ettin_count += 1;
                    } else if beast.id == BeastId::Cyclops {
                        cyclops_count += 1;
                    } else if beast.id == BeastId::Giant {
                        giant_count += 1;
                    } else if beast.id == BeastId::NemeanLion {
                        nemean_lion_count += 1;
                    } else if beast.id == BeastId::Berserker {
                        berserker_count += 1;
                    } else if beast.id == BeastId::Yeti {
                        yeti_count += 1;
                    } else if beast.id == BeastId::Golem {
                        golem_count += 1;
                    } else if beast.id == BeastId::Ent {
                        ent_count += 1;
                    } else if beast.id == BeastId::Troll {
                        troll_count += 1;
                    } else if beast.id == BeastId::Bigfoot {
                        bigfoot_count += 1;
                    } else if beast.id == BeastId::Ogre {
                        ogre_count += 1;
                    } else if beast.id == BeastId::Orc {
                        orc_count += 1;
                    } else if beast.id == BeastId::Skeleton {
                        skeleton_count += 1;
                    }
                },
                ExploreResult::Obstacle(()) => {},
                ExploreResult::Discovery(()) => {}
            }

            adventurer_entropy += 1;
        };

        // assert beasts distributions are reasonably uniform
        let warlock_percentage = (warlock_count * 1000) / total_beasts;
        assert(warlock_percentage >= 7 && warlock_percentage <= 21, 'warlock distribution');

        let typhon_percentage = (typhon_count * 1000) / total_beasts;
        assert(typhon_percentage >= 7 && typhon_percentage <= 21, 'typhon distribution');

        let jiangshi_percentage = (jiangshi_count * 1000) / total_beasts;
        assert(jiangshi_percentage >= 7 && jiangshi_percentage <= 21, 'jiangshi distribution');

        let anansi_percentage = (anansi_count * 1000) / total_beasts;
        assert(anansi_percentage >= 7 && anansi_percentage <= 21, 'anansi distribution');

        let basilisk_percentage = (basilisk_count * 1000) / total_beasts;
        assert(basilisk_percentage >= 7 && basilisk_percentage <= 21, 'basilisk distribution');

        let gorgon_percentage = (gorgon_count * 1000) / total_beasts;
        assert(gorgon_percentage >= 7 && gorgon_percentage <= 21, 'gorgon distribution');

        let kitsune_percentage = (kitsune_count * 1000) / total_beasts;
        assert(kitsune_percentage >= 7 && kitsune_percentage <= 21, 'kitsune distribution');

        let lich_percentage = (lich_count * 1000) / total_beasts;
        assert(lich_percentage >= 7 && lich_percentage <= 21, 'lich distribution');

        let chimera_percentage = (chimera_count * 1000) / total_beasts;
        assert(chimera_percentage >= 7 && chimera_percentage <= 21, 'chimera distribution');

        let wendigo_percentage = (wendigo_count * 1000) / total_beasts;
        assert(wendigo_percentage >= 7 && wendigo_percentage <= 21, 'wendigo distribution');

        let raksasa_percentage = (raksasa_count * 1000) / total_beasts;
        assert(raksasa_percentage >= 7 && raksasa_percentage <= 21, 'raksasa distribution');

        let werewolf_percentage = (werewolf_count * 1000) / total_beasts;
        assert(werewolf_percentage >= 7 && werewolf_percentage <= 21, 'werewolf distribution');

        let banshee_percentage = (banshee_count * 1000) / total_beasts;
        assert(banshee_percentage >= 7 && banshee_percentage <= 21, 'banshee distribution');

        let draugr_percentage = (draugr_count * 1000) / total_beasts;
        assert(draugr_percentage >= 7 && draugr_percentage <= 21, 'draugr distribution');

        let vampire_percentage = (vampire_count * 1000) / total_beasts;
        assert(vampire_percentage >= 7 && vampire_percentage <= 21, 'vampire distribution');

        let goblin_percentage = (goblin_count * 1000) / total_beasts;
        assert(goblin_percentage >= 7 && goblin_percentage <= 21, 'goblin distribution');

        let ghoul_percentage = (ghoul_count * 1000) / total_beasts;
        assert(ghoul_percentage >= 7 && ghoul_percentage <= 21, 'ghoul distribution');

        let wraith_percentage = (wraith_count * 1000) / total_beasts;
        assert(wraith_percentage >= 7 && wraith_percentage <= 21, 'wraith distribution');

        let sprite_percentage = (sprite_count * 1000) / total_beasts;
        assert(sprite_percentage >= 7 && sprite_percentage <= 21, 'sprite distribution');

        let kappa_percentage = (kappa_count * 1000) / total_beasts;
        assert(kappa_percentage >= 7 && kappa_percentage <= 21, 'kappa distribution');

        let fairy_percentage = (fairy_count * 1000) / total_beasts;
        assert(fairy_percentage >= 7 && fairy_percentage <= 21, 'fairy distribution');

        let leprechaun_percentage = (leprechaun_count * 1000) / total_beasts;
        assert(
            leprechaun_percentage >= 7 && leprechaun_percentage <= 21, 'leprechaun distribution'
        );

        let kelpie_percentage = (kelpie_count * 1000) / total_beasts;
        assert(kelpie_percentage >= 7 && kelpie_percentage <= 21, 'kelpie distribution');

        let pixie_percentage = (pixie_count * 1000) / total_beasts;
        assert(pixie_percentage >= 7 && pixie_percentage <= 21, 'pixie distribution');

        let gnome_percentage = (gnome_count * 1000) / total_beasts;
        assert(gnome_percentage >= 7 && gnome_percentage <= 21, 'gnome distribution');

        let griffin_percentage = (griffin_count * 1000) / total_beasts;
        assert(griffin_percentage >= 7 && griffin_percentage <= 21, 'griffin distribution');

        let manticore_percentage = (manticore_count * 1000) / total_beasts;
        assert(manticore_percentage >= 7 && manticore_percentage <= 21, 'manticore distribution');

        let phoenix_percentage = (phoenix_count * 1000) / total_beasts;
        assert(phoenix_percentage >= 7 && phoenix_percentage <= 21, 'phoenix distribution');

        let dragon_percentage = (dragon_count * 1000) / total_beasts;
        assert(dragon_percentage >= 7 && dragon_percentage <= 21, 'dragon distribution');

        let minotaur_percentage = (minotaur_count * 1000) / total_beasts;
        assert(minotaur_percentage >= 7 && minotaur_percentage <= 21, 'minotaur distribution');

        let qilin_percentage = (qilin_count * 1000) / total_beasts;
        assert(qilin_percentage >= 7 && qilin_percentage <= 21, 'qilin distribution');

        let ammit_percentage = (ammit_count * 1000) / total_beasts;
        assert(ammit_percentage >= 7 && ammit_percentage <= 21, 'ammit distribution');

        let nue_percentage = (nue_count * 1000) / total_beasts;
        assert(nue_percentage >= 7 && nue_percentage <= 21, 'nue distribution');

        let skinwalker_percentage = (skinwalker_count * 1000) / total_beasts;
        assert(
            skinwalker_percentage >= 7 && skinwalker_percentage <= 21, 'skinwalker distribution'
        );

        let chupacabra_percentage = (chupacabra_count * 1000) / total_beasts;
        assert(
            chupacabra_percentage >= 7 && chupacabra_percentage <= 21, 'chupacabra distribution'
        );

        let weretiger_percentage = (weretiger_count * 1000) / total_beasts;
        assert(weretiger_percentage >= 7 && weretiger_percentage <= 21, 'weretiger distribution');

        let wyvern_percentage = (wyvern_count * 1000) / total_beasts;
        assert(wyvern_percentage >= 7 && wyvern_percentage <= 21, 'wyvern distribution');

        let roc_percentage = (roc_count * 1000) / total_beasts;
        assert(roc_percentage >= 7 && roc_percentage <= 21, 'roc distribution');

        let harpy_percentage = (harpy_count * 1000) / total_beasts;
        assert(harpy_percentage >= 7 && harpy_percentage <= 21, 'harpy distribution');

        let pegasus_percentage = (pegasus_count * 1000) / total_beasts;
        assert(pegasus_percentage >= 7 && pegasus_percentage <= 21, 'pegasus distribution');

        let hippogriff_percentage = (hippogriff_count * 1000) / total_beasts;
        assert(
            hippogriff_percentage >= 7 && hippogriff_percentage <= 21, 'hippogriff distribution'
        );

        let fenrir_percentage = (fenrir_count * 1000) / total_beasts;
        assert(fenrir_percentage >= 7 && fenrir_percentage <= 21, 'fenrir distribution');

        let jaguar_percentage = (jaguar_count * 1000) / total_beasts;
        assert(jaguar_percentage >= 7 && jaguar_percentage <= 21, 'jaguar distribution');

        let satori_percentage = (satori_count * 1000) / total_beasts;
        assert(satori_percentage >= 7 && satori_percentage <= 21, 'satori distribution');

        let direwolf_percentage = (direwolf_count * 1000) / total_beasts;
        assert(direwolf_percentage >= 7 && direwolf_percentage <= 21, 'direwolf distribution');

        let bear_percentage = (bear_count * 1000) / total_beasts;
        assert(bear_percentage >= 7 && bear_percentage <= 21, 'bear distribution');

        let wolf_percentage = (wolf_count * 1000) / total_beasts;
        assert(wolf_percentage >= 7 && wolf_percentage <= 21, 'wolf distribution');

        let mantis_percentage = (mantis_count * 1000) / total_beasts;
        assert(mantis_percentage >= 7 && mantis_percentage <= 21, 'mantis distribution');

        let spider_percentage = (spider_count * 1000) / total_beasts;
        assert(spider_percentage >= 7 && spider_percentage <= 21, 'spider distribution');

        let rat_percentage = (rat_count * 1000) / total_beasts;
        assert(rat_percentage >= 7 && rat_percentage <= 21, 'rat distribution');

        let kraken_percentage = (kraken_count * 1000) / total_beasts;
        assert(kraken_percentage >= 7 && kraken_percentage <= 21, 'kraken distribution');

        let colossus_percentage = (colossus_count * 1000) / total_beasts;
        assert(colossus_percentage >= 7 && colossus_percentage <= 21, 'colossus distribution');

        let balrog_percentage = (balrog_count * 1000) / total_beasts;
        assert(balrog_percentage >= 7 && balrog_percentage <= 21, 'balrog distribution');

        let leviathan_percentage = (leviathan_count * 1000) / total_beasts;
        assert(leviathan_percentage >= 7 && leviathan_percentage <= 21, 'leviathan distribution');

        let tarrasque_percentage = (tarrasque_count * 1000) / total_beasts;
        assert(tarrasque_percentage >= 7 && tarrasque_percentage <= 21, 'tarrasque distribution');

        let titan_percentage = (titan_count * 1000) / total_beasts;
        assert(titan_percentage >= 7 && titan_percentage <= 21, 'titan distribution');

        let nephilim_percentage = (nephilim_count * 1000) / total_beasts;
        assert(nephilim_percentage >= 7 && nephilim_percentage <= 21, 'nephilim distribution');

        let behemoth_percentage = (behemoth_count * 1000) / total_beasts;
        assert(behemoth_percentage >= 7 && behemoth_percentage <= 21, 'behemoth distribution');

        let hydra_percentage = (hydra_count * 1000) / total_beasts;
        assert(hydra_percentage >= 7 && hydra_percentage <= 21, 'hydra distribution');

        let juggernaut_percentage = (juggernaut_count * 1000) / total_beasts;
        assert(
            juggernaut_percentage >= 7 && juggernaut_percentage <= 21, 'juggernaut distribution'
        );

        let oni_percentage = (oni_count * 1000) / total_beasts;
        assert(oni_percentage >= 7 && oni_percentage <= 21, 'oni distribution');

        let jotunn_percentage = (jotunn_count * 1000) / total_beasts;
        assert(jotunn_percentage >= 7 && jotunn_percentage <= 21, 'jotunn distribution');

        let ettin_percentage = (ettin_count * 1000) / total_beasts;
        assert(ettin_percentage >= 7 && ettin_percentage <= 21, 'ettin distribution');

        let cyclops_percentage = (cyclops_count * 1000) / total_beasts;
        assert(cyclops_percentage >= 7 && cyclops_percentage <= 21, 'cyclops distribution');

        let giant_percentage = (giant_count * 1000) / total_beasts;
        assert(giant_percentage >= 7 && giant_percentage <= 21, 'giant distribution');

        let nemean_lion_percentage = (nemean_lion_count * 1000) / total_beasts;
        assert(
            nemean_lion_percentage >= 7 && nemean_lion_percentage <= 21, 'nemean_lion distribution'
        );

        let berserker_percentage = (berserker_count * 1000) / total_beasts;
        assert(berserker_percentage >= 7 && berserker_percentage <= 21, 'berserker distribution');

        let yeti_percentage = (yeti_count * 1000) / total_beasts;
        assert(yeti_percentage >= 7 && yeti_percentage <= 21, 'yeti distribution');

        let golem_percentage = (golem_count * 1000) / total_beasts;
        assert(golem_percentage >= 7 && golem_percentage <= 21, 'golem distribution');

        let ent_percentage = (ent_count * 1000) / total_beasts;
        assert(ent_percentage >= 7 && ent_percentage <= 21, 'ent distribution');

        let troll_percentage = (troll_count * 1000) / total_beasts;
        assert(troll_percentage >= 7 && troll_percentage <= 21, 'troll distribution');

        let bigfoot_percentage = (bigfoot_count * 1000) / total_beasts;
        assert(bigfoot_percentage >= 7 && bigfoot_percentage <= 21, 'bigfoot distribution');

        let ogre_percentage = (ogre_count * 1000) / total_beasts;
        assert(ogre_percentage >= 7 && ogre_percentage <= 21, 'ogre distribution');

        let orc_percentage = (orc_count * 1000) / total_beasts;
        assert(orc_percentage >= 7 && orc_percentage <= 21, 'orc distribution');

        let skeleton_percentage = (skeleton_count * 1000) / total_beasts;
        assert(skeleton_percentage >= 7 && skeleton_percentage <= 21, 'skeleton distribution');
    }

    #[test]
    #[available_gas(254644)]
    fn test_charisma_adjusted_item_price() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);

        // zero case
        let item_price = adventurer.charisma_adjusted_item_price(0);
        assert(item_price == MINIMUM_ITEM_PRICE, 'item should be min price');

        // above minimum price, no charisma (base case)
        let item_price = adventurer.charisma_adjusted_item_price(10);
        assert(item_price == 10, 'price should not change');

        // above minimum price, 1 charisma (base case)
        adventurer.stats.charisma = 1;
        let item_price = adventurer.charisma_adjusted_item_price(10);
        assert(item_price == 10 - CHARISMA_ITEM_DISCOUNT, 'price should not change');

        // underflow case
        adventurer.stats.charisma = 31;
        let item_price = adventurer.charisma_adjusted_item_price(15);
        assert(item_price == MINIMUM_ITEM_PRICE, 'price should be minimum');
    }

    #[test]
    #[available_gas(289254)]
    fn test_charisma_adjusted_potion_price() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);

        // default case (no charisma discount)
        let potion_price = adventurer.charisma_adjusted_potion_price();
        assert(potion_price == POTION_PRICE, 'potion should be base price');

        // advance adventurer to level 2 (potion cost should double)
        adventurer.xp = 4;
        let potion_price = adventurer.charisma_adjusted_potion_price();
        assert(potion_price == POTION_PRICE * 2, 'potion should cost double base');

        // give adventurer 1 charisma (potion cost should go back to base price)
        adventurer.stats.charisma = 1;
        let potion_price = adventurer.charisma_adjusted_potion_price();
        assert(potion_price == POTION_PRICE, 'potion should be base price');

        // give adventurer 2 charisma which would result in a 0 cost potion
        // but since potion cost cannot be 0, it should be minimum price
        adventurer.stats.charisma = 2;
        let potion_price = adventurer.charisma_adjusted_potion_price();
        assert(potion_price == MINIMUM_POTION_PRICE, 'potion should be minimum price');

        // give adventurer 31 charisma which would result in an underflow
        adventurer.stats.charisma = 31;
        let potion_price = adventurer.charisma_adjusted_potion_price();
        assert(potion_price == MINIMUM_POTION_PRICE, 'potion should be minimum price');
    }

    #[test]
    #[should_panic(expected: ('health overflow',))]
    #[available_gas(3000000)]
    fn test_pack_protection_overflow_health() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        adventurer.health = MAX_ADVENTURER_HEALTH + 1;
        AdventurerPacking::pack(adventurer);
    }

    #[test]
    #[should_panic(expected: ('gold overflow',))]
    #[available_gas(3000000)]
    fn test_pack_protection_overflow_gold() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        adventurer.gold = MAX_GOLD + 1;
        AdventurerPacking::pack(adventurer);
    }

    #[test]
    #[should_panic(expected: ('xp overflow',))]
    #[available_gas(3000000)]
    fn test_pack_protection_overflow_xp() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        adventurer.xp = MAX_ADVENTURER_XP + 1;
        AdventurerPacking::pack(adventurer);
    }

    #[test]
    #[should_panic(expected: ('beast health overflow',))]
    #[available_gas(3000000)]
    fn test_pack_protection_overflow_beast_health() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        adventurer.beast_health = MAX_PACKABLE_BEAST_HEALTH + 1;
        AdventurerPacking::pack(adventurer);
    }

    #[test]
    #[should_panic(expected: ('stat upgrades avail overflow',))]
    #[available_gas(3000000)]
    fn test_pack_protection_overflow_stat_points_available() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        adventurer.stat_upgrades_available = MAX_STAT_UPGRADES_AVAILABLE + 1;
        AdventurerPacking::pack(adventurer);
    }

    #[test]
    #[available_gas(2000000)]
    fn test_new_adventurer() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        AdventurerPacking::pack(adventurer);
        assert(adventurer.health == STARTING_HEALTH, 'wrong starting health');
        assert(adventurer.gold == STARTING_GOLD, 'wrong starting gold');
        assert(adventurer.xp == 0, 'wrong starting xp');
    }

    #[test]
    #[available_gas(305064)]
    fn test_increase_health() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);

        // test stock max health is 100
        adventurer.increase_health(5);
        assert(adventurer.health == 100, 'max health with 0 vit is 100');

        // increase max health via vitality boost
        adventurer.stats.vitality = 1;
        adventurer.increase_health(5);
        assert(adventurer.health == 105, 'health should be 105');

        // verify max health is starting health + vitality boost
        adventurer.increase_health(50);
        assert(
            adventurer.health == STARTING_HEALTH + HEALTH_INCREASE_PER_VITALITY.into(),
            'max health error'
        );

        // check overflow
        adventurer.increase_health(65535);
        assert(
            adventurer.health == STARTING_HEALTH + HEALTH_INCREASE_PER_VITALITY.into(),
            'health should be 120'
        );
    }

    #[test]
    #[available_gas(2701164)]
    fn test_increase_gold() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);

        // assert starting state
        assert(adventurer.gold == STARTING_GOLD, 'wrong advntr starting gold');

        // base case
        adventurer.increase_gold(5);
        assert(adventurer.gold == STARTING_GOLD + 5, 'gold should be +5');

        // at max value case
        adventurer.increase_gold(MAX_GOLD);
        assert(adventurer.gold == MAX_GOLD, 'gold should be max');

        // pack and unpack adventurer to test overflow in packing
        let unpacked: Adventurer = AdventurerPacking::unpack(AdventurerPacking::pack(adventurer));
        assert(unpacked.gold == MAX_GOLD, 'should still be max gold');

        // extreme/overflow case
        adventurer.gold = 65535;
        adventurer.increase_gold(65535);
        assert(adventurer.gold == MAX_GOLD, 'gold overflow check');
    }

    #[test]
    #[available_gas(197164)]
    fn test_decrease_health() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        let starting_health = adventurer.health;
        let deduct_amount = 5;

        // base case
        adventurer.decrease_health(deduct_amount);
        assert(adventurer.health == starting_health - deduct_amount, 'wrong health');

        // underflow case
        adventurer.decrease_health(65535);
        assert(adventurer.health == 0, 'health should be 0');
    }

    #[test]
    #[available_gas(197064)]
    fn test_deduct_gold() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        let starting_gold = adventurer.gold;
        let deduct_amount = 5;

        // base case
        adventurer.deduct_gold(deduct_amount);
        assert(adventurer.gold == starting_gold - deduct_amount, 'wrong gold');

        // test underflow
        adventurer.deduct_gold(65535);
        assert(adventurer.gold == 0, 'gold should be 0');
    }

    #[test]
    #[available_gas(339614)]
    fn test_increase_adventurer_xp() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        // base case level increase
        let (previous_level, new_level) = adventurer.increase_adventurer_xp(4);
        assert(adventurer.xp == 4, 'xp should be 4');
        assert(previous_level == 1, 'previous level should be 1');
        assert(new_level == 2, 'new level should be 2');

        // base case no level increase
        let (previous_level, new_level) = adventurer.increase_adventurer_xp(1);
        assert(adventurer.xp == 5, 'xp should be 5');
        assert(previous_level == 2, 'prev level should be 2');
        assert(new_level == 2, 'new level should still be 2');

        // multi-level and exceed max xp case
        let (previous_level, new_level) = adventurer.increase_adventurer_xp(MAX_ADVENTURER_XP + 10);
        assert(adventurer.xp == MAX_ADVENTURER_XP, 'xp should stop at max xp');
        assert(previous_level == 2, 'prev level should be 2');
        assert(new_level == 181, 'new level should be max 181');

        // u16 overflow case
        adventurer.increase_adventurer_xp(65535);
        assert(adventurer.xp == MAX_ADVENTURER_XP, 'xp should be max on overflow');
    }

    #[test]
    #[available_gas(3000000)]
    fn test_increase_stat_upgrades_available() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        let original_stat_points = adventurer.stat_upgrades_available;

        // zero case
        adventurer.increase_stat_upgrades_available(0);
        assert(
            adventurer.stat_upgrades_available == original_stat_points,
            'stat points should not change'
        );

        // base case - adding 1 stat point (no need to pack and unpack this test case)
        adventurer.increase_stat_upgrades_available(1);
        assert(
            adventurer.stat_upgrades_available == 1 + original_stat_points,
            'stat points should be +1'
        );

        // max stat upgrade value case
        adventurer.increase_stat_upgrades_available(MAX_STAT_UPGRADES_AVAILABLE);
        assert(
            adventurer.stat_upgrades_available == MAX_STAT_UPGRADES_AVAILABLE,
            'stat points should be max'
        );

        // pack and unpack at max value to ensure our max values are correct for packing
        let unpacked: Adventurer = AdventurerPacking::unpack(AdventurerPacking::pack(adventurer));
        assert(
            unpacked.stat_upgrades_available == MAX_STAT_UPGRADES_AVAILABLE,
            'stat point should still be max'
        );

        // extreme/overflow case
        adventurer.stat_upgrades_available = 255;
        adventurer.increase_stat_upgrades_available(255);
        assert(
            adventurer.stat_upgrades_available == MAX_STAT_UPGRADES_AVAILABLE,
            'stat points should be max'
        );
    }

    #[test]
    #[available_gas(192164)]
    fn test_increase_strength() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        // basic case
        adventurer.stats.increase_strength(1);
        assert(adventurer.stats.strength == 1, 'strength should be 1');
        // overflow case
        adventurer.stats.increase_strength(255);
        assert(adventurer.stats.strength == MAX_STAT_VALUE, 'strength should be max');
    }

    #[test]
    #[available_gas(192164)]
    fn test_increase_dexterity() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        // basic case
        adventurer.stats.increase_dexterity(1);
        assert(adventurer.stats.dexterity == 1, 'dexterity should be 1');
        // overflow case
        adventurer.stats.increase_dexterity(255);
        assert(adventurer.stats.dexterity == MAX_STAT_VALUE, 'dexterity should be max');
    }

    #[test]
    #[available_gas(192164)]
    fn test_increase_vitality() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        // basic case
        adventurer.stats.increase_vitality(1);
        assert(adventurer.stats.vitality == 1, 'vitality should be 1');
        // overflow case
        adventurer.stats.increase_vitality(255);
        assert(adventurer.stats.vitality == MAX_STAT_VALUE, 'vitality should be max');
    }

    #[test]
    #[available_gas(192164)]
    fn test_increase_intelligence() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        // basic case
        adventurer.stats.increase_intelligence(1);
        assert(adventurer.stats.intelligence == 1, 'intelligence should be 1');
        // overflow case
        adventurer.stats.increase_intelligence(255);
        assert(adventurer.stats.intelligence == MAX_STAT_VALUE, 'intelligence should be max');
    }

    #[test]
    #[available_gas(192164)]
    fn test_increase_wisdom() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        // basic case
        adventurer.stats.increase_wisdom(1);
        assert(adventurer.stats.wisdom == 1, 'wisdom should be 1');
        // overflow case
        adventurer.stats.increase_wisdom(255);
        assert(adventurer.stats.wisdom == MAX_STAT_VALUE, 'wisdom should be max');
    }

    #[test]
    #[available_gas(192164)]
    fn test_increase_charisma() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        // basic case
        adventurer.stats.increase_charisma(1);
        assert(adventurer.stats.charisma == 1, 'charisma should be 1');
        // overflow case
        adventurer.stats.increase_charisma(255);
        assert(adventurer.stats.charisma == MAX_STAT_VALUE, 'charisma should be max');
    }

    #[test]
    #[available_gas(8850)]
    fn test_decrease_strength_gas() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        adventurer.stats.decrease_strength(0);
    }

    #[test]
    fn test_decrease_strength() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        adventurer.stats.increase_strength(2);
        assert(adventurer.stats.strength == 2, 'strength should be 2');
        adventurer.stats.decrease_strength(1);
        assert(adventurer.stats.strength == 1, 'strength should be 1');
    }

    #[test]
    #[should_panic(expected: ('strength underflow',))]
    fn test_decrease_strength_underflow() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        adventurer.stats.increase_strength(5);
        adventurer.stats.decrease_strength(6);
    }

    #[test]
    #[available_gas(8850)]
    fn test_decrease_dexterity_gas() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        adventurer.stats.decrease_dexterity(0);
    }

    #[test]
    fn test_decrease_dexterity() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        adventurer.stats.increase_dexterity(2);
        assert(adventurer.stats.dexterity == 2, 'dexterity should be 2');
        adventurer.stats.decrease_dexterity(1);
        assert(adventurer.stats.dexterity == 1, 'dexterity should be 1');
    }

    #[test]
    #[should_panic(expected: ('dexterity underflow',))]
    fn test_decrease_dexterity_underflow() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        adventurer.stats.increase_dexterity(5);
        adventurer.stats.decrease_dexterity(6);
    }

    #[test]
    #[available_gas(8850)]
    fn test_decrease_vitality_gas() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        adventurer.stats.decrease_vitality(0);
    }

    #[test]
    fn test_decrease_vitality() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        adventurer.stats.increase_vitality(2);
        assert(adventurer.stats.vitality == 2, 'vitality should be 2');
        adventurer.stats.decrease_vitality(1);
        assert(adventurer.stats.vitality == 1, 'vitality should be 1');
    }

    #[test]
    #[should_panic(expected: ('vitality underflow',))]
    fn test_decrease_vitality_underflow() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        adventurer.stats.increase_vitality(5);
        adventurer.stats.decrease_vitality(6);
    }

    #[test]
    #[available_gas(8850)]
    fn test_decrease_intelligence_gas() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        adventurer.stats.decrease_intelligence(0);
    }

    #[test]
    fn test_decrease_intelligence() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        adventurer.stats.increase_intelligence(2);
        assert(adventurer.stats.intelligence == 2, 'intelligence should be 2');
        adventurer.stats.decrease_intelligence(1);
        assert(adventurer.stats.intelligence == 1, 'intelligence should be 1');
    }

    #[test]
    #[should_panic(expected: ('intelligence underflow',))]
    fn test_decrease_intelligence_underflow() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        adventurer.stats.increase_intelligence(5);
        adventurer.stats.decrease_intelligence(6);
    }

    #[test]
    #[available_gas(8850)]
    fn test_decrease_wisdom_gas() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        adventurer.stats.decrease_wisdom(0);
    }

    #[test]
    fn test_decrease_wisdom() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        adventurer.stats.increase_wisdom(2);
        assert(adventurer.stats.wisdom == 2, 'wisdom should be 2');
        adventurer.stats.decrease_wisdom(1);
        assert(adventurer.stats.wisdom == 1, 'wisdom should be 1');
    }

    #[test]
    #[should_panic(expected: ('wisdom underflow',))]
    fn test_decrease_wisdom_underflow() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        adventurer.stats.increase_wisdom(5);
        adventurer.stats.decrease_wisdom(6);
    }

    #[test]
    #[available_gas(8850)]
    fn test_decrease_charisma_gas() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        adventurer.stats.decrease_charisma(0);
    }

    #[test]
    fn test_decrease_charisma() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        adventurer.stats.increase_charisma(2);
        assert(adventurer.stats.charisma == 2, 'charisma should be 2');
        adventurer.stats.decrease_charisma(1);
        assert(adventurer.stats.charisma == 1, 'charisma should be 1');
    }

    #[test]
    #[should_panic(expected: ('charisma underflow',))]
    fn test_decrease_charisma_underflow() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        adventurer.stats.increase_charisma(5);
        adventurer.stats.decrease_charisma(6);
    }

    #[test]
    #[available_gas(449564)]
    fn test_get_equipped_items() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);

        let starting_equipment = adventurer.get_equipped_items();
        assert(starting_equipment.len() == 1, 'adventurer starts with 1 item');
        assert(*starting_equipment.at(0).id == ItemId::Wand, 'adventurer starts with wand');

        // equip chest armor
        let chest = Item { id: ItemId::DivineRobe, xp: 1 };
        adventurer.equipment.equip_chest_armor(chest);

        // assert we now have two items equipped
        let equipped_items = adventurer.get_equipped_items();
        assert(equipped_items.len() == 2, 'should have 2 items equipped');
        assert(*equipped_items.at(0).id == ItemId::Wand, 'should have wand equipped');
        assert(*equipped_items.at(1).id == ItemId::DivineRobe, 'should have robe equipped');

        // equip head armor
        let head = Item { id: ItemId::Crown, xp: 1 };
        adventurer.equipment.equip_head_armor(head);

        // assert we now have three items equipped
        let equipped_items = adventurer.get_equipped_items();
        assert(equipped_items.len() == 3, 'should have 3 items equipped');
        assert(*equipped_items.at(0).id == ItemId::Wand, 'should have wand equipped');
        assert(*equipped_items.at(1).id == ItemId::DivineRobe, 'should have robe equipped');
        assert(*equipped_items.at(2).id == ItemId::Crown, 'should have crown equipped');

        // equip waist armor
        let waist = Item { id: ItemId::DemonhideBelt, xp: 1 };
        adventurer.equipment.equip_waist_armor(waist);

        // assert we now have four items equipped
        let equipped_items = adventurer.get_equipped_items();
        assert(equipped_items.len() == 4, 'should have 4 items equipped');
        assert(*equipped_items.at(0).id == ItemId::Wand, 'should have wand equipped');
        assert(*equipped_items.at(1).id == ItemId::DivineRobe, 'should have robe equipped');
        assert(*equipped_items.at(2).id == ItemId::Crown, 'should have crown equipped');
        assert(*equipped_items.at(3).id == ItemId::DemonhideBelt, 'should have belt equipped');

        // equip foot armor
        let foot = Item { id: ItemId::LeatherBoots, xp: 1 };
        adventurer.equipment.equip_foot_armor(foot);

        // assert we now have five items equipped
        let equipped_items = adventurer.get_equipped_items();
        assert(equipped_items.len() == 5, 'should have 5 items equipped');
        assert(*equipped_items.at(0).id == ItemId::Wand, 'should have wand equipped');
        assert(*equipped_items.at(1).id == ItemId::DivineRobe, 'should have robe equipped');
        assert(*equipped_items.at(2).id == ItemId::Crown, 'should have crown equipped');
        assert(*equipped_items.at(3).id == ItemId::DemonhideBelt, 'should have belt equipped');
        assert(*equipped_items.at(4).id == ItemId::LeatherBoots, 'should have boots equipped');

        // equip hand armor
        let hand = Item { id: ItemId::LeatherGloves, xp: 1 };
        adventurer.equipment.equip_hand_armor(hand);

        // assert we now have six items equipped
        let equipped_items = adventurer.get_equipped_items();
        assert(equipped_items.len() == 6, 'should have 6 items equipped');
        assert(*equipped_items.at(0).id == ItemId::Wand, 'should have wand equipped');
        assert(*equipped_items.at(1).id == ItemId::DivineRobe, 'should have robe equipped');
        assert(*equipped_items.at(2).id == ItemId::Crown, 'should have crown equipped');
        assert(*equipped_items.at(3).id == ItemId::DemonhideBelt, 'should have belt equipped');
        assert(*equipped_items.at(4).id == ItemId::LeatherBoots, 'should have boots equipped');
        assert(*equipped_items.at(5).id == ItemId::LeatherGloves, 'should have gloves equipped');

        // equip necklace
        let neck = Item { id: ItemId::Amulet, xp: 1 };
        adventurer.equipment.equip_necklace(neck);

        // assert we now have seven items equipped
        let equipped_items = adventurer.get_equipped_items();
        assert(equipped_items.len() == 7, 'should have 7 items equipped');
        assert(*equipped_items.at(0).id == ItemId::Wand, 'should have wand equipped');
        assert(*equipped_items.at(1).id == ItemId::DivineRobe, 'should have robe equipped');
        assert(*equipped_items.at(2).id == ItemId::Crown, 'should have crown equipped');
        assert(*equipped_items.at(3).id == ItemId::DemonhideBelt, 'should have belt equipped');
        assert(*equipped_items.at(4).id == ItemId::LeatherBoots, 'should have boots equipped');
        assert(*equipped_items.at(5).id == ItemId::LeatherGloves, 'should have gloves equipped');
        assert(*equipped_items.at(6).id == ItemId::Amulet, 'should have amulet equipped');

        // equip ring
        let ring = Item { id: ItemId::GoldRing, xp: 1 };
        adventurer.equipment.equip_ring(ring);

        // assert we now have eight items equipped
        let equipped_items = adventurer.get_equipped_items();
        assert(equipped_items.len() == 8, 'should have 8 items equipped');
        assert(*equipped_items.at(0).id == ItemId::Wand, 'should have wand equipped');
        assert(*equipped_items.at(1).id == ItemId::DivineRobe, 'should have robe equipped');
        assert(*equipped_items.at(2).id == ItemId::Crown, 'should have crown equipped');
        assert(*equipped_items.at(3).id == ItemId::DemonhideBelt, 'should have belt equipped');
        assert(*equipped_items.at(4).id == ItemId::LeatherBoots, 'should have boots equipped');
        assert(*equipped_items.at(5).id == ItemId::LeatherGloves, 'should have gloves equipped');
        assert(*equipped_items.at(6).id == ItemId::Amulet, 'should have amulet equipped');
        assert(*equipped_items.at(7).id == ItemId::GoldRing, 'should have ring equipped');

        // equip a different weapon
        let weapon = Item { id: ItemId::Katana, xp: 1 };
        adventurer.equipment.equip_weapon(weapon);

        // assert we still have eight items equipped
        let equipped_items = adventurer.get_equipped_items();
        assert(equipped_items.len() == 8, 'should have 8 items equipped');
        assert(*equipped_items.at(0).id == ItemId::Katana, 'should have katana equipped');
        assert(*equipped_items.at(1).id == ItemId::DivineRobe, 'should have robe equipped');
        assert(*equipped_items.at(2).id == ItemId::Crown, 'should have crown equipped');
        assert(*equipped_items.at(3).id == ItemId::DemonhideBelt, 'should have belt equipped');
        assert(*equipped_items.at(4).id == ItemId::LeatherBoots, 'should have boots equipped');
        assert(*equipped_items.at(5).id == ItemId::LeatherGloves, 'should have gloves equipped');
        assert(*equipped_items.at(6).id == ItemId::Amulet, 'should have amulet equipped');
        assert(*equipped_items.at(7).id == ItemId::GoldRing, 'should have ring equipped');
    }

    #[test]
    #[available_gas(184944)]
    fn test_set_beast_health() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);

        // base case
        adventurer.set_beast_health(100);
        assert(adventurer.beast_health == 100, 'wrong beast health');

        // overflow case
        adventurer.set_beast_health(65535);
        assert(
            adventurer.beast_health == BeastSettings::MAXIMUM_HEALTH, 'beast health should be max'
        );
    }

    #[test]
    #[available_gas(194964)]
    fn test_deduct_beast_health() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);

        // stage beast with 100
        adventurer.set_beast_health(100);

        // deduct 5 (base case)
        adventurer.deduct_beast_health(5);
        assert(adventurer.beast_health == 95, 'beast should have 95HP');

        // deduct 2^16 - 1 (overflow case)
        adventurer.deduct_beast_health(65535);
        assert(adventurer.beast_health == 0, 'beast should have 0HP');
    }

    #[test]
    #[available_gas(900000)]
    fn test_explore_health_discovery() { //TODO: test health discovery
    }

    #[test]
    #[available_gas(900000)]
    fn test_explore_gold_discovery() { //TODO: test health discovery
    }

    #[test]
    #[available_gas(900000)]
    fn test_explore_xp_discovery() { // TODO: test xp discovery
    }

    #[test]
    #[available_gas(300000)]
    fn test_get_item_at_slot() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);

        // stage items
        let weapon = Item { id: ItemId::Katana, xp: 1 };
        let chest = Item { id: ItemId::DivineRobe, xp: 1 };
        let head = Item { id: ItemId::Crown, xp: 1 };
        let waist = Item { id: ItemId::DemonhideBelt, xp: 1 };
        let foot = Item { id: ItemId::LeatherBoots, xp: 1 };
        let hand = Item { id: ItemId::LeatherGloves, xp: 1 };
        let neck = Item { id: ItemId::Amulet, xp: 1 };
        let ring = Item { id: ItemId::GoldRing, xp: 1 };

        // equip items
        adventurer.equipment.equip_weapon(weapon);
        adventurer.equipment.equip_chest_armor(chest);
        adventurer.equipment.equip_head_armor(head);
        adventurer.equipment.equip_waist_armor(waist);
        adventurer.equipment.equip_foot_armor(foot);
        adventurer.equipment.equip_hand_armor(hand);
        adventurer.equipment.equip_necklace(neck);
        adventurer.equipment.equip_ring(ring);

        // verify getting item by slot returns correct items
        assert(adventurer.equipment.get_item_at_slot(Slot::Weapon(())) == weapon, 'wrong weapon');
        assert(
            adventurer.equipment.get_item_at_slot(Slot::Chest(())) == chest, 'wrong chest armor'
        );
        assert(adventurer.equipment.get_item_at_slot(Slot::Head(())) == head, 'wrong head armor');
        assert(
            adventurer.equipment.get_item_at_slot(Slot::Waist(())) == waist, 'wrong waist armor'
        );
        assert(adventurer.equipment.get_item_at_slot(Slot::Foot(())) == foot, 'wrong foot armor');
        assert(adventurer.equipment.get_item_at_slot(Slot::Hand(())) == hand, 'wrong hand armor');
        assert(adventurer.equipment.get_item_at_slot(Slot::Neck(())) == neck, 'wrong necklace');
        assert(adventurer.equipment.get_item_at_slot(Slot::Ring(())) == ring, 'wrong ring');
    }

    #[test]
    #[available_gas(353184)]
    fn test_is_slot_free() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);

        // stage items
        let weapon = Item { id: ItemId::Katana, xp: 1 };
        let chest = Item { id: ItemId::DivineRobe, xp: 1 };
        let head = Item { id: ItemId::Crown, xp: 1 };
        let waist = Item { id: ItemId::DemonhideBelt, xp: 1 };
        let foot = Item { id: ItemId::LeatherBoots, xp: 1 };
        let hand = Item { id: ItemId::LeatherGloves, xp: 1 };
        let neck = Item { id: ItemId::Amulet, xp: 1 };
        let ring = Item { id: ItemId::GoldRing, xp: 1 };

        // equip half the items, adventurer will have nothing equipped for the other slots
        adventurer.equipment.equip_weapon(weapon);
        adventurer.equipment.equip_head_armor(head);
        adventurer.equipment.equip_foot_armor(foot);
        adventurer.equipment.equip_necklace(neck);

        // verify is_slot_free returns correct values
        assert(
            adventurer.equipment.is_slot_free(weapon) == false, 'weapon slot should be occupied'
        );
        assert(adventurer.equipment.is_slot_free(chest) == true, 'chest slot should be free');
        assert(adventurer.equipment.is_slot_free(head) == false, 'head slot should be occupied');
        assert(adventurer.equipment.is_slot_free(waist) == true, 'waist slot should be free');
        assert(adventurer.equipment.is_slot_free(foot) == false, 'foot slot should be occupied');
        assert(adventurer.equipment.is_slot_free(hand) == true, 'hand slot should be free');
        assert(adventurer.equipment.is_slot_free(neck) == false, 'neck slot should be occupied');
        assert(adventurer.equipment.is_slot_free(ring) == true, 'ring slot should be free');
    }

    #[test]
    #[available_gas(600000)]
    fn test_get_level() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        assert(adventurer.get_level() == 1, 'level should be 1');

        adventurer.xp = 4;
        assert(adventurer.get_level() == 2, 'level should be 2');

        adventurer.xp = 9;
        assert(adventurer.get_level() == 3, 'level should be 3');

        adventurer.xp = 16;
        assert(adventurer.get_level() == 4, 'level should be 4');

        // max xp available for packing (2^13 - 1)
        adventurer.xp = 8191;
        assert(adventurer.get_level() == 90, 'level should be 15');

        // max u16 value
        adventurer.xp = 65535;
        assert(adventurer.get_level() == 255, 'level should be 15');
    }

    #[test]
    #[available_gas(234224)]
    fn test_charisma_health_discount_overflow() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);

        // max charisma
        adventurer.stats.charisma = 255;
        let discount = adventurer.charisma_adjusted_potion_price();
        assert(discount == MINIMUM_POTION_PRICE, 'discount');

        // set charisma to 0
        adventurer.stats.charisma = 0;
        let discount = adventurer.charisma_adjusted_potion_price();
        assert(
            discount == MINIMUM_POTION_PRICE * adventurer.get_level().into(), 'no charisma potion'
        );
    }

    #[test]
    #[available_gas(234524)]
    fn test_charisma_item_discount_overflow() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        let item_price = 15;

        // no charisma case
        adventurer.stats.charisma = 0;
        assert(adventurer.charisma_adjusted_item_price(item_price) == 15, 'should be no discount');

        // small discount case
        adventurer.stats.charisma = 1;
        assert(
            adventurer.charisma_adjusted_item_price(item_price) == item_price
                - CHARISMA_ITEM_DISCOUNT,
            'wrong discounted price'
        );

        // underflow case
        adventurer.stats.charisma = 255;
        assert(
            adventurer.charisma_adjusted_item_price(item_price) == MINIMUM_ITEM_PRICE,
            'item should be min price'
        );
    }

    #[test]
    #[available_gas(256224)]
    fn test_increase_xp() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);

        // increase adventurer xp by 3 which should level up the adventurer
        adventurer.increase_adventurer_xp(4);
        assert(adventurer.get_level() == 2, 'advtr should be lvl 2');

        // double level up without spending previous stat point
        adventurer.increase_adventurer_xp(12);
        assert(adventurer.get_level() == 4, 'advtr should be lvl 4');
    }

    #[test]
    #[available_gas(293884)]
    fn test_apply_suffix_boost() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);

        adventurer.stats.apply_suffix_boost(ItemSuffix::of_Power);
        assert(adventurer.stats.strength == 3, 'strength should be 3');
        assert(adventurer.stats.dexterity == 0, 'dexterity should be 0');
        assert(adventurer.stats.vitality == 0, 'vitality should be 0');
        assert(adventurer.stats.intelligence == 0, 'intelligence should be 0');
        assert(adventurer.stats.wisdom == 0, 'wisdom should be 0');
        assert(adventurer.stats.charisma == 0, 'charisma should be 0');

        adventurer.stats.apply_suffix_boost(ItemSuffix::of_Giant);
        assert(adventurer.stats.strength == 3, 'strength should be 3');
        assert(adventurer.stats.vitality == 3, 'vitality should be 3');
        assert(adventurer.stats.dexterity == 0, 'dexterity should be 0');
        assert(adventurer.stats.intelligence == 0, 'intelligence should be 0');
        assert(adventurer.stats.wisdom == 0, 'wisdom should be 0');
        assert(adventurer.stats.charisma == 0, 'charisma should be 0');

        adventurer.stats.apply_suffix_boost(ItemSuffix::of_Perfection);
        assert(adventurer.stats.strength == 4, 'strength should be 4');
        assert(adventurer.stats.vitality == 4, 'vitality should be 4');
        assert(adventurer.stats.dexterity == 1, 'dexterity should be 1');
        assert(adventurer.stats.intelligence == 0, 'intelligence should be 0');
        assert(adventurer.stats.wisdom == 0, 'wisdom should be 0');
        assert(adventurer.stats.charisma == 0, 'charisma should be 0');

        adventurer.stats.apply_suffix_boost(ItemSuffix::of_Rage);
        assert(adventurer.stats.strength == 5, 'strength should be 5');
        assert(adventurer.stats.vitality == 4, 'vitality should be 4');
        assert(adventurer.stats.dexterity == 1, 'dexterity should be 1');
        assert(adventurer.stats.intelligence == 0, 'intelligence should be 0');
        assert(adventurer.stats.wisdom == 1, 'wisdom should be 1');
        assert(adventurer.stats.charisma == 1, 'charisma should be 1');

        adventurer.stats.apply_suffix_boost(ItemSuffix::of_Fury);
        assert(adventurer.stats.strength == 5, 'strength should be 5');
        assert(adventurer.stats.vitality == 5, 'vitality should be 5');
        assert(adventurer.stats.dexterity == 1, 'dexterity should be 1');
        assert(adventurer.stats.intelligence == 1, 'intelligence should be 1');
        assert(adventurer.stats.wisdom == 1, 'wisdom should be 1');
        assert(adventurer.stats.charisma == 2, 'charisma should be 2');
    }

    #[test]
    #[available_gas(1900000)]
    fn test_remove_suffix_boost() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        adventurer.stats.strength = 4;
        adventurer.stats.remove_suffix_boost(ItemSuffix::of_Power);
        assert(adventurer.stats.strength == 1, 'strength should be 1');
    }

    #[test]
    fn test_apply_power_boost() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        adventurer.stats.apply_suffix_boost(ItemSuffix::of_Power);
        assert(adventurer.stats.strength == 3, 'strength should be 3');
        assert(adventurer.stats.vitality == 0, 'vitality should be 0');
        assert(adventurer.stats.dexterity == 0, 'dexterity should be 0');
        assert(adventurer.stats.intelligence == 0, 'intelligence should be 0');
        assert(adventurer.stats.wisdom == 0, 'wisdom should be 0');
        assert(adventurer.stats.charisma == 0, 'charisma should be 0');
    }

    #[test]
    fn test_apply_giant_boost() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        adventurer.stats.apply_suffix_boost(ItemSuffix::of_Giant);
        assert(adventurer.stats.strength == 0, 'strength should be 0');
        assert(adventurer.stats.vitality == 3, 'vitality should be 3');
        assert(adventurer.stats.dexterity == 0, 'dexterity should be 0');
        assert(adventurer.stats.intelligence == 0, 'intelligence should be 0');
        assert(adventurer.stats.wisdom == 0, 'wisdom should be 0');
        assert(adventurer.stats.charisma == 0, 'charisma should be 0');
    }

    #[test]
    fn test_apply_skill_boost() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        adventurer.stats.apply_suffix_boost(ItemSuffix::of_Skill);
        assert(adventurer.stats.strength == 0, 'strength should be 0');
        assert(adventurer.stats.vitality == 0, 'vitality should be 0');
        assert(adventurer.stats.dexterity == 3, 'dexterity should be 3');
        assert(adventurer.stats.intelligence == 0, 'intelligence should be 0');
        assert(adventurer.stats.wisdom == 0, 'wisdom should be 0');
        assert(adventurer.stats.charisma == 0, 'charisma should be 0');
    }

    #[test]
    fn test_apply_perfection_boost() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        adventurer.stats.apply_suffix_boost(ItemSuffix::of_Perfection);
        assert(adventurer.stats.strength == 1, 'strength should be 1');
        assert(adventurer.stats.vitality == 1, 'vitality should be 1');
        assert(adventurer.stats.dexterity == 1, 'dexterity should be 1');
        assert(adventurer.stats.intelligence == 0, 'intelligence should be 0');
        assert(adventurer.stats.wisdom == 0, 'wisdom should be 0');
        assert(adventurer.stats.charisma == 0, 'charisma should be 0');
    }

    #[test]
    fn test_apply_brilliance_boost() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        adventurer.stats.apply_suffix_boost(ItemSuffix::of_Brilliance);
        assert(adventurer.stats.strength == 0, 'strength should be 0');
        assert(adventurer.stats.vitality == 0, 'vitality should be 0');
        assert(adventurer.stats.dexterity == 0, 'dexterity should be 0');
        assert(adventurer.stats.intelligence == 3, 'intelligence should be 3');
        assert(adventurer.stats.wisdom == 0, 'wisdom should be 0');
        assert(adventurer.stats.charisma == 0, 'charisma should be 0');
    }

    #[test]
    fn test_apply_enlightenment_boost() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        adventurer.stats.apply_suffix_boost(ItemSuffix::of_Enlightenment);
        assert(adventurer.stats.strength == 0, 'strength should be 0');
        assert(adventurer.stats.vitality == 0, 'vitality should be 0');
        assert(adventurer.stats.dexterity == 0, 'dexterity should be 0');
        assert(adventurer.stats.intelligence == 0, 'intelligence should be 0');
        assert(adventurer.stats.wisdom == 3, 'wisdom should be 3');
        assert(adventurer.stats.charisma == 0, 'charisma should be 0');
    }

    #[test]
    fn test_apply_protection_boost() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        adventurer.stats.apply_suffix_boost(ItemSuffix::of_Protection);
        assert(adventurer.stats.strength == 0, 'strength should be 0');
        assert(adventurer.stats.vitality == 2, 'vitality should be 2');
        assert(adventurer.stats.dexterity == 1, 'dexterity should be 1');
        assert(adventurer.stats.intelligence == 0, 'intelligence should be 0');
        assert(adventurer.stats.wisdom == 0, 'wisdom should be 0');
        assert(adventurer.stats.charisma == 0, 'charisma should be 0');
    }

    #[test]
    fn test_apply_anger_boost() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        adventurer.stats.apply_suffix_boost(ItemSuffix::of_Anger);
        assert(adventurer.stats.strength == 2, 'strength should be 2');
        assert(adventurer.stats.vitality == 0, 'vitality should be 0');
        assert(adventurer.stats.dexterity == 1, 'dexterity should be 1');
        assert(adventurer.stats.intelligence == 0, 'intelligence should be 0');
        assert(adventurer.stats.wisdom == 0, 'wisdom should be 0');
        assert(adventurer.stats.charisma == 0, 'charisma should be 0');
    }

    #[test]
    fn test_apply_rage_boost() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        adventurer.stats.apply_suffix_boost(ItemSuffix::of_Rage);
        assert(adventurer.stats.strength == 1, 'strength should be 1');
        assert(adventurer.stats.vitality == 0, 'vitality should be 0');
        assert(adventurer.stats.dexterity == 0, 'dexterity should be 0');
        assert(adventurer.stats.intelligence == 0, 'intelligence should be 0');
        assert(adventurer.stats.wisdom == 1, 'wisdom should be 1');
        assert(adventurer.stats.charisma == 1, 'charisma should be 1');
    }

    #[test]
    fn test_apply_fury_boost() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        adventurer.stats.apply_suffix_boost(ItemSuffix::of_Fury);
        assert(adventurer.stats.strength == 0, 'strength should be 0');
        assert(adventurer.stats.vitality == 1, 'vitality should be 1');
        assert(adventurer.stats.dexterity == 0, 'dexterity should be 0');
        assert(adventurer.stats.intelligence == 1, 'intelligence should be 1');
        assert(adventurer.stats.wisdom == 0, 'wisdom should be 0');
        assert(adventurer.stats.charisma == 1, 'charisma should be 1');
    }

    #[test]
    fn test_apply_vitriol_boost() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        adventurer.stats.apply_suffix_boost(ItemSuffix::of_Vitriol);
        assert(adventurer.stats.strength == 0, 'strength should be 0');
        assert(adventurer.stats.vitality == 0, 'vitality should be 0');
        assert(adventurer.stats.dexterity == 0, 'dexterity should be 0');
        assert(adventurer.stats.intelligence == 2, 'intelligence should be 2');
        assert(adventurer.stats.wisdom == 1, 'wisdom should be 1');
        assert(adventurer.stats.charisma == 0, 'charisma should be 0');
    }

    #[test]
    fn test_apply_fox_boost() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        adventurer.stats.apply_suffix_boost(ItemSuffix::of_the_Fox);
        assert(adventurer.stats.strength == 0, 'strength should be 0');
        assert(adventurer.stats.vitality == 0, 'vitality should be 0');
        assert(adventurer.stats.dexterity == 2, 'dexterity should be 2');
        assert(adventurer.stats.intelligence == 0, 'intelligence should be 0');
        assert(adventurer.stats.wisdom == 0, 'wisdom should be 0');
        assert(adventurer.stats.charisma == 1, 'charisma should be 1');
    }

    #[test]
    fn test_apply_detection_boost() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        adventurer.stats.apply_suffix_boost(ItemSuffix::of_Detection);
        assert(adventurer.stats.strength == 0, 'strength should be 0');
        assert(adventurer.stats.vitality == 0, 'vitality should be 0');
        assert(adventurer.stats.dexterity == 1, 'dexterity should be 1');
        assert(adventurer.stats.intelligence == 0, 'intelligence should be 0');
        assert(adventurer.stats.wisdom == 2, 'wisdom should be 2');
        assert(adventurer.stats.charisma == 0, 'charisma should be 0');
    }

    #[test]
    fn test_apply_reflection_boost() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        adventurer.stats.apply_suffix_boost(ItemSuffix::of_Reflection);
        assert(adventurer.stats.strength == 0, 'strength should be 0');
        assert(adventurer.stats.vitality == 0, 'vitality should be 0');
        assert(adventurer.stats.dexterity == 0, 'dexterity should be 0');
        assert(adventurer.stats.intelligence == 1, 'intelligence should be 1');
        assert(adventurer.stats.wisdom == 2, 'wisdom should be 2');
        assert(adventurer.stats.charisma == 0, 'charisma should be 0');
    }

    #[test]
    fn test_apply_twins_boost() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        adventurer.stats.apply_suffix_boost(ItemSuffix::of_the_Twins);
        assert(adventurer.stats.strength == 0, 'strength should be 0');
        assert(adventurer.stats.vitality == 0, 'vitality should be 0');
        assert(adventurer.stats.dexterity == 0, 'dexterity should be 0');
        assert(adventurer.stats.intelligence == 0, 'intelligence should be 0');
        assert(adventurer.stats.wisdom == 0, 'wisdom should be 0');
        assert(adventurer.stats.charisma == 3, 'charisma should be 3');
    }

    #[test]
    fn test_apply_and_remove_power_boost() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        adventurer.stats.apply_suffix_boost(ItemSuffix::of_Power);
        adventurer.stats.remove_suffix_boost(ItemSuffix::of_Power);
        assert(adventurer.stats.strength == 0, 'strength should be 0');
        assert(adventurer.stats.vitality == 0, 'vitality should be 0');
        assert(adventurer.stats.dexterity == 0, 'dexterity should be 0');
        assert(adventurer.stats.intelligence == 0, 'intelligence should be 0');
        assert(adventurer.stats.wisdom == 0, 'wisdom should be 0');
        assert(adventurer.stats.charisma == 0, 'charisma should be 0');
    }

    #[test]
    fn test_apply_and_remove_giant_boost() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        adventurer.stats.apply_suffix_boost(ItemSuffix::of_Giant);
        adventurer.stats.remove_suffix_boost(ItemSuffix::of_Giant);
        assert(adventurer.stats.strength == 0, 'strength should be 0');
        assert(adventurer.stats.vitality == 0, 'vitality should be 0');
        assert(adventurer.stats.dexterity == 0, 'dexterity should be 0');
        assert(adventurer.stats.intelligence == 0, 'intelligence should be 0');
        assert(adventurer.stats.wisdom == 0, 'wisdom should be 0');
        assert(adventurer.stats.charisma == 0, 'charisma should be 0');
    }

    #[test]
    fn test_apply_and_remove_titans_boost() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        adventurer.stats.apply_suffix_boost(ItemSuffix::of_Titans);
        adventurer.stats.remove_suffix_boost(ItemSuffix::of_Titans);
        assert(adventurer.stats.strength == 0, 'strength should be 0');
        assert(adventurer.stats.vitality == 0, 'vitality should be 0');
        assert(adventurer.stats.dexterity == 0, 'dexterity should be 0');
        assert(adventurer.stats.intelligence == 0, 'intelligence should be 0');
        assert(adventurer.stats.wisdom == 0, 'wisdom should be 0');
        assert(adventurer.stats.charisma == 0, 'charisma should be 0');
    }

    #[test]
    fn test_apply_and_remove_skill_boost() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        adventurer.stats.apply_suffix_boost(ItemSuffix::of_Skill);
        adventurer.stats.remove_suffix_boost(ItemSuffix::of_Skill);
        assert(adventurer.stats.strength == 0, 'strength should be 0');
        assert(adventurer.stats.vitality == 0, 'vitality should be 0');
        assert(adventurer.stats.dexterity == 0, 'dexterity should be 0');
        assert(adventurer.stats.intelligence == 0, 'intelligence should be 0');
        assert(adventurer.stats.wisdom == 0, 'wisdom should be 0');
        assert(adventurer.stats.charisma == 0, 'charisma should be 0');
    }

    #[test]
    fn test_apply_and_remove_perfection_boost() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        adventurer.stats.apply_suffix_boost(ItemSuffix::of_Perfection);
        adventurer.stats.remove_suffix_boost(ItemSuffix::of_Perfection);
        assert(adventurer.stats.strength == 0, 'strength should be 0');
        assert(adventurer.stats.vitality == 0, 'vitality should be 0');
        assert(adventurer.stats.dexterity == 0, 'dexterity should be 0');
        assert(adventurer.stats.intelligence == 0, 'intelligence should be 0');
        assert(adventurer.stats.wisdom == 0, 'wisdom should be 0');
        assert(adventurer.stats.charisma == 0, 'charisma should be 0');
    }

    #[test]
    fn test_apply_and_remove_brilliance_boost() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        adventurer.stats.apply_suffix_boost(ItemSuffix::of_Brilliance);
        adventurer.stats.remove_suffix_boost(ItemSuffix::of_Brilliance);
        assert(adventurer.stats.strength == 0, 'strength should be 0');
        assert(adventurer.stats.vitality == 0, 'vitality should be 0');
        assert(adventurer.stats.dexterity == 0, 'dexterity should be 0');
        assert(adventurer.stats.intelligence == 0, 'intelligence should be 0');
        assert(adventurer.stats.wisdom == 0, 'wisdom should be 0');
        assert(adventurer.stats.charisma == 0, 'charisma should be 0');
    }

    #[test]
    fn test_apply_and_remove_enlightenment_boost() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        adventurer.stats.apply_suffix_boost(ItemSuffix::of_Enlightenment);
        adventurer.stats.remove_suffix_boost(ItemSuffix::of_Enlightenment);
        assert(adventurer.stats.strength == 0, 'strength should be 0');
        assert(adventurer.stats.vitality == 0, 'vitality should be 0');
        assert(adventurer.stats.dexterity == 0, 'dexterity should be 0');
        assert(adventurer.stats.intelligence == 0, 'intelligence should be 0');
        assert(adventurer.stats.wisdom == 0, 'wisdom should be 0');
        assert(adventurer.stats.charisma == 0, 'charisma should be 0');
    }

    #[test]
    fn test_apply_and_remove_protection_boost() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        adventurer.stats.apply_suffix_boost(ItemSuffix::of_Protection);
        adventurer.stats.remove_suffix_boost(ItemSuffix::of_Protection);
        assert(adventurer.stats.strength == 0, 'strength should be 0');
        assert(adventurer.stats.vitality == 0, 'vitality should be 0');
        assert(adventurer.stats.dexterity == 0, 'dexterity should be 0');
        assert(adventurer.stats.intelligence == 0, 'intelligence should be 0');
        assert(adventurer.stats.wisdom == 0, 'wisdom should be 0');
        assert(adventurer.stats.charisma == 0, 'charisma should be 0');
    }

    #[test]
    fn test_apply_and_remove_anger_boost() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        adventurer.stats.apply_suffix_boost(ItemSuffix::of_Anger);
        adventurer.stats.remove_suffix_boost(ItemSuffix::of_Anger);
        assert(adventurer.stats.strength == 0, 'strength should be 0');
        assert(adventurer.stats.vitality == 0, 'vitality should be 0');
        assert(adventurer.stats.dexterity == 0, 'dexterity should be 0');
        assert(adventurer.stats.intelligence == 0, 'intelligence should be 0');
        assert(adventurer.stats.wisdom == 0, 'wisdom should be 0');
        assert(adventurer.stats.charisma == 0, 'charisma should be 0');
    }

    #[test]
    fn test_apply_and_remove_rage_boost() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        adventurer.stats.apply_suffix_boost(ItemSuffix::of_Rage);
        adventurer.stats.remove_suffix_boost(ItemSuffix::of_Rage);
        assert(adventurer.stats.strength == 0, 'strength should be 0');
        assert(adventurer.stats.vitality == 0, 'vitality should be 0');
        assert(adventurer.stats.dexterity == 0, 'dexterity should be 0');
        assert(adventurer.stats.intelligence == 0, 'intelligence should be 0');
        assert(adventurer.stats.wisdom == 0, 'wisdom should be 0');
        assert(adventurer.stats.charisma == 0, 'charisma should be 0');
    }

    #[test]
    fn test_apply_and_remove_fury_boost() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        adventurer.stats.apply_suffix_boost(ItemSuffix::of_Fury);
        adventurer.stats.remove_suffix_boost(ItemSuffix::of_Fury);
        assert(adventurer.stats.strength == 0, 'strength should be 0');
        assert(adventurer.stats.vitality == 0, 'vitality should be 0');
        assert(adventurer.stats.dexterity == 0, 'dexterity should be 0');
        assert(adventurer.stats.intelligence == 0, 'intelligence should be 0');
        assert(adventurer.stats.wisdom == 0, 'wisdom should be 0');
        assert(adventurer.stats.charisma == 0, 'charisma should be 0');
    }

    #[test]
    fn test_apply_and_remove_vitriol_boost() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        adventurer.stats.apply_suffix_boost(ItemSuffix::of_Vitriol);
        adventurer.stats.remove_suffix_boost(ItemSuffix::of_Vitriol);
        assert(adventurer.stats.strength == 0, 'strength should be 0');
        assert(adventurer.stats.vitality == 0, 'vitality should be 0');
        assert(adventurer.stats.dexterity == 0, 'dexterity should be 0');
        assert(adventurer.stats.intelligence == 0, 'intelligence should be 0');
        assert(adventurer.stats.wisdom == 0, 'wisdom should be 0');
        assert(adventurer.stats.charisma == 0, 'charisma should be 0');
    }

    #[test]
    fn test_apply_and_remove_fox_boost() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        adventurer.stats.apply_suffix_boost(ItemSuffix::of_the_Fox);
        adventurer.stats.remove_suffix_boost(ItemSuffix::of_the_Fox);
        assert(adventurer.stats.strength == 0, 'strength should be 0');
        assert(adventurer.stats.vitality == 0, 'vitality should be 0');
        assert(adventurer.stats.dexterity == 0, 'dexterity should be 0');
        assert(adventurer.stats.intelligence == 0, 'intelligence should be 0');
        assert(adventurer.stats.wisdom == 0, 'wisdom should be 0');
        assert(adventurer.stats.charisma == 0, 'charisma should be 0');
    }

    #[test]
    fn test_apply_and_remove_detection_boost() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        adventurer.stats.apply_suffix_boost(ItemSuffix::of_Detection);
        adventurer.stats.remove_suffix_boost(ItemSuffix::of_Detection);
        assert(adventurer.stats.strength == 0, 'strength should be 0');
        assert(adventurer.stats.vitality == 0, 'vitality should be 0');
        assert(adventurer.stats.dexterity == 0, 'dexterity should be 0');
        assert(adventurer.stats.intelligence == 0, 'intelligence should be 0');
        assert(adventurer.stats.wisdom == 0, 'wisdom should be 0');
        assert(adventurer.stats.charisma == 0, 'charisma should be 0');
    }

    #[test]
    fn test_apply_and_remove_reflection_boost() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        adventurer.stats.apply_suffix_boost(ItemSuffix::of_Reflection);
        adventurer.stats.remove_suffix_boost(ItemSuffix::of_Reflection);
        assert(adventurer.stats.strength == 0, 'strength should be 0');
        assert(adventurer.stats.vitality == 0, 'vitality should be 0');
        assert(adventurer.stats.dexterity == 0, 'dexterity should be 0');
        assert(adventurer.stats.intelligence == 0, 'intelligence should be 0');
        assert(adventurer.stats.wisdom == 0, 'wisdom should be 0');
        assert(adventurer.stats.charisma == 0, 'charisma should be 0');
    }

    #[test]
    fn test_apply_and_remove_twins_boost() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        adventurer.stats.apply_suffix_boost(ItemSuffix::of_the_Twins);
        adventurer.stats.remove_suffix_boost(ItemSuffix::of_the_Twins);
        assert(adventurer.stats.strength == 0, 'strength should be 0');
        assert(adventurer.stats.vitality == 0, 'vitality should be 0');
        assert(adventurer.stats.dexterity == 0, 'dexterity should be 0');
        assert(adventurer.stats.intelligence == 0, 'intelligence should be 0');
        assert(adventurer.stats.wisdom == 0, 'wisdom should be 0');
        assert(adventurer.stats.charisma == 0, 'charisma should be 0');
    }

    #[test]
    #[available_gas(582280)]
    fn test_get_and_apply_stats() {
        let mut adventurer = Adventurer {
            health: 100,
            xp: 1,
            stats: Stats {
                strength: 0,
                dexterity: 0,
                vitality: 0,
                intelligence: 0,
                wisdom: 0,
                charisma: 0,
                luck: 0
            },
            gold: 40,
            equipment: Equipment {
                weapon: Item { id: 1, xp: 225 },
                chest: Item { id: 2, xp: 65535 },
                head: Item { id: 3, xp: 225 },
                waist: Item { id: 4, xp: 225 },
                foot: Item { id: 5, xp: 1000 },
                hand: Item { id: 6, xp: 224 },
                neck: Item { id: 7, xp: 1 },
                ring: Item { id: 8, xp: 1 }
            },
            beast_health: 20,
            stat_upgrades_available: 0,
            mutated: false,
            awaiting_item_specials: false
        };

        let stat_boosts = adventurer.equipment.get_stat_boosts(1);
        assert(stat_boosts.strength == 6, 'wrong strength');
        assert(stat_boosts.vitality == 1, 'wrong vitality');
        assert(stat_boosts.dexterity == 2, 'wrong dexterity');
        assert(stat_boosts.intelligence == 1, 'wrong intelligence');
        assert(stat_boosts.wisdom == 4, 'wrong wisdom');
        assert(stat_boosts.charisma == 1, 'wrong charisma');
    }

    // test base case
    #[test]
    #[available_gas(207524)]
    fn test_apply_stats() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);

        let boost_stats = Stats {
            strength: 5, dexterity: 1, vitality: 5, intelligence: 1, wisdom: 1, charisma: 2, luck: 1
        };

        adventurer.stats.apply_stats(boost_stats);
        assert(adventurer.stats.strength == 5, 'strength should be 5');
        assert(adventurer.stats.dexterity == 1, 'dexterity should be 1');
        assert(adventurer.stats.vitality == 5, 'vitality should be 5');

        assert(adventurer.stats.intelligence == 1, 'intelligence should be 1');
        assert(adventurer.stats.wisdom == 1, 'wisdom should be 1');
        assert(adventurer.stats.charisma == 2, 'charisma should be 2');
    }

    // test zero case
    #[test]
    #[available_gas(207524)]
    fn test_apply_stats_zero() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);

        let boost_stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0, luck: 0
        };

        adventurer.stats.apply_stats(boost_stats);
        assert(adventurer.stats.strength == 0, 'strength should be 0');
        assert(adventurer.stats.dexterity == 0, 'dexterity should be 0');
        assert(adventurer.stats.vitality == 0, 'vitality should be 0');
        assert(adventurer.stats.intelligence == 0, 'intelligence should be 0');
        assert(adventurer.stats.wisdom == 0, 'wisdom should be 0');
        assert(adventurer.stats.charisma == 0, 'charisma should be 0');
    }

    // test max value case
    #[test]
    #[available_gas(207524)]
    fn test_apply_stats_max() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        let boost_stats = Stats {
            strength: 255,
            dexterity: 255,
            vitality: 255,
            intelligence: 255,
            wisdom: 255,
            charisma: 255,
            luck: 255,
        };

        adventurer.stats.apply_stats(boost_stats);
        assert(adventurer.stats.strength == 255, 'strength should be max');
        assert(adventurer.stats.dexterity == 255, 'dexterity should be max');
        assert(adventurer.stats.vitality == 255, 'vitality should be max');
        assert(adventurer.stats.intelligence == 255, 'intelligence should be max');
        assert(adventurer.stats.wisdom == 255, 'wisdom should be max');
        assert(adventurer.stats.charisma == 255, 'charisma should be max');
    }

    // base case
    #[test]
    #[available_gas(53430)]
    fn test_remove_stats() {
        let mut adventurer = Adventurer {
            health: 100,
            xp: 1,
            stats: Stats {
                strength: 5,
                dexterity: 4,
                vitality: 3,
                intelligence: 2,
                wisdom: 1,
                charisma: 0,
                luck: 0
            },
            gold: 40,
            equipment: Equipment {
                weapon: Item { id: 1, xp: 225 },
                chest: Item { id: 2, xp: 65535 },
                head: Item { id: 3, xp: 225 },
                waist: Item { id: 4, xp: 225 },
                foot: Item { id: 5, xp: 1000 },
                hand: Item { id: 6, xp: 224 },
                neck: Item { id: 7, xp: 1 },
                ring: Item { id: 8, xp: 1 }
            },
            beast_health: 20,
            stat_upgrades_available: 0,
            mutated: false,
            awaiting_item_specials: false
        };

        let boost_stats = Stats {
            strength: 5, dexterity: 4, vitality: 3, intelligence: 2, wisdom: 1, charisma: 0, luck: 1
        };

        adventurer.stats.remove_stats(boost_stats);
        assert(adventurer.stats.strength == 0, 'strength should be 0');
        assert(adventurer.stats.dexterity == 0, 'dexterity should be 0');
        assert(adventurer.stats.vitality == 0, 'vitality should be 0');
        assert(adventurer.stats.intelligence == 0, 'intelligence should be 0');
        assert(adventurer.stats.wisdom == 0, 'wisdom should be 0');
        assert(adventurer.stats.charisma == 0, 'charisma should be 0');
    }

    // zero case
    #[test]
    #[available_gas(53430)]
    fn test_remove_stats_zero() {
        let mut adventurer = Adventurer {
            health: 100,
            xp: 1,
            stats: Stats {
                strength: 5,
                dexterity: 4,
                vitality: 3,
                intelligence: 2,
                wisdom: 1,
                charisma: 0,
                luck: 0
            },
            gold: 40,
            equipment: Equipment {
                weapon: Item { id: 1, xp: 225 },
                chest: Item { id: 2, xp: 65535 },
                head: Item { id: 3, xp: 225 },
                waist: Item { id: 4, xp: 225 },
                foot: Item { id: 5, xp: 1000 },
                hand: Item { id: 6, xp: 224 },
                neck: Item { id: 7, xp: 1 },
                ring: Item { id: 8, xp: 1 }
            },
            beast_health: 20,
            stat_upgrades_available: 0,
            mutated: false,
            awaiting_item_specials: false
        };

        let boost_stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0, luck: 0
        };

        adventurer.stats.remove_stats(boost_stats);
        assert(adventurer.stats.strength == 5, 'strength should be 5');
        assert(adventurer.stats.dexterity == 4, 'dexterity should be 4');
        assert(adventurer.stats.vitality == 3, 'vitality should be 3');
        assert(adventurer.stats.intelligence == 2, 'intelligence should be 2');
        assert(adventurer.stats.wisdom == 1, 'wisdom should be 1');
        assert(adventurer.stats.charisma == 0, 'charisma should be 0');
    }

    // max values case
    #[test]
    fn test_remove_stats_max() {
        let mut adventurer = Adventurer {
            health: 100,
            xp: 1,
            stats: Stats {
                strength: 255,
                dexterity: 255,
                vitality: 255,
                intelligence: 255,
                wisdom: 255,
                charisma: 255,
                luck: 0
            },
            gold: 40,
            equipment: Equipment {
                weapon: Item { id: 1, xp: 225 },
                chest: Item { id: 2, xp: 65535 },
                head: Item { id: 3, xp: 225 },
                waist: Item { id: 4, xp: 225 },
                foot: Item { id: 5, xp: 1000 },
                hand: Item { id: 6, xp: 224 },
                neck: Item { id: 7, xp: 1 },
                ring: Item { id: 8, xp: 1 }
            },
            beast_health: 20,
            stat_upgrades_available: 0,
            mutated: false,
            awaiting_item_specials: false
        };

        let boost_stats = Stats {
            strength: 255,
            dexterity: 255,
            vitality: 255,
            intelligence: 255,
            wisdom: 255,
            charisma: 255,
            luck: 255,
        };

        adventurer.stats.remove_stats(boost_stats);
        assert(adventurer.stats.strength == 0, 'strength should be 0');
        assert(adventurer.stats.dexterity == 0, 'dexterity should be 0');
        assert(adventurer.stats.vitality == 0, 'vitality should be 0');
        assert(adventurer.stats.intelligence == 0, 'intelligence should be 0');
        assert(adventurer.stats.wisdom == 0, 'wisdom should be 0');
        assert(adventurer.stats.charisma == 0, 'charisma should be 0');
    }

    #[test]
    #[available_gas(390000)]
    fn test_get_discovery() {
        let adventurer_level = 1;

        // discover gold
        let discovery_type = ImplAdventurer::get_discovery(adventurer_level, 1);
        assert(discovery_type == DiscoveryType::Gold((1)), 'should have found gold');

        // discover health
        let discovery_type = ImplAdventurer::get_discovery(adventurer_level, 46);
        assert(discovery_type == DiscoveryType::Health((2)), 'should have found health');
    }

    #[test]
    #[available_gas(245054)]
    fn test_calculate_luck_gas_no_luck() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        let bag = ImplBag::new();
        assert(adventurer.equipment.calculate_luck(bag) == 2, 'start with 2 luck');
    }

    #[test]
    #[available_gas(245554)]
    fn test_calculate_luck_gas_with_luck() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        let bag = ImplBag::new();

        let neck = Item { id: ItemId::Amulet, xp: 1 };
        adventurer.equipment.equip_necklace(neck);
        let ring = Item { id: ItemId::GoldRing, xp: 1 };
        adventurer.equipment.equip_ring(ring);
        assert(adventurer.equipment.calculate_luck(bag) == 2, 'start with 2 luck');
    }

    #[test]
    #[available_gas(698414)]
    fn test_calculate_luck() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        let bag = ImplBag::new();
        assert(adventurer.equipment.calculate_luck(bag) == 2, 'start with 2 luck');

        // equip a greatness 1 necklace
        let neck = Item { id: ItemId::Amulet, xp: 1 };
        adventurer.equipment.equip_necklace(neck);
        assert(adventurer.equipment.calculate_luck(bag) == 2, 'still 2 luck');

        // equip a greatness 1 ring
        let ring = Item { id: ItemId::GoldRing, xp: 1 };
        adventurer.equipment.equip_ring(ring);
        assert(adventurer.equipment.calculate_luck(bag) == 2, 'still 2 luck');

        // equip a greatness 19 silver ring
        let mut silver_ring = Item { id: ItemId::SilverRing, xp: 399 };
        adventurer.equipment.equip_ring(silver_ring);
        assert(adventurer.equipment.calculate_luck(bag) == 39, 'should be 39 luck');

        // increase silver ring to greatness 20 to unlock extra 20 luck
        adventurer.equipment.ring.xp = 400;
        assert(adventurer.equipment.calculate_luck(bag) == 41, 'should be 41 luck');

        // overflow case
        adventurer.equipment.ring.xp = 65535;
        adventurer.equipment.neck.xp = 65535;
        let _luck = adventurer.equipment.calculate_luck(bag);
        assert(
            adventurer.equipment.calculate_luck(bag) == (ITEM_MAX_GREATNESS * 2)
                + SILVER_RING_G20_LUCK_BONUS,
            'should be 60 luck'
        );
    }

    #[test]
    #[available_gas(177984)]
    fn test_in_battle() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        assert(adventurer.in_battle() == true, 'new advntr start in battle');

        adventurer.beast_health = 0;
        assert(adventurer.in_battle() == false, 'advntr not in battle');

        // overflow check
        adventurer.beast_health = 65535;
        assert(adventurer.in_battle() == true, 'advntr in battle');
    }

    #[test]
    #[available_gas(421224)]
    fn test_is_ambush() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);

        // without any wisdom, should get ambushed by all entropy
        assert(adventurer.is_ambushed(1), 'no wisdom should get ambushed');
        assert(adventurer.is_ambushed(2), 'no wisdom should get ambushed');
        assert(adventurer.is_ambushed(3), 'no wisdom should get ambushed');
        assert(adventurer.is_ambushed(4), 'no wisdom should get ambushed');
        assert(adventurer.is_ambushed(5), 'no wisdom should get ambushed');

        // level 1 adventurer with 1 wisdom should never get ambushed
        adventurer.stats.wisdom = 1;
        assert(!adventurer.is_ambushed(1), 'wise adventurer avoids ambush');
        assert(!adventurer.is_ambushed(2), 'wise adventurer avoids ambush');
        assert(!adventurer.is_ambushed(3), 'wise adventurer avoids ambush');
        assert(!adventurer.is_ambushed(4), 'wise adventurer avoids ambush');
        assert(!adventurer.is_ambushed(5), 'wise adventurer avoids ambush');
        assert(!adventurer.is_ambushed(6), 'wise adventurer avoids ambush');

        // increase adventurer to level 2, now chance is 1/2
        adventurer.xp = 4;
        assert(adventurer.is_ambushed(1), 'should be ambushed 1');
        assert(!adventurer.is_ambushed(2), 'should not be ambushed 2');
        assert(adventurer.is_ambushed(3), 'should be ambushed 3');
        assert(!adventurer.is_ambushed(4), 'should not be ambushed 4');
        assert(adventurer.is_ambushed(5), 'should be ambushed 5');
        assert(!adventurer.is_ambushed(6), 'should not be ambushed 6');
    }

    #[test]
    #[available_gas(3820)]
    fn test_get_gold_discovery_gas() {
        ImplAdventurer::get_gold_discovery(1, 0);
    }

    #[test]
    fn test_get_gold_discovery() {
        let adventurer_level = 1;
        let entropy = 0;
        let gold_discovery = ImplAdventurer::get_gold_discovery(adventurer_level, entropy);
        assert(gold_discovery == 1, 'gold_discovery should be 1');
    }

    #[test]
    #[available_gas(4690)]
    fn test_get_health_discovery_gas() {
        let adventurer_level = 1;
        let entropy = 12345;
        ImplAdventurer::get_health_discovery(adventurer_level, entropy);
    }

    #[test]
    fn test_get_health_discovery() {
        let adventurer_level = 1;
        let entropy = 0;
        let discovery_amount = ImplAdventurer::get_health_discovery(adventurer_level, entropy);
        assert(discovery_amount == 2, 'health discovery should be 2');
    }

    #[test]
    #[available_gas(16210)]
    fn test_get_discovery_gas() {
        let adventurer_level = 1;
        let entropy = 12345;
        ImplAdventurer::get_discovery(adventurer_level, entropy);
    }

    #[test]
    #[available_gas(328654)]
    fn test_get_loot_discovery_gas() {
        let entropy = 0;
        ImplAdventurer::get_loot_discovery(entropy);
    }

    fn is_item_in_set(item_id: u8, ref item_set: Span<u8>) -> bool {
        loop {
            match item_set.pop_front() {
                Option::Some(item) => { if item_id == (*item).into() {
                    break true;
                } },
                Option::None(_) => { break false; }
            };
        }
    }

    #[test]
    fn test_is_item_in_set_found() {
        let mut item_set = array![ItemId::Cap, ItemId::Club, ItemId::Sash];
        let item_id: u8 = ItemId::Club.into();
        let mut item_set_span = item_set.span();
        assert(is_item_in_set(item_id, ref item_set_span), 'Item should be in set');
    }

    #[test]
    fn test_is_item_in_set_not_found() {
        let mut item_set = array![ItemId::Cap, ItemId::Club, ItemId::Sash];
        let item_id: u8 = ItemId::Helm.into();
        let mut item_set_span = item_set.span();
        assert(!is_item_in_set(item_id, ref item_set_span), 'Item should not be in set');
    }

    #[test]
    fn test_is_item_in_set_empty_set() {
        let mut item_set = array![];
        let item_id: u8 = ItemId::Cap.into();
        let mut item_set_span = item_set.span();
        assert(!is_item_in_set(item_id, ref item_set_span), 'Item should not be in empty set');
    }

    #[test]
    fn test_is_item_in_set_single_item_found() {
        let mut item_set = array![ItemId::Cap];
        let item_id: u8 = ItemId::Cap.into();
        let mut item_set_span = item_set.span();
        assert(is_item_in_set(item_id, ref item_set_span), 'Single item should be in set');
    }

    #[test]
    fn test_is_item_in_set_single_item_not_found() {
        let mut item_set = array![ItemId::Cap];
        let item_id: u8 = ItemId::Club.into();
        let mut item_set_span = item_set.span();
        assert(!is_item_in_set(item_id, ref item_set_span), 'Single item should not be set');
    }

    #[test]
    fn test_loot_discovery_distribution() {
        let mut t5_count: u32 = 0;
        let mut t4_count: u32 = 0;
        let mut t3_count: u32 = 0;
        let mut t2_count: u32 = 0;
        let mut t1_count: u32 = 0;

        let mut entropy = 0;
        loop {
            if entropy == 10000 {
                break;
            }

            let mut t5_items = ItemUtils::get_t5_items();
            let mut t4_items = ItemUtils::get_t4_items();
            let mut t3_items = ItemUtils::get_t3_items();
            let mut t2_items = ItemUtils::get_t2_items();
            let mut t1_items = ItemUtils::get_t1_items();
            let mut jewlery_items = ItemUtils::get_jewelry_items();

            let item_id = ImplAdventurer::get_loot_discovery(entropy);

            assert(!is_item_in_set(item_id, ref jewlery_items), 'No finding jewlery');

            if is_item_in_set(item_id, ref t5_items) {
                t5_count += 1;
            } else if is_item_in_set(item_id, ref t4_items) {
                t4_count += 1;
            } else if is_item_in_set(item_id, ref t3_items) {
                t3_count += 1;
            } else if is_item_in_set(item_id, ref t2_items) {
                t2_count += 1;
            } else if is_item_in_set(item_id, ref t1_items) {
                t1_count += 1;
            }

            entropy += 1;
        };

        // assert T5 is greater than T4 is greater than T3 is greater than T2 is greater than T1
        assert(t5_count > t4_count, 'T5 should be more than T4');
        assert(t4_count > t3_count, 'T4 should be more than T3');
        assert(t3_count > t2_count, 'T3 should be more than T2');
        assert(t2_count > t1_count, 'T2 should be more than T1');

        // generate percentages
        let total_count = t5_count + t4_count + t3_count + t2_count + t1_count;
        let t5_percentage = (t5_count * 100) / total_count;
        let t4_percentage = (t4_count * 100) / total_count;
        let t3_percentage = (t3_count * 100) / total_count;
        let t2_percentage = (t2_count * 100) / total_count;
        let t1_percentage = (t1_count * 100) / total_count;

        // verify against hard coded percentages
        assert(t5_percentage == 50, 'wrong t5 percentage');
        assert(t4_percentage == 30, 'wrong t4 percentage');
        assert(t3_percentage == 12, 'wrong t3 percentage');
        assert(t2_percentage == 6, 'wrong t2 percentage');
        assert(t1_percentage == 2, 'wrong t1 percentage');
    }

    #[test]
    fn test_get_random_discovery_distribution() {
        let mut gold_count: u32 = 0;
        let mut health_count: u32 = 0;
        let mut loot_count: u32 = 0;

        let mut adventurer_level = 1;
        let mut entropy = 0;

        loop {
            if adventurer_level == 50 {
                break;
            }

            loop {
                if entropy == 10000 {
                    break;
                }

                let discovery_type = ImplAdventurer::get_discovery(adventurer_level, entropy);

                match discovery_type {
                    DiscoveryType::Gold(_) => { gold_count += 1; },
                    DiscoveryType::Health(_) => { health_count += 1; },
                    DiscoveryType::Loot(_) => { loot_count += 1; }
                }

                entropy += 1;
            };
            adventurer_level += 1;
        };

        // Calculate total count
        let total_count = gold_count + health_count + loot_count;

        // Calculate percentages
        let gold_percentage = (gold_count * 100) / total_count;
        let health_percentage = (health_count * 100) / total_count;
        let loot_percentage = (loot_count * 100) / total_count;

        // Verify percentages
        assert(gold_percentage == 45, 'wrong gold percentage');
        assert(health_percentage == 45, 'wrong health percentage');
        assert(loot_percentage == 10, 'wrong loot percentage');
    }

    #[test]
    #[available_gas(2500)]
    fn test_get_item_gas() {
        let equipment = Equipment {
            weapon: Item { id: 10, xp: 10 },
            chest: Item { id: 20, xp: 20 },
            head: Item { id: 30, xp: 30 },
            waist: Item { id: 40, xp: 40 },
            foot: Item { id: 50, xp: 50 },
            hand: Item { id: 60, xp: 60 },
            neck: Item { id: 70, xp: 70 },
            ring: Item { id: 80, xp: 80 },
        };

        equipment.get_item(1);
    }

    #[test]
    fn test_get_item() {
        let equipment = Equipment {
            weapon: Item { id: ItemId::Katana, xp: 15 },
            chest: Item { id: ItemId::DivineRobe, xp: 25 },
            head: Item { id: ItemId::Crown, xp: 35 },
            waist: Item { id: ItemId::BrightsilkSash, xp: 45 },
            foot: Item { id: ItemId::DivineSlippers, xp: 55 },
            hand: Item { id: ItemId::DivineGloves, xp: 65 },
            neck: Item { id: ItemId::Amulet, xp: 75 },
            ring: Item { id: ItemId::GoldRing, xp: 85 },
        };

        let weapon = equipment.get_item(ItemId::Katana);
        assert(weapon.id == ItemId::Katana, 'wrong weapon id');
        assert(weapon.xp == 15, 'wrong weapon xp');
        assert(ImplLoot::get_slot(weapon.id) == Slot::Weapon, 'wrong weapon slot');

        let chest = equipment.get_item(ItemId::DivineRobe);
        assert(chest.id == ItemId::DivineRobe, 'wrong chest id');
        assert(chest.xp == 25, 'wrong chest xp');
        assert(ImplLoot::get_slot(chest.id) == Slot::Chest, 'wrong chest slot');

        let head = equipment.get_item(ItemId::Crown);
        assert(head.id == ItemId::Crown, 'wrong head id');
        assert(head.xp == 35, 'wrong head xp');
        assert(ImplLoot::get_slot(head.id) == Slot::Head, 'wrong head slot');

        let waist = equipment.get_item(ItemId::BrightsilkSash);
        assert(waist.id == ItemId::BrightsilkSash, 'wrong waist id');
        assert(waist.xp == 45, 'wrong waist xp');
        assert(ImplLoot::get_slot(waist.id) == Slot::Waist, 'wrong waist slot');

        let foot = equipment.get_item(ItemId::DivineSlippers);
        assert(foot.id == ItemId::DivineSlippers, 'wrong foot id');
        assert(foot.xp == 55, 'wrong foot xp');
        assert(ImplLoot::get_slot(foot.id) == Slot::Foot, 'wrong foot slot');

        let hand = equipment.get_item(ItemId::DivineGloves);
        assert(hand.id == ItemId::DivineGloves, 'wrong hand id');
        assert(hand.xp == 65, 'wrong hand xp');
        assert(ImplLoot::get_slot(hand.id) == Slot::Hand, 'wrong hand slot');

        let neck = equipment.get_item(ItemId::Amulet);
        assert(neck.id == ItemId::Amulet, 'wrong neck id');
        assert(neck.xp == 75, 'wrong neck xp');
        assert(ImplLoot::get_slot(neck.id) == Slot::Neck, 'wrong neck slot');

        let ring = equipment.get_item(ItemId::GoldRing);
        assert(ring.id == ItemId::GoldRing, 'wrong ring id');
        assert(ring.xp == 85, 'wrong ring xp');
        assert(ImplLoot::get_slot(ring.id) == Slot::Ring, 'wrong ring slot');
    }

    #[test]
    fn test_get_item_no_match() {
        let equipment = Equipment {
            weapon: Item { id: 10, xp: 10 },
            chest: Item { id: 20, xp: 20 },
            head: Item { id: 30, xp: 30 },
            waist: Item { id: 40, xp: 40 },
            foot: Item { id: 50, xp: 50 },
            hand: Item { id: 60, xp: 60 },
            neck: Item { id: 70, xp: 70 },
            ring: Item { id: 80, xp: 80 },
        };

        assert(equipment.get_item(255).id == 0, 'should be item id 0');
        assert(equipment.get_item(255).xp == 0, 'should be item xp 0');
    }
}
