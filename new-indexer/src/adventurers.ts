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
    database: "loot_example",
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
        // console.log("Start game", value);
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
            weapon: as.adventurer.weapon,
            chest: as.adventurer.chest,
            head: as.adventurer.head,
            waist: as.adventurer.waist,
            foot: as.adventurer.foot,
            hand: as.adventurer.hand,
            neck: as.adventurer.neck,
            ring: as.adventurer.ring,
            beastHealth: as.adventurer.beastHealth,
            statUpgrades: as.adventurer.statsPointsAvailable,
            name: am.name,
            homeRealm: am.homeRealm,
            classType: am.class,
            entropy: am.entropy,
            createdTime: timestamp,
            lastUpdatedTime: timestamp,
            timestamp,
          }),
        ];
      }
      case ADVENTURER_UPGRADED: {
        const { value } = parseAdventurerUpgraded(event.data, 0);
        return [
          updateAdventurer({
            adventurerState: value.adventurerStateWithBag.adventurerState,
            timestamp,
          }),
        ];
      }
      case DISCOVERED_HEALTH: {
        const { value } = parseDiscoveredHealth(event.data, 0);
        return [
          updateAdventurer({
            timestamp,
            adventurerState: value.adventurerState,
          }),
        ];
      }
      case DISCOVERED_GOLD: {
        const { value } = parseDiscoveredGold(event.data, 0);
        return [
          updateAdventurer({
            timestamp,
            adventurerState: value.adventurerState,
          }),
        ];
      }
      case DISCOVERED_XP: {
        const { value } = parseDiscoveredXp(event.data, 0);
        return [
          updateAdventurer({
            timestamp,
            adventurerState: value.adventurerState,
          }),
        ];
      }
      case PURCHASED_POTIONS: {
        const { value } = parseDiscoveredXp(event.data, 0);
        return [
          updateAdventurer({
            timestamp,
            adventurerState: value.adventurerState,
          }),
        ];
      }
      case PURCHASED_ITEMS: {
        const { value } = parseDiscoveredXp(event.data, 0);
        return [
          updateAdventurer({
            timestamp,
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
