import BN from "bn.js";
import { GameData } from "@/app/components/GameData";
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
  ItemSpecialUnlockedEvent,
  NewHighScoreEvent,
  AdventurerDiedEvent,
  AdventurerLeveledUpEvent,
  NewItemsAvailableEvent,
  IdleDeathPenaltyEvent,
  AdventurerUpgradedEvent,
  AdventurerState,
} from "../../types/events";
import { Adventurer } from "@/app/types";
import { feltToString } from ".";

type EventData =
  | DiscoveredHealthEvent
  | DiscoveredGoldEvent
  | StartGameEvent
  | UpgradeAvailableEvent
  | DiscoveredXPEvent
  | DodgedObstacleEvent
  | HitByObstacleEvent
  | DiscoveredBeastEvent
  | AmbushedByBeastEvent
  | AttackedBeastEvent
  | AttackedByBeastEvent
  | SlayedBeastEvent
  | FleeFailedEvent
  | FleeSucceededEvent
  | PurchasedItemsEvent
  | PurchasedPotionsEvent
  | EquippedItemsEvent
  | DroppedItemsEvent
  | GreatnessIncreasedEvent
  | ItemSpecialUnlockedEvent
  | NewHighScoreEvent
  | AdventurerDiedEvent
  | AdventurerLeveledUpEvent
  | NewItemsAvailableEvent
  | IdleDeathPenaltyEvent
  | AdventurerUpgradedEvent;

function createBaseItems(data: AdventurerState) {
  const gameData = new GameData();
  let items = [];
  for (let i = 1; i <= 101; i++) {
    items.push({
      item: gameData.ITEMS[i],
      adventurerId: data.adventurerId,
      owner: false,
      equipped: false,
      ownerAddress: data.owner,
      xp: 0,
      special1: 0,
      special2: 0,
      special3: 0,
      isAvailable: false,
      purchasedTime: 0,
      timestamp: new Date(),
    });
  }
  return items;
}

function processAdventurerState(data: any) {
  const gameData = new GameData();
  const updateAdventurerDoc: Adventurer = {
    id: data.adventurerState["adventurerId"].low,
    owner: data.adventurerState["owner"],
    lastAction: data.adventurerState["adventurer"]["lastAction"],
    health: data.adventurerState["adventurer"]["health"],
    xp: data.adventurerState["adventurer"]["xp"],
    strength: data.adventurerState["adventurer"]["stats"]["strength"],
    dexterity: data.adventurerState["adventurer"]["stats"]["dexterity"],
    vitality: data.adventurerState["adventurer"]["stats"]["vitality"],
    intelligence: data.adventurerState["adventurer"]["stats"]["intelligence"],
    wisdom: data.adventurerState["adventurer"]["stats"]["wisdom"],
    charisma: data.adventurerState["adventurer"]["stats"]["charisma"],
    gold: data.adventurerState["adventurer"]["gold"],
    weapon: gameData.ITEMS[data.adventurerState["adventurer"]["weapon"]["id"]],
    chest: gameData.ITEMS[data.adventurerState["adventurer"]["chest"]["id"]],
    head: gameData.ITEMS[data.adventurerState["adventurer"]["head"]["id"]],
    waist: gameData.ITEMS[data.adventurerState["adventurer"]["waist"]["id"]],
    foot: gameData.ITEMS[data.adventurerState["adventurer"]["foot"]["id"]],
    hand: gameData.ITEMS[data.adventurerState["adventurer"]["hand"]["id"]],
    neck: gameData.ITEMS[data.adventurerState["adventurer"]["neck"]["id"]],
    ring: gameData.ITEMS[data.adventurerState["adventurer"]["ring"]["id"]],
    beastHealth: data.adventurerState["adventurer"]["beastHealth"],
    statUpgrades: data.adventurerState["adventurer"]["statPointsAvailable"],
    lastUpdatedTime: new Date(), // Use this date for now though it is block_timestamp in indexer
    timestamp: new Date(), // Equivalent to datetime.now() in Python.
  };
  return updateAdventurerDoc;
}

