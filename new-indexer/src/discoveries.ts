import type { Config } from "https://esm.sh/@apibara/indexer";
import type { Block, Starknet } from "https://esm.sh/@apibara/indexer/starknet";
import type { Mongo } from "https://esm.sh/@apibara/indexer/sink/mongo";
import type { Console } from "https://esm.sh/@apibara/indexer/sink/console";
import {
  AMBUSHED_BY_BEAST,
  ATTACKED_BEAST,
  ATTACKED_BY_BEAST,
  DISCOVERED_BEAST,
  DISCOVERED_GOLD,
  DISCOVERED_HEALTH,
  parseAmbushedByBeast,
  parseDiscoveredBeast,
  parseDiscoveredGold,
  parseDiscoveredHealth,
  parseDiscoveredXp,
  SLAYED_BEAST,
} from "./utils/events.ts";
import { insertDiscovery } from "./utils/helpers.js";

const GAME = Deno.env.get("GAME");
const START = +(Deno.env.get("START") || 0);

const filter = {
  header: { weak: true },
  events: [
    { fromAddress: GAME, keys: [DISCOVERED_BEAST] },
    { fromAddress: GAME, keys: [AMBUSHED_BY_BEAST] },
    { fromAddress: GAME, keys: [ATTACKED_BEAST] },
    { fromAddress: GAME, keys: [ATTACKED_BY_BEAST] },
    { fromAddress: GAME, keys: [SLAYED_BEAST] },
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
    collectionName: "beasts",
    // @ts-ignore - indexer package not updated
    entityMode: true,
  },
};

export default function transform({ header, events }: Block) {
  const { timestamp } = header!;

  return events.flatMap(({ event, receipt }) => {
    switch (event.keys[0]) {
      case DISCOVERED_HEALTH: {
        const { value } = parseDiscoveredHealth(event.data, 0);
        const as = value.adventurerState;
        // console.log("Start game", value);
        return [
          insertDiscovery({
            txHash: receipt.transaction_hash,
            adventurerId: as.adventurerId,
            adventurerHealth: as.adventurer.health,
            discoveryType: 3,
            subDiscoveryType: 1,
            outputAmount: value.healthAmount,
            obstacle: null,
            obstacleLevel: null,
            dodgedObstacle: null,
            damageTaken: null,
            damageLocation: null,
            xpEarnedAdventurer: null,
            xpEarnedItems: null,
            entity: null,
            entityLevel: null,
            entityHealth: null,
            special1: null,
            special2: null,
            special3: null,
            ambushed: null,
            seed: null,
            discoveryTime: timestamp,
            timestamp,
          }),
        ];
      }
      case DISCOVERED_GOLD: {
        const { value } = parseDiscoveredGold(event.data, 0);
        const as = value.adventurerState;
        // console.log("Start game", value);
        return [
          insertDiscovery({
            txHash: receipt.transaction_hash,
            adventurerId: as.adventurerId,
            adventurerHealth: as.adventurer.health,
            discoveryType: 3,
            subDiscoveryType: 1,
            outputAmount: value.goldAmount,
            obstacle: null,
            obstacleLevel: null,
            dodgedObstacle: null,
            damageTaken: null,
            damageLocation: null,
            xpEarnedAdventurer: null,
            xpEarnedItems: null,
            entity: null,
            entityLevel: null,
            entityHealth: null,
            special1: null,
            special2: null,
            special3: null,
            ambushed: null,
            seed: null,
            discoveryTime: timestamp,
            timestamp,
          }),
        ];
      }
      case DISCOVERED_XP: {
        const { value } = parseDiscoveredXp(event.data, 0);
        const as = value.adventurerState;
        // console.log("Start game", value);
        return [
          insertDiscovery({
            txHash: receipt.transaction_hash,
            adventurerId: as.adventurerId,
            adventurerHealth: as.adventurer.health,
            discoveryType: 3,
            subDiscoveryType: 1,
            outputAmount: value.xpAmount,
            obstacle: null,
            obstacleLevel: null,
            dodgedObstacle: null,
            damageTaken: null,
            damageLocation: null,
            xpEarnedAdventurer: null,
            xpEarnedItems: null,
            entity: null,
            entityLevel: null,
            entityHealth: null,
            special1: null,
            special2: null,
            special3: null,
            ambushed: null,
            seed: null,
            discoveryTime: timestamp,
            timestamp,
          }),
        ];
      }
      case DISCOVERED_BEAST: {
        const { value } = parseDiscoveredBeast(event.data, 0);
        const as = value.adventurerState;
        const bs = value.beastSpec;
        // console.log("Start game", value);
        return [
          insertDiscovery({
            txHash: receipt.transaction_hash,
            adventurerId: as.adventurerId,
            adventurerHealth: as.adventurer.health,
            discoveryType: 3,
            subDiscoveryType: 1,
            outputAmount: null,
            obstacle: null,
            obstacleLevel: null,
            dodgedObstacle: null,
            damageTaken: null,
            damageLocation: null,
            xpEarnedAdventurer: null,
            xpEarnedItems: null,
            entity: value.id,
            entityLevel: bs.level,
            entityHealth: as.adventurer.beastHealth,
            special1: bs.specials.special1,
            special2: bs.specials.special2,
            special3: bs.specials.special3,
            ambushed: false,
            seed: value.seed,
            discoveryTime: timestamp,
            timestamp,
          }),
        ];
      }
      case AMBUSHED_BY_BEAST: {
        const { value } = parseAmbushedByBeast(event.data, 0);
        const as = value.adventurerState;
        const bs = value.beastSpec;
        // console.log("Start game", value);
        return [
          insertDiscovery({
            txHash: receipt.transaction_hash,
            adventurerId: as.adventurerId,
            adventurerHealth: as.adventurer.health,
            discoveryType: 3,
            subDiscoveryType: 1,
            outputAmount: null,
            obstacle: null,
            obstacleLevel: null,
            dodgedObstacle: null,
            damageTaken: null,
            damageLocation: null,
            xpEarnedAdventurer: null,
            xpEarnedItems: null,
            entity: value.id,
            entityLevel: bs.level,
            entityHealth: as.adventurer.beastHealth,
            special1: bs.specials.special1,
            special2: bs.specials.special2,
            special3: bs.specials.special3,
            ambushed: true,
            seed: value.seed,
            discoveryTime: timestamp,
            timestamp,
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
