import asyncio
from datetime import datetime
from typing import List, NewType, Optional, Dict
import socket

import strawberry
import aiohttp_cors
from aiohttp import web
from pymongo import MongoClient
from strawberry.aiohttp.views import GraphQLView
from indexer.indexer import LootSurvivorIndexer
from indexer.utils import felt_to_str, str_to_felt, get_key_by_value
from indexer.config import Config

config = Config()


def parse_hex(value):
    if not value.startswith("0x"):
        raise ValueError("invalid Hex value")
    return bytes.fromhex(value.replace("0x", ""))


def serialize_hex(value):
    return "0x" + value.hex()


def parse_felt(value):
    return value.to_bytes(32, "big")


def serialize_felt(value):
    return int.from_bytes(value, "big")


def parse_string(value):
    felt = str_to_felt(value)
    return felt.to_bytes(32, "big")


def serialize_string(value):
    felt = int.from_bytes(value, "big")
    return felt_to_str(felt).replace("\u0000", "")


def parse_order(value):
    felt = get_key_by_value(value, config.ORDERS)
    return felt.to_bytes(32, "big")


def serialize_order(value):
    felt = int.from_bytes(value, "big")
    return config.ORDERS.get(felt)


def parse_race(value):
    felt = get_key_by_value(value, config.RACES)
    return felt.to_bytes(32, "big")


def serialize_race(value):
    felt = int.from_bytes(value, "big")
    return config.RACES.get(felt)


def parse_beast(value):
    felt = get_key_by_value(value, config.BEASTS)
    return felt.to_bytes(32, "big")


def serialize_beast(value):
    felt = int.from_bytes(value, "big")
    return config.BEASTS.get(felt)


def parse_discovery(value):
    felt = get_key_by_value(value, config.DISCOVERY_TYPES)
    return felt.to_bytes(32, "big")


def serialize_discovery(value):
    felt = int.from_bytes(value, "big")
    return config.DISCOVERY_TYPES.get(felt)


def parse_sub_discovery(value):
    felt = get_key_by_value(value, config.ITEM_DISCOVERY_TYPES)
    return felt.to_bytes(32, "big")


def serialize_sub_discovery(value):
    felt = int.from_bytes(value, "big")
    return config.ITEM_DISCOVERY_TYPES.get(felt)


def parse_obstacle(value):
    felt = get_key_by_value(value, config.OBSTACLES)
    return felt.to_bytes(32, "big")


def serialize_obstacle(value):
    felt = int.from_bytes(value, "big")
    return config.OBSTACLES.get(felt)


def parse_attacker(value):
    felt = get_key_by_value(value, config.ATTACKERS)
    return felt.to_bytes(32, "big")


def serialize_attacker(value):
    felt = int.from_bytes(value, "big")
    return config.ATTACKERS.get(felt)


def parse_item(value):
    felt = get_key_by_value(value, config.ITEMS)
    return felt.to_bytes(32, "big")


def serialize_item(value):
    felt = int.from_bytes(value, "big")
    return config.ITEMS.get(felt)


def parse_material(value):
    felt = get_key_by_value(value, config.MATERIALS)
    return felt.to_bytes(32, "big")


def serialize_material(value):
    felt = int.from_bytes(value, "big")
    return config.MATERIALS.get(felt)


def parse_item_type(value):
    felt = get_key_by_value(value, config.ITEM_TYPES)
    return felt.to_bytes(32, "big")


def serialize_item_type(value):
    felt = int.from_bytes(value, "big")
    return config.ITEM_TYPES.get(felt)


def parse_name_prefixes(value):
    felt = get_key_by_value(value, config.ITEM_NAME_PREFIXES)
    return felt.to_bytes(32, "big")


def serialize_name_prefixes(value):
    felt = int.from_bytes(value, "big")
    if felt == 0:
        return None
    else:
        return config.ITEM_NAME_PREFIXES.get(felt)


def parse_name_suffixes(value):
    felt = get_key_by_value(value, config.ITEM_NAME_SUFFIXES)
    return felt.to_bytes(32, "big")


def serialize_name_suffixes(value):
    felt = int.from_bytes(value, "big")
    return config.ITEM_NAME_SUFFIXES.get(felt)


def parse_suffixes(value):
    felt = get_key_by_value(value, config.ITEM_SUFFIXES)
    return felt.to_bytes(32, "big")


def serialize_suffixes(value):
    felt = int.from_bytes(value, "big")
    return config.ITEM_SUFFIXES.get(felt)


def parse_status(value):
    felt = get_key_by_value(value, config.STATUS)
    return felt.to_bytes(32, "big")


def serialize_status(value):
    felt = int.from_bytes(value, "big")
    return config.STATUS.get(felt)


def parse_slot(value):
    felt = get_key_by_value(value, config.SLOTS)
    return felt.to_bytes(32, "big")


def serialize_slot(value):
    felt = int.from_bytes(value, "big")
    return config.SLOTS.get(felt)


def parse_adventurer(value):
    felt = get_key_by_value(value, config.ATTACKERS)
    return felt.to_bytes(32, "big")


def serialize_adventurer(value):
    felt = int.from_bytes(value, "big")
    return config.ATTACKERS.get(felt)


HexValue = strawberry.scalar(
    NewType("HexValue", bytes), parse_value=parse_hex, serialize=serialize_hex
)

FeltValue = strawberry.scalar(
    NewType("FeltValue", bytes), parse_value=parse_felt, serialize=serialize_felt
)

StringValue = strawberry.scalar(
    NewType("StringValue", bytes), parse_value=parse_string, serialize=serialize_string
)

BooleanValue = strawberry.scalar(
    NewType("BooleanValue", bytes), parse_value=parse_felt, serialize=serialize_felt
)

OrderValue = strawberry.scalar(
    NewType("OrderValue", bytes), parse_value=parse_order, serialize=serialize_order
)

