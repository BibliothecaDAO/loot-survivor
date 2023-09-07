import { parseAdventurerState } from "./events.js";
import { encodeIntAsBytes, checkExistsInt } from "./encode.js";

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
    id: checkExistsInt(BigInt(id)),
    owner: checkExistsInt(BigInt(owner)),
  };

  return {
    entity,
    update: {
      $set: {
        ...entity,
        lastAction: encodeIntAsBytes(BigInt(lastAction)),
        health: encodeIntAsBytes(BigInt(health)),
        xp: encodeIntAsBytes(BigInt(xp)),
        strength: encodeIntAsBytes(BigInt(strength)),
        dexterity: encodeIntAsBytes(BigInt(dexterity)),
        vitality: encodeIntAsBytes(BigInt(vitality)),
        intelligence: encodeIntAsBytes(BigInt(intelligence)),
        wisdom: encodeIntAsBytes(BigInt(wisdom)),
        charisma: encodeIntAsBytes(BigInt(charisma)),
        gold: encodeIntAsBytes(BigInt(gold)),
        weapon: checkExistsInt(BigInt(weapon)),
        chest: checkExistsInt(BigInt(chest)),
        head: checkExistsInt(BigInt(head)),
        waist: checkExistsInt(BigInt(waist)),
        foot: checkExistsInt(BigInt(foot)),
        hand: checkExistsInt(BigInt(hand)),
        neck: checkExistsInt(BigInt(neck)),
        ring: checkExistsInt(BigInt(ring)),
        beastHealth: encodeIntAsBytes(BigInt(beastHealth)),
        statUpgrades: checkExistsInt(BigInt(statUpgrades)),
        name: checkExistsInt(BigInt(name)),
        homeRealm: checkExistsInt(BigInt(homeRealm)),
        classType: checkExistsInt(BigInt(classType)),
        entropy: encodeIntAsBytes(BigInt(entropy)),
        createdTime: createdTime,
        lastUpdatedTime: lastUpdatedTime,
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
  slayed,
  slainOnTime,
  createdTime,
  lastUpdatedTime,
  timestamp,
}: any) {
  const entity = {
    beast: checkExistsInt(BigInt(beast)),
    adventurerId: checkExistsInt(BigInt(adventurerId)),
    seed: encodeIntAsBytes(BigInt(seed)),
  };

  return {
    entity,
    update: {
      $set: {
        ...entity,
        health: encodeIntAsBytes(BigInt(health)),
        level: checkExistsInt(BigInt(level)),
        special1: checkExistsInt(BigInt(special1)),
        special2: checkExistsInt(BigInt(special2)),
        special3: checkExistsInt(BigInt(special3)),
        slayed: slayed,
        slainOnTime: slainOnTime,
        createdTime: createdTime,
        lastUpdatedTime: lastUpdatedTime,
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
  slainOnTime,
  lastUpdatedTime,
  timestamp,
}: any) {
  const entity = {
    beast: checkExistsInt(BigInt(beast)),
    adventurerId: checkExistsInt(BigInt(adventurerId)),
    seed: encodeIntAsBytes(BigInt(seed)),
  };

  const newBeast = slayed
    ? {
        ...entity,
        health: encodeIntAsBytes(BigInt(health)),
        slainOnTime: slainOnTime,
        lastUpdatedTime: lastUpdatedTime,
        timestamp,
      }
    : {
        ...entity,
        health: encodeIntAsBytes(BigInt(health)),
        lastUpdatedTime: lastUpdatedTime,
        timestamp,
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
      id: checkExistsInt(BigInt(adventurerState.adventurerId)),
    },
    update: {
      $set: {
        id: checkExistsInt(BigInt(adventurerState.adventurerId)),
        owner: checkExistsInt(BigInt(adventurerState.owner)),
        lastAction: encodeIntAsBytes(BigInt(adventurer.lastAction)),
        health: encodeIntAsBytes(BigInt(adventurer.health)),
        xp: encodeIntAsBytes(BigInt(adventurer.xp)),
        strength: encodeIntAsBytes(BigInt(adventurer.stats.strength)),
        dexterity: encodeIntAsBytes(BigInt(adventurer.stats.dexterity)),
        vitality: encodeIntAsBytes(BigInt(adventurer.stats.vitality)),
        intelligence: encodeIntAsBytes(BigInt(adventurer.stats.intelligence)),
        wisdom: encodeIntAsBytes(BigInt(adventurer.stats.wisdom)),
        charisma: encodeIntAsBytes(BigInt(adventurer.stats.charisma)),
        gold: encodeIntAsBytes(BigInt(adventurer.gold)),
        weapon: checkExistsInt(BigInt(adventurer.weapon.id)),
        chest: checkExistsInt(BigInt(adventurer.chest.id)),
        head: checkExistsInt(BigInt(adventurer.head.id)),
        waist: checkExistsInt(BigInt(adventurer.waist.id)),
        foot: checkExistsInt(BigInt(adventurer.foot.id)),
        hand: checkExistsInt(BigInt(adventurer.hand.id)),
        neck: checkExistsInt(BigInt(adventurer.neck.id)),
        ring: checkExistsInt(BigInt(adventurer.ring.id)),
        beastHealth: encodeIntAsBytes(BigInt(adventurer.beastHealth)),
        statUpgrades: encodeIntAsBytes(BigInt(adventurer.statsPointsAvailable)),
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
    txHash: checkExistsInt(BigInt(txHash)),
    adventurerId: checkExistsInt(BigInt(adventurerId)),
    adventurerHealth: checkExistsInt(BigInt(adventurerHealth)),
    discoveryType: checkExistsInt(BigInt(discoveryType)),
    subDiscoveryType: checkExistsInt(BigInt(subDiscoveryType)),
    outputAmount: encodeIntAsBytes(BigInt(outputAmount)),
    obstacle: checkExistsInt(BigInt(obstacle)),
    obstacleLevel: checkExistsInt(BigInt(obstacleLevel)),
    dodgedObstacle: dodgedObstacle,
    damageTaken: encodeIntAsBytes(BigInt(damageTaken)),
    damageLocation: checkExistsInt(BigInt(damageLocation)),
    xpEarnedAdventurer: checkExistsInt(BigInt(xpEarnedAdventurer)),
    xpEarnedItems: checkExistsInt(BigInt(xpEarnedItems)),
    entity: checkExistsInt(BigInt(entity)),
    entityLevel: checkExistsInt(BigInt(entityLevel)),
    entityHealth: encodeIntAsBytes(BigInt(entityHealth)),
    special1: checkExistsInt(BigInt(special1)),
    special2: checkExistsInt(BigInt(special2)),
    special3: checkExistsInt(BigInt(special3)),
    ambushed: ambushed,
    seed: encodeIntAsBytes(BigInt(seed)),
    discoveryTime,
    timestamp,
  };

  return {
    entity: entityDoc,
    update: {
      $set: {
        ...entityDoc,
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
  const entity = {
    txHash: checkExistsInt(BigInt(txHash)),
    adventurerId: checkExistsInt(BigInt(adventurerId)),
    beast: checkExistsInt(BigInt(beast)),
    seed: encodeIntAsBytes(BigInt(seed)),
    beastHealth: encodeIntAsBytes(BigInt(beastHealth)),
    beastLevel: checkExistsInt(BigInt(beastLevel)),
    special1: checkExistsInt(BigInt(special1)),
    special2: checkExistsInt(BigInt(special2)),
    special3: checkExistsInt(BigInt(special3)),
    adventurerHealth: encodeIntAsBytes(BigInt(adventurerHealth)),
    attacker: checkExistsInt(BigInt(attacker)),
    fled: fled,
    damageDealt: encodeIntAsBytes(BigInt(damageDealt)),
    criticalHit: criticalHit,
    damageTaken: encodeIntAsBytes(BigInt(damageTaken)),
    damageLocation: checkExistsInt(BigInt(damageLocation)),
    xpEarnedAdventurer: encodeIntAsBytes(BigInt(xpEarnedAdventurer)),
    xpEarnedItems: encodeIntAsBytes(BigInt(xpEarnedItems)),
    goldEarned: encodeIntAsBytes(BigInt(goldEarned)),
    discoveryTime: discoveryTime,
    blockTime: blockTime,
    timestamp: timestamp,
  };

  // every battle should be unique
  return {
    entity,
    update: {
      $set: {
        ...entity,
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
  const entity = {
    item: checkExistsInt(BigInt(item)),
    adventurerId: checkExistsInt(BigInt(adventurerId)),
  };

  return {
    entity,
    update: {
      $set: {
        ...entity,
        owner: checkExistsInt(BigInt(owner)),
        equipped,
        ownerAddress: checkExistsInt(BigInt(ownerAddress)),
        xp: encodeIntAsBytes(BigInt(xp)),
        special1: checkExistsInt(BigInt(special1)),
        special2: checkExistsInt(BigInt(special2)),
        special3: checkExistsInt(BigInt(special3)),
        isAvailable,
        purchasedTime,
        timestamp,
      },
    },
  };
}

export function updateItemXP({ item, adventurerId, xp }: any) {
  const entity = {
    item: checkExistsInt(BigInt(item)),
    adventurerId: checkExistsInt(BigInt(adventurerId)),
  };

  return {
    entity,
    update: {
      $set: {
        ...entity,
        xp: encodeIntAsBytes(BigInt(xp)),
        timestamp: new Date().toISOString(),
      },
    },
  };
}

export function updateItemsXP({
  adventurerState,
}: {
  adventurerState: ReturnType<typeof parseAdventurerState>["value"];
}) {
  const { adventurer } = adventurerState;
  const itemUpdates: any[] = [];
  itemUpdates.push(
    updateItemXP({
      item: adventurer.weapon.id,
      adventurerId: adventurerState.adventurerId,
      xp: adventurer.weapon.xp,
    })
  );
  itemUpdates.push(
    updateItemXP({
      item: adventurer.chest.id,
      adventurerId: adventurerState.adventurerId,
      xp: adventurer.chest.xp,
    })
  );
  itemUpdates.push(
    updateItemXP({
      item: adventurer.head.id,
      adventurerId: adventurerState.adventurerId,
      xp: adventurer.head.xp,
    })
  );
  itemUpdates.push(
    updateItemXP({
      item: adventurer.waist.id,
      adventurerId: adventurerState.adventurerId,
      xp: adventurer.waist.xp,
    })
  );
  itemUpdates.push(
    updateItemXP({
      item: adventurer.foot.id,
      adventurerId: adventurerState.adventurerId,
      xp: adventurer.foot.xp,
    })
  );
  itemUpdates.push(
    updateItemXP({
      item: adventurer.hand.id,
      adventurerId: adventurerState.adventurerId,
      xp: adventurer.hand.xp,
    })
  );
  itemUpdates.push(
    updateItemXP({
      item: adventurer.neck.id,
      adventurerId: adventurerState.adventurerId,
      xp: adventurer.neck.xp,
    })
  );
  itemUpdates.push(
    updateItemXP({
      item: adventurer.ring.id,
      adventurerId: adventurerState.adventurerId,
      xp: adventurer.ring.xp,
    })
  );
  return itemUpdates;
}

export function updateItemSpecials({
  item,
  adventurerId,
  special1,
  special2,
  special3,
}: any) {
  const entity = {
    item: checkExistsInt(BigInt(item)),
    adventurerId: checkExistsInt(BigInt(adventurerId)),
  };

  return {
    entity,
    update: {
      $set: {
        ...entity,
        special1: checkExistsInt(BigInt(special1)),
        special2: checkExistsInt(BigInt(special2)),
        special3: checkExistsInt(BigInt(special3)),
      },
    },
  };
}

export function insertHighScore({
  adventurerId,
  owner,
  rank,
  xp,
  txHash,
  scoreTime,
  timestamp,
  totalPayout,
}: any) {
  const entity = {
    adventurerId: checkExistsInt(BigInt(adventurerId)),
    owner: checkExistsInt(BigInt(owner)),
    rank: checkExistsInt(BigInt(rank)),
  };

  return {
    entity,
    update: {
      $set: {
        ...entity,
        xp: encodeIntAsBytes(BigInt(xp)),
        txHash: checkExistsInt(BigInt(txHash)),
        scoreTime,
        timestamp,
        totalPayout: totalPayout,
      },
    },
  };
}

export function updateTotalPayout({
  adventurerId,
  owner,
  rank,
  timestamp,
  newPayout,
}: any) {
  const entity = {
    adventurerId: checkExistsInt(BigInt(adventurerId)),
    owner: checkExistsInt(BigInt(owner)),
    rank: checkExistsInt(BigInt(rank)),
  };

  return {
    entity,
    update: {
      $set: {
        ...entity,
        timestamp,
      },
      $inc: {
        totalPayout: BigInt(newPayout),
      },
    },
  };
}
