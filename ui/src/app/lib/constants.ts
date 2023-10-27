import { Adventurer } from "../types";

export const prologue =
  "An adventurer stirs from a slumber in a cold, dark cave.";
export const chapter1 =
  "Disoriented, they scour the darkness, the only sound a dripping echo and the biting whisper of wind.";
export const chapter2 =
  "Where? How? Water whispers nearby. They move, reaching through the mist. Suddenly, a fountain materializes, an ethereal sentinel obscured by the swirling vapor.";
export const chapter3 =
  "Intrigued, they draw closer, their form dancing on the water's surface. Four oddities lie within - a wand, a book, a club, and a sword.";
export const chapter4 =
  "They find golden coins in their pocket, glimmering in the dim light - an enigma wrapped in the shroud of the unexpected.";
export const battle = "A beast lurks in the shadow, prepare for battle!";

export const NETWORK: "goerli" | "mainnet" = "goerli";

export function getRPCUrl() {
  switch (NETWORK) {
    case "goerli":
      return "https://starknet-goerli.infura.io/v3/6c536e8272f84d3ba63bf9f248c5e128";
    case "mainnet":
      return "https://starknet-mainnet.infura.io/v3/6c536e8272f84d3ba63bf9f248c5e128";
    default:
      return "http://localhost:8000/graphql";
  }
}

export function getAPIKey() {
  switch (NETWORK) {
    case "goerli":
      return "6c536e8272f84d3ba63bf9f248c5e128";
    case "mainnet":
      return "6c536e8272f84d3ba63bf9f248c5e128";
    default:
      return "http://localhost:8000/graphql";
  }
}

export function getGraphQLUrl() {
  switch (NETWORK) {
    case "goerli":
      return "https://survivor-indexer.realms.world/goerli-graphql";
    case "mainnet":
      return "https://survivor-indexer.realms.world/graphql";
    default:
      return "http://localhost:8000/graphql";
  }
}

export function getContracts() {
  switch (NETWORK) {
    case "goerli":
      return {
        eth: "0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7",
        game: "0x0759060edbce85ab703ecca246194f625387e44ef5b1b7b91e685e70b2a1c342",
        lords:
          "0x05e367ac160e5f90c5775089b582dfc987dd148a5a2f977c49def2a6644f724b",
        beasts:
          "0x05ffc59bb38e18a1ddc09e4c92963642ee7b66b6fc32dc76aa6c33a3b4197f82",
        goldenToken:
          "0x04a71260d6e29274b760195acdc5379592bd78383713ddce5d2c635d237edf55",
      };
    case "mainnet":
      return {
        eth: "0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7",
        game: "0x0",
        lords:
          "0x0124aeb495b947201f5fac96fd1138e326ad86195b98df6dec9009158a533b49",
        beasts: "0x0",
        goldenToken: "0x0",
      };
  }
}

export function getArcadeClassHash() {
  switch (NETWORK) {
    case "goerli":
      return "0x0715b5e10bf63c36e69c402a81e1eb96b9107ef56eb5e821b00893e39bdcf545";
    case "mainnet":
      return "0x0";
  }
}

export function getAppUrl() {
  switch (NETWORK) {
    case "goerli":
      return "https://goerli-survivor.realms.world/";
    case "mainnet":
      return "https://survivor.realms.world/";
  }
}

export function getTokenViewerUrl() {
  switch (NETWORK) {
    case "goerli":
      return "https://realmsworld-git-ls-updates-loot-bibliotheca.vercel.app/collection/beasts/";
    case "mainnet":
      return "https://realmsworld-git-ls-updates-loot-bibliotheca.vercel.app/collection/beasts/";
  }
}

export const notificationAnimations = [
  { name: "idle", startFrame: 0, frameCount: 4 },
  { name: "run", startFrame: 9, frameCount: 5 },
  { name: "jump", startFrame: 11, frameCount: 7 },
  { name: "attack1", startFrame: 42, frameCount: 5 },
  { name: "attack2", startFrame: 47, frameCount: 6 },
  { name: "attack3", startFrame: 53, frameCount: 8 },
  { name: "damage", startFrame: 59, frameCount: 4 },
  { name: "die", startFrame: 64, frameCount: 9 },
  { name: "drawSword", startFrame: 70, frameCount: 5 },
  { name: "discoverItem", startFrame: 85, frameCount: 6 },
  { name: "slide", startFrame: 24, frameCount: 5 },
];

