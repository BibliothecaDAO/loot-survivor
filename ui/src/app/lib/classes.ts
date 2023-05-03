import { Adventurer } from "../types";

export class AdventurerClass implements Adventurer {
    id: number;
    owner: string;
    race: string;
    name: string;
    order: string;
    imageHash1: string;
    imageHash2: string;
    health: number;
    level: number;
    strength: number;
    dexterity: number;
    vitality: number;
    intelligence: number;
    wisdom: number;
    charisma: number;
    luck: number;
    xp: number;
    weaponId: number;
    chestId: number;
    headId: number;
    waistId: number;
    feetId: number;
    handsId: number;
    neckId: number;
    ringId: number;
    status: string;
    beastId: number;
    upgrading: boolean;
    gold: number;
    constructor(adventurer: Adventurer) {
        const {
            id,
            owner,
            race,
            name,
            order,
            imageHash1,
            imageHash2,
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
            weaponId,
            chestId,
            headId,
            waistId,
            feetId,
            handsId,
            neckId,
            ringId,
            status,
            beastId,
            upgrading,
            gold,
        } = adventurer;

        this.id = id;
        this.owner = owner;
        this.race = race;
        this.name = name;
        this.order = order;
        this.imageHash1 = imageHash1;
        this.imageHash2 = imageHash2;
        this.health = health;
        this.level = level;
        this.strength = strength;
        this.dexterity = dexterity;
        this.vitality = vitality;
        this.intelligence = intelligence;
        this.wisdom = wisdom;
        this.charisma = charisma;
        this.luck = luck;
        this.xp = xp;
        this.weaponId = weaponId;
        this.chestId = chestId;
        this.headId = headId;
        this.waistId = waistId;
        this.feetId = feetId;
        this.handsId = handsId;
        this.neckId = neckId;
        this.ringId = ringId;
        this.status = status;
        this.beastId = beastId;
        this.upgrading = upgrading;
        this.gold = gold;
    }
}