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
  ITEM_SPECIAL_UNLOCKED,
  parseItemSpecialUnlocked,
  EQUIPPED_ITEMS,
  parsePurchasedItems,
  parseEquippedItems,
  DROPPED_ITEMS,
  parseDroppedItems,
  HIT_BY_OBSTACLE,
  parseHitByObstacle,
  DODGED_OBSTACLE,
  parseDodgedObstacle,
  NEW_ITEMS_AVAILABLE,
  parseNewItemsAvailable,
} from "./utils/events.ts";
import { insertAdventurer, updateAdventurer } from "./utils/helpers.ts";

const GAME = Deno.env.get("GAME");
const START = +(Deno.env.get("START") || 0);

const filter = {
  header: { weak: true },
  events: [
    { fromAddress: GAME, keys: [START_GAME] },
    { fromAddress: GAME, keys: [ADVENTURER_UPGRADED] },
    { fromAddress: GAME, keys: [DISCOVERED_HEALTH] },
    { fromAddress: GAME, keys: [DISCOVERED_GOLD] },
    { fromAddress: GAME, keys: [DISCOVERED_XP] },
    { fromAddress: GAME, keys: [ATTACKED_BY_BEAST] },
    { fromAddress: GAME, keys: [ADVENTURER_DIED] },
  ],
};

export const config: Config<Starknet, Mongo | Console> = {
  streamUrl: "https://goerli.starknet.a5a.ch",
  network: "starknet",
  filter,
  startingBlock: START,
  finality: "DATA_STATUS_PENDING",
  sinkType: "mongo",
  sinkOptions: {
    database: "mongo_goerli",
    collectionName: "adventurers",
    // @ts-ignore - indexer package not updated
    entityMode: true,
  },
};

export default function transform({ header, events }: Block) {
  const { timestamp } = header!;

  return events.flatMap(({ event }) => {
    switch (event.keys[0]) {
      case START_GAME: {
        const { value } = parseStartGame(event.data, 0);
        const as = value.adventurerState;
        const am = value.adventurerMeta;
        return [
          insertAdventurer({
            id: as.adventurerId,
            owner: as.owner,
            lastAction: as.adventurer.lastAction,
            health: as.adventurer.health,
            xp: as.adventurer.xp,
            strength: as.adventurer.stats.strength,
            dexterity: as.adventurer.stats.dexterity,
            vitality: as.adventurer.stats.vitality,
            intelligence: as.adventurer.stats.intelligence,
            wisdom: as.adventurer.stats.wisdom,
            charisma: as.adventurer.stats.charisma,
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
            name: am.name,
            homeRealm: am.homeRealm,
            classType: am.class,
            entropy: am.entropy,
            createdTime: new Date().toISOString(),
            lastUpdatedTime: new Date().toISOString(),
            timestamp: new Date().toISOString(),
          }),
        ];
      }
      case ADVENTURER_UPGRADED: {
        const { value } = parseAdventurerUpgraded(event.data, 0);
        return [
          updateAdventurer({
            adventurerState: value.adventurerStateWithBag.adventurerState,
            timestamp: new Date().toISOString(),
          }),
        ];
      }
      case DISCOVERED_HEALTH: {
        const { value } = parseDiscoveredHealth(event.data, 0);
        return [
          updateAdventurer({
            timestamp: new Date().toISOString(),
            adventurerState: value.adventurerState,
          }),
        ];
      }
      case DISCOVERED_GOLD: {
        const { value } = parseDiscoveredGold(event.data, 0);
        return [
          updateAdventurer({
            timestamp: new Date().toISOString(),
            adventurerState: value.adventurerState,
          }),
        ];
      }
      case DISCOVERED_XP: {
        const { value } = parseDiscoveredXp(event.data, 0);
        return [
          updateAdventurer({
            timestamp: new Date().toISOString(),
            adventurerState: value.adventurerState,
          }),
        ];
      }
      case DODGED_OBSTACLE: {
        const { value } = parseDodgedObstacle(event.data, 0);
        return [
          updateAdventurer({
            timestamp: new Date().toISOString(),
            adventurerState: value.adventurerState,
          }),
        ];
      }
      case HIT_BY_OBSTACLE: {
        const { value } = parseHitByObstacle(event.data, 0);
        return [
          updateAdventurer({
            timestamp: new Date().toISOString(),
            adventurerState: value.adventurerState,
          }),
        ];
      }
      case PURCHASED_POTIONS: {
        const { value } = parseDiscoveredXp(event.data, 0);
        return [
          updateAdventurer({
            timestamp: new Date().toISOString(),
            adventurerState: value.adventurerState,
          }),
        ];
      }
      case PURCHASED_ITEMS: {
        const { value } = parsePurchasedItems(event.data, 0);
        return [
          updateAdventurer({
            timestamp: new Date().toISOString(),
            adventurerState: value.adventurerStateWithBag.adventurerState,
          }),
        ];
      }
      case EQUIPPED_ITEMS: {
        const { value } = parseEquippedItems(event.data, 0);
        return [
          updateAdventurer({
            timestamp: new Date().toISOString(),
            adventurerState: value.adventurerStateWithBag.adventurerState,
          }),
        ];
      }
      case DROPPED_ITEMS: {
        const { value } = parseDroppedItems(event.data, 0);
        return [
          updateAdventurer({
            timestamp: new Date().toISOString(),
            adventurerState: value.adventurerStateWithBag.adventurerState,
          }),
        ];
      }
      case ATTACKED_BEAST: {
        const { value } = parseAttackedByBeast(event.data, 0);
        return [
          updateAdventurer({
            timestamp: new Date().toISOString(),
            adventurerState: value.adventurerState,
          }),
        ];
      }
      case ATTACKED_BY_BEAST: {
        const { value } = parseAttackedByBeast(event.data, 0);
        return [
          updateAdventurer({
            timestamp: new Date().toISOString(),
            adventurerState: value.adventurerState,
          }),
        ];
      }
      case AMBUSHED_BY_BEAST: {
        const { value } = parseAmbushedByBeast(event.data, 0);
        return [
          updateAdventurer({
            timestamp: new Date().toISOString(),
            adventurerState: value.adventurerState,
          }),
        ];
      }
      case SLAYED_BEAST: {
        const { value } = parseSlayedBeast(event.data, 0);
        return [
          updateAdventurer({
            timestamp: new Date().toISOString(),
            adventurerState: value.adventurerState,
          }),
        ];
      }
      case ADVENTURER_DIED: {
        const { value } = parseAdventurerDied(event.data, 0);
        return [
          updateAdventurer({
            timestamp: new Date().toISOString(),
            adventurerState: value.adventurerState,
          }),
        ];
      }
      case FLEE_FAILED: {
        const { value } = parseFleeFailed(event.data, 0);
        return [
          updateAdventurer({
            timestamp: new Date().toISOString(),
            adventurerState: value.adventurerState,
          }),
        ];
      }
      case FLEE_SUCCEEDED: {
        const { value } = parseFleeSucceeded(event.data, 0);
        return [
          updateAdventurer({
            timestamp: new Date().toISOString(),
            adventurerState: value.adventurerState,
          }),
        ];
      }
      case ITEM_SPECIAL_UNLOCKED: {
        const { value } = parseItemSpecialUnlocked(event.data, 0);
        return [
          updateAdventurer({
            timestamp: new Date().toISOString(),
            adventurerState: value.adventurerState,
          }),
        ];
      }
      case NEW_ITEMS_AVAILABLE: {
        const { value } = parseNewItemsAvailable(event.data, 0);
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
