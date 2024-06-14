import type { Config } from "https://esm.sh/@apibara/indexer";
import type { Block, Starknet } from "https://esm.sh/@apibara/indexer/starknet";
import type { Mongo } from "https://esm.sh/@apibara/indexer/sink/mongo";
import type { Console } from "https://esm.sh/@apibara/indexer/sink/console";
import {
  AMBUSHED_BY_BEAST,
  ATTACKED_BEAST,
  DISCOVERED_BEAST,
  parseAmbushedByBeast,
  parseAttackedBeast,
  parseDiscoveredBeast,
  parseSlayedBeast,
  SLAYED_BEAST,
} from "./utils/events.ts";
import { insertBeast, updateBeastHealth } from "./utils/helpers.ts";
import { MONGO_CONNECTION_STRING } from "./utils/constants.ts";

const GAME = Deno.env.get("GAME");
const START = +(Deno.env.get("START") || 0);
const STREAM_URL = Deno.env.get("STREAM_URL");
const MONGO_DB = Deno.env.get("MONGO_DB");

const filter = {
  header: { weak: true },
  events: [
    { fromAddress: GAME, keys: [DISCOVERED_BEAST] },
    { fromAddress: GAME, keys: [AMBUSHED_BY_BEAST] },
    { fromAddress: GAME, keys: [ATTACKED_BEAST] },
    { fromAddress: GAME, keys: [SLAYED_BEAST] },
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
    collectionName: "beasts",
    // @ts-ignore - indexer package not updated
    entityMode: true,
  },
};

export default function transform({ header, events }: Block) {
  return events.flatMap(({ event }) => {
    switch (event.keys[0]) {
      case DISCOVERED_BEAST: {
        const { value } = parseDiscoveredBeast(event.data, 0);
        console.log("DISCOVERED_BEAST", "->", "BEASTS UPDATES");
        return [
          insertBeast({
            beast: value.id,
            adventurerId: value.adventurerState.adventurerId,
            seed: value.seed,
            health: value.adventurerState.adventurer.beastHealth,
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
        console.log("AMBUSHED_BY_BEAST", "->", "BEASTS UPDATES");
        return [
          insertBeast({
            beast: value.id,
            adventurerId: value.adventurerState.adventurerId,
            seed: value.seed,
            health: value.adventurerState.adventurer.beastHealth,
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
        console.log("ATTACKED_BEAST", "->", "BEASTS UPDATES");
        return [
          updateBeastHealth({
            beast: value.id,
            adventurerId: value.adventurerState.adventurerId,
            seed: value.seed,
            health: value.adventurerState.adventurer.beastHealth,
            slayed: false,
            slainOnTime: null,
            lastUpdatedTime: new Date().toISOString(),
            timestamp: new Date().toISOString(),
          }),
        ];
      }
      case SLAYED_BEAST: {
        const { value } = parseSlayedBeast(event.data, 0);
        console.log("SLAYED_BEAST", "->", "BEASTS UPDATES");
        return [
          updateBeastHealth({
            beast: value.id,
            adventurerId: value.adventurerState.adventurerId,
            seed: value.seed,
            health: value.adventurerState.adventurer.beastHealth,
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
