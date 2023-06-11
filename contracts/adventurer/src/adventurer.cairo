use core::serde::Serde;
use integer::{
    U128IntoFelt252, Felt252IntoU256, Felt252TryIntoU64, U256TryIntoFelt252, u256_from_felt252,
};
use traits::{TryInto, Into};
use option::OptionTrait;
use debug::PrintTrait;

use pack::pack::{pack_value, unpack_value, U256TryIntoU32, U256TryIntoU16, U256TryIntoU8};
use pack::constants::{MASK_16, pow, MASK_8, MASK_BOOL};


#[derive(Drop, Copy)]
struct Item {
    id: u8,
    xp: u8,
    isEquipped: u8,
}

#[derive(Drop, Copy)]
struct AdventurerMeta {
    name: u32,
    home_realm: u8,
    race: u8,
    seed: u8,
}

#[derive(Drop, Copy)]
struct Adventurer {
    health: u16, // health
    xp: u16, // xp 
    // Adventurers have 7 Stats
    // 3 Physical
    strength: u8,
    dexterity: u8,
    vitality: u8,
    // 3 Mental
    intelligence: u8,
    wisdom: u8,
    charisma: u8,
    // 1 Meta Physical
    luck: u8,
    // // Adventurers can carry a maximum of 16 items
    item1: Item, // starter weapon (wand) 
    item2: Item, // first item purchased (katana)
    item3: Item, // second item purchased
    item4: Item, // third item purchased
    item5: Item,
    item6: Item,
    item7: Item,
    item8: Item,
    // Adventurer in battle will have a beast assigned to them
    beast_health: u8,
    // Denotes if the adventurer has a stat 
    stat_upgrade_available: u8,
}


fn pack_adventurer(adventurer: Adventurer) -> felt252 {
    let mut packed = 0;

    packed = packed | pack_value(adventurer.health.into(), pow::TWO_POW_224);
    packed = packed | pack_value(adventurer.xp.into(), pow::TWO_POW_208);
    packed = packed | pack_value(adventurer.strength.into(), pow::TWO_POW_200);
    packed = packed | pack_value(adventurer.dexterity.into(), pow::TWO_POW_192);
    packed = packed | pack_value(adventurer.vitality.into(), pow::TWO_POW_184);
    packed = packed | pack_value(adventurer.intelligence.into(), pow::TWO_POW_176);
    packed = packed | pack_value(adventurer.wisdom.into(), pow::TWO_POW_168);
    packed = packed | pack_value(adventurer.charisma.into(), pow::TWO_POW_160);
    packed = packed | pack_value(adventurer.luck.into(), pow::TWO_POW_152);
    packed = packed | pack_value(adventurer.item1.id.into(), pow::TWO_POW_144);
    packed = packed | pack_value(adventurer.item1.xp.into(), pow::TWO_POW_136);
    packed = packed | pack_value(adventurer.item1.isEquipped.into(), pow::TWO_POW_135);
    packed = packed | pack_value(adventurer.item2.id.into(), pow::TWO_POW_127);
    packed = packed | pack_value(adventurer.item2.xp.into(), pow::TWO_POW_119);
    packed = packed | pack_value(adventurer.item2.isEquipped.into(), pow::TWO_POW_118);
    packed = packed | pack_value(adventurer.item3.id.into(), pow::TWO_POW_110);
    packed = packed | pack_value(adventurer.item3.xp.into(), pow::TWO_POW_102);
    packed = packed | pack_value(adventurer.item3.isEquipped.into(), pow::TWO_POW_101);
    packed = packed | pack_value(adventurer.item4.id.into(), pow::TWO_POW_93);
    packed = packed | pack_value(adventurer.item4.xp.into(), pow::TWO_POW_85);
    packed = packed | pack_value(adventurer.item4.isEquipped.into(), pow::TWO_POW_84);
    packed = packed | pack_value(adventurer.item5.id.into(), pow::TWO_POW_76);
    packed = packed | pack_value(adventurer.item5.xp.into(), pow::TWO_POW_68);
    packed = packed | pack_value(adventurer.item5.isEquipped.into(), pow::TWO_POW_67);
    packed = packed | pack_value(adventurer.item6.id.into(), pow::TWO_POW_59);
    packed = packed | pack_value(adventurer.item6.xp.into(), pow::TWO_POW_51);
    packed = packed | pack_value(adventurer.item6.isEquipped.into(), pow::TWO_POW_50);
    packed = packed | pack_value(adventurer.item7.id.into(), pow::TWO_POW_42);
    packed = packed | pack_value(adventurer.item7.xp.into(), pow::TWO_POW_34);
    packed = packed | pack_value(adventurer.item7.isEquipped.into(), pow::TWO_POW_33);
    packed = packed | pack_value(adventurer.item8.id.into(), pow::TWO_POW_25);
    packed = packed | pack_value(adventurer.item8.xp.into(), pow::TWO_POW_17);
    packed = packed | pack_value(adventurer.item8.isEquipped.into(), pow::TWO_POW_16);
    packed = packed | pack_value(adventurer.beast_health.into(), pow::TWO_POW_8);
    packed = packed | pack_value(adventurer.stat_upgrade_available.into(), pow::TWO_POW_7);

    packed.try_into().unwrap()
}


