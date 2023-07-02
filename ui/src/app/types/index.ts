import { ScreenPage } from "../hooks/useUIStore";

export interface Adventurer {
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
}

export interface ItemIndexer {
  item?: string; // name
  cost?: number; // purchase cost for the item
  adventurerId: number; // Adventurer ID
  owneAddress?: string; // Hex Address of the Owner
  owner?: boolean; // Is the item owned by the adventurer?
  equipped?: boolean; // Is the item equipped by the adventurer?
  purchasedTime: Date; // Block time the item was purchased
  namePrefix?: number; // First part of the name prefix (i.e Demon)
  nameSuffix?: number; // Second part of the name prefix (i.e Grasp)
  itemSuffix?: number; // Stored value if item has a Suffix (i.e of Power)
  xp?: number; // Experience of the item
  lastUpdatedTime: Date; // Block time the item was last updated
}

export interface Item {
  item?: string; // name
  cost?: number; // purchase cost for the item
  adventurerId?: number; // Adventurer ID
  owneAddress?: string; // Hex Address of the Owner
  owner?: boolean; // Is the item owned by the adventurer?
  equipped?: boolean; // Is the item equipped by the adventurer?
  purchasedTime?: Date; // Block time the item was purchased
  namePrefix?: number; // First part of the name prefix (i.e Demon)
  nameSuffix?: number; // Second part of the name prefix (i.e Grasp)
  itemSuffix?: number; // Stored value if item has a Suffix (i.e of Power)
  xp?: number; // Experience of the item
  slot?: string; // Item slot location
  tier?: number; // Tier of the item
  type?: string; // Type of the item
  lastUpdatedTime?: Date; // Block time the item was last updated
}
export interface Battle {
  adventurerId?: number; // Adventurer ID
  beast?: string; // Beast adventurer is engaging
  beastHealth?: number; // Beast health adventurer is engaging
  beastLevel?: number; // Beast level adventurer is engaging
  beastNamePrefix?: string; // Name prefix of the beast
  beastNameSuffix?: string; // Name suffix of the beast
  attacker?: string; // Attacker in the battle (Adventurer or Beast)
  fled?: boolean; // Did the adventurer flee?
  damageDealt?: number; // Damage dealt to the beast
  damageTaken?: number; // Damage taken from the beast
  damageLocation?: string; // Location of the damage taken
  xpEarnedAdventurer?: number; // Experience earned by the adventurer
  xpEarnedItems?: number; // Experience earned by the items
  goldEarned?: number; // Gold earned by the adventurer
  txHash?: string; // Transaction hash
  timestamp?: Date; // Block time of the battle
}

export interface Discovery {
  adventurerId?: number; // Adventurer ID
  discoveryType?: string; // Type of discovery
  subDiscoveryType?: string; // Sub type of discovery
  outputAmount?: number; // Amount of the discovery finding
  obstacle?: string; // Obstacle discovered
  obstacleLevel?: number; // Obstacle level discovered
  dodgedObstacle?: boolean; // Did the adventurer dodge the obstacle?
  damageTaken?: number; // Damage taken from the obstacle
  damageLocation?: string; // Location of the damage taken
  xpEarnedAdventurer?: number; // Experience earned by the adventurer
  xpEarnedItems?: number; // Experience earned by the items
  entity?: string; // Entity discovered
  entityLevel?: number; // Entity level discovered
  entityHealth?: number; // Entity health discovered
  entityNamePrefix?: string; // Entity name prifix
  entityNameSuffix?: string; // Entity name suffix
  ambushed?: boolean; // Did the adventurer ambush the entity?
  discoveryTime?: Date; // Block time of the discovery
  txHash?: string; // Transaction hash
}

export interface Score {
  adventurerId: number; // Adventurer ID
  address: string; // Hex Address of the adventurer owner
  rank: number; // Rank of the score
  xp: number; // Experience points of the adventurer
  txHash: string; // Hex of the transaction hash
  scoreTime: Date; // Time of the score
}

export interface Metadata {
  method?: string; // Method of the transaction
  description?: string; // Description of the transaction
  items?: string[]; // Items in the transaction
}

export type Menu = {
  id: number;
  label: string;
  screen: ScreenPage;
  disabled?: boolean;
};

