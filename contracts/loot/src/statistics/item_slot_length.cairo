use array::ArrayTrait;
use lootitems::statistics::item_tier;
use lootitems::statistics::constants::{ItemNamePrefix, ItemId, ItemIndex, ItemSlotLength};
use combat::constants::CombatEnums::Tier;
use combat::constants::CombatEnums::Slot;

fn get(slot: Slot) -> u8 {
    match slot {
        Slot::None(()) => 0,
        Slot::Weapon(()) => ItemSlotLength::SlotItemsLengthWeapon,
        Slot::Chest(()) => ItemSlotLength::SlotItemsLengthChest,
        Slot::Head(()) => ItemSlotLength::SlotItemsLengthHead,
        Slot::Waist(()) => ItemSlotLength::SlotItemsLengthWaist,
        Slot::Foot(()) => ItemSlotLength::SlotItemsLengthFoot,
        Slot::Hand(()) => ItemSlotLength::SlotItemsLengthHand,
        Slot::Neck(()) => ItemSlotLength::SlotItemsLengthHand,
        Slot::Ring(()) => ItemSlotLength::SlotItemsLengthRing,
    }
}