RaceValue = strawberry.scalar(
    NewType("RaceValue", bytes), parse_value=parse_race, serialize=serialize_race
)

BeastValue = strawberry.scalar(
    NewType("BeastValue", bytes), parse_value=parse_beast, serialize=serialize_beast
)

DiscoveryValue = strawberry.scalar(
    NewType("DiscoveryValue", bytes),
    parse_value=parse_discovery,
    serialize=serialize_discovery,
)

SubDiscoveryValue = strawberry.scalar(
    NewType("SubDiscoveryValue", bytes),
    parse_value=parse_sub_discovery,
    serialize=serialize_sub_discovery,
)

ObstacleValue = strawberry.scalar(
    NewType("ObstacleValue", bytes),
    parse_value=parse_obstacle,
    serialize=serialize_obstacle,
)

AttackerValue = strawberry.scalar(
    NewType("AttackerValue", bytes),
    parse_value=parse_attacker,
    serialize=serialize_attacker,
)

ItemValue = strawberry.scalar(
    NewType("ItemValue", bytes),
    parse_value=parse_item,
    serialize=serialize_item,
)

MaterialValue = strawberry.scalar(
    NewType("MaterialValue", bytes),
    parse_value=parse_material,
    serialize=serialize_material,
)

TypeValue = strawberry.scalar(
    NewType("TypeValue", bytes),
    parse_value=parse_item_type,
    serialize=serialize_item_type,
)

NamePrefixValue = strawberry.scalar(
    NewType("NamePrefixValue", bytes),
    parse_value=parse_name_prefixes,
    serialize=serialize_name_prefixes,
)

NameSuffixValue = strawberry.scalar(
    NewType("NameSuffixValue", bytes),
    parse_value=parse_name_suffixes,
    serialize=serialize_name_suffixes,
)

SuffixValue = strawberry.scalar(
    NewType("SuffixValue", bytes),
    parse_value=parse_suffixes,
    serialize=serialize_suffixes,
)

StatusValue = strawberry.scalar(
    NewType("StatusValue", bytes),
    parse_value=parse_status,
    serialize=serialize_status,
)

SlotValue = strawberry.scalar(
    NewType("SlotValue", bytes),
    parse_value=parse_slot,
    serialize=serialize_slot,
)

AttackerValue = strawberry.scalar(
    NewType("AttackerValue", bytes),
    parse_value=parse_adventurer,
    serialize=serialize_adventurer,
)


@strawberry.input
class StringFilter:
    eq: Optional[StringValue] = None
    _in: Optional[List[StringValue]] = None
    notIn: Optional[StringValue] = None
    lt: Optional[StringValue] = None
    lte: Optional[StringValue] = None
    gt: Optional[StringValue] = None
    gte: Optional[StringValue] = None
    contains: Optional[StringValue] = None
    startsWith: Optional[StringValue] = None
    endsWith: Optional[StringValue] = None


@strawberry.input
class HexValueFilter:
    eq: Optional[HexValue] = None
    _in: Optional[List[HexValue]] = None
    notIn: Optional[List[HexValue]] = None
    lt: Optional[HexValue] = None
    lte: Optional[HexValue] = None
    gt: Optional[HexValue] = None
    gte: Optional[HexValue] = None


@strawberry.input
class FeltValueFilter:
    eq: Optional[FeltValue] = None
    _in: Optional[List[FeltValue]] = None
    notIn: Optional[List[FeltValue]] = None
    lt: Optional[FeltValue] = None
    lte: Optional[FeltValue] = None
    gt: Optional[FeltValue] = None
    gte: Optional[FeltValue] = None


@strawberry.input
class DateTimeFilter:
    eq: Optional[datetime] = None
    _in: Optional[List[datetime]] = None
    notIn: Optional[List[datetime]] = None
    lt: Optional[datetime] = None
    lte: Optional[datetime] = None
    gt: Optional[datetime] = None
    gte: Optional[datetime] = None


@strawberry.input
class BooleanFilter:
    eq: Optional[bool] = None


@strawberry.input
class OrderFilter:
    eq: Optional[OrderValue] = None
    _in: Optional[List[OrderValue]] = None
    notIn: Optional[OrderValue] = None
    lt: Optional[OrderValue] = None
    lte: Optional[OrderValue] = None
    gt: Optional[OrderValue] = None
    gte: Optional[OrderValue] = None
    contains: Optional[OrderValue] = None
    startsWith: Optional[OrderValue] = None
    endsWith: Optional[OrderValue] = None


@strawberry.input
class RaceFilter:
    eq: Optional[RaceValue] = None
    _in: Optional[List[RaceValue]] = None
    notIn: Optional[RaceValue] = None
    lt: Optional[RaceValue] = None
    lte: Optional[RaceValue] = None
    gt: Optional[RaceValue] = None
    gte: Optional[RaceValue] = None
    contains: Optional[RaceValue] = None
    startsWith: Optional[RaceValue] = None
    endsWith: Optional[RaceValue] = None


@strawberry.input
class BeastFilter:
    eq: Optional[BeastValue] = None
    _in: Optional[List[BeastValue]] = None
    notIn: Optional[BeastValue] = None
    lt: Optional[BeastValue] = None
    lte: Optional[BeastValue] = None
    gt: Optional[BeastValue] = None
    gte: Optional[BeastValue] = None
    contains: Optional[BeastValue] = None
    startsWith: Optional[BeastValue] = None
    endsWith: Optional[BeastValue] = None


@strawberry.input
class DiscoveryFilter:
    eq: Optional[DiscoveryValue] = None
    _in: Optional[List[DiscoveryValue]] = None
    notIn: Optional[DiscoveryValue] = None
    lt: Optional[DiscoveryValue] = None
    lte: Optional[DiscoveryValue] = None
    gt: Optional[DiscoveryValue] = None
    gte: Optional[DiscoveryValue] = None
    contains: Optional[DiscoveryValue] = None
    startsWith: Optional[DiscoveryValue] = None
    endsWith: Optional[DiscoveryValue] = None


