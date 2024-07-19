use core::starknet::StorePacking;
use super::item::{Item, ImplItem, ItemPacking};
use loot::loot::ImplLoot;
use loot::constants::SUFFIX_UNLOCK_GREATNESS;
use combat::constants::CombatEnums::Slot;
use adventurer::stats::{Stats, ImplStats};

#[derive(Drop, Copy, Serde, PartialEq)]
struct Equipment { // 128 bits
    weapon: Item, // 16 bits per item
    chest: Item,
    head: Item,
    waist: Item,
    foot: Item,
    hand: Item,
    neck: Item,
    ring: Item,
}

impl EquipmentPacking of StorePacking<Equipment, felt252> {
    fn pack(value: Equipment) -> felt252 {
        (ItemPacking::pack(value.weapon).into()
            + ItemPacking::pack(value.chest).into() * TWO_POW_16
            + ItemPacking::pack(value.head).into() * TWO_POW_32
            + ItemPacking::pack(value.waist).into() * TWO_POW_48
            + ItemPacking::pack(value.foot).into() * TWO_POW_64
            + ItemPacking::pack(value.hand).into() * TWO_POW_80
            + ItemPacking::pack(value.neck).into() * TWO_POW_96
            + ItemPacking::pack(value.ring).into() * TWO_POW_112)
            .try_into()
            .unwrap()
    }

    fn unpack(value: felt252) -> Equipment {
        let packed = value.into();
        let (packed, weapon) = integer::U256DivRem::div_rem(packed, TWO_POW_16.try_into().unwrap());
        let (packed, chest) = integer::U256DivRem::div_rem(packed, TWO_POW_16.try_into().unwrap());
        let (packed, head) = integer::U256DivRem::div_rem(packed, TWO_POW_16.try_into().unwrap());
        let (packed, waist) = integer::U256DivRem::div_rem(packed, TWO_POW_16.try_into().unwrap());
        let (packed, foot) = integer::U256DivRem::div_rem(packed, TWO_POW_16.try_into().unwrap());
        let (packed, hand) = integer::U256DivRem::div_rem(packed, TWO_POW_16.try_into().unwrap());
        let (packed, neck) = integer::U256DivRem::div_rem(packed, TWO_POW_16.try_into().unwrap());
        let (_, ring) = integer::U256DivRem::div_rem(packed, TWO_POW_16.try_into().unwrap());

        Equipment {
            weapon: ItemPacking::unpack(weapon.try_into().unwrap()),
            chest: ItemPacking::unpack(chest.try_into().unwrap()),
            head: ItemPacking::unpack(head.try_into().unwrap()),
            waist: ItemPacking::unpack(waist.try_into().unwrap()),
            foot: ItemPacking::unpack(foot.try_into().unwrap()),
            hand: ItemPacking::unpack(hand.try_into().unwrap()),
            neck: ItemPacking::unpack(neck.try_into().unwrap()),
            ring: ItemPacking::unpack(ring.try_into().unwrap()),
        }
    }
}

#[generate_trait]
impl ImplEquipment of IEquipment {
    fn new() -> Equipment {
        Equipment {
            weapon: ImplItem::new(0),
            chest: ImplItem::new(0),
            head: ImplItem::new(0),
            waist: ImplItem::new(0),
            foot: ImplItem::new(0),
            hand: ImplItem::new(0),
            neck: ImplItem::new(0),
            ring: ImplItem::new(0),
        }
    }

