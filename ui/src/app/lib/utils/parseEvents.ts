import { InvokeTransactionReceiptResponse } from "starknet";
import { GameData } from "../../components/GameData";
import { getKeyFromValue, convertToBoolean, chunkArray } from ".";
import {
  DiscoveredHealthEvent,
  DiscoveredGoldEvent,
  StartGameEvent,
  UpgradeAvailableEvent,
  DiscoveredXPEvent,
  DodgedObstacleEvent,
  HitByObstacleEvent,
  DiscoveredBeastEvent,
  AmbushedByBeastEvent,
  AttackedBeastEvent,
  AttackedByBeastEvent,
  SlayedBeastEvent,
  FleeFailedEvent,
  FleeSucceededEvent,
  PurchasedItemsEvent,
  PurchasedPotionsEvent,
  EquippedItemsEvent,
  DroppedItemsEvent,
  GreatnessIncreasedEvent,
  ItemsLeveledUpEvent,
  NewHighScoreEvent,
  AdventurerDiedEvent,
  AdventurerLeveledUpEvent,
  NewItemsAvailableEvent,
  IdleDeathPenaltyEvent,
} from "../../types/events";
import { processData } from "./processData";

function parseAdventurerState(data: string[]) {
  return {
    owner: data[0],
    adventurerId: {
      low: parseInt(data[1]),
      high: parseInt(data[2]),
    },
    adventurer: {
      lastAction: parseInt(data[3]),
      health: parseInt(data[4]),
      xp: parseInt(data[5]),
      stats: {
        strength: parseInt(data[6]),
        dexterity: parseInt(data[7]),
        vitality: parseInt(data[8]),
        intelligence: parseInt(data[9]),
        wisdom: parseInt(data[10]),
        charisma: parseInt(data[11]),
      },
      gold: parseInt(data[12]),
      weapon: {
        id: parseInt(data[13]),
        xp: parseInt(data[14]),
        metadata: parseInt(data[15]),
      },
      chest: {
        id: parseInt(data[16]),
        xp: parseInt(data[17]),
        metadata: parseInt(data[18]),
      },
      head: {
        id: parseInt(data[19]),
        xp: parseInt(data[20]),
        metadata: parseInt(data[21]),
      },
      waist: {
        id: parseInt(data[22]),
        xp: parseInt(data[23]),
        metadata: parseInt(data[24]),
      },
      foot: {
        id: parseInt(data[25]),
        xp: parseInt(data[26]),
        metadata: parseInt(data[27]),
      },
      hand: {
        id: parseInt(data[28]),
        xp: parseInt(data[29]),
        metadata: parseInt(data[30]),
      },
      neck: {
        id: parseInt(data[31]),
        xp: parseInt(data[32]),
        metadata: parseInt(data[33]),
      },
      ring: {
        id: parseInt(data[34]),
        xp: parseInt(data[35]),
        metadata: parseInt(data[36]),
      },
      beastHealth: parseInt(data[37]),
      statPointsAvailable: parseInt(data[38]),
      mutated: convertToBoolean(parseInt(data[39])),
    },
  };
}

function parseBag(data: string[]) {
  return {
    item1: {
      id: parseInt(data[0]),
      xp: parseInt(data[1]),
      metadata: parseInt(data[2]),
    },
    item2: {
      id: parseInt(data[3]),
      xp: parseInt(data[4]),
      metadata: parseInt(data[5]),
    },
    item3: {
      id: parseInt(data[6]),
      xp: parseInt(data[7]),
      metadata: parseInt(data[8]),
    },
    item4: {
      id: parseInt(data[9]),
      xp: parseInt(data[10]),
      metadata: parseInt(data[11]),
    },
    item5: {
      id: parseInt(data[12]),
      xp: parseInt(data[13]),
      metadata: parseInt(data[14]),
    },
    item6: {
      id: parseInt(data[15]),
      xp: parseInt(data[16]),
      metadata: parseInt(data[17]),
    },
    item7: {
      id: parseInt(data[18]),
      xp: parseInt(data[19]),
      metadata: parseInt(data[20]),
    },
    item8: {
      id: parseInt(data[21]),
      xp: parseInt(data[22]),
      metadata: parseInt(data[23]),
    },
    item9: {
      id: parseInt(data[24]),
      xp: parseInt(data[25]),
      metadata: parseInt(data[26]),
    },
    item10: {
      id: parseInt(data[27]),
      xp: parseInt(data[28]),
      metadata: parseInt(data[29]),
    },
    item11: {
      id: parseInt(data[30]),
      xp: parseInt(data[31]),
      metadata: parseInt(data[32]),
    },
    mutated: convertToBoolean(parseInt(data[33])),
  };
}

