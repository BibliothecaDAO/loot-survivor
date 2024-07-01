import * as starknet from "@scure/starknet";
import { calculateLevel, formatItemName, getKeyFromValue } from ".";
import { GameData } from "../data/GameData";

const MAX_ID = BigInt(75);
const U128_MAX = BigInt("340282366920938463463374607431768211455");

interface Beast {
  encounter: string;
  id: bigint;
  type: string;
  tier: number;
  level: number;
  health: number;
  location: string;
  dodgeRoll: number;
  nextXp: number;
  specialName: string;
  criticalMultiplier: number;
  damage: number;
}

interface Encounter {
  encounter: string;
  id?: bigint;
  type: string;
  tier: string | number;
  level?: number;
  health?: number;
  location?: string;
  dodgeRoll?: number;
  nextXp: number;
  specialName?: string;
  criticalMultiplier?: number;
  damage?: number;
}

interface Item {
  slot: string;
  item?: string;
  type?: string;
  xp?: number;
  level?: number;
  tier?: number;
  special2?: string;
  special3?: string;
}

interface CombatResult {
  totalDamage: number;
  isCriticalHit: boolean;
}

interface BattleEvent {
  type: string;
  totalDamage: number;
  isCriticalHit: boolean;
  beastDamageType?: string;
  location?: string;
}

export function beastEncounters(
  xpList: number[],
  adventurerEntropy: bigint
): any[] {
  let beasts: any[] = [];

  xpList.forEach((xp) => {
    const level = BigInt(Math.floor(Math.sqrt(xp)));

    let { rnd2 } = getRandomness(xp, adventurerEntropy);

    beasts.push({
      ...beastEncounter(adventurerEntropy, level, xp, rnd2),
      adventurerLevel: Math.floor(Math.sqrt(xp)),
      xp: xp,
    });
  });

  return beasts;
}

export function listAllEncounters(
  xp: number,
  adventurerEntropy: bigint,
  hasBeast: boolean,
  adventurerLevel: number
): Encounter[] {
  let encounters: Encounter[] = [];

  if (!adventurerEntropy) {
    return encounters;
  }

  if (!xp || xp === 0) {
    xp = 4;
  }

  encounters = recurseEncounters(
    encounters,
    [xp],
    adventurerEntropy,
    hasBeast,
    adventurerLevel
  );

  return encounters;
}

function recurseEncounters(
  encounters: Encounter[],
  xpList: number[],
  adventurerEntropy: bigint,
  hasBeast: boolean,
  adventurerLevel: number
): Encounter[] {
  if (encounters.length > 49) {
    return encounters;
  }

  let xp = xpList.sort((a, b) => a - b).shift()!;

  if (calculateLevel(xp) > adventurerLevel) {
    return encounters;
  }

  let nextEncounter = {
    ...getNextEncounter(xp, adventurerEntropy, undefined, hasBeast),
    adventurerLevel: Math.floor(Math.sqrt(xp)),
    xp: xp,
  };
  encounters.push(nextEncounter);

  if (nextEncounter.encounter === "Beast") {
    if (!xpList.includes(xp + 1)) {
      xpList.push(xp + 1);
    }
  }

  if (!xpList.includes(nextEncounter.nextXp)) {
    xpList.push(nextEncounter.nextXp);
  }

  return recurseEncounters(
    encounters,
    xpList,
    adventurerEntropy,
    false,
    adventurerLevel
  );
}

export function getNextBigEncounter(
  lvl: number,
  xp: number,
  adventurerEntropy: bigint,
  items: Item[]
): Encounter {
  let newLevel = Math.floor(Math.sqrt(xp));
  if (newLevel > lvl) {
    return { encounter: "levelup", type: "", tier: "", nextXp: xp + 1 };
  }

  let encounter = getNextEncounter(xp, adventurerEntropy, items);
  if (encounter.encounter !== "Discovery") {
    return encounter;
  }

  return getNextBigEncounter(lvl, xp + 1, adventurerEntropy, items);
}

