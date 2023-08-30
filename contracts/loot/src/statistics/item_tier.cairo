use array::ArrayTrait;
use lootitems::statistics::item_tier;
use lootitems::statistics::constants::ItemId;
use combat::constants::CombatEnums::Tier;

fn get(id: u8) -> Tier {
    if id == ItemId::Pendant {
        Tier::T1(())
    } else if id == ItemId::Necklace {
        Tier::T2(())
    } else if id == ItemId::Amulet {
        Tier::T1(())
    } else if id == ItemId::GoldRing {
        Tier::T1(())
    } else if id == ItemId::SilverRing {
        Tier::T2(())
    } else if id == ItemId::BronzeRing {
        Tier::T3(())
    } else if id == ItemId::PlatinumRing {
        Tier::T1(())
    } else if id == ItemId::TitaniumRing {
        Tier::T1(())
    } else if id == ItemId::GhostWand {
        Tier::T1(())
    } else if id == ItemId::GraveWand {
        Tier::T2(())
    } else if id == ItemId::BoneWand {
        Tier::T3(())
    } else if id == ItemId::Wand {
        Tier::T5(())
    } else if id == ItemId::Grimoire {
        Tier::T1(())
    } else if id == ItemId::Chronicle {
        Tier::T2(())
    } else if id == ItemId::Tome {
        Tier::T3(())
    } else if id == ItemId::Book {
        Tier::T5(())
    } else if id == ItemId::DivineRobe {
        Tier::T1(())
    } else if id == ItemId::SilkRobe {
        Tier::T2(())
    } else if id == ItemId::LinenRobe {
        Tier::T3(())
    } else if id == ItemId::Robe {
        Tier::T4(())
    } else if id == ItemId::Shirt {
        Tier::T5(())
    } else if id == ItemId::Crown {
        Tier::T1(())
    } else if id == ItemId::DivineHood {
        Tier::T2(())
    } else if id == ItemId::SilkHood {
        Tier::T3(())
    } else if id == ItemId::LinenHood {
        Tier::T4(())
    } else if id == ItemId::Hood {
        Tier::T5(())
    } else if id == ItemId::BrightsilkSash {
        Tier::T1(())
    } else if id == ItemId::SilkSash {
        Tier::T2(())
    } else if id == ItemId::WoolSash {
        Tier::T3(())
    } else if id == ItemId::LinenSash {
        Tier::T4(())
    } else if id == ItemId::Sash {
        Tier::T5(())
    } else if id == ItemId::DivineSlippers {
        Tier::T1(())
    } else if id == ItemId::SilkSlippers {
        Tier::T2(())
    } else if id == ItemId::WoolShoes {
        Tier::T3(())
    } else if id == ItemId::LinenShoes {
        Tier::T4(())
    } else if id == ItemId::Shoes {
        Tier::T5(())
    } else if id == ItemId::DivineGloves {
        Tier::T1(())
    } else if id == ItemId::SilkGloves {
        Tier::T2(())
    } else if id == ItemId::WoolGloves {
        Tier::T3(())
    } else if id == ItemId::LinenGloves {
        Tier::T4(())
    } else if id == ItemId::Gloves {
        Tier::T5(())
    } else if id == ItemId::Katana {
        Tier::T1(())
    } else if id == ItemId::Falchion {
        Tier::T2(())
    } else if id == ItemId::Scimitar {
        Tier::T3(())
    } else if id == ItemId::LongSword {
        Tier::T4(())
    } else if id == ItemId::ShortSword {
        Tier::T5(())
    } else if id == ItemId::DemonHusk {
        Tier::T1(())
    } else if id == ItemId::DragonskinArmor {
        Tier::T2(())
    } else if id == ItemId::StuddedLeatherArmor {
        Tier::T3(())
    } else if id == ItemId::HardLeatherArmor {
        Tier::T4(())
    } else if id == ItemId::LeatherArmor {
        Tier::T5(())
    } else if id == ItemId::DemonCrown {
        Tier::T1(())
    } else if id == ItemId::DragonsCrown {
        Tier::T2(())
    } else if id == ItemId::WarCap {
        Tier::T3(())
    } else if id == ItemId::LeatherCap {
        Tier::T4(())
    } else if id == ItemId::Cap {
        Tier::T5(())
    } else if id == ItemId::DemonhideBelt {
        Tier::T1(())
    } else if id == ItemId::DragonskinBelt {
        Tier::T2(())
    } else if id == ItemId::StuddedLeatherBelt {
        Tier::T3(())
    } else if id == ItemId::HardLeatherBelt {
        Tier::T4(())
    } else if id == ItemId::LeatherBelt {
        Tier::T5(())
    } else if id == ItemId::DemonhideBoots {
        Tier::T1(())
    } else if id == ItemId::DragonskinBoots {
        Tier::T2(())
    } else if id == ItemId::StuddedLeatherBoots {
        Tier::T3(())
    } else if id == ItemId::HardLeatherBoots {
        Tier::T4(())
    } else if id == ItemId::LeatherBoots {
        Tier::T5(())
    } else if id == ItemId::DemonsHands {
        Tier::T1(())
    } else if id == ItemId::DragonskinGloves {
        Tier::T2(())
    } else if id == ItemId::StuddedLeatherGloves {
        Tier::T3(())
    } else if id == ItemId::HardLeatherGloves {
        Tier::T4(())
    } else if id == ItemId::LeatherGloves {
        Tier::T5(())
    } else if id == ItemId::Warhammer {
        Tier::T1(())
    } else if id == ItemId::Quarterstaff {
        Tier::T2(())
    } else if id == ItemId::Maul {
        Tier::T3(())
    } else if id == ItemId::Mace {
        Tier::T4(())
    } else if id == ItemId::Club {
        Tier::T5(())
    } else if id == ItemId::HolyChestplate {
        Tier::T1(())
    } else if id == ItemId::OrnateChestplate {
        Tier::T2(())
    } else if id == ItemId::PlateMail {
        Tier::T3(())
    } else if id == ItemId::ChainMail {
        Tier::T4(())
    } else if id == ItemId::RingMail {
        Tier::T5(())
    } else if id == ItemId::AncientHelm {
        Tier::T1(())
    } else if id == ItemId::OrnateHelm {
        Tier::T2(())
    } else if id == ItemId::GreatHelm {
        Tier::T3(())
    } else if id == ItemId::FullHelm {
        Tier::T4(())
    } else if id == ItemId::Helm {
        Tier::T5(())
    } else if id == ItemId::OrnateBelt {
        Tier::T1(())
    } else if id == ItemId::WarBelt {
        Tier::T2(())
    } else if id == ItemId::PlatedBelt {
        Tier::T3(())
    } else if id == ItemId::MeshBelt {
        Tier::T4(())
    } else if id == ItemId::HeavyBelt {
        Tier::T5(())
    } else if id == ItemId::HolyGreaves {
        Tier::T1(())
    } else if id == ItemId::OrnateGreaves {
        Tier::T2(())
    } else if id == ItemId::Greaves {
        Tier::T3(())
    } else if id == ItemId::ChainBoots {
        Tier::T4(())
    } else if id == ItemId::HeavyBoots {
        Tier::T5(())
    } else if id == ItemId::HolyGauntlets {
        Tier::T1(())
    } else if id == ItemId::OrnateGauntlets {
        Tier::T2(())
    } else if id == ItemId::Gauntlets {
        Tier::T3(())
    } else if id == ItemId::ChainGloves {
        Tier::T4(())
    } else if id == ItemId::HeavyGloves {
        Tier::T5(())
    } else {
        Tier::T5(())
    }
}

