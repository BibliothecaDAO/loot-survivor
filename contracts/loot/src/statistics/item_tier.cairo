use array::ArrayTrait;
use loot::statistics::item_tier;
use loot::statistics::constants::ItemId;
use loot::statistics::constants::ItemTier;

fn get(id: u8) -> u8 {
    if id == ItemId::Pendant {
        return ItemTier::Pendant;
    } else if id == ItemId::Necklace {
        return ItemTier::Necklace;
    } else if id == ItemId::Amulet {
        return ItemTier::Amulet;
    } else if id == ItemId::SilverRing {
        return ItemTier::SilverRing;
    } else if id == ItemId::BronzeRing {
        return ItemTier::BronzeRing;
    } else if id == ItemId::PlatinumRing {
        return ItemTier::PlatinumRing;
    } else if id == ItemId::TitaniumRing {
        return ItemTier::TitaniumRing;
    } else if id == ItemId::GoldRing {
        return ItemTier::GoldRing;
    } else if id == ItemId::GhostWand {
        return ItemTier::GhostWand;
    } else if id == ItemId::GraveWand {
        return ItemTier::GraveWand;
    } else if id == ItemId::BoneWand {
        return ItemTier::BoneWand;
    } else if id == ItemId::Wand {
        return ItemTier::Wand;
    } else if id == ItemId::Grimoire {
        return ItemTier::Grimoire;
    } else if id == ItemId::Chronicle {
        return ItemTier::Chronicle;
    } else if id == ItemId::Tome {
        return ItemTier::Tome;
    } else if id == ItemId::Book {
        return ItemTier::Book;
    } else if id == ItemId::DivineRobe {
        return ItemTier::DivineRobe;
    } else if id == ItemId::SilkRobe {
        return ItemTier::SilkRobe;
    } else if id == ItemId::LinenRobe {
        return ItemTier::LinenRobe;
    } else if id == ItemId::Robe {
        return ItemTier::Robe;
    } else if id == ItemId::Shirt {
        return ItemTier::Shirt;
    } else if id == ItemId::Crown {
        return ItemTier::Crown;
    } else if id == ItemId::DivineHood {
        return ItemTier::DivineHood;
    } else if id == ItemId::SilkHood {
        return ItemTier::SilkHood;
    } else if id == ItemId::LinenHood {
        return ItemTier::LinenHood;
    } else if id == ItemId::Hood {
        return ItemTier::Hood;
    } else if id == ItemId::BrightsilkSash {
        return ItemTier::BrightsilkSash;
    } else if id == ItemId::SilkSash {
        return ItemTier::SilkSash;
    } else if id == ItemId::WoolSash {
        return ItemTier::WoolSash;
    } else if id == ItemId::LinenSash {
        return ItemTier::LinenSash;
    } else if id == ItemId::Sash {
        return ItemTier::Sash;
    } else if id == ItemId::DivineSlippers {
        return ItemTier::DivineSlippers;
    } else if id == ItemId::SilkSlippers {
        return ItemTier::SilkSlippers;
    } else if id == ItemId::WoolShoes {
        return ItemTier::WoolShoes;
    } else if id == ItemId::LinenShoes {
        return ItemTier::LinenShoes;
    } else if id == ItemId::Shoes {
        return ItemTier::Shoes;
    } else if id == ItemId::DivineGloves {
        return ItemTier::DivineGloves;
    } else if id == ItemId::SilkGloves {
        return ItemTier::SilkGloves;
    } else if id == ItemId::WoolGloves {
        return ItemTier::WoolGloves;
    } else if id == ItemId::LinenGloves {
        return ItemTier::LinenGloves;
    } else if id == ItemId::Gloves {
        return ItemTier::Gloves;
    } else if id == ItemId::Katana {
        return ItemTier::Katana;
    } else if id == ItemId::Falchion {
        return ItemTier::Falchion;
    } else if id == ItemId::Scimitar {
        return ItemTier::Scimitar;
    } else if id == ItemId::LongSword {
        return ItemTier::LongSword;
    } else if id == ItemId::ShortSword {
        return ItemTier::ShortSword;
    } else if id == ItemId::DemonHusk {
        return ItemTier::DemonHusk;
    } else if id == ItemId::DragonskinArmor {
        return ItemTier::DragonskinArmor;
    } else if id == ItemId::StuddedLeatherArmor {
        return ItemTier::StuddedLeatherArmor;
    } else if id == ItemId::HardLeatherArmor {
        return ItemTier::HardLeatherArmor;
    } else if id == ItemId::LeatherArmor {
        return ItemTier::LeatherArmor;
    } else if id == ItemId::DemonCrown {
        return ItemTier::DemonCrown;
    } else if id == ItemId::DragonsCrown {
        return ItemTier::DragonsCrown;
    } else if id == ItemId::WarCap {
        return ItemTier::WarCap;
    } else if id == ItemId::LeatherCap {
        return ItemTier::LeatherCap;
    } else if id == ItemId::Cap {
        return ItemTier::Cap;
    } else if id == ItemId::DemonhideBelt {
        return ItemTier::DemonhideBelt;
    } else if id == ItemId::DragonskinBelt {
        return ItemTier::DragonskinBelt;
    } else if id == ItemId::StuddedLeatherBelt {
        return ItemTier::StuddedLeatherBelt;
    } else if id == ItemId::HardLeatherBelt {
        return ItemTier::HardLeatherBelt;
    } else if id == ItemId::LeatherBelt {
        return ItemTier::LeatherBelt;
    } else if id == ItemId::DemonhideBoots {
        return ItemTier::DemonhideBoots;
    } else if id == ItemId::DragonskinBoots {
        return ItemTier::DragonskinBoots;
    } else if id == ItemId::StuddedLeatherBoots {
        return ItemTier::StuddedLeatherBoots;
    } else if id == ItemId::HardLeatherBoots {
        return ItemTier::HardLeatherBoots;
    } else if id == ItemId::LeatherBoots {
        return ItemTier::LeatherBoots;
    } else if id == ItemId::DemonsHands {
        return ItemTier::DemonsHands;
    } else if id == ItemId::DragonskinGloves {
        return ItemTier::DragonskinGloves;
    } else if id == ItemId::StuddedLeatherGloves {
        return ItemTier::StuddedLeatherGloves;
    } else if id == ItemId::HardLeatherGloves {
        return ItemTier::HardLeatherGloves;
    } else if id == ItemId::LeatherGloves {
        return ItemTier::LeatherGloves;
    } else if id == ItemId::Warhammer {
        return ItemTier::Warhammer;
    } else if id == ItemId::Quarterstaff {
        return ItemTier::Quarterstaff;
    } else if id == ItemId::Maul {
        return ItemTier::Maul;
    } else if id == ItemId::Mace {
        return ItemTier::Mace;
    } else if id == ItemId::Club {
        return ItemTier::Club;
    } else if id == ItemId::HolyChestplate {
        return ItemTier::HolyChestplate;
    } else if id == ItemId::OrnateChestplate {
        return ItemTier::OrnateChestplate;
    } else if id == ItemId::PlateMail {
        return ItemTier::PlateMail;
    } else if id == ItemId::ChainMail {
        return ItemTier::ChainMail;
    } else if id == ItemId::RingMail {
        return ItemTier::RingMail;
    } else if id == ItemId::AncientHelm {
        return ItemTier::AncientHelm;
    } else if id == ItemId::OrnateHelm {
        return ItemTier::OrnateHelm;
    } else if id == ItemId::GreatHelm {
        return ItemTier::GreatHelm;
    } else if id == ItemId::FullHelm {
        return ItemTier::FullHelm;
    } else if id == ItemId::Helm {
        return ItemTier::Helm;
    } else if id == ItemId::OrnateBelt {
        return ItemTier::OrnateBelt;
    } else if id == ItemId::WarBelt {
        return ItemTier::WarBelt;
    } else if id == ItemId::PlatedBelt {
        return ItemTier::PlatedBelt;
    } else if id == ItemId::MeshBelt {
        return ItemTier::MeshBelt;
    } else if id == ItemId::HeavyBelt {
        return ItemTier::HeavyBelt;
    } else if id == ItemId::HolyGreaves {
        return ItemTier::HolyGreaves;
    } else if id == ItemId::OrnateGreaves {
        return ItemTier::OrnateGreaves;
    } else if id == ItemId::Greaves {
        return ItemTier::Greaves;
    } else if id == ItemId::ChainBoots {
        return ItemTier::ChainBoots;
    } else if id == ItemId::HeavyBoots {
        return ItemTier::HeavyBoots;
    } else if id == ItemId::HolyGauntlets {
        return ItemTier::HolyGauntlets;
    } else if id == ItemId::OrnateGauntlets {
        return ItemTier::OrnateGauntlets;
    } else if id == ItemId::Gauntlets {
        return ItemTier::Gauntlets;
    } else if id == ItemId::ChainGloves {
        return ItemTier::ChainGloves;
    } else if id == ItemId::HeavyGloves {
        return ItemTier::HeavyGloves;
    } else {
        // invalid id passed in
        return 0;
    }
}


