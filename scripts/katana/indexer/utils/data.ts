export type Dict<T> = { [key: number]: T };
export type DictString<T> = { [key: string]: T };

export class GameData {
  ITEM_TIERS: Dict<number>;
  ITEM_SLOTS: Dict<number>;
  ITEM_TYPES: Dict<number>;
  BEAST_TYPES: Dict<number>;
  BEAST_TIERS: Dict<number>;

  constructor() {
    this.ITEM_TIERS = {
      1: 1, // Pendant
      2: 1, // Necklace
      3: 1, // Amulet
      4: 2, // SilverRing
      5: 3, // BronzeRing
      6: 1, // PlatinumRing
      7: 1, // TitaniumRing
      8: 1, // GoldRing
      9: 1, // GhostWand
      10: 2, // GraveWand
      11: 3, // BoneWand
      12: 5, // Wand
      13: 1, // Grimoire
      14: 2, // Chronicle
      15: 3, // Tome
      16: 5, // Book
      17: 1, // DivineRobe
      18: 2, // SilkRobe
      19: 3, // LinenRobe
      20: 4, // Robe
      21: 5, // Shirt
      22: 1, // Crown
      23: 2, // DivineHood
      24: 3, // SilkHood
      25: 4, // LinenHood
      26: 5, // Hood
      27: 1, // BrightsilkSash
      28: 2, // SilkSash
      29: 3, // WoolSash
      30: 4, // LinenSash
      31: 5, // Sash
      32: 1, // DivineSlippers
      33: 2, // SilkSlippers
      34: 3, // WoolShoes
      35: 4, // LinenShoes
      36: 5, // Shoes
      37: 1, // DivineGloves
      38: 2, // SilkGloves
      39: 3, // WoolGloves
      40: 4, // LinenGloves
      41: 5, // Gloves
      42: 1, // Katana
      43: 2, // Falchion
      44: 3, // Scimitar
      45: 4, // LongSword
      46: 5, // ShortSword
      47: 1, // DemonHusk
      48: 2, // DragonskinArmor
      49: 3, // StuddedLeatherArmor
      50: 4, // HardLeatherArmor
      51: 5, // LeatherArmor
      52: 1, // DemonCrown
      53: 2, // DragonsCrown
      54: 3, // WarCap
      55: 4, // LeatherCap
      56: 5, // Cap
      57: 1, // DemonhideBelt
      58: 2, // DragonskinBelt
      59: 3, // StuddedLeatherBelt
      60: 4, // HardLeatherBelt
      61: 5, // LeatherBelt
      62: 1, // DemonhideBoots
      63: 2, // DragonskinBoots
      64: 3, // StuddedLeatherBoots
      65: 4, // HardLeatherBoots
      66: 5, // LeatherBoots
      67: 1, // DemonsHands
      68: 2, // DragonskinGloves
      69: 3, // StuddedLeatherGloves
      70: 4, // HardLeatherGloves
      71: 5, // LeatherGloves
      72: 1, // Warhammer
      73: 2, // Quarterstaff
      74: 3, // Maul
      75: 4, // Mace
      76: 5, // Club
      77: 1, // HolyChestplate
      78: 2, // OrnateChestplate
      79: 3, // PlateMail
      80: 4, // ChainMail
      81: 5, // RingMail
      82: 1, // AncientHelm
      83: 2, // OrnateHelm
      84: 3, // GreatHelm
      85: 4, // FullHelm
      86: 5, // Helm
      87: 1, // OrnateBelt
      88: 2, // WarBelt
      89: 3, // PlatedBelt
      90: 4, // MeshBelt
      91: 5, // HeavyBelt
      92: 1, // HolyGreaves
      93: 2, // OrnateGreaves
      94: 3, // Greaves
      95: 4, // ChainBoots
      96: 5, // HeavyBoots
      97: 1, // HolyGauntlets
      98: 2, // OrnateGauntlets
      99: 3, // Gauntlets
      100: 4, // ChainGloves
      101: 5, // HeavyGloves
    };

    this.ITEM_SLOTS = {
      1: 7, // Pendant: Neck
      2: 7, // Necklace: Neck
      3: 7, // Amulet: Neck
      4: 8, // SilverRing: Ring
      5: 8, // BronzeRing: Ring
      6: 8, // PlatinumRing: Ring
      7: 8, // TitaniumRing: Ring
      8: 8, // GoldRing: Ring
      9: 1, // GhostWand: Weapon
      10: 1, // GraveWand: Weapon
      11: 1, // BoneWand: Weapon
      12: 1, // Wand: Weapon
      13: 1, // Grimoire: Weapon
      14: 1, // Chronicle: Weapon
      15: 1, // Tome: Weapon
      16: 1, // Book: Weapon
      17: 2, // DivineRobe: Chest
      18: 2, // SilkRobe: Chest
      19: 2, // LinenRobe: Chest
      20: 2, // Robe: Chest
      21: 2, // Shirt: Chest
      22: 3, // Crown: Head
      23: 3, // DivineHood: Head
      24: 3, // SilkHood: Head
      25: 3, // LinenHood: Head
      26: 3, // Hood: Head
      27: 4, // BrightsilkSash: Waist
      28: 4, // SilkSash: Waist
      29: 4, // WoolSash: Waist
      30: 4, // LinenSash: Waist
      31: 4, // Sash: Waist
      32: 5, // DivineSlippers: Foot
      33: 5, // SilkSlippers: Foot
      34: 5, // WoolShoes: Foot
      35: 5, // LinenShoes: Foot
      36: 5, // Shoes: Foot
      37: 6, // DivineGloves: Hand
      38: 6, // SilkGloves: Hand
      39: 6, // WoolGloves: Hand
      40: 6, // LinenGloves: Hand
      41: 6, // Gloves: Hand
      42: 1, // Katana: Weapon
      43: 1, // Falchion: Weapon
      44: 1, // Scimitar: Weapon
      45: 1, // LongSword: Weapon
      46: 1, // ShortSword: Weapon
      47: 2, // DemonHusk: Chest
      48: 2, // DragonskinArmor: Chest
      49: 2, // StuddedLeatherArmor: Chest
      50: 2, // HardLeatherArmor: Chest
      51: 2, // LeatherArmor: Chest
      52: 3, // DemonCrown: Head
      53: 3, // DragonsCrown: Head
      54: 3, // WarCap: Head
      55: 3, // LeatherCap: Head
      56: 3, // Cap: Head
      57: 4, // DemonhideBelt: Waist
      58: 4, // DragonskinBelt: Waist
      59: 4, // StuddedLeatherBelt: Waist
      60: 4, // HardLeatherBelt: Waist
      61: 4, // LeatherBelt: Waist
      62: 5, // DemonhideBoots: Foot
      63: 5, // DragonskinBoots: Foot
      64: 5, // StuddedLeatherBoots: Foot
      65: 5, // HardLeatherBoots: Foot
      66: 5, // LeatherBoots: Foot
      67: 6, // DemonsHands: Hand
      68: 6, // DragonskinGloves: Hand
      69: 6, // StuddedLeatherGloves: Hand
      70: 6, // HardLeatherGloves: Hand
      71: 6, // LeatherGloves: Hand
      72: 1, // Warhammer: Weapon
      73: 1, // Quarterstaff: Weapon
      74: 1, // Maul: Weapon
      75: 1, // Mace: Weapon
      76: 1, // Club: Weapon
      77: 2, // HolyChestplate: Chest
      78: 2, // OrnateChestplate: Chest
      79: 2, // PlateMail: Chest
      80: 2, // ChainMail: Chest
      81: 2, // RingMail: Chest
      82: 3, // AncientHelm: Head
      83: 3, // OrnateHelm: Head
      84: 3, // GreatHelm: Head
      85: 3, // FullHelm: Head
      86: 3, // Helm: Head
      87: 4, // OrnateBelt: Waist
      88: 4, // WarBelt: Waist
      89: 4, // PlatedBelt: Waist
      90: 4, // MeshBelt: Waist
      91: 4, // HeavyBelt: Waist
      92: 5, // HolyGreaves: Foot
      93: 5, // OrnateGreaves: Foot
      94: 5, // Greaves: Foot
      95: 5, // ChainBoots: Foot
      96: 5, // HeavyBoots: Foot
      97: 6, // HolyGauntlets: Hand
      98: 6, // OrnateGauntlets: Hand
      99: 6, // Gauntlets: Hand
      100: 6, // ChainGloves: Hand
      101: 6, // HeavyGloves: Hand
    };

    this.ITEM_TYPES = {
      1: 1,
      2: 1,
      3: 1,
      4: 2,
      5: 2,
      6: 2,
      7: 2,
      8: 2,
      9: 3,
      10: 3,
      11: 3,
      12: 3,
      13: 3,
      14: 3,
      15: 3,
      16: 3,
      17: 4,
      18: 4,
      19: 4,
      20: 4,
      21: 4,
      22: 4,
      23: 4,
      24: 4,
      25: 4,
      26: 4,
      27: 4,
      28: 4,
      29: 4,
      30: 4,
      31: 4,
      32: 4,
      33: 4,
      34: 4,
      35: 4,
      36: 4,
      37: 4,
      38: 4,
      39: 4,
      40: 4,
      41: 4,
      42: 5,
      43: 5,
      44: 5,
      45: 5,
      46: 5,
      47: 6,
      48: 6,
      49: 6,
      50: 6,
      51: 6,
      52: 6,
      53: 6,
      54: 6,
      55: 6,
      56: 6,
      57: 6,
      58: 6,
      59: 6,
      60: 6,
      61: 6,
      62: 6,
      63: 6,
      64: 6,
      65: 6,
      66: 6,
      67: 6,
      68: 6,
      69: 6,
      70: 6,
      71: 6,
      72: 7,
      73: 7,
      74: 7,
      75: 7,
      76: 7,
      77: 8,
      78: 8,
      79: 8,
      80: 8,
      81: 8,
      82: 8,
      83: 8,
      84: 8,
      85: 8,
      86: 8,
      87: 8,
      88: 8,
      89: 8,
      90: 8,
      91: 8,
      92: 8,
      93: 8,
      94: 8,
      95: 8,
      96: 8,
      97: 8,
      98: 8,
      99: 8,
      100: 8,
      101: 8,
    };

    this.BEAST_TYPES = {
      // Magical Beasts
      1: 1,
      2: 1,
      3: 1,
      4: 1,
      5: 1,
      6: 1,
      7: 1,
      8: 1,
      9: 1,
      10: 1,
      11: 1,
      12: 1,
      13: 1,
      14: 1,
      15: 1,
      16: 1,
      17: 1,
      18: 1,
      19: 1,
      20: 1,
      21: 1,
      22: 1,
      23: 1,
      24: 1,
      25: 1,
      // Hunter Beasts
      26: 2,
      27: 2,
      28: 2,
      29: 2,
      30: 2,
      31: 2,
      32: 2,
      33: 2,
      34: 2,
      35: 2,
      36: 2,
      37: 2,
      38: 2,
      39: 2,
      40: 2,
      41: 2,
      42: 2,
      43: 2,
      44: 2,
      45: 2,
      46: 2,
      47: 2,
      48: 2,
      49: 2,
      50: 2,
      // Brute Beasts
      51: 3,
      52: 3,
      53: 3,
      54: 3,
      55: 3,
      56: 3,
      57: 3,
      58: 3,
      59: 3,
      60: 3,
      61: 3,
      62: 3,
      63: 3,
      64: 3,
      65: 3,
      66: 3,
      67: 3,
      68: 3,
      69: 3,
      70: 3,
      71: 3,
      72: 3,
      73: 3,
      74: 3,
      75: 3,
    };

    this.BEAST_TIERS = {
      // Magical T1s
      1: 1,
      2: 1,
      3: 1,
      4: 1,
      5: 1,
      // Magical T2s
      6: 2,
      7: 2,
      8: 2,
      9: 2,
      10: 2,
      // Magical T3s
      11: 3,
      12: 3,
      13: 3,
      14: 3,
      15: 3,
      // Magical T4s
      16: 4,
      17: 4,
      18: 4,
      19: 4,
      20: 4,
      // Magical T5s
      21: 5,
      22: 5,
      23: 5,
      24: 5,
      25: 5,
      // Hunter T1s
      26: 1,
      27: 1,
      28: 1,
      29: 1,
      30: 1,
      // Hunter T2s
      31: 2,
      32: 2,
      33: 2,
      34: 2,
      35: 2,
      // Hunter T3s
      36: 3,
      37: 3,
      38: 3,
      39: 3,
      40: 3,
      // Hunter T4s
      41: 4,
      42: 4,
      43: 4,
      44: 4,
      45: 4,
      // Hunter T5s
      46: 5,
      47: 5,
      48: 5,
      49: 5,
      50: 5,
      // Brute T1s
      51: 1,
      52: 1,
      53: 1,
      54: 1,
      55: 1,
      // Brute T2s
      56: 2,
      57: 2,
      58: 2,
      59: 2,
      60: 2,
      // Brute T3s
      61: 3,
      62: 3,
      63: 3,
      64: 3,
      65: 3,
      // Brute T4s
      66: 4,
      67: 4,
      68: 4,
      69: 4,
      70: 4,
      // Brute T5s
      71: 5,
      72: 5,
      73: 5,
      74: 5,
      75: 5,
    };
  }
}
