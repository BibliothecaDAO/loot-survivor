import type { Config } from "https://esm.sh/@apibara/indexer";
import type { Block, Starknet } from "https://esm.sh/@apibara/indexer/starknet";
import type { Mongo } from "https://esm.sh/@apibara/indexer/sink/mongo";
import type { Console } from "https://esm.sh/@apibara/indexer/sink/console";
import {
  REWARD_DISTRIBUTION,
  parseRewardDistribution,
  NEW_HIGH_SCORE,
  parseNewHighScore,
} from "./utils/events.ts";
import { insertHighScore, updateTotalPayout } from "./utils/helpers.ts";

const GAME = Deno.env.get("GAME");
const START = +(Deno.env.get("START") || 0);

const filter = {
  header: { weak: true },
  events: [
    { fromAddress: GAME, keys: [NEW_HIGH_SCORE] },
    { fromAddress: GAME, keys: [REWARD_DISTRIBUTION] },
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
    collectionName: "scores",
    // @ts-ignore - indexer package not updated
    entityMode: true,
  },
};

export default function transform({ header, events }: Block) {
  const { timestamp } = header!;

  return events.flatMap(({ event, receipt }) => {
    switch (event.keys[0]) {
      case NEW_HIGH_SCORE: {
        const { value } = parseNewHighScore(event.data, 0);
        const as = value.adventurer_state;
        console.log("NEW_HIGH_SCORE", "->", "SCORES UPDATE");
        return [
          insertHighScore({
            adventurerId: as.adventurerId,
            owner: as.owner,
            rank: value.rank,
            xp: as.adventurer.xp,
            txHash: receipt.transactionHash,
            scoreTime: new Date().toISOString(),
            timestamp: new Date().toISOString(),
            totalPayout: 0,
          }),
        ];
      }
      case REWARD_DISTRIBUTION: {
        const { value } = parseRewardDistribution(event.data, 0);
        const fp = value.firstPlace;
        const sp = value.secondPlace;
        const tp = value.thirdPlace;
        console.log("REWARD_DISTRIBUTION", "->", "SCORES UPDATE");
        const updates: any[] = [];
        if (BigInt(fp.amount) > 0) {
          updates.push(
            updateTotalPayout({
              adventurerId: fp.adventurerId,
              owner: fp.address,
              rank: fp.rank,
              timestamp: new Date().toISOString(),
              newPayout: fp.amount,
            })
          );
        }
        if (BigInt(sp.amount) > 0) {
          updates.push(
            updateTotalPayout({
              adventurerId: sp.adventurerId,
              owner: sp.address,
              rank: sp.rank,
              timestamp: new Date().toISOString(),
              newPayout: sp.amount,
            })
          );
        }
        if (BigInt(tp.amount) > 0) {
          updates.push(
            updateTotalPayout({
              adventurerId: tp.adventurerId,
              owner: tp.address,
              rank: tp.rank,
              timestamp: new Date().toISOString(),
              newPayout: tp.amount,
            })
          );
        }
        return updates;
      }
    }
  });
}
