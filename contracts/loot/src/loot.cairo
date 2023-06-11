use traits::{TryInto, Into};
use option::OptionTrait;
use debug::PrintTrait;

use core::clone::Clone;
use array::ArrayTrait;

use lootitems::statistics::item_tier;
use lootitems::statistics::item_slot;
use lootitems::statistics::item_type;
use lootitems::statistics::constants;

use pack::pack::{pack_value, unpack_value, U256TryIntoU32, U256TryIntoU8};
use pack::constants::{pow, mask};

#[derive(Copy, Drop, Clone)]
struct Loot {
    tier: u8,
    item_type: u8,
    slot: u8,
}

trait ItemTrait {
    fn get(id: u8) -> Loot;
    fn tier(id: u8) -> u8;
    fn item_type(id: u8) -> u8;
    fn slot(id: u8) -> u8;
    fn pack(loot: Loot) -> felt252;
    fn unpack(packed: felt252) -> Loot;
}

impl ItemStats of ItemTrait {
    fn get(id: u8) -> Loot {
        Loot {
            tier: ItemStats::tier(id),
            item_type: ItemStats::item_type(id),
            slot: ItemStats::slot(id),
        }
    }
    fn tier(id: u8) -> u8 {
        return item_tier::get(id);
    }
    fn item_type(id: u8) -> u8 {
        return item_type::get(id);
    }
    fn slot(id: u8) -> u8 {
        return item_slot::get(id);
    }
    fn pack(loot: Loot) -> felt252 {
        let mut packed = 0;

        packed = packed | pack_value(loot.tier.into(), pow::TWO_POW_180);
        packed = packed | pack_value(loot.item_type.into(), pow::TWO_POW_63);
        packed = packed | pack_value(loot.slot.into(), 1);

        packed.try_into().unwrap()
    }
    fn unpack(packed: felt252) -> Loot {
        let packed = packed.into();

        Loot {
            tier: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_180, mask::MASK_16))
                .unwrap(),
            item_type: U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_63, mask::MASK_16))
                .unwrap(),
            slot: U256TryIntoU8::try_into(unpack_value(packed, 1, mask::MASK_16)).unwrap(),
        }
    }
}

#[test]
#[available_gas(100000000)]
fn test() {
    let lootItem = Loot { tier: 1, item_type: 3, slot: 4 };

    let packed = ItemStats::pack(lootItem);
    let unpacked = ItemStats::unpack(packed);

    assert(lootItem.tier == unpacked.tier, 'tier');
    assert(lootItem.item_type == unpacked.item_type, 'item_type');
    assert(lootItem.slot == unpacked.slot, 'slot');
}
// #[test]
// #[available_gas(30000000)]
// fn test_get_item() {
//     let katana_id = constants::ItemId::Katana;
//     let katana_item = ItemStats::get(katana_id);
//     assert(katana_item.tier == 1, 'katana is T1');
//     assert(katana_item.item_type == 2, 'katana is blade');
//     assert(katana_item.slot == 1, 'katana is weapon');

//     let pendant_id = constants::ItemId::Pendant;
//     let pendant_item = ItemStats::get(pendant_id);
//     assert(pendant_item.tier == 1, 'pendant is T1');
//     assert(pendant_item.item_type == 4, 'pendant is neck jewlery');
//     assert(pendant_item.slot == 7, 'pendant is neck slot');

//     let necklace_id = constants::ItemId::Necklace;
//     let necklace_item = ItemStats::get(necklace_id);
//     assert(necklace_item.tier == 1, 'necklace is T1');
//     assert(necklace_item.item_type == 4, 'necklace is neck jewlery');
//     assert(necklace_item.slot == 7, 'necklace is neck slot');

//     let amulet_id = constants::ItemId::Amulet;
//     let amulet_item = ItemStats::get(amulet_id);
//     assert(amulet_item.tier == 1, 'amulet is T1');
//     assert(amulet_item.item_type == 4, 'amulet is neck jewlery');
//     assert(amulet_item.slot == 7, 'amulet is neck slot');

//     let silver_ring_id = constants::ItemId::SilverRing;
//     let silver_ring_item = ItemStats::get(silver_ring_id);
//     assert(silver_ring_item.tier == 2, 'silver ring is T2');
//     assert(silver_ring_item.item_type == 5, 'silver ring is a ring');
//     assert(silver_ring_item.slot == 8, 'silver ring is ring slot');

