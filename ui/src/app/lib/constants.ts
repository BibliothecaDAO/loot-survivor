import { constants } from "starknet";
// export const prologue =
//   "In the beginning, echoes of a thousand whispers stirred, breathing life into a mystical force. This force, known as the Adventurer's Will, gave rise to an enigmatic figure destined to navigate the boundless realms of a world shrouded in darkness: the Adventurer. Armed with nothing but their will to survive and a weapon as an extension of their spirit, they found themselves on the brink of an uncharted and forsaken land where the sun no longer graced the sky, and a dying moon cast an eerie glow. Each exploration was a unique labyrinth of trials, treasures, and mythical creatures. As the Adventurer journeyed through these desolate realms, their power grew, their bag filled with enchanted protection - precious loot that empowered them with the strength and wisdom needed to confront the lurking horrors. Beasts of unimaginable terror, each bearing unique attacks, weapons, and armor, roamed these lands, turning every encounter into a choice between battle and flight, a calculated risk between survival and demise. The veil between the living and the dead had grown thin in this forsaken world, allowing malevolent beings to wreak havoc upon the remnants. Amidst the chaos and looming dread, a desperate hope flickered in the hearts of the survivors, tethered to an ancient prophecy whispering of a chosen one who would restore balance. Relying on their cunning and resourcefulness, growing stronger with each fall and rising, fueled by the knowledge and experiences of their past lives. And so, the question remains: will the Adventurer fulfill their destiny as the harbinger of hope, or succumb to the encroaching darkness that threatens to consume all that remains?";
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

export const mainnet_addr = "https://alpha-mainnet.starknet.io";

export function getGraphQLUrl() {
  switch (process.env.NEXT_PUBLIC_NETWORK) {
    case "dev":
      return "https://p01--loot-survivor-graphql-new--cwpz4gs4p7vn.code.run/goerli-graphql";
    case "production":
      return "https://p01--loot-survivor-graphql--cwpz4gs4p7vn.code.run/graphql";
    default:
      return "http://localhost:8000/graphql";
  }
}

export const contracts = {
  mainnet: {
    game: "0x0",
    lords_erc20_mintable:
      "0x067e87cea28bfd9314a1d3c41fb26a58ca1346ff0ea2452e59b9eeb2828692dc",
  },
  goerli: {
    game: "0x02047b8a0f95a8aab8d01534565bdd6eb0b5a81c432e39f0977ab6e165d88ee8",
    lords_erc20_mintable:
      "0x059dac5df32cbce17b081399e97d90be5fba726f97f00638f838613d088e5a47",
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
// Penalty time is 8 blocks, where each block is ~ 3 minutes
export const penaltyTime = 12 * (3 * 60);
export const itemCharismaDiscount = 1;
export const itemBasePrice = 4;
export const itemMinimumPrice = 1;
export const potionCharismaDiscount = 2;
export const potionBasePrice = 2;
export const idleDeathPenaltyBlocks = 300;
