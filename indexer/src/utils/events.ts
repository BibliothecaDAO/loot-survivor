import { hash } from "https://esm.sh/starknet@5.19.5";

import {
  combineParsers,
  parseArray,
  parseBoolean,
  parseFelt252,
  parseU128,
  parseU16,
  parseU256,
  parseU64,
  parseU8,
} from "./parser.ts";

// Get hash of name, and zero-pad it to 32 bytes.
function eventKey(name: string) {
  const h = BigInt(hash.getSelectorFromName(name));
  return `0x${h.toString(16).padStart(64, "0")}`;
}

export const START_GAME = eventKey("StartGame");
export const ADVENTURER_UPGRADED = eventKey("AdventurerUpgraded");
export const DISCOVERED_HEALTH = eventKey("DiscoveredHealth");
export const DISCOVERED_GOLD = eventKey("DiscoveredGold");
export const DISCOVERED_XP = eventKey("DiscoveredXP");
export const HIT_BY_OBSTACLE = eventKey("HitByObstacle");
export const DODGED_OBSTACLE = eventKey("DodgedObstacle");

export const DISCOVERED_BEAST = eventKey("DiscoveredBeast");
export const AMBUSHED_BY_BEAST = eventKey("AmbushedByBeast");
export const ATTACKED_BEAST = eventKey("AttackedBeast");
export const ATTACKED_BY_BEAST = eventKey("AttackedByBeast");
export const SLAYED_BEAST = eventKey("SlayedBeast");

export const ADVENTURER_DIED = eventKey("AdventurerDied");

export const FLEE_FAILED = eventKey("FleeFailed");
export const FLEE_SUCCEEDED = eventKey("FleeSucceeded");

export const PURCHASED_POTIONS = eventKey("PurchasedPotions");
export const PURCHASED_ITEMS = eventKey("PurchasedItems");
export const UPGRADES_AVAILABLE = eventKey("UpgradesAvailable");
export const EQUIPPED_ITEMS = eventKey("EquippedItems");
export const DROPPED_ITEMS = eventKey("DroppedItems");
export const ITEMS_LEVELED_UP = eventKey("ItemsLeveledUp");

export const NEW_HIGH_SCORE = eventKey("NewHighScore");
export const REWARD_DISTRIBUTION = eventKey("RewardDistribution");
export const GAME_ENTROPY_ROTATED = eventKey("GameEntropyRotatedEvent");

export const parseStats = combineParsers({
  strength: { index: 0, parser: parseU8 },
  dexterity: { index: 1, parser: parseU8 },
  vitality: { index: 2, parser: parseU8 },
  intelligence: { index: 3, parser: parseU8 },
  wisdom: { index: 4, parser: parseU8 },
  charisma: { index: 5, parser: parseU8 },
  luck: { index: 6, parser: parseU8 },
});

export const parseLootStatistics = combineParsers({
  id: { index: 0, parser: parseU8 },
  xp: { index: 1, parser: parseU16 },
  metadata: { index: 2, parser: parseU8 },
});

export const parseLoot = combineParsers({
  id: { index: 0, parser: parseU8 },
  tier: { index: 1, parser: parseU16 },
  itemType: { index: 2, parser: parseU8 },
  slot: { index: 3, parser: parseU8 },
});

export const parseLootWithPrice = combineParsers({
  item: { index: 0, parser: parseLoot },
  price: { index: 1, parser: parseU16 },
});

export const parseAdventurer = combineParsers({
  lastActionBlock: { index: 0, parser: parseU16 },
  health: { index: 1, parser: parseU16 },
  xp: { index: 2, parser: parseU16 },
  stats: { index: 3, parser: parseStats },
  gold: { index: 4, parser: parseU16 },
  weapon: { index: 5, parser: parseLootStatistics },
  chest: { index: 6, parser: parseLootStatistics },
  head: { index: 7, parser: parseLootStatistics },
  waist: { index: 8, parser: parseLootStatistics },
  foot: { index: 9, parser: parseLootStatistics },
  hand: { index: 10, parser: parseLootStatistics },
  neck: { index: 11, parser: parseLootStatistics },
  ring: { index: 12, parser: parseLootStatistics },
  beastHealth: { index: 13, parser: parseU16 },
  statsPointsAvailable: { index: 14, parser: parseU8 },
  actionsPerBlock: { index: 15, parser: parseU8 },
  mutated: { index: 16, parser: parseBoolean },
});

export const parseAdventurerState = combineParsers({
  owner: { index: 0, parser: parseFelt252 },
  adventurerId: { index: 1, parser: parseFelt252 },
  adventurer: { index: 2, parser: parseAdventurer },
});

export const parseSpecialPowers = combineParsers({
  special1: { index: 0, parser: parseU8 },
  special2: { index: 1, parser: parseU8 },
  special3: { index: 2, parser: parseU8 },
});

export const parseCombatSpec = combineParsers({
  tier: { index: 0, parser: parseU8 },
  itemType: { index: 1, parser: parseU8 },
  level: { index: 2, parser: parseU16 },
  specials: { index: 3, parser: parseSpecialPowers },
});

