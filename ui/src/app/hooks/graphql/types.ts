export type Maybe<T> = T | null;

export type Scalars = {
  ID: string;
  String: string;
  Boolean: boolean;
  Int: number;
  Float: number;
  JSON: any;
  Timestamp: any;
  Hex: string;
};

/** The Adventurer Model */
export type AdventurerQuery = {
  _typename?: "Query";
  getAdventurer: Array<{
    __typename?: "Adventurer";
    id: Maybe<Scalars["Int"]>;
    lastAction: Maybe<Scalars["Int"]>;
    owner: Maybe<Scalars["Hex"]>;
    race: Maybe<Scalars["String"]>;
    name: Maybe<Scalars["String"]>;
    order: Maybe<Scalars["String"]>;
    health: Maybe<Scalars["Int"]>;
    strength: Maybe<Scalars["Int"]>;
    dexterity: Maybe<Scalars["Int"]>;
    vitality: Maybe<Scalars["Int"]>;
    intelligence: Maybe<Scalars["Int"]>;
    wisdom: Maybe<Scalars["Int"]>;
    charisma: Maybe<Scalars["Int"]>;
    luck: Maybe<Scalars["Int"]>;
    xp: Maybe<Scalars["Int"]>;
    weapon: Maybe<Scalars["String"]>;
    chest: Maybe<Scalars["String"]>;
    head: Maybe<Scalars["String"]>;
    waist: Maybe<Scalars["String"]>;
    feet: Maybe<Scalars["String"]>;
    hands: Maybe<Scalars["String"]>;
    neck: Maybe<Scalars["String"]>;
    ring: Maybe<Scalars["String"]>;
    beast: Maybe<Scalars["String"]>;
    beastHealth: Maybe<Scalars["Int"]>;
    statUpgrades: Maybe<Scalars["Int"]>;
    startBlock: Maybe<Scalars["Int"]>;
    revealBlock: Maybe<Scalars["Int"]>;
    actionsPerBlock: Maybe<Scalars["Int"]>;
    gold: Maybe<Scalars["Int"]>;
    createdTime: Maybe<Scalars["Timestamp"]>;
    lastUpdatedTime: Maybe<Scalars["Timestamp"]>;
  }>;
};

/** The Score Model */
export type ScoreQuery = {
  __typename?: "Score";
  adventurerId: Maybe<Scalars["Int"]>;
  address: Maybe<Scalars["Hex"]>;
  rank: Maybe<Scalars["Int"]>;
  xp: Maybe<Scalars["Int"]>;
  txHash: Maybe<Scalars["Hex"]>;
  scoreTime: Maybe<Scalars["Timestamp"]>;
};

/** The Discovery Model */
export type DiscoveriesQuery = {
  _typename?: "Query";
  getDiscoveries: Array<{
    __typename?: "Discovery";
    adventurerId: Maybe<Scalars["Int"]>;
    discoveryType: Maybe<Scalars["String"]>;
    subDiscoveryType: Maybe<Scalars["String"]>;
    outputAmount: Maybe<Scalars["Int"]>;
    obstacle: Maybe<Scalars["String"]>;
    obstacleLevel: Maybe<Scalars["Int"]>;
    dodgedObstacle: Maybe<Scalars["Boolean"]>;
    damageTaken: Maybe<Scalars["Int"]>;
    damageLocation: Maybe<Scalars["String"]>;
    xpEarnedAdventurer: Maybe<Scalars["Int"]>;
    xpEarnedItems: Maybe<Scalars["Int"]>;
    entity: Maybe<Scalars["String"]>;
    entityLevel: Maybe<Scalars["Int"]>;
    entityHealth: Maybe<Scalars["Int"]>;
    special2: Maybe<Scalars["String"]>;
    special3: Maybe<Scalars["String"]>;
    ambushed: Maybe<Scalars["Boolean"]>;
    discoveryTime: Maybe<Scalars["Timestamp"]>;
    txHash: Maybe<Scalars["Hex"]>;
  }>;
};

/** The Battle Model */
export type BattleQuery = {
  __typename?: "Battle";
  adventurerId: Maybe<Scalars["Int"]>;
  beast: Maybe<Scalars["String"]>;
  beastHealth: Maybe<Scalars["Int"]>;
  beastLevel: Maybe<Scalars["Int"]>;
  special2: Maybe<Scalars["String"]>;
  special3: Maybe<Scalars["String"]>;
  attacker: Maybe<Scalars["String"]>;
  fled: Maybe<Scalars["Boolean"]>;
  damageDealt: Maybe<Scalars["Int"]>;
  damageTaken: Maybe<Scalars["Int"]>;
  damageLocation: Maybe<Scalars["String"]>;
  xpEarnedAdventurer: Maybe<Scalars["Int"]>;
  xpEarnedItems: Maybe<Scalars["Int"]>;
  goldEarned: Maybe<Scalars["Int"]>;
  txHash: Maybe<Scalars["Hex"]>;
  timestamp: Maybe<Scalars["Timestamp"]>;
};

/** The Item Model */
export type ItemQuery = {
  __typename?: "Item";
  item: Maybe<Scalars["String"]>;
  cost: Maybe<Scalars["Int"]>;
  owner: Maybe<Scalars["Hex"]>;
  ownerAdventurerId: Maybe<Scalars["Int"]>;
  equippedAdventurerId: Maybe<Scalars["Int"]>;
  purchasedTime: Maybe<Scalars["Timestamp"]>;
  special1: Maybe<Scalars["String"]>;
  special2: Maybe<Scalars["String"]>;
  special3: Maybe<Scalars["String"]>;
  xp: Maybe<Scalars["Int"]>;
  lastUpdatedTime: Maybe<Scalars["Timestamp"]>;
};
