mod ItemId {
    const Pendant: u8 = 1;
    const Necklace: u8 = 2;
    const Amulet: u8 = 3;
    const SilverRing: u8 = 4;
    const BronzeRing: u8 = 5;
    const PlatinumRing: u8 = 6;
    const TitaniumRing: u8 = 7;
    const GoldRing: u8 = 8;
    const GhostWand: u8 = 9;
    const GraveWand: u8 = 10;
    const BoneWand: u8 = 11;
    const Wand: u8 = 12;
    const Grimoire: u8 = 13;
    const Chronicle: u8 = 14;
    const Tome: u8 = 15;
    const Book: u8 = 16;
    const DivineRobe: u8 = 17;
    const SilkRobe: u8 = 18;
    const LinenRobe: u8 = 19;
    const Robe: u8 = 20;
    const Shirt: u8 = 21;
    const Crown: u8 = 22;
    const DivineHood: u8 = 23;
    const SilkHood: u8 = 24;
    const LinenHood: u8 = 25;
    const Hood: u8 = 26;
    const BrightsilkSash: u8 = 27;
    const SilkSash: u8 = 28;
    const WoolSash: u8 = 29;
    const LinenSash: u8 = 30;
    const Sash: u8 = 31;
    const DivineSlippers: u8 = 32;
    const SilkSlippers: u8 = 33;
    const WoolShoes: u8 = 34;
    const LinenShoes: u8 = 35;
    const Shoes: u8 = 36;
    const DivineGloves: u8 = 37;
    const SilkGloves: u8 = 38;
    const WoolGloves: u8 = 39;
    const LinenGloves: u8 = 40;
    const Gloves: u8 = 41;
    const Katana: u8 = 42;
    const Falchion: u8 = 43;
    const Scimitar: u8 = 44;
    const LongSword: u8 = 45;
    const ShortSword: u8 = 46;
    const DemonHusk: u8 = 47;
    const DragonskinArmor: u8 = 48;
    const StuddedLeatherArmor: u8 = 49;
    const HardLeatherArmor: u8 = 50;
    const LeatherArmor: u8 = 51;
    const DemonCrown: u8 = 52;
    const DragonsCrown: u8 = 53;
    const WarCap: u8 = 54;
    const LeatherCap: u8 = 55;
    const Cap: u8 = 56;
    const DemonhideBelt: u8 = 57;
    const DragonskinBelt: u8 = 58;
    const StuddedLeatherBelt: u8 = 59;
    const HardLeatherBelt: u8 = 60;
    const LeatherBelt: u8 = 61;
    const DemonhideBoots: u8 = 62;
    const DragonskinBoots: u8 = 63;
    const StuddedLeatherBoots: u8 = 64;
    const HardLeatherBoots: u8 = 65;
    const LeatherBoots: u8 = 66;
    const DemonsHands: u8 = 67;
    const DragonskinGloves: u8 = 68;
    const StuddedLeatherGloves: u8 = 69;
    const HardLeatherGloves: u8 = 70;
    const LeatherGloves: u8 = 71;
    const Warhammer: u8 = 72;
    const Quarterstaff: u8 = 73;
    const Maul: u8 = 74;
    const Mace: u8 = 75;
    const Club: u8 = 76;
    const HolyChestplate: u8 = 77;
    const OrnateChestplate: u8 = 78;
    const PlateMail: u8 = 79;
    const ChainMail: u8 = 80;
    const RingMail: u8 = 81;
    const AncientHelm: u8 = 82;
    const OrnateHelm: u8 = 83;
    const GreatHelm: u8 = 84;
    const FullHelm: u8 = 85;
    const Helm: u8 = 86;
    const OrnateBelt: u8 = 87;
    const WarBelt: u8 = 88;
    const PlatedBelt: u8 = 89;
    const MeshBelt: u8 = 90;
    const HeavyBelt: u8 = 91;
    const HolyGreaves: u8 = 92;
    const OrnateGreaves: u8 = 93;
    const Greaves: u8 = 94;
    const ChainBoots: u8 = 95;
    const HeavyBoots: u8 = 96;
    const HolyGauntlets: u8 = 97;
    const OrnateGauntlets: u8 = 98;
    const Gauntlets: u8 = 99;
    const ChainGloves: u8 = 100;
    const HeavyGloves: u8 = 101;
}

// Item Slot Length
mod ItemSlotLength {
    const SlotItemsLengthWeapon: u8 = 18;
    const SlotItemsLengthChest: u8 = 15;
    const SlotItemsLengthHead: u8 = 15;
    const SlotItemsLengthWaist: u8 = 15;
    const SlotItemsLengthFoot: u8 = 15;
    const SlotItemsLengthHand: u8 = 15;
    const SlotItemsLengthNeck: u8 = 3;
    const SlotItemsLengthRing: u8 = 5;
}

mod ItemIndex {
    // Weapon
    const Warhammer: u8 = 0;
    const Quarterstaff: u8 = 1;
    const Maul: u8 = 2;
    const Mace: u8 = 3;
    const Club: u8 = 4;
    const Katana: u8 = 5;
    const Falchion: u8 = 6;
    const Scimitar: u8 = 7;
    const LongSword: u8 = 8;
    const ShortSword: u8 = 9;
    const GhostWand: u8 = 10;
    const GraveWand: u8 = 11;
    const BoneWand: u8 = 12;
    const Wand: u8 = 13;
    const Grimoire: u8 = 14;
    const Chronicle: u8 = 15;
    const Tome: u8 = 16;
    const Book: u8 = 17;

