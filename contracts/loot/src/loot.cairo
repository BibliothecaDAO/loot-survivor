use traits::{TryInto, Into};
use option::OptionTrait;
use debug::PrintTrait;
use core::serde::Serde;
use integer::{U256TryIntoU32, U256TryIntoU8};

use core::clone::Clone;
use array::ArrayTrait;

use super::statistics::{item_tier, item_slot, item_type};
use super::statistics::constants;

use pack::pack::{pack_value, unpack_value};
use pack::constants::{pow, mask};

use combat::constants::CombatEnums::{Type, Tier, Slot};
use combat::combat::ImplCombat;

#[derive(Copy, Drop, Clone, Serde)]
struct Loot {
    id: u8,
    tier: Tier,
    item_type: Type,
    slot: Slot,
}

trait ILoot {
    fn get_item(id: u8) -> Loot;
    fn get_tier(id: u8) -> Tier;
    fn get_type(id: u8) -> Type;
    fn get_slot(id: u8) -> Slot;
    fn is_starting_weapon(id: u8) -> bool;
    fn get_greatness_level(xp: u16) -> u8;
    fn pack(self: Loot) -> felt252;
    fn unpack(packed: felt252) -> Loot;
}

impl ImplLoot of ILoot {
    fn get_item(id: u8) -> Loot {
        Loot {
            id: id,
            tier: ImplLoot::get_tier(id),
            item_type: ImplLoot::get_type(id),
            slot: ImplLoot::get_slot(id),
        }
    }
    fn get_tier(id: u8) -> Tier {
        return item_tier::get(id);
    }
    fn get_type(id: u8) -> Type {
        return item_type::get(id);
    }
    fn get_slot(id: u8) -> Slot {
        return item_slot::get(id);
    }

    // is_starting_weapon returns true if the item is a starting weapon.
    // Starting weapons are: {Wand, Book, Club, ShortSword}
    // @param id The item id.
    // @return True if the item is a starting weapon.
    fn is_starting_weapon(id: u8) -> bool {
        if (id == constants::ItemId::Wand) {
            return true;
        } else if (id == constants::ItemId::Book) {
            return true;
        } else if (id == constants::ItemId::Club) {
            return true;
        } else if (id == constants::ItemId::ShortSword) {
            return true;
        } else {
            return false;
        }
    }

    // get_greatness_level returns the greatness level of an item based on xp
    // @param xp The xp of the item.
    // @return The greatness level of the item.
    fn get_greatness_level(xp: u16) -> u8 {
        // use combat lib to determine the level but give items a bonus based
        // on the item level multiplier setting (currently 4) which means
        // items will level up 4x faster than entities without a multplier
        // such as adventurers
        return ImplCombat::get_level_from_xp(xp * constants::Settings::ITEM_LEVEL_MULTIPLIER);
    }

    fn pack(self: Loot) -> felt252 {
        let mut packed = 0;
        let item_tier = ImplCombat::tier_to_u8(self.tier);
        let item_type = ImplCombat::type_to_u8(self.item_type);
        let item_slot = ImplCombat::slot_to_u8(self.slot);

        packed = packed | pack_value(self.id.into(), pow::TWO_POW_236);
        packed = packed | pack_value(item_tier.into(), pow::TWO_POW_220);
        packed = packed | pack_value(item_type.into(), pow::TWO_POW_204);
        packed = packed | pack_value(item_slot.into(), pow::TWO_POW_118);

        packed.try_into().unwrap()
    }
    fn unpack(packed: felt252) -> Loot {
        let packed = packed.into();
        let item_tier_u8 = U256TryIntoU8::try_into(
            unpack_value(packed, pow::TWO_POW_220, mask::MASK_16)
        )
            .unwrap();
        let item_type_u8 = U256TryIntoU8::try_into(
            unpack_value(packed, pow::TWO_POW_204, mask::MASK_16)
        )
            .unwrap();

        let item_slot_u8 = U256TryIntoU8::try_into(
            unpack_value(packed, pow::TWO_POW_118, mask::MASK_16)
        )
            .unwrap();

        let item_id = U256TryIntoU8::try_into(unpack_value(packed, pow::TWO_POW_236, mask::MASK_16))
            .unwrap();
        let item_tier = ImplCombat::u8_to_tier(item_tier_u8);
        let item_type = ImplCombat::u8_to_type(item_type_u8);
        let item_slot = ImplCombat::u8_to_slot(item_slot_u8);

        Loot { id: item_id, tier: item_tier, item_type: item_type, slot: item_slot }
    }
}

