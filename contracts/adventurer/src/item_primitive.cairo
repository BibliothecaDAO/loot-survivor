use option::OptionTrait;
use traits::{TryInto, Into};
use pack::{pack::{Packing, rshift_split}, constants::pow};

#[derive(Drop, Copy, PartialEq, Serde)] // 21 bits
struct ItemPrimitive {
    id: u8, // 7 bits
    xp: u16, // 9 bits
    // this is set as the items are found/purchased
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
    fn new_item(item_id: u8) -> ItemPrimitive { 
        ItemPrimitive { id: item_id, xp: 0, metadata: 0 }
    }
}

#[test]
#[available_gas(9000)]
fn test_new_item() {
    // zero case
    let item = IItemPrimitive::new_item(0);
    assert(item.id == 0, 'id should be 0');
    assert(item.xp == 0, 'xp should be 0');
    assert(item.metadata == 0, 'metadata should be 0');

    // base case
    let item = IItemPrimitive::new_item(1);
    assert(item.id == 1, 'id should be 1');
    assert(item.xp == 0, 'xp should be 0');
    assert(item.metadata == 0, 'metadata should be 0');

    // max u8 case
    let item = IItemPrimitive::new_item(255);
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