function parseItems(data: string[]) {
  const purchases = [];
  const chunkedArray = chunkArray(data, 5);
  for (let i = 0; i < chunkedArray.length; i++) {
    purchases.push({
      item: {
        id: parseInt(chunkedArray[i][0]),
        tier: parseInt(chunkedArray[i][1]),
        itemType: parseInt(chunkedArray[i][2]),
        slot: parseInt(chunkedArray[i][3]),
      },
      price: parseInt(chunkedArray[i][4]),
    });
  }
  return purchases;
}

function parseItemLevels(data: string[]) {
  const itemLevels = [];
  const chunkedArray = chunkArray(data, 8);
  for (let i = 0; i < chunkedArray.length; i++) {
    itemLevels.push({
      itemId: parseInt(chunkedArray[i][0]),
      previousLevel: parseInt(chunkedArray[i][1]),
      newLevel: parseInt(chunkedArray[i][2]),
      suffixUnlocked: convertToBoolean(parseInt(chunkedArray[i][3])),
      prefixesUnlocked: convertToBoolean(parseInt(chunkedArray[i][4])),
      specials: {
        special1: parseInt(chunkedArray[i][5]),
        special2: parseInt(chunkedArray[i][6]),
        special3: parseInt(chunkedArray[i][7]),
      },
    });
  }
  return itemLevels;
}

function parseEquippedItems(data: string[]) {
  const equippedLength = parseInt(data[0]);
  const equippedItems = [];
  const unequippedItems = [];
  for (let i = 1; i <= equippedLength; i++) {
    equippedItems.push(parseInt(data[i]));
  }
  const unequippedLength = parseInt(data[equippedLength + 1]);
  for (let i = 2; i <= unequippedLength + 1; i++) {
    unequippedItems.push(parseInt(data[i + equippedLength]));
  }
  return { equippedItems, unequippedItems };
}

