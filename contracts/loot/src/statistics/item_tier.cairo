use array::ArrayTrait;
use lootitems::statistics::item_tier;
use lootitems::statistics::constants::ItemId;
use combat::constants::CombatEnums::Tier;

fn get(id: u8) -> Tier {
    if id == ItemId::Pendant {
        return Tier::T1(());
    } else if id == ItemId::Necklace {
        return Tier::T1(());
    } else if id == ItemId::Amulet {
        return Tier::T1(());
    } else if id == ItemId::GoldRing {
        return Tier::T1(());
    } else if id == ItemId::SilverRing {
        return Tier::T2(());
    } else if id == ItemId::BronzeRing {
        return Tier::T3(());
    } else if id == ItemId::PlatinumRing {
        return Tier::T1(());
    } else if id == ItemId::TitaniumRing {
        return Tier::T1(());
    } else if id == ItemId::GhostWand {
        return Tier::T1(());
    } else if id == ItemId::GraveWand {
        return Tier::T2(());
    } else if id == ItemId::BoneWand {
        return Tier::T3(());
    } else if id == ItemId::Wand {
        return Tier::T5(());
    } else if id == ItemId::Grimoire {
        return Tier::T1(());
    } else if id == ItemId::Chronicle {
        return Tier::T2(());
    } else if id == ItemId::Tome {
        return Tier::T3(());
    } else if id == ItemId::Book {
        return Tier::T5(());
    } else if id == ItemId::DivineRobe {
        return Tier::T1(());
    } else if id == ItemId::SilkRobe {
        return Tier::T2(());
    } else if id == ItemId::LinenRobe {
        return Tier::T3(());
    } else if id == ItemId::Robe {
        return Tier::T4(());
    } else if id == ItemId::Shirt {
        return Tier::T5(());
    } else if id == ItemId::Crown {
        return Tier::T1(());
    } else if id == ItemId::DivineHood {
        return Tier::T2(());
    } else if id == ItemId::SilkHood {
        return Tier::T3(());
    } else if id == ItemId::LinenHood {
        return Tier::T4(());
    } else if id == ItemId::Hood {
        return Tier::T5(());
    } else if id == ItemId::BrightsilkSash {
        return Tier::T1(());
    } else if id == ItemId::SilkSash {
        return Tier::T2(());
    } else if id == ItemId::WoolSash {
        return Tier::T3(());
    } else if id == ItemId::LinenSash {
        return Tier::T4(());
    } else if id == ItemId::Sash {
        return Tier::T5(());
    } else if id == ItemId::DivineSlippers {
        return Tier::T1(());
    } else if id == ItemId::SilkSlippers {
        return Tier::T2(());
    } else if id == ItemId::WoolShoes {
        return Tier::T3(());
    } else if id == ItemId::LinenShoes {
        return Tier::T4(());
    } else if id == ItemId::Shoes {
        return Tier::T5(());
    } else if id == ItemId::DivineGloves {
        return Tier::T1(());
    } else if id == ItemId::SilkGloves {
        return Tier::T2(());
    } else if id == ItemId::WoolGloves {
        return Tier::T3(());
    } else if id == ItemId::LinenGloves {
        return Tier::T4(());
    } else if id == ItemId::Gloves {
        return Tier::T5(());
    } else if id == ItemId::Katana {
        return Tier::T1(());
    } else if id == ItemId::Falchion {
        return Tier::T2(());
    } else if id == ItemId::Scimitar {
        return Tier::T3(());
    } else if id == ItemId::LongSword {
        return Tier::T4(());
    } else if id == ItemId::ShortSword {
        return Tier::T5(());
    } else if id == ItemId::DemonHusk {
        return Tier::T1(());
    } else if id == ItemId::DragonskinArmor {
        return Tier::T2(());
    } else if id == ItemId::StuddedLeatherArmor {
        return Tier::T3(());
    } else if id == ItemId::HardLeatherArmor {
        return Tier::T4(());
    } else if id == ItemId::LeatherArmor {
        return Tier::T5(());
    } else if id == ItemId::DemonCrown {
        return Tier::T1(());
    } else if id == ItemId::DragonsCrown {
        return Tier::T2(());
    } else if id == ItemId::WarCap {
        return Tier::T3(());
    } else if id == ItemId::LeatherCap {
        return Tier::T4(());
    } else if id == ItemId::Cap {
        return Tier::T5(());
    } else if id == ItemId::DemonhideBelt {
        return Tier::T1(());
    } else if id == ItemId::DragonskinBelt {
        return Tier::T2(());
    } else if id == ItemId::StuddedLeatherBelt {
        return Tier::T3(());
    } else if id == ItemId::HardLeatherBelt {
        return Tier::T4(());
    } else if id == ItemId::LeatherBelt {
        return Tier::T5(());
    } else if id == ItemId::DemonhideBoots {
        return Tier::T1(());
    } else if id == ItemId::DragonskinBoots {
        return Tier::T2(());
    } else if id == ItemId::StuddedLeatherBoots {
        return Tier::T3(());
    } else if id == ItemId::HardLeatherBoots {
        return Tier::T4(());
    } else if id == ItemId::LeatherBoots {
        return Tier::T5(());
    } else if id == ItemId::DemonsHands {
        return Tier::T1(());
    } else if id == ItemId::DragonskinGloves {
        return Tier::T2(());
    } else if id == ItemId::StuddedLeatherGloves {
        return Tier::T3(());
    } else if id == ItemId::HardLeatherGloves {
        return Tier::T4(());
    } else if id == ItemId::LeatherGloves {
        return Tier::T5(());
    } else if id == ItemId::Warhammer {
        return Tier::T1(());
    } else if id == ItemId::Quarterstaff {
        return Tier::T2(());
    } else if id == ItemId::Maul {
        return Tier::T3(());
    } else if id == ItemId::Mace {
        return Tier::T4(());
    } else if id == ItemId::Club {
        return Tier::T5(());
    } else if id == ItemId::HolyChestplate {
        return Tier::T1(());
    } else if id == ItemId::OrnateChestplate {
        return Tier::T2(());
    } else if id == ItemId::PlateMail {
        return Tier::T3(());
    } else if id == ItemId::ChainMail {
        return Tier::T4(());
    } else if id == ItemId::RingMail {
        return Tier::T5(());
    } else if id == ItemId::AncientHelm {
        return Tier::T1(());
    } else if id == ItemId::OrnateHelm {
        return Tier::T2(());
    } else if id == ItemId::GreatHelm {
        return Tier::T3(());
    } else if id == ItemId::FullHelm {
        return Tier::T4(());
    } else if id == ItemId::Helm {
        return Tier::T5(());
    } else if id == ItemId::OrnateBelt {
        return Tier::T1(());
    } else if id == ItemId::WarBelt {
        return Tier::T2(());
    } else if id == ItemId::PlatedBelt {
        return Tier::T3(());
    } else if id == ItemId::MeshBelt {
        return Tier::T4(());
    } else if id == ItemId::HeavyBelt {
        return Tier::T5(());
    } else if id == ItemId::HolyGreaves {
        return Tier::T1(());
    } else if id == ItemId::OrnateGreaves {
        return Tier::T2(());
    } else if id == ItemId::Greaves {
        return Tier::T3(());
    } else if id == ItemId::ChainBoots {
        return Tier::T4(());
    } else if id == ItemId::HeavyBoots {
        return Tier::T5(());
    } else if id == ItemId::HolyGauntlets {
        return Tier::T1(());
    } else if id == ItemId::OrnateGauntlets {
        return Tier::T2(());
    } else if id == ItemId::Gauntlets {
        return Tier::T3(());
    } else if id == ItemId::ChainGloves {
        return Tier::T4(());
    } else if id == ItemId::HeavyGloves {
        return Tier::T5(());
    } else {
        // invalid id passed in
        return Tier::T5(());
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
    assert(necklace_tier == Tier::T1(()), 'necklace is T1');

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
}
