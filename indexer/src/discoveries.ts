import type { Config } from "https://esm.sh/@apibara/indexer";
import type { Block, Starknet } from "https://esm.sh/@apibara/indexer/starknet";
import type { Mongo } from "https://esm.sh/@apibara/indexer/sink/mongo";
import type { Console } from "https://esm.sh/@apibara/indexer/sink/console";
import {
  AMBUSHED_BY_BEAST,
  DISCOVERED_BEAST,
  DISCOVERED_GOLD,
  DISCOVERED_HEALTH,
  DISCOVERED_XP,
  DODGED_OBSTACLE,
  HIT_BY_OBSTACLE,
  parseAmbushedByBeast,
  parseDiscoveredBeast,
  parseDiscoveredGold,
  parseDiscoveredHealth,
  parseDiscoveredXp,
  parseHitByObstacle,
} from "./utils/events.ts";
import { insertDiscovery } from "./utils/helpers.ts";
import { MONGO_CONNECTION_STRING } from "./utils/constants.ts";

const GAME = Deno.env.get("GAME");
const START = +(Deno.env.get("START") || 0);
const STREAM_URL = Deno.env.get("STREAM_URL");
const MONGO_DB = Deno.env.get("MONGO_DB");

const filter = {
  header: { weak: true },
  events: [
    { fromAddress: GAME, keys: [DISCOVERED_HEALTH] },
    { fromAddress: GAME, keys: [DISCOVERED_GOLD] },
    { fromAddress: GAME, keys: [DISCOVERED_XP] },
    { fromAddress: GAME, keys: [HIT_BY_OBSTACLE] },
    { fromAddress: GAME, keys: [DODGED_OBSTACLE] },
    { fromAddress: GAME, keys: [AMBUSHED_BY_BEAST] },
    { fromAddress: GAME, keys: [DISCOVERED_BEAST] },
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
    collectionName: "discoveries",
    // @ts-ignore - indexer package not updated
    entityMode: true,
  },
};

