use array::ArrayTrait;
use lootitems::statistics::item_slot;
use lootitems::statistics::constants::ItemId;
use lootitems::statistics::constants::ItemSlot;

fn get(id: u8) -> u8 {
    if id == ItemId::Pendant {
        return ItemSlot::Pendant;
    } else if id == ItemId::Necklace {
        return ItemSlot::Necklace;
    } else if id == ItemId::Amulet {
        return ItemSlot::Amulet;
    } else if id == ItemId::SilverRing {
        return ItemSlot::SilverRing;
    } else if id == ItemId::BronzeRing {
        return ItemSlot::BronzeRing;
    } else if id == ItemId::PlatinumRing {
        return ItemSlot::PlatinumRing;
    } else if id == ItemId::TitaniumRing {
        return ItemSlot::TitaniumRing;
    } else if id == ItemId::GoldRing {
        return ItemSlot::GoldRing;
    } else if id == ItemId::GhostWand {
        return ItemSlot::GhostWand;
    } else if id == ItemId::GraveWand {
        return ItemSlot::GraveWand;
    } else if id == ItemId::BoneWand {
        return ItemSlot::BoneWand;
    } else if id == ItemId::Wand {
        return ItemSlot::Wand;
    } else if id == ItemId::Grimoire {
        return ItemSlot::Grimoire;
    } else if id == ItemId::Chronicle {
        return ItemSlot::Chronicle;
    } else if id == ItemId::Tome {
        return ItemSlot::Tome;
    } else if id == ItemId::Book {
        return ItemSlot::Book;
    } else if id == ItemId::DivineRobe {
        return ItemSlot::DivineRobe;
    } else if id == ItemId::SilkRobe {
        return ItemSlot::SilkRobe;
    } else if id == ItemId::LinenRobe {
        return ItemSlot::LinenRobe;
    } else if id == ItemId::Robe {
        return ItemSlot::Robe;
    } else if id == ItemId::Shirt {
        return ItemSlot::Shirt;
    } else if id == ItemId::Crown {
        return ItemSlot::Crown;
    } else if id == ItemId::DivineHood {
        return ItemSlot::DivineHood;
    } else if id == ItemId::SilkHood {
        return ItemSlot::SilkHood;
    } else if id == ItemId::LinenHood {
        return ItemSlot::LinenHood;
    } else if id == ItemId::Hood {
        return ItemSlot::Hood;
    } else if id == ItemId::BrightsilkSash {
        return ItemSlot::BrightsilkSash;
    } else if id == ItemId::SilkSash {
        return ItemSlot::SilkSash;
    } else if id == ItemId::WoolSash {
        return ItemSlot::WoolSash;
    } else if id == ItemId::LinenSash {
        return ItemSlot::LinenSash;
    } else if id == ItemId::Sash {
        return ItemSlot::Sash;
    } else if id == ItemId::DivineSlippers {
        return ItemSlot::DivineSlippers;
    } else if id == ItemId::SilkSlippers {
        return ItemSlot::SilkSlippers;
    } else if id == ItemId::WoolShoes {
        return ItemSlot::WoolShoes;
    } else if id == ItemId::LinenShoes {
        return ItemSlot::LinenShoes;
    } else if id == ItemId::Shoes {
        return ItemSlot::Shoes;
    } else if id == ItemId::DivineGloves {
        return ItemSlot::DivineGloves;
    } else if id == ItemId::SilkGloves {
        return ItemSlot::SilkGloves;
    } else if id == ItemId::WoolGloves {
        return ItemSlot::WoolGloves;
    } else if id == ItemId::LinenGloves {
        return ItemSlot::LinenGloves;
    } else if id == ItemId::Gloves {
        return ItemSlot::Gloves;
    } else if id == ItemId::Katana {
        return ItemSlot::Katana;
    } else if id == ItemId::Falchion {
        return ItemSlot::Falchion;
    } else if id == ItemId::Scimitar {
        return ItemSlot::Scimitar;
    } else if id == ItemId::LongSword {
        return ItemSlot::LongSword;
    } else if id == ItemId::ShortSword {
        return ItemSlot::ShortSword;
    } else if id == ItemId::DemonHusk {
        return ItemSlot::DemonHusk;
    } else if id == ItemId::DragonskinArmor {
        return ItemSlot::DragonskinArmor;
    } else if id == ItemId::StuddedLeatherArmor {
        return ItemSlot::StuddedLeatherArmor;
    } else if id == ItemId::HardLeatherArmor {
        return ItemSlot::HardLeatherArmor;
    } else if id == ItemId::LeatherArmor {
        return ItemSlot::LeatherArmor;
    } else if id == ItemId::DemonCrown {
        return ItemSlot::DemonCrown;
    } else if id == ItemId::DragonsCrown {
        return ItemSlot::DragonsCrown;
    } else if id == ItemId::WarCap {
        return ItemSlot::WarCap;
    } else if id == ItemId::LeatherCap {
        return ItemSlot::LeatherCap;
    } else if id == ItemId::Cap {
        return ItemSlot::Cap;
    } else if id == ItemId::DemonhideBelt {
        return ItemSlot::DemonhideBelt;
    } else if id == ItemId::DragonskinBelt {
        return ItemSlot::DragonskinBelt;
    } else if id == ItemId::StuddedLeatherBelt {
        return ItemSlot::StuddedLeatherBelt;
    } else if id == ItemId::HardLeatherBelt {
        return ItemSlot::HardLeatherBelt;
    } else if id == ItemId::LeatherBelt {
        return ItemSlot::LeatherBelt;
    } else if id == ItemId::DemonhideBoots {
        return ItemSlot::DemonhideBoots;
    } else if id == ItemId::DragonskinBoots {
        return ItemSlot::DragonskinBoots;
    } else if id == ItemId::StuddedLeatherBoots {
        return ItemSlot::StuddedLeatherBoots;
    } else if id == ItemId::HardLeatherBoots {
        return ItemSlot::HardLeatherBoots;
    } else if id == ItemId::LeatherBoots {
        return ItemSlot::LeatherBoots;
    } else if id == ItemId::DemonsHands {
        return ItemSlot::DemonsHands;
    } else if id == ItemId::DragonskinGloves {
        return ItemSlot::DragonskinGloves;
    } else if id == ItemId::StuddedLeatherGloves {
        return ItemSlot::StuddedLeatherGloves;
    } else if id == ItemId::HardLeatherGloves {
        return ItemSlot::HardLeatherGloves;
    } else if id == ItemId::LeatherGloves {
        return ItemSlot::LeatherGloves;
    } else if id == ItemId::Warhammer {
        return ItemSlot::Warhammer;
    } else if id == ItemId::Quarterstaff {
        return ItemSlot::Quarterstaff;
    } else if id == ItemId::Maul {
        return ItemSlot::Maul;
    } else if id == ItemId::Mace {
        return ItemSlot::Mace;
    } else if id == ItemId::Club {
        return ItemSlot::Club;
    } else if id == ItemId::HolyChestplate {
        return ItemSlot::HolyChestplate;
    } else if id == ItemId::OrnateChestplate {
        return ItemSlot::OrnateChestplate;
    } else if id == ItemId::PlateMail {
        return ItemSlot::PlateMail;
    } else if id == ItemId::ChainMail {
        return ItemSlot::ChainMail;
    } else if id == ItemId::RingMail {
        return ItemSlot::RingMail;
    } else if id == ItemId::AncientHelm {
        return ItemSlot::AncientHelm;
    } else if id == ItemId::OrnateHelm {
        return ItemSlot::OrnateHelm;
    } else if id == ItemId::GreatHelm {
        return ItemSlot::GreatHelm;
    } else if id == ItemId::FullHelm {
        return ItemSlot::FullHelm;
    } else if id == ItemId::Helm {
        return ItemSlot::Helm;
    } else if id == ItemId::OrnateBelt {
        return ItemSlot::OrnateBelt;
    } else if id == ItemId::WarBelt {
        return ItemSlot::WarBelt;
    } else if id == ItemId::PlatedBelt {
        return ItemSlot::PlatedBelt;
    } else if id == ItemId::MeshBelt {
        return ItemSlot::MeshBelt;
    } else if id == ItemId::HeavyBelt {
        return ItemSlot::HeavyBelt;
    } else if id == ItemId::HolyGreaves {
        return ItemSlot::HolyGreaves;
    } else if id == ItemId::OrnateGreaves {
        return ItemSlot::OrnateGreaves;
    } else if id == ItemId::Greaves {
        return ItemSlot::Greaves;
    } else if id == ItemId::ChainBoots {
        return ItemSlot::ChainBoots;
    } else if id == ItemId::HeavyBoots {
        return ItemSlot::HeavyBoots;
    } else if id == ItemId::HolyGauntlets {
        return ItemSlot::HolyGauntlets;
    } else if id == ItemId::OrnateGauntlets {
        return ItemSlot::OrnateGauntlets;
    } else if id == ItemId::Gauntlets {
        return ItemSlot::Gauntlets;
    } else if id == ItemId::ChainGloves {
        return ItemSlot::ChainGloves;
    } else if id == ItemId::HeavyGloves {
        return ItemSlot::HeavyGloves;
    } else {
        // invalid id passed in
        return 0;
    }
}