function getNextEncounter(
  xp: number,
  adventurerEntropy: bigint,
  items?: Item[],
  hasBeast?: boolean
): Encounter {
  let { rnd1, rnd2 } = getRandomness(xp, adventurerEntropy);
  const level = BigInt(Math.floor(Math.sqrt(xp)));

  let encounter = Number(rnd1 % BigInt(3));

  if (hasBeast || encounter === 0) {
    return beastEncounter(adventurerEntropy, level, xp, rnd2, items);
  } else if (encounter === 1) {
    return obstacleEncounter(level, rnd2, xp, items);
  } else {
    return discoveryEncounter(level, rnd2, xp);
  }
}

function getRandomness(xp: number, adventurerEntropy: bigint) {
  let params = [BigInt(xp), adventurerEntropy];

  let poseidon = starknet.poseidonHashMany(params);
  let d = poseidon / U128_MAX;
  let r = poseidon % U128_MAX;

  return { rnd1: r, rnd2: d };
}

function getRandomnessWithHealth(
  xp: number,
  health: number,
  adventurerEntropy: bigint
) {
  let params = [BigInt(xp), BigInt(health), adventurerEntropy];

  let poseidon = starknet.poseidonHashMany(params);

  let d = poseidon / U128_MAX;
  let r = poseidon % U128_MAX;

  return { rnd1: r, rnd2: d };
}

function getDiscoveryItem(entropy: bigint): string {
  let roll = entropy % BigInt(100);

  let itemIndex = 0;

  let gameData = new GameData();

  // 50% chance of T5
  if (roll < 50) {
    itemIndex = Number(entropy % BigInt(gameData.T5_ITEMS.length));
    return gameData.T5_ITEMS[itemIndex];
    // 30% chance of T4
  } else if (roll < 80) {
    itemIndex = Number(entropy % BigInt(gameData.T4_ITEMS.length));
    return gameData.T4_ITEMS[itemIndex];
    // 12% chance of T3
  } else if (roll < 92) {
    itemIndex = Number(entropy % BigInt(gameData.T3_ITEMS.length));
    return gameData.T3_ITEMS[itemIndex];
    // 6% chance of T2
  } else if (roll < 98) {
    itemIndex = Number(entropy % BigInt(gameData.T2_ITEMS.length));
    return gameData.T2_ITEMS[itemIndex];
    // 2% chance of T1
  } else {
    itemIndex = Number(entropy % BigInt(gameData.T1_ITEMS.length));
    return gameData.T1_ITEMS[itemIndex];
  }
}

function getAttackLocation(entropy: bigint): string {
  let slots = BigInt(5);

  let rnd_slot = Number(entropy % slots);

  if (rnd_slot == 0) {
    return "Chest";
  } else if (rnd_slot == 1) {
    return "Head";
  } else if (rnd_slot == 2) {
    return "Waist";
  } else if (rnd_slot == 3) {
    return "Foot";
  } else if (rnd_slot == 4) {
    return "Hand";
  }
  return "Unknown";
}

function getXpReward(level: bigint, tier: bigint): bigint {
  let xp = ((BigInt(6) - tier) * level) / BigInt(2);

  if (xp < 4) {
    return BigInt(4);
  }

  return xp;
}

function abilityBasedAvoidThreat(level: bigint, entropy: bigint): bigint {
  let dice_roll = entropy % level;
  return dice_roll;
}

function getObstacleLevel(level: bigint, entropy: bigint): bigint {
  let obstacleLevel = BigInt(1) + (entropy % (level * BigInt(3)));

  if (level >= 50) {
    obstacleLevel += BigInt(80);
  } else if (level >= 40) {
    obstacleLevel += BigInt(40);
  } else if (level >= 30) {
    obstacleLevel += BigInt(20);
  } else if (level >= 20) {
    obstacleLevel += BigInt(10);
  }

  return obstacleLevel;
}

function getTier(id: bigint): bigint {
  if ((id >= 1 && id <= 5) || (id >= 26 && id < 31) || (id >= 51 && id < 56)) {
    return BigInt(1);
  } else if (
    (id >= 6 && id < 11) ||
    (id >= 31 && id < 36) ||
    (id >= 56 && id < 61)
  ) {
    return BigInt(2);
  } else if (
    (id >= 11 && id < 16) ||
    (id >= 36 && id < 41) ||
    (id >= 61 && id < 66)
  ) {
    return BigInt(3);
  } else if (
    (id >= 16 && id < 21) ||
    (id >= 41 && id < 46) ||
    (id >= 66 && id < 71)
  ) {
    return BigInt(4);
  } else {
    return BigInt(5);
  }
}