@strawberry.input
class SubDiscoveryFilter:
    eq: Optional[SubDiscoveryValue] = None
    _in: Optional[List[SubDiscoveryValue]] = None
    notIn: Optional[SubDiscoveryValue] = None
    lt: Optional[SubDiscoveryValue] = None
    lte: Optional[SubDiscoveryValue] = None
    gt: Optional[SubDiscoveryValue] = None
    gte: Optional[SubDiscoveryValue] = None
    contains: Optional[SubDiscoveryValue] = None
    startsWith: Optional[SubDiscoveryValue] = None
    endsWith: Optional[SubDiscoveryValue] = None


@strawberry.input
class ObstacleFilter:
    eq: Optional[ObstacleValue] = None
    _in: Optional[List[ObstacleValue]] = None
    notIn: Optional[ObstacleValue] = None
    lt: Optional[ObstacleValue] = None
    lte: Optional[ObstacleValue] = None
    gt: Optional[ObstacleValue] = None
    gte: Optional[ObstacleValue] = None
    contains: Optional[ObstacleValue] = None
    startsWith: Optional[ObstacleValue] = None
    endsWith: Optional[ObstacleValue] = None


@strawberry.input
class AttackerFilter:
    eq: Optional[AttackerValue] = None


@strawberry.input
class ItemFilter:
    eq: Optional[ItemValue] = None
    _in: Optional[List[ItemValue]] = None
    notIn: Optional[ItemValue] = None
    lt: Optional[ItemValue] = None
    lte: Optional[ItemValue] = None
    gt: Optional[ItemValue] = None
    gte: Optional[ItemValue] = None
    contains: Optional[ItemValue] = None
    startsWith: Optional[ItemValue] = None
    endsWith: Optional[ItemValue] = None


@strawberry.input
class MaterialFilter:
    eq: Optional[MaterialValue] = None
    _in: Optional[List[MaterialValue]] = None
    notIn: Optional[MaterialValue] = None
    lt: Optional[MaterialValue] = None
    lte: Optional[MaterialValue] = None
    gt: Optional[MaterialValue] = None
    gte: Optional[MaterialValue] = None
    contains: Optional[MaterialValue] = None
    startsWith: Optional[MaterialValue] = None
    endsWith: Optional[MaterialValue] = None


@strawberry.input
class TypeFilter:
    eq: Optional[TypeValue] = None
    _in: Optional[List[TypeValue]] = None
    notIn: Optional[TypeValue] = None
    lt: Optional[TypeValue] = None
    lte: Optional[TypeValue] = None
    gt: Optional[TypeValue] = None
    gte: Optional[TypeValue] = None
    contains: Optional[TypeValue] = None
    startsWith: Optional[TypeValue] = None
    endsWith: Optional[TypeValue] = None


@strawberry.input
class NamePrefixFilter:
    eq: Optional[NamePrefixValue] = None
    _in: Optional[List[NamePrefixValue]] = None
    notIn: Optional[NamePrefixValue] = None
    lt: Optional[NamePrefixValue] = None
    lte: Optional[NamePrefixValue] = None
    gt: Optional[NamePrefixValue] = None
    gte: Optional[NamePrefixValue] = None
    contains: Optional[NamePrefixValue] = None
    startsWith: Optional[NamePrefixValue] = None
    endsWith: Optional[NamePrefixValue] = None


@strawberry.input
class NameSuffixFilter:
    eq: Optional[NameSuffixValue] = None
    _in: Optional[List[NameSuffixValue]] = None
    notIn: Optional[NameSuffixValue] = None
    lt: Optional[NameSuffixValue] = None
    lte: Optional[NameSuffixValue] = None
    gt: Optional[NameSuffixValue] = None
    gte: Optional[NameSuffixValue] = None
    contains: Optional[NameSuffixValue] = None
    startsWith: Optional[NameSuffixValue] = None
    endsWith: Optional[NameSuffixValue] = None


@strawberry.input
class SuffixFilter:
    eq: Optional[SuffixValue] = None
    _in: Optional[List[SuffixValue]] = None
    notIn: Optional[SuffixValue] = None
    lt: Optional[SuffixValue] = None
    lte: Optional[SuffixValue] = None
    gt: Optional[SuffixValue] = None
    gte: Optional[SuffixValue] = None
    contains: Optional[SuffixValue] = None
    startsWith: Optional[SuffixValue] = None
    endsWith: Optional[SuffixValue] = None


@strawberry.input
class StatusFilter:
    eq: Optional[StatusValue] = None
    _in: Optional[List[StatusValue]] = None
    notIn: Optional[StatusValue] = None
    lt: Optional[StatusValue] = None
    lte: Optional[StatusValue] = None
    gt: Optional[StatusValue] = None
    gte: Optional[StatusValue] = None
    contains: Optional[StatusValue] = None
    startsWith: Optional[StatusValue] = None
    endsWith: Optional[StatusValue] = None


@strawberry.input
class SlotFilter:
    eq: Optional[SlotValue] = None
    _in: Optional[List[SlotValue]] = None
    notIn: Optional[SlotValue] = None
    lt: Optional[SlotValue] = None
    lte: Optional[SlotValue] = None
    gt: Optional[SlotValue] = None
    gte: Optional[SlotValue] = None
    contains: Optional[SlotValue] = None
    startsWith: Optional[SlotValue] = None
    endsWith: Optional[SlotValue] = None


@strawberry.input
class OrderByInput:
    asc: Optional[bool] = False
    desc: Optional[bool] = False