export default function transform({ header, events }: Block) {
  return events.flatMap(({ event, receipt }) => {
    switch (event.keys[0]) {
      case DISCOVERED_HEALTH: {
        const { value } = parseDiscoveredHealth(event.data, 0);
        const as = value.adventurerState;
        console.log("DISCOVERED_HEALTH", "->", "DISCOVERIES UPDATES");
        return [
          insertDiscovery({
            txHash: receipt.transactionHash,
            adventurerId: as.adventurerId,
            adventurerHealth: as.adventurer.health,
            discoveryType: 3,
            subDiscoveryType: 1,
            outputAmount: value.healthAmount,
            obstacle: 0,
            obstacleLevel: 0,
            dodgedObstacle: false,
            damageTaken: 0,
            damageLocation: 0,
            xpEarnedAdventurer: 0,
            xpEarnedItems: 0,
            entity: 0,
            entityLevel: 0,
            entityHealth: 0,
            special1: 0,
            special2: 0,
            special3: 0,
            ambushed: false,
            seed: 0,
            discoveryTime: new Date().toISOString(),
            timestamp: new Date().toISOString(),
          }),
        ];
      }
      case DISCOVERED_GOLD: {
        const { value } = parseDiscoveredGold(event.data, 0);
        const as = value.adventurerState;
        console.log("DISCOVERED_HEALTH", "->", "DISCOVERIES UPDATES");
        return [
          insertDiscovery({
            txHash: receipt.transactionHash,
            adventurerId: as.adventurerId,
            adventurerHealth: as.adventurer.health,
            discoveryType: 3,
            subDiscoveryType: 1,
            outputAmount: value.goldAmount,
            obstacle: 0,
            obstacleLevel: 0,
            dodgedObstacle: false,
            damageTaken: 0,
            damageLocation: 0,
            xpEarnedAdventurer: 0,
            xpEarnedItems: 0,
            entity: 0,
            entityLevel: 0,
            entityHealth: 0,
            special1: 0,
            special2: 0,
            special3: 0,
            ambushed: false,
            seed: 0,
            discoveryTime: new Date().toISOString(),
            timestamp: new Date().toISOString(),
          }),
        ];
      }
      case DISCOVERED_XP: {
        const { value } = parseDiscoveredXp(event.data, 0);
        const as = value.adventurerState;
        console.log("DISCOVERED_XP", "->", "DISCOVERIES UPDATES");
        return [
          insertDiscovery({
            txHash: receipt.transactionHash,
            adventurerId: as.adventurerId,
            adventurerHealth: as.adventurer.health,
            discoveryType: 3,
            subDiscoveryType: 1,
            outputAmount: value.xpAmount,
            obstacle: 0,
            obstacleLevel: 0,
            dodgedObstacle: false,
            damageTaken: 0,
            damageLocation: 0,
            xpEarnedAdventurer: 0,
            xpEarnedItems: 0,
            entity: 0,
            entityLevel: 0,
            entityHealth: 0,
            special1: 0,
            special2: 0,
            special3: 0,
            ambushed: false,
            seed: 0,
            discoveryTime: new Date().toISOString(),
            timestamp: new Date().toISOString(),
          }),
        ];
      }
      case HIT_BY_OBSTACLE: {
        const { value } = parseHitByObstacle(event.data, 0);
        const as = value.adventurerState;
        console.log("HIT_BY_OBSTACLE", "->", "DISCOVERIES UPDATES");
        return [
          insertDiscovery({
            txHash: receipt.transactionHash,
            adventurerId: as.adventurerId,
            adventurerHealth: as.adventurer.health,
            discoveryType: 2,
            subDiscoveryType: 0,
            outputAmount: 0,
            obstacle: value.id,
            obstacleLevel: value.level,
            dodgedObstacle: false,
            damageTaken: value.damageTaken,
            damageLocation: value.damageLocation,
            xpEarnedAdventurer: value.xpEarnedAdventurer,
            xpEarnedItems: value.xpEarnedItems,
            entity: 0,
            entityLevel: 0,
            entityHealth: 0,
            special1: 0,
            special2: 0,
            special3: 0,
            ambushed: false,
            seed: 0,
            discoveryTime: new Date().toISOString(),
            timestamp: new Date().toISOString(),
          }),
        ];
      }
      case DODGED_OBSTACLE: {
        const { value } = parseHitByObstacle(event.data, 0);
        const as = value.adventurerState;
        console.log("DODGED_OBSTACLE", "->", "DISCOVERIES UPDATES");
        return [
          insertDiscovery({
            txHash: receipt.transactionHash,
            adventurerId: as.adventurerId,
            adventurerHealth: as.adventurer.health,
            discoveryType: 2,
            subDiscoveryType: 0,
            outputAmount: 0,
            obstacle: value.id,
            obstacleLevel: value.level,
            dodgedObstacle: true,
            damageTaken: value.damageTaken,
            damageLocation: value.damageLocation,
            xpEarnedAdventurer: value.xpEarnedAdventurer,
            xpEarnedItems: value.xpEarnedItems,
            entity: 0,
            entityLevel: 0,
            entityHealth: 0,
            special1: 0,
            special2: 0,
            special3: 0,
            ambushed: false,
            seed: 0,
            discoveryTime: new Date().toISOString(),
            timestamp: new Date().toISOString(),
          }),
        ];
      }
      case DISCOVERED_BEAST: {
        const { value } = parseDiscoveredBeast(event.data, 0);
        const as = value.adventurerState;
        const bs = value.beastSpec;
        console.log("DISCOVERED_BEAST", "->", "DISCOVERIES UPDATES");
        return [
          insertDiscovery({
            txHash: receipt.transactionHash,
            adventurerId: as.adventurerId,
            adventurerHealth: as.adventurer.health,
            discoveryType: 1,
            subDiscoveryType: 0,
            outputAmount: 0,
            obstacle: 0,
            obstacleLevel: 0,
            dodgedObstacle: false,
            damageTaken: 0,
            damageLocation: 0,
            xpEarnedAdventurer: 0,
            xpEarnedItems: 0,
            entity: value.id,
            entityLevel: bs.level,
            entityHealth: as.adventurer.beastHealth,
            special1: bs.specials.special1,
            special2: bs.specials.special2,
            special3: bs.specials.special3,
            ambushed: false,
            seed: value.seed,
            discoveryTime: new Date().toISOString(),
            timestamp: new Date().toISOString(),
          }),
        ];
      }
      case AMBUSHED_BY_BEAST: {
        const { value } = parseAmbushedByBeast(event.data, 0);
        const as = value.adventurerState;
        const bs = value.beastSpec;
        console.log("AMBUSHED_BY_BEAST", "->", "DISCOVERIES UPDATES");
        return [
          insertDiscovery({
            txHash: receipt.transactionHash,
            adventurerId: as.adventurerId,
            adventurerHealth: as.adventurer.health,
            discoveryType: 1,
            subDiscoveryType: 0,
            outputAmount: 0,
            obstacle: 0,
            obstacleLevel: 0,
            dodgedObstacle: false,
            damageTaken: value.damage,
            damageLocation: value.location,
            xpEarnedAdventurer: 0,
            xpEarnedItems: 0,
            entity: value.id,
            entityLevel: bs.level,
            entityHealth: as.adventurer.beastHealth,
            special1: bs.specials.special1,
            special2: bs.specials.special2,
            special3: bs.specials.special3,
            ambushed: true,
            seed: value.seed,
            discoveryTime: new Date().toISOString(),
            timestamp: new Date().toISOString(),
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
