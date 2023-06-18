use array::ArrayTrait;
use lootitems::statistics::item_slot;
use lootitems::statistics::constants::ItemId;
use combat::constants::CombatEnums::Slot;

fn get(id: u8) -> Slot {
    // Weapons
    if id == ItemId::Warhammer {
        return Slot::Weapon(());
    } else if id == ItemId::Quarterstaff {
        return Slot::Weapon(());
    } else if id == ItemId::Maul {
        return Slot::Weapon(());
    } else if id == ItemId::Mace {
        return Slot::Weapon(());
    } else if id == ItemId::Club {
        return Slot::Weapon(());
    } else if id == ItemId::GhostWand {
        return Slot::Weapon(());
    } else if id == ItemId::GraveWand {
        return Slot::Weapon(());
    } else if id == ItemId::BoneWand {
        return Slot::Weapon(());
    } else if id == ItemId::Wand {
        return Slot::Weapon(());
    } else if id == ItemId::Grimoire {
        return Slot::Weapon(());
    } else if id == ItemId::Chronicle {
        return Slot::Weapon(());
    } else if id == ItemId::Tome {
        return Slot::Weapon(());
    } else if id == ItemId::Book {
        return Slot::Weapon(());
    } else if id == ItemId::Katana {
        return Slot::Weapon(());
    } else if id == ItemId::Falchion {
        return Slot::Weapon(());
    } else if id == ItemId::Scimitar {
        return Slot::Weapon(());
    } else if id == ItemId::LongSword {
        return Slot::Weapon(());
    } else if id == ItemId::ShortSword {
        return Slot::Weapon(());
    //
    // Chest Armor
    //
    } else if id == ItemId::HolyChestplate {
        return Slot::Chest(());
    } else if id == ItemId::OrnateChestplate {
        return Slot::Chest(());
    } else if id == ItemId::PlateMail {
        return Slot::Chest(());
    } else if id == ItemId::ChainMail {
        return Slot::Chest(());
    } else if id == ItemId::RingMail {
        return Slot::Chest(());
    } else if id == ItemId::DivineRobe {
        return Slot::Chest(());
    } else if id == ItemId::SilkRobe {
        return Slot::Chest(());
    } else if id == ItemId::LinenRobe {
        return Slot::Chest(());
    } else if id == ItemId::Robe {
        return Slot::Chest(());
    } else if id == ItemId::Shirt {
        return Slot::Chest(());
    } else if id == ItemId::DemonHusk {
        return Slot::Chest(());
    } else if id == ItemId::DragonskinArmor {
        return Slot::Chest(());
    } else if id == ItemId::StuddedLeatherArmor {
        return Slot::Chest(());
    } else if id == ItemId::HardLeatherArmor {
        return Slot::Chest(());
    } else if id == ItemId::LeatherArmor {
        return Slot::Chest(());
    //
    // Head Armor
    //
    } else if id == ItemId::AncientHelm {
        return Slot::Head(());
    } else if id == ItemId::OrnateHelm {
        return Slot::Head(());
    } else if id == ItemId::GreatHelm {
        return Slot::Head(());
    } else if id == ItemId::FullHelm {
        return Slot::Head(());
    } else if id == ItemId::Helm {
        return Slot::Head(());
    } else if id == ItemId::Crown {
        return Slot::Head(());
    } else if id == ItemId::DivineHood {
        return Slot::Head(());
    } else if id == ItemId::SilkHood {
        return Slot::Head(());
    } else if id == ItemId::LinenHood {
        return Slot::Head(());
    } else if id == ItemId::Hood {
        return Slot::Head(());
    } else if id == ItemId::DemonCrown {
        return Slot::Head(());
    } else if id == ItemId::DragonsCrown {
        return Slot::Head(());
    } else if id == ItemId::WarCap {
        return Slot::Head(());
    } else if id == ItemId::LeatherCap {
        return Slot::Head(());
    } else if id == ItemId::Cap {
        return Slot::Head(());
    //
    // Waist armor
    //
    } else if id == ItemId::OrnateBelt {
        return Slot::Waist(());
    } else if id == ItemId::WarBelt {
        return Slot::Waist(());
    } else if id == ItemId::PlatedBelt {
        return Slot::Waist(());
    } else if id == ItemId::MeshBelt {
        return Slot::Waist(());
    } else if id == ItemId::HeavyBelt {
        return Slot::Waist(());
    } else if id == ItemId::BrightsilkSash {
        return Slot::Waist(());
    } else if id == ItemId::SilkSash {
        return Slot::Waist(());
    } else if id == ItemId::WoolSash {
        return Slot::Waist(());
    } else if id == ItemId::LinenSash {
        return Slot::Waist(());
    } else if id == ItemId::Sash {
        return Slot::Waist(());
    } else if id == ItemId::DemonhideBelt {
        return Slot::Waist(());
    } else if id == ItemId::DragonskinBelt {
        return Slot::Waist(());
    } else if id == ItemId::StuddedLeatherBelt {
        return Slot::Waist(());
    } else if id == ItemId::HardLeatherBelt {
        return Slot::Waist(());
    } else if id == ItemId::LeatherBelt {
        return Slot::Waist(());
    //
    // Foot armor
    //
    } else if id == ItemId::HolyGreaves {
        return Slot::Foot(());
    } else if id == ItemId::OrnateGreaves {
        return Slot::Foot(());
    } else if id == ItemId::Greaves {
        return Slot::Foot(());
    } else if id == ItemId::ChainBoots {
        return Slot::Foot(());
    } else if id == ItemId::HeavyBoots {
        return Slot::Foot(());
    } else if id == ItemId::DivineSlippers {
        return Slot::Foot(());
    } else if id == ItemId::SilkSlippers {
        return Slot::Foot(());
    } else if id == ItemId::WoolShoes {
        return Slot::Foot(());
    } else if id == ItemId::LinenShoes {
        return Slot::Foot(());
    } else if id == ItemId::Shoes {
        return Slot::Foot(());
    } else if id == ItemId::DemonhideBoots {
        return Slot::Foot(());
    } else if id == ItemId::DragonskinBoots {
        return Slot::Foot(());
    } else if id == ItemId::StuddedLeatherBoots {
        return Slot::Foot(());
    } else if id == ItemId::HardLeatherBoots {
        return Slot::Foot(());
    } else if id == ItemId::LeatherBoots {
        return Slot::Foot(());
    //
    // Hand armor
    //
    } else if id == ItemId::HolyGauntlets {
        return Slot::Hand(());
    } else if id == ItemId::OrnateGauntlets {
        return Slot::Hand(());
    } else if id == ItemId::Gauntlets {
        return Slot::Hand(());
    } else if id == ItemId::ChainGloves {
        return Slot::Hand(());
    } else if id == ItemId::HeavyGloves {
        return Slot::Hand(());
    } else if id == ItemId::DivineGloves {
        return Slot::Hand(());
    } else if id == ItemId::SilkGloves {
        return Slot::Hand(());
    } else if id == ItemId::WoolGloves {
        return Slot::Hand(());
    } else if id == ItemId::LinenGloves {
        return Slot::Hand(());
    } else if id == ItemId::Gloves {
        return Slot::Hand(());
    } else if id == ItemId::DemonsHands {
        return Slot::Hand(());
    } else if id == ItemId::DragonskinGloves {
        return Slot::Hand(());
    } else if id == ItemId::StuddedLeatherGloves {
        return Slot::Hand(());
    } else if id == ItemId::HardLeatherGloves {
        return Slot::Hand(());
    } else if id == ItemId::LeatherGloves {
        return Slot::Hand(());
    //
    // Necklaces
    //
    } else if id == ItemId::Pendant {
        return Slot::Neck(());
    } else if id == ItemId::Necklace {
        return Slot::Neck(());
    } else if id == ItemId::Amulet {
        return Slot::Neck(());
    //
    // Rings
    //
    } else if id == ItemId::SilverRing {
        return Slot::Ring(());
    } else if id == ItemId::BronzeRing {
        return Slot::Ring(());
    } else if id == ItemId::PlatinumRing {
        return Slot::Ring(());
    } else if id == ItemId::TitaniumRing {
        return Slot::Ring(());
    } else if id == ItemId::GoldRing {
        return Slot::Ring(());
    } else {
        // invalid id passed in
        return Slot::Ring(());
    }
}