@strawberry.input
class AdventurersFilter:
    id: Optional[FeltValueFilter] = None
    owner: Optional[HexValueFilter] = None
    race: Optional[RaceFilter] = None
    homeRealm: Optional[FeltValueFilter] = None
    birthdate: Optional[DateTimeFilter] = None
    name: Optional[StringFilter] = None
    order: Optional[OrderFilter] = None
    imageHash1: Optional[StringFilter] = None
    imageHash2: Optional[StringFilter] = None
    health: Optional[FeltValueFilter] = None
    level: Optional[FeltValueFilter] = None
    strength: Optional[FeltValueFilter] = None
    dexterity: Optional[FeltValueFilter] = None
    vitality: Optional[FeltValueFilter] = None
    intelligence: Optional[FeltValueFilter] = None
    wisdom: Optional[FeltValueFilter] = None
    charisma: Optional[FeltValueFilter] = None
    luck: Optional[FeltValueFilter] = None
    xp: Optional[FeltValueFilter] = None
    weaponId: Optional[FeltValueFilter] = None
    chestId: Optional[FeltValueFilter] = None
    headId: Optional[FeltValueFilter] = None
    waistId: Optional[FeltValueFilter] = None
    feetId: Optional[FeltValueFilter] = None
    handsId: Optional[FeltValueFilter] = None
    neckId: Optional[FeltValueFilter] = None
    ringId: Optional[FeltValueFilter] = None
    status: Optional[StringFilter] = None
    beast: Optional[FeltValueFilter] = None
    upgrading: Optional[BooleanFilter] = None
    gold: Optional[FeltValueFilter] = None
    lastUpdated: Optional[DateTimeFilter] = None


@strawberry.input
class DiscoveriesFilter:
    adventurerId: Optional[FeltValueFilter] = None
    disoveryType: Optional[StringFilter] = None
    subDiscoveryType: Optional[StringFilter] = None
    entityId: Optional[FeltValueFilter] = None
    outputAmount: Optional[FeltValueFilter] = None
    discoveryTime: Optional[DateTimeFilter] = None
    txHash: Optional[HexValueFilter] = None


@strawberry.input
class BeastsFilter:
    id: Optional[FeltValueFilter] = None
    adventurerId: Optional[FeltValueFilter] = None
    beast: Optional[BeastFilter] = None
    attackType: Optional[TypeFilter] = None
    armorType: Optional[TypeFilter] = None
    rank: Optional[FeltValueFilter] = None
    prefix1: Optional[NamePrefixFilter] = None
    prefix2: Optional[NameSuffixFilter] = None
    health: Optional[FeltValueFilter] = None
    xp: Optional[FeltValueFilter] = None
    level: Optional[FeltValueFilter] = None
    slainOnDate: Optional[DateTimeFilter] = None
    birthdate: Optional[DateTimeFilter] = None
    lastUpdated: Optional[DateTimeFilter] = None


@strawberry.input
class BattlesFilter:
    adventurerId: Optional[FeltValueFilter] = None
    beastId: Optional[FeltValueFilter] = None
    timestamp: Optional[DateTimeFilter] = None
    attacker: Optional[AttackerFilter] = None
    fled: Optional[BooleanFilter] = None
    ambushed: Optional[BooleanFilter] = None
    damage: Optional[FeltValueFilter] = None
    targetHealth: Optional[FeltValueFilter] = None
    xpEarned: Optional[FeltValueFilter] = None
    goldEarned: Optional[FeltValueFilter] = None
    txhash: Optional[HexValueFilter] = None


@strawberry.input
class ItemsFilter:
    id: Optional[FeltValueFilter] = None
    marketId: Optional[FeltValueFilter] = None
    owner: Optional[HexValueFilter] = None
    ownerAdventurerId: Optional[FeltValueFilter] = None
    claimedTime: Optional[DateTimeFilter] = None
    item: Optional[ItemFilter] = None
    slot: Optional[StringFilter] = None
    type: Optional[StringFilter] = None
    material: Optional[MaterialFilter] = None
    rank: Optional[FeltValueFilter] = None
    prefix1: Optional[NamePrefixFilter] = None
    prefix2: Optional[NameSuffixFilter] = None
    suffix: Optional[SuffixFilter] = None
    greatness: Optional[FeltValueFilter] = None
    createdBlock: Optional[FeltValueFilter] = None
    xp: Optional[FeltValueFilter] = None
    equippedAdventurerId: Optional[FeltValueFilter] = None
    bag: Optional[FeltValueFilter] = None
    price: Optional[FeltValueFilter] = None
    expiry: Optional[DateTimeFilter] = None
    bidder: Optional[FeltValueFilter] = None
    status: Optional[StatusFilter] = None
    lastUpdated: Optional[DateTimeFilter] = None


@strawberry.input
class MarketFilter:
    caller: Optional[HexValueFilter] = None
    itemsNumber: Optional[FeltValueFilter] = None
    timestamp: Optional[DateTimeFilter] = None


@strawberry.input
class AdventurersOrderByInput:
    id: Optional[OrderByInput] = None
    owner: Optional[OrderByInput] = None
    race: Optional[OrderByInput] = None
    homeRealm: Optional[OrderByInput] = None
    birthdate: Optional[OrderByInput] = None
    name: Optional[OrderByInput] = None
    order: Optional[OrderByInput] = None
    imageHash1: Optional[OrderByInput] = None
    imageHash2: Optional[OrderByInput] = None
    health: Optional[OrderByInput] = None
    level: Optional[OrderByInput] = None
    strength: Optional[OrderByInput] = None
    dexterity: Optional[OrderByInput] = None
    vitality: Optional[OrderByInput] = None
    intelligence: Optional[OrderByInput] = None
    wisdom: Optional[OrderByInput] = None
    charisma: Optional[OrderByInput] = None
    luck: Optional[OrderByInput] = None
    xp: Optional[OrderByInput] = None
    weaponId: Optional[OrderByInput] = None
    chestId: Optional[OrderByInput] = None
    headId: Optional[OrderByInput] = None
    waistId: Optional[OrderByInput] = None
    feetId: Optional[OrderByInput] = None
    handsId: Optional[OrderByInput] = None
    neckId: Optional[OrderByInput] = None
    ringId: Optional[OrderByInput] = None
    status: Optional[OrderByInput] = None
    beast: Optional[OrderByInput] = None
    upgrading: Optional[OrderByInput] = None
    gold: Optional[OrderByInput] = None
    lastUpdated: Optional[OrderByInput] = None