    // Chest
    const DivineRobe: u8 = 0;
    const SilkRobe: u8 = 1;
    const LinenRobe: u8 = 2;
    const Robe: u8 = 3;
    const Shirt: u8 = 4;
    const DemonHusk: u8 = 5;
    const DragonskinArmor: u8 = 6;
    const StuddedLeatherArmor: u8 = 7;
    const HardLeatherArmor: u8 = 8;
    const LeatherArmor: u8 = 9;
    const HolyChestplate: u8 = 10;
    const OrnateChestplate: u8 = 11;
    const PlateMail: u8 = 12;
    const ChainMail: u8 = 13;
    const RingMail: u8 = 14;

    // Head
    const AncientHelm: u8 = 0;
    const OrnateHelm: u8 = 1;
    const GreatHelm: u8 = 2;
    const FullHelm: u8 = 3;
    const Helm: u8 = 4;
    const DemonCrown: u8 = 5;
    const DragonsCrown: u8 = 6;
    const WarCap: u8 = 7;
    const LeatherCap: u8 = 8;
    const Cap: u8 = 9;
    const Crown: u8 = 10;
    const DivineHood: u8 = 11;
    const SilkHood: u8 = 12;
    const LinenHood: u8 = 13;
    const Hood: u8 = 14;

    // Waist
    const OrnateBelt: u8 = 0;
    const WarBelt: u8 = 1;
    const PlatedBelt: u8 = 2;
    const MeshBelt: u8 = 3;
    const HeavyBelt: u8 = 4;
    const DemonhideBelt: u8 = 5;
    const DragonskinBelt: u8 = 6;
    const StuddedLeatherBelt: u8 = 7;
    const HardLeatherBelt: u8 = 8;
    const LeatherBelt: u8 = 9;
    const BrightsilkSash: u8 = 10;
    const SilkSash: u8 = 11;
    const WoolSash: u8 = 12;
    const LinenSash: u8 = 13;
    const Sash: u8 = 14;

    // Foot
    const HolyGreaves: u8 = 0;
    const OrnateGreaves: u8 = 1;
    const Greaves: u8 = 2;
    const ChainBoots: u8 = 3;
    const HeavyBoots: u8 = 4;
    const DemonhideBoots: u8 = 5;
    const DragonskinBoots: u8 = 6;
    const StuddedLeatherBoots: u8 = 7;
    const HardLeatherBoots: u8 = 8;
    const LeatherBoots: u8 = 9;
    const DivineSlippers: u8 = 10;
    const SilkSlippers: u8 = 11;
    const WoolShoes: u8 = 12;
    const LinenShoes: u8 = 13;
    const Shoes: u8 = 14;

    // Hand
    const HolyGauntlets: u8 = 0;
    const OrnateGauntlets: u8 = 1;
    const Gauntlets: u8 = 2;
    const ChainGloves: u8 = 3;
    const HeavyGloves: u8 = 4;
    const DemonsHands: u8 = 5;
    const DragonskinGloves: u8 = 6;
    const StuddedLeatherGloves: u8 = 7;
    const HardLeatherGloves: u8 = 8;
    const LeatherGloves: u8 = 9;
    const DivineGloves: u8 = 10;
    const SilkGloves: u8 = 11;
    const WoolGloves: u8 = 12;
    const LinenGloves: u8 = 13;
    const Gloves: u8 = 14;

    // Necklaces
    const Necklace: u8 = 0;
    const Amulet: u8 = 1;
    const Pendant: u8 = 2;

    // Rings
    const GoldRing: u8 = 0;
    const SilverRing: u8 = 1;
    const BronzeRing: u8 = 2;
    const PlatinumRing: u8 = 3;
    const TitaniumRing: u8 = 4;
}

mod ItemNamePrefix {
    const Agony: u8 = 1;
    const Apocalypse: u8 = 2;
    const Armageddon: u8 = 3;
    const Beast: u8 = 4;
    const Behemoth: u8 = 5;
    const Blight: u8 = 6;
    const Blood: u8 = 7;
    const Bramble: u8 = 8;
    const Brimstone: u8 = 9;
    const Brood: u8 = 10;
    const Carrion: u8 = 11;
    const Cataclysm: u8 = 12;
    const Chimeric: u8 = 13;
    const Corpse: u8 = 14;
    const Corruption: u8 = 15;
    const Damnation: u8 = 16;
    const Death: u8 = 17;
    const Demon: u8 = 18;
    const Dire: u8 = 19;
    const Dragon: u8 = 20;
    const Dread: u8 = 21;
    const Doom: u8 = 22;
    const Dusk: u8 = 23;
    const Eagle: u8 = 24;
    const Empyrean: u8 = 25;
    const Fate: u8 = 26;
    const Foe: u8 = 27;
    const Gale: u8 = 28;
    const Ghoul: u8 = 29;
    const Gloom: u8 = 30;
    const Glyph: u8 = 31;
    const Golem: u8 = 32;
    const Grim: u8 = 33;
    const Hate: u8 = 34;
    const Havoc: u8 = 35;
    const Honour: u8 = 36;
    const Horror: u8 = 37;
    const Hypnotic: u8 = 38;
    const Kraken: u8 = 39;
    const Loath: u8 = 40;
    const Maelstrom: u8 = 41;
    const Mind: u8 = 42;
    const Miracle: u8 = 43;
    const Morbid: u8 = 44;
    const Oblivion: u8 = 45;
    const Onslaught: u8 = 46;
    const Pain: u8 = 47;
    const Pandemonium: u8 = 48;
    const Phoenix: u8 = 49;
    const Plague: u8 = 50;
    const Rage: u8 = 51;
    const Rapture: u8 = 52;
    const Rune: u8 = 53;
    const Skull: u8 = 54;
    const Sol: u8 = 55;
    const Soul: u8 = 56;
    const Sorrow: u8 = 57;
    const Spirit: u8 = 58;
    const Storm: u8 = 59;
    const Tempest: u8 = 60;
    const Torment: u8 = 61;
    const Vengeance: u8 = 62;
    const Victory: u8 = 63;
    const Viper: u8 = 64;
    const Vortex: u8 = 65;
    const Woe: u8 = 66;
    const Wrath: u8 = 67;
    const Lights: u8 = 68;
    const Shimmering: u8 = 69;
}