//     let bronze_ring_id = constants::ItemId::BronzeRing;
//     let bronze_ring_item = ItemStats::get(bronze_ring_id);
//     assert(bronze_ring_item.tier == 3, 'bronze ring is T3');
//     assert(bronze_ring_item.item_type == 5, 'bronze ring is ring');
//     assert(bronze_ring_item.slot == 8, 'bronze ring is ring slot');

//     let platinum_ring_id = constants::ItemId::PlatinumRing;
//     let platinum_ring_item = ItemStats::get(platinum_ring_id);
//     assert(platinum_ring_item.tier == 1, 'platinum ring is T1');
//     assert(platinum_ring_item.item_type == 5, 'platinum ring is ring');
//     assert(platinum_ring_item.slot == 8, 'platinum ring is ring slot');

//     let titanium_ring_id = constants::ItemId::TitaniumRing;
//     let titanium_ring_item = ItemStats::get(titanium_ring_id);
//     assert(titanium_ring_item.tier == 1, 'titanium ring is T1');
//     assert(titanium_ring_item.item_type == 5, 'titanium ring is ring');
//     assert(titanium_ring_item.slot == 8, 'titanium ring is ring slot');

//     let gold_ring_id = constants::ItemId::GoldRing;
//     let gold_ring_item = ItemStats::get(gold_ring_id);
//     assert(gold_ring_item.tier == 1, 'gold ring is T1');
//     assert(gold_ring_item.item_type == 5, 'gold ring is ring');
//     assert(gold_ring_item.slot == 8, 'gold ring is ring slow');

//     let ghost_wand_id = constants::ItemId::GhostWand;
//     let ghost_wand_item = ItemStats::get(ghost_wand_id);
//     assert(ghost_wand_item.tier == 2, 'ghost wand is T2');
//     assert(ghost_wand_item.item_type == 1, 'ghost wand is magical');
//     assert(ghost_wand_item.slot == 1, 'ghost wand is weapon');

//     let grave_wand_id = constants::ItemId::GraveWand;
//     let grave_wand_item = ItemStats::get(grave_wand_id);
//     assert(grave_wand_item.tier == 3, 'grave wand is T3');
//     assert(grave_wand_item.item_type == 1, 'grave wand is magical');
//     assert(grave_wand_item.slot == 1, 'grave wand is weapon');

//     let bone_wand_id = constants::ItemId::BoneWand;
//     let bone_wand_item = ItemStats::get(bone_wand_id);
//     assert(bone_wand_item.tier == 4, 'bone wand is T4');
//     assert(bone_wand_item.item_type == 1, 'bone wand is magical');
//     assert(bone_wand_item.slot == 1, 'bone wand is weapon');

//     let wand_id = constants::ItemId::Wand;
//     let wand_item = ItemStats::get(wand_id);
//     assert(wand_item.tier == 5, 'wand is T5');
//     assert(wand_item.item_type == 1, 'wand is magical');
//     assert(wand_item.slot == 1, 'wand is weapon');

//     let grimoire_id = constants::ItemId::Grimoire;
//     let grimoire_item = ItemStats::get(grimoire_id);
//     assert(grimoire_item.tier == 2, 'grimoire is T2');
//     assert(grimoire_item.item_type == 1, 'grimoire is magical');
//     assert(grimoire_item.slot == 1, 'grimoire is weapon');

//     let chronicle_id = constants::ItemId::Chronicle;
//     let chronicle_item = ItemStats::get(chronicle_id);
//     assert(chronicle_item.tier == 3, 'chronicle is T3');
//     assert(chronicle_item.item_type == 1, 'chronicle is magical');
//     assert(chronicle_item.slot == 1, 'chronicle is weapon');

//     let tome_id = constants::ItemId::Tome;
//     let tome_item = ItemStats::get(tome_id);
//     assert(tome_item.tier == 4, 'tome is T4');
//     assert(tome_item.item_type == 1, 'tome is magical');
//     assert(tome_item.slot == 1, 'tome is weapon');

//     let book_id = constants::ItemId::Book;
//     let book_item = ItemStats::get(book_id);
//     assert(book_item.tier == 5, 'book is T5');
//     assert(book_item.item_type == 1, 'book is magical');
//     assert(book_item.slot == 1, 'book is weapon');

//     let divine_robe_id = constants::ItemId::DivineRobe;
//     let divine_robe_item = ItemStats::get(divine_robe_id);
//     assert(divine_robe_item.tier == 1, 'divine robe is T1');
//     assert(divine_robe_item.item_type == 1, 'divine robe is cloth');
//     assert(divine_robe_item.slot == 2, 'divine robe is chest armor');