// ---- CONTRACT PARAMS
// Penalty time is 12 blocks, where each block is ~ 15 seconds
export const penaltyTime = 420;
export const itemCharismaDiscount = 1;
export const itemBasePrice = 4;
export const itemMinimumPrice = 1;
export const potionCharismaDiscount = 2;
export const potionBasePrice = 2;
export const idleDeathPenaltyBlocks = 300;

// UI PARAMS
export const MIN_BALANCE = 10000000000000; // 0.00001ETH or $0.015
export const FEE_CHECK_BALANCE = 200000000000000; // 0.00025ETH or $0.45

export const deathMessages = [
  {
    rank: 3,
    message: "Supreme Conqueror! - Unrivaled mastery of survival!",
  },
  {
    rank: 10,
    message: "Glorious Victor! - A testament to your indomitable spirit!",
  },
  {
    rank: 25,
    message: "Heroic Endurance! - Legends will speak of your bravery!",
  },
  {
    rank: 50,
    message: "Valiant Survivor! - A remarkable display of fortitude!",
  },
  { rank: 100, message: "Brave Combatant! - A commendable effort!" },
  { rank: 250, message: "Daring Challenger! - A brave stand!" },
];

export const efficacyData = [
  { weapon: "Blade", metal: "Weak", hide: "Fair", cloth: "Strong" },
  { weapon: "Bludgeon", metal: "Fair", hide: "Strong", cloth: "Weak" },
  { weapon: "Magic", metal: "Strong", hide: "Weak", cloth: "Fair" },
];

