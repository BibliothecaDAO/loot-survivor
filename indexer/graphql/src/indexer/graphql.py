import asyncio
from typing import List, NewType, Optional, Dict
import base64
import ssl
import json

import strawberry
import aiohttp_cors
from aiohttp import web
import aioredis
from pymongo import MongoClient
from strawberry.aiohttp.views import GraphQLView
from indexer.utils import felt_to_str, str_to_felt, get_key_by_value
from indexer.config import Config

config = Config()


def parse_u256(value):
    return value * (10**18)


def serialize_u256(value):
    return value / (10**18)


def parse_hex(value):
    if not value.startswith("0x"):
        raise ValueError("invalid Hex value")
    bytesValue = bytes.fromhex(value.replace("0x", ""))
    return base64.b64encode(bytesValue).decode("utf-8")


def serialize_hex(value):
    bytes = base64.b64decode(value)
    return "0x" + bytes.hex()


def parse_felt(value):
    bytes = value.to_bytes(32, "big")
    return base64.b64encode(bytes).decode("utf-8")


def serialize_felt(value):
    bytes = base64.b64decode(value)
    return int.from_bytes(bytes, "big")


def parse_string(value):
    bytes = value.encode("utf-8")
    return base64.b64encode(bytes).decode("utf-8")


def serialize_string(value):
    bytes = base64.b64decode(value)
    return bytes.decode("utf-8").replace("\u0000", "")


def parse_class(value):
    felt = get_key_by_value(value, config.CLASSES)
    bytes = felt.to_bytes(32, "big")
    return base64.b64encode(bytes).decode("utf-8")


def serialize_class(value):
    bytes = base64.b64decode(value)
    felt = int.from_bytes(bytes, "big")
    return config.CLASSES.get(felt)


def parse_beast(value):
    felt = get_key_by_value(value, config.BEASTS)
    bytes = felt.to_bytes(32, "big")
    return base64.b64encode(bytes).decode("utf-8")


def serialize_beast(value):
    bytes = base64.b64decode(value)
    felt = int.from_bytes(bytes, "big")
    return config.BEASTS.get(felt)


def parse_adventurer_status(value):
    felt = get_key_by_value(value, config.ADVENTURER_STATUS)
    bytes = felt.to_bytes(32, "big")
    return base64.b64encode(bytes).decode("utf-8")


def serialize_adventurer_status(value):
    bytes = base64.b64decode(value)
    felt = int.from_bytes(bytes, "big")
    return config.ADVENTURER_STATUS.get(felt)


def parse_discovery(value):
    felt = get_key_by_value(value, config.DISCOVERY_TYPES)
    bytes = felt.to_bytes(32, "big")
    return base64.b64encode(bytes).decode("utf-8")


def serialize_discovery(value):
    bytes = base64.b64decode(value)
    felt = int.from_bytes(bytes, "big")
    return config.DISCOVERY_TYPES.get(felt)


def parse_sub_discovery(value):
    felt = get_key_by_value(value, config.SUB_DISCOVERY_TYPES)
    bytes = felt.to_bytes(32, "big")
    return base64.b64encode(bytes).decode("utf-8")


def serialize_sub_discovery(value):
    bytes = base64.b64decode(value)
    felt = int.from_bytes(bytes, "big")
    return config.SUB_DISCOVERY_TYPES.get(felt)


def parse_obstacle(value):
    felt = get_key_by_value(value, config.OBSTACLES)
    bytes = felt.to_bytes(32, "big")
    return base64.b64encode(bytes).decode("utf-8")


def serialize_obstacle(value):
    bytes = base64.b64decode(value)
    felt = int.from_bytes(bytes, "big")
    return config.OBSTACLES.get(felt)


def parse_attacker(value):
    felt = get_key_by_value(value, config.ATTACKERS)
    bytes = felt.to_bytes(32, "big")
    return base64.b64encode(bytes).decode("utf-8")


def serialize_attacker(value):
    bytes = base64.b64decode(value)
    felt = int.from_bytes(bytes, "big")
    return config.ATTACKERS.get(felt)