export const parseDiscoveredBeast = combineParsers({
  adventurerState: { index: 0, parser: parseAdventurerState },
  seed: { index: 1, parser: parseU128 },
  id: { index: 2, parser: parseU8 },
  beastSpec: { index: 3, parser: parseCombatSpec },
});

export const parseAmbushedByBeast = combineParsers({
  adventurerState: { index: 0, parser: parseAdventurerState },
  seed: { index: 1, parser: parseU128 },
  id: { index: 2, parser: parseU8 },
  beastSpec: { index: 3, parser: parseCombatSpec },
  damage: { index: 4, parser: parseU16 },
  criticalHit: { index: 5, parser: parseBoolean },
  location: { index: 6, parser: parseU8 },
});

export const parseAttackedBeast = combineParsers({
  adventurerState: { index: 0, parser: parseAdventurerState },
  seed: { index: 1, parser: parseU128 },
  id: { index: 2, parser: parseU8 },
  beastSpec: { index: 3, parser: parseCombatSpec },
  damage: { index: 4, parser: parseU16 },
  criticalHit: { index: 5, parser: parseBoolean },
  location: { index: 6, parser: parseU8 },
});

export const parseAttackedByBeast = combineParsers({
  adventurerState: { index: 0, parser: parseAdventurerState },
  seed: { index: 1, parser: parseU128 },
  id: { index: 2, parser: parseU8 },
  beastSpec: { index: 3, parser: parseCombatSpec },
  damage: { index: 4, parser: parseU16 },
  criticalHit: { index: 5, parser: parseBoolean },
  location: { index: 6, parser: parseU8 },
});

export const parseSlayedBeast = combineParsers({
  adventurerState: { index: 0, parser: parseAdventurerState },
  seed: { index: 1, parser: parseU128 },
  id: { index: 2, parser: parseU8 },
  beastSpec: { index: 3, parser: parseCombatSpec },
  damageDealt: { index: 4, parser: parseU16 },
  criticalHit: { index: 5, parser: parseBoolean },
  xpEarnedAdventurer: { index: 6, parser: parseU16 },
  xpEarnedItems: { index: 7, parser: parseU16 },
  goldEarned: { index: 8, parser: parseU16 },
});

export const parseAdventurerDied = combineParsers({
  adventurerState: { index: 0, parser: parseAdventurerState },
  killedByBeast: { index: 1, parser: parseU8 },
  killedByObstacle: { index: 2, parser: parseU8 },
  callerAddress: { index: 3, parser: parseFelt252 },
});

export const parseAdventurerMetadata = combineParsers({
  startBlock: { index: 0, parser: parseU128 },
  startingStats: { index: 1, parser: parseStats },
  name: { index: 2, parser: parseU128 },
  interfaceCamel: { index: 3, parser: parseBoolean },
});

export const parseStartGame = combineParsers({
  adventurerState: { index: 0, parser: parseAdventurerState },
  adventurerMeta: { index: 1, parser: parseAdventurerMetadata },
  revealBlock: { index: 2, parser: parseU64 },
});

export const parseBag = combineParsers({
  item1: { index: 0, parser: parseLootStatistics },
  item2: { index: 1, parser: parseLootStatistics },
  item3: { index: 2, parser: parseLootStatistics },
  item4: { index: 3, parser: parseLootStatistics },
  item5: { index: 4, parser: parseLootStatistics },
  item6: { index: 5, parser: parseLootStatistics },
  item7: { index: 6, parser: parseLootStatistics },
  item8: { index: 7, parser: parseLootStatistics },
  item9: { index: 8, parser: parseLootStatistics },
  item10: { index: 9, parser: parseLootStatistics },
  item11: { index: 10, parser: parseLootStatistics },
  mutated: { index: 11, parser: parseBoolean },
});

export const parseAdventurerStateWithBag = combineParsers({
  adventurerState: { index: 0, parser: parseAdventurerState },
  bag: { index: 1, parser: parseBag },
});

export const parseAdventurerUpgraded = combineParsers({
  adventurerStateWithBag: { index: 0, parser: parseAdventurerStateWithBag },
  strengthIncrease: { index: 1, parser: parseU8 },
  dexterityIncrease: { index: 2, parser: parseU8 },
  vitalityIncrease: { index: 3, parser: parseU8 },
  intelligenceIncrease: { index: 4, parser: parseU8 },
  wisdomIncrease: { index: 5, parser: parseU8 },
  charismaIncrease: { index: 6, parser: parseU8 },
});

export const parseDiscoveredHealth = combineParsers({
  adventurerState: { index: 0, parser: parseAdventurerState },
  healthAmount: { index: 1, parser: parseU16 },
});

export const parseDiscoveredGold = combineParsers({
  adventurerState: { index: 0, parser: parseAdventurerState },
  goldAmount: { index: 1, parser: parseU16 },
});

