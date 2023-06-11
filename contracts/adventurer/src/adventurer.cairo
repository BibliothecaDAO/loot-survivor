use core::serde::Serde;
use integer::{
    U128IntoFelt252, Felt252IntoU256, Felt252TryIntoU64, U256TryIntoFelt252, u256_from_felt252,
};
use traits::{TryInto, Into};
use option::OptionTrait;
use debug::PrintTrait;

use pack::pack::{pack_value, unpack_value, U256TryIntoU32, U256TryIntoU16, U256TryIntoU8};
use pack::constants::{MASK_16, pow, MASK_8, MASK_BOOL, mask};


#[derive(Drop, Copy)] // 24 bits
struct Item {
    id: u8, // 7 bits
    xp: u16, // 12 bits
    metadata: u8, // 5 bits 
}

#[derive(Drop, Copy)]
struct ItemMeta {
    id: u8, // 7 bits
    name_prefix: u8, // 7 bits
    name_suffix: u8, // 5 bits
    item_suffix: u8, // 4 bit
}

#[derive(Drop, Copy)]
struct ItemMetaStorageOne {
    item_1: ItemMeta,
    item_2: ItemMeta,
    item_3: ItemMeta,
    item_4: ItemMeta,
    item_5: ItemMeta,
    item_6: ItemMeta,
    item_7: ItemMeta,
    item_8: ItemMeta,
    item_9: ItemMeta,
    item_10: ItemMeta,
}

#[derive(Drop, Copy)]
struct ItemMetaStorageTwo {
    item_11: ItemMeta,
    item_12: ItemMeta,
    item_13: ItemMeta,
    item_14: ItemMeta,
    item_15: ItemMeta,
    item_16: ItemMeta,
    item_17: ItemMeta,
    item_18: ItemMeta,
    item_19: ItemMeta,
    item_20: ItemMeta,
    item_21: ItemMeta,
}

#[derive(Drop, Copy)]
struct Bag {
    spare_item_1: Item, // club
    spare_item_2: Item, // club
    spare_item_3: Item, // club
    spare_item_4: Item, // club
    spare_item_5: Item, // club
    spare_item_6: Item, // club
    spare_item_7: Item, // club
    spare_item_8: Item, // club
    spare_item_9: Item, // club
    spare_item_10: Item, // club
    spare_item_11: Item, // club
    spare_item_12: Item, // club
    spare_item_13: Item, // club
}

#[derive(Drop, Copy)]
struct AdventurerMeta {
    name: u32,
    home_realm: u8,
    race: u8
}

#[derive(Drop, Copy)]
struct Adventurer {
    health: u16, // 10 bits     
    xp: u16, // 16 bits
    // Adventurers have 7 Stats
    // Physical
    strength: u8, // 5 bits
    dexterity: u8, //  5 bits
    vitality: u8, //  5 bits
    // Mental
    intelligence: u8, //  5 bits
    wisdom: u8, //  5 bits
    charisma: u8, //  5 bits
    // Meta Physical
    luck: u8, //  5 bits
    // equipped
    weapon: Item, // 24 bits
    chest: Item, // 24 bits
    head: Item, // 24 bits
    waist: Item, // 24 bits
    foot: Item, // 24 bits
    hand: Item, // 24 bits
    neck: Item, // 24 bits
    ring: Item, // 24 bits
    // Beast health
    beast_health: u8,
    // Denotes if the adventurer has a stat 
    stat_upgrade_available: u8,
}


