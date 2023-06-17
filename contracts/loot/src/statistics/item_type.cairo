use array::ArrayTrait;
use lootitems::statistics::item_type;
use lootitems::statistics::constants::ItemId;
use combat::constants::CombatEnums::Type;

fn get(id: u8) -> Type {
    if id == ItemId::Pendant {
        return Type::Necklace(());
    } else if id == ItemId::Necklace {
        return Type::Necklace(());
    } else if id == ItemId::Amulet {
        return Type::Necklace(());
    } else if id == ItemId::SilverRing {
        return Type::Ring(());
    } else if id == ItemId::BronzeRing {
        return Type::Ring(());
    } else if id == ItemId::PlatinumRing {
        return Type::Ring(());
    } else if id == ItemId::TitaniumRing {
        return Type::Ring(());
    } else if id == ItemId::GoldRing {
        return Type::Ring(());
    } else if id == ItemId::GhostWand {
        return Type::Magic_or_Cloth(());
    } else if id == ItemId::GraveWand {
        return Type::Magic_or_Cloth(());
    } else if id == ItemId::BoneWand {
        return Type::Magic_or_Cloth(());
    } else if id == ItemId::Wand {
        return Type::Magic_or_Cloth(());
    } else if id == ItemId::Grimoire {
        return Type::Magic_or_Cloth(());
    } else if id == ItemId::Chronicle {
        return Type::Magic_or_Cloth(());
    } else if id == ItemId::Tome {
        return Type::Magic_or_Cloth(());
    } else if id == ItemId::Book {
        return Type::Magic_or_Cloth(());
    } else if id == ItemId::DivineRobe {
        return Type::Magic_or_Cloth(());
    } else if id == ItemId::SilkRobe {
        return Type::Magic_or_Cloth(());
    } else if id == ItemId::LinenRobe {
        return Type::Magic_or_Cloth(());
    } else if id == ItemId::Robe {
        return Type::Magic_or_Cloth(());
    } else if id == ItemId::Shirt {
        return Type::Magic_or_Cloth(());
    } else if id == ItemId::Crown {
        return Type::Magic_or_Cloth(());
    } else if id == ItemId::DivineHood {
        return Type::Magic_or_Cloth(());
    } else if id == ItemId::SilkHood {
        return Type::Magic_or_Cloth(());
    } else if id == ItemId::LinenHood {
        return Type::Magic_or_Cloth(());
    } else if id == ItemId::Hood {
        return Type::Magic_or_Cloth(());
    } else if id == ItemId::BrightsilkSash {
        return Type::Magic_or_Cloth(());
    } else if id == ItemId::SilkSash {
        return Type::Magic_or_Cloth(());
    } else if id == ItemId::WoolSash {
        return Type::Magic_or_Cloth(());
    } else if id == ItemId::LinenSash {
        return Type::Magic_or_Cloth(());
    } else if id == ItemId::Sash {
        return Type::Magic_or_Cloth(());
    } else if id == ItemId::DivineSlippers {
        return Type::Magic_or_Cloth(());
    } else if id == ItemId::SilkSlippers {
        return Type::Magic_or_Cloth(());
    } else if id == ItemId::WoolShoes {
        return Type::Magic_or_Cloth(());
    } else if id == ItemId::LinenShoes {
        return Type::Magic_or_Cloth(());
    } else if id == ItemId::Shoes {
        return Type::Magic_or_Cloth(());
    } else if id == ItemId::DivineGloves {
        return Type::Magic_or_Cloth(());
    } else if id == ItemId::SilkGloves {
        return Type::Magic_or_Cloth(());
    } else if id == ItemId::WoolGloves {
        return Type::Magic_or_Cloth(());
    } else if id == ItemId::LinenGloves {
        return Type::Magic_or_Cloth(());
    } else if id == ItemId::Gloves {
        return Type::Magic_or_Cloth(());
    } else if id == ItemId::Katana {
        return Type::Blade_or_Hide(());
    } else if id == ItemId::Falchion {
        return Type::Blade_or_Hide(());
    } else if id == ItemId::Scimitar {
        return Type::Blade_or_Hide(());
    } else if id == ItemId::LongSword {
        return Type::Blade_or_Hide(());
    } else if id == ItemId::ShortSword {
        return Type::Blade_or_Hide(());
    } else if id == ItemId::DemonHusk {
        return Type::Blade_or_Hide(());
    } else if id == ItemId::DragonskinArmor {
        return Type::Blade_or_Hide(());
    } else if id == ItemId::StuddedLeatherArmor {
        return Type::Blade_or_Hide(());
    } else if id == ItemId::HardLeatherArmor {
        return Type::Blade_or_Hide(());
    } else if id == ItemId::LeatherArmor {
        return Type::Blade_or_Hide(());
    } else if id == ItemId::DemonCrown {
        return Type::Blade_or_Hide(());
    } else if id == ItemId::DragonsCrown {
        return Type::Blade_or_Hide(());
    } else if id == ItemId::WarCap {
        return Type::Blade_or_Hide(());
    } else if id == ItemId::LeatherCap {
        return Type::Blade_or_Hide(());
    } else if id == ItemId::Cap {
        return Type::Blade_or_Hide(());
    } else if id == ItemId::DemonhideBelt {
        return Type::Blade_or_Hide(());
    } else if id == ItemId::DragonskinBelt {
        return Type::Blade_or_Hide(());
    } else if id == ItemId::StuddedLeatherBelt {
        return Type::Blade_or_Hide(());
    } else if id == ItemId::HardLeatherBelt {
        return Type::Blade_or_Hide(());
    } else if id == ItemId::LeatherBelt {
        return Type::Blade_or_Hide(());
    } else if id == ItemId::DemonhideBoots {
        return Type::Blade_or_Hide(());
    } else if id == ItemId::DragonskinBoots {
        return Type::Blade_or_Hide(());
    } else if id == ItemId::StuddedLeatherBoots {
        return Type::Blade_or_Hide(());
    } else if id == ItemId::HardLeatherBoots {
        return Type::Blade_or_Hide(());
    } else if id == ItemId::LeatherBoots {
        return Type::Blade_or_Hide(());
    } else if id == ItemId::DemonsHands {
        return Type::Blade_or_Hide(());
    } else if id == ItemId::DragonskinGloves {
        return Type::Blade_or_Hide(());
    } else if id == ItemId::StuddedLeatherGloves {
        return Type::Blade_or_Hide(());
    } else if id == ItemId::HardLeatherGloves {
        return Type::Blade_or_Hide(());
    } else if id == ItemId::LeatherGloves {
        return Type::Blade_or_Hide(());
    } else if id == ItemId::Warhammer {
        return Type::Bludgeon_or_Metal(());
    } else if id == ItemId::Quarterstaff {
        return Type::Bludgeon_or_Metal(());
    } else if id == ItemId::Maul {
        return Type::Bludgeon_or_Metal(());
    } else if id == ItemId::Mace {
        return Type::Bludgeon_or_Metal(());
    } else if id == ItemId::Club {
        return Type::Bludgeon_or_Metal(());
    } else if id == ItemId::HolyChestplate {
        return Type::Bludgeon_or_Metal(());
    } else if id == ItemId::OrnateChestplate {
        return Type::Bludgeon_or_Metal(());
    } else if id == ItemId::PlateMail {
        return Type::Bludgeon_or_Metal(());
    } else if id == ItemId::ChainMail {
        return Type::Bludgeon_or_Metal(());
    } else if id == ItemId::RingMail {
        return Type::Bludgeon_or_Metal(());
    } else if id == ItemId::AncientHelm {
        return Type::Bludgeon_or_Metal(());
    } else if id == ItemId::OrnateHelm {
        return Type::Bludgeon_or_Metal(());
    } else if id == ItemId::GreatHelm {
        return Type::Bludgeon_or_Metal(());
    } else if id == ItemId::FullHelm {
        return Type::Bludgeon_or_Metal(());
    } else if id == ItemId::Helm {
        return Type::Bludgeon_or_Metal(());
    } else if id == ItemId::OrnateBelt {
        return Type::Bludgeon_or_Metal(());
    } else if id == ItemId::WarBelt {
        return Type::Bludgeon_or_Metal(());
    } else if id == ItemId::PlatedBelt {
        return Type::Bludgeon_or_Metal(());
    } else if id == ItemId::MeshBelt {
        return Type::Bludgeon_or_Metal(());
    } else if id == ItemId::HeavyBelt {
        return Type::Bludgeon_or_Metal(());
    } else if id == ItemId::HolyGreaves {
        return Type::Bludgeon_or_Metal(());
    } else if id == ItemId::OrnateGreaves {
        return Type::Bludgeon_or_Metal(());
    } else if id == ItemId::Greaves {
        return Type::Bludgeon_or_Metal(());
    } else if id == ItemId::ChainBoots {
        return Type::Bludgeon_or_Metal(());
    } else if id == ItemId::HeavyBoots {
        return Type::Bludgeon_or_Metal(());
    } else if id == ItemId::HolyGauntlets {
        return Type::Bludgeon_or_Metal(());
    } else if id == ItemId::OrnateGauntlets {
        return Type::Bludgeon_or_Metal(());
    } else if id == ItemId::Gauntlets {
        return Type::Bludgeon_or_Metal(());
    } else if id == ItemId::ChainGloves {
        return Type::Bludgeon_or_Metal(());
    } else if id == ItemId::HeavyGloves {
        return Type::Bludgeon_or_Metal(());
    } else {
        // unknown id, return bludgeon
        return Type::Bludgeon_or_Metal(());
    }
}