@strawberry.input
class DiscoveriesOrderByInput:
    adventurerId: Optional[OrderByInput] = None
    disoveryType: Optional[OrderByInput] = None
    subDiscoveryType: Optional[OrderByInput] = None
    entityId: Optional[OrderByInput] = None
    outputAmount: Optional[OrderByInput] = None
    discoveryTime: Optional[OrderByInput] = None
    txHash: Optional[OrderByInput] = None


@strawberry.input
class BeastsOrderByInput:
    id: Optional[OrderByInput] = None
    adventurerId: Optional[OrderByInput] = None
    beastType: Optional[OrderByInput] = None
    attackType: Optional[OrderByInput] = None
    armorType: Optional[OrderByInput] = None
    rank: Optional[OrderByInput] = None
    prefixes: Optional[OrderByInput] = None
    health: Optional[OrderByInput] = None
    xp: Optional[OrderByInput] = None
    level: Optional[OrderByInput] = None
    slainOnDate: Optional[OrderByInput] = None
    lastUpdated: Optional[OrderByInput] = None


@strawberry.input
class BattlesOrderByInput:
    adventurerId: Optional[OrderByInput] = None
    beastId: Optional[OrderByInput] = None
    timestamp: Optional[OrderByInput] = None
    attacker: Optional[OrderByInput] = None
    fled: Optional[OrderByInput] = None
    ambushed: Optional[OrderByInput] = None
    damage: Optional[OrderByInput] = None
    targetHealth: Optional[OrderByInput] = None
    xpEarned: Optional[OrderByInput] = None
    goldEarned: Optional[OrderByInput] = None
    txhash: Optional[OrderByInput] = None


@strawberry.input
class ItemsOrderByInput:
    id: Optional[OrderByInput] = None
    marketId: Optional[OrderByInput] = None
    owner: Optional[OrderByInput] = None
    ownerAdventurerId: Optional[OrderByInput] = None
    claimedTime: Optional[datetime] = None
    item: Optional[OrderByInput] = None
    slot: Optional[OrderByInput] = None
    type: Optional[OrderByInput] = None
    material: Optional[OrderByInput] = None
    rank: Optional[OrderByInput] = None
    prefix1: Optional[OrderByInput] = None
    prefix2: Optional[OrderByInput] = None
    suffix: Optional[OrderByInput] = None
    greatness: Optional[OrderByInput] = None
    createdBlock: Optional[OrderByInput] = None
    xp: Optional[OrderByInput] = None
    equippedAdventurerId: Optional[OrderByInput] = None
    bag: Optional[OrderByInput] = None
    price: Optional[OrderByInput] = None
    expiry: Optional[OrderByInput] = None
    bidder: Optional[OrderByInput] = None
    status: Optional[OrderByInput] = None
    lastUpdated: Optional[OrderByInput] = None


@strawberry.input
class MarketOrderByInput:
    caller: Optional[OrderByInput] = None
    itemsNumber: Optional[OrderByInput] = None
    timestamp: Optional[OrderByInput] = None


@strawberry.type
class Adventurer:
    id: Optional[FeltValue]
    owner: Optional[HexValue]
    race: Optional[RaceValue]
    homeRealm: Optional[FeltValue]
    birthdate: Optional[datetime]
    name: Optional[StringValue]
    order: Optional[OrderValue]
    imageHash1: Optional[StringValue]
    imageHash2: Optional[StringValue]
    health: Optional[FeltValue]
    level: Optional[FeltValue]
    strength: Optional[FeltValue]
    dexterity: Optional[FeltValue]
    vitality: Optional[FeltValue]
    intelligence: Optional[FeltValue]
    wisdom: Optional[FeltValue]
    charisma: Optional[FeltValue]
    luck: Optional[FeltValue]
    xp: Optional[FeltValue]
    weaponId: Optional[FeltValue]
    chestId: Optional[FeltValue]
    headId: Optional[FeltValue]
    waistId: Optional[FeltValue]
    feetId: Optional[FeltValue]
    handsId: Optional[FeltValue]
    neckId: Optional[FeltValue]
    ringId: Optional[FeltValue]
    status: Optional[FeltValue]
    beastId: Optional[FeltValue]
    upgrading: Optional[BooleanValue]
    gold: Optional[FeltValue]
    lastUpdated: Optional[datetime]

    @classmethod
    def from_mongo(cls, data):
        return cls(
            id=data["id"],
            owner=data["owner"],
            race=data["race"],
            homeRealm=data["homeRealm"],
            birthdate=data["birthdate"],
            name=data["name"],
            order=data["order"],
            imageHash1=data["imageHash1"],
            imageHash2=data["imageHash2"],
            health=data["health"],
            level=data["level"],
            strength=data["strength"],
            dexterity=data["dexterity"],
            vitality=data["vitality"],
            intelligence=data["intelligence"],
            wisdom=data["wisdom"],
            charisma=data["charisma"],
            luck=data["luck"],
            xp=data["xp"],
            weaponId=data["weaponId"],
            chestId=data["chestId"],
            headId=data["headId"],
            waistId=data["waistId"],
            feetId=data["feetId"],
            handsId=data["handsId"],
            neckId=data["neckId"],
            ringId=data["ringId"],
            status=data["status"],
            beastId=data["beast"],
            upgrading=data["upgrading"],
            gold=data["gold"],
            lastUpdated=data["lastUpdated"],
        )


