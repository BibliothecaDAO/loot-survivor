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

// Slot
mod Slot {
    const Weapon: u8 = 1;
    const Chest: u8 = 2;
    const Head: u8 = 3;
    const Waist: u8 = 4;
    const Foot: u8 = 5;
    const Hand: u8 = 6;
    const Neck: u8 = 7;
    const Ring: u8 = 8;
}

// Item Slot lookups
// TODO: Make this use the Slot enum (Slot.Weapon)
// @loaf
mod ItemSlot {
    const Warhammer: u8 = 1;
    const Quarterstaff: u8 = 1;
    const Maul: u8 = 1;
    const Mace: u8 = 1;
    const Club: u8 = 1;
    const Katana: u8 = 1;
    const Falchion: u8 = 1;
    const Scimitar: u8 = 1;
    const LongSword: u8 = 1;
    const ShortSword: u8 = 1;
    const GhostWand: u8 = 1;
    const GraveWand: u8 = 1;
    const BoneWand: u8 = 1;
    const Wand: u8 = 1;
    const Grimoire: u8 = 1;
    const Chronicle: u8 = 1;
    const Tome: u8 = 1;
    const Book: u8 = 1;

    // Chest
    const DivineRobe: u8 = 2;
    const SilkRobe: u8 = 2;
    const LinenRobe: u8 = 2;
    const Robe: u8 = 2;
    const Shirt: u8 = 2;
    const DemonHusk: u8 = 2;
    const DragonskinArmor: u8 = 2;
    const StuddedLeatherArmor: u8 = 2;
    const HardLeatherArmor: u8 = 2;
    const LeatherArmor: u8 = 2;
    const HolyChestplate: u8 = 2;
    const OrnateChestplate: u8 = 2;
    const PlateMail: u8 = 2;
    const ChainMail: u8 = 2;
    const RingMail: u8 = 2;

    // Head
    const AncientHelm: u8 = 3;
    const OrnateHelm: u8 = 3;
    const GreatHelm: u8 = 3;
    const FullHelm: u8 = 3;
    const Helm: u8 = 3;
    const DemonCrown: u8 = 3;
    const DragonsCrown: u8 = 3;
    const WarCap: u8 = 3;
    const LeatherCap: u8 = 3;
    const Cap: u8 = 3;
    const Crown: u8 = 3;
    const DivineHood: u8 = 3;
    const SilkHood: u8 = 3;
    const LinenHood: u8 = 3;
    const Hood: u8 = 3;

    // Waist
    const OrnateBelt: u8 = 4;
    const WarBelt: u8 = 4;
    const PlatedBelt: u8 = 4;
    const MeshBelt: u8 = 4;
    const HeavyBelt: u8 = 4;
    const DemonhideBelt: u8 = 4;
    const DragonskinBelt: u8 = 4;
    const StuddedLeatherBelt: u8 = 4;
    const HardLeatherBelt: u8 = 4;
    const LeatherBelt: u8 = 4;
    const BrightsilkSash: u8 = 4;
    const SilkSash: u8 = 4;
    const WoolSash: u8 = 4;
    const LinenSash: u8 = 4;
    const Sash: u8 = 4;

    // Foot
    const HolyGreaves: u8 = 5;
    const OrnateGreaves: u8 = 5;
    const Greaves: u8 = 5;
    const ChainBoots: u8 = 5;
    const HeavyBoots: u8 = 5;
    const DemonhideBoots: u8 = 5;
    const DragonskinBoots: u8 = 5;
    const StuddedLeatherBoots: u8 = 5;
    const HardLeatherBoots: u8 = 5;
    const LeatherBoots: u8 = 5;
    const DivineSlippers: u8 = 5;
    const SilkSlippers: u8 = 5;
    const WoolShoes: u8 = 5;
    const LinenShoes: u8 = 5;
    const Shoes: u8 = 5;

    // Hand
    const HolyGauntlets: u8 = 6;
    const OrnateGauntlets: u8 = 6;
    const Gauntlets: u8 = 6;
    const ChainGloves: u8 = 6;
    const HeavyGloves: u8 = 6;
    const DemonsHands: u8 = 6;
    const DragonskinGloves: u8 = 6;
    const StuddedLeatherGloves: u8 = 6;
    const HardLeatherGloves: u8 = 6;
    const LeatherGloves: u8 = 6;
    const DivineGloves: u8 = 6;
    const SilkGloves: u8 = 6;
    const WoolGloves: u8 = 6;
    const LinenGloves: u8 = 6;
    const Gloves: u8 = 6;

    // Necklaces
    const Necklace: u8 = 7;
    const Amulet: u8 = 7;
    const Pendant: u8 = 7;

    // Rings
    const GoldRing: u8 = 8;
    const SilverRing: u8 = 8;
    const BronzeRing: u8 = 8;
    const PlatinumRing: u8 = 8;
    const TitaniumRing: u8 = 8;
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

// number space the types to provide room for future work
mod Type {
    mod Weapon {
        const Magic: u8 = 1;
        const Blade: u8 = 2;
        const Bludgeon: u8 = 3;
    }

