import type { Config } from "https://esm.sh/@apibara/indexer";
import type { Block, Starknet } from "https://esm.sh/@apibara/indexer/starknet";
import type { Mongo } from "https://esm.sh/@apibara/indexer/sink/mongo";
import type { Console } from "https://esm.sh/@apibara/indexer/sink/console";
import {
  ADVENTURER_UPGRADED,
  DISCOVERED_GOLD,
  DISCOVERED_HEALTH,
  DISCOVERED_XP,
  parseAdventurerUpgraded,
  parseDiscoveredGold,
  parseDiscoveredHealth,
  parseDiscoveredXp,
  parseStartGame,
  START_GAME,
  PURCHASED_POTIONS,
  PURCHASED_ITEMS,
  ATTACKED_BY_BEAST,
  ADVENTURER_DIED,
  parseAdventurerDied,
  parseAttackedByBeast,
  AMBUSHED_BY_BEAST,
  parseAmbushedByBeast,
  ATTACKED_BEAST,
  SLAYED_BEAST,
  parseSlayedBeast,
  FLEE_FAILED,
  parseFleeFailed,
  FLEE_SUCCEEDED,
  parseFleeSucceeded,
  ITEMS_LEVELED_UP,
  parseItemsLeveledUp,
  EQUIPPED_ITEMS,
  parsePurchasedItems,
  parseEquippedItems,
  DROPPED_ITEMS,
  parseDroppedItems,
  HIT_BY_OBSTACLE,
  parseHitByObstacle,
  DODGED_OBSTACLE,
  parseDodgedObstacle,
  UPGRADES_AVAILABLE,
  parseUpgradesAvailable,
  DISCOVERED_BEAST,
  parseDiscoveredBeast,
} from "./utils/events.ts";
import { insertAdventurer, updateAdventurer } from "./utils/helpers.ts";
import { MONGO_CONNECTION_STRING } from "./utils/constants.ts";

const GAME = Deno.env.get("GAME");
const START = +(Deno.env.get("START") || 0);
const STREAM_URL = Deno.env.get("STREAM_URL");
const MONGO_DB = Deno.env.get("MONGO_DB");

const filter = {
  header: { weak: true },
  events: [
    { fromAddress: GAME, keys: [START_GAME] },
    { fromAddress: GAME, keys: [ADVENTURER_UPGRADED] },
    { fromAddress: GAME, keys: [DISCOVERED_HEALTH] },
    { fromAddress: GAME, keys: [DISCOVERED_GOLD] },
    { fromAddress: GAME, keys: [DISCOVERED_XP] },
    { fromAddress: GAME, keys: [DODGED_OBSTACLE] },
    { fromAddress: GAME, keys: [HIT_BY_OBSTACLE] },
    { fromAddress: GAME, keys: [DISCOVERED_BEAST] },
    { fromAddress: GAME, keys: [PURCHASED_POTIONS] },
    { fromAddress: GAME, keys: [PURCHASED_ITEMS] },
    { fromAddress: GAME, keys: [EQUIPPED_ITEMS] },
    { fromAddress: GAME, keys: [DROPPED_ITEMS] },
    { fromAddress: GAME, keys: [ATTACKED_BEAST] },
    { fromAddress: GAME, keys: [ATTACKED_BY_BEAST] },
    { fromAddress: GAME, keys: [AMBUSHED_BY_BEAST] },
    { fromAddress: GAME, keys: [SLAYED_BEAST] },
    { fromAddress: GAME, keys: [ADVENTURER_DIED] },
    { fromAddress: GAME, keys: [FLEE_FAILED] },
    { fromAddress: GAME, keys: [FLEE_SUCCEEDED] },
    { fromAddress: GAME, keys: [ITEMS_LEVELED_UP] },
    { fromAddress: GAME, keys: [UPGRADES_AVAILABLE] },
  ],
};

export const config: Config<Starknet, Mongo | Console> = {
  streamUrl: STREAM_URL,
  network: "starknet",
  filter,
  startingBlock: START,
  finality: "DATA_STATUS_PENDING",
  sinkType: "mongo",
  sinkOptions: {
    connectionString: MONGO_CONNECTION_STRING,
    database: MONGO_DB,
    collectionName: "adventurers",
    // @ts-ignore - indexer package not updated
    entityMode: true,
  },
};