fn pack_adventurer(adventurer: Adventurer) -> felt252 {
    let mut packed = 0;

    packed = packed | pack_value(adventurer.health.into(), pow::TWO_POW_242);
    packed = packed | pack_value(adventurer.xp.into(), pow::TWO_POW_228);
    packed = packed | pack_value(adventurer.strength.into(), pow::TWO_POW_223);
    packed = packed | pack_value(adventurer.dexterity.into(), pow::TWO_POW_218);
    packed = packed | pack_value(adventurer.vitality.into(), pow::TWO_POW_213);
    packed = packed | pack_value(adventurer.intelligence.into(), pow::TWO_POW_208);
    packed = packed | pack_value(adventurer.wisdom.into(), pow::TWO_POW_203);
    packed = packed | pack_value(adventurer.charisma.into(), pow::TWO_POW_198);
    packed = packed | pack_value(adventurer.luck.into(), pow::TWO_POW_193);

    packed = packed | pack_value(adventurer.weapon.id.into(), pow::TWO_POW_186);
    packed = packed | pack_value(adventurer.weapon.xp.into(), pow::TWO_POW_175);
    packed = packed | pack_value(adventurer.weapon.metadata.into(), pow::TWO_POW_170);

    packed = packed | pack_value(adventurer.chest.id.into(), pow::TWO_POW_163);
    packed = packed | pack_value(adventurer.chest.xp.into(), pow::TWO_POW_152);
    packed = packed | pack_value(adventurer.chest.metadata.into(), pow::TWO_POW_147);

    packed = packed | pack_value(adventurer.head.id.into(), pow::TWO_POW_140);
    packed = packed | pack_value(adventurer.head.xp.into(), pow::TWO_POW_129);
    packed = packed | pack_value(adventurer.head.metadata.into(), pow::TWO_POW_124);

    packed = packed | pack_value(adventurer.waist.id.into(), pow::TWO_POW_117);
    packed = packed | pack_value(adventurer.waist.xp.into(), pow::TWO_POW_106);
    packed = packed | pack_value(adventurer.waist.metadata.into(), pow::TWO_POW_101);

    packed = packed | pack_value(adventurer.foot.id.into(), pow::TWO_POW_94);
    packed = packed | pack_value(adventurer.foot.xp.into(), pow::TWO_POW_83);
    packed = packed | pack_value(adventurer.foot.metadata.into(), pow::TWO_POW_78);

    packed = packed | pack_value(adventurer.hand.id.into(), pow::TWO_POW_71);
    packed = packed | pack_value(adventurer.hand.xp.into(), pow::TWO_POW_60);
    packed = packed | pack_value(adventurer.hand.metadata.into(), pow::TWO_POW_55);

    packed = packed | pack_value(adventurer.neck.id.into(), pow::TWO_POW_48);
    packed = packed | pack_value(adventurer.neck.xp.into(), pow::TWO_POW_37);
    packed = packed | pack_value(adventurer.neck.metadata.into(), pow::TWO_POW_32);

    packed = packed | pack_value(adventurer.ring.id.into(), pow::TWO_POW_25);
    packed = packed | pack_value(adventurer.ring.xp.into(), pow::TWO_POW_14);
    packed = packed | pack_value(adventurer.ring.metadata.into(), pow::TWO_POW_9);

    packed = packed | pack_value(adventurer.beast_health.into(), pow::TWO_POW_1);
    packed = packed | pack_value(adventurer.stat_upgrade_available.into(), 1);

    packed.try_into().unwrap()
}


