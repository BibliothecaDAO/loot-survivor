import { parseAdventurerState } from "./events.ts";
import { encodeIntAsBytes, checkExistsInt } from "./encode.ts";

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
  actionsPerBlock,
  name,
  startBlock,
  revealBlock,
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
        actionsPerBlock: encodeIntAsBytes(BigInt(actionsPerBlock)),
        name: checkExistsInt(BigInt(name)),
        startBlock: encodeIntAsBytes(BigInt(startBlock)),
        revealBlock: encodeIntAsBytes(BigInt(revealBlock)),
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
  const entity = {
    id: checkExistsInt(BigInt(adventurerState.adventurerId)),
    owner: checkExistsInt(BigInt(adventurerState.owner)),
  };
  return {
    entity,
    update: {
      $set: {
        ...entity,
        lastAction: encodeIntAsBytes(BigInt(adventurer.lastActionBlock)),
        health: encodeIntAsBytes(BigInt(adventurer.health)),
        xp: encodeIntAsBytes(BigInt(adventurer.xp)),
        strength: encodeIntAsBytes(BigInt(adventurer.stats.strength)),
        dexterity: encodeIntAsBytes(BigInt(adventurer.stats.dexterity)),
        vitality: encodeIntAsBytes(BigInt(adventurer.stats.vitality)),
        intelligence: encodeIntAsBytes(BigInt(adventurer.stats.intelligence)),
        wisdom: encodeIntAsBytes(BigInt(adventurer.stats.wisdom)),
        charisma: encodeIntAsBytes(BigInt(adventurer.stats.charisma)),
        luck: encodeIntAsBytes(BigInt(adventurer.stats.luck)),
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
        actionsPerBlock: encodeIntAsBytes(BigInt(adventurer.actionsPerBlock)),
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
    update: [
      {
        $set: {
          ...entity,
          owner: {
            $cond: [
              { $not: ["$owner"] },
              checkExistsInt(BigInt(owner)),
              "$owner",
            ],
          },
          equipped: {
            $cond: [
              { $not: ["$owner"] },
              checkExistsInt(BigInt(equipped)),
              "$equipped",
            ],
          },
          ownerAddress: {
            $cond: [
              { $not: ["$owner"] },
              checkExistsInt(BigInt(ownerAddress)),
              "$ownerAddress",
            ],
          },
          xp: {
            $cond: [{ $not: ["$owner"] }, encodeIntAsBytes(BigInt(xp)), "$xp"],
          },
          special1: {
            $cond: [
              { $not: ["$owner"] },
              checkExistsInt(BigInt(special1)),
              "$special1",
            ],
          },
          special2: {
            $cond: [
              { $not: ["$owner"] },
              checkExistsInt(BigInt(special2)),
              "$special2",
            ],
          },
          special3: {
            $cond: [
              { $not: ["$owner"] },
              checkExistsInt(BigInt(special3)),
              "$special3",
            ],
          },
          isAvailable,
          purchasedTime: {
            $cond: [{ $not: ["$owner"] }, purchasedTime, "$purchasedTime"],
          },
          timestamp,
        },
      },
    ],
  };
}

export function updateItemXP({ item, adventurerId, xp }: any) {
  const entity = {
    item: checkExistsInt(BigInt(item)),
    adventurerId: checkExistsInt(BigInt(adventurerId)),
  };

  if (entity.item) {
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
  const filteredUpdates = itemUpdates.filter((value) => value !== undefined);
  return filteredUpdates;
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

export function insertHighScore({ adventurerId, timestamp, totalPayout }: any) {
  const entity = {
    adventurerId: checkExistsInt(BigInt(adventurerId)),
  };

  return {
    entity,
    update: {
      $set: {
        ...entity,
        timestamp,
        totalPayout: totalPayout,
      },
    },
  };
}

export function updateTotalPayout({ adventurerId, timestamp, newPayout }: any) {
  const entity = {
    adventurerId: checkExistsInt(BigInt(adventurerId)),
  };

  return {
    entity,
    update: {
      $set: {
        ...entity,
        timestamp,
      },
      $inc: {
        totalPayout: parseInt(newPayout),
      },
    },
  };
}

export function insertEntropy({
  prevHash,
  prevBlockNumber,
  prevBlockTimestamp,
  prevNextRotationBlock,
  newHash,
  newBlockNumber,
  newBlockTimestamp,
  newNextRotationBlock,
  blocksPerHour,
  currentTimestamp,
}: any) {
  const entity = {
    prevHash: checkExistsInt(BigInt(prevHash)),
    prevBlockNumber: prevBlockNumber,
    prevBlockTimestamp: prevBlockTimestamp,
    prevNextRotationBlock: prevNextRotationBlock,
    newHash: checkExistsInt(BigInt(newHash)),
    newBlockNumber: newBlockNumber,
    newBlockTimestamp: newBlockTimestamp,
    newNextRotationBlock: newNextRotationBlock,
    blocksPerHour: blocksPerHour,
    currentTimestamp: currentTimestamp,
  };

  return {
    entity,
    update: {
      $set: {
        ...entity,
      },
    },
  };
}
