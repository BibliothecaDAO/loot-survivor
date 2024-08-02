import { Adventurer, Item } from "@/app/types";
import { calculateLevel, getItemData } from "@/app/lib/utils";

export class AdventurerClass implements Adventurer {
  [key: string]: number | string | Date | undefined;
  id?: number; // Adventurer ID
  owner?: string; // Hex address of the owner
  entropy?: string; // Entropy of the adventurer
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
  foot?: string; // Feet armor of the adventurer
  hand?: string; // Hands armor of the adventurer
  neck?: string; // Necklace of the adventure
  ring?: string; // Ring of the adventure
  beastHealth?: number; // Beast health adventurer is engaging
  statUpgrades?: number; // Stat upgrades adventurer has
  birthDate?: number; // Birth date of the adventurer
  deathDate?: number; // Death date of the adventurer
  goldenTokenId?: number; // Golden token ID of the adventurer
  customRenderer?: string; // Custom renderer of the adventurer
  battleActionCount?: number; // Battle action count of the adventurer
  gold?: number; // Gold adventurer has
  createdTime?: Date; // Block time the adventurer was created
  lastUpdatedTime?: Date; // Block time the adventurer was last updated
  timestamp?: Date; // Indexer timestamp of event process
  constructor(adventurer: Adventurer) {
    const {
      id,
      owner,
      entropy,
      name,
      order,
      health,
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
      foot,
      hand,
      neck,
      ring,
      beastHealth,
      statUpgrades,
      birthDate,
      deathDate,
      goldenTokenId,
      customRenderer,
      battleActionCount,
      gold,
      createdTime,
      lastUpdatedTime,
      timestamp,
    } = adventurer;

    this.id = id;
    this.owner = owner;
    this.entropy = entropy;
    this.name = name;
    this.order = order;
    this.health = health;
    this.level = calculateLevel(xp ?? 0);
    this.strength = strength;
    this.dexterity = dexterity;
    this.vitality = vitality;
    this.vitality = vitality;
    this.intelligence = intelligence;
    this.wisdom = wisdom;
    this.charisma = charisma;
    this.luck = luck;
    this.xp = xp;
    this.weapon = weapon;
    this.chest = chest;
    this.chest = chest;
    this.head = head;
    this.waist = waist;
    this.foot = foot;
    this.hand = hand;
    this.neck = neck;
    this.ring = ring;
    this.beastHealth = beastHealth;
    this.statUpgrades = statUpgrades;
    this.birthDate = birthDate;
    this.deathDate = deathDate;
    this.goldenTokenId = goldenTokenId;
    this.customRenderer = customRenderer;
    this.battleActionCount = battleActionCount;
    this.gold = gold;
    this.createdTime = createdTime;
    this.lastUpdatedTime = lastUpdatedTime;
    this.timestamp = timestamp;
  }
}

export class ItemClass implements Item {
  [key: string]: string | number | undefined | boolean | Date;
  item?: string; // name
  cost?: number; // purchase cost for the item
  adventurerId?: number; // Adventurer ID
  ownerAddress?: string; // Hex Address of the Owner
  owner?: boolean; // Is the item owned by the adventurer?
  equipped?: boolean; // Is the item equipped by the adventurer?
  purchasedTime?: Date; // Block time the item was purchased
  special1?: string; // First special on the item (i.e of Power)
  special2?: string; // Second special on the item (i.e Grasp)
  special3?: string; // Third special on the item (i.e Demon)
  xp?: number; // Experience of the item
  slot?: string; // Item slot location
  tier?: number; // Tier of the item
  type?: string; // Type of the item
  lastUpdatedTime?: Date; // Block time the item was last updated
  constructor(items: Item) {
    const {
      item,
      cost,
      adventurerId,
      ownerAddress,
      owner,
      equipped,
      purchasedTime,
      special1,
      special2,
      special3,
      xp,
      lastUpdatedTime,
    } = items;

    const { tier, slot, type } = getItemData(item ?? "");

    this.item = item;
    this.cost = cost;
    this.adventurerId = adventurerId;
    this.ownerAddress = ownerAddress;
    this.owner = owner;
    this.equipped = equipped;
    this.purchasedTime = purchasedTime;
    this.special1 = special1;
    this.special2 = special2;
    this.special3 = special3;
    this.xp = xp;
    this.slot = slot;
    this.tier = tier;
    this.type = type;
    this.lastUpdatedTime = lastUpdatedTime;
  }
}