export const tempTop10Adventurers: Adventurer[] = [
  {
    actionsPerBlock: 0,
    beastHealth: 0,
    charisma: 13,
    chest: "Demon Husk",
    createdTime: new Date(),
    dexterity: 14,
    foot: "Demonhide Boots",
    gold: 130,
    hand: "Demons Hands",
    head: "Demon Crown",
    health: 0,
    id: 472,
    intelligence: 22,
    lastAction: 69,
    lastUpdatedTime: new Date(),
    luck: 49,
    name: ".",
    neck: "Pendant",
    owner: "0x017de9abd0041be0e0efe6878762fa11ccc68a0108772022df73da2b5ec8fa6b",
    revealBlock: 890361,
    ring: "Platinum Ring",
    startBlock: 890360,
    statUpgrades: 0,
    strength: 14,
    timestamp: new Date(),
    vitality: 10,
    waist: "Demonhide Belt",
    weapon: "Katana",
    wisdom: 21,
    xp: 2132,
  },
  {
    actionsPerBlock: 2,
    beastHealth: 463,
    charisma: 18,
    chest: "Holy Chestplate",
    createdTime: new Date(),
    dexterity: 7,
    foot: "Holy Greaves",
    gold: 335,
    hand: "Holy Gauntlets",
    head: "Ancient Helm",
    health: 0,
    id: 225,
    intelligence: 16,
    lastAction: 137,
    lastUpdatedTime: new Date(),
    luck: 80,
    name: "jbp3 _",
    neck: "Necklace",
    owner: "0x033a1e350f82d492c5b1cebe072cf638f9b98dde82dba9d2a6f8b02b5cf97ad1",
    revealBlock: 889899,
    ring: "Titanium Ring",
    startBlock: 889898,
    statUpgrades: 0,
    strength: 13,
    timestamp: new Date(),
    vitality: 20,
    waist: "Ornate Belt",
    weapon: "Katana",
    wisdom: 12,
    xp: 1821,
  },
  {
    actionsPerBlock: 0,
    beastHealth: 326,
    charisma: 19,
    chest: "Demon Husk",
    createdTime: new Date(),
    dexterity: 2,
    foot: "Divine Slippers",
    gold: 263,
    hand: "Holy Gauntlets",
    head: "Crown",
    health: 0,
    id: 180,
    intelligence: 13,
    lastAction: 448,
    lastUpdatedTime: new Date(),
    luck: 60,
    name: "zzz",
    neck: "Necklace",
    owner: "0x0165813274b87d254ee2750891fbb8db6738b72618e3e1cbc3cc325ebe727905",
    revealBlock: 889758,
    ring: "Platinum Ring",
    startBlock: 889757,
    statUpgrades: 0,
    strength: 19,
    timestamp: new Date(),
    vitality: 15,
    waist: "Ornate Belt",
    weapon: "Katana",
    wisdom: 14,
    xp: 1225,
  },
  {
    actionsPerBlock: 3,
    beastHealth: 283,
    charisma: 14,
    chest: "Holy Chestplate",
    createdTime: new Date(),
    dexterity: 12,
    foot: "Divine Slippers",
    gold: 141,
    hand: "Holy Gauntlets",
    head: "Crown",
    health: 0,
    id: 134,
    intelligence: 4,
    lastAction: 396,
    lastUpdatedTime: new Date(),
    luck: 59,
    name: "ducky1",
    neck: "Necklace",
    owner: "0x0667882833a0229a1d306148fcf58c3ffd5232b461eb68c2f4ddcd88f698609b",
    revealBlock: 889685,
    ring: "Gold Ring",
    startBlock: 889684,
    statUpgrades: 0,
    strength: 19,
    timestamp: new Date(),
    vitality: 13,
    waist: "Ornate Belt",
    weapon: "Ghost Wand",
    wisdom: 14,
    xp: 944,
  },
  {
    actionsPerBlock: 2,
    beastHealth: 230,
    charisma: 15,
    chest: "Demon Husk",
    createdTime: new Date(),
    dexterity: 4,
    foot: "Holy Greaves",
    gold: 271,
    hand: "Demons Hands",
    head: "Ancient Helm",
    health: 0,
    id: 262,
    intelligence: 19,
    lastAction: 208,
    lastUpdatedTime: new Date(),
    luck: 40,
    name: "dd",
    neck: "Pendant",
    owner: "0x0598adbc9a39f611b5522b5d5765096574f702821e0b3cdf8cc80d8425cff19a",
    revealBlock: 890029,
    ring: "Platinum Ring",
    startBlock: 890028,
    statUpgrades: 0,
    strength: 16,
    timestamp: new Date(),
    vitality: 10,
    waist: "Demonhide Belt",
    weapon: "Katana",
    wisdom: 12,
    xp: 936,
  },
  {
    actionsPerBlock: 3,
    beastHealth: 0,
    charisma: 10,
    chest: "Demon Husk",
    createdTime: new Date(),
    dexterity: 14,
    foot: "Demonhide Boots",
    gold: 122,
    hand: "Demons Hands",
    head: "Demon Crown",
    health: 0,
    id: 474,
    intelligence: 14,
    lastAction: 44,
    lastUpdatedTime: new Date(),
    luck: 51,
    name: "frost-111",
    neck: "Pendant",
    owner: "0x049e4f42072a5ff2b712334082fa29241c1737ea03116ec3092d2863a31a1e13",
    revealBlock: 890364,
    ring: "Titanium Ring",
    startBlock: 890363,
    statUpgrades: 0,
    strength: 12,
    timestamp: new Date(),
    vitality: 11,
    waist: "Demonhide Belt",
    weapon: "Ghost Wand",
    wisdom: 13,
    xp: 832,
  },
  {
    actionsPerBlock: 1,
    beastHealth: 484,
    charisma: 13,
    chest: "Demon Husk",
    createdTime: new Date(),
    dexterity: 9,
    foot: "Demonhide Boots",
    gold: 53,
    hand: "Demons Hands",
    head: "Demon Crown",
    health: 0,
    id: 951,
    intelligence: 14,
    lastAction: 143,
    lastUpdatedTime: new Date(),
    luck: 52,
    name: "jbp3 $$$$",
    neck: "Pendant",
    owner: "0x033a1e350f82d492c5b1cebe072cf638f9b98dde82dba9d2a6f8b02b5cf97ad1",
    revealBlock: 891490,
    ring: "Gold Ring",
    startBlock: 891489,
    statUpgrades: 0,
    strength: 4,
    timestamp: new Date(),
    vitality: 10,
    waist: "Leather Belt",
    weapon: "Ghost Wand",
    wisdom: 14,
    xp: 696,
  },
  {
    actionsPerBlock: 3,
    beastHealth: 251,
    charisma: 16,
    chest: "Holy Chestplate",
    createdTime: new Date(),
    dexterity: 1,
    foot: "Holy Greaves",
    gold: 178,
    hand: "Holy Gauntlets",
    head: "Cap",
    health: 0,
    id: 133,
    intelligence: 7,
    lastAction: 391,
    lastUpdatedTime: new Date(),
    luck: 72,
    name: "Tw@Gink5814",
    neck: "Necklace",
    owner: "0x01405a296a77a60c0621f680e822a1049b9a1d219a75c4d57b872b2cfbb7950f",
    revealBlock: 889685,
    ring: "Titanium Ring",
    startBlock: 889684,
    statUpgrades: 0,
    strength: 14,
    timestamp: new Date(),
    vitality: 18,
    waist: "Mesh Belt",
    weapon: "Warhammer",
    wisdom: 10,
    xp: 690,
  },
  {
    actionsPerBlock: 0,
    beastHealth: 276,
    charisma: 11,
    chest: "Shirt",
    createdTime: new Date(),
    dexterity: 8,
    foot: "Divine Slippers",
    gold: 4,
    hand: "Divine Gloves",
    head: "Helm",
    health: 0,
    id: 727,
    intelligence: 6,
    lastAction: 106,
    lastUpdatedTime: new Date(),
    luck: 44,
    name: "jbp3 $",
    neck: "Amulet",
    owner: "0x033a1e350f82d492c5b1cebe072cf638f9b98dde82dba9d2a6f8b02b5cf97ad1",
    revealBlock: 890966,
    ring: "Gold Ring",
    startBlock: 890965,
    statUpgrades: 0,
    strength: 4,
    timestamp: new Date(),
    vitality: 6,
    waist: "Brightsilk Sash",
    weapon: "Warhammer",
    wisdom: 11,
    xp: 402,
  },
  {
    actionsPerBlock: 5,
    beastHealth: 119,
    charisma: 9,
    chest: "Holy Chestplate",
    createdTime: new Date(),
    dexterity: 4,
    foot: "Divine Slippers",
    gold: 60,
    hand: "Gloves",
    head: "Helm",
    health: 0,
    id: 381,
    intelligence: 4,
    lastAction: 398,
    lastUpdatedTime: new Date(),
    luck: 31,
    name: "shirohige",
    neck: "Amulet",
    owner: "0x03d03ca02b001d90a3c26844acaac834615b6e6d3dffc4ffd0ae0c672b9fd525",
    revealBlock: 890228,
    ring: "Titanium Ring",
    startBlock: 890227,
    statUpgrades: 0,
    strength: 9,
    timestamp: new Date(),
    vitality: 11,
    waist: "Ornate Belt",
    weapon: "Ghost Wand",
    wisdom: 7,
    xp: 378,
  },
];