#[test]
#[available_gas(3000000)]
fn test_get_item_tiers() {
    let pendant = ItemId::Pendant;
    let pendant_tier = get(pendant);
    assert(pendant_tier == 1, 'pendant is T1');

    let necklace = ItemId::Necklace;
    let necklace_tier = get(necklace);
    assert(necklace_tier == 1, 'necklace is T1');

    let amulet = ItemId::Amulet;
    let amulet_tier = get(amulet);
    assert(amulet_tier == 1, 'amulet is T1');

    let silver_ring = ItemId::SilverRing;
    let silver_ring_tier = get(silver_ring);
    assert(silver_ring_tier == 2, 'silver ring is T2');

    let bronze_ring = ItemId::BronzeRing;
    let bronze_ring_tier = get(bronze_ring);
    assert(bronze_ring_tier == 3, 'bronze ring is T3');

    let platinum_ring = ItemId::PlatinumRing;
    let platinum_ring_tier = get(platinum_ring);
    assert(platinum_ring_tier == 1, 'platinum ring is T1');

    let titanium_ring = ItemId::TitaniumRing;
    let titanium_ring_tier = get(titanium_ring);
    assert(titanium_ring_tier == 1, 'titanium ring is T1');

    let gold_ring = ItemId::GoldRing;
    let gold_ring_tier = get(gold_ring);
    assert(gold_ring_tier == 1, 'gold ring is T1');

    let ghost_wand = ItemId::GhostWand;
    let ghost_wand_tier = get(ghost_wand);
    assert(ghost_wand_tier == 2, 'ghost wand is T2');

    let grave_wand = ItemId::GraveWand;
    let grave_wand_tier = get(grave_wand);
    assert(grave_wand_tier == 3, 'grave wand is T3');

    let bone_wand = ItemId::BoneWand;
    let bone_wand_tier = get(bone_wand);
    assert(bone_wand_tier == 4, 'bone wand is T4');

    let wand = ItemId::Wand;
    let wand_tier = get(wand);
    assert(wand_tier == 5, 'wand is T5');

    let grimoire = ItemId::Grimoire;
    let grimoire_tier = get(grimoire);
    assert(grimoire_tier == 2, 'grimoire is T2');

    let chronicle = ItemId::Chronicle;
    let chronicle_tier = get(chronicle);
    assert(chronicle_tier == 3, 'chronicle is T3');

    let tome = ItemId::Tome;
    let tome_tier = get(tome);
    assert(tome_tier == 4, 'tome is T4');

    let book = ItemId::Book;
    let book_tier = get(book);
    assert(book_tier == 5, 'book is T5');

    let divine_robe = ItemId::DivineRobe;
    let divine_robe_tier = get(divine_robe);
    assert(divine_robe_tier == 1, 'divine robe is T1');

    let silk_robe = ItemId::SilkRobe;
    let silk_robe_tier = get(silk_robe);
    assert(silk_robe_tier == 2, 'silk robe is T2');

    let linen_robe = ItemId::LinenRobe;
    let linen_robe_tier = get(linen_robe);
    assert(linen_robe_tier == 3, 'linen robe is T3');

    let robe = ItemId::Robe;
    let robe_tier = get(robe);
    assert(robe_tier == 4, 'robe is T4');

    let shirt = ItemId::Shirt;
    let shirt_tier = get(shirt);
    assert(shirt_tier == 5, 'shirt is T5');

    let crown = ItemId::Crown;
    let crown_tier = get(crown);
    assert(crown_tier == 1, 'crown is T1');

    let divine_hood = ItemId::DivineHood;
    let divine_hood_tier = get(divine_hood);
    assert(divine_hood_tier == 2, 'divine hood is T2');

    let silk_hood = ItemId::SilkHood;
    let silk_hood_tier = get(silk_hood);
    assert(silk_hood_tier == 3, 'silk hood is T3');

    let linen_hood = ItemId::LinenHood;
    let linen_hood_tier = get(linen_hood);
    assert(linen_hood_tier == 4, 'linen hood is T4');

    let hood = ItemId::Hood;
    let hood_tier = get(hood);
    assert(hood_tier == 5, 'hood is T5');

    let brightsilk_sash = ItemId::BrightsilkSash;
    let brightsilk_sash_tier = get(brightsilk_sash);
    assert(brightsilk_sash_tier == 1, 'brightsilk sash is T1');

    let silk_sash = ItemId::SilkSash;
    let silk_sash_tier = get(silk_sash);
    assert(silk_sash_tier == 2, 'silk sash is T2');

    let wool_sash = ItemId::WoolSash;
    let wool_sash_tier = get(wool_sash);
    assert(wool_sash_tier == 3, 'wool sash is T3');

    let linen_sash = ItemId::LinenSash;
    let linen_sash_tier = get(linen_sash);
    assert(linen_sash_tier == 4, 'linen sash is T4');

    let sash = ItemId::Sash;
    let sash_tier = get(sash);
    assert(sash_tier == 5, 'sash is T5');

    let divine_slippers = ItemId::DivineSlippers;
    let divine_slippers_tier = get(divine_slippers);
    assert(divine_slippers_tier == 1, 'divine slippers is T1');

    let silk_slippers = ItemId::SilkSlippers;
    let silk_slippers_tier = get(silk_slippers);
    assert(silk_slippers_tier == 2, 'silk slippers is T2');

    let wool_shoes = ItemId::WoolShoes;
    let wool_shoes_tier = get(wool_shoes);
    assert(wool_shoes_tier == 3, 'wool shoes is T3');

    let linen_shoes = ItemId::LinenShoes;
    let linen_shoes_tier = get(linen_shoes);
    assert(linen_shoes_tier == 4, 'linen shoes is T4');

    let shoes = ItemId::Shoes;
    let shoes_tier = get(shoes);
    assert(shoes_tier == 5, 'shoes is T5');

    let divine_gloves = ItemId::DivineGloves;
    let divine_gloves_tier = get(divine_gloves);
    assert(divine_gloves_tier == 1, 'divine gloves is T1');

    let silk_gloves = ItemId::SilkGloves;
    let silk_gloves_tier = get(silk_gloves);
    assert(silk_gloves_tier == 2, 'silk gloves is T2');

    let wool_gloves = ItemId::WoolGloves;
    let wool_gloves_tier = get(wool_gloves);
    assert(wool_gloves_tier == 3, 'wool gloves is T3');

    let linen_gloves = ItemId::LinenGloves;
    let linen_gloves_tier = get(linen_gloves);
    assert(linen_gloves_tier == 4, 'linen gloves is T4');

    let gloves = ItemId::Gloves;
    let gloves_tier = get(gloves);
    assert(gloves_tier == 5, 'gloves is T5');

    let katana = ItemId::Katana;
    let katana_tier = get(katana);
    assert(katana_tier == 1, 'katana is T1');

    let falchion = ItemId::Falchion;
    let falchion_tier = get(falchion);
    assert(falchion_tier == 2, 'falchion is T2');

    let scimitar = ItemId::Scimitar;
    let scimitar_tier = get(scimitar);
    assert(scimitar_tier == 3, 'scimitar is T3');

    let long_sword = ItemId::LongSword;
    let long_sword_tier = get(long_sword);
    assert(long_sword_tier == 4, 'long sword is T4');

    let short_sword = ItemId::ShortSword;
    let short_sword_tier = get(short_sword);
    assert(short_sword_tier == 5, 'short sword is T5');

    let demon_husk = ItemId::DemonHusk;
    let demon_husk_tier = get(demon_husk);
    assert(demon_husk_tier == 1, 'demon husk is T1');

    let dragonskin_armor = ItemId::DragonskinArmor;
    let dragonskin_armor_tier = get(dragonskin_armor);
    assert(dragonskin_armor_tier == 2, 'dragonskin armor is T2');

    let studded_leather_armor = ItemId::StuddedLeatherArmor;
    let studded_leather_armor_tier = get(studded_leather_armor);
    assert(studded_leather_armor_tier == 3, 'studded leather armor is T3');

    let hard_leather_armor = ItemId::HardLeatherArmor;
    let hard_leather_armor_tier = get(hard_leather_armor);
    assert(hard_leather_armor_tier == 4, 'hard leather armor is T4');

    let leather_armor = ItemId::LeatherArmor;
    let leather_armor_tier = get(leather_armor);
    assert(leather_armor_tier == 5, 'leather armor is T5');

    let demon_crown = ItemId::DemonCrown;
    let demon_crown_tier = get(demon_crown);
    assert(demon_crown_tier == 1, 'demon crown is T1');

    let dragons_crown = ItemId::DragonsCrown;
    let dragons_crown_tier = get(dragons_crown);
    assert(dragons_crown_tier == 2, 'dragons crown is T2');

    let war_cap = ItemId::WarCap;
    let war_cap_tier = get(war_cap);
    assert(war_cap_tier == 3, 'war cap is T3');

    let leather_cap = ItemId::LeatherCap;
    let leather_cap_tier = get(leather_cap);
    assert(leather_cap_tier == 4, 'leather cap is T4');

    let cap = ItemId::Cap;
    let cap_tier = get(cap);
    assert(cap_tier == 5, 'cap is T5');

    let demonhide_belt = ItemId::DemonhideBelt;
    let demonhide_belt_tier = get(demonhide_belt);
    assert(demonhide_belt_tier == 1, 'demonhide belt is T1');

    let dragonskin_belt = ItemId::DragonskinBelt;
    let dragonskin_belt_tier = get(dragonskin_belt);
    assert(dragonskin_belt_tier == 2, 'dragonskin belt is T2');

    let studded_leather_belt = ItemId::StuddedLeatherBelt;
    let studded_leather_belt_tier = get(studded_leather_belt);
    assert(studded_leather_belt_tier == 3, 'studded leather belt is T3');

    let hard_leather_belt = ItemId::HardLeatherBelt;
    let hard_leather_belt_tier = get(hard_leather_belt);
    assert(hard_leather_belt_tier == 4, 'hard leather belt is T4');

    let leather_belt = ItemId::LeatherBelt;
    let leather_belt_tier = get(leather_belt);
    assert(leather_belt_tier == 5, 'leather belt is T5');

    let demonhide_boots = ItemId::DemonhideBoots;
    let demonhide_boots_tier = get(demonhide_boots);
    assert(demonhide_boots_tier == 1, 'demonhide boots is T1');

    let dragonskin_boots = ItemId::DragonskinBoots;
    let dragonskin_boots_tier = get(dragonskin_boots);
    assert(dragonskin_boots_tier == 2, 'dragonskin boots is T2');

    let studded_leather_boots = ItemId::StuddedLeatherBoots;
    let studded_leather_boots_tier = get(studded_leather_boots);
    assert(studded_leather_boots_tier == 3, 'studded leather boots is T3');

    let hard_leather_boots = ItemId::HardLeatherBoots;
    let hard_leather_boots_tier = get(hard_leather_boots);
    assert(hard_leather_boots_tier == 4, 'hard leather boots is T4');

    let leather_boots = ItemId::LeatherBoots;
    let leather_boots_tier = get(leather_boots);
    assert(leather_boots_tier == 5, 'leather boots is T5');

    let demons_hands = ItemId::DemonsHands;
    let demons_hands_tier = get(demons_hands);
    assert(demons_hands_tier == 1, 'demons hands is T1');

    let dragonskin_gloves = ItemId::DragonskinGloves;
    let dragonskin_gloves_tier = get(dragonskin_gloves);
    assert(dragonskin_gloves_tier == 2, 'dragonskin gloves is T2');

    let studded_leather_gloves = ItemId::StuddedLeatherGloves;
    let studded_leather_gloves_tier = get(studded_leather_gloves);
    assert(studded_leather_gloves_tier == 3, 'studded leather gloves is T3');

    let hard_leather_gloves = ItemId::HardLeatherGloves;
    let hard_leather_gloves_tier = get(hard_leather_gloves);
    assert(hard_leather_gloves_tier == 4, 'hard leather gloves is T4');

    let leather_gloves = ItemId::LeatherGloves;
    let leather_gloves_tier = get(leather_gloves);
    assert(leather_gloves_tier == 5, 'leather gloves is T5');

    let warhammer = ItemId::Warhammer;
    let warhammer_tier = get(warhammer);
    assert(warhammer_tier == 1, 'warhammer is T1');

    let quarterstaff = ItemId::Quarterstaff;
    let quarterstaff_tier = get(quarterstaff);
    assert(quarterstaff_tier == 2, 'quarterstaff is T2');

    let maul = ItemId::Maul;
    let maul_tier = get(maul);
    assert(maul_tier == 3, 'maul is T3');

    let mace = ItemId::Mace;
    let mace_tier = get(mace);
    assert(mace_tier == 4, 'mace is T4');

    let club = ItemId::Club;
    let club_tier = get(club);
    assert(club_tier == 5, 'club is T5');

    let holy_chestplate = ItemId::HolyChestplate;
    let holy_chestplate_tier = get(holy_chestplate);
    assert(holy_chestplate_tier == 1, 'holy chestplate is T1');

    let ornate_chestplate = ItemId::OrnateChestplate;
    let ornate_chestplate_tier = get(ornate_chestplate);
    assert(ornate_chestplate_tier == 2, 'ornate chestplate is T2');

    let plate_mail = ItemId::PlateMail;
    let plate_mail_tier = get(plate_mail);
    assert(plate_mail_tier == 3, 'plate mail is T3');

    let chain_mail = ItemId::ChainMail;
    let chain_mail_tier = get(chain_mail);
    assert(chain_mail_tier == 4, 'chain mail is T4');

    let ring_mail = ItemId::RingMail;
    let ring_mail_tier = get(ring_mail);
    assert(ring_mail_tier == 5, 'ring mail is T5');

    let ancient_helm = ItemId::AncientHelm;
    let ancient_helm_tier = get(ancient_helm);
    assert(ancient_helm_tier == 1, 'ancient helm is T1');

    let ornate_helm = ItemId::OrnateHelm;
    let ornate_helm_tier = get(ornate_helm);
    assert(ornate_helm_tier == 2, 'ornate helm is T2');

    let great_helm = ItemId::GreatHelm;
    let great_helm_tier = get(great_helm);
    assert(great_helm_tier == 3, 'great helm is T3');

    let full_helm = ItemId::FullHelm;
    let full_helm_tier = get(full_helm);
    assert(full_helm_tier == 4, 'full helm is T4');

    let helm = ItemId::Helm;
    let helm_tier = get(helm);
    assert(helm_tier == 5, 'helm is T5');

    let ornate_belt = ItemId::OrnateBelt;
    let ornate_belt_tier = get(ornate_belt);
    assert(ornate_belt_tier == 1, 'ornate belt is T1');

    let war_belt = ItemId::WarBelt;
    let war_belt_tier = get(war_belt);
    assert(war_belt_tier == 2, 'war belt is T2');

    let plated_belt = ItemId::PlatedBelt;
    let plated_belt_tier = get(plated_belt);
    assert(plated_belt_tier == 3, 'plated belt is T3');

    let mesh_belt = ItemId::MeshBelt;
    let mesh_belt_tier = get(mesh_belt);
    assert(mesh_belt_tier == 4, 'mesh belt is T4');

    let heavy_belt = ItemId::HeavyBelt;
    let heavy_belt_tier = get(heavy_belt);
    assert(heavy_belt_tier == 5, 'heavy belt is T5');

    let holy_greaves = ItemId::HolyGreaves;
    let holy_greaves_tier = get(holy_greaves);
    assert(holy_greaves_tier == 1, 'holy greaves is T1');

    let ornate_greaves = ItemId::OrnateGreaves;
    let ornate_greaves_tier = get(ornate_greaves);
    assert(ornate_greaves_tier == 2, 'ornate greaves is T2');

    let greaves = ItemId::Greaves;
    let greaves_tier = get(greaves);
    assert(greaves_tier == 3, 'greaves is T3');

    let chain_boots = ItemId::ChainBoots;
    let chain_boots_tier = get(chain_boots);
    assert(chain_boots_tier == 4, 'chain boots is T4');

    let heavy_boots = ItemId::HeavyBoots;
    let heavy_boots_tier = get(heavy_boots);
    assert(heavy_boots_tier == 5, 'heavy boots is T5');

    let holy_gauntlets = ItemId::HolyGauntlets;
    let holy_gauntlets_tier = get(holy_gauntlets);
    assert(holy_gauntlets_tier == 1, 'holy gauntlets is T1');

    let ornate_gauntlets = ItemId::OrnateGauntlets;
    let ornate_gauntlets_tier = get(ornate_gauntlets);
    assert(ornate_gauntlets_tier == 2, 'ornate gauntlets is T2');

    let gauntlets = ItemId::Gauntlets;
    let gauntlets_tier = get(gauntlets);
    assert(gauntlets_tier == 3, 'gauntlets is T3');

    let chain_gloves = ItemId::ChainGloves;
    let chain_gloves_tier = get(chain_gloves);
    assert(chain_gloves_tier == 4, 'chain gloves is T4');

    let heavy_gloves = ItemId::HeavyGloves;
    let heavy_gloves_tier = get(heavy_gloves);
    assert(heavy_gloves_tier == 5, 'heavy gloves is T5');
}
