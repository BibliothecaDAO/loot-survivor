use array::ArrayTrait;
use lootitems::statistics::item_type;
use lootitems::statistics::constants::ItemId;
use lootitems::statistics::constants::ItemType;

fn get(id: u8) -> u8 {
    if id == ItemId::Pendant {
        return ItemType::Pendant;
    } else if id == ItemId::Necklace {
        return ItemType::Necklace;
    } else if id == ItemId::Amulet {
        return ItemType::Amulet;
    } else if id == ItemId::SilverRing {
        return ItemType::SilverRing;
    } else if id == ItemId::BronzeRing {
        return ItemType::BronzeRing;
    } else if id == ItemId::PlatinumRing {
        return ItemType::PlatinumRing;
    } else if id == ItemId::TitaniumRing {
        return ItemType::TitaniumRing;
    } else if id == ItemId::GoldRing {
        return ItemType::GoldRing;
    } else if id == ItemId::GhostWand {
        return ItemType::GhostWand;
    } else if id == ItemId::GraveWand {
        return ItemType::GraveWand;
    } else if id == ItemId::BoneWand {
        return ItemType::BoneWand;
    } else if id == ItemId::Wand {
        return ItemType::Wand;
    } else if id == ItemId::Grimoire {
        return ItemType::Grimoire;
    } else if id == ItemId::Chronicle {
        return ItemType::Chronicle;
    } else if id == ItemId::Tome {
        return ItemType::Tome;
    } else if id == ItemId::Book {
        return ItemType::Book;
    } else if id == ItemId::DivineRobe {
        return ItemType::DivineRobe;
    } else if id == ItemId::SilkRobe {
        return ItemType::SilkRobe;
    } else if id == ItemId::LinenRobe {
        return ItemType::LinenRobe;
    } else if id == ItemId::Robe {
        return ItemType::Robe;
    } else if id == ItemId::Shirt {
        return ItemType::Shirt;
    } else if id == ItemId::Crown {
        return ItemType::Crown;
    } else if id == ItemId::DivineHood {
        return ItemType::DivineHood;
    } else if id == ItemId::SilkHood {
        return ItemType::SilkHood;
    } else if id == ItemId::LinenHood {
        return ItemType::LinenHood;
    } else if id == ItemId::Hood {
        return ItemType::Hood;
    } else if id == ItemId::BrightsilkSash {
        return ItemType::BrightsilkSash;
    } else if id == ItemId::SilkSash {
        return ItemType::SilkSash;
    } else if id == ItemId::WoolSash {
        return ItemType::WoolSash;
    } else if id == ItemId::LinenSash {
        return ItemType::LinenSash;
    } else if id == ItemId::Sash {
        return ItemType::Sash;
    } else if id == ItemId::DivineSlippers {
        return ItemType::DivineSlippers;
    } else if id == ItemId::SilkSlippers {
        return ItemType::SilkSlippers;
    } else if id == ItemId::WoolShoes {
        return ItemType::WoolShoes;
    } else if id == ItemId::LinenShoes {
        return ItemType::LinenShoes;
    } else if id == ItemId::Shoes {
        return ItemType::Shoes;
    } else if id == ItemId::DivineGloves {
        return ItemType::DivineGloves;
    } else if id == ItemId::SilkGloves {
        return ItemType::SilkGloves;
    } else if id == ItemId::WoolGloves {
        return ItemType::WoolGloves;
    } else if id == ItemId::LinenGloves {
        return ItemType::LinenGloves;
    } else if id == ItemId::Gloves {
        return ItemType::Gloves;
    } else if id == ItemId::Katana {
        return ItemType::Katana;
    } else if id == ItemId::Falchion {
        return ItemType::Falchion;
    } else if id == ItemId::Scimitar {
        return ItemType::Scimitar;
    } else if id == ItemId::LongSword {
        return ItemType::LongSword;
    } else if id == ItemId::ShortSword {
        return ItemType::ShortSword;
    } else if id == ItemId::DemonHusk {
        return ItemType::DemonHusk;
    } else if id == ItemId::DragonskinArmor {
        return ItemType::DragonskinArmor;
    } else if id == ItemId::StuddedLeatherArmor {
        return ItemType::StuddedLeatherArmor;
    } else if id == ItemId::HardLeatherArmor {
        return ItemType::HardLeatherArmor;
    } else if id == ItemId::LeatherArmor {
        return ItemType::LeatherArmor;
    } else if id == ItemId::DemonCrown {
        return ItemType::DemonCrown;
    } else if id == ItemId::DragonsCrown {
        return ItemType::DragonsCrown;
    } else if id == ItemId::WarCap {
        return ItemType::WarCap;
    } else if id == ItemId::LeatherCap {
        return ItemType::LeatherCap;
    } else if id == ItemId::Cap {
        return ItemType::Cap;
    } else if id == ItemId::DemonhideBelt {
        return ItemType::DemonhideBelt;
    } else if id == ItemId::DragonskinBelt {
        return ItemType::DragonskinBelt;
    } else if id == ItemId::StuddedLeatherBelt {
        return ItemType::StuddedLeatherBelt;
    } else if id == ItemId::HardLeatherBelt {
        return ItemType::HardLeatherBelt;
    } else if id == ItemId::LeatherBelt {
        return ItemType::LeatherBelt;
    } else if id == ItemId::DemonhideBoots {
        return ItemType::DemonhideBoots;
    } else if id == ItemId::DragonskinBoots {
        return ItemType::DragonskinBoots;
    } else if id == ItemId::StuddedLeatherBoots {
        return ItemType::StuddedLeatherBoots;
    } else if id == ItemId::HardLeatherBoots {
        return ItemType::HardLeatherBoots;
    } else if id == ItemId::LeatherBoots {
        return ItemType::LeatherBoots;
    } else if id == ItemId::DemonsHands {
        return ItemType::DemonsHands;
    } else if id == ItemId::DragonskinGloves {
        return ItemType::DragonskinGloves;
    } else if id == ItemId::StuddedLeatherGloves {
        return ItemType::StuddedLeatherGloves;
    } else if id == ItemId::HardLeatherGloves {
        return ItemType::HardLeatherGloves;
    } else if id == ItemId::LeatherGloves {
        return ItemType::LeatherGloves;
    } else if id == ItemId::Warhammer {
        return ItemType::Warhammer;
    } else if id == ItemId::Quarterstaff {
        return ItemType::Quarterstaff;
    } else if id == ItemId::Maul {
        return ItemType::Maul;
    } else if id == ItemId::Mace {
        return ItemType::Mace;
    } else if id == ItemId::Club {
        return ItemType::Club;
    } else if id == ItemId::HolyChestplate {
        return ItemType::HolyChestplate;
    } else if id == ItemId::OrnateChestplate {
        return ItemType::OrnateChestplate;
    } else if id == ItemId::PlateMail {
        return ItemType::PlateMail;
    } else if id == ItemId::ChainMail {
        return ItemType::ChainMail;
    } else if id == ItemId::RingMail {
        return ItemType::RingMail;
    } else if id == ItemId::AncientHelm {
        return ItemType::AncientHelm;
    } else if id == ItemId::OrnateHelm {
        return ItemType::OrnateHelm;
    } else if id == ItemId::GreatHelm {
        return ItemType::GreatHelm;
    } else if id == ItemId::FullHelm {
        return ItemType::FullHelm;
    } else if id == ItemId::Helm {
        return ItemType::Helm;
    } else if id == ItemId::OrnateBelt {
        return ItemType::OrnateBelt;
    } else if id == ItemId::WarBelt {
        return ItemType::WarBelt;
    } else if id == ItemId::PlatedBelt {
        return ItemType::PlatedBelt;
    } else if id == ItemId::MeshBelt {
        return ItemType::MeshBelt;
    } else if id == ItemId::HeavyBelt {
        return ItemType::HeavyBelt;
    } else if id == ItemId::HolyGreaves {
        return ItemType::HolyGreaves;
    } else if id == ItemId::OrnateGreaves {
        return ItemType::OrnateGreaves;
    } else if id == ItemId::Greaves {
        return ItemType::Greaves;
    } else if id == ItemId::ChainBoots {
        return ItemType::ChainBoots;
    } else if id == ItemId::HeavyBoots {
        return ItemType::HeavyBoots;
    } else if id == ItemId::HolyGauntlets {
        return ItemType::HolyGauntlets;
    } else if id == ItemId::OrnateGauntlets {
        return ItemType::OrnateGauntlets;
    } else if id == ItemId::Gauntlets {
        return ItemType::Gauntlets;
    } else if id == ItemId::ChainGloves {
        return ItemType::ChainGloves;
    } else if id == ItemId::HeavyGloves {
        return ItemType::HeavyGloves;
    } else {
        // invalid id passed in
        return 0;
    }
}