    mod Armor {
        const Cloth: u8 = 1;
        const Hide: u8 = 2;
        const Metal: u8 = 3;
    }

    mod Jewlery {
        const Neck: u8 = 4;
        const Ring: u8 = 5;
    }
}

// Item Type
// TODO: @loaf use the above module instead of literals
// i.e we want Warhammer = Type.Weapon.Bludgeon
mod ItemType {
    // Weapons - Bludgeons 
    const Warhammer: u8 = 3;
    const Quarterstaff: u8 = 3;
    const Maul: u8 = 3;
    const Mace: u8 = 3;
    const Club: u8 = 3;

    // Weapons - Blades
    const Katana: u8 = 2;
    const Falchion: u8 = 2;
    const Scimitar: u8 = 2;
    const LongSword: u8 = 2;
    const ShortSword: u8 = 2;

    // Weapons - Magic Wands
    const GhostWand: u8 = 1;
    const GraveWand: u8 = 1;
    const BoneWand: u8 = 1;
    const Wand: u8 = 1;

    // Weapons - Magic Books
    const Grimoire: u8 = 1;
    const Chronicle: u8 = 1;
    const Tome: u8 = 1;
    const Book: u8 = 1;

    // Chest Armor - Cloth
    const DivineRobe: u8 = 1;
    const SilkRobe: u8 = 1;
    const LinenRobe: u8 = 1;
    const Robe: u8 = 1;
    const Shirt: u8 = 1;

    // Chest Armor - Hide
    const DemonHusk: u8 = 2;
    const DragonskinArmor: u8 = 2;
    const StuddedLeatherArmor: u8 = 2;
    const HardLeatherArmor: u8 = 2;
    const LeatherArmor: u8 = 2;

    // Chest Armor - Metal
    const HolyChestplate: u8 = 3;
    const OrnateChestplate: u8 = 3;
    const PlateMail: u8 = 3;
    const ChainMail: u8 = 3;
    const RingMail: u8 = 3;

    // Head Armor - Metal
    const AncientHelm: u8 = 3;
    const OrnateHelm: u8 = 3;
    const GreatHelm: u8 = 3;
    const FullHelm: u8 = 3;
    const Helm: u8 = 3;

    // Head Armor - Hide
    const DemonCrown: u8 = 2;
    const DragonsCrown: u8 = 2;
    const WarCap: u8 = 2;
    const LeatherCap: u8 = 2;
    const Cap: u8 = 2;

    // Head Armor - Cloth
    const Crown: u8 = 1;
    const DivineHood: u8 = 1;
    const SilkHood: u8 = 1;
    const LinenHood: u8 = 1;
    const Hood: u8 = 1;

    // Waist Armor - Metal
    const OrnateBelt: u8 = 3;
    const WarBelt: u8 = 3;
    const PlatedBelt: u8 = 3;
    const MeshBelt: u8 = 3;
    const HeavyBelt: u8 = 3;

    // Waist Armor - Hide
    const DemonhideBelt: u8 = 2;
    const DragonskinBelt: u8 = 2;
    const StuddedLeatherBelt: u8 = 2;
    const HardLeatherBelt: u8 = 2;
    const LeatherBelt: u8 = 2;

    // Wait Armor - Cloth
    const BrightsilkSash: u8 = 1;
    const SilkSash: u8 = 1;
    const WoolSash: u8 = 1;
    const LinenSash: u8 = 1;
    const Sash: u8 = 1;

    // Foot Armor - Metal
    const HolyGreaves: u8 = 3;
    const OrnateGreaves: u8 = 3;
    const Greaves: u8 = 3;
    const ChainBoots: u8 = 3;
    const HeavyBoots: u8 = 3;

    // Foot Armor - Hide
    const DemonhideBoots: u8 = 2;
    const DragonskinBoots: u8 = 2;
    const StuddedLeatherBoots: u8 = 2;
    const HardLeatherBoots: u8 = 2;
    const LeatherBoots: u8 = 2;

    // Foot Armor - Cloth
    const DivineSlippers: u8 = 1;
    const SilkSlippers: u8 = 1;
    const WoolShoes: u8 = 1;
    const LinenShoes: u8 = 1;
    const Shoes: u8 = 1;

    // Hand Armor - Metal
    const HolyGauntlets: u8 = 3;
    const OrnateGauntlets: u8 = 3;
    const Gauntlets: u8 = 3;
    const ChainGloves: u8 = 3;
    const HeavyGloves: u8 = 3;

    // Hand Armor - Hide
    const DemonsHands: u8 = 2;
    const DragonskinGloves: u8 = 2;
    const StuddedLeatherGloves: u8 = 2;
    const HardLeatherGloves: u8 = 2;
    const LeatherGloves: u8 = 2;