//     let silk_robe_id = constants::ItemId::SilkRobe;
//     let silk_robe_item = ItemStats::get(silk_robe_id);
//     assert(silk_robe_item.tier == 2, 'silk robe is T2');
//     assert(silk_robe_item.item_type == 1, 'silk robe is cloth');
//     assert(silk_robe_item.slot == 2, 'silk robe is chest armor');

//     let linen_robe_id = constants::ItemId::LinenRobe;
//     let linen_robe_item = ItemStats::get(linen_robe_id);
//     assert(linen_robe_item.tier == 3, 'linen robe is T3');
//     assert(linen_robe_item.item_type == 1, 'linen robe is cloth');
//     assert(linen_robe_item.slot == 2, 'linen robe is chest armor');

//     let robe_id = constants::ItemId::Robe;
//     let robe_item = ItemStats::get(robe_id);
//     assert(robe_item.tier == 4, 'robe is T4');
//     assert(robe_item.item_type == 1, 'robe is cloth');
//     assert(robe_item.slot == 2, 'robe is chest armor');

//     let shirt_id = constants::ItemId::Shirt;
//     let shirt_item = ItemStats::get(shirt_id);
//     assert(shirt_item.tier == 5, 'shirt is T5');
//     assert(shirt_item.item_type == 1, 'shirt is cloth');
//     assert(shirt_item.slot == 2, 'shirt is chest armor');

//     let crown_id = constants::ItemId::Crown;
//     let crown_item = ItemStats::get(crown_id);
//     assert(crown_item.tier == 1, 'crown is T1');
//     assert(crown_item.item_type == 1, 'crown is cloth');
//     assert(crown_item.slot == 3, 'crown is head armor');

//     let divine_hood_id = constants::ItemId::DivineHood;
//     let divine_hood_item = ItemStats::get(divine_hood_id);
//     assert(divine_hood_item.tier == 2, 'divine hood is T2');
//     assert(divine_hood_item.item_type == 1, 'divine hood is cloth');
//     assert(divine_hood_item.slot == 3, 'divine hood is head armor');

//     let silk_hood_id = constants::ItemId::SilkHood;
//     let silk_hood_item = ItemStats::get(silk_hood_id);
//     assert(silk_hood_item.tier == 3, 'silk hood is T3');
//     assert(silk_hood_item.item_type == 1, 'silk hood is cloth');
//     assert(silk_hood_item.slot == 3, 'silk hood is head armor');

//     let linen_hood_id = constants::ItemId::LinenHood;
//     let linen_hood_item = ItemStats::get(linen_hood_id);
//     assert(linen_hood_item.tier == 4, 'linen hood is T4');
//     assert(linen_hood_item.item_type == 1, 'linen hood is cloth');
//     assert(linen_hood_item.slot == 3, 'linen hood is head armor');

//     let hood_id = constants::ItemId::Hood;
//     let hood_item = ItemStats::get(hood_id);
//     assert(hood_item.tier == 5, 'hood is T5');
//     assert(hood_item.item_type == 1, 'hood is cloth');
//     assert(hood_item.slot == 3, 'hood is head armor');

//     let brightsilk_sash_id = constants::ItemId::BrightsilkSash;
//     let brightsilk_sash_item = ItemStats::get(brightsilk_sash_id);
//     assert(brightsilk_sash_item.tier == 1, 'brightsilk sash is T1');
//     assert(brightsilk_sash_item.item_type == 1, 'brightsilk sash is cloth');
//     assert(brightsilk_sash_item.slot == 4, 'brightsilk sash is waist armor');

//     let silk_sash_id = constants::ItemId::SilkSash;
//     let silk_sash_item = ItemStats::get(silk_sash_id);
//     assert(silk_sash_item.tier == 2, 'silk sash is T2');
//     assert(silk_sash_item.item_type == 1, 'silk sash is cloth');
//     assert(silk_sash_item.slot == 4, 'silk sash is waist armor');

//     let wool_sash_id = constants::ItemId::WoolSash;
//     let wool_sash_item = ItemStats::get(wool_sash_id);
//     assert(wool_sash_item.tier == 3, 'wool sash is T3');
//     assert(wool_sash_item.item_type == 1, 'wool sash is cloth');
//     assert(wool_sash_item.slot == 4, 'wool sash is waist armor');

//     let linen_sash_id = constants::ItemId::LinenSash;
//     let linen_sash_item = ItemStats::get(linen_sash_id);
//     assert(linen_sash_item.tier == 4, 'linen sash is T4');
//     assert(linen_sash_item.item_type == 1, 'linen sash is cloth');
//     assert(linen_sash_item.slot == 4, 'linen sash is waist armor');