function getType(id: bigint): string {
  if (id >= 0 && id < 26) {
    return "Magic";
  } else if (id < 51) {
    return "Blade";
  } else if (id < 76) {
    return "Bludgeon";
  } else {
    return "None";
  }
}

function getBeastHealth(level: bigint, seed: bigint): bigint {
  let health = BigInt(1) + (seed % (level * BigInt(20)));

  if (level >= 50) {
    health += BigInt(500);
  } else if (level >= 40) {
    health += BigInt(400);
  } else if (level >= 30) {
    health += BigInt(200);
  } else if (level >= 20) {
    health += BigInt(100);
  } else {
    health += BigInt(10);
  }

  if (health > 511) {
    return BigInt(511);
  } else {
    return health;
  }
}

function beastEncounter(
  adventurerEntropy: bigint,
  level: bigint,
  xp: number,
  rnd2: bigint,
  items?: Item[]
): Beast {
  let seed = getRandomness(xp, adventurerEntropy).rnd1;

  let beast_id = (seed % MAX_ID) + BigInt(1);

  let beast_health = getBeastHealth(level, seed);

  let beast_tier = getTier(beast_id);
  let beast_type = getType(beast_id);
  let beast_level = getObstacleLevel(level, seed);

  let ambush_location = getAttackLocation(rnd2);
  let roll = abilityBasedAvoidThreat(level, seed);
  let xp_reward = getXpReward(beast_level, beast_tier);
  let specialName = getSpecialName(seed);
  let criticalMultiplier = critical_multiplier(Number(level * BigInt(3)), rnd2);

  let adventurerArmor = items?.find((item) => item.slot === ambush_location);

  let damage = calculateEncounterDamage(
    beast_type,
    Number(beast_tier),
    Number(beast_level),
    adventurerArmor,
    rnd2,
    2,
    Number(level)
  );

  let neck = items?.find((item) => item.slot === "Neck");
  if (neck_reduction(adventurerArmor, neck)) {
    damage -= Math.floor(
      (Math.floor(Math.sqrt(adventurerArmor!.xp!)) *
        (6 - adventurerArmor!.tier!) *
        Math.floor(Math.sqrt(neck!.xp!)) *
        3) /
        100
    );
  }

  return {
    encounter: "Beast",
    id: beast_id,
    type: beast_type,
    tier: Number(beast_tier),
    level: Number(beast_level),
    health: Number(beast_health),
    location: ambush_location,
    dodgeRoll: Number(roll) + 1,
    nextXp: xp + Number(xp_reward),
    specialName,
    criticalMultiplier,
    damage,
  };
}

function obstacleEncounter(
  level: bigint,
  rnd2: bigint,
  xp: number,
  items?: Item[]
): Encounter {
  let obstacle_id = (rnd2 % MAX_ID) + BigInt(1);
  let obstacle_level = getObstacleLevel(level, rnd2);
  let obstacle_tier = getTier(obstacle_id);
  let obstacle_type = getType(obstacle_id);

  let location = getAttackLocation(rnd2);
  let roll = abilityBasedAvoidThreat(level, rnd2);
  let xp_reward = getXpReward(obstacle_level, obstacle_tier);
  let criticalMultiplier = critical_multiplier(Number(level * BigInt(3)), rnd2);

  let adventurerArmor = items?.find((item) => item.slot === location);

  let damage = calculateEncounterDamage(
    obstacle_type,
    Number(obstacle_tier),
    Number(obstacle_level),
    adventurerArmor,
    rnd2,
    2,
    Number(level)
  );

  let neck = items?.find((item) => item.slot === "Neck");
  if (neck_reduction(adventurerArmor, neck)) {
    damage -= Math.floor(
      (Math.floor(Math.sqrt(adventurerArmor!.xp!)) *
        (6 - adventurerArmor!.tier!) *
        Math.floor(Math.sqrt(neck!.xp!)) *
        3) /
        100
    );
  }

  return {
    encounter: "Obstacle",
    id: obstacle_id,
    type: obstacle_type,
    tier: Number(obstacle_tier),
    level: Number(obstacle_level),
    location: location,
    dodgeRoll: Number(roll) + 1,
    nextXp: xp + Number(xp_reward),
    criticalMultiplier,
    damage,
  };
}