export type FormData = {
  startingWeapon: string;
  name: string;
  homeRealmId: string;
  race: string;
  order: string;
};

export type Beast =
  | "Basilisk"
  | "Kitsune"
  | "Jiangshi"
  | "Rakshasa"
  | "Warlock"
  | "Minotaur"
  | "Dragon"
  | "Phoenix"
  | "Manticore"
  | "Griffin"
  | "Cyclops"
  | "Titan"
  | "Yeti"
  | "Colossus"
  | "Balrog"
  | "Gorgon"
  | "Anansi"
  | "Lich"
  | "Chimera"
  | "Wendigo"
  | "Harpy"
  | "Arachne"
  | "Nue"
  | "Skinwalker"
  | "Chupacabra"
  | "Oni"
  | "Ogre"
  | "Juggernaut"
  | "Bigfoot"
  | "Orc"
  | "Cerberus"
  | "Werewolf"
  | "Banshee"
  | "Draugr"
  | "Vampire"
  | "Weretiger"
  | "Wyvern"
  | "Roc"
  | "Qilin"
  | "Pegasus"
  | "Behemoth"
  | "Ent"
  | "Giant"
  | "Kraken"
  | "Leviathan"
  | "Golem"
  | "Goblin"
  | "Ghoul"
  | "Pixie"
  | "Sprite"
  | "Kappa"
  | "Hippogriff"
  | "Fenrir"
  | "Jaguar"
  | "Ammit"
  | "DireWolf"
  | "Skeleton"
  | "Nephilim"
  | "Tarrasque"
  | "Berserker"
  | "Fairy"
  | "Leprechaun"
  | "Kelpie"
  | "Wraith"
  | "Gnome"
  | "Bear"
  | "Wolf"
  | "Scorpion"
  | "Spider"
  | "Rat"
  | "Ettin"
  | "Jotunn"
  | "Hydra"
  | "NemeanLion"
  | "Troll";

export const NullAdventurer: Adventurer = {
  id: undefined,
  lastAction: undefined,
  owner: undefined,
  race: undefined,
  homeRealm: undefined,
  name: undefined,
  order: undefined,
  health: undefined,
  level: undefined,
  strength: undefined,
  dexterity: undefined,
  vitality: undefined,
  intelligence: undefined,
  wisdom: undefined,
  charisma: undefined,
  luck: undefined,
  xp: undefined,
  weapon: undefined,
  chest: undefined,
  head: undefined,
  waist: undefined,
  feet: undefined,
  hands: undefined,
  neck: undefined,
  ring: undefined,
  beastHealth: undefined,
  statUpgrades: undefined,
  gold: undefined,
  createdTime: undefined,
  lastUpdatedTime: undefined,
};

export const NullBattle: Battle = {
  adventurerId: undefined,
  beast: undefined,
  beastHealth: undefined,
  beastLevel: undefined,
  beastNamePrefix: undefined,
  beastNameSuffix: undefined,
  attacker: undefined,
  fled: undefined,
  damageDealt: undefined,
  damageTaken: undefined,
  damageLocation: undefined,
  xpEarnedAdventurer: undefined,
  xpEarnedItems: undefined,
  goldEarned: undefined,
  txHash: undefined,
  timestamp: undefined,
};

export const NullDiscovery: Discovery = {
  adventurerId: undefined,
  discoveryType: undefined,
  subDiscoveryType: undefined,
  outputAmount: undefined,
  obstacle: undefined,
  obstacleLevel: undefined,
  dodgedObstacle: undefined,
  damageTaken: undefined,
  damageLocation: undefined,
  xpEarnedAdventurer: undefined,
  xpEarnedItems: undefined,
  entity: undefined,
  entityLevel: undefined,
  entityHealth: undefined,
  entityNamePrefix: undefined,
  entityNameSuffix: undefined,
  ambushed: undefined,
  discoveryTime: undefined,
  txHash: undefined,
};

export const NullItem: Item = {
  item: undefined,
  cost: undefined,
  adventurerId: undefined,
  owneAddress: undefined,
  owner: undefined,
  equipped: undefined,
  purchasedTime: undefined,
  namePrefix: undefined,
  nameSuffix: undefined,
  itemSuffix: undefined,
  xp: undefined,
  slot: undefined,
  tier: undefined,
  type: undefined,
  lastUpdatedTime: undefined,
};