//     let sash_id = constants::ItemId::Sash;
//     let sash_item = ItemStats::get(sash_id);
//     assert(sash_item.tier == 5, 'sash is T5');
//     assert(sash_item.item_type == 1, 'sash is cloth');
//     assert(sash_item.slot == 4, 'sash is waist armor');

//     let divine_slippers_id = constants::ItemId::DivineSlippers;
//     let divine_slippers_item = ItemStats::get(divine_slippers_id);
//     assert(divine_slippers_item.tier == 1, 'divine slippers are T1');
//     assert(divine_slippers_item.item_type == 1, 'divine slippers are cloth');
//     assert(divine_slippers_item.slot == 5, 'divine slippers are foot armor');

//     let silk_slippers_id = constants::ItemId::SilkSlippers;
//     let silk_slippers_item = ItemStats::get(silk_slippers_id);
//     assert(silk_slippers_item.tier == 2, 'silk slippers are T2');
//     assert(silk_slippers_item.item_type == 1, 'silk slippers are cloth');
//     assert(silk_slippers_item.slot == 5, 'silk slippers are foot armor');

//     let wool_shoes_id = constants::ItemId::WoolShoes;
//     let wool_shoes_item = ItemStats::get(wool_shoes_id);
//     assert(wool_shoes_item.tier == 3, 'wool shoes are T3');
//     assert(wool_shoes_item.item_type == 1, 'wool shoes are cloth');
//     assert(wool_shoes_item.slot == 5, 'wool shoes are foot armor');

//     let linen_shoes_id = constants::ItemId::LinenShoes;
//     let linen_shoes_item = ItemStats::get(linen_shoes_id);
//     assert(linen_shoes_item.tier == 4, 'linen shoes are T4');
//     assert(linen_shoes_item.item_type == 1, 'linen shoes are cloth');
//     assert(linen_shoes_item.slot == 5, 'linen shoes are foot armor');

//     let shoes_id = constants::ItemId::Shoes;
//     let shoes_item = ItemStats::get(shoes_id);
//     assert(shoes_item.tier == 5, 'shoes are T5');
//     assert(shoes_item.item_type == 1, 'shoes are cloth');
//     assert(shoes_item.slot == 5, 'shoes are foot armor');

//     let divine_gloves_id = constants::ItemId::DivineGloves;
//     let divine_gloves_item = ItemStats::get(divine_gloves_id);
//     assert(divine_gloves_item.tier == constants::ItemTier::DivineGloves, 'divine gloves are T1');
//     assert(
//         divine_gloves_item.item_type == constants::ItemType::DivineGloves, 'divine gloves are cloth'
//     );
//     assert(
//         divine_gloves_item.slot == constants::ItemSlot::DivineGloves, 'divine gloves are hand armor'
//     );

//     let silk_gloves_id = constants::ItemId::SilkGloves;
//     let silk_gloves_item = ItemStats::get(silk_gloves_id);
//     assert(silk_gloves_item.tier == constants::ItemTier::SilkGloves, 'silk gloves are T2');
//     assert(silk_gloves_item.item_type == constants::ItemType::SilkGloves, 'silk gloves are cloth');
//     assert(silk_gloves_item.slot == constants::ItemSlot::SilkGloves, 'silk gloves are hand armor');

//     let wool_gloves_id = constants::ItemId::WoolGloves;
//     let wool_gloves_item = ItemStats::get(wool_gloves_id);
//     assert(wool_gloves_item.tier == constants::ItemTier::WoolGloves, 'wool gloves are T3');
//     assert(wool_gloves_item.item_type == constants::ItemType::WoolGloves, 'wool gloves are cloth');
//     assert(wool_gloves_item.slot == constants::ItemSlot::WoolGloves, 'wool gloves are hand armor');

//     let linen_gloves_id = constants::ItemId::LinenGloves;
//     let linen_gloves_item = ItemStats::get(linen_gloves_id);
//     assert(linen_gloves_item.tier == constants::ItemTier::LinenGloves, 'linen gloves are T4');
//     assert(
//         linen_gloves_item.item_type == constants::ItemType::LinenGloves,
//         'linen gloves are hand armor'
//     );
//     assert(linen_gloves_item.slot == constants::ItemSlot::LinenGloves, 'linen gloves are cloth');

//     let gloves_id = constants::ItemId::Gloves;
//     let gloves_item = ItemStats::get(gloves_id);
//     assert(gloves_item.tier == constants::ItemTier::Gloves, 'gloves are T5');
//     assert(gloves_item.item_type == constants::ItemType::Gloves, 'gloves are cloth');
//     assert(gloves_item.slot == constants::ItemSlot::Gloves, 'gloves are hand armor');