export async function parseEvents(
  receipt: InvokeTransactionReceiptResponse,
  currentAdventurer?: any
) {
  if (!receipt.events) {
    throw new Error(`No events found`);
  }
  const gameData = new GameData();

  let events: Array<any> = [];

  for (let raw of receipt.events) {
    const eventName = getKeyFromValue(gameData.SELECTOR_KEYS, raw.keys[0]);

    switch (eventName) {
      case "StartGame":
        const startGameData: StartGameEvent = {
          adventurerState: parseAdventurerState(raw.data.slice(0, 39)),
          adventurerMeta: {
            name: parseInt(raw.data[40]),
            homeRealm: parseInt(raw.data[41]),
            class: parseInt(raw.data[42]),
            entropy: parseInt(raw.data[43]),
          },
        };
        const startGameEvent = processData(
          startGameData,
          eventName,
          receipt.transaction_hash
        );
        events.push({ name: eventName, data: startGameEvent });
        break;
      case "AdventurerUpgraded":
        const upgradeAvailableData: UpgradeAvailableEvent = {
          adventurerState: parseAdventurerState(raw.data.slice(0, 39)),
        };
        const upgradeAvailableEvent = processData(
          upgradeAvailableData,
          eventName,
          receipt.transaction_hash,
          currentAdventurer
        );
        events.push({ name: eventName, data: upgradeAvailableEvent });
        break;
      case "DiscoveredHealth":
        const discoveredHealthData: DiscoveredHealthEvent = {
          adventurerState: parseAdventurerState(raw.data.slice(0, 39)),
          healthAmount: parseInt(raw.data[40]),
        };
        const discoveredHealthEvent = processData(
          discoveredHealthData,
          eventName,
          receipt.transaction_hash,
          currentAdventurer
        );
        events.push({ name: eventName, data: discoveredHealthEvent });
        break;
      case "DiscoveredGold":
        const discoveredGoldData: DiscoveredGoldEvent = {
          adventurerState: parseAdventurerState(raw.data.slice(0, 39)),
          goldAmount: parseInt(raw.data[40]),
        };
        const discoveredGoldEvent = processData(
          discoveredGoldData,
          eventName,
          receipt.transaction_hash,
          currentAdventurer
        );
        events.push({ name: eventName, data: discoveredGoldEvent });
        break;
      case "DiscoveredXP":
        const discoveredXPData: DiscoveredXPEvent = {
          adventurerState: parseAdventurerState(raw.data.slice(0, 39)),
          xpAmount: parseInt(raw.data[40]),
        };
        const discoveredXPEvent = processData(
          discoveredXPData,
          eventName,
          receipt.transaction_hash,
          currentAdventurer
        );
        events.push({ name: eventName, data: discoveredXPEvent });
        break;
      case "DodgedObstacle":
        const dodgedObstacleData: DodgedObstacleEvent = {
          adventurerState: parseAdventurerState(raw.data.slice(0, 39)),
          id: parseInt(raw.data[40]),
          level: parseInt(raw.data[41]),
          damageTaken: parseInt(raw.data[42]),
          damageLocation: parseInt(raw.data[43]),
          xpEarnedAdventurer: parseInt(raw.data[44]),
          xpEarnedItems: parseInt(raw.data[45]),
        };
        const dodgedObstacleEvent = processData(
          dodgedObstacleData,
          eventName,
          receipt.transaction_hash,
          currentAdventurer
        );
        events.push({ name: eventName, data: dodgedObstacleEvent });
        break;
      case "HitByObstacle":
        const hitByObstacleData: HitByObstacleEvent = {
          adventurerState: parseAdventurerState(raw.data.slice(0, 39)),
          id: parseInt(raw.data[40]),
          level: parseInt(raw.data[41]),
          damageTaken: parseInt(raw.data[42]),
          damageLocation: parseInt(raw.data[43]),
          xpEarnedAdventurer: parseInt(raw.data[44]),
          xpEarnedItems: parseInt(raw.data[45]),
        };
        const hitByObstacleEvent = processData(
          hitByObstacleData,
          eventName,
          receipt.transaction_hash,
          currentAdventurer
        );
        events.push({ name: eventName, data: hitByObstacleEvent });
        break;
      case "DiscoveredBeast":
        const discoveredBeastData: DiscoveredBeastEvent = {
          adventurerState: parseAdventurerState(raw.data.slice(0, 39)),
          seed: parseInt(raw.data[40]),
          id: parseInt(raw.data[41]),
          beastSpecs: {
            tier: parseInt(raw.data[42]),
            itemType: parseInt(raw.data[43]),
            level: parseInt(raw.data[44]),
            specials: {
              special1: parseInt(raw.data[45]),
              special2: parseInt(raw.data[46]),
              special3: parseInt(raw.data[47]),
            },
          },
        };
        const discoveredBeastEvent = processData(
          discoveredBeastData,
          eventName,
          receipt.transaction_hash,
          currentAdventurer
        );
        events.push({ name: eventName, data: discoveredBeastEvent });
        break;
      case "AmbushedByBeast":
        const ambushedByBeastData: AmbushedByBeastEvent = {
          adventurerState: parseAdventurerState(raw.data.slice(0, 39)),
          seed: parseInt(raw.data[40]),
          id: parseInt(raw.data[41]),
          beastSpecs: {
            tier: parseInt(raw.data[42]),
            itemType: parseInt(raw.data[43]),
            level: parseInt(raw.data[44]),
            specials: {
              special1: parseInt(raw.data[45]),
              special2: parseInt(raw.data[46]),
              special3: parseInt(raw.data[47]),
            },
          },
          damage: parseInt(raw.data[48]),
          criticalHit: convertToBoolean(parseInt(raw.data[49])),
          location: parseInt(raw.data[50]),
        };
        const ambushedByBeastEvent = processData(
          ambushedByBeastData,
          eventName,
          receipt.transaction_hash,
          currentAdventurer
        );
        events.push({ name: eventName, data: ambushedByBeastEvent });
        break;
      case "AttackedBeast":
        const attackedBeastData: AttackedBeastEvent = {
          adventurerState: parseAdventurerState(raw.data.slice(0, 39)),
          seed: parseInt(raw.data[40]),
          id: parseInt(raw.data[41]),
          beastSpecs: {
            tier: parseInt(raw.data[42]),
            itemType: parseInt(raw.data[43]),
            level: parseInt(raw.data[44]),
            specials: {
              special1: parseInt(raw.data[45]),
              special2: parseInt(raw.data[46]),
              special3: parseInt(raw.data[47]),
            },
          },
          damage: parseInt(raw.data[48]),
          criticalHit: convertToBoolean(parseInt(raw.data[49])),
          location: parseInt(raw.data[50]),
        };
        const attackedBeastEvent = processData(
          attackedBeastData,
          eventName,
          receipt.transaction_hash,
          currentAdventurer
        );
        events.push({ name: eventName, data: attackedBeastEvent });
        break;
      case "AttackedByBeast":
        const attackedByBeastData: AttackedByBeastEvent = {
          adventurerState: parseAdventurerState(raw.data.slice(0, 39)),
          seed: parseInt(raw.data[40]),
          id: parseInt(raw.data[41]),
          beastSpecs: {
            tier: parseInt(raw.data[42]),
            itemType: parseInt(raw.data[43]),
            level: parseInt(raw.data[44]),
            specials: {
              special1: parseInt(raw.data[45]),
              special2: parseInt(raw.data[46]),
              special3: parseInt(raw.data[47]),
            },
          },
          damage: parseInt(raw.data[48]),
          criticalHit: convertToBoolean(parseInt(raw.data[49])),
          location: parseInt(raw.data[50]),
        };
        const attackedByBeastEvent = processData(
          attackedByBeastData,
          eventName,
          receipt.transaction_hash,
          currentAdventurer
        );
        events.push({ name: eventName, data: attackedByBeastEvent });
        break;
      case "SlayedBeast":
        const slayedBeastData: SlayedBeastEvent = {
          adventurerState: parseAdventurerState(raw.data.slice(0, 39)),
          seed: parseInt(raw.data[40]),
          id: parseInt(raw.data[41]),
          beastSpecs: {
            tier: parseInt(raw.data[42]),
            itemType: parseInt(raw.data[43]),
            level: parseInt(raw.data[44]),
            specials: {
              special1: parseInt(raw.data[45]),
              special2: parseInt(raw.data[46]),
              special3: parseInt(raw.data[47]),
            },
          },
          damageDealt: parseInt(raw.data[48]),
          criticalHit: convertToBoolean(parseInt(raw.data[49])),
          xpEarnedAdventurer: parseInt(raw.data[50]),
          xpEarnedItems: parseInt(raw.data[51]),
          goldEarned: parseInt(raw.data[52]),
        };
        const slayedBeastEvent = processData(
          slayedBeastData,
          eventName,
          receipt.transaction_hash,
          currentAdventurer
        );
        events.push({ name: eventName, data: slayedBeastEvent });
        break;
      case "FleeFailed":
        const fleeFailedData: FleeFailedEvent = {
          adventurerState: parseAdventurerState(raw.data.slice(0, 39)),
          seed: parseInt(raw.data[40]),
          id: parseInt(raw.data[41]),
          beastSpecs: {
            tier: parseInt(raw.data[42]),
            itemType: parseInt(raw.data[43]),
            level: parseInt(raw.data[44]),
            specials: {
              special1: parseInt(raw.data[45]),
              special2: parseInt(raw.data[46]),
              special3: parseInt(raw.data[47]),
            },
          },
        };
        const fleeFailedEvent = processData(
          fleeFailedData,
          eventName,
          receipt.transaction_hash,
          currentAdventurer
        );
        events.push({ name: eventName, data: fleeFailedEvent });
        break;
      case "FleeSucceeded":
        const fleeSucceededData: FleeSucceededEvent = {
          adventurerState: parseAdventurerState(raw.data.slice(0, 39)),
          seed: parseInt(raw.data[40]),
          id: parseInt(raw.data[41]),
          beastSpecs: {
            tier: parseInt(raw.data[42]),
            itemType: parseInt(raw.data[43]),
            level: parseInt(raw.data[44]),
            specials: {
              special1: parseInt(raw.data[45]),
              special2: parseInt(raw.data[46]),
              special3: parseInt(raw.data[47]),
            },
          },
        };
        const fleeSucceededEvent = processData(
          fleeSucceededData,
          eventName,
          receipt.transaction_hash,
          currentAdventurer
        );
        events.push({ name: eventName, data: fleeSucceededEvent });
        break;
      case "PurchasedItems":
        const purchasedItemsData: PurchasedItemsEvent = {
          adventurerStateWithBag: {
            adventurerState: parseAdventurerState(raw.data.slice(0, 39)),
            bag: parseBag(raw.data.slice(40, 73)),
          },
          // Skip array length
          purchases: parseItems(raw.data.slice(75)),
        };
        const purchasedItemsEvent = processData(
          purchasedItemsData,
          eventName,
          receipt.transaction_hash,
          currentAdventurer
        );
        events.push({ name: eventName, data: purchasedItemsEvent });
        break;
      case "PurchasedPotions":
        const purchasedPotionsData: PurchasedPotionsEvent = {
          adventurerState: parseAdventurerState(raw.data.slice(0, 39)),
          quantity: parseInt(raw.data[40]),
          cost: parseInt(raw.data[41]),
          health: parseInt(raw.data[42]),
        };
        const purchasedPotionsEvent = processData(
          purchasedPotionsData,
          eventName,
          receipt.transaction_hash,
          currentAdventurer
        );
        events.push({ name: eventName, data: purchasedPotionsEvent });
        break;
      case "EquippedItems":
        const { equippedItems, unequippedItems } = parseEquippedItems(
          // Include equipped array length
          raw.data.slice(74)
        );
        const equippedItemsData: EquippedItemsEvent = {
          adventurerStateWithBag: {
            adventurerState: parseAdventurerState(raw.data.slice(0, 39)),
            bag: parseBag(raw.data.slice(40, 73)),
          },
          equippedItems: equippedItems,
          unequippedItems: unequippedItems,
        };
        const equippedItemsEvent = processData(
          equippedItemsData,
          eventName,
          receipt.transaction_hash,
          currentAdventurer
        );
        events.push({ name: eventName, data: equippedItemsEvent });
        break;
      case "DroppedItems":
        const itemIds = [];
        // Skip array length
        const itemsData = raw.data.slice(75);
        for (let i = 0; i < itemsData.length; i++) {
          itemIds.push(parseInt(itemsData[i]));
        }
        const droppedItemsData: DroppedItemsEvent = {
          adventurerStateWithBag: {
            adventurerState: parseAdventurerState(raw.data.slice(0, 39)),
            bag: parseBag(raw.data.slice(40, 73)),
          },
          itemIds: itemIds,
        };
        const droppedItemsEvent = processData(
          droppedItemsData,
          eventName,
          receipt.transaction_hash,
          currentAdventurer
        );
        events.push({ name: eventName, data: droppedItemsEvent });
        break;
      case "GreatnessIncreased":
        const greatnessIncreasedData: GreatnessIncreasedEvent = {
          adventurerState: parseAdventurerState(raw.data.slice(0, 39)),
          itemId: parseInt(raw.data[40]),
          previousLevel: parseInt(raw.data[41]),
          newLevel: parseInt(raw.data[42]),
        };
        const greatnessIncreasedEvent = processData(
          greatnessIncreasedData,
          eventName,
          receipt.transaction_hash,
          currentAdventurer
        );
        events.push({ name: eventName, data: greatnessIncreasedEvent });
        break;
      case "ItemsLeveledUp":
        const itemsLeveledUpData: ItemsLeveledUpEvent = {
          adventurerState: parseAdventurerState(raw.data.slice(0, 39)),
          // Skip items length
          items: parseItemLevels(raw.data.slice(41)),
        };
        const itemsLeveledUpEvent = processData(
          itemsLeveledUpData,
          eventName,
          receipt.transaction_hash,
          currentAdventurer
        );
        events.push({ name: eventName, data: itemsLeveledUpEvent });
        break;
      case "NewHighScore":
        const newHighScoreData: NewHighScoreEvent = {
          adventurerState: parseAdventurerState(raw.data.slice(0, 39)),
          rank: parseInt(raw.data[40]),
        };
        const newHighScoreEvent = processData(
          newHighScoreData,
          eventName,
          receipt.transaction_hash,
          currentAdventurer
        );
        events.push({ name: eventName, data: newHighScoreEvent });
        break;
      case "AdventurerDied":
        const adventurerDiedData: AdventurerDiedEvent = {
          adventurerState: parseAdventurerState(raw.data.slice(0, 39)),
          killedByBeast: parseInt(raw.data[40]),
          killedByObstacle: parseInt(raw.data[41]),
          callerAddress: raw.data[42],
        };
        const adventurerDiedEvent = processData(
          adventurerDiedData,
          eventName,
          receipt.transaction_hash,
          currentAdventurer
        );
        events.push({ name: eventName, data: adventurerDiedEvent });
        break;
      case "AdventurerLeveledUp":
        const adventurerLeveledUpData: AdventurerLeveledUpEvent = {
          adventurerState: parseAdventurerState(raw.data.slice(0, 39)),
          previousLevel: parseInt(raw.data[40]),
          newLevel: parseInt(raw.data[41]),
        };
        const adventurerLeveledUpEvent = processData(
          adventurerLeveledUpData,
          eventName,
          receipt.transaction_hash,
          currentAdventurer
        );
        events.push({ name: eventName, data: adventurerLeveledUpEvent });
        break;
      case "NewItemsAvailable":
        const newItems = raw.data.slice(41);
        const newItemsIds = [];
        for (let i = 0; i < newItems.length; i++) {
          newItemsIds.push(parseInt(newItems[i]));
        }
        const newItemsAvailableData: NewItemsAvailableEvent = {
          adventurerState: parseAdventurerState(raw.data.slice(0, 39)),
          // Skip array length
          items: newItemsIds,
        };
        const newItemsAvailableEvent = processData(
          newItemsAvailableData,
          eventName,
          receipt.transaction_hash,
          currentAdventurer
        );
        events.push({ name: eventName, data: newItemsAvailableEvent });
        break;
      case "IdleDeathPenalty":
        const idleDeathPenaltyData: IdleDeathPenaltyEvent = {
          adventurerState: parseAdventurerState(raw.data.slice(0, 39)),
          idleBlocks: parseInt(raw.data[40]),
          penaltyThreshold: parseInt(raw.data[41]),
          caller: raw.data[42],
        };
        const idleDeathPenaltyEvent = processData(
          idleDeathPenaltyData,
          eventName,
          receipt.transaction_hash,
          currentAdventurer
        );
        events.push({ name: eventName, data: idleDeathPenaltyEvent });
        break;
    }
  }

  return events;
}