@strawberry.type
class Discovery:
    adventurerId: Optional[FeltValue]
    discoveryType: Optional[DiscoveryValue]
    subDiscoveryType: Optional[SubDiscoveryValue]
    entityId: Optional[FeltValue]
    outputAmount: Optional[FeltValue]
    discoveryTime: Optional[datetime]
    txHash: Optional[HexValue]

    @classmethod
    def from_mongo(cls, data):
        return cls(
            adventurerId=data["adventurerId"],
            discoveryType=data["discoveryType"],
            subDiscoveryType=data["subDiscoveryType"],
            entityId=data["entityId"],
            outputAmount=data["outputAmount"],
            discoveryTime=data["discoveryTime"],
            txHash=data["txHash"],
        )


@strawberry.type
class Heist:
    thiefId: Optional[FeltValue]
    heist_time: Optional[datetime]
    gold: Optional[FeltValue]


@strawberry.type
class Beast:
    id: Optional[FeltValue]
    adventurerId: Optional[FeltValue]
    beast: Optional[BeastValue]
    attackType: Optional[TypeValue]
    armorType: Optional[TypeValue]
    rank: Optional[FeltValue]
    prefix1: Optional[NamePrefixValue]
    prefix2: Optional[NameSuffixValue]
    health: Optional[FeltValue]
    xp: Optional[FeltValue]
    level: Optional[FeltValue]
    slainOnDate: Optional[datetime]
    lastUpdated: Optional[datetime]

    @classmethod
    def from_mongo(cls, data):
        return cls(
            id=data["id"],
            adventurerId=data["adventurerId"],
            beast=data["beast"],
            attackType=data["attackType"],
            armorType=data["armorType"],
            rank=data["rank"],
            prefix1=data["prefix1"],
            prefix2=data["prefix2"],
            health=data["health"],
            xp=data["xp"],
            level=data["level"],
            slainOnDate=data["slainOnDate"],
            lastUpdated=data["lastUpdated"],
        )


@strawberry.type
class Battle:
    adventurerId: Optional[FeltValue]
    beastId: Optional[FeltValue]
    timestamp: Optional[datetime]
    attacker: Optional[AttackerValue]
    fled: Optional[BooleanValue]
    ambushed: Optional[BooleanValue]
    damage: Optional[FeltValue]
    targetHealth: Optional[FeltValue]
    xpEarned: Optional[FeltValue]
    goldEarned: Optional[FeltValue]
    txHash: Optional[HexValue]

    @classmethod
    def from_mongo(cls, data):
        return cls(
            adventurerId=data["adventurerId"],
            beastId=data["beastId"],
            timestamp=data["timestamp"],
            attacker=data["attacker"],
            fled=data["fled"],
            ambushed=data["ambushed"],
            damage=data["damage"],
            targetHealth=data["targetHealth"],
            xpEarned=data["xpEarned"],
            goldEarned=data["goldEarned"],
            txHash=data["txHash"],
        )


@strawberry.type
class Item:
    id: Optional[FeltValue]
    marketId: Optional[FeltValue]
    owner: Optional[HexValue]
    ownerAdventurerId: Optional[FeltValue]
    claimedTime: Optional[datetime]
    item: Optional[ItemValue]
    slot: Optional[SlotValue]
    type: Optional[TypeValue]
    material: Optional[MaterialValue]
    rank: Optional[FeltValue]
    prefix1: Optional[NamePrefixValue]
    prefix2: Optional[NameSuffixValue]
    suffix: Optional[SuffixValue]
    greatness: Optional[FeltValue]
    createdBlock: Optional[FeltValue]
    xp: Optional[FeltValue]
    equippedAdventurerId: Optional[FeltValue]
    bag: Optional[FeltValue]
    price: Optional[FeltValue]
    expiry: Optional[datetime]
    bidder: Optional[FeltValue]
    status: Optional[StatusValue]
    lastUpdated: Optional[datetime]

    @classmethod
    def from_mongo(cls, data):
        return cls(
            id=data["id"],
            marketId=data["marketId"],
            owner=data["owner"],
            ownerAdventurerId=data["ownerAdventurerId"],
            claimedTime=data["claimedTime"],
            item=data["item"],
            slot=data["slot"],
            type=data["type"],
            material=data["material"],
            rank=data["rank"],
            prefix1=data["prefix1"],
            prefix2=data["prefix2"],
            suffix=data["suffix"],
            greatness=data["greatness"],
            createdBlock=data["createdBlock"],
            xp=data["xp"],
            equippedAdventurerId=data["equippedAdventurerId"],
            bag=data["bag"],
            price=data["price"],
            expiry=data["expiry"],
            bidder=data["bidder"],
            status=data["status"],
            lastUpdated=data["lastUpdated"],
        )


@strawberry.type
class Market:
    caller: Optional[HexValue]
    itemsNumber: Optional[FeltValue]
    timestamp: Optional[datetime]

    @classmethod
    def from_mongo(cls, data):
        return cls(
            caller=data["caller"],
            itemsNumber=data["itemsNumber"],
            timestamp=data["timestamp"],
        )


def get_str_filters(where: StringFilter) -> List[Dict]:
    filter = {}
    if where.eq:
        filter = where.eq
    if where._in:
        filter["$in"] = where._in
    if where.notIn:
        filter["$nin"] = where.notIn
    if where.lt:
        filter["$lt"] = where.lt
    if where.lte:
        filter["$lte"] = where.lte
    if where.gt:
        filter["$gt"] = where.gt
    if where.gte:
        filter["$gte"] = where.gte
    if where.contains:
        filter["$regex"] = where.contains
    if where.startsWith:
        filter["$regex"] = "^" + where.startsWith
    if where.endsWith:
        filter["$regex"] = where.endsWith + "$"

    return filter


def get_felt_filters(where: FeltValueFilter) -> List[Dict]:
    filter = {}
    if where.eq:
        filter = where.eq
    if where._in:
        filter["$in"] = where._in
    if where.notIn:
        filter["$nin"] = where.notIn
    if where.lt:
        filter["$lt"] = where.lt
    if where.lte:
        filter["$lte"] = where.lte
    if where.gt:
        filter["$gt"] = where.gt
    if where.gte:
        filter["$gte"] = where.gte

    return filter