mod ItemNameSuffix {
    const Bane: u8 = 1;
    const Root: u8 = 2;
    const Bite: u8 = 3;
    const Song: u8 = 4;
    const Roar: u8 = 5;
    const Grasp: u8 = 6;
    const Instrument: u8 = 7;
    const Glow: u8 = 8;
    const Bender: u8 = 9;
    const Shadow: u8 = 10;
    const Whisper: u8 = 11;
    const Shout: u8 = 12;
    const Growl: u8 = 13;
    const Tear: u8 = 14;
    const Peak: u8 = 15;
    const Form: u8 = 16;
    const Sun: u8 = 17;
    const Moon: u8 = 18;
}

mod ItemSuffix {
    const of_Power: u8 = 1;
    const of_Giant: u8 = 2;
    const of_Titans: u8 = 3;
    const of_Skill: u8 = 4;
    const of_Perfection: u8 = 5;
    const of_Brilliance: u8 = 6;
    const of_Enlightenment: u8 = 7;
    const of_Protection: u8 = 8;
    const of_Anger: u8 = 9;
    const of_Rage: u8 = 10;
    const of_Fury: u8 = 11;
    const of_Vitriol: u8 = 12;
    const of_the_Fox: u8 = 13;
    const of_Detection: u8 = 14;
    const of_Reflection: u8 = 15;
    const of_the_Twins: u8 = 16;
}

// suffix and prefix
const NamePrefixLength: u8 = 69; // requires 7 bits
const NameSuffixLength: u8 = 18; // requires 5 bits
const ItemSuffixLength: u8 = 16; // requires 4 bits

const NUM_ITEMS: u8 = 101;
const NUM_ITEMS_NZ: NonZero<u64> = 101;
const NUM_ITEMS_NZ_MINUS_ONE: NonZero<u64> = 100;
const SUFFIX_UNLOCK_GREATNESS: u8 = 15;
const PREFIXES_UNLOCK_GREATNESS: u8 = 19;


