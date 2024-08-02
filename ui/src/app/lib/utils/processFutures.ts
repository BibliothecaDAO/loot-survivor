import * as starknet from "@scure/starknet";
import { calculateLevel, formatItemName, getKeyFromValue } from ".";
import { GameData } from "../data/GameData";

const MAX_ID = BigInt(75);
const TWO_POW_64_NZ = BigInt("18446744073709551616");
const TWO_POW_32_NZ = BigInt("4294967296");
const TWO_POW_16_NZ = BigInt("65536");
const TWO_POW_8_NZ = BigInt("256");

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
  isCritical: boolean;
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
  isCritical?: boolean;
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

    let { rnd1, rnd3, rnd4, rnd5, rnd6, rnd7 } = getRandomness(
      xp,
      adventurerEntropy
    );

    beasts.push({
      ...beastEncounter(
        adventurerEntropy,
        level,
        xp,
        rnd1,
        rnd3,
        rnd4,
        rnd5,
        rnd6,
        rnd7,
        rnd5, // use same entropy for crit hit, initial attack location, and beast specials
        rnd6
      ),
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
  let { rnd1, rnd3, rnd4, rnd5, rnd6, rnd7, rnd8 } = getRandomness(
    xp,
    adventurerEntropy
  );
  const level = BigInt(Math.floor(Math.sqrt(xp)));

  let encounter = Number(rnd8 % BigInt(3));

  if (hasBeast || encounter === 0) {
    return beastEncounter(
      adventurerEntropy,
      level,
      xp,
      rnd1,
      rnd3,
      rnd4,
      rnd5,
      rnd6,
      rnd7,
      rnd5, // use same entropy for crit hit, initial attack location, and beast specials
      rnd6
    ); // to create some fun organic lore for the beast special names, items);
  } else if (encounter === 1) {
    return obstacleEncounter(level, rnd1, rnd4, rnd5, rnd6, rnd7, xp, items);
  } else {
    return discoveryEncounter(level, rnd5, rnd6, rnd7, xp);
  }
}

function getLower128Bits(bigInt: bigint): bigint {
  // Create a mask with 128 1's
  const mask = (1n << 128n) - 1n;

  // Use bitwise AND to keep only the lower 128 bits
  return bigInt & mask;
}

function split_poseidon(poseidon: bigint) {
  let u128_low = getLower128Bits(poseidon);

  let rnd1_u64 = u128_low / TWO_POW_64_NZ;
  let rnd2_u64 = u128_low % TWO_POW_64_NZ;

  let rnd1_u32 = rnd1_u64 / TWO_POW_32_NZ;
  let rnd2_u32 = rnd1_u64 % TWO_POW_32_NZ;
  let rnd3_u32 = rnd2_u64 / TWO_POW_32_NZ;
  let rnd4_u32 = rnd2_u64 % TWO_POW_32_NZ;

  let rnd1_u16 = rnd3_u32 / TWO_POW_16_NZ;
  let rnd2_u16 = rnd3_u32 % TWO_POW_16_NZ;
  let rnd3_u16 = rnd4_u32 / TWO_POW_16_NZ;
  let rnd4_u16 = rnd4_u32 % TWO_POW_16_NZ;

  let rnd1_u8 = rnd3_u16 / TWO_POW_8_NZ;
  let rnd2_u8 = rnd3_u16 % TWO_POW_8_NZ;
  let rnd3_u8 = rnd4_u16 / TWO_POW_8_NZ;
  let rnd4_u8 = rnd4_u16 % TWO_POW_8_NZ;

  return {
    rnd1_u32,
    rnd2_u32,
    rnd1_u16,
    rnd2_u16,
    rnd1_u8,
    rnd2_u8,
    rnd3_u8,
    rnd4_u8,
  };
}

export function getRandomness(xp: number, adventurerEntropy: bigint) {
  let params = [BigInt(xp), adventurerEntropy];

  let poseidon = starknet.poseidonHashMany(params);
  let {
    rnd1_u32,
    rnd2_u32,
    rnd1_u16,
    rnd2_u16,
    rnd1_u8,
    rnd2_u8,
    rnd3_u8,
    rnd4_u8,
  } = split_poseidon(poseidon);

  return {
    rnd1: rnd1_u32,
    rnd2: rnd2_u32,
    rnd3: rnd1_u16,
    rnd4: rnd2_u16,
    rnd5: rnd1_u8,
    rnd6: rnd2_u8,
    rnd7: rnd3_u8,
    rnd8: rnd4_u8,
  };
}

export function getRandomnessWithActions(
  xp: number,
  actions: number,
  adventurerEntropy: bigint
) {
  let params = [BigInt(xp), adventurerEntropy, BigInt(actions)];

  let poseidon = starknet.poseidonHashMany(params);
  let rnd1_u32 = poseidon % TWO_POW_32_NZ;

  let rnd1_u16 = rnd1_u32 / TWO_POW_16_NZ;
  let rnd2_u16 = rnd1_u32 % TWO_POW_16_NZ;

  let rnd1_u8 = rnd1_u16 / TWO_POW_8_NZ;
  let rnd2_u8 = rnd1_u16 % TWO_POW_8_NZ;
  let rnd3_u8 = rnd2_u16 / TWO_POW_8_NZ;
  let rnd4_u8 = rnd2_u16 % TWO_POW_8_NZ;

  return {
    rnd1_u8,
    rnd2_u8,
    rnd3_u8,
    rnd4_u8,
  };
}

function getDiscoveryItem(tier_rnd: bigint, item_rnd: bigint): string {
  let roll = (tier_rnd * BigInt(100) + BigInt(127)) / BigInt(255);

  let itemIndex = 0;

  let gameData = new GameData();

  // 50% chance of T5
  if (roll < 50) {
    itemIndex = Number(item_rnd % BigInt(gameData.T5_ITEMS.length));
    return gameData.T5_ITEMS[itemIndex];
    // 30% chance of T4
  } else if (roll < 80) {
    itemIndex = Number(item_rnd % BigInt(gameData.T4_ITEMS.length));
    return gameData.T4_ITEMS[itemIndex];
    // 12% chance of T3
  } else if (roll < 92) {
    itemIndex = Number(item_rnd % BigInt(gameData.T3_ITEMS.length));
    return gameData.T3_ITEMS[itemIndex];
    // 6% chance of T2
  } else if (roll < 98) {
    itemIndex = Number(item_rnd % BigInt(gameData.T2_ITEMS.length));
    return gameData.T2_ITEMS[itemIndex];
    // 2% chance of T1
  } else {
    itemIndex = Number(item_rnd % BigInt(gameData.T1_ITEMS.length));
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

function getXpReward(
  level: bigint,
  tier: bigint,
  adventurerLevel: number
): bigint {
  let xp = ((BigInt(6) - tier) * level) / BigInt(2);

  let adusted_xp =
    (xp * BigInt(100 - Math.min(adventurerLevel * 2, 95))) / BigInt(100);

  if (adusted_xp < 4) {
    return BigInt(4);
  }

  return adusted_xp;
}

function abilityBasedAvoidThreat(level: bigint, entropy: bigint): bigint {
  return (level * entropy) / BigInt(255);
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
  seed: bigint,
  health_rnd: bigint,
  level_rnd: bigint,
  dmg_location_rnd: bigint,
  crit_hit_rnd: bigint,
  ambush_rnd: bigint,
  specials1_rnd: bigint, // use same entropy for crit hit, initial attack location, and beast specials
  specials2_rnd: bigint,
  items?: Item[]
): Beast {
  let beast_id = (seed % MAX_ID) + BigInt(1);

  let beast_health = getBeastHealth(level, health_rnd);

  let beast_tier = getTier(beast_id);
  let beast_type = getType(beast_id);
  let beast_level = getObstacleLevel(level, level_rnd);

  let ambush_location = getAttackLocation(dmg_location_rnd);
  let roll = abilityBasedAvoidThreat(level, ambush_rnd);
  let xp_reward = getXpReward(beast_level, beast_tier, Number(level));
  let specialName = getSpecialName(specials1_rnd, specials2_rnd);
  let isCritical = getCritical(Number(level * BigInt(3)), crit_hit_rnd);
  let adventurerArmor = items?.find((item) => item.slot === ambush_location);

  let damage = calculateEncounterDamage(
    beast_type,
    Number(beast_tier),
    Number(beast_level),
    adventurerArmor,
    crit_hit_rnd,
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
    isCritical,
    damage,
  };
}

function obstacleEncounter(
  level: bigint,
  seed: bigint,
  level_rnd: bigint,
  dmg_location_rnd: bigint,
  crit_hit_rnd: bigint,
  dodge_rnd: bigint,
  xp: number,
  items?: Item[]
): Encounter {
  let obstacle_id = (seed % MAX_ID) + BigInt(1);
  let obstacle_level = getObstacleLevel(level, level_rnd);
  let obstacle_tier = getTier(obstacle_id);
  let obstacle_type = getType(obstacle_id);

  let location = getAttackLocation(dmg_location_rnd);
  let roll = abilityBasedAvoidThreat(level, dodge_rnd);
  let xp_reward = getXpReward(obstacle_level, obstacle_tier, Number(level));
  let isCritical = getCritical(Number(level * BigInt(3)), crit_hit_rnd);

  let adventurerArmor = items?.find((item) => item.slot === location);

  let damage = calculateEncounterDamage(
    obstacle_type,
    Number(obstacle_tier),
    Number(obstacle_level),
    adventurerArmor,
    crit_hit_rnd,
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
    isCritical,
    damage,
  };
}

function discoveryEncounter(
  level: bigint,
  discovery_type_rnd: bigint,
  amount_rnd1: bigint,
  amount_rnd2: bigint,
  xp: number
): Encounter {
  let type = (discovery_type_rnd * BigInt(100) + BigInt(127)) / BigInt(255);

  let discovery_amount = BigInt(0);
  let discovery_type = "";

  if (type < BigInt(45)) {
    discovery_type = "Gold";
    discovery_amount = (amount_rnd1 % level) + BigInt(1);
  } else if (type < BigInt(90)) {
    discovery_type = "Health";
    discovery_amount = ((amount_rnd1 % level) + BigInt(1)) * BigInt(2);
  } else {
    discovery_type = "Loot";
  }

  let discovery_item = getDiscoveryItem(amount_rnd1, amount_rnd2);

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

function getCritical(luck: number, entropy: bigint): boolean {
  return (luck * 255) / 100 > Number(entropy);
}

function critical_hit_bonus(
  base_damage: number,
  luck: number,
  ring: Item | undefined,
  entropy: bigint
): number {
  let total = 0;

  if (getCritical(luck, entropy)) {
    total = base_damage;

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
  beastCriticalRnd: bigint,
  attackLocationRnd: bigint,
  adventurerLevel: number
) {
  let attack_location = getAttackLocation(attackLocationRnd);
  let item = items.find((item) => item.slot === attack_location);
  let combatResult = calculateDamage(
    beast,
    item,
    undefined,
    0,
    adventurerLevel,
    beastCriticalRnd,
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
  let { rnd2_u8, rnd3_u8, rnd4_u8 } = getRandomnessWithActions(
    adventurer.xp,
    adventurer.battleActionCount,
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
    rnd2_u8,
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
    rnd3_u8,
    rnd4_u8,
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

  let ring = items.find(
    (item) => item.slot === "Ring" && item.item === "Gold Ring"
  );

  let base_reward = Math.max(
    4,
    Math.floor(((6 - beast.tier) * beast.level) / 2 / 2)
  );

  if (ring) {
    base_reward += Math.floor(
      (base_reward * Math.floor(Math.sqrt(ring.xp!)) * 3) / 100
    );
  }

  return Math.max(4, base_reward);
}

function getSpecialName(
  special_2_seed: bigint,
  special_3_seed: bigint
): string {
  let special2 = 1 + Number(special_2_seed % BigInt(69));
  let special3 = 1 + Number(special_3_seed % BigInt(18));
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
  let battleActions = adventurer.battleActionCount;

  let events: BattleEvent[] = [];

  while (health > 0) {
    let { rnd2_u8, rnd3_u8, rnd4_u8 } = getRandomnessWithActions(
      adventurer.xp,
      battleActions,
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
      rnd2_u8,
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
      rnd3_u8,
      rnd4_u8,
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
    battleActions += 1;
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
  let battleActions = adventurer.battleActionCount;

  let events: BattleEvent[] = [];

  while (health > 0) {
    let { rnd1_u8, rnd3_u8, rnd4_u8 } = getRandomnessWithActions(
      adventurer.xp,
      battleActions,
      adventurerEntropy
    );
    let roll = abilityBasedAvoidThreat(level, rnd1_u8);

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
      rnd3_u8,
      rnd4_u8,
      Number(level)
    );
    health -= beastCounter.damage;
    battleActions += 1;

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