def get_hex_filters(where: HexValueFilter) -> List[Dict]:
    filter = {}
    if where.eq:
        filter = where.eq
    if where._in:
        filter["$in"] = where._in
    if where.notIn:
        filter["$nin"] = where.notIn
    if where.lt:
        filter["$lt"] = where.lt
    if where.lte:
        filter["$lte"] = where.lte
    if where.gt:
        filter["$gt"] = where.gt
    if where.gte:
        filter["$gte"] = where.gte

    return filter


def get_date_filters(where: DateTimeFilter) -> List[Dict]:
    filter = {}
    if where.eq:
        filter = where.eq
    if where._in:
        filter["$in"] = where._in
    if where.notIn:
        filter["$nin"] = where.notIn
    if where.lt:
        filter["$lt"] = where.lt
    if where.lte:
        filter["$lte"] = where.lte
    if where.gt:
        filter["$gt"] = where.gt
    if where.gte:
        filter["$gte"] = where.gte

    return filter


def get_bool_filters(where: BooleanFilter) -> List[Dict]:
    filter = {}
    if where.eq:
        filter = where.eq
    return filter


def process_filters(obj, prefix=None):
    filters = {}
    for key, value in obj.__dict__.items():
        if value is not None:
            filter_key = f"{prefix}.{key}" if prefix else key
            filters[filter_key] = value
    return filters


def get_adventurers(
    info,
    where: Optional[AdventurersFilter] = {},
    limit: Optional[int] = 10,
    skip: Optional[int] = 0,
    orderBy: Optional[AdventurersOrderByInput] = {},
) -> List[Adventurer]:
    db = info.context["db"]

    filter = {"_chain.valid_to": None}

    if where:
        processed_filters = process_filters(where)
        for key, value in processed_filters.items():
            if (
                isinstance(value, StringFilter)
                | isinstance(value, OrderFilter)
                | isinstance(value, RaceFilter)
            ):
                filter[key] = get_str_filters(value)
            elif isinstance(value, HexValueFilter):
                filter[key] = get_hex_filters(value)
            elif isinstance(value, DateTimeFilter):
                filter[key] = get_date_filters(value)
            elif isinstance(value, FeltValueFilter):
                filter[key] = get_felt_filters(value)
            elif isinstance(value, BooleanFilter):
                filter[key] = get_bool_filters(value)

    sort_options = {k: v for k, v in orderBy.__dict__.items() if v is not None}

    sort_var = "updated_at"
    sort_dir = -1

    for key, value in sort_options.items():
        if value.asc:
            sort_var = key
            sort_dir = 1
            break
        if value.desc:
            sort_var = key
            sort_dir = -1
            break

    query = (
        db["adventurers"].find(filter).skip(skip).limit(limit).sort(sort_var, sort_dir)
    )

    return [Adventurer.from_mongo(t) for t in query]


def get_discoveries(
    info,
    where: Optional[DiscoveriesFilter] = {},
    limit: Optional[int] = 10,
    skip: Optional[int] = 0,
    orderBy: Optional[DiscoveriesOrderByInput] = {},
) -> List[Discovery]:
    db = info.context["db"]

    filter = {"_chain.valid_to": None}

    if where:
        processed_filters = process_filters(where)
        for key, value in processed_filters.items():
            if (
                isinstance(value, StringFilter)
                | isinstance(value, DiscoveryFilter)
                | isinstance(value, SubDiscoveryFilter)
            ):
                filter[key] = get_str_filters(value)
            elif isinstance(value, HexValueFilter):
                filter[key] = get_hex_filters(value)
            elif isinstance(value, DateTimeFilter):
                filter[key] = get_date_filters(value)
            elif isinstance(value, FeltValueFilter):
                filter[key] = get_felt_filters(value)

    sort_options = {k: v for k, v in orderBy.__dict__.items() if v is not None}

    sort_var = "updated_at"
    sort_dir = -1

    for key, value in sort_options.items():
        if value.asc:
            sort_var = key
            sort_dir = 1
            break
        if value.desc:
            sort_var = key
            sort_dir = -1
            break

    query = (
        db["discoveries"].find(filter).skip(skip).limit(limit).sort(sort_var, sort_dir)
    )

    return [Discovery.from_mongo(t) for t in query]


def get_beasts(
    info,
    where: Optional[BeastsFilter] = {},
    limit: Optional[int] = 10,
    skip: Optional[int] = 0,
    orderBy: Optional[BeastsOrderByInput] = {},
) -> List[Beast]:
    db = info.context["db"]

    filter = {"_chain.valid_to": None}

    if where:
        processed_filters = process_filters(where)
        for key, value in processed_filters.items():
            if (
                isinstance(value, StringFilter)
                | isinstance(value, BeastFilter)
                | isinstance(value, NamePrefixFilter)
                | isinstance(value, NameSuffixFilter)
            ):
                filter[key] = get_str_filters(value)
            elif isinstance(value, HexValueFilter):
                filter[key] = get_hex_filters(value)
            elif isinstance(value, DateTimeFilter):
                filter[key] = get_date_filters(value)
            elif isinstance(value, FeltValueFilter):
                filter[key] = get_felt_filters(value)

    sort_options = {k: v for k, v in orderBy.__dict__.items() if v is not None}

    sort_var = "updated_at"
    sort_dir = -1

    for key, value in sort_options.items():
        if value.asc:
            sort_var = key
            sort_dir = 1
            break
        if value.desc:
            sort_var = key
            sort_dir = -1
            break

    query = db["beasts"].find(filter).skip(skip).limit(limit).sort(sort_var, sort_dir)

    return [Beast.from_mongo(t) for t in query]