def parse_item(value):
    felt = get_key_by_value(value, config.ITEMS)
    bytes = felt.to_bytes(32, "big")
    return base64.b64encode(bytes).decode("utf-8")


def serialize_item(value):
    bytes = base64.b64decode(value)
    felt = int.from_bytes(bytes, "big")
    return config.ITEMS.get(felt)


def parse_material(value):
    felt = get_key_by_value(value, config.MATERIALS)
    bytes = felt.to_bytes(32, "big")
    return base64.b64encode(bytes).decode("utf-8")


def serialize_material(value):
    bytes = base64.b64decode(value)
    felt = int.from_bytes(bytes, "big")
    return config.MATERIALS.get(felt)


def parse_item_type(value):
    felt = get_key_by_value(value, config.ITEM_TYPES)
    return felt.to_bytes(32, "big")


def serialize_item_type(value):
    felt = int.from_bytes(value, "big")
    return config.ITEM_TYPES.get(felt)


def parse_special_2(value):
    felt = get_key_by_value(value, config.ITEM_NAME_PREFIXES)
    bytes = felt.to_bytes(32, "big")
    return base64.b64encode(bytes).decode("utf-8")


def serialize_special_2(value):
    bytes = base64.b64decode(value)
    felt = int.from_bytes(bytes, "big")
    return config.ITEM_NAME_PREFIXES.get(felt)


def parse_special_3(value):
    felt = get_key_by_value(value, config.ITEM_NAME_SUFFIXES)
    bytes = felt.to_bytes(32, "big")
    return base64.b64encode(bytes).decode("utf-8")


def serialize_special_3(value):
    bytes = base64.b64decode(value)
    felt = int.from_bytes(bytes, "big")
    return config.ITEM_NAME_SUFFIXES.get(felt)


def parse_special_1(value):
    felt = get_key_by_value(value, config.ITEM_SUFFIXES)
    bytes = felt.to_bytes(32, "big")
    return base64.b64encode(bytes).decode("utf-8")


def serialize_special_1(value):
    bytes = base64.b64decode(value)
    felt = int.from_bytes(bytes, "big")
    return config.ITEM_SUFFIXES.get(felt)


def parse_item_status(value):
    felt = get_key_by_value(value, config.ITEM_STATUS)
    bytes = felt.to_bytes(32, "big")
    return base64.b64encode(bytes).decode("utf-8")


def serialize_item_status(value):
    bytes = base64.b64decode(value)
    felt = int.from_bytes(bytes, "big")
    return config.ITEM_STATUS.get(felt)


def parse_slot(value):
    felt = get_key_by_value(value, config.SLOTS)
    bytes = felt.to_bytes(32, "big")
    return base64.b64encode(bytes).decode("utf-8")


def serialize_slot(value):
    bytes = base64.b64decode(value)
    felt = int.from_bytes(bytes, "big")
    return config.SLOTS.get(felt)


def parse_adventurer(value):
    felt = get_key_by_value(value, config.ATTACKERS)
    bytes = felt.to_bytes(32, "big")
    return base64.b64encode(bytes).decode("utf-8")


def serialize_adventurer(value):
    bytes = base64.b64decode(value)
    felt = int.from_bytes(bytes, "big")
    return config.ATTACKERS.get(felt)


U256Value = strawberry.scalar(
    NewType("U256Value", bytes), parse_value=parse_u256, serialize=serialize_u256
)


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

ClassValue = strawberry.scalar(
    NewType("ClassValue", bytes), parse_value=parse_class, serialize=serialize_class
)

BeastValue = strawberry.scalar(
    NewType("BeastValue", bytes), parse_value=parse_beast, serialize=serialize_beast
)

