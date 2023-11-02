import type { Config } from "https://esm.sh/@apibara/indexer";
import type { Block, Starknet } from "https://esm.sh/@apibara/indexer/starknet";
import type { Mongo } from "https://esm.sh/@apibara/indexer/sink/mongo";
import type { Console } from "https://esm.sh/@apibara/indexer/sink/console";
import {
  AMBUSHED_BY_BEAST,
  ATTACKED_BEAST,
  ATTACKED_BY_BEAST,
  FLEE_FAILED,
  FLEE_SUCCEEDED,
  parseAmbushedByBeast,
  parseAttackedBeast,
  parseAttackedByBeast,
  parseFleeFailed,
  parseFleeSucceeded,
  parseSlayedBeast,
  SLAYED_BEAST,
} from "./utils/events.ts";
import { insertBattle } from "./utils/helpers.ts";
import { MONGO_CONNECTION_STRING } from "./utils/constants.ts";

const GAME = Deno.env.get("GAME");
const START = +(Deno.env.get("START") || 0);
const STREAM_URL = Deno.env.get("STREAM_URL");
const MONGO_DB = Deno.env.get("MONGO_DB");

const filter = {
  header: { weak: true },
  events: [
    { fromAddress: GAME, keys: [ATTACKED_BEAST] },
    { fromAddress: GAME, keys: [ATTACKED_BY_BEAST] },
    { fromAddress: GAME, keys: [AMBUSHED_BY_BEAST] },
    { fromAddress: GAME, keys: [SLAYED_BEAST] },
    { fromAddress: GAME, keys: [FLEE_FAILED] },
    { fromAddress: GAME, keys: [FLEE_SUCCEEDED] },
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
    collectionName: "battles",
    // @ts-ignore - indexer package not updated
    entityMode: true,
  },
};