//     let katana_id = constants::ItemId::Katana;
//     let katana_item = ItemStats::get(katana_id);
//     assert(katana_item.tier == constants::ItemTier::Katana, 'katana is T1');
//     assert(katana_item.item_type == constants::ItemType::Katana, 'katana is blade');
//     assert(katana_item.slot == constants::ItemSlot::Katana, 'katana is weapon');

//     let falchion_id = constants::ItemId::Falchion;
//     let falchion_item = ItemStats::get(falchion_id);
//     assert(falchion_item.tier == constants::ItemTier::Falchion, 'falchion is T2');
//     assert(falchion_item.item_type == constants::ItemType::Falchion, 'falchion is blade');
//     assert(falchion_item.slot == constants::ItemSlot::Falchion, 'falchion is weapon');

//     let scimitar_id = constants::ItemId::Scimitar;
//     let scimitar_item = ItemStats::get(scimitar_id);
//     assert(scimitar_item.tier == constants::ItemTier::Scimitar, 'scimitar is T3');
//     assert(scimitar_item.item_type == constants::ItemType::Scimitar, 'scimitar is blade');
//     assert(scimitar_item.slot == constants::ItemSlot::Scimitar, 'scimitar is weapon');

//     let long_sword_id = constants::ItemId::LongSword;
//     let long_sword_item = ItemStats::get(long_sword_id);
//     assert(long_sword_item.tier == constants::ItemTier::LongSword, 'long sword is T4');
//     assert(long_sword_item.item_type == constants::ItemType::LongSword, 'long sword is blade');
//     assert(long_sword_item.slot == constants::ItemSlot::LongSword, 'long sword is weapon');

//     let short_sword_id = constants::ItemId::ShortSword;
//     let short_sword_item = ItemStats::get(short_sword_id);
//     assert(short_sword_item.tier == constants::ItemTier::ShortSword, 'short sword is T5');
//     assert(short_sword_item.item_type == constants::ItemType::ShortSword, 'short sword is blade');
//     assert(short_sword_item.slot == constants::ItemSlot::ShortSword, 'short sword is weapon');

//     let demon_husk_id = constants::ItemId::DemonHusk;
//     let demon_husk_item = ItemStats::get(demon_husk_id);
//     assert(demon_husk_item.tier == constants::ItemTier::DemonHusk, 'demon husk is T1');
//     assert(demon_husk_item.item_type == constants::ItemType::DemonHusk, 'demon husk is hide');
//     assert(demon_husk_item.slot == constants::ItemSlot::DemonHusk, 'demon husk is chest armor');

//     let dragonskin_armor_id = constants::ItemId::DragonskinArmor;
//     let dragonskin_armor_item = ItemStats::get(dragonskin_armor_id);
//     assert(
//         dragonskin_armor_item.tier == constants::ItemTier::DragonskinArmor, 'dragonskin armor is T2'
//     );
//     assert(
//         dragonskin_armor_item.item_type == constants::ItemType::DragonskinArmor,
//         'dragonskin armor is hide'
//     );
//     assert(
//         dragonskin_armor_item.slot == constants::ItemSlot::DragonskinArmor,
//         'dragonskin armor is chest armor'
//     );

//     let studded_leather_armor_id = constants::ItemId::StuddedLeatherArmor;
//     let studded_leather_armor_item = ItemStats::get(studded_leather_armor_id);
//     assert(
//         studded_leather_armor_item.tier == constants::ItemTier::StuddedLeatherArmor,
//         'studded leather armor is T3'
//     );
//     assert(
//         studded_leather_armor_item.item_type == constants::ItemType::StuddedLeatherArmor,
//         'studded leather armor is hide'
//     );
//     assert(
//         studded_leather_armor_item.slot == constants::ItemSlot::StuddedLeatherArmor,
//         'studded leather armor is chest'
//     );

//     let hard_leather_armor_id = constants::ItemId::HardLeatherArmor;
//     let hard_leather_armor_item = ItemStats::get(hard_leather_armor_id);
//     assert(
//         hard_leather_armor_item.tier == constants::ItemTier::HardLeatherArmor,
//         'hard leather armor is T4'
//     );
//     assert(
//         hard_leather_armor_item.item_type == constants::ItemType::HardLeatherArmor,
//         'hard leather armor is hide'
//     );
//     assert(
//         hard_leather_armor_item.slot == constants::ItemSlot::HardLeatherArmor,
//         'hard leather armor is chest'
//     );