#[generate_trait]
impl ImplItemNaming of ItemNamingTrait {
    fn item_id_to_string(item: u8) -> felt252 {
        if (item == ItemId::Pendant) {
            ItemString::Pendant
        } else if (item == ItemId::Necklace) {
            ItemString::Necklace
        } else if (item == ItemId::Amulet) {
            ItemString::Amulet
        } else if (item == ItemId::SilverRing) {
            ItemString::SilverRing
        } else if (item == ItemId::BronzeRing) {
            ItemString::BronzeRing
        } else if (item == ItemId::PlatinumRing) {
            ItemString::PlatinumRing
        } else if (item == ItemId::TitaniumRing) {
            ItemString::TitaniumRing
        } else if (item == ItemId::GoldRing) {
            ItemString::GoldRing
        } else if (item == ItemId::GhostWand) {
            ItemString::GhostWand
        } else if (item == ItemId::GraveWand) {
            ItemString::GraveWand
        } else if (item == ItemId::BoneWand) {
            ItemString::BoneWand
        } else if (item == ItemId::Wand) {
            ItemString::Wand
        } else if (item == ItemId::Grimoire) {
            ItemString::Grimoire
        } else if (item == ItemId::Chronicle) {
            ItemString::Chronicle
        } else if (item == ItemId::Tome) {
            ItemString::Tome
        } else if (item == ItemId::Book) {
            ItemString::Book
        } else if (item == ItemId::DivineRobe) {
            ItemString::DivineRobe
        } else if (item == ItemId::SilkRobe) {
            ItemString::SilkRobe
        } else if (item == ItemId::LinenRobe) {
            ItemString::LinenRobe
        } else if (item == ItemId::Robe) {
            ItemString::Robe
        } else if (item == ItemId::Shirt) {
            ItemString::Shirt
        } else if (item == ItemId::Crown) {
            ItemString::Crown
        } else if (item == ItemId::DivineHood) {
            ItemString::DivineHood
        } else if (item == ItemId::SilkHood) {
            ItemString::SilkHood
        } else if (item == ItemId::LinenHood) {
            ItemString::LinenHood
        } else if (item == ItemId::Hood) {
            ItemString::Hood
        } else if (item == ItemId::BrightsilkSash) {
            ItemString::BrightsilkSash
        } else if (item == ItemId::SilkSash) {
            ItemString::SilkSash
        } else if (item == ItemId::WoolSash) {
            ItemString::WoolSash
        } else if (item == ItemId::LinenSash) {
            ItemString::LinenSash
        } else if (item == ItemId::Sash) {
            ItemString::Sash
        } else if (item == ItemId::DivineSlippers) {
            ItemString::DivineSlippers
        } else if (item == ItemId::SilkSlippers) {
            ItemString::SilkSlippers
        } else if (item == ItemId::WoolShoes) {
            ItemString::WoolShoes
        } else if (item == ItemId::LinenShoes) {
            ItemString::LinenShoes
        } else if (item == ItemId::Shoes) {
            ItemString::Shoes
        } else if (item == ItemId::DivineGloves) {
            ItemString::DivineGloves
        } else if (item == ItemId::SilkGloves) {
            ItemString::SilkGloves
        } else if (item == ItemId::WoolGloves) {
            ItemString::WoolGloves
        } else if (item == ItemId::LinenGloves) {
            ItemString::LinenGloves
        } else if (item == ItemId::Gloves) {
            ItemString::Gloves
        } else if (item == ItemId::Katana) {
            ItemString::Katana
        } else if (item == ItemId::Falchion) {
            ItemString::Falchion
        } else if (item == ItemId::Scimitar) {
            ItemString::Scimitar
        } else if (item == ItemId::LongSword) {
            ItemString::LongSword
        } else if (item == ItemId::ShortSword) {
            ItemString::ShortSword
        } else if (item == ItemId::DemonHusk) {
            ItemString::DemonHusk
        } else if (item == ItemId::DragonskinArmor) {
            ItemString::DragonskinArmor
        } else if (item == ItemId::StuddedLeatherArmor) {
            ItemString::StuddedLeatherArmor
        } else if (item == ItemId::HardLeatherArmor) {
            ItemString::HardLeatherArmor
        } else if (item == ItemId::LeatherArmor) {
            ItemString::LeatherArmor
        } else if (item == ItemId::DemonCrown) {
            ItemString::DemonCrown
        } else if (item == ItemId::DragonsCrown) {
            ItemString::DragonsCrown
        } else if (item == ItemId::WarCap) {
            ItemString::WarCap
        } else if (item == ItemId::LeatherCap) {
            ItemString::LeatherCap
        } else if (item == ItemId::Cap) {
            ItemString::Cap
        } else if (item == ItemId::DemonhideBelt) {
            ItemString::DemonhideBelt
        } else if (item == ItemId::DragonskinBelt) {
            ItemString::DragonskinBelt
        } else if (item == ItemId::StuddedLeatherBelt) {
            ItemString::StuddedLeatherBelt
        } else if (item == ItemId::HardLeatherBelt) {
            ItemString::HardLeatherBelt
        } else if (item == ItemId::LeatherBelt) {
            ItemString::LeatherBelt
        } else if (item == ItemId::DemonhideBoots) {
            ItemString::DemonhideBoots
        } else if (item == ItemId::DragonskinBoots) {
            ItemString::DragonskinBoots
        } else if (item == ItemId::StuddedLeatherBoots) {
            ItemString::StuddedLeatherBoots
        } else if (item == ItemId::HardLeatherBoots) {
            ItemString::HardLeatherBoots
        } else if (item == ItemId::LeatherBoots) {
            ItemString::LeatherBoots
        } else if (item == ItemId::DemonsHands) {
            ItemString::DemonsHands
        } else if (item == ItemId::DragonskinGloves) {
            ItemString::DragonskinGloves
        } else if (item == ItemId::StuddedLeatherGloves) {
            ItemString::StuddedLeatherGloves
        } else if (item == ItemId::HardLeatherGloves) {
            ItemString::HardLeatherGloves
        } else if (item == ItemId::LeatherGloves) {
            ItemString::LeatherGloves
        } else if (item == ItemId::Warhammer) {
            ItemString::Warhammer
        } else if (item == ItemId::Quarterstaff) {
            ItemString::Quarterstaff
        } else if (item == ItemId::Maul) {
            ItemString::Maul
        } else if (item == ItemId::Mace) {
            ItemString::Mace
        } else if (item == ItemId::Club) {
            ItemString::Club
        } else if (item == ItemId::HolyChestplate) {
            ItemString::HolyChestplate
        } else if (item == ItemId::OrnateChestplate) {
            ItemString::OrnateChestplate
        } else if (item == ItemId::PlateMail) {
            ItemString::PlateMail
        } else if (item == ItemId::ChainMail) {
            ItemString::ChainMail
        } else if (item == ItemId::RingMail) {
            ItemString::RingMail
        } else if (item == ItemId::AncientHelm) {
            ItemString::AncientHelm
        } else if (item == ItemId::OrnateHelm) {
            ItemString::OrnateHelm
        } else if (item == ItemId::GreatHelm) {
            ItemString::GreatHelm
        } else if (item == ItemId::FullHelm) {
            ItemString::FullHelm
        } else if (item == ItemId::Helm) {
            ItemString::Helm
        } else if (item == ItemId::OrnateBelt) {
            ItemString::OrnateBelt
        } else if (item == ItemId::WarBelt) {
            ItemString::WarBelt
        } else if (item == ItemId::PlatedBelt) {
            ItemString::PlatedBelt
        } else if (item == ItemId::MeshBelt) {
            ItemString::MeshBelt
        } else if (item == ItemId::HeavyBelt) {
            ItemString::HeavyBelt
        } else if (item == ItemId::HolyGreaves) {
            ItemString::HolyGreaves
        } else if (item == ItemId::OrnateGreaves) {
            ItemString::OrnateGreaves
        } else if (item == ItemId::Greaves) {
            ItemString::Greaves
        } else if (item == ItemId::ChainBoots) {
            ItemString::ChainBoots
        } else if (item == ItemId::HeavyBoots) {
            ItemString::HeavyBoots
        } else if (item == ItemId::HolyGauntlets) {
            ItemString::HolyGauntlets
        } else if (item == ItemId::OrnateGauntlets) {
            ItemString::OrnateGauntlets
        } else if (item == ItemId::Gauntlets) {
            ItemString::Gauntlets
        } else if (item == ItemId::ChainGloves) {
            ItemString::ChainGloves
        } else if (item == ItemId::HeavyGloves) {
            ItemString::HeavyGloves
        } else {
            ''
        }
    }

