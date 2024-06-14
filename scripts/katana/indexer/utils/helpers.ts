import { parseAdventurerState } from "./events.ts";
import { encodeIntAsBytes, checkExistsInt } from "./encode.ts";

export function insertAdventurer({
  id,
  owner,
  entropy,
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
  startEntropy,
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
        entropy: encodeIntAsBytes(BigInt(entropy)),
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
        startEntropy: encodeIntAsBytes(BigInt(startEntropy)),
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
        entropy: encodeIntAsBytes(BigInt(adventurerState.adventurerEntropy)),
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
        weapon: checkExistsInt(BigInt(adventurer.equipment.weapon.id)),
        chest: checkExistsInt(BigInt(adventurer.equipment.chest.id)),
        head: checkExistsInt(BigInt(adventurer.equipment.head.id)),
        waist: checkExistsInt(BigInt(adventurer.equipment.waist.id)),
        foot: checkExistsInt(BigInt(adventurer.equipment.foot.id)),
        hand: checkExistsInt(BigInt(adventurer.equipment.hand.id)),
        neck: checkExistsInt(BigInt(adventurer.equipment.neck.id)),
        ring: checkExistsInt(BigInt(adventurer.equipment.ring.id)),
        beastHealth: encodeIntAsBytes(BigInt(adventurer.beastHealth)),
        statUpgrades: encodeIntAsBytes(
          BigInt(adventurer.statsUpgradesAvailable)
        ),
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
      item: adventurer.equipment.weapon.id,
      adventurerId: adventurerState.adventurerId,
      xp: adventurer.equipment.weapon.xp,
    })
  );
  itemUpdates.push(
    updateItemXP({
      item: adventurer.equipment.chest.id,
      adventurerId: adventurerState.adventurerId,
      xp: adventurer.equipment.chest.xp,
    })
  );
  itemUpdates.push(
    updateItemXP({
      item: adventurer.equipment.head.id,
      adventurerId: adventurerState.adventurerId,
      xp: adventurer.equipment.head.xp,
    })
  );
  itemUpdates.push(
    updateItemXP({
      item: adventurer.equipment.waist.id,
      adventurerId: adventurerState.adventurerId,
      xp: adventurer.equipment.waist.xp,
    })
  );
  itemUpdates.push(
    updateItemXP({
      item: adventurer.equipment.foot.id,
      adventurerId: adventurerState.adventurerId,
      xp: adventurer.equipment.foot.xp,
    })
  );
  itemUpdates.push(
    updateItemXP({
      item: adventurer.equipment.hand.id,
      adventurerId: adventurerState.adventurerId,
      xp: adventurer.equipment.hand.xp,
    })
  );
  itemUpdates.push(
    updateItemXP({
      item: adventurer.equipment.neck.id,
      adventurerId: adventurerState.adventurerId,
      xp: adventurer.equipment.neck.xp,
    })
  );
  itemUpdates.push(
    updateItemXP({
      item: adventurer.equipment.ring.id,
      adventurerId: adventurerState.adventurerId,
      xp: adventurer.equipment.ring.xp,
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
