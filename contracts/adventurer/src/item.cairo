use core::{option::OptionTrait, starknet::StorePacking, traits::{TryInto, Into}};
use integer::{u16_sqrt, u16_overflowing_add};
use loot::loot::{ItemId};

const MAX_GREATNESS: u8 = 20;
const MAX_PACKABLE_ITEM_ID: u8 = 127;
const MAX_PACKABLE_XP: u16 = 511;
const MAX_ITEM_XP: u16 = 400;

#[derive(Drop, Copy, PartialEq, Serde)]
struct Item { // 21 storage bits
    id: u8, // 7 bits
    xp: u16, // 9 bits
}

impl ItemPacking of StorePacking<Item, felt252> {
    fn pack(value: Item) -> felt252 {
        assert(value.id <= MAX_PACKABLE_ITEM_ID, 'item id pack overflow');
        assert(value.xp <= MAX_PACKABLE_XP, 'item xp pack overflow');
        (value.id.into() + value.xp.into() * TWO_POW_7).try_into().unwrap()
    }

    fn unpack(value: felt252) -> Item {
        let packed = value.into();
        let (packed, id) = integer::U256DivRem::div_rem(packed, TWO_POW_7.try_into().unwrap());
        let (_, xp) = integer::U256DivRem::div_rem(packed, TWO_POW_9.try_into().unwrap());

        Item { id: id.try_into().unwrap(), xp: xp.try_into().unwrap() }
    }
}

#[generate_trait]
impl ImplItem of IItemPrimitive {
    // @notice creates a new Item with the given id
    // @param item_id the id of the item
    // @return the new Item
    fn new(item_id: u8) -> Item {
        Item { id: item_id, xp: 0 }
    }

    // @notice checks if the item is a jewelery
    // @param self the Item to check
    // @return bool: true if the item is a jewelery, false otherwise
    fn is_jewlery(self: Item) -> bool {
        if (self.id == ItemId::BronzeRing) {
            true
        } else if (self.id == ItemId::SilverRing) {
            true
        } else if (self.id == ItemId::GoldRing) {
            true
        } else if (self.id == ItemId::PlatinumRing) {
            true
        } else if (self.id == ItemId::TitaniumRing) {
            true
        } else if (self.id == ItemId::Necklace) {
            true
        } else if (self.id == ItemId::Amulet) {
            true
        } else if (self.id == ItemId::Pendant) {
            true
        } else {
            false
        }
    }

    // @notice increases the xp of an item
    // @param self the Item to increase the xp of
    // @param amount the amount to increase the xp by
    // @return (u8, u8): the previous level and the new level
    #[inline(always)]
    fn increase_xp(ref self: Item, amount: u16) -> (u8, u8) {
        let previous_level = self.get_greatness();
        if (u16_overflowing_add(self.xp, amount).is_ok()) {
            if (self.xp + amount > MAX_ITEM_XP) {
                self.xp = MAX_ITEM_XP;
            } else {
                self.xp += amount;
            }
        } else {
            self.xp = MAX_ITEM_XP;
        }
        let new_level = self.get_greatness();
        (previous_level, new_level)
    }

    // @notice gets the greatness of an item
    // @param self the Item to get the greatness of
    // @return u8: the greatness of the item
    #[inline(always)]
    fn get_greatness(self: Item) -> u8 {
        if (self.xp == 0) {
            1
        } else {
            let level = u16_sqrt(self.xp);
            if (level > MAX_GREATNESS) {
                MAX_GREATNESS
            } else {
                level
            }
        }
    }
}

const TWO_POW_7: u256 = 0x80;
const TWO_POW_9: u256 = 0x200;

// ---------------------------
// ---------- Tests ----------
// ---------------------------
#[cfg(test)]
mod tests {
    use adventurer::item::{
        Item, ImplItem, ItemPacking, IItemPrimitive, MAX_PACKABLE_XP, MAX_PACKABLE_ITEM_ID
    };
    use loot::constants::{ItemId};

    #[test]
    #[available_gas(54370)]
    fn test_item_packing_gas() {
        ItemPacking::unpack(
            ItemPacking::pack(Item { id: MAX_PACKABLE_ITEM_ID, xp: MAX_PACKABLE_XP })
        );
    }

    #[test]
    fn test_item_packing() {
        // zero case
        let item = Item { id: 0, xp: 0 };
        let unpacked = ItemPacking::unpack(ItemPacking::pack(item));
        assert(item.id == unpacked.id, 'id should be the same');
        assert(item.xp == unpacked.xp, 'xp should be the same');

        let item = Item { id: 1, xp: 2 };
        let unpacked = ItemPacking::unpack(ItemPacking::pack(item));
        assert(item.id == unpacked.id, 'id should be the same');
        assert(item.xp == unpacked.xp, 'xp should be the same');

        // max value case
        let item = Item { id: MAX_PACKABLE_ITEM_ID, xp: MAX_PACKABLE_XP };
        let unpacked = ItemPacking::unpack(ItemPacking::pack(item));
        assert(item.id == unpacked.id, 'id should be the same');
        assert(item.xp == unpacked.xp, 'xp should be the same');
    }

    #[test]
    #[should_panic(expected: ('item id pack overflow',))]
    fn test_item_packing_id_overflow() {
        // attempt to save item with id above pack limit
        ItemPacking::unpack(
            ItemPacking::pack(Item { id: MAX_PACKABLE_ITEM_ID + 1, xp: MAX_PACKABLE_XP })
        );
    }