AdventurerStatusValue = strawberry.scalar(
    NewType("AdventurerStatusValue", bytes),
    parse_value=parse_adventurer_status,
    serialize=serialize_adventurer_status,
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

Special1Value = strawberry.scalar(
    NewType("Special1Value", bytes),
    parse_value=parse_special_1,
    serialize=serialize_special_1,
)

Special2Value = strawberry.scalar(
    NewType("Special2Value", bytes),
    parse_value=parse_special_2,
    serialize=serialize_special_2,
)

Special3Value = strawberry.scalar(
    NewType("Special3Value", bytes),
    parse_value=parse_special_3,
    serialize=serialize_special_3,
)

StatusValue = strawberry.scalar(
    NewType("StatusValue", bytes),
    parse_value=parse_item_status,
    serialize=serialize_item_status,
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
            "eq": serialize_u256(self.eq) if self.eq else None,
            "_in": [serialize_u256(v) for v in self._in] if self._in else None,
            "notIn": [serialize_u256(v) for v in self.notIn] if self.notIn else None,
            "lt": serialize_u256(self.lt) if self.lt else None,
            "lte": serialize_u256(self.lte) if self.lte else None,
            "gt": serialize_u256(self.gt) if self.gt else None,
            "gte": serialize_u256(self.gte) if self.gte else None,
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
            "eq": serialize_string(self.eq) if self.eq else None,
            "_in": [serialize_string(v) for v in self._in] if self._in else None,
            "notIn": [serialize_string(v) for v in self.notIn] if self.notIn else None,
            "lt": serialize_string(self.lt) if self.lt else None,
            "lte": serialize_string(self.lte) if self.lte else None,
            "gt": serialize_string(self.gt) if self.gt else None,
            "gte": serialize_string(self.gte) if self.gte else None,
            "contains": serialize_string(self.contains) if self.contains else None,
            "startsWith": (
                serialize_string(self.startsWith) if self.startsWith else None
            ),
            "endsWith": serialize_string(self.endsWith) if self.endsWith else None,
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
            "eq": serialize_hex(self.eq) if self.eq else None,
            "_in": [serialize_hex(v) for v in self._in] if self._in else None,
            "notIn": [serialize_hex(v) for v in self.notIn] if self.notIn else None,
            "lt": serialize_hex(self.lt) if self.lt else None,
            "lte": serialize_hex(self.lte) if self.lte else None,
            "gt": serialize_hex(self.gt) if self.gt else None,
            "gte": serialize_hex(self.gte) if self.gte else None,
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
            "eq": serialize_felt(self.eq) if self.eq else None,
            "_in": [serialize_felt(v) for v in self._in] if self._in else None,
            "notIn": [serialize_felt(v) for v in self.notIn] if self.notIn else None,
            "lt": serialize_felt(self.lt) if self.lt else None,
            "lte": serialize_felt(self.lte) if self.lte else None,
            "gt": serialize_felt(self.gt) if self.gt else None,
            "gte": serialize_felt(self.gte) if self.gte else None,
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
            "eq": serialize_class(self.eq) if self.eq else None,
            "_in": [serialize_class(v) for v in self._in] if self._in else None,
            "notIn": [serialize_class(v) for v in self.notIn] if self.notIn else None,
            "lt": serialize_class(self.lt) if self.lt else None,
            "lte": serialize_class(self.lte) if self.lte else None,
            "gt": serialize_class(self.gt) if self.gt else None,
            "gte": serialize_class(self.gte) if self.gte else None,
            "contains": serialize_class(self.contains) if self.contains else None,
            "startsWith": serialize_class(self.startsWith) if self.startsWith else None,
            "endsWith": serialize_class(self.endsWith) if self.endsWith else None,
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
            "eq": serialize_beast(self.eq) if self.eq else None,
            "_in": [serialize_beast(v) for v in self._in] if self._in else None,
            "notIn": [serialize_beast(v) for v in self.notIn] if self.notIn else None,
            "lt": serialize_beast(self.lt) if self.lt else None,
            "lte": serialize_beast(self.lte) if self.lte else None,
            "gt": serialize_beast(self.gt) if self.gt else None,
            "gte": serialize_beast(self.gte) if self.gte else None,
            "contains": serialize_beast(self.contains) if self.contains else None,
            "startsWith": serialize_beast(self.startsWith) if self.startsWith else None,
            "endsWith": serialize_beast(self.endsWith) if self.endsWith else None,
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
            "eq": serialize_adventurer_status(self.eq) if self.eq else None,
            "_in": (
                [serialize_adventurer_status(v) for v in self._in] if self._in else None
            ),
            "notIn": (
                [serialize_adventurer_status(v) for v in self.notIn]
                if self.notIn
                else None
            ),
            "lt": serialize_adventurer_status(self.lt) if self.lt else None,
            "lte": serialize_adventurer_status(self.lte) if self.lte else None,
            "gt": serialize_adventurer_status(self.gt) if self.gt else None,
            "gte": serialize_adventurer_status(self.gte) if self.gte else None,
            "contains": (
                serialize_adventurer_status(self.contains) if self.contains else None
            ),
            "startsWith": (
                serialize_adventurer_status(self.startsWith)
                if self.startsWith
                else None
            ),
            "endsWith": (
                serialize_adventurer_status(self.endsWith) if self.endsWith else None
            ),
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
            "eq": serialize_discovery(self.eq) if self.eq else None,
            "_in": [serialize_discovery(v) for v in self._in] if self._in else None,
            "notIn": (
                [serialize_discovery(v) for v in self.notIn] if self.notIn else None
            ),
            "lt": serialize_discovery(self.lt) if self.lt else None,
            "lte": serialize_discovery(self.lte) if self.lte else None,
            "gt": serialize_discovery(self.gt) if self.gt else None,
            "gte": serialize_discovery(self.gte) if self.gte else None,
            "contains": serialize_discovery(self.contains) if self.contains else None,
            "startsWith": (
                serialize_discovery(self.startsWith) if self.startsWith else None
            ),
            "endsWith": serialize_discovery(self.endsWith) if self.endsWith else None,
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
            "eq": serialize_sub_discovery(self.eq) if self.eq else None,
            "_in": [serialize_sub_discovery(v) for v in self._in] if self._in else None,
            "notIn": (
                [serialize_sub_discovery(v) for v in self.notIn] if self.notIn else None
            ),
            "lt": serialize_sub_discovery(self.lt) if self.lt else None,
            "lte": serialize_sub_discovery(self.lte) if self.lte else None,
            "gt": serialize_sub_discovery(self.gt) if self.gt else None,
            "gte": serialize_sub_discovery(self.gte) if self.gte else None,
            "contains": (
                serialize_sub_discovery(self.contains) if self.contains else None
            ),
            "startsWith": (
                serialize_sub_discovery(self.startsWith) if self.startsWith else None
            ),
            "endsWith": (
                serialize_sub_discovery(self.endsWith) if self.endsWith else None
            ),
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
            "eq": serialize_obstacle(self.eq) if self.eq else None,
            "_in": [serialize_obstacle(v) for v in self._in] if self._in else None,
            "notIn": (
                [serialize_obstacle(v) for v in self.notIn] if self.notIn else None
            ),
            "lt": serialize_obstacle(self.lt) if self.lt else None,
            "lte": serialize_obstacle(self.lte) if self.lte else None,
            "gt": serialize_obstacle(self.gt) if self.gt else None,
            "gte": serialize_obstacle(self.gte) if self.gte else None,
            "contains": serialize_obstacle(self.contains) if self.contains else None,
            "startsWith": (
                serialize_obstacle(self.startsWith) if self.startsWith else None
            ),
            "endsWith": serialize_obstacle(self.endsWith) if self.endsWith else None,
        }


@strawberry.input
class AttackerFilter:
    eq: Optional[AttackerValue] = None

    def to_dict(self):
        return {
            "eq": serialize_attacker(self.eq) if self.eq else None,
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
    startEntropy: Optional[FeltValueFilter] = None
    revealBlock: Optional[FeltValueFilter] = None
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
            "startEntropy": self.startEntropy.to_dict() if self.startEntropy else None,
            "revealBlock": self.revealBlock.to_dict() if self.revealBlock else None,
            "actionsPerBlock": (
                self.actionsPerBlock.to_dict() if self.actionsPerBlock else None
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
    level: Optional[OrderByInput] = None
    strength: Optional[OrderByInput] = None
    dexterity: Optional[OrderByInput] = None
    vitality: Optional[OrderByInput] = None
    intelligence: Optional[OrderByInput] = None
    wisdom: Optional[OrderByInput] = None
    charisma: Optional[OrderByInput] = None
    luck: Optional[OrderByInput] = None
    xp: Optional[OrderByInput] = None
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
    startEntropy: Optional[OrderByInput] = None
    revealBlock: Optional[OrderByInput] = None
    actionsPerBlock: Optional[OrderByInput] = None
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
            "level": self.level.to_dict() if self.level else None,
            "strength": self.strength.to_dict() if self.strength else None,
            "dexterity": self.dexterity.to_dict() if self.dexterity else None,
            "vitality": self.vitality.to_dict() if self.vitality else None,
            "intelligence": self.intelligence.to_dict() if self.intelligence else None,
            "wisdom": self.wisdom.to_dict() if self.wisdom else None,
            "charisma": self.charisma.to_dict() if self.charisma else None,
            "luck": self.luck.to_dict() if self.luck else None,
            "xp": self.xp.to_dict() if self.xp else None,
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
            "startEntropy": self.startEntropy.to_dict() if self.startEntropy else None,
            "revealBlock": self.revealBlock.to_dict() if self.revealBlock else None,
            "actionsPerBlock": (
                self.actionsPerBlock.to_dict() if self.actionsPerBlock else None
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
    startEntropy: Optional[FeltValue]
    revealBlock: Optional[FeltValue]
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
            startEntropy=data["startEntropy"],
            revealBlock=data["revealBlock"],
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
class Item:
    item: Optional[ItemValue]
    adventurerId: Optional[FeltValue]
    ownerAddress: Optional[HexValue]
    owner: Optional[bool]
    equipped: Optional[bool]
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
            purchasedTime=data["purchasedTime"],
            special1=data["special1"],
            special2=data["special2"],
            special3=data["special3"],
            xp=data["xp"],
            isAvailable=data["isAvailable"],
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


async def get_adventurers(
    info,
    where: Optional[AdventurersFilter] = {},
    limit: Optional[int] = 10,
    skip: Optional[int] = 0,
    orderBy: Optional[AdventurersOrderByInput] = {},
) -> List[Adventurer]:
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


@strawberry.type
class Query:
    adventurers: List[Adventurer] = strawberry.field(resolver=get_adventurers)
    scores: List[Score] = strawberry.field(resolver=get_scores)
    discoveries: List[Discovery] = strawberry.field(resolver=get_discoveries)
    beasts: List[Beast] = strawberry.field(resolver=get_beasts)
    battles: List[Battle] = strawberry.field(resolver=get_battles)
    items: List[Item] = strawberry.field(resolver=get_items)


class IndexerGraphQLView(GraphQLView):
    def __init__(self, db, redis, **kwargs):
        super().__init__(**kwargs)
        self._db = db
        self._redis = redis

    async def get_context(self, _request, _response):
        return {"db": self._db, "redis": self._redis}


async def run_graphql_api(mongo=None, redis_url="redis://redis", port="8080"):
    mongo = MongoClient(mongo)
    db_name = "mongo".replace("-", "_")
    db = mongo[db_name]

    redis = await aioredis.from_url(redis_url)

    schema = strawberry.Schema(query=Query)
    view = IndexerGraphQLView(db, redis, schema=schema)

    app = web.Application()

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

    # Comment out with path to your certs if deploying with SSL support
    # ssl_context = ssl.create_default_context(ssl.Purpose.CLIENT_AUTH)
    # ssl_context.load_cert_chain(
    # "/etc/letsencrypt/live/fullchain.pem",
    # "/etc/letsencrypt/live/privkey.pem",
    # )
    # site = web.TCPSite(runner, "0.0.0.0", int(port), ssl_context=ssl_context)

    site = web.TCPSite(runner, "0.0.0.0", int(port))
    await site.start()

    print(f"GraphQL server started on port {port}")

    while True:
        await asyncio.sleep(5_000)