export function processData(event: EventData, eventName: string) {
  const gameData = new GameData();
  switch (eventName) {
    case "StartGame":
      const startGameEvent = event as StartGameEvent;
      const updateAdventurerDoc: Adventurer = {
        id: startGameEvent.adventurerState["adventurerId"].low,
        owner: startGameEvent.adventurerState["owner"],
        lastAction: startGameEvent.adventurerState["adventurer"]["lastAction"],
        health: startGameEvent.adventurerState["adventurer"]["health"],
        xp: startGameEvent.adventurerState["adventurer"]["xp"],
        strength:
          startGameEvent.adventurerState["adventurer"]["stats"]["strength"],
        dexterity:
          startGameEvent.adventurerState["adventurer"]["stats"]["dexterity"],
        vitality:
          startGameEvent.adventurerState["adventurer"]["stats"]["vitality"],
        intelligence:
          startGameEvent.adventurerState["adventurer"]["stats"]["intelligence"],
        wisdom: startGameEvent.adventurerState["adventurer"]["stats"]["wisdom"],
        charisma:
          startGameEvent.adventurerState["adventurer"]["stats"]["charisma"],
        gold: startGameEvent.adventurerState["adventurer"]["gold"],
        weapon:
          gameData.ITEMS[
            startGameEvent.adventurerState["adventurer"]["weapon"]["id"]
          ],
        chest:
          gameData.ITEMS[
            startGameEvent.adventurerState["adventurer"]["chest"]["id"]
          ],
        head: gameData.ITEMS[
          startGameEvent.adventurerState["adventurer"]["head"]["id"]
        ],
        waist:
          gameData.ITEMS[
            startGameEvent.adventurerState["adventurer"]["waist"]["id"]
          ],
        foot: gameData.ITEMS[
          startGameEvent.adventurerState["adventurer"]["foot"]["id"]
        ],
        hand: gameData.ITEMS[
          startGameEvent.adventurerState["adventurer"]["hand"]["id"]
        ],
        neck: gameData.ITEMS[
          startGameEvent.adventurerState["adventurer"]["neck"]["id"]
        ],
        ring: gameData.ITEMS[
          startGameEvent.adventurerState["adventurer"]["ring"]["id"]
        ],
        beastHealth:
          startGameEvent.adventurerState["adventurer"]["beastHealth"],
        statUpgrades:
          startGameEvent.adventurerState["adventurer"]["statPointsAvailable"],
        name: feltToString(new BN(startGameEvent.adventurerMeta["name"])),
        homeRealm: startGameEvent.adventurerMeta["homeRealm"],
        classType: gameData.CLASSES[startGameEvent.adventurerMeta["class"]],
        entropy: startGameEvent.adventurerMeta["entropy"],
        createdTime: new Date(),
        lastUpdatedTime: new Date(), // Use this date for now though it is block_timestamp in indexer
        timestamp: new Date(),
      };
      const items = createBaseItems(startGameEvent.adventurerState);
      return [updateAdventurerDoc, items];
    case "AdventurerUpgraded":
      const adventurerUpgradedEvent = event as AdventurerUpgradedEvent;
      return processAdventurerState(adventurerUpgradedEvent);
    case "DiscoveredHealth":
      const discoveredHealthEvent = event as DiscoveredHealthEvent;
      return processAdventurerState(discoveredHealthEvent);
    case "DiscoveredGold":
      const discoveredGoldEvent = event as DiscoveredGoldEvent;
      return processAdventurerState(discoveredGoldEvent);
    case "DiscoveredXP":
      const discoveredXPEvent = event as DiscoveredXPEvent;
      return processAdventurerState(discoveredXPEvent);
    case "DodgedObstacle":
      const dodgedObstacleEvent = event as DodgedObstacleEvent;
      return processAdventurerState(dodgedObstacleEvent);
    case "HitByObstacle":
      const hitByObstacleEvent = event as HitByObstacleEvent;
      return processAdventurerState(hitByObstacleEvent);
    case "DiscoveredBeast":
      const discoveredBeastEvent = event as DiscoveredBeastEvent;
      return processAdventurerState(discoveredBeastEvent);
    case "AmbushedByBeast":
      const ambushedByBeastEvent = event as AmbushedByBeastEvent;
      return processAdventurerState(ambushedByBeastEvent);
    case "AttackedBeast":
      const attackedBeastEvent = event as AttackedBeastEvent;
      return processAdventurerState(attackedBeastEvent);
    case "AttackedByBeast":
      const AttackedByBeastEvent = event as AttackedByBeastEvent;
      return processAdventurerState(AttackedByBeastEvent);
    case "SlayedBeast":
      const slayedBeastEvent = event as SlayedBeastEvent;
      return processAdventurerState(slayedBeastEvent);
    case "FleeFailed":
      const fleeFailedEvent = event as FleeFailedEvent;
      return processAdventurerState(fleeFailedEvent);
    case "FleeSucceeded":
      const fleeSucceededEvent = event as FleeSucceededEvent;
      return processAdventurerState(fleeSucceededEvent);
    case "PurchasedItems":
      const purchasedItemsEvent = event as PurchasedItemsEvent;
      return processAdventurerState(purchasedItemsEvent);
    case "PurchasedPotions":
      const purchasedPotionsEvent = event as PurchasedPotionsEvent;
      return processAdventurerState(purchasedPotionsEvent);
    case "EquippedItems":
      const equippedItemsEvent = event as EquippedItemsEvent;
      return processAdventurerState(equippedItemsEvent);
    case "DroppedItems":
      const droppedItemsEvent = event as DroppedItemsEvent;
      return processAdventurerState(droppedItemsEvent);
    case "GreatnessIncreased":
      const greatnessIncreasedEvent = event as GreatnessIncreasedEvent;
      return processAdventurerState(greatnessIncreasedEvent);
    case "ItemSpecialUnlocked":
      const itemsSpecialUnlockedEvent = event as ItemSpecialUnlockedEvent;
      return processAdventurerState(itemsSpecialUnlockedEvent);
    case "NewHighScore":
      const newHishScoreEvent = event as NewHighScoreEvent;
      return processAdventurerState(newHishScoreEvent);
    case "AdventurerDied":
      const adventurerDiedEvent = event as AdventurerDiedEvent;
      return processAdventurerState(adventurerDiedEvent);
    case "AdventurerLeveledUp":
      const adventurerLeveledUpEvent = event as AdventurerLeveledUpEvent;
      return processAdventurerState(adventurerLeveledUpEvent);
    case "NewItemsAvailable":
      const newItemsAvailableEvent = event as NewItemsAvailableEvent;
      return processAdventurerState(newItemsAvailableEvent);
    case "IdleDeathPenalty":
      const idleDeathPenaltyEvent = event as IdleDeathPenaltyEvent;
      return processAdventurerState(idleDeathPenaltyEvent);
  }
}