export const tempTop10Scores = [
  {
    adventurerId: 472,
    owner: "0x017de9abd0041be0e0efe6878762fa11ccc68a0108772022df73da2b5ec8fa6b",
    rank: 1,
    scoreTime: "2023-10-26T22:07:06.320Z",
    timestamp: "2023-10-27T13:33:56.558Z",
    totalPayout: 4517.999999999937,
    txHash:
      "0x03a1e96c27f5cf0b4fc24fc2fbbe541b5f94fa67873d76026c7f315e2df35eba",
    xp: 2132,
  },
  {
    adventurerId: 225,
    owner: "0x033a1e350f82d492c5b1cebe072cf638f9b98dde82dba9d2a6f8b02b5cf97ad1",
    rank: 1,
    scoreTime: "2023-10-26T22:07:01.599Z",
    timestamp: "2023-10-27T13:33:56.558Z",
    totalPayout: 4177,
    txHash:
      "0x05b4428378d7a70a277f089eea392ddcbc37fee096910e29556a0940e6632213",
    xp: 1821,
  },
  {
    adventurerId: 180,
    owner: "0x0165813274b87d254ee2750891fbb8db6738b72618e3e1cbc3cc325ebe727905",
    rank: 1,
    scoreTime: "2023-10-26T22:07:00.627Z",
    timestamp: "2023-10-27T13:33:56.558Z",
    totalPayout: 2893.000000000046,
    txHash:
      "0x0310fa8ab0e9e59d3543190d4d79a5a5deaf0a5d0d370308e78635057308d94d",
    xp: 1225,
  },
  {
    adventurerId: 133,
    owner: "0x01405a296a77a60c0621f680e822a1049b9a1d219a75c4d57b872b2cfbb7950f",
    rank: 1,
    scoreTime: "2023-10-26T22:06:59.910Z",
    timestamp: "2023-10-26T22:07:01.563Z",
    totalPayout: 312,
    txHash:
      "0x0150b2cb9bf90e269ffc20855aa50a39b1614d8531bd3785da40c73d0e984cc3",
    xp: 690,
  },
  {
    adventurerId: 81,
    owner: "0x03dd4e8cb7848db2a3e57dca93c79dcd69bf28c92023cc097c8761ce358f9ff7",
    rank: 1,
    scoreTime: "2023-10-26T22:06:58.770Z",
    timestamp: "2023-10-26T22:07:00.627Z",
    totalPayout: 669,
    txHash:
      "0x00b942d727d22e55e83c44ea35b688e865335c15a7499bb7bed7550a0b097bf0",
    xp: 292,
  },
  {
    adventurerId: 10,
    owner: "0x078022d1a419fc2e4ad96b575d2c939db2bddef3a1b143058d17afab73b28933",
    rank: 1,
    scoreTime: "2023-10-26T22:06:57.843Z",
    timestamp: "2023-10-26T22:06:59.956Z",
    totalPayout: 613,
    txHash:
      "0x01c7ed0127e8bbd05a923d5a6bf5bd7e576dd1fa2196a8a7ce772db45891f061",
    xp: 281,
  },
  {
    adventurerId: 93,
    owner: "0x033a1e350f82d492c5b1cebe072cf638f9b98dde82dba9d2a6f8b02b5cf97ad1",
    rank: 3,
    scoreTime: "2023-10-26T22:06:59.288Z",
    timestamp: "2023-10-26T22:06:59.910Z",
    totalPayout: 102,
    txHash:
      "0x02cb574ab3d5a40525e136c5e90b44d8749c759f6dc0aaae34e1845807fc7c7e",
    xp: 278,
  },
  {
    adventurerId: 91,
    owner: "0x01405a296a77a60c0621f680e822a1049b9a1d219a75c4d57b872b2cfbb7950f",
    rank: 3,
    scoreTime: "2023-10-26T22:06:59.056Z",
    timestamp: "2023-10-26T22:06:59.288Z",
    totalPayout: 36,
    txHash:
      "0x00a427821343d2105ba6f2df06dcdb21fd6b5c3706a4b41a07b80bad6787a8a4",
    xp: 277,
  },
  {
    adventurerId: 86,
    owner: "0x017de9abd0041be0e0efe6878762fa11ccc68a0108772022df73da2b5ec8fa6b",
    rank: 3,
    scoreTime: "2023-10-26T22:06:58.833Z",
    timestamp: "2023-10-26T22:06:59.025Z",
    totalPayout: 24,
    txHash:
      "0x00c7e644d1c6931942be0d7a557554d3823597e9e5ac29abfb64bcc6a59cadb7",
    xp: 193,
  },
  {
    adventurerId: 54,
    owner: "0x017de9abd0041be0e0efe6878762fa11ccc68a0108772022df73da2b5ec8fa6b",
    rank: 3,
    scoreTime: "2023-10-26T22:06:58.310Z",
    timestamp: "2023-10-26T22:06:58.769Z",
    totalPayout: 81,
    txHash:
      "0x02fa952f02398c1a877ec248c2929fe62deaf152a1ec3c34ed1d0c5ecb5a4b60",
    xp: 146,
  },
];