#[test]
#[available_gas(3000000)]
fn test_get_item_type() {
    let warhammer = ItemId::Warhammer;
    let warhammer_type = get(warhammer);
    assert(warhammer_type == Type::Bludgeon_or_Metal(()), 'warhammer is blunt');

    let quarterstaff = ItemId::Quarterstaff;
    let quarterstaff_type = get(quarterstaff);
    assert(quarterstaff_type == Type::Bludgeon_or_Metal(()), 'quarterstaff is blunt');

    let maul = ItemId::Maul;
    let maul_type = get(maul);
    assert(maul_type == Type::Bludgeon_or_Metal(()), 'maul is blunt');

    let mace = ItemId::Mace;
    let mace_type = get(mace);
    assert(mace_type == Type::Bludgeon_or_Metal(()), 'mace is blunt');

    let club = ItemId::Club;
    let club_type = get(club);
    assert(club_type == Type::Bludgeon_or_Metal(()), 'club is blunt');

    let katana = ItemId::Katana;
    let katana_type = get(katana);
    assert(katana_type == Type::Blade_or_Hide(()), 'katana is blade');

    let falchion = ItemId::Falchion;
    let falchion_type = get(falchion);
    assert(falchion_type == Type::Blade_or_Hide(()), 'falchion is blade');

    let scimitar = ItemId::Scimitar;
    let scimitar_type = get(scimitar);
    assert(scimitar_type == Type::Blade_or_Hide(()), 'scimitar is blade');

    let long_sword = ItemId::LongSword;
    let long_sword_type = get(long_sword);
    assert(long_sword_type == Type::Blade_or_Hide(()), 'long sword is blade');

    let short_sword = ItemId::ShortSword;
    let short_sword_type = get(short_sword);
    assert(short_sword_type == Type::Blade_or_Hide(()), 'short sword is blade');

    let ghost_wand = ItemId::GhostWand;
    let ghost_wand_type = get(ghost_wand);
    assert(ghost_wand_type == Type::Magic_or_Cloth(()), 'ghost wand is magic');

    let grave_wand = ItemId::GraveWand;
    let grave_wand_type = get(grave_wand);
    assert(grave_wand_type == Type::Magic_or_Cloth(()), 'grave wand is magic');

    let bone_wand = ItemId::BoneWand;
    let bone_wand_type = get(bone_wand);
    assert(bone_wand_type == Type::Magic_or_Cloth(()), 'bone wand is magic');

    let wand = ItemId::Wand;
    let wand_type = get(wand);
    assert(wand_type == Type::Magic_or_Cloth(()), 'wand is magic');

    let grimoire = ItemId::Grimoire;
    let grimoire_type = get(grimoire);
    assert(grimoire_type == Type::Magic_or_Cloth(()), 'grimoire is magic');

    let chronicle = ItemId::Chronicle;
    let chronicle_type = get(chronicle);
    assert(chronicle_type == Type::Magic_or_Cloth(()), 'chronicle is magic');

    let tome = ItemId::Tome;
    let tome_type = get(tome);
    assert(tome_type == Type::Magic_or_Cloth(()), 'tome is magic');

    let book = ItemId::Book;
    let book_type = get(book);
    assert(book_type == Type::Magic_or_Cloth(()), 'book is magic');

    let divine_robe = ItemId::DivineRobe;
    let divine_robe_type = get(divine_robe);
    assert(divine_robe_type == Type::Magic_or_Cloth(()), 'divine robe is cloth');

    let silk_robe = ItemId::SilkRobe;
    let silk_robe_type = get(silk_robe);
    assert(silk_robe_type == Type::Magic_or_Cloth(()), 'silk robe is cloth');

    let linen_robe = ItemId::LinenRobe;
    let linen_robe_type = get(linen_robe);
    assert(linen_robe_type == Type::Magic_or_Cloth(()), 'linen robe is cloth');

    let robe = ItemId::Robe;
    let robe_type = get(robe);
    assert(robe_type == Type::Magic_or_Cloth(()), 'robe is cloth');

    let shirt = ItemId::Shirt;
    let shirt_type = get(shirt);
    assert(shirt_type == Type::Magic_or_Cloth(()), 'shirt is cloth');

    let demon_husk = ItemId::DemonHusk;
    let demon_husk_type = get(demon_husk);
    assert(demon_husk_type == Type::Blade_or_Hide(()), 'demon husk is hide');

    let dragonskin_armor = ItemId::DragonskinArmor;
    let dragonskin_armor_type = get(dragonskin_armor);
    assert(dragonskin_armor_type == Type::Blade_or_Hide(()), 'dragonskin armor is hide');

    let studded_leather_armor = ItemId::StuddedLeatherArmor;
    let studded_leather_armor_type = get(studded_leather_armor);
    assert(studded_leather_armor_type == Type::Blade_or_Hide(()), 'studded leather armor is hide');

    let hard_leather_armor = ItemId::HardLeatherArmor;
    let hard_leather_armor_type = get(hard_leather_armor);
    assert(hard_leather_armor_type == Type::Blade_or_Hide(()), 'hard leather armor is hide');

    let leather_armor = ItemId::LeatherArmor;
    let leather_armor_type = get(leather_armor);
    assert(leather_armor_type == Type::Blade_or_Hide(()), 'leather armor is hide');

    let holy_chestplate = ItemId::HolyChestplate;
    let holy_chestplate_type = get(holy_chestplate);
    assert(holy_chestplate_type == Type::Bludgeon_or_Metal(()), 'holy chestplate is metal');

    let ornate_chestplate = ItemId::OrnateChestplate;
    let ornate_chestplate_type = get(ornate_chestplate);
    assert(ornate_chestplate_type == Type::Bludgeon_or_Metal(()), 'ornate chestplate is metal');

    let plate_mail = ItemId::PlateMail;
    let plate_mail_type = get(plate_mail);
    assert(plate_mail_type == Type::Bludgeon_or_Metal(()), 'plate mail is metal');

    let chain_mail = ItemId::ChainMail;
    let chain_mail_type = get(chain_mail);
    assert(chain_mail_type == Type::Bludgeon_or_Metal(()), 'chain mail is metal');

    let ring_mail = ItemId::RingMail;
    let ring_mail_type = get(ring_mail);
    assert(ring_mail_type == Type::Bludgeon_or_Metal(()), 'ring mail is metal');

    let ancient_helm = ItemId::AncientHelm;
    let ancient_helm_type = get(ancient_helm);
    assert(ancient_helm_type == Type::Bludgeon_or_Metal(()), 'ancient helm is metal');

    let ornate_helm = ItemId::OrnateHelm;
    let ornate_helm_type = get(ornate_helm);
    assert(ornate_helm_type == Type::Bludgeon_or_Metal(()), 'ornate helm is metal');

    let great_helm = ItemId::GreatHelm;
    let great_helm_type = get(great_helm);
    assert(great_helm_type == Type::Bludgeon_or_Metal(()), 'great helm is metal');

    let full_helm = ItemId::FullHelm;
    let full_helm_type = get(full_helm);
    assert(full_helm_type == Type::Bludgeon_or_Metal(()), 'full helm is metal');

    let helm = ItemId::Helm;
    let helm_type = get(helm);
    assert(helm_type == Type::Bludgeon_or_Metal(()), 'helm is metal');

    let demon_crown = ItemId::DemonCrown;
    let demon_crown_type = get(demon_crown);
    assert(demon_crown_type == Type::Blade_or_Hide(()), 'demon crown is hide');

    let dragons_crown = ItemId::DragonsCrown;
    let dragons_crown_type = get(dragons_crown);
    assert(dragons_crown_type == Type::Blade_or_Hide(()), 'dragons crown is hide');

    let war_cap = ItemId::WarCap;
    let war_cap_type = get(war_cap);
    assert(war_cap_type == Type::Blade_or_Hide(()), 'war cap is hide');

    let leather_cap = ItemId::LeatherCap;
    let leather_cap_type = get(leather_cap);
    assert(leather_cap_type == Type::Blade_or_Hide(()), 'leather cap is hide');

    let cap = ItemId::Cap;
    let cap_type = get(cap);
    assert(cap_type == Type::Blade_or_Hide(()), 'cap is hide');

    let crown = ItemId::Crown;
    let crown_type = get(crown);
    assert(crown_type == Type::Magic_or_Cloth(()), 'crown is cloth');

    let divine_hood = ItemId::DivineHood;
    let divine_hood_type = get(divine_hood);
    assert(divine_hood_type == Type::Magic_or_Cloth(()), 'divine hood is cloth');

    let silk_hood = ItemId::SilkHood;
    let silk_hood_type = get(silk_hood);
    assert(silk_hood_type == Type::Magic_or_Cloth(()), 'silk hood is cloth');

    let linen_hood = ItemId::LinenHood;
    let linen_hood_type = get(linen_hood);
    assert(linen_hood_type == Type::Magic_or_Cloth(()), 'linen hood is cloth');

    let hood = ItemId::Hood;
    let hood_type = get(hood);
    assert(hood_type == Type::Magic_or_Cloth(()), 'hood is cloth');

    let ornate_belt = ItemId::OrnateBelt;
    let ornate_belt_type = get(ornate_belt);
    assert(ornate_belt_type == Type::Bludgeon_or_Metal(()), 'ornate belt is metal');

    let war_belt = ItemId::WarBelt;
    let war_belt_type = get(war_belt);
    assert(war_belt_type == Type::Bludgeon_or_Metal(()), 'war belt is metal');

    let plated_belt = ItemId::PlatedBelt;
    let plated_belt_type = get(plated_belt);
    assert(plated_belt_type == Type::Bludgeon_or_Metal(()), 'plated belt is metal');

    let mesh_belt = ItemId::MeshBelt;
    let mesh_belt_type = get(mesh_belt);
    assert(mesh_belt_type == Type::Bludgeon_or_Metal(()), 'mesh belt is metal');

    let heavy_belt = ItemId::HeavyBelt;
    let heavy_belt_type = get(heavy_belt);
    assert(heavy_belt_type == Type::Bludgeon_or_Metal(()), 'heavy belt is metal');

    let demonhide_belt = ItemId::DemonhideBelt;
    let demonhide_belt_type = get(demonhide_belt);
    assert(demonhide_belt_type == Type::Blade_or_Hide(()), 'demonhide belt is hide');

    let dragonskin_belt = ItemId::DragonskinBelt;
    let dragonskin_belt_type = get(dragonskin_belt);
    assert(dragonskin_belt_type == Type::Blade_or_Hide(()), 'dragonskin belt is hide');

    let studded_leather_belt = ItemId::StuddedLeatherBelt;
    let studded_leather_belt_type = get(studded_leather_belt);
    assert(studded_leather_belt_type == Type::Blade_or_Hide(()), 'studded leather belt is hide');

    let hard_leather_belt = ItemId::HardLeatherBelt;
    let hard_leather_belt_type = get(hard_leather_belt);
    assert(hard_leather_belt_type == Type::Blade_or_Hide(()), 'hard leather belt is hide');

    let leather_belt = ItemId::LeatherBelt;
    let leather_belt_type = get(leather_belt);
    assert(leather_belt_type == Type::Blade_or_Hide(()), 'leather belt is hide');

    let brightsilk_sash = ItemId::BrightsilkSash;
    let brightsilk_sash_type = get(brightsilk_sash);
    assert(brightsilk_sash_type == Type::Magic_or_Cloth(()), 'brightsilk sash is cloth');

    let silk_sash = ItemId::SilkSash;
    let silk_sash_type = get(silk_sash);
    assert(silk_sash_type == Type::Magic_or_Cloth(()), 'silk sash is cloth');

    let wool_sash = ItemId::WoolSash;
    let wool_sash_type = get(wool_sash);
    assert(wool_sash_type == Type::Magic_or_Cloth(()), 'wool sash is cloth');

    let linen_sash = ItemId::LinenSash;
    let linen_sash_type = get(linen_sash);
    assert(linen_sash_type == Type::Magic_or_Cloth(()), 'linen sash is cloth');

    let sash = ItemId::Sash;
    let sash_type = get(sash);
    assert(sash_type == Type::Magic_or_Cloth(()), 'sash is cloth');

    let holy_greaves = ItemId::HolyGreaves;
    let holy_greaves_type = get(holy_greaves);
    assert(holy_greaves_type == Type::Bludgeon_or_Metal(()), 'holy greaves is metal');

    let ornate_greaves = ItemId::OrnateGreaves;
    let ornate_greaves_type = get(ornate_greaves);
    assert(ornate_greaves_type == Type::Bludgeon_or_Metal(()), 'ornate greaves is metal');

    let greaves = ItemId::Greaves;
    let greaves_type = get(greaves);
    assert(greaves_type == Type::Bludgeon_or_Metal(()), 'greaves is metal');

    let chain_boots = ItemId::ChainBoots;
    let chain_boots_type = get(chain_boots);
    assert(chain_boots_type == Type::Bludgeon_or_Metal(()), 'chain boots is metal');

    let heavy_boots = ItemId::HeavyBoots;
    let heavy_boots_type = get(heavy_boots);
    assert(heavy_boots_type == Type::Bludgeon_or_Metal(()), 'heavy boots is metal');

    let demonhide_boots = ItemId::DemonhideBoots;
    let demonhide_boots_type = get(demonhide_boots);
    assert(demonhide_boots_type == Type::Blade_or_Hide(()), 'demonhide boots is hide');

    let dragonskin_boots = ItemId::DragonskinBoots;
    let dragonskin_boots_type = get(dragonskin_boots);
    assert(dragonskin_boots_type == Type::Blade_or_Hide(()), 'dragonskin boots is hide');

    let studded_leather_boots = ItemId::StuddedLeatherBoots;
    let studded_leather_boots_type = get(studded_leather_boots);
    assert(studded_leather_boots_type == Type::Blade_or_Hide(()), 'studded leather boots is hide');

    let hard_leather_boots = ItemId::HardLeatherBoots;
    let hard_leather_boots_type = get(hard_leather_boots);
    assert(hard_leather_boots_type == Type::Blade_or_Hide(()), 'hard leather boots is hide');

    let leather_boots = ItemId::LeatherBoots;
    let leather_boots_type = get(leather_boots);
    assert(leather_boots_type == Type::Blade_or_Hide(()), 'leather boots is hide');

    let divine_slippers = ItemId::DivineSlippers;
    let divine_slippers_type = get(divine_slippers);
    assert(divine_slippers_type == Type::Magic_or_Cloth(()), 'divine slippers is cloth');

    let silk_slippers = ItemId::SilkSlippers;
    let silk_slippers_type = get(silk_slippers);
    assert(silk_slippers_type == Type::Magic_or_Cloth(()), 'silk slippers is cloth');

    let wool_shoes = ItemId::WoolShoes;
    let wool_shoes_type = get(wool_shoes);
    assert(wool_shoes_type == Type::Magic_or_Cloth(()), 'wool shoes is cloth');

    let linen_shoes = ItemId::LinenShoes;
    let linen_shoes_type = get(linen_shoes);
    assert(linen_shoes_type == Type::Magic_or_Cloth(()), 'linen shoes is cloth');

    let shoes = ItemId::Shoes;
    let shoes_type = get(shoes);
    assert(shoes_type == Type::Magic_or_Cloth(()), 'shoes is cloth');

    let holy_gauntlets = ItemId::HolyGauntlets;
    let holy_gauntlets_type = get(holy_gauntlets);
    assert(holy_gauntlets_type == Type::Bludgeon_or_Metal(()), 'holy gauntlets is metal');

    let ornate_gauntlets = ItemId::OrnateGauntlets;
    let ornate_gauntlets_type = get(ornate_gauntlets);
    assert(ornate_gauntlets_type == Type::Bludgeon_or_Metal(()), 'ornate gauntlets is metal');

    let gauntlets = ItemId::Gauntlets;
    let gauntlets_type = get(gauntlets);
    assert(gauntlets_type == Type::Bludgeon_or_Metal(()), 'gauntlets is metal');

    let chain_gloves = ItemId::ChainGloves;
    let chain_gloves_type = get(chain_gloves);
    assert(chain_gloves_type == Type::Bludgeon_or_Metal(()), 'chain gloves is metal');

    let heavy_gloves = ItemId::HeavyGloves;
    let heavy_gloves_type = get(heavy_gloves);
    assert(heavy_gloves_type == Type::Bludgeon_or_Metal(()), 'heavy gloves is metal');

    let demons_hands = ItemId::DemonsHands;
    let demons_hands_type = get(demons_hands);
    assert(demons_hands_type == Type::Blade_or_Hide(()), 'demons hands is hide');

    let dragonskin_gloves = ItemId::DragonskinGloves;
    let dragonskin_gloves_type = get(dragonskin_gloves);
    assert(dragonskin_gloves_type == Type::Blade_or_Hide(()), 'dragonskin gloves is hide');

    let studded_leather_gloves = ItemId::StuddedLeatherGloves;
    let studded_leather_gloves_type = get(studded_leather_gloves);
    assert(
        studded_leather_gloves_type == Type::Blade_or_Hide(()), 'studded leather gloves is hide'
    );

    let hard_leather_gloves = ItemId::HardLeatherGloves;
    let hard_leather_gloves_type = get(hard_leather_gloves);
    assert(hard_leather_gloves_type == Type::Blade_or_Hide(()), 'hard leather gloves is hide');

    let leather_gloves = ItemId::LeatherGloves;
    let leather_gloves_type = get(leather_gloves);
    assert(leather_gloves_type == Type::Blade_or_Hide(()), 'leather gloves is hide');

    let necklace = ItemId::Necklace;
    let necklace_type = get(necklace);
    assert(necklace_type == Type::Necklace(()), 'necklace is necklace');

    let amulet = ItemId::Amulet;
    let amulet_type = get(amulet);
    assert(amulet_type == Type::Necklace(()), 'amulet is necklace');

    let pendant = ItemId::Pendant;
    let pendant_type = get(pendant);
    assert(pendant_type == Type::Necklace(()), 'pendant is necklace');

    let gold_ring = ItemId::GoldRing;
    let gold_ring_type = get(gold_ring);
    assert(gold_ring_type == Type::Ring(()), 'gold ring is ring');

    let silver_ring = ItemId::SilverRing;
    let silver_ring_type = get(silver_ring);
    assert(silver_ring_type == Type::Ring(()), 'silver ring is ring');

    let bronze_ring = ItemId::BronzeRing;
    let bronze_ring_type = get(bronze_ring);
    assert(bronze_ring_type == Type::Ring(()), 'bronze ring is ring');

    let platinum_ring = ItemId::PlatinumRing;
    let platinum_ring_type = get(platinum_ring);
    assert(platinum_ring_type == Type::Ring(()), 'platinum ring is ring');

    let titanium_ring = ItemId::TitaniumRing;
    let titanium_ring_type = get(titanium_ring);
    assert(titanium_ring_type == Type::Ring(()), 'titanium ring is ring');
}
