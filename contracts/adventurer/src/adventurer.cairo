use core::result::ResultTrait;
use integer::{u16_overflowing_add, u16_overflowing_sub};
use traits::{TryInto, Into};
use option::OptionTrait;

use pack::pack::{Packing, rshift_split};
use pack::constants::{MASK_16, pow, MASK_8, MASK_BOOL, mask};

use lootitems::loot::{Loot, ILoot, ImplLoot, DynamicItem};
use lootitems::statistics::{
    constants, item_tier, item_type, constants::Settings, constants::ItemSuffix
};

use super::exploration::ExploreUtils;
use super::constants::adventurer_constants::{
    STARTING_GOLD, StatisticIndex, POTION_PRICE, STARTING_HEALTH, CHARISMA_DISCOUNT,
    MINIMUM_ITEM_PRICE, MINIMUM_POTION_PRICE, ITEM_XP_MULTIPLIER, VITALITY_HEALTH_INCREASE,
    MAX_GOLD, MAX_STAT_VALUE, MAX_STAT_UPGRADES, MAX_XP, MAX_ADVENTURER_BLOCKS
};
use super::constants::discovery_constants::DiscoveryEnums::{ExploreResult, TreasureDiscovery};
use super::item_meta::{LootItemSpecialNames, LootItemSpecialNamesStorage, ImplLootItemSpecialNames};

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
    last_action: u16, // 9 bits
    health: u16, // 9 bits
    xp: u16, // 13 bits
    stats: Stats, // 30 bits
    gold: u16, // 9 bits
    weapon: LootStatistics, // 21 bits
    chest: LootStatistics, // 21 bits
    head: LootStatistics, // 21 bits
    waist: LootStatistics, // 21 bits
    foot: LootStatistics, // 21 bits
    hand: LootStatistics, // 21 bits
    neck: LootStatistics, // 21 bits
    ring: LootStatistics, // 21 bits
    beast_health: u16, // 9 bits
    stat_points_available: u8, // 3 bits
}

impl StatsPacking of Packing<Stats> {
    fn pack(self: Stats) -> felt252 {
        (self.strength.into()
            + self.dexterity.into() * pow::TWO_POW_5
            + self.vitality.into() * pow::TWO_POW_10
            + self.intelligence.into() * pow::TWO_POW_15
            + self.wisdom.into() * pow::TWO_POW_20
            + self.charisma.into() * pow::TWO_POW_25)
            .try_into()
            .expect('pack Stats')
    }

    fn unpack(packed: felt252) -> Stats {
        let packed = packed.into();
        let (packed, strength) = rshift_split(packed, pow::TWO_POW_5);
        let (packed, dexterity) = rshift_split(packed, pow::TWO_POW_5);
        let (packed, vitality) = rshift_split(packed, pow::TWO_POW_5);
        let (packed, intelligence) = rshift_split(packed, pow::TWO_POW_5);
        let (packed, wisdom) = rshift_split(packed, pow::TWO_POW_5);
        let (_, charisma) = rshift_split(packed, pow::TWO_POW_5);

        Stats {
            strength: strength.try_into().expect('unpack Stats strength'),
            dexterity: dexterity.try_into().expect('unpack Stats dexterity'),
            vitality: vitality.try_into().expect('unpack Stats vitality'),
            intelligence: intelligence.try_into().expect('unpack Stats intelligence'),
            wisdom: wisdom.try_into().expect('unpack Stats wisdom'),
            charisma: charisma.try_into().expect('unpack Stats charisma')
        }
    }
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
}

#[generate_trait]
impl ImplAdventurer of IAdventurer {
    fn get_market_entropy(self: Adventurer, adventurer_id: u256) -> u64 {
        // TODO: check potential overflow
        ((self.xp.into() + 1) * pow::TWO_POW_9 * adventurer_id)
            .try_into()
            .expect('get_market_entropy')
    }
    fn charisma_potion_discount(self: Adventurer) -> u16 {
        CHARISMA_DISCOUNT * self.stats.charisma.into()
    }

    fn charisma_item_discount(self: Adventurer) -> u16 {
        CHARISMA_DISCOUNT * self.stats.charisma.into()
    }

    fn get_item_cost(self: Adventurer, item_cost: u16) -> u16 {
        if (u16_overflowing_sub(item_cost, self.charisma_item_discount()).is_ok()) {
            let cost = item_cost - self.charisma_item_discount();

            if (cost < MINIMUM_ITEM_PRICE) {
                MINIMUM_ITEM_PRICE
            } else {
                cost
            }
        } else {
            MINIMUM_ITEM_PRICE
        }
    }

