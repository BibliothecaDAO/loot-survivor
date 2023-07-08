import { Adventurer } from "../types";
import { calculateLevel } from "./utils";

export class AdventurerClass implements Adventurer {
  [key: string]: number | string | Date | undefined;
  id?: number; // Adventurer ID
  lastAction?: number; // Block number from last action
  owner?: string; // Hex address of the owner
  race?: string; // Race of the adventurer
  homeRealm?: number; // Home Realm of the adventurer
  name?: string; // Name of the adventurer
  order?: string; // Order of the adventurer
  health?: number; // Health of the adventurer
  level?: number; // Level of the adventurer
  strength?: number; // Strength of the adventurer
  dexterity?: number; // Dexterity of the adventurer
  vitality?: number; // Vitality of the adventurer
  intelligence?: number; // Intelligence of the adventurer
  wisdom?: number; // Wisdom of the adventurer
  charisma?: number; // Charisma of the adventurer
  luck?: number; // Luck of the adventurer
  xp?: number; // Experience of the adventurer
  weapon?: string; // Weapon of the adventurer
  chest?: string; // Chest armor of the adventurer
  head?: string; // Head armor of the adventurer
  waist?: string; // Waist armor of the adventurer
  feet?: string; // Feet armor of the adventurer
  hands?: string; // Hands armor of the adventurer
  neck?: string; // Necklace of the adventure
  ring?: string; // Ring of the adventure
  beastHealth?: number; // Beast health adventurer is engaging
  statUpgrades?: number; // Stat upgrades adventurer has
  gold?: number; // Gold adventurer has
  createdTime?: Date; // Block time the adventurer was created
  lastUpdatedTime?: Date; // Block time the adventurer was last updated
  constructor(adventurer: Adventurer) {
    const {
      id,
      lastAction,
      owner,
      race,
      homeRealm,
      name,
      order,
      health,
      level,
      strength,
      dexterity,
      vitality,
      intelligence,
      wisdom,
      charisma,
      luck,
      xp,
      weapon,
      chest,
      head,
      waist,
      feet,
      hands,
      neck,
      ring,
      beastHealth,
      statUpgrades,
      gold,
      createdTime,
      lastUpdatedTime,
    } = adventurer;

    this.id = id;
    this.lastAction = lastAction;
    this.owner = owner;
    this.race = race;
    this.homeRealm = homeRealm;
    this.name = name;
    this.order = order;
    this.health = health;
    this.level = level;
    this.strength = strength;
    this.dexterity = dexterity;
    this.vitality = vitality;
    this.vitality = vitality;
    this.intelligence = intelligence;
    this.wisdom = wisdom;
    this.charisma = charisma;
    this.luck = luck;
    this.xp = calculateLevel(xp ?? 0);
    this.weapon = weapon;
    this.chest = chest;
    this.chest = chest;
    this.head = head;
    this.waist = waist;
    this.feet = feet;
    this.hands = hands;
    this.neck = neck;
    this.ring = ring;
    this.beastHealth = beastHealth;
    this.statUpgrades = statUpgrades;
    this.gold = gold;
    this.createdTime = createdTime;
    this.lastUpdatedTime = lastUpdatedTime;
  }
}
