use core::result::ResultTrait;
use integer::{u8_overflowing_add, u16_overflowing_add, u16_overflowing_sub};
use traits::{TryInto, Into};
use option::OptionTrait;
use poseidon::poseidon_hash_span;
use array::ArrayTrait;

use super::{
    item_meta::{ItemSpecials, ItemSpecialsStorage, ImplItemSpecials}, adventurer_stats::Stats,
    item_primitive::ItemPrimitive, adventurer_utils::{AdventurerUtils}, exploration::ExploreUtils,
    bag::{Bag, IBag, ImplBag},
    constants::{
        adventurer_constants::{
            STARTING_GOLD, StatisticIndex, POTION_PRICE, STARTING_HEALTH, CHARISMA_POTION_DISCOUNT,
            MINIMUM_ITEM_PRICE, MINIMUM_POTION_PRICE, HEALTH_INCREASE_PER_VITALITY, MAX_GOLD,
            MAX_STAT_VALUE, MAX_STAT_UPGRADES, MAX_XP, MAX_ADVENTURER_BLOCKS, ITEM_MAX_GREATNESS,
            ITEM_MAX_XP, MAX_ADVENTURER_HEALTH, CHARISMA_ITEM_DISCOUNT, ClassStatBoosts,
            MAX_BLOCK_COUNT, STAT_UPGRADE_POINTS_PER_LEVEL, NECKLACE_G20_BONUS_STATS,
            SILVER_RING_G20_LUCK_BONUS, BEAST_SPECIAL_NAME_LEVEL_UNLOCK
        },
        discovery_constants::DiscoveryEnums::{ExploreResult, TreasureDiscovery}
    }
};
use pack::{pack::{Packing, rshift_split}, constants::{MASK_16, pow, MASK_8, MASK_BOOL, mask}};
use lootitems::{
    loot::{Loot, ILoot, ImplLoot},
    constants::{ItemSuffix, ItemId, NamePrefixLength, NameSuffixLength}
};
use combat::{
    combat::{ImplCombat, CombatSpec, SpecialPowers}, constants::CombatEnums::{Type, Tier, Slot}
};
use obstacles::obstacle::{ImplObstacle, Obstacle};
use beasts::{beast::{ImplBeast, Beast}, constants::BeastSettings};

#[derive(Drop, Copy, Serde)]
struct Adventurer {
    last_action: u16, // 9 bits
    health: u16, // 9 bits
    xp: u16, // 13 bits
    stats: Stats, // 30 bits
    gold: u16, // 9 bits
    weapon: ItemPrimitive, // 21 bits
    chest: ItemPrimitive, // 21 bits
    head: ItemPrimitive, // 21 bits
    waist: ItemPrimitive, // 21 bits
    foot: ItemPrimitive, // 21 bits
    hand: ItemPrimitive, // 21 bits
    neck: ItemPrimitive, // 21 bits
    ring: ItemPrimitive, // 21 bits
    beast_health: u16, // 9 bits
    stat_points_available: u8, // 3 bits
    mutated: bool, // not packed
}

impl AdventurerPacking of Packing<Adventurer> {
    fn pack(self: Adventurer) -> felt252 {
        (self.last_action.into()
            + self.health.into() * pow::TWO_POW_9
            + self.xp.into() * pow::TWO_POW_18
            + self.stats.pack().into() * pow::TWO_POW_31
            + self.gold.into() * pow::TWO_POW_61
            + self.weapon.pack().into() * pow::TWO_POW_70
            + self.chest.pack().into() * pow::TWO_POW_91
            + self.head.pack().into() * pow::TWO_POW_112
            + self.waist.pack().into() * pow::TWO_POW_133
            + self.foot.pack().into() * pow::TWO_POW_154
            + self.hand.pack().into() * pow::TWO_POW_175
            + self.neck.pack().into() * pow::TWO_POW_196
            + self.ring.pack().into() * pow::TWO_POW_217
            + self.beast_health.into() * pow::TWO_POW_238
            + self.stat_points_available.into() * pow::TWO_POW_247)
            .try_into()
            .expect('pack Adventurer')
    }

    fn unpack(packed: felt252) -> Adventurer {
        let packed = packed.into();
        let (packed, last_action) = rshift_split(packed, pow::TWO_POW_9);
        let (packed, health) = rshift_split(packed, pow::TWO_POW_9);
        let (packed, xp) = rshift_split(packed, pow::TWO_POW_13);
        let (packed, stats) = rshift_split(packed, pow::TWO_POW_30);
        let (packed, gold) = rshift_split(packed, pow::TWO_POW_9);
        let (packed, weapon) = rshift_split(packed, pow::TWO_POW_21);
        let (packed, chest) = rshift_split(packed, pow::TWO_POW_21);
        let (packed, head) = rshift_split(packed, pow::TWO_POW_21);
        let (packed, waist) = rshift_split(packed, pow::TWO_POW_21);
        let (packed, foot) = rshift_split(packed, pow::TWO_POW_21);
        let (packed, hand) = rshift_split(packed, pow::TWO_POW_21);
        let (packed, neck) = rshift_split(packed, pow::TWO_POW_21);
        let (packed, ring) = rshift_split(packed, pow::TWO_POW_21);
        let (packed, beast_health) = rshift_split(packed, pow::TWO_POW_9);
        let (_, stat_points_available) = rshift_split(packed, pow::TWO_POW_3);

        Adventurer {
            last_action: last_action.try_into().expect('unpack Adventurer last_action'),
            health: health.try_into().expect('unpack Adventurer health'),
            xp: xp.try_into().expect('unpack Adventurer xp'),
            stats: Packing::unpack(stats.try_into().expect('unpack Adventurer stats')),
            gold: gold.try_into().expect('unpack Adventurer gold'),
            weapon: Packing::unpack(weapon.try_into().expect('unpack Adventurer weapon')),
            chest: Packing::unpack(chest.try_into().expect('unpack Adventurer chest')),
            head: Packing::unpack(head.try_into().expect('unpack Adventurer head')),
            waist: Packing::unpack(waist.try_into().expect('unpack Adventurer waist')),
            foot: Packing::unpack(foot.try_into().expect('unpack Adventurer foot')),
            hand: Packing::unpack(hand.try_into().expect('unpack Adventurer hand')),
            neck: Packing::unpack(neck.try_into().expect('unpack Adventurer neck')),
            ring: Packing::unpack(ring.try_into().expect('unpack Adventurer ring')),
            beast_health: beast_health.try_into().expect('unpack Adventurer beast_health'),
            stat_points_available: stat_points_available
                .try_into()
                .expect('unpack Adventurer stat_upgrade'),
            mutated: false,
        }
    }

    // TODO: add overflow pack protection
    fn overflow_pack_protection(self: Adventurer) -> Adventurer {
        self
    }
}

#[generate_trait]
impl ImplAdventurer of IAdventurer {
    // create a new adventurer from a starting item and a block number
    // the block number is used to set the last action
    // the starting item is used to set the starting weapon
    // @param starting_item: the id of the starting item
    // @param block_number: the block number of the block that the adventurer was created in
    // @return Adventurer: the new adventurer
    fn new(starting_item: u8, block_number: u64, starting_stats: Stats) -> Adventurer {
        let current_block_modulo_512: u16 = (block_number % MAX_ADVENTURER_BLOCKS.into())
            .try_into()
            .unwrap();

        let mut adventurer = Adventurer {
            last_action: current_block_modulo_512,
            health: STARTING_HEALTH,
            xp: 0,
            stats: Stats {
                strength: starting_stats.strength,
                dexterity: starting_stats.dexterity,
                vitality: starting_stats.vitality,
                intelligence: starting_stats.intelligence,
                wisdom: starting_stats.wisdom,
                charisma: starting_stats.charisma
            },
            gold: STARTING_GOLD,
            weapon: ItemPrimitive { id: starting_item, xp: 0, metadata: 1, },
            chest: ItemPrimitive { id: 0, xp: 0, metadata: 0, },
            head: ItemPrimitive { id: 0, xp: 0, metadata: 0, },
            waist: ItemPrimitive { id: 0, xp: 0, metadata: 0, },
            foot: ItemPrimitive { id: 0, xp: 0, metadata: 0, },
            hand: ItemPrimitive { id: 0, xp: 0, metadata: 0, },
            neck: ItemPrimitive { id: 0, xp: 0, metadata: 0, },
            ring: ItemPrimitive { id: 0, xp: 0, metadata: 0, },
            beast_health: BeastSettings::STARTER_BEAST_HEALTH,
            stat_points_available: 0,
            mutated: false,
        };

        // set adventurers health to max which will compensate for starting for vitality
        adventurer.health = AdventurerUtils::get_max_health(adventurer.stats.vitality);
        adventurer
    }

    // @notice Calculates the charisma potion discount for the adventurer based on their charisma stat.
    // @return The charisma potion discount.
    #[inline(always)]
    fn charisma_potion_discount(self: Adventurer) -> u16 {
        CHARISMA_POTION_DISCOUNT * self.stats.charisma.into()
    }

    // @notice Calculates the charisma item discount for the adventurer based on their charisma stat.
    // @return The charisma item discount.
    #[inline(always)]
    fn charisma_item_discount(self: Adventurer) -> u16 {
        CHARISMA_ITEM_DISCOUNT * self.stats.charisma.into()
    }

