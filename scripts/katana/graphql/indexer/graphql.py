import asyncio
from typing import List, NewType, Optional, Dict, Union, Any
import ssl
import json
import logging

import strawberry
import aiohttp_cors
from aiohttp import web
import aioredis
from pymongo import MongoClient
from strawberry.aiohttp.views import GraphQLView
from indexer.utils import get_key_by_value
from indexer.config import Config
from strawberry.types import Info

config = Config()

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Define a maximum limit constant
MAX_DOCUMENT_LIMIT = 101


def parse_u256(value):
    return value * (10**18)


def serialize_u256(value):
    return value / (10**18)


def parse_hex(value):
    if not value.startswith("0x"):
        raise ValueError("invalid Hex value")
    # Remove the '0x' prefix before storing
    return value[2:]


def serialize_hex(value):
    # Add the '0x' prefix when returning
    return "0x" + value


def parse_felt(value):
    return value


def serialize_felt(value):
    return value


def parse_string(value):
    # Encode the string to UTF-8 bytes
    bytes_array = value.encode("utf-8")
    # Convert the bytes to an integer
    int_value = int.from_bytes(bytes_array, byteorder="big")
    # Return the integer as a string
    return str(int_value)


def serialize_string(value):
    int_value = int(value)
    # Convert the integer to bytes
    bytes_array = int_value.to_bytes((int_value.bit_length() + 7) // 8, byteorder="big")
    # Decode the bytes using UTF-8
    return bytes_array.decode("utf-8")


def parse_class(value):
    return get_key_by_value(str(value), config.CLASSES)


def serialize_class(value):
    return config.CLASSES.get(value)


def parse_beast(value):
    return get_key_by_value(str(value), config.BEASTS)


def serialize_beast(value):
    return config.BEASTS.get(value)


def parse_adventurer_status(value):
    return get_key_by_value(str(value), config.ADVENTURER_STATUS)


def serialize_adventurer_status(value):
    return config.ADVENTURER_STATUS.get(value)


def parse_discovery(value):
    return get_key_by_value(str(value), config.DISCOVERY_TYPES)


def serialize_discovery(value):
    return config.DISCOVERY_TYPES.get(value)


def parse_sub_discovery(value):
    return get_key_by_value(str(value), config.SUB_DISCOVERY_TYPES)


def serialize_sub_discovery(value):
    return config.SUB_DISCOVERY_TYPES.get(value)


def parse_obstacle(value):
    return get_key_by_value(value, config.OBSTACLES)


def serialize_obstacle(value):
    return config.OBSTACLES.get(value)


def parse_attacker(value):
    return get_key_by_value(str(value), config.ATTACKERS)


def serialize_attacker(value):
    return config.ATTACKERS.get(value)


def parse_item(value):
    return get_key_by_value(str(value), config.ITEMS)


def serialize_item(value):
    return config.ITEMS.get(value)


def parse_material(value):
    return get_key_by_value(str(value), config.MATERIALS)


def serialize_material(value):
    return config.MATERIALS.get(value)


def parse_item_type(value):
    return get_key_by_value(str(value), config.ITEM_TYPES)


def serialize_item_type(value):
    return config.ITEM_TYPES.get(value)


def parse_special_2(value):
    return get_key_by_value(str(value), config.ITEM_NAME_PREFIXES)


def serialize_special_2(value):
    return config.ITEM_NAME_PREFIXES.get(value)


def parse_special_3(value):
    return get_key_by_value(str(value), config.ITEM_NAME_SUFFIXES)


def serialize_special_3(value):
    return config.ITEM_NAME_SUFFIXES.get(value)


def parse_special_1(value):
    return get_key_by_value(str(value), config.ITEM_SUFFIXES)


def serialize_special_1(value):
    return config.ITEM_SUFFIXES.get(value)


def parse_item_status(value):
    return get_key_by_value(str(value), config.ITEM_STATUS)


def serialize_item_status(value):
    return config.ITEM_STATUS.get(value)


def parse_slot(value):
    return get_key_by_value(str(value), config.SLOTS)


def serialize_slot(value):
    return config.SLOTS.get(value)


def parse_adventurer(value):
    return get_key_by_value(str(value), config.ATTACKERS)


def serialize_adventurer(value):
    return config.ATTACKERS.get(value)


def parse_item_tier(value):
    return get_key_by_value(str(value), config.ITEM_TIERS)


def serialize_item_tier(value):
    return config.ITEM_TIERS.get(value)


U256Value = strawberry.scalar(
    NewType("U256Value", str), parse_value=parse_u256, serialize=serialize_u256
)


HexValue = strawberry.scalar(
    NewType("HexValue", str), parse_value=parse_hex, serialize=serialize_hex
)

FeltValue = strawberry.scalar(
    NewType("FeltValue", str), parse_value=parse_felt, serialize=serialize_felt
)

StringValue = strawberry.scalar(
    NewType("StringValue", str), parse_value=parse_string, serialize=serialize_string
)

BooleanValue = strawberry.scalar(
    NewType("BooleanValue", str), parse_value=parse_felt, serialize=serialize_felt
)

ClassValue = strawberry.scalar(
    NewType("ClassValue", str), parse_value=parse_class, serialize=serialize_class
)

BeastValue = strawberry.scalar(
    NewType("BeastValue", str), parse_value=parse_beast, serialize=serialize_beast
)

AdventurerStatusValue = strawberry.scalar(
    NewType("AdventurerStatusValue", str),
    parse_value=parse_adventurer_status,
    serialize=serialize_adventurer_status,
)

DiscoveryValue = strawberry.scalar(
    NewType("DiscoveryValue", str),
    parse_value=parse_discovery,
    serialize=serialize_discovery,
)

SubDiscoveryValue = strawberry.scalar(
    NewType("SubDiscoveryValue", str),
    parse_value=parse_sub_discovery,
    serialize=serialize_sub_discovery,
)

ObstacleValue = strawberry.scalar(
    NewType("ObstacleValue", str),
    parse_value=parse_obstacle,
    serialize=serialize_obstacle,
)

AttackerValue = strawberry.scalar(
    NewType("AttackerValue", str),
    parse_value=parse_attacker,
    serialize=serialize_attacker,
)

ItemValue = strawberry.scalar(
    NewType("ItemValue", str),
    parse_value=parse_item,
    serialize=serialize_item,
)

MaterialValue = strawberry.scalar(
    NewType("MaterialValue", str),
    parse_value=parse_material,
    serialize=serialize_material,
)

ItemTypeValue = strawberry.scalar(
    NewType("ItemTypeValue", str),
    parse_value=parse_item_type,
    serialize=serialize_item_type,
)

Special1Value = strawberry.scalar(
    NewType("Special1Value", str),
    parse_value=parse_special_1,
    serialize=serialize_special_1,
)

Special2Value = strawberry.scalar(
    NewType("Special2Value", str),
    parse_value=parse_special_2,
    serialize=serialize_special_2,
)

Special3Value = strawberry.scalar(
    NewType("Special3Value", str),
    parse_value=parse_special_3,
    serialize=serialize_special_3,
)

StatusValue = strawberry.scalar(
    NewType("StatusValue", str),
    parse_value=parse_item_status,
    serialize=serialize_item_status,
)

SlotValue = strawberry.scalar(
    NewType("SlotValue", str),
    parse_value=parse_slot,
    serialize=serialize_slot,
)

AttackerValue = strawberry.scalar(
    NewType("AttackerValue", str),
    parse_value=parse_adventurer,
    serialize=serialize_adventurer,
)

ItemTierValue = strawberry.scalar(
    NewType("ItemTierValue", str),
    parse_value=parse_item_tier,
    serialize=serialize_item_tier,
)


@strawberry.input
class U256ValueFilter:
    eq: Optional[U256Value] = None
    _in: Optional[List[U256Value]] = None
    notIn: Optional[List[U256Value]] = None
    lt: Optional[U256Value] = None
    lte: Optional[U256Value] = None
    gt: Optional[U256Value] = None
    gte: Optional[U256Value] = None

    def to_dict(self):
        return {
            "eq": self.eq,
            "_in": self._in,
            "notIn": self.notIn,
            "lt": self.lt,
            "lte": self.lte,
            "gt": self.gt,
            "gte": self.gte,
        }


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

    def to_dict(self):
        return {
            "eq": self.eq,
            "_in": self._in,
            "notIn": self.notIn,
            "lt": self.lt,
            "lte": self.lte,
            "gt": self.gt,
            "gte": self.gte,
            "contains": self.contains,
            "startsWith": self.startsWith,
            "endsWith": self.endsWith,
        }


@strawberry.input
class HexValueFilter:
    eq: Optional[HexValue] = None
    _in: Optional[List[HexValue]] = None
    notIn: Optional[List[HexValue]] = None
    lt: Optional[HexValue] = None
    lte: Optional[HexValue] = None
    gt: Optional[HexValue] = None
    gte: Optional[HexValue] = None

    def to_dict(self):
        return {
            "eq": self.eq,
            "_in": self._in,
            "notIn": self.notIn,
            "lt": self.lt,
            "lte": self.lte,
            "gt": self.gt,
            "gte": self.gte,
        }


@strawberry.input
class FeltValueFilter:
    eq: Optional[FeltValue] = None
    _in: Optional[List[FeltValue]] = None
    notIn: Optional[List[FeltValue]] = None
    lt: Optional[FeltValue] = None
    lte: Optional[FeltValue] = None
    gt: Optional[FeltValue] = None
    gte: Optional[FeltValue] = None

    def to_dict(self):
        return {
            "eq": self.eq,
            "_in": self._in,
            "notIn": self.notIn,
            "lt": self.lt,
            "lte": self.lte,
            "gt": self.gt,
            "gte": self.gte,
        }


@strawberry.input
class DateTimeFilter:
    eq: Optional[str] = None
    _in: Optional[List[str]] = None
    notIn: Optional[List[str]] = None
    lt: Optional[str] = None
    lte: Optional[str] = None
    gt: Optional[str] = None
    gte: Optional[str] = None

    def to_dict(self):
        return {
            "eq": self.eq,
            "_in": self._in,
            "notIn": self.notIn,
            "lt": self.lt,
            "lte": self.lte,
            "gt": self.gt,
            "gte": self.gte,
        }


@strawberry.input
class IntFilter:
    eq: Optional[int] = None
    _in: Optional[List[int]] = None
    notIn: Optional[List[int]] = None
    lt: Optional[int] = None
    lte: Optional[int] = None
    gt: Optional[int] = None
    gte: Optional[int] = None

    def to_dict(self):
        return {
            "eq": self.eq,
            "_in": self._in,
            "notIn": self.notIn,
            "lt": self.lt,
            "lte": self.lte,
            "gt": self.gt,
            "gte": self.gte,
        }


@strawberry.input
class FloatFilter:
    eq: Optional[float] = None
    _in: Optional[List[float]] = None
    notIn: Optional[List[float]] = None
    lt: Optional[float] = None
    lte: Optional[float] = None
    gt: Optional[float] = None
    gte: Optional[float] = None

    def to_dict(self):
        return {
            "eq": self.eq,
            "_in": self._in,
            "notIn": self.notIn,
            "lt": self.lt,
            "lte": self.lte,
            "gt": self.gt,
            "gte": self.gte,
        }


@strawberry.input
class BooleanFilter:
    eq: Optional[bool] = None

    def to_dict(self):
        return {
            "eq": self.eq,
        }


@strawberry.input
class ClassFilter:
    eq: Optional[ClassValue] = None
    _in: Optional[List[ClassValue]] = None
    notIn: Optional[ClassValue] = None
    lt: Optional[ClassValue] = None
    lte: Optional[ClassValue] = None
    gt: Optional[ClassValue] = None
    gte: Optional[ClassValue] = None
    contains: Optional[ClassValue] = None
    startsWith: Optional[ClassValue] = None
    endsWith: Optional[ClassValue] = None

    def to_dict(self):
        return {
            "eq": self.eq,
            "_in": self._in,
            "notIn": self.notIn,
            "lt": self.lt,
            "lte": self.lte,
            "gt": self.gt,
            "gte": self.gte,
            "contains": self.contains,
            "startsWith": self.startsWith,
            "endsWith": self.endsWith,
        }


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

    def to_dict(self):
        return {
            "eq": self.eq,
            "_in": self._in,
            "notIn": self.notIn,
            "lt": self.lt,
            "lte": self.lte,
            "gt": self.gt,
            "gte": self.gte,
            "contains": self.contains,
            "startsWith": self.startsWith,
            "endsWith": self.endsWith,
        }


@strawberry.input
class AdventurerStatusFilter:
    eq: Optional[AdventurerStatusValue] = None
    _in: Optional[List[AdventurerStatusValue]] = None
    notIn: Optional[AdventurerStatusValue] = None
    lt: Optional[AdventurerStatusValue] = None
    lte: Optional[AdventurerStatusValue] = None
    gt: Optional[AdventurerStatusValue] = None
    gte: Optional[AdventurerStatusValue] = None
    contains: Optional[AdventurerStatusValue] = None
    startsWith: Optional[AdventurerStatusValue] = None
    endsWith: Optional[AdventurerStatusValue] = None

    def to_dict(self):
        return {
            "eq": self.eq,
            "_in": self._in,
            "notIn": self.notIn,
            "lt": self.lt,
            "lte": self.lte,
            "gt": self.gt,
            "gte": self.gte,
            "contains": self.contains,
            "startsWith": self.startsWith,
            "endsWith": self.endsWith,
        }


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

    def to_dict(self):
        return {
            "eq": self.eq,
            "_in": self._in,
            "notIn": self.notIn,
            "lt": self.lt,
            "lte": self.lte,
            "gt": self.gt,
            "gte": self.gte,
            "contains": self.contains,
            "startsWith": self.startsWith,
            "endsWith": self.endsWith,
        }


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

    def to_dict(self):
        return {
            "eq": self.eq,
            "_in": self._in,
            "notIn": self.notIn,
            "lt": self.lt,
            "lte": self.lte,
            "gt": self.gt,
            "gte": self.gte,
            "contains": self.contains,
            "startsWith": self.startsWith,
            "endsWith": self.endsWith,
        }


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

    def to_dict(self):
        return {
            "eq": self.eq,
            "_in": self._in,
            "notIn": self.notIn,
            "lt": self.lt,
            "lte": self.lte,
            "gt": self.gt,
            "gte": self.gte,
            "contains": self.contains,
            "startsWith": self.startsWith,
            "endsWith": self.endsWith,
        }


@strawberry.input
class AttackerFilter:
    eq: Optional[AttackerValue] = None

    def to_dict(self):
        return {
            "eq": self.eq,
        }


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

    def to_dict(self):
        return {
            "eq": serialize_item(self.eq) if self.eq else None,
            "_in": [serialize_item(v) for v in self._in] if self._in else None,
            "notIn": [serialize_item(v) for v in self.notIn] if self.notIn else None,
            "lt": serialize_item(self.lt) if self.lt else None,
            "lte": serialize_item(self.lte) if self.lte else None,
            "gt": serialize_item(self.gt) if self.gt else None,
            "gte": serialize_item(self.gte) if self.gte else None,
            "contains": serialize_item(self.contains) if self.contains else None,
            "startsWith": serialize_item(self.startsWith) if self.startsWith else None,
            "endsWith": serialize_item(self.endsWith) if self.endsWith else None,
        }


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

    def to_dict(self):
        return {
            "eq": serialize_material(self.eq) if self.eq else None,
            "_in": [serialize_material(v) for v in self._in] if self._in else None,
            "notIn": (
                [serialize_material(v) for v in self.notIn] if self.notIn else None
            ),
            "lt": serialize_material(self.lt) if self.lt else None,
            "lte": serialize_material(self.lte) if self.lte else None,
            "gt": serialize_material(self.gt) if self.gt else None,
            "gte": serialize_material(self.gte) if self.gte else None,
            "contains": serialize_material(self.contains) if self.contains else None,
            "startsWith": (
                serialize_material(self.startsWith) if self.startsWith else None
            ),
            "endsWith": serialize_material(self.endsWith) if self.endsWith else None,
        }


@strawberry.input
class TypeFilter:
    eq: Optional[ItemTypeValue] = None
    _in: Optional[List[ItemTypeValue]] = None
    notIn: Optional[ItemTypeValue] = None
    lt: Optional[ItemTypeValue] = None
    lte: Optional[ItemTypeValue] = None
    gt: Optional[ItemTypeValue] = None
    gte: Optional[ItemTypeValue] = None
    contains: Optional[ItemTypeValue] = None
    startsWith: Optional[ItemTypeValue] = None
    endsWith: Optional[ItemTypeValue] = None

    def to_dict(self):
        return {
            "eq": serialize_item_type(self.eq) if self.eq else None,
            "_in": [serialize_item_type(v) for v in self._in] if self._in else None,
            "notIn": (
                [serialize_item_type(v) for v in self.notIn] if self.notIn else None
            ),
            "lt": serialize_item_type(self.lt) if self.lt else None,
            "lte": serialize_item_type(self.lte) if self.lte else None,
            "gt": serialize_item_type(self.gt) if self.gt else None,
            "gte": serialize_item_type(self.gte) if self.gte else None,
            "contains": serialize_item_type(self.contains) if self.contains else None,
            "startsWith": (
                serialize_item_type(self.startsWith) if self.startsWith else None
            ),
            "endsWith": serialize_item_type(self.endsWith) if self.endsWith else None,
        }


@strawberry.input
class Special1Filter:
    eq: Optional[Special1Value] = None
    _in: Optional[List[Special1Value]] = None
    notIn: Optional[Special1Value] = None
    lt: Optional[Special1Value] = None
    lte: Optional[Special1Value] = None
    gt: Optional[Special1Value] = None
    gte: Optional[Special1Value] = None
    contains: Optional[Special1Value] = None
    startsWith: Optional[Special1Value] = None
    endsWith: Optional[Special1Value] = None

    def to_dict(self):
        return {
            "eq": serialize_special_1(self.eq) if self.eq else None,
            "_in": [serialize_special_1(v) for v in self._in] if self._in else None,
            "notIn": (
                [serialize_special_1(v) for v in self.notIn] if self.notIn else None
            ),
            "lt": serialize_special_1(self.lt) if self.lt else None,
            "lte": serialize_special_1(self.lte) if self.lte else None,
            "gt": serialize_special_1(self.gt) if self.gt else None,
            "gte": serialize_special_1(self.gte) if self.gte else None,
            "contains": serialize_special_1(self.contains) if self.contains else None,
            "startsWith": (
                serialize_special_1(self.startsWith) if self.startsWith else None
            ),
            "endsWith": serialize_special_1(self.endsWith) if self.endsWith else None,
        }


@strawberry.input
class Special2Filter:
    eq: Optional[Special2Value] = None
    _in: Optional[List[Special2Value]] = None
    notIn: Optional[Special2Value] = None
    lt: Optional[Special2Value] = None
    lte: Optional[Special2Value] = None
    gt: Optional[Special2Value] = None
    gte: Optional[Special2Value] = None
    contains: Optional[Special2Value] = None
    startsWith: Optional[Special2Value] = None
    endsWith: Optional[Special2Value] = None

    def to_dict(self):
        return {
            "eq": serialize_special_2(self.eq) if self.eq else None,
            "_in": [serialize_special_2(v) for v in self._in] if self._in else None,
            "notIn": (
                [serialize_special_2(v) for v in self.notIn] if self.notIn else None
            ),
            "lt": serialize_special_2(self.lt) if self.lt else None,
            "lte": serialize_special_2(self.lte) if self.lte else None,
            "gt": serialize_special_2(self.gt) if self.gt else None,
            "gte": serialize_special_2(self.gte) if self.gte else None,
            "contains": serialize_special_2(self.contains) if self.contains else None,
            "startsWith": (
                serialize_special_2(self.startsWith) if self.startsWith else None
            ),
            "endsWith": serialize_special_2(self.endsWith) if self.endsWith else None,
        }


@strawberry.input
class Special3Filter:
    eq: Optional[Special3Value] = None
    _in: Optional[List[Special3Value]] = None
    notIn: Optional[Special3Value] = None
    lt: Optional[Special3Value] = None
    lte: Optional[Special3Value] = None
    gt: Optional[Special3Value] = None
    gte: Optional[Special3Value] = None
    contains: Optional[Special3Value] = None
    startsWith: Optional[Special3Value] = None
    endsWith: Optional[Special3Value] = None

    def to_dict(self):
        return {
            "eq": serialize_special_3(self.eq) if self.eq else None,
            "_in": [serialize_special_3(v) for v in self._in] if self._in else None,
            "notIn": (
                [serialize_special_3(v) for v in self.notIn] if self.notIn else None
            ),
            "lt": serialize_special_3(self.lt) if self.lt else None,
            "lte": serialize_special_3(self.lte) if self.lte else None,
            "gt": serialize_special_3(self.gt) if self.gt else None,
            "gte": serialize_special_3(self.gte) if self.gte else None,
            "contains": serialize_special_3(self.contains) if self.contains else None,
            "startsWith": (
                serialize_special_3(self.startsWith) if self.startsWith else None
            ),
            "endsWith": serialize_special_3(self.endsWith) if self.endsWith else None,
        }


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

    def to_dict(self):
        return {
            "eq": serialize_item_status(self.eq) if self.eq else None,
            "_in": [serialize_item_status(v) for v in self._in] if self._in else None,
            "notIn": (
                [serialize_item_status(v) for v in self.notIn] if self.notIn else None
            ),
            "lt": serialize_item_status(self.lt) if self.lt else None,
            "lte": serialize_item_status(self.lte) if self.lte else None,
            "gt": serialize_item_status(self.gt) if self.gt else None,
            "gte": serialize_item_status(self.gte) if self.gte else None,
            "contains": serialize_item_status(self.contains) if self.contains else None,
            "startsWith": (
                serialize_item_status(self.startsWith) if self.startsWith else None
            ),
            "endsWith": serialize_item_status(self.endsWith) if self.endsWith else None,
        }


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

    def to_dict(self):
        return {
            "eq": serialize_slot(self.eq) if self.eq else None,
            "_in": [serialize_slot(v) for v in self._in] if self._in else None,
            "notIn": [serialize_slot(v) for v in self.notIn] if self.notIn else None,
            "lt": serialize_slot(self.lt) if self.lt else None,
            "lte": serialize_slot(self.lte) if self.lte else None,
            "gt": serialize_slot(self.gt) if self.gt else None,
            "gte": serialize_slot(self.gte) if self.gte else None,
            "contains": serialize_slot(self.contains) if self.contains else None,
            "startsWith": serialize_slot(self.startsWith) if self.startsWith else None,
            "endsWith": serialize_slot(self.endsWith) if self.endsWith else None,
        }


@strawberry.input
class ItemTierFilter:
    eq: Optional[ItemTierValue] = None
    _in: Optional[List[ItemTierValue]] = None
    notIn: Optional[ItemTierValue] = None
    lt: Optional[ItemTierValue] = None
    lte: Optional[ItemTierValue] = None
    gt: Optional[ItemTierValue] = None
    gte: Optional[ItemTierValue] = None
    contains: Optional[ItemTierValue] = None
    startsWith: Optional[ItemTierValue] = None
    endsWith: Optional[ItemTierValue] = None

    def to_dict(self):
        return {
            "eq": serialize_item_tier(self.eq) if self.eq else None,
            "_in": [serialize_item_tier(v) for v in self._in] if self._in else None,
            "notIn": (
                [serialize_item_tier(v) for v in self.notIn] if self.notIn else None
            ),
            "lt": serialize_item_tier(self.lt) if self.lt else None,
            "lte": serialize_item_tier(self.lte) if self.lte else None,
            "gt": serialize_item_tier(self.gt) if self.gt else None,
            "gte": serialize_item_tier(self.gte) if self.gte else None,
            "contains": serialize_item_tier(self.contains) if self.contains else None,
            "startsWith": (
                serialize_item_tier(self.startsWith) if self.startsWith else None
            ),
            "endsWith": serialize_item_tier(self.endsWith) if self.endsWith else None,
        }


@strawberry.input
class ItemTypeFilter:
    eq: Optional[ItemTypeValue] = None
    _in: Optional[List[ItemTypeValue]] = None
    notIn: Optional[ItemTypeValue] = None
    lt: Optional[ItemTypeValue] = None
    lte: Optional[ItemTypeValue] = None
    gt: Optional[ItemTypeValue] = None
    gte: Optional[ItemTypeValue] = None
    contains: Optional[ItemTypeValue] = None
    startsWith: Optional[ItemTypeValue] = None
    endsWith: Optional[ItemTypeValue] = None

    def to_dict(self):
        return {
            "eq": serialize_item_type(self.eq) if self.eq else None,
            "_in": [serialize_item_type(v) for v in self._in] if self._in else None,
            "notIn": (
                [serialize_item_type(v) for v in self.notIn] if self.notIn else None
            ),
            "lt": serialize_item_type(self.lt) if self.lt else None,
            "lte": serialize_item_type(self.lte) if self.lte else None,
            "gt": serialize_item_type(self.gt) if self.gt else None,
            "gte": serialize_item_type(self.gte) if self.gte else None,
            "contains": serialize_item_type(self.contains) if self.contains else None,
            "startsWith": (
                serialize_item_type(self.startsWith) if self.startsWith else None
            ),
            "endsWith": serialize_item_type(self.endsWith) if self.endsWith else None,
        }


@strawberry.input
class OrderByInput:
    asc: Optional[bool] = False
    desc: Optional[bool] = False

    def to_dict(self):
        return {
            "asc": self.asc,
            "desc": self.desc,
        }


@strawberry.input
class AdventurersFilter:
    id: Optional[FeltValueFilter] = None
    entropy: Optional[HexValueFilter] = None
    owner: Optional[HexValueFilter] = None
    name: Optional[StringFilter] = None
    health: Optional[FeltValueFilter] = None
    strength: Optional[FeltValueFilter] = None
    dexterity: Optional[FeltValueFilter] = None
    vitality: Optional[FeltValueFilter] = None
    intelligence: Optional[FeltValueFilter] = None
    wisdom: Optional[FeltValueFilter] = None
    charisma: Optional[FeltValueFilter] = None
    luck: Optional[FeltValueFilter] = None
    xp: Optional[FeltValueFilter] = None
    level: Optional[FeltValueFilter] = None
    weapon: Optional[FeltValueFilter] = None
    chest: Optional[FeltValueFilter] = None
    head: Optional[FeltValueFilter] = None
    waist: Optional[FeltValueFilter] = None
    foot: Optional[FeltValueFilter] = None
    hand: Optional[FeltValueFilter] = None
    neck: Optional[FeltValueFilter] = None
    ring: Optional[FeltValueFilter] = None
    beastHealth: Optional[FeltValueFilter] = None
    statUpgrades: Optional[FeltValueFilter] = None
    birthDate: Optional[OrderByInput] = None
    deathDate: Optional[OrderByInput] = None
    goldenTokenId: Optional[OrderByInput] = None
    customRenderer: Optional[OrderByInput] = None
    battleActionCount: Optional[OrderByInput] = None
    actionsPerBlock: Optional[FeltValueFilter] = None
    gold: Optional[FeltValueFilter] = None
    createdTime: Optional[OrderByInput] = None
    lastUpdatedTime: Optional[DateTimeFilter] = None
    timestamp: Optional[DateTimeFilter] = None

    def to_dict(self):
        return {
            "id": self.id.to_dict() if self.id else None,
            "entropy": self.entropy.to_dict() if self.entropy else None,
            "owner": self.owner.to_dict() if self.owner else None,
            "name": self.name.to_dict() if self.name else None,
            "health": self.health.to_dict() if self.health else None,
            "strength": self.strength.to_dict() if self.strength else None,
            "dexterity": self.dexterity.to_dict() if self.dexterity else None,
            "vitality": self.vitality.to_dict() if self.vitality else None,
            "intelligence": self.intelligence.to_dict() if self.intelligence else None,
            "wisdom": self.wisdom.to_dict() if self.wisdom else None,
            "charisma": self.charisma.to_dict() if self.charisma else None,
            "luck": self.luck.to_dict() if self.luck else None,
            "xp": self.xp.to_dict() if self.xp else None,
            "level": self.level.to_dict() if self.level else None,
            "weapon": self.weapon.to_dict() if self.weapon else None,
            "chest": self.chest.to_dict() if self.chest else None,
            "head": self.head.to_dict() if self.head else None,
            "waist": self.waist.to_dict() if self.waist else None,
            "foot": self.foot.to_dict() if self.foot else None,
            "hand": self.hand.to_dict() if self.hand else None,
            "neck": self.neck.to_dict() if self.neck else None,
            "ring": self.ring.to_dict() if self.ring else None,
            "beastHealth": self.beastHealth.to_dict() if self.beastHealth else None,
            "statUpgrades": self.statUpgrades.to_dict() if self.statUpgrades else None,
            "birthDate": self.birthDate.to_dict() if self.birthDate else None,
            "deathDate": self.deathDate.to_dict() if self.deathDate else None,
            "goldenTokenId": (
                self.goldenTokenId.to_dict() if self.goldenTokenId else None
            ),
            "customRenderer": (
                self.customRenderer.to_dict() if self.customRenderer else None
            ),
            "battleActionCount": (
                self.battleActionCount.to_dict() if self.battleActionCount else None
            ),
            "gold": self.gold.to_dict() if self.gold else None,
            "createdTime": self.createdTime.to_dict() if self.createdTime else None,
            "lastUpdatedTime": (
                self.lastUpdatedTime.to_dict() if self.lastUpdatedTime else None
            ),
            "timestamp": self.timestamp.to_dict() if self.timestamp else None,
        }


@strawberry.input
class ScoresFilter:
    adventurerId: Optional[FeltValueFilter] = None
    timestamp: Optional[DateTimeFilter] = None
    totalPayout: Optional[U256ValueFilter] = None

    def to_dict(self):
        return {
            "adventurerId": self.adventurerId.to_dict() if self.adventurerId else None,
            "timestamp": self.timestamp.to_dict() if self.timestamp else None,
            "totalPayout": self.totalPayout.to_dict() if self.totalPayout else None,
        }


@strawberry.input
class DiscoveriesFilter:
    adventurerId: Optional[FeltValueFilter] = None
    adventurerHealth: Optional[FeltValueFilter] = None
    disoveryType: Optional[StringFilter] = None
    subDiscoveryType: Optional[StringFilter] = None
    outputAmount: Optional[FeltValueFilter] = None
    obstacle: Optional[ObstacleFilter] = None
    obstacleLevel: Optional[FeltValueFilter] = None
    dodgedObstacle: Optional[BooleanFilter] = None
    damageTaken: Optional[FeltValueFilter] = None
    damageLocation: Optional[SlotFilter] = None
    xpEarnedAdventurer: Optional[FeltValueFilter] = None
    xpEarnedItems: Optional[FeltValueFilter] = None
    entity: Optional[FeltValueFilter] = None
    entityLevel: Optional[FeltValueFilter] = None
    entityHealth: Optional[FeltValueFilter] = None
    special1: Optional[Special1Filter] = None
    special2: Optional[Special2Filter] = None
    special3: Optional[Special3Filter] = None
    seed: Optional[HexValueFilter] = None
    ambushed: Optional[BooleanFilter] = None
    discoveryTime: Optional[DateTimeFilter] = None
    timestamp: Optional[DateTimeFilter] = None
    txHash: Optional[HexValueFilter] = None

    def to_dict(self):
        return {
            "adventurerId": self.adventurerId.to_dict() if self.adventurerId else None,
            "adventurerHealth": (
                self.adventurerHealth.to_dict() if self.adventurerHealth else None
            ),
            "disoveryType": self.disoveryType.to_dict() if self.disoveryType else None,
            "subDiscoveryType": (
                self.subDiscoveryType.to_dict() if self.subDiscoveryType else None
            ),
            "outputAmount": self.outputAmount.to_dict() if self.outputAmount else None,
            "obstacle": self.obstacle.to_dict() if self.obstacle else None,
            "obstacleLevel": (
                self.obstacleLevel.to_dict() if self.obstacleLevel else None
            ),
            "dodgedObstacle": (
                self.dodgedObstacle.to_dict() if self.dodgedObstacle else None
            ),
            "damageTaken": self.damageTaken.to_dict() if self.damageTaken else None,
            "damageLocation": (
                self.damageLocation.to_dict() if self.damageLocation else None
            ),
            "xpEarnedAdventurer": (
                self.xpEarnedAdventurer.to_dict() if self.xpEarnedAdventurer else None
            ),
            "xpEarnedItems": (
                self.xpEarnedItems.to_dict() if self.xpEarnedItems else None
            ),
            "entity": self.entity.to_dict() if self.entity else None,
            "entityLevel": self.entityLevel.to_dict() if self.entityLevel else None,
            "entityHealth": self.entityHealth.to_dict() if self.entityHealth else None,
            "special1": self.special1.to_dict() if self.special1 else None,
            "special2": self.special2.to_dict() if self.special2 else None,
            "special3": self.special3.to_dict() if self.special3 else None,
            "seed": self.seed.to_dict() if self.seed else None,
            "ambushed": self.ambushed.to_dict() if self.ambushed else None,
            "discoveryTime": (
                self.discoveryTime.to_dict() if self.discoveryTime else None
            ),
            "timestamp": self.timestamp.to_dict() if self.timestamp else None,
            "txHash": self.txHash.to_dict() if self.txHash else None,
        }


@strawberry.input
class BeastsFilter:
    beast: Optional[BeastFilter] = None
    adventurerId: Optional[FeltValueFilter] = None
    seed: Optional[HexValueFilter] = None
    special1: Optional[Special1Filter] = None
    special2: Optional[Special2Filter] = None
    special3: Optional[Special3Filter] = None
    health: Optional[FeltValueFilter] = None
    level: Optional[FeltValueFilter] = None
    tier: Optional[FeltValueFilter] = None
    slainOnTime: Optional[DateTimeFilter] = None
    createdTime: Optional[DateTimeFilter] = None
    lastUpdatedTime: Optional[DateTimeFilter] = None
    timestamp: Optional[DateTimeFilter] = None

    def to_dict(self):
        return {
            "beast": self.beast.to_dict() if self.beast else None,
            "adventurerId": self.adventurerId.to_dict() if self.adventurerId else None,
            "seed": self.seed.to_dict() if self.seed else None,
            "special1": self.special1.to_dict() if self.special1 else None,
            "special2": self.special2.to_dict() if self.special2 else None,
            "special3": self.special3.to_dict() if self.special3 else None,
            "health": self.health.to_dict() if self.health else None,
            "level": self.level.to_dict() if self.level else None,
            "tier": self.tier.to_dict() if self.tier else None,
            "slainOnTime": self.slainOnTime.to_dict() if self.slainOnTime else None,
            "createdTime": self.createdTime.to_dict() if self.createdTime else None,
            "lastUpdatedTime": (
                self.lastUpdatedTime.to_dict() if self.lastUpdatedTime else None
            ),
            "timestamp": self.timestamp.to_dict() if self.timestamp else None,
        }


@strawberry.input
class BattlesFilter:
    adventurerId: Optional[FeltValueFilter] = None
    adventurerHealth: Optional[FeltValueFilter] = None
    beast: Optional[BeastFilter] = None
    beastHealth: Optional[FeltValueFilter] = None
    beastLevel: Optional[FeltValueFilter] = None
    special1: Optional[Special1Filter] = None
    special2: Optional[Special2Filter] = None
    special3: Optional[Special3Filter] = None
    seed: Optional[HexValueFilter] = None
    attacker: Optional[AttackerFilter] = None
    fled: Optional[BooleanFilter] = None
    damageDealt: Optional[FeltValueFilter] = None
    criticalHit: Optional[BooleanFilter] = None
    damageTaken: Optional[FeltValueFilter] = None
    damageLocation: Optional[SlotFilter] = None
    xpEarnedAdventurer: Optional[FeltValueFilter] = None
    xpEarnedItems: Optional[FeltValueFilter] = None
    goldEarned: Optional[FeltValueFilter] = None
    txHash: Optional[HexValueFilter] = None
    discoveryTime: Optional[DateTimeFilter] = None
    blockTime: Optional[DateTimeFilter] = None

    def to_dict(self):
        return {
            "adventurerId": self.adventurerId.to_dict() if self.adventurerId else None,
            "adventurerHealth": (
                self.adventurerHealth.to_dict() if self.adventurerHealth else None
            ),
            "beast": self.beast.to_dict() if self.beast else None,
            "beastHealth": self.beastHealth.to_dict() if self.beastHealth else None,
            "beastLevel": self.beastLevel.to_dict() if self.beastLevel else None,
            "special1": self.special1.to_dict() if self.special1 else None,
            "special2": self.special2.to_dict() if self.special2 else None,
            "special3": self.special3.to_dict() if self.special3 else None,
            "seed": self.seed.to_dict() if self.seed else None,
            "attacker": self.attacker.to_dict() if self.attacker else None,
            "fled": self.fled.to_dict() if self.fled else None,
            "damageDealt": self.damageDealt.to_dict() if self.damageDealt else None,
            "criticalHit": self.criticalHit.to_dict() if self.criticalHit else None,
            "damageTaken": self.damageTaken.to_dict() if self.damageTaken else None,
            "damageLocation": (
                self.damageLocation.to_dict() if self.damageLocation else None
            ),
            "xpEarnedAdventurer": (
                self.xpEarnedAdventurer.to_dict() if self.xpEarnedAdventurer else None
            ),
            "xpEarnedItems": (
                self.xpEarnedItems.to_dict() if self.xpEarnedItems else None
            ),
            "goldEarned": self.goldEarned.to_dict() if self.goldEarned else None,
            "txHash": self.txHash.to_dict() if self.txHash else None,
            "discoveryTime": (
                self.discoveryTime.to_dict() if self.discoveryTime else None
            ),
            "blockTime": self.blockTime.to_dict() if self.blockTime else None,
        }


@strawberry.input
class ItemsFilter:
    item: Optional[ItemFilter] = None
    adventurerId: Optional[FeltValueFilter] = None
    ownerAddress: Optional[HexValueFilter] = None
    owner: Optional[BooleanFilter] = None
    equipped: Optional[BooleanFilter] = None
    slot: Optional[SlotFilter] = None
    tier: Optional[ItemTierFilter] = None
    type: Optional[ItemTypeFilter] = None
    greatness: Optional[FeltValueFilter] = None
    purchasedTime: Optional[DateTimeFilter] = None
    special1: Optional[Special1Filter] = None
    special2: Optional[Special2Filter] = None
    special3: Optional[Special3Filter] = None
    xp: Optional[FeltValueFilter] = None
    isAvailable: Optional[BooleanFilter] = None
    timestamp: Optional[DateTimeFilter] = None

    def to_dict(self):
        return {
            "item": self.item.to_dict() if self.item else None,
            "adventurerId": self.adventurerId.to_dict() if self.adventurerId else None,
            "ownerAddress": self.ownerAddress.to_dict() if self.ownerAddress else None,
            "owner": self.owner.to_dict() if self.owner else None,
            "equipped": self.equipped.to_dict() if self.equipped else None,
            "slot": self.slot.to_dict() if self.slot else None,
            "tier": self.tier.to_dict() if self.tier else None,
            "type": self.type.to_dict() if self.type else None,
            "greatness": self.greatness.to_dict() if self.greatness else None,
            "purchasedTime": (
                self.purchasedTime.to_dict() if self.purchasedTime else None
            ),
            "special1": self.special1.to_dict() if self.special1 else None,
            "special2": self.special2.to_dict() if self.special2 else None,
            "special3": self.special3.to_dict() if self.special3 else None,
            "xp": self.xp.to_dict() if self.xp else None,
            "isAvailable": self.isAvailable.to_dict() if self.isAvailable else None,
            "timestamp": self.timestamp.to_dict() if self.timestamp else None,
        }


@strawberry.input
class AdventurersOrderByInput:
    id: Optional[OrderByInput] = None
    entropy: Optional[OrderByInput] = None
    owner: Optional[OrderByInput] = None
    name: Optional[OrderByInput] = None
    health: Optional[OrderByInput] = None
    strength: Optional[OrderByInput] = None
    dexterity: Optional[OrderByInput] = None
    vitality: Optional[OrderByInput] = None
    intelligence: Optional[OrderByInput] = None
    wisdom: Optional[OrderByInput] = None
    charisma: Optional[OrderByInput] = None
    luck: Optional[OrderByInput] = None
    xp: Optional[OrderByInput] = None
    level: Optional[OrderByInput] = None
    weapon: Optional[OrderByInput] = None
    chest: Optional[OrderByInput] = None
    head: Optional[OrderByInput] = None
    waist: Optional[OrderByInput] = None
    foot: Optional[OrderByInput] = None
    hand: Optional[OrderByInput] = None
    neck: Optional[OrderByInput] = None
    ring: Optional[OrderByInput] = None
    beastHealth: Optional[OrderByInput] = None
    statUpgrades: Optional[OrderByInput] = None
    birthDate: Optional[OrderByInput] = None
    deathDate: Optional[OrderByInput] = None
    goldenTokenId: Optional[OrderByInput] = None
    customRenderer: Optional[OrderByInput] = None
    battleActionCount: Optional[OrderByInput] = None
    gold: Optional[OrderByInput] = None
    createdTime: Optional[OrderByInput] = None
    lastUpdatedTime: Optional[OrderByInput] = None
    timestamp: Optional[OrderByInput] = None

    def to_dict(self):
        return {
            "id": self.id.to_dict() if self.id else None,
            "entropy": self.entropy.to_dict() if self.entropy else None,
            "owner": self.owner.to_dict() if self.owner else None,
            "name": self.name.to_dict() if self.name else None,
            "health": self.health.to_dict() if self.health else None,
            "strength": self.strength.to_dict() if self.strength else None,
            "dexterity": self.dexterity.to_dict() if self.dexterity else None,
            "vitality": self.vitality.to_dict() if self.vitality else None,
            "intelligence": self.intelligence.to_dict() if self.intelligence else None,
            "wisdom": self.wisdom.to_dict() if self.wisdom else None,
            "charisma": self.charisma.to_dict() if self.charisma else None,
            "luck": self.luck.to_dict() if self.luck else None,
            "xp": self.xp.to_dict() if self.xp else None,
            "level": self.level.to_dict() if self.level else None,
            "weapon": self.weapon.to_dict() if self.weapon else None,
            "chest": self.chest.to_dict() if self.chest else None,
            "head": self.head.to_dict() if self.head else None,
            "waist": self.waist.to_dict() if self.waist else None,
            "foot": self.foot.to_dict() if self.foot else None,
            "hand": self.hand.to_dict() if self.hand else None,
            "neck": self.neck.to_dict() if self.neck else None,
            "ring": self.ring.to_dict() if self.ring else None,
            "beastHealth": self.beastHealth.to_dict() if self.beastHealth else None,
            "statUpgrades": self.statUpgrades.to_dict() if self.statUpgrades else None,
            "birthDate": self.birthDate.to_dict() if self.birthDate else None,
            "deathDate": self.deathDate.to_dict() if self.deathDate else None,
            "goldenTokenId": (
                self.goldenTokenId.to_dict() if self.goldenTokenId else None
            ),
            "customRenderer": (
                self.customRenderer.to_dict() if self.customRenderer else None
            ),
            "battleActionCount": (
                self.battleActionCount.to_dict() if self.battleActionCount else None
            ),
            "gold": self.gold.to_dict() if self.gold else None,
            "createdTime": self.createdTime.to_dict() if self.createdTime else None,
            "lastUpdatedTime": (
                self.lastUpdatedTime.to_dict() if self.lastUpdatedTime else None
            ),
            "timestamp": self.timestamp.to_dict() if self.timestamp else None,
        }


@strawberry.input
class ScoresOrderByInput:
    adventurerId: Optional[OrderByInput] = None
    timestamp: Optional[OrderByInput] = None
    totalPayout: Optional[OrderByInput] = None

    def to_dict(self):
        return {
            "adventurerId": self.adventurerId.to_dict() if self.adventurerId else None,
            "timestamp": self.timestamp.to_dict() if self.timestamp else None,
            "totalPayout": self.totalPayout.to_dict() if self.totalPayout else None,
        }


@strawberry.input
class DiscoveriesOrderByInput:
    adventurerId: Optional[OrderByInput] = None
    adventurerHealth: Optional[OrderByInput] = None
    disoveryType: Optional[OrderByInput] = None
    subDiscoveryType: Optional[OrderByInput] = None
    outputAmount: Optional[OrderByInput] = None
    obstacle: Optional[OrderByInput] = None
    obstacleLevel: Optional[OrderByInput] = None
    dodgedObstacle: Optional[OrderByInput] = None
    damageTaken: Optional[OrderByInput] = None
    damageLocation: Optional[OrderByInput] = None
    xpEarnedAdventurer: Optional[OrderByInput] = None
    xpEarnedItems: Optional[OrderByInput] = None
    entity: Optional[OrderByInput] = None
    entityLevel: Optional[OrderByInput] = None
    entityHealth: Optional[OrderByInput] = None
    special1: Optional[OrderByInput] = None
    special2: Optional[OrderByInput] = None
    special3: Optional[OrderByInput] = None
    ambushed: Optional[OrderByInput] = None
    discoveryTime: Optional[OrderByInput] = None
    timestamp: Optional[OrderByInput] = None
    seed: Optional[OrderByInput] = None
    txHash: Optional[OrderByInput] = None

    def to_dict(self):
        return {
            "adventurerId": self.adventurerId.to_dict() if self.adventurerId else None,
            "adventurerHealth": (
                self.adventurerHealth.to_dict() if self.adventurerHealth else None
            ),
            "disoveryType": self.disoveryType.to_dict() if self.disoveryType else None,
            "subDiscoveryType": (
                self.subDiscoveryType.to_dict() if self.subDiscoveryType else None
            ),
            "outputAmount": self.outputAmount.to_dict() if self.outputAmount else None,
            "obstacle": self.obstacle.to_dict() if self.obstacle else None,
            "obstacleLevel": (
                self.obstacleLevel.to_dict() if self.obstacleLevel else None
            ),
            "dodgedObstacle": (
                self.dodgedObstacle.to_dict() if self.dodgedObstacle else None
            ),
            "damageTaken": self.damageTaken.to_dict() if self.damageTaken else None,
            "damageLocation": (
                self.damageLocation.to_dict() if self.damageLocation else None
            ),
            "xpEarnedAdventurer": (
                self.xpEarnedAdventurer.to_dict() if self.xpEarnedAdventurer else None
            ),
            "xpEarnedItems": (
                self.xpEarnedItems.to_dict() if self.xpEarnedItems else None
            ),
            "entity": self.entity.to_dict() if self.entity else None,
            "entityLevel": self.entityLevel.to_dict() if self.entityLevel else None,
            "entityHealth": self.entityHealth.to_dict() if self.entityHealth else None,
            "special1": self.special1.to_dict() if self.special1 else None,
            "special2": self.special2.to_dict() if self.special2 else None,
            "special3": self.special3.to_dict() if self.special3 else None,
            "ambushed": self.ambushed.to_dict() if self.ambushed else None,
            "discoveryTime": (
                self.discoveryTime.to_dict() if self.discoveryTime else None
            ),
            "timestamp": self.timestamp.to_dict() if self.timestamp else None,
            "seed": self.seed.to_dict() if self.seed else None,
            "txHash": self.txHash.to_dict() if self.txHash else None,
        }


@strawberry.input
class BeastsOrderByInput:
    beast: Optional[OrderByInput] = None
    adventurerId: Optional[OrderByInput] = None
    seed: Optional[OrderByInput] = None
    special1: Optional[OrderByInput] = None
    special2: Optional[OrderByInput] = None
    special3: Optional[OrderByInput] = None
    health: Optional[OrderByInput] = None
    level: Optional[OrderByInput] = None
    tier: Optional[OrderByInput] = None
    slainOnTime: Optional[OrderByInput] = None
    createdTime: Optional[OrderByInput] = None
    lastUpdatedTime: Optional[OrderByInput] = None
    timestamp: Optional[OrderByInput] = None

    def to_dict(self):
        return {
            "beast": self.beast.to_dict() if self.beast else None,
            "adventurerId": self.adventurerId.to_dict() if self.adventurerId else None,
            "seed": self.seed.to_dict() if self.seed else None,
            "special1": self.special1.to_dict() if self.special1 else None,
            "special2": self.special2.to_dict() if self.special2 else None,
            "special3": self.special3.to_dict() if self.special3 else None,
            "health": self.health.to_dict() if self.health else None,
            "level": self.level.to_dict() if self.level else None,
            "tier": self.tier.to_dict() if self.tier else None,
            "slainOnTime": self.slainOnTime.to_dict() if self.slainOnTime else None,
            "createdTime": self.createdTime.to_dict() if self.createdTime else None,
            "lastUpdatedTime": (
                self.lastUpdatedTime.to_dict() if self.lastUpdatedTime else None
            ),
            "timestamp": self.timestamp.to_dict() if self.timestamp else None,
        }


@strawberry.input
class BattlesOrderByInput:
    adventurerId: Optional[OrderByInput] = None
    adventurerHealth: Optional[OrderByInput] = None
    beast: Optional[OrderByInput] = None
    beastHealth: Optional[OrderByInput] = None
    beastLevel: Optional[OrderByInput] = None
    special1: Optional[OrderByInput] = None
    special2: Optional[OrderByInput] = None
    special3: Optional[OrderByInput] = None
    seed: Optional[OrderByInput] = None
    attacker: Optional[OrderByInput] = None
    fled: Optional[OrderByInput] = None
    damageDealt: Optional[OrderByInput] = None
    criticalHit: Optional[OrderByInput] = None
    damageTaken: Optional[OrderByInput] = None
    damageLocation: Optional[OrderByInput] = None
    xpEarnedAdventurer: Optional[OrderByInput] = None
    xpEarnedItems: Optional[OrderByInput] = None
    goldEarned: Optional[OrderByInput] = None
    txHash: Optional[OrderByInput] = None
    discoveryTime: Optional[OrderByInput] = None
    blockTime: Optional[OrderByInput] = None
    timestamp: Optional[OrderByInput] = None

    def to_dict(self):
        return {
            "adventurerId": self.adventurerId.to_dict() if self.adventurerId else None,
            "adventurerHealth": (
                self.adventurerHealth.to_dict() if self.adventurerHealth else None
            ),
            "beast": self.beast.to_dict() if self.beast else None,
            "beastHealth": self.beastHealth.to_dict() if self.beastHealth else None,
            "beastLevel": self.beastLevel.to_dict() if self.beastLevel else None,
            "special1": self.special1.to_dict() if self.special1 else None,
            "special2": self.special2.to_dict() if self.special2 else None,
            "special3": self.special3.to_dict() if self.special3 else None,
            "seed": self.seed.to_dict() if self.seed else None,
            "attacker": self.attacker.to_dict() if self.attacker else None,
            "fled": self.fled.to_dict() if self.fled else None,
            "damageDealt": self.damageDealt.to_dict() if self.damageDealt else None,
            "criticalHit": self.criticalHit.to_dict() if self.criticalHit else None,
            "damageTaken": self.damageTaken.to_dict() if self.damageTaken else None,
            "damageLocation": (
                self.damageLocation.to_dict() if self.damageLocation else None
            ),
            "xpEarnedAdventurer": (
                self.xpEarnedAdventurer.to_dict() if self.xpEarnedAdventurer else None
            ),
            "xpEarnedItems": (
                self.xpEarnedItems.to_dict() if self.xpEarnedItems else None
            ),
            "goldEarned": self.goldEarned.to_dict() if self.goldEarned else None,
            "txHash": self.txHash.to_dict() if self.txHash else None,
            "discoveryTime": (
                self.discoveryTime.to_dict() if self.discoveryTime else None
            ),
            "blockTime": self.blockTime.to_dict() if self.blockTime else None,
            "timestamp": self.timestamp.to_dict() if self.timestamp else None,
        }


@strawberry.input
class ItemsOrderByInput:
    item: Optional[OrderByInput] = None
    adventurerId: Optional[OrderByInput] = None
    ownerAddress: Optional[OrderByInput] = None
    owner: Optional[OrderByInput] = None
    equipped: Optional[OrderByInput] = None
    slot: Optional[OrderByInput] = None
    tier: Optional[OrderByInput] = None
    type: Optional[OrderByInput] = None
    greatness: Optional[OrderByInput] = None
    purchasedTime: Optional[OrderByInput] = None
    special1: Optional[OrderByInput] = None
    special2: Optional[OrderByInput] = None
    special3: Optional[OrderByInput] = None
    xp: Optional[OrderByInput] = None
    isAvailable: Optional[OrderByInput] = None
    timestamp: Optional[OrderByInput] = None

    def to_dict(self):
        return {
            "item": self.item.to_dict() if self.item else None,
            "adventurerId": self.adventurerId.to_dict() if self.adventurerId else None,
            "ownerAddress": self.ownerAddress.to_dict() if self.ownerAddress else None,
            "owner": self.owner.to_dict() if self.owner else None,
            "equipped": self.equipped.to_dict() if self.equipped else None,
            "slot": self.slot.to_dict() if self.slot else None,
            "tier": self.tier.to_dict() if self.tier else None,
            "type": self.type.to_dict() if self.type else None,
            "greatness": self.greatness.to_dict() if self.greatness else None,
            "purchasedTime": (
                self.purchasedTime.to_dict() if self.purchasedTime else None
            ),
            "special1": self.special1.to_dict() if self.special1 else None,
            "special2": self.special2.to_dict() if self.special2 else None,
            "special3": self.special3.to_dict() if self.special3 else None,
            "xp": self.xp.to_dict() if self.xp else None,
            "isAvailable": self.isAvailable.to_dict() if self.isAvailable else None,
            "timestamp": self.timestamp.to_dict() if self.timestamp else None,
        }


@strawberry.type
class Adventurer:
    id: Optional[FeltValue]
    entropy: Optional[HexValue]
    owner: Optional[HexValue]
    name: Optional[StringValue]
    health: Optional[FeltValue]
    strength: Optional[FeltValue]
    dexterity: Optional[FeltValue]
    vitality: Optional[FeltValue]
    intelligence: Optional[FeltValue]
    wisdom: Optional[FeltValue]
    charisma: Optional[FeltValue]
    luck: Optional[FeltValue]
    xp: Optional[FeltValue]
    level: Optional[FeltValue]
    weapon: Optional[ItemValue]
    chest: Optional[ItemValue]
    head: Optional[ItemValue]
    waist: Optional[ItemValue]
    foot: Optional[ItemValue]
    hand: Optional[ItemValue]
    neck: Optional[ItemValue]
    ring: Optional[ItemValue]
    beastHealth: Optional[FeltValue]
    statUpgrades: Optional[FeltValue]
    birthDate: Optional[str]
    deathDate: Optional[str]
    goldenTokenId: Optional[FeltValue]
    customRenderer: Optional[FeltValue]
    battleActionCount: Optional[FeltValue]
    gold: Optional[FeltValue]
    createdTime: Optional[str]
    lastUpdatedTime: Optional[str]
    timestamp: Optional[str]

    @classmethod
    def from_mongo(cls, data):
        return cls(
            id=data["id"],
            entropy=data["entropy"],
            owner=data["owner"],
            name=data["name"],
            health=data["health"],
            strength=data["strength"],
            dexterity=data["dexterity"],
            vitality=data["vitality"],
            intelligence=data["intelligence"],
            wisdom=data["wisdom"],
            charisma=data["charisma"],
            luck=data["luck"],
            xp=data["xp"],
            level=data["level"],
            weapon=data["weapon"],
            chest=data["chest"],
            head=data["head"],
            waist=data["waist"],
            foot=data["foot"],
            hand=data["hand"],
            neck=data["neck"],
            ring=data["ring"],
            beastHealth=data["beastHealth"],
            statUpgrades=data["statUpgrades"],
            birthDate=data["birthDate"],
            deathDate=data["deathDate"],
            goldenTokenId=data["goldenTokenId"],
            customRenderer=data["customRenderer"],
            battleActionCount=data["battleActionCount"],
            gold=data["gold"],
            createdTime=data["createdTime"],
            lastUpdatedTime=data["lastUpdatedTime"],
            timestamp=data["timestamp"],
        )


@strawberry.type
class Score:
    adventurerId: Optional[FeltValue]
    timestamp: Optional[str]
    totalPayout: Optional[U256Value]

    @classmethod
    def from_mongo(cls, data):
        return cls(
            adventurerId=data["adventurerId"],
            timestamp=data["timestamp"],
            totalPayout=data["totalPayout"],
        )


@strawberry.type
class Discovery:
    adventurerId: Optional[FeltValue]
    adventurerHealth: Optional[FeltValue]
    discoveryType: Optional[DiscoveryValue]
    subDiscoveryType: Optional[SubDiscoveryValue]
    outputAmount: Optional[FeltValue]
    obstacle: Optional[ObstacleValue]
    obstacleLevel: Optional[FeltValue]
    dodgedObstacle: Optional[bool]
    damageTaken: Optional[FeltValue]
    damageLocation: Optional[SlotValue]
    xpEarnedAdventurer: Optional[FeltValue]
    xpEarnedItems: Optional[FeltValue]
    entity: Optional[BeastValue]
    entityLevel: Optional[FeltValue]
    entityHealth: Optional[FeltValue]
    special1: Optional[Special1Value]
    special2: Optional[Special2Value]
    special3: Optional[Special3Value]
    ambushed: Optional[bool]
    discoveryTime: Optional[str]
    timestamp: Optional[str]
    seed: Optional[HexValue]
    txHash: Optional[HexValue]

    @classmethod
    def from_mongo(cls, data):
        return cls(
            adventurerId=data["adventurerId"],
            adventurerHealth=data["adventurerHealth"],
            discoveryType=data["discoveryType"],
            subDiscoveryType=data["subDiscoveryType"],
            outputAmount=data["outputAmount"],
            obstacle=data["obstacle"],
            obstacleLevel=data["obstacleLevel"],
            dodgedObstacle=data["dodgedObstacle"],
            damageTaken=data["damageTaken"],
            damageLocation=data["damageLocation"],
            xpEarnedAdventurer=data["xpEarnedAdventurer"],
            xpEarnedItems=data["xpEarnedItems"],
            entity=data["entity"],
            entityLevel=data["entityLevel"],
            entityHealth=data["entityHealth"],
            special1=data["special1"],
            special2=data["special2"],
            special3=data["special3"],
            ambushed=data["ambushed"],
            discoveryTime=data["discoveryTime"],
            timestamp=data["timestamp"],
            seed=data["seed"],
            txHash=data["txHash"],
        )


@strawberry.type
class Beast:
    beast: Optional[BeastValue] = None
    adventurerId: Optional[FeltValue] = None
    seed: Optional[HexValue] = None
    special1: Optional[Special1Value] = None
    special2: Optional[Special2Value] = None
    special3: Optional[Special3Value] = None
    health: Optional[FeltValue] = None
    level: Optional[FeltValue] = None
    tier: Optional[FeltValue] = None
    slainOnTime: Optional[str] = None
    createdTime: Optional[str] = None
    lastUpdatedTime: Optional[str] = None
    timestamp: Optional[str] = None

    @classmethod
    def from_mongo(cls, data):
        return cls(
            beast=data["beast"],
            adventurerId=data["adventurerId"],
            seed=data["seed"],
            special1=data["special1"],
            special2=data["special2"],
            special3=data["special3"],
            health=data["health"],
            level=data["level"],
            tier=data["tier"],
            slainOnTime=data["slainOnTime"],
            createdTime=data["createdTime"],
            lastUpdatedTime=data["lastUpdatedTime"],
            timestamp=data["timestamp"],
        )


@strawberry.type
class Battle:
    adventurerId: Optional[FeltValue]
    adventurerHealth: Optional[FeltValue]
    beast: Optional[BeastValue]
    beastHealth: Optional[FeltValue]
    beastLevel: Optional[FeltValue]
    special1: Optional[Special1Value]
    special2: Optional[Special2Value]
    special3: Optional[Special3Value]
    seed: Optional[HexValue]
    attacker: Optional[AttackerValue]
    fled: Optional[bool]
    damageDealt: Optional[FeltValue]
    criticalHit: Optional[bool]
    damageTaken: Optional[FeltValue]
    damageLocation: Optional[SlotValue]
    xpEarnedAdventurer: Optional[FeltValue]
    xpEarnedItems: Optional[FeltValue]
    goldEarned: Optional[FeltValue]
    txHash: Optional[HexValue]
    discoveryTime: Optional[str]
    blockTime: Optional[str]
    timestamp: Optional[str]

    @classmethod
    def from_mongo(cls, data):
        return cls(
            adventurerId=data["adventurerId"],
            adventurerHealth=data["adventurerHealth"],
            beast=data["beast"],
            beastHealth=data["beastHealth"],
            beastLevel=data["beastLevel"],
            special1=data["special1"],
            special2=data["special2"],
            special3=data["special3"],
            seed=data["seed"],
            attacker=data["attacker"],
            fled=data["fled"],
            damageDealt=data["damageDealt"],
            criticalHit=data["criticalHit"],
            damageTaken=data["damageTaken"],
            damageLocation=data["damageLocation"],
            xpEarnedAdventurer=data["xpEarnedAdventurer"],
            xpEarnedItems=data["xpEarnedItems"],
            goldEarned=data["goldEarned"],
            txHash=data["txHash"],
            discoveryTime=data["discoveryTime"],
            blockTime=data["blockTime"],
            timestamp=data["timestamp"],
        )


@strawberry.type
class DiscoveryOrBattle:
    type: str
    timestamp: str
    data: Union[Discovery, Battle]

    @classmethod
    def from_discovery(cls, discovery: Discovery):
        return cls(type="Discovery", timestamp=discovery.timestamp, data=discovery)

    @classmethod
    def from_battle(cls, battle: Battle):
        return cls(type="Battle", timestamp=battle.timestamp, data=battle)


class CustomJSONEncoder(json.JSONEncoder):
    def default(self, obj: Any) -> Any:
        if isinstance(obj, (Discovery, Battle, DiscoveryOrBattle)):
            return obj.__dict__
        return super().default(obj)


@strawberry.type
class Item:
    item: Optional[ItemValue]
    adventurerId: Optional[FeltValue]
    ownerAddress: Optional[HexValue]
    owner: Optional[bool]
    equipped: Optional[bool]
    tier: Optional[ItemTierValue]
    slot: Optional[SlotValue]
    type: Optional[ItemTypeValue]
    greatness: Optional[FeltValue]
    purchasedTime: Optional[str]
    special1: Optional[Special1Value]
    special2: Optional[Special2Value]
    special3: Optional[Special3Value]
    xp: Optional[FeltValue]
    isAvailable: Optional[bool]
    timestamp: Optional[str]

    @classmethod
    def from_mongo(cls, data):
        return cls(
            item=data["item"],
            adventurerId=data["adventurerId"],
            ownerAddress=data["ownerAddress"],
            owner=data["owner"],
            equipped=data["equipped"],
            tier=data["tier"],
            slot=data["slot"],
            type=data["type"],
            greatness=data["greatness"],
            purchasedTime=data["purchasedTime"],
            special1=data["special1"],
            special2=data["special2"],
            special3=data["special3"],
            xp=data["xp"],
            isAvailable=data["isAvailable"],
            timestamp=data["timestamp"],
        )


@strawberry.type
class AdventurerRank:
    adventurer_id: str
    xp: int
    rank: int
    total_adventurers: int


def get_str_filters(where: StringFilter) -> List[Dict]:
    filter = {}
    if where.eq is not None:
        filter["$eq"] = where.eq
    if where._in:
        filter["$in"] = where._in
    if where.notIn:
        filter["$nin"] = where.notIn
    if where.lt is not None:
        filter["$lt"] = where.lt
    if where.lte is not None:
        filter["$lte"] = where.lte
    if where.gt is not None:
        filter["$gt"] = where.gt
    if where.gte is not None:
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
    if where.eq is not None:
        filter["$eq"] = where.eq
    if where._in:
        filter["$in"] = where._in
    if where.notIn:
        filter["$nin"] = where.notIn
    if where.lt is not None:
        filter["$lt"] = where.lt
    if where.lte is not None:
        filter["$lte"] = where.lte
    if where.gt is not None:
        filter["$gt"] = where.gt
    if where.gte is not None:
        filter["$gte"] = where.gte

    return filter


def get_hex_filters(where: HexValueFilter) -> List[Dict]:
    filter = {}
    if where.eq is not None:
        filter["$eq"] = where.eq
    if where._in:
        filter["$in"] = where._in
    if where.notIn:
        filter["$nin"] = where.notIn
    if where.lt is not None:
        filter["$lt"] = where.lt
    if where.lte is not None:
        filter["$lte"] = where.lte
    if where.gt is not None:
        filter["$gt"] = where.gt
    if where.gte is not None:
        filter["$gte"] = where.gte

    return filter


def get_date_filters(where: DateTimeFilter) -> List[Dict]:
    filter = {}
    if where.eq is not None:
        filter["$eq"] = where.eq
    if where._in:
        filter["$in"] = where._in
    if where.notIn:
        filter["$nin"] = where.notIn
    if where.lt is not None:
        filter["$lt"] = where.lt
    if where.lte is not None:
        filter["$lte"] = where.lte
    if where.gt is not None:
        filter["$gt"] = where.gt
    if where.gte is not None:
        filter["$gte"] = where.gte

    return filter


def get_bool_filters(where: BooleanFilter) -> List[Dict]:
    filter = {}
    if where.eq is not None:
        filter["$eq"] = where.eq
    return filter


def process_filters(obj, prefix=None):
    filters = {}
    for key, value in obj.__dict__.items():
        if value is not None:
            filter_key = f"{prefix}.{key}" if prefix else key
            filters[filter_key] = value
    return filters


async def get_adventurers(
    info: Info,
    where: Optional[AdventurersFilter] = {},
    limit: Optional[int] = 10,
    skip: Optional[int] = 0,
    orderBy: Optional[AdventurersOrderByInput] = {},
) -> List[Adventurer]:
    # Enforce the maximum limit
    if limit is None or limit > MAX_DOCUMENT_LIMIT:
        limit = MAX_DOCUMENT_LIMIT

    db = info.context["db"]
    redis = info.context["redis"]

    # Convert custom filter objects to dictionaries
    where_dict = where.to_dict() if where else {}
    orderBy_dict = orderBy.to_dict() if orderBy else {}

    # Create a unique cache key based on the query parameters
    cache_key = f"adventurers:{json.dumps(where_dict)}:{limit}:{skip}:{json.dumps(orderBy_dict)}"
    cached_result = await redis.get(cache_key)

    cached_result = await redis.get(cache_key)
    if cached_result:
        cached_result = cached_result.decode("utf-8")  # Decode the byte string
        return [Adventurer.from_mongo(item) for item in json.loads(cached_result)]

    filter = {"_cursor.to": None}

    if where:
        processed_filters = process_filters(where)
        for key, value in processed_filters.items():
            if (
                isinstance(value, StringFilter)
                | isinstance(value, ClassFilter)
                | isinstance(value, AdventurerStatusFilter)
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
        if getattr(
            value, "asc", False
        ):  # Use getattr to safely access attribute and provide a default value
            sort_var = key
            sort_dir = 1
            break
        if getattr(
            value, "desc", False
        ):  # Use getattr to safely access attribute and provide a default value
            sort_var = key
            sort_dir = -1
            break

    query = (
        db["adventurers"].find(filter).skip(skip).limit(limit).sort(sort_var, sort_dir)
    )

    result = [Adventurer.from_mongo(t) for t in query]

    # Cache the result
    await redis.set(cache_key, json.dumps([item.__dict__ for item in result]), ex=60)

    return result


async def get_scores(
    info,
    where: Optional[ScoresFilter] = {},
    limit: Optional[int] = 10,
    skip: Optional[int] = 0,
    orderBy: Optional[ScoresOrderByInput] = {},
) -> List[Score]:
    db = info.context["db"]
    redis = info.context["redis"]

    # Convert custom filter objects to dictionaries
    where_dict = where.to_dict() if where else {}
    orderBy_dict = orderBy.to_dict() if orderBy else {}

    # Create a unique cache key based on the query parameters
    cache_key = (
        f"scores:{json.dumps(where_dict)}:{limit}:{skip}:{json.dumps(orderBy_dict)}"
    )
    cached_result = await redis.get(cache_key)

    if cached_result:
        cached_result = cached_result.decode("utf-8")  # Decode the byte string
        return [Score.from_mongo(item) for item in json.loads(cached_result)]

    filter = {"_cursor.to": None}

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
            elif isinstance(value, U256ValueFilter):
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

    query = db["scores"].find(filter).skip(skip).limit(limit).sort(sort_var, sort_dir)

    result = [Score.from_mongo(t) for t in query]

    # Cache the result
    await redis.set(cache_key, json.dumps([item.__dict__ for item in result]), ex=60)

    return result


async def get_discoveries(
    info,
    where: Optional[DiscoveriesFilter] = {},
    limit: Optional[int] = 10,
    skip: Optional[int] = 0,
    orderBy: Optional[DiscoveriesOrderByInput] = {},
) -> List[Discovery]:
    db = info.context["db"]
    redis = info.context["redis"]

    # Convert custom filter objects to dictionaries
    where_dict = where.to_dict() if where else {}
    orderBy_dict = orderBy.to_dict() if orderBy else {}

    # Create a unique cache key based on the query parameters
    cache_key = f"discoveries:{json.dumps(where_dict)}:{limit}:{skip}:{json.dumps(orderBy_dict)}"
    cached_result = await redis.get(cache_key)

    if cached_result:
        cached_result = cached_result.decode("utf-8")  # Decode the byte string
        return [Discovery.from_mongo(item) for item in json.loads(cached_result)]

    filter = {"cursor.to": None}

    if where:
        processed_filters = process_filters(where)
        for key, value in processed_filters.items():
            if (
                isinstance(value, StringFilter)
                | isinstance(value, DiscoveryFilter)
                | isinstance(value, SubDiscoveryFilter)
                | isinstance(value, SlotFilter)
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

    result = [Discovery.from_mongo(t) for t in query]

    # Cache the result
    await redis.set(cache_key, json.dumps([item.__dict__ for item in result]), ex=60)

    return result


async def get_beasts(
    info,
    where: Optional[BeastsFilter] = {},
    limit: Optional[int] = 10,
    skip: Optional[int] = 0,
    orderBy: Optional[BeastsOrderByInput] = {},
) -> List[Discovery]:
    db = info.context["db"]
    redis = info.context["redis"]

    # Convert custom filter objects to dictionaries
    where_dict = where.to_dict() if where else {}
    orderBy_dict = orderBy.to_dict() if orderBy else {}

    # Create a unique cache key based on the query parameters
    cache_key = (
        f"beasts:{json.dumps(where_dict)}:{limit}:{skip}:{json.dumps(orderBy_dict)}"
    )
    cached_result = await redis.get(cache_key)

    if cached_result:
        cached_result = cached_result.decode("utf-8")  # Decode the byte string
        return [Beast.from_mongo(item) for item in json.loads(cached_result)]

    filter = {"_cursor.to": None}

    if where:
        processed_filters = process_filters(where)
        for key, value in processed_filters.items():
            if (
                isinstance(value, StringFilter)
                | isinstance(value, BeastFilter)
                | isinstance(value, Special1Filter)
                | isinstance(value, Special2Filter)
                | isinstance(value, Special3Filter)
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

    result = [Beast.from_mongo(t) for t in query]

    # Cache the result
    await redis.set(cache_key, json.dumps([item.__dict__ for item in result]), ex=60)

    return result


async def get_battles(
    info,
    where: Optional[BattlesFilter] = {},
    limit: Optional[int] = 10,
    skip: Optional[int] = 0,
    orderBy: Optional[BattlesOrderByInput] = {},
) -> List[Battle]:
    db = info.context["db"]
    redis = info.context["redis"]

    # Convert custom filter objects to dictionaries
    where_dict = where.to_dict() if where else {}
    orderBy_dict = orderBy.to_dict() if orderBy else {}

    # Create a unique cache key based on the query parameters
    cache_key = (
        f"battles:{json.dumps(where_dict)}:{limit}:{skip}:{json.dumps(orderBy_dict)}"
    )
    cached_result = await redis.get(cache_key)

    if cached_result:
        cached_result = cached_result.decode("utf-8")  # Decode the byte string
        return [Battle.from_mongo(item) for item in json.loads(cached_result)]

    filter = {"_cursor.to": None}

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

    result = [Battle.from_mongo(t) for t in query]

    # Cache the result
    await redis.set(cache_key, json.dumps([item.__dict__ for item in result]), ex=60)

    return result


async def get_items(
    info,
    where: Optional[ItemsFilter] = {},
    limit: Optional[int] = 10,
    skip: Optional[int] = 0,
    orderBy: Optional[ItemsOrderByInput] = {},
) -> List[Item]:
    db = info.context["db"]
    redis = info.context["redis"]

    # Convert custom filter objects to dictionaries
    where_dict = where.to_dict() if where else {}
    orderBy_dict = orderBy.to_dict() if orderBy else {}

    # Create a unique cache key based on the query parameters
    cache_key = (
        f"items:{json.dumps(where_dict)}:{limit}:{skip}:{json.dumps(orderBy_dict)}"
    )
    cached_result = await redis.get(cache_key)

    if cached_result:
        cached_result = cached_result.decode("utf-8")  # Decode the byte string
        return [Item.from_mongo(item) for item in json.loads(cached_result)]

    filter = {"_cursor.to": None}

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

    query = db["items"].find(filter).skip(skip).limit(limit).sort(sort_var, sort_dir)

    result = [Item.from_mongo(t) for t in query]

    # Cache the result
    await redis.set(cache_key, json.dumps([item.__dict__ for item in result]), ex=60)

    return result


async def get_discoveries_and_battles(
    info,
    where: Optional[ItemsFilter] = {},
    limit: int = 10,
    skip: int = 0,
) -> List[DiscoveryOrBattle]:
    db = info.context["db"]
    redis = info.context["redis"]

    # Convert custom filter objects to dictionaries
    where_dict = where.to_dict() if where else {}

    # Create a unique cache key based on the query parameters
    cache_key = f"discoveries_and_battles:{json.dumps(where_dict)}:{limit}:{skip}"
    cached_result = await redis.get(cache_key)

    if cached_result:
        cached_result = cached_result.decode("utf-8")  # Decode the byte string
        deserialized = json.loads(cached_result)
        return [
            DiscoveryOrBattle(
                type=item["type"],
                timestamp=item["timestamp"],
                data=(
                    Discovery.from_mongo(item["data"])
                    if item["type"] == "Discovery"
                    else Battle.from_mongo(item["data"])
                ),
            )
            for item in deserialized
        ]

    filter = {"_cursor.to": None}

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
            elif isinstance(value, BooleanFilter):
                filter[key] = get_bool_filters(value)

    # Pipeline for discoveries
    discoveries_pipeline = [
        {"$match": filter},
        {"$addFields": {"type": "Discovery"}},
        {"$project": {"_id": 0, "type": 1, "timestamp": 1, "data": "$$ROOT"}},
        {"$sort": {"timestamp": -1}},
    ]

    # Pipeline for battles
    battles_pipeline = [
        {"$match": filter},
        {"$addFields": {"type": "Battle"}},
        {"$project": {"_id": 0, "type": 1, "timestamp": 1, "data": "$$ROOT"}},
        {"$sort": {"timestamp": -1}},
    ]

    # Run aggregations
    discoveries = list(db["discoveries"].aggregate(discoveries_pipeline))
    battles = list(db["battles"].aggregate(battles_pipeline))

    # Combine and sort results
    combined = sorted(discoveries + battles, key=lambda x: x["timestamp"], reverse=True)

    # Apply skip and limit
    paginated = combined[skip : skip + limit]

    # Convert the result to DiscoveryOrBattle objects
    converted_result = [
        DiscoveryOrBattle(
            type=item["type"],
            timestamp=item["timestamp"],
            data=(
                Discovery.from_mongo(item["data"])
                if item["type"] == "Discovery"
                else Battle.from_mongo(item["data"])
            ),
        )
        for item in paginated
    ]

    # Cache the result
    await redis.set(
        cache_key,
        json.dumps(converted_result, cls=CustomJSONEncoder),
        ex=60,
    )

    return converted_result


async def count_adventurers_with_zero_health(info) -> int:
    redis = info.context["redis"]
    cache_key = "count_adventurers_with_zero_health"

    # Check if the result is in the cache
    cached_count = await redis.get(cache_key)
    if cached_count is not None:
        return int(cached_count)

    # If not in cache, query the database
    db = info.context["db"]
    filter = {"_cursor.to": None}
    count = db["adventurers"].count_documents({**filter, "health": {"$eq": 0}})

    # Store the result in the cache
    await redis.set(cache_key, count, ex=60)  # Set an expiration time of 60 seconds

    return count


async def count_adventurers_with_positive_health(
    info, owner: Optional[HexValue] = None
) -> int:
    redis = info.context["redis"]

    filter = {"_cursor.to": None}

    # Add adventurerId to the filter if provided
    if owner:
        filter["owner"] = {"$eq": owner}

    cache_key = f"count_adventurers_with_positive_health:{json.dumps(filter)}"

    # Check if the result is in the cache
    cached_count = await redis.get(cache_key)
    if cached_count is not None:
        return int(cached_count)

    # If not in cache, query the database
    db = info.context["db"]
    count = db["adventurers"].count_documents({**filter, "health": {"$gt": 0}})

    # Store the result in the cache
    await redis.set(cache_key, count, ex=60)  # Set an expiration time of 60 seconds

    return count


async def count_total_adventurers(info, owner: Optional[HexValue] = None) -> int:
    redis = info.context["redis"]

    filter = {"_cursor.to": None}

    # Add adventurerId to the filter if provided
    if owner:
        filter["owner"] = {"$eq": owner}

    cache_key = f"count_total_adventurers:{json.dumps(filter)}"

    # Check if the result is in the cache
    cached_count = await redis.get(cache_key)
    if cached_count is not None:
        return int(cached_count)

    # If not in cache, query the database
    db = info.context["db"]
    count = db["adventurers"].count_documents({**filter})

    # Store the result in the cache
    await redis.set(cache_key, count, ex=60)  # Set an expiration time of 60 seconds

    return count


async def count_total_discoveries_and_battles(
    info, adventurerId: Optional[int] = None
) -> int:
    redis = info.context["redis"]
    # If not in cache, query the database
    db = info.context["db"]
    filter = {"_cursor.to": None}

    # Add adventurerId to the filter if provided
    if adventurerId:
        filter["adventurerId"] = {"$eq": adventurerId}

    cache_key = f"count_total_discoveries_and_battles:{json.dumps(filter)}"

    # Check if the result is in the cache
    cached_count = await redis.get(cache_key)
    if cached_count is not None:
        return int(cached_count)

    discoveries_count = db["discoveries"].count_documents({**filter})
    battles_count = db["battles"].count_documents({**filter})

    total_count = discoveries_count + battles_count

    # Store the result in the cache
    await redis.set(
        cache_key, total_count, ex=60
    )  # Set an expiration time of 60 seconds

    return total_count


async def get_adventurer_rank(
    info, adventurer_id: int, adventurer_xp: int
) -> Optional[AdventurerRank]:
    db = info.context["db"]
    redis = info.context["redis"]

    # Try to get the rank from cache
    cache_key = f"adventurer_rank:{adventurer_id}"
    cached_rank = await redis.get(cache_key)
    if cached_rank:
        return AdventurerRank(**json.loads(cached_rank))

    # If not in cache, calculate the rank
    pipeline = [
        {
            "$match": {
                "_cursor.to": None,  # Only consider current adventurers
                "health": 0,  # Filter adventurers with health equal 0
            }
        },
        {
            "$group": {
                "_id": None,
                "total": {"$sum": 1},
                "rank": {"$sum": {"$cond": [{"$gt": ["$xp", adventurer_xp]}, 1, 0]}},
            }
        },
        {
            "$project": {
                "_id": 0,
                "adventurer_id": {"$literal": adventurer_id},
                "xp": {"$literal": adventurer_xp},
                "rank": {"$add": ["$rank", 1]},  # Add 1 because rank is 1-indexed
                "total_adventurers": "$total",
            }
        },
    ]

    result = list(db["adventurers"].aggregate(pipeline))

    if not result:
        # If no result, it means there are no adventurers with 0 health
        # In this case, we'll return a rank of 1 out of 1
        rank_data = {
            "adventurer_id": adventurer_id,
            "xp": adventurer_xp,
            "rank": 1,
            "total_adventurers": 1,
        }
    else:
        rank_data = result[0]

    adventurer_rank = AdventurerRank(**rank_data)

    # Cache the result
    await redis.set(cache_key, json.dumps(rank_data), ex=300)  # Cache for 5 minutes

    return adventurer_rank


@strawberry.type
class Query:
    adventurers: List[Adventurer] = strawberry.field(resolver=get_adventurers)
    scores: List[Score] = strawberry.field(resolver=get_scores)
    beasts: List[Beast] = strawberry.field(resolver=get_beasts)
    discoveries: List[Discovery] = strawberry.field(resolver=get_discoveries)
    battles: List[Battle] = strawberry.field(resolver=get_battles)
    discoveriesAndBattles: List[DiscoveryOrBattle] = strawberry.field(
        resolver=get_discoveries_and_battles
    )
    items: List[Item] = strawberry.field(resolver=get_items)
    countDeadAdventurers: int = strawberry.field(
        resolver=count_adventurers_with_zero_health
    )
    countAliveAdventurers: int = strawberry.field(
        resolver=count_adventurers_with_positive_health
    )
    countTotalAdventurers: int = strawberry.field(resolver=count_total_adventurers)
    countDiscoveriesAndBattles: int = strawberry.field(
        resolver=count_total_discoveries_and_battles
    )
    adventurerRank: Optional[AdventurerRank] = strawberry.field(
        resolver=get_adventurer_rank
    )


class IndexerGraphQLView(GraphQLView):
    def __init__(self, db, redis, api_key, **kwargs):
        super().__init__(**kwargs)
        self._db = db
        self._redis = redis
        self._api_key = api_key

    async def get_context(self, request, _response):
        # api_key = request.headers.get("X-API-Key")
        # if api_key != self._api_key:
        #     raise web.HTTPUnauthorized(reason="Invalid API Key")

        return {"db": self._db, "redis": self._redis, "max_limit": MAX_DOCUMENT_LIMIT}


async def run_graphql_api(
    mongo=None,
    redis_url="redis://redis",
    port="8080",
    allowed_origins=["http://localhost:3000"],
    api_key=None,
):
    mongo = MongoClient(mongo)
    db_name = "mongo".replace("-", "_")
    db = mongo[db_name]

    redis = await aioredis.from_url(redis_url)

    schema = strawberry.Schema(query=Query)
    view = IndexerGraphQLView(db, redis, api_key, schema=schema)

    app = web.Application()

    # Setup CORS with the specific origin
    cors = aiohttp_cors.setup(
        app,
        defaults={
            origin: aiohttp_cors.ResourceOptions(
                allow_credentials=True,
                expose_headers="*",
                allow_headers="*",
                allow_methods=["POST", "GET"],
            )
            for origin in allowed_origins
        },
    )

    resource = cors.add(app.router.add_resource("/graphql"))
    cors.add(resource.add_route("POST", view))
    cors.add(resource.add_route("GET", view))

    runner = web.AppRunner(app)
    await runner.setup()

    ssl_context = ssl.create_default_context(ssl.Purpose.CLIENT_AUTH)
    ssl_context.load_cert_chain(
        "/etc/letsencrypt/live/ls-katana.provable.games/fullchain.pem",
        "/etc/letsencrypt/live/ls-katana.provable.games/privkey.pem",
    )

    site = web.TCPSite(runner, "0.0.0.0", int(port), ssl_context=ssl_context)
    await site.start()

    print(f"GraphQL server started on port {port}")

    while True:
        await asyncio.sleep(5_000)