#[test]
#[available_gas(3000000)]
fn test_get_item_type() {
    let warhammer = ItemId::Warhammer;
    let warhammer_type = get(warhammer);
    assert(warhammer_type == 3, 'warhammer is blunt');

    let quarterstaff = ItemId::Quarterstaff;
    let quarterstaff_type = get(quarterstaff);
    assert(quarterstaff_type == 3, 'quarterstaff is blunt');

    let maul = ItemId::Maul;
    let maul_type = get(maul);
    assert(maul_type == 3, 'maul is blunt');

    let mace = ItemId::Mace;
    let mace_type = get(mace);
    assert(mace_type == 3, 'mace is blunt');

    let club = ItemId::Club;
    let club_type = get(club);
    assert(club_type == 3, 'club is blunt');

    let katana = ItemId::Katana;
    let katana_type = get(katana);
    assert(katana_type == 2, 'katana is blade');

    let falchion = ItemId::Falchion;
    let falchion_type = get(falchion);
    assert(falchion_type == 2, 'falchion is blade');

    let scimitar = ItemId::Scimitar;
    let scimitar_type = get(scimitar);
    assert(scimitar_type == 2, 'scimitar is blade');

    let long_sword = ItemId::LongSword;
    let long_sword_type = get(long_sword);
    assert(long_sword_type == 2, 'long sword is blade');

    let short_sword = ItemId::ShortSword;
    let short_sword_type = get(short_sword);
    assert(short_sword_type == 2, 'short sword is blade');

    let ghost_wand = ItemId::GhostWand;
    let ghost_wand_type = get(ghost_wand);
    assert(ghost_wand_type == 1, 'ghost wand is magic');

    let grave_wand = ItemId::GraveWand;
    let grave_wand_type = get(grave_wand);
    assert(grave_wand_type == 1, 'grave wand is magic');

    let bone_wand = ItemId::BoneWand;
    let bone_wand_type = get(bone_wand);
    assert(bone_wand_type == 1, 'bone wand is magic');

    let wand = ItemId::Wand;
    let wand_type = get(wand);
    assert(wand_type == 1, 'wand is magic');

    let grimoire = ItemId::Grimoire;
    let grimoire_type = get(grimoire);
    assert(grimoire_type == 1, 'grimoire is magic');

    let chronicle = ItemId::Chronicle;
    let chronicle_type = get(chronicle);
    assert(chronicle_type == 1, 'chronicle is magic');

    let tome = ItemId::Tome;
    let tome_type = get(tome);
    assert(tome_type == 1, 'tome is magic');

    let book = ItemId::Book;
    let book_type = get(book);
    assert(book_type == 1, 'book is magic');

    let divine_robe = ItemId::DivineRobe;
    let divine_robe_type = get(divine_robe);
    assert(divine_robe_type == 1, 'divine robe is cloth');

    let silk_robe = ItemId::SilkRobe;
    let silk_robe_type = get(silk_robe);
    assert(silk_robe_type == 1, 'silk robe is cloth');

    let linen_robe = ItemId::LinenRobe;
    let linen_robe_type = get(linen_robe);
    assert(linen_robe_type == 1, 'linen robe is cloth');

    let robe = ItemId::Robe;
    let robe_type = get(robe);
    assert(robe_type == 1, 'robe is cloth');

    let shirt = ItemId::Shirt;
    let shirt_type = get(shirt);
    assert(shirt_type == 1, 'shirt is cloth');

    let demon_husk = ItemId::DemonHusk;
    let demon_husk_type = get(demon_husk);
    assert(demon_husk_type == 2, 'demon husk is hide');

    let dragonskin_armor = ItemId::DragonskinArmor;
    let dragonskin_armor_type = get(dragonskin_armor);
    assert(dragonskin_armor_type == 2, 'dragonskin armor is hide');

    let studded_leather_armor = ItemId::StuddedLeatherArmor;
    let studded_leather_armor_type = get(studded_leather_armor);
    assert(studded_leather_armor_type == 2, 'studded leather armor is hide');

    let hard_leather_armor = ItemId::HardLeatherArmor;
    let hard_leather_armor_type = get(hard_leather_armor);
    assert(hard_leather_armor_type == 2, 'hard leather armor is hide');

    let leather_armor = ItemId::LeatherArmor;
    let leather_armor_type = get(leather_armor);
    assert(leather_armor_type == 2, 'leather armor is hide');

    let holy_chestplate = ItemId::HolyChestplate;
    let holy_chestplate_type = get(holy_chestplate);
    assert(holy_chestplate_type == 3, 'holy chestplate is metal');

    let ornate_chestplate = ItemId::OrnateChestplate;
    let ornate_chestplate_type = get(ornate_chestplate);
    assert(ornate_chestplate_type == 3, 'ornate chestplate is metal');

    let plate_mail = ItemId::PlateMail;
    let plate_mail_type = get(plate_mail);
    assert(plate_mail_type == 3, 'plate mail is metal');

    let chain_mail = ItemId::ChainMail;
    let chain_mail_type = get(chain_mail);
    assert(chain_mail_type == 3, 'chain mail is metal');

    let ring_mail = ItemId::RingMail;
    let ring_mail_type = get(ring_mail);
    assert(ring_mail_type == 3, 'ring mail is metal');

    let ancient_helm = ItemId::AncientHelm;
    let ancient_helm_type = get(ancient_helm);
    assert(ancient_helm_type == 3, 'ancient helm is metal');

    let ornate_helm = ItemId::OrnateHelm;
    let ornate_helm_type = get(ornate_helm);
    assert(ornate_helm_type == 3, 'ornate helm is metal');

    let great_helm = ItemId::GreatHelm;
    let great_helm_type = get(great_helm);
    assert(great_helm_type == 3, 'great helm is metal');

    let full_helm = ItemId::FullHelm;
    let full_helm_type = get(full_helm);
    assert(full_helm_type == 3, 'full helm is metal');

    let helm = ItemId::Helm;
    let helm_type = get(helm);
    assert(helm_type == 3, 'helm is metal');

    let demon_crown = ItemId::DemonCrown;
    let demon_crown_type = get(demon_crown);
    assert(demon_crown_type == 2, 'demon crown is hide');

    let dragons_crown = ItemId::DragonsCrown;
    let dragons_crown_type = get(dragons_crown);
    assert(dragons_crown_type == 2, 'dragons crown is hide');

    let war_cap = ItemId::WarCap;
    let war_cap_type = get(war_cap);
    assert(war_cap_type == 2, 'war cap is hide');

    let leather_cap = ItemId::LeatherCap;
    let leather_cap_type = get(leather_cap);
    assert(leather_cap_type == 2, 'leather cap is hide');

    let cap = ItemId::Cap;
    let cap_type = get(cap);
    assert(cap_type == 2, 'cap is hide');

    let crown = ItemId::Crown;
    let crown_type = get(crown);
    assert(crown_type == 1, 'crown is cloth');

    let divine_hood = ItemId::DivineHood;
    let divine_hood_type = get(divine_hood);
    assert(divine_hood_type == 1, 'divine hood is cloth');

    let silk_hood = ItemId::SilkHood;
    let silk_hood_type = get(silk_hood);
    assert(silk_hood_type == 1, 'silk hood is cloth');

    let linen_hood = ItemId::LinenHood;
    let linen_hood_type = get(linen_hood);
    assert(linen_hood_type == 1, 'linen hood is cloth');

    let hood = ItemId::Hood;
    let hood_type = get(hood);
    assert(hood_type == 1, 'hood is cloth');

    let ornate_belt = ItemId::OrnateBelt;
    let ornate_belt_type = get(ornate_belt);
    assert(ornate_belt_type == 3, 'ornate belt is metal');

    let war_belt = ItemId::WarBelt;
    let war_belt_type = get(war_belt);
    assert(war_belt_type == 3, 'war belt is metal');

    let plated_belt = ItemId::PlatedBelt;
    let plated_belt_type = get(plated_belt);
    assert(plated_belt_type == 3, 'plated belt is metal');

    let mesh_belt = ItemId::MeshBelt;
    let mesh_belt_type = get(mesh_belt);
    assert(mesh_belt_type == 3, 'mesh belt is metal');

    let heavy_belt = ItemId::HeavyBelt;
    let heavy_belt_type = get(heavy_belt);
    assert(heavy_belt_type == 3, 'heavy belt is metal');

    let demonhide_belt = ItemId::DemonhideBelt;
    let demonhide_belt_type = get(demonhide_belt);
    assert(demonhide_belt_type == 2, 'demonhide belt is hide');

    let dragonskin_belt = ItemId::DragonskinBelt;
    let dragonskin_belt_type = get(dragonskin_belt);
    assert(dragonskin_belt_type == 2, 'dragonskin belt is hide');

    let studded_leather_belt = ItemId::StuddedLeatherBelt;
    let studded_leather_belt_type = get(studded_leather_belt);
    assert(studded_leather_belt_type == 2, 'studded leather belt is hide');

    let hard_leather_belt = ItemId::HardLeatherBelt;
    let hard_leather_belt_type = get(hard_leather_belt);
    assert(hard_leather_belt_type == 2, 'hard leather belt is hide');

    let leather_belt = ItemId::LeatherBelt;
    let leather_belt_type = get(leather_belt);
    assert(leather_belt_type == 2, 'leather belt is hide');

    let brightsilk_sash = ItemId::BrightsilkSash;
    let brightsilk_sash_type = get(brightsilk_sash);
    assert(brightsilk_sash_type == 1, 'brightsilk sash is cloth');

    let silk_sash = ItemId::SilkSash;
    let silk_sash_type = get(silk_sash);
    assert(silk_sash_type == 1, 'silk sash is cloth');

    let wool_sash = ItemId::WoolSash;
    let wool_sash_type = get(wool_sash);
    assert(wool_sash_type == 1, 'wool sash is cloth');

    let linen_sash = ItemId::LinenSash;
    let linen_sash_type = get(linen_sash);
    assert(linen_sash_type == 1, 'linen sash is cloth');

    let sash = ItemId::Sash;
    let sash_type = get(sash);
    assert(sash_type == 1, 'sash is cloth');

    let holy_greaves = ItemId::HolyGreaves;
    let holy_greaves_type = get(holy_greaves);
    assert(holy_greaves_type == 3, 'holy greaves is metal');

    let ornate_greaves = ItemId::OrnateGreaves;
    let ornate_greaves_type = get(ornate_greaves);
    assert(ornate_greaves_type == 3, 'ornate greaves is metal');

    let greaves = ItemId::Greaves;
    let greaves_type = get(greaves);
    assert(greaves_type == 3, 'greaves is metal');

    let chain_boots = ItemId::ChainBoots;
    let chain_boots_type = get(chain_boots);
    assert(chain_boots_type == 3, 'chain boots is metal');

    let heavy_boots = ItemId::HeavyBoots;
    let heavy_boots_type = get(heavy_boots);
    assert(heavy_boots_type == 3, 'heavy boots is metal');

    let demonhide_boots = ItemId::DemonhideBoots;
    let demonhide_boots_type = get(demonhide_boots);
    assert(demonhide_boots_type == 2, 'demonhide boots is hide');

    let dragonskin_boots = ItemId::DragonskinBoots;
    let dragonskin_boots_type = get(dragonskin_boots);
    assert(dragonskin_boots_type == 2, 'dragonskin boots is hide');

    let studded_leather_boots = ItemId::StuddedLeatherBoots;
    let studded_leather_boots_type = get(studded_leather_boots);
    assert(studded_leather_boots_type == 2, 'studded leather boots is hide');

    let hard_leather_boots = ItemId::HardLeatherBoots;
    let hard_leather_boots_type = get(hard_leather_boots);
    assert(hard_leather_boots_type == 2, 'hard leather boots is hide');

    let leather_boots = ItemId::LeatherBoots;
    let leather_boots_type = get(leather_boots);
    assert(leather_boots_type == 2, 'leather boots is hide');

    let divine_slippers = ItemId::DivineSlippers;
    let divine_slippers_type = get(divine_slippers);
    assert(divine_slippers_type == 1, 'divine slippers is cloth');

    let silk_slippers = ItemId::SilkSlippers;
    let silk_slippers_type = get(silk_slippers);
    assert(silk_slippers_type == 1, 'silk slippers is cloth');

    let wool_shoes = ItemId::WoolShoes;
    let wool_shoes_type = get(wool_shoes);
    assert(wool_shoes_type == 1, 'wool shoes is cloth');

    let linen_shoes = ItemId::LinenShoes;
    let linen_shoes_type = get(linen_shoes);
    assert(linen_shoes_type == 1, 'linen shoes is cloth');

    let shoes = ItemId::Shoes;
    let shoes_type = get(shoes);
    assert(shoes_type == 1, 'shoes is cloth');

    let holy_gauntlets = ItemId::HolyGauntlets;
    let holy_gauntlets_type = get(holy_gauntlets);
    assert(holy_gauntlets_type == 3, 'holy gauntlets is metal');

    let ornate_gauntlets = ItemId::OrnateGauntlets;
    let ornate_gauntlets_type = get(ornate_gauntlets);
    assert(ornate_gauntlets_type == 3, 'ornate gauntlets is metal');

    let gauntlets = ItemId::Gauntlets;
    let gauntlets_type = get(gauntlets);
    assert(gauntlets_type == 3, 'gauntlets is metal');

    let chain_gloves = ItemId::ChainGloves;
    let chain_gloves_type = get(chain_gloves);
    assert(chain_gloves_type == 3, 'chain gloves is metal');

    let heavy_gloves = ItemId::HeavyGloves;
    let heavy_gloves_type = get(heavy_gloves);
    assert(heavy_gloves_type == 3, 'heavy gloves is metal');

    let demons_hands = ItemId::DemonsHands;
    let demons_hands_type = get(demons_hands);
    assert(demons_hands_type == 2, 'demons hands is hide');

    let dragonskin_gloves = ItemId::DragonskinGloves;
    let dragonskin_gloves_type = get(dragonskin_gloves);
    assert(dragonskin_gloves_type == 2, 'dragonskin gloves is hide');

    let studded_leather_gloves = ItemId::StuddedLeatherGloves;
    let studded_leather_gloves_type = get(studded_leather_gloves);
    assert(studded_leather_gloves_type == 2, 'studded leather gloves is hide');

    let hard_leather_gloves = ItemId::HardLeatherGloves;
    let hard_leather_gloves_type = get(hard_leather_gloves);
    assert(hard_leather_gloves_type == 2, 'hard leather gloves is hide');

    let leather_gloves = ItemId::LeatherGloves;
    let leather_gloves_type = get(leather_gloves);
    assert(leather_gloves_type == 2, 'leather gloves is hide');

    let necklace = ItemId::Necklace;
    let necklace_type = get(necklace);
    assert(necklace_type == 4, 'necklace is necklace');

    let amulet = ItemId::Amulet;
    let amulet_type = get(amulet);
    assert(amulet_type == 4, 'amulet is necklace');

    let pendant = ItemId::Pendant;
    let pendant_type = get(pendant);
    assert(pendant_type == 4, 'pendant is necklace');

    let gold_ring = ItemId::GoldRing;
    let gold_ring_type = get(gold_ring);
    assert(gold_ring_type == 5, 'gold ring is ring');

    let silver_ring = ItemId::SilverRing;
    let silver_ring_type = get(silver_ring);
    assert(silver_ring_type == 5, 'silver ring is ring');

    let bronze_ring = ItemId::BronzeRing;
    let bronze_ring_type = get(bronze_ring);
    assert(bronze_ring_type == 5, 'bronze ring is ring');

    let platinum_ring = ItemId::PlatinumRing;
    let platinum_ring_type = get(platinum_ring);
    assert(platinum_ring_type == 5, 'platinum ring is ring');

    let titanium_ring = ItemId::TitaniumRing;
    let titanium_ring_type = get(titanium_ring);
    assert(titanium_ring_type == 5, 'titanium ring is ring');
}