#[test]
#[available_gas(1000000)]
fn test_pack_and_unpack() {
    let loot = Loot {
        id: 1, tier: Tier::T1(()), item_type: Type::Bludgeon_or_Metal(()), slot: Slot::Waist(())
    };

    let unpacked = ImplLoot::unpack(loot.pack());

    let unpacked = ImplLoot::unpack(loot.pack());
    assert(loot.id == unpacked.id, 'id');
    assert(loot.tier == unpacked.tier, 'tier');
    assert(loot.item_type == unpacked.item_type, 'item_type');
    assert(loot.slot == unpacked.slot, 'slot');
}
#[test]
#[available_gas(2000000)]
fn test_get_item_part1() {
    let katana_id = constants::ItemId::Katana;
    let katana_item = ImplLoot::get_item(katana_id);
    assert(katana_item.tier == Tier::T1(()), 'katana is T1');
    assert(katana_item.item_type == Type::Blade_or_Hide(()), 'katana is blade');
    assert(katana_item.slot == Slot::Weapon(()), 'katana is weapon');

    let pendant_id = constants::ItemId::Pendant;
    let pendant_item = ImplLoot::get_item(pendant_id);
    assert(pendant_item.tier == Tier::T1(()), 'pendant is T1');
    assert(pendant_item.item_type == Type::Necklace(()), 'pendant is necklace');
    assert(pendant_item.slot == Slot::Neck(()), 'pendant is neck slot');

    let necklace_id = constants::ItemId::Necklace;
    let necklace_item = ImplLoot::get_item(necklace_id);
    assert(necklace_item.tier == Tier::T1(()), 'necklace is T1');
    assert(necklace_item.item_type == Type::Necklace(()), 'necklace is necklace');
    assert(necklace_item.slot == Slot::Neck(()), 'necklace is neck slot');

    let amulet_id = constants::ItemId::Amulet;
    let amulet_item = ImplLoot::get_item(amulet_id);
    assert(amulet_item.tier == Tier::T1(()), 'amulet is T1');
    assert(amulet_item.item_type == Type::Necklace(()), 'amulet is necklace');
    assert(amulet_item.slot == Slot::Neck(()), 'amulet is neck slot');

    let silver_ring_id = constants::ItemId::SilverRing;
    let silver_ring_item = ImplLoot::get_item(silver_ring_id);
    assert(silver_ring_item.tier == Tier::T2(()), 'silver ring is T2');
    assert(silver_ring_item.item_type == Type::Ring(()), 'silver ring is a ring');
    assert(silver_ring_item.slot == Slot::Ring(()), 'silver ring is ring slot');

    let bronze_ring_id = constants::ItemId::BronzeRing;
    let bronze_ring_item = ImplLoot::get_item(bronze_ring_id);
    assert(bronze_ring_item.tier == Tier::T3(()), 'bronze ring is T3');
    assert(bronze_ring_item.item_type == Type::Ring(()), 'bronze ring is ring');
    assert(bronze_ring_item.slot == Slot::Ring(()), 'bronze ring is ring slot');

    let platinum_ring_id = constants::ItemId::PlatinumRing;
    let platinum_ring_item = ImplLoot::get_item(platinum_ring_id);
    assert(platinum_ring_item.tier == Tier::T1(()), 'platinum ring is T1');
    assert(platinum_ring_item.item_type == Type::Ring(()), 'platinum ring is ring');
    assert(platinum_ring_item.slot == Slot::Ring(()), 'platinum ring is ring slot');

    let titanium_ring_id = constants::ItemId::TitaniumRing;
    let titanium_ring_item = ImplLoot::get_item(titanium_ring_id);
    assert(titanium_ring_item.tier == Tier::T1(()), 'titanium ring is T1');
    assert(titanium_ring_item.item_type == Type::Ring(()), 'titanium ring is ring');
    assert(titanium_ring_item.slot == Slot::Ring(()), 'titanium ring is ring slot');

    let gold_ring_id = constants::ItemId::GoldRing;
    let gold_ring_item = ImplLoot::get_item(gold_ring_id);
    assert(gold_ring_item.tier == Tier::T1(()), 'gold ring is T1');
    assert(gold_ring_item.item_type == Type::Ring(()), 'gold ring is ring');
    assert(gold_ring_item.slot == Slot::Ring(()), 'gold ring is ring slow');

    let ghost_wand_id = constants::ItemId::GhostWand;
    let ghost_wand_item = ImplLoot::get_item(ghost_wand_id);
    assert(ghost_wand_item.tier == Tier::T1(()), 'ghost wand is T1');
    assert(ghost_wand_item.item_type == Type::Magic_or_Cloth(()), 'ghost wand is magical');
    assert(ghost_wand_item.slot == Slot::Weapon(()), 'ghost wand is weapon');

    let grave_wand_id = constants::ItemId::GraveWand;
    let grave_wand_item = ImplLoot::get_item(grave_wand_id);
    assert(grave_wand_item.tier == Tier::T2(()), 'grave wand is T2');
    assert(grave_wand_item.item_type == Type::Magic_or_Cloth(()), 'grave wand is magical');
    assert(grave_wand_item.slot == Slot::Weapon(()), 'grave wand is weapon');

    let bone_wand_id = constants::ItemId::BoneWand;
    let bone_wand_item = ImplLoot::get_item(bone_wand_id);
    assert(bone_wand_item.tier == Tier::T3(()), 'bone wand is T3');
    assert(bone_wand_item.item_type == Type::Magic_or_Cloth(()), 'bone wand is magical');
    assert(bone_wand_item.slot == Slot::Weapon(()), 'bone wand is weapon');

    let wand_id = constants::ItemId::Wand;
    let wand_item = ImplLoot::get_item(wand_id);
    assert(wand_item.tier == Tier::T5(()), 'wand is T5');
    assert(wand_item.item_type == Type::Magic_or_Cloth(()), 'wand is magical');
    assert(wand_item.slot == Slot::Weapon(()), 'wand is weapon');

    let grimoire_id = constants::ItemId::Grimoire;
    let grimoire_item = ImplLoot::get_item(grimoire_id);
    assert(grimoire_item.tier == Tier::T1(()), 'grimoire is T1');
    assert(grimoire_item.item_type == Type::Magic_or_Cloth(()), 'grimoire is magical');
    assert(grimoire_item.slot == Slot::Weapon(()), 'grimoire is weapon');

    let chronicle_id = constants::ItemId::Chronicle;
    let chronicle_item = ImplLoot::get_item(chronicle_id);
    assert(chronicle_item.tier == Tier::T2(()), 'chronicle is T2');
    assert(chronicle_item.item_type == Type::Magic_or_Cloth(()), 'chronicle is magical');
    assert(chronicle_item.slot == Slot::Weapon(()), 'chronicle is weapon');

    let tome_id = constants::ItemId::Tome;
    let tome_item = ImplLoot::get_item(tome_id);
    assert(tome_item.tier == Tier::T3(()), 'tome is T3');
    assert(tome_item.item_type == Type::Magic_or_Cloth(()), 'tome is magical');
    assert(tome_item.slot == Slot::Weapon(()), 'tome is weapon');

    let book_id = constants::ItemId::Book;
    let book_item = ImplLoot::get_item(book_id);
    assert(book_item.tier == Tier::T5(()), 'book is T5');
    assert(book_item.item_type == Type::Magic_or_Cloth(()), 'book is magical');
    assert(book_item.slot == Slot::Weapon(()), 'book is weapon');

    let divine_robe_id = constants::ItemId::DivineRobe;
    let divine_robe_item = ImplLoot::get_item(divine_robe_id);
    assert(divine_robe_item.tier == Tier::T1(()), 'divine robe is T1');
    assert(divine_robe_item.item_type == Type::Magic_or_Cloth(()), 'divine robe is cloth');
    assert(divine_robe_item.slot == Slot::Chest(()), 'divine robe is chest armor');

    let silk_robe_id = constants::ItemId::SilkRobe;
    let silk_robe_item = ImplLoot::get_item(silk_robe_id);
    assert(silk_robe_item.tier == Tier::T2(()), 'silk robe is T2');
    assert(silk_robe_item.item_type == Type::Magic_or_Cloth(()), 'silk robe is cloth');
    assert(silk_robe_item.slot == Slot::Chest(()), 'silk robe is chest armor');

    let linen_robe_id = constants::ItemId::LinenRobe;
    let linen_robe_item = ImplLoot::get_item(linen_robe_id);
    assert(linen_robe_item.tier == Tier::T3(()), 'linen robe is T3');
    assert(linen_robe_item.item_type == Type::Magic_or_Cloth(()), 'linen robe is cloth');
    assert(linen_robe_item.slot == Slot::Chest(()), 'linen robe is chest armor');

    let robe_id = constants::ItemId::Robe;
    let robe_item = ImplLoot::get_item(robe_id);
    assert(robe_item.tier == Tier::T4(()), 'robe is T4');
    assert(robe_item.item_type == Type::Magic_or_Cloth(()), 'robe is cloth');
    assert(robe_item.slot == Slot::Chest(()), 'robe is chest armor');

    let shirt_id = constants::ItemId::Shirt;
    let shirt_item = ImplLoot::get_item(shirt_id);
    assert(shirt_item.tier == Tier::T5(()), 'shirt is T5');
    assert(shirt_item.item_type == Type::Magic_or_Cloth(()), 'shirt is cloth');
    assert(shirt_item.slot == Slot::Chest(()), 'shirt is chest armor');

    let crown_id = constants::ItemId::Crown;
    let crown_item = ImplLoot::get_item(crown_id);
    assert(crown_item.tier == Tier::T1(()), 'crown is T1');
    assert(crown_item.item_type == Type::Magic_or_Cloth(()), 'crown is cloth');
    assert(crown_item.slot == Slot::Head(()), 'crown is head armor');

    let divine_hood_id = constants::ItemId::DivineHood;
    let divine_hood_item = ImplLoot::get_item(divine_hood_id);
    assert(divine_hood_item.tier == Tier::T2(()), 'divine hood is T2');
    assert(divine_hood_item.item_type == Type::Magic_or_Cloth(()), 'divine hood is cloth');
    assert(divine_hood_item.slot == Slot::Head(()), 'divine hood is head armor');
}
#[test]
#[available_gas(2000000)]
fn test_get_item_part2() {
    let silk_hood_id = constants::ItemId::SilkHood;
    let silk_hood_item = ImplLoot::get_item(silk_hood_id);
    assert(silk_hood_item.tier == Tier::T3(()), 'silk hood is T3');
    assert(silk_hood_item.item_type == Type::Magic_or_Cloth(()), 'silk hood is cloth');
    assert(silk_hood_item.slot == Slot::Head(()), 'silk hood is head armor');

    let linen_hood_id = constants::ItemId::LinenHood;
    let linen_hood_item = ImplLoot::get_item(linen_hood_id);
    assert(linen_hood_item.tier == Tier::T4(()), 'linen hood is T4');
    assert(linen_hood_item.item_type == Type::Magic_or_Cloth(()), 'linen hood is cloth');
    assert(linen_hood_item.slot == Slot::Head(()), 'linen hood is head armor');

    let hood_id = constants::ItemId::Hood;
    let hood_item = ImplLoot::get_item(hood_id);
    assert(hood_item.tier == Tier::T5(()), 'hood is T5');
    assert(hood_item.item_type == Type::Magic_or_Cloth(()), 'hood is cloth');
    assert(hood_item.slot == Slot::Head(()), 'hood is head armor');

    let brightsilk_sash_id = constants::ItemId::BrightsilkSash;
    let brightsilk_sash_item = ImplLoot::get_item(brightsilk_sash_id);
    assert(brightsilk_sash_item.tier == Tier::T1(()), 'brightsilk sash is T1');
    assert(brightsilk_sash_item.item_type == Type::Magic_or_Cloth(()), 'brightsilk sash is cloth');
    assert(brightsilk_sash_item.slot == Slot::Waist(()), 'brightsilk sash is waist armor');

    let silk_sash_id = constants::ItemId::SilkSash;
    let silk_sash_item = ImplLoot::get_item(silk_sash_id);
    assert(silk_sash_item.tier == Tier::T2(()), 'silk sash is T2');
    assert(silk_sash_item.item_type == Type::Magic_or_Cloth(()), 'silk sash is cloth');
    assert(silk_sash_item.slot == Slot::Waist(()), 'silk sash is waist armor');

    let wool_sash_id = constants::ItemId::WoolSash;
    let wool_sash_item = ImplLoot::get_item(wool_sash_id);
    assert(wool_sash_item.tier == Tier::T3(()), 'wool sash is T3');
    assert(wool_sash_item.item_type == Type::Magic_or_Cloth(()), 'wool sash is cloth');
    assert(wool_sash_item.slot == Slot::Waist(()), 'wool sash is waist armor');

    let linen_sash_id = constants::ItemId::LinenSash;
    let linen_sash_item = ImplLoot::get_item(linen_sash_id);
    assert(linen_sash_item.tier == Tier::T4(()), 'linen sash is T4');
    assert(linen_sash_item.item_type == Type::Magic_or_Cloth(()), 'linen sash is cloth');
    assert(linen_sash_item.slot == Slot::Waist(()), 'linen sash is waist armor');

    let sash_id = constants::ItemId::Sash;
    let sash_item = ImplLoot::get_item(sash_id);
    assert(sash_item.tier == Tier::T5(()), 'sash is T5');
    assert(sash_item.item_type == Type::Magic_or_Cloth(()), 'sash is cloth');
    assert(sash_item.slot == Slot::Waist(()), 'sash is waist armor');

    let divine_slippers_id = constants::ItemId::DivineSlippers;
    let divine_slippers_item = ImplLoot::get_item(divine_slippers_id);
    assert(divine_slippers_item.tier == Tier::T1(()), 'divine slippers are T1');
    assert(divine_slippers_item.item_type == Type::Magic_or_Cloth(()), 'divine slippers are cloth');
    assert(divine_slippers_item.slot == Slot::Foot(()), 'divine slippers are foot armor');

    let silk_slippers_id = constants::ItemId::SilkSlippers;
    let silk_slippers_item = ImplLoot::get_item(silk_slippers_id);
    assert(silk_slippers_item.tier == Tier::T2(()), 'silk slippers are T2');
    assert(silk_slippers_item.item_type == Type::Magic_or_Cloth(()), 'silk slippers are cloth');
    assert(silk_slippers_item.slot == Slot::Foot(()), 'silk slippers are foot armor');

    let wool_shoes_id = constants::ItemId::WoolShoes;
    let wool_shoes_item = ImplLoot::get_item(wool_shoes_id);
    assert(wool_shoes_item.tier == Tier::T3(()), 'wool shoes are T3');
    assert(wool_shoes_item.item_type == Type::Magic_or_Cloth(()), 'wool shoes are cloth');
    assert(wool_shoes_item.slot == Slot::Foot(()), 'wool shoes are foot armor');

    let linen_shoes_id = constants::ItemId::LinenShoes;
    let linen_shoes_item = ImplLoot::get_item(linen_shoes_id);
    assert(linen_shoes_item.tier == Tier::T4(()), 'linen shoes are T4');
    assert(linen_shoes_item.item_type == Type::Magic_or_Cloth(()), 'linen shoes are cloth');
    assert(linen_shoes_item.slot == Slot::Foot(()), 'linen shoes are foot armor');

    let shoes_id = constants::ItemId::Shoes;
    let shoes_item = ImplLoot::get_item(shoes_id);
    assert(shoes_item.tier == Tier::T5(()), 'shoes are T5');
    assert(shoes_item.item_type == Type::Magic_or_Cloth(()), 'shoes are cloth');
    assert(shoes_item.slot == Slot::Foot(()), 'shoes are foot armor');

    let divine_gloves_id = constants::ItemId::DivineGloves;
    let divine_gloves_item = ImplLoot::get_item(divine_gloves_id);
    assert(divine_gloves_item.tier == Tier::T1(()), 'divine gloves are T1');
    assert(divine_gloves_item.item_type == Type::Magic_or_Cloth(()), 'divine gloves are cloth');
    assert(divine_gloves_item.slot == Slot::Hand(()), 'divine gloves are hand armor');

    let silk_gloves_id = constants::ItemId::SilkGloves;
    let silk_gloves_item = ImplLoot::get_item(silk_gloves_id);
    assert(silk_gloves_item.tier == Tier::T2(()), 'silk gloves are T2');
    assert(silk_gloves_item.item_type == Type::Magic_or_Cloth(()), 'silk gloves are cloth');
    assert(silk_gloves_item.slot == Slot::Hand(()), 'silk gloves are hand armor');

    let wool_gloves_id = constants::ItemId::WoolGloves;
    let wool_gloves_item = ImplLoot::get_item(wool_gloves_id);
    assert(wool_gloves_item.tier == Tier::T3(()), 'wool gloves are T3');
    assert(wool_gloves_item.item_type == Type::Magic_or_Cloth(()), 'wool gloves are cloth');
    assert(wool_gloves_item.slot == Slot::Hand(()), 'wool gloves are hand armor');

    let linen_gloves_id = constants::ItemId::LinenGloves;
    let linen_gloves_item = ImplLoot::get_item(linen_gloves_id);
    assert(linen_gloves_item.tier == Tier::T4(()), 'linen gloves are T4');
    assert(linen_gloves_item.item_type == Type::Magic_or_Cloth(()), 'linen gloves are hand armor');
    assert(linen_gloves_item.slot == Slot::Hand(()), 'linen gloves are cloth');

    let gloves_id = constants::ItemId::Gloves;
    let gloves_item = ImplLoot::get_item(gloves_id);
    assert(gloves_item.tier == Tier::T5(()), 'gloves are T5');
    assert(gloves_item.item_type == Type::Magic_or_Cloth(()), 'gloves are cloth');
    assert(gloves_item.slot == Slot::Hand(()), 'gloves are hand armor');

    let katana_id = constants::ItemId::Katana;
    let katana_item = ImplLoot::get_item(katana_id);
    assert(katana_item.tier == Tier::T1(()), 'katana is T1');
    assert(katana_item.item_type == Type::Blade_or_Hide(()), 'katana is blade');
    assert(katana_item.slot == Slot::Weapon(()), 'katana is weapon');

    let falchion_id = constants::ItemId::Falchion;
    let falchion_item = ImplLoot::get_item(falchion_id);
    assert(falchion_item.tier == Tier::T2(()), 'falchion is T2');
    assert(falchion_item.item_type == Type::Blade_or_Hide(()), 'falchion is blade');
    assert(falchion_item.slot == Slot::Weapon(()), 'falchion is weapon');

    let scimitar_id = constants::ItemId::Scimitar;
    let scimitar_item = ImplLoot::get_item(scimitar_id);
    assert(scimitar_item.tier == Tier::T3(()), 'scimitar is T3');
    assert(scimitar_item.item_type == Type::Blade_or_Hide(()), 'scimitar is blade');
    assert(scimitar_item.slot == Slot::Weapon(()), 'scimitar is weapon');

    let long_sword_id = constants::ItemId::LongSword;
    let long_sword_item = ImplLoot::get_item(long_sword_id);
    assert(long_sword_item.tier == Tier::T4(()), 'long sword is T4');
    assert(long_sword_item.item_type == Type::Blade_or_Hide(()), 'long sword is blade');
    assert(long_sword_item.slot == Slot::Weapon(()), 'long sword is weapon');

    let short_sword_id = constants::ItemId::ShortSword;
    let short_sword_item = ImplLoot::get_item(short_sword_id);
    assert(short_sword_item.tier == Tier::T5(()), 'short sword is T5');
    assert(short_sword_item.item_type == Type::Blade_or_Hide(()), 'short sword is blade');
    assert(short_sword_item.slot == Slot::Weapon(()), 'short sword is weapon');

    let demon_husk_id = constants::ItemId::DemonHusk;
    let demon_husk_item = ImplLoot::get_item(demon_husk_id);
    assert(demon_husk_item.tier == Tier::T1(()), 'demon husk is T1');
    assert(demon_husk_item.item_type == Type::Blade_or_Hide(()), 'demon husk is hide');
    assert(demon_husk_item.slot == Slot::Chest(()), 'demon husk is chest armor');

    let dragonskin_armor_id = constants::ItemId::DragonskinArmor;
    let dragonskin_armor_item = ImplLoot::get_item(dragonskin_armor_id);
    assert(dragonskin_armor_item.tier == Tier::T2(()), 'dragonskin armor is T2');
    assert(dragonskin_armor_item.item_type == Type::Blade_or_Hide(()), 'dragonskin armor is hide');
    assert(dragonskin_armor_item.slot == Slot::Chest(()), 'dragonskin armor is chest armor');
}

