use array::ArrayTrait;
use lootitems::statistics::item_tier;
use lootitems::statistics::constants::{ItemNamePrefix, ItemId, ItemIndex};
use combat::constants::CombatEnums::Tier;

fn get(index: u8) -> u8 {
    if index == ItemId::Pendant {
        return ItemIndex::Pendant;
    } else if index == ItemId::Necklace {
        return ItemIndex::Necklace;
    } else if index == ItemId::Amulet {
        return ItemIndex::Amulet;
    } else if index == ItemId::SilverRing {
        return ItemIndex::SilverRing;
    } else if index == ItemId::BronzeRing {
        return ItemIndex::BronzeRing;
    } else if index == ItemId::PlatinumRing {
        return ItemIndex::PlatinumRing;
    } else if index == ItemId::TitaniumRing {
        return ItemIndex::TitaniumRing;
    } else if index == ItemId::GoldRing {
        return ItemIndex::GoldRing;
    } else if index == ItemId::GhostWand {
        return ItemIndex::GhostWand;
    } else if index == ItemId::GraveWand {
        return ItemIndex::GraveWand;
    } else if index == ItemId::BoneWand {
        return ItemIndex::BoneWand;
    } else if index == ItemId::Wand {
        return ItemIndex::Wand;
    } else if index == ItemId::Grimoire {
        return ItemIndex::Grimoire;
    } else if index == ItemId::Chronicle {
        return ItemIndex::Chronicle;
    } else if index == ItemId::Tome {
        return ItemIndex::Tome;
    } else if index == ItemId::Book {
        return ItemIndex::Book;
    } else if index == ItemId::DivineRobe {
        return ItemIndex::DivineRobe;
    } else if index == ItemId::SilkRobe {
        return ItemIndex::SilkRobe;
    } else if index == ItemId::LinenRobe {
        return ItemIndex::LinenRobe;
    } else if index == ItemId::Robe {
        return ItemIndex::Robe;
    } else if index == ItemId::Shirt {
        return ItemIndex::Shirt;
    } else if index == ItemId::Crown {
        return ItemIndex::Crown;
    } else if index == ItemId::DivineHood {
        return ItemIndex::DivineHood;
    } else if index == ItemId::SilkHood {
        return ItemIndex::SilkHood;
    } else if index == ItemId::LinenHood {
        return ItemIndex::LinenHood;
    } else if index == ItemId::Hood {
        return ItemIndex::Hood;
    } else if index == ItemId::BrightsilkSash {
        return ItemIndex::BrightsilkSash;
    } else if index == ItemId::SilkSash {
        return ItemIndex::SilkSash;
    } else if index == ItemId::WoolSash {
        return ItemIndex::WoolSash;
    } else if index == ItemId::LinenSash {
        return ItemIndex::LinenSash;
    } else if index == ItemId::Sash {
        return ItemIndex::Sash;
    } else if index == ItemId::DivineSlippers {
        return ItemIndex::DivineSlippers;
    } else if index == ItemId::SilkSlippers {
        return ItemIndex::SilkSlippers;
    } else if index == ItemId::WoolShoes {
        return ItemIndex::WoolShoes;
    } else if index == ItemId::LinenShoes {
        return ItemIndex::LinenShoes;
    } else if index == ItemId::Shoes {
        return ItemIndex::Shoes;
    } else if index == ItemId::DivineGloves {
        return ItemIndex::DivineGloves;
    } else if index == ItemId::SilkGloves {
        return ItemIndex::SilkGloves;
    } else if index == ItemId::WoolGloves {
        return ItemIndex::WoolGloves;
    } else if index == ItemId::LinenGloves {
        return ItemIndex::LinenGloves;
    } else if index == ItemId::Gloves {
        return ItemIndex::Gloves;
    } else if index == ItemId::Katana {
        return ItemIndex::Katana;
    } else if index == ItemId::Falchion {
        return ItemIndex::Falchion;
    } else if index == ItemId::Scimitar {
        return ItemIndex::Scimitar;
    } else if index == ItemId::LongSword {
        return ItemIndex::LongSword;
    } else if index == ItemId::ShortSword {
        return ItemIndex::ShortSword;
    } else if index == ItemId::DemonHusk {
        return ItemIndex::DemonHusk;
    } else if index == ItemId::DragonskinArmor {
        return ItemIndex::DragonskinArmor;
    } else if index == ItemId::StuddedLeatherArmor {
        return ItemIndex::StuddedLeatherArmor;
    } else if index == ItemId::HardLeatherArmor {
        return ItemIndex::HardLeatherArmor;
    } else if index == ItemId::LeatherArmor {
        return ItemIndex::LeatherArmor;
    } else if index == ItemId::DemonCrown {
        return ItemIndex::DemonCrown;
    } else if index == ItemId::DragonsCrown {
        return ItemIndex::DragonsCrown;
    } else if index == ItemId::WarCap {
        return ItemIndex::WarCap;
    } else if index == ItemId::LeatherCap {
        return ItemIndex::LeatherCap;
    } else if index == ItemId::Cap {
        return ItemIndex::Cap;
    } else if index == ItemId::DemonhideBelt {
        return ItemIndex::DemonhideBelt;
    } else if index == ItemId::DragonskinBelt {
        return ItemIndex::DragonskinBelt;
    } else if index == ItemId::StuddedLeatherBelt {
        return ItemIndex::StuddedLeatherBelt;
    } else if index == ItemId::HardLeatherBelt {
        return ItemIndex::HardLeatherBelt;
    } else if index == ItemId::LeatherBelt {
        return ItemIndex::LeatherBelt;
    } else if index == ItemId::DemonhideBoots {
        return ItemIndex::DemonhideBoots;
    } else if index == ItemId::DragonskinBoots {
        return ItemIndex::DragonskinBoots;
    } else if index == ItemId::StuddedLeatherBoots {
        return ItemIndex::StuddedLeatherBoots;
    } else if index == ItemId::HardLeatherBoots {
        return ItemIndex::HardLeatherBoots;
    } else if index == ItemId::LeatherBoots {
        return ItemIndex::LeatherBoots;
    } else if index == ItemId::DemonsHands {
        return ItemIndex::DemonsHands;
    } else if index == ItemId::DragonskinGloves {
        return ItemIndex::DragonskinGloves;
    } else if index == ItemId::StuddedLeatherGloves {
        return ItemIndex::StuddedLeatherGloves;
    } else if index == ItemId::HardLeatherGloves {
        return ItemIndex::HardLeatherGloves;
    } else if index == ItemId::LeatherGloves {
        return ItemIndex::LeatherGloves;
    } else if index == ItemId::HolyChestplate {
        return ItemIndex::HolyChestplate;
    } else if index == ItemId::OrnateChestplate {
        return ItemIndex::OrnateChestplate;
    } else if index == ItemId::PlateMail {
        return ItemIndex::PlateMail;
    } else if index == ItemId::ChainMail {
        return ItemIndex::ChainMail;
    } else if index == ItemId::RingMail {
        return ItemIndex::RingMail;
    } else if index == ItemId::AncientHelm {
        return ItemIndex::AncientHelm;
    } else if index == ItemId::OrnateHelm {
        return ItemIndex::OrnateHelm;
    } else if index == ItemId::GreatHelm {
        return ItemIndex::GreatHelm;
    } else if index == ItemId::FullHelm {
        return ItemIndex::FullHelm;
    } else if index == ItemId::Helm {
        return ItemIndex::Helm;
    } else if index == ItemId::OrnateBelt {
        return ItemIndex::OrnateBelt;
    } else if index == ItemId::WarBelt {
        return ItemIndex::WarBelt;
    } else if index == ItemId::PlatedBelt {
        return ItemIndex::PlatedBelt;
    } else if index == ItemId::MeshBelt {
        return ItemIndex::MeshBelt;
    } else if index == ItemId::HeavyBelt {
        return ItemIndex::HeavyBelt;
    } else if index == ItemId::HolyGreaves {
        return ItemIndex::HolyGreaves;
    } else if index == ItemId::OrnateGreaves {
        return ItemIndex::OrnateGreaves;
    } else if index == ItemId::Greaves {
        return ItemIndex::Greaves;
    } else if index == ItemId::ChainBoots {
        return ItemIndex::ChainBoots;
    } else if index == ItemId::HeavyBoots {
        return ItemIndex::HeavyBoots;
    } else {
        return 0;
    }
}