#[test]
#[available_gas(3000000)]
fn test_get_item_slots() {
    // Weapons
    let katana = ItemId::Katana;
    let katana_slot = get(katana);
    assert(katana_slot == 1, 'katana is weapon slot');

    let warhammer = ItemId::Warhammer;
    let warhammer_slot = get(warhammer);
    assert(warhammer_slot == 1, 'warhammer is weapon slot');

    let quarterstaff = ItemId::Quarterstaff;
    let quarterstaff_slot = get(quarterstaff);
    assert(quarterstaff_slot == 1, 'quarterstaff is weapon slot');

    let maul = ItemId::Maul;
    let maul_slot = get(maul);
    assert(maul_slot == 1, 'maul is weapon slot');

    let mace = ItemId::Mace;
    let mace_slot = get(mace);
    assert(mace_slot == 1, 'mace is weapon slot');

    let club = ItemId::Club;
    let club_slot = get(club);
    assert(club_slot == 1, 'club is weapon slot');

    let falchion = ItemId::Falchion;
    let falchion_slot = get(falchion);
    assert(falchion_slot == 1, 'falchion is weapon slot');

    let scimitar = ItemId::Scimitar;
    let scimitar_slot = get(scimitar);
    assert(scimitar_slot == 1, 'scimitar is weapon slot');

    let long_sword = ItemId::LongSword;
    let long_sword_slot = get(long_sword);
    assert(long_sword_slot == 1, 'long sword is weapon slot');

    let short_sword = ItemId::ShortSword;
    let short_sword_slot = get(short_sword);
    assert(short_sword_slot == 1, 'short sword is weapon slot');

    let ghost_wand = ItemId::GhostWand;
    let ghost_wand_slot = get(ghost_wand);
    assert(ghost_wand_slot == 1, 'ghost wand is weapon slot');

    let grave_wand = ItemId::GraveWand;
    let grave_wand_slot = get(grave_wand);
    assert(grave_wand_slot == 1, 'grave wand is weapon slot');

    let bone_wand = ItemId::BoneWand;
    let bone_wand_slot = get(bone_wand);
    assert(bone_wand_slot == 1, 'bone wand is weapon slot');

    let wand = ItemId::Wand;
    let wand_slot = get(wand);
    assert(wand_slot == 1, 'wand is weapon slot');

    let grimoire = ItemId::Grimoire;
    let grimoire_slot = get(grimoire);
    assert(grimoire_slot == 1, 'grimoire is weapon slot');

    let chronicle = ItemId::Chronicle;
    let chronicle_slot = get(chronicle);
    assert(chronicle_slot == 1, 'chronicle is weapon slot');

    let tome = ItemId::Tome;
    let tome_slot = get(tome);
    assert(tome_slot == 1, 'tome is weapon slot');

    let book = ItemId::Book;
    let book_slot = get(book);
    assert(book_slot == 1, 'book is weapon slot');

    // Chest
    let divine_robe = ItemId::DivineRobe;
    let divine_robe_slot = get(divine_robe);
    assert(divine_robe_slot == 2, 'divine robe is chest slot');

    let silk_robe = ItemId::SilkRobe;
    let silk_robe_slot = get(silk_robe);
    assert(silk_robe_slot == 2, 'silk robe is chest slot');

    let linen_robe = ItemId::LinenRobe;
    let linen_robe_slot = get(linen_robe);
    assert(linen_robe_slot == 2, 'linen robe is chest slot');

    let robe = ItemId::Robe;
    let robe_slot = get(robe);
    assert(robe_slot == 2, 'robe is chest slot');

    let shirt = ItemId::Shirt;
    let shirt_slot = get(shirt);
    assert(shirt_slot == 2, 'shirt is chest slot');

    let demon_husk = ItemId::DemonHusk;
    let demon_husk_slot = get(demon_husk);
    assert(demon_husk_slot == 2, 'demon husk is chest slot');

    let dragonskin_armor = ItemId::DragonskinArmor;
    let dragonskin_armor_slot = get(dragonskin_armor);
    assert(dragonskin_armor_slot == 2, 'dragonskin armor is chest slot');

    let studded_leather_armor = ItemId::StuddedLeatherArmor;
    let studded_leather_armor_slot = get(studded_leather_armor);
    assert(studded_leather_armor_slot == 2, 'studded leather armor slot err');

    let hard_leather_armor = ItemId::HardLeatherArmor;
    let hard_leather_armor_slot = get(hard_leather_armor);
    assert(hard_leather_armor_slot == 2, 'hard leather armor slot err');

    let leather_armor = ItemId::LeatherArmor;
    let leather_armor_slot = get(leather_armor);
    assert(leather_armor_slot == 2, 'leather armor is chest slot');

    let holy_chestplate = ItemId::HolyChestplate;
    let holy_chestplate_slot = get(holy_chestplate);
    assert(holy_chestplate_slot == 2, 'holy chestplate is chest slot');

    let ornate_chestplate = ItemId::OrnateChestplate;
    let ornate_chestplate_slot = get(ornate_chestplate);
    assert(ornate_chestplate_slot == 2, 'ornate chestplate is chest slot');

    let plate_mail = ItemId::PlateMail;
    let plate_mail_slot = get(plate_mail);
    assert(plate_mail_slot == 2, 'plate mail is chest slot');

    let chain_mail = ItemId::ChainMail;
    let chain_mail_slot = get(chain_mail);
    assert(chain_mail_slot == 2, 'chain mail is chest slot');

    let ring_mail = ItemId::RingMail;
    let ring_mail_slot = get(ring_mail);
    assert(ring_mail_slot == 2, 'ring mail is chest slot');

    // Head
    let ancient_helm = ItemId::AncientHelm;
    let ancient_helm_slot = get(ancient_helm);
    assert(ancient_helm_slot == 3, 'ancient helm is head slot');

    let ornate_helm = ItemId::OrnateHelm;
    let ornate_helm_slot = get(ornate_helm);
    assert(ornate_helm_slot == 3, 'ornate helm is head slot');

    let great_helm = ItemId::GreatHelm;
    let great_helm_slot = get(great_helm);
    assert(great_helm_slot == 3, 'great helm is head slot');

    let full_helm = ItemId::FullHelm;
    let full_helm_slot = get(full_helm);
    assert(full_helm_slot == 3, 'full helm is head slot');

    let helm = ItemId::Helm;
    let helm_slot = get(helm);
    assert(helm_slot == 3, 'helm is head slot');

    let demon_crown = ItemId::DemonCrown;
    let demon_crown_slot = get(demon_crown);
    assert(demon_crown_slot == 3, 'demon crown is head slot');

    let dragons_crown = ItemId::DragonsCrown;
    let dragons_crown_slot = get(dragons_crown);
    assert(dragons_crown_slot == 3, 'dragons crown is head slot');

    let war_cap = ItemId::WarCap;
    let war_cap_slot = get(war_cap);
    assert(war_cap_slot == 3, 'war cap is head slot');

    let leather_cap = ItemId::LeatherCap;
    let leather_cap_slot = get(leather_cap);
    assert(leather_cap_slot == 3, 'leather cap is head slot');

    let cap = ItemId::Cap;
    let cap_slot = get(cap);
    assert(cap_slot == 3, 'cap is head slot');

    let crown = ItemId::Crown;
    let crown_slot = get(crown);
    assert(crown_slot == 3, 'crown is head slot');

    let divine_hood = ItemId::DivineHood;
    let divine_hood_slot = get(divine_hood);
    assert(divine_hood_slot == 3, 'divine hood is head slot');

    let silk_hood = ItemId::SilkHood;
    let silk_hood_slot = get(silk_hood);
    assert(silk_hood_slot == 3, 'silk hood is head slot');

    let linen_hood = ItemId::LinenHood;
    let linen_hood_slot = get(linen_hood);
    assert(linen_hood_slot == 3, 'linen hood is head slot');

    let hood = ItemId::Hood;
    let hood_slot = get(hood);
    assert(hood_slot == 3, 'hood is head slot');

    // Waist
    let ornate_belt = ItemId::OrnateBelt;
    let ornate_belt_slot = get(ornate_belt);
    assert(ornate_belt_slot == 4, 'ornate belt is waist slot');

    let war_belt = ItemId::WarBelt;
    let war_belt_slot = get(war_belt);
    assert(war_belt_slot == 4, 'war belt is waist slot');

    let plated_belt = ItemId::PlatedBelt;
    let plated_belt_slot = get(plated_belt);
    assert(plated_belt_slot == 4, 'plated belt is waist slot');

    let mesh_belt = ItemId::MeshBelt;
    let mesh_belt_slot = get(mesh_belt);
    assert(mesh_belt_slot == 4, 'mesh belt is waist slot');

    let heavy_belt = ItemId::HeavyBelt;
    let heavy_belt_slot = get(heavy_belt);
    assert(heavy_belt_slot == 4, 'heavy belt is waist slot');

    let demonhide_belt = ItemId::DemonhideBelt;
    let demonhide_belt_slot = get(demonhide_belt);
    assert(demonhide_belt_slot == 4, 'demonhide belt is waist slot');

    let dragonskin_belt = ItemId::DragonskinBelt;
    let dragonskin_belt_slot = get(dragonskin_belt);
    assert(dragonskin_belt_slot == 4, 'dragonskin belt is waist slot');

    let studded_leather_belt = ItemId::StuddedLeatherBelt;
    let studded_leather_belt_slot = get(studded_leather_belt);
    assert(studded_leather_belt_slot == 4, 'studded leather belt wrong slot');

    let hard_leather_belt = ItemId::HardLeatherBelt;
    let hard_leather_belt_slot = get(hard_leather_belt);
    assert(hard_leather_belt_slot == 4, 'hard leather belt is waist slot');

    let leather_belt = ItemId::LeatherBelt;
    let leather_belt_slot = get(leather_belt);
    assert(leather_belt_slot == 4, 'leather belt is waist slot');

    let brightsilk_sash = ItemId::BrightsilkSash;
    let brightsilk_sash_slot = get(brightsilk_sash);
    assert(brightsilk_sash_slot == 4, 'brightsilk sash is waist slot');

    let silk_sash = ItemId::SilkSash;
    let silk_sash_slot = get(silk_sash);
    assert(silk_sash_slot == 4, 'silk sash is waist slot');

    let wool_sash = ItemId::WoolSash;
    let wool_sash_slot = get(wool_sash);
    assert(wool_sash_slot == 4, 'wool sash is waist slot');

    let linen_sash = ItemId::LinenSash;
    let linen_sash_slot = get(linen_sash);
    assert(linen_sash_slot == 4, 'linen sash is waist slot');

    let sash = ItemId::Sash;
    let sash_slot = get(sash);
    assert(sash_slot == 4, 'sash is waist slot');

    // Foot
    let holy_greaves = ItemId::HolyGreaves;
    let holy_greaves_slot = get(holy_greaves);
    assert(holy_greaves_slot == 5, 'holy greaves is foot slot');

    let ornate_greaves = ItemId::OrnateGreaves;
    let ornate_greaves_slot = get(ornate_greaves);
    assert(ornate_greaves_slot == 5, 'ornate greaves is foot slot');

    let greaves = ItemId::Greaves;
    let greaves_slot = get(greaves);
    assert(greaves_slot == 5, 'greaves is foot slot');

    let chain_boots = ItemId::ChainBoots;
    let chain_boots_slot = get(chain_boots);
    assert(chain_boots_slot == 5, 'chain boots is foot slot');

    let heavy_boots = ItemId::HeavyBoots;
    let heavy_boots_slot = get(heavy_boots);
    assert(heavy_boots_slot == 5, 'heavy boots is foot slot');

    let demonhide_boots = ItemId::DemonhideBoots;
    let demonhide_boots_slot = get(demonhide_boots);
    assert(demonhide_boots_slot == 5, 'demonhide boots is foot slot');

    let dragonskin_boots = ItemId::DragonskinBoots;
    let dragonskin_boots_slot = get(dragonskin_boots);
    assert(dragonskin_boots_slot == 5, 'dragonskin boots is foot slot');

    let studded_leather_boots = ItemId::StuddedLeatherBoots;
    let studded_leather_boots_slot = get(studded_leather_boots);
    assert(studded_leather_boots_slot == 5, 'studded leather boots err');

    let hard_leather_boots = ItemId::HardLeatherBoots;
    let hard_leather_boots_slot = get(hard_leather_boots);
    assert(hard_leather_boots_slot == 5, 'hard leather boots is foot slot');

    let leather_boots = ItemId::LeatherBoots;
    let leather_boots_slot = get(leather_boots);
    assert(leather_boots_slot == 5, 'leather boots is foot slot');

    let divine_slippers = ItemId::DivineSlippers;
    let divine_slippers_slot = get(divine_slippers);
    assert(divine_slippers_slot == 5, 'divine slippers is foot slot');

    let silk_slippers = ItemId::SilkSlippers;
    let silk_slippers_slot = get(silk_slippers);
    assert(silk_slippers_slot == 5, 'silk slippers is foot slot');

    let wool_shoes = ItemId::WoolShoes;
    let wool_shoes_slot = get(wool_shoes);
    assert(wool_shoes_slot == 5, 'wool shoes is foot slot');

    let linen_shoes = ItemId::LinenShoes;
    let linen_shoes_slot = get(linen_shoes);
    assert(linen_shoes_slot == 5, 'linen shoes is foot slot');

    let shoes = ItemId::Shoes;
    let shoes_slot = get(shoes);
    assert(shoes_slot == 5, 'shoes is foot slot');

    // Hand
    let holy_gauntlets = ItemId::HolyGauntlets;
    let holy_gauntlets_slot = get(holy_gauntlets);
    assert(holy_gauntlets_slot == 6, 'holy gauntlets is hand slot');

    let ornate_gauntlets = ItemId::OrnateGauntlets;
    let ornate_gauntlets_slot = get(ornate_gauntlets);
    assert(ornate_gauntlets_slot == 6, 'ornate gauntlets is hand slot');

    let gauntlets = ItemId::Gauntlets;
    let gauntlets_slot = get(gauntlets);
    assert(gauntlets_slot == 6, 'gauntlets is hand slot');

    let chain_gloves = ItemId::ChainGloves;
    let chain_gloves_slot = get(chain_gloves);
    assert(chain_gloves_slot == 6, 'chain gloves is hand slot');

    let heavy_gloves = ItemId::HeavyGloves;
    let heavy_gloves_slot = get(heavy_gloves);
    assert(heavy_gloves_slot == 6, 'heavy gloves is hand slot');

    let demons_hands = ItemId::DemonsHands;
    let demons_hands_slot = get(demons_hands);
    assert(demons_hands_slot == 6, 'demons hands is hand slot');

    let dragonskin_gloves = ItemId::DragonskinGloves;
    let dragonskin_gloves_slot = get(dragonskin_gloves);
    assert(dragonskin_gloves_slot == 6, 'dragonskin gloves is hand slot');

    let studded_leather_gloves = ItemId::StuddedLeatherGloves;
    let studded_leather_gloves_slot = get(studded_leather_gloves);
    assert(studded_leather_gloves_slot == 6, 'studded leather gloves err');

    let hard_leather_gloves = ItemId::HardLeatherGloves;
    let hard_leather_gloves_slot = get(hard_leather_gloves);
    assert(hard_leather_gloves_slot == 6, 'hard leather gloves wrong slot');

    let leather_gloves = ItemId::LeatherGloves;
    let leather_gloves_slot = get(leather_gloves);
    assert(leather_gloves_slot == 6, 'leather gloves is hand slot');

    let divine_gloves = ItemId::DivineGloves;
    let divine_gloves_slot = get(divine_gloves);
    assert(divine_gloves_slot == 6, 'divine gloves is hand slot');

    let silk_gloves = ItemId::SilkGloves;
    let silk_gloves_slot = get(silk_gloves);
    assert(silk_gloves_slot == 6, 'silk gloves is hand slot');

    let wool_gloves = ItemId::WoolGloves;
    let wool_gloves_slot = get(wool_gloves);
    assert(wool_gloves_slot == 6, 'wool gloves is hand slot');

    let linen_gloves = ItemId::LinenGloves;
    let linen_gloves_slot = get(linen_gloves);
    assert(linen_gloves_slot == 6, 'linen gloves is hand slot');

    let gloves = ItemId::Gloves;
    let gloves_slot = get(gloves);
    assert(gloves_slot == 6, 'gloves is hand slot');

    // Necklaces
    let necklace = ItemId::Necklace;
    let necklace_slot = get(necklace);
    assert(necklace_slot == 7, 'necklace is necklace slot');

    let amulet = ItemId::Amulet;
    let amulet_slot = get(amulet);
    assert(amulet_slot == 7, 'amulet is necklace slot');

    let pendant = ItemId::Pendant;
    let pendant_slot = get(pendant);
    assert(pendant_slot == 7, 'pendant is necklace slot');

    // Rings
    let gold_ring = ItemId::GoldRing;
    let gold_ring_slot = get(gold_ring);
    assert(gold_ring_slot == 8, 'gold ring is ring slot');

    let silver_ring = ItemId::SilverRing;
    let silver_ring_slot = get(silver_ring);
    assert(silver_ring_slot == 8, 'silver ring is ring slot');

    let bronze_ring = ItemId::BronzeRing;
    let bronze_ring_slot = get(bronze_ring);
    assert(bronze_ring_slot == 8, 'bronze ring is ring slot');

    let platinum_ring = ItemId::PlatinumRing;
    let platinum_ring_slot = get(platinum_ring);
    assert(platinum_ring_slot == 8, 'platinum ring is ring slot');

    let titanium_ring = ItemId::TitaniumRing;
    let titanium_ring_slot = get(titanium_ring);
    assert(titanium_ring_slot == 8, 'titanium ring is ring slot');
}
