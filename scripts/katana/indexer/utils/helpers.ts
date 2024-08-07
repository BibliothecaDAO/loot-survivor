import { parseAdventurerState } from "./events.ts";
import { checkExistsInt, getLevelFromXp } from "./encode.ts";

export function insertAdventurer({
  id,
  owner,
  entropy,
  health,
  xp,
  level,
  strength,
  dexterity,
  vitality,
  intelligence,
  wisdom,
  charisma,
  gold,
  actions,
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
  birthDate,
  deathDate,
  goldenTokenId,
  customRenderer,
  createdTime,
  lastUpdatedTime,
  timestamp,
}: any) {
  const entity = {
    id: checkExistsInt(parseInt(id)),
    owner: checkExistsInt(BigInt(owner).toString(16)),
  };

  return {
    entity,
    update: {
      $set: {
        ...entity,
        entropy: BigInt(entropy).toString(16),
        health: parseInt(health),
        xp: parseInt(xp),
        level: level,
        strength: parseInt(strength),
        dexterity: parseInt(dexterity),
        vitality: parseInt(vitality),
        intelligence: parseInt(intelligence),
        wisdom: parseInt(wisdom),
        charisma: parseInt(charisma),
        gold: parseInt(gold),
        battleActionCount: parseInt(actions),
        weapon: checkExistsInt(parseInt(weapon)),
        chest: checkExistsInt(parseInt(chest)),
        head: checkExistsInt(parseInt(head)),
        waist: checkExistsInt(parseInt(waist)),
        foot: checkExistsInt(parseInt(foot)),
        hand: checkExistsInt(parseInt(hand)),
        neck: checkExistsInt(parseInt(neck)),
        ring: checkExistsInt(parseInt(ring)),
        beastHealth: parseInt(beastHealth),
        statUpgrades: parseInt(statUpgrades),
        name: checkExistsInt(parseInt(name)),
        birthDate: parseInt(birthDate),
        deathDate: parseInt(deathDate),
        goldenTokenId: checkExistsInt(parseInt(goldenTokenId)),
        customRenderer: checkExistsInt(parseInt(customRenderer)),
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
  tier,
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
    beast: checkExistsInt(parseInt(beast)),
    adventurerId: checkExistsInt(parseInt(adventurerId)),
    seed: BigInt(seed).toString(16),
  };

  return {
    entity,
    update: {
      $set: {
        ...entity,
        health: parseInt(health),
        level: checkExistsInt(parseInt(level)),
        tier: checkExistsInt(parseInt(tier)),
        special1: checkExistsInt(parseInt(special1)),
        special2: checkExistsInt(parseInt(special2)),
        special3: checkExistsInt(parseInt(special3)),
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
    beast: checkExistsInt(parseInt(beast)),
    adventurerId: checkExistsInt(parseInt(adventurerId)),
    seed: BigInt(seed).toString(16),
  };

  const newBeast = slayed
    ? {
        ...entity,
        health: parseInt(health),
        slainOnTime: slainOnTime,
        lastUpdatedTime: lastUpdatedTime,
        timestamp,
      }
    : {
        ...entity,
        health: parseInt(health),
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
    id: checkExistsInt(parseInt(adventurerState.adventurerId)),
    owner: checkExistsInt(BigInt(adventurerState.owner).toString(16)),
  };
  return {
    entity,
    update: {
      $set: {
        ...entity,
        entropy: BigInt(adventurerState.entropy).toString(16),
        health: adventurer.health,
        xp: adventurer.xp,
        level: getLevelFromXp(adventurer.xp),
        strength: adventurer.stats.strength,
        dexterity: adventurer.stats.dexterity,
        vitality: adventurer.stats.vitality,
        intelligence: adventurer.stats.intelligence,
        wisdom: adventurer.stats.wisdom,
        charisma: adventurer.stats.charisma,
        luck: adventurer.stats.luck,
        gold: adventurer.gold,
        battleActionCount: adventurer.battleActionCount,
        weapon: checkExistsInt(adventurer.equipment.weapon.id),
        chest: checkExistsInt(adventurer.equipment.chest.id),
        head: checkExistsInt(adventurer.equipment.head.id),
        waist: checkExistsInt(adventurer.equipment.waist.id),
        foot: checkExistsInt(adventurer.equipment.foot.id),
        hand: checkExistsInt(adventurer.equipment.hand.id),
        neck: checkExistsInt(adventurer.equipment.neck.id),
        ring: checkExistsInt(adventurer.equipment.ring.id),
        beastHealth: adventurer.beastHealth,
        statUpgrades: adventurer.statsUpgradesAvailable,
        lastUpdatedTime: timestamp,
        timestamp,
      },
    },
  };
}

export function updateAdventurerOwner({
  adventurerId,
  newOwner,
  timestamp,
}: any) {
  const entity = {
    id: checkExistsInt(BigInt(adventurerId)),
  };

  return {
    entity,
    update: {
      $set: {
        ...entity,
        owner: checkExistsInt(BigInt(newOwner)),
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
    txHash: checkExistsInt(BigInt(txHash).toString(16)),
    adventurerId: checkExistsInt(parseInt(adventurerId)),
    adventurerHealth: checkExistsInt(parseInt(adventurerHealth)),
    discoveryType: checkExistsInt(parseInt(discoveryType)),
    subDiscoveryType: checkExistsInt(parseInt(subDiscoveryType)),
    outputAmount: parseInt(outputAmount),
    obstacle: checkExistsInt(parseInt(obstacle)),
    obstacleLevel: checkExistsInt(parseInt(obstacleLevel)),
    dodgedObstacle: dodgedObstacle,
    damageTaken: parseInt(damageTaken),
    damageLocation: checkExistsInt(parseInt(damageLocation)),
    xpEarnedAdventurer: checkExistsInt(parseInt(xpEarnedAdventurer)),
    xpEarnedItems: checkExistsInt(parseInt(xpEarnedItems)),
    entity: checkExistsInt(parseInt(entity)),
    entityLevel: checkExistsInt(parseInt(entityLevel)),
    entityHealth: parseInt(entityHealth),
    special1: checkExistsInt(parseInt(special1)),
    special2: checkExistsInt(parseInt(special2)),
    special3: checkExistsInt(parseInt(special3)),
    ambushed: ambushed,
    seed: BigInt(seed).toString(16),
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
    txHash: checkExistsInt(BigInt(txHash).toString(16)),
    adventurerId: checkExistsInt(parseInt(adventurerId)),
    beast: checkExistsInt(parseInt(beast)),
    seed: BigInt(seed).toString(16),
    beastHealth: parseInt(beastHealth),
    beastLevel: checkExistsInt(parseInt(beastLevel)),
    special1: checkExistsInt(parseInt(special1)),
    special2: checkExistsInt(parseInt(special2)),
    special3: checkExistsInt(parseInt(special3)),
    adventurerHealth: parseInt(adventurerHealth),
    attacker: checkExistsInt(parseInt(attacker)),
    fled: fled,
    damageDealt: parseInt(damageDealt),
    criticalHit: criticalHit,
    damageTaken: parseInt(damageTaken),
    damageLocation: checkExistsInt(parseInt(damageLocation)),
    xpEarnedAdventurer: parseInt(xpEarnedAdventurer),
    xpEarnedItems: parseInt(xpEarnedItems),
    goldEarned: parseInt(goldEarned),
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
  tier,
  slot,
  type,
  ownerAddress,
  xp,
  greatness,
  special1,
  special2,
  special3,
  isAvailable,
  purchasedTime,
  timestamp,
}: any) {
  const entity = {
    item: checkExistsInt(parseInt(item)),
    adventurerId: checkExistsInt(parseInt(adventurerId)),
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
              checkExistsInt(parseInt(owner)),
              "$owner",
            ],
          },
          equipped: {
            $cond: [
              { $not: ["$owner"] },
              checkExistsInt(parseInt(equipped)),
              "$equipped",
            ],
          },
          tier: {
            $cond: [{ $not: ["$owner"] }, parseInt(tier), "$tier"],
          },
          slot: {
            $cond: [{ $not: ["$owner"] }, parseInt(slot), "$slot"],
          },
          type: {
            $cond: [{ $not: ["$owner"] }, parseInt(type), "$type"],
          },
          ownerAddress: {
            $cond: [
              { $not: ["$owner"] },
              checkExistsInt(BigInt(ownerAddress).toString(16)),
              "$ownerAddress",
            ],
          },
          xp: {
            $cond: [{ $not: ["$owner"] }, parseInt(xp), "$xp"],
          },
          greatness: {
            $cond: [{ $not: ["$owner"] }, parseInt(greatness), "$greatness"],
          },
          special1: {
            $cond: [
              { $not: ["$owner"] },
              checkExistsInt(parseInt(special1)),
              "$special1",
            ],
          },
          special2: {
            $cond: [
              { $not: ["$owner"] },
              checkExistsInt(parseInt(special2)),
              "$special2",
            ],
          },
          special3: {
            $cond: [
              { $not: ["$owner"] },
              checkExistsInt(parseInt(special3)),
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
    item: checkExistsInt(parseInt(item)),
    adventurerId: checkExistsInt(parseInt(adventurerId)),
  };

  if (entity.item) {
    return {
      entity,
      update: {
        $set: {
          ...entity,
          xp: parseInt(xp),
          greatness: getLevelFromXp(xp),
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
    item: checkExistsInt(parseInt(item)),
    adventurerId: checkExistsInt(parseInt(adventurerId)),
  };

  return {
    entity,
    update: {
      $set: {
        ...entity,
        special1: checkExistsInt(parseInt(special1)),
        special2: checkExistsInt(parseInt(special2)),
        special3: checkExistsInt(parseInt(special3)),
      },
    },
  };
}

export function insertHighScore({ adventurerId, timestamp, totalPayout }: any) {
  const entity = {
    adventurerId: checkExistsInt(parseInt(adventurerId)),
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

export function updateItemsOwner({ adventurerId, timestamp, newOwner }: any) {
  const entity = {
    adventurerId: checkExistsInt(parseInt(adventurerId)),
  };

  return {
    entity,
    update: {
      $set: {
        ...entity,
        ownerAddress: checkExistsInt(BigInt(newOwner).toString(16)),
        timestamp,
      },
    },
  };
}

export function updateTotalPayout({ adventurerId, timestamp, newPayout }: any) {
  const entity = {
    adventurerId: checkExistsInt(parseInt(adventurerId)),
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