    // @notice Gets the item cost for the adventurer after applying any charisma discounts.
    // @param item_cost The original cost of the item.
    // @return The final cost of the item after applying discounts. If the discount exceeds the original cost, returns the MINIMUM_ITEM_PRICE.
    fn charisma_adjusted_item_price(self: Adventurer, item_cost: u16) -> u16 {
        if (u16_overflowing_sub(item_cost, self.charisma_item_discount()).is_ok()) {
            if (item_cost - self.charisma_item_discount() > MINIMUM_ITEM_PRICE) {
                return (item_cost - self.charisma_item_discount());
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
            POTION_PRICE * self.get_level().into(), self.charisma_potion_discount()
        )
            .is_ok()) {
            let potion_price = POTION_PRICE * self.get_level().into()
                - self.charisma_potion_discount();
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
    // @param self: Adventurer to check
    // @param slot: Slot to check
    // @return ItemPrimitive: Item at slot
    #[inline(always)]
    fn get_item_at_slot(self: Adventurer, slot: Slot) -> ItemPrimitive {
        match slot {
            Slot::None(()) => ItemPrimitive { id: 0, xp: 0, metadata: 0 },
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
    #[inline(always)]
    fn is_slot_free(self: Adventurer, item: ItemPrimitive) -> bool {
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

    // Returns the current level of the adventurer based on their XP.
    // @param self: Adventurer to get level for
    // @return The current level of the adventurer.
    #[inline(always)]
    fn get_level(self: Adventurer) -> u8 {
        ImplCombat::get_level_from_xp(self.xp)
    }

    fn get_beast(self: Adventurer, adventurer_entropy: u128) -> (Beast, u128) {
        let beast_seed: u128 = self.get_beast_seed(adventurer_entropy);
        let adventurer_level = self.get_level();

        // @dev ideally this would be a setting but to minimize gas we're using hardcoded value so we can use cheaper equal operator
        if (adventurer_level == 1) {
            (
                ImplBeast::get_starter_beast(ImplLoot::get_type(self.weapon.id), beast_seed),
                beast_seed
            )
        } else {
            let beast_id = ImplBeast::get_beast_id(beast_seed);
            let starting_health = ImplBeast::get_starting_health(adventurer_level, beast_seed);
            let beast_tier = ImplBeast::get_tier(beast_id);
            let beast_type = ImplBeast::get_type(beast_id);
            let beast_level = ImplBeast::get_level(adventurer_level, beast_seed);
            let mut special_names = SpecialPowers { special1: 0, special2: 0, special3: 0 };

            if (beast_level >= BEAST_SPECIAL_NAME_LEVEL_UNLOCK) {
                special_names =
                    ImplBeast::get_special_names(
                        adventurer_level,
                        beast_seed,
                        NamePrefixLength.into(),
                        NameSuffixLength.into()
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
    fn is_ambushed(self: Adventurer, entropy: u128) -> bool {
        !ImplCombat::ability_based_avoid_threat(self.get_level(), self.stats.wisdom, entropy)
    }

    // Attempts to discover treasure during an adventure.
    // The discovered treasure type and amount are determined based on a given entropy.
    // Possible discoveries include gold, XP, and health.
    // @param self: Adventurer to discover treasure for
    // @param entropy: Entropy for generating treasure
    // @return TreasureDiscovery: The type of treasure discovered.
    // @return u16: The amount of treasure discovered.
    fn discover_treasure(self: Adventurer, entropy: u128) -> (TreasureDiscovery, u16) {
        // generate random item discovery
        let item_type = ExploreUtils::get_random_discovery(entropy);

        match item_type {
            TreasureDiscovery::Gold(()) => {
                // return discovery type and amount
                (TreasureDiscovery::Gold(()), ExploreUtils::get_gold_discovery(self, entropy))
            },
            TreasureDiscovery::XP(()) => {
                // return discovery type and amount
                (TreasureDiscovery::XP(()), ExploreUtils::get_xp_discovery(self, entropy))
            },
            TreasureDiscovery::Health(()) => {
                // return discovery type and amount
                (TreasureDiscovery::Health(()), ExploreUtils::get_health_discovery(self, entropy))
            }
        }
    }

    // @notice Calculates the adventurer's luck based on the greatness of their jewelry
    // @dev Adventurer gets luck from three sources:
    //      1. Greatness of equipped jewlery
    //      2. Greatness of bagged jewlery
    //      3. Bonus luck, currently an equipped G20 Silver Ring
    // @param self: Adventurer to calculate luck for
    // @param bag: Bag to calculate luck for
    // @return The adventurer's luck.
    #[inline(always)]
    fn get_luck(self: Adventurer, bag: Bag) -> u8 {
        let equipped_necklace_luck = self.neck.get_greatness();
        let equipped_ring_luck = self.ring.get_greatness();
        let bonus_luck = self.get_bonus_luck();
        let bagged_jewelry_luck = bag.get_jewelry_greatness();
        equipped_necklace_luck + equipped_ring_luck + bonus_luck + bagged_jewelry_luck
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
            if (self.xp + amount <= MAX_XP) {
                // if it is, add xp
                self.xp += amount;
            } else {
                // if amount to add exceeds max xp, set xp to max
                self.xp = MAX_XP;
            }
        } else {
            // if we overflow u16, set xp to max xp
            self.xp = MAX_XP;
        }

        // get the new level
        let new_level = self.get_level();

        // if adventurer reached a new level
        if (new_level > previous_level) {
            // add stat upgrade points
            let stat_upgrade_points = (new_level - previous_level) * STAT_UPGRADE_POINTS_PER_LEVEL;
            self.stat_points_available.increase_stat_points_available(stat_upgrade_points);
        }

        // return the previous and new levels
        (previous_level, new_level)
    }

    // @notice Grants stat upgrades to the Adventurer.
    // @dev The function will add the specified value to the stat_points_available up to the maximum limit of MAX_STAT_UPGRADES.
    // @param value The amount of stat points to be added to the Adventurer.
    fn increase_stat_points_available(ref self: u8, amount: u8) {
        // check for u8 overflow
        if (u8_overflowing_add(self, amount).is_ok()) {
            // if overflow is ok
            // check if added amount is less than or equal to max upgrade points
            if (self + amount <= MAX_STAT_UPGRADES) {
                // if it is, add upgrade points to adventurer and return
                self += amount;
                return;
            }
        }

        // fall through is to return MAX_STAT_UPGRADES
        // this will happen either in a u8 overflow case
        // or if the upgrade points being added exceeds max upgrade points
        self = MAX_STAT_UPGRADES
    }

    // @notice Increase the Adventurer's strength stat.
    // @dev The function will add the specified amount to the strength stat up to the maximum limit of MAX_STAT_VALUE.
    // @param amount The amount to be added to the strength stat.
    #[inline(always)]
    fn increase_strength(ref self: Stats, amount: u8) {
        AdventurerUtils::overflow_protected_stat_increase(ref self.strength, amount)
    }

    // @notice Increase the Adventurer's dexterity stat.
    // @dev The function will add the specified amount to the dexterity stat up to the maximum limit of MAX_STAT_VALUE.
    // @param amount The amount to be added to the dexterity stat.
    #[inline(always)]
    fn increase_dexterity(ref self: Stats, amount: u8) {
        AdventurerUtils::overflow_protected_stat_increase(ref self.dexterity, amount)
    }

    // @notice Increase the Adventurer's vitality stat.
    // @dev The function will add the specified amount to the vitality stat up to the maximum limit of MAX_STAT_VALUE.
    // @param amount The amount to be added to the vitality stat.
    #[inline(always)]
    fn increase_vitality(ref self: Stats, amount: u8) {
        AdventurerUtils::overflow_protected_stat_increase(ref self.vitality, amount)
    }

    // @notice Increase the Adventurer's intelligence stat.
    // @dev The function will add the specified amount to the intelligence stat up to the maximum limit of MAX_STAT_VALUE.
    // @param amount The amount to be added to the intelligence stat.
    #[inline(always)]
    fn increase_intelligence(ref self: Stats, amount: u8) {
        AdventurerUtils::overflow_protected_stat_increase(ref self.intelligence, amount)
    }

    // @notice Increase the Adventurer's wisdom stat.
    // @dev The function will add the specified amount to the wisdom stat up to the maximum limit of MAX_STAT_VALUE.
    // @param amount The amount to be added to the wisdom stat.
    #[inline(always)]
    fn increase_wisdom(ref self: Stats, amount: u8) {
        AdventurerUtils::overflow_protected_stat_increase(ref self.wisdom, amount)
    }

    // @notice Increase the Adventurer's charisma stat.
    // @dev The function will add the specified amount to the charisma stat up to the maximum limit of MAX_STAT_VALUE.
    // @param amount The amount to be added to the charisma stat.
    #[inline(always)]
    fn increase_charisma(ref self: Stats, amount: u8) {
        AdventurerUtils::overflow_protected_stat_increase(ref self.charisma, amount)
    }

    // @notice Decrease the Adventurer's strength stat.
    // @dev The function will subtract the specified amount from the strength stat without allowing it to fall below 0.
    // @param amount The amount to be subtracted from the strength stat.
    #[inline(always)]
    fn decrease_strength(ref self: Stats, amount: u8) {
        // underflow protection
        if amount > self.strength {
            self.strength = 0;
        } else {
            self.strength -= amount;
        }
    }

    // @notice Decrease the Adventurer's dexterity stat.
    // @dev The function will subtract the specified amount from the dexterity stat without allowing it to fall below 0.
    // @param amount The amount to be deducted from the dexterity stat.
    #[inline(always)]
    fn decrease_dexterity(ref self: Stats, amount: u8) {
        // underflow protection
        if amount > self.dexterity {
            self.dexterity = 0;
        } else {
            self.dexterity -= amount;
        }
    }

    // @notice Decrease the Adventurer's vitality stat.
    // @dev The function will subtract the specified amount from the vitality stat without allowing it to fall below 0.
    // @param amount The amount to be deducted from the vitality stat.
    #[inline(always)]
    fn decrease_vitality(ref self: Stats, amount: u8) {
        // underflow protection
        if amount > self.vitality {
            self.vitality = 0;
        } else {
            self.vitality -= amount;
        }
    }

    // @notice Decrease the Adventurer's intelligence stat.
    // @dev The function will subtract the specified amount from the intelligence stat without allowing it to fall below 0.
    // @param amount The amount to be deducted from the intelligence stat.
    #[inline(always)]
    fn decrease_intelligence(ref self: Stats, amount: u8) {
        // underflow protection
        if amount > self.intelligence {
            self.intelligence = 0;
        } else {
            self.intelligence -= amount;
        }
    }

    // @notice Decrease the Adventurer's wisdom stat.
    // @dev The function will subtract the specified amount from the wisdom stat without allowing it to fall below 0.
    // @param amount The amount to be deducted from the wisdom stat.
    #[inline(always)]
    fn decrease_wisdom(ref self: Stats, amount: u8) {
        // underflow protection
        if amount > self.wisdom {
            self.wisdom = 0;
        } else {
            self.wisdom -= amount;
        }
    }

    // @notice Decrease the Adventurer's charisma stat.
    // @dev The function will subtract the specified amount from the charisma stat without allowing it to fall below 0.
    // @param amount The amount to be deducted from the charisma stat.
    #[inline(always)]
    fn decrease_charisma(ref self: Stats, amount: u8) {
        // underflow protection
        if amount > self.charisma {
            self.charisma = 0;
        } else {
            self.charisma -= amount;
        }
    }

    // @notice Adds an item to the adventurer's equipment.
    // @dev The type of the item determines which equipment slot it goes into.
    // @param item The item to be added to the adventurer's equipment.
    #[inline(always)]
    fn equip_item(ref self: Adventurer, item: ItemPrimitive) {
        let slot = ImplLoot::get_slot(item.id);
        match slot {
            Slot::None(()) => (),
            Slot::Weapon(()) => self.equip_weapon(item),
            Slot::Chest(()) => self.equip_chest_armor(item),
            Slot::Head(()) => self.equip_head_armor(item),
            Slot::Waist(()) => self.equip_waist_armor(item),
            Slot::Foot(()) => self.equip_foot_armor(item),
            Slot::Hand(()) => self.equip_hand_armor(item),
            Slot::Neck(()) => self.equip_necklace(item),
            Slot::Ring(()) => self.equip_ring(item),
        }
    }

    // @dev This function allows an adventurer to drop an item they have equipped.
    // @notice The function only works if the item is currently equipped by the adventurer. It removes the item from the adventurer's equipment and replaces it with a blank item.
    // @param item_id The ID of the item to be dropped. The function will assert if the item is not currently equipped.
    #[inline(always)]
    fn drop_item(ref self: Adventurer, item_id: u8) {
        if self.weapon.id == item_id {
            self.weapon.id = 0;
            self.weapon.xp = 0;
        } else if self.chest.id == item_id {
            self.chest.id = 0;
            self.chest.xp = 0;
        } else if self.head.id == item_id {
            self.head.id = 0;
            self.head.xp = 0;
        } else if self.waist.id == item_id {
            self.waist.id = 0;
            self.waist.xp = 0;
        } else if self.foot.id == item_id {
            self.foot.id = 0;
            self.foot.xp = 0;
        } else if self.hand.id == item_id {
            self.hand.id = 0;
            self.hand.xp = 0;
        } else if self.neck.id == item_id {
            self.neck.id = 0;
            self.neck.xp = 0;
        } else if self.ring.id == item_id {
            self.ring.id = 0;
            self.ring.xp = 0;
        } else {
            panic_with_felt252('item is not equipped')
        }

        // flag adventurer as mutated
        self.mutated = true;
    }

    // @dev This function checks if the adventurer has a given item equipped
    // @param item_id The id of the item to check
    // @return A boolean indicating if the item is equipped by the adventurer. Returns true if the item is equipped, false otherwise.
    #[inline(always)]
    fn is_equipped(self: Adventurer, item_id: u8) -> bool {
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

    // @notice Equips the adventurer with a weapon. 
    // @dev The function asserts that the given item is a weapon before adding it to the adventurer's weapon slot.
    // @param item The weapon to be added to the adventurer's equipment.
    #[inline(always)]
    fn equip_weapon(ref self: Adventurer, item: ItemPrimitive) {
        // TODO: use configuration compilation to assert that the item is a weapon during development
        // but not in production so we don't waste gas on this check see https://docs.swmansion.com/scarb/docs/reference/conditional-compilation.html
        //assert(ImplLoot::get_slot(item.id) == Slot::Weapon(()), 'Item is not weapon');
        self.weapon = item
    }

    // @notice Equips the adventurer with a chest armor. 
    // @dev The function asserts that the given item is a chest armor before adding it to the adventurer's chest slot.
    // @param item The chest armor to be added to the adventurer's equipment.
    #[inline(always)]
    fn equip_chest_armor(ref self: Adventurer, item: ItemPrimitive) {
        // TODO: use configuration compilation to assert that the item is a weapon during development
        // but not in production so we don't waste gas on this check see https://docs.swmansion.com/scarb/docs/reference/conditional-compilation.html
        //assert(ImplLoot::get_slot(item.id) == Slot::Chest(()), 'Item is not chest armor');
        self.chest = item
    }

    // @notice Equips the adventurer with a head armor. 
    // @dev The function asserts that the given item is a head armor before adding it to the adventurer's head slot.
    // @param item The head armor to be added to the adventurer's equipment.
    #[inline(always)]
    fn equip_head_armor(ref self: Adventurer, item: ItemPrimitive) {
        // TODO: use configuration compilation to assert that the item is a weapon during development
        // but not in production so we don't waste gas on this check see https://docs.swmansion.com/scarb/docs/reference/conditional-compilation.html
        //assert(ImplLoot::get_slot(item.id) == Slot::Head(()), 'Item is not head armor');
        self.head = item
    }

    // @notice Equips the adventurer with a waist armor. 
    // @dev The function asserts that the given item is a waist armor before adding it to the adventurer's waist slot.
    // @param item The waist armor to be added to the adventurer's equipment.
    #[inline(always)]
    fn equip_waist_armor(ref self: Adventurer, item: ItemPrimitive) {
        // TODO: use configuration compilation to assert that the item is a weapon during development
        // but not in production so we don't waste gas on this check see https://docs.swmansion.com/scarb/docs/reference/conditional-compilation.html
        //assert(ImplLoot::get_slot(item.id) == Slot::Waist(()), 'Item is not waist armor');
        self.waist = item
    }

    // @notice Equips the adventurer with a foot armor. 
    // @dev The function asserts that the given item is a foot armor before adding it to the adventurer's foot slot.
    // @param item The foot armor to be added to the adventurer's equipment.
    #[inline(always)]
    fn equip_foot_armor(ref self: Adventurer, item: ItemPrimitive) {
        // TODO: use configuration compilation to assert that the item is a weapon during development
        // but not in production so we don't waste gas on this check see https://docs.swmansion.com/scarb/docs/reference/conditional-compilation.html
        //assert(ImplLoot::get_slot(item.id) == Slot::Foot(()), 'Item is not foot armor');
        self.foot = item
    }

    // @notice Equips the adventurer with a hand armor. 
    // @dev The function asserts that the given item is a hand armor before adding it to the adventurer's hand slot.
    // @param item The hand armor to be added to the adventurer's equipment.
    #[inline(always)]
    fn equip_hand_armor(ref self: Adventurer, item: ItemPrimitive) {
        // TODO: use configuration compilation to assert that the item is a weapon during development
        // but not in production so we don't waste gas on this check see https://docs.swmansion.com/scarb/docs/reference/conditional-compilation.html
        //assert(ImplLoot::get_slot(item.id) == Slot::Hand(()), 'Item is not hand armor');
        self.hand = item
    }

    // @notice Equips the adventurer with a necklace. 
    // @dev The function asserts that the given item is a necklace before adding it to the adventurer's neck slot.
    // @param item The necklace to be added to the adventurer's equipment.
    #[inline(always)]
    fn equip_necklace(ref self: Adventurer, item: ItemPrimitive) {
        // TODO: use configuration compilation to assert that the item is a weapon during development
        // but not in production so we don't waste gas on this check see https://docs.swmansion.com/scarb/docs/reference/conditional-compilation.html
        //assert(ImplLoot::get_slot(item.id) == Slot::Neck(()), 'Item is not necklace');
        self.neck = item
    }

    // @notice Equips the adventurer with a ring. 
    // @dev The function asserts that the given item is a ring before adding it to the adventurer's ring slot.
    // @param item The ring to be added to the adventurer's equipment.
    #[inline(always)]
    fn equip_ring(ref self: Adventurer, item: ItemPrimitive) {
        // TODO: use configuration compilation to assert that the item is a weapon during development
        // but not in production so we don't waste gas on this check see https://docs.swmansion.com/scarb/docs/reference/conditional-compilation.html
        //assert(ImplLoot::get_slot(item.id) == Slot::Ring(()), 'Item is not a ring');
        self.ring = item;
    }


    #[inline(always)]
    fn increase_xp(ref self: ItemPrimitive, amount: u16) -> (u8, u8) {
        let previous_level = self.get_greatness();
        if (u16_overflowing_add(self.xp, amount).is_ok()) {
            if (self.xp + amount > ITEM_MAX_XP) {
                self.xp = ITEM_MAX_XP;
            } else {
                self.xp += amount;
            }
        } else {
            self.xp = ITEM_MAX_XP;
        }
        let new_level = self.get_greatness();
        (previous_level, new_level)
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
        } else if (previous_level < 15 && new_level >= 15) {
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

    /// @notice Applies specials to an item.
    /// @param self The primitive item data.
    /// @param name_storage Reference to the item specials storage which will be updated
    /// @param suffix_unlocked Flag indicating if the suffix is unlocked.
    /// @param prefixes_unlocked Flag indicating if the prefixes are unlocked.
    /// @param entropy Randomness input for generating item specials.
    /// @return ItemSpecials instance with applied specials.
    fn apply_specials(
        self: ItemPrimitive,
        ref name_storage: ItemSpecialsStorage,
        suffix_unlocked: bool,
        prefixes_unlocked: bool,
        entropy: u128
    ) -> ItemSpecials {
        if (suffix_unlocked && prefixes_unlocked) {
            return self.apply_suffix_and_prefixes(ref name_storage, entropy);
        } else if (suffix_unlocked) {
            return self.apply_suffix(ref name_storage, entropy);
        } else if (prefixes_unlocked) {
            return self.apply_prefixes(ref name_storage, entropy);
        } else {
            panic_with_felt252('no specials unlocked')
        }
    }

    // @notice Applies suffix and prefixes to an item
    // @param self The primitive item data.
    // @param name_storage Reference to the item specials storage.
    // @param entropy Randomness input for generating item specials.
    // @return ItemSpecials instance with applied specials.
    fn apply_suffix_and_prefixes(
        self: ItemPrimitive, ref name_storage: ItemSpecialsStorage, entropy: u128
    ) -> ItemSpecials {
        // get rnd for specials
        let (specials_rnd1, special_rnd2) = AdventurerUtils::generate_item_special_entropy(
            entropy, self.id
        );

        // generate special names
        let specials = ItemSpecials {
            special1: ImplLoot::get_special1(self.id, specials_rnd1),
            special2: ImplLoot::generate_prefix1(self.id, special_rnd2),
            special3: ImplLoot::generate_prefix2(self.id, specials_rnd1)
        };

        // set specials in storage
        name_storage.set_specials(self, specials);

        // return specials
        specials
    }

    // @notice Applies suffix to an item.
    // @param self The primitive item data.
    // @param name_storage Reference to the item specials storage.
    // @param entropy Randomness input for generating the item suffix.
    // @return ItemSpecials instance with applied suffix.
    fn apply_suffix(
        self: ItemPrimitive, ref name_storage: ItemSpecialsStorage, entropy: u128
    ) -> ItemSpecials {
        // get rnd for specials
        let (specials_rnd1, _) = AdventurerUtils::generate_item_special_entropy(entropy, self.id);

        // generate special names
        let specials = ItemSpecials {
            special1: ImplLoot::get_special1(self.id, specials_rnd1), // set item suffix
            special2: 0,
            special3: 0,
        };

        // set specials in storage
        name_storage.set_specials(self, specials);

        // return specials
        specials
    }

    // @dev Apply only the prefixes to an item while preserving any existing suffix.
    // @param self The primitive item data.
    // @param name_storage Reference to the item specials storage.
    // @param entropy Randomness input for generating the item prefixes.
    // @return ItemSpecials instance with applied prefixes.
    fn apply_prefixes(
        self: ItemPrimitive, ref name_storage: ItemSpecialsStorage, entropy: u128
    ) -> ItemSpecials {
        // get rnd for specials
        let (specials_rnd1, specials_rnd2) = AdventurerUtils::generate_item_special_entropy(
            entropy, self.id
        );
        // generate prefixes while preserving existing suffix
        let specials = ItemSpecials {
            special1: name_storage.get_specials(self).special1,
            special2: ImplLoot::generate_prefix1(self.id, specials_rnd1),
            special3: ImplLoot::generate_prefix2(self.id, specials_rnd2),
        };

        // set specials in storage
        ImplItemSpecials::set_specials(ref name_storage, self, specials);

        // return specials
        specials
    }

    // @notice get_beast_seed provides an entropy source that is fixed during battle
    // it intentionally does not use global_entropy as that could change during battle and this
    // entropy allows us to simulate a persistent battle without having to store beast
    // details on-chain.
    // @param self A reference to the Adventurer object which represents the adventurer.
    // @param adventurer_entropy A number used for randomization.
    // @return Returns a number used for generated a random beast.
    fn get_beast_seed(self: Adventurer, adventurer_entropy: u128) -> u128 {
        if self.get_level() > 1 {
            let mut hash_span = ArrayTrait::new();
            hash_span.append(self.xp.into());
            hash_span.append(self.gold.into());
            hash_span.append(adventurer_entropy.into());
            let poseidon = poseidon_hash_span(hash_span.span());
            let (d, r) = rshift_split(poseidon.into(), 340282366920938463463374607431768211455);
            r.try_into().unwrap()
        } else {
            0
        }
    }

    // @notice This function adds a boost to an adventurer's attributes based on a provided suffix.
    // Each suffix corresponds to a unique combination of attribute enhancements.
    //
    // The following enhancements are available:
    // - of_Power: Increases the adventurer's Strength by 3 points.
    // - of_Giant: Increases the adventurer's Vitality by 3 points.
    // - of_Titans: Increases the adventurer's Strength by 2 points and Charisma by 1 point.
    // - of_Skill: Increases the adventurer's Dexterity by 3 points.
    // - of_Perfection: Increases the adventurer's Strength, Dexterity, and Vitality by 1 point each.
    // - of_Brilliance: Increases the adventurer's Intelligence by 3 points.
    // - of_Enlightenment: Increases the adventurer's Wisdom by 3 points.
    // - of_Protection: Increases the adventurer's Vitality by 2 points and Dexterity by 1 point.
    // - of_Anger: Increases the adventurer's Strength by 2 points and Dexterity by 1 point.
    // - of_Rage: Increases the adventurer's Strength, Charisma, and Wisdom by 1 point each.
    // - of_Fury: Increases the adventurer's Vitality, Charisma, and Intelligence by 1 point each.
    // - of_Vitriol: Increases the adventurer's Intelligence by 2 points and Wisdom by 1 point.
    // - of_the_Fox: Increases the adventurer's Dexterity by 2 points and Charisma by 1 point.
    // - of_Detection: Increases the adventurer's Wisdom by 2 points and Dexterity by 1 point.
    // - of_Reflection: Increases the adventurer's Intelligence by 1 point and Wisdom by 2 points.
    // - of_the_Twins: Increases the adventurer's Charisma by 3 points.
    //
    // @param self A mutable reference to the Adventurer Stats on which the function operates.
    // @param suffix A u8 value representing the suffix tied to the attribute enhancement.
    fn apply_suffix_boost(ref self: Stats, suffix: u8) {
        if (suffix == ItemSuffix::of_Power) {
            self.increase_strength(3);
        } else if (suffix == ItemSuffix::of_Giant) {
            self.increase_vitality(3);
        } else if (suffix == ItemSuffix::of_Titans) {
            self.increase_strength(2);
            self.increase_charisma(1);
        } else if (suffix == ItemSuffix::of_Skill) {
            self.increase_dexterity(3);
        } else if (suffix == ItemSuffix::of_Perfection) {
            self.increase_strength(1);
            self.increase_dexterity(1);
            self.increase_vitality(1);
        } else if (suffix == ItemSuffix::of_Brilliance) {
            self.increase_intelligence(3);
        } else if (suffix == ItemSuffix::of_Enlightenment) {
            self.increase_wisdom(3);
        } else if (suffix == ItemSuffix::of_Protection) {
            self.increase_vitality(2);
            self.increase_dexterity(1);
        } else if (suffix == ItemSuffix::of_Anger) {
            self.increase_strength(2);
            self.increase_dexterity(1);
        } else if (suffix == ItemSuffix::of_Rage) {
            self.increase_strength(1);
            self.increase_charisma(1);
            self.increase_wisdom(1);
        } else if (suffix == ItemSuffix::of_Fury) {
            self.increase_vitality(1);
            self.increase_charisma(1);
            self.increase_intelligence(1);
        } else if (suffix == ItemSuffix::of_Vitriol) {
            self.increase_intelligence(2);
            self.increase_wisdom(1);
        } else if (suffix == ItemSuffix::of_the_Fox) {
            self.increase_dexterity(2);
            self.increase_charisma(1);
        } else if (suffix == ItemSuffix::of_Detection) {
            self.increase_wisdom(2);
            self.increase_dexterity(1);
        } else if (suffix == ItemSuffix::of_Reflection) {
            self.increase_intelligence(1);
            self.increase_wisdom(2);
        } else if (suffix == ItemSuffix::of_the_Twins) {
            self.increase_charisma(3);
        }
    }

    // @notice Removes a specified suffix boost from an adventurer's stats.
    // @param self The instance of the Stats struct which contains the adventurer's stats.
    // @param suffix The suffix to be removed from the adventurer's stats.
    fn remove_suffix_boost(ref self: Adventurer, suffix: u8) {
        if (suffix == ItemSuffix::of_Power) {
            self.stats.decrease_strength(3);
        } else if (suffix == ItemSuffix::of_Giant) {
            self.stats.decrease_vitality(3);
        } else if (suffix == ItemSuffix::of_Titans) {
            self.stats.decrease_strength(2);
            self.stats.decrease_vitality(1);
        } else if (suffix == ItemSuffix::of_Skill) {
            self.stats.decrease_dexterity(3);
        } else if (suffix == ItemSuffix::of_Perfection) {
            self.stats.decrease_strength(1);
            self.stats.decrease_dexterity(1);
            self.stats.decrease_vitality(1);
        } else if (suffix == ItemSuffix::of_Brilliance) {
            self.stats.decrease_vitality(3);
        } else if (suffix == ItemSuffix::of_Enlightenment) {
            self.stats.decrease_vitality(3);
        } else if (suffix == ItemSuffix::of_Protection) {
            self.stats.decrease_vitality(2);
            self.stats.decrease_dexterity(1);
        } else if (suffix == ItemSuffix::of_Anger) {
            self.stats.decrease_strength(2);
            self.stats.decrease_dexterity(1);
        } else if (suffix == ItemSuffix::of_Rage) {
            self.stats.decrease_strength(1);
            self.stats.decrease_vitality(1);
            self.stats.decrease_vitality(1);
        } else if (suffix == ItemSuffix::of_Fury) {
            self.stats.decrease_vitality(1);
            self.stats.decrease_vitality(1);
            self.stats.decrease_vitality(1);
        } else if (suffix == ItemSuffix::of_Vitriol) {
            self.stats.decrease_vitality(2);
            self.stats.decrease_vitality(1);
        } else if (suffix == ItemSuffix::of_the_Fox) {
            self.stats.decrease_dexterity(2);
            self.stats.decrease_vitality(1);
        } else if (suffix == ItemSuffix::of_Detection) {
            self.stats.decrease_vitality(2);
            self.stats.decrease_dexterity(1);
        } else if (suffix == ItemSuffix::of_Reflection) {
            self.stats.decrease_vitality(1);
            self.stats.decrease_vitality(2);
        } else if (suffix == ItemSuffix::of_the_Twins) {
            self.stats.decrease_vitality(3);
        }
    }

    // @notice checks if the adventurer has any items with special names.
    // @param self The Adventurer to check for item specials.
    // @return Returns true if adventurer has item specials, false otherwise.
    fn has_item_specials(self: Adventurer) -> bool {
        if (self.weapon.get_greatness() >= 15) {
            true
        } else if (self.chest.get_greatness() >= 15) {
            true
        } else if (self.head.get_greatness() >= 15) {
            true
        } else if (self.waist.get_greatness() >= 15) {
            true
        } else if (self.foot.get_greatness() >= 15) {
            true
        } else if (self.hand.get_greatness() >= 15) {
            true
        } else if (self.neck.get_greatness() >= 15) {
            true
        } else if (self.ring.get_greatness() >= 15) {
            true
        } else {
            false
        }
    }

    // @notice applies stat boosts to adventurer
    // @param self The Adventurer to apply stat boosts to.
    // @param stat_boosts The stat boosts to apply to the adventurer.
    // @dev overflow protection is handled further up the stack
    #[inline(always)]
    fn apply_stat_boosts(ref self: Adventurer, stat_boosts: Stats) {
        self.stats.increase_strength(stat_boosts.strength);
        self.stats.increase_dexterity(stat_boosts.dexterity);
        self.stats.increase_vitality(stat_boosts.vitality);
        self.stats.increase_charisma(stat_boosts.charisma);
        self.stats.increase_intelligence(stat_boosts.intelligence);
        self.stats.increase_wisdom(stat_boosts.wisdom);
    }

    // @notice removes stat boosts from adventurer
    // @param self The Adventurer to remove stat boosts from.
    // @param stat_boosts The stat boosts to remove from the adventurer.
    // @dev underflow protection is handled further up the stack
    #[inline(always)]
    fn remove_stat_boosts(ref self: Adventurer, stat_boosts: Stats) {
        self.stats.decrease_strength(stat_boosts.strength);
        self.stats.decrease_dexterity(stat_boosts.dexterity);
        self.stats.decrease_vitality(stat_boosts.vitality);
        self.stats.decrease_charisma(stat_boosts.charisma);
        self.stats.decrease_intelligence(stat_boosts.intelligence);
        self.stats.decrease_wisdom(stat_boosts.wisdom);
    }

    // @notice gets stat boosts based on item specials
    // @param self The Adventurer to get stat boosts for.
    // @param name_storage1 The first ItemSpecialsStorage to use for getting item specials.
    // @param name_storage2 The second ItemSpecialsStorage to use for getting item specials.
    // @return Returns the stat boosts for the adventurer.
    fn get_stat_boosts(
        self: Adventurer, name_storage1: ItemSpecialsStorage, name_storage2: ItemSpecialsStorage
    ) -> Stats {
        let mut stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, charisma: 0, intelligence: 0, wisdom: 0,
        };

        if (self.weapon.get_greatness() >= 15) {
            stats
                .apply_suffix_boost(
                    ImplItemSpecials::get_specials_full(name_storage1, name_storage2, self.weapon)
                        .special1
                );
        }
        if (self.chest.get_greatness() >= 15) {
            stats
                .apply_suffix_boost(
                    ImplItemSpecials::get_specials_full(name_storage1, name_storage2, self.chest)
                        .special1
                );
        }
        if (self.head.get_greatness() >= 15) {
            stats
                .apply_suffix_boost(
                    ImplItemSpecials::get_specials_full(name_storage1, name_storage2, self.head)
                        .special1
                );
        }
        if (self.waist.get_greatness() >= 15) {
            stats
                .apply_suffix_boost(
                    ImplItemSpecials::get_specials_full(name_storage1, name_storage2, self.waist)
                        .special1
                );
        }

        if (self.foot.get_greatness() >= 15) {
            stats
                .apply_suffix_boost(
                    ImplItemSpecials::get_specials_full(name_storage1, name_storage2, self.foot)
                        .special1
                );
        }

        if (self.hand.get_greatness() >= 15) {
            stats
                .apply_suffix_boost(
                    ImplItemSpecials::get_specials_full(name_storage1, name_storage2, self.hand)
                        .special1
                );
        }

        if (self.neck.get_greatness() >= 15) {
            stats
                .apply_suffix_boost(
                    ImplItemSpecials::get_specials_full(name_storage1, name_storage2, self.neck)
                        .special1
                );
        }

        if (self.ring.get_greatness() >= 15) {
            stats
                .apply_suffix_boost(
                    ImplItemSpecials::get_specials_full(name_storage1, name_storage2, self.ring)
                        .special1
                );
        }
        stats
    }

    // @notice The `get_storage_index` function is a helper function that determines the storage index based on the metadata ID.
    // @param meta_data_id The ID of the metadata. 
    // @return Returns 0 if the metadata ID is less than or equal to 10, otherwise returns 1.
    #[inline(always)]
    fn get_storage_index(meta_data_id: u8) -> u256 {
        if (meta_data_id <= 10) {
            0
        } else {
            1
        }
    }

    // @notice The `get_idle_blocks` function calculates the number of idle blocks by subtracting the last action from the 
    // current block (modulo 512). 
    // @param self A reference to the Adventurer instance.
    // @param current_block The current block number.
    // @return Returns the number of idle blocks.
    #[inline(always)]
    fn get_idle_blocks(self: Adventurer, current_block: u64) -> u16 {
        // adventurer only has 9 bits of storage for block numbers
        // the last_action on the adventurer is 0-511 which is based on 
        // the current starknet block % 512. As such, when calculating the number Of
        // idle blocks, we need to % 512 the current block
        let current_block_modulo_512: u16 = (current_block % MAX_ADVENTURER_BLOCKS.into())
            .try_into()
            .unwrap();

        // if the current block is greater than or equal to the last last_action
        if (current_block_modulo_512 >= self.last_action) {
            // we can just subtract the two to get idle blocks
            current_block_modulo_512 - self.last_action
        } else {
            // otherwise we need to add the two and subtract 512
            MAX_ADVENTURER_BLOCKS - self.last_action + current_block_modulo_512
        }
    }

    // @notice gets the greatness of an item
    // @param self the ItemPrimitive to get the greatness of
    // @return u8: the greatness of the item
    #[inline(always)]
    fn get_greatness(self: ItemPrimitive) -> u8 {
        let level = ImplCombat::get_level_from_xp(self.xp);
        if level > ITEM_MAX_GREATNESS {
            ITEM_MAX_GREATNESS
        } else {
            level
        }
    }

    // @notice: last_action.set_last_action sets the last action on the adventurer to the current block
    // @dev: we only have 9 bits of storage for block numbers so we need to modulo the current block
    // @dev: by 512 to ensure we don't overflow the storage
    // @param self A reference to the Adventurer instance.
    // @param current_block The current block number.
    #[inline(always)]
    fn set_last_action(ref self: u16, current_block: u64) {
        self = (current_block % MAX_BLOCK_COUNT).try_into().unwrap();
    }

    // @notice gets a multplier bonus for discoveries based on the Adventurer
    // @dev Equipped Platinum Ring provides 2x and then 4x gold at greatness 20
    //      if no platinum ring is equipped, the gold multiplier is 1x
    // @param self: The Adventurer to get the gold multplier for
    // @return u8: the gold multiplier 
    #[inline(always)]
    fn discovery_bonus_multplier(self: Adventurer) -> u8 {
        if (self.ring.id == ItemId::PlatinumRing) {
            if (self.ring.get_greatness() == 20) {
                return 4;
            } else {
                return 2;
            }
        }
        return 1;
    }

    // @notice gets gold multplier bonus when discovering an obstacle
    // @dev Equipped TItanium Ring provides 1x and then 2x gold at greatness 20
    //      if no titanium ring is equipped, the gold multiplier is 0x
    // @param self: The Adventurer to get the gold multplier for
    // @return u8: the gold multiplier
    #[inline(always)]
    fn obstacle_gold_reward_multplier(self: Adventurer) -> u8 {
        if (self.ring.id == ItemId::TitaniumRing) {
            if (self.ring.get_greatness() == 20) {
                return 2;
            } else {
                return 1;
            }
        }
        return 0;
    }

    // @notice gets luck bonus for an item
    // @dev this is currently used for the silver ring which grants +20 luck at greatness 20
    // @param the Adventurer to check if it qualifies for bonus luck
    // @return u8 the luck bonus, 0 if none
    #[inline(always)]
    fn get_bonus_luck(self: Adventurer) -> u8 {
        if (self.ring.id == ItemId::SilverRing) {
            if (self.ring.get_greatness() == 20) {
                return SILVER_RING_G20_LUCK_BONUS;
            }
        }
        return 0;
    }

    // @notice returns the gold multplier bonus when defeating a beast
    // @dev Equipped Gold Ring provides 2x and then 4x gold at greatness 20
    //      if no gold ring is equipped, the gold multiplier is 1x
    // @param self: The Adventurer to get the gold multplier for
    // @return u8: the gold multiplier
    #[inline(always)]
    fn beast_gold_reward_multiplier(self: Adventurer) -> u8 {
        if (self.ring.id == ItemId::GoldRing) {
            if (self.ring.get_greatness() == 20) {
                return 4;
            } else {
                return 2;
            }
        }

        return 1;
    }

    // @notice checks if adventurer has double critical hit ability unlocked
    // @dev unlock is an equipped Pendant with greatness 20
    // @param adventurer the Adventurer to check if double critical hit is unlocked
    // @return u8 the critical hit bonus multplier
    #[inline(always)]
    fn critical_hit_bonus_multiplier(self: Adventurer) -> u8 {
        if (self.neck.id == ItemId::Pendant && self.neck.get_greatness() == 20) {
            2
        } else {
            1
        }
    }

    // @notice gets armor defense bonus multiplier for the adventurer
    // @players  Equipped Amulet with greatness 20 grants 2x armor defense, otherwise 1
    // @param adventurer the Adventurer to check if double armor defense is unlocked
    // @return u8 the armor defense bonus multiplier
    #[inline(always)]
    fn armor_bonus_multiplier(self: Adventurer) -> u8 {
        if (self.neck.id == ItemId::Amulet && self.neck.get_greatness() == 20) {
            2
        } else {
            1
        }
    }

    // @notice checks if adventurer has double special name damage ability unlocked
    // @dev unlock is an equipped Necklace with greatness 20
    // @param adventurer the Adventurer to check if double special name damage is unlocked
    // @return bool: true if double special name damage is unlocked, false otherwise
    #[inline(always)]
    fn name_match_bonus_damage_multiplier(self: Adventurer) -> u8 {
        if (self.neck.id == ItemId::Necklace && self.neck.get_greatness() == 20) {
            2
        } else {
            1
        }
    }

    // @notice increases the xp of an item at a given slot
    // @param self the Adventurer to increase item xp for
    // @param slot the Slot to increase item xp for
    // @param amount the amount of xp to increase the item by
    // @return (u8, u8): a tuple containing the previous and new level of the item
    fn increase_item_xp_at_slot(ref self: Adventurer, slot: Slot, amount: u16) -> (u8, u8) {
        match slot {
            Slot::None(()) => (0, 0),
            Slot::Weapon(()) => self.weapon.increase_xp(amount),
            Slot::Chest(()) => self.chest.increase_xp(amount),
            Slot::Head(()) => self.head.increase_xp(amount),
            Slot::Waist(()) => self.waist.increase_xp(amount),
            Slot::Foot(()) => self.foot.increase_xp(amount),
            Slot::Hand(()) => self.hand.increase_xp(amount),
            Slot::Neck(()) => self.neck.increase_xp(amount),
            Slot::Ring(()) => self.ring.increase_xp(amount),
        }
    }

    // @notice get the adventurer's equipped items
    // @param adventurer the Adventurer to get equipped items for
    // @return Array<ItemPrimitive>: the adventurer's equipped items
    fn get_equipped_items(self: Adventurer) -> Array<ItemPrimitive> {
        let mut equipped_items = ArrayTrait::<ItemPrimitive>::new();
        if self.weapon.id != 0 {
            equipped_items.append(self.weapon);
        }
        if self.chest.id != 0 {
            equipped_items.append(self.chest);
        }
        if self.head.id != 0 {
            equipped_items.append(self.head);
        }
        if self.waist.id != 0 {
            equipped_items.append(self.waist);
        }
        if self.foot.id != 0 {
            equipped_items.append(self.foot);
        }
        if self.hand.id != 0 {
            equipped_items.append(self.hand);
        }
        if self.neck.id != 0 {
            equipped_items.append(self.neck);
        }
        if self.ring.id != 0 {
            equipped_items.append(self.ring);
        }
        equipped_items
    }
}

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

    use lootitems::{loot::{Loot, ILoot, ImplLoot}, constants::{ItemSuffix, ItemId}};

    use combat::{constants::CombatEnums::{Slot}};

    use beasts::{beast::{ImplBeast, Beast}, constants::BeastSettings};

    use survivor::{
        adventurer::{IAdventurer, ImplAdventurer, Adventurer},
        item_meta::{ItemSpecials, ItemSpecialsStorage, ImplItemSpecials}, adventurer_stats::Stats,
        item_primitive::ItemPrimitive, adventurer_utils::{AdventurerUtils}, bag::{Bag, ImplBag},
        constants::{
            adventurer_constants::{
                STARTING_GOLD, StatisticIndex, POTION_PRICE, STARTING_HEALTH,
                CHARISMA_POTION_DISCOUNT, MINIMUM_ITEM_PRICE, MINIMUM_POTION_PRICE,
                HEALTH_INCREASE_PER_VITALITY, MAX_GOLD, MAX_STAT_VALUE, MAX_STAT_UPGRADES, MAX_XP,
                MAX_ADVENTURER_BLOCKS, ITEM_MAX_GREATNESS, ITEM_MAX_XP, MAX_ADVENTURER_HEALTH,
                CHARISMA_ITEM_DISCOUNT, ClassStatBoosts, MAX_BLOCK_COUNT, SILVER_RING_G20_LUCK_BONUS
            },
            discovery_constants::DiscoveryEnums::{ExploreResult, TreasureDiscovery}
        }
    };
    use pack::{pack::{Packing, rshift_split}, constants::{MASK_16, pow, MASK_8, MASK_BOOL, mask}};

    #[test]
    #[available_gas(28390)]
    fn test_beast_gold_reward_multiplier_gas() {
        let mut adventurer = ImplAdventurer::new(
            12,
            0,
            Stats {
                strength: 1, dexterity: 1, vitality: 1, intelligence: 1, wisdom: 1, charisma: 1,
            }
        );
        let reward = adventurer.beast_gold_reward_multiplier();
    }


    #[test]
    #[available_gas(48470)]
    fn test_beast_gold_reward_multiplier() {
        let mut adventurer = ImplAdventurer::new(
            12,
            0,
            Stats {
                strength: 1, dexterity: 1, vitality: 1, intelligence: 1, wisdom: 1, charisma: 1,
            }
        );

        assert(adventurer.beast_gold_reward_multiplier() == 1, 'no gold reward');

        // equip gold ring
        let gold_ring = ItemPrimitive { id: ItemId::GoldRing, xp: 1, metadata: 1 };
        adventurer.ring = gold_ring;
        assert(adventurer.beast_gold_reward_multiplier() == 2, '2x gold reward');

        // increase greatness of gold ring to G20
        adventurer.ring.xp = 400;
        assert(adventurer.beast_gold_reward_multiplier() == 4, '4x gold reward');

        // change to platinum ring
        let platinum_ring = ItemPrimitive { id: ItemId::PlatinumRing, xp: 1, metadata: 1 };
        adventurer.ring = platinum_ring;
        assert(adventurer.beast_gold_reward_multiplier() == 1, 'removed gold reward');
    }

    #[test]
    #[available_gas(28390)]
    fn test_get_bonus_luck_gas() {
        let adventurer = ImplAdventurer::new(
            12,
            0,
            Stats {
                strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
            }
        );

        let bonus_luck = adventurer.get_bonus_luck();
    }

    #[test]
    #[available_gas(48470)]
    fn test_get_bonus_luck() {
        let mut adventurer = ImplAdventurer::new(
            12,
            0,
            Stats {
                strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
            }
        );

        assert(adventurer.get_bonus_luck() == 0, 'no bonus luck');

        // equip silver ring
        let silver_ring = ItemPrimitive { id: ItemId::SilverRing, xp: 1, metadata: 1 };
        adventurer.ring = silver_ring;
        assert(adventurer.get_bonus_luck() == 0, 'no bonus luck at G1');

        // increase greatness to 20
        adventurer.ring.xp = 400;
        assert(adventurer.get_bonus_luck() == SILVER_RING_G20_LUCK_BONUS, 'bonus luck at G20');

        // switch to platinum ring
        let platinum_ring = ItemPrimitive { id: ItemId::PlatinumRing, xp: 1, metadata: 1 };
        adventurer.ring = platinum_ring;
        assert(adventurer.get_bonus_luck() == 0, 'no bonus luck after swap');
    }

    #[test]
    #[available_gas(28390)]
    fn test_obstacle_gold_reward_multplier_gas() {
        let mut adventurer = ImplAdventurer::new(
            12,
            0,
            Stats {
                strength: 1, dexterity: 1, vitality: 1, intelligence: 1, wisdom: 1, charisma: 1,
            }
        );
        let reward = adventurer.obstacle_gold_reward_multplier();
    }

    #[test]
    #[available_gas(2811390)]
    fn test_obstacle_gold_reward_multplier() {
        let mut adventurer = ImplAdventurer::new(
            12,
            0,
            Stats {
                strength: 1, dexterity: 1, vitality: 1, intelligence: 1, wisdom: 1, charisma: 1,
            }
        );

        assert(adventurer.obstacle_gold_reward_multplier() == 0, 'no obstacle gold reward');

        // equip Titanium ring
        let titanium_ring = ItemPrimitive { id: ItemId::TitaniumRing, xp: 1, metadata: 1 };
        adventurer.ring = titanium_ring;
        assert(adventurer.obstacle_gold_reward_multplier() == 1, '1x obstacle gold reward');

        // increase greatness of Titanium ring to G20
        adventurer.ring.xp = 400;
        assert(adventurer.obstacle_gold_reward_multplier() == 2, '2x obstacle gold reward');

        // change to platinum ring
        let platinum_ring = ItemPrimitive { id: ItemId::PlatinumRing, xp: 1, metadata: 1 };
        adventurer.ring = platinum_ring;
        assert(adventurer.obstacle_gold_reward_multplier() == 0, 'removed obstacle gold reward');
    }

    #[test]
    #[available_gas(28390)]
    fn test_discovery_bonus_multplier_gas() {
        let mut adventurer = ImplAdventurer::new(
            12,
            0,
            Stats {
                strength: 1, dexterity: 1, vitality: 1, intelligence: 1, wisdom: 1, charisma: 1,
            }
        );

        let discovery_bonus = adventurer.discovery_bonus_multplier();
    }
    #[test]
    #[available_gas(48470)]
    fn test_discovery_bonus_multplier() {
        let mut adventurer = ImplAdventurer::new(
            12,
            0,
            Stats {
                strength: 1, dexterity: 1, vitality: 1, intelligence: 1, wisdom: 1, charisma: 1,
            }
        );

        assert(adventurer.discovery_bonus_multplier() == 1, 'start with 1x discovery bonus');

        // equip platinum ring
        let platinum_ring = ItemPrimitive { id: ItemId::PlatinumRing, xp: 1, metadata: 1 };
        adventurer.ring = platinum_ring;
        assert(adventurer.discovery_bonus_multplier() == 2, '2x discovery with platinum ring');

        // increase greatness of platinum ring to G20
        adventurer.ring.xp = 400;
        assert(adventurer.discovery_bonus_multplier() == 4, '4x discovery with platinum ring');

        // switch to titanium ring
        let titanium_ring = ItemPrimitive { id: ItemId::TitaniumRing, xp: 1, metadata: 1 };
        adventurer.ring = titanium_ring;
        assert(adventurer.discovery_bonus_multplier() == 1, '1x discovery with titanium ring');
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
    #[should_panic(expected: ('no specials unlocked',))]
    #[available_gas(278330)]
    fn test_apply_specials_panic() {
        let suffix_unlocked = false;
        let prefixes_unlocked = false;
        let entropy = 12345;

        let blank_item_specials = ItemSpecials { special2: 0, special3: 0, special1: 0, };

        let mut name_storage = ItemSpecialsStorage {
            item_1: blank_item_specials,
            item_2: blank_item_specials,
            item_3: blank_item_specials,
            item_4: blank_item_specials,
            item_5: blank_item_specials,
            item_6: blank_item_specials,
            item_7: blank_item_specials,
            item_8: blank_item_specials,
            item_9: blank_item_specials,
            item_10: blank_item_specials,
            mutated: false
        };

        let katana = ItemPrimitive { id: ItemId::Katana, xp: 0, metadata: 0 };

        // calling apply specials with suffix_unlock and prefixed_unlocked is not a valid
        // apply_specials should panic in this case which the test is annotated to expect
        katana.apply_specials(ref name_storage, suffix_unlocked, prefixes_unlocked, entropy);
    }

    #[test]
    #[available_gas(483540)]
    fn test_apply_prefixes() {
        let entropy = 12345;

        let katana_starting_specials = ItemSpecials { special1: 1, special2: 0, special3: 0 };
        let blank_item_specials = ItemSpecials { special2: 0, special3: 0, special1: 0, };

        let mut name_storage = ItemSpecialsStorage {
            item_1: katana_starting_specials,
            item_2: blank_item_specials,
            item_3: blank_item_specials,
            item_4: blank_item_specials,
            item_5: blank_item_specials,
            item_6: blank_item_specials,
            item_7: blank_item_specials,
            item_8: blank_item_specials,
            item_9: blank_item_specials,
            item_10: blank_item_specials,
            mutated: false
        };

        let katana = ItemPrimitive { id: ItemId::Katana, xp: 0, metadata: 1 };
        katana.apply_prefixes(ref name_storage, entropy);

        // verify special2 and special3 are now set in the name_storage
        assert(name_storage.item_1.special1 != 0, 'katana special1 not preserved');
        assert(name_storage.item_1.special2 != 0, 'katana special2 not applied');
        assert(name_storage.item_1.special3 != 0, 'katana special3 not applied');

        // assert all other specials for all other items is still 0
        assert(name_storage.item_2.special1 == 0, 'item2 special1 not blank');
        assert(name_storage.item_2.special2 == 0, 'item2 special2 not blank');
        assert(name_storage.item_2.special3 == 0, 'item2 special3 not blank');
        assert(name_storage.item_3.special1 == 0, 'item3 special1 not blank');
        assert(name_storage.item_3.special2 == 0, 'item3 special2 not blank');
        assert(name_storage.item_3.special3 == 0, 'item3 special3 not blank');
        assert(name_storage.item_4.special1 == 0, 'item4 special1 not blank');
        assert(name_storage.item_4.special2 == 0, 'item4 special2 not blank');
        assert(name_storage.item_4.special3 == 0, 'item4 special3 not blank');
        assert(name_storage.item_5.special1 == 0, 'item5 special1 not blank');
        assert(name_storage.item_5.special2 == 0, 'item5 special2 not blank');
        assert(name_storage.item_5.special3 == 0, 'item5 special3 not blank');
        assert(name_storage.item_6.special1 == 0, 'item6 special1 not blank');
        assert(name_storage.item_6.special2 == 0, 'item6 special2 not blank');
        assert(name_storage.item_6.special3 == 0, 'item6 special3 not blank');
        assert(name_storage.item_7.special1 == 0, 'item7 special1 not blank');
        assert(name_storage.item_7.special2 == 0, 'item7 special2 not blank');
        assert(name_storage.item_7.special3 == 0, 'item7 special3 not blank');
        assert(name_storage.item_8.special1 == 0, 'item8 special1 not blank');
        assert(name_storage.item_8.special2 == 0, 'item8 special2 not blank');
        assert(name_storage.item_8.special3 == 0, 'item8 special3 not blank');
        assert(name_storage.item_9.special1 == 0, 'item9 special1 not blank');
        assert(name_storage.item_9.special2 == 0, 'item9 special2 not blank');
        assert(name_storage.item_9.special3 == 0, 'item9 special3 not blank');
        assert(name_storage.item_10.special1 == 0, 'item10 special1 not blank');
        assert(name_storage.item_10.special2 == 0, 'item10 special2 not blank');
        assert(name_storage.item_10.special3 == 0, 'item10 special3 not blank');

        let crown = ItemPrimitive { id: ItemId::Crown, xp: 0, metadata: 5 };
        crown.apply_prefixes(ref name_storage, entropy);

        // assert katana special2 and special3 are still set
        assert(name_storage.item_1.special1 != 0, 'katana special1 not preserved');
        assert(name_storage.item_1.special2 != 0, 'katana special2 not preserved');
        assert(name_storage.item_1.special3 != 0, 'katana special3 not preserved');

        // assert crown special2 and special3 are now set
        assert(name_storage.item_5.special1 == 0, 'crown special1 not zero');
        assert(name_storage.item_5.special2 != 0, 'crown special2 not applied');
        assert(name_storage.item_5.special3 != 0, 'crown special3 not applied');

        // assert all other specials for all other items are still 0
        assert(name_storage.item_2.special1 == 0, 'item2 special1 not blank');
        assert(name_storage.item_2.special2 == 0, 'item2 special2 not blank');
        assert(name_storage.item_2.special3 == 0, 'item2 special3 not blank');
        assert(name_storage.item_3.special1 == 0, 'item3 special1 not blank');
        assert(name_storage.item_3.special2 == 0, 'item3 special2 not blank');
        assert(name_storage.item_3.special3 == 0, 'item3 special3 not blank');
        assert(name_storage.item_4.special1 == 0, 'item4 special1 not blank');
        assert(name_storage.item_4.special2 == 0, 'item4 special2 not blank');
        assert(name_storage.item_4.special3 == 0, 'item4 special3 not blank');
        assert(name_storage.item_6.special1 == 0, 'item6 special1 not blank');
        assert(name_storage.item_6.special2 == 0, 'item6 special2 not blank');
        assert(name_storage.item_6.special3 == 0, 'item6 special3 not blank');
        assert(name_storage.item_7.special1 == 0, 'item7 special1 not blank');
        assert(name_storage.item_7.special2 == 0, 'item7 special2 not blank');
        assert(name_storage.item_7.special3 == 0, 'item7 special3 not blank');
        assert(name_storage.item_8.special1 == 0, 'item8 special1 not blank');
        assert(name_storage.item_8.special2 == 0, 'item8 special2 not blank');
        assert(name_storage.item_8.special3 == 0, 'item8 special3 not blank');
        assert(name_storage.item_9.special1 == 0, 'item9 special1 not blank');
        assert(name_storage.item_9.special2 == 0, 'item9 special2 not blank');
        assert(name_storage.item_9.special3 == 0, 'item9 special3 not blank');
        assert(name_storage.item_10.special1 == 0, 'item10 special1 not blank');
        assert(name_storage.item_10.special2 == 0, 'item10 special2 not blank');
        assert(name_storage.item_10.special3 == 0, 'item10 special3 not blank');
    }
    #[test]
    #[available_gas(310600)]
    fn test_apply_suffix() {
        let entropy = 12345;

        let blank_item_specials = ItemSpecials { special2: 0, special3: 0, special1: 0, };

        let mut name_storage = ItemSpecialsStorage {
            item_1: blank_item_specials,
            item_2: blank_item_specials,
            item_3: blank_item_specials,
            item_4: blank_item_specials,
            item_5: blank_item_specials,
            item_6: blank_item_specials,
            item_7: blank_item_specials,
            item_8: blank_item_specials,
            item_9: blank_item_specials,
            item_10: blank_item_specials,
            mutated: false
        };

        let katana = ItemPrimitive { id: ItemId::Katana, xp: 0, metadata: 1 };
        katana.apply_suffix(ref name_storage, entropy);

        // verify special2 and special3 are now set in the name_storage
        assert(name_storage.item_1.special1 != 0, 'katana special1 not applied');
        assert(name_storage.item_1.special2 == 0, 'katana special2 not zero');
        assert(name_storage.item_1.special3 == 0, 'katana special3 not zero');

        // assert special1, special2, and special3 for the other items are still 0
        assert(name_storage.item_2.special1 == 0, 'item2 special1 not blank');
        assert(name_storage.item_2.special2 == 0, 'item2 special2 not blank');
        assert(name_storage.item_2.special3 == 0, 'item2 special3 not blank');
        assert(name_storage.item_3.special1 == 0, 'item3 special1 not blank');
        assert(name_storage.item_3.special2 == 0, 'item3 special2 not blank');
        assert(name_storage.item_3.special3 == 0, 'item3 special3 not blank');

        let crown = ItemPrimitive { id: ItemId::Crown, xp: 0, metadata: 5 };
        crown.apply_suffix(ref name_storage, entropy);

        // assert katana special1 is still set
        assert(name_storage.item_1.special1 != 0, 'katana special1 not applied');
        // assert crown special1 is set
        assert(name_storage.item_5.special1 != 0, 'crown special1 not applied');

        // assert all other specials for all other items are still 0
        assert(name_storage.item_1.special2 == 0, 'katana special2 not zero');
        assert(name_storage.item_1.special3 == 0, 'katana special3 not zero');
        assert(name_storage.item_2.special1 == 0, 'item2 special1 not blank');
        assert(name_storage.item_2.special2 == 0, 'crown special2 not zero');
        assert(name_storage.item_2.special3 == 0, 'crown special3 not zero');
        assert(name_storage.item_3.special1 == 0, 'item3 special1 not blank');
        assert(name_storage.item_3.special2 == 0, 'item3 special2 not blank');
        assert(name_storage.item_3.special3 == 0, 'item3 special3 not blank');
        assert(name_storage.item_4.special1 == 0, 'item4 special1 not blank');
        assert(name_storage.item_4.special2 == 0, 'item4 special2 not blank');
        assert(name_storage.item_4.special3 == 0, 'item4 special3 not blank');
        assert(name_storage.item_5.special2 == 0, 'item5 special2 not blank');
        assert(name_storage.item_5.special3 == 0, 'item5 special3 not blank');
        assert(name_storage.item_6.special1 == 0, 'item6 special1 not blank');
        assert(name_storage.item_6.special2 == 0, 'item6 special2 not blank');
        assert(name_storage.item_6.special3 == 0, 'item6 special3 not blank');
        assert(name_storage.item_7.special1 == 0, 'item7 special1 not blank');
        assert(name_storage.item_7.special2 == 0, 'item7 special2 not blank');
        assert(name_storage.item_7.special3 == 0, 'item7 special3 not blank');
        assert(name_storage.item_8.special1 == 0, 'item8 special1 not blank');
        assert(name_storage.item_8.special2 == 0, 'item8 special2 not blank');
        assert(name_storage.item_8.special3 == 0, 'item8 special3 not blank');
        assert(name_storage.item_9.special1 == 0, 'item9 special1 not blank');
        assert(name_storage.item_9.special2 == 0, 'item9 special2 not blank');
        assert(name_storage.item_9.special3 == 0, 'item9 special3 not blank');
        assert(name_storage.item_10.special1 == 0, 'item10 special1 not blank');
        assert(name_storage.item_10.special2 == 0, 'item10 special2 not blank');
        assert(name_storage.item_10.special3 == 0, 'item10 special3 not blank');
    }

    #[test]
    #[available_gas(285140)]
    fn test_apply_suffix_and_prefixes() {
        let entropy = 12345;

        // start katana with a special as would be the case in the game
        let katana = ItemPrimitive { id: ItemId::Katana, xp: 0, metadata: 1 };
        let katana_starting_special = ItemSpecials { special1: 0, special2: 0, special3: 0 };
        let blank_item_specials = ItemSpecials { special1: 0, special2: 0, special3: 0 };

        let mut name_storage = ItemSpecialsStorage {
            item_1: katana_starting_special,
            item_2: blank_item_specials,
            item_3: blank_item_specials,
            item_4: blank_item_specials,
            item_5: blank_item_specials,
            item_6: blank_item_specials,
            item_7: blank_item_specials,
            item_8: blank_item_specials,
            item_9: blank_item_specials,
            item_10: blank_item_specials,
            mutated: false
        };

        // apply prefixes to katana
        katana.apply_suffix_and_prefixes(ref name_storage, entropy);

        // verify special2 and special3 are now set in the name_storage
        assert(name_storage.item_1.special1 != 0, 'katana special1 not applied');
        assert(name_storage.item_1.special2 != 0, 'katana special2 not applied');
        assert(name_storage.item_1.special3 != 0, 'katana special3 not applied');

        // assert special1, special2, and special3 for the other items are still 0
        assert(name_storage.item_2.special1 == 0, 'item2 special1 not blank');
        assert(name_storage.item_2.special2 == 0, 'item2 special2 not blank');
        assert(name_storage.item_2.special3 == 0, 'item2 special3 not blank');
        assert(name_storage.item_3.special1 == 0, 'item3 special1 not blank');
        assert(name_storage.item_3.special2 == 0, 'item3 special2 not blank');
        assert(name_storage.item_3.special3 == 0, 'item3 special3 not blank');
    }

    #[test]
    #[available_gas(299740)]
    fn test_apply_specials_suffix_and_prefixes() {
        let suffix_unlocked = true;
        let prefixes_unlocked = true;
        let entropy = 12345;

        // start katana with a special as would be the case in the game
        let katana = ItemPrimitive { id: ItemId::Katana, xp: 0, metadata: 1 };
        let katana_starting_special = ItemSpecials { special1: 0, special2: 0, special3: 0 };
        let blank_item_specials = ItemSpecials { special1: 0, special2: 0, special3: 0 };

        let mut name_storage = ItemSpecialsStorage {
            item_1: katana_starting_special,
            item_2: blank_item_specials,
            item_3: blank_item_specials,
            item_4: blank_item_specials,
            item_5: blank_item_specials,
            item_6: blank_item_specials,
            item_7: blank_item_specials,
            item_8: blank_item_specials,
            item_9: blank_item_specials,
            item_10: blank_item_specials,
            mutated: false
        };

        // apply prefixes to katana
        katana.apply_specials(ref name_storage, suffix_unlocked, prefixes_unlocked, entropy);

        // verify special2 and special3 are now set in the name_storage
        assert(name_storage.item_1.special1 != 0, 'katana special1 not applied');
        assert(name_storage.item_1.special2 != 0, 'katana special2 not applied');
        assert(name_storage.item_1.special3 != 0, 'katana special3 not applied');

        // assert special1, special2, and special3 for the other items are still 0
        assert(name_storage.item_2.special1 == 0, 'item2 special1 not blank');
        assert(name_storage.item_2.special2 == 0, 'item2 special2 not blank');
        assert(name_storage.item_2.special3 == 0, 'item2 special3 not blank');
        assert(name_storage.item_3.special1 == 0, 'item3 special1 not blank');
        assert(name_storage.item_3.special2 == 0, 'item3 special2 not blank');
        assert(name_storage.item_3.special3 == 0, 'item3 special3 not blank');
        assert(name_storage.item_4.special1 == 0, 'item4 special1 not blank');
        assert(name_storage.item_4.special2 == 0, 'item4 special2 not blank');
        assert(name_storage.item_4.special3 == 0, 'item4 special3 not blank');
        assert(name_storage.item_5.special1 == 0, 'item5 special1 not blank');
        assert(name_storage.item_5.special2 == 0, 'item5 special2 not blank');
        assert(name_storage.item_5.special3 == 0, 'item5 special3 not blank');
        assert(name_storage.item_6.special1 == 0, 'item6 special1 not blank');
        assert(name_storage.item_6.special2 == 0, 'item6 special2 not blank');
        assert(name_storage.item_6.special3 == 0, 'item6 special3 not blank');
        assert(name_storage.item_7.special1 == 0, 'item7 special1 not blank');
        assert(name_storage.item_7.special2 == 0, 'item7 special2 not blank');
        assert(name_storage.item_7.special3 == 0, 'item7 special3 not blank');
        assert(name_storage.item_8.special1 == 0, 'item8 special1 not blank');
        assert(name_storage.item_8.special2 == 0, 'item8 special2 not blank');
        assert(name_storage.item_8.special3 == 0, 'item8 special3 not blank');
        assert(name_storage.item_9.special1 == 0, 'item9 special1 not blank');
        assert(name_storage.item_9.special2 == 0, 'item9 special2 not blank');
        assert(name_storage.item_9.special3 == 0, 'item9 special3 not blank');
        assert(name_storage.item_10.special1 == 0, 'item10 special1 not blank');
        assert(name_storage.item_10.special2 == 0, 'item10 special2 not blank');
        assert(name_storage.item_10.special3 == 0, 'item10 special3 not blank');
    }

    #[test]
    #[available_gas(299340)]
    fn test_apply_specials_prefixes() {
        let suffix_unlocked = false;
        let prefixes_unlocked = true;
        let entropy = 12345;

        // start katana with a special as would be the case in the game
        let katana = ItemPrimitive { id: ItemId::Katana, xp: 0, metadata: 1 };
        let katana_starting_special = ItemSpecials { special1: 1, special2: 0, special3: 0 };
        let blank_item_specials = ItemSpecials { special1: 0, special2: 0, special3: 0 };

        let mut name_storage = ItemSpecialsStorage {
            item_1: katana_starting_special,
            item_2: blank_item_specials,
            item_3: blank_item_specials,
            item_4: blank_item_specials,
            item_5: blank_item_specials,
            item_6: blank_item_specials,
            item_7: blank_item_specials,
            item_8: blank_item_specials,
            item_9: blank_item_specials,
            item_10: blank_item_specials,
            mutated: false
        };

        // apply prefixes to katana
        katana.apply_specials(ref name_storage, suffix_unlocked, prefixes_unlocked, entropy);

        // verify special2 and special3 are now set in the name_storage
        assert(name_storage.item_1.special1 == 1, 'katana special1 not preserved');
        assert(name_storage.item_1.special2 != 0, 'katana special2 not applied');
        assert(name_storage.item_1.special3 != 0, 'katana special3 not applied');

        // assert special1, special2, and special3 for the other items are still 0
        assert(name_storage.item_2.special1 == 0, 'item2 special1 not blank');
        assert(name_storage.item_2.special2 == 0, 'item2 special2 not blank');
        assert(name_storage.item_2.special3 == 0, 'item2 special3 not blank');
        assert(name_storage.item_3.special1 == 0, 'item3 special1 not blank');
        assert(name_storage.item_3.special2 == 0, 'item3 special2 not blank');
        assert(name_storage.item_3.special3 == 0, 'item3 special3 not blank');
        assert(name_storage.item_4.special1 == 0, 'item4 special1 not blank');
        assert(name_storage.item_4.special2 == 0, 'item4 special2 not blank');
        assert(name_storage.item_4.special3 == 0, 'item4 special3 not blank');
        assert(name_storage.item_5.special1 == 0, 'item5 special1 not blank');
        assert(name_storage.item_5.special2 == 0, 'item5 special2 not blank');
        assert(name_storage.item_5.special3 == 0, 'item5 special3 not blank');
        assert(name_storage.item_6.special1 == 0, 'item6 special1 not blank');
        assert(name_storage.item_6.special2 == 0, 'item6 special2 not blank');
        assert(name_storage.item_6.special3 == 0, 'item6 special3 not blank');
        assert(name_storage.item_7.special1 == 0, 'item7 special1 not blank');
        assert(name_storage.item_7.special2 == 0, 'item7 special2 not blank');
        assert(name_storage.item_7.special3 == 0, 'item7 special3 not blank');
        assert(name_storage.item_8.special1 == 0, 'item8 special1 not blank');
        assert(name_storage.item_8.special2 == 0, 'item8 special2 not blank');
        assert(name_storage.item_8.special3 == 0, 'item8 special3 not blank');
        assert(name_storage.item_9.special1 == 0, 'item9 special1 not blank');
        assert(name_storage.item_9.special2 == 0, 'item9 special2 not blank');
        assert(name_storage.item_9.special3 == 0, 'item9 special3 not blank');
        assert(name_storage.item_10.special1 == 0, 'item10 special1 not blank');
        assert(name_storage.item_10.special2 == 0, 'item10 special2 not blank');
        assert(name_storage.item_10.special3 == 0, 'item10 special3 not blank');
    }

    #[test]
    #[available_gas(11278330)]
    fn test_apply_specials_suffix() {
        let suffix_unlocked = true;
        let prefixes_unlocked = false;
        let entropy = 12345;

        let blank_item_specials = ItemSpecials { special2: 0, special3: 0, special1: 0, };

        let mut name_storage = ItemSpecialsStorage {
            item_1: blank_item_specials,
            item_2: blank_item_specials,
            item_3: blank_item_specials,
            item_4: blank_item_specials,
            item_5: blank_item_specials,
            item_6: blank_item_specials,
            item_7: blank_item_specials,
            item_8: blank_item_specials,
            item_9: blank_item_specials,
            item_10: blank_item_specials,
            mutated: false
        };

        let katana = ItemPrimitive { id: ItemId::Katana, xp: 0, metadata: 1 };
        katana.apply_specials(ref name_storage, suffix_unlocked, prefixes_unlocked, entropy);

        // assert katana now has special1 set in the name_storage
        assert(name_storage.item_1.special1 != 0, 'suffix not applied');
        // the katanas special2 and special3 should still be empty
        assert(name_storage.item_1.special2 == 0, 'special2 not blank');
        assert(name_storage.item_1.special3 == 0, 'special3 not blank');

        // as should the rest of the names in the storage
        assert(name_storage.item_2.special1 == 0, 'special1 not blank');
        assert(name_storage.item_2.special2 == 0, 'special2 not blank');
        assert(name_storage.item_2.special3 == 0, 'special3 not blank');
        assert(name_storage.item_3.special1 == 0, 'special1 not blank');
        assert(name_storage.item_3.special2 == 0, 'special2 not blank');
        assert(name_storage.item_3.special3 == 0, 'special3 not blank');
        assert(name_storage.item_4.special1 == 0, 'special1 not blank');
        assert(name_storage.item_4.special2 == 0, 'special2 not blank');
        assert(name_storage.item_4.special3 == 0, 'special3 not blank');
        assert(name_storage.item_5.special1 == 0, 'special1 not blank');
        assert(name_storage.item_5.special2 == 0, 'special2 not blank');
        assert(name_storage.item_5.special3 == 0, 'special3 not blank');
        assert(name_storage.item_6.special1 == 0, 'special1 not blank');
        assert(name_storage.item_6.special2 == 0, 'special2 not blank');
        assert(name_storage.item_6.special3 == 0, 'special3 not blank');
        assert(name_storage.item_7.special1 == 0, 'special1 not blank');
        assert(name_storage.item_7.special2 == 0, 'special2 not blank');
        assert(name_storage.item_7.special3 == 0, 'special3 not blank');
        assert(name_storage.item_8.special1 == 0, 'special1 not blank');
        assert(name_storage.item_8.special2 == 0, 'special2 not blank');
        assert(name_storage.item_8.special3 == 0, 'special3 not blank');
        assert(name_storage.item_9.special1 == 0, 'special1 not blank');
        assert(name_storage.item_9.special2 == 0, 'special2 not blank');
        assert(name_storage.item_9.special3 == 0, 'special3 not blank');
        assert(name_storage.item_10.special1 == 0, 'special1 not blank');
        assert(name_storage.item_10.special2 == 0, 'special2 not blank');
        assert(name_storage.item_10.special3 == 0, 'special3 not blank');
    }

    #[test]
    #[available_gas(35290)]
    fn test_double_gold_from_beasts_unlocked_gas() {
        let adventurer = ImplAdventurer::new(
            12,
            0,
            Stats {
                strength: 1, dexterity: 1, vitality: 1, intelligence: 1, wisdom: 1, charisma: 1,
            }
        );
        let bag = Bag {
            item_1: ItemPrimitive { id: ItemId::Katana, xp: 0, metadata: 9 },
            item_2: ItemPrimitive { id: ItemId::Crown, xp: 0, metadata: 10 },
            item_3: ItemPrimitive { id: ItemId::Shirt, xp: 0, metadata: 11 },
            item_4: ItemPrimitive { id: ItemId::Shoes, xp: 0, metadata: 12 },
            item_5: ItemPrimitive { id: ItemId::GoldRing, xp: 0, metadata: 13 },
            item_6: ItemPrimitive { id: 0, xp: 0, metadata: 14 },
            item_7: ItemPrimitive { id: 0, xp: 0, metadata: 15 },
            item_8: ItemPrimitive { id: 0, xp: 0, metadata: 16 },
            item_9: ItemPrimitive { id: 0, xp: 0, metadata: 17 },
            item_10: ItemPrimitive { id: 0, xp: 0, metadata: 18 },
            item_11: ItemPrimitive { id: 0, xp: 0, metadata: 19 },
            mutated: false,
        };

        ImplAdventurer::beast_gold_reward_multiplier(adventurer);
    }

    #[test]
    #[available_gas(99050)]
    fn test_double_gold_from_beasts_unlocked() {
        let mut adventurer = ImplAdventurer::new(
            12,
            0,
            Stats {
                strength: 1, dexterity: 1, vitality: 1, intelligence: 1, wisdom: 1, charisma: 1,
            }
        );

        let bag = Bag {
            item_1: ItemPrimitive { id: ItemId::Katana, xp: 0, metadata: 9 },
            item_2: ItemPrimitive { id: ItemId::Crown, xp: 0, metadata: 10 },
            item_3: ItemPrimitive { id: ItemId::Shirt, xp: 0, metadata: 11 },
            item_4: ItemPrimitive { id: ItemId::Shoes, xp: 0, metadata: 12 },
            item_5: ItemPrimitive { id: 0, xp: 0, metadata: 13 },
            item_6: ItemPrimitive { id: 0, xp: 0, metadata: 14 },
            item_7: ItemPrimitive { id: 0, xp: 0, metadata: 15 },
            item_8: ItemPrimitive { id: 0, xp: 0, metadata: 16 },
            item_9: ItemPrimitive { id: 0, xp: 0, metadata: 17 },
            item_10: ItemPrimitive { id: 0, xp: 0, metadata: 18 },
            item_11: ItemPrimitive { id: 0, xp: 0, metadata: 19 },
            mutated: false,
        };

        // verify new adventurers don't have double gold discovery unlocked
        assert(
            ImplAdventurer::beast_gold_reward_multiplier(adventurer) == 1,
            'double beast gold not unlocked'
        );

        // equip an amulet and verify result doesn't change
        adventurer.neck = ItemPrimitive { id: ItemId::Amulet, xp: 400, metadata: 1 };
        assert(
            ImplAdventurer::beast_gold_reward_multiplier(adventurer) == 1,
            'amulet not unlock beast 2xgold'
        );

        // equip a pendant and verify result doesn't change
        adventurer.neck = ItemPrimitive { id: ItemId::Pendant, xp: 400, metadata: 2 };
        assert(
            ImplAdventurer::beast_gold_reward_multiplier(adventurer) == 1,
            'pendant not unlock beast 2xgold'
        );

        // equip a necklace and verify result doesn't change
        adventurer.neck = ItemPrimitive { id: ItemId::Necklace, xp: 400, metadata: 3 };
        assert(
            ImplAdventurer::beast_gold_reward_multiplier(adventurer) == 1,
            'necklace not beast 2xgold'
        );

        // equip a bronze ring and verify result doesn't change
        adventurer.ring = ItemPrimitive { id: ItemId::BronzeRing, xp: 400, metadata: 4 };
        assert(
            ImplAdventurer::beast_gold_reward_multiplier(adventurer) == 1,
            'brnze ring ! unlck beast 2xgold'
        );

        // equip a gold ring with 1xp (greatness 2) and verify it yields 2x gold reward
        adventurer.ring = ItemPrimitive { id: ItemId::GoldRing, xp: 1, metadata: 5 };
        assert(
            ImplAdventurer::beast_gold_reward_multiplier(adventurer) == 2,
            'G1 gold ring gives 2x reward'
        );

        // equip a gold ring with 400 xp (greatness 20) and verify result is true
        adventurer.ring = ItemPrimitive { id: ItemId::GoldRing, xp: 400, metadata: 6 };
        assert(
            ImplAdventurer::beast_gold_reward_multiplier(adventurer) == 4,
            'G20 gold ring gives 4xgold'
        );
    }

    #[test]
    #[available_gas(28390)]
    fn test_armor_bonus_multiplier_gas() {
        let adventurer = ImplAdventurer::new(
            12,
            0,
            Stats {
                strength: 1, dexterity: 1, vitality: 1, intelligence: 1, wisdom: 1, charisma: 1,
            }
        );

        let armor_bonus = ImplAdventurer::armor_bonus_multiplier(adventurer);
    }

    #[test]
    #[available_gas(40910)]
    fn test_armor_bonus_multiplier() {
        let mut adventurer = ImplAdventurer::new(
            12,
            0,
            Stats {
                strength: 1, dexterity: 1, vitality: 1, intelligence: 1, wisdom: 1, charisma: 1,
            }
        );

        // verify no armor bonus multplier at start
        assert(
            ImplAdventurer::armor_bonus_multiplier(adventurer) == 1,
            'start with no armor bonus'
        );

        // equip a greatness 1 Amulet
        adventurer.neck = ItemPrimitive { id: ItemId::Amulet, xp: 1, metadata: 1 };
        // verify there is still no armor bonus
        assert(
            ImplAdventurer::armor_bonus_multiplier(adventurer) == 1, 'no amulet till g20'
        );

        // increase greatness of amulet to g20
        adventurer.neck.xp = 400;
        // verify there is now an armor bonus
        assert(
            ImplAdventurer::armor_bonus_multiplier(adventurer) == 2,
            'amulet gives 20% armor bonus'
        );
    }

    #[test]
    #[available_gas(28790)]
    fn test_critical_hit_bonus_multiplier_gas() {
        let mut adventurer = ImplAdventurer::new(
            12,
            0,
            Stats {
                strength: 1, dexterity: 1, vitality: 1, intelligence: 1, wisdom: 1, charisma: 1,
            }
        );

        // equip a Platinum Ring ring with 400xp (greatness 20)
        adventurer.ring = ItemPrimitive { id: ItemId::PlatinumRing, xp: 400, metadata: 6 };
        ImplAdventurer::critical_hit_bonus_multiplier(adventurer);
    }

    #[test]
    #[available_gas(44910)]
    fn test_critical_hit_bonus_multiplier() {
        let mut adventurer = ImplAdventurer::new(
            12,
            0,
            Stats {
                strength: 1, dexterity: 1, vitality: 1, intelligence: 1, wisdom: 1, charisma: 1,
            }
        );

        // verify starting state (no necklace)
        assert(adventurer.neck.id == 0, 'start without a neck');

        // verify no critical hit damage multiplier at start
        assert(
            ImplAdventurer::critical_hit_bonus_multiplier(adventurer) == 1,
            'no starting crit hit multi'
        );

        // equip a greatness 1 pendant
        adventurer.neck = ItemPrimitive { id: ItemId::Pendant, xp: 1, metadata: 2 };
        // verify critical damage isn't unlocked
        assert(
            ImplAdventurer::critical_hit_bonus_multiplier(adventurer) == 1,
            '< g20 pendant ! unlck 2xdmg'
        );

        // increase pendant to G20
        adventurer.neck.xp = 400;
        // verify critical damage is unlocked
        assert(
            ImplAdventurer::critical_hit_bonus_multiplier(adventurer) == 2,
            'G20 pendant unlcks 2x crit dmg'
        );
    }

    // gas baseline
    #[test]
    #[available_gas(28790)]
    fn test_name_match_bonus_damage_multiplier_gas() {
        let mut adventurer = ImplAdventurer::new(
            12,
            0,
            Stats {
                strength: 1, dexterity: 1, vitality: 1, intelligence: 1, wisdom: 1, charisma: 1,
            }
        );

        // equip a titanium ring with 400xp (greatness 20)
        adventurer.ring = ItemPrimitive { id: ItemId::TitaniumRing, xp: 400, metadata: 6 };
        ImplAdventurer::name_match_bonus_damage_multiplier(adventurer);
    }

    #[test]
    #[available_gas(44910)]
    fn test_name_match_bonus_damage_multiplier() {
        let mut adventurer = ImplAdventurer::new(
            12,
            0,
            Stats {
                strength: 1, dexterity: 1, vitality: 1, intelligence: 1, wisdom: 1, charisma: 1,
            }
        );

        // verify starting state (no necklace)
        assert(adventurer.neck.id == 0, 'start without a ring');

        // verify no double critical hit unlocked without a ring
        assert(
            ImplAdventurer::name_match_bonus_damage_multiplier(adventurer) == 1,
            'no name match bonus multi'
        );

        // equip a G1 necklace
        adventurer.neck = ItemPrimitive { id: ItemId::Necklace, xp: 1, metadata: 7 };
        // verify double name damage is still false
        assert(
            ImplAdventurer::name_match_bonus_damage_multiplier(adventurer) == 1,
            '< g20 necklace ! 2x name dmg'
        );

        // increase necklace to G20
        adventurer.neck.xp = 400;
        // verify double name damage is true
        assert(
            ImplAdventurer::name_match_bonus_damage_multiplier(adventurer) == 2,
            'G20 necklace unlcks 2x name dmg'
        );
    }

    #[test]
    #[available_gas(100000)]
    fn test_get_storage_index() {
        assert(ImplAdventurer::get_storage_index(0) == 0, 'storage index should be 0');
        assert(ImplAdventurer::get_storage_index(1) == 0, 'storage index should be 0');
        assert(ImplAdventurer::get_storage_index(2) == 0, 'storage index should be 0');
        assert(ImplAdventurer::get_storage_index(3) == 0, 'storage index should be 0');
        assert(ImplAdventurer::get_storage_index(4) == 0, 'storage index should be 0');
        assert(ImplAdventurer::get_storage_index(5) == 0, 'storage index should be 0');
        assert(ImplAdventurer::get_storage_index(6) == 0, 'storage index should be 0');
        assert(ImplAdventurer::get_storage_index(7) == 0, 'storage index should be 0');
        assert(ImplAdventurer::get_storage_index(8) == 0, 'storage index should be 0');
        assert(ImplAdventurer::get_storage_index(9) == 0, 'storage index should be 0');
        assert(ImplAdventurer::get_storage_index(10) == 0, 'storage index should be 0');
        assert(ImplAdventurer::get_storage_index(11) == 1, 'storage index should be 1');
        assert(ImplAdventurer::get_storage_index(12) == 1, 'storage index should be 1');
        assert(ImplAdventurer::get_storage_index(13) == 1, 'storage index should be 1');
        assert(ImplAdventurer::get_storage_index(14) == 1, 'storage index should be 1');
        assert(ImplAdventurer::get_storage_index(15) == 1, 'storage index should be 1');
        assert(ImplAdventurer::get_storage_index(16) == 1, 'storage index should be 1');
        assert(ImplAdventurer::get_storage_index(17) == 1, 'storage index should be 1');
        assert(ImplAdventurer::get_storage_index(18) == 1, 'storage index should be 1');
        assert(ImplAdventurer::get_storage_index(19) == 1, 'storage index should be 1');
        assert(ImplAdventurer::get_storage_index(20) == 1, 'storage index should be 1');
    }


    #[test]
    #[available_gas(170020)]
    fn test_get_beast_seed_gas() {
        let mut adventurer = ImplAdventurer::new(
            12,
            0,
            Stats {
                strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
            }
        );
        let adventurer_entropy = 1;
        ImplAdventurer::get_beast_seed(adventurer, adventurer_entropy);
        adventurer.xp = 100;
        ImplAdventurer::get_beast_seed(adventurer, adventurer_entropy);
    }

    #[test]
    #[available_gas(1064170)]
    fn test_get_beast() {
        let mut adventurer = ImplAdventurer::new(
            12,
            0,
            Stats {
                strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
            }
        );

        let entropy = 1;
        // check new adventurer (level 1) gets a starter beast
        let (beast, beast_seed) = adventurer.get_beast(entropy);
        assert(beast.combat_spec.level == 1, 'beast should be lvl1');
        assert(beast.combat_spec.specials.special1 == 0, 'beast should have no special1');
        assert(beast.combat_spec.specials.special2 == 0, 'beast should have no special2');
        assert(beast.combat_spec.specials.special3 == 0, 'beast should have no special3');

        let entropy = 2;
        // check beast is still starter beast with different entropy source
        let (beast, beast_seed) = adventurer.get_beast(entropy);
        assert(beast.combat_spec.level == 1, 'beast should be lvl1');
        assert(beast.combat_spec.specials.special1 == 0, 'beast should have no special1');
        assert(beast.combat_spec.specials.special2 == 0, 'beast should have no special2');
        assert(beast.combat_spec.specials.special3 == 0, 'beast should have no special3');

        // advance adventurer to level 2
        adventurer.xp = 4;
        let entropy = 1;
        let (beast1, beast_seed) = adventurer.get_beast(entropy);
        let entropy = 2;
        let (beast2, beast_seed) = adventurer.get_beast(entropy);

        // verify beasts are the same since the seed did not change
        assert(beast1.id != beast2.id, 'beasts not unique');
    }

    #[test]
    #[available_gas(70020)]
    fn test_get_greatness_gas() {
        let greatness = ImplAdventurer::get_greatness(
            ItemPrimitive { id: 1, xp: 400, metadata: 1 }
        );
    }

    #[test]
    #[available_gas(70020)]
    fn test_get_greatness() {
        let mut item = ItemPrimitive { id: 1, xp: 0, metadata: 0 };
        // test 0 case (should be level 1)
        let greatness = ImplAdventurer::get_greatness(item);
        assert(greatness == 1, 'greatness should be 1');

        // test level 1
        item.xp = 1;
        let greatness = ImplAdventurer::get_greatness(item);
        assert(greatness == 1, 'greatness should be 1');

        // test level 2
        item.xp = 4;
        let greatness = ImplAdventurer::get_greatness(item);
        assert(greatness == 2, 'greatness should be 2');

        // test level 3
        item.xp = 9;
        let greatness = ImplAdventurer::get_greatness(item);
        assert(greatness == 3, 'greatness should be 3');

        // test level 4
        item.xp = 16;
        let greatness = ImplAdventurer::get_greatness(item);
        assert(greatness == 4, 'greatness should be 4');

        // test level 5
        item.xp = 25;
        let greatness = ImplAdventurer::get_greatness(item);
        assert(greatness == 5, 'greatness should be 5');

        // test level 6
        item.xp = 36;
        let greatness = ImplAdventurer::get_greatness(item);
        assert(greatness == 6, 'greatness should be 6');

        // test level 7
        item.xp = 49;
        let greatness = ImplAdventurer::get_greatness(item);
        assert(greatness == 7, 'greatness should be 7');

        // test level 8
        item.xp = 64;
        let greatness = ImplAdventurer::get_greatness(item);
        assert(greatness == 8, 'greatness should be 8');

        // test level 9
        item.xp = 81;
        let greatness = ImplAdventurer::get_greatness(item);
        assert(greatness == 9, 'greatness should be 9');

        // test level 10
        item.xp = 100;
        let greatness = ImplAdventurer::get_greatness(item);
        assert(greatness == 10, 'greatness should be 10');

        // test level 11
        item.xp = 121;
        let greatness = ImplAdventurer::get_greatness(item);
        assert(greatness == 11, 'greatness should be 11');

        // test level 12
        item.xp = 144;
        let greatness = ImplAdventurer::get_greatness(item);
        assert(greatness == 12, 'greatness should be 12');

        // test level 13
        item.xp = 169;
        let greatness = ImplAdventurer::get_greatness(item);
        assert(greatness == 13, 'greatness should be 13');

        // test level 14
        item.xp = 196;
        let greatness = ImplAdventurer::get_greatness(item);
        assert(greatness == 14, 'greatness should be 14');

        // test level 15
        item.xp = 225;
        let greatness = ImplAdventurer::get_greatness(item);
        assert(greatness == 15, 'greatness should be 15');

        // test level 16
        item.xp = 256;
        let greatness = ImplAdventurer::get_greatness(item);
        assert(greatness == 16, 'greatness should be 16');

        // test level 17
        item.xp = 289;
        let greatness = ImplAdventurer::get_greatness(item);
        assert(greatness == 17, 'greatness should be 17');

        // test level 18
        item.xp = 324;
        let greatness = ImplAdventurer::get_greatness(item);
        assert(greatness == 18, 'greatness should be 18');

        // test level 19
        item.xp = 361;
        let greatness = ImplAdventurer::get_greatness(item);
        assert(greatness == 19, 'greatness should be 19');

        // test level 20
        item.xp = 400;
        let greatness = ImplAdventurer::get_greatness(item);
        assert(greatness == 20, 'greatness should be 20');

        // test overflow / max u16
        item.xp = 65535;
        let greatness = ImplAdventurer::get_greatness(item);
        assert(greatness == 20, 'greatness should be 20');
    }

    #[test]
    #[available_gas(55630)]
    fn test_set_last_action() {
        let mut adventurer = ImplAdventurer::new(
            12,
            0,
            Stats {
                strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
            }
        );
        adventurer.last_action.set_last_action(0);
        assert(adventurer.last_action == 0, 'last action should be 0');
        adventurer.last_action.set_last_action(511);
        assert(adventurer.last_action == 511, 'last action should be 511');
        adventurer.last_action.set_last_action(512);
        assert(adventurer.last_action == 0, 'last action should be 0');
        adventurer.last_action.set_last_action(1023);
        assert(adventurer.last_action == 511, 'last action should be 511');
        adventurer.last_action.set_last_action(1024);
        assert(adventurer.last_action == 0, 'last action should be 0');
    }

    #[test]
    #[available_gas(200000)]
    fn test_charisma_adjusted_item_price() {
        let mut adventurer = ImplAdventurer::new(
            12,
            0,
            Stats {
                strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
            }
        );

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
    #[available_gas(290000)]
    fn test_charisma_adjusted_potion_price() {
        let starting_stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
        };
        let mut adventurer = ImplAdventurer::new(12, 0, starting_stats);

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
    #[available_gas(150000)]
    fn test_get_idle_blocks() {
        let starting_stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
        };
        let mut adventurer = ImplAdventurer::new(12, 0, starting_stats);
        adventurer.last_action = 1;

        // test with current block greater than last action
        assert(adventurer.get_idle_blocks(3) == 2, 'idle blocks should be 2');
        assert(adventurer.get_idle_blocks(10) == 9, 'idle blocks should be 9');

        // test with current block less than last action
        assert(adventurer.get_idle_blocks(0) == 511, 'idle blocks should be 511');
        adventurer.last_action = 511;
        assert(adventurer.get_idle_blocks(511) == 0, 'idle blocks should be 0');
        assert(adventurer.get_idle_blocks(0) == 1, 'idle blocks should be 1');
    }

    #[test]
    #[available_gas(3000000)]
    fn test_packing_and_unpacking_adventurer() {
        let adventurer = Adventurer {
            last_action: 511,
            health: 511,
            xp: 8191,
            stats: Stats {
                strength: 31,
                dexterity: 31,
                vitality: 31,
                intelligence: 31,
                wisdom: 31,
                charisma: 31,
            },
            gold: 511,
            weapon: ItemPrimitive { id: 127, xp: 511, metadata: 31, },
            chest: ItemPrimitive { id: 1, xp: 0, metadata: 0, },
            head: ItemPrimitive { id: 127, xp: 511, metadata: 31, },
            waist: ItemPrimitive { id: 87, xp: 511, metadata: 4, },
            foot: ItemPrimitive { id: 78, xp: 511, metadata: 5, },
            hand: ItemPrimitive { id: 34, xp: 511, metadata: 6, },
            neck: ItemPrimitive { id: 32, xp: 511, metadata: 7, },
            ring: ItemPrimitive { id: 1, xp: 511, metadata: 8, },
            beast_health: 511,
            stat_points_available: 7,
            mutated: false
        };
        let packed = adventurer.pack();
        let unpacked: Adventurer = Packing::unpack(packed);
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
            adventurer.stat_points_available == unpacked.stat_points_available,
            'stat_points_available'
        );
    }

    #[test]
    #[available_gas(3000000)]
    fn test_packing_stat_overflow_protection() {
        // create an adventurer with stats at max u8
        let adventurer = Adventurer {
            last_action: 511,
            health: 511,
            xp: 8191,
            stats: Stats {
                strength: 255,
                dexterity: 255,
                vitality: 255,
                intelligence: 255,
                wisdom: 255,
                charisma: 255,
            },
            gold: 511,
            weapon: ItemPrimitive { id: 127, xp: 511, metadata: 31, },
            chest: ItemPrimitive { id: 1, xp: 0, metadata: 0, },
            head: ItemPrimitive { id: 127, xp: 511, metadata: 31, },
            waist: ItemPrimitive { id: 87, xp: 511, metadata: 4, },
            foot: ItemPrimitive { id: 78, xp: 511, metadata: 5, },
            hand: ItemPrimitive { id: 34, xp: 511, metadata: 6, },
            neck: ItemPrimitive { id: 32, xp: 511, metadata: 7, },
            ring: ItemPrimitive { id: 1, xp: 511, metadata: 8, },
            beast_health: 511,
            stat_points_available: 7,
            mutated: false
        };

        // pack adventurer
        let packed = adventurer.pack();

        // unpack adventurer
        let unpacked: Adventurer = Packing::unpack(packed);

        // verify packing function didn't overflow stats
        // but instead set values to max
        assert(unpacked.stats.strength == MAX_STAT_VALUE, 'strength');
        assert(unpacked.stats.dexterity == MAX_STAT_VALUE, 'dexterity');
        assert(unpacked.stats.vitality == MAX_STAT_VALUE, 'vitality');
        assert(unpacked.stats.intelligence == MAX_STAT_VALUE, 'intelligence');
        assert(unpacked.stats.wisdom == MAX_STAT_VALUE, 'wisdom');
        assert(unpacked.stats.charisma == MAX_STAT_VALUE, 'charisma');
    }

    #[test]
    #[available_gas(2000000)]
    fn test_new_adventurer() {
        let starting_stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
        };
        let mut adventurer = ImplAdventurer::new(12, 0, starting_stats);
        adventurer.pack();
        assert(adventurer.health == STARTING_HEALTH, 'wrong starting health');
        assert(adventurer.gold == STARTING_GOLD, 'wrong starting gold');
        assert(adventurer.xp == 0, 'wrong starting xp');
    }

    #[test]
    #[available_gas(200000)]
    fn test_increase_health() {
        let starting_stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
        };
        let mut adventurer = ImplAdventurer::new(12, 0, starting_stats);

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
    #[available_gas(2600000)]
    fn test_increase_gold() {
        let starting_stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
        };
        let mut adventurer = ImplAdventurer::new(12, 0, starting_stats);

        // assert starting state
        assert(adventurer.gold == STARTING_GOLD, 'wrong advntr starting gold');

        // base case
        adventurer.increase_gold(5);
        assert(adventurer.gold == STARTING_GOLD + 5, 'gold should be +5');

        // at max value case
        adventurer.increase_gold(MAX_GOLD);
        assert(adventurer.gold == MAX_GOLD, 'gold should be max');

        // pack and unpack adventurer to test overflow in packing
        let unpacked: Adventurer = Packing::unpack(adventurer.pack());
        assert(unpacked.gold == MAX_GOLD, 'should still be max gold');

        // extreme/overflow case
        adventurer.gold = 65535;
        adventurer.increase_gold(65535);
        assert(adventurer.gold == MAX_GOLD, 'gold overflow check');
    }

    #[test]
    #[available_gas(50610)]
    fn test_decrease_health() {
        let starting_stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
        };
        let mut adventurer = ImplAdventurer::new(12, 0, starting_stats);
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
    #[available_gas(53000)]
    fn test_deduct_gold() {
        let starting_stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
        };
        let mut adventurer = ImplAdventurer::new(12, 0, starting_stats);
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
    #[available_gas(250000)]
    fn test_increase_adventurer_xp() {
        let starting_stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
        };
        let mut adventurer = ImplAdventurer::new(12, 0, starting_stats);
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
        let (previous_level, new_level) = adventurer.increase_adventurer_xp(MAX_XP + 10);
        assert(adventurer.xp == MAX_XP, 'xp should stop at max xp');
        assert(previous_level == 2, 'prev level should be 2');
        assert(new_level == 90, 'new level should be 90');

        // u16 overflow case
        adventurer.increase_adventurer_xp(65535);
        assert(adventurer.xp == MAX_XP, 'xp should be max on overflow');
    }

    #[test]
    #[available_gas(3000000)]
    fn test_increase_stat_points_available() {
        // get new adventurer
        let starting_stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
        };
        let mut adventurer = ImplAdventurer::new(12, 0, starting_stats);
        let original_stat_points = adventurer.stat_points_available;

        // zero case
        adventurer.stat_points_available.increase_stat_points_available(0);
        assert(
            adventurer.stat_points_available == original_stat_points,
            'stat points should not change'
        );

        // base case - adding 1 stat point (no need to pack and unpack this test case)
        adventurer.stat_points_available.increase_stat_points_available(1);
        assert(
            adventurer.stat_points_available == 1 + original_stat_points, 'stat points should be +1'
        );

        // max stat upgrade value case
        adventurer.stat_points_available.increase_stat_points_available(MAX_STAT_UPGRADES);
        assert(adventurer.stat_points_available == MAX_STAT_UPGRADES, 'stat points should be max');

        // pack and unpack at max value to ensure our max values are correct for packing
        let unpacked: Adventurer = Packing::unpack(adventurer.pack());
        assert(
            unpacked.stat_points_available == MAX_STAT_UPGRADES, 'stat point should still be max'
        );

        // extreme/overflow case
        adventurer.stat_points_available = 255;
        adventurer.stat_points_available.increase_stat_points_available(255);
        assert(adventurer.stat_points_available == MAX_STAT_UPGRADES, 'stat points should be max');
    }

    #[test]
    #[available_gas(90000)]
    fn test_increase_strength() {
        let starting_stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
        };
        let mut adventurer = ImplAdventurer::new(12, 0, starting_stats);
        // basic case
        adventurer.stats.increase_strength(1);
        assert(adventurer.stats.strength == 1, 'strength should be 1');
        // overflow case
        adventurer.stats.increase_strength(255);
        assert(adventurer.stats.strength == MAX_STAT_VALUE, 'strength should be max');
    }

    #[test]
    #[available_gas(90000)]
    fn test_increase_dexterity() {
        let starting_stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
        };
        let mut adventurer = ImplAdventurer::new(12, 0, starting_stats);
        // basic case
        adventurer.stats.increase_dexterity(1);
        assert(adventurer.stats.dexterity == 1, 'dexterity should be 1');
        // overflow case
        adventurer.stats.increase_dexterity(255);
        assert(adventurer.stats.dexterity == MAX_STAT_VALUE, 'dexterity should be max');
    }

    #[test]
    #[available_gas(90000)]
    fn test_increase_vitality() {
        let starting_stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
        };
        let mut adventurer = ImplAdventurer::new(12, 0, starting_stats);
        // basic case
        adventurer.stats.increase_vitality(1);
        assert(adventurer.stats.vitality == 1, 'vitality should be 1');
        // overflow case
        adventurer.stats.increase_vitality(255);
        assert(adventurer.stats.vitality == MAX_STAT_VALUE, 'vitality should be max');
    }

    #[test]
    #[available_gas(90000)]
    fn test_increase_intelligence() {
        let starting_stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
        };
        let mut adventurer = ImplAdventurer::new(12, 0, starting_stats);
        // basic case
        adventurer.stats.increase_intelligence(1);
        assert(adventurer.stats.intelligence == 1, 'intelligence should be 1');
        // overflow case
        adventurer.stats.increase_intelligence(255);
        assert(adventurer.stats.intelligence == MAX_STAT_VALUE, 'intelligence should be max');
    }