function discoveryEncounter(
  level: bigint,
  rnd2: bigint,
  xp: number
): Encounter {
  let r = rnd2 / BigInt(100);
  let type = rnd2 % BigInt(100);

  let discovery_amount = BigInt(0);
  let discovery_type = "";

  if (type < BigInt(45)) {
    discovery_type = "Gold";
    discovery_amount = (r % level) + BigInt(1);
  } else if (type < BigInt(90)) {
    discovery_type = "Health";
    discovery_amount = ((r % level) + BigInt(1)) * BigInt(2);
  } else {
    discovery_type = "Loot";
  }

  let discovery_item = getDiscoveryItem(r);

  let gameData = new GameData();

  return {
    encounter: "Discovery",
    type: discovery_type,
    tier:
      type < BigInt(90)
        ? `${Number(discovery_amount)}`
        : `${getKeyFromValue(gameData.ITEMS, formatItemName(discovery_item))}`,
    nextXp: xp + 1,
  };
}

function getElementalType(weapon_type?: string, armor_type?: string): string {
  if (!weapon_type) return "Weak";
  if (!armor_type) return "Strong";

  if (
    (weapon_type === "Magic" && armor_type === "Metal") ||
    (weapon_type === "Blade" && armor_type === "Cloth") ||
    (weapon_type === "Bludgeon" && armor_type === "Hide")
  ) {
    return "Strong";
  }

  if (
    (weapon_type === "Magic" && armor_type === "Hide") ||
    (weapon_type === "Blade" && armor_type === "Metal") ||
    (weapon_type === "Bludgeon" && armor_type === "Cloth")
  ) {
    return "Weak";
  }

  return "Fair";
}

function elementalAdjustedDamage(
  base_attack: number,
  weapon_type: string,
  armor_type: string
): number {
  let elemental_effect = Math.floor(base_attack / 2);

  if (
    (weapon_type === "Magic" && armor_type === "Metal") ||
    (weapon_type === "Blade" && armor_type === "Cloth") ||
    (weapon_type === "Bludgeon" && armor_type === "Hide")
  ) {
    let damage = base_attack + elemental_effect;
    return damage;
  }

  if (
    (weapon_type === "Magic" && armor_type === "Hide") ||
    (weapon_type === "Blade" && armor_type === "Metal") ||
    (weapon_type === "Bludgeon" && armor_type === "Cloth")
  ) {
    let damage = base_attack - elemental_effect;
    return damage;
  }

  return base_attack;
}

function strength_dmg(damage: number, strength: number): number {
  if (strength == 0) {
    return 0;
  }

  return (damage * strength * 10) / 100;
}

function critical_multiplier(luck: number, entropy: bigint): number {
  if (luck > Number(entropy % BigInt(100))) {
    return Number(entropy % BigInt(5)) + 1;
  }

  return 0;
}

function critical_hit_bonus(
  base_damage: number,
  luck: number,
  ring: Item | undefined,
  entropy: bigint
): number {
  let total = 0;

  if (luck > Number(entropy % BigInt(100))) {
    let damage_boost_base = Math.floor(base_damage / 5);
    let damage_multiplier = Number(entropy % BigInt(5)) + 1;
    total = damage_boost_base * damage_multiplier;

    if (ring?.item === "Titanium Ring" && total > 0) {
      total += Math.floor((total * 3 * Math.floor(Math.sqrt(ring.xp!))) / 100);
    }
  }

  return total;
}

function weapon_special_bonus(
  damage: number,
  weapon: Item,
  beast: Beast,
  ring: Item | undefined,
  entropy: bigint
): number {
  let special2_bonus =
    weapon.special2 && weapon.special2 === beast.specialName
      ? Math.floor(damage * (Number(entropy % BigInt(4)) + 4))
      : 0;
  let special3_bonus =
    weapon.special3 && weapon.special3 === beast.specialName
      ? Math.floor(damage / 4) * (Number(entropy % BigInt(4)) + 1)
      : 0;

  let total_bonus = special2_bonus + special3_bonus;

  if (ring?.item === "Platinum Ring" && total_bonus > 0) {
    total_bonus += Math.floor(
      (total_bonus * 3 * Math.floor(Math.sqrt(ring.xp!))) / 100
    );
  }

  return total_bonus;
}

