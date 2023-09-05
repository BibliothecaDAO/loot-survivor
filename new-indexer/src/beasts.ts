import type { Config } from "https://esm.sh/@apibara/indexer";
import type { Block, Starknet } from "https://esm.sh/@apibara/indexer/starknet";
import type { Mongo } from "https://esm.sh/@apibara/indexer/sink/mongo";
import type { Console } from "https://esm.sh/@apibara/indexer/sink/console";
import {
  AMBUSHED_BY_BEAST,
  ATTACKED_BEAST,
  ATTACKED_BY_BEAST,
  DISCOVERED_BEAST,
  parseAmbushedByBeast,
  parseAttackedBeast,
  parseDiscoveredBeast,
  parseSlayedBeast,
  SLAYED_BEAST,
} from "./utils/events.ts";
import { insertBeast, updateBeastHealth } from "./utils/helpers.ts";

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
    database: "mongo_goerli",
    collectionName: "beasts",
    // @ts-ignore - indexer package not updated
    entityMode: true,
  },
};

export default function transform({ header, events }: Block) {
  const { timestamp } = header!;

  return events.flatMap(({ event }) => {
    switch (event.keys[0]) {
      case DISCOVERED_BEAST: {
        const { value } = parseDiscoveredBeast(event.data, 0);
        console.log("Discovered beast", value);
        return [
          insertBeast({
            beast: value.id,
            adventurerId: value.adventurerState.adventurerId,
            seed: value.seed,
            health: value.adventurerState.adventurer.health,
            level: value.beastSpec.level,
            special1: value.beastSpec.specials.special1,
            special2: value.beastSpec.specials.special2,
            special3: value.beastSpec.specials.special3,
            slayed: false,
            slainOnTime: null,
            createdTime: new Date().toISOString(),
            lastUpdatedTime: new Date().toISOString(),
            timestamp: new Date().toISOString(),
          }),
        ];
      }
      case AMBUSHED_BY_BEAST: {
        const { value } = parseAmbushedByBeast(event.data, 0);
        console.log("Discovered beast", value);
        return [
          insertBeast({
            beast: value.id,
            adventurerId: value.adventurerState.adventurerId,
            seed: value.seed,
            health: value.adventurerState.adventurer.health,
            level: value.beastSpec.level,
            special1: value.beastSpec.specials.special1,
            special2: value.beastSpec.specials.special2,
            special3: value.beastSpec.specials.special3,
            slayed: false,
            slainOnTime: null,
            createdTime: new Date().toISOString(),
            lastUpdatedTime: new Date().toISOString(),
            timestamp: new Date().toISOString(),
          }),
        ];
      }
      case ATTACKED_BEAST: {
        const { value } = parseAttackedBeast(event.data, 0);
        console.log("Attacked beast", value);
        return [
          updateBeastHealth({
            beast: value.id,
            adventurerId: value.adventurerState.adventurerId,
            seed: value.seed,
            health: value.adventurerState.adventurer.health,
            slayed: false,
            slainOnTime: null,
            lastUpdatedTime: new Date().toISOString(),
            timestamp: new Date().toISOString(),
          }),
        ];
      }
      case SLAYED_BEAST: {
        const { value } = parseSlayedBeast(event.data, 0);
        // console.log("Slayed beast", value);
        return [
          updateBeastHealth({
            beast: value.id,
            adventurerId: value.adventurerState.adventurerId,
            seed: value.seed,
            health: value.adventurerState.adventurer.health,
            slayed: true,
            slainOnTime: new Date().toISOString(),
            lastUpdatedTime: new Date().toISOString(),
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
