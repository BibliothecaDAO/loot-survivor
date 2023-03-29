interface Adventurer {
    // evolving stats
    Health: number;
    Level: number;

    // Physical
    Strength: number;
    Dexterity: number;
    Vitality: number;

    // Mental
    Intelligence: number;
    Wisdom: number;
    Charisma: number;

    // Meta Physical
    Luck: number;

    // XP
    XP: number;

    // store item NFT id when equipped
    // Packed Stats p2
    WeaponId: number;
    ChestId: number;
    HeadId: number;
    WaistId: number;

    // Packed Stats p3
    FeetId: number;
    HandsId: number;
    NeckId: number;
    RingId: number;

    Status: number;
    Beast: number;
    Upgrading: number;
}

interface Item {
    Id: number; // item id 1 - 100
    Slot: number; // weapon, head, chest, etc
    Type: number; // weapon.blade, armor.metal, jewelry.ring
    Material: number; // the material of the item
    Rank: number; // 1 is best (Divine Robe = 1, Silk Robe = 2, Linen Robe = 3, Robe = 4, Shirt = 5)
    Prefix_1: number; // First part of the name prefix (i.e Demon)
    Prefix_2: number; // Second part of the name prefix (i.e Grasp)
    Suffix: number; // Stored value if item has a Suffix (i.e of Power)
    Greatness: number; // Item greatness
    CreatedBlock: number; // Timestamp of when item was created
    XP: number; // Experience of the item
    Adventurer: number; // Adventurer ID IF equipped
    Bag: number; // Bag ID IF bagged
}

interface Bid {
    price: number;
    expiry: number;
    bidder: number;
    status: number;
    item_id: number;
}