export default function transform({ header, events }: Block) {
  return events.flatMap(({ event, receipt }) => {
    switch (event.keys[0]) {
      case ATTACKED_BEAST: {
        const { value } = parseAttackedBeast(event.data, 0);
        const as = value.adventurerState;
        const bs = value.beastSpec;
        console.log("ATTACKED_BEAST", "->", "BATTLES UPDATE");
        return [
          insertBattle({
            txHash: receipt.transactionHash,
            beast: value.id,
            beastHealth: as.adventurer.beastHealth,
            beastLevel: bs.level,
            special1: bs.specials.special1,
            special2: bs.specials.special2,
            special3: bs.specials.special3,
            seed: value.seed,
            adventurerId: as.adventurerId,
            adventurerHealth: as.adventurer.health,
            attacker: 1,
            fled: false,
            damageDealt: value.damage,
            criticalHit: value.criticalHit,
            damageTaken: 0,
            damageLocation: 0,
            xpEarnedAdventurer: 0,
            xpEarnedItems: 0,
            goldEarned: 0,
            discoveryTime: new Date().toISOString(),
            blockTime: new Date().toISOString(),
            timestamp: new Date().toISOString(),
          }),
        ];
      }
      case ATTACKED_BY_BEAST: {
        const { value } = parseAttackedByBeast(event.data, 0);
        const as = value.adventurerState;
        const bs = value.beastSpec;
        console.log("ATTACKED_BY_BEAST", "->", "BATTLES UPDATE");
        return [
          insertBattle({
            txHash: receipt.transactionHash,
            beast: value.id,
            beastHealth: as.adventurer.beastHealth,
            beastLevel: bs.level,
            special1: bs.specials.special1,
            special2: bs.specials.special2,
            special3: bs.specials.special3,
            seed: value.seed,
            adventurerId: as.adventurerId,
            adventurerHealth: as.adventurer.health,
            attacker: 2,
            fled: false,
            damageDealt: 0,
            criticalHit: value.criticalHit,
            damageTaken: value.damage,
            damageLocation: value.location,
            xpEarnedAdventurer: 0,
            xpEarnedItems: 0,
            goldEarned: 0,
            discoveryTime: new Date().toISOString(),
            blockTime: new Date().toISOString(),
            timestamp: new Date().toISOString(),
          }),
        ];
      }
      case AMBUSHED_BY_BEAST: {
        const { value } = parseAmbushedByBeast(event.data, 0);
        const as = value.adventurerState;
        const bs = value.beastSpec;
        console.log("AMBUSHED_BY_BEAST", "->", "BATTLES UPDATE");
        return [
          insertBattle({
            txHash: receipt.transactionHash,
            beast: value.id,
            beastHealth: as.adventurer.beastHealth,
            beastLevel: bs.level,
            special1: bs.specials.special1,
            special2: bs.specials.special2,
            special3: bs.specials.special3,
            seed: value.seed,
            adventurerId: as.adventurerId,
            adventurerHealth: as.adventurer.health,
            attacker: 2,
            fled: false,
            damageDealt: 0,
            criticalHit: value.criticalHit,
            damageTaken: value.damage,
            damageLocation: value.location,
            xpEarnedAdventurer: 0,
            xpEarnedItems: 0,
            goldEarned: 0,
            discoveryTime: new Date().toISOString(),
            blockTime: new Date().toISOString(),
            timestamp: new Date().toISOString(),
          }),
        ];
      }
      case SLAYED_BEAST: {
        const { value } = parseSlayedBeast(event.data, 0);
        const as = value.adventurerState;
        const bs = value.beastSpec;
        console.log("SLAYED_BEAST", "->", "BATTLES UPDATE");
        return [
          insertBattle({
            txHash: receipt.transactionHash,
            beast: value.id,
            beastHealth: as.adventurer.beastHealth,
            beastLevel: bs.level,
            special1: bs.specials.special1,
            special2: bs.specials.special2,
            special3: bs.specials.special3,
            seed: value.seed,
            adventurerId: as.adventurerId,
            adventurerHealth: as.adventurer.health,
            attacker: 1,
            fled: false,
            damageDealt: value.damageDealt,
            criticalHit: value.criticalHit,
            damageTaken: 0,
            damageLocation: 0,
            xpEarnedAdventurer: value.xpEarnedAdventurer,
            xpEarnedItems: value.xpEarnedItems,
            goldEarned: 0,
            discoveryTime: new Date().toISOString(),
            blockTime: new Date().toISOString(),
            timestamp: new Date().toISOString(),
          }),
        ];
      }
      case FLEE_FAILED: {
        const { value } = parseFleeFailed(event.data, 0);
        const as = value.adventurerState;
        const bs = value.beastSpec;
        console.log("FLEE_FAILED", "->", "BATTLES UPDATE");
        return [
          insertBattle({
            txHash: receipt.transactionHash,
            beast: value.id,
            beastHealth: as.adventurer.beastHealth,
            beastLevel: bs.level,
            special1: bs.specials.special1,
            special2: bs.specials.special2,
            special3: bs.specials.special3,
            seed: value.seed,
            adventurerId: as.adventurerId,
            adventurerHealth: as.adventurer.health,
            attacker: 1,
            fled: false,
            damageDealt: 0,
            criticalHit: false,
            damageTaken: 0,
            damageLocation: 0,
            xpEarnedAdventurer: 0,
            xpEarnedItems: 0,
            goldEarned: 0,
            discoveryTime: new Date().toISOString(),
            blockTime: new Date().toISOString(),
            timestamp: new Date().toISOString(),
          }),
        ];
      }
      case FLEE_SUCCEEDED: {
        const { value } = parseFleeSucceeded(event.data, 0);
        const as = value.adventurerState;
        const bs = value.beastSpec;
        console.log("FLEE_SUCCEEDED", "->", "BATTLES UPDATE");
        return [
          insertBattle({
            txHash: receipt.transactionHash,
            beast: value.id,
            beastHealth: as.adventurer.beastHealth,
            beastLevel: bs.level,
            special1: bs.specials.special1,
            special2: bs.specials.special2,
            special3: bs.specials.special3,
            seed: value.seed,
            adventurerId: as.adventurerId,
            adventurerHealth: as.adventurer.health,
            attacker: 1,
            fled: true,
            damageDealt: 0,
            criticalHit: false,
            damageTaken: 0,
            damageLocation: 0,
            xpEarnedAdventurer: 0,
            xpEarnedItems: 0,
            goldEarned: 0,
            discoveryTime: new Date().toISOString(),
            blockTime: new Date().toISOString(),
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
