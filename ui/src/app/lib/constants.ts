import { constants } from "starknet";
// export const prologue =
//   "In the beginning, echoes of a thousand whispers stirred, breathing life into a mystical force. This force, known as the Adventurer's Will, gave rise to an enigmatic figure destined to navigate the boundless realms of a world shrouded in darkness: the Adventurer. Armed with nothing but their will to survive and a weapon as an extension of their spirit, they found themselves on the brink of an uncharted and forsaken land where the sun no longer graced the sky, and a dying moon cast an eerie glow. Each exploration was a unique labyrinth of trials, treasures, and mythical creatures. As the Adventurer journeyed through these desolate realms, their power grew, their bag filled with enchanted protection - precious loot that empowered them with the strength and wisdom needed to confront the lurking horrors. Beasts of unimaginable terror, each bearing unique attacks, weapons, and armor, roamed these lands, turning every encounter into a choice between battle and flight, a calculated risk between survival and demise. The veil between the living and the dead had grown thin in this forsaken world, allowing malevolent beings to wreak havoc upon the remnants. Amidst the chaos and looming dread, a desperate hope flickered in the hearts of the survivors, tethered to an ancient prophecy whispering of a chosen one who would restore balance. Relying on their cunning and resourcefulness, growing stronger with each fall and rising, fueled by the knowledge and experiences of their past lives. And so, the question remains: will the Adventurer fulfill their destiny as the harbinger of hope, or succumb to the encroaching darkness that threatens to consume all that remains?";
export const prologue =
  "In a world devoid of sun, teetering on annihilation, humanity clings to an archaic prophecy of a savior restoring balance.";
export const chapter1 =
  "An adventurer stirs from slumber in the cold, dank cave. Disoriented, they scour the darkness, the only sound a dripping echo and the biting whisper of wind.";
export const chapter2 =
  "Where? How? Water whispers nearby. They move, reaching through the mist. Suddenly, a fountain materializes, an ethereal sentinel obscured by the swirling vapor.";
export const chapter3 =
  "Intrigued, they draw closer, their form dancing on the water's surface. Four oddities lie within - a wand, a book, a club, and a sword. Selecting one, the others dissolve, leaving an unnerving hush in their wake.";
export const chapter4 =
  "They find golden coins in their pocket, glimmering in the dim light - an enigma wrapped in the shroud of the unexpected.";
export const battle =
  "A beast lurks in the shadow, the time for battle is nigh.";

export const mainnet_addr = "https://alpha-mainnet.starknet.io";

export function getGraphQLUrl() {
  switch (process.env.NEXT_PUBLIC_NETWORK) {
    case "dev":
      return "https://p01--loot-survivor-graphql--cwpz4gs4p7vn.code.run/goerli-graphql";
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
    game: "0x071ef5e6d758ad81d8754c0fd6123018388d6dfb53965fae291c498858186ef6",
    lords_erc20_mintable:
      "0x059dac5df32cbce17b081399e97d90be5fba726f97f00638f838613d088e5a47",
  },
};

export const appUrl = "https://beta-survivor.realms.world/";

// ---- CONTRACT PARAMS
// Penalty time is 8 blocks, where each block is ~ 3 minutes
export const penaltyTime = 16 * (3 * 60);
export const itemCharismaDiscount = 1;
export const itemBasePrice = 4;
export const itemMinimumPrice = 1;
export const potionCharismaDiscount = 2;
export const potionBasePrice = 2;
export const idleDeathPenaltyBlocks = 300;