def get_battles(
    info,
    where: Optional[BattlesFilter] = {},
    limit: Optional[int] = 10,
    skip: Optional[int] = 0,
    orderBy: Optional[BattlesOrderByInput] = {},
) -> List[Beast]:
    db = info.context["db"]

    filter = {"_chain.valid_to": None}

    if where:
        processed_filters = process_filters(where)
        for key, value in processed_filters.items():
            if isinstance(value, StringFilter) | isinstance(value, AttackerFilter):
                filter[key] = get_str_filters(value)
            elif isinstance(value, HexValueFilter):
                filter[key] = get_hex_filters(value)
            elif isinstance(value, DateTimeFilter):
                filter[key] = get_date_filters(value)
            elif isinstance(value, FeltValueFilter):
                filter[key] = get_felt_filters(value)
            elif isinstance(value, BooleanFilter):
                filter[key] = get_bool_filters(value)

    sort_options = {k: v for k, v in orderBy.__dict__.items() if v is not None}

    sort_var = "updated_at"
    sort_dir = -1

    for key, value in sort_options.items():
        if value.asc:
            sort_var = key
            sort_dir = 1
            break
        if value.desc:
            sort_var = key
            sort_dir = -1
            break

    query = db["battles"].find(filter).skip(skip).limit(limit).sort(sort_var, sort_dir)

    return [Battle.from_mongo(t) for t in query]


def get_items(
    info,
    where: Optional[ItemsFilter] = {},
    limit: Optional[int] = 10,
    skip: Optional[int] = 0,
    orderBy: Optional[ItemsOrderByInput] = {},
) -> List[Item]:
    db = info.context["db"]

    filter = {"_chain.valid_to": None}

    if where:
        processed_filters = process_filters(where)
        for key, value in processed_filters.items():
            if (
                isinstance(value, StringFilter)
                | isinstance(value, ItemFilter)
                | isinstance(value, SlotFilter)
                | isinstance(value, TypeFilter)
                | isinstance(value, MaterialFilter)
                | isinstance(value, NamePrefixFilter)
                | isinstance(value, NameSuffixFilter)
                | isinstance(value, SuffixFilter)
                | isinstance(value, StatusFilter)
            ):
                filter[key] = get_str_filters(value)
            elif isinstance(value, HexValueFilter):
                filter[key] = get_hex_filters(value)
            elif isinstance(value, DateTimeFilter):
                filter[key] = get_date_filters(value)
            elif isinstance(value, FeltValueFilter):
                filter[key] = get_felt_filters(value)

    sort_options = {k: v for k, v in orderBy.__dict__.items() if v is not None}

    sort_var = "updated_at"
    sort_dir = -1

    for key, value in sort_options.items():
        if value.asc:
            sort_var = key
            sort_dir = 1
            break
        if value.desc:
            sort_var = key
            sort_dir = -1
            break
    query = db["items"].find(filter).skip(skip).limit(limit).sort(sort_var, sort_dir)

    return [Item.from_mongo(t) for t in query]


def get_market(
    info,
    where: Optional[MarketFilter] = {},
    limit: Optional[int] = 10,
    skip: Optional[int] = 0,
    orderBy: Optional[MarketOrderByInput] = {},
) -> List[Item]:
    db = info.context["db"]

    filter = {"_chain.valid_to": None}

    if where:
        processed_filters = process_filters(where)
        for key, value in processed_filters.items():
            if isinstance(value, StringFilter):
                filter[key] = get_str_filters(value)
            elif isinstance(value, HexValueFilter):
                filter[key] = get_hex_filters(value)
            elif isinstance(value, DateTimeFilter):
                filter[key] = get_date_filters(value)
            elif isinstance(value, FeltValueFilter):
                filter[key] = get_felt_filters(value)

    sort_options = {k: v for k, v in orderBy.__dict__.items() if v is not None}

    sort_var = "updated_at"
    sort_dir = -1

    for key, value in sort_options.items():
        if value.asc:
            sort_var = key
            sort_dir = 1
            break
        if value.desc:
            sort_var = key
            sort_dir = -1
            break
    query = db["market"].find(filter).skip(skip).limit(limit).sort(sort_var, sort_dir)

    return [Market.from_mongo(t) for t in query]


@strawberry.type
class Query:
    adventurers: List[Adventurer] = strawberry.field(resolver=get_adventurers)
    discoveries: List[Discovery] = strawberry.field(resolver=get_discoveries)
    beasts: List[Beast] = strawberry.field(resolver=get_beasts)
    battles: List[Battle] = strawberry.field(resolver=get_battles)
    items: List[Item] = strawberry.field(resolver=get_items)
    market: List[Market] = strawberry.field(resolver=get_market)


class IndexerGraphQLView(GraphQLView):
    def __init__(self, db, **kwargs):
        super().__init__(**kwargs)
        self._db = db

    async def get_context(self, _request, _response):
        return {"db": self._db}


async def run_graphql_api(mongo_url=None, port="8080", network="goerli"):
    mongo = MongoClient(mongo_url)
    config = Config(network=network)
    indexer = LootSurvivorIndexer(config)
    db_name = indexer.indexer_id().replace("-", "_")
    db = mongo[db_name]

    schema = strawberry.Schema(query=Query)
    view = IndexerGraphQLView(db, schema=schema)

    app = web.Application()
    # app.router.add_route("*", "/graphql", view)

    cors = aiohttp_cors.setup(app)
    resource = cors.add(app.router.add_resource("/graphql"))
    cors.add(
        resource.add_route("POST", view),
        {
            "*": aiohttp_cors.ResourceOptions(
                expose_headers="*", allow_headers="*", allow_methods="*"
            ),
        },
    )
    cors.add(
        resource.add_route("GET", view),
        {
            "*": aiohttp_cors.ResourceOptions(
                expose_headers="*", allow_headers="*", allow_methods="*"
            ),
        },
    )

    runner = web.AppRunner(app)
    await runner.setup()
    site = web.TCPSite(runner, "0.0.0.0", int(port))
    await site.start()

    print(f"GraphQL server started on port {port}")

    while True:
        await asyncio.sleep(5_000)
