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
        game: "0x01263ecbc05e28d1e99f531894838db10b90cfcdd39d020642da1747a733a37a",
        lords:
          "0x05e367ac160e5f90c5775089b582dfc987dd148a5a2f977c49def2a6644f724b",
      };
    case "mainnet":
      return {
        eth: "0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7",
        game: "0x0",
        lords:
          "0x0124aeb495b947201f5fac96fd1138e326ad86195b98df6dec9009158a533b49",
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
      return "https://starknet-goerli.infura.io/v3/6c536e8272f84d3ba63bf9f248c5e128";
    case "mainnet":
      return "https://starknet-mainnet.infura.io/v3/6c536e8272f84d3ba63bf9f248c5e128";
  }
}

// export function getRPCUrl() {
//   switch (process.env.NEXT_PUBLIC_NETWORK) {
//     case "goerli":
//       return process.env.NEXT_PUBLIC_RPC_GOERLI_ENDPOINT;
//     case "mainnet":
//       return process.env.NEXT_PUBLIC_RPC_MAINNET_ENDPOINT;
//     default:
//       return "http://localhost:8000/graphql";
//   }
// }

// export function getGraphQLUrl() {
//   switch (process.env.NEXT_PUBLIC_NETWORK) {
//     case "goerli":
//       return "https://survivor-indexer.realms.world/goerli-graphql";
//     case "mainnet":
//       return "https://survivor-indexer.realms.world/graphql";
//     default:
//       return "http://localhost:8000/graphql";
//   }
// }

// export function getContracts() {
//   switch (process.env.NEXT_PUBLIC_NETWORK) {
//     case "goerli":
//       return {
//         eth: process.env.NEXT_PUBLIC_GOERLI_ETH_CONTRACT_ADDRESS,
//         game: process.env.NEXT_PUBLIC_GOERLI_GAME_CONTRACT_ADDRESS,
//         lords: process.env.NEXT_PUBLIC_GOERLI_LORDS_CONTRACT_ADDRESS,
//       };
//     case "mainnet":
//       return {
//         eth: process.env.NEXT_PUBLIC_MAINNET_ETH_CONTRACT_ADDRESS,
//         game: process.env.NEXT_PUBLIC_MAINNET_GAME_CONTRACT_ADDRESS,
//         lords: process.env.NEXT_PUBLIC_MAINNET_LORDS_CONTRACT_ADDRESS,
//       };
//   }
// }

// export function getArcadeClassHash() {
//   switch (process.env.NEXT_PUBLIC_NETWORK) {
//     case "goerli":
//       return process.env.NEXT_PUBLIC_GOERLI_ARCADE_ACCOUNT_CLASS_HASH;
//     case "mainnet":
//       return process.env.NEXT_PUBLIC_MAINNET_ARCADE_ACCOUNT_CLASS_HASH;
//   }
// }

// export function getAppUrl() {
//   switch (process.env.NEXT_PUBLIC_NETWORK) {
//     case "goerli":
//       return process.env.NEXT_PUBLIC_GOERLI_APP_URL;
//     case "mainnet":
//       return process.env.NEXT_PUBLIC_MAINNET_APP_URL;
//   }
// }

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