#[test]
#[available_gas(2000000)]
fn test_get_item_part3() {
    let studded_leather_armor_id = constants::ItemId::StuddedLeatherArmor;
    let studded_leather_armor_item = ImplLoot::get_item(studded_leather_armor_id);
    assert(studded_leather_armor_item.tier == Tier::T3(()), 'studded leather armor is T3');
    assert(
        studded_leather_armor_item.item_type == Type::Blade_or_Hide(()),
        'studded leather armor is hide'
    );
    assert(studded_leather_armor_item.slot == Slot::Chest(()), 'studded leather armor is chest');

    let hard_leather_armor_id = constants::ItemId::HardLeatherArmor;
    let hard_leather_armor_item = ImplLoot::get_item(hard_leather_armor_id);
    assert(hard_leather_armor_item.tier == Tier::T4(()), 'hard leather armor is T4');
    assert(
        hard_leather_armor_item.item_type == Type::Blade_or_Hide(()), 'hard leather armor is hide'
    );
    assert(hard_leather_armor_item.slot == Slot::Chest(()), 'hard leather armor is chest');

    let leather_armor_id = constants::ItemId::LeatherArmor;
    let leather_armor_item = ImplLoot::get_item(leather_armor_id);
    assert(leather_armor_item.tier == Tier::T5(()), 'leather armor is T5');
    assert(leather_armor_item.item_type == Type::Blade_or_Hide(()), 'leather armor is hide');
    assert(leather_armor_item.slot == Slot::Chest(()), 'leather armor is chest armor');

    let demon_crown_id = constants::ItemId::DemonCrown;
    let demon_crown_item = ImplLoot::get_item(demon_crown_id);
    assert(demon_crown_item.tier == Tier::T1(()), 'demon crown is T1');
    assert(demon_crown_item.item_type == Type::Blade_or_Hide(()), 'demon crown is hide');
    assert(demon_crown_item.slot == Slot::Head(()), 'demon crown is head armor');

    let dragons_crown_id = constants::ItemId::DragonsCrown;
    let dragons_crown_item = ImplLoot::get_item(dragons_crown_id);
    assert(dragons_crown_item.tier == Tier::T2(()), 'dragons crown is T2');
    assert(dragons_crown_item.item_type == Type::Blade_or_Hide(()), 'dragons crown is hide');
    assert(dragons_crown_item.slot == Slot::Head(()), 'dragons crown is head armor');

    let war_cap_id = constants::ItemId::WarCap;
    let war_cap_item = ImplLoot::get_item(war_cap_id);
    assert(war_cap_item.tier == Tier::T3(()), 'war cap is T3');
    assert(war_cap_item.item_type == Type::Blade_or_Hide(()), 'war cap is hide');
    assert(war_cap_item.slot == Slot::Head(()), 'war cap is head armor');

    let leather_cap_id = constants::ItemId::LeatherCap;
    let leather_cap_item = ImplLoot::get_item(leather_cap_id);
    assert(leather_cap_item.tier == Tier::T4(()), 'leather cap is T4');
    assert(leather_cap_item.item_type == Type::Blade_or_Hide(()), 'leather cap is hide');
    assert(leather_cap_item.slot == Slot::Head(()), 'leather cap is head armor');

    let cap_id = constants::ItemId::Cap;
    let cap_item = ImplLoot::get_item(cap_id);
    assert(cap_item.tier == Tier::T5(()), 'cap is T5');
    assert(cap_item.item_type == Type::Blade_or_Hide(()), 'cap is hide');
    assert(cap_item.slot == Slot::Head(()), 'cap is head armor');

    let demonhide_belt_id = constants::ItemId::DemonhideBelt;
    let demonhide_belt_item = ImplLoot::get_item(demonhide_belt_id);
    assert(demonhide_belt_item.tier == Tier::T1(()), 'demonhide belt is T1');
    assert(demonhide_belt_item.item_type == Type::Blade_or_Hide(()), 'demonhide belt is hide');
    assert(demonhide_belt_item.slot == Slot::Waist(()), 'demonhide belt is waist armor');

    let dragonskin_belt_id = constants::ItemId::DragonskinBelt;
    let dragonskin_belt_item = ImplLoot::get_item(dragonskin_belt_id);
    assert(dragonskin_belt_item.tier == Tier::T2(()), 'dragonskin belt is T2');
    assert(dragonskin_belt_item.item_type == Type::Blade_or_Hide(()), 'dragonskin belt is hide');
    assert(dragonskin_belt_item.slot == Slot::Waist(()), 'dragonskin belt is waist armor');

    let studded_leather_belt_id = constants::ItemId::StuddedLeatherBelt;
    let studded_leather_belt_item = ImplLoot::get_item(studded_leather_belt_id);
    assert(studded_leather_belt_item.tier == Tier::T3(()), 'studded leather belt is T3');
    assert(
        studded_leather_belt_item.item_type == Type::Blade_or_Hide(()),
        'studded leather belt is hide'
    );
    assert(studded_leather_belt_item.slot == Slot::Waist(()), 'studded leather belt is waist');

    let hard_leather_belt_id = constants::ItemId::HardLeatherBelt;
    let hard_leather_belt_item = ImplLoot::get_item(hard_leather_belt_id);
    assert(hard_leather_belt_item.tier == Tier::T4(()), 'hard leather belt is T4');
    assert(
        hard_leather_belt_item.item_type == Type::Blade_or_Hide(()), 'hard leather belt is hide'
    );
    assert(hard_leather_belt_item.slot == Slot::Waist(()), 'hard leather belt is waist');

    let leather_belt_id = constants::ItemId::LeatherBelt;
    let leather_belt_item = ImplLoot::get_item(leather_belt_id);
    assert(leather_belt_item.tier == Tier::T5(()), 'leather belt is T5');
    assert(leather_belt_item.item_type == Type::Blade_or_Hide(()), 'leather belt is hide');
    assert(leather_belt_item.slot == Slot::Waist(()), 'leather belt is waist armor');

    let demonhide_boots_id = constants::ItemId::DemonhideBoots;
    let demonhide_boots_item = ImplLoot::get_item(demonhide_boots_id);
    assert(demonhide_boots_item.tier == Tier::T1(()), 'demonhide boots is T1');
    assert(demonhide_boots_item.item_type == Type::Blade_or_Hide(()), 'demonhide boots is hide');
    assert(demonhide_boots_item.slot == Slot::Foot(()), 'demonhide boots is foot armor');

    let dragonskin_boots_id = constants::ItemId::DragonskinBoots;
    let dragonskin_boots_item = ImplLoot::get_item(dragonskin_boots_id);
    assert(dragonskin_boots_item.tier == Tier::T2(()), 'dragonskin boots is T2');
    assert(dragonskin_boots_item.item_type == Type::Blade_or_Hide(()), 'dragonskin boots is hide');
    assert(dragonskin_boots_item.slot == Slot::Foot(()), 'dragonskin boots is foot armor');
}

