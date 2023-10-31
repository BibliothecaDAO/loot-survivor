import { InvokeTransactionReceiptResponse } from "starknet";
import { GameData } from "@/app/lib/data/GameData";
import { getKeyFromValue, convertToBoolean, chunkArray } from "@/app/lib/utils";
import {
  DiscoveredHealthEvent,
  DiscoveredGoldEvent,
  StartGameEvent,
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
  UpgradesAvailableEvent,
  IdleDeathPenaltyEvent,
  AdventurerUpgradedEvent,
  ERC721TransferEvent,
} from "@/app/types/events";
import { processData } from "@/app/lib/utils/processData";
import { AdventurerClass } from "../classes";

function parseAdventurerState(data: string[]) {
  return {
    owner: data[0],
    adventurerId: parseInt(data[1]),
    adventurer: {
      lastAction: parseInt(data[2]),
      health: parseInt(data[3]),
      xp: parseInt(data[4]),
      stats: {
        strength: parseInt(data[5]),
        dexterity: parseInt(data[6]),
        vitality: parseInt(data[7]),
        intelligence: parseInt(data[8]),
        wisdom: parseInt(data[9]),
        charisma: parseInt(data[10]),
        luck: parseInt(data[11]),
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
      actionsPerBlock: parseInt(data[39]),
      mutated: convertToBoolean(parseInt(data[40])),
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
  currentAdventurer?: AdventurerClass,
  beastsContract?: string,
  event?: string
) {
  if (!receipt.events) {
    throw new Error(`No events found`);
  }
  const gameData = new GameData();

  let events: Array<any> = [];

  for (let raw of receipt.events) {
    let eventName: string | null = "";
    // If event is a Transfer, make sure it is just the beast contract that
    if (getKeyFromValue(gameData.SELECTOR_KEYS, raw.keys[0]) == "Transfer") {
      if (raw.from_address == beastsContract) {
        eventName = "Transfer";
      } else {
        eventName = null;
      }
    } else {
      if (event) {
        const eventFromKey = getKeyFromValue(
          gameData.SELECTOR_KEYS,
          raw.keys[0]
        )!;
        if (event == eventFromKey) {
          eventName = event;
        } else {
          eventName = null;
        }
      } else {
        eventName = getKeyFromValue(gameData.SELECTOR_KEYS, raw.keys[0]);
      }
    }

    switch (eventName) {
      case "StartGame":
        const startGameData: StartGameEvent = {
          adventurerState: parseAdventurerState(raw.data.slice(0, 40)),
          adventurerMeta: {
            startBlock: parseInt(raw.data[41]),
            startingStats: {
              strength: parseInt(raw.data[42]),
              dexterity: parseInt(raw.data[43]),
              vitality: parseInt(raw.data[44]),
              intelligence: parseInt(raw.data[45]),
              wisdom: parseInt(raw.data[46]),
              charisma: parseInt(raw.data[47]),
              luck: parseInt(raw.data[48]),
            },
            name: parseInt(raw.data[49]),
            interfaceCamel: convertToBoolean(parseInt(raw.data[50])),
          },
          revealBlock: parseInt(raw.data[51]),
        };
        const startGameEvent = processData(
          startGameData,
          eventName,
          receipt.transaction_hash
        );
        events.push({ name: eventName, data: startGameEvent });
        break;
      case "AdventurerUpgraded":
        const upgradeAvailableData: AdventurerUpgradedEvent = {
          adventurerStateWithBag: {
            adventurerState: parseAdventurerState(raw.data.slice(0, 40)),
            bag: parseBag(raw.data.slice(41, 74)),
          },
          strengthIncrease: parseInt(raw.data[75]),
          dexterityIncrease: parseInt(raw.data[76]),
          vitalityIncrease: parseInt(raw.data[77]),
          intelligenceIncrease: parseInt(raw.data[78]),
          wisdomIncrease: parseInt(raw.data[79]),
          charismaIncrease: parseInt(raw.data[80]),
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
          adventurerState: parseAdventurerState(raw.data.slice(0, 40)),
          healthAmount: parseInt(raw.data[41]),
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
          adventurerState: parseAdventurerState(raw.data.slice(0, 40)),
          goldAmount: parseInt(raw.data[41]),
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
          adventurerState: parseAdventurerState(raw.data.slice(0, 40)),
          xpAmount: parseInt(raw.data[41]),
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
          adventurerState: parseAdventurerState(raw.data.slice(0, 40)),
          id: parseInt(raw.data[41]),
          level: parseInt(raw.data[42]),
          damageTaken: parseInt(raw.data[43]),
          damageLocation: parseInt(raw.data[44]),
          xpEarnedAdventurer: parseInt(raw.data[45]),
          xpEarnedItems: parseInt(raw.data[46]),
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
          adventurerState: parseAdventurerState(raw.data.slice(0, 40)),
          id: parseInt(raw.data[41]),
          level: parseInt(raw.data[42]),
          damageTaken: parseInt(raw.data[43]),
          damageLocation: parseInt(raw.data[44]),
          xpEarnedAdventurer: parseInt(raw.data[45]),
          xpEarnedItems: parseInt(raw.data[46]),
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
          adventurerState: parseAdventurerState(raw.data.slice(0, 40)),
          seed: parseInt(raw.data[41]),
          id: parseInt(raw.data[42]),
          beastSpecs: {
            tier: parseInt(raw.data[43]),
            itemType: parseInt(raw.data[44]),
            level: parseInt(raw.data[45]),
            specials: {
              special1: parseInt(raw.data[46]),
              special2: parseInt(raw.data[47]),
              special3: parseInt(raw.data[48]),
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
          adventurerState: parseAdventurerState(raw.data.slice(0, 40)),
          seed: parseInt(raw.data[41]),
          id: parseInt(raw.data[42]),
          beastSpecs: {
            tier: parseInt(raw.data[43]),
            itemType: parseInt(raw.data[44]),
            level: parseInt(raw.data[45]),
            specials: {
              special1: parseInt(raw.data[46]),
              special2: parseInt(raw.data[47]),
              special3: parseInt(raw.data[48]),
            },
          },
          damage: parseInt(raw.data[49]),
          criticalHit: convertToBoolean(parseInt(raw.data[50])),
          location: parseInt(raw.data[51]),
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
          adventurerState: parseAdventurerState(raw.data.slice(0, 40)),
          seed: parseInt(raw.data[41]),
          id: parseInt(raw.data[42]),
          beastSpecs: {
            tier: parseInt(raw.data[43]),
            itemType: parseInt(raw.data[44]),
            level: parseInt(raw.data[45]),
            specials: {
              special1: parseInt(raw.data[46]),
              special2: parseInt(raw.data[47]),
              special3: parseInt(raw.data[48]),
            },
          },
          damage: parseInt(raw.data[49]),
          criticalHit: convertToBoolean(parseInt(raw.data[50])),
          location: parseInt(raw.data[51]),
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
          adventurerState: parseAdventurerState(raw.data.slice(0, 40)),
          seed: parseInt(raw.data[41]),
          id: parseInt(raw.data[42]),
          beastSpecs: {
            tier: parseInt(raw.data[43]),
            itemType: parseInt(raw.data[44]),
            level: parseInt(raw.data[45]),
            specials: {
              special1: parseInt(raw.data[46]),
              special2: parseInt(raw.data[47]),
              special3: parseInt(raw.data[48]),
            },
          },
          damage: parseInt(raw.data[49]),
          criticalHit: convertToBoolean(parseInt(raw.data[50])),
          location: parseInt(raw.data[51]),
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
          adventurerState: parseAdventurerState(raw.data.slice(0, 40)),
          seed: parseInt(raw.data[41]),
          id: parseInt(raw.data[42]),
          beastSpecs: {
            tier: parseInt(raw.data[43]),
            itemType: parseInt(raw.data[44]),
            level: parseInt(raw.data[45]),
            specials: {
              special1: parseInt(raw.data[46]),
              special2: parseInt(raw.data[47]),
              special3: parseInt(raw.data[48]),
            },
          },
          damageDealt: parseInt(raw.data[49]),
          criticalHit: convertToBoolean(parseInt(raw.data[50])),
          xpEarnedAdventurer: parseInt(raw.data[51]),
          xpEarnedItems: parseInt(raw.data[52]),
          goldEarned: parseInt(raw.data[53]),
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
          adventurerState: parseAdventurerState(raw.data.slice(0, 40)),
          seed: parseInt(raw.data[41]),
          id: parseInt(raw.data[42]),
          beastSpecs: {
            tier: parseInt(raw.data[43]),
            itemType: parseInt(raw.data[44]),
            level: parseInt(raw.data[45]),
            specials: {
              special1: parseInt(raw.data[46]),
              special2: parseInt(raw.data[47]),
              special3: parseInt(raw.data[48]),
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
          adventurerState: parseAdventurerState(raw.data.slice(0, 40)),
          seed: parseInt(raw.data[41]),
          id: parseInt(raw.data[42]),
          beastSpecs: {
            tier: parseInt(raw.data[43]),
            itemType: parseInt(raw.data[44]),
            level: parseInt(raw.data[45]),
            specials: {
              special1: parseInt(raw.data[46]),
              special2: parseInt(raw.data[47]),
              special3: parseInt(raw.data[48]),
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
            adventurerState: parseAdventurerState(raw.data.slice(0, 40)),
            bag: parseBag(raw.data.slice(41, 74)),
          },
          // Skip array length
          purchases: parseItems(raw.data.slice(76)),
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
          adventurerState: parseAdventurerState(raw.data.slice(0, 40)),
          quantity: parseInt(raw.data[41]),
          cost: parseInt(raw.data[42]),
          health: parseInt(raw.data[43]),
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
          raw.data.slice(75)
        );
        const equippedItemsData: EquippedItemsEvent = {
          adventurerStateWithBag: {
            adventurerState: parseAdventurerState(raw.data.slice(0, 40)),
            bag: parseBag(raw.data.slice(41, 74)),
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
        const itemsData = raw.data.slice(76);
        for (let i = 0; i < itemsData.length; i++) {
          itemIds.push(parseInt(itemsData[i]));
        }
        const droppedItemsData: DroppedItemsEvent = {
          adventurerStateWithBag: {
            adventurerState: parseAdventurerState(raw.data.slice(0, 40)),
            bag: parseBag(raw.data.slice(41, 74)),
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
          adventurerState: parseAdventurerState(raw.data.slice(0, 40)),
          itemId: parseInt(raw.data[41]),
          previousLevel: parseInt(raw.data[42]),
          newLevel: parseInt(raw.data[43]),
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
          adventurerState: parseAdventurerState(raw.data.slice(0, 40)),
          // Skip items length
          items: parseItemLevels(raw.data.slice(42)),
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
          adventurerState: parseAdventurerState(raw.data.slice(0, 40)),
          rank: parseInt(raw.data[41]),
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
          adventurerState: parseAdventurerState(raw.data.slice(0, 40)),
          killedByBeast: parseInt(raw.data[41]),
          killedByObstacle: parseInt(raw.data[42]),
          callerAddress: raw.data[43],
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
          adventurerState: parseAdventurerState(raw.data.slice(0, 40)),
          previousLevel: parseInt(raw.data[41]),
          newLevel: parseInt(raw.data[42]),
        };
        const adventurerLeveledUpEvent = processData(
          adventurerLeveledUpData,
          eventName,
          receipt.transaction_hash,
          currentAdventurer
        );
        events.push({ name: eventName, data: adventurerLeveledUpEvent });
        break;
      case "UpgradesAvailable":
        // Skip array length
        const newItems = raw.data.slice(42);
        const newItemsIds = [];
        for (let i = 0; i < newItems.length; i++) {
          newItemsIds.push(parseInt(newItems[i]));
        }
        const upgradesAvailableData: UpgradesAvailableEvent = {
          adventurerState: parseAdventurerState(raw.data.slice(0, 40)),
          // Skip array length
          items: newItemsIds,
        };
        const upgradesAvailableEvent = processData(
          upgradesAvailableData,
          eventName,
          receipt.transaction_hash,
          currentAdventurer
        );
        events.push({ name: eventName, data: upgradesAvailableEvent });
        break;
      case "IdleDeathPenalty":
        const idleDeathPenaltyData: IdleDeathPenaltyEvent = {
          adventurerState: parseAdventurerState(raw.data.slice(0, 40)),
          idleBlocks: parseInt(raw.data[41]),
          penaltyThreshold: parseInt(raw.data[42]),
          caller: raw.data[43],
        };
        const idleDeathPenaltyEvent = processData(
          idleDeathPenaltyData,
          eventName,
          receipt.transaction_hash,
          currentAdventurer
        );
        events.push({ name: eventName, data: idleDeathPenaltyEvent });
        break;
      case "Transfer":
        const beastTransferData: ERC721TransferEvent = {
          from: raw.data[0],
          to: raw.data[1],
          tokenId: {
            low: parseInt(raw.data[2]),
            high: parseInt(raw.data[3]),
          },
        };
        events.push({ name: eventName, data: beastTransferData });
        break;
    }
  }

  return events;
}