    // @notice Adds an item to the adventurer's equipment.
    // @dev The type of the item determines which equipment slot it goes into.
    // @param item The item to be added to the adventurer's equipment.
    #[inline(always)]
    fn equip(ref self: Equipment, item: Item) {
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

    // @notice Equips the adventurer with a weapon. 
    // @dev The function asserts that the given item is a weapon before adding it to the adventurer's weapon slot.
    // @param item The weapon to be added to the adventurer's equipment.
    #[inline(always)]
    fn equip_weapon(ref self: Equipment, item: Item) {
        assert(ImplLoot::get_slot(item.id) == Slot::Weapon(()), 'Item is not weapon');
        self.weapon = item
    }

    // @notice Equips the adventurer with a chest armor. 
    // @dev The function asserts that the given item is a chest armor before adding it to the adventurer's chest slot.
    // @param item The chest armor to be added to the adventurer's equipment.
    #[inline(always)]
    fn equip_chest_armor(ref self: Equipment, item: Item) {
        assert(ImplLoot::get_slot(item.id) == Slot::Chest(()), 'Item is not chest armor');
        self.chest = item
    }

    // @notice Equips the adventurer with a head armor. 
    // @dev The function asserts that the given item is a head armor before adding it to the adventurer's head slot.
    // @param item The head armor to be added to the adventurer's equipment.
    #[inline(always)]
    fn equip_head_armor(ref self: Equipment, item: Item) {
        assert(ImplLoot::get_slot(item.id) == Slot::Head(()), 'Item is not head armor');
        self.head = item
    }

    // @notice Equips the adventurer with a waist armor. 
    // @dev The function asserts that the given item is a waist armor before adding it to the adventurer's waist slot.
    // @param item The waist armor to be added to the adventurer's equipment.
    #[inline(always)]
    fn equip_waist_armor(ref self: Equipment, item: Item) {
        assert(ImplLoot::get_slot(item.id) == Slot::Waist(()), 'Item is not waist armor');
        self.waist = item
    }

    // @notice Equips the adventurer with a foot armor. 
    // @dev The function asserts that the given item is a foot armor before adding it to the adventurer's foot slot.
    // @param item The foot armor to be added to the adventurer's equipment.
    #[inline(always)]
    fn equip_foot_armor(ref self: Equipment, item: Item) {
        assert(ImplLoot::get_slot(item.id) == Slot::Foot(()), 'Item is not foot armor');
        self.foot = item
    }

    // @notice Equips the adventurer with a hand armor. 
    // @dev The function asserts that the given item is a hand armor before adding it to the adventurer's hand slot.
    // @param item The hand armor to be added to the adventurer's equipment.
    #[inline(always)]
    fn equip_hand_armor(ref self: Equipment, item: Item) {
        assert(ImplLoot::get_slot(item.id) == Slot::Hand(()), 'Item is not hand armor');
        self.hand = item
    }

    // @notice Equips the adventurer with a necklace. 
    // @dev The function asserts that the given item is a necklace before adding it to the adventurer's neck slot.
    // @param item The necklace to be added to the adventurer's equipment.
    #[inline(always)]
    fn equip_necklace(ref self: Equipment, item: Item) {
        assert(ImplLoot::get_slot(item.id) == Slot::Neck(()), 'Item is not necklace');
        self.neck = item
    }

    // @notice Equips the adventurer with a ring. 
    // @dev The function asserts that the given item is a ring before adding it to the adventurer's ring slot.
    // @param item The ring to be added to the adventurer's equipment.
    #[inline(always)]
    fn equip_ring(ref self: Equipment, item: Item) {
        assert(ImplLoot::get_slot(item.id) == Slot::Ring(()), 'Item is not a ring');
        self.ring = item;
    }

    // @dev This function allows an adventurer to drop an item they have equipped.
    // @notice The function only works if the item is currently equipped by the adventurer. It removes the item from the adventurer's equipment and replaces it with a blank item.
    // @param item_id The ID of the item to be dropped. The function will assert if the item is not currently equipped.
    #[inline(always)]
    fn drop(ref self: Equipment, item_id: u8) {
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

    // @notice increases the xp of an item at a given slot
    // @param self the Equipment to increase item xp for
    // @param slot the Slot to increase item xp for
    // @param amount the amount of xp to increase the item by
    // @return (u8, u8): a tuple containing the previous and new level of the item
    fn increase_item_xp_at_slot(ref self: Equipment, slot: Slot, amount: u16) -> (u8, u8) {
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

    // @notice checks if the adventurer has any items with special names.
    // @param self The Equipment to check for item specials.
    // @return Returns true if equipment has item specials, false otherwise.
    fn has_specials(self: Equipment) -> bool {
        if (self.weapon.get_greatness() >= SUFFIX_UNLOCK_GREATNESS) {
            true
        } else if (self.chest.get_greatness() >= SUFFIX_UNLOCK_GREATNESS) {
            true
        } else if (self.head.get_greatness() >= SUFFIX_UNLOCK_GREATNESS) {
            true
        } else if (self.waist.get_greatness() >= SUFFIX_UNLOCK_GREATNESS) {
            true
        } else if (self.foot.get_greatness() >= SUFFIX_UNLOCK_GREATNESS) {
            true
        } else if (self.hand.get_greatness() >= SUFFIX_UNLOCK_GREATNESS) {
            true
        } else if (self.neck.get_greatness() >= SUFFIX_UNLOCK_GREATNESS) {
            true
        } else if (self.ring.get_greatness() >= SUFFIX_UNLOCK_GREATNESS) {
            true
        } else {
            false
        }
    }

    // @notice gets stat boosts based on item specials
    // @param self The Equipment to get stat boosts for.
    // @param start_entropy The start entropy to use for getting item specials.
    // @return Returns the stat boosts for the equipment.
    fn get_stat_boosts(self: Equipment, start_entropy: u64) -> Stats {
        let mut stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, charisma: 0, intelligence: 0, wisdom: 0, luck: 0
        };

        if (self.weapon.get_greatness() >= SUFFIX_UNLOCK_GREATNESS) {
            stats.apply_suffix_boost(ImplLoot::get_suffix(self.weapon.id, start_entropy));
        }
        if (self.chest.get_greatness() >= SUFFIX_UNLOCK_GREATNESS) {
            stats.apply_suffix_boost(ImplLoot::get_suffix(self.chest.id, start_entropy));
        }
        if (self.head.get_greatness() >= SUFFIX_UNLOCK_GREATNESS) {
            stats.apply_suffix_boost(ImplLoot::get_suffix(self.head.id, start_entropy));
        }
        if (self.waist.get_greatness() >= SUFFIX_UNLOCK_GREATNESS) {
            stats.apply_suffix_boost(ImplLoot::get_suffix(self.waist.id, start_entropy));
        }
        if (self.foot.get_greatness() >= SUFFIX_UNLOCK_GREATNESS) {
            stats.apply_suffix_boost(ImplLoot::get_suffix(self.foot.id, start_entropy));
        }
        if (self.hand.get_greatness() >= SUFFIX_UNLOCK_GREATNESS) {
            stats.apply_suffix_boost(ImplLoot::get_suffix(self.hand.id, start_entropy));
        }
        if (self.neck.get_greatness() >= SUFFIX_UNLOCK_GREATNESS) {
            stats.apply_suffix_boost(ImplLoot::get_suffix(self.neck.id, start_entropy));
        }
        if (self.ring.get_greatness() >= SUFFIX_UNLOCK_GREATNESS) {
            stats.apply_suffix_boost(ImplLoot::get_suffix(self.ring.id, start_entropy));
        }
        stats
    }

    // @notice gets stat boosts based on item specials
    // @param item_id The ID of the item to get stat boosts for.
    // @param start_entropy The start entropy to use for getting item specials.
    // @return Returns the stat boosts for the item.
    fn get_item_boost(item_id: u8, start_entropy: u64) -> Stats {
        let mut stats = Stats {
            strength: 0, dexterity: 0, vitality: 0, charisma: 0, intelligence: 0, wisdom: 0, luck: 0
        };
        stats.apply_suffix_boost(ImplLoot::get_suffix(item_id, start_entropy));
        stats
    }
}

const TWO_POW_21: u256 = 0x200000;
const TWO_POW_16: u256 = 0x10000;
const TWO_POW_32: u256 = 0x100000000;
const TWO_POW_48: u256 = 0x1000000000000;
const TWO_POW_64: u256 = 0x10000000000000000;
const TWO_POW_80: u256 = 0x100000000000000000000;
const TWO_POW_96: u256 = 0x1000000000000000000000000;
const TWO_POW_112: u256 = 0x10000000000000000000000000000;

// ---------------------------
// ---------- Tests ----------
// ---------------------------
#[cfg(test)]
mod tests {
    use super::{Equipment, ImplEquipment, EquipmentPacking, Item};
    use super::super::adventurer::ImplAdventurer;
    use loot::constants::ItemId;
    use adventurer::stats::Stats;
    use adventurer::item::{MAX_ITEM_XP, MAX_PACKABLE_XP, MAX_PACKABLE_ITEM_ID};
    use combat::constants::CombatEnums::Slot;

    #[test]
    #[available_gas(1447420)]
    fn test_equipment_packing() {
        let equipment = Equipment {
            weapon: Item { id: MAX_PACKABLE_ITEM_ID, xp: MAX_PACKABLE_XP },
            chest: Item { id: MAX_PACKABLE_ITEM_ID, xp: MAX_PACKABLE_XP },
            head: Item { id: MAX_PACKABLE_ITEM_ID, xp: MAX_PACKABLE_XP },
            waist: Item { id: MAX_PACKABLE_ITEM_ID, xp: MAX_PACKABLE_XP },
            foot: Item { id: MAX_PACKABLE_ITEM_ID, xp: MAX_PACKABLE_XP },
            hand: Item { id: MAX_PACKABLE_ITEM_ID, xp: MAX_PACKABLE_XP },
            neck: Item { id: MAX_PACKABLE_ITEM_ID, xp: MAX_PACKABLE_XP },
            ring: Item { id: MAX_PACKABLE_ITEM_ID, xp: MAX_PACKABLE_XP }
        };

        let packed_equipment: Equipment = EquipmentPacking::unpack(
            EquipmentPacking::pack(equipment)
        );

        assert(packed_equipment.weapon.id == equipment.weapon.id, 'wrong weapon id');
        assert(packed_equipment.weapon.xp == equipment.weapon.xp, 'wrong weapon xp');

        assert(packed_equipment.chest.id == equipment.chest.id, 'wrong chest id');
        assert(packed_equipment.chest.xp == equipment.chest.xp, 'wrong chest xp');

        assert(packed_equipment.head.id == equipment.head.id, 'wrong head id');
        assert(packed_equipment.head.xp == equipment.head.xp, 'wrong head xp');

        assert(packed_equipment.waist.id == equipment.waist.id, 'wrong waist id');
        assert(packed_equipment.waist.xp == equipment.waist.xp, 'wrong waist xp');

        assert(packed_equipment.foot.id == equipment.foot.id, 'wrong foot id');
        assert(packed_equipment.foot.xp == equipment.foot.xp, 'wrong foot xp');

        assert(packed_equipment.hand.id == equipment.hand.id, 'wrong hand id');
        assert(packed_equipment.hand.xp == equipment.hand.xp, 'wrong hand xp');

        assert(packed_equipment.neck.id == equipment.neck.id, 'wrong neck id');
        assert(packed_equipment.neck.xp == equipment.neck.xp, 'wrong neck xp');

        assert(packed_equipment.ring.id == equipment.ring.id, 'wrong ring id');
        assert(packed_equipment.ring.xp == equipment.ring.xp, 'wrong ring xp');

        let equipment = Equipment {
            weapon: Item { id: 127, xp: 511 },
            chest: Item { id: 0, xp: 0 },
            head: Item { id: 127, xp: 511 },
            waist: Item { id: 1, xp: 1 },
            foot: Item { id: 127, xp: 511 },
            hand: Item { id: 0, xp: 0 },
            neck: Item { id: 127, xp: 511 },
            ring: Item { id: 0, xp: 0 }
        };

        let packed_equipment: Equipment = EquipmentPacking::unpack(
            EquipmentPacking::pack(equipment)
        );

        assert(packed_equipment.weapon.id == equipment.weapon.id, 'wrong weapon id');
        assert(packed_equipment.weapon.xp == equipment.weapon.xp, 'wrong weapon xp');

        assert(packed_equipment.chest.id == equipment.chest.id, 'wrong chest id');
        assert(packed_equipment.chest.xp == equipment.chest.xp, 'wrong chest xp');

        assert(packed_equipment.head.id == equipment.head.id, 'wrong head id');
        assert(packed_equipment.head.xp == equipment.head.xp, 'wrong head xp');

        assert(packed_equipment.waist.id == equipment.waist.id, 'wrong waist id');
        assert(packed_equipment.waist.xp == equipment.waist.xp, 'wrong waist xp');

        assert(packed_equipment.foot.id == equipment.foot.id, 'wrong foot id');
        assert(packed_equipment.foot.xp == equipment.foot.xp, 'wrong foot xp');

        assert(packed_equipment.hand.id == equipment.hand.id, 'wrong hand id');
        assert(packed_equipment.hand.xp == equipment.hand.xp, 'wrong hand xp');

        assert(packed_equipment.neck.id == equipment.neck.id, 'wrong neck id');
        assert(packed_equipment.neck.xp == equipment.neck.xp, 'wrong neck xp');

        assert(packed_equipment.ring.id == equipment.ring.id, 'wrong ring id');
        assert(packed_equipment.ring.xp == equipment.ring.xp, 'wrong ring xp');
    }

    #[test]
    #[should_panic(expected: ('item xp pack overflow',))]
    #[available_gas(3000000)]
    fn test_pack_protection_overflow_weapon_xp() {
        EquipmentPacking::pack(
            Equipment {
                weapon: Item { id: 127, xp: MAX_PACKABLE_XP + 1 },
                chest: Item { id: 127, xp: 511 },
                head: Item { id: 127, xp: 511 },
                waist: Item { id: 127, xp: 511 },
                foot: Item { id: 127, xp: 511 },
                hand: Item { id: 127, xp: 511 },
                neck: Item { id: 127, xp: 511 },
                ring: Item { id: 127, xp: 511 }
            }
        );
    }

    #[test]
    #[should_panic(expected: ('item xp pack overflow',))]
    #[available_gas(3000000)]
    fn test_pack_protection_overflow_chest_xp() {
        EquipmentPacking::pack(
            Equipment {
                weapon: Item { id: 127, xp: 511 },
                chest: Item { id: 127, xp: MAX_PACKABLE_XP + 1 },
                head: Item { id: 127, xp: 511 },
                waist: Item { id: 127, xp: 511 },
                foot: Item { id: 127, xp: 511 },
                hand: Item { id: 127, xp: 511 },
                neck: Item { id: 127, xp: 511 },
                ring: Item { id: 127, xp: 511 }
            }
        );
    }

    #[test]
    #[should_panic(expected: ('item xp pack overflow',))]
    #[available_gas(3000000)]
    fn test_pack_protection_overflow_head_xp() {
        EquipmentPacking::pack(
            Equipment {
                weapon: Item { id: 127, xp: 511 },
                chest: Item { id: 127, xp: 511 },
                head: Item { id: 127, xp: MAX_PACKABLE_XP + 1 },
                waist: Item { id: 127, xp: 511 },
                foot: Item { id: 127, xp: 511 },
                hand: Item { id: 127, xp: 511 },
                neck: Item { id: 127, xp: 511 },
                ring: Item { id: 127, xp: 511 }
            }
        );
    }

    #[test]
    #[should_panic(expected: ('item xp pack overflow',))]
    #[available_gas(3000000)]
    fn test_pack_protection_overflow_waist_xp() {
        EquipmentPacking::pack(
            Equipment {
                weapon: Item { id: 127, xp: 511 },
                chest: Item { id: 127, xp: 511 },
                head: Item { id: 127, xp: 511 },
                waist: Item { id: 127, xp: MAX_PACKABLE_XP + 1 },
                foot: Item { id: 127, xp: 511 },
                hand: Item { id: 127, xp: 511 },
                neck: Item { id: 127, xp: 511 },
                ring: Item { id: 127, xp: 511 }
            }
        );
    }

    #[test]
    #[should_panic(expected: ('item xp pack overflow',))]
    #[available_gas(3000000)]
    fn test_pack_protection_overflow_foot_xp() {
        EquipmentPacking::pack(
            Equipment {
                weapon: Item { id: 127, xp: 511 },
                chest: Item { id: 127, xp: 511 },
                head: Item { id: 127, xp: 511 },
                waist: Item { id: 127, xp: 511 },
                foot: Item { id: 127, xp: MAX_PACKABLE_XP + 1 },
                hand: Item { id: 127, xp: 511 },
                neck: Item { id: 127, xp: 511 },
                ring: Item { id: 127, xp: 511 }
            }
        );
    }

    #[test]
    #[should_panic(expected: ('item xp pack overflow',))]
    #[available_gas(3000000)]
    fn test_pack_protection_overflow_hand_xp() {
        EquipmentPacking::pack(
            Equipment {
                weapon: Item { id: 127, xp: 511 },
                chest: Item { id: 127, xp: 511 },
                head: Item { id: 127, xp: 511 },
                waist: Item { id: 127, xp: 511 },
                foot: Item { id: 127, xp: 511 },
                hand: Item { id: 127, xp: MAX_PACKABLE_XP + 1 },
                neck: Item { id: 127, xp: 511 },
                ring: Item { id: 127, xp: 511 }
            }
        );
    }

    #[test]
    #[should_panic(expected: ('item xp pack overflow',))]
    #[available_gas(3000000)]
    fn test_pack_protection_overflow_neck_xp() {
        EquipmentPacking::pack(
            Equipment {
                weapon: Item { id: 127, xp: 511 },
                chest: Item { id: 127, xp: 511 },
                head: Item { id: 127, xp: 511 },
                waist: Item { id: 127, xp: 511 },
                foot: Item { id: 127, xp: 511 },
                hand: Item { id: 127, xp: 511 },
                neck: Item { id: 127, xp: MAX_PACKABLE_XP + 1 },
                ring: Item { id: 127, xp: 511 }
            }
        );
    }

    #[test]
    #[should_panic(expected: ('item xp pack overflow',))]
    #[available_gas(3000000)]
    fn test_pack_protection_overflow_ring_xp() {
        EquipmentPacking::pack(
            Equipment {
                weapon: Item { id: 127, xp: 511 },
                chest: Item { id: 127, xp: 511 },
                head: Item { id: 127, xp: 511 },
                waist: Item { id: 127, xp: 511 },
                foot: Item { id: 127, xp: 511 },
                hand: Item { id: 127, xp: 511 },
                neck: Item { id: 127, xp: 511 },
                ring: Item { id: 127, xp: MAX_PACKABLE_XP + 1 }
            }
        );
    }

    #[test]
    #[should_panic(expected: ('Item is not weapon',))]
    #[available_gas(90000)]
    fn test_equip_invalid_weapon() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        let item = Item { id: ItemId::DemonCrown, xp: 1 };
        // try to equip demon crown as a weapon
        // should panic with 'Item is not weapon' message
        adventurer.equipment.equip_weapon(item);
    }

    #[test]
    #[available_gas(171984)]
    fn test_equip_valid_weapon() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        let item = Item { id: ItemId::Katana, xp: 1 };
        adventurer.equipment.equip_weapon(item);
        assert(adventurer.equipment.weapon.id == ItemId::Katana, 'did not equip weapon');
        assert(adventurer.equipment.weapon.xp == 1, 'weapon xp is not 1');
    }

