import { parseAdventurerState } from "./events.ts";

export function insertAdventurer({
  id,
  owner,
  lastAction,
  health,
  xp,
  strength,
  dexterity,
  vitality,
  intelligence,
  wisdom,
  charisma,
  gold,
  weapon,
  chest,
  head,
  waist,
  foot,
  hand,
  neck,
  ring,
  beastHealth,
  statUpgrades,
  name,
  homeRealm,
  classType,
  entropy,
  createdTime,
  lastUpdatedTime,
  timestamp,
}: any) {
  const entity = {
    id,
    owner,
  };

  return {
    entity,
    update: {
      $set: {
        ...entity,
        lastAction,
        health,
        xp,
        strength,
        dexterity,
        vitality,
        intelligence,
        wisdom,
        charisma,
        gold,
        weapon,
        chest,
        head,
        waist,
        foot,
        hand,
        neck,
        ring,
        beastHealth,
        statUpgrades,
        name,
        homeRealm,
        classType,
        entropy,
        createdTime,
        lastUpdatedTime,
        timestamp,
      },
    },
  };
}

export function insertBeast({
  beast,
  seed,
  adventurerId,
  health,
  level,
  special1,
  special2,
  special3,
  timestamp,
}: any) {
  const entity = {
    beast,
    adventurerId,
    seed,
  };

  return {
    entity,
    update: {
      $set: {
        ...entity,
        health,
        level,
        special1,
        special2,
        special3,
        slainOnTime: null,
        createdTime: timestamp,
        timestamp,
      },
    },
  };
}

export function updateBeastHealth({
  beast,
  seed,
  adventurerId,
  health,
  slayed,
  timestamp,
}: any) {
  const entity = {
    beast,
    adventurerId,
    seed,
  };

  const newBeast = slayed
    ? {
        health,
        timestamp,
        ...entity,
      }
    : {
        health,
        timestamp,
        slainOnTime: timestamp,
        ...entity,
      };

  return {
    entity,
    update: {
      $set: newBeast,
    },
  };
}

export function updateAdventurer({
  adventurerState,
  timestamp,
}: {
  adventurerState: ReturnType<typeof parseAdventurerState>["value"];
  timestamp: string;
}) {
  const { adventurer } = adventurerState;
  return {
    entity: {
      id: adventurerState.adventurerId,
    },
    update: {
      $set: {
        id: adventurerState.adventurerId,
        owner: adventurerState.owner,
        lastAction: adventurer.lastAction,
        health: adventurer.health,
        xp: adventurer.xp,
        strength: adventurer.stats.strength,
        dexterity: adventurer.stats.dexterity,
        vitality: adventurer.stats.vitality,
        intelligence: adventurer.stats.intelligence,
        wisdom: adventurer.stats.wisdom,
        charisma: adventurer.stats.charisma,
        gold: adventurer.gold,
        weapon: adventurer.weapon.id,
        chest: adventurer.chest.id,
        head: adventurer.head.id,
        waist: adventurer.waist.id,
        foot: adventurer.foot.id,
        hand: adventurer.hand.id,
        neck: adventurer.neck.id,
        ring: adventurer.ring.id,
        beastHealth: adventurer.beastHealth,
        statUpgrades: adventurer.statsPointsAvailable,
        lastUpdatedTime: timestamp,
        timestamp,
      },
    },
  };
}

export function insertDiscovery({
  txHash,
  adventurerId,
  adventurerHealth,
  discoveryType,
  subDiscoveryType,
  outputAmount,
  obstacle,
  obstacleLevel,
  dodgedObstacle,
  damageTaken,
  damageLocation,
  xpEarnedAdventurer,
  xpEarnedItems,
  entity,
  entityLevel,
  entityHealth,
  special1,
  special2,
  special3,
  ambushed,
  seed,
  discoveryTime,
  timestamp,
}: any) {
  const entityDoc = {
    txHash,
    adventurerId,
    timestamp,
  };

  return {
    entityDoc,
    update: {
      $set: {
        ...entityDoc,
        adventurerHealth,
        discoveryType,
        subDiscoveryType,
        outputAmount,
        obstacle,
        obstacleLevel,
        dodgedObstacle,
        damageTaken,
        damageLocation,
        xpEarnedAdventurer,
        xpEarnedItems,
        entity,
        entityLevel,
        entityHealth,
        special1,
        special2,
        special3,
        ambushed,
        seed,
        discoveryTime,
      },
    },
  };
}

export function insertBattle({
  txHash,
  beast,
  beastHealth,
  beastLevel,
  special1,
  special2,
  special3,
  seed,
  adventurerId,
  adventurerHealth,
  attacker,
  fled,
  damageDealt,
  criticalHit,
  damageTaken,
  damageLocation,
  xpEarnedAdventurer,
  xpEarnedItems,
  goldEarned,
  discoveryTime,
  blockTime,
  timestamp,
}: any) {
  const entityDoc = {
    txHash,
    adventurerId,
    beast,
    seed,
    timestamp,
  };

  return {
    entityDoc,
    update: {
      $set: {
        ...entityDoc,
        beastHealth,
        beastLevel,
        special1,
        special2,
        special3,
        adventurerHealth,
        attacker,
        fled,
        damageDealt,
        criticalHit,
        damageTaken,
        damageLocation,
        xpEarnedAdventurer,
        xpEarnedItems,
        goldEarned,
        discoveryTime,
        blockTime,
      },
    },
  };
}

export function insertItem({
  item,
  adventurerId,
  owner,
  equipped,
  ownerAddress,
  xp,
  special1,
  special2,
  special3,
  isAvailable,
  purchasedTime,
  timestamp,
}: any) {
  const entityDoc = {
    item,
    adventurerId,
  };

  return {
    entityDoc,
    update: {
      $set: {
        ...entityDoc,
        owner,
        equipped,
        ownerAddress,
        xp,
        special1,
        special2,
        special3,
        isAvailable,
        purchasedTime,
        timestamp,
      },
    },
  };
}
