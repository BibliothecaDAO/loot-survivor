import type { Config } from "https://esm.sh/@apibara/indexer";
import type { Block, Starknet } from "https://esm.sh/@apibara/indexer/starknet";
import type { Mongo } from "https://esm.sh/@apibara/indexer/sink/mongo";
import type { Console } from "https://esm.sh/@apibara/indexer/sink/console";
import {
  ADVENTURER_UPGRADED,
  DODGED_OBSTACLE,
  DROPPED_ITEMS,
  EQUIPPED_ITEMS,
  HIT_BY_OBSTACLE,
  ITEMS_LEVELED_UP,
  UPGRADES_AVAILABLE,
  parseAdventurerUpgraded,
  parseDodgedObstacle,
  parseDroppedItems,
  parseEquippedItems,
  parseHitByObstacle,
  parseUpgradesAvailable,
  parseItemsLeveledUp,
  parsePurchasedItems,
  parseSlayedBeast,
  parseStartGame,
  PURCHASED_ITEMS,
  SLAYED_BEAST,
  START_GAME,
  DISCOVERED_LOOT,
  parseDiscoveredLoot,
  EQUIPMENT_CHANGED,
  parseEquipmentChanged,
  TRANSFER,
  parseTransfer,
} from "./utils/events.ts";
import {
  insertItem,
  updateItemsOwner,
  updateItemsXP,
} from "./utils/helpers.ts";
import { checkExistsInt } from "./utils/encode.ts";
import { GameData } from "./utils/data.ts";
import { MONGO_CONNECTION_STRING } from "./utils/constants.ts";

const gameData = new GameData();

const GAME = Deno.env.get("GAME");
const START = +(Deno.env.get("START") || 0);
const STREAM_URL = Deno.env.get("STREAM_URL");
const MONGO_DB = Deno.env.get("MONGO_DB");

const filter = {
  header: { weak: true },
  events: [
    { fromAddress: GAME, keys: [START_GAME] },
    { fromAddress: GAME, keys: [PURCHASED_ITEMS] },
    { fromAddress: GAME, keys: [DISCOVERED_LOOT] },
    { fromAddress: GAME, keys: [EQUIPMENT_CHANGED] },
    { fromAddress: GAME, keys: [EQUIPPED_ITEMS] },
    { fromAddress: GAME, keys: [DROPPED_ITEMS] },
    { fromAddress: GAME, keys: [HIT_BY_OBSTACLE] },
    { fromAddress: GAME, keys: [DODGED_OBSTACLE] },
    { fromAddress: GAME, keys: [SLAYED_BEAST] },
    { fromAddress: GAME, keys: [ITEMS_LEVELED_UP] },
    { fromAddress: GAME, keys: [UPGRADES_AVAILABLE] },
    { fromAddress: GAME, keys: [ADVENTURER_UPGRADED] },
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
    collectionName: "items",
    // @ts-ignore - indexer package not updated
    entityMode: true,
  },
};

