use option::OptionTrait;
use traits::{TryInto, Into};
use pack::{pack::{Packing, rshift_split}, constants::pow};
use lootitems::loot::{ItemId};

#[derive(Drop, Copy, PartialEq, Serde)] // 21 bits
struct ItemPrimitive {
    id: u8, // 7 bits
    xp: u16, // 9 bits
    metadata: u8, // 5 bits
}

impl ItemPrimitivePacking of Packing<ItemPrimitive> {
    fn pack(self: ItemPrimitive) -> felt252 {
        (self.id.into() + self.xp.into() * pow::TWO_POW_7 + self.metadata.into() * pow::TWO_POW_16)
            .try_into()
            .expect('pack ItemPrimitive')
    }

    fn unpack(packed: felt252) -> ItemPrimitive {
        let packed = packed.into();
        let (packed, id) = rshift_split(packed, pow::TWO_POW_7);
        let (packed, xp) = rshift_split(packed, pow::TWO_POW_9);
        let (_, metadata) = rshift_split(packed, pow::TWO_POW_5);

        ItemPrimitive {
            id: id.try_into().expect('unpack ItemPrimitive id'),
            xp: xp.try_into().expect('unpack ItemPrimitive xp'),
            metadata: metadata.try_into().expect('unpack ItemPrimitive metadata')
        }
    }

    // TODO: add overflow pack protection
    fn overflow_pack_protection(self: ItemPrimitive) -> ItemPrimitive {
        self
    }
}

#[generate_trait]
impl ImplItemPrimitive of IItemPrimitive {
    // @notice creates a new ItemPrimitive with the given id
    // @param item_id the id of the item
    // @return the new ItemPrimitive
    fn new(item_id: u8) -> ItemPrimitive {
        ItemPrimitive { id: item_id, xp: 0, metadata: 0 }
    }

    #[inline(always)]
    fn is_jewlery(self: ItemPrimitive) -> bool {
        if (self.id == ItemId::BronzeRing) {
            return true;
        } else if (self.id == ItemId::SilverRing) {
            return true;
        } else if (self.id == ItemId::GoldRing) {
            return true;
        } else if (self.id == ItemId::PlatinumRing) {
            return true;
        } else if (self.id == ItemId::TitaniumRing) {
            return true;
        } else if (self.id == ItemId::Necklace) {
            return true;
        } else if (self.id == ItemId::Amulet) {
            return true;
        } else if (self.id == ItemId::Pendant) {
            return true;
        } else {
            return false;
        }
    }
}

// ---------------------------
// ---------- Tests ----------
// ---------------------------
#[cfg(test)]
mod tests {
    use survivor::item_primitive::{
        ItemPrimitive, ImplItemPrimitive, ItemPrimitivePacking, IItemPrimitive
    };
    use lootitems::constants::{ItemId};

    #[test]
    #[available_gas(1893950)]
    fn test_is_jewlery_gas() {
        assert(!ImplItemPrimitive::new(101).is_jewlery(), 'should not be jewlery');
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
                assert(ImplItemPrimitive::new(item_index).is_jewlery(), 'should be jewlery')
            } else {
                assert(!ImplItemPrimitive::new(item_index).is_jewlery(), 'should not be jewlery');
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
        assert(item.metadata == 0, 'metadata should be 0');

        // base case
        let item = IItemPrimitive::new(1);
        assert(item.id == 1, 'id should be 1');
        assert(item.xp == 0, 'xp should be 0');
        assert(item.metadata == 0, 'metadata should be 0');

        // max u8 case
        let item = IItemPrimitive::new(255);
        assert(item.id == 255, 'id should be 255');
        assert(item.xp == 0, 'xp should be 0');
        assert(item.metadata == 0, 'metadata should be 0');
    }

    #[test]
    #[available_gas(500000)]
    fn test_item_primitive_packing() {
        let item = ItemPrimitive { id: 1, xp: 2, metadata: 3 };

        let packed = item.pack();
        let unpacked = ItemPrimitivePacking::unpack(packed);

        assert(item.id == unpacked.id, 'id should be the same');
        assert(item.xp == unpacked.xp, 'xp should be the same');
        assert(item.metadata == unpacked.metadata, 'metadata should be the same');

        // max value case
        let item = ItemPrimitive { id: 127, xp: 511, metadata: 31 };

        let packed = item.pack();
        let unpacked = ItemPrimitivePacking::unpack(packed);
        assert(item.id == unpacked.id, 'id should be the same');
        assert(item.xp == unpacked.xp, 'xp should be the same');
        assert(item.metadata == unpacked.metadata, 'metadata should be the same');

        // overflow case
        let item = ItemPrimitive { id: 128, xp: 512, metadata: 32 };
        let packed = item.pack();
        let unpacked = ItemPrimitivePacking::unpack(packed);
        assert(unpacked.id == 0, 'id should overflow to 0');
        assert(unpacked.xp == 1, 'xp should overflow to 1');
        assert(unpacked.metadata == 1, 'metadata should overflow to 1');
    }
}