    fn prefix1_to_string(name_prefix: u8) -> felt252 {
        if (name_prefix == ItemNamePrefix::Agony) {
            ItemNamePrefixString::Agony
        } else if (name_prefix == ItemNamePrefix::Apocalypse) {
            ItemNamePrefixString::Apocalypse
        } else if (name_prefix == ItemNamePrefix::Armageddon) {
            ItemNamePrefixString::Armageddon
        } else if (name_prefix == ItemNamePrefix::Beast) {
            ItemNamePrefixString::Beast
        } else if (name_prefix == ItemNamePrefix::Behemoth) {
            ItemNamePrefixString::Behemoth
        } else if (name_prefix == ItemNamePrefix::Blight) {
            ItemNamePrefixString::Blight
        } else if (name_prefix == ItemNamePrefix::Blood) {
            ItemNamePrefixString::Blood
        } else if (name_prefix == ItemNamePrefix::Bramble) {
            ItemNamePrefixString::Bramble
        } else if (name_prefix == ItemNamePrefix::Brimstone) {
            ItemNamePrefixString::Brimstone
        } else if (name_prefix == ItemNamePrefix::Brood) {
            ItemNamePrefixString::Brood
        } else if (name_prefix == ItemNamePrefix::Carrion) {
            ItemNamePrefixString::Carrion
        } else if (name_prefix == ItemNamePrefix::Cataclysm) {
            ItemNamePrefixString::Cataclysm
        } else if (name_prefix == ItemNamePrefix::Chimeric) {
            ItemNamePrefixString::Chimeric
        } else if (name_prefix == ItemNamePrefix::Corpse) {
            ItemNamePrefixString::Corpse
        } else if (name_prefix == ItemNamePrefix::Corruption) {
            ItemNamePrefixString::Corruption
        } else if (name_prefix == ItemNamePrefix::Damnation) {
            ItemNamePrefixString::Damnation
        } else if (name_prefix == ItemNamePrefix::Death) {
            ItemNamePrefixString::Death
        } else if (name_prefix == ItemNamePrefix::Demon) {
            ItemNamePrefixString::Demon
        } else if (name_prefix == ItemNamePrefix::Dire) {
            ItemNamePrefixString::Dire
        } else if (name_prefix == ItemNamePrefix::Dragon) {
            ItemNamePrefixString::Dragon
        } else if (name_prefix == ItemNamePrefix::Dread) {
            ItemNamePrefixString::Dread
        } else if (name_prefix == ItemNamePrefix::Doom) {
            ItemNamePrefixString::Doom
        } else if (name_prefix == ItemNamePrefix::Dusk) {
            ItemNamePrefixString::Dusk
        } else if (name_prefix == ItemNamePrefix::Eagle) {
            ItemNamePrefixString::Eagle
        } else if (name_prefix == ItemNamePrefix::Empyrean) {
            ItemNamePrefixString::Empyrean
        } else if (name_prefix == ItemNamePrefix::Fate) {
            ItemNamePrefixString::Fate
        } else if (name_prefix == ItemNamePrefix::Foe) {
            ItemNamePrefixString::Foe
        } else if (name_prefix == ItemNamePrefix::Gale) {
            ItemNamePrefixString::Gale
        } else if (name_prefix == ItemNamePrefix::Ghoul) {
            ItemNamePrefixString::Ghoul
        } else if (name_prefix == ItemNamePrefix::Gloom) {
            ItemNamePrefixString::Gloom
        } else if (name_prefix == ItemNamePrefix::Glyph) {
            ItemNamePrefixString::Glyph
        } else if (name_prefix == ItemNamePrefix::Golem) {
            ItemNamePrefixString::Golem
        } else if (name_prefix == ItemNamePrefix::Grim) {
            ItemNamePrefixString::Grim
        } else if (name_prefix == ItemNamePrefix::Hate) {
            ItemNamePrefixString::Hate
        } else if (name_prefix == ItemNamePrefix::Havoc) {
            ItemNamePrefixString::Havoc
        } else if (name_prefix == ItemNamePrefix::Honour) {
            ItemNamePrefixString::Honour
        } else if (name_prefix == ItemNamePrefix::Horror) {
            ItemNamePrefixString::Horror
        } else if (name_prefix == ItemNamePrefix::Hypnotic) {
            ItemNamePrefixString::Hypnotic
        } else if (name_prefix == ItemNamePrefix::Kraken) {
            ItemNamePrefixString::Kraken
        } else if (name_prefix == ItemNamePrefix::Loath) {
            ItemNamePrefixString::Loath
        } else if (name_prefix == ItemNamePrefix::Maelstrom) {
            ItemNamePrefixString::Maelstrom
        } else if (name_prefix == ItemNamePrefix::Mind) {
            ItemNamePrefixString::Mind
        } else if (name_prefix == ItemNamePrefix::Miracle) {
            ItemNamePrefixString::Miracle
        } else if (name_prefix == ItemNamePrefix::Morbid) {
            ItemNamePrefixString::Morbid
        } else if (name_prefix == ItemNamePrefix::Oblivion) {
            ItemNamePrefixString::Oblivion
        } else if (name_prefix == ItemNamePrefix::Onslaught) {
            ItemNamePrefixString::Onslaught
        } else if (name_prefix == ItemNamePrefix::Pain) {
            ItemNamePrefixString::Pain
        } else if (name_prefix == ItemNamePrefix::Pandemonium) {
            ItemNamePrefixString::Pandemonium
        } else if (name_prefix == ItemNamePrefix::Phoenix) {
            ItemNamePrefixString::Phoenix
        } else if (name_prefix == ItemNamePrefix::Plague) {
            ItemNamePrefixString::Plague
        } else if (name_prefix == ItemNamePrefix::Rage) {
            ItemNamePrefixString::Rage
        } else if (name_prefix == ItemNamePrefix::Rapture) {
            ItemNamePrefixString::Rapture
        } else if (name_prefix == ItemNamePrefix::Rune) {
            ItemNamePrefixString::Rune
        } else if (name_prefix == ItemNamePrefix::Skull) {
            ItemNamePrefixString::Skull
        } else if (name_prefix == ItemNamePrefix::Sol) {
            ItemNamePrefixString::Sol
        } else if (name_prefix == ItemNamePrefix::Soul) {
            ItemNamePrefixString::Soul
        } else if (name_prefix == ItemNamePrefix::Sorrow) {
            ItemNamePrefixString::Sorrow
        } else if (name_prefix == ItemNamePrefix::Spirit) {
            ItemNamePrefixString::Spirit
        } else if (name_prefix == ItemNamePrefix::Storm) {
            ItemNamePrefixString::Storm
        } else if (name_prefix == ItemNamePrefix::Tempest) {
            ItemNamePrefixString::Tempest
        } else if (name_prefix == ItemNamePrefix::Torment) {
            ItemNamePrefixString::Torment
        } else if (name_prefix == ItemNamePrefix::Vengeance) {
            ItemNamePrefixString::Vengeance
        } else if (name_prefix == ItemNamePrefix::Victory) {
            ItemNamePrefixString::Victory
        } else if (name_prefix == ItemNamePrefix::Viper) {
            ItemNamePrefixString::Viper
        } else if (name_prefix == ItemNamePrefix::Vortex) {
            ItemNamePrefixString::Vortex
        } else if (name_prefix == ItemNamePrefix::Woe) {
            ItemNamePrefixString::Woe
        } else if (name_prefix == ItemNamePrefix::Wrath) {
            ItemNamePrefixString::Wrath
        } else if (name_prefix == ItemNamePrefix::Lights) {
            ItemNamePrefixString::Lights
        } else if (name_prefix == ItemNamePrefix::Shimmering) {
            ItemNamePrefixString::Shimmering
        } else {
            ''
        }
    }
    fn prefix2_to_string(name_suffix: u8) -> felt252 {
        if (name_suffix == ItemNameSuffix::Bane) {
            ItemNameSuffixString::Bane
        } else if (name_suffix == ItemNameSuffix::Root) {
            ItemNameSuffixString::Root
        } else if (name_suffix == ItemNameSuffix::Bite) {
            ItemNameSuffixString::Bite
        } else if (name_suffix == ItemNameSuffix::Song) {
            ItemNameSuffixString::Song
        } else if (name_suffix == ItemNameSuffix::Roar) {
            ItemNameSuffixString::Roar
        } else if (name_suffix == ItemNameSuffix::Grasp) {
            ItemNameSuffixString::Grasp
        } else if (name_suffix == ItemNameSuffix::Instrument) {
            ItemNameSuffixString::Instrument
        } else if (name_suffix == ItemNameSuffix::Glow) {
            ItemNameSuffixString::Glow
        } else if (name_suffix == ItemNameSuffix::Bender) {
            ItemNameSuffixString::Bender
        } else if (name_suffix == ItemNameSuffix::Shadow) {
            ItemNameSuffixString::Shadow
        } else if (name_suffix == ItemNameSuffix::Whisper) {
            ItemNameSuffixString::Whisper
        } else if (name_suffix == ItemNameSuffix::Shout) {
            ItemNameSuffixString::Shout
        } else if (name_suffix == ItemNameSuffix::Growl) {
            ItemNameSuffixString::Growl
        } else if (name_suffix == ItemNameSuffix::Tear) {
            ItemNameSuffixString::Tear
        } else if (name_suffix == ItemNameSuffix::Peak) {
            ItemNameSuffixString::Peak
        } else if (name_suffix == ItemNameSuffix::Form) {
            ItemNameSuffixString::Form
        } else if (name_suffix == ItemNameSuffix::Sun) {
            ItemNameSuffixString::Sun
        } else if (name_suffix == ItemNameSuffix::Moon) {
            ItemNameSuffixString::Moon
        } else {
            ''
        }
    }
    fn suffix_to_string(suffix: u8) -> felt252 {
        if (suffix == ItemSuffix::of_Power) {
            ItemSuffixString::of_Power
        } else if (suffix == ItemSuffix::of_Giant) {
            ItemSuffixString::of_Giant
        } else if (suffix == ItemSuffix::of_Titans) {
            ItemSuffixString::of_Titans
        } else if (suffix == ItemSuffix::of_Skill) {
            ItemSuffixString::of_Skill
        } else if (suffix == ItemSuffix::of_Perfection) {
            ItemSuffixString::of_Perfection
        } else if (suffix == ItemSuffix::of_Brilliance) {
            ItemSuffixString::of_Brilliance
        } else if (suffix == ItemSuffix::of_Enlightenment) {
            ItemSuffixString::of_Enlightenment
        } else if (suffix == ItemSuffix::of_Protection) {
            ItemSuffixString::of_Protection
        } else if (suffix == ItemSuffix::of_Anger) {
            ItemSuffixString::of_Anger
        } else if (suffix == ItemSuffix::of_Rage) {
            ItemSuffixString::of_Rage
        } else if (suffix == ItemSuffix::of_Fury) {
            ItemSuffixString::of_Fury
        } else if (suffix == ItemSuffix::of_Vitriol) {
            ItemSuffixString::of_Vitriol
        } else if (suffix == ItemSuffix::of_the_Fox) {
            ItemSuffixString::of_the_Fox
        } else if (suffix == ItemSuffix::of_Detection) {
            ItemSuffixString::of_Detection
        } else if (suffix == ItemSuffix::of_Reflection) {
            ItemSuffixString::of_Reflection
        } else if (suffix == ItemSuffix::of_the_Twins) {
            ItemSuffixString::of_the_Twins
        } else {
            ''
        }
    }
}