    #[test]
    #[available_gas(90000)]
    fn test_increase_wisdom() {
        let starting_stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
        };
        let mut adventurer = ImplAdventurer::new(12, 0, starting_stats);
        // basic case
        adventurer.stats.increase_wisdom(1);
        assert(adventurer.stats.wisdom == 1, 'wisdom should be 1');
        // overflow case
        adventurer.stats.increase_wisdom(255);
        assert(adventurer.stats.wisdom == MAX_STAT_VALUE, 'wisdom should be max');
    }

    #[test]
    #[available_gas(90000)]
    fn test_increase_charisma() {
        let starting_stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
        };
        let mut adventurer = ImplAdventurer::new(12, 0, starting_stats);
        // basic case
        adventurer.stats.increase_charisma(1);
        assert(adventurer.stats.charisma == 1, 'charisma should be 1');
        // overflow case
        adventurer.stats.increase_charisma(255);
        assert(adventurer.stats.charisma == MAX_STAT_VALUE, 'charisma should be max');
    }

    #[test]
    #[available_gas(90000)]
    fn test_decrease_strength() {
        let starting_stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
        };
        let mut adventurer = ImplAdventurer::new(12, 0, starting_stats);
        // basic case
        adventurer.stats.increase_strength(2);
        adventurer.stats.decrease_strength(1);
        assert(adventurer.stats.strength == 1, 'strength should be 1');
        // underflow case
        adventurer.stats.increase_strength(5);
        adventurer.stats.decrease_strength(255);
        assert(adventurer.stats.strength == 0, 'strength should be 0');
    }

    #[test]
    #[available_gas(90000)]
    fn test_decrease_dexterity() {
        let starting_stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
        };
        let mut adventurer = ImplAdventurer::new(12, 0, starting_stats);
        // basic case
        adventurer.stats.increase_dexterity(2);
        adventurer.stats.decrease_dexterity(1);
        assert(adventurer.stats.dexterity == 1, 'dexterity should be 1');
        // underflow case
        adventurer.stats.increase_dexterity(5);
        adventurer.stats.decrease_dexterity(255);
        assert(adventurer.stats.dexterity == 0, 'dexterity should be 0');
    }

    #[test]
    #[available_gas(90000)]
    fn test_decrease_vitality() {
        let starting_stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
        };
        let mut adventurer = ImplAdventurer::new(12, 0, starting_stats);
        // basic case
        adventurer.stats.increase_vitality(2);
        adventurer.stats.decrease_vitality(1);
        assert(adventurer.stats.vitality == 1, 'vitality should be 1');
        // underflow case
        adventurer.stats.increase_vitality(5);
        adventurer.stats.decrease_vitality(255);
        assert(adventurer.stats.vitality == 0, 'vitality should be 0');
    }

    #[test]
    #[available_gas(90000)]
    fn test_decrease_intelligence() {
        let starting_stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
        };
        let mut adventurer = ImplAdventurer::new(12, 0, starting_stats);
        // basic case
        adventurer.stats.increase_intelligence(2);
        adventurer.stats.decrease_intelligence(1);
        assert(adventurer.stats.intelligence == 1, 'intelligence should be 1');
        // underflow case
        adventurer.stats.increase_intelligence(5);
        adventurer.stats.decrease_intelligence(255);
        assert(adventurer.stats.intelligence == 0, 'intelligence should be 0');
    }

    #[test]
    #[available_gas(90000)]
    fn test_decrease_wisdom_gas() {
        let mut adventurer = ImplAdventurer::new(
            12,
            0,
            Stats {
                strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 1, charisma: 0,
            }
        );
        adventurer.stats.decrease_wisdom(1);
    }

    #[test]
    #[available_gas(90000)]
    fn test_decrease_wisdom() {
        let starting_stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
        };
        let mut adventurer = ImplAdventurer::new(12, 0, starting_stats);
        // basic case
        adventurer.stats.increase_wisdom(2);
        adventurer.stats.decrease_wisdom(1);
        assert(adventurer.stats.wisdom == 1, 'wisdom should be 1');
        // underflow case
        adventurer.stats.increase_wisdom(5);
        adventurer.stats.decrease_wisdom(255);
        assert(adventurer.stats.wisdom == 0, 'wisdom should be 0');
    }

    #[test]
    #[available_gas(90000)]
    fn test_decrease_charisma() {
        let starting_stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
        };
        let mut adventurer = ImplAdventurer::new(12, 0, starting_stats);
        // basic case
        adventurer.stats.increase_charisma(2);
        adventurer.stats.decrease_charisma(1);
        assert(adventurer.stats.charisma == 1, 'charisma should be 1');

        // underflow case
        adventurer.stats.increase_charisma(5);
        adventurer.stats.decrease_charisma(255);
        assert(adventurer.stats.charisma == 0, 'charisma should be 0');
    }

    // TODO: Use conditional compilation to test this in the future
    // see https://docs.swmansion.com/scarb/docs/reference/conditional-compilation.html
    // #[test]
    // #[should_panic(expected: ('Item is not weapon',))]
    // #[available_gas(90000)]
    // fn test_equip_invalid_weapon() {
    //     let starting_stats = Stats {
    //         strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
    //     };
    //     let mut adventurer = ImplAdventurer::new(12, 0, starting_stats);
    //     // create demon crown item
    //     let item = ItemPrimitive { id: ItemId::DemonCrown, xp: 1, metadata: 0 };
    //     // try to equip it to adventurer as a weapon
    //     adventurer.equip_weapon(item);
    // // should panic with 'Item is not weapon' message
    // // because demon crown is not a weapon
    // // test is annotated to expect this panic and will
    // // pass if it does, otherwise it will fail
    // }

    #[test]
    #[available_gas(90000)]
    fn test_equip_valid_weapon() {
        let starting_stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
        };
        let mut adventurer = ImplAdventurer::new(12, 0, starting_stats);

        // Create Katana item
        let item = ItemPrimitive { id: ItemId::Katana, xp: 1, metadata: 0 };

        // Equip to adventurer as a weapon
        adventurer.equip_weapon(item);

        // Assert item was equipped
        assert(adventurer.weapon.id == ItemId::Katana, 'did not equip weapon');
        assert(adventurer.weapon.xp == 1, 'weapon xp is not 1');
        assert(adventurer.weapon.metadata == 0, 'weapon metadata is not 0');
    }

    // TODO: Use conditional compilation to test this in the future
    // see https://docs.swmansion.com/scarb/docs/reference/conditional-compilation.html
    // #[test]
    // #[should_panic(expected: ('Item is not chest armor',))]
    // #[available_gas(90000)]
    // fn test_equip_invalid_chest() {
    //     let starting_stats = Stats {
    //         strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
    //     };
    //     let mut adventurer = ImplAdventurer::new(12, 0, starting_stats);
    //     // try to equip a Demon Crown as chest item
    //     let item = ItemPrimitive { id: ItemId::DemonCrown, xp: 1, metadata: 0 };
    //     adventurer.equip_chest_armor(item);
    // // should panic with 'Item is not chest armor' message
    // // because Demon Crown is not chest armor
    // // test is annotated to expect this panic and will
    // // pass if it does, otherwise it will fail
    // }

    #[test]
    #[available_gas(90000)]
    fn test_equip_valid_chest() {
        let starting_stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
        };
        let mut adventurer = ImplAdventurer::new(12, 0, starting_stats);
        // equip Divine Robe as chest item
        let item = ItemPrimitive { id: ItemId::DivineRobe, xp: 1, metadata: 0 };
        adventurer.equip_chest_armor(item);

        // this should not panic
        // assert item was equipped
        assert(adventurer.chest.id == ItemId::DivineRobe, 'did not equip chest armor');
        assert(adventurer.chest.xp == 1, 'chest armor xp is not 1');
        assert(adventurer.chest.metadata == 0, 'chest armor metadata is not 0');
    }

    // TODO: Use conditional compilation to test this in the future
    // see https://docs.swmansion.com/scarb/docs/reference/conditional-compilation.html
    // #[test]
    // #[should_panic(expected: ('Item is not head armor',))]
    // #[available_gas(90000)]
    // fn test_equip_invalid_head() {
    //     let starting_stats = Stats {
    //         strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
    //     };
    //     let mut adventurer = ImplAdventurer::new(12, 0, starting_stats);
    //     // try to equip a Katana as head item
    //     let item = ItemPrimitive { id: ItemId::Katana, xp: 1, metadata: 0 };
    //     adventurer.equip_head_armor(item);
    // // should panic with 'Item is not head armor' message
    // }

    #[test]
    #[available_gas(90000)]
    fn test_equip_valid_head() {
        let starting_stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
        };
        let mut adventurer = ImplAdventurer::new(12, 0, starting_stats);
        // equip Crown as head item
        let item = ItemPrimitive { id: ItemId::Crown, xp: 1, metadata: 0 };
        adventurer.equip_head_armor(item);
        // this should not panic
        // assert item was equipped
        assert(adventurer.head.id == ItemId::Crown, 'did not equip head armor');
        assert(adventurer.head.xp == 1, 'head armor xp is not 1');
        assert(adventurer.head.metadata == 0, 'head armor metadata is not 0');
    }

    // TODO: Use conditional compilation to test this in the future
    // see https://docs.swmansion.com/scarb/docs/reference/conditional-compilation.html
    // #[test]
    // #[should_panic(expected: ('Item is not waist armor',))]
    // #[available_gas(90000)]
    // fn test_equip_invalid_waist() {
    //     let starting_stats = Stats {
    //         strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
    //     };
    //     let mut adventurer = ImplAdventurer::new(12, 0, starting_stats);
    //     // try to equip a Demon Crown as waist item
    //     let item = ItemPrimitive { id: ItemId::DemonCrown, xp: 1, metadata: 0 };
    //     adventurer.equip_waist_armor(item);
    // // should panic with 'Item is not waist armor' message
    // }

    #[test]
    #[available_gas(90000)]
    fn test_equip_valid_waist() {
        let starting_stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
        };
        let mut adventurer = ImplAdventurer::new(12, 0, starting_stats);

        // equip Wool Sash as waist item
        let item = ItemPrimitive { id: ItemId::WoolSash, xp: 1, metadata: 0 };
        adventurer.equip_waist_armor(item);

        // this should not panic
        // assert item was equipped
        assert(adventurer.waist.id == ItemId::WoolSash, 'did not equip waist armor');
        assert(adventurer.waist.xp == 1, 'waist armor xp is not 1');
        assert(adventurer.waist.metadata == 0, 'waist armor metadata is not 0');
    }

    // TODO: Use conditional compilation to test this in the future
    // see https://docs.swmansion.com/scarb/docs/reference/conditional-compilation.html
    // #[test]
    // #[should_panic(expected: ('Item is not foot armor',))]
    // #[available_gas(90000)]
    // fn test_equip_invalid_foot() {
    //     let starting_stats = Stats {
    //         strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
    //     };
    //     let mut adventurer = ImplAdventurer::new(12, 0, starting_stats);
    //     // try to equip a Demon Crown as foot item
    //     let item = ItemPrimitive { id: ItemId::DemonCrown, xp: 1, metadata: 0 };
    //     adventurer.equip_foot_armor(item);
    // // should panic with 'Item is not foot armor' message
    // }

    #[test]
    #[available_gas(90000)]
    fn test_equip_valid_foot() {
        let starting_stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
        };
        let mut adventurer = ImplAdventurer::new(12, 0, starting_stats);

        // equip Silk Slippers as foot item
        let item = ItemPrimitive { id: ItemId::SilkSlippers, xp: 1, metadata: 0 };
        adventurer.equip_foot_armor(item);

        // this should not panic
        // assert item was equipped
        assert(adventurer.foot.id == ItemId::SilkSlippers, 'did not equip foot armor');
        assert(adventurer.foot.xp == 1, 'foot armor xp is not 1');
        assert(adventurer.foot.metadata == 0, 'foot armor metadata is not 0');
    }

    // TODO: Use conditional compilation to test this in the future
    // see https://docs.swmansion.com/scarb/docs/reference/conditional-compilation.html
    // #[test]
    // #[should_panic(expected: ('Item is not hand armor',))]
    // #[available_gas(90000)]
    // fn test_equip_invalid_hand() {
    //     let starting_stats = Stats {
    //         strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
    //     };
    //     let mut adventurer = ImplAdventurer::new(12, 0, starting_stats);

    //     // try to equip a Demon Crown as hand item
    //     let item = ItemPrimitive { id: ItemId::DemonCrown, xp: 1, metadata: 0 };
    //     adventurer.equip_hand_armor(item);
    // // should panic with 'Item is not hand armor' message
    // }

    #[test]
    #[available_gas(90000)]
    fn test_equip_valid_hand() {
        let starting_stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
        };
        let mut adventurer = ImplAdventurer::new(12, 0, starting_stats);

        // equip Divine Gloves as hand item
        let item = ItemPrimitive { id: ItemId::DivineGloves, xp: 1, metadata: 0 };
        adventurer.equip_hand_armor(item);

        // this should not panic
        // assert item was equipped
        assert(adventurer.hand.id == ItemId::DivineGloves, 'did not equip hand armor');
        assert(adventurer.hand.xp == 1, 'hand armor xp is not 1');
        assert(adventurer.hand.metadata == 0, 'hand armor metadata is not 0');
    }

    // TODO: Use conditional compilation to test this in the future
    // see https://docs.swmansion.com/scarb/docs/reference/conditional-compilation.html
    // #[test]
    // #[should_panic(expected: ('Item is not necklace',))]
    // #[available_gas(90000)]
    // fn test_equip_invalid_neck() {
    //     let starting_stats = Stats {
    //         strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
    //     };
    //     let mut adventurer = ImplAdventurer::new(12, 0, starting_stats);

    //     // try to equip a Demon Crown as necklace
    //     let item = ItemPrimitive { id: ItemId::DemonCrown, xp: 1, metadata: 0 };
    //     adventurer.equip_necklace(item);
    // // should panic with 'Item is not necklace' message
    // }

    #[test]
    #[available_gas(90000)]
    fn test_equip_valid_neck() {
        let starting_stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
        };
        let mut adventurer = ImplAdventurer::new(12, 0, starting_stats);

        // equip Pendant as necklace
        let item = ItemPrimitive { id: ItemId::Pendant, xp: 1, metadata: 0 };
        adventurer.equip_necklace(item);

        // this should not panic
        // assert item was equipped
        assert(adventurer.neck.id == ItemId::Pendant, 'did not equip necklace');
        assert(adventurer.neck.xp == 1, 'necklace xp is not 1');
        assert(adventurer.neck.metadata == 0, 'necklace metadata is not 0');
    }

    // TODO: Use conditional compilation to test this in the future
    // see https://docs.swmansion.com/scarb/docs/reference/conditional-compilation.html
    // #[test]
    // #[should_panic(expected: ('Item is not a ring',))]
    // #[available_gas(90000)]
    // fn test_equip_invalid_ring() {
    //     let starting_stats = Stats {
    //         strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
    //     };
    //     let mut adventurer = ImplAdventurer::new(12, 0, starting_stats);

    //     // try to equip a Demon Crown as ring
    //     let item = ItemPrimitive { id: ItemId::DemonCrown, xp: 1, metadata: 0 };
    //     adventurer.equip_ring(item);
    // // should panic with 'Item is not a ring' message
    // }

    #[test]
    #[available_gas(90000)]
    fn test_equip_valid_ring() {
        let mut adventurer = ImplAdventurer::new(
            12,
            0,
            Stats {
                strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
            }
        );
        let item = ItemPrimitive { id: ItemId::PlatinumRing, xp: 1, metadata: 0 };
        adventurer.equip_ring(item);
        assert(adventurer.ring.id == ItemId::PlatinumRing, 'did not equip ring');
        assert(adventurer.ring.xp == 1, 'ring xp is not 1');
        assert(adventurer.ring.metadata == 0, 'ring metadata is not 0');
    }

    #[test]
    #[available_gas(52230)]
    fn test_increase_item_xp_at_slot_gas() {
        let mut adventurer = ImplAdventurer::new(
            12,
            0,
            Stats {
                strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
            }
        );
        adventurer.increase_item_xp_at_slot(Slot::Weapon(()), 1);
    }

    #[test]
    #[available_gas(234830)]
    fn test_increase_item_xp_at_slot() {
        let mut adventurer = ImplAdventurer::new(
            12,
            0,
            Stats {
                strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
            }
        );

        // assert starting conditions
        assert(adventurer.weapon.xp == 0, 'weapon should start with 0xp');
        assert(adventurer.chest.xp == 0, 'chest should start with 0xp');
        assert(adventurer.head.xp == 0, 'head should start with 0xp');
        assert(adventurer.waist.xp == 0, 'waist should start with 0xp');
        assert(adventurer.foot.xp == 0, 'foot should start with 0xp');
        assert(adventurer.hand.xp == 0, 'hand should start with 0xp');
        assert(adventurer.neck.xp == 0, 'neck should start with 0xp');
        assert(adventurer.ring.xp == 0, 'ring should start with 0xp');

        adventurer.increase_item_xp_at_slot(Slot::Weapon(()), 1);
        assert(adventurer.weapon.xp == 1, 'weapon should have 1xp');

        adventurer.increase_item_xp_at_slot(Slot::Chest(()), 1);
        assert(adventurer.chest.xp == 1, 'chest should have 1xp');

        adventurer.increase_item_xp_at_slot(Slot::Head(()), 1);
        assert(adventurer.head.xp == 1, 'head should have 1xp');

        adventurer.increase_item_xp_at_slot(Slot::Waist(()), 1);
        assert(adventurer.waist.xp == 1, 'waist should have 1xp');

        adventurer.increase_item_xp_at_slot(Slot::Foot(()), 1);
        assert(adventurer.foot.xp == 1, 'foot should have 1xp');

        adventurer.increase_item_xp_at_slot(Slot::Hand(()), 1);
        assert(adventurer.hand.xp == 1, 'hand should have 1xp');

        adventurer.increase_item_xp_at_slot(Slot::Neck(()), 1);
        assert(adventurer.neck.xp == 1, 'neck should have 1xp');

        adventurer.increase_item_xp_at_slot(Slot::Ring(()), 1);
        assert(adventurer.ring.xp == 1, 'ring should have 1xp');
    }

    #[test]
    #[available_gas(53030)]
    fn test_increase_item_xp_at_slot_max() {
        let mut adventurer = ImplAdventurer::new(
            12,
            0,
            Stats {
                strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
            }
        );

        assert(adventurer.weapon.xp == 0, 'weapon should start with 0xp');
        adventurer.increase_item_xp_at_slot(Slot::Weapon(()), 65535);
        assert(adventurer.weapon.xp == ITEM_MAX_XP, 'weapon should have have xp');
    }

    #[test]
    #[available_gas(53030)]
    fn test_increase_item_xp_at_slot_zero() {
        let mut adventurer = ImplAdventurer::new(
            12,
            0,
            Stats {
                strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
            }
        );

        assert(adventurer.weapon.xp == 0, 'weapon should start with 0xp');
        adventurer.increase_item_xp_at_slot(Slot::Weapon(()), 0);
        assert(adventurer.weapon.xp == 0, 'weapon should still have 0xp');
    }

    #[test]
    #[available_gas(302010)]
    fn test_get_equipped_items() {
        let mut adventurer = ImplAdventurer::new(
            ItemId::Wand,
            0,
            Stats {
                strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
            }
        );

        let starting_equipment = adventurer.get_equipped_items();
        assert(starting_equipment.len() == 1, 'adventurer starts with 1 item');
        assert(*starting_equipment.at(0).id == ItemId::Wand, 'adventurer starts with wand');

        // equip chest armor
        let chest = ItemPrimitive { id: ItemId::DivineRobe, xp: 1, metadata: 2 };
        adventurer.equip_chest_armor(chest);

        // assert we now have two items equipped
        let equipped_items = adventurer.get_equipped_items();
        assert(equipped_items.len() == 2, 'should have 2 items equipped');
        assert(*equipped_items.at(0).id == ItemId::Wand, 'should have wand equipped');
        assert(*equipped_items.at(1).id == ItemId::DivineRobe, 'should have robe equipped');

        // equip head armor
        let head = ItemPrimitive { id: ItemId::Crown, xp: 1, metadata: 3 };
        adventurer.equip_head_armor(head);

        // assert we now have three items equipped
        let equipped_items = adventurer.get_equipped_items();
        assert(equipped_items.len() == 3, 'should have 3 items equipped');
        assert(*equipped_items.at(0).id == ItemId::Wand, 'should have wand equipped');
        assert(*equipped_items.at(1).id == ItemId::DivineRobe, 'should have robe equipped');
        assert(*equipped_items.at(2).id == ItemId::Crown, 'should have crown equipped');

        // equip waist armor
        let waist = ItemPrimitive { id: ItemId::DemonhideBelt, xp: 1, metadata: 4 };
        adventurer.equip_waist_armor(waist);

        // assert we now have four items equipped
        let equipped_items = adventurer.get_equipped_items();
        assert(equipped_items.len() == 4, 'should have 4 items equipped');
        assert(*equipped_items.at(0).id == ItemId::Wand, 'should have wand equipped');
        assert(*equipped_items.at(1).id == ItemId::DivineRobe, 'should have robe equipped');
        assert(*equipped_items.at(2).id == ItemId::Crown, 'should have crown equipped');
        assert(*equipped_items.at(3).id == ItemId::DemonhideBelt, 'should have belt equipped');

        // equip foot armor
        let foot = ItemPrimitive { id: ItemId::LeatherBoots, xp: 1, metadata: 5 };
        adventurer.equip_foot_armor(foot);

        // assert we now have five items equipped
        let equipped_items = adventurer.get_equipped_items();
        assert(equipped_items.len() == 5, 'should have 5 items equipped');
        assert(*equipped_items.at(0).id == ItemId::Wand, 'should have wand equipped');
        assert(*equipped_items.at(1).id == ItemId::DivineRobe, 'should have robe equipped');
        assert(*equipped_items.at(2).id == ItemId::Crown, 'should have crown equipped');
        assert(*equipped_items.at(3).id == ItemId::DemonhideBelt, 'should have belt equipped');
        assert(*equipped_items.at(4).id == ItemId::LeatherBoots, 'should have boots equipped');

        // equip hand armor
        let hand = ItemPrimitive { id: ItemId::LeatherGloves, xp: 1, metadata: 6 };
        adventurer.equip_hand_armor(hand);

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
        let neck = ItemPrimitive { id: ItemId::Amulet, xp: 1, metadata: 7 };
        adventurer.equip_necklace(neck);

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
        let ring = ItemPrimitive { id: ItemId::GoldRing, xp: 1, metadata: 8 };
        adventurer.equip_ring(ring);

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
        let weapon = ItemPrimitive { id: ItemId::Katana, xp: 1, metadata: 1 };
        adventurer.equip_weapon(weapon);

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
    #[available_gas(90000)]
    #[test]
    #[available_gas(60000)]
    fn test_set_beast_health() {
        let starting_stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
        };
        let mut adventurer = ImplAdventurer::new(12, 0, starting_stats);

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
    #[available_gas(90000)]
    fn test_deduct_beast_health() {
        let starting_stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
        };
        let mut adventurer = ImplAdventurer::new(12, 0, starting_stats);

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
        let mut adventurer = ImplAdventurer::new(
            12,
            0,
            Stats {
                strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
            }
        );

        // stage items
        let weapon = ItemPrimitive { id: ItemId::Katana, xp: 1, metadata: 1 };
        let chest = ItemPrimitive { id: ItemId::DivineRobe, xp: 1, metadata: 2 };
        let head = ItemPrimitive { id: ItemId::Crown, xp: 1, metadata: 3 };
        let waist = ItemPrimitive { id: ItemId::DemonhideBelt, xp: 1, metadata: 4 };
        let foot = ItemPrimitive { id: ItemId::LeatherBoots, xp: 1, metadata: 5 };
        let hand = ItemPrimitive { id: ItemId::LeatherGloves, xp: 1, metadata: 6 };
        let neck = ItemPrimitive { id: ItemId::Amulet, xp: 1, metadata: 7 };
        let ring = ItemPrimitive { id: ItemId::GoldRing, xp: 1, metadata: 8 };

        // equip items
        adventurer.equip_weapon(weapon);
        adventurer.equip_chest_armor(chest);
        adventurer.equip_head_armor(head);
        adventurer.equip_waist_armor(waist);
        adventurer.equip_foot_armor(foot);
        adventurer.equip_hand_armor(hand);
        adventurer.equip_necklace(neck);
        adventurer.equip_ring(ring);

        // verify getting item by slot returns correct items
        assert(adventurer.get_item_at_slot(Slot::Weapon(())) == weapon, 'wrong weapon');
        assert(adventurer.get_item_at_slot(Slot::Chest(())) == chest, 'wrong chest armor');
        assert(adventurer.get_item_at_slot(Slot::Head(())) == head, 'wrong head armor');
        assert(adventurer.get_item_at_slot(Slot::Waist(())) == waist, 'wrong waist armor');
        assert(adventurer.get_item_at_slot(Slot::Foot(())) == foot, 'wrong foot armor');
        assert(adventurer.get_item_at_slot(Slot::Hand(())) == hand, 'wrong hand armor');
        assert(adventurer.get_item_at_slot(Slot::Neck(())) == neck, 'wrong necklace');
        assert(adventurer.get_item_at_slot(Slot::Ring(())) == ring, 'wrong ring');
    }

    #[test]
    #[available_gas(340000)]
    fn test_is_slot_free() {
        let mut adventurer = ImplAdventurer::new(
            12,
            0,
            Stats {
                strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
            }
        );

        // stage items
        let weapon = ItemPrimitive { id: ItemId::Katana, xp: 1, metadata: 1 };
        let chest = ItemPrimitive { id: ItemId::DivineRobe, xp: 1, metadata: 2 };
        let head = ItemPrimitive { id: ItemId::Crown, xp: 1, metadata: 3 };
        let waist = ItemPrimitive { id: ItemId::DemonhideBelt, xp: 1, metadata: 4 };
        let foot = ItemPrimitive { id: ItemId::LeatherBoots, xp: 1, metadata: 5 };
        let hand = ItemPrimitive { id: ItemId::LeatherGloves, xp: 1, metadata: 6 };
        let neck = ItemPrimitive { id: ItemId::Amulet, xp: 1, metadata: 7 };
        let ring = ItemPrimitive { id: ItemId::GoldRing, xp: 1, metadata: 8 };

        // equip half the items, adventurer will have nothing equipped for the other slots
        adventurer.equip_weapon(weapon);
        adventurer.equip_head_armor(head);
        adventurer.equip_foot_armor(foot);
        adventurer.equip_necklace(neck);

        // verify is_slot_free returns correct values
        assert(adventurer.is_slot_free(weapon) == false, 'weapon slot should be occupied');
        assert(adventurer.is_slot_free(chest) == true, 'chest slot should be free');
        assert(adventurer.is_slot_free(head) == false, 'head slot should be occupied');
        assert(adventurer.is_slot_free(waist) == true, 'waist slot should be free');
        assert(adventurer.is_slot_free(foot) == false, 'foot slot should be occupied');
        assert(adventurer.is_slot_free(hand) == true, 'hand slot should be free');
        assert(adventurer.is_slot_free(neck) == false, 'neck slot should be occupied');
        assert(adventurer.is_slot_free(ring) == true, 'ring slot should be free');
    }

    #[test]
    #[available_gas(600000)]
    fn test_get_level() {
        let starting_stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
        };
        let mut adventurer = ImplAdventurer::new(12, 0, starting_stats);
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
    #[available_gas(200000)]
    fn test_charisma_health_discount_overflow() {
        let starting_stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
        };
        let mut adventurer = ImplAdventurer::new(12, 0, starting_stats);

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
    #[available_gas(200000)]
    fn test_charisma_item_discount_overflow() {
        let starting_stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
        };
        let mut adventurer = ImplAdventurer::new(12, 0, starting_stats);
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
    #[available_gas(150000)]
    fn test_increase_xp() {
        // initialize lvl 1 adventurer with no stat points available
        let starting_stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
        };
        let mut adventurer = ImplAdventurer::new(12, 0, starting_stats);

        // increase adventurer xp by 3 which should level up the adventurer
        adventurer.increase_adventurer_xp(4);
        assert(adventurer.get_level() == 2, 'advtr should be lvl 2');

        // double level up without spending previous stat point
        adventurer.increase_adventurer_xp(12);
        assert(adventurer.get_level() == 4, 'advtr should be lvl 4');
    }

    #[test]
    #[available_gas(145830)]
    fn test_apply_suffix_boost() {
        let starting_stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
        };
        let mut adventurer = ImplAdventurer::new(12, 0, starting_stats);

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
        let starting_stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
        };
        let mut adventurer = ImplAdventurer::new(12, 0, starting_stats);

        // verify starting state
        assert(adventurer.stats.strength == 0, 'strength should be 0');

        // test base case
        adventurer.stats.strength = 4;
        adventurer.remove_suffix_boost(1);
        assert(adventurer.stats.strength == 1, 'strength should be 1');

        // underflow check
        adventurer.remove_suffix_boost(1);
        assert(adventurer.stats.strength == 0, 'strength should still be 0');
    }

    #[test]
    #[available_gas(332700)]
    fn test_get_and_apply_stat_boosts() {
        let mut adventurer = Adventurer {
            last_action: 511,
            health: 100,
            xp: 1,
            stats: Stats {
                strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
            },
            gold: 40,
            weapon: ItemPrimitive { id: 1, xp: 225, metadata: 1, },
            chest: ItemPrimitive { id: 2, xp: 65535, metadata: 2, },
            head: ItemPrimitive { id: 3, xp: 225, metadata: 3, },
            waist: ItemPrimitive { id: 4, xp: 225, metadata: 4, },
            foot: ItemPrimitive { id: 5, xp: 1000, metadata: 5, },
            hand: ItemPrimitive { id: 6, xp: 224, metadata: 6, },
            neck: ItemPrimitive { id: 7, xp: 1, metadata: 7, },
            ring: ItemPrimitive { id: 8, xp: 1, metadata: 8, },
            beast_health: 20,
            stat_points_available: 0,
            mutated: false,
        };

        let item1_names = ItemSpecials {
            special2: 0, special3: 0, special1: ItemSuffix::of_Power,
        };
        let item2_names = ItemSpecials {
            special2: 0, special3: 0, special1: ItemSuffix::of_Giant,
        };
        let item3_names = ItemSpecials {
            special2: 0, special3: 0, special1: ItemSuffix::of_Perfection,
        };
        let item4_names = ItemSpecials { special2: 0, special3: 0, special1: ItemSuffix::of_Rage, };
        let item5_names = ItemSpecials { special2: 0, special3: 0, special1: ItemSuffix::of_Fury, };
        let item6_names = ItemSpecials {
            special2: 0, special3: 0, special1: ItemSuffix::of_Skill,
        };
        let item7_names = ItemSpecials {
            special2: 0, special3: 0, special1: ItemSuffix::of_Vitriol,
        };
        let item8_names = ItemSpecials {
            special2: 0, special3: 0, special1: ItemSuffix::of_the_Fox,
        };
        let item9_names = ItemSpecials { special2: 0, special3: 0, special1: 0, };
        let item10_names = ItemSpecials { special2: 0, special3: 0, special1: 0, };

        let name_storage1 = ItemSpecialsStorage {
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
            mutated: false
        };

        let name_storage2 = ItemSpecialsStorage {
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
            mutated: false
        };

        let boost_stats = adventurer.get_stat_boosts(name_storage1, name_storage2);
        assert(boost_stats.strength == 5, 'strength should be 5');
        assert(boost_stats.vitality == 5, 'vitality should be 5');
        assert(boost_stats.dexterity == 1, 'dexterity should be 1');
        assert(boost_stats.intelligence == 1, 'intelligence should be 1');
        assert(boost_stats.wisdom == 1, 'wisdom should be 1');
        assert(boost_stats.charisma == 2, 'charisma should be 2');
    }

    // test base case
    #[test]
    #[available_gas(61470)]
    fn test_apply_stat_boosts() {
        let mut adventurer = ImplAdventurer::new(
            12,
            0,
            Stats {
                strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
            }
        );

        let boost_stats = Stats {
            strength: 5, dexterity: 1, vitality: 5, intelligence: 1, wisdom: 1, charisma: 2,
        };

        adventurer.apply_stat_boosts(boost_stats);
        assert(adventurer.stats.strength == 5, 'strength should be 5');
        assert(adventurer.stats.dexterity == 1, 'dexterity should be 1');
        assert(adventurer.stats.vitality == 5, 'vitality should be 5');

        assert(adventurer.stats.intelligence == 1, 'intelligence should be 1');
        assert(adventurer.stats.wisdom == 1, 'wisdom should be 1');
        assert(adventurer.stats.charisma == 2, 'charisma should be 2');
    }

    // test zero case
    #[test]
    #[available_gas(61470)]
    fn test_apply_stat_boosts_zero() {
        let mut adventurer = ImplAdventurer::new(
            12,
            0,
            Stats {
                strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
            }
        );

        let boost_stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
        };

        adventurer.apply_stat_boosts(boost_stats);
        assert(adventurer.stats.strength == 0, 'strength should be 0');
        assert(adventurer.stats.dexterity == 0, 'dexterity should be 0');
        assert(adventurer.stats.vitality == 0, 'vitality should be 0');
        assert(adventurer.stats.intelligence == 0, 'intelligence should be 0');
        assert(adventurer.stats.wisdom == 0, 'wisdom should be 0');
        assert(adventurer.stats.charisma == 0, 'charisma should be 0');
    }

    // test max value case
    #[test]
    #[available_gas(61470)]
    fn test_apply_stat_boosts_max() {
        let mut adventurer = ImplAdventurer::new(
            12,
            0,
            Stats {
                strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
            }
        );
        let boost_stats = Stats {
            strength: 255,
            dexterity: 255,
            vitality: 255,
            intelligence: 255,
            wisdom: 255,
            charisma: 255,
        };

        adventurer.apply_stat_boosts(boost_stats);
        assert(adventurer.stats.strength == 255, 'strength should be max');
        assert(adventurer.stats.dexterity == 255, 'dexterity should be max');
        assert(adventurer.stats.vitality == 255, 'vitality should be max');
        assert(adventurer.stats.intelligence == 255, 'intelligence should be max');
        assert(adventurer.stats.wisdom == 255, 'wisdom should be max');
        assert(adventurer.stats.charisma == 255, 'charisma should be max');
    }

    // base case
    #[test]
    #[available_gas(52530)]
    fn test_remove_stat_boosts() {
        let mut adventurer = ImplAdventurer::new(
            12,
            0,
            Stats {
                strength: 5, dexterity: 4, vitality: 3, intelligence: 2, wisdom: 1, charisma: 0,
            }
        );

        let boost_stats = Stats {
            strength: 5, dexterity: 4, vitality: 3, intelligence: 2, wisdom: 1, charisma: 20,
        };

        adventurer.remove_stat_boosts(boost_stats);
        assert(adventurer.stats.strength == 0, 'strength should be 0');
        assert(adventurer.stats.dexterity == 0, 'dexterity should be 0');
        assert(adventurer.stats.vitality == 0, 'vitality should be 0');
        assert(adventurer.stats.intelligence == 0, 'intelligence should be 0');
        assert(adventurer.stats.wisdom == 0, 'wisdom should be 0');
        assert(adventurer.stats.charisma == 0, 'charisma should be 0');
    }

    // zero case
    #[test]
    #[available_gas(52530)]
    fn test_remove_stat_boosts_zero() {
        let mut adventurer = ImplAdventurer::new(
            12,
            0,
            Stats {
                strength: 5, dexterity: 4, vitality: 3, intelligence: 2, wisdom: 1, charisma: 0,
            }
        );

        let boost_stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
        };

        adventurer.remove_stat_boosts(boost_stats);
        assert(adventurer.stats.strength == 5, 'strength should be 5');
        assert(adventurer.stats.dexterity == 4, 'dexterity should be 4');
        assert(adventurer.stats.vitality == 3, 'vitality should be 3');
        assert(adventurer.stats.intelligence == 2, 'intelligence should be 2');
        assert(adventurer.stats.wisdom == 1, 'wisdom should be 1');
        assert(adventurer.stats.charisma == 0, 'charisma should be 0');
    }

    // max values case
    #[test]
    #[available_gas(52530)]
    fn test_remove_stat_boosts_max() {
        let mut adventurer = ImplAdventurer::new(
            12,
            0,
            Stats {
                strength: 5, dexterity: 4, vitality: 3, intelligence: 2, wisdom: 1, charisma: 0,
            }
        );

        let boost_stats = Stats {
            strength: 255,
            dexterity: 255,
            vitality: 255,
            intelligence: 255,
            wisdom: 255,
            charisma: 255,
        };

        adventurer.remove_stat_boosts(boost_stats);
        assert(adventurer.stats.strength == 0, 'strength should be 0');
        assert(adventurer.stats.dexterity == 0, 'dexterity should be 0');
        assert(adventurer.stats.vitality == 0, 'vitality should be 0');
        assert(adventurer.stats.intelligence == 0, 'intelligence should be 0');
        assert(adventurer.stats.wisdom == 0, 'wisdom should be 0');
        assert(adventurer.stats.charisma == 0, 'charisma should be 0');
    }

    #[test]
    #[available_gas(390000)]
    fn test_discover_treasure() {
        let starting_stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
        };
        let mut adventurer = ImplAdventurer::new(12, 0, starting_stats);

        // give vitality so we can discover health
        adventurer.stats.vitality = 1;
        adventurer.xp = 25;

        // disover gold
        let (discovery_type, amount) = adventurer.discover_treasure(0);
        assert(discovery_type == TreasureDiscovery::Gold(()), 'should have found gold');
        assert(amount != 0, 'gold should be non-zero');

        // discover health
        let (discovery_type, amount) = adventurer.discover_treasure(1);
        assert(discovery_type == TreasureDiscovery::Health(()), 'should have found health');
        assert(amount != 0, 'health should be non-zero');

        // discover xp
        let (discovery_type, amount) = adventurer.discover_treasure(2);
        assert(discovery_type == TreasureDiscovery::XP(()), 'should have found xp');
        assert(amount != 0, 'xp should be non-zero');
    }

    #[test]
    #[available_gas(161530)]
    fn test_get_luck_gas_no_luck() {
        let mut adventurer = ImplAdventurer::new(
            12,
            0,
            Stats {
                strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
            }
        );
        let bag = ImplBag::new();
        assert(adventurer.get_luck(bag) == 2, 'start with 2 luck');
    }

    #[test]
    #[available_gas(161530)]
    fn test_get_luck_gas_with_luck() {
        let mut adventurer = ImplAdventurer::new(
            12,
            0,
            Stats {
                strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
            }
        );
        let bag = ImplBag::new();

        let neck = ItemPrimitive { id: ItemId::Amulet, xp: 1, metadata: 7 };
        adventurer.equip_necklace(neck);
        let ring = ItemPrimitive { id: ItemId::GoldRing, xp: 1, metadata: 8 };
        adventurer.equip_ring(ring);
        assert(adventurer.get_luck(bag) == 2, 'start with 2 luck');
    }

    #[test]
    #[available_gas(983740)]
    fn test_get_luck() {
        let mut adventurer = ImplAdventurer::new(
            12,
            0,
            Stats {
                strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
            }
        );
        let bag = ImplBag::new();
        assert(adventurer.get_luck(bag) == 2, 'start with 2 luck');

        // equip a greatness 1 necklace
        let neck = ItemPrimitive { id: ItemId::Amulet, xp: 1, metadata: 7 };
        adventurer.equip_necklace(neck);
        assert(adventurer.get_luck(bag) == 2, 'still 2 luck');

        // equip a greatness 1 ring
        let ring = ItemPrimitive { id: ItemId::GoldRing, xp: 1, metadata: 8 };
        adventurer.equip_ring(ring);
        assert(adventurer.get_luck(bag) == 2, 'still 2 luck');

        // equip a greatness 19 silver ring
        let mut silver_ring = ItemPrimitive { id: ItemId::SilverRing, xp: 399, metadata: 8 };
        adventurer.equip_ring(silver_ring);
        assert(adventurer.get_luck(bag) == 20, 'should be 20 luck');

        // increase silver ring to greatness 20 to unlock extra 20 luck
        adventurer.ring.xp = 400;
        assert(adventurer.get_luck(bag) == 41, 'should be 41 luck');

        // overflow case
        adventurer.ring.xp = 65535;
        adventurer.neck.xp = 65535;
        let luck = adventurer.get_luck(bag);
        assert(
            adventurer.get_luck(bag) == (ITEM_MAX_GREATNESS * 2) + SILVER_RING_G20_LUCK_BONUS,
            'should be 60 luck'
        );
    }

    #[test]
    #[available_gas(45000)]
    fn test_in_battle() {
        let mut adventurer = ImplAdventurer::new(
            12,
            0,
            Stats {
                strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
            }
        );
        assert(adventurer.in_battle() == true, 'new advntr start in battle');

        adventurer.beast_health = 0;
        assert(adventurer.in_battle() == false, 'advntr not in battle');

        // overflow check
        adventurer.beast_health = 65535;
        assert(adventurer.in_battle() == true, 'advntr in battle');
    }

    #[test]
    #[available_gas(550000)]
    fn test_equip_item() {
        let starting_stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
        };
        let mut adventurer = ImplAdventurer::new(12, 0, starting_stats);

        // assert starting conditions
        assert(adventurer.weapon.id == 12, 'weapon should be 12');
        assert(adventurer.chest.id == 0, 'chest should be 0');
        assert(adventurer.head.id == 0, 'head should be 0');
        assert(adventurer.waist.id == 0, 'waist should be 0');
        assert(adventurer.foot.id == 0, 'foot should be 0');
        assert(adventurer.hand.id == 0, 'hand should be 0');
        assert(adventurer.neck.id == 0, 'neck should be 0');
        assert(adventurer.ring.id == 0, 'ring should be 0');

        // stage items
        let weapon = ItemPrimitive { id: ItemId::Katana, xp: 1, metadata: 1 };
        let chest = ItemPrimitive { id: ItemId::DivineRobe, xp: 1, metadata: 2 };
        let head = ItemPrimitive { id: ItemId::Crown, xp: 1, metadata: 3 };
        let waist = ItemPrimitive { id: ItemId::DemonhideBelt, xp: 1, metadata: 4 };
        let foot = ItemPrimitive { id: ItemId::LeatherBoots, xp: 1, metadata: 5 };
        let hand = ItemPrimitive { id: ItemId::LeatherGloves, xp: 1, metadata: 6 };
        let neck = ItemPrimitive { id: ItemId::Amulet, xp: 1, metadata: 7 };
        let ring = ItemPrimitive { id: ItemId::GoldRing, xp: 1, metadata: 8 };

        adventurer.equip_item(weapon);
        adventurer.equip_item(chest);
        adventurer.equip_item(head);
        adventurer.equip_item(waist);
        adventurer.equip_item(foot);
        adventurer.equip_item(hand);
        adventurer.equip_item(neck);
        adventurer.equip_item(ring);

        // assert items were added
        assert(adventurer.weapon.id == weapon.id, 'weapon should be equipped');
        assert(adventurer.chest.id == chest.id, 'chest should be equipped');
        assert(adventurer.head.id == head.id, 'head should be equipped');
        assert(adventurer.waist.id == waist.id, 'waist should be equipped');
        assert(adventurer.foot.id == foot.id, 'foot should be equipped');
        assert(adventurer.hand.id == hand.id, 'hand should be equipped');
        assert(adventurer.neck.id == neck.id, 'neck should be equipped');
        assert(adventurer.ring.id == ring.id, 'ring should be equipped');
    }

    #[test]
    #[available_gas(1000000)]
    fn test_is_equipped() {
        let wand = ItemPrimitive { id: ItemId::Wand, xp: 1, metadata: 1 };
        let demon_crown = ItemPrimitive { id: ItemId::DemonCrown, xp: 1, metadata: 2 };
        let starting_stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
        };
        let mut adventurer = ImplAdventurer::new(12, 0, starting_stats);

        // assert starting state
        assert(adventurer.weapon.id == wand.id, 'weapon should be wand');
        assert(adventurer.chest.id == 0, 'chest should be 0');
        assert(adventurer.head.id == 0, 'head should be 0');
        assert(adventurer.waist.id == 0, 'waist should be 0');
        assert(adventurer.foot.id == 0, 'foot should be 0');
        assert(adventurer.hand.id == 0, 'hand should be 0');
        assert(adventurer.neck.id == 0, 'neck should be 0');
        assert(adventurer.ring.id == 0, 'ring should be 0');

        // assert base case for is_equipped
        assert(adventurer.is_equipped(wand.id) == true, 'wand should be equipped');
        assert(adventurer.is_equipped(demon_crown.id) == false, 'demon crown is not equipped');

        // stage items
        let katana = ItemPrimitive { id: ItemId::Katana, xp: 1, metadata: 1 };
        let divine_robe = ItemPrimitive { id: ItemId::DivineRobe, xp: 1, metadata: 2 };
        let crown = ItemPrimitive { id: ItemId::Crown, xp: 1, metadata: 3 };
        let demonhide_belt = ItemPrimitive { id: ItemId::DemonhideBelt, xp: 1, metadata: 4 };
        let leather_boots = ItemPrimitive { id: ItemId::LeatherBoots, xp: 1, metadata: 5 };
        let leather_gloves = ItemPrimitive { id: ItemId::LeatherGloves, xp: 1, metadata: 6 };
        let amulet = ItemPrimitive { id: ItemId::Amulet, xp: 1, metadata: 7 };
        let gold_ring = ItemPrimitive { id: ItemId::GoldRing, xp: 1, metadata: 8 };

        // Equip a katana and verify is_equipped returns true for katana and false everything else
        adventurer.equip_item(katana);
        assert(adventurer.is_equipped(katana.id) == true, 'weapon should be equipped');
        assert(adventurer.is_equipped(wand.id) == false, 'wand should not be equipped');
        assert(adventurer.is_equipped(crown.id) == false, 'crown should not be equipped');
        assert(adventurer.is_equipped(divine_robe.id) == false, 'divine robe is not equipped');
        assert(
            adventurer.is_equipped(demonhide_belt.id) == false, 'demonhide belt is not equipped'
        );
        assert(adventurer.is_equipped(leather_boots.id) == false, 'leather boots is not equipped');
        assert(
            adventurer.is_equipped(leather_gloves.id) == false, 'leather gloves is not equipped'
        );
        assert(adventurer.is_equipped(amulet.id) == false, 'amulet is not equipped');
        assert(adventurer.is_equipped(gold_ring.id) == false, 'gold ring is not equipped');

        // equip a divine robe and verify is_equipped returns true for katana and divine robe and false everything else
        adventurer.equip_item(divine_robe);
        assert(adventurer.is_equipped(divine_robe.id) == true, 'divine robe should be equipped');
        assert(adventurer.is_equipped(katana.id) == true, 'katana still equipped');
        assert(adventurer.is_equipped(crown.id) == false, 'crown should not be equipped');
        assert(
            adventurer.is_equipped(demonhide_belt.id) == false, 'demonhide belt is not equipped'
        );
        assert(adventurer.is_equipped(leather_boots.id) == false, 'leather boots is not equipped');
        assert(
            adventurer.is_equipped(leather_gloves.id) == false, 'leather gloves is not equipped'
        );
        assert(adventurer.is_equipped(amulet.id) == false, 'amulet is not equipped');
        assert(adventurer.is_equipped(gold_ring.id) == false, 'gold ring is not equipped');

        // equip a crown and verify is_equipped returns true for katana, divine robe, and crown and false everything else
        adventurer.equip_item(crown);
        assert(adventurer.is_equipped(crown.id) == true, 'crown should be equipped');
        assert(adventurer.is_equipped(divine_robe.id) == true, 'divine robe should be equipped');
        assert(adventurer.is_equipped(katana.id) == true, 'katana still equipped');
        assert(
            adventurer.is_equipped(demonhide_belt.id) == false, 'demonhide belt is not equipped'
        );
        assert(adventurer.is_equipped(leather_boots.id) == false, 'leather boots is not equipped');
        assert(
            adventurer.is_equipped(leather_gloves.id) == false, 'leather gloves is not equipped'
        );
        assert(adventurer.is_equipped(amulet.id) == false, 'amulet is not equipped');
        assert(adventurer.is_equipped(gold_ring.id) == false, 'gold ring is not equipped');

        // equip a demonhide belt and verify is_equipped returns true for katana, divine robe, crown, and demonhide belt and false everything else
        adventurer.equip_item(demonhide_belt);
        assert(adventurer.is_equipped(demonhide_belt.id) == true, 'demonhide belt is equipped');
        assert(adventurer.is_equipped(crown.id) == true, 'crown should be equipped');
        assert(adventurer.is_equipped(divine_robe.id) == true, 'divine robe should be equipped');
        assert(adventurer.is_equipped(katana.id) == true, 'katana still equipped');
        assert(adventurer.is_equipped(leather_boots.id) == false, 'leather boots is not equipped');
        assert(
            adventurer.is_equipped(leather_gloves.id) == false, 'leather gloves is not equipped'
        );
        assert(adventurer.is_equipped(amulet.id) == false, 'amulet is not equipped');
        assert(adventurer.is_equipped(gold_ring.id) == false, 'gold ring is not equipped');

        // equip leather boots and verify is_equipped returns true for katana, divine robe, crown, demonhide belt, and leather boots and false everything else
        adventurer.equip_item(leather_boots);
        assert(adventurer.is_equipped(leather_boots.id) == true, 'leather boots is equipped');
        assert(adventurer.is_equipped(demonhide_belt.id) == true, 'demonhide belt is equipped');
        assert(adventurer.is_equipped(crown.id) == true, 'crown should be equipped');
        assert(adventurer.is_equipped(divine_robe.id) == true, 'divine robe should be equipped');
        assert(adventurer.is_equipped(katana.id) == true, 'katana still equipped');
        assert(
            adventurer.is_equipped(leather_gloves.id) == false, 'leather gloves is not equipped'
        );
        assert(adventurer.is_equipped(amulet.id) == false, 'amulet is not equipped');
        assert(adventurer.is_equipped(gold_ring.id) == false, 'gold ring is not equipped');

        // equip leather gloves and verify is_equipped returns true for katana, divine robe, crown, demonhide belt, leather boots, and leather gloves and false everything else
        adventurer.equip_item(leather_gloves);
        assert(adventurer.is_equipped(leather_gloves.id) == true, 'leather gloves is equipped');
        assert(adventurer.is_equipped(leather_boots.id) == true, 'leather boots is equipped');
        assert(adventurer.is_equipped(demonhide_belt.id) == true, 'demonhide belt is equipped');
        assert(adventurer.is_equipped(crown.id) == true, 'crown should be equipped');
        assert(adventurer.is_equipped(divine_robe.id) == true, 'divine robe should be equipped');
        assert(adventurer.is_equipped(katana.id) == true, 'katana still equipped');
        assert(adventurer.is_equipped(amulet.id) == false, 'amulet is not equipped');
        assert(adventurer.is_equipped(gold_ring.id) == false, 'gold ring is not equipped');

        // equip amulet and verify is_equipped returns true for katana, divine robe, crown, demonhide belt, leather boots, leather gloves, and amulet and false everything else
        adventurer.equip_item(amulet);
        assert(adventurer.is_equipped(amulet.id) == true, 'amulet is equipped');
        assert(adventurer.is_equipped(leather_gloves.id) == true, 'leather gloves is equipped');
        assert(adventurer.is_equipped(leather_boots.id) == true, 'leather boots is equipped');
        assert(adventurer.is_equipped(demonhide_belt.id) == true, 'demonhide belt is equipped');
        assert(adventurer.is_equipped(crown.id) == true, 'crown should be equipped');
        assert(adventurer.is_equipped(divine_robe.id) == true, 'divine robe should be equipped');
        assert(adventurer.is_equipped(katana.id) == true, 'katana still equipped');
        assert(adventurer.is_equipped(gold_ring.id) == false, 'gold ring is not equipped');

        // equip gold ring and verify is_equipped returns true for katana, divine robe, crown, demonhide belt, leather boots, leather gloves, amulet, and gold ring and false everything else
        adventurer.equip_item(gold_ring);
        assert(adventurer.is_equipped(gold_ring.id) == true, 'gold ring is equipped');
        assert(adventurer.is_equipped(amulet.id) == true, 'amulet is equipped');
        assert(adventurer.is_equipped(leather_gloves.id) == true, 'leather gloves is equipped');
        assert(adventurer.is_equipped(leather_boots.id) == true, 'leather boots is equipped');
        assert(adventurer.is_equipped(demonhide_belt.id) == true, 'demonhide belt is equipped');
        assert(adventurer.is_equipped(crown.id) == true, 'crown should be equipped');
        assert(adventurer.is_equipped(divine_robe.id) == true, 'divine robe should be equipped');
        assert(adventurer.is_equipped(katana.id) == true, 'katana still equipped');
    }

    #[test]
    #[should_panic(expected: ('item is not equipped',))]
    #[available_gas(50000)]
    fn test_drop_item_not_equipped() {
        // instantiate adventurer
        let starting_stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
        };
        let mut adventurer = ImplAdventurer::new(12, 0, starting_stats);
        // try to drop an item that isn't equipped
        // this should panic with 'item is not equipped'
        // the test is annotated to expect this panic
        adventurer.drop_item(ItemId::Crown);
    }

    #[test]
    #[available_gas(700000)]
    fn test_drop_item() {
        let starting_stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
        };
        let mut adventurer = ImplAdventurer::new(12, 0, starting_stats);

        // assert starting conditions
        assert(adventurer.weapon.id == ItemId::Wand, 'weapon should be wand');
        assert(adventurer.chest.id == 0, 'chest should be 0');
        assert(adventurer.head.id == 0, 'head should be 0');
        assert(adventurer.waist.id == 0, 'waist should be 0');
        assert(adventurer.foot.id == 0, 'foot should be 0');
        assert(adventurer.hand.id == 0, 'hand should be 0');
        assert(adventurer.neck.id == 0, 'neck should be 0');
        assert(adventurer.ring.id == 0, 'ring should be 0');

        // drop equipped wand
        adventurer.drop_item(ItemId::Wand);
        assert(adventurer.weapon.id == 0, 'weapon should be 0');
        assert(adventurer.weapon.xp == 0, 'weapon xp should be 0');

        // instantiate additional items
        let weapon = ItemPrimitive { id: ItemId::Katana, xp: 1, metadata: 1 };
        let chest = ItemPrimitive { id: ItemId::DivineRobe, xp: 1, metadata: 2 };
        let head = ItemPrimitive { id: ItemId::Crown, xp: 1, metadata: 3 };
        let waist = ItemPrimitive { id: ItemId::DemonhideBelt, xp: 1, metadata: 4 };
        let foot = ItemPrimitive { id: ItemId::LeatherBoots, xp: 1, metadata: 5 };
        let hand = ItemPrimitive { id: ItemId::LeatherGloves, xp: 1, metadata: 6 };
        let neck = ItemPrimitive { id: ItemId::Amulet, xp: 1, metadata: 7 };
        let ring = ItemPrimitive { id: ItemId::GoldRing, xp: 1, metadata: 8 };

        // equip item
        adventurer.equip_item(weapon);
        adventurer.equip_item(chest);
        adventurer.equip_item(head);
        adventurer.equip_item(waist);
        adventurer.equip_item(foot);
        adventurer.equip_item(hand);
        adventurer.equip_item(neck);
        adventurer.equip_item(ring);

        // assert items were equipped
        assert(adventurer.weapon.id == weapon.id, 'weapon should be equipped');
        assert(adventurer.chest.id == chest.id, 'chest should be equipped');
        assert(adventurer.head.id == head.id, 'head should be equipped');
        assert(adventurer.waist.id == waist.id, 'waist should be equipped');
        assert(adventurer.foot.id == foot.id, 'foot should be equipped');
        assert(adventurer.hand.id == hand.id, 'hand should be equipped');
        assert(adventurer.neck.id == neck.id, 'neck should be equipped');
        assert(adventurer.ring.id == ring.id, 'ring should be equipped');

        // drop equipped items one by one and assert they get dropped
        adventurer.drop_item(weapon.id);
        assert(adventurer.weapon.id == 0, 'weapon should be 0');
        assert(adventurer.weapon.xp == 0, 'weapon xp should be 0');

        adventurer.drop_item(chest.id);
        assert(adventurer.chest.id == 0, 'chest should be 0');
        assert(adventurer.chest.xp == 0, 'chest xp should be 0');

        adventurer.drop_item(head.id);
        assert(adventurer.head.id == 0, 'head should be 0');
        assert(adventurer.head.xp == 0, 'head xp should be 0');

        adventurer.drop_item(waist.id);
        assert(adventurer.waist.id == 0, 'waist should be 0');
        assert(adventurer.waist.xp == 0, 'waist xp should be 0');

        adventurer.drop_item(foot.id);
        assert(adventurer.foot.id == 0, 'foot should be 0');
        assert(adventurer.foot.xp == 0, 'foot xp should be 0');

        adventurer.drop_item(hand.id);
        assert(adventurer.hand.id == 0, 'hand should be 0');
        assert(adventurer.hand.xp == 0, 'hand xp should be 0');

        adventurer.drop_item(neck.id);
        assert(adventurer.neck.id == 0, 'neck should be 0');
        assert(adventurer.neck.xp == 0, 'neck xp should be 0');

        adventurer.drop_item(ring.id);
        assert(adventurer.ring.id == 0, 'ring should be 0');
        assert(adventurer.ring.xp == 0, 'ring xp should be 0');
    }

    #[test]
    #[available_gas(272270)]
    fn test_is_ambush() {
        let mut adventurer = ImplAdventurer::new(
            12,
            0,
            Stats {
                strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0,
            }
        );

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
}