//     let leather_armor_id = constants::ItemId::LeatherArmor;
//     let leather_armor_item = ItemStats::get(leather_armor_id);
//     assert(leather_armor_item.tier == constants::ItemTier::LeatherArmor, 'leather armor is T5');
//     assert(
//         leather_armor_item.item_type == constants::ItemType::LeatherArmor, 'leather armor is hide'
//     );
//     assert(
//         leather_armor_item.slot == constants::ItemSlot::LeatherArmor, 'leather armor is chest armor'
//     );

//     let demon_crown_id = constants::ItemId::DemonCrown;
//     let demon_crown_item = ItemStats::get(demon_crown_id);
//     assert(demon_crown_item.tier == constants::ItemTier::DemonCrown, 'demon crown is T1');
//     assert(demon_crown_item.item_type == constants::ItemType::DemonCrown, 'demon crown is hide');
//     assert(demon_crown_item.slot == constants::ItemSlot::DemonCrown, 'demon crown is head armor');

//     let dragons_crown_id = constants::ItemId::DragonsCrown;
//     let dragons_crown_item = ItemStats::get(dragons_crown_id);
//     assert(dragons_crown_item.tier == constants::ItemTier::DragonsCrown, 'dragons crown is T2');
//     assert(
//         dragons_crown_item.item_type == constants::ItemType::DragonsCrown, 'dragons crown is hide'
//     );
//     assert(
//         dragons_crown_item.slot == constants::ItemSlot::DragonsCrown, 'dragons crown is head armor'
//     );

//     let war_cap_id = constants::ItemId::WarCap;
//     let war_cap_item = ItemStats::get(war_cap_id);
//     assert(war_cap_item.tier == constants::ItemTier::WarCap, 'war cap is T3');
//     assert(war_cap_item.item_type == constants::ItemType::WarCap, 'war cap is hide');
//     assert(war_cap_item.slot == constants::ItemSlot::WarCap, 'war cap is head armor');

//     let leather_cap_id = constants::ItemId::LeatherCap;
//     let leather_cap_item = ItemStats::get(leather_cap_id);
//     assert(leather_cap_item.tier == constants::ItemTier::LeatherCap, 'leather cap is T4');
//     assert(leather_cap_item.item_type == constants::ItemType::LeatherCap, 'leather cap is hide');
//     assert(leather_cap_item.slot == constants::ItemSlot::LeatherCap, 'leather cap is head armor');

//     let cap_id = constants::ItemId::Cap;
//     let cap_item = ItemStats::get(cap_id);
//     assert(cap_item.tier == constants::ItemTier::Cap, 'cap is T5');
//     assert(cap_item.item_type == constants::ItemType::Cap, 'cap is hide');
//     assert(cap_item.slot == constants::ItemSlot::Cap, 'cap is head armor');

//     let demonhide_belt_id = constants::ItemId::DemonhideBelt;
//     let demonhide_belt_item = ItemStats::get(demonhide_belt_id);
//     assert(demonhide_belt_item.tier == constants::ItemTier::DemonhideBelt, 'demonhide belt is T1');
//     assert(
//         demonhide_belt_item.item_type == constants::ItemType::DemonhideBelt,
//         'demonhide belt is hide'
//     );
//     assert(
//         demonhide_belt_item.slot == constants::ItemSlot::DemonhideBelt,
//         'demonhide belt is waist armor'
//     );

//     let dragonskin_belt_id = constants::ItemId::DragonskinBelt;
//     let dragonskin_belt_item = ItemStats::get(dragonskin_belt_id);
//     assert(
//         dragonskin_belt_item.tier == constants::ItemTier::DragonskinBelt, 'dragonskin belt is T2'
//     );
//     assert(
//         dragonskin_belt_item.item_type == constants::ItemType::DragonskinBelt,
//         'dragonskin belt is hide'
//     );
//     assert(
//         dragonskin_belt_item.slot == constants::ItemSlot::DragonskinBelt,
//         'dragonskin belt is waist armor'
//     );

//     let studded_leather_belt_id = constants::ItemId::StuddedLeatherBelt;
//     let studded_leather_belt_item = ItemStats::get(studded_leather_belt_id);
//     assert(
//         studded_leather_belt_item.tier == constants::ItemTier::StuddedLeatherBelt,
//         'studded leather belt is T3'
//     );
//     assert(
//         studded_leather_belt_item.item_type == constants::ItemType::StuddedLeatherBelt,
//         'studded leather belt is hide'
//     );
//     assert(
//         studded_leather_belt_item.slot == constants::ItemSlot::StuddedLeatherBelt,
//         'studded leather belt is waist'
//     );