fn unpack_adventurer(packed: felt252) -> Adventurer {
    let packed = packed.into();

    Adventurer {
        health: U256TryIntoU16::try_into(unpack_value(packed, pow::TWO_POW_242, mask::MASK_9))
            .unwrap(),
        xp: U256TryIntoU16::try_into(unpack_value(packed, pow::TWO_POW_228, mask::MASK_15))
            .unwrap(),
        strength: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_223, mask::MASK_5))
            .unwrap(),
        dexterity: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_218, mask::MASK_5))
            .unwrap(),
        vitality: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_213, mask::MASK_5))
            .unwrap(),
        intelligence: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_208, mask::MASK_5))
            .unwrap(),
        wisdom: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_203, mask::MASK_5))
            .unwrap(),
        charisma: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_198, mask::MASK_5))
            .unwrap(),
        luck: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_193, mask::MASK_5))
            .unwrap(),
        weapon: Item {
            id: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_186, mask::MASK_7))
                .unwrap(),
            xp: U256TryIntoU16::try_into(unpack_value(packed, pow::TWO_POW_175, mask::MASK_11))
                .unwrap(),
            metadata: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_170, mask::MASK_5))
                .unwrap(),
            }, chest: Item {
            id: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_163, mask::MASK_7))
                .unwrap(),
            xp: U256TryIntoU16::try_into(unpack_value(packed, pow::TWO_POW_152, mask::MASK_11))
                .unwrap(),
            metadata: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_147, mask::MASK_5))
                .unwrap(),
            }, head: Item {
            id: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_140, mask::MASK_7))
                .unwrap(),
            xp: U256TryIntoU16::try_into(unpack_value(packed, pow::TWO_POW_129, mask::MASK_11))
                .unwrap(),
            metadata: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_124, mask::MASK_5))
                .unwrap(),
            }, waist: Item {
            id: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_117, mask::MASK_7))
                .unwrap(),
            xp: U256TryIntoU16::try_into(unpack_value(packed, pow::TWO_POW_106, mask::MASK_11))
                .unwrap(),
            metadata: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_101, mask::MASK_5))
                .unwrap(),
            }, foot: Item {
            id: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_94, mask::MASK_7))
                .unwrap(),
            xp: U256TryIntoU16::try_into(unpack_value(packed, pow::TWO_POW_83, mask::MASK_11))
                .unwrap(),
            metadata: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_78, mask::MASK_5))
                .unwrap(),
            }, hand: Item {
            id: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_71, mask::MASK_7))
                .unwrap(),
            xp: U256TryIntoU16::try_into(unpack_value(packed, pow::TWO_POW_60, mask::MASK_11))
                .unwrap(),
            metadata: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_55, mask::MASK_5))
                .unwrap(),
            }, neck: Item {
            id: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_48, mask::MASK_7))
                .unwrap(),
            xp: U256TryIntoU16::try_into(unpack_value(packed, pow::TWO_POW_37, mask::MASK_11))
                .unwrap(),
            metadata: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_32, mask::MASK_5))
                .unwrap(),
            }, ring: Item {
            id: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_25, mask::MASK_7))
                .unwrap(),
            xp: U256TryIntoU16::try_into(unpack_value(packed, pow::TWO_POW_14, mask::MASK_11))
                .unwrap(),
            metadata: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_9, mask::MASK_5))
                .unwrap(),
        },
        beast_health: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_1, MASK_8))
            .unwrap(),
        stat_upgrade_available: U256TryIntoU8::try_into(unpack_value(packed, 1, MASK_BOOL))
            .unwrap(),
    }
}


#[test]
#[available_gas(5000000)]
fn test_adventurer() {
    let adventurer = Adventurer {
        health: 511,
        xp: 32767,
        strength: 31,
        dexterity: 31,
        vitality: 31,
        intelligence: 31,
        wisdom: 31,
        charisma: 31,
        luck: 31,
        weapon: Item {
            id: 100, xp: 2047, metadata: 1, 
            }, chest: Item {
            id: 99, xp: 2047, metadata: 2, 
            }, head: Item {
            id: 98, xp: 2047, metadata: 3, 
            }, waist: Item {
            id: 87, xp: 2047, metadata: 4, 
            }, foot: Item {
            id: 78, xp: 2047, metadata: 5, 
            }, hand: Item {
            id: 34, xp: 2047, metadata: 6, 
            }, neck: Item {
            id: 32, xp: 2047, metadata: 7, 
            }, ring: Item {
            id: 1, xp: 2047, metadata: 8, 
        }, beast_health: 100, stat_upgrade_available: 0,
    };

    let unpacked = unpack_adventurer(pack_adventurer(adventurer));

    assert(adventurer.health == unpacked.health, 'health');
    assert(adventurer.xp == unpacked.xp, 'xp');
    assert(adventurer.strength == unpacked.strength, 'strength');
    assert(adventurer.dexterity == unpacked.dexterity, 'dexterity');
    assert(adventurer.vitality == unpacked.vitality, 'vitality');
    assert(adventurer.intelligence == unpacked.intelligence, 'intelligence');
    assert(adventurer.wisdom == unpacked.wisdom, 'wisdom');
    assert(adventurer.charisma == unpacked.charisma, 'charisma');
    assert(adventurer.luck == unpacked.luck, 'luck');
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