    // Hand Armor - Cloth
    const DivineGloves: u8 = 1;
    const SilkGloves: u8 = 1;
    const WoolGloves: u8 = 1;
    const LinenGloves: u8 = 1;
    const Gloves: u8 = 1;

    // Necklaces
    const Necklace: u8 = 4;
    const Amulet: u8 = 4;
    const Pendant: u8 = 4;

    // Rings
    const GoldRing: u8 = 5;
    const SilverRing: u8 = 5;
    const BronzeRing: u8 = 5;
    const PlatinumRing: u8 = 5;
    const TitaniumRing: u8 = 5;
}

mod ItemTier {
    const Pendant: u8 = 1;
    const Necklace: u8 = 1;
    const Amulet: u8 = 1;
    const SilverRing: u8 = 2;
    const BronzeRing: u8 = 3;
    const PlatinumRing: u8 = 1;
    const TitaniumRing: u8 = 1;
    const GoldRing: u8 = 1;
    const GhostWand: u8 = 2;
    const GraveWand: u8 = 3;
    const BoneWand: u8 = 4;
    const Wand: u8 = 5;
    const Grimoire: u8 = 2;
    const Chronicle: u8 = 3;
    const Tome: u8 = 4;
    const Book: u8 = 5;
    const DivineRobe: u8 = 1;
    const SilkRobe: u8 = 2;
    const LinenRobe: u8 = 3;
    const Robe: u8 = 4;
    const Shirt: u8 = 5;
    const Crown: u8 = 1;
    const DivineHood: u8 = 2;
    const SilkHood: u8 = 3;
    const LinenHood: u8 = 4;
    const Hood: u8 = 5;
    const BrightsilkSash: u8 = 1;
    const SilkSash: u8 = 2;
    const WoolSash: u8 = 3;
    const LinenSash: u8 = 4;
    const Sash: u8 = 5;
    const DivineSlippers: u8 = 1;
    const SilkSlippers: u8 = 2;
    const WoolShoes: u8 = 3;
    const LinenShoes: u8 = 4;
    const Shoes: u8 = 5;
    const DivineGloves: u8 = 1;
    const SilkGloves: u8 = 2;
    const WoolGloves: u8 = 3;
    const LinenGloves: u8 = 4;
    const Gloves: u8 = 5;
    const Katana: u8 = 1;
    const Falchion: u8 = 2;
    const Scimitar: u8 = 3;
    const LongSword: u8 = 4;
    const ShortSword: u8 = 5;
    const DemonHusk: u8 = 1;
    const DragonskinArmor: u8 = 2;
    const StuddedLeatherArmor: u8 = 3;
    const HardLeatherArmor: u8 = 4;
    const LeatherArmor: u8 = 5;
    const DemonCrown: u8 = 1;
    const DragonsCrown: u8 = 2;
    const WarCap: u8 = 3;
    const LeatherCap: u8 = 4;
    const Cap: u8 = 5;
    const DemonhideBelt: u8 = 1;
    const DragonskinBelt: u8 = 2;
    const StuddedLeatherBelt: u8 = 3;
    const HardLeatherBelt: u8 = 4;
    const LeatherBelt: u8 = 5;
    const DemonhideBoots: u8 = 1;
    const DragonskinBoots: u8 = 2;
    const StuddedLeatherBoots: u8 = 3;
    const HardLeatherBoots: u8 = 4;
    const LeatherBoots: u8 = 5;
    const DemonsHands: u8 = 1;
    const DragonskinGloves: u8 = 2;
    const StuddedLeatherGloves: u8 = 3;
    const HardLeatherGloves: u8 = 4;
    const LeatherGloves: u8 = 5;
    const Warhammer: u8 = 1;
    const Quarterstaff: u8 = 2;
    const Maul: u8 = 3;
    const Mace: u8 = 4;
    const Club: u8 = 5;
    const HolyChestplate: u8 = 1;
    const OrnateChestplate: u8 = 2;
    const PlateMail: u8 = 3;
    const ChainMail: u8 = 4;
    const RingMail: u8 = 5;
    const AncientHelm: u8 = 1;
    const OrnateHelm: u8 = 2;
    const GreatHelm: u8 = 3;
    const FullHelm: u8 = 4;
    const Helm: u8 = 5;
    const OrnateBelt: u8 = 1;
    const WarBelt: u8 = 2;
    const PlatedBelt: u8 = 3;
    const MeshBelt: u8 = 4;
    const HeavyBelt: u8 = 5;
    const HolyGreaves: u8 = 1;
    const OrnateGreaves: u8 = 2;
    const Greaves: u8 = 3;
    const ChainBoots: u8 = 4;
    const HeavyBoots: u8 = 5;
    const HolyGauntlets: u8 = 1;
    const OrnateGauntlets: u8 = 2;
    const Gauntlets: u8 = 3;
    const ChainGloves: u8 = 4;
    const HeavyGloves: u8 = 5;
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
