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

export function processData(
  event: EventData,
  eventName: string,
  txHash?: string
) {
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
      const discoveredHealthAdventurerData = processAdventurerState(
        discoveredHealthEvent
      );
      const discoverHealthData = {
        txHash: txHash,
        adventurerId: discoveredHealthEvent.adventurerState["adventurerId"],
        adventurerHealth:
          discoveredHealthEvent.adventurerState["adventurer"]["health"],
        discoveryType: gameData.DISCOVERY_TYPES[3],
        subDiscoveryType: gameData.ITEM_DISCOVERY_TYPES[1],
        outputAmount: discoveredHealthEvent.healthAmount,
        obstacle: null,
        obstacleLevel: null,
        dodgedObstacle: false,
        damageTaken: 0,
        damageLocation: null,
        xpEarnedAdventurer: null,
        xpEarnedItems: null,
        entity: null,
        entityLevel: null,
        entityHealth: 0,
        special1: null,
        special2: null,
        special3: null,
        ambushed: null,
        seed: 0,
        discoveryTime: new Date(),
        timestamp: new Date(),
      };
      return [discoveredHealthAdventurerData, discoverHealthData];
    case "DiscoveredGold":
      const discoveredGoldEvent = event as DiscoveredGoldEvent;
      const discoveredGoldAdventurerData =
        processAdventurerState(discoveredGoldEvent);
      const discoverGoldData = {
        txHash: txHash,
        adventurerId: discoveredGoldEvent.adventurerState["adventurerId"],
        adventurerHealth:
          discoveredGoldEvent.adventurerState["adventurer"]["health"],
        discoveryType: gameData.DISCOVERY_TYPES[3],
        subDiscoveryType: gameData.ITEM_DISCOVERY_TYPES[2],
        outputAmount: discoveredGoldEvent.goldAmount,
        obstacle: null,
        obstacleLevel: null,
        dodgedObstacle: false,
        damageTaken: 0,
        damageLocation: null,
        xpEarnedAdventurer: null,
        xpEarnedItems: null,
        entity: null,
        entityLevel: null,
        entityHealth: 0,
        special1: null,
        special2: null,
        special3: null,
        ambushed: null,
        seed: 0,
        discoveryTime: new Date(),
        timestamp: new Date(),
      };

      return [discoveredGoldAdventurerData, discoverGoldData];
    case "DiscoveredXP":
      const discoveredXPEvent = event as DiscoveredXPEvent;
      const discoveredXPAdventurerData =
        processAdventurerState(discoveredXPEvent);
      const discoverXPData = {
        txHash: txHash,
        adventurerId: discoveredXPEvent.adventurerState["adventurerId"],
        adventurerHealth:
          discoveredXPEvent.adventurerState["adventurer"]["health"],
        discoveryType: gameData.DISCOVERY_TYPES[3],
        subDiscoveryType: gameData.ITEM_DISCOVERY_TYPES[3],
        outputAmount: discoveredXPEvent.xpAmount,
        obstacle: null,
        obstacleLevel: null,
        dodgedObstacle: false,
        damageTaken: 0,
        damageLocation: null,
        xpEarnedAdventurer: null,
        xpEarnedItems: null,
        entity: null,
        entityLevel: null,
        entityHealth: 0,
        special1: null,
        special2: null,
        special3: null,
        ambushed: null,
        seed: 0,
        discoveryTime: new Date(),
        timestamp: new Date(),
      };

      return [discoveredXPAdventurerData, discoverXPData];
    case "DodgedObstacle":
      const dodgedObstacleEvent = event as DodgedObstacleEvent;
      const dodgedObstacleAdventurerData =
        processAdventurerState(dodgedObstacleEvent);
      const dodgedObstacleData = {
        txHash: txHash,
        adventurerId: dodgedObstacleEvent.adventurerState["adventurerId"],
        adventurerHealth:
          dodgedObstacleEvent.adventurerState["adventurer"]["health"],
        discoveryType: gameData.DISCOVERY_TYPES[2],
        subDiscoveryType: null,
        outputAmount: 0,
        obstacle: dodgedObstacleEvent.id,
        obstacleLevel: dodgedObstacleEvent.level,
        dodgedObstacle: 1,
        damageTaken: dodgedObstacleEvent.damageTaken,
        damageLocation: dodgedObstacleEvent.damageLocation,
        xpEarnedAdventurer: dodgedObstacleEvent.xpEarnedAdventurer,
        xpEarnedItems: dodgedObstacleEvent.xpEarnedItems,
        entity: null,
        entityLevel: null,
        entityHealth: 0,
        special1: null,
        special2: null,
        special3: null,
        ambushed: null,
        seed: 0,
        discoveryTime: new Date(),
        timestamp: new Date(),
      };

      return [dodgedObstacleAdventurerData, dodgedObstacleData];
    case "HitByObstacle":
      const hitByObstacleEvent = event as HitByObstacleEvent;
      const hitByObstacleAdventurerData =
        processAdventurerState(hitByObstacleEvent);
      const hitByObstacleData = {
        txHash: txHash,
        adventurerId: hitByObstacleEvent.adventurerState["adventurerId"],
        adventurerHealth:
          hitByObstacleEvent.adventurerState["adventurer"]["health"],
        discoveryType: gameData.DISCOVERY_TYPES[2],
        subDiscoveryType: null,
        outputAmount: 0,
        obstacle: hitByObstacleEvent.id,
        obstacleLevel: hitByObstacleEvent.level,
        dodgedObstacle: 0,
        damageTaken: hitByObstacleEvent.damageTaken,
        damageLocation: hitByObstacleEvent.damageLocation,
        xpEarnedAdventurer: hitByObstacleEvent.xpEarnedAdventurer,
        xpEarnedItems: hitByObstacleEvent.xpEarnedItems,
        entity: null,
        entityLevel: null,
        entityHealth: 0,
        special1: null,
        special2: null,
        special3: null,
        ambushed: null,
        seed: 0,
        discoveryTime: new Date(),
        timestamp: new Date(),
      };

      return [hitByObstacleAdventurerData, hitByObstacleData];
    case "DiscoveredBeast":
      const discoveredBeastEvent = event as DiscoveredBeastEvent;
      const discoveredBeastAdventurerData =
        processAdventurerState(discoveredBeastEvent);
      const discoveredBeastData = {
        txHash: txHash,
        adventurerId: discoveredBeastEvent.adventurerState["adventurerId"],
        adventurerHealth:
          discoveredBeastEvent.adventurerState["adventurer"]["health"],
        discoveryType: gameData.DISCOVERY_TYPES[1],
        subDiscoveryType: null,
        outputAmount: 0,
        obstacle: null,
        obstacleLevel: null,
        dodgedObstacle: 0,
        damageTaken: 0,
        damageLocation: null,
        xpEarnedAdventurer: null,
        xpEarnedItems: null,
        entity: gameData.BEASTS[discoveredBeastEvent.id],
        entityLevel: discoveredBeastEvent.beastSpecs["level"],
        entityHealth:
          discoveredBeastEvent.adventurerState["adventurer"]["beastHealth"],
        special1: discoveredBeastEvent.beastSpecs["specials"]["special1"],
        special2: discoveredBeastEvent.beastSpecs["specials"]["special2"],
        special3: discoveredBeastEvent.beastSpecs["specials"]["special3"],
        ambushed: null,
        seed: discoveredBeastEvent.seed,
        discoveryTime: new Date(),
        timestamp: new Date(),
      };
      const discoveredBeastBeastData = {
        beast: gameData.BEASTS[discoveredBeastEvent.id],
        health:
          discoveredBeastEvent.adventurerState["adventurer"]["beastHealth"],
        level: discoveredBeastEvent.beastSpecs["level"],
        special1: discoveredBeastEvent.beastSpecs["specials"]["special1"],
        special2: discoveredBeastEvent.beastSpecs["specials"]["special2"],
        special3: discoveredBeastEvent.beastSpecs["specials"]["special3"],
        seed: discoveredBeastEvent.seed,
        adventurerId: discoveredBeastEvent.adventurerState["adventurerId"],
        slainOnTime: null,
        createdTime: new Date(),
        lastUpdatedTime: new Date(),
        timestamp: new Date(),
      };
      return [
        discoveredBeastAdventurerData,
        discoveredBeastData,
        discoveredBeastBeastData,
      ];
    case "AmbushedByBeast":
      const ambushedByBeastEvent = event as AmbushedByBeastEvent;
      const ambushedByBeastAdventurerData =
        processAdventurerState(ambushedByBeastEvent);
      const ambushedByBeastData = {
        txHash: txHash,
        adventurerId: ambushedByBeastEvent.adventurerState["adventurerId"],
        adventurerHealth:
          ambushedByBeastEvent.adventurerState["adventurer"]["health"],
        discoveryType: gameData.DISCOVERY_TYPES[1],
        subDiscoveryType: null,
        outputAmount: 0,
        obstacle: null,
        obstacleLevel: null,
        dodgedObstacle: 0,
        damageTaken: 0,
        damageLocation: null,
        xpEarnedAdventurer: null,
        xpEarnedItems: null,
        entity: gameData.BEASTS[ambushedByBeastEvent.id],
        entityLevel: ambushedByBeastEvent.beastSpecs["level"],
        entityHealth:
          ambushedByBeastEvent.adventurerState["adventurer"]["beastHealth"],
        special1: ambushedByBeastEvent.beastSpecs["specials"]["special1"],
        special2: ambushedByBeastEvent.beastSpecs["specials"]["special2"],
        special3: ambushedByBeastEvent.beastSpecs["specials"]["special3"],
        ambushed: null,
        seed: ambushedByBeastEvent.seed,
        discoveryTime: new Date(),
        timestamp: new Date(),
      };
      const ambushedByBeastBeastData = {
        beast: gameData.BEASTS[ambushedByBeastEvent.id],
        health:
          ambushedByBeastEvent.adventurerState["adventurer"]["beastHealth"],
        level: ambushedByBeastEvent.beastSpecs["level"],
        special1: ambushedByBeastEvent.beastSpecs["specials"]["special1"],
        special2: ambushedByBeastEvent.beastSpecs["specials"]["special2"],
        special3: ambushedByBeastEvent.beastSpecs["specials"]["special3"],
        seed: ambushedByBeastEvent.seed,
        adventurerId: ambushedByBeastEvent.adventurerState["adventurerId"],
        slainOnTime: null,
        createdTime: new Date(),
        lastUpdatedTime: new Date(),
        timestamp: new Date(),
      };
      const ambushedByBeastAttackData = {
        txHash: txHash,
        beast: gameData.BEASTS[ambushedByBeastEvent.id],
        beastHealth:
          ambushedByBeastEvent.adventurerState["adventurer"]["beastHealth"],
        beastLevel: ambushedByBeastEvent.beastSpecs["level"],
        special1: ambushedByBeastEvent.beastSpecs["specials"]["special1"],
        special2: ambushedByBeastEvent.beastSpecs["specials"]["special2"],
        special3: ambushedByBeastEvent.beastSpecs["specials"]["special3"],
        seed: ambushedByBeastEvent.seed,
        adventurerId: ambushedByBeastEvent.adventurerState["adventurerId"],
        adventurerHealth:
          ambushedByBeastEvent.adventurerState["adventurer"]["health"],
        attacker: "Beast",
        fled: null,
        damageDealt: 0,
        criticalHit: ambushedByBeastEvent.criticalHit,
        damageTaken: ambushedByBeastEvent.damage,
        damageLocation: ambushedByBeastEvent.location,
        xpEarnedAdventurer: 0,
        xpEarnedItems: 0,
        goldEarned: 0,
        discoveryTime: new Date(),
        blockTime: new Date(),
        timestamp: new Date(),
      };
      return [
        ambushedByBeastAdventurerData,
        ambushedByBeastData,
        ambushedByBeastBeastData,
        ambushedByBeastAttackData,
      ];
    case "AttackedBeast":
      const attackedBeastEvent = event as AttackedBeastEvent;
      const attackedBeastAdventurerData =
        processAdventurerState(attackedBeastEvent);
      const attackedBeastData = {
        txHash: txHash,
        beast: gameData.BEASTS[attackedBeastEvent.id],
        beastHealth:
          attackedBeastEvent.adventurerState["adventurer"]["beastHealth"],
        beastLevel: attackedBeastEvent.beastSpecs["level"],
        special1: attackedBeastEvent.beastSpecs["specials"]["special1"],
        special2: attackedBeastEvent.beastSpecs["specials"]["special2"],
        special3: attackedBeastEvent.beastSpecs["specials"]["special3"],
        seed: attackedBeastEvent.seed,
        adventurerId: attackedBeastEvent.adventurerState["adventurerId"],
        adventurerHealth:
          attackedBeastEvent.adventurerState["adventurer"]["health"],
        attacker: "Adventurer",
        fled: null,
        damageDealt: attackedBeastEvent.damage,
        criticalHit: attackedBeastEvent.criticalHit,
        damageTaken: 0,
        damageLocation: attackedBeastEvent.location,
        xpEarnedAdventurer: 0,
        xpEarnedItems: 0,
        goldEarned: 0,
        discoveryTime: new Date(),
        blockTime: new Date(),
        timestamp: new Date(),
      };
      return [attackedBeastAdventurerData, attackedBeastData];
    case "AttackedByBeast":
      const attackedByBeastEvent = event as AttackedByBeastEvent;
      const attackedByBeastData = {
        txHash: txHash,
        beast: gameData.BEASTS[attackedByBeastEvent.id],
        beastHealth:
          attackedByBeastEvent.adventurerState["adventurer"]["beastHealth"],
        beastLevel: attackedByBeastEvent.beastSpecs["level"],
        special1: attackedByBeastEvent.beastSpecs["specials"]["special1"],
        special2: attackedByBeastEvent.beastSpecs["specials"]["special2"],
        special3: attackedByBeastEvent.beastSpecs["specials"]["special3"],
        seed: attackedByBeastEvent.seed,
        adventurerId: attackedByBeastEvent.adventurerState["adventurerId"],
        adventurerHealth:
          attackedByBeastEvent.adventurerState["adventurer"]["health"],
        attacker: "Beast",
        fled: null,
        damageDealt: 0,
        criticalHit: attackedByBeastEvent.criticalHit,
        damageTaken: attackedByBeastEvent.damage,
        damageLocation: attackedByBeastEvent.location,
        xpEarnedAdventurer: 0,
        xpEarnedItems: 0,
        goldEarned: 0,
        discoveryTime: new Date(),
        blockTime: new Date(),
        timestamp: new Date(),
      };
      return [attackedByBeastEvent, attackedByBeastData];
    case "SlayedBeast":
      const slayedBeastEvent = event as SlayedBeastEvent;
      const slayedBeastAdventurerData =
        processAdventurerState(slayedBeastEvent);
      const slayedBeastData = {
        txHash: txHash,
        beast: gameData.BEASTS[slayedBeastEvent.id],
        beastHealth:
          slayedBeastEvent.adventurerState["adventurer"]["beastHealth"],
        beastLevel: slayedBeastEvent.beastSpecs["level"],
        special1: slayedBeastEvent.beastSpecs["specials"]["special1"],
        special2: slayedBeastEvent.beastSpecs["specials"]["special2"],
        special3: slayedBeastEvent.beastSpecs["specials"]["special3"],
        seed: slayedBeastEvent.seed,
        adventurerId: slayedBeastEvent.adventurerState["adventurerId"],
        adventurerHealth:
          slayedBeastEvent.adventurerState["adventurer"]["health"],
        attacker: "Adventurer",
        fled: null,
        damageDealt: slayedBeastEvent.damageDealt,
        criticalHit: slayedBeastEvent.criticalHit,
        damageTaken: 0,
        damageLocation: null,
        xpEarnedAdventurer: slayedBeastEvent.xpEarnedAdventurer,
        xpEarnedItems: slayedBeastEvent.xpEarnedItems,
        goldEarned: slayedBeastEvent.goldEarned,
        discoveryTime: new Date(),
        blockTime: new Date(),
        timestamp: new Date(),
      };
      return [slayedBeastAdventurerData, slayedBeastData];
    case "FleeFailed":
      const fleeFailedEvent = event as FleeFailedEvent;
      const fleeFailedAdventurerData = processAdventurerState(fleeFailedEvent);
      const fleeFailedData = {
        txHash: txHash,
        beast: gameData.BEASTS[fleeFailedEvent.id],
        beastHealth:
          fleeFailedEvent.adventurerState["adventurer"]["beastHealth"],
        beastLevel: fleeFailedEvent.beastSpecs["level"],
        special1: fleeFailedEvent.beastSpecs["specials"]["special1"],
        special2: fleeFailedEvent.beastSpecs["specials"]["special2"],
        special3: fleeFailedEvent.beastSpecs["specials"]["special3"],
        seed: fleeFailedEvent.seed,
        adventurerId: fleeFailedEvent.adventurerState["adventurerId"],
        adventurerHealth:
          fleeFailedEvent.adventurerState["adventurer"]["health"],
        attacker: "Beast",
        fled: null,
        damageDealt: 0,
        criticalHit: false,
        damageTaken: 0,
        damageLocation: null,
        xpEarnedAdventurer: 0,
        xpEarnedItems: 0,
        goldEarned: 0,
        discoveryTime: new Date(),
        blockTime: new Date(),
        timestamp: new Date(),
      };
      return [fleeFailedAdventurerData, fleeFailedData];
    case "FleeSucceeded":
      const fleeSucceededEvent = event as FleeSucceededEvent;
      const fleeSucceededAdventurerData =
        processAdventurerState(fleeSucceededEvent);
      const fleeSucceededData = {
        txHash: txHash,
        beast: gameData.BEASTS[fleeSucceededEvent.id],
        beastHealth:
          fleeSucceededEvent.adventurerState["adventurer"]["beastHealth"],
        beastLevel: fleeSucceededEvent.beastSpecs["level"],
        special1: fleeSucceededEvent.beastSpecs["specials"]["special1"],
        special2: fleeSucceededEvent.beastSpecs["specials"]["special2"],
        special3: fleeSucceededEvent.beastSpecs["specials"]["special3"],
        seed: fleeSucceededEvent.seed,
        adventurerId: fleeSucceededEvent.adventurerState["adventurerId"],
        adventurerHealth:
          fleeSucceededEvent.adventurerState["adventurer"]["health"],
        attacker: "Beast",
        fled: true,
        damageDealt: 0,
        criticalHit: false,
        damageTaken: 0,
        damageLocation: null,
        xpEarnedAdventurer: 0,
        xpEarnedItems: 0,
        goldEarned: 0,
        discoveryTime: new Date(),
        blockTime: new Date(),
        timestamp: new Date(),
      };
      return [fleeSucceededAdventurerData, fleeSucceededData];
    case "PurchasedItems":
      const purchasedItemsEvent = event as PurchasedItemsEvent;
      const purchasedItemsAdventurerData =
        processAdventurerState(purchasedItemsEvent);
      return [purchasedItemsAdventurerData, purchasedItemsEvent.purchases];
    case "PurchasedPotions":
      const purchasedPotionsEvent = event as PurchasedPotionsEvent;
      return processAdventurerState(purchasedPotionsEvent);
    case "EquippedItems":
      const equippedItemsEvent = event as EquippedItemsEvent;
      const equipedItemsAdventurerData =
        processAdventurerState(equippedItemsEvent);
      const formattedEquippedItems = [];
      for (let i = 0; i < equippedItemsEvent.equippedItems.length; i++) {
        formattedEquippedItems.push(
          gameData.ITEMS[equippedItemsEvent.equippedItems[i]]
        );
      }
      const formattedUnequippedItems = [];
      for (let i = 0; i < equippedItemsEvent.unequippedItems.length; i++) {
        formattedUnequippedItems.push(
          gameData.ITEMS[equippedItemsEvent.equippedItems[i]]
        );
      }
      return [
        equipedItemsAdventurerData,
        formattedEquippedItems,
        formattedUnequippedItems,
      ];
    case "DroppedItems":
      const droppedItemsEvent = event as DroppedItemsEvent;
      const droppedItemsAdventurerData =
        processAdventurerState(droppedItemsEvent);
      const formattedDroppedItems = [];
      for (let i = 0; i < droppedItemsEvent.itemIds.length; i++) {
        formattedDroppedItems.push(
          gameData.ITEMS[droppedItemsEvent.itemIds[i]]
        );
      }
      return [droppedItemsAdventurerData, formattedDroppedItems];
    case "GreatnessIncreased":
      const greatnessIncreasedEvent = event as GreatnessIncreasedEvent;
      return processAdventurerState(greatnessIncreasedEvent);
    case "ItemSpecialUnlocked":
      const itemsSpecialUnlockedEvent = event as ItemSpecialUnlockedEvent;
      const itemSpecialUnlockedAdventurerData = processAdventurerState(
        itemsSpecialUnlockedEvent
      );
      const itemData = {
        item: itemsSpecialUnlockedEvent.id,
        special1: itemsSpecialUnlockedEvent.specials.special1,
        special2: itemsSpecialUnlockedEvent.specials.special2,
        special3: itemsSpecialUnlockedEvent.specials.special3,
        timestamp: new Date(),
      };
      return [itemSpecialUnlockedAdventurerData, itemData];
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
      const newItemsAvailableAdventurerData = processAdventurerState(
        newItemsAvailableEvent
      );
      const formattedNewItems = [];
      for (let i = 0; i < newItemsAvailableEvent.items.length; i++) {
        formattedNewItems.push(
          gameData.ITEMS[newItemsAvailableEvent.items[i]["item"]["id"]]
        );
      }
      return [newItemsAvailableAdventurerData, formattedNewItems];
    case "IdleDeathPenalty":
      const idleDeathPenaltyEvent = event as IdleDeathPenaltyEvent;
      const penaltyAdventurerData = processAdventurerState(
        idleDeathPenaltyEvent
      );
      const penaltyBattleData = {
        txHash: txHash,
        beast: null,
        beastHealth: 0,
        beastLevel: 0,
        special1: null,
        special2: null,
        special3: null,
        seed: 0,
        adventurerId: idleDeathPenaltyEvent.adventurerState["adventurerId"],
        adventurerHealth:
          idleDeathPenaltyEvent.adventurerState["adventurer"]["health"],
        attacker: null,
        fled: null,
        damageDealt: 0,
        criticalHit: false,
        damageTaken: 0,
        damageLocation: null,
        xpEarnedAdventurer: 0,
        xpEarnedItems: 0,
        goldEarned: 0,
        discoveryTime: new Date(),
        blockTime: new Date(),
        timestamp: new Date(),
      };
      const penaltyDiscoveryData = {
        txHash: txHash,
        adventurerId: idleDeathPenaltyEvent.adventurerState["adventurerId"],
        adventurerHealth:
          idleDeathPenaltyEvent.adventurerState["adventurer"]["health"],
        discoveryType: null,
        subDiscoveryType: null,
        outputAmount: 0,
        obstacle: null,
        obstacleLevel: null,
        dodgedObstacle: 0,
        damageTaken: 0,
        damageLocation: null,
        xpEarnedAdventurer: null,
        xpEarnedItems: null,
        entity: null,
        entityLevel: null,
        entityHealth: 0,
        special1: null,
        special2: null,
        special3: null,
        ambushed: null,
        seed: 0,
        discoveryTime: new Date(),
        timestamp: new Date(),
      };
      return [penaltyAdventurerData, penaltyBattleData, penaltyDiscoveryData];
  }
}