function calculateDamage(
  weapon: any | undefined,
  beast: any | undefined,
  ring: Item | undefined,
  strength: number,
  luck: number,
  entropy: bigint,
  minimumDmg: number
): CombatResult {
  if (!weapon) return { totalDamage: minimumDmg, isCriticalHit: false };

  let elemental_damage = 0;
  let special_bonus = 0;
  let base_armor = 0;

  let weapon_lvl = weapon.level || Math.floor(Math.sqrt(weapon.xp!));
  let base_attack = weapon_lvl * (6 - weapon.tier!);

  if (beast) {
    let beast_lvl = beast.level || Math.floor(Math.sqrt(beast.xp!));
    let weapon_type = weapon.type || weapon.item! || weapon.attack!;
    let beast_armor = beast.armor || beast.type;

    base_armor = beast_lvl * (6 - beast.tier);
    elemental_damage = elementalAdjustedDamage(
      base_attack,
      weapon_type,
      beast_armor
    );
    special_bonus = weapon_special_bonus(
      elemental_damage,
      weapon,
      beast,
      ring,
      entropy
    );
  } else {
    elemental_damage = base_attack * 1.5;
  }

  let strength_bonus = strength_dmg(elemental_damage, strength);
  let crit_bonus = critical_hit_bonus(elemental_damage, luck, ring, entropy);

  let total_attack =
    elemental_damage + strength_bonus + crit_bonus + special_bonus;
  let total_damage = Math.floor(total_attack - base_armor);

  return {
    totalDamage: Math.max(minimumDmg, total_damage),
    isCriticalHit: crit_bonus > 0,
  };
}

function calculateEncounterDamage(
  type: string | undefined,
  tier: number,
  level: number,
  adventurerArmor: Item | undefined,
  entropy: bigint,
  minimumDmg: number,
  adventurerLevel: number
) {
  if (!type) return minimumDmg;

  let base_attack = level * (6 - tier!);

  let base_armor = 0;
  let elemental_damage = 0;

  if (adventurerArmor) {
    base_armor =
      calculateLevel(adventurerArmor?.xp!) * (6 - adventurerArmor?.tier!);
    elemental_damage = elementalAdjustedDamage(
      base_attack,
      type,
      adventurerArmor?.type!
    );
  } else {
    elemental_damage = base_attack * 1.5;
  }

  let crit_bonus = critical_hit_bonus(
    elemental_damage,
    adventurerLevel * 3,
    undefined,
    entropy
  );

  let total_attack = elemental_damage + crit_bonus;
  let total_damage = Math.floor(total_attack - base_armor);

  return Math.max(minimumDmg, total_damage);
}

function neck_reduction(
  item: Item | undefined,
  neck: Item | undefined
): boolean {
  if (!item || !neck) return false;

  if (item.type === "Cloth" && neck.item === "Amulet") {
    return true;
  }

  if (item.type === "Hide" && neck.item === "Pendant") {
    return true;
  }

  if (item.type === "Metal" && neck.item === "Necklace") {
    return true;
  }

  return false;
}

function beastCounterAttack(
  items: Item[],
  beast: any,
  rnd1: bigint,
  rnd2: bigint,
  adventurerLevel: number
) {
  let attack_location = getAttackLocation(rnd2);
  let item = items.find((item) => item.slot === attack_location);
  let combatResult = calculateDamage(
    beast,
    item,
    undefined,
    0,
    adventurerLevel,
    rnd1,
    2
  );

  let neck = items.find((item) => item.slot === "Neck");
  if (neck_reduction(item, neck)) {
    combatResult.totalDamage -= Math.floor(
      (Math.floor(Math.sqrt(item!.xp!)) *
        (6 - item!.tier!) *
        Math.floor(Math.sqrt(neck!.xp!)) *
        3) /
        100
    );
  }

  let elementalType = getElementalType(beast?.type, item?.type);

  return {
    damage: Math.max(combatResult.totalDamage, 2),
    isCrit: combatResult.isCriticalHit,
    beastDamageType: elementalType,
    location: attack_location,
  };
}

