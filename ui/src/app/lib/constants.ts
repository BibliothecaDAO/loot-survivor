// export const prologue =
//   "In the beginning, echoes of a thousand whispers stirred, breathing life into a mystical force. This force, known as the Adventurer's Will, gave rise to an enigmatic figure destined to navigate the boundless realms of a world shrouded in darkness: the Adventurer. Armed with nothing but their will to survive and a weapon as an extension of their spirit, they found themselves on the brink of an uncharted and forsaken land where the sun no longer graced the sky, and a dying moon cast an eerie glow. Each exploration was a unique labyrinth of trials, treasures, and mythical creatures. As the Adventurer journeyed through these desolate realms, their power grew, their bag filled with enchanted protection - precious loot that empowered them with the strength and wisdom needed to confront the lurking horrors. Beasts of unimaginable terror, each bearing unique attacks, weapons, and armor, roamed these lands, turning every encounter into a choice between battle and flight, a calculated risk between survival and demise. The veil between the living and the dead had grown thin in this forsaken world, allowing malevolent beings to wreak havoc upon the remnants. Amidst the chaos and looming dread, a desperate hope flickered in the hearts of the survivors, tethered to an ancient prophecy whispering of a chosen one who would restore balance. Relying on their cunning and resourcefulness, growing stronger with each fall and rising, fueled by the knowledge and experiences of their past lives. And so, the question remains: will the Adventurer fulfill their destiny as the harbinger of hope, or succumb to the encroaching darkness that threatens to consume all that remains?";
export const prologue =
  "In a sunless world teetering on the brink of destruction, humanity clings to an ancient prophecy of a chosen one bringing balance.";
export const chapter1 =
  "In the chilling embrace of the cave, an adventurer stirs awake. Confused, disoriented, their eyes dart across the darkness, searching. The echo of water dripping and the chilling wind fill the air.";
export const chapter2 = "Where is this place? How did you get here? Water trickles nearby. You move toward the sound. A thick mist prevents you from seeing much further than your outstretched hands. After a moment, you come upon a fountain. It stands here, spectral, shrouded in mist."
export const chapter3 = "Curiosity piqued, the adventurer approaches, their silhouette reflecting in the hypnotizing water. A mystical fountain with four peculiar items resting on the bottom - a wand, a book, a club, and a sword. They reach in, pulling out a weapon. The remaining items appear to dissolve into the water, leaving behind an unsettling silence."
export const chapter4 = "The adventurer notices they have something in their pocket, reaches in and pulls out a handful of golden coins that shimmer even in the dim light. An unexpected surprise. A mystery."
export const battle = "Oh no, there's a beast coming! Prepare for attack!";

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
    game: "0x068f2b40d1520593f7ad2718c4d7d220ab1028a43ea48e477c31991262178ee3",
    lords_erc20_mintable:
      "0x059dac5df32cbce17b081399e97d90be5fba726f97f00638f838613d088e5a47",
  },
};

export const appUrl = "https://survivor.vercel.app/";

// Penalty time is 3 blocks, where each block is ~ 3 minutes
export const penaltyTime = 3 * (3 * 60);