export default function transform({ header, events }: Block) {
  return events.flatMap(({ event }) => {
    switch (event.keys[0]) {
      case START_GAME: {
        console.log("START_GAME", "->", "ADVENTURER UPDATES");
        const { value } = parseStartGame(event.data, 0);
        const as = value.adventurerState;
        const am = value.adventurerMeta;
        return [
          insertAdventurer({
            id: as.adventurerId,
            owner: as.owner,
            lastAction: as.adventurer.lastActionBlock,
            health: as.adventurer.health,
            xp: as.adventurer.xp,
            strength: as.adventurer.stats.strength,
            dexterity: as.adventurer.stats.dexterity,
            vitality: as.adventurer.stats.vitality,
            intelligence: as.adventurer.stats.intelligence,
            wisdom: as.adventurer.stats.wisdom,
            charisma: as.adventurer.stats.charisma,
            luck: as.adventurer.stats.luck,
            gold: as.adventurer.gold,
            weapon: as.adventurer.weapon.id,
            chest: as.adventurer.chest.id,
            head: as.adventurer.head.id,
            waist: as.adventurer.waist.id,
            foot: as.adventurer.foot.id,
            hand: as.adventurer.hand.id,
            neck: as.adventurer.neck.id,
            ring: as.adventurer.ring.id,
            beastHealth: as.adventurer.beastHealth,
            statUpgrades: as.adventurer.statsPointsAvailable,
            actionsPerBlock: as.adventurer.actionsPerBlock,
            name: am.name,
            startBlock: am.startBlock,
            revealBlock: value.revealBlock,
            createdTime: new Date().toISOString(),
            lastUpdatedTime: new Date().toISOString(),
            timestamp: new Date().toISOString(),
          }),
        ];
      }
      case ADVENTURER_UPGRADED: {
        console.log("ADVENTURER_UPGRADED", "->", "ADVENTURER UPDATES");
        const { value } = parseAdventurerUpgraded(event.data, 0);
        return [
          updateAdventurer({
            adventurerState: value.adventurerStateWithBag.adventurerState,
            timestamp: new Date().toISOString(),
          }),
        ];
      }
      case DISCOVERED_HEALTH: {
        console.log("DISCOVERED_HEALTH", "->", "ADVENTURER UPDATES");
        const { value } = parseDiscoveredHealth(event.data, 0);
        return [
          updateAdventurer({
            timestamp: new Date().toISOString(),
            adventurerState: value.adventurerState,
          }),
        ];
      }
      case DISCOVERED_GOLD: {
        console.log("DISCOVERED_GOLD", "->", "ADVENTURER UPDATES");
        const { value } = parseDiscoveredGold(event.data, 0);
        return [
          updateAdventurer({
            timestamp: new Date().toISOString(),
            adventurerState: value.adventurerState,
          }),
        ];
      }
      case DISCOVERED_XP: {
        console.log("DISCOVERED_XP", "->", "ADVENTURER UPDATES");
        const { value } = parseDiscoveredXp(event.data, 0);
        return [
          updateAdventurer({
            timestamp: new Date().toISOString(),
            adventurerState: value.adventurerState,
          }),
        ];
      }
      case DODGED_OBSTACLE: {
        console.log("DODGED_OBSTACLE", "->", "ADVENTURER UPDATES");
        const { value } = parseDodgedObstacle(event.data, 0);
        return [
          updateAdventurer({
            timestamp: new Date().toISOString(),
            adventurerState: value.adventurerState,
          }),
        ];
      }
      case HIT_BY_OBSTACLE: {
        console.log("HIT_BY_OBSTACLE", "->", "ADVENTURER UPDATES");
        const { value } = parseHitByObstacle(event.data, 0);
        return [
          updateAdventurer({
            timestamp: new Date().toISOString(),
            adventurerState: value.adventurerState,
          }),
        ];
      }
      case DISCOVERED_BEAST: {
        console.log("DISCOVERED_BEAST", "->", "ADVENTURER UPDATES");
        const { value } = parseDiscoveredBeast(event.data, 0);
        return [
          updateAdventurer({
            timestamp: new Date().toISOString(),
            adventurerState: value.adventurerState,
          }),
        ];
      }
      case PURCHASED_POTIONS: {
        console.log("PURCHASED_POTIONS", "->", "ADVENTURER UPDATES");
        const { value } = parseDiscoveredXp(event.data, 0);
        return [
          updateAdventurer({
            timestamp: new Date().toISOString(),
            adventurerState: value.adventurerState,
          }),
        ];
      }
      case PURCHASED_ITEMS: {
        console.log("PURCHASED_ITEMS", "->", "ADVENTURER UPDATES");
        const { value } = parsePurchasedItems(event.data, 0);
        return [
          updateAdventurer({
            timestamp: new Date().toISOString(),
            adventurerState: value.adventurerStateWithBag.adventurerState,
          }),
        ];
      }
      case EQUIPPED_ITEMS: {
        console.log("EQUIPPED_ITEMS", "->", "ADVENTURER UPDATES");
        const { value } = parseEquippedItems(event.data, 0);
        return [
          updateAdventurer({
            timestamp: new Date().toISOString(),
            adventurerState: value.adventurerStateWithBag.adventurerState,
          }),
        ];
      }
      case DROPPED_ITEMS: {
        console.log("DROPPED_ITEMS", "->", "ADVENTURER UPDATES");
        const { value } = parseDroppedItems(event.data, 0);
        return [
          updateAdventurer({
            timestamp: new Date().toISOString(),
            adventurerState: value.adventurerStateWithBag.adventurerState,
          }),
        ];
      }
      case ATTACKED_BEAST: {
        console.log("ATTACKED_BEAST", "->", "ADVENTURER UPDATES");
        const { value } = parseAttackedByBeast(event.data, 0);
        return [
          updateAdventurer({
            timestamp: new Date().toISOString(),
            adventurerState: value.adventurerState,
          }),
        ];
      }
      case ATTACKED_BY_BEAST: {
        console.log("ATTACKED_BY_BEAST", "->", "ADVENTURER UPDATES");
        const { value } = parseAttackedByBeast(event.data, 0);
        return [
          updateAdventurer({
            timestamp: new Date().toISOString(),
            adventurerState: value.adventurerState,
          }),
        ];
      }
      case AMBUSHED_BY_BEAST: {
        console.log("AMBUSHED_BY_BEAST", "->", "ADVENTURER UPDATES");
        const { value } = parseAmbushedByBeast(event.data, 0);
        return [
          updateAdventurer({
            timestamp: new Date().toISOString(),
            adventurerState: value.adventurerState,
          }),
        ];
      }
      case SLAYED_BEAST: {
        console.log("SLAYED_BEAST", "->", "ADVENTURER UPDATES");
        const { value } = parseSlayedBeast(event.data, 0);
        return [
          updateAdventurer({
            timestamp: new Date().toISOString(),
            adventurerState: value.adventurerState,
          }),
        ];
      }
      case ADVENTURER_DIED: {
        console.log("ADVENTURER_DIED", "->", "ADVENTURER UPDATES");
        const { value } = parseAdventurerDied(event.data, 0);
        return [
          updateAdventurer({
            timestamp: new Date().toISOString(),
            adventurerState: value.adventurerState,
          }),
        ];
      }
      case FLEE_FAILED: {
        console.log("FLEE_FAILED", "->", "ADVENTURER UPDATES");
        const { value } = parseFleeFailed(event.data, 0);
        return [
          updateAdventurer({
            timestamp: new Date().toISOString(),
            adventurerState: value.adventurerState,
          }),
        ];
      }
      case FLEE_SUCCEEDED: {
        console.log("FLEE_SUCCEEDED", "->", "ADVENTURER UPDATES");
        const { value } = parseFleeSucceeded(event.data, 0);
        return [
          updateAdventurer({
            timestamp: new Date().toISOString(),
            adventurerState: value.adventurerState,
          }),
        ];
      }
      case ITEMS_LEVELED_UP: {
        console.log("ITEMS_LEVELED_UP", "->", "ADVENTURER UPDATES");
        const { value } = parseItemsLeveledUp(event.data, 0);
        return [
          updateAdventurer({
            timestamp: new Date().toISOString(),
            adventurerState: value.adventurerState,
          }),
        ];
      }
      case UPGRADES_AVAILABLE: {
        console.log("UPGRADES_AVAILABLE", "->", "ADVENTURER UPDATES");
        const { value } = parseUpgradesAvailable(event.data, 0);
        return [
          updateAdventurer({
            timestamp: new Date().toISOString(),
            adventurerState: value.adventurerState,
          }),
        ];
      }
      default: {
        console.warn("Unknown event", event.keys[0]);
        return [];
      }
    }
  });
}