export function nextAttackResult(
  items: Item[],
  beast: any,
  adventurer: any,
  adventurerEntropy: bigint
): {
  beastFatal: boolean;
  damage: number;
  damageType: string;
  isCriticalHit: boolean;
  counter: number;
  counterCrit: boolean;
  adventurerFatal?: boolean;
  beastDamageType?: string;
  location?: string;
} {
  let { rnd1, rnd2 } = getRandomnessWithHealth(
    adventurer.xp,
    adventurer.health,
    adventurerEntropy
  );
  let weapon = items.find((item) => item.slot === "Weapon");
  let ring = items.find((item) => item.slot === "Ring");
  let combatResult = calculateDamage(
    weapon,
    beast,
    ring,
    adventurer.strength,
    adventurer.luck,
    rnd1,
    4
  );
  let elementalType = getElementalType(weapon?.type, beast?.type);

  if (combatResult.totalDamage >= adventurer.beastHealth) {
    return {
      beastFatal: true,
      damage: combatResult.totalDamage,
      damageType: elementalType,
      isCriticalHit: combatResult.isCriticalHit,
      counter: 0,
      counterCrit: false,
    };
  }

  let beastCounter = beastCounterAttack(
    items,
    beast,
    rnd1,
    rnd2,
    adventurer?.level
  );

  return {
    beastFatal: false,
    adventurerFatal: beastCounter.damage >= adventurer.health,
    damage: combatResult.totalDamage,
    damageType: elementalType,
    isCriticalHit: combatResult.isCriticalHit,
    counter: beastCounter.damage,
    counterCrit: beastCounter.isCrit,
    beastDamageType: beastCounter.beastDamageType,
    location: beastCounter.location,
  };
}

export function getGoldReward(
  items: Item[],
  beast: any,
  xp: number,
  adventurerEntropy: bigint
): number {
  if (xp < 1) {
    return 4;
  }

  let seed = getRandomness(xp, adventurerEntropy).rnd1;

  let ring = items.find(
    (item) => item.slot === "Ring" && item.item === "Gold Ring"
  );

  let base_reward = Math.max(
    4,
    Math.floor(((6 - beast.tier) * beast.level) / 2 / 2)
  );

  let bonus_base = Math.floor(base_reward / 4);
  let bonus_multiplier = Number(seed % BigInt(5));

  base_reward += Math.floor(bonus_base * bonus_multiplier);

  if (ring) {
    base_reward += Math.floor(
      (base_reward * Math.floor(Math.sqrt(ring.xp!)) * 3) / 100
    );
  }

  return Math.max(4, base_reward);
}

function getSpecialName(seed: bigint): string {
  let special2 = 1 + Number(seed % BigInt(69));
  let special3 = 1 + Number(seed % BigInt(18));
  return `${ITEM_NAME_PREFIXES[special2]} ${ITEM_NAME_SUFFIXES[special3]}`;
}

export function simulateBattle(
  items: Item[],
  beast: any,
  adventurer: any,
  adventurerEntropy: bigint
): { success: boolean; healthLeft: number; events: BattleEvent[] } {
  let health = adventurer.health;
  let beastHealth = adventurer.beastHealth;

  let events: BattleEvent[] = [];

  while (health > 0) {
    let { rnd1, rnd2 } = getRandomnessWithHealth(
      adventurer.xp,
      health,
      adventurerEntropy
    );
    let weapon = items.find((item) => item.slot === "Weapon");
    let ring = items.find((item) => item.slot === "Ring");
    let combatResult = calculateDamage(
      weapon,
      beast,
      ring,
      adventurer.strength,
      adventurer.luck,
      rnd1,
      4
    );

    events.push({
      type: "adventurer_attack",
      totalDamage: combatResult.totalDamage,
      isCriticalHit: combatResult.isCriticalHit,
      beastDamageType: undefined,
      location: undefined,
    });

    if (combatResult.totalDamage >= beastHealth) {
      return {
        success: true,
        healthLeft: health,
        events,
      };
    }

    let beastCounter = beastCounterAttack(
      items,
      beast,
      rnd1,
      rnd2,
      adventurer?.level
    );

    events.push({
      type: "beast_attack",
      totalDamage: beastCounter.damage,
      isCriticalHit: beastCounter.isCrit,
      beastDamageType: beastCounter.beastDamageType,
      location: beastCounter.location,
    });

    if (beastCounter.damage >= health) {
      return {
        success: false,
        healthLeft: 0,
        events,
      };
    }

    beastHealth -= combatResult.totalDamage;
    health -= beastCounter.damage;
  }

  return {
    success: false,
    healthLeft: 0,
    events,
  };
}