//     let hard_leather_belt_id = constants::ItemId::HardLeatherBelt;
//     let hard_leather_belt_item = ItemStats::get(hard_leather_belt_id);
//     assert(
//         hard_leather_belt_item.tier == constants::ItemTier::HardLeatherBelt,
//         'hard leather belt is T4'
//     );
//     assert(
//         hard_leather_belt_item.item_type == constants::ItemType::HardLeatherBelt,
//         'hard leather belt is hide'
//     );
//     assert(
//         hard_leather_belt_item.slot == constants::ItemSlot::HardLeatherBelt,
//         'hard leather belt is waist'
//     );

//     let leather_belt_id = constants::ItemId::LeatherBelt;
//     let leather_belt_item = ItemStats::get(leather_belt_id);
//     assert(leather_belt_item.tier == constants::ItemTier::LeatherBelt, 'leather belt is T5');
//     assert(leather_belt_item.item_type == constants::ItemType::LeatherBelt, 'leather belt is hide');
//     assert(
//         leather_belt_item.slot == constants::ItemSlot::LeatherBelt, 'leather belt is waist armor'
//     );

//     let demonhide_boots_id = constants::ItemId::DemonhideBoots;
//     let demonhide_boots_item = ItemStats::get(demonhide_boots_id);
//     assert(
//         demonhide_boots_item.tier == constants::ItemTier::DemonhideBoots, 'demonhide boots is T1'
//     );
//     assert(
//         demonhide_boots_item.item_type == constants::ItemType::DemonhideBoots,
//         'demonhide boots is hide'
//     );
//     assert(
//         demonhide_boots_item.slot == constants::ItemSlot::DemonhideBoots,
//         'demonhide boots is foot armor'
//     );

//     let dragonskin_boots_id = constants::ItemId::DragonskinBoots;
//     let dragonskin_boots_item = ItemStats::get(dragonskin_boots_id);
//     assert(
//         dragonskin_boots_item.tier == constants::ItemTier::DragonskinBoots, 'dragonskin boots is T2'
//     );
//     assert(
//         dragonskin_boots_item.item_type == constants::ItemType::DragonskinBoots,
//         'dragonskin boots is hide'
//     );
//     assert(
//         dragonskin_boots_item.slot == constants::ItemSlot::DragonskinBoots,
//         'dragonskin boots is foot armor'
//     );

//     let studded_leather_boots_id = constants::ItemId::StuddedLeatherBoots;
//     let studded_leather_boots_item = ItemStats::get(studded_leather_boots_id);
//     assert(
//         studded_leather_boots_item.tier == constants::ItemTier::StuddedLeatherBoots,
//         'studded leather boots is T3'
//     );
//     assert(
//         studded_leather_boots_item.item_type == constants::ItemType::StuddedLeatherBoots,
//         'studded leather boots is hide'
//     );
//     assert(
//         studded_leather_boots_item.slot == constants::ItemSlot::StuddedLeatherBoots,
//         'studded leather boots is foot'
//     );

//     let hard_leather_boots_id = constants::ItemId::HardLeatherBoots;
//     let hard_leather_boots_item = ItemStats::get(hard_leather_boots_id);
//     assert(
//         hard_leather_boots_item.tier == constants::ItemTier::HardLeatherBoots,
//         'hard leather boots is T4'
//     );
//     assert(
//         hard_leather_boots_item.item_type == constants::ItemType::HardLeatherBoots,
//         'hard leather boots is hide'
//     );
//     assert(
//         hard_leather_boots_item.slot == constants::ItemSlot::HardLeatherBoots,
//         'hard leather boots is foot'
//     );

//     let leather_boots_id = constants::ItemId::LeatherBoots;
//     let leather_boots_item = ItemStats::get(leather_boots_id);
//     assert(leather_boots_item.tier == constants::ItemTier::LeatherBoots, 'leather boots is T5');
//     assert(
//         leather_boots_item.item_type == constants::ItemType::LeatherBoots, 'leather boots is hide'
//     );
//     assert(
//         leather_boots_item.slot == constants::ItemSlot::LeatherBoots, 'leather boots is foot armor'
//     );

//     let demons_hands_id = constants::ItemId::DemonsHands;
//     let demons_hands_item = ItemStats::get(demons_hands_id);
//     assert(demons_hands_item.tier == constants::ItemTier::DemonsHands, 'demons hands is T1');
//     assert(demons_hands_item.item_type == constants::ItemType::DemonsHands, 'demons hands is hide');
//     assert(
//         demons_hands_item.slot == constants::ItemSlot::DemonsHands, 'demons hands is hand armor'
//     );

