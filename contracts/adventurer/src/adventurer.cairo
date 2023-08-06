use debug::PrintTrait;
use core::result::ResultTrait;
use integer::{u8_overflowing_add, u16_overflowing_add, u16_overflowing_sub};
use traits::{TryInto, Into};
use option::OptionTrait;
use poseidon::poseidon_hash_span;
use array::ArrayTrait;

use super::{
    item_meta::{ItemSpecials, ItemSpecialsStorage, ImplItemSpecials}, adventurer_stats::Stats,
    item_primitive::ItemPrimitive, adventurer_utils::{AdventurerUtils}, exploration::ExploreUtils,
    constants::{
        adventurer_constants::{
            STARTING_GOLD, StatisticIndex, POTION_PRICE, STARTING_HEALTH, CHARISMA_POTION_DISCOUNT,
            MINIMUM_ITEM_PRICE, MINIMUM_POTION_PRICE, VITALITY_HEALTH_CAP_INCREASE, MAX_GOLD,
            MAX_STAT_VALUE, MAX_STAT_UPGRADES, MAX_XP, MAX_ADVENTURER_BLOCKS, ITEM_MAX_GREATNESS,
            ITEM_MAX_XP, MAX_ADVENTURER_HEALTH, CHARISMA_ITEM_DISCOUNT, ClassStatBoosts,
            MAX_BLOCK_COUNT
        },
        discovery_constants::DiscoveryEnums::{ExploreResult, TreasureDiscovery}
    }
};
use pack::{pack::{Packing, rshift_split}, constants::{MASK_16, pow, MASK_8, MASK_BOOL, mask}};
use lootitems::{
    loot::{Loot, ILoot, ImplLoot},
    statistics::{constants, item_tier, item_type, constants::ItemSuffix}
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
                .expect('unpack Adventurer stat_upgrade')
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
    fn new(
        starting_item: u8,
        block_number: u64,
        starting_strength: u8,
        starting_dexterity: u8,
        starting_vitality: u8,
        starting_intelligence: u8,
        starting_wisdom: u8,
        starting_charsima: u8
    ) -> Adventurer {
        let current_block_modulo_512: u16 = (block_number % MAX_ADVENTURER_BLOCKS.into())
            .try_into()
            .unwrap();

        let mut adventurer = Adventurer {
            last_action: current_block_modulo_512, health: STARTING_HEALTH, xp: 0, stats: Stats {
                strength: starting_strength,
                dexterity: starting_dexterity,
                vitality: starting_vitality,
                intelligence: starting_intelligence,
                wisdom: starting_wisdom,
                charisma: starting_charsima
                }, gold: STARTING_GOLD, weapon: ItemPrimitive {
                id: starting_item, xp: 0, metadata: 1, 
                }, chest: ItemPrimitive {
                id: 0, xp: 0, metadata: 0, 
                }, head: ItemPrimitive {
                id: 0, xp: 0, metadata: 0, 
                }, waist: ItemPrimitive {
                id: 0, xp: 0, metadata: 0, 
                }, foot: ItemPrimitive {
                id: 0, xp: 0, metadata: 0, 
                }, hand: ItemPrimitive {
                id: 0, xp: 0, metadata: 0, 
                }, neck: ItemPrimitive {
                id: 0, xp: 0, metadata: 0, 
                }, ring: ItemPrimitive {
                id: 0, xp: 0, metadata: 0, 
            }, beast_health: BeastSettings::STARTER_BEAST_HEALTH, stat_points_available: 0,
        };

        // set adventurers health to max which will compensate for starting for vitality
        adventurer.health = adventurer.get_max_health();
        adventurer
    }

    // @notice Generates market seeds and offsets for an adventurer based on their stat points, 
    // adventurer id, and entropy.
    //
    // Each market seed and offset pair corresponds to a stat point. The pairs are generated using
    // the function AdventurerUtils::get_market_seed_and_offset. The process ends when all stat points 
    // have been assigned a market seed and offset pair.
    //
    // @param adventurer_id Unique identifier for the adventurer.
    // @param adventurer_entropy A numerical value representing the randomness for the adventurer.
    //
    // @return Span<u128> The array of market seeds for the adventurer.
    // @return Span<u8> The corresponding offsets for the market seeds.
    //
    // @dev The function uses the internal value of stat_points_available for determining the number of seeds 
    // and offsets to generate. The function iteratively decreases the stat points until no more are left, 
    // and appends the market seed and offset pair generated in each iteration to the respective arrays.
    fn get_market_seeds(
        self: Adventurer, adventurer_id: u256, adventurer_entropy: u128
    ) -> (Span<u256>, Span<u8>) {
        let mut seeds = ArrayTrait::new();
        let mut offsets = ArrayTrait::new();

        // for each stat point available
        let mut stat_count: u8 = self.stat_points_available;
        loop {
            // stop if we have no more stat points
            if stat_count == 0 {
                break ();
            }

            // generate a unique market seed and offset
            let (seed, offset) = AdventurerUtils::get_market_seed_and_offset(
                adventurer_id, adventurer_entropy, self.xp, stat_count
            );

            // add to our seeds and offsets arrays
            seeds.append(seed);
            offsets.append(offset);

            // decrement stat count
            stat_count -= 1;
        };

        // return seeds and offsets
        (seeds.span(), offsets.span())
    }

    // @notice Calculates the charisma potion discount for the adventurer based on their charisma stat.
    // @return The charisma potion discount.
    fn charisma_potion_discount(self: Adventurer) -> u16 {
        CHARISMA_POTION_DISCOUNT * self.stats.charisma.into()
    }

    // @notice Calculates the charisma item discount for the adventurer based on their charisma stat.
    // @return The charisma item discount.
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

    // @notice Adds to a stat for the adventurer.
    // @dev Assumes the `value` is within a valid range (0-5).
    // @param value The index of the stat to be increased.
    fn increment_stat(ref self: Adventurer, value: u8) {
        assert(value < 6, 'Valid stat range is 0-5');
        if (value == StatisticIndex::STRENGTH) {
            self.increase_strength(1)
        } else if (value == StatisticIndex::DEXTERITY) {
            self.increase_dexterity(1)
        } else if (value == StatisticIndex::VITALITY) {
            self.increase_vitality(1)
        } else if (value == StatisticIndex::INTELLIGENCE) {
            self.increase_intelligence(1)
        } else if (value == StatisticIndex::WISDOM) {
            self.increase_wisdom(1)
        } else {
            self.increase_charisma(1)
        }
    }

    // @notice Deducts a specified amount of gold from the adventurer, preventing underflow.
    // @param amount The amount of gold to be deducted.
    fn deduct_gold(ref self: Adventurer, amount: u16) {
        // underflow protection
        if amount >= self.gold {
            self.gold = 0;
        } else {
            self.gold -= amount;
        }
    }

    // get_item_at_slot returns the item at a given item slot
    // @param self: Adventurer to check
    // @param slot: Slot to check
    // @return ItemPrimitive: Item at slot
    fn get_item_at_slot(self: Adventurer, slot: Slot) -> ItemPrimitive {
        match slot {
            Slot::None(()) => ItemPrimitive { id: 0, xp: 0, metadata: 0,  },
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
    fn beast_encounter(ref self: Adventurer, adventurer_entropy: u128) -> Beast {
        // generate battle fixed entropy by combining adventurer xp and adventurer entropy
        let beast_seed: u128 = self.get_beast_seed(adventurer_entropy);
        let special_names = ImplBeast::get_special_names(
            self.get_level(),
            beast_seed,
            constants::NamePrefixLength.into(),
            constants::NameSuffixLength.into()
        );

        // get beast using battle fixed seed
        // this is important because in the context of this call
        // the player has just encountered the beast and will
        // subsequently be calling "attack" to attack the beast
        // to enable the adventurer state to fit in a single 252felt, we
        // don't store anything about the beast in the adventurer state
        // except it's health. Instead the beast is generated at run-time
        // via the battle_fixed_seed
        let beast = ImplBeast::get_beast(
            self.get_level(), special_names, beast_seed, ImplLoot::get_type(self.weapon.id)
        );

        // otherwise generate random starting health for the beast
        self.set_beast_health(beast.starting_health);

        // return beast
        return beast;
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
        let item_type = ExploreUtils::get_random_treasury_discovery(self, entropy);

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

    // Calculates the adventurer's luck based on the greatness of their equipped necklace and ring.
    // @param self: Adventurer to calculate luck for
    // @return The adventurer's luck.
    fn get_luck(self: Adventurer) -> u8 {
        // get greatness of aventurers equipped necklace
        let mut necklace_greatness = 0;
        if (self.neck.id > 0) {
            necklace_greatness = self.neck.get_greatness();
        }

        let mut ring_greatness = 0;
        if (self.ring.id > 0) {
            ring_greatness = self.ring.get_greatness();
        }

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

    // Deducts a specified amount of health from the adventurer's beast, preventing underflow.
    // @param self: Adventurer to deduct beast health from
    // @param amount: Amount of health to deduct from the beast
    fn deduct_beast_health(ref self: Adventurer, amount: u16) {
        // underflow protection
        if amount >= self.beast_health {
            self.beast_health = 0;
        } else {
            self.beast_health -= amount;
        }
    }

    // Sets the beast's health to a specified amount, preventing overflow.
    // @param self: Adventurer to set beast health for
    // @param amount: Amount of health to set the beast's health to
    fn set_beast_health(ref self: Adventurer, amount: u16) {
        // check for overflow
        // we currently use 9 bits for beast health so MAX HEALTH is 2^9 - 1
        if (amount > BeastSettings::MAXIMUM_HEALTH) {
            self.beast_health = BeastSettings::MAXIMUM_HEALTH;
        } else {
            self.beast_health = amount;
        }
    }

    // Adds a specified amount of health to the adventurer, preventing overflow and capping at max health.
    // @param self: Adventurer to add health to
    // @param amount: Amount of health to add to the adventurer
    fn increase_health(ref self: Adventurer, amount: u16) {
        // check for u16 overflow
        if (u16_overflowing_add(self.health, amount).is_ok()) {
            // if overflow is ok
            // check if added amount is less than or equal to max health
            if (self.health + amount <= self.get_max_health()) {
                // if it is, add health
                self.health += amount;
                return;
            }
        }

        // fall through is to set health to max health
        // this will happen either in a u16 overflow case
        // or if the health being added exceeds max health
        self.health = self.get_max_health()
    }

    // Returns the maximum health an adventurer can have.
    // The maximum health is the sum of the starting health and the health increase due to the adventurer's vitality.
    //
    // @return The maximum health as a u16. If the total health would exceed the maximum possible health, 
    //         then this value is capped to MAX_ADVENTURER_HEALTH.
    fn get_max_health(self: Adventurer) -> u16 {
        // Calculate vitality boost, casting to u16 to prevent overflow during multiplication
        let vitality_boost: u16 = (self.stats.vitality.into()
            * VITALITY_HEALTH_CAP_INCREASE.into());

        // Check if health calculation would result in overflow
        if (u16_overflowing_add(STARTING_HEALTH, vitality_boost).is_ok()) {
            // If it does not cause overflow, check if health + vitality boost is within maximum allowed health
            if (STARTING_HEALTH + vitality_boost <= MAX_ADVENTURER_HEALTH) {
                // if it is, return full boost
                return (STARTING_HEALTH + vitality_boost);
            }
        }

        // In the case of potential overflow or exceeding max adventurer health, return max adventurer health
        MAX_ADVENTURER_HEALTH
    }

    // @notice Returns true if the adventurer has full health.
    // @param self: Adventurer to check if health is full
    // @return bool true if the adventurer has full health, false otherwise
    fn has_full_health(self: Adventurer) -> bool {
        self.health == self.get_max_health()
    }

    // Adds a specified amount of gold to the adventurer's total gold.
    // The amount of gold an adventurer can have is capped at MAX_GOLD.
    //
    // @param amount The amount of gold to add as a u16.
    fn add_gold(ref self: Adventurer, amount: u16) {
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

    // @notice Decreases the health of an Adventurer by the given value, with underflow protection.
    // @dev If the value to deduct is greater than the current health, it sets the health to zero.
    // @param value The amount of health to be deducted from the Adventurer.
    fn deduct_health(ref self: Adventurer, value: u16) {
        // underflow protection
        if value >= self.health {
            self.health = 0;
        } else {
            self.health -= value;
        }
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

        // return the previous and new levels
        (previous_level, new_level)
    }

    // @notice Grants stat upgrades to the Adventurer.
    // @dev The function will add the specified value to the stat_points_available up to the maximum limit of MAX_STAT_UPGRADES.
    // @param value The amount of stat points to be added to the Adventurer.
    fn add_stat_upgrade_points(ref self: Adventurer, amount: u8) {
        // check for u8 overflow
        if (u8_overflowing_add(self.stat_points_available, amount).is_ok()) {
            // if overflow is ok
            // check if added amount is less than or equal to max upgrade points
            if (self.stat_points_available + amount <= MAX_STAT_UPGRADES) {
                // if it is, add upgrade points to adventurer and return
                self.stat_points_available += amount;
                return;
            }
        }

        // fall through is to return MAX_STAT_UPGRADES
        // this will happen either in a u8 overflow case
        // or if the upgrade points being added exceeds max upgrade points
        self.stat_points_available = MAX_STAT_UPGRADES
    }

    // @notice Increase the Adventurer's strength stat.
    // @dev The function will add the specified amount to the strength stat up to the maximum limit of MAX_STAT_VALUE.
    // @param amount The amount to be added to the strength stat.
    fn increase_strength(ref self: Adventurer, amount: u8) {
        self
            .stats
            .strength =
                AdventurerUtils::overflow_protected_stat_increase(self.stats.strength, amount);
    }

    // @notice Increase the Adventurer's dexterity stat.
    // @dev The function will add the specified amount to the dexterity stat up to the maximum limit of MAX_STAT_VALUE.
    // @param amount The amount to be added to the dexterity stat.
    fn increase_dexterity(ref self: Adventurer, amount: u8) {
        self
            .stats
            .dexterity =
                AdventurerUtils::overflow_protected_stat_increase(self.stats.dexterity, amount);
    }

    // @notice Increase the Adventurer's vitality stat.
    // @dev The function will add the specified amount to the vitality stat up to the maximum limit of MAX_STAT_VALUE.
    // @param amount The amount to be added to the vitality stat.
    fn increase_vitality(ref self: Adventurer, amount: u8) {
        self
            .stats
            .vitality =
                AdventurerUtils::overflow_protected_stat_increase(self.stats.vitality, amount);
    }

    // @notice Increase the Adventurer's intelligence stat.
    // @dev The function will add the specified amount to the intelligence stat up to the maximum limit of MAX_STAT_VALUE.
    // @param amount The amount to be added to the intelligence stat.
    fn increase_intelligence(ref self: Adventurer, amount: u8) {
        self
            .stats
            .intelligence =
                AdventurerUtils::overflow_protected_stat_increase(self.stats.intelligence, amount);
    }

    // @notice Increase the Adventurer's wisdom stat.
    // @dev The function will add the specified amount to the wisdom stat up to the maximum limit of MAX_STAT_VALUE.
    // @param amount The amount to be added to the wisdom stat.
    fn increase_wisdom(ref self: Adventurer, amount: u8) {
        self
            .stats
            .wisdom = AdventurerUtils::overflow_protected_stat_increase(self.stats.wisdom, amount);
    }

    // @notice Increase the Adventurer's charisma stat.
    // @dev The function will add the specified amount to the charisma stat up to the maximum limit of MAX_STAT_VALUE.
    // @param amount The amount to be added to the charisma stat.
    fn increase_charisma(ref self: Adventurer, amount: u8) {
        self
            .stats
            .charisma =
                AdventurerUtils::overflow_protected_stat_increase(self.stats.charisma, amount);
    }

    // @notice Decrease the Adventurer's strength stat.
    // @dev The function will subtract the specified amount from the strength stat without allowing it to fall below 0.
    // @param amount The amount to be subtracted from the strength stat.
    fn deduct_strength(ref self: Adventurer, amount: u8) {
        // underflow protection
        if amount >= self.stats.strength {
            self.stats.strength = 0;
        } else {
            self.stats.strength -= amount;
        }
    }

    // @notice Decrease the Adventurer's dexterity stat.
    // @dev The function will subtract the specified amount from the dexterity stat without allowing it to fall below 0.
    // @param amount The amount to be deducted from the dexterity stat.
    fn deduct_dexterity(ref self: Adventurer, amount: u8) {
        // underflow protection
        if amount >= self.stats.dexterity {
            self.stats.dexterity = 0;
        } else {
            self.stats.dexterity -= amount;
        }
    }

    // @notice Decrease the Adventurer's vitality stat.
    // @dev The function will subtract the specified amount from the vitality stat without allowing it to fall below 0.
    // @param amount The amount to be deducted from the vitality stat.
    fn deduct_vitality(ref self: Adventurer, amount: u8) {
        // underflow protection
        if amount >= self.stats.vitality {
            self.stats.vitality = 0;
        } else {
            self.stats.vitality -= amount;
        }
    }

    // @notice Decrease the Adventurer's intelligence stat.
    // @dev The function will subtract the specified amount from the intelligence stat without allowing it to fall below 0.
    // @param amount The amount to be deducted from the intelligence stat.
    fn deduct_intelligence(ref self: Adventurer, amount: u8) {
        // underflow protection
        if amount >= self.stats.intelligence {
            self.stats.intelligence = 0;
        } else {
            self.stats.intelligence -= amount;
        }
    }

    // @notice Decrease the Adventurer's wisdom stat.
    // @dev The function will subtract the specified amount from the wisdom stat without allowing it to fall below 0.
    // @param amount The amount to be deducted from the wisdom stat.
    fn deduct_wisdom(ref self: Adventurer, amount: u8) {
        // underflow protection
        if amount >= self.stats.wisdom {
            self.stats.wisdom = 0;
        } else {
            self.stats.wisdom -= amount;
        }
    }

    // @notice Decrease the Adventurer's charisma stat.
    // @dev The function will subtract the specified amount from the charisma stat without allowing it to fall below 0.
    // @param amount The amount to be deducted from the charisma stat.
    fn deduct_charisma(ref self: Adventurer, amount: u8) {
        // underflow protection
        if amount >= self.stats.charisma {
            self.stats.charisma = 0;
        } else {
            self.stats.charisma -= amount;
        }
    }

    // @notice Adds an item to the adventurer's equipment.
    // @dev The type of the item determines which equipment slot it goes into.
    // @param item The item to be added to the adventurer's equipment.
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
    // @notice The function does not handle adding the dropped item to the adventurer's bag or any other inventory system. This must be handled separately.
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
    }

    // @dev This function checks if the adventurer has a given item equipped
    // @param item_id The id of the item to check
    // @return A boolean indicating if the item is equipped by the adventurer. Returns true if the item is equipped, false otherwise.
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

    // @dev This function checks if the adventurer has a given item equipped
    // @param item_id The id of the item to check
    // @return A boolean indicating if the item is equipped by the adventurer. Returns true if the item is equipped, false otherwise.
    fn get_item_slot(self: Adventurer, item_id: u8) -> Slot {
        if (self.weapon.id == item_id) {
            Slot::Weapon(())
        } else if (self.chest.id == item_id) {
            Slot::Chest(())
        } else if (self.head.id == item_id) {
            Slot::Head(())
        } else if (self.waist.id == item_id) {
            Slot::Waist(())
        } else if (self.foot.id == item_id) {
            Slot::Foot(())
        } else if (self.hand.id == item_id) {
            Slot::Hand(())
        } else if (self.neck.id == item_id) {
            Slot::Neck(())
        } else if (self.ring.id == item_id) {
            Slot::Ring(())
        } else {
            Slot::None(())
        }
    }

    // @notice Equips the adventurer with a weapon. 
    // @dev The function asserts that the given item is a weapon before adding it to the adventurer's weapon slot.
    // @param item The weapon to be added to the adventurer's equipment.
    fn equip_weapon(ref self: Adventurer, item: ItemPrimitive) {
        assert(ImplLoot::get_slot(item.id) == Slot::Weapon(()), 'Item is not weapon');
        self.weapon = item;
    }

    // @notice Equips the adventurer with a chest armor. 
    // @dev The function asserts that the given item is a chest armor before adding it to the adventurer's chest slot.
    // @param item The chest armor to be added to the adventurer's equipment.
    fn equip_chest_armor(ref self: Adventurer, item: ItemPrimitive) {
        assert(ImplLoot::get_slot(item.id) == Slot::Chest(()), 'Item is not chest armor');
        self.chest = item;
    }

    // @notice Equips the adventurer with a head armor. 
    // @dev The function asserts that the given item is a head armor before adding it to the adventurer's head slot.
    // @param item The head armor to be added to the adventurer's equipment.
    fn equip_head_armor(ref self: Adventurer, item: ItemPrimitive) {
        assert(ImplLoot::get_slot(item.id) == Slot::Head(()), 'Item is not head armor');
        self.head = item;
    }

    // @notice Equips the adventurer with a waist armor. 
    // @dev The function asserts that the given item is a waist armor before adding it to the adventurer's waist slot.
    // @param item The waist armor to be added to the adventurer's equipment.
    fn equip_waist_armor(ref self: Adventurer, item: ItemPrimitive) {
        assert(ImplLoot::get_slot(item.id) == Slot::Waist(()), 'Item is not waist armor');
        self.waist = item;
    }

    // @notice Equips the adventurer with a foot armor. 
    // @dev The function asserts that the given item is a foot armor before adding it to the adventurer's foot slot.
    // @param item The foot armor to be added to the adventurer's equipment.
    fn equip_foot_armor(ref self: Adventurer, item: ItemPrimitive) {
        assert(ImplLoot::get_slot(item.id) == Slot::Foot(()), 'Item is not foot armor');
        self.foot = item;
    }

    // @notice Equips the adventurer with a hand armor. 
    // @dev The function asserts that the given item is a hand armor before adding it to the adventurer's hand slot.
    // @param item The hand armor to be added to the adventurer's equipment.
    fn equip_hand_armor(ref self: Adventurer, item: ItemPrimitive) {
        assert(ImplLoot::get_slot(item.id) == Slot::Hand(()), 'Item is not hand armor');
        self.hand = item;
    }

    // @notice Equips the adventurer with a necklace. 
    // @dev The function asserts that the given item is a necklace before adding it to the adventurer's neck slot.
    // @param item The necklace to be added to the adventurer's equipment.
    fn equip_necklace(ref self: Adventurer, item: ItemPrimitive) {
        assert(ImplLoot::get_slot(item.id) == Slot::Neck(()), 'Item is not necklace');
        self.neck = item;
    }

    // @notice Equips the adventurer with a ring. 
    // @dev The function asserts that the given item is a ring before adding it to the adventurer's ring slot.
    // @param item The ring to be added to the adventurer's equipment.
    fn equip_ring(ref self: Adventurer, item: ItemPrimitive) {
        assert(ImplLoot::get_slot(item.id) == Slot::Ring(()), 'Item is not a ring');
        self.ring = item;
    }

    // @notice This function is used to increase the experience points of a particular item.
    // @dev This function calls the grant_xp_and_check_for_greatness_increase function to execute its logic.
    //
    // @param self A reference to the ItemPrimitive object which represents the item.
    // @param amount The amount of experience points to be added to the item.
    // @param name_storage A reference to the ItemSpecialsStorage object.
    // @param entropy A number used for randomization.
    //
    // @return Returns a tuple containing the original item level, new level,
    //         boolean indicating if a suffix was assigned, boolean indicating if a prefix was assigned,
    //         and a ItemSpecials object storing the special names for the item.
    fn increase_item_xp(
        ref self: ItemPrimitive, amount: u16, ref name_storage: ItemSpecialsStorage, entropy: u128
    ) -> (u8, u8, bool, bool, ItemSpecials) {
        return self.grant_xp_and_check_for_greatness_increase(amount, ref name_storage, entropy);
    }

    // @notice This function increases the experience points of an item and checks for possible level ups, assigning prefixes and suffixes as necessary.
    // @dev The function should only be used internally within the smart contract.
    //
    // @param self A reference to the ItemPrimitive object which represents the item.
    // @param value The amount of experience points to be added to the item.
    // @param name_storage A reference to the ItemSpecialsStorage object.
    // @param entropy A number used for randomization.
    //
    // @return Returns a tuple containing the original item level, new level,
    //         boolean indicating if a suffix was assigned, boolean indicating if a prefix was assigned,
    //         and a ItemSpecials object storing the special names for the item.
    fn grant_xp_and_check_for_greatness_increase(
        ref self: ItemPrimitive, value: u16, ref name_storage: ItemSpecialsStorage, entropy: u128
    ) -> (u8, u8, bool, bool, ItemSpecials) {
        // get the previous level of the item
        let original_level = self.get_greatness();

        // check to ensure adding value to XP does not overflow u16
        if (u16_overflowing_add(self.xp, value).is_ok()) {
            // if it does not, check if the new XP is less than or equal to the max XP
            if (self.xp + value <= ITEM_MAX_XP) {
                // if it is, add it to the item
                self.xp += value;
            } else {
                // if the new XP exceeds the max XP, set the XP to the max XP 
                self.xp = ITEM_MAX_XP;
            }
        } else {
            // if we overflow a u16, set the XP to the max XP
            self.xp = ITEM_MAX_XP;
        }

        // get the new level of the item
        let new_level = self.get_greatness();

        // There are five cases to handle when an item recieves XP
        // 1. The item is the same level as before (no work to do)
        // 2. The item level increased from below G15 to G19+ and thus needs both name prefixes and item suffix
        // 3. The item level increased from below G15 to above G15 but below G19. Assign prefixes
        // 4. The item level increased from below G19 to above G19. Assign suffix
        // 5. The item level increased 

        // if the level is the same
        if (original_level == new_level) {
            // we can return without assigning a prefix or suffix
            return (
                original_level, new_level, false, false, ItemSpecials {
                    special1: 0, special2: 0, special3: 0
                }
            );
        }

        if (original_level < 15 && new_level >= 19) {
            // If the item leveled up, we need to check if it has reached G15 or G19 and
            // unlocked a name suffix or prefix

            // if the item was able to level up from below greatness 15 to 19 (unlikely but possible)

            // item went from below G15 to G19+
            // item gets name prefixes and item suffix
            let suffix_assigned = true;
            let prefix_assigned = true;

            // generate hash using provided entropy and the item id to ensure that even if a group of items
            // unlocks specials at the same time, the names are still unique
            let (specials_rnd1, special_rnd2) = AdventurerUtils::generate_item_special_entropy(
                entropy, self.id
            );

            let special_names = ItemSpecials {
                special1: ImplLoot::get_special1(self.id, specials_rnd1),
                special2: ImplLoot::get_special2(self.id, special_rnd2),
                special3: ImplLoot::get_special3(self.id, specials_rnd1)
            };

            ImplItemSpecials::set_specials(ref name_storage, self, special_names);
            (original_level, new_level, suffix_assigned, prefix_assigned, special_names)
        } // a more likely scenario is the item was previously below greatness 15 and is now at 15 or above
        // in this case we only need to assign the name suffix (Of Power)
        else if (original_level < 15 && new_level >= 15) {
            // item reached G15, grant it an item suffix
            let suffix_assigned = true;
            let prefix_assigned = false;

            // generate hash using provided entropy and the item id to ensure that even if a group of items
            // unlocks specials at the same time, the names are still unique
            let (specials_rnd1, _) = AdventurerUtils::generate_item_special_entropy(
                entropy, self.id
            );

            let special_names = ItemSpecials {
                special1: ImplLoot::get_special1(self.id, specials_rnd1), // set item suffix
                special2: 0,
                special3: 0,
            };

            ImplItemSpecials::set_specials(ref name_storage, self, special_names);
            (original_level, new_level, suffix_assigned, prefix_assigned, special_names)
        } // lastly, we check for the transition from below G19 to G19 or higher which results
        // in the item receiving a name prefix (Demon Grasp)
        else if (original_level < 19 && new_level >= 19) {
            // item got a prefix but not already has a suffix
            let prefix_assigned = true;
            let suffix_assigned = false;

            // generate hash using provided entropy and the item id to ensure that even if a group of items
            // unlocks specials at the same time, the names are still unique
            let (specials_rnd1, specials_rnd2) = AdventurerUtils::generate_item_special_entropy(
                entropy, self.id
            );

            // When handling the greatness upgrade to G19 we need to ensure we preserve
            // the item name suffix applied at G15.
            let special_names = ItemSpecials {
                // preserve previous item suffix from G15
                special1: ImplItemSpecials::get_specials(name_storage, self).special1,
                special2: ImplLoot::get_special2(self.id, specials_rnd1),
                special3: ImplLoot::get_special3(self.id, specials_rnd2),
            };

            ImplItemSpecials::set_specials(ref name_storage, self, special_names);

            (original_level, new_level, suffix_assigned, prefix_assigned, special_names)
        } else {
            // item leveled up but did not receive prefix or suffix
            let prefix_assigned = false;
            let suffix_assigned = false;
            (
                original_level, new_level, false, false, ItemSpecials {
                    special1: 0, special2: 0, special3: 0
                }
            )
        }
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
    // @param self A mutable reference to the Adventurer instance on which the function operates.
    // @param suffix A u8 value representing the suffix tied to the attribute enhancement.
    fn add_suffix_boost(ref self: Adventurer, suffix: u8, ) {
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
            self.deduct_strength(3);
        } else if (suffix == ItemSuffix::of_Giant) {
            self.deduct_vitality(3);
        } else if (suffix == ItemSuffix::of_Titans) {
            self.deduct_strength(2);
            self.deduct_charisma(1);
        } else if (suffix == ItemSuffix::of_Skill) {
            self.deduct_dexterity(3);
        } else if (suffix == ItemSuffix::of_Perfection) {
            self.deduct_strength(1);
            self.deduct_dexterity(1);
            self.deduct_vitality(1);
        } else if (suffix == ItemSuffix::of_Brilliance) {
            self.deduct_intelligence(3);
        } else if (suffix == ItemSuffix::of_Enlightenment) {
            self.deduct_wisdom(3);
        } else if (suffix == ItemSuffix::of_Protection) {
            self.deduct_vitality(2);
            self.deduct_dexterity(1);
        } else if (suffix == ItemSuffix::of_Anger) {
            self.deduct_strength(2);
            self.deduct_dexterity(1);
        } else if (suffix == ItemSuffix::of_Rage) {
            self.deduct_strength(1);
            self.deduct_charisma(1);
            self.deduct_wisdom(1);
        } else if (suffix == ItemSuffix::of_Fury) {
            self.deduct_vitality(1);
            self.deduct_charisma(1);
            self.deduct_intelligence(1);
        } else if (suffix == ItemSuffix::of_Vitriol) {
            self.deduct_intelligence(2);
            self.deduct_wisdom(1);
        } else if (suffix == ItemSuffix::of_the_Fox) {
            self.deduct_dexterity(2);
            self.deduct_charisma(1);
        } else if (suffix == ItemSuffix::of_Detection) {
            self.deduct_wisdom(2);
            self.deduct_dexterity(1);
        } else if (suffix == ItemSuffix::of_Reflection) {
            self.deduct_intelligence(1);
            self.deduct_wisdom(2);
        } else if (suffix == ItemSuffix::of_the_Twins) {
            self.deduct_charisma(3);
        }
    }

    // @notice Applies item stat boosts to an adventurer if the item's greatness is greater than or equal to 15.
    // Boosts are applied based on the special names of the items. The item's special names are stored 
    // in either the first or second name storage.
    // @param self The instance of the Adventurer struct which contains the adventurer's stats and items.
    // @param name_storage1 The first storage of special item names.
    // @param name_storage2 The second storage of special item names.
    fn add_stat_boosts(
        ref self: Adventurer, name_storage1: ItemSpecialsStorage, name_storage2: ItemSpecialsStorage
    ) {
        if (self.weapon.get_greatness() >= 15) {
            if (ImplAdventurer::get_storage_index(self.weapon.metadata) == 0) {
                let weapon_names = ImplItemSpecials::get_specials(name_storage1, self.weapon);
                self.add_suffix_boost(weapon_names.special1);
            } else {
                let weapon_names = ImplItemSpecials::get_specials(name_storage2, self.weapon);
                self.add_suffix_boost(weapon_names.special1);
            }
        }
        if (self.chest.get_greatness() >= 15) {
            if (ImplAdventurer::get_storage_index(self.chest.metadata) == 0) {
                let chest_names = ImplItemSpecials::get_specials(name_storage1, self.chest);
                self.add_suffix_boost(chest_names.special1);
            } else {
                let chest_names = ImplItemSpecials::get_specials(name_storage2, self.chest);
                self.add_suffix_boost(chest_names.special1);
            }
        }
        if (self.head.get_greatness() >= 15) {
            if (ImplAdventurer::get_storage_index(self.head.metadata) == 0) {
                let head_names = ImplItemSpecials::get_specials(name_storage1, self.head);
                self.add_suffix_boost(head_names.special1);
            } else {
                let head_names = ImplItemSpecials::get_specials(name_storage2, self.head);
                self.add_suffix_boost(head_names.special1);
            }
        }
        if (self.waist.get_greatness() >= 15) {
            if (ImplAdventurer::get_storage_index(self.waist.metadata) == 0) {
                let waist_names = ImplItemSpecials::get_specials(name_storage1, self.waist);
                self.add_suffix_boost(waist_names.special1);
            } else {
                let waist_names = ImplItemSpecials::get_specials(name_storage2, self.waist);
                self.add_suffix_boost(waist_names.special1);
            }
        }

        if (self.foot.get_greatness() >= 15) {
            if (ImplAdventurer::get_storage_index(self.foot.metadata) == 0) {
                let foot_names = ImplItemSpecials::get_specials(name_storage1, self.foot);
                self.add_suffix_boost(foot_names.special1);
            } else {
                let foot_names = ImplItemSpecials::get_specials(name_storage2, self.foot);
                self.add_suffix_boost(foot_names.special1);
            }
        }

        if (self.hand.get_greatness() >= 15) {
            if (ImplAdventurer::get_storage_index(self.hand.metadata) == 0) {
                let hand_names = ImplItemSpecials::get_specials(name_storage1, self.hand);
                self.add_suffix_boost(hand_names.special1);
            } else {
                let hand_names = ImplItemSpecials::get_specials(name_storage2, self.hand);
                self.add_suffix_boost(hand_names.special1);
            }
        }

        if (self.neck.get_greatness() >= 15) {
            if (ImplAdventurer::get_storage_index(self.neck.metadata) == 0) {
                let neck_names = ImplItemSpecials::get_specials(name_storage1, self.neck);
                self.add_suffix_boost(neck_names.special1);
            } else {
                let neck_names = ImplItemSpecials::get_specials(name_storage2, self.neck);
                self.add_suffix_boost(neck_names.special1);
            }
        }

        if (self.ring.get_greatness() >= 15) {
            if (ImplAdventurer::get_storage_index(self.ring.metadata) == 0) {
                let ring_names = ImplItemSpecials::get_specials(name_storage1, self.ring);
                self.add_suffix_boost(ring_names.special1);
            } else {
                let ring_names = ImplItemSpecials::get_specials(name_storage2, self.ring);
                self.add_suffix_boost(ring_names.special1);
            }
        }

        // check to ensure adventurer doesn't have more health
        // than the max provided by vitality stat
        if self.health > self.get_max_health() {
            self.health = self.get_max_health();
        }
    }

    // @notice The `remove_stat_boosts` function takes a reference to an Adventurer and two ItemSpecialsStorages 
    // and removes the item stat boosts from the Adventurer's equipment.
    // @param self A reference to the Adventurer instance.
    // @param name_storage1 The first ItemSpecialsStorage instance.
    // @param name_storage2 The second ItemSpecialsStorage instance.
    fn remove_stat_boosts(
        ref self: Adventurer, name_storage1: ItemSpecialsStorage, name_storage2: ItemSpecialsStorage
    ) {
        if (self.weapon.get_greatness() >= 15) {
            if (ImplAdventurer::get_storage_index(self.weapon.metadata) == 0) {
                let weapon_names = ImplItemSpecials::get_specials(name_storage1, self.weapon);
                self.remove_suffix_boost(weapon_names.special1, );
            } else {
                let weapon_names = ImplItemSpecials::get_specials(name_storage2, self.weapon);
                self.remove_suffix_boost(weapon_names.special1, );
            }
        }
        if (self.chest.get_greatness() >= 15) {
            if (ImplAdventurer::get_storage_index(self.chest.metadata) == 0) {
                let chest_names = ImplItemSpecials::get_specials(name_storage1, self.chest);
                self.remove_suffix_boost(chest_names.special1, );
            } else {
                let chest_names = ImplItemSpecials::get_specials(name_storage2, self.chest);
                self.remove_suffix_boost(chest_names.special1, );
            }
        }
        if (self.head.get_greatness() >= 15) {
            if (ImplAdventurer::get_storage_index(self.head.metadata) == 0) {
                let head_names = ImplItemSpecials::get_specials(name_storage1, self.head);
                self.remove_suffix_boost(head_names.special1, );
            } else {
                let head_names = ImplItemSpecials::get_specials(name_storage2, self.head);
                self.remove_suffix_boost(head_names.special1, );
            }
        }
        if (self.waist.get_greatness() >= 15) {
            if (ImplAdventurer::get_storage_index(self.waist.metadata) == 0) {
                let waist_names = ImplItemSpecials::get_specials(name_storage1, self.waist);
                self.remove_suffix_boost(waist_names.special1, );
            } else {
                let waist_names = ImplItemSpecials::get_specials(name_storage2, self.waist);
                self.remove_suffix_boost(waist_names.special1, );
            }
        }

        if (self.foot.get_greatness() >= 15) {
            if (ImplAdventurer::get_storage_index(self.foot.metadata) == 0) {
                let foot_names = ImplItemSpecials::get_specials(name_storage1, self.foot);
                self.remove_suffix_boost(foot_names.special1, );
            } else {
                let foot_names = ImplItemSpecials::get_specials(name_storage2, self.foot);
                self.remove_suffix_boost(foot_names.special1, );
            }
        }

        if (self.hand.get_greatness() >= 15) {
            if (ImplAdventurer::get_storage_index(self.hand.metadata) == 0) {
                let hand_names = ImplItemSpecials::get_specials(name_storage1, self.hand);
                self.remove_suffix_boost(hand_names.special1, );
            } else {
                let hand_names = ImplItemSpecials::get_specials(name_storage2, self.hand);
                self.remove_suffix_boost(hand_names.special1, );
            }
        }

        if (self.neck.get_greatness() >= 15) {
            if (ImplAdventurer::get_storage_index(self.neck.metadata) == 0) {
                let neck_names = ImplItemSpecials::get_specials(name_storage1, self.neck);
                self.remove_suffix_boost(neck_names.special1, );
            } else {
                let neck_names = ImplItemSpecials::get_specials(name_storage2, self.neck);
                self.remove_suffix_boost(neck_names.special1, );
            }
        }

        if (self.ring.get_greatness() >= 15) {
            // we need to get the suffix which is in one of the two meta data storages
            if (ImplAdventurer::get_storage_index(self.ring.metadata) == 0) {
                // it's in storage slot 1
                let ring_names = ImplItemSpecials::get_specials(name_storage1, self.ring);
                self.remove_suffix_boost(ring_names.special1, );
            } else {
                // it's in storage slot 2
                let ring_names = ImplItemSpecials::get_specials(name_storage2, self.ring);
                self.remove_suffix_boost(ring_names.special1, );
            }
        }
    }

    // @notice The `get_storage_index` function is a helper function that determines the storage index based on the metadata ID.
    // @param meta_data_id The ID of the metadata. 
    // @return Returns 0 if the metadata ID is less than or equal to 10, otherwise returns 1.
    fn get_storage_index(meta_data_id: u8) -> u256 {
        if (meta_data_id <= 10) {
            return 0;
        } else {
            return 1;
        }
    }

    // @notice The `get_idle_blocks` function calculates the number of idle blocks by subtracting the last action from the 
    // current block (modulo 512). 
    // @param self A reference to the Adventurer instance.
    // @param current_block The current block number.
    // @return Returns the number of idle blocks.
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

    // get_greatness returns the greatness level of an item based on xp
    // @param xp The xp of the item.
    // @return The greatness level of the item.
    fn get_greatness(self: ItemPrimitive) -> u8 {
        // use combat lib to determine the level but give items a bonus based
        // on the item level multiplier setting (currently 4) which means
        // items will level up 4x faster than entities without a multplier
        // such as adventurers
        let level = ImplCombat::get_level_from_xp(self.xp);

        // if level exceeds max greatness
        if level > ITEM_MAX_GREATNESS {
            // return max greatness
            ITEM_MAX_GREATNESS
        } else {
            level
        }
    }

    // @notice: set_last_action sets the last action on the adventurer to the current block
    // @dev: we only have 9 bits of storage for block numbers so we need to modulo the current block
    // @dev: by 512 to ensure we don't overflow the storage
    // @param self A reference to the Adventurer instance.
    // @param current_block The current block number.

    fn set_last_action(ref self: Adventurer, current_block: u64) {
        // adventurer only has 9 bits of storage for block numbers
        // the last_action on the adventurer is 0-511 which is based on 
        // the current starknet block % 512. As such, when calculating the number Of
        // idle blocks, we need to % 512 the current block
        let current_block_modulo_512: u16 = (current_block % MAX_BLOCK_COUNT).try_into().unwrap();

        self.last_action = current_block_modulo_512;
    }
}

// ---------------------------
// ---------- Tests ----------
// ---------------------------
#[test]
#[available_gas(200000)]
fn test_charisma_adjusted_item_price() {
    let mut adventurer = ImplAdventurer::new(12, 0, 0, 0, 0, 0, 0, 0);

    // zero case
    let item_price = adventurer.charisma_adjusted_item_price(0);
    assert(item_price == MINIMUM_ITEM_PRICE, 'item should be min price');

    // above minimum price, no charisma (base case)
    let item_price = adventurer.charisma_adjusted_item_price(10);
    item_price.print();
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
    let mut adventurer = ImplAdventurer::new(12, 0, 0, 0, 0, 0, 0, 0);

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
    let mut adventurer = ImplAdventurer::new(12, 0, 0, 0, 0, 0, 0, 0);
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
        last_action: 511, health: 511, xp: 8191, stats: Stats {
            strength: 31, dexterity: 31, vitality: 31, intelligence: 31, wisdom: 31, charisma: 31, 
            }, gold: 511, weapon: ItemPrimitive {
            id: 127, xp: 511, metadata: 31, 
            }, chest: ItemPrimitive {
            id: 1, xp: 0, metadata: 0, 
            }, head: ItemPrimitive {
            id: 127, xp: 511, metadata: 31, 
            }, waist: ItemPrimitive {
            id: 87, xp: 511, metadata: 4, 
            }, foot: ItemPrimitive {
            id: 78, xp: 511, metadata: 5, 
            }, hand: ItemPrimitive {
            id: 34, xp: 511, metadata: 6, 
            }, neck: ItemPrimitive {
            id: 32, xp: 511, metadata: 7, 
            }, ring: ItemPrimitive {
            id: 1, xp: 511, metadata: 8, 
        }, beast_health: 511, stat_points_available: 7,
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
        adventurer.stat_points_available == unpacked.stat_points_available, 'stat_points_available'
    );
}

#[test]
#[available_gas(3000000)]
fn test_packing_stat_overflow_protection() {
    // create an adventurer with stats at max u8
    let adventurer = Adventurer {
        last_action: 511, health: 511, xp: 8191, stats: Stats {
            strength: 255,
            dexterity: 255,
            vitality: 255,
            intelligence: 255,
            wisdom: 255,
            charisma: 255,
            }, gold: 511, weapon: ItemPrimitive {
            id: 127, xp: 511, metadata: 31, 
            }, chest: ItemPrimitive {
            id: 1, xp: 0, metadata: 0, 
            }, head: ItemPrimitive {
            id: 127, xp: 511, metadata: 31, 
            }, waist: ItemPrimitive {
            id: 87, xp: 511, metadata: 4, 
            }, foot: ItemPrimitive {
            id: 78, xp: 511, metadata: 5, 
            }, hand: ItemPrimitive {
            id: 34, xp: 511, metadata: 6, 
            }, neck: ItemPrimitive {
            id: 32, xp: 511, metadata: 7, 
            }, ring: ItemPrimitive {
            id: 1, xp: 511, metadata: 8, 
        }, beast_health: 511, stat_points_available: 7,
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
    let new_adventurer = ImplAdventurer::new(12, 0, 0, 0, 0, 0, 0, 0);
    new_adventurer.pack();
    assert(new_adventurer.health == STARTING_HEALTH, 'wrong starting health');
    assert(new_adventurer.gold == STARTING_GOLD, 'wrong starting gold');
    assert(new_adventurer.xp == 0, 'wrong starting xp');
}


#[test]
#[available_gas(200000)]
fn test_increase_health() {
    let mut adventurer = ImplAdventurer::new(12, 0, 0, 0, 0, 0, 0, 0);

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
        adventurer.health == STARTING_HEALTH + VITALITY_HEALTH_CAP_INCREASE.into(),
        'max health error'
    );

    // check overflow
    adventurer.increase_health(65535);
    assert(
        adventurer.health == STARTING_HEALTH + VITALITY_HEALTH_CAP_INCREASE.into(),
        'health should be 120'
    );
}

#[test]
#[available_gas(200000)]
fn test_get_max_health() {
    let mut adventurer = ImplAdventurer::new(12, 0, 0, 0, 0, 0, 0, 0);

    // assert starting state
    assert(adventurer.get_max_health() == STARTING_HEALTH, 'advntr should have max health');

    // base case
    adventurer.stats.vitality = 1;
    // assert max health is starting health + single vitality increase
    assert(
        adventurer.get_max_health() == STARTING_HEALTH + VITALITY_HEALTH_CAP_INCREASE.into(),
        'max health shuld be 120'
    );

    // extreme/overflow case
    adventurer.stats.vitality = 255;
    assert(adventurer.get_max_health() == MAX_ADVENTURER_HEALTH, 'wrong max health');
}

#[test]
#[available_gas(200000)]
fn test_has_full_health() {
    let mut adventurer = ImplAdventurer::new(12, 0, 0, 0, 0, 0, 0, 0);

    // adventurers should start with full health
    assert(adventurer.has_full_health() == true, 'should start with full health');

    // increase max health via vitality boost
    // health is no longer technically full
    adventurer.stats.vitality = 2;
    assert(adventurer.has_full_health() == false, 'vitality increased max');

    // fill up health
    adventurer.increase_health(100);
    assert(adventurer.has_full_health() == true, 'health should be full');

    // deduct 1 health
    adventurer.deduct_health(1);
    assert(adventurer.has_full_health() == false, 'health should not be full');
}

#[test]
#[available_gas(3000000)]
fn test_add_gold() {
    let mut adventurer = ImplAdventurer::new(12, 0, 0, 0, 0, 0, 0, 0);

    // assert starting state
    assert(adventurer.gold == STARTING_GOLD, 'wrong advntr starting gold');

    // base case
    adventurer.add_gold(5);
    assert(adventurer.gold == STARTING_GOLD + 5, 'gold should be +5');

    // at max value case
    adventurer.add_gold(MAX_GOLD);
    assert(adventurer.gold == MAX_GOLD, 'gold should be max');

    // pack and unpack adventurer to test overflow in packing
    let unpacked: Adventurer = Packing::unpack(adventurer.pack());
    assert(unpacked.gold == MAX_GOLD, 'should still be max gold');

    // extreme/overflow case
    adventurer.gold = 65535;
    adventurer.add_gold(65535);
    assert(adventurer.gold == MAX_GOLD, 'gold overflow check');
}

#[test]
#[available_gas(90000)]
fn test_deduct_health() {
    let mut adventurer = ImplAdventurer::new(12, 0, 0, 0, 0, 0, 0, 0);
    let starting_health = adventurer.health;
    let deduct_amount = 5;

    // base case
    adventurer.deduct_health(deduct_amount);
    assert(adventurer.health == starting_health - deduct_amount, 'wrong health');

    // underflow case
    adventurer.deduct_health(65535);
    assert(adventurer.health == 0, 'health should be 0');
}

#[test]
#[available_gas(90000)]
fn test_deduct_gold() {
    let mut adventurer = ImplAdventurer::new(12, 0, 0, 0, 0, 0, 0, 0);
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
#[available_gas(200000)]
fn test_increase_adventurer_xp() {
    let mut adventurer = ImplAdventurer::new(12, 0, 0, 0, 0, 0, 0, 0);
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
fn test_add_stat_upgrade_points() {
    // get new adventurer
    let mut adventurer = ImplAdventurer::new(12, 0, 0, 0, 0, 0, 0, 0);
    let original_stat_points = adventurer.stat_points_available;

    // zero case
    adventurer.add_stat_upgrade_points(0);
    assert(
        adventurer.stat_points_available == original_stat_points, 'stat points should not change'
    );

    // base case - adding 1 stat point (no need to pack and unpack this test case)
    adventurer.add_stat_upgrade_points(1);
    assert(
        adventurer.stat_points_available == 1 + original_stat_points, 'stat points should be +1'
    );

    // max stat upgrade value case
    adventurer.add_stat_upgrade_points(MAX_STAT_UPGRADES);
    assert(adventurer.stat_points_available == MAX_STAT_UPGRADES, 'stat points should be max');

    // pack and unpack at max value to ensure our max values are correct for packing
    let unpacked: Adventurer = Packing::unpack(adventurer.pack());
    assert(unpacked.stat_points_available == MAX_STAT_UPGRADES, 'stat point should still be max');

    // extreme/overflow case
    adventurer.stat_points_available = 255;
    adventurer.add_stat_upgrade_points(255);
    assert(adventurer.stat_points_available == MAX_STAT_UPGRADES, 'stat points should be max');
}

#[test]
#[available_gas(90000)]
fn test_add_strength() {
    let mut adventurer = ImplAdventurer::new(12, 0, 0, 0, 0, 0, 0, 0);
    // basic case
    adventurer.increase_strength(1);
    assert(adventurer.stats.strength == 1, 'strength should be 1');
    // overflow case
    adventurer.increase_strength(255);
    assert(adventurer.stats.strength == MAX_STAT_VALUE, 'strength should be max');
}

#[test]
#[available_gas(90000)]
fn test_add_dexterity() {
    let mut adventurer = ImplAdventurer::new(12, 0, 0, 0, 0, 0, 0, 0);
    // basic case
    adventurer.increase_dexterity(1);
    assert(adventurer.stats.dexterity == 1, 'dexterity should be 1');
    // overflow case
    adventurer.increase_dexterity(255);
    assert(adventurer.stats.dexterity == MAX_STAT_VALUE, 'dexterity should be max');
}

#[test]
#[available_gas(90000)]
fn test_add_vitality() {
    let mut adventurer = ImplAdventurer::new(12, 0, 0, 0, 0, 0, 0, 0);
    // basic case
    adventurer.increase_vitality(1);
    assert(adventurer.stats.vitality == 1, 'vitality should be 1');
    // overflow case
    adventurer.increase_vitality(255);
    assert(adventurer.stats.vitality == MAX_STAT_VALUE, 'vitality should be max');
}

#[test]
#[available_gas(90000)]
fn test_add_intelligence() {
    let mut adventurer = ImplAdventurer::new(12, 0, 0, 0, 0, 0, 0, 0);
    // basic case
    adventurer.increase_intelligence(1);
    assert(adventurer.stats.intelligence == 1, 'intelligence should be 1');
    // overflow case
    adventurer.increase_intelligence(255);
    assert(adventurer.stats.intelligence == MAX_STAT_VALUE, 'intelligence should be max');
}

#[test]
#[available_gas(90000)]
fn test_add_wisdom() {
    let mut adventurer = ImplAdventurer::new(12, 0, 0, 0, 0, 0, 0, 0);
    // basic case
    adventurer.increase_wisdom(1);
    assert(adventurer.stats.wisdom == 1, 'wisdom should be 1');
    // overflow case
    adventurer.increase_wisdom(255);
    assert(adventurer.stats.wisdom == MAX_STAT_VALUE, 'wisdom should be max');
}

#[test]
#[available_gas(90000)]
fn test_add_charisma() {
    let mut adventurer = ImplAdventurer::new(12, 0, 0, 0, 0, 0, 0, 0);
    // basic case
    adventurer.increase_charisma(1);
    assert(adventurer.stats.charisma == 1, 'charisma should be 1');
    // overflow case
    adventurer.increase_charisma(255);
    assert(adventurer.stats.charisma == MAX_STAT_VALUE, 'charisma should be max');
}

#[test]
#[available_gas(90000)]
fn test_deduct_strength() {
    let mut adventurer = ImplAdventurer::new(12, 0, 0, 0, 0, 0, 0, 0);
    // basic case
    adventurer.increase_strength(2);
    adventurer.deduct_strength(1);
    assert(adventurer.stats.strength == 1, 'strength should be 1');
    // underflow case
    adventurer.increase_strength(5);
    adventurer.deduct_strength(255);
    assert(adventurer.stats.strength == 0, 'strength should be 0');
}

#[test]
#[available_gas(90000)]
fn test_deduct_dexterity() {
    let mut adventurer = ImplAdventurer::new(12, 0, 0, 0, 0, 0, 0, 0);
    // basic case
    adventurer.increase_dexterity(2);
    adventurer.deduct_dexterity(1);
    assert(adventurer.stats.dexterity == 1, 'dexterity should be 1');
    // underflow case
    adventurer.increase_dexterity(5);
    adventurer.deduct_dexterity(255);
    assert(adventurer.stats.dexterity == 0, 'dexterity should be 0');
}

#[test]
#[available_gas(90000)]
fn test_deduct_vitality() {
    let mut adventurer = ImplAdventurer::new(12, 0, 0, 0, 0, 0, 0, 0);
    // basic case
    adventurer.increase_vitality(2);
    adventurer.deduct_vitality(1);
    assert(adventurer.stats.vitality == 1, 'vitality should be 1');
    // underflow case
    adventurer.increase_vitality(5);
    adventurer.deduct_vitality(255);
    assert(adventurer.stats.vitality == 0, 'vitality should be 0');
}

#[test]
#[available_gas(90000)]
fn test_deduct_intelligence() {
    let mut adventurer = ImplAdventurer::new(12, 0, 0, 0, 0, 0, 0, 0);
    // basic case
    adventurer.increase_intelligence(2);
    adventurer.deduct_intelligence(1);
    assert(adventurer.stats.intelligence == 1, 'intelligence should be 1');
    // underflow case
    adventurer.increase_intelligence(5);
    adventurer.deduct_intelligence(255);
    assert(adventurer.stats.intelligence == 0, 'intelligence should be 0');
}

#[test]
#[available_gas(90000)]
fn test_deduct_wisdom() {
    let mut adventurer = ImplAdventurer::new(12, 0, 0, 0, 0, 0, 0, 0);
    // basic case
    adventurer.increase_wisdom(2);
    adventurer.deduct_wisdom(1);
    assert(adventurer.stats.wisdom == 1, 'wisdom should be 1');
    // underflow case
    adventurer.increase_wisdom(5);
    adventurer.deduct_wisdom(255);
    assert(adventurer.stats.wisdom == 0, 'wisdom should be 0');
}

#[test]
#[available_gas(90000)]
fn test_deduct_charisma() {
    let mut adventurer = ImplAdventurer::new(12, 0, 0, 0, 0, 0, 0, 0);
    // basic case
    adventurer.increase_charisma(2);
    adventurer.deduct_charisma(1);
    assert(adventurer.stats.charisma == 1, 'charisma should be 1');

    // underflow case
    adventurer.increase_charisma(5);
    adventurer.deduct_charisma(255);
    assert(adventurer.stats.charisma == 0, 'charisma should be 0');
}

#[test]
#[should_panic(expected: ('Item is not weapon', ))]
#[available_gas(90000)]
fn test_equip_invalid_weapon() {
    let mut adventurer = ImplAdventurer::new(12, 0, 0, 0, 0, 0, 0, 0);
    // create demon crown item
    let item = ItemPrimitive { id: constants::ItemId::DemonCrown, xp: 1, metadata: 0 };
    // try to equip it to adventurer as a weapon
    adventurer.equip_weapon(item);
// should panic with 'Item is not weapon' message
// because demon crown is not a weapon
// test is annotated to expect this panic and will
// pass if it does, otherwise it will fail
}

#[test]
#[available_gas(90000)]
fn test_equip_valid_weapon() {
    let mut adventurer = ImplAdventurer::new(12, 0, 0, 0, 0, 0, 0, 0);

    // Create Katana item
    let item = ItemPrimitive { id: constants::ItemId::Katana, xp: 1, metadata: 0 };

    // Equip to adventurer as a weapon
    adventurer.equip_weapon(item);

    // Assert item was equipped
    assert(adventurer.weapon.id == constants::ItemId::Katana, 'did not equip weapon');
    assert(adventurer.weapon.xp == 1, 'weapon xp is not 1');
    assert(adventurer.weapon.metadata == 0, 'weapon metadata is not 0');
}

#[test]
#[should_panic(expected: ('Item is not chest armor', ))]
#[available_gas(90000)]
fn test_equip_invalid_chest() {
    let mut adventurer = ImplAdventurer::new(12, 0, 0, 0, 0, 0, 0, 0);
    // try to equip a Demon Crown as chest item
    let item = ItemPrimitive { id: constants::ItemId::DemonCrown, xp: 1, metadata: 0 };
    adventurer.equip_chest_armor(item);
// should panic with 'Item is not chest armor' message
// because Demon Crown is not chest armor
// test is annotated to expect this panic and will
// pass if it does, otherwise it will fail
}

#[test]
#[available_gas(90000)]
fn test_equip_valid_chest() {
    let mut adventurer = ImplAdventurer::new(12, 0, 0, 0, 0, 0, 0, 0);
    // equip Divine Robe as chest item
    let item = ItemPrimitive { id: constants::ItemId::DivineRobe, xp: 1, metadata: 0 };
    adventurer.equip_chest_armor(item);

    // this should not panic
    // assert item was equipped
    assert(adventurer.chest.id == constants::ItemId::DivineRobe, 'did not equip chest armor');
    assert(adventurer.chest.xp == 1, 'chest armor xp is not 1');
    assert(adventurer.chest.metadata == 0, 'chest armor metadata is not 0');
}

#[test]
#[should_panic(expected: ('Item is not head armor', ))]
#[available_gas(90000)]
fn test_equip_invalid_head() {
    let mut adventurer = ImplAdventurer::new(12, 0, 0, 0, 0, 0, 0, 0);
    // try to equip a Katana as head item
    let item = ItemPrimitive { id: constants::ItemId::Katana, xp: 1, metadata: 0 };
    adventurer.equip_head_armor(item);
// should panic with 'Item is not head armor' message
}

#[test]
#[available_gas(90000)]
fn test_equip_valid_head() {
    let mut adventurer = ImplAdventurer::new(12, 0, 0, 0, 0, 0, 0, 0);
    // equip Crown as head item
    let item = ItemPrimitive { id: constants::ItemId::Crown, xp: 1, metadata: 0 };
    adventurer.equip_head_armor(item);
    // this should not panic
    // assert item was equipped
    assert(adventurer.head.id == constants::ItemId::Crown, 'did not equip head armor');
    assert(adventurer.head.xp == 1, 'head armor xp is not 1');
    assert(adventurer.head.metadata == 0, 'head armor metadata is not 0');
}

#[test]
#[should_panic(expected: ('Item is not waist armor', ))]
#[available_gas(90000)]
fn test_equip_invalid_waist() {
    let mut adventurer = ImplAdventurer::new(12, 0, 0, 0, 0, 0, 0, 0);
    // try to equip a Demon Crown as waist item
    let item = ItemPrimitive { id: constants::ItemId::DemonCrown, xp: 1, metadata: 0 };
    adventurer.equip_waist_armor(item);
// should panic with 'Item is not waist armor' message
}

#[test]
#[available_gas(90000)]
fn test_equip_valid_waist() {
    let mut adventurer = ImplAdventurer::new(12, 0, 0, 0, 0, 0, 0, 0);

    // equip Wool Sash as waist item
    let item = ItemPrimitive { id: constants::ItemId::WoolSash, xp: 1, metadata: 0 };
    adventurer.equip_waist_armor(item);

    // this should not panic
    // assert item was equipped
    assert(adventurer.waist.id == constants::ItemId::WoolSash, 'did not equip waist armor');
    assert(adventurer.waist.xp == 1, 'waist armor xp is not 1');
    assert(adventurer.waist.metadata == 0, 'waist armor metadata is not 0');
}

#[test]
#[should_panic(expected: ('Item is not foot armor', ))]
#[available_gas(90000)]
fn test_equip_invalid_foot() {
    let mut adventurer = ImplAdventurer::new(12, 0, 0, 0, 0, 0, 0, 0);
    // try to equip a Demon Crown as foot item
    let item = ItemPrimitive { id: constants::ItemId::DemonCrown, xp: 1, metadata: 0 };
    adventurer.equip_foot_armor(item);
// should panic with 'Item is not foot armor' message
}

#[test]
#[available_gas(90000)]
fn test_equip_valid_foot() {
    let mut adventurer = ImplAdventurer::new(12, 0, 0, 0, 0, 0, 0, 0);

    // equip Silk Slippers as foot item
    let item = ItemPrimitive { id: constants::ItemId::SilkSlippers, xp: 1, metadata: 0 };
    adventurer.equip_foot_armor(item);

    // this should not panic
    // assert item was equipped
    assert(adventurer.foot.id == constants::ItemId::SilkSlippers, 'did not equip foot armor');
    assert(adventurer.foot.xp == 1, 'foot armor xp is not 1');
    assert(adventurer.foot.metadata == 0, 'foot armor metadata is not 0');
}

#[test]
#[should_panic(expected: ('Item is not hand armor', ))]
#[available_gas(90000)]
fn test_equip_invalid_hand() {
    let mut adventurer = ImplAdventurer::new(12, 0, 0, 0, 0, 0, 0, 0);

    // try to equip a Demon Crown as hand item
    let item = ItemPrimitive { id: constants::ItemId::DemonCrown, xp: 1, metadata: 0 };
    adventurer.equip_hand_armor(item);
// should panic with 'Item is not hand armor' message
}

#[test]
#[available_gas(90000)]
fn test_equip_valid_hand() {
    let mut adventurer = ImplAdventurer::new(12, 0, 0, 0, 0, 0, 0, 0);

    // equip Divine Gloves as hand item
    let item = ItemPrimitive { id: constants::ItemId::DivineGloves, xp: 1, metadata: 0 };
    adventurer.equip_hand_armor(item);

    // this should not panic
    // assert item was equipped
    assert(adventurer.hand.id == constants::ItemId::DivineGloves, 'did not equip hand armor');
    assert(adventurer.hand.xp == 1, 'hand armor xp is not 1');
    assert(adventurer.hand.metadata == 0, 'hand armor metadata is not 0');
}

#[test]
#[should_panic(expected: ('Item is not necklace', ))]
#[available_gas(90000)]
fn test_equip_invalid_neck() {
    let mut adventurer = ImplAdventurer::new(12, 0, 0, 0, 0, 0, 0, 0);

    // try to equip a Demon Crown as necklace
    let item = ItemPrimitive { id: constants::ItemId::DemonCrown, xp: 1, metadata: 0 };
    adventurer.equip_necklace(item);
// should panic with 'Item is not necklace' message
}

#[test]
#[available_gas(90000)]
fn test_equip_valid_neck() {
    let mut adventurer = ImplAdventurer::new(12, 0, 0, 0, 0, 0, 0, 0);

    // equip Pendant as necklace
    let item = ItemPrimitive { id: constants::ItemId::Pendant, xp: 1, metadata: 0 };
    adventurer.equip_necklace(item);

    // this should not panic
    // assert item was equipped
    assert(adventurer.neck.id == constants::ItemId::Pendant, 'did not equip necklace');
    assert(adventurer.neck.xp == 1, 'necklace xp is not 1');
    assert(adventurer.neck.metadata == 0, 'necklace metadata is not 0');
}

#[test]
#[should_panic(expected: ('Item is not a ring', ))]
#[available_gas(90000)]
fn test_equip_invalid_ring() {
    let mut adventurer = ImplAdventurer::new(12, 0, 0, 0, 0, 0, 0, 0);

    // try to equip a Demon Crown as ring
    let item = ItemPrimitive { id: constants::ItemId::DemonCrown, xp: 1, metadata: 0 };
    adventurer.equip_ring(item);
// should panic with 'Item is not a ring' message
}

#[test]
#[available_gas(90000)]
fn test_equip_valid_ring() {
    let mut adventurer = ImplAdventurer::new(12, 0, 0, 0, 0, 0, 0, 0);
    let item = ItemPrimitive { id: constants::ItemId::PlatinumRing, xp: 1, metadata: 0 };
    adventurer.equip_ring(item);
    assert(adventurer.ring.id == constants::ItemId::PlatinumRing, 'did not equip ring');
    assert(adventurer.ring.xp == 1, 'ring xp is not 1');
    assert(adventurer.ring.metadata == 0, 'ring metadata is not 0');
}

#[test]
#[available_gas(6000000)]
fn test_increase_item_xp() {
    let mut adventurer = ImplAdventurer::new(12, 0, 0, 0, 0, 0, 0, 0);
    let entropy = 1;
    let item_ghost_wand = ItemPrimitive { id: constants::ItemId::GhostWand, xp: 1, metadata: 1 };
    adventurer.equip_item(item_ghost_wand);

    let blank_special_name = ItemSpecials { special2: 0, special3: 0, special1: 0 };

    let ghost_wand_special_name = ItemSpecials { special2: 0, special3: 0, special1: 0 };

    let mut loot_item_name_storage = ItemSpecialsStorage {
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

    let original_level = adventurer.weapon.get_greatness();

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

    assert(special_names.special1 != 0, 'suffix should be set');
    assert(special_names.special2 == 0, 'name prefix should be 0');
    assert(special_names.special3 == 0, 'name suffix should be 0');
    // verify name was updated in storage
    assert(loot_item_name_storage.item_1.special1 != 0, 'suffix should be set');

    // save the suffix the item received at G15 to ensure it is persisted when prefixes get unlocked at G19
    let original_weapon_suffix = loot_item_name_storage.item_1.special1;
    // grant weapon 136 more xp, bringing it to 361 total (level 19 - prefixes assigned)
    let (previous_level, new_level, suffix_assigned, prefix_assigned, special_names) = adventurer
        .weapon
        .increase_item_xp(136, ref loot_item_name_storage, 1);
    assert(adventurer.weapon.xp == 361, 'weapon should have 361');
    assert(previous_level == 15, 'weapon prev level should be 15');
    assert(new_level == 19, 'weapon new level should be 19');
    assert(suffix_assigned == false, 'weapon should not recv suffix');
    assert(prefix_assigned == true, 'weapon should recv prefixes');

    assert(special_names.special1 == original_weapon_suffix, 'suffix should not have changed');
    assert(special_names.special2 != 0, 'name prefix should be set');
    assert(special_names.special3 != 0, 'name suffix should be set');
    // verify storage data was updated properly
    assert(
        loot_item_name_storage.item_1.special1 == original_weapon_suffix,
        'suffix should not have changed'
    );
    assert(loot_item_name_storage.item_1.special2 != 0, 'name prefix should be set');
    assert(loot_item_name_storage.item_1.special3 != 0, 'name suffix should be set');
    let original_special2 = loot_item_name_storage.item_1.special2;
    let original_special3 = loot_item_name_storage.item_1.special3;

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
        loot_item_name_storage.item_1.special1 == original_weapon_suffix,
        'item suffix should be same'
    );
    assert(
        loot_item_name_storage.item_1.special2 == original_special2, 'name prefix should be same'
    );
    assert(
        loot_item_name_storage.item_1.special3 == original_special3, 'name suffix should be same'
    );

    // test with max XP input (2^16) - 1 = 65535;
    let (previous_level, new_level, suffix_assigned, prefix_assigned, special_names) = adventurer
        .weapon
        .increase_item_xp(65535, ref loot_item_name_storage, 1);
    assert(adventurer.weapon.xp == 400, 'max item xp is 400');
    assert(previous_level == 20, 'weapon prev level should be 20');
    assert(new_level == ITEM_MAX_GREATNESS, 'weapon new lvl should be max');
    assert(suffix_assigned == false, 'weapon should not recv suffix');
    assert(prefix_assigned == false, 'weapon should not recv prefixes');
    // verify storage data was not updated
    assert(
        loot_item_name_storage.item_1.special1 == original_weapon_suffix,
        'item suffix should be same'
    );
    assert(
        loot_item_name_storage.item_1.special2 == original_special2, 'name prefix should be same'
    );
    assert(
        loot_item_name_storage.item_1.special3 == original_special3, 'name suffix should be same'
    );

    // There is one more variant to test when it comes to item leveling and name assignment
    // which is an item going from < G15 to G19 in a single hop. This is highly unlikely
    // but technically possible so the contract needs to be able to handle it

    // to test this lets create a new item
    let divine_robe = ItemPrimitive { id: constants::ItemId::DivineRobe, xp: 1, metadata: 2 };
    adventurer.equip_item(divine_robe);

    // verify starting state
    assert(adventurer.chest.id == constants::ItemId::DivineRobe, 'advntr should have divine robe');
    assert(adventurer.chest.xp == 1, 'divine robe should have 1 xp');
    assert(adventurer.chest.metadata == 2, 'advntr should have divine robe');
    let divine_robe_starting_level = adventurer.chest.get_greatness();
    assert(divine_robe_starting_level == 1, 'divine robe should be level 1');

    // give divine robe max XP 65535
    let (previous_level, new_level, suffix_assigned, prefix_assigned, special_names) = adventurer
        .chest
        .increase_item_xp(65535, ref loot_item_name_storage, 1);
    assert(adventurer.chest.xp == 400, 'max item xp is 400');
    assert(previous_level == divine_robe_starting_level, 'DR prev level should be 1');
    assert(new_level == ITEM_MAX_GREATNESS, 'DR new level should be MAX');
    assert(suffix_assigned == true, 'DR should have recv suffix');
    assert(prefix_assigned == true, 'DR should have recv prefix');

    assert(special_names.special1 != 0, 'suffix should be set');
    assert(special_names.special2 != 0, 'name prefix should be set');
    assert(special_names.special3 != 0, 'name suffix should be set');
    // verify storage data was updated properly
    assert(
        special_names.special1 == loot_item_name_storage.item_2.special1,
        'storage suffix should be set'
    );
    assert(
        special_names.special2 == loot_item_name_storage.item_2.special2,
        'storage prefix1 should be set'
    );
    assert(
        special_names.special3 == loot_item_name_storage.item_2.special3,
        'storage prefix2 should be set'
    );
}

#[test]
#[available_gas(60000)]
fn test_set_beast_health() {
    let mut adventurer = ImplAdventurer::new(12, 0, 0, 0, 0, 0, 0, 0);

    // base case
    adventurer.set_beast_health(100);
    assert(adventurer.beast_health == 100, 'wrong beast health');

    // overflow case
    adventurer.set_beast_health(65535);
    assert(adventurer.beast_health == BeastSettings::MAXIMUM_HEALTH, 'beast health should be max');
}

#[test]
#[available_gas(90000)]
fn test_deduct_beast_health() {
    let mut adventurer = ImplAdventurer::new(12, 0, 0, 0, 0, 0, 0, 0);

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
#[available_gas(220000)]
fn test_increment_stat_valid() {
    let mut adventurer = ImplAdventurer::new(12, 0, 0, 0, 0, 0, 0, 0);

    adventurer.increment_stat(StatisticIndex::STRENGTH);
    assert(adventurer.stats.strength == 1, 'strength');
    assert(adventurer.stats.dexterity == 0, 'dexterity should be 0');
    assert(adventurer.stats.intelligence == 0, 'intelligence should be 0');
    assert(adventurer.stats.vitality == 0, 'vitality should be 0');
    assert(adventurer.stats.wisdom == 0, 'wisdom should be 0');
    assert(adventurer.stats.charisma == 0, 'charisma should be 0');

    adventurer.increment_stat(StatisticIndex::DEXTERITY);
    assert(adventurer.stats.dexterity == 1, 'dexterity');
    assert(adventurer.stats.strength == 1, 'strength should be 1');
    assert(adventurer.stats.intelligence == 0, 'intelligence should be 0');
    assert(adventurer.stats.vitality == 0, 'vitality should be 0');
    assert(adventurer.stats.wisdom == 0, 'wisdom should be 0');
    assert(adventurer.stats.charisma == 0, 'charisma should be 0');

    adventurer.increment_stat(StatisticIndex::INTELLIGENCE);
    assert(adventurer.stats.intelligence == 1, 'intelligence');
    assert(adventurer.stats.strength == 1, 'strength should be 1');
    assert(adventurer.stats.dexterity == 1, 'dexterity should be 1');
    assert(adventurer.stats.vitality == 0, 'vitality should be 0');
    assert(adventurer.stats.wisdom == 0, 'wisdom should be 0');
    assert(adventurer.stats.charisma == 0, 'charisma should be 0');

    adventurer.increment_stat(StatisticIndex::VITALITY);
    assert(adventurer.stats.vitality == 1, 'vitality');
    assert(adventurer.stats.strength == 1, 'strength should be 1');
    assert(adventurer.stats.dexterity == 1, 'dexterity should be 1');
    assert(adventurer.stats.intelligence == 1, 'intelligence should be 1');
    assert(adventurer.stats.wisdom == 0, 'wisdom should be 0');
    assert(adventurer.stats.charisma == 0, 'charisma should be 0');

    adventurer.increment_stat(StatisticIndex::WISDOM);
    assert(adventurer.stats.wisdom == 1, 'wisdom');
    assert(adventurer.stats.strength == 1, 'strength should be 1');
    assert(adventurer.stats.dexterity == 1, 'dexterity should be 1');
    assert(adventurer.stats.intelligence == 1, 'intelligence should be 1');
    assert(adventurer.stats.vitality == 1, 'vitality should be 1');
    assert(adventurer.stats.charisma == 0, 'charisma should be 0');

    adventurer.increment_stat(StatisticIndex::CHARISMA);
    assert(adventurer.stats.charisma == 1, 'charisma');
    assert(adventurer.stats.strength == 1, 'strength should be 1');
    assert(adventurer.stats.dexterity == 1, 'dexterity should be 1');
    assert(adventurer.stats.intelligence == 1, 'intelligence should be 1');
    assert(adventurer.stats.vitality == 1, 'vitality should be 1');
    assert(adventurer.stats.wisdom == 1, 'wisdom should be 1');
}

#[test]
#[should_panic(expected: ('Valid stat range is 0-5', ))]
#[available_gas(90000)]
fn test_increment_stat_invalid() {
    let mut adventurer = ImplAdventurer::new(12, 0, 0, 0, 0, 0, 0, 0);

    // invalid stat index should cause panic
    // which this test is annotated to expect
    adventurer.increment_stat(255);
}

#[test]
#[available_gas(600000)]
fn test_get_item_at_slot() {
    let mut adventurer = ImplAdventurer::new(12, 0, 0, 0, 0, 0, 0, 0);

    // stage items
    let weapon = ItemPrimitive { id: constants::ItemId::Katana, xp: 1, metadata: 1 };
    let chest = ItemPrimitive { id: constants::ItemId::DivineRobe, xp: 1, metadata: 2 };
    let head = ItemPrimitive { id: constants::ItemId::Crown, xp: 1, metadata: 3 };
    let waist = ItemPrimitive { id: constants::ItemId::DemonhideBelt, xp: 1, metadata: 4 };
    let foot = ItemPrimitive { id: constants::ItemId::LeatherBoots, xp: 1, metadata: 5 };
    let hand = ItemPrimitive { id: constants::ItemId::LeatherGloves, xp: 1, metadata: 6 };
    let neck = ItemPrimitive { id: constants::ItemId::Amulet, xp: 1, metadata: 7 };
    let ring = ItemPrimitive { id: constants::ItemId::GoldRing, xp: 1, metadata: 8 };

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
#[available_gas(600000)]
fn test_is_slot_free() {
    let mut adventurer = ImplAdventurer::new(12, 0, 0, 0, 0, 0, 0, 0);

    // stage items
    let weapon = ItemPrimitive { id: constants::ItemId::Katana, xp: 1, metadata: 1 };
    let chest = ItemPrimitive { id: constants::ItemId::DivineRobe, xp: 1, metadata: 2 };
    let head = ItemPrimitive { id: constants::ItemId::Crown, xp: 1, metadata: 3 };
    let waist = ItemPrimitive { id: constants::ItemId::DemonhideBelt, xp: 1, metadata: 4 };
    let foot = ItemPrimitive { id: constants::ItemId::LeatherBoots, xp: 1, metadata: 5 };
    let hand = ItemPrimitive { id: constants::ItemId::LeatherGloves, xp: 1, metadata: 6 };
    let neck = ItemPrimitive { id: constants::ItemId::Amulet, xp: 1, metadata: 7 };
    let ring = ItemPrimitive { id: constants::ItemId::GoldRing, xp: 1, metadata: 8 };

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
    let mut adventurer = ImplAdventurer::new(12, 0, 0, 0, 0, 0, 0, 0);
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
    let mut adventurer = ImplAdventurer::new(12, 0, 0, 0, 0, 0, 0, 0);

    // max charisma
    adventurer.stats.charisma = 255;
    let discount = adventurer.charisma_adjusted_potion_price();
    assert(discount == MINIMUM_POTION_PRICE, 'discount');

    // set charisma to 0
    adventurer.stats.charisma = 0;
    let discount = adventurer.charisma_adjusted_potion_price();
    assert(discount == MINIMUM_POTION_PRICE * adventurer.get_level().into(), 'no charisma potion');
}

#[test]
#[available_gas(200000)]
fn test_charisma_item_discount_overflow() {
    let mut adventurer = ImplAdventurer::new(12, 0, 0, 0, 0, 0, 0, 0);
    let item_price = 15;

    // no charisma case
    adventurer.stats.charisma = 0;
    assert(adventurer.charisma_adjusted_item_price(item_price) == 15, 'should be no discount');

    // small discount case
    adventurer.stats.charisma = 1;
    assert(
        adventurer.charisma_adjusted_item_price(item_price) == item_price - CHARISMA_ITEM_DISCOUNT,
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
#[available_gas(100000)]
fn test_increase_xp() {
    // initialize lvl 1 adventurer with no stat points available
    let mut adventurer = ImplAdventurer::new(12, 0, 0, 0, 0, 0, 0, 0);

    // increase adventurer xp by 3 which should level up the adventurer
    adventurer.increase_adventurer_xp(4);
    assert(adventurer.get_level() == 2, 'advtr should be lvl 2');

    // double level up without spending previous stat point
    adventurer.increase_adventurer_xp(12);
    assert(adventurer.get_level() == 4, 'advtr should be lvl 4');
}

#[test]
#[available_gas(600000)]
fn test_add_suffix_boost() {
    let mut adventurer = ImplAdventurer::new(12, 0, 0, 0, 0, 0, 0, 0);

    adventurer.add_suffix_boost(ItemSuffix::of_Power);
    assert(adventurer.stats.strength == 3, 'strength should be 3');
    assert(adventurer.stats.dexterity == 0, 'dexterity should be 0');
    assert(adventurer.stats.vitality == 0, 'vitality should be 0');
    assert(adventurer.stats.intelligence == 0, 'intelligence should be 0');
    assert(adventurer.stats.wisdom == 0, 'wisdom should be 0');
    assert(adventurer.stats.charisma == 0, 'charisma should be 0');

    adventurer.add_suffix_boost(ItemSuffix::of_Giant);
    assert(adventurer.stats.strength == 3, 'strength should be 3');
    assert(adventurer.stats.vitality == 3, 'vitality should be 3');
    assert(adventurer.stats.dexterity == 0, 'dexterity should be 0');
    assert(adventurer.stats.intelligence == 0, 'intelligence should be 0');
    assert(adventurer.stats.wisdom == 0, 'wisdom should be 0');
    assert(adventurer.stats.charisma == 0, 'charisma should be 0');

    adventurer.add_suffix_boost(ItemSuffix::of_Perfection);
    assert(adventurer.stats.strength == 4, 'strength should be 4');
    assert(adventurer.stats.vitality == 4, 'vitality should be 4');
    assert(adventurer.stats.dexterity == 1, 'dexterity should be 1');
    assert(adventurer.stats.intelligence == 0, 'intelligence should be 0');
    assert(adventurer.stats.wisdom == 0, 'wisdom should be 0');
    assert(adventurer.stats.charisma == 0, 'charisma should be 0');

    adventurer.add_suffix_boost(ItemSuffix::of_Rage);
    assert(adventurer.stats.strength == 5, 'strength should be 5');
    assert(adventurer.stats.vitality == 4, 'vitality should be 4');
    assert(adventurer.stats.dexterity == 1, 'dexterity should be 1');
    assert(adventurer.stats.intelligence == 0, 'intelligence should be 0');
    assert(adventurer.stats.wisdom == 1, 'wisdom should be 1');
    assert(adventurer.stats.charisma == 1, 'charisma should be 1');

    adventurer.add_suffix_boost(ItemSuffix::of_Fury);
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
    let mut adventurer = ImplAdventurer::new(12, 0, 0, 0, 0, 0, 0, 0);

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
#[available_gas(900000)]
fn test_add_stat_boosts() {
    let mut adventurer = Adventurer {
        last_action: 511, health: 100, xp: 1, stats: Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0, 
            }, gold: 40, weapon: ItemPrimitive {
            id: 1, xp: 225, metadata: 1, 
            }, chest: ItemPrimitive {
            id: 2, xp: 65535, metadata: 2, 
            }, head: ItemPrimitive {
            id: 3, xp: 225, metadata: 3, 
            }, waist: ItemPrimitive {
            id: 4, xp: 225, metadata: 4, 
            }, foot: ItemPrimitive {
            id: 5, xp: 1000, metadata: 5, 
            }, hand: ItemPrimitive {
            id: 6, xp: 224, metadata: 6, 
            }, neck: ItemPrimitive {
            id: 7, xp: 1, metadata: 7, 
            }, ring: ItemPrimitive {
            id: 8, xp: 1, metadata: 8, 
        }, beast_health: 20, stat_points_available: 0,
    };

    let item1_names = ItemSpecials { special2: 0, special3: 0, special1: ItemSuffix::of_Power,  };
    let item2_names = ItemSpecials { special2: 0, special3: 0, special1: ItemSuffix::of_Giant,  };
    let item3_names = ItemSpecials {
        special2: 0, special3: 0, special1: ItemSuffix::of_Perfection, 
    };
    let item4_names = ItemSpecials { special2: 0, special3: 0, special1: ItemSuffix::of_Rage,  };
    let item5_names = ItemSpecials { special2: 0, special3: 0, special1: ItemSuffix::of_Fury,  };
    let item6_names = ItemSpecials { special2: 0, special3: 0, special1: ItemSuffix::of_Skill,  };
    let item7_names = ItemSpecials { special2: 0, special3: 0, special1: ItemSuffix::of_Vitriol,  };
    let item8_names = ItemSpecials { special2: 0, special3: 0, special1: ItemSuffix::of_the_Fox,  };
    let item9_names = ItemSpecials { special2: 0, special3: 0, special1: 0,  };
    let item10_names = ItemSpecials { special2: 0, special3: 0, special1: 0,  };

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
    };

    let boost_stats = ImplAdventurer::add_stat_boosts(ref adventurer, name_storage1, name_storage2);
    assert(adventurer.stats.strength == 5, 'strength should be 5');
    assert(adventurer.stats.vitality == 5, 'vitality should be 5');
    assert(adventurer.stats.dexterity == 1, 'dexterity should be 1');
    assert(adventurer.stats.intelligence == 1, 'intelligence should be 1');
    assert(adventurer.stats.wisdom == 1, 'wisdom should be 1');
    assert(adventurer.stats.charisma == 2, 'charisma should be 2');
}


#[test]
#[available_gas(1100000)]
fn test_get_market_entropy() {
    // test zero case
    let mut adventurer = Adventurer {
        last_action: 511, health: 12, xp: 0, stats: Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0, 
            }, gold: 40, weapon: ItemPrimitive {
            id: 1, xp: 225, metadata: 1, 
            }, chest: ItemPrimitive {
            id: 2, xp: 65535, metadata: 2, 
            }, head: ItemPrimitive {
            id: 3, xp: 225, metadata: 3, 
            }, waist: ItemPrimitive {
            id: 4, xp: 225, metadata: 4, 
            }, foot: ItemPrimitive {
            id: 5, xp: 1000, metadata: 5, 
            }, hand: ItemPrimitive {
            id: 6, xp: 224, metadata: 6, 
            }, neck: ItemPrimitive {
            id: 7, xp: 1, metadata: 7, 
            }, ring: ItemPrimitive {
            id: 8, xp: 1, metadata: 8, 
        }, beast_health: 20, stat_points_available: 1,
    };

    // assert get_market_seed doesn't fail with zero case
    // result isn't important, just that it doesn't fail
    let market_entropy = adventurer.get_market_seeds(1, 1);

    // test extreme/overflow case
    adventurer.xp = 8191; // max value for 13 bits
    adventurer.stat_points_available = 7; // max value for 3 bits

    // // max value for 256 bits
    let max_adventurer_id: u256 = 340282366920938463463374607431768211455;

    // max value for 128 bits
    let max_adventurer_entropy: u128 = 340282366920938463463374607431768211455;

    // result isn't important, just that it doesn't fail via overflow
    let market_entropy = adventurer.get_market_seeds(max_adventurer_id, max_adventurer_entropy);
}

#[test]
#[available_gas(390000)]
fn test_discover_treasure() {
    let mut adventurer = ImplAdventurer::new(12, 0, 0, 0, 0, 0, 0, 0);

    // give vitality so we can discover health
    adventurer.stats.vitality = 1;
    adventurer.xp = 25;

    // disover gold
    let (discovery_type, amount) = adventurer.discover_treasure(5);
    assert(discovery_type == TreasureDiscovery::Gold(()), 'should have found gold');
    assert(amount > 0, 'gold should be non-zero');

    // discover health
    let (discovery_type, amount) = adventurer.discover_treasure(6);
    assert(discovery_type == TreasureDiscovery::Health(()), 'should have found health');
    assert(amount > 0, 'health should be non-zero');

    // discover xp
    let (discovery_type, amount) = adventurer.discover_treasure(7);
    assert(discovery_type == TreasureDiscovery::XP(()), 'should have found xp');
    assert(amount > 0, 'xp should be non-zero');
}

#[test]
#[available_gas(200000)]
fn test_get_luck() {
    let mut adventurer = ImplAdventurer::new(12, 0, 0, 0, 0, 0, 0, 0);
    assert(adventurer.get_luck() == 0, 'start with no luck');

    // equip a greatness 1 necklace
    let mut neck = ItemPrimitive { id: constants::ItemId::Amulet, xp: 1, metadata: 7 };
    adventurer.equip_necklace(neck);
    assert(adventurer.get_luck() == 1, 'should be 1 luck');

    // equip a greatness 1 ring
    let mut ring = ItemPrimitive { id: constants::ItemId::GoldRing, xp: 1, metadata: 8 };
    adventurer.equip_ring(ring);
    assert(adventurer.get_luck() == 2, 'should be 2 luck');

    // overflow case
    adventurer.ring.xp = 65535;
    adventurer.neck.xp = 65535;
    assert(adventurer.get_luck() == ITEM_MAX_GREATNESS * 2, 'should be 40 luck');
}

#[test]
#[available_gas(200000)]
fn test_in_battle() {
    let mut adventurer = ImplAdventurer::new(12, 0, 0, 0, 0, 0, 0, 0);
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
    let mut adventurer = ImplAdventurer::new(12, 0, 0, 0, 0, 0, 0, 0);

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
    let weapon = ItemPrimitive { id: constants::ItemId::Katana, xp: 1, metadata: 1 };
    let chest = ItemPrimitive { id: constants::ItemId::DivineRobe, xp: 1, metadata: 2 };
    let head = ItemPrimitive { id: constants::ItemId::Crown, xp: 1, metadata: 3 };
    let waist = ItemPrimitive { id: constants::ItemId::DemonhideBelt, xp: 1, metadata: 4 };
    let foot = ItemPrimitive { id: constants::ItemId::LeatherBoots, xp: 1, metadata: 5 };
    let hand = ItemPrimitive { id: constants::ItemId::LeatherGloves, xp: 1, metadata: 6 };
    let neck = ItemPrimitive { id: constants::ItemId::Amulet, xp: 1, metadata: 7 };
    let ring = ItemPrimitive { id: constants::ItemId::GoldRing, xp: 1, metadata: 8 };

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
#[available_gas(2000000)]
fn test_grant_xp_and_check_for_greatness_increase() {
    let mut adventurer = ImplAdventurer::new(12, 0, 0, 0, 0, 0, 0, 0);

    // stage items
    let mut weapon = ItemPrimitive { id: constants::ItemId::Katana, xp: 1, metadata: 1 };
    let mut chest_armor = ItemPrimitive { id: constants::ItemId::DivineRobe, xp: 1, metadata: 2 };

    // state name storage
    let mut special_name_storage = ItemSpecialsStorage {
        item_1: ItemSpecials {
            special2: 0, special3: 0, special1: 0
            }, item_2: ItemSpecials {
            special2: 0, special3: 0, special1: 0
            }, item_3: ItemSpecials {
            special2: 0, special3: 0, special1: 0
            }, item_4: ItemSpecials {
            special2: 0, special3: 0, special1: 0
            }, item_5: ItemSpecials {
            special2: 0, special3: 0, special1: 0
            }, item_6: ItemSpecials {
            special2: 0, special3: 0, special1: 0
            }, item_7: ItemSpecials {
            special2: 0, special3: 0, special1: 0
            }, item_8: ItemSpecials {
            special2: 0, special3: 0, special1: 0
            }, item_9: ItemSpecials {
            special2: 0, special3: 0, special1: 0
            }, item_10: ItemSpecials {
            special2: 0, special3: 0, special1: 0
        },
    };

    // level weapon from greatness 1 to 2
    let (previous_level, new_level, suffix_assigned, prefixes_assigned, special_names) = weapon
        .grant_xp_and_check_for_greatness_increase(4, ref special_name_storage, 0);
    assert(previous_level == 1, 'previous level should be 1');
    assert(new_level == 2, 'new level should be 2');
    assert(suffix_assigned == false, 'no suffix_assigned');
    assert(prefixes_assigned == false, 'no prefix assigned');
    assert(special_names.special2 == 0, 'no prefix assigned');
    assert(special_names.special3 == 0, 'no suffix assigned');
    assert(special_names.special1 == 0, 'no item suffix assigned');

    // level weapon from greatness 2 to greatness 15
    let (previous_level, new_level, suffix_assigned, prefixes_assigned, special_names) = weapon
        .grant_xp_and_check_for_greatness_increase(220, ref special_name_storage, 0);
    assert(previous_level == 2, 'previous level should be 2');
    assert(new_level == 15, 'new level should be 15');
    assert(suffix_assigned == true, 'suffix should be assigned');
    assert(prefixes_assigned == false, 'prefix should not be assigned');
    assert(special_names.special2 == 0, 'no prefix');
    assert(special_names.special3 == 0, 'no suffix');
    assert(special_names.special1 > 0, 'suffix should be assigned');
    assert(
        special_name_storage.item_1.special1 == special_names.special1,
        'suffix should be in storage'
    );
    let assigned_suffix = special_names.special1;

    // level weapon from greatness 15 to 16 by giving it 31 xp
    let (previous_level, new_level, suffix_assigned, prefixes_assigned, special_names) = weapon
        .grant_xp_and_check_for_greatness_increase(31, ref special_name_storage, 0);
    assert(previous_level == 15, 'previous level should be 15');
    assert(new_level == 16, 'new level should be 16');
    assert(suffix_assigned == false, 'suffix should not be assigned');
    assert(prefixes_assigned == false, 'prefix should not be assigned');
    assert(special_names.special2 == 0, 'no prefix');
    assert(special_names.special3 == 0, 'no suffix');
    assert(special_name_storage.item_1.special1 == assigned_suffix, 'suffix should not be changed');

    // level weapon to greatness 19 by giving it 105xp
    let (previous_level, new_level, suffix_assigned, prefixes_assigned, special_names) = weapon
        .grant_xp_and_check_for_greatness_increase(105, ref special_name_storage, 0);
    assert(previous_level == 16, 'previous level should be 16');
    assert(new_level == 19, 'new level should be 19');
    assert(suffix_assigned == false, 'suffix already already assigned');
    assert(prefixes_assigned == true, 'prefixes should be assigned');
    assert(special_names.special2 > 0, 'prefix1 should be assigned');
    assert(special_names.special3 > 0, 'prefix2 should be assigned');
    assert(special_names.special1 == assigned_suffix, 'suffix should be assigned');
    assert(
        special_name_storage.item_1.special2 == special_names.special2,
        'prefix1 should be in storage'
    );
    assert(
        special_name_storage.item_1.special3 == special_names.special3,
        'prefix2 should be in storage'
    );
    assert(special_name_storage.item_1.special1 == assigned_suffix, 'suffix should not be changed');
    let assigned_prefix1 = special_names.special2;
    let assigned_prefix2 = special_names.special3;

    // last test case we need to cover is leveling from below greatness 15 to above greatness 19
    let (previous_level, new_level, suffix_assigned, prefixes_assigned, special_names) = chest_armor
        .grant_xp_and_check_for_greatness_increase(400, ref special_name_storage, 0);
    assert(previous_level == 1, 'previous level should be 1');
    assert(new_level == 20, 'new level should be 20');
    assert(suffix_assigned == true, 'suffix should be assigned');
    assert(prefixes_assigned == true, 'prefixes should be assigned');
    assert(special_names.special2 > 0, 'prefix1 should be assigned');
    assert(special_names.special3 > 0, 'prefix2 should be assigned');
    assert(special_names.special1 > 0, 'suffix should be assigned');
    assert(
        special_name_storage.item_2.special2 == special_names.special2,
        'prefix1 should be in storage'
    );
    assert(
        special_name_storage.item_2.special3 == special_names.special3,
        'prefix2 should be in storage'
    );
    assert(
        special_name_storage.item_2.special1 == special_names.special1,
        'suffix should be in storage'
    );
}

#[test]
#[available_gas(1200000)]
fn test_is_equipped() {
    let wand = ItemPrimitive { id: constants::ItemId::Wand, xp: 1, metadata: 1 };
    let demon_crown = ItemPrimitive { id: constants::ItemId::DemonCrown, xp: 1, metadata: 2 };
    let mut adventurer = ImplAdventurer::new(12, 0, 0, 0, 0, 0, 0, 0);

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
    let katana = ItemPrimitive { id: constants::ItemId::Katana, xp: 1, metadata: 1 };
    let divine_robe = ItemPrimitive { id: constants::ItemId::DivineRobe, xp: 1, metadata: 2 };
    let crown = ItemPrimitive { id: constants::ItemId::Crown, xp: 1, metadata: 3 };
    let demonhide_belt = ItemPrimitive { id: constants::ItemId::DemonhideBelt, xp: 1, metadata: 4 };
    let leather_boots = ItemPrimitive { id: constants::ItemId::LeatherBoots, xp: 1, metadata: 5 };
    let leather_gloves = ItemPrimitive { id: constants::ItemId::LeatherGloves, xp: 1, metadata: 6 };
    let amulet = ItemPrimitive { id: constants::ItemId::Amulet, xp: 1, metadata: 7 };
    let gold_ring = ItemPrimitive { id: constants::ItemId::GoldRing, xp: 1, metadata: 8 };

    // Equip a katana and verify is_equipped returns true for katana and false everything else
    adventurer.equip_item(katana);
    assert(adventurer.is_equipped(katana.id) == true, 'weapon should be equipped');
    assert(adventurer.is_equipped(wand.id) == false, 'wand should not be equipped');
    assert(adventurer.is_equipped(crown.id) == false, 'crown should not be equipped');
    assert(adventurer.is_equipped(divine_robe.id) == false, 'divine robe is not equipped');
    assert(adventurer.is_equipped(demonhide_belt.id) == false, 'demonhide belt is not equipped');
    assert(adventurer.is_equipped(leather_boots.id) == false, 'leather boots is not equipped');
    assert(adventurer.is_equipped(leather_gloves.id) == false, 'leather gloves is not equipped');
    assert(adventurer.is_equipped(amulet.id) == false, 'amulet is not equipped');
    assert(adventurer.is_equipped(gold_ring.id) == false, 'gold ring is not equipped');

    // equip a divine robe and verify is_equipped returns true for katana and divine robe and false everything else
    adventurer.equip_item(divine_robe);
    assert(adventurer.is_equipped(divine_robe.id) == true, 'divine robe should be equipped');
    assert(adventurer.is_equipped(katana.id) == true, 'katana still equipped');
    assert(adventurer.is_equipped(crown.id) == false, 'crown should not be equipped');
    assert(adventurer.is_equipped(demonhide_belt.id) == false, 'demonhide belt is not equipped');
    assert(adventurer.is_equipped(leather_boots.id) == false, 'leather boots is not equipped');
    assert(adventurer.is_equipped(leather_gloves.id) == false, 'leather gloves is not equipped');
    assert(adventurer.is_equipped(amulet.id) == false, 'amulet is not equipped');
    assert(adventurer.is_equipped(gold_ring.id) == false, 'gold ring is not equipped');

    // equip a crown and verify is_equipped returns true for katana, divine robe, and crown and false everything else
    adventurer.equip_item(crown);
    assert(adventurer.is_equipped(crown.id) == true, 'crown should be equipped');
    assert(adventurer.is_equipped(divine_robe.id) == true, 'divine robe should be equipped');
    assert(adventurer.is_equipped(katana.id) == true, 'katana still equipped');
    assert(adventurer.is_equipped(demonhide_belt.id) == false, 'demonhide belt is not equipped');
    assert(adventurer.is_equipped(leather_boots.id) == false, 'leather boots is not equipped');
    assert(adventurer.is_equipped(leather_gloves.id) == false, 'leather gloves is not equipped');
    assert(adventurer.is_equipped(amulet.id) == false, 'amulet is not equipped');
    assert(adventurer.is_equipped(gold_ring.id) == false, 'gold ring is not equipped');

    // equip a demonhide belt and verify is_equipped returns true for katana, divine robe, crown, and demonhide belt and false everything else
    adventurer.equip_item(demonhide_belt);
    assert(adventurer.is_equipped(demonhide_belt.id) == true, 'demonhide belt is equipped');
    assert(adventurer.is_equipped(crown.id) == true, 'crown should be equipped');
    assert(adventurer.is_equipped(divine_robe.id) == true, 'divine robe should be equipped');
    assert(adventurer.is_equipped(katana.id) == true, 'katana still equipped');
    assert(adventurer.is_equipped(leather_boots.id) == false, 'leather boots is not equipped');
    assert(adventurer.is_equipped(leather_gloves.id) == false, 'leather gloves is not equipped');
    assert(adventurer.is_equipped(amulet.id) == false, 'amulet is not equipped');
    assert(adventurer.is_equipped(gold_ring.id) == false, 'gold ring is not equipped');

    // equip leather boots and verify is_equipped returns true for katana, divine robe, crown, demonhide belt, and leather boots and false everything else
    adventurer.equip_item(leather_boots);
    assert(adventurer.is_equipped(leather_boots.id) == true, 'leather boots is equipped');
    assert(adventurer.is_equipped(demonhide_belt.id) == true, 'demonhide belt is equipped');
    assert(adventurer.is_equipped(crown.id) == true, 'crown should be equipped');
    assert(adventurer.is_equipped(divine_robe.id) == true, 'divine robe should be equipped');
    assert(adventurer.is_equipped(katana.id) == true, 'katana still equipped');
    assert(adventurer.is_equipped(leather_gloves.id) == false, 'leather gloves is not equipped');
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
#[should_panic(expected: ('item is not equipped', ))]
#[available_gas(50000)]
fn test_drop_item_not_equipped() {
    // instantiate adventurer
    let mut adventurer = ImplAdventurer::new(12, 0, 0, 0, 0, 0, 0, 0);
    // try to drop an item that isn't equipped
    // this should panic with 'item is not equipped'
    // the test is annotated to expect this panic
    adventurer.drop_item(constants::ItemId::Crown);
}

#[test]
#[available_gas(700000)]
fn test_drop_item() {
    let mut adventurer = ImplAdventurer::new(12, 0, 0, 0, 0, 0, 0, 0);

    // assert starting conditions
    assert(adventurer.weapon.id == constants::ItemId::Wand, 'weapon should be wand');
    assert(adventurer.chest.id == 0, 'chest should be 0');
    assert(adventurer.head.id == 0, 'head should be 0');
    assert(adventurer.waist.id == 0, 'waist should be 0');
    assert(adventurer.foot.id == 0, 'foot should be 0');
    assert(adventurer.hand.id == 0, 'hand should be 0');
    assert(adventurer.neck.id == 0, 'neck should be 0');
    assert(adventurer.ring.id == 0, 'ring should be 0');

    // drop equipped wand
    adventurer.drop_item(constants::ItemId::Wand);
    assert(adventurer.weapon.id == 0, 'weapon should be 0');
    assert(adventurer.weapon.xp == 0, 'weapon xp should be 0');

    // instantiate additional items
    let weapon = ItemPrimitive { id: constants::ItemId::Katana, xp: 1, metadata: 1 };
    let chest = ItemPrimitive { id: constants::ItemId::DivineRobe, xp: 1, metadata: 2 };
    let head = ItemPrimitive { id: constants::ItemId::Crown, xp: 1, metadata: 3 };
    let waist = ItemPrimitive { id: constants::ItemId::DemonhideBelt, xp: 1, metadata: 4 };
    let foot = ItemPrimitive { id: constants::ItemId::LeatherBoots, xp: 1, metadata: 5 };
    let hand = ItemPrimitive { id: constants::ItemId::LeatherGloves, xp: 1, metadata: 6 };
    let neck = ItemPrimitive { id: constants::ItemId::Amulet, xp: 1, metadata: 7 };
    let ring = ItemPrimitive { id: constants::ItemId::GoldRing, xp: 1, metadata: 8 };

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