#[test]
#[available_gas(2000000)]
fn test_get_item_part4() {
    let studded_leather_boots_id = constants::ItemId::StuddedLeatherBoots;
    let studded_leather_boots_item = ImplLoot::get_item(studded_leather_boots_id);
    assert(studded_leather_boots_item.tier == Tier::T3(()), 'studded leather boots is T3');
    assert(
        studded_leather_boots_item.item_type == Type::Blade_or_Hide(()),
        'studded leather boots is hide'
    );
    assert(studded_leather_boots_item.slot == Slot::Foot(()), 'studded leather boots is foot');

    let hard_leather_boots_id = constants::ItemId::HardLeatherBoots;
    let hard_leather_boots_item = ImplLoot::get_item(hard_leather_boots_id);
    assert(hard_leather_boots_item.tier == Tier::T4(()), 'hard leather boots is T4');
    assert(
        hard_leather_boots_item.item_type == Type::Blade_or_Hide(()), 'hard leather boots is hide'
    );
    assert(hard_leather_boots_item.slot == Slot::Foot(()), 'hard leather boots is foot');

    let leather_boots_id = constants::ItemId::LeatherBoots;
    let leather_boots_item = ImplLoot::get_item(leather_boots_id);
    assert(leather_boots_item.tier == Tier::T5(()), 'leather boots is T5');
    assert(leather_boots_item.item_type == Type::Blade_or_Hide(()), 'leather boots is hide');
    assert(leather_boots_item.slot == Slot::Foot(()), 'leather boots is foot armor');

    let demons_hands_id = constants::ItemId::DemonsHands;
    let demons_hands_item = ImplLoot::get_item(demons_hands_id);
    assert(demons_hands_item.tier == Tier::T1(()), 'demons hands is T1');
    assert(demons_hands_item.item_type == Type::Blade_or_Hide(()), 'demons hands is hide');
    assert(demons_hands_item.slot == Slot::Hand(()), 'demons hands is hand armor');

    let dragonskin_gloves_id = constants::ItemId::DragonskinGloves;
    let dragonskin_gloves_item = ImplLoot::get_item(dragonskin_gloves_id);
    assert(dragonskin_gloves_item.tier == Tier::T2(()), 'dragonskin gloves is T2');
    assert(
        dragonskin_gloves_item.item_type == Type::Blade_or_Hide(()), 'dragonskin gloves is hide'
    );
    assert(dragonskin_gloves_item.slot == Slot::Hand(()), 'dragonskin gloves is hand armor');

    let studded_leather_gloves_id = constants::ItemId::StuddedLeatherGloves;
    let studded_leather_gloves_item = ImplLoot::get_item(studded_leather_gloves_id);
    assert(studded_leather_gloves_item.tier == Tier::T3(()), 'studded leather gloves is T3');
    assert(
        studded_leather_gloves_item.item_type == Type::Blade_or_Hide(()),
        'studded leather gloves is hide'
    );
    assert(studded_leather_gloves_item.slot == Slot::Hand(()), 'studded leather gloves is hand');

    let hard_leather_gloves_id = constants::ItemId::HardLeatherGloves;
    let hard_leather_gloves_item = ImplLoot::get_item(hard_leather_gloves_id);
    assert(hard_leather_gloves_item.tier == Tier::T4(()), 'hard leather gloves is T4');
    assert(
        hard_leather_gloves_item.item_type == Type::Blade_or_Hide(()), 'hard leather gloves is hide'
    );
    assert(hard_leather_gloves_item.slot == Slot::Hand(()), 'hard leather gloves is hand');

    let leather_gloves_id = constants::ItemId::LeatherGloves;
    let leather_gloves_item = ImplLoot::get_item(leather_gloves_id);
    assert(leather_gloves_item.tier == Tier::T5(()), 'leather gloves is T5');
    assert(leather_gloves_item.item_type == Type::Blade_or_Hide(()), 'leather gloves is hide');
    assert(leather_gloves_item.slot == Slot::Hand(()), 'leather gloves is hand armor');

    let warhammer_id = constants::ItemId::Warhammer;
    let warhammer_item = ImplLoot::get_item(warhammer_id);
    assert(warhammer_item.tier == Tier::T1(()), 'warhammer is T1');
    assert(warhammer_item.item_type == Type::Bludgeon_or_Metal(()), 'warhammer is bludgeon');
    assert(warhammer_item.slot == Slot::Weapon(()), 'warhammer is weapon');

    let quarterstaff_id = constants::ItemId::Quarterstaff;
    let quarterstaff_item = ImplLoot::get_item(quarterstaff_id);
    assert(quarterstaff_item.tier == Tier::T2(()), 'quarterstaff is T2');
    assert(quarterstaff_item.item_type == Type::Bludgeon_or_Metal(()), 'quarterstaff is bludgeon');
    assert(quarterstaff_item.slot == Slot::Weapon(()), 'quarterstaff is weapon');

    let maul_id = constants::ItemId::Maul;
    let maul_item = ImplLoot::get_item(maul_id);
    assert(maul_item.tier == Tier::T3(()), 'maul is T3');
    assert(maul_item.item_type == Type::Bludgeon_or_Metal(()), 'maul is bludgeon');
    assert(maul_item.slot == Slot::Weapon(()), 'maul is weapon');

    let mace_id = constants::ItemId::Mace;
    let mace_item = ImplLoot::get_item(mace_id);
    assert(mace_item.tier == Tier::T4(()), 'mace is T4');
    assert(mace_item.item_type == Type::Bludgeon_or_Metal(()), 'mace is bludgeon');
    assert(mace_item.slot == Slot::Weapon(()), 'mace is weapon');

    let club_id = constants::ItemId::Club;
    let club_item = ImplLoot::get_item(club_id);
    assert(club_item.tier == Tier::T5(()), 'club is T5');
    assert(club_item.item_type == Type::Bludgeon_or_Metal(()), 'club is bludgeon');
    assert(club_item.slot == Slot::Weapon(()), 'club is weapon');
}
