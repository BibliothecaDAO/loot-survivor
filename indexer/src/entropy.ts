import type { Config } from "https://esm.sh/@apibara/indexer";
import type { Block, Starknet } from "https://esm.sh/@apibara/indexer/starknet";
import type { Mongo } from "https://esm.sh/@apibara/indexer/sink/mongo";
import type { Console } from "https://esm.sh/@apibara/indexer/sink/console";
import {
  GAME_ENTROPY_ROTATED,
  parseGameEntropyRotated,
} from "./utils/events.ts";
import { insertEntropy } from "./utils/helpers.ts";
import { MONGO_CONNECTION_STRING } from "./utils/constants.ts";

const GAME = Deno.env.get("GAME");
const START = +(Deno.env.get("START") || 0);

const filter = {
  header: { weak: true },
  events: [{ fromAddress: GAME, keys: [GAME_ENTROPY_ROTATED] }],
};

export const config: Config<Starknet, Mongo | Console> = {
  streamUrl: "https://goerli.starknet.a5a.ch",
  network: "starknet",
  filter,
  startingBlock: START,
  finality: "DATA_STATUS_PENDING",
  sinkType: "mongo",
  sinkOptions: {
    connectionString: MONGO_CONNECTION_STRING,
    database: "mongo_goerli",
    collectionName: "entropy",
    // @ts-ignore - indexer package not updated
    entityMode: true,
  },
};

export default function transform({ header, events }: Block) {
  return events.flatMap(({ event, receipt }) => {
    switch (event.keys[0]) {
      case GAME_ENTROPY_ROTATED: {
        console.log("GAME_ENTROPY_ROTATED", "->", "ENTROPY UPDATE");
        const { value } = parseGameEntropyRotated(event.data, 0);
        return [
          insertEntropy({
            prevHash: value.prevHash,
            prevBlockNumber: value.prevBlockNumber,
            prevBlockTimestamp: value.prevBlockTimestamp,
            prevNextRotationBlock: value.prevNextRotationBlock,
            newHash: value.newHash,
            newBlockNumber: value.newBlockNumber,
            newBlockTimestamp: value.newBlockTimestamp,
            newNextRotationBlock: value.newNextRotationBlock,
            blocksPerHour: value.blocksPerHour,
            currentTimestamp: new Date().toISOString(),
          }),
        ];
      }
    }
  });
}