    #[test]
    #[should_panic(expected: ('Item is not chest armor',))]
    #[available_gas(90000)]
    fn test_equip_invalid_chest() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        // try to equip a Demon Crown as chest item
        // should panic with 'Item is not chest armor' message
        let item = Item { id: ItemId::DemonCrown, xp: 1 };
        adventurer.equipment.equip_chest_armor(item);
    }

    #[test]
    #[available_gas(171984)]
    fn test_equip_valid_chest() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        let item = Item { id: ItemId::DivineRobe, xp: 1 };
        adventurer.equipment.equip_chest_armor(item);
        assert(adventurer.equipment.chest.id == ItemId::DivineRobe, 'did not equip chest armor');
        assert(adventurer.equipment.chest.xp == 1, 'chest armor xp is not 1');
    }

    #[test]
    #[should_panic(expected: ('Item is not head armor',))]
    #[available_gas(90000)]
    fn test_equip_invalid_head() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        // try to equip a Katana as head item
        // should panic with 'Item is not head armor' message
        let item = Item { id: ItemId::Katana, xp: 1 };
        adventurer.equipment.equip_head_armor(item);
    }

    #[test]
    #[available_gas(171984)]
    fn test_equip_valid_head() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        let item = Item { id: ItemId::Crown, xp: 1 };
        adventurer.equipment.equip_head_armor(item);
        assert(adventurer.equipment.head.id == ItemId::Crown, 'did not equip head armor');
        assert(adventurer.equipment.head.xp == 1, 'head armor xp is not 1');
    }


    #[test]
    #[should_panic(expected: ('Item is not waist armor',))]
    #[available_gas(90000)]
    fn test_equip_invalid_waist() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        // try to equip a Demon Crown as waist item
        // should panic with 'Item is not waist armor' message
        let item = Item { id: ItemId::DemonCrown, xp: 1 };
        adventurer.equipment.equip_waist_armor(item);
    }

    #[test]
    #[available_gas(171984)]
    fn test_equip_valid_waist() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        let item = Item { id: ItemId::WoolSash, xp: 1 };
        adventurer.equipment.equip_waist_armor(item);
        assert(adventurer.equipment.waist.id == ItemId::WoolSash, 'did not equip waist armor');
        assert(adventurer.equipment.waist.xp == 1, 'waist armor xp is not 1');
    }

    #[test]
    #[should_panic(expected: ('Item is not foot armor',))]
    #[available_gas(90000)]
    fn test_equip_invalid_foot() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        // try to equip a Demon Crown as foot item
        // should panic with 'Item is not foot armor' message
        let item = Item { id: ItemId::DemonCrown, xp: 1 };
        adventurer.equipment.equip_foot_armor(item);
    }

    #[test]
    #[available_gas(172184)]
    fn test_equip_valid_foot() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        let item = Item { id: ItemId::SilkSlippers, xp: 1 };
        adventurer.equipment.equip_foot_armor(item);
        assert(adventurer.equipment.foot.id == ItemId::SilkSlippers, 'did not equip foot armor');
        assert(adventurer.equipment.foot.xp == 1, 'foot armor xp is not 1');
    }

    #[test]
    #[should_panic(expected: ('Item is not hand armor',))]
    #[available_gas(90000)]
    fn test_equip_invalid_hand() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        // try to equip a Demon Crown as hand item
        // should panic with 'Item is not hand armor' message
        let item = Item { id: ItemId::DemonCrown, xp: 1 };
        adventurer.equipment.equip_hand_armor(item);
    }

    #[test]
    #[available_gas(172184)]
    fn test_equip_valid_hand() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        let item = Item { id: ItemId::DivineGloves, xp: 1 };
        adventurer.equipment.equip_hand_armor(item);
        assert(adventurer.equipment.hand.id == ItemId::DivineGloves, 'did not equip hand armor');
        assert(adventurer.equipment.hand.xp == 1, 'hand armor xp is not 1');
    }

    #[test]
    #[should_panic(expected: ('Item is not necklace',))]
    #[available_gas(90000)]
    fn test_equip_invalid_neck() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        // try to equip a Demon Crown as necklace
        // should panic with 'Item is not necklace' message
        let item = Item { id: ItemId::DemonCrown, xp: 1 };
        adventurer.equipment.equip_necklace(item);
    }

    #[test]
    #[available_gas(172184)]
    fn test_equip_valid_neck() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        let item = Item { id: ItemId::Pendant, xp: 1 };
        adventurer.equipment.equip_necklace(item);
        assert(adventurer.equipment.neck.id == ItemId::Pendant, 'did not equip necklace');
        assert(adventurer.equipment.neck.xp == 1, 'necklace xp is not 1');
    }

    #[test]
    #[should_panic(expected: ('Item is not a ring',))]
    #[available_gas(90000)]
    fn test_equip_invalid_ring() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        // try to equip a Demon Crown as ring
        // should panic with 'Item is not a ring' message
        let item = Item { id: ItemId::DemonCrown, xp: 1 };
        adventurer.equipment.equip_ring(item);
    }

    #[test]
    #[available_gas(172184)]
    fn test_equip_valid_ring() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        let item = Item { id: ItemId::PlatinumRing, xp: 1 };
        adventurer.equipment.equip_ring(item);
        assert(adventurer.equipment.ring.id == ItemId::PlatinumRing, 'did not equip ring');
        assert(adventurer.equipment.ring.xp == 1, 'ring xp is not 1');
    }

    #[test]
    #[available_gas(511384)]
    fn test_drop_item() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);

        // assert starting conditions
        assert(adventurer.equipment.weapon.id == ItemId::Wand, 'weapon should be wand');
        assert(adventurer.equipment.chest.id == 0, 'chest should be 0');
        assert(adventurer.equipment.head.id == 0, 'head should be 0');
        assert(adventurer.equipment.waist.id == 0, 'waist should be 0');
        assert(adventurer.equipment.foot.id == 0, 'foot should be 0');
        assert(adventurer.equipment.hand.id == 0, 'hand should be 0');
        assert(adventurer.equipment.neck.id == 0, 'neck should be 0');
        assert(adventurer.equipment.ring.id == 0, 'ring should be 0');

        // drop equipped wand
        adventurer.equipment.drop(ItemId::Wand);
        assert(adventurer.equipment.weapon.id == 0, 'weapon should be 0');
        assert(adventurer.equipment.weapon.xp == 0, 'weapon xp should be 0');

        // instantiate additional items
        let weapon = Item { id: ItemId::Katana, xp: 1 };
        let chest = Item { id: ItemId::DivineRobe, xp: 1 };
        let head = Item { id: ItemId::Crown, xp: 1 };
        let waist = Item { id: ItemId::DemonhideBelt, xp: 1 };
        let foot = Item { id: ItemId::LeatherBoots, xp: 1 };
        let hand = Item { id: ItemId::LeatherGloves, xp: 1 };
        let neck = Item { id: ItemId::Amulet, xp: 1 };
        let ring = Item { id: ItemId::GoldRing, xp: 1 };

        // equip item
        adventurer.equipment.equip(weapon);
        adventurer.equipment.equip(chest);
        adventurer.equipment.equip(head);
        adventurer.equipment.equip(waist);
        adventurer.equipment.equip(foot);
        adventurer.equipment.equip(hand);
        adventurer.equipment.equip(neck);
        adventurer.equipment.equip(ring);

        // assert items were equipped
        assert(adventurer.equipment.weapon.id == weapon.id, 'weapon should be equipped');
        assert(adventurer.equipment.chest.id == chest.id, 'chest should be equipped');
        assert(adventurer.equipment.head.id == head.id, 'head should be equipped');
        assert(adventurer.equipment.waist.id == waist.id, 'waist should be equipped');
        assert(adventurer.equipment.foot.id == foot.id, 'foot should be equipped');
        assert(adventurer.equipment.hand.id == hand.id, 'hand should be equipped');
        assert(adventurer.equipment.neck.id == neck.id, 'neck should be equipped');
        assert(adventurer.equipment.ring.id == ring.id, 'ring should be equipped');

        // drop equipped items one by one and assert they get dropped
        adventurer.equipment.drop(weapon.id);
        assert(adventurer.equipment.weapon.id == 0, 'weapon should be 0');
        assert(adventurer.equipment.weapon.xp == 0, 'weapon xp should be 0');

        adventurer.equipment.drop(chest.id);
        assert(adventurer.equipment.chest.id == 0, 'chest should be 0');
        assert(adventurer.equipment.chest.xp == 0, 'chest xp should be 0');

        adventurer.equipment.drop(head.id);
        assert(adventurer.equipment.head.id == 0, 'head should be 0');
        assert(adventurer.equipment.head.xp == 0, 'head xp should be 0');

        adventurer.equipment.drop(waist.id);
        assert(adventurer.equipment.waist.id == 0, 'waist should be 0');
        assert(adventurer.equipment.waist.xp == 0, 'waist xp should be 0');

        adventurer.equipment.drop(foot.id);
        assert(adventurer.equipment.foot.id == 0, 'foot should be 0');
        assert(adventurer.equipment.foot.xp == 0, 'foot xp should be 0');

        adventurer.equipment.drop(hand.id);
        assert(adventurer.equipment.hand.id == 0, 'hand should be 0');
        assert(adventurer.equipment.hand.xp == 0, 'hand xp should be 0');

        adventurer.equipment.drop(neck.id);
        assert(adventurer.equipment.neck.id == 0, 'neck should be 0');
        assert(adventurer.equipment.neck.xp == 0, 'neck xp should be 0');

        adventurer.equipment.drop(ring.id);
        assert(adventurer.equipment.ring.id == 0, 'ring should be 0');
        assert(adventurer.equipment.ring.xp == 0, 'ring xp should be 0');
    }

    #[test]
    #[should_panic(expected: ('item is not equipped',))]
    #[available_gas(172984)]
    fn test_drop_item_not_equipped() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        // try to drop an item that isn't equipped
        // this should panic with 'item is not equipped'
        // the test is annotated to expect this panic
        adventurer.equipment.drop(ItemId::Crown);
    }

    #[test]
    #[available_gas(550000)]
    fn test_equip_item() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);

        // assert starting conditions
        assert(adventurer.equipment.weapon.id == 12, 'weapon should be 12');
        assert(adventurer.equipment.chest.id == 0, 'chest should be 0');
        assert(adventurer.equipment.head.id == 0, 'head should be 0');
        assert(adventurer.equipment.waist.id == 0, 'waist should be 0');
        assert(adventurer.equipment.foot.id == 0, 'foot should be 0');
        assert(adventurer.equipment.hand.id == 0, 'hand should be 0');
        assert(adventurer.equipment.neck.id == 0, 'neck should be 0');
        assert(adventurer.equipment.ring.id == 0, 'ring should be 0');

        // stage items
        let weapon = Item { id: ItemId::Katana, xp: 1 };
        let chest = Item { id: ItemId::DivineRobe, xp: 1 };
        let head = Item { id: ItemId::Crown, xp: 1 };
        let waist = Item { id: ItemId::DemonhideBelt, xp: 1 };
        let foot = Item { id: ItemId::LeatherBoots, xp: 1 };
        let hand = Item { id: ItemId::LeatherGloves, xp: 1 };
        let neck = Item { id: ItemId::Amulet, xp: 1 };
        let ring = Item { id: ItemId::GoldRing, xp: 1 };

        adventurer.equipment.equip(weapon);
        adventurer.equipment.equip(chest);
        adventurer.equipment.equip(head);
        adventurer.equipment.equip(waist);
        adventurer.equipment.equip(foot);
        adventurer.equipment.equip(hand);
        adventurer.equipment.equip(neck);
        adventurer.equipment.equip(ring);

        // assert items were added
        assert(adventurer.equipment.weapon.id == weapon.id, 'weapon should be equipped');
        assert(adventurer.equipment.chest.id == chest.id, 'chest should be equipped');
        assert(adventurer.equipment.head.id == head.id, 'head should be equipped');
        assert(adventurer.equipment.waist.id == waist.id, 'waist should be equipped');
        assert(adventurer.equipment.foot.id == foot.id, 'foot should be equipped');
        assert(adventurer.equipment.hand.id == hand.id, 'hand should be equipped');
        assert(adventurer.equipment.neck.id == neck.id, 'neck should be equipped');
        assert(adventurer.equipment.ring.id == ring.id, 'ring should be equipped');
    }

    #[test]
    #[available_gas(1000000)]
    fn test_is_equipped() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        let wand = Item { id: ItemId::Wand, xp: 1 };
        let demon_crown = Item { id: ItemId::DemonCrown, xp: 1 };

        // assert starting state
        assert(adventurer.equipment.weapon.id == wand.id, 'weapon should be wand');
        assert(adventurer.equipment.chest.id == 0, 'chest should be 0');
        assert(adventurer.equipment.head.id == 0, 'head should be 0');
        assert(adventurer.equipment.waist.id == 0, 'waist should be 0');
        assert(adventurer.equipment.foot.id == 0, 'foot should be 0');
        assert(adventurer.equipment.hand.id == 0, 'hand should be 0');
        assert(adventurer.equipment.neck.id == 0, 'neck should be 0');
        assert(adventurer.equipment.ring.id == 0, 'ring should be 0');

        // assert base case for is_equipped
        assert(adventurer.equipment.is_equipped(wand.id) == true, 'wand should be equipped');
        assert(
            adventurer.equipment.is_equipped(demon_crown.id) == false, 'demon crown is not equipped'
        );

        // stage items
        let katana = Item { id: ItemId::Katana, xp: 1 };
        let divine_robe = Item { id: ItemId::DivineRobe, xp: 1 };
        let crown = Item { id: ItemId::Crown, xp: 1 };
        let demonhide_belt = Item { id: ItemId::DemonhideBelt, xp: 1 };
        let leather_boots = Item { id: ItemId::LeatherBoots, xp: 1 };
        let leather_gloves = Item { id: ItemId::LeatherGloves, xp: 1 };
        let amulet = Item { id: ItemId::Amulet, xp: 1 };
        let gold_ring = Item { id: ItemId::GoldRing, xp: 1 };

        // Equip a katana and verify is_equipped returns true for katana and false everything else
        adventurer.equipment.equip(katana);
        assert(adventurer.equipment.is_equipped(katana.id) == true, 'weapon should be equipped');
        assert(adventurer.equipment.is_equipped(wand.id) == false, 'wand should not be equipped');
        assert(adventurer.equipment.is_equipped(crown.id) == false, 'crown should not be equipped');
        assert(
            adventurer.equipment.is_equipped(divine_robe.id) == false, 'divine robe is not equipped'
        );
        assert(
            adventurer.equipment.is_equipped(demonhide_belt.id) == false,
            'demonhide belt is not equipped'
        );
        assert(
            adventurer.equipment.is_equipped(leather_boots.id) == false,
            'leather boots is not equipped'
        );
        assert(
            adventurer.equipment.is_equipped(leather_gloves.id) == false,
            'leather gloves is not equipped'
        );
        assert(adventurer.equipment.is_equipped(amulet.id) == false, 'amulet is not equipped');
        assert(
            adventurer.equipment.is_equipped(gold_ring.id) == false, 'gold ring is not equipped'
        );

        // equip a divine robe and verify is_equipped returns true for katana and divine robe and false everything else
        adventurer.equipment.equip(divine_robe);
        assert(
            adventurer.equipment.is_equipped(divine_robe.id) == true,
            'divine robe should be equipped'
        );
        assert(adventurer.equipment.is_equipped(katana.id) == true, 'katana still equipped');
        assert(adventurer.equipment.is_equipped(crown.id) == false, 'crown should not be equipped');
        assert(
            adventurer.equipment.is_equipped(demonhide_belt.id) == false,
            'demonhide belt is not equipped'
        );
        assert(
            adventurer.equipment.is_equipped(leather_boots.id) == false,
            'leather boots is not equipped'
        );
        assert(
            adventurer.equipment.is_equipped(leather_gloves.id) == false,
            'leather gloves is not equipped'
        );
        assert(adventurer.equipment.is_equipped(amulet.id) == false, 'amulet is not equipped');
        assert(
            adventurer.equipment.is_equipped(gold_ring.id) == false, 'gold ring is not equipped'
        );

        // equip a crown and verify is_equipped returns true for katana, divine robe, and crown and false everything else
        adventurer.equipment.equip(crown);
        assert(adventurer.equipment.is_equipped(crown.id) == true, 'crown should be equipped');
        assert(
            adventurer.equipment.is_equipped(divine_robe.id) == true,
            'divine robe should be equipped'
        );
        assert(adventurer.equipment.is_equipped(katana.id) == true, 'katana still equipped');
        assert(
            adventurer.equipment.is_equipped(demonhide_belt.id) == false,
            'demonhide belt is not equipped'
        );
        assert(
            adventurer.equipment.is_equipped(leather_boots.id) == false,
            'leather boots is not equipped'
        );
        assert(
            adventurer.equipment.is_equipped(leather_gloves.id) == false,
            'leather gloves is not equipped'
        );
        assert(adventurer.equipment.is_equipped(amulet.id) == false, 'amulet is not equipped');
        assert(
            adventurer.equipment.is_equipped(gold_ring.id) == false, 'gold ring is not equipped'
        );

        // equip a demonhide belt and verify is_equipped returns true for katana, divine robe, crown, and demonhide belt and false everything else
        adventurer.equipment.equip(demonhide_belt);
        assert(
            adventurer.equipment.is_equipped(demonhide_belt.id) == true,
            'demonhide belt is equipped'
        );
        assert(adventurer.equipment.is_equipped(crown.id) == true, 'crown should be equipped');
        assert(
            adventurer.equipment.is_equipped(divine_robe.id) == true,
            'divine robe should be equipped'
        );
        assert(adventurer.equipment.is_equipped(katana.id) == true, 'katana still equipped');
        assert(
            adventurer.equipment.is_equipped(leather_boots.id) == false,
            'leather boots is not equipped'
        );
        assert(
            adventurer.equipment.is_equipped(leather_gloves.id) == false,
            'leather gloves is not equipped'
        );
        assert(adventurer.equipment.is_equipped(amulet.id) == false, 'amulet is not equipped');
        assert(
            adventurer.equipment.is_equipped(gold_ring.id) == false, 'gold ring is not equipped'
        );

        // equip leather boots and verify is_equipped returns true for katana, divine robe, crown, demonhide belt, and leather boots and false everything else
        adventurer.equipment.equip(leather_boots);
        assert(
            adventurer.equipment.is_equipped(leather_boots.id) == true, 'leather boots is equipped'
        );
        assert(
            adventurer.equipment.is_equipped(demonhide_belt.id) == true,
            'demonhide belt is equipped'
        );
        assert(adventurer.equipment.is_equipped(crown.id) == true, 'crown should be equipped');
        assert(
            adventurer.equipment.is_equipped(divine_robe.id) == true,
            'divine robe should be equipped'
        );
        assert(adventurer.equipment.is_equipped(katana.id) == true, 'katana still equipped');
        assert(
            adventurer.equipment.is_equipped(leather_gloves.id) == false,
            'leather gloves is not equipped'
        );
        assert(adventurer.equipment.is_equipped(amulet.id) == false, 'amulet is not equipped');
        assert(
            adventurer.equipment.is_equipped(gold_ring.id) == false, 'gold ring is not equipped'
        );

        // equip leather gloves and verify is_equipped returns true for katana, divine robe, crown, demonhide belt, leather boots, and leather gloves and false everything else
        adventurer.equipment.equip(leather_gloves);
        assert(
            adventurer.equipment.is_equipped(leather_gloves.id) == true,
            'leather gloves is equipped'
        );
        assert(
            adventurer.equipment.is_equipped(leather_boots.id) == true, 'leather boots is equipped'
        );
        assert(
            adventurer.equipment.is_equipped(demonhide_belt.id) == true,
            'demonhide belt is equipped'
        );
        assert(adventurer.equipment.is_equipped(crown.id) == true, 'crown should be equipped');
        assert(
            adventurer.equipment.is_equipped(divine_robe.id) == true,
            'divine robe should be equipped'
        );
        assert(adventurer.equipment.is_equipped(katana.id) == true, 'katana still equipped');
        assert(adventurer.equipment.is_equipped(amulet.id) == false, 'amulet is not equipped');
        assert(
            adventurer.equipment.is_equipped(gold_ring.id) == false, 'gold ring is not equipped'
        );

        // equip amulet and verify is_equipped returns true for katana, divine robe, crown, demonhide belt, leather boots, leather gloves, and amulet and false everything else
        adventurer.equipment.equip(amulet);
        assert(adventurer.equipment.is_equipped(amulet.id) == true, 'amulet is equipped');
        assert(
            adventurer.equipment.is_equipped(leather_gloves.id) == true,
            'leather gloves is equipped'
        );
        assert(
            adventurer.equipment.is_equipped(leather_boots.id) == true, 'leather boots is equipped'
        );
        assert(
            adventurer.equipment.is_equipped(demonhide_belt.id) == true,
            'demonhide belt is equipped'
        );
        assert(adventurer.equipment.is_equipped(crown.id) == true, 'crown should be equipped');
        assert(
            adventurer.equipment.is_equipped(divine_robe.id) == true,
            'divine robe should be equipped'
        );
        assert(adventurer.equipment.is_equipped(katana.id) == true, 'katana still equipped');
        assert(
            adventurer.equipment.is_equipped(gold_ring.id) == false, 'gold ring is not equipped'
        );

        // equip gold ring and verify is_equipped returns true for katana, divine robe, crown, demonhide belt, leather boots, leather gloves, amulet, and gold ring and false everything else
        adventurer.equipment.equip(gold_ring);
        assert(adventurer.equipment.is_equipped(gold_ring.id) == true, 'gold ring is equipped');
        assert(adventurer.equipment.is_equipped(amulet.id) == true, 'amulet is equipped');
        assert(
            adventurer.equipment.is_equipped(leather_gloves.id) == true,
            'leather gloves is equipped'
        );
        assert(
            adventurer.equipment.is_equipped(leather_boots.id) == true, 'leather boots is equipped'
        );
        assert(
            adventurer.equipment.is_equipped(demonhide_belt.id) == true,
            'demonhide belt is equipped'
        );
        assert(adventurer.equipment.is_equipped(crown.id) == true, 'crown should be equipped');
        assert(
            adventurer.equipment.is_equipped(divine_robe.id) == true,
            'divine robe should be equipped'
        );
        assert(adventurer.equipment.is_equipped(katana.id) == true, 'katana still equipped');
    }

    #[test]
    #[available_gas(198584)]
    fn test_increase_item_xp_at_slot_gas() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);
        adventurer.equipment.increase_item_xp_at_slot(Slot::Weapon(()), 1);
    }

    #[test]
    #[available_gas(385184)]
    fn test_increase_item_xp_at_slot() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);

        // assert starting conditions
        assert(adventurer.equipment.weapon.xp == 0, 'weapon should start with 0xp');
        assert(adventurer.equipment.chest.xp == 0, 'chest should start with 0xp');
        assert(adventurer.equipment.head.xp == 0, 'head should start with 0xp');
        assert(adventurer.equipment.waist.xp == 0, 'waist should start with 0xp');
        assert(adventurer.equipment.foot.xp == 0, 'foot should start with 0xp');
        assert(adventurer.equipment.hand.xp == 0, 'hand should start with 0xp');
        assert(adventurer.equipment.neck.xp == 0, 'neck should start with 0xp');
        assert(adventurer.equipment.ring.xp == 0, 'ring should start with 0xp');

        adventurer.equipment.increase_item_xp_at_slot(Slot::Weapon(()), 1);
        assert(adventurer.equipment.weapon.xp == 1, 'weapon should have 1xp');

        adventurer.equipment.increase_item_xp_at_slot(Slot::Chest(()), 1);
        assert(adventurer.equipment.chest.xp == 1, 'chest should have 1xp');

        adventurer.equipment.increase_item_xp_at_slot(Slot::Head(()), 1);
        assert(adventurer.equipment.head.xp == 1, 'head should have 1xp');

        adventurer.equipment.increase_item_xp_at_slot(Slot::Waist(()), 1);
        assert(adventurer.equipment.waist.xp == 1, 'waist should have 1xp');

        adventurer.equipment.increase_item_xp_at_slot(Slot::Foot(()), 1);
        assert(adventurer.equipment.foot.xp == 1, 'foot should have 1xp');

        adventurer.equipment.increase_item_xp_at_slot(Slot::Hand(()), 1);
        assert(adventurer.equipment.hand.xp == 1, 'hand should have 1xp');

        adventurer.equipment.increase_item_xp_at_slot(Slot::Neck(()), 1);
        assert(adventurer.equipment.neck.xp == 1, 'neck should have 1xp');

        adventurer.equipment.increase_item_xp_at_slot(Slot::Ring(()), 1);
        assert(adventurer.equipment.ring.xp == 1, 'ring should have 1xp');
    }

    #[test]
    #[available_gas(198084)]
    fn test_increase_item_xp_at_slot_max() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);

        assert(adventurer.equipment.weapon.xp == 0, 'weapon should start with 0xp');
        adventurer.equipment.increase_item_xp_at_slot(Slot::Weapon(()), 65535);
        assert(adventurer.equipment.weapon.xp == MAX_ITEM_XP, 'weapon should have max xp');
    }

    #[test]
    #[available_gas(198084)]
    fn test_increase_item_xp_at_slot_zero() {
        let mut adventurer = ImplAdventurer::new(ItemId::Wand);

        assert(adventurer.equipment.weapon.xp == 0, 'weapon should start with 0xp');
        adventurer.equipment.increase_item_xp_at_slot(Slot::Weapon(()), 0);
        assert(adventurer.equipment.weapon.xp == 0, 'weapon should still have 0xp');
    }

    #[test]
    #[available_gas(61360)]
    fn test_get_item_boost_gas() {
        ImplEquipment::get_item_boost(1, 0);
    }

    #[test]
    fn test_get_item_boost() {
        let item_id = ItemId::Wand;
        let mut start_entropy = 0;
        let stats = ImplEquipment::get_item_boost(item_id, start_entropy);

        assert(stats.strength == 0, 'STR should be 0');
        assert(stats.dexterity == 0, 'DEX should be 0');
        assert(stats.vitality == 0, 'VIT should be 0');
        assert(stats.charisma == 0, 'CHA should be 0');
        assert(stats.intelligence == 3, 'INT should be 3');
        assert(stats.wisdom == 0, 'WIS should be 0');
        assert(stats.luck == 0, 'LUK should be 0');

        start_entropy = 1;
        let stats = ImplEquipment::get_item_boost(item_id, start_entropy);
        assert(stats.strength == 0, 'STR should be 0');
        assert(stats.dexterity == 1, 'DEX should be 1');
        assert(stats.vitality == 2, 'VIT should be 2');
        assert(stats.charisma == 0, 'CHA should be 0');
        assert(stats.intelligence == 0, 'INT should be 0');
        assert(stats.wisdom == 0, 'WIS should be 0');
        assert(stats.luck == 0, 'LUK should be 0');
    }
}