mod ItemString {
    const Pendant: felt252 = 'Pendant';
    const Necklace: felt252 = 'Necklace';
    const Amulet: felt252 = 'Amulet';
    const SilverRing: felt252 = 'Silver Ring';
    const BronzeRing: felt252 = 'Bronze Ring';
    const PlatinumRing: felt252 = 'Platinum Ring';
    const TitaniumRing: felt252 = 'Titanium Ring';
    const GoldRing: felt252 = 'Gold Ring';
    const GhostWand: felt252 = 'Ghost Wand';
    const GraveWand: felt252 = 'Grave Wand';
    const BoneWand: felt252 = 'Bone Wand';
    const Wand: felt252 = 'Wand';
    const Grimoire: felt252 = 'Grimoire';
    const Chronicle: felt252 = 'Chronicle';
    const Tome: felt252 = 'Tome';
    const Book: felt252 = 'Book';
    const DivineRobe: felt252 = 'Divine Robe';
    const SilkRobe: felt252 = 'Silk Robe';
    const LinenRobe: felt252 = 'Linen Robe';
    const Robe: felt252 = 'Robe';
    const Shirt: felt252 = 'Shirt';
    const Crown: felt252 = 'Crown';
    const DivineHood: felt252 = 'Divine Hood';
    const SilkHood: felt252 = 'Silk Hood';
    const LinenHood: felt252 = 'Linen Hood';
    const Hood: felt252 = 'Hood';
    const BrightsilkSash: felt252 = 'Brightsilk Sash';
    const SilkSash: felt252 = 'Silk Sash';
    const WoolSash: felt252 = 'Wool Sash';
    const LinenSash: felt252 = 'Linen Sash';
    const Sash: felt252 = 'Sash';
    const DivineSlippers: felt252 = 'Divine Slippers';
    const SilkSlippers: felt252 = 'Silk Slippers';
    const WoolShoes: felt252 = 'Wool Shoes';
    const LinenShoes: felt252 = 'Linen Shoes';
    const Shoes: felt252 = 'Shoes';
    const DivineGloves: felt252 = 'Divine Gloves';
    const SilkGloves: felt252 = 'Silk Gloves';
    const WoolGloves: felt252 = 'Wool Gloves';
    const LinenGloves: felt252 = 'Linen Gloves';
    const Gloves: felt252 = 'Gloves';
    const Katana: felt252 = 'Katana';
    const Falchion: felt252 = 'Falchion';
    const Scimitar: felt252 = 'Scimitar';
    const LongSword: felt252 = 'Long Sword';
    const ShortSword: felt252 = 'Short Sword';
    const DemonHusk: felt252 = 'Demon Husk';
    const DragonskinArmor: felt252 = 'Dragonskin Armor';
    const StuddedLeatherArmor: felt252 = 'Studded Leather Armor';
    const HardLeatherArmor: felt252 = 'Hard Leather Armor';
    const LeatherArmor: felt252 = 'Leather Armor';
    const DemonCrown: felt252 = 'Demon Crown';
    const DragonsCrown: felt252 = 'Dragon\'s Crown';
    const WarCap: felt252 = 'War Cap';
    const LeatherCap: felt252 = 'Leather Cap';
    const Cap: felt252 = 'Cap';
    const DemonhideBelt: felt252 = 'Demonhide Belt';
    const DragonskinBelt: felt252 = 'Dragonskin Belt';
    const StuddedLeatherBelt: felt252 = 'Studded Leather Belt';
    const HardLeatherBelt: felt252 = 'Hard Leather Belt';
    const LeatherBelt: felt252 = 'Leather Belt';
    const DemonhideBoots: felt252 = 'Demonhide Boots';
    const DragonskinBoots: felt252 = 'Dragonskin Boots';
    const StuddedLeatherBoots: felt252 = 'Studded Leather Boots';
    const HardLeatherBoots: felt252 = 'Hard Leather Boots';
    const LeatherBoots: felt252 = 'Leather Boots';
    const DemonsHands: felt252 = 'Demon\'s Hands';
    const DragonskinGloves: felt252 = 'Dragonskin Gloves';
    const StuddedLeatherGloves: felt252 = 'Studded Leather Gloves';
    const HardLeatherGloves: felt252 = 'Hard Leather Gloves';
    const LeatherGloves: felt252 = 'Leather Gloves';
    const Warhammer: felt252 = 'Warhammer';
    const Quarterstaff: felt252 = 'Quarterstaff';
    const Maul: felt252 = 'Maul';
    const Mace: felt252 = 'Mace';
    const Club: felt252 = 'Club';
    const HolyChestplate: felt252 = 'Holy Chestplate';
    const OrnateChestplate: felt252 = 'Ornate Chestplate';
    const PlateMail: felt252 = 'Plate Mail';
    const ChainMail: felt252 = 'Chain Mail';
    const RingMail: felt252 = 'Ring Mail';
    const AncientHelm: felt252 = 'Ancient Helm';
    const OrnateHelm: felt252 = 'Ornate Helm';
    const GreatHelm: felt252 = 'Great Helm';
    const FullHelm: felt252 = 'Full Helm';
    const Helm: felt252 = 'Helm';
    const OrnateBelt: felt252 = 'Ornate Belt';
    const WarBelt: felt252 = 'War Belt';
    const PlatedBelt: felt252 = 'Plated Belt';
    const MeshBelt: felt252 = 'Mesh Belt';
    const HeavyBelt: felt252 = 'Heavy Belt';
    const HolyGreaves: felt252 = 'Holy Greaves';
    const OrnateGreaves: felt252 = 'Ornate Greaves';
    const Greaves: felt252 = 'Greaves';
    const ChainBoots: felt252 = 'Chain Boots';
    const HeavyBoots: felt252 = 'Heavy Boots';
    const HolyGauntlets: felt252 = 'Holy Gauntlets';
    const OrnateGauntlets: felt252 = 'Ornate Gauntlets';
    const Gauntlets: felt252 = 'Gauntlets';
    const ChainGloves: felt252 = 'Chain Gloves';
    const HeavyGloves: felt252 = 'Heavy Gloves';
}