    fn get_potion_price(self: Adventurer) -> u16 {
        // check if we overflow
        if (u16_overflowing_sub(
            POTION_PRICE * self.get_level().into(), self.charisma_potion_discount()
        )
            .is_ok()) {
            let price = POTION_PRICE * self.get_level().into() - self.charisma_potion_discount();

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
    fn add_statistic(ref self: Adventurer, value: u8) {
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
    fn deduct_gold(ref self: Adventurer, value: u16) {
        self.gold -= value;
        if (self.gold < 0) {
            self.gold = 0;
        }
    }
    fn check_gold(self: Adventurer, value: u16) -> bool {
        self.gold >= value
    }

    // get_item_at_slot returns the item at a given item slot
    // @param self: Adventurer to check
    // @param slot: Slot to check
    // @return DynamicItem: Item at slot
    fn get_item_at_slot(self: Adventurer, slot: Slot) -> DynamicItem {
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
    fn is_slot_free(self: Adventurer, item: DynamicItem) -> bool {
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
        let battle_fixed_entropy: u128 = self.get_battle_fixed_entropy(battle_fixed_seed);

        // generate special names for beast using Loot name schema.
        // We use Loot names because the combat system will deal bonus damage for matching names (these are the items super powers)
        // We do this here instead of in beast to prevent beast from depending on Loot
        let prefix1 = battle_fixed_entropy % constants::NamePrefixLength.into();
        let prefix2 = battle_fixed_entropy % constants::NameSuffixLength.into();

        // use the randomly generated prefixes but set suffic to 0
        let special_names = SpecialPowers {
            prefix1: prefix1.try_into().unwrap(), prefix2: prefix2.try_into().unwrap(), suffix: 0
        };

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

    // luck
    fn get_luck(self: Adventurer) -> u8 {
        // get greatness of aventurers equipped necklace
        let necklace_greatness = self.neck.get_greatness();
        // get greatness of aventurers equipped ring
        let ring_greatness = self.neck.get_greatness();

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

    fn add_health(ref self: Adventurer, value: u16) {
        // if the health to add is greater than or equal to the max health
        if (self.health + value) >= self.get_max_health() {
            // set health to max health
            self.health = self.get_max_health();
        } else {
            // otherwise add health
            self.health += value;
        }
    }

    fn get_max_health(ref self: Adventurer) -> u16 {
        // max health is starting health plus impact of vitality stat
        STARTING_HEALTH + (self.stats.vitality.into() * VITALITY_HEALTH_INCREASE)
    }

    fn increase_gold(ref self: Adventurer, value: u16) -> Adventurer {
        // if the gold to add is greater than or equal to the max gold
        if (self.gold + value) > MAX_GOLD {
            // set gold to max gold
            self.gold = MAX_GOLD;
            return self;
        }
        self.gold = self.gold + value;

        self
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
    fn increase_adventurer_xp(ref self: Adventurer, value: u16) -> (u8, u8) {
        // get the previous level
        let previous_level = self.get_level();

        // overflow check using MAX_XP
        if self.xp + value >= MAX_XP {
            self.xp = MAX_XP;
        } else {
            self.xp += value;
        }

        // get the new level
        let new_level = self.get_level();

        // return the previous and new levels
        (previous_level, new_level)
    }

    // @notice Grants stat upgrades to the Adventurer.
    // @dev The function will add the specified value to the stat_points_available up to the maximum limit of MAX_STAT_UPGRADES.
    // @param value The amount of stat points to be added to the Adventurer.
    fn grant_stat_upgrades(ref self: Adventurer, value: u8) {
        if (self.stat_points_available + value > MAX_STAT_UPGRADES) {
            self.stat_points_available = MAX_STAT_UPGRADES;
        } else {
            self.stat_points_available += value;
        }
    }

    // @notice Increase the Adventurer's strength stat.
    // @dev The function will add the specified amount to the strength stat up to the maximum limit of MAX_STAT_VALUE.
    // @param amount The amount to be added to the strength stat.
    fn add_strength(ref self: Adventurer, amount: u8) {
        if (self.stats.strength + amount > MAX_STAT_VALUE) {
            self.stats.strength = MAX_STAT_VALUE;
        } else {
            self.stats.strength += amount;
        }
    }

    // @notice Increase the Adventurer's dexterity stat.
    // @dev The function will add the specified amount to the dexterity stat up to the maximum limit of MAX_STAT_VALUE.
    // @param amount The amount to be added to the dexterity stat.
    fn add_dexterity(ref self: Adventurer, amount: u8) {
        if (self.stats.dexterity + amount > MAX_STAT_VALUE) {
            self.stats.dexterity = MAX_STAT_VALUE;
        } else {
            self.stats.dexterity += amount;
        }
    }

    // @notice Increase the Adventurer's vitality stat.
    // @dev The function will add the specified amount to the vitality stat up to the maximum limit of MAX_STAT_VALUE.
    // @param amount The amount to be added to the vitality stat.
    fn add_vitality(ref self: Adventurer, amount: u8) {
        if (self.stats.vitality + amount > MAX_STAT_VALUE) {
            self.stats.vitality = MAX_STAT_VALUE;
        } else {
            self.stats.vitality += amount;
        }
    }

    // @notice Increase the Adventurer's intelligence stat.
    // @dev The function will add the specified amount to the intelligence stat up to the maximum limit of MAX_STAT_VALUE.
    // @param amount The amount to be added to the intelligence stat.
    fn add_intelligence(ref self: Adventurer, amount: u8) {
        if (self.stats.intelligence + amount > MAX_STAT_VALUE) {
            self.stats.intelligence = MAX_STAT_VALUE;
        } else {
            self.stats.intelligence += amount;
        }
    }

    // @notice Increase the Adventurer's wisdom stat.
    // @dev The function will add the specified amount to the wisdom stat up to the maximum limit of MAX_STAT_VALUE.
    // @param amount The amount to be added to the wisdom stat.
    fn add_wisdom(ref self: Adventurer, amount: u8) {
        if (self.stats.wisdom + amount > MAX_STAT_VALUE) {
            self.stats.wisdom = MAX_STAT_VALUE;
        } else {
            self.stats.wisdom += amount;
        }
    }

    // @notice Increase the Adventurer's charisma stat.
    // @dev The function will add the specified amount to the charisma stat up to the maximum limit of MAX_STAT_VALUE.
    // @param amount The amount to be added to the charisma stat.
    fn add_charisma(ref self: Adventurer, amount: u8) {
        if (self.stats.charisma + amount > MAX_STAT_VALUE) {
            self.stats.charisma = MAX_STAT_VALUE;
        } else {
            self.stats.charisma += amount;
        }
    }

    // @notice Decrease the Adventurer's strength stat.
    // @dev The function will subtract the specified amount from the strength stat without allowing it to fall below 0.
    // @param amount The amount to be subtracted from the strength stat.
    fn deduct_strength(ref self: Adventurer, amount: u8) {
        // If subtraction doesn't cause underflow, subtract amount; otherwise, set to 0
        if (u16_overflowing_sub(self.stats.strength.into(), amount.into()).is_ok()) {
            self.stats.strength -= amount;
        } else {
            self.stats.strength = 0;
        }
    }

    // @notice Decrease the Adventurer's dexterity stat.
    // @dev The function will subtract the specified amount from the dexterity stat without allowing it to fall below 0.
    // @param amount The amount to be deducted from the dexterity stat.
    fn deduct_dexterity(ref self: Adventurer, amount: u8) {
        // If subtraction doesn't cause underflow, subtract amount; otherwise, set to 0
        if (u16_overflowing_sub(self.stats.dexterity.into(), amount.into()).is_ok()) {
            self.stats.dexterity -= amount;
        } else {
            self.stats.dexterity = 0;
        }
    }

    // @notice Decrease the Adventurer's vitality stat.
    // @dev The function will subtract the specified amount from the vitality stat without allowing it to fall below 0.
    // @param amount The amount to be deducted from the vitality stat.
    fn deduct_vitality(ref self: Adventurer, amount: u8) {
        // If subtraction doesn't cause underflow, subtract amount; otherwise, set to 0
        if (u16_overflowing_sub(self.stats.vitality.into(), amount.into()).is_ok()) {
            self.stats.vitality -= amount;
        } else {
            self.stats.vitality = 0;
        }
    }

    // @notice Decrease the Adventurer's intelligence stat.
    // @dev The function will subtract the specified amount from the intelligence stat without allowing it to fall below 0.
    // @param amount The amount to be deducted from the intelligence stat.
    fn deduct_intelligence(ref self: Adventurer, amount: u8) {
        // If subtraction doesn't cause underflow, subtract amount; otherwise, set to 0
        if (u16_overflowing_sub(self.stats.intelligence.into(), amount.into()).is_ok()) {
            self.stats.intelligence -= amount;
        } else {
            self.stats.intelligence = 0;
        }
    }

    // @notice Decrease the Adventurer's wisdom stat.
    // @dev The function will subtract the specified amount from the wisdom stat without allowing it to fall below 0.
    // @param amount The amount to be deducted from the wisdom stat.
    fn deduct_wisdom(ref self: Adventurer, amount: u8) {
        // If subtraction doesn't cause underflow, subtract amount; otherwise, set to 0
        if (u16_overflowing_sub(self.stats.wisdom.into(), amount.into()).is_ok()) {
            self.stats.wisdom -= amount;
        } else {
            self.stats.wisdom = 0;
        }
    }

    // @notice Decrease the Adventurer's charisma stat.
    // @dev The function will subtract the specified amount from the charisma stat without allowing it to fall below 0.
    // @param amount The amount to be deducted from the charisma stat.
    fn deduct_charisma(ref self: Adventurer, amount: u8) {
        // If subtraction doesn't cause underflow, subtract amount; otherwise, set to 0
        if (u16_overflowing_sub(self.stats.charisma.into(), amount.into()).is_ok()) {
            self.stats.charisma -= amount;
        } else {
            self.stats.charisma = 0;
        }
    }

    // @notice Adds an item to the adventurer's equipment.
    // @dev The type of the item determines which equipment slot it goes into.
    // @param item The item to be added to the adventurer's equipment.
    fn add_item(ref self: Adventurer, item: DynamicItem) {
        let slot = ImplLoot::get_slot(item.id);
        match slot {
            Slot::Weapon(()) => self.add_weapon(item),
            Slot::Chest(()) => self.add_chest(item),
            Slot::Head(()) => self.add_head(item),
            Slot::Waist(()) => self.add_waist(item),
            Slot::Foot(()) => self.add_foot(item),
            Slot::Hand(()) => self.add_hand(item),
            Slot::Neck(()) => self.add_neck(item),
            Slot::Ring(()) => self.add_ring(item),
        }
    }

    // @notice Equips the adventurer with a weapon. 
    // @dev The function asserts that the given item is a weapon before adding it to the adventurer's weapon slot.
    // @param item The weapon to be added to the adventurer's equipment.
    fn add_weapon(ref self: Adventurer, item: DynamicItem) {
        assert(ImplLoot::get_slot(item.id) == Slot::Weapon(()), 'Item is not weapon');
        self.weapon = item;
    }
    // @notice Equips the adventurer with a chest armor. 
    // @dev The function asserts that the given item is a chest armor before adding it to the adventurer's chest slot.
    // @param item The chest armor to be added to the adventurer's equipment.
    fn add_chest(ref self: Adventurer, item: DynamicItem) {
        assert(ImplLoot::get_slot(item.id) == Slot::Chest(()), 'Item is not chest armor');
        self.chest = item;
    }
    // @notice Equips the adventurer with a head armor. 
    // @dev The function asserts that the given item is a head armor before adding it to the adventurer's head slot.
    // @param item The head armor to be added to the adventurer's equipment.
    fn add_head(ref self: Adventurer, item: DynamicItem) {
        assert(ImplLoot::get_slot(item.id) == Slot::Head(()), 'Item is not head armor');
        self.head = item;
    }
    // @notice Equips the adventurer with a waist armor. 
    // @dev The function asserts that the given item is a waist armor before adding it to the adventurer's waist slot.
    // @param item The waist armor to be added to the adventurer's equipment.
    fn add_waist(ref self: Adventurer, item: DynamicItem) {
        assert(ImplLoot::get_slot(item.id) == Slot::Waist(()), 'Item is not waist armor');
        self.waist = item;
    }
    // @notice Equips the adventurer with a foot armor. 
    // @dev The function asserts that the given item is a foot armor before adding it to the adventurer's foot slot.
    // @param item The foot armor to be added to the adventurer's equipment.
    fn add_foot(ref self: Adventurer, item: DynamicItem) {
        assert(ImplLoot::get_slot(item.id) == Slot::Foot(()), 'Item is not foot armor');
        self.foot = item;
    }
    // @notice Equips the adventurer with a hand armor. 
    // @dev The function asserts that the given item is a hand armor before adding it to the adventurer's hand slot.
    // @param item The hand armor to be added to the adventurer's equipment.
    fn add_hand(ref self: Adventurer, item: DynamicItem) {
        assert(ImplLoot::get_slot(item.id) == Slot::Hand(()), 'Item is not hand armor');
        self.hand = item;
    }
    // @notice Equips the adventurer with a necklace. 
    // @dev The function asserts that the given item is a necklace before adding it to the adventurer's neck slot.
    // @param item The necklace to be added to the adventurer's equipment.
    fn add_neck(ref self: Adventurer, item: DynamicItem) {
        assert(ImplLoot::get_slot(item.id) == Slot::Neck(()), 'Item is not necklace');
        self.neck = item;
    }
    // @notice Equips the adventurer with a ring. 
    // @dev The function asserts that the given item is a ring before adding it to the adventurer's ring slot.
    // @param item The ring to be added to the adventurer's equipment.
    fn add_ring(ref self: Adventurer, item: DynamicItem) {
        assert(ImplLoot::get_slot(item.id) == Slot::Ring(()), 'Item is not a ring');
        self.ring = item;
    }

    // @title Increase Item Experience
    // @notice This function is used to increase the experience points of a particular item.
    // @dev This function calls the grant_xp_and_check_for_greatness_increase function to execute its logic.
    //
    // @param self A reference to the DynamicItem object which represents the item.
    // @param amount The amount of experience points to be added to the item.
    // @param name_storage A reference to the LootItemSpecialNamesStorage object.
    // @param entropy A number used for randomization.
    //
    // @return Returns a tuple containing the original item level, new level,
    //         boolean indicating if a suffix was assigned, boolean indicating if a prefix was assigned,
    //         and a LootItemSpecialNames object storing the special names for the item.
    fn increase_item_xp(
        ref self: DynamicItem,
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
    // @param self A reference to the DynamicItem object which represents the item.
    // @param value The amount of experience points to be added to the item.
    // @param name_storage A reference to the LootItemSpecialNamesStorage object.
    // @param entropy A number used for randomization.
    //
    // @return Returns a tuple containing the original item level, new level,
    //         boolean indicating if a suffix was assigned, boolean indicating if a prefix was assigned,
    //         and a LootItemSpecialNames object storing the special names for the item.
    fn grant_xp_and_check_for_greatness_increase(
        ref self: DynamicItem,
        value: u16,
        ref name_storage: LootItemSpecialNamesStorage,
        entropy: u128
    ) -> (u8, u8, bool, bool, LootItemSpecialNames) {
        // get the previous level of the item
        let original_level = self.get_greatness();

        if (u16_overflowing_add(self.xp, value).is_ok()) {
            self.xp += value;
        } else {
            self.xp = 65535;
        }

        // get the new level of the item
        let new_level = self.get_greatness();

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
        let current_block_modulo_512: u16 = (block_number % MAX_ADVENTURER_BLOCKS.into())
            .try_into()
            .unwrap();

        return Adventurer {
            last_action: current_block_modulo_512, health: STARTING_HEALTH, xp: 0, stats: Stats {
                strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0
                }, gold: STARTING_GOLD, weapon: DynamicItem {
                id: starting_item, xp: 0, metadata: 1, 
                }, chest: DynamicItem {
                id: 0, xp: 0, metadata: 0, 
                }, head: DynamicItem {
                id: 0, xp: 0, metadata: 0, 
                }, waist: DynamicItem {
                id: 0, xp: 0, metadata: 0, 
                }, foot: DynamicItem {
                id: 0, xp: 0, metadata: 0, 
                }, hand: DynamicItem {
                id: 0, xp: 0, metadata: 0, 
                }, neck: DynamicItem {
                id: 0, xp: 0, metadata: 0, 
                }, ring: DynamicItem {
                id: 0, xp: 0, metadata: 0, 
            }, beast_health: BeastSettings::STARTER_BEAST_HEALTH, stat_points_available: 0,
        };
    }


    // get_battle_fixed_entropy provides an entropy source that is fixed during battle
    // it intentionally does not use game_entropy as that could change during battle and this
    // entropy allows us to simulate a persistent battle without having to store beast
    // details on-chain.
    fn get_battle_fixed_entropy(self: Adventurer, adventurer_entropy: u128) -> u128 {
        self.xp.into() + adventurer_entropy.into()
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

    // @dev This function adds a boost to an adventurer's attributes based on a provided suffix.
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
            self.add_strength(3);
        } else if (suffix == ItemSuffix::of_Giant) {
            self.add_vitality(3);
        } else if (suffix == ItemSuffix::of_Titans) {
            self.add_strength(2);
            self.add_charisma(1);
        } else if (suffix == ItemSuffix::of_Skill) {
            self.add_dexterity(3);
        } else if (suffix == ItemSuffix::of_Perfection) {
            self.add_strength(1);
            self.add_dexterity(1);
            self.add_vitality(1);
        } else if (suffix == ItemSuffix::of_Brilliance) {
            self.add_intelligence(3);
        } else if (suffix == ItemSuffix::of_Enlightenment) {
            self.add_wisdom(3);
        } else if (suffix == ItemSuffix::of_Protection) {
            self.add_vitality(2);
            self.add_dexterity(1);
        } else if (suffix == ItemSuffix::of_Anger) {
            self.add_strength(2);
            self.add_dexterity(1);
        } else if (suffix == ItemSuffix::of_Rage) {
            self.add_strength(1);
            self.add_charisma(1);
            self.add_wisdom(1);
        } else if (suffix == ItemSuffix::of_Fury) {
            self.add_vitality(1);
            self.add_charisma(1);
            self.add_intelligence(1);
        } else if (suffix == ItemSuffix::of_Vitriol) {
            self.add_intelligence(2);
            self.add_wisdom(1);
        } else if (suffix == ItemSuffix::of_the_Fox) {
            self.add_dexterity(2);
            self.add_charisma(1);
        } else if (suffix == ItemSuffix::of_Detection) {
            self.add_wisdom(2);
            self.add_dexterity(1);
        } else if (suffix == ItemSuffix::of_Reflection) {
            self.add_intelligence(1);
            self.add_wisdom(2);
        } else if (suffix == ItemSuffix::of_the_Twins) {
            self.add_charisma(3);
        }
    }

    fn remove_suffix_boost(ref self: Stats, suffix: u8, ) {
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

    fn apply_item_stat_boosts(
        ref self: Adventurer,
        name_storage1: LootItemSpecialNamesStorage,
        name_storage2: LootItemSpecialNamesStorage
    ) -> Adventurer {
        if (self.weapon.get_greatness() >= 15) {
            if (ImplAdventurer::get_storage_index(self.weapon.metadata) == 0) {
                let weapon_names = ImplLootItemSpecialNames::get_loot_special_names(
                    name_storage1, self.weapon
                );
                self.add_suffix_boost(weapon_names.item_suffix, );
            } else {
                let weapon_names = ImplLootItemSpecialNames::get_loot_special_names(
                    name_storage2, self.weapon
                );
                self.add_suffix_boost(weapon_names.item_suffix, );
            }
        }
        if (self.chest.get_greatness() >= 15) {
            if (ImplAdventurer::get_storage_index(self.chest.metadata) == 0) {
                let chest_names = ImplLootItemSpecialNames::get_loot_special_names(
                    name_storage1, self.chest
                );
                self.add_suffix_boost(chest_names.item_suffix, );
            } else {
                let chest_names = ImplLootItemSpecialNames::get_loot_special_names(
                    name_storage2, self.chest
                );
                self.add_suffix_boost(chest_names.item_suffix, );
            }
        }
        if (self.head.get_greatness() >= 15) {
            if (ImplAdventurer::get_storage_index(self.head.metadata) == 0) {
                let head_names = ImplLootItemSpecialNames::get_loot_special_names(
                    name_storage1, self.head
                );
                self.add_suffix_boost(head_names.item_suffix, );
            } else {
                let head_names = ImplLootItemSpecialNames::get_loot_special_names(
                    name_storage2, self.head
                );
                self.add_suffix_boost(head_names.item_suffix, );
            }
        }
        if (self.waist.get_greatness() >= 15) {
            if (ImplAdventurer::get_storage_index(self.waist.metadata) == 0) {
                let waist_names = ImplLootItemSpecialNames::get_loot_special_names(
                    name_storage1, self.waist
                );
                self.add_suffix_boost(waist_names.item_suffix, );
            } else {
                let waist_names = ImplLootItemSpecialNames::get_loot_special_names(
                    name_storage2, self.waist
                );
                self.add_suffix_boost(waist_names.item_suffix, );
            }
        }

        if (self.foot.get_greatness() >= 15) {
            if (ImplAdventurer::get_storage_index(self.foot.metadata) == 0) {
                let foot_names = ImplLootItemSpecialNames::get_loot_special_names(
                    name_storage1, self.foot
                );
                self.add_suffix_boost(foot_names.item_suffix, );
            } else {
                let foot_names = ImplLootItemSpecialNames::get_loot_special_names(
                    name_storage2, self.foot
                );
                self.add_suffix_boost(foot_names.item_suffix, );
            }
        }

        if (self.hand.get_greatness() >= 15) {
            if (ImplAdventurer::get_storage_index(self.hand.metadata) == 0) {
                let hand_names = ImplLootItemSpecialNames::get_loot_special_names(
                    name_storage1, self.hand
                );
                self.add_suffix_boost(hand_names.item_suffix, );
            } else {
                let hand_names = ImplLootItemSpecialNames::get_loot_special_names(
                    name_storage2, self.hand
                );
                self.add_suffix_boost(hand_names.item_suffix, );
            }
        }

        if (self.neck.get_greatness() >= 15) {
            if (ImplAdventurer::get_storage_index(self.neck.metadata) == 0) {
                let neck_names = ImplLootItemSpecialNames::get_loot_special_names(
                    name_storage1, self.neck
                );
                self.add_suffix_boost(neck_names.item_suffix, );
            } else {
                let neck_names = ImplLootItemSpecialNames::get_loot_special_names(
                    name_storage2, self.neck
                );
                self.add_suffix_boost(neck_names.item_suffix, );
            }
        }

        if (self.ring.get_greatness() >= 15) {
            // we need to get the suffix which is in one of the two meta data storages
            if (ImplAdventurer::get_storage_index(self.ring.metadata) == 0) {
                // it's in storage slot 1
                let ring_names = ImplLootItemSpecialNames::get_loot_special_names(
                    name_storage1, self.ring
                );
                self.add_suffix_boost(ring_names.item_suffix, );
            } else {
                // it's in storage slot 2
                let ring_names = ImplLootItemSpecialNames::get_loot_special_names(
                    name_storage2, self.ring
                );
                self.add_suffix_boost(ring_names.item_suffix, );
            }
        }

        self
    }

    fn remove_item_stat_boosts(
        ref self: Adventurer,
        name_storage1: LootItemSpecialNamesStorage,
        name_storage2: LootItemSpecialNamesStorage
    ) {
        if (self.weapon.get_greatness() >= 15) {
            if (ImplAdventurer::get_storage_index(self.weapon.metadata) == 0) {
                let weapon_names = ImplLootItemSpecialNames::get_loot_special_names(
                    name_storage1, self.weapon
                );
                self.stats.remove_suffix_boost(weapon_names.item_suffix, );
            } else {
                let weapon_names = ImplLootItemSpecialNames::get_loot_special_names(
                    name_storage2, self.weapon
                );
                self.stats.remove_suffix_boost(weapon_names.item_suffix, );
            }
        }
        if (self.chest.get_greatness() >= 15) {
            if (ImplAdventurer::get_storage_index(self.chest.metadata) == 0) {
                let chest_names = ImplLootItemSpecialNames::get_loot_special_names(
                    name_storage1, self.chest
                );
                self.stats.remove_suffix_boost(chest_names.item_suffix, );
            } else {
                let chest_names = ImplLootItemSpecialNames::get_loot_special_names(
                    name_storage2, self.chest
                );
                self.stats.remove_suffix_boost(chest_names.item_suffix, );
            }
        }
        if (self.head.get_greatness() >= 15) {
            if (ImplAdventurer::get_storage_index(self.head.metadata) == 0) {
                let head_names = ImplLootItemSpecialNames::get_loot_special_names(
                    name_storage1, self.head
                );
                self.stats.remove_suffix_boost(head_names.item_suffix, );
            } else {
                let head_names = ImplLootItemSpecialNames::get_loot_special_names(
                    name_storage2, self.head
                );
                self.stats.remove_suffix_boost(head_names.item_suffix, );
            }
        }
        if (self.waist.get_greatness() >= 15) {
            if (ImplAdventurer::get_storage_index(self.waist.metadata) == 0) {
                let waist_names = ImplLootItemSpecialNames::get_loot_special_names(
                    name_storage1, self.waist
                );
                self.stats.remove_suffix_boost(waist_names.item_suffix, );
            } else {
                let waist_names = ImplLootItemSpecialNames::get_loot_special_names(
                    name_storage2, self.waist
                );
                self.stats.remove_suffix_boost(waist_names.item_suffix, );
            }
        }

        if (self.foot.get_greatness() >= 15) {
            if (ImplAdventurer::get_storage_index(self.foot.metadata) == 0) {
                let foot_names = ImplLootItemSpecialNames::get_loot_special_names(
                    name_storage1, self.foot
                );
                self.stats.remove_suffix_boost(foot_names.item_suffix, );
            } else {
                let foot_names = ImplLootItemSpecialNames::get_loot_special_names(
                    name_storage2, self.foot
                );
                self.stats.remove_suffix_boost(foot_names.item_suffix, );
            }
        }

        if (self.hand.get_greatness() >= 15) {
            if (ImplAdventurer::get_storage_index(self.hand.metadata) == 0) {
                let hand_names = ImplLootItemSpecialNames::get_loot_special_names(
                    name_storage1, self.hand
                );
                self.stats.remove_suffix_boost(hand_names.item_suffix, );
            } else {
                let hand_names = ImplLootItemSpecialNames::get_loot_special_names(
                    name_storage2, self.hand
                );
                self.stats.remove_suffix_boost(hand_names.item_suffix, );
            }
        }

        if (self.neck.get_greatness() >= 15) {
            if (ImplAdventurer::get_storage_index(self.neck.metadata) == 0) {
                let neck_names = ImplLootItemSpecialNames::get_loot_special_names(
                    name_storage1, self.neck
                );
                self.stats.remove_suffix_boost(neck_names.item_suffix, );
            } else {
                let neck_names = ImplLootItemSpecialNames::get_loot_special_names(
                    name_storage2, self.neck
                );
                self.stats.remove_suffix_boost(neck_names.item_suffix, );
            }
        }

        if (self.ring.get_greatness() >= 15) {
            // we need to get the suffix which is in one of the two meta data storages
            if (ImplAdventurer::get_storage_index(self.ring.metadata) == 0) {
                // it's in storage slot 1
                let ring_names = ImplLootItemSpecialNames::get_loot_special_names(
                    name_storage1, self.ring
                );
                self.stats.remove_suffix_boost(ring_names.item_suffix, );
            } else {
                // it's in storage slot 2
                let ring_names = ImplLootItemSpecialNames::get_loot_special_names(
                    name_storage2, self.ring
                );
                self.stats.remove_suffix_boost(ring_names.item_suffix, );
            }
        }
    }

    fn get_storage_index(meta_data_id: u8) -> u256 {
        if (meta_data_id <= 10) {
            return 0;
        } else {
            return 1;
        }
    }

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
}

#[test]
#[available_gas(5000000)]
fn test_get_idle_blocks() {
    let mut adventurer = Adventurer {
        last_action: 1, health: 480, xp: 8191, stats: Stats {
            strength: 31, dexterity: 31, vitality: 31, intelligence: 31, wisdom: 31, charisma: 31, 
            }, gold: 511, weapon: DynamicItem {
            id: 100, xp: 511, metadata: 1, 
            }, chest: DynamicItem {
            id: 99, xp: 511, metadata: 2, 
            }, head: DynamicItem {
            id: 98, xp: 511, metadata: 3, 
            }, waist: DynamicItem {
            id: 87, xp: 511, metadata: 4, 
            }, foot: DynamicItem {
            id: 78, xp: 511, metadata: 5, 
            }, hand: DynamicItem {
            id: 34, xp: 511, metadata: 6, 
            }, neck: DynamicItem {
            id: 32, xp: 511, metadata: 7, 
            }, ring: DynamicItem {
            id: 1, xp: 511, metadata: 8, 
        }, beast_health: 480, stat_points_available: 1,
    };

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
#[available_gas(5000000)]
fn test_adventurer() {
    let adventurer = Adventurer {
        last_action: 511, health: 480, xp: 8191, stats: Stats {
            strength: 31, dexterity: 31, vitality: 31, intelligence: 31, wisdom: 31, charisma: 31, 
            }, gold: 511, weapon: DynamicItem {
            id: 100, xp: 511, metadata: 1, 
            }, chest: DynamicItem {
            id: 99, xp: 511, metadata: 2, 
            }, head: DynamicItem {
            id: 98, xp: 511, metadata: 3, 
            }, waist: DynamicItem {
            id: 87, xp: 511, metadata: 4, 
            }, foot: DynamicItem {
            id: 78, xp: 511, metadata: 5, 
            }, hand: DynamicItem {
            id: 34, xp: 511, metadata: 6, 
            }, neck: DynamicItem {
            id: 32, xp: 511, metadata: 7, 
            }, ring: DynamicItem {
            id: 1, xp: 511, metadata: 8, 
        }, beast_health: 480, stat_points_available: 1,
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
#[available_gas(5000000)]
fn test_new_adventurer() {
    let new_adventurer = ImplAdventurer::new(1, 1);

    new_adventurer.pack();

    assert(new_adventurer.health == 100, 'health');
}

#[test]
#[available_gas(5000000)]
fn test_add_health() {
    let mut adventurer = ImplAdventurer::new(1, 1);
    adventurer.add_health(5);
    assert(adventurer.health == 100, 'max health with 0 vit is 100');

    adventurer.stats.vitality = 1;
    adventurer.add_health(5);
    assert(adventurer.health == 105, 'health should be 105');

    adventurer.add_health(50);
    assert(adventurer.health == 120, 'max health with 1 vit is 120');
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
#[available_gas(50000)]
fn test_add_strength() {
    let mut adventurer = ImplAdventurer::new(1, 1);
    // basic case
    adventurer.add_strength(1);
    assert(adventurer.stats.strength == 1, 'strength should be 1');
    // overflow case
    adventurer.add_strength(100);
    assert(adventurer.stats.strength == MAX_STAT_VALUE, 'strength should be max');
}

#[test]
#[available_gas(90000)]
fn test_deduct_strength() {
    let mut adventurer = ImplAdventurer::new(1, 1);
    // basic case
    adventurer.add_strength(2);
    adventurer.deduct_strength(1);
    assert(adventurer.stats.strength == 1, 'strength should be 1');
    // underflow case
    adventurer.add_strength(5);
    adventurer.deduct_strength(6);
    assert(adventurer.stats.strength == 0, 'strength should be 0');
}

#[test]
#[available_gas(90000)]
fn test_deduct_dexterity() {
    let mut adventurer = ImplAdventurer::new(1, 1);
    // basic case
    adventurer.add_dexterity(2);
    adventurer.deduct_dexterity(1);
    assert(adventurer.stats.dexterity == 1, 'dexterity should be 1');
    // underflow case
    adventurer.add_dexterity(5);
    adventurer.deduct_dexterity(6);
    assert(adventurer.stats.dexterity == 0, 'dexterity should be 0');
}

#[test]
#[available_gas(90000)]
fn test_deduct_vitality() {
    let mut adventurer = ImplAdventurer::new(1, 1);
    // basic case
    adventurer.add_vitality(2);
    adventurer.deduct_vitality(1);
    assert(adventurer.stats.vitality == 1, 'vitality should be 1');
    // underflow case
    adventurer.add_vitality(5);
    adventurer.deduct_vitality(6);
    assert(adventurer.stats.vitality == 0, 'vitality should be 0');
}

#[test]
#[available_gas(90000)]
fn test_deduct_intelligence() {
    let mut adventurer = ImplAdventurer::new(1, 1);
    // basic case
    adventurer.add_intelligence(2);
    adventurer.deduct_intelligence(1);
    assert(adventurer.stats.intelligence == 1, 'intelligence should be 1');
    // underflow case
    adventurer.add_intelligence(5);
    adventurer.deduct_intelligence(6);
    assert(adventurer.stats.intelligence == 0, 'intelligence should be 0');
}

#[test]
#[available_gas(90000)]
fn test_deduct_wisdom() {
    let mut adventurer = ImplAdventurer::new(1, 1);
    // basic case
    adventurer.add_wisdom(2);
    adventurer.deduct_wisdom(1);
    assert(adventurer.stats.wisdom == 1, 'wisdom should be 1');
    // underflow case
    adventurer.add_wisdom(5);
    adventurer.deduct_wisdom(6);
    assert(adventurer.stats.wisdom == 0, 'wisdom should be 0');
}

#[test]
#[available_gas(90000)]
fn test_deduct_charisma() {
    let mut adventurer = ImplAdventurer::new(1, 1);
    // basic case
    adventurer.add_charisma(2);
    adventurer.deduct_charisma(1);
    assert(adventurer.stats.charisma == 1, 'charisma should be 1');
    // underflow case
    adventurer.add_charisma(5);
    adventurer.deduct_charisma(6);
    assert(adventurer.stats.charisma == 0, 'charisma should be 0');
}

#[test]
#[available_gas(50000)]
fn test_add_dexterity() {
    let mut adventurer = ImplAdventurer::new(1, 1);
    // basic case
    adventurer.add_dexterity(1);
    assert(adventurer.stats.dexterity == 1, 'dexterity should be 1');
    // overflow case
    adventurer.add_dexterity(100);
    assert(adventurer.stats.dexterity == MAX_STAT_VALUE, 'dexterity should be max');
}

#[test]
#[available_gas(50000)]
fn test_add_vitality() {
    let mut adventurer = ImplAdventurer::new(1, 1);
    // basic case
    adventurer.add_vitality(1);
    assert(adventurer.stats.vitality == 1, 'vitality should be 1');
    // overflow case
    adventurer.add_vitality(100);
    assert(adventurer.stats.vitality == MAX_STAT_VALUE, 'vitality should be max');
}

#[test]
#[available_gas(50000)]
fn test_add_intelligence() {
    let mut adventurer = ImplAdventurer::new(1, 1);
    // basic case
    adventurer.add_intelligence(1);
    assert(adventurer.stats.intelligence == 1, 'intelligence should be 1');
    // overflow case
    adventurer.add_intelligence(100);
    assert(adventurer.stats.intelligence == MAX_STAT_VALUE, 'intelligence should be max');
}

#[test]
#[available_gas(50000)]
fn test_add_wisdom() {
    let mut adventurer = ImplAdventurer::new(1, 1);
    // basic case
    adventurer.add_wisdom(1);
    assert(adventurer.stats.wisdom == 1, 'wisdom should be 1');
    // overflow case
    adventurer.add_wisdom(100);
    assert(adventurer.stats.wisdom == MAX_STAT_VALUE, 'wisdom should be max');
}

#[test]
#[available_gas(50000)]
fn test_add_charisma() {
    let mut adventurer = ImplAdventurer::new(1, 1);
    // basic case
    adventurer.add_charisma(1);
    assert(adventurer.stats.charisma == 1, 'charisma should be 1');
    // overflow case
    adventurer.add_charisma(100);
    assert(adventurer.stats.charisma == MAX_STAT_VALUE, 'charisma should be max');
}

#[test]
#[should_panic(expected: ('Item is not weapon', ))]
#[available_gas(50000)]
fn test_add_invalid_weapon() {
    let mut adventurer = ImplAdventurer::new(1, 1);
    // create demon crown item
    let item = DynamicItem { id: constants::ItemId::DemonCrown, xp: 1, metadata: 0 };
    // try to equip it to adventurer as a weapon
    adventurer.add_weapon(item);
// should panic with 'Item is not weapon' message
// because demon crown is not a weapon
// test is annotated to expect this panic and will
// pass if it does, otherwise it will fail
}

#[test]
#[available_gas(50000)]
fn test_add_valid_weapon() {
    let mut adventurer = ImplAdventurer::new(1, 1);

    // Create Katana item
    let item = DynamicItem { id: constants::ItemId::Katana, xp: 1, metadata: 0 };

    // Equip to adventurer as a weapon
    adventurer.add_weapon(item);

    // Assert item was equipped
    assert(adventurer.weapon.id == constants::ItemId::Katana, 'did not equip weapon');
    assert(adventurer.weapon.xp == 1, 'weapon xp is not 1');
    assert(adventurer.weapon.metadata == 0, 'weapon metadata is not 0');
}

#[test]
#[should_panic(expected: ('Item is not chest armor', ))]
#[available_gas(50000)]
fn test_add_invalid_chest() {
    let mut adventurer = ImplAdventurer::new(1, 1);
    // try to equip a Demon Crown as chest item
    let item = DynamicItem { id: constants::ItemId::DemonCrown, xp: 1, metadata: 0 };
    adventurer.add_chest(item);
// should panic with 'Item is not chest armor' message
// because Demon Crown is not chest armor
// test is annotated to expect this panic and will
// pass if it does, otherwise it will fail
}

#[test]
#[available_gas(50000)]
fn test_add_valid_chest() {
    let mut adventurer = ImplAdventurer::new(1, 1);
    // equip Divine Robe as chest item
    let item = DynamicItem { id: constants::ItemId::DivineRobe, xp: 1, metadata: 0 };
    adventurer.add_chest(item);

    // this should not panic
    // assert item was equipped
    assert(adventurer.chest.id == constants::ItemId::DivineRobe, 'did not equip chest armor');
    assert(adventurer.chest.xp == 1, 'chest armor xp is not 1');
    assert(adventurer.chest.metadata == 0, 'chest armor metadata is not 0');
}

#[test]
#[should_panic(expected: ('Item is not head armor', ))]
#[available_gas(50000)]
fn test_add_invalid_head() {
    let mut adventurer = ImplAdventurer::new(1, 1);
    // try to equip a Katana as head item
    let item = DynamicItem { id: constants::ItemId::Katana, xp: 1, metadata: 0 };
    adventurer.add_head(item);
// should panic with 'Item is not head armor' message
}

#[test]
#[available_gas(50000)]
fn test_add_valid_head() {
    let mut adventurer = ImplAdventurer::new(1, 1);
    // equip Crown as head item
    let item = DynamicItem { id: constants::ItemId::Crown, xp: 1, metadata: 0 };
    adventurer.add_head(item);
    // this should not panic
    // assert item was equipped
    assert(adventurer.head.id == constants::ItemId::Crown, 'did not equip head armor');
    assert(adventurer.head.xp == 1, 'head armor xp is not 1');
    assert(adventurer.head.metadata == 0, 'head armor metadata is not 0');
}

#[test]
#[should_panic(expected: ('Item is not waist armor', ))]
#[available_gas(50000)]
fn test_add_invalid_waist() {
    let mut adventurer = ImplAdventurer::new(1, 1);
    // try to equip a Demon Crown as waist item
    let item = DynamicItem { id: constants::ItemId::DemonCrown, xp: 1, metadata: 0 };
    adventurer.add_waist(item);
// should panic with 'Item is not waist armor' message
}

#[test]
#[available_gas(50000)]
fn test_add_valid_waist() {
    let mut adventurer = ImplAdventurer::new(1, 1);

    // equip Wool Sash as waist item
    let item = DynamicItem { id: constants::ItemId::WoolSash, xp: 1, metadata: 0 };
    adventurer.add_waist(item);

    // this should not panic
    // assert item was equipped
    assert(adventurer.waist.id == constants::ItemId::WoolSash, 'did not equip waist armor');
    assert(adventurer.waist.xp == 1, 'waist armor xp is not 1');
    assert(adventurer.waist.metadata == 0, 'waist armor metadata is not 0');
}

#[test]
#[should_panic(expected: ('Item is not foot armor', ))]
#[available_gas(50000)]
fn test_add_invalid_foot() {
    let mut adventurer = ImplAdventurer::new(1, 1);
    // try to equip a Demon Crown as foot item
    let item = DynamicItem { id: constants::ItemId::DemonCrown, xp: 1, metadata: 0 };
    adventurer.add_foot(item);
// should panic with 'Item is not foot armor' message
}

#[test]
#[available_gas(50000)]
fn test_add_valid_foot() {
    let mut adventurer = ImplAdventurer::new(1, 1);

    // equip Silk Slippers as foot item
    let item = DynamicItem { id: constants::ItemId::SilkSlippers, xp: 1, metadata: 0 };
    adventurer.add_foot(item);

    // this should not panic
    // assert item was equipped
    assert(adventurer.foot.id == constants::ItemId::SilkSlippers, 'did not equip foot armor');
    assert(adventurer.foot.xp == 1, 'foot armor xp is not 1');
    assert(adventurer.foot.metadata == 0, 'foot armor metadata is not 0');
}

#[test]
#[should_panic(expected: ('Item is not hand armor', ))]
#[available_gas(50000)]
fn test_add_invalid_hand() {
    let mut adventurer = ImplAdventurer::new(1, 1);

    // try to equip a Demon Crown as hand item
    let item = DynamicItem { id: constants::ItemId::DemonCrown, xp: 1, metadata: 0 };
    adventurer.add_hand(item);
// should panic with 'Item is not hand armor' message
}

#[test]
#[available_gas(50000)]
fn test_add_valid_hand() {
    let mut adventurer = ImplAdventurer::new(1, 1);

    // equip Divine Gloves as hand item
    let item = DynamicItem { id: constants::ItemId::DivineGloves, xp: 1, metadata: 0 };
    adventurer.add_hand(item);

    // this should not panic
    // assert item was equipped
    assert(adventurer.hand.id == constants::ItemId::DivineGloves, 'did not equip hand armor');
    assert(adventurer.hand.xp == 1, 'hand armor xp is not 1');
    assert(adventurer.hand.metadata == 0, 'hand armor metadata is not 0');
}

#[test]
#[should_panic(expected: ('Item is not necklace', ))]
#[available_gas(50000)]
fn test_add_invalid_neck() {
    let mut adventurer = ImplAdventurer::new(1, 1);

    // try to equip a Demon Crown as necklace
    let item = DynamicItem { id: constants::ItemId::DemonCrown, xp: 1, metadata: 0 };
    adventurer.add_neck(item);
// should panic with 'Item is not necklace' message
}

#[test]
#[available_gas(50000)]
fn test_add_valid_neck() {
    let mut adventurer = ImplAdventurer::new(1, 1);

    // equip Pendant as necklace
    let item = DynamicItem { id: constants::ItemId::Pendant, xp: 1, metadata: 0 };
    adventurer.add_neck(item);

    // this should not panic
    // assert item was equipped
    assert(adventurer.neck.id == constants::ItemId::Pendant, 'did not equip necklace');
    assert(adventurer.neck.xp == 1, 'necklace xp is not 1');
    assert(adventurer.neck.metadata == 0, 'necklace metadata is not 0');
}

#[test]
#[should_panic(expected: ('Item is not a ring', ))]
#[available_gas(50000)]
fn test_add_invalid_ring() {
    let mut adventurer = ImplAdventurer::new(1, 1);

    // try to equip a Demon Crown as ring
    let item = DynamicItem { id: constants::ItemId::DemonCrown, xp: 1, metadata: 0 };
    adventurer.add_ring(item);
// should panic with 'Item is not a ring' message
}

#[test]
#[available_gas(50000)]
fn test_add_valid_ring() {
    let mut adventurer = ImplAdventurer::new(1, 1);
    let item = DynamicItem { id: constants::ItemId::PlatinumRing, xp: 1, metadata: 0 };
    adventurer.add_ring(item);
    assert(adventurer.ring.id == constants::ItemId::PlatinumRing, 'did not equip ring');
    assert(adventurer.ring.xp == 1, 'ring xp is not 1');
    assert(adventurer.ring.metadata == 0, 'ring metadata is not 0');
}

#[test]
#[available_gas(5000000)]
fn test_increase_item_xp() {
    let mut adventurer = ImplAdventurer::new(1, 1);
    let entropy = 1;
    let item_ghost_wand = DynamicItem { id: constants::ItemId::GhostWand, xp: 1, metadata: 1 };
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
    let divine_robe = DynamicItem { id: constants::ItemId::DivineRobe, xp: 1, metadata: 2 };
    adventurer.add_item(divine_robe);

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
            }, gold: 1, weapon: DynamicItem {
            id: 100, xp: 511, metadata: 1, 
            }, chest: DynamicItem {
            id: 99, xp: 511, metadata: 2, 
            }, head: DynamicItem {
            id: 98, xp: 511, metadata: 3, 
            }, waist: DynamicItem {
            id: 87, xp: 511, metadata: 4, 
            }, foot: DynamicItem {
            id: 78, xp: 511, metadata: 5, 
            }, hand: DynamicItem {
            id: 34, xp: 511, metadata: 6, 
            }, neck: DynamicItem {
            id: 32, xp: 511, metadata: 7, 
            }, ring: DynamicItem {
            id: 1, xp: 511, metadata: 8, 
        }, beast_health: 1023, stat_points_available: 1,
    };

    let discount = adventurer.get_potion_price();

    assert(discount == MINIMUM_POTION_PRICE, 'discount');

    // set to 0
    adventurer.stats.charisma = 0;

    let discount = adventurer.get_potion_price();

    assert(discount == MINIMUM_POTION_PRICE * adventurer.get_level().into(), 'no charisma potion');
}

#[test]
#[available_gas(500000)]
fn test_charisma_item_discount_overflow() {
    let mut adventurer = Adventurer {
        last_action: 511, health: 1023, xp: 100, stats: Stats {
            strength: 31, dexterity: 31, vitality: 31, intelligence: 31, wisdom: 31, charisma: 10, 
            }, gold: 40, weapon: DynamicItem {
            id: 100, xp: 511, metadata: 1, 
            }, chest: DynamicItem {
            id: 99, xp: 511, metadata: 2, 
            }, head: DynamicItem {
            id: 98, xp: 511, metadata: 3, 
            }, waist: DynamicItem {
            id: 87, xp: 511, metadata: 4, 
            }, foot: DynamicItem {
            id: 78, xp: 511, metadata: 5, 
            }, hand: DynamicItem {
            id: 34, xp: 511, metadata: 6, 
            }, neck: DynamicItem {
            id: 32, xp: 511, metadata: 7, 
            }, ring: DynamicItem {
            id: 1, xp: 511, metadata: 8, 
        }, beast_health: 1023, stat_points_available: 1,
    };

    let max_item_price = 15;

    let item_price = adventurer.get_item_cost(max_item_price);

    assert(item_price == MINIMUM_ITEM_PRICE, 'min_item_price');

    adventurer.stats.charisma = 0;

    let item_price = adventurer.get_item_cost(max_item_price);

    assert(item_price == max_item_price, 'max_item_price');
}

#[test]
#[available_gas(90000)]
fn test_increase_xp() {
    // initialize lvl 1 adventurer with no stat points available
    let mut adventurer = Adventurer {
        last_action: 511, health: 1023, xp: 1, stats: Stats {
            strength: 31, dexterity: 31, vitality: 31, intelligence: 31, wisdom: 31, charisma: 10, 
            }, gold: 40, weapon: DynamicItem {
            id: 100, xp: 511, metadata: 1, 
            }, chest: DynamicItem {
            id: 99, xp: 511, metadata: 2, 
            }, head: DynamicItem {
            id: 98, xp: 511, metadata: 3, 
            }, waist: DynamicItem {
            id: 87, xp: 511, metadata: 4, 
            }, foot: DynamicItem {
            id: 78, xp: 511, metadata: 5, 
            }, hand: DynamicItem {
            id: 34, xp: 511, metadata: 6, 
            }, neck: DynamicItem {
            id: 32, xp: 511, metadata: 7, 
            }, ring: DynamicItem {
            id: 1, xp: 511, metadata: 8, 
        }, beast_health: 1023, stat_points_available: 0,
    };

    // increase adventurer xp by 3 which should level up the adventurer
    adventurer.increase_adventurer_xp(3);
    assert(adventurer.get_level() == 2, 'advtr should be lvl 2');

    // double level up without spending previous stat point
    adventurer.increase_adventurer_xp(12);
    assert(adventurer.get_level() == 4, 'advtr should be lvl 4');
}

#[test]
#[available_gas(400000)]
fn test_add_suffix_boost() {
    // initialize new adventurer
    let mut adventurer = Adventurer {
        last_action: 511, health: 100, xp: 1, stats: Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0, 
            }, gold: 40, weapon: DynamicItem {
            id: 1, xp: 225, metadata: 1, 
            }, chest: DynamicItem {
            id: 2, xp: 65535, metadata: 2, 
            }, head: DynamicItem {
            id: 3, xp: 225, metadata: 3, 
            }, waist: DynamicItem {
            id: 4, xp: 225, metadata: 4, 
            }, foot: DynamicItem {
            id: 5, xp: 1000, metadata: 5, 
            }, hand: DynamicItem {
            id: 6, xp: 224, metadata: 6, 
            }, neck: DynamicItem {
            id: 7, xp: 1, metadata: 7, 
            }, ring: DynamicItem {
            id: 8, xp: 1, metadata: 8, 
        }, beast_health: 20, stat_points_available: 0,
    };

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
#[available_gas(800000)]
fn test_apply_item_stat_boosts() {
    let mut adventurer = Adventurer {
        last_action: 511, health: 100, xp: 1, stats: Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0, 
            }, gold: 40, weapon: DynamicItem {
            id: 1, xp: 225, metadata: 1, 
            }, chest: DynamicItem {
            id: 2, xp: 65535, metadata: 2, 
            }, head: DynamicItem {
            id: 3, xp: 225, metadata: 3, 
            }, waist: DynamicItem {
            id: 4, xp: 225, metadata: 4, 
            }, foot: DynamicItem {
            id: 5, xp: 1000, metadata: 5, 
            }, hand: DynamicItem {
            id: 6, xp: 224, metadata: 6, 
            }, neck: DynamicItem {
            id: 7, xp: 1, metadata: 7, 
            }, ring: DynamicItem {
            id: 8, xp: 1, metadata: 8, 
        }, beast_health: 20, stat_points_available: 0,
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

    let boost_stats = ImplAdventurer::apply_item_stat_boosts(
        ref adventurer, name_storage1, name_storage2
    );
    assert(adventurer.stats.strength == 5, 'strength should be 5');
    assert(adventurer.stats.vitality == 5, 'vitality should be 5');
    assert(adventurer.stats.dexterity == 1, 'dexterity should be 1');
    assert(adventurer.stats.intelligence == 1, 'intelligence should be 1');
    assert(adventurer.stats.wisdom == 1, 'wisdom should be 1');
    assert(adventurer.stats.charisma == 2, 'charisma should be 2');
}


#[test]
#[available_gas(300000)]
fn test_get_market_entropy() {
    let mut adventurer = Adventurer {
        last_action: 511, health: 12, xp: 231, stats: Stats {
            strength: 0, dexterity: 0, vitality: 0, intelligence: 0, wisdom: 0, charisma: 0, 
            }, gold: 40, weapon: DynamicItem {
            id: 1, xp: 225, metadata: 1, 
            }, chest: DynamicItem {
            id: 2, xp: 65535, metadata: 2, 
            }, head: DynamicItem {
            id: 3, xp: 225, metadata: 3, 
            }, waist: DynamicItem {
            id: 4, xp: 225, metadata: 4, 
            }, foot: DynamicItem {
            id: 5, xp: 1000, metadata: 5, 
            }, hand: DynamicItem {
            id: 6, xp: 224, metadata: 6, 
            }, neck: DynamicItem {
            id: 7, xp: 1, metadata: 7, 
            }, ring: DynamicItem {
            id: 8, xp: 1, metadata: 8, 
        }, beast_health: 20, stat_points_available: 0,
    };
}