export const parseDiscoveredXp = combineParsers({
  adventurerState: { index: 0, parser: parseAdventurerState },
  xpAmount: { index: 1, parser: parseU16 },
});

export const parseHitByObstacle = combineParsers({
  adventurerState: { index: 0, parser: parseAdventurerState },
  id: { index: 1, parser: parseU8 },
  level: { index: 2, parser: parseU8 },
  damageTaken: { index: 3, parser: parseU16 },
  damageLocation: { index: 4, parser: parseU8 },
  xpEarnedAdventurer: { index: 5, parser: parseU16 },
  xpEarnedItems: { index: 6, parser: parseU16 },
});

export const parseDodgedObstacle = combineParsers({
  adventurerState: { index: 0, parser: parseAdventurerState },
  id: { index: 1, parser: parseU8 },
  level: { index: 2, parser: parseU8 },
  damageTaken: { index: 3, parser: parseU16 },
  damageLocation: { index: 4, parser: parseU8 },
  xpEarnedAdventurer: { index: 5, parser: parseU16 },
  xpEarnedItems: { index: 6, parser: parseU16 },
});

export const parseFleeFailed = combineParsers({
  adventurerState: { index: 0, parser: parseAdventurerState },
  seed: { index: 1, parser: parseU128 },
  id: { index: 2, parser: parseU8 },
  beastSpec: { index: 3, parser: parseCombatSpec },
});

export const parseFleeSucceeded = combineParsers({
  adventurerState: { index: 0, parser: parseAdventurerState },
  seed: { index: 1, parser: parseU128 },
  id: { index: 2, parser: parseU8 },
  beastSpec: { index: 3, parser: parseCombatSpec },
});

export const parsePurchasedPotions = combineParsers({
  adventurerState: { index: 0, parser: parseAdventurerState },
  quantity: { index: 1, parser: parseU8 },
  cost: { index: 2, parser: parseU16 },
  health: { index: 3, parser: parseU16 },
});

export const parsePurchasedItems = combineParsers({
  adventurerStateWithBag: {
    index: 0,
    parser: parseAdventurerStateWithBag,
  },
  purchases: { index: 1, parser: parseArray(parseLootWithPrice) },
});

export const parseEquippedItems = combineParsers({
  adventurerStateWithBag: { index: 0, parser: parseAdventurerStateWithBag },
  equippedItems: { index: 1, parser: parseArray(parseU8) },
  unequippedItems: { index: 2, parser: parseArray(parseU8) },
});

export const parseDroppedItems = combineParsers({
  adventurerStateWithBag: { index: 0, parser: parseAdventurerStateWithBag },
  itemIds: { index: 1, parser: parseArray(parseU8) },
});

export const parseUpgradesAvailable = combineParsers({
  adventurerState: { index: 0, parser: parseAdventurerState },
  items: { index: 1, parser: parseArray(parseU8) },
});

export const parseItemLeveledUp = combineParsers({
  itemId: { index: 0, parser: parseU8 },
  previousLevel: { index: 1, parser: parseU8 },
  newLevel: { index: 2, parser: parseU8 },
  suffixUnlocked: { index: 3, parser: parseBoolean },
  prefixesUnlocked: { index: 4, parser: parseBoolean },
  specials: { index: 5, parser: parseSpecialPowers },
});

export const parseItemsLeveledUp = combineParsers({
  adventurerState: { index: 0, parser: parseAdventurerState },
  items: { index: 1, parser: parseArray(parseItemLeveledUp) },
});

export const parsePlayerReward = combineParsers({
  adventurerId: { index: 0, parser: parseFelt252 },
  rank: { index: 1, parser: parseU8 },
  amount: { index: 2, parser: parseU256 },
  address: { index: 3, parser: parseFelt252 },
});

export const parseClientReward = combineParsers({
  amount: { index: 0, parser: parseU256 },
  address: { index: 0, parser: parseFelt252 },
});

export const parseRewardDistribution = combineParsers({
  firstPlace: { index: 0, parser: parsePlayerReward },
  secondPlace: { index: 1, parser: parsePlayerReward },
  thirdPlace: { index: 2, parser: parsePlayerReward },
  client: { index: 3, parser: parseClientReward },
  dao: { index: 4, parser: parseU256 },
});

export const parseNewHighScore = combineParsers({
  adventurerState: { index: 0, parser: parseAdventurerState },
  rank: { index: 1, parser: parseU8 },
});

export const parseGameEntropyRotated = combineParsers({
  prevHash: { index: 0, parser: parseFelt252 },
  prevBlockNumber: { index: 1, parser: parseU64 },
  prevBlockTimestamp: { index: 2, parser: parseU64 },
  prevNextRotationBlock: { index: 3, parser: parseU64 },
  newHash: { index: 4, parser: parseFelt252 },
  newBlockNumber: { index: 5, parser: parseU64 },
  newBlockTimestamp: { index: 6, parser: parseU64 },
  newNextRotationBlock: { index: 7, parser: parseU64 },
  blocksPerHour: { index: 8, parser: parseU64 },
});