export default function transform({ header, events }: Block) {
  return events.flatMap(({ event, receipt }) => {
    switch (event.keys[0]) {
      case START_GAME: {
        const { value } = parseStartGame(event.data, 0);
        const as = value.adventurerState;
        console.log("START_GAME", "->", "ITEMS UPDATES");
        const starterWeapon = {
          entity: {
            item: checkExistsInt(as.adventurer.equipment.weapon.id),
            adventurerId: checkExistsInt(parseInt(as.adventurerId)),
          },
          update: {
            $set: {
              item: checkExistsInt(as.adventurer.equipment.weapon.id),
              adventurerId: checkExistsInt(parseInt(as.adventurerId)),
              owner: true,
              equipped: true,
              ownerAddress: checkExistsInt(BigInt(as.owner).toString(16)),
              xp: 0,
              tier: gameData.ITEM_TIERS[as.adventurer.equipment.weapon.id],
              slot: gameData.ITEM_SLOTS[as.adventurer.equipment.weapon.id],
              type: gameData.ITEM_TYPES[as.adventurer.equipment.weapon.id],
              greatness: 1,
              special1: null,
              special2: null,
              special3: null,
              isAvailable: false,
              purchasedTime: null,
              timestamp: new Date().toISOString(),
            },
          },
        };
        return starterWeapon;
      }
      case PURCHASED_ITEMS: {
        const { value } = parsePurchasedItems(event.data, 0);
        const as = value.adventurerStateWithBag.adventurerState;
        console.log("PURCHASED_ITEMS", "->", "ITEMS UPDATES");
        const result = value.purchases.map((item) => ({
          entity: {
            item: checkExistsInt(item.item.id),
            adventurerId: checkExistsInt(parseInt(as.adventurerId)),
          },
          update: {
            $set: {
              item: checkExistsInt(item.item.id),
              adventurerId: checkExistsInt(parseInt(as.adventurerId)),
              owner: true,
              equipped: false,
              tier: gameData.ITEM_TIERS[item.item.id],
              slot: gameData.ITEM_SLOTS[item.item.id],
              type: gameData.ITEM_TYPES[item.item.id],
              ownerAddress: checkExistsInt(BigInt(as.owner).toString(16)),
              purchasedTime: new Date().toISOString(),
              timestamp: new Date().toISOString(),
            },
          },
        }));
        return result;
      }
      case DISCOVERED_LOOT: {
        const { value } = parseDiscoveredLoot(event.data, 0);
        const as = value.adventurerState;
        console.log("DISCOVERED_LOOT", "->", "ITEMS UPDATES");
        return {
          entity: {
            item: checkExistsInt(value.itemId),
            adventurerId: checkExistsInt(parseInt(as.adventurerId)),
          },
          update: {
            $set: {
              item: checkExistsInt(value.itemId),
              adventurerId: checkExistsInt(parseInt(as.adventurerId)),
              equipped: false,
              tier: gameData.ITEM_TIERS[value.itemId],
              slot: gameData.ITEM_SLOTS[value.itemId],
              type: gameData.ITEM_TYPES[value.itemId],
              timestamp: new Date().toISOString(),
            },
          },
        };
      }
      case EQUIPMENT_CHANGED: {
        const { value } = parseEquipmentChanged(event.data, 0);
        const as = value.adventurerStateWithBag.adventurerState;
        console.log("EQUIPMENT_CHANGED", "->", "ITEMS UPDATES");
        const equippedResult = value.equippedItems.map((item) => ({
          entity: {
            item: checkExistsInt(item),
            adventurerId: checkExistsInt(parseInt(as.adventurerId)),
          },
          update: {
            $set: {
              item: checkExistsInt(item),
              adventurerId: checkExistsInt(parseInt(as.adventurerId)),
              owner: true,
              equipped: true,
              tier: gameData.ITEM_TIERS[item],
              slot: gameData.ITEM_SLOTS[item],
              type: gameData.ITEM_TYPES[item],
              ownerAddress: checkExistsInt(BigInt(as.owner).toString(16)),
              xp: 0,
              greatness: 1,
              special1: null,
              special2: null,
              special3: null,
              isAvailable: false,
              purchasedTime: null,
              timestamp: new Date().toISOString(),
            },
          },
        }));
        const baggedResult = value.baggedItems.map((item) => ({
          entity: {
            item: checkExistsInt(item),
            adventurerId: checkExistsInt(parseInt(as.adventurerId)),
          },
          update: {
            $set: {
              item: checkExistsInt(item),
              adventurerId: checkExistsInt(parseInt(as.adventurerId)),
              owner: true,
              equipped: false,
              tier: gameData.ITEM_TIERS[item],
              slot: gameData.ITEM_SLOTS[item],
              type: gameData.ITEM_TYPES[item],
              ownerAddress: checkExistsInt(BigInt(as.owner).toString(16)),
              xp: 0,
              greatness: 1,
              special1: null,
              special2: null,
              special3: null,
              isAvailable: false,
              purchasedTime: null,
              timestamp: new Date().toISOString(),
            },
          },
        }));
        return [...equippedResult, ...baggedResult];
      }
      case EQUIPPED_ITEMS: {
        const { value } = parseEquippedItems(event.data, 0);
        const as = value.adventurerStateWithBag.adventurerState;
        console.log("EQUIPPED_ITEMS", "->", "ITEMS UPDATES");
        const equippedResult = value.equippedItems.map((item) => ({
          entity: {
            item: checkExistsInt(item),
            adventurerId: checkExistsInt(parseInt(as.adventurerId)),
          },
          update: {
            $set: {
              item: checkExistsInt(item),
              adventurerId: checkExistsInt(parseInt(as.adventurerId)),
              equipped: true,
              timestamp: new Date().toISOString(),
            },
          },
        }));
        const unequippedResult = value.unequippedItems.map((item) => ({
          entity: {
            item: checkExistsInt(item),
            adventurerId: checkExistsInt(parseInt(as.adventurerId)),
          },
          update: {
            $set: {
              item: checkExistsInt(item),
              adventurerId: checkExistsInt(parseInt(as.adventurerId)),
              equipped: false,
              timestamp: new Date().toISOString(),
            },
          },
        }));
        return [...equippedResult, ...unequippedResult];
      }
      case DROPPED_ITEMS: {
        const { value } = parseDroppedItems(event.data, 0);
        const as = value.adventurerStateWithBag.adventurerState;
        console.log("DROPPED_ITEMS", "->", "ITEMS UPDATES");
        const result = value.itemIds.map((item) => ({
          entity: {
            item: checkExistsInt(item),
            adventurerId: checkExistsInt(parseInt(as.adventurerId)),
          },
          update: {
            $set: {
              item: checkExistsInt(item),
              adventurerId: checkExistsInt(parseInt(as.adventurerId)),
              owner: false,
              equipped: false,
              ownerAddress: null,
              timestamp: new Date().toISOString(),
            },
          },
        }));
        return result;
      }
      case HIT_BY_OBSTACLE: {
        const { value } = parseHitByObstacle(event.data, 0);
        const as = value.adventurerState;
        console.log("HIT_BY_OBSTACLE", "->", "ITEMS UPDATES");
        return updateItemsXP({ adventurerState: as });
      }
      case DODGED_OBSTACLE: {
        const { value } = parseDodgedObstacle(event.data, 0);
        const as = value.adventurerState;
        console.log("DODGED_OBSTACLE", "->", "ITEMS UPDATES");
        return updateItemsXP({ adventurerState: as });
      }
      case SLAYED_BEAST: {
        const { value } = parseSlayedBeast(event.data, 0);
        const as = value.adventurerState;
        console.log("SLAYED_BEAST", "->", "ITEMS UPDATES");
        return updateItemsXP({ adventurerState: as });
      }
      case ITEMS_LEVELED_UP: {
        const { value } = parseItemsLeveledUp(event.data, 0);
        const as = value.adventurerState;
        console.log("ITEMS_LEVELED_UP", "->", "ITEMS UPDATES");
        const result = value.items.map((item) => {
          if (item.prefixesUnlocked && item.suffixUnlocked) {
            return {
              entity: {
                item: checkExistsInt(item.itemId),
                adventurerId: checkExistsInt(parseInt(as.adventurerId)),
              },
              update: {
                $set: {
                  item: checkExistsInt(item.itemId),
                  adventurerId: checkExistsInt(parseInt(as.adventurerId)),
                  special1: checkExistsInt(item.specials.special1),
                  special2: checkExistsInt(item.specials.special2),
                  special3: checkExistsInt(item.specials.special3),
                },
              },
            };
          } else if (item.prefixesUnlocked) {
            return {
              entity: {
                item: checkExistsInt(item.itemId),
                adventurerId: checkExistsInt(parseInt(as.adventurerId)),
              },
              update: {
                $set: {
                  item: checkExistsInt(item.itemId),
                  adventurerId: checkExistsInt(parseInt(as.adventurerId)),
                  special2: checkExistsInt(item.specials.special2),
                  special3: checkExistsInt(item.specials.special3),
                },
              },
            };
          } else if (item.suffixUnlocked) {
            return {
              entity: {
                item: checkExistsInt(item.itemId),
                adventurerId: checkExistsInt(parseInt(as.adventurerId)),
              },
              update: {
                $set: {
                  item: checkExistsInt(item.itemId),
                  adventurerId: checkExistsInt(parseInt(as.adventurerId)),
                  special1: checkExistsInt(item.specials.special1),
                  special2: checkExistsInt(item.specials.special2),
                  special3: checkExistsInt(item.specials.special3),
                },
              },
            };
          }
        });
        const filteredResult = result.filter((value) => value !== undefined);
        return filteredResult;
      }
      case UPGRADES_AVAILABLE: {
        const { value } = parseUpgradesAvailable(event.data, 0);
        const as = value.adventurerState;
        console.log("UPGRADES_AVAILABLE", "->", "ITEMS UPDATES");
        const newResult = value.items.map((item) =>
          insertItem({
            item: item,
            adventurerId: parseInt(as.adventurerId),
            owner: false,
            equipped: false,
            tier: gameData.ITEM_TIERS[item],
            slot: gameData.ITEM_SLOTS[item],
            type: gameData.ITEM_TYPES[item],
            ownerAddress: 0,
            xp: 0,
            greatness: 1,
            special1: 0,
            special2: 0,
            special3: 0,
            isAvailable: true,
            purchasedTime: 0,
            timestamp: new Date().toISOString(),
          })
        );
        return newResult;
      }
      case ADVENTURER_UPGRADED: {
        const { value } = parseAdventurerUpgraded(event.data, 0);
        const as = value.adventurerStateWithBag.adventurerState;
        console.log("ADVENTURER_UPGRADED", "->", "ITEMS UPDATES");
        return {
          entity: {
            adventurerId: checkExistsInt(parseInt(as.adventurerId)),
          },
          update: {
            $set: {
              adventurerId: checkExistsInt(parseInt(as.adventurerId)),
              isAvailable: false,
              timestamp: new Date().toISOString(),
            },
          },
        };
      }
      case TRANSFER: {
        const { value } = parseTransfer(event.data, 0);
        console.log("TRANSFER", "->", "ITEMS UPDATES");
        return updateItemsOwner({
          adventurerId: value.toAddress,
          newOwner: value.fromAddress,
          timestamp: new Date().toISOString(),
        });
      }
      default: {
        console.warn("Unknown event", event.keys[0]);
        return [];
      }
    }
  });
}
