import type { Config } from "https://esm.sh/@apibara/indexer";
import type { Block, Starknet } from "https://esm.sh/@apibara/indexer/starknet";
import type { Mongo } from "https://esm.sh/@apibara/indexer/sink/mongo";
import type { Console } from "https://esm.sh/@apibara/indexer/sink/console";
import {
  AMBUSHED_BY_BEAST,
  ATTACKED_BEAST,
  ATTACKED_BY_BEAST,
  DISCOVERED_BEAST,
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
import { insertBattle, insertDiscovery } from "./utils/helpers.js";

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
      case ATTACKED_BEAST: {
        const { value } = parseAttackedBeast(event.data, 0);
        const as = value.adventurerState;
        const bs = value.beastSpec;
        // console.log("Start game", value);
        return [
          insertBattle({
            txHash: receipt.transaction_hash,
            beast: value.id,
            beastHealth: as.adventurer.beastHealth,
            beastLevel: bs.level,
            special1: bs.specials.special1,
            special2: bs.specials.special2,
            special3: bs.specials.special3,
            seed: value.seed,
            adventurerId: as.adventurerId,
            adventurerHealth: as.adventurer.health,
            attacker: "Adventurer",
            fled: null,
            damageDealt: value.damage,
            criticalHit: value.criticalHit,
            damageTaken: 0,
            damageLocation: null,
            xpEarnedAdventurer: 0,
            xpEarnedItems: 0,
            goldEarned: 0,
            discoveryTime: timestamp,
            blockTime: timestamp,
            timestamp,
          }),
        ];
      }
      case ATTACKED_BY_BEAST: {
        const { value } = parseAttackedByBeast(event.data, 0);
        const as = value.adventurerState;
        const bs = value.beastSpec;
        // console.log("Start game", value);
        return [
          insertBattle({
            txHash: receipt.transaction_hash,
            beast: value.id,
            beastHealth: as.adventurer.beastHealth,
            beastLevel: bs.level,
            special1: bs.specials.special1,
            special2: bs.specials.special2,
            special3: bs.specials.special3,
            seed: value.seed,
            adventurerId: as.adventurerId,
            adventurerHealth: as.adventurer.health,
            attacker: "Beast",
            fled: null,
            damageDealt: 0,
            criticalHit: value.criticalHit,
            damageTaken: value.damage,
            damageLocation: value.location,
            xpEarnedAdventurer: 0,
            xpEarnedItems: 0,
            goldEarned: 0,
            discoveryTime: timestamp,
            blockTime: timestamp,
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
          insertBattle({
            txHash: receipt.transaction_hash,
            beast: value.id,
            beastHealth: as.adventurer.beastHealth,
            beastLevel: bs.level,
            special1: bs.specials.special1,
            special2: bs.specials.special2,
            special3: bs.specials.special3,
            seed: value.seed,
            adventurerId: as.adventurerId,
            adventurerHealth: as.adventurer.health,
            attacker: "Beast",
            fled: null,
            damageDealt: 0,
            criticalHit: value.criticalHit,
            damageTaken: value.damage,
            damageLocation: value.location,
            xpEarnedAdventurer: 0,
            xpEarnedItems: 0,
            goldEarned: 0,
            discoveryTime: timestamp,
            blockTime: timestamp,
            timestamp,
          }),
        ];
      }
      case SLAYED_BEAST: {
        const { value } = parseSlayedBeast(event.data, 0);
        const as = value.adventurerState;
        const bs = value.beastSpec;
        // console.log("Start game", value);
        return [
          insertBattle({
            txHash: receipt.transaction_hash,
            beast: value.id,
            beastHealth: as.adventurer.beastHealth,
            beastLevel: bs.level,
            special1: bs.specials.special1,
            special2: bs.specials.special2,
            special3: bs.specials.special3,
            seed: value.seed,
            adventurerId: as.adventurerId,
            adventurerHealth: as.adventurer.health,
            attacker: "Adventurer",
            fled: null,
            damageDealt: value.damageDealt,
            criticalHit: value.criticalHit,
            damageTaken: 0,
            damageLocation: null,
            xpEarnedAdventurer: value.xpEarnedAdventurer,
            xpEarnedItems: value.xpEarnedItems,
            goldEarned: 0,
            discoveryTime: timestamp,
            blockTime: timestamp,
            timestamp,
          }),
        ];
      }
      case FLEE_FAILED: {
        const { value } = parseFleeFailed(event.data, 0);
        const as = value.adventurerState;
        const bs = value.beastSpec;
        // console.log("Start game", value);
        return [
          insertBattle({
            txHash: receipt.transaction_hash,
            beast: value.id,
            beastHealth: as.adventurer.beastHealth,
            beastLevel: bs.level,
            special1: bs.specials.special1,
            special2: bs.specials.special2,
            special3: bs.specials.special3,
            seed: value.seed,
            adventurerId: as.adventurerId,
            adventurerHealth: as.adventurer.health,
            attacker: "Adventurer",
            fled: null,
            damageDealt: 0,
            criticalHit: false,
            damageTaken: 0,
            damageLocation: null,
            xpEarnedAdventurer: 0,
            xpEarnedItems: 0,
            goldEarned: 0,
            discoveryTime: timestamp,
            blockTime: timestamp,
            timestamp,
          }),
        ];
      }
      case FLEE_SUCCEEDED: {
        const { value } = parseFleeSucceeded(event.data, 0);
        const as = value.adventurerState;
        const bs = value.beastSpec;
        // console.log("Start game", value);
        return [
          insertBattle({
            txHash: receipt.transaction_hash,
            beast: value.id,
            beastHealth: as.adventurer.beastHealth,
            beastLevel: bs.level,
            special1: bs.specials.special1,
            special2: bs.specials.special2,
            special3: bs.specials.special3,
            seed: value.seed,
            adventurerId: as.adventurerId,
            adventurerHealth: as.adventurer.health,
            attacker: "Adventurer",
            fled: true,
            damageDealt: 0,
            criticalHit: false,
            damageTaken: 0,
            damageLocation: null,
            xpEarnedAdventurer: 0,
            xpEarnedItems: 0,
            goldEarned: 0,
            discoveryTime: timestamp,
            blockTime: timestamp,
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