    #[test]
    #[should_panic(expected: ('item xp pack overflow',))]
    fn test_item_packing_xp_overflow() {
        // attempt to save item with xp above pack limit
        ItemPacking::unpack(
            ItemPacking::pack(Item { id: MAX_PACKABLE_ITEM_ID, xp: MAX_PACKABLE_XP + 1 })
        );
    }

    #[test]
    #[available_gas(1893950)]
    fn test_is_jewlery_gas() {
        assert(!ImplItem::new(ItemId::Book).is_jewlery(), 'should not be jewlery');
    }

    #[test]
    #[available_gas(1893950)]
    fn test_is_jewlery() {
        let mut item_index = 1;
        loop {
            if item_index == 102 {
                break;
            }

            if (item_index == ItemId::BronzeRing
                || item_index == ItemId::SilverRing
                || item_index == ItemId::GoldRing
                || item_index == ItemId::PlatinumRing
                || item_index == ItemId::TitaniumRing
                || item_index == ItemId::Necklace
                || item_index == ItemId::Amulet
                || item_index == ItemId::Pendant) {
                assert(ImplItem::new(item_index).is_jewlery(), 'should be jewlery')
            } else {
                assert(!ImplItem::new(item_index).is_jewlery(), 'should not be jewlery');
            }

            item_index += 1;
        };
    }

    #[test]
    #[available_gas(9000)]
    fn test_new_item() {
        // zero case
        let item = IItemPrimitive::new(0);
        assert(item.id == 0, 'id should be 0');
        assert(item.xp == 0, 'xp should be 0');

        // base case
        let item = IItemPrimitive::new(1);
        assert(item.id == 1, 'id should be 1');
        assert(item.xp == 0, 'xp should be 0');

        // max u8 case
        let item = IItemPrimitive::new(255);
        assert(item.id == 255, 'id should be 255');
        assert(item.xp == 0, 'xp should be 0');
    }

    #[test]
    #[available_gas(70320)]
    fn test_get_greatness_gas() {
        let mut item = Item { id: 1, xp: 400 };
        item.get_greatness();
    }

    #[test]
    #[available_gas(70320)]
    fn test_get_greatness() {
        let mut item = Item { id: 1, xp: 0 };
        // test 0 case (should be level 1)
        let greatness = item.get_greatness();
        assert(greatness == 1, 'greatness should be 1');

        // test level 1
        item.xp = 1;
        let greatness = item.get_greatness();
        assert(greatness == 1, 'greatness should be 1');

        // test level 2
        item.xp = 4;
        let greatness = item.get_greatness();
        assert(greatness == 2, 'greatness should be 2');

        // test level 3
        item.xp = 9;
        let greatness = item.get_greatness();
        assert(greatness == 3, 'greatness should be 3');

        // test level 4
        item.xp = 16;
        let greatness = item.get_greatness();
        assert(greatness == 4, 'greatness should be 4');

        // test level 5
        item.xp = 25;
        let greatness = item.get_greatness();
        assert(greatness == 5, 'greatness should be 5');

        // test level 6
        item.xp = 36;
        let greatness = item.get_greatness();
        assert(greatness == 6, 'greatness should be 6');

        // test level 7
        item.xp = 49;
        let greatness = item.get_greatness();
        assert(greatness == 7, 'greatness should be 7');

        // test level 8
        item.xp = 64;
        let greatness = item.get_greatness();
        assert(greatness == 8, 'greatness should be 8');

        // test level 9
        item.xp = 81;
        let greatness = item.get_greatness();
        assert(greatness == 9, 'greatness should be 9');

        // test level 10
        item.xp = 100;
        let greatness = item.get_greatness();
        assert(greatness == 10, 'greatness should be 10');

        // test level 11
        item.xp = 121;
        let greatness = item.get_greatness();
        assert(greatness == 11, 'greatness should be 11');

        // test level 12
        item.xp = 144;
        let greatness = item.get_greatness();
        assert(greatness == 12, 'greatness should be 12');

        // test level 13
        item.xp = 169;
        let greatness = item.get_greatness();
        assert(greatness == 13, 'greatness should be 13');

        // test level 14
        item.xp = 196;
        let greatness = item.get_greatness();
        assert(greatness == 14, 'greatness should be 14');

        // test level 15
        item.xp = 225;
        let greatness = item.get_greatness();
        assert(greatness == 15, 'greatness should be 15');

        // test level 16
        item.xp = 256;
        let greatness = item.get_greatness();
        assert(greatness == 16, 'greatness should be 16');

        // test level 17
        item.xp = 289;
        let greatness = item.get_greatness();
        assert(greatness == 17, 'greatness should be 17');

        // test level 18
        item.xp = 324;
        let greatness = item.get_greatness();
        assert(greatness == 18, 'greatness should be 18');

        // test level 19
        item.xp = 361;
        let greatness = item.get_greatness();
        assert(greatness == 19, 'greatness should be 19');

        // test level 20
        item.xp = 400;
        let greatness = item.get_greatness();
        assert(greatness == 20, 'greatness should be 20');

        // test overflow / max u16
        item.xp = 65535;
        let greatness = item.get_greatness();
        assert(greatness == 20, 'greatness should be 20');
    }
}