mod ItemSuffixString {
    const of_Power: felt252 = 'of Power';
    const of_Giant: felt252 = 'of Giant';
    const of_Titans: felt252 = 'of Titans';
    const of_Skill: felt252 = 'of Skill';
    const of_Perfection: felt252 = 'of Perfection';
    const of_Brilliance: felt252 = 'of Brilliance';
    const of_Enlightenment: felt252 = 'of Enlightenment';
    const of_Protection: felt252 = 'of Protection';
    const of_Anger: felt252 = 'of Anger';
    const of_Rage: felt252 = 'of Rage';
    const of_Fury: felt252 = 'of Fury';
    const of_Vitriol: felt252 = 'of Vitriol';
    const of_the_Fox: felt252 = 'of the Fox';
    const of_Detection: felt252 = 'of Detection';
    const of_Reflection: felt252 = 'of Reflection';
    const of_the_Twins: felt252 = 'of the Twins';
}

mod ItemNameSuffixString {
    const Bane: felt252 = 'Bane';
    const Root: felt252 = 'Root';
    const Bite: felt252 = 'Bite';
    const Song: felt252 = 'Song';
    const Roar: felt252 = 'Roar';
    const Grasp: felt252 = 'Grasp';
    const Instrument: felt252 = 'Instrument';
    const Glow: felt252 = 'Glow';
    const Bender: felt252 = 'Bender';
    const Shadow: felt252 = 'Shadow';
    const Whisper: felt252 = 'Whisper';
    const Shout: felt252 = 'Shout';
    const Growl: felt252 = 'Growl';
    const Tear: felt252 = 'Tear';
    const Peak: felt252 = 'Peak';
    const Form: felt252 = 'Form';
    const Sun: felt252 = 'Sun';
    const Moon: felt252 = 'Moon';
}