fn unpack_adventurer(packed: felt252) -> Adventurer {
    let packed = packed.into();

    Adventurer {
        health: U256TryIntoU16::try_into(unpack_value(packed, pow::TWO_POW_224, MASK_16)).unwrap(),
        xp: U256TryIntoU16::try_into(unpack_value(packed, pow::TWO_POW_208, MASK_16)).unwrap(),
        strength: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_200, MASK_8)).unwrap(),
        dexterity: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_192, MASK_8)).unwrap(),
        vitality: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_184, MASK_8)).unwrap(),
        intelligence: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_176, MASK_8))
            .unwrap(),
        wisdom: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_168, MASK_8)).unwrap(),
        charisma: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_160, MASK_8)).unwrap(),
        luck: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_152, MASK_8)).unwrap(),
        item1: Item {
            id: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_144, MASK_8)).unwrap(),
            xp: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_136, MASK_8)).unwrap(),
            isEquipped: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_135, MASK_BOOL))
                .unwrap(),
            }, item2: Item {
            id: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_127, MASK_8)).unwrap(),
            xp: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_119, MASK_8)).unwrap(),
            isEquipped: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_118, MASK_BOOL))
                .unwrap(),
            }, item3: Item {
            id: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_110, MASK_8)).unwrap(),
            xp: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_102, MASK_8)).unwrap(),
            isEquipped: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_101, MASK_BOOL))
                .unwrap(),
            }, item4: Item {
            id: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_93, MASK_8)).unwrap(),
            xp: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_85, MASK_8)).unwrap(),
            isEquipped: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_84, MASK_BOOL))
                .unwrap(),
            }, item5: Item {
            id: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_76, MASK_8)).unwrap(),
            xp: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_68, MASK_8)).unwrap(),
            isEquipped: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_67, MASK_BOOL))
                .unwrap(),
            }, item6: Item {
            id: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_59, MASK_8)).unwrap(),
            xp: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_51, MASK_8)).unwrap(),
            isEquipped: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_50, MASK_BOOL))
                .unwrap(),
            }, item7: Item {
            id: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_42, MASK_8)).unwrap(),
            xp: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_34, MASK_8)).unwrap(),
            isEquipped: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_33, MASK_BOOL))
                .unwrap(),
            }, item8: Item {
            id: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_25, MASK_8)).unwrap(),
            xp: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_17, MASK_8)).unwrap(),
            isEquipped: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_16, MASK_BOOL))
                .unwrap(),
        },
        beast_health: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_8, MASK_8))
            .unwrap(),
        stat_upgrade_available: U256TryIntoU8::try_into(
            unpack_value(packed, pow::TWO_POW_7, MASK_BOOL)
        )
            .unwrap(),
    }
}


#[test]
#[available_gas(5000000)]
fn test_adventurer() {
    let adventurer = Adventurer {
        health: 100,
        xp: 100,
        strength: 10,
        dexterity: 10,
        vitality: 10,
        intelligence: 10,
        wisdom: 10,
        charisma: 10,
        luck: 10,
        item1: Item {
            id: 1, xp: 1, isEquipped: 0, 
            }, item2: Item {
            id: 2, xp: 2, isEquipped: 0, 
            }, item3: Item {
            id: 3, xp: 3, isEquipped: 0, 
            }, item4: Item {
            id: 4, xp: 4, isEquipped: 0, 
            }, item5: Item {
            id: 5, xp: 5, isEquipped: 0, 
            }, item6: Item {
            id: 6, xp: 6, isEquipped: 0, 
            }, item7: Item {
            id: 7, xp: 7, isEquipped: 0, 
            }, item8: Item {
            id: 8, xp: 8, isEquipped: 0, 
        }, beast_health: 100, stat_upgrade_available: 0,
    };

    let packed = pack_adventurer(adventurer);
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
    assert(adventurer.item1.id == unpacked.item1.id, 'item1.id');
    assert(adventurer.item1.xp == unpacked.item1.xp, 'item1.xp');
    assert(adventurer.item1.isEquipped == unpacked.item1.isEquipped, 'item1.isEquipped');
    assert(adventurer.item2.id == unpacked.item2.id, 'item2.id');
    assert(adventurer.item2.xp == unpacked.item2.xp, 'item2.xp');
    assert(adventurer.item2.isEquipped == unpacked.item2.isEquipped, 'item2.isEquipped');
    assert(adventurer.item3.id == unpacked.item3.id, 'item3.id');
    assert(adventurer.item3.xp == unpacked.item3.xp, 'item3.xp');
    assert(adventurer.item3.isEquipped == unpacked.item3.isEquipped, 'item3.isEquipped');
    assert(adventurer.item4.id == unpacked.item4.id, 'item4.id');
    assert(adventurer.item4.xp == unpacked.item4.xp, 'item4.xp');
    assert(adventurer.item4.isEquipped == unpacked.item4.isEquipped, 'item4.isEquipped');
    assert(adventurer.item5.id == unpacked.item5.id, 'item5.id');
    assert(adventurer.item5.xp == unpacked.item5.xp, 'item5.xp');
    assert(adventurer.item5.isEquipped == unpacked.item5.isEquipped, 'item5.isEquipped');
    assert(adventurer.item6.id == unpacked.item6.id, 'item6.id');
    assert(adventurer.item6.xp == unpacked.item6.xp, 'item6.xp');
    assert(adventurer.item6.isEquipped == unpacked.item6.isEquipped, 'item6.isEquipped');
    assert(adventurer.item7.id == unpacked.item7.id, 'item7.id');
    assert(adventurer.item7.xp == unpacked.item7.xp, 'item7.xp');
    assert(adventurer.item7.isEquipped == unpacked.item7.isEquipped, 'item7.isEquipped');
    assert(adventurer.item8.id == unpacked.item8.id, 'item8.id');
    assert(adventurer.item8.xp == unpacked.item8.xp, 'item8.xp');
    assert(adventurer.item8.isEquipped == unpacked.item8.isEquipped, 'item8.isEquipped');
    assert(adventurer.beast_health == unpacked.beast_health, 'beast_health');
    assert(
        adventurer.stat_upgrade_available == unpacked.stat_upgrade_available,
        'stat_upgrade_available'
    );
}

