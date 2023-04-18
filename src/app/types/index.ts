import { AdventurerProps } from "../context/AdventurerProvider";

export interface Adventurer {

    // static stats
    id: number;
    owner: string;
    race: string;
    name: string;
    order: string;
    imageHash1: string;
    imageHash2: string;

    // evolving stats
    health: number;
    level: number;

    // Physical
    strength: number;
    dexterity: number;
    vitality: number;

    // Mental
    intelligence: number;
    wisdom: number;
    charisma: number;

    // Meta Physical
    luck: number;

    // XP
    xp: number;

    // store item NFT id when equipped
    // Packed Stats p2
    weaponId: number;
    chestId: number;
    headId: number;
    waistId: number;

    // Packed Stats p3
    feetId: number;
    handsId: number;
    neckId: number;
    ringId: number;

    status: string;
    beast: number;
    upgrading: boolean;
    gold: number;
}

export interface Item {
    id?: number; // item id 1 - 100
    slot?: number; // weapon, head, chest, etc
    type?: number; // weapon.blade, armor.metal, jewelry.ring
    material?: number; // the material of the item
    rank?: number; // 1 is best (Divine Robe = 1, Silk Robe = 2, Linen Robe = 3, Robe = 4, Shirt = 5)
    prefix_1?: number; // First part of the name prefix (i.e Demon)
    prefix_2?: number; // Second part of the name prefix (i.e Grasp)
    suffix?: number; // Stored value if item has a Suffix (i.e of Power)
    greatness?: number; // Item greatness
    createdBlock?: number; // Timestamp of when item was created
    xp?: number; // Experience of the item
    adventurerId?: number; // Adventurer ID IF equipped
    bag?: number; // Bag ID IF bagged
    claimedTime?: Date;
    bidder?: number;
    expiry?: Date;
    status?: string;
    price?: number;
    owner?: string;
    marketId?: number;
} 

export interface MarketItem {
    id?: number; // item id 1 - 100
    slot?: number; // weapon, head, chest, etc
    type?: number; // weapon.blade, armor.metal, jewelry.ring
    material?: number; // the material of the item
    rank?: number; // 1 is best (Divine Robe = 1, Silk Robe = 2, Linen Robe = 3, Robe = 4, Shirt = 5)
    prefix_1?: number; // First part of the name prefix (i.e Demon)
    prefix_2?: number; // Second part of the name prefix (i.e Grasp)
    suffix?: number; // Stored value if item has a Suffix (i.e of Power)
    greatness?: number; // Item greatness
    createdBlock?: number; // Timestamp of when item was created
    xp?: number; // Experience of the item
    adventurerId?: number; // Adventurer ID IF equipped
    bag?: number; // Bag ID IF bagged
    claimedTime?: Date;
    bidder?: number;
    expiry?: Date;
    status?: string;
    price?: number;
    owner?: string;
    marketId?: number;
} 


export interface Beast {
    adventurerId: number;
    armorType: string;
    attackType: string;
    beast: string;
    health: number;
    id: number;
    level: number;
    prefix1: string;
    prefix2: string;
    rank: number;
    slainOnDate: Date;
    xp: number;
}

export interface Discoveries {
    adventurerId: number;
    discoveryTime: Date;
    discoveryType: string;
    entityId: number;
    outputAmount: number;
    subDiscoveryType: string;
}

export const NullAdventurer: Adventurer = {
    id: 0,
    owner: "",
    race: "",
    name: "",
    order: "",
    imageHash1: "",
    imageHash2: "",
    health: 0,
    level: 0,
    strength: 0,
    dexterity: 0,
    vitality: 0,
    intelligence: 0,
    wisdom: 0,
    charisma: 0,
    luck: 0,
    xp: 0,
    weaponId: 0,
    chestId: 0,
    headId: 0,
    waistId: 0,
    feetId: 0,
    handsId: 0,
    neckId: 0,
    ringId: 0,
    status: "",
    beast: 0,
    upgrading: false,
    gold: 0    
}

export const NullAdventurerProps: AdventurerProps = {
    adventurer: NullAdventurer,
    image: "",

}

export const NullBeast = {
    adventurerId: 0,
    armorType: "",
    attackType: "",
    beast: "",
    health: 0,
    id: 0,
    level: 0,
    prefix1: "",
    prefix2: "",
    rank: 0,
    slainOnDate: 0,
    xp: 0
}

export const NullDiscovery = {
    adventurerId: 0,
    discoveryTime: 0,
    discoveryType: "",
    entityId: 0,
    outputAmount: 0,
    subDiscoveryType: ""
}

export const NullItem = {
    id: 0, // item id 1 - 100
    slot: 0, // weapon, head, chest, etc
    type: 0, // weapon.blade, armor.metal, jewelry.ring
    material: 0, // the material of the item
    rank: 0, // 1 is best (Divine Robe = 1, Silk Robe = 2, Linen Robe = 3, Robe = 4, Shirt = 5)
    prefix_1: 0, // First part of the name prefix (i.e Demon)
    prefix_2: 0, // Second part of the name prefix (i.e Grasp)
    suffix: 0, // Stored value if item has a Suffix (i.e of Power)
    greatness: 0, // Item greatness
    createdBlock: 0, // Timestamp of when item was created
    xp: 0, // Experience of the item
    adventurerId: 0, // Adventurer ID IF equipped
    bag: 0, // Bag ID IF bagged
    claimedTime: 0,
    bidder: 0,
    expiry: 0,
    status: "",
    price: 0,
    owner: "",
    marketId: 0
}