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

export const mainnet_addr =
  process.env.NEXT_PUBLIC_RPC_ENDPOINT || "https://alpha-mainnet.starknet.io";

export function getGraphQLUrl() {
  switch (process.env.NEXT_PUBLIC_NETWORK) {
    case "dev":
      return "https://survivor-indexer.realms.world/goerli-graphql";
    case "production":
      return "https://survivor-indexer.realms.world/graphql";
    default:
      return "http://localhost:8000/graphql";
  }
}

export const contracts = {
  mainnet: {
    game: "0x0",
    lords: "0x067e87cea28bfd9314a1d3c41fb26a58ca1346ff0ea2452e59b9eeb2828692dc",
  },
  goerli: {
    game: "0x01263ecbc05e28d1e99f531894838db10b90cfcdd39d020642da1747a733a37a",
    lords: "0x05e367ac160e5f90c5775089b582dfc987dd148a5a2f977c49def2a6644f724b",
  },
};

export const appUrl = "https://survivor.realms.world/";

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
export const penaltyTime = 12 * 15;
export const itemCharismaDiscount = 1;
export const itemBasePrice = 4;
export const itemMinimumPrice = 1;
export const potionCharismaDiscount = 2;
export const potionBasePrice = 2;
export const idleDeathPenaltyBlocks = 300;

// UI PARAMS
export const MIN_BALANCE = 10000000000000; // 0.00001ETH or $0.015
export const FEE_CHECK_BALANCE = 100000000000000; // 0.0001ETH or $0.15

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