export function simulateFlee(
  items: Item[],
  beast: any,
  adventurer: any,
  adventurerEntropy: bigint
): { flee: boolean; healthLeft: number; events: BattleEvent[] } {
  if (!adventurer.dexterity) {
    return {
      flee: false,
      healthLeft: 0,
      events: [],
    };
  }

  const level = BigInt(Math.floor(Math.sqrt(adventurer.xp)));
  let health = adventurer.health;

  let events: BattleEvent[] = [];

  while (health > 0) {
    let { rnd1, rnd2 } = getRandomnessWithHealth(
      adventurer.xp,
      health,
      adventurerEntropy
    );
    let roll = abilityBasedAvoidThreat(level, rnd1);

    if (adventurer.dexterity > roll) {
      return {
        flee: true,
        healthLeft: health,
        events,
      };
    }

    let beastCounter = beastCounterAttack(
      items,
      beast,
      rnd2,
      rnd2,
      Number(level)
    );
    health -= beastCounter.damage;

    events.push({
      type: "beast_attack",
      totalDamage: beastCounter.damage,
      isCriticalHit: beastCounter.isCrit,
      beastDamageType: beastCounter.beastDamageType,
      location: beastCounter.location,
    });
  }

  return {
    flee: false,
    healthLeft: 0,
    events,
  };
}

const ITEM_NAME_PREFIXES: { [key: number]: string } = {
  1: "Agony",
  2: "Apocalypse",
  3: "Armageddon",
  4: "Beast",
  5: "Behemoth",
  6: "Blight",
  7: "Blood",
  8: "Bramble",
  9: "Brimstone",
  10: "Brood",
  11: "Carrion",
  12: "Cataclysm",
  13: "Chimeric",
  14: "Corpse",
  15: "Corruption",
  16: "Damnation",
  17: "Death",
  18: "Demon",
  19: "Dire",
  20: "Dragon",
  21: "Dread",
  22: "Doom",
  23: "Dusk",
  24: "Eagle",
  25: "Empyrean",
  26: "Fate",
  27: "Foe",
  28: "Gale",
  29: "Ghoul",
  30: "Gloom",
  31: "Glyph",
  32: "Golem",
  33: "Grim",
  34: "Hate",
  35: "Havoc",
  36: "Honour",
  37: "Horror",
  38: "Hypnotic",
  39: "Kraken",
  40: "Loath",
  41: "Maelstrom",
  42: "Mind",
  43: "Miracle",
  44: "Morbid",
  45: "Oblivion",
  46: "Onslaught",
  47: "Pain",
  48: "Pandemonium",
  49: "Phoenix",
  50: "Plague",
  51: "Rage",
  52: "Rapture",
  53: "Rune",
  54: "Skull",
  55: "Sol",
  56: "Soul",
  57: "Sorrow",
  58: "Spirit",
  59: "Storm",
  60: "Tempest",
  61: "Torment",
  62: "Vengeance",
  63: "Victory",
  64: "Viper",
  65: "Vortex",
  66: "Woe",
  67: "Wrath",
  68: "Lights",
  69: "Shimmering",
};

const ITEM_NAME_SUFFIXES: { [key: number]: string } = {
  1: "Bane",
  2: "Root",
  3: "Bite",
  4: "Song",
  5: "Roar",
  6: "Grasp",
  7: "Instrument",
  8: "Glow",
  9: "Bender",
  10: "Shadow",
  11: "Whisper",
  12: "Shout",
  13: "Growl",
  14: "Tear",
  15: "Peak",
  16: "Form",
  17: "Sun",
  18: "Moon",
};