#[test]
#[available_gas(3000000)]
fn test_get_item_slots() {
    // Weapons
    let katana = ItemId::Katana;
    let katana_slot = get(katana);
    assert(katana_slot == Slot::Weapon(()), 'katana is weapon slot');

    let warhammer = ItemId::Warhammer;
    let warhammer_slot = get(warhammer);
    assert(warhammer_slot == Slot::Weapon(()), 'warhammer is weapon slot');

    let quarterstaff = ItemId::Quarterstaff;
    let quarterstaff_slot = get(quarterstaff);
    assert(quarterstaff_slot == Slot::Weapon(()), 'quarterstaff is weapon slot');

    let maul = ItemId::Maul;
    let maul_slot = get(maul);
    assert(maul_slot == Slot::Weapon(()), 'maul is weapon slot');

    let mace = ItemId::Mace;
    let mace_slot = get(mace);
    assert(mace_slot == Slot::Weapon(()), 'mace is weapon slot');

    let club = ItemId::Club;
    let club_slot = get(club);
    assert(club_slot == Slot::Weapon(()), 'club is weapon slot');

    let falchion = ItemId::Falchion;
    let falchion_slot = get(falchion);
    assert(falchion_slot == Slot::Weapon(()), 'falchion is weapon slot');

    let scimitar = ItemId::Scimitar;
    let scimitar_slot = get(scimitar);
    assert(scimitar_slot == Slot::Weapon(()), 'scimitar is weapon slot');

    let long_sword = ItemId::LongSword;
    let long_sword_slot = get(long_sword);
    assert(long_sword_slot == Slot::Weapon(()), 'long sword is weapon slot');

    let short_sword = ItemId::ShortSword;
    let short_sword_slot = get(short_sword);
    assert(short_sword_slot == Slot::Weapon(()), 'short sword is weapon slot');

    let ghost_wand = ItemId::GhostWand;
    let ghost_wand_slot = get(ghost_wand);
    assert(ghost_wand_slot == Slot::Weapon(()), 'ghost wand is weapon slot');

    let grave_wand = ItemId::GraveWand;
    let grave_wand_slot = get(grave_wand);
    assert(grave_wand_slot == Slot::Weapon(()), 'grave wand is weapon slot');

    let bone_wand = ItemId::BoneWand;
    let bone_wand_slot = get(bone_wand);
    assert(bone_wand_slot == Slot::Weapon(()), 'bone wand is weapon slot');

    let wand = ItemId::Wand;
    let wand_slot = get(wand);
    assert(wand_slot == Slot::Weapon(()), 'wand is weapon slot');

    let grimoire = ItemId::Grimoire;
    let grimoire_slot = get(grimoire);
    assert(grimoire_slot == Slot::Weapon(()), 'grimoire is weapon slot');

    let chronicle = ItemId::Chronicle;
    let chronicle_slot = get(chronicle);
    assert(chronicle_slot == Slot::Weapon(()), 'chronicle is weapon slot');

    let tome = ItemId::Tome;
    let tome_slot = get(tome);
    assert(tome_slot == Slot::Weapon(()), 'tome is weapon slot');

    let book = ItemId::Book;
    let book_slot = get(book);
    assert(book_slot == Slot::Weapon(()), 'book is weapon slot');

    // Chest
    let divine_robe = ItemId::DivineRobe;
    let divine_robe_slot = get(divine_robe);
    assert(divine_robe_slot == Slot::Chest(()), 'divine robe is chest slot');

    let silk_robe = ItemId::SilkRobe;
    let silk_robe_slot = get(silk_robe);
    assert(silk_robe_slot == Slot::Chest(()), 'silk robe is chest slot');

    let linen_robe = ItemId::LinenRobe;
    let linen_robe_slot = get(linen_robe);
    assert(linen_robe_slot == Slot::Chest(()), 'linen robe is chest slot');

    let robe = ItemId::Robe;
    let robe_slot = get(robe);
    assert(robe_slot == Slot::Chest(()), 'robe is chest slot');

    let shirt = ItemId::Shirt;
    let shirt_slot = get(shirt);
    assert(shirt_slot == Slot::Chest(()), 'shirt is chest slot');

    let demon_husk = ItemId::DemonHusk;
    let demon_husk_slot = get(demon_husk);
    assert(demon_husk_slot == Slot::Chest(()), 'demon husk is chest slot');

    let dragonskin_armor = ItemId::DragonskinArmor;
    let dragonskin_armor_slot = get(dragonskin_armor);
    assert(dragonskin_armor_slot == Slot::Chest(()), 'dragonskin armor is chest slot');

    let studded_leather_armor = ItemId::StuddedLeatherArmor;
    let studded_leather_armor_slot = get(studded_leather_armor);
    assert(studded_leather_armor_slot == Slot::Chest(()), 'studded leather armor slot err');

    let hard_leather_armor = ItemId::HardLeatherArmor;
    let hard_leather_armor_slot = get(hard_leather_armor);
    assert(hard_leather_armor_slot == Slot::Chest(()), 'hard leather armor slot err');

    let leather_armor = ItemId::LeatherArmor;
    let leather_armor_slot = get(leather_armor);
    assert(leather_armor_slot == Slot::Chest(()), 'leather armor is chest slot');

    let holy_chestplate = ItemId::HolyChestplate;
    let holy_chestplate_slot = get(holy_chestplate);
    assert(holy_chestplate_slot == Slot::Chest(()), 'holy chestplate is chest slot');

    let ornate_chestplate = ItemId::OrnateChestplate;
    let ornate_chestplate_slot = get(ornate_chestplate);
    assert(ornate_chestplate_slot == Slot::Chest(()), 'ornate chestplate is chest slot');

    let plate_mail = ItemId::PlateMail;
    let plate_mail_slot = get(plate_mail);
    assert(plate_mail_slot == Slot::Chest(()), 'plate mail is chest slot');

    let chain_mail = ItemId::ChainMail;
    let chain_mail_slot = get(chain_mail);
    assert(chain_mail_slot == Slot::Chest(()), 'chain mail is chest slot');

    let ring_mail = ItemId::RingMail;
    let ring_mail_slot = get(ring_mail);
    assert(ring_mail_slot == Slot::Chest(()), 'ring mail is chest slot');

    // Head
    let ancient_helm = ItemId::AncientHelm;
    let ancient_helm_slot = get(ancient_helm);
    assert(ancient_helm_slot == Slot::Head(()), 'ancient helm is head slot');

    let ornate_helm = ItemId::OrnateHelm;
    let ornate_helm_slot = get(ornate_helm);
    assert(ornate_helm_slot == Slot::Head(()), 'ornate helm is head slot');

    let great_helm = ItemId::GreatHelm;
    let great_helm_slot = get(great_helm);
    assert(great_helm_slot == Slot::Head(()), 'great helm is head slot');

    let full_helm = ItemId::FullHelm;
    let full_helm_slot = get(full_helm);
    assert(full_helm_slot == Slot::Head(()), 'full helm is head slot');

    let helm = ItemId::Helm;
    let helm_slot = get(helm);
    assert(helm_slot == Slot::Head(()), 'helm is head slot');

    let demon_crown = ItemId::DemonCrown;
    let demon_crown_slot = get(demon_crown);
    assert(demon_crown_slot == Slot::Head(()), 'demon crown is head slot');

    let dragons_crown = ItemId::DragonsCrown;
    let dragons_crown_slot = get(dragons_crown);
    assert(dragons_crown_slot == Slot::Head(()), 'dragons crown is head slot');

    let war_cap = ItemId::WarCap;
    let war_cap_slot = get(war_cap);
    assert(war_cap_slot == Slot::Head(()), 'war cap is head slot');

    let leather_cap = ItemId::LeatherCap;
    let leather_cap_slot = get(leather_cap);
    assert(leather_cap_slot == Slot::Head(()), 'leather cap is head slot');

    let cap = ItemId::Cap;
    let cap_slot = get(cap);
    assert(cap_slot == Slot::Head(()), 'cap is head slot');

    let crown = ItemId::Crown;
    let crown_slot = get(crown);
    assert(crown_slot == Slot::Head(()), 'crown is head slot');

    let divine_hood = ItemId::DivineHood;
    let divine_hood_slot = get(divine_hood);
    assert(divine_hood_slot == Slot::Head(()), 'divine hood is head slot');

    let silk_hood = ItemId::SilkHood;
    let silk_hood_slot = get(silk_hood);
    assert(silk_hood_slot == Slot::Head(()), 'silk hood is head slot');

    let linen_hood = ItemId::LinenHood;
    let linen_hood_slot = get(linen_hood);
    assert(linen_hood_slot == Slot::Head(()), 'linen hood is head slot');

    let hood = ItemId::Hood;
    let hood_slot = get(hood);
    assert(hood_slot == Slot::Head(()), 'hood is head slot');

    // Waist
    let ornate_belt = ItemId::OrnateBelt;
    let ornate_belt_slot = get(ornate_belt);
    assert(ornate_belt_slot == Slot::Waist(()), 'ornate belt is waist slot');

    let war_belt = ItemId::WarBelt;
    let war_belt_slot = get(war_belt);
    assert(war_belt_slot == Slot::Waist(()), 'war belt is waist slot');

    let plated_belt = ItemId::PlatedBelt;
    let plated_belt_slot = get(plated_belt);
    assert(plated_belt_slot == Slot::Waist(()), 'plated belt is waist slot');

    let mesh_belt = ItemId::MeshBelt;
    let mesh_belt_slot = get(mesh_belt);
    assert(mesh_belt_slot == Slot::Waist(()), 'mesh belt is waist slot');

    let heavy_belt = ItemId::HeavyBelt;
    let heavy_belt_slot = get(heavy_belt);
    assert(heavy_belt_slot == Slot::Waist(()), 'heavy belt is waist slot');

    let demonhide_belt = ItemId::DemonhideBelt;
    let demonhide_belt_slot = get(demonhide_belt);
    assert(demonhide_belt_slot == Slot::Waist(()), 'demonhide belt is waist slot');

    let dragonskin_belt = ItemId::DragonskinBelt;
    let dragonskin_belt_slot = get(dragonskin_belt);
    assert(dragonskin_belt_slot == Slot::Waist(()), 'dragonskin belt is waist slot');

    let studded_leather_belt = ItemId::StuddedLeatherBelt;
    let studded_leather_belt_slot = get(studded_leather_belt);
    assert(studded_leather_belt_slot == Slot::Waist(()), 'studded leather belt wrong slot');

    let hard_leather_belt = ItemId::HardLeatherBelt;
    let hard_leather_belt_slot = get(hard_leather_belt);
    assert(hard_leather_belt_slot == Slot::Waist(()), 'hard leather belt is waist slot');

    let leather_belt = ItemId::LeatherBelt;
    let leather_belt_slot = get(leather_belt);
    assert(leather_belt_slot == Slot::Waist(()), 'leather belt is waist slot');

    let brightsilk_sash = ItemId::BrightsilkSash;
    let brightsilk_sash_slot = get(brightsilk_sash);
    assert(brightsilk_sash_slot == Slot::Waist(()), 'brightsilk sash is waist slot');

    let silk_sash = ItemId::SilkSash;
    let silk_sash_slot = get(silk_sash);
    assert(silk_sash_slot == Slot::Waist(()), 'silk sash is waist slot');

    let wool_sash = ItemId::WoolSash;
    let wool_sash_slot = get(wool_sash);
    assert(wool_sash_slot == Slot::Waist(()), 'wool sash is waist slot');

    let linen_sash = ItemId::LinenSash;
    let linen_sash_slot = get(linen_sash);
    assert(linen_sash_slot == Slot::Waist(()), 'linen sash is waist slot');

    let sash = ItemId::Sash;
    let sash_slot = get(sash);
    assert(sash_slot == Slot::Waist(()), 'sash is waist slot');

    // Foot
    let holy_greaves = ItemId::HolyGreaves;
    let holy_greaves_slot = get(holy_greaves);
    assert(holy_greaves_slot == Slot::Foot(()), 'holy greaves is foot slot');

    let ornate_greaves = ItemId::OrnateGreaves;
    let ornate_greaves_slot = get(ornate_greaves);
    assert(ornate_greaves_slot == Slot::Foot(()), 'ornate greaves is foot slot');

    let greaves = ItemId::Greaves;
    let greaves_slot = get(greaves);
    assert(greaves_slot == Slot::Foot(()), 'greaves is foot slot');

    let chain_boots = ItemId::ChainBoots;
    let chain_boots_slot = get(chain_boots);
    assert(chain_boots_slot == Slot::Foot(()), 'chain boots is foot slot');

    let heavy_boots = ItemId::HeavyBoots;
    let heavy_boots_slot = get(heavy_boots);
    assert(heavy_boots_slot == Slot::Foot(()), 'heavy boots is foot slot');

    let demonhide_boots = ItemId::DemonhideBoots;
    let demonhide_boots_slot = get(demonhide_boots);
    assert(demonhide_boots_slot == Slot::Foot(()), 'demonhide boots is foot slot');

    let dragonskin_boots = ItemId::DragonskinBoots;
    let dragonskin_boots_slot = get(dragonskin_boots);
    assert(dragonskin_boots_slot == Slot::Foot(()), 'dragonskin boots is foot slot');

    let studded_leather_boots = ItemId::StuddedLeatherBoots;
    let studded_leather_boots_slot = get(studded_leather_boots);
    assert(studded_leather_boots_slot == Slot::Foot(()), 'studded leather boots err');

    let hard_leather_boots = ItemId::HardLeatherBoots;
    let hard_leather_boots_slot = get(hard_leather_boots);
    assert(hard_leather_boots_slot == Slot::Foot(()), 'hard leather boots is foot slot');

    let leather_boots = ItemId::LeatherBoots;
    let leather_boots_slot = get(leather_boots);
    assert(leather_boots_slot == Slot::Foot(()), 'leather boots is foot slot');

    let divine_slippers = ItemId::DivineSlippers;
    let divine_slippers_slot = get(divine_slippers);
    assert(divine_slippers_slot == Slot::Foot(()), 'divine slippers is foot slot');

    let silk_slippers = ItemId::SilkSlippers;
    let silk_slippers_slot = get(silk_slippers);
    assert(silk_slippers_slot == Slot::Foot(()), 'silk slippers is foot slot');

    let wool_shoes = ItemId::WoolShoes;
    let wool_shoes_slot = get(wool_shoes);
    assert(wool_shoes_slot == Slot::Foot(()), 'wool shoes is foot slot');

    let linen_shoes = ItemId::LinenShoes;
    let linen_shoes_slot = get(linen_shoes);
    assert(linen_shoes_slot == Slot::Foot(()), 'linen shoes is foot slot');

    let shoes = ItemId::Shoes;
    let shoes_slot = get(shoes);
    assert(shoes_slot == Slot::Foot(()), 'shoes is foot slot');

    // Hand
    let holy_gauntlets = ItemId::HolyGauntlets;
    let holy_gauntlets_slot = get(holy_gauntlets);
    assert(holy_gauntlets_slot == Slot::Hand(()), 'holy gauntlets is hand slot');

    let ornate_gauntlets = ItemId::OrnateGauntlets;
    let ornate_gauntlets_slot = get(ornate_gauntlets);
    assert(ornate_gauntlets_slot == Slot::Hand(()), 'ornate gauntlets is hand slot');

    let gauntlets = ItemId::Gauntlets;
    let gauntlets_slot = get(gauntlets);
    assert(gauntlets_slot == Slot::Hand(()), 'gauntlets is hand slot');

    let chain_gloves = ItemId::ChainGloves;
    let chain_gloves_slot = get(chain_gloves);
    assert(chain_gloves_slot == Slot::Hand(()), 'chain gloves is hand slot');

    let heavy_gloves = ItemId::HeavyGloves;
    let heavy_gloves_slot = get(heavy_gloves);
    assert(heavy_gloves_slot == Slot::Hand(()), 'heavy gloves is hand slot');

    let demons_hands = ItemId::DemonsHands;
    let demons_hands_slot = get(demons_hands);
    assert(demons_hands_slot == Slot::Hand(()), 'demons hands is hand slot');

    let dragonskin_gloves = ItemId::DragonskinGloves;
    let dragonskin_gloves_slot = get(dragonskin_gloves);
    assert(dragonskin_gloves_slot == Slot::Hand(()), 'dragonskin gloves is hand slot');

    let studded_leather_gloves = ItemId::StuddedLeatherGloves;
    let studded_leather_gloves_slot = get(studded_leather_gloves);
    assert(studded_leather_gloves_slot == Slot::Hand(()), 'studded leather gloves err');

    let hard_leather_gloves = ItemId::HardLeatherGloves;
    let hard_leather_gloves_slot = get(hard_leather_gloves);
    assert(hard_leather_gloves_slot == Slot::Hand(()), 'hard leather gloves wrong slot');

    let leather_gloves = ItemId::LeatherGloves;
    let leather_gloves_slot = get(leather_gloves);
    assert(leather_gloves_slot == Slot::Hand(()), 'leather gloves is hand slot');

    let divine_gloves = ItemId::DivineGloves;
    let divine_gloves_slot = get(divine_gloves);
    assert(divine_gloves_slot == Slot::Hand(()), 'divine gloves is hand slot');

    let silk_gloves = ItemId::SilkGloves;
    let silk_gloves_slot = get(silk_gloves);
    assert(silk_gloves_slot == Slot::Hand(()), 'silk gloves is hand slot');

    let wool_gloves = ItemId::WoolGloves;
    let wool_gloves_slot = get(wool_gloves);
    assert(wool_gloves_slot == Slot::Hand(()), 'wool gloves is hand slot');

    let linen_gloves = ItemId::LinenGloves;
    let linen_gloves_slot = get(linen_gloves);
    assert(linen_gloves_slot == Slot::Hand(()), 'linen gloves is hand slot');

    let gloves = ItemId::Gloves;
    let gloves_slot = get(gloves);
    assert(gloves_slot == Slot::Hand(()), 'gloves is hand slot');

    // Necklaces
    let necklace = ItemId::Necklace;
    let necklace_slot = get(necklace);
    assert(necklace_slot == Slot::Neck(()), 'necklace is necklace slot');

    let amulet = ItemId::Amulet;
    let amulet_slot = get(amulet);
    assert(amulet_slot == Slot::Neck(()), 'amulet is necklace slot');

    let pendant = ItemId::Pendant;
    let pendant_slot = get(pendant);
    assert(pendant_slot == Slot::Neck(()), 'pendant is necklace slot');

    // Rings
    let gold_ring = ItemId::GoldRing;
    let gold_ring_slot = get(gold_ring);
    assert(gold_ring_slot == Slot::Ring(()), 'gold ring is ring slot');

    let silver_ring = ItemId::SilverRing;
    let silver_ring_slot = get(silver_ring);
    assert(silver_ring_slot == Slot::Ring(()), 'silver ring is ring slot');

    let bronze_ring = ItemId::BronzeRing;
    let bronze_ring_slot = get(bronze_ring);
    assert(bronze_ring_slot == Slot::Ring(()), 'bronze ring is ring slot');

    let platinum_ring = ItemId::PlatinumRing;
    let platinum_ring_slot = get(platinum_ring);
    assert(platinum_ring_slot == Slot::Ring(()), 'platinum ring is ring slot');

    let titanium_ring = ItemId::TitaniumRing;
    let titanium_ring_slot = get(titanium_ring);
    assert(titanium_ring_slot == Slot::Ring(()), 'titanium ring is ring slot');
}