#[test]
#[available_gas(3000000)]
fn test_get_item_tiers() {
    let pendant = ItemId::Pendant;
    let pendant_tier = get(pendant);
    assert(pendant_tier == Tier::T1(()), 'pendant is T1');

    let necklace = ItemId::Necklace;
    let necklace_tier = get(necklace);
    assert(necklace_tier == Tier::T2(()), 'necklace is T2');

    let amulet = ItemId::Amulet;
    let amulet_tier = get(amulet);
    assert(amulet_tier == Tier::T1(()), 'amulet is T1');

    let silver_ring = ItemId::SilverRing;
    let silver_ring_tier = get(silver_ring);
    assert(silver_ring_tier == Tier::T2(()), 'silver ring is T2');

    let bronze_ring = ItemId::BronzeRing;
    let bronze_ring_tier = get(bronze_ring);
    assert(bronze_ring_tier == Tier::T3(()), 'bronze ring is T3');

    let platinum_ring = ItemId::PlatinumRing;
    let platinum_ring_tier = get(platinum_ring);
    assert(platinum_ring_tier == Tier::T1(()), 'platinum ring is T1');

    let titanium_ring = ItemId::TitaniumRing;
    let titanium_ring_tier = get(titanium_ring);
    assert(titanium_ring_tier == Tier::T1(()), 'titanium ring is T1');

    let gold_ring = ItemId::GoldRing;
    let gold_ring_tier = get(gold_ring);
    assert(gold_ring_tier == Tier::T1(()), 'gold ring is T1');

    let ghost_wand = ItemId::GhostWand;
    let ghost_wand_tier = get(ghost_wand);
    assert(ghost_wand_tier == Tier::T1(()), 'ghost wand is T1');

    let grave_wand = ItemId::GraveWand;
    let grave_wand_tier = get(grave_wand);
    assert(grave_wand_tier == Tier::T2(()), 'grave wand is T2');

    let bone_wand = ItemId::BoneWand;
    let bone_wand_tier = get(bone_wand);
    assert(bone_wand_tier == Tier::T3(()), 'bone wand is T3');

    let wand = ItemId::Wand;
    let wand_tier = get(wand);
    assert(wand_tier == Tier::T5(()), 'wand is T5');

    let grimoire = ItemId::Grimoire;
    let grimoire_tier = get(grimoire);
    assert(grimoire_tier == Tier::T1(()), 'grimoire is T1');

    let chronicle = ItemId::Chronicle;
    let chronicle_tier = get(chronicle);
    assert(chronicle_tier == Tier::T2(()), 'chronicle is T2');

    let tome = ItemId::Tome;
    let tome_tier = get(tome);
    assert(tome_tier == Tier::T3(()), 'tome is T3');

    let book = ItemId::Book;
    let book_tier = get(book);
    assert(book_tier == Tier::T5(()), 'book is T5');

    let divine_robe_id = ItemId::DivineRobe;
    let divine_robe_tier = get(divine_robe_id);
    assert(divine_robe_tier == Tier::T1(()), 'divine robe is T1');

    let silk_robe_id = ItemId::SilkRobe;
    let silk_robe_tier = get(silk_robe_id);
    assert(silk_robe_tier == Tier::T2(()), 'silk robe is T2');

    let linen_robe_id = ItemId::LinenRobe;
    let linen_robe_tier = get(linen_robe_id);
    assert(linen_robe_tier == Tier::T3(()), 'linen robe is T3');

    let robe_id = ItemId::Robe;
    let robe_tier = get(robe_id);
    assert(robe_tier == Tier::T4(()), 'robe is T4');

    let shirt_id = ItemId::Shirt;
    let shirt_tier = get(shirt_id);
    assert(shirt_tier == Tier::T5(()), 'shirt is T5');

    assert(get(255) == Tier::T5(()), 'undefined is T5');
}