mod ItemNamePrefixString {
    const Agony: felt252 = 'Agony';
    const Apocalypse: felt252 = 'Apocalypse';
    const Armageddon: felt252 = 'Armageddon';
    const Beast: felt252 = 'Beast';
    const Behemoth: felt252 = 'Behemoth';
    const Blight: felt252 = 'Blight';
    const Blood: felt252 = 'Blood';
    const Bramble: felt252 = 'Bramble';
    const Brimstone: felt252 = 'Brimstone';
    const Brood: felt252 = 'Brood';
    const Carrion: felt252 = 'Carrion';
    const Cataclysm: felt252 = 'Cataclysm';
    const Chimeric: felt252 = 'Chimeric';
    const Corpse: felt252 = 'Corpse';
    const Corruption: felt252 = 'Corruption';
    const Damnation: felt252 = 'Damnation';
    const Death: felt252 = 'Death';
    const Demon: felt252 = 'Demon';
    const Dire: felt252 = 'Dire';
    const Dragon: felt252 = 'Dragon';
    const Dread: felt252 = 'Dread';
    const Doom: felt252 = 'Doom';
    const Dusk: felt252 = 'Dusk';
    const Eagle: felt252 = 'Eagle';
    const Empyrean: felt252 = 'Empyrean';
    const Fate: felt252 = 'Fate';
    const Foe: felt252 = 'Foe';
    const Gale: felt252 = 'Gale';
    const Ghoul: felt252 = 'Ghoul';
    const Gloom: felt252 = 'Gloom';
    const Glyph: felt252 = 'Glyph';
    const Golem: felt252 = 'Golem';
    const Grim: felt252 = 'Grim';
    const Hate: felt252 = 'Hate';
    const Havoc: felt252 = 'Havoc';
    const Honour: felt252 = 'Honour';
    const Horror: felt252 = 'Horror';
    const Hypnotic: felt252 = 'Hypnotic';
    const Kraken: felt252 = 'Kraken';
    const Loath: felt252 = 'Loath';
    const Maelstrom: felt252 = 'Maelstrom';
    const Mind: felt252 = 'Mind';
    const Miracle: felt252 = 'Miracle';
    const Morbid: felt252 = 'Morbid';
    const Oblivion: felt252 = 'Oblivion';
    const Onslaught: felt252 = 'Onslaught';
    const Pain: felt252 = 'Pain';
    const Pandemonium: felt252 = 'Pandemonium';
    const Phoenix: felt252 = 'Phoenix';
    const Plague: felt252 = 'Plague';
    const Rage: felt252 = 'Rage';
    const Rapture: felt252 = 'Rapture';
    const Rune: felt252 = 'Rune';
    const Skull: felt252 = 'Skull';
    const Sol: felt252 = 'Sol';
    const Soul: felt252 = 'Soul';
    const Sorrow: felt252 = 'Sorrow';
    const Spirit: felt252 = 'Spirit';
    const Storm: felt252 = 'Storm';
    const Tempest: felt252 = 'Tempest';
    const Torment: felt252 = 'Torment';
    const Vengeance: felt252 = 'Vengeance';
    const Victory: felt252 = 'Victory';
    const Viper: felt252 = 'Viper';
    const Vortex: felt252 = 'Vortex';
    const Woe: felt252 = 'Woe';
    const Wrath: felt252 = 'Wrath';
    const Lights: felt252 = 'Lights';
    const Shimmering: felt252 = 'Shimmering';
}
