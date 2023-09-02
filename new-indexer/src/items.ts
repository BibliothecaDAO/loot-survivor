import type { Config } from "https://esm.sh/@apibara/indexer";
import type { Block, Starknet } from "https://esm.sh/@apibara/indexer/starknet";
import type { Mongo } from "https://esm.sh/@apibara/indexer/sink/mongo";
import type { Console } from "https://esm.sh/@apibara/indexer/sink/console";
import {
  DODGED_OBSTACLE,
  DROPPED_ITEMS,
  EQUIPPED_ITEMS,
  HIT_BY_OBSTACLE,
  ITEM_SPECIAL_UNLOCKED,
  parseDodgedObstacle,
  parseDroppedItems,
  parseEquippedItems,
  parseHitByObstacle,
  parseItemSpecialUnlocked,
  parsePurchasedItems,
  parseSlayedBeast,
  parseStartGame,
  PURCHASED_ITEMS,
  SLAYED_BEAST,
  START_GAME,
} from "./utils/events.ts";
import { insertItem, updateItemsXP } from "./utils/helpers.js";

const GAME = Deno.env.get("GAME");
const START = +(Deno.env.get("START") || 0);

const filter = {
  header: { weak: true },
  events: [
    { fromAddress: GAME, keys: [START_GAME] },
    { fromAddress: GAME, keys: [PURCHASED_ITEMS] },
    { fromAddress: GAME, keys: [EQUIPPED_ITEMS] },
    { fromAddress: GAME, keys: [DROPPED_ITEMS] },
    { fromAddress: GAME, keys: [HIT_BY_OBSTACLE] },
    { fromAddress: GAME, keys: [DODGED_OBSTACLE] },
    { fromAddress: GAME, keys: [SLAYED_BEAST] },
    { fromAddress: GAME, keys: [ITEM_SPECIAL_UNLOCKED] },
  ],
};

export const config: Config<Starknet, Mongo | Console> = {
  streamUrl: "https://goerli.starknet.a5a.ch",
  network: "starknet",
  filter,
  startingBlock: START,
  finality: "DATA_STATUS_PENDING",
  sinkType: "console",
  sinkOptions: {
    database: "loot_example",
    collectionName: "items",
    // @ts-ignore - indexer package not updated
    entityMode: true,
  },
};

export default function transform({ header, events }: Block) {
  const { timestamp } = header!;

  return events.flatMap(({ event, receipt }) => {
    switch (event.keys[0]) {
      case START_GAME: {
        const { value } = parseStartGame(event.data, 0);
        const as = value.adventurerState;
        // console.log("Start game", value);
        const itemInserts: any[] = [];
        for (let i = 1; i < 102; i++) {
          itemInserts.push(
            insertItem({
              item: i,
              adventurerId: as.adventurerId,
              owner: false,
              equipped: false,
              ownerAddress: null,
              xp: 0,
              special1: null,
              special2: null,
              special3: null,
              isAvailable: false,
              purchasedTime: null,
              timestamp,
            })
          );
        }

        return itemInserts;
      }
      case PURCHASED_ITEMS: {
        const { value } = parsePurchasedItems(event.data, 0);
        const as = value.adventurerState;
        // console.log("Start game", value);
        const result = value.purchases.map((item) => ({
          entity: {
            item: item.item.id,
            adventurerId: as.adventurerId,
          },
          update: {
            $set: {
              owner: true,
              equipped: false,
              ownerAddress: as.owner,
              purchasedTime: timestamp,
              timestamp,
            },
          },
        }));
        return result;
      }
      case EQUIPPED_ITEMS: {
        const { value } = parseEquippedItems(event.data, 0);
        const as = value.adventurerState;
        // console.log("Start game", value);
        const equippedResult = value.equippedItems.map((item) => ({
          entity: {
            item: item,
            adventurerId: as.adventurerId,
          },
          update: {
            $set: {
              equipped: true,
              timestamp,
            },
          },
        }));
        const unequippedResult = value.unequippedItems.map((item) => ({
          entity: {
            item: item,
            adventurerId: as.adventurerId,
          },
          update: {
            $set: {
              equipped: false,
              timestamp,
            },
          },
        }));
        return [...equippedResult, ...unequippedResult];
      }
      case DROPPED_ITEMS: {
        const { value } = parseDroppedItems(event.data, 0);
        const as = value.adventurerState;
        // console.log("Start game", value);
        const result = value.droppedItems.map((item) => ({
          entity: {
            item: item,
            adventurerId: as.adventurerId,
          },
          update: {
            $set: {
              owner: false,
              equipped: false,
              ownerAddress: null,
              timestamp,
            },
          },
        }));
        return result;
      }
      case HIT_BY_OBSTACLE: {
        const { value } = parseHitByObstacle(event.data, 0);
        const as = value.adventurerState;
        // console.log("Start game", value);
        return updateItemsXP({ adventurerState: as });
      }
      case DODGED_OBSTACLE: {
        const { value } = parseDodgedObstacle(event.data, 0);
        const as = value.adventurerState;
        // console.log("Start game", value);
        return updateItemsXP({ adventurerState: as });
      }
      case SLAYED_BEAST: {
        const { value } = parseSlayedBeast(event.data, 0);
        const as = value.adventurerState;
        // console.log("Start game", value);
        return updateItemsXP({ adventurerState: as });
      }
      case ITEM_SPECIAL_UNLOCKED:
        const { value } = parseItemSpecialUnlocked(event.data, 0);
        const as = value.adventurerState;
        // console.log("Start game", value);
        return updateItemsXP({ adventurerState: as });
      default: {
        console.warn("Unknown event", event.keys[0]);
        return [];
      }
    }
  });
}