//     let dragonskin_gloves_id = constants::ItemId::DragonskinGloves;
//     let dragonskin_gloves_item = ItemStats::get(dragonskin_gloves_id);
//     assert(
//         dragonskin_gloves_item.tier == constants::ItemTier::DragonskinGloves,
//         'dragonskin gloves is T2'
//     );
//     assert(
//         dragonskin_gloves_item.item_type == constants::ItemType::DragonskinGloves,
//         'dragonskin gloves is hide'
//     );
//     assert(
//         dragonskin_gloves_item.slot == constants::ItemSlot::DragonskinGloves,
//         'dragonskin gloves is hand armor'
//     );

//     let studded_leather_gloves_id = constants::ItemId::StuddedLeatherGloves;
//     let studded_leather_gloves_item = ItemStats::get(studded_leather_gloves_id);
//     assert(
//         studded_leather_gloves_item.tier == constants::ItemTier::StuddedLeatherGloves,
//         'studded leather gloves is T3'
//     );
//     assert(
//         studded_leather_gloves_item.item_type == constants::ItemType::StuddedLeatherGloves,
//         'studded leather gloves is hide'
//     );
//     assert(
//         studded_leather_gloves_item.slot == constants::ItemSlot::StuddedLeatherGloves,
//         'studded leather gloves is hand'
//     );

//     let hard_leather_gloves_id = constants::ItemId::HardLeatherGloves;
//     let hard_leather_gloves_item = ItemStats::get(hard_leather_gloves_id);
//     assert(
//         hard_leather_gloves_item.tier == constants::ItemTier::HardLeatherGloves,
//         'hard leather gloves is T4'
//     );
//     assert(
//         hard_leather_gloves_item.item_type == constants::ItemType::HardLeatherGloves,
//         'hard leather gloves is hide'
//     );
//     assert(
//         hard_leather_gloves_item.slot == constants::ItemSlot::HardLeatherGloves,
//         'hard leather gloves is hand'
//     );

//     let leather_gloves_id = constants::ItemId::LeatherGloves;
//     let leather_gloves_item = ItemStats::get(leather_gloves_id);
//     assert(leather_gloves_item.tier == constants::ItemTier::LeatherGloves, 'leather gloves is T5');
//     assert(
//         leather_gloves_item.item_type == constants::ItemType::LeatherGloves,
//         'leather gloves is hide'
//     );
//     assert(
//         leather_gloves_item.slot == constants::ItemSlot::LeatherGloves,
//         'leather gloves is hand armor'
//     );

//     let warhammer_id = constants::ItemId::Warhammer;
//     let warhammer_item = ItemStats::get(warhammer_id);
//     assert(warhammer_item.tier == constants::ItemTier::Warhammer, 'warhammer is T1');
//     assert(warhammer_item.item_type == constants::ItemType::Warhammer, 'warhammer is bludgeon');
//     assert(warhammer_item.slot == constants::ItemSlot::Warhammer, 'warhammer is weapon');

//     let quarterstaff_id = constants::ItemId::Quarterstaff;
//     let quarterstaff_item = ItemStats::get(quarterstaff_id);
//     assert(quarterstaff_item.tier == constants::ItemTier::Quarterstaff, 'quarterstaff is T2');
//     assert(
//         quarterstaff_item.item_type == constants::ItemType::Quarterstaff, 'quarterstaff is bludgeon'
//     );
//     assert(quarterstaff_item.slot == constants::ItemSlot::Quarterstaff, 'quarterstaff is weapon');

//     let maul_id = constants::ItemId::Maul;
//     let maul_item = ItemStats::get(maul_id);
//     assert(maul_item.tier == constants::ItemTier::Maul, 'maul is T3');
//     assert(maul_item.item_type == constants::ItemType::Maul, 'maul is bludgeon');
//     assert(maul_item.slot == constants::ItemSlot::Maul, 'maul is weapon');

//     let mace_id = constants::ItemId::Mace;
//     let mace_item = ItemStats::get(mace_id);
//     assert(mace_item.tier == constants::ItemTier::Mace, 'mace is T4');
//     assert(mace_item.item_type == constants::ItemType::Mace, 'mace is bludgeon');
//     assert(mace_item.slot == constants::ItemSlot::Mace, 'mace is weapon');

//     let club_id = constants::ItemId::Club;
//     let club_item = ItemStats::get(club_id);
//     assert(club_item.tier == constants::ItemTier::Club, 'club is T5');
//     assert(club_item.item_type == constants::ItemType::Club, 'club is bludgeon');
//     assert(club_item.slot == constants::ItemSlot::Club, 'club is weapon');
// }


