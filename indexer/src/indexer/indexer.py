import os
import logging
from datetime import datetime

from apibara.indexer import IndexerRunner, IndexerRunnerConfiguration, Info
from apibara.indexer.indexer import IndexerConfiguration
from apibara.protocol.proto.stream_pb2 import Cursor, DataFinality
from apibara.starknet import EventFilter, Filter, StarkNetIndexer, felt
from apibara.starknet.cursor import starknet_cursor
from apibara.starknet.proto.starknet_pb2 import Block
from starknet_py.contract import ContractFunction
from apibara.starknet.proto.types_pb2 import FieldElement

from typing import List

from indexer.config import Config
from indexer.decoder import (
    decode_start_game_event,
    decode_stat_upgrade_event,
    decode_discover_health_event,
    decode_discover_gold_event,
    decode_discover_xp_event,
    decode_discover_obstacle_event,
    decode_discover_beast_event,
    decode_attack_beast_event,
    decode_slayed_beast_event,
    decode_flee_attempt_event,
    decode_purchased_item_event,
    decode_equip_item_event,
    decode_greatness_increased_event,
    decode_item_prefix_discovered_event,
    decode_item_suffix_discovered_event,
    decode_purchased_potion_event,
    decode_new_high_score_event,
    decode_adventurer_died_event,
)
from indexer.utils import (
    felt_to_str,
    str_to_felt,
    check_exists_int,
    check_exists_timestamp,
    encode_int_as_bytes,
    decode_bytes_as_int,
    get_key_by_value,
)

# Print apibara logs
root_logger = logging.getLogger("apibara")
# change to `logging.DEBUG` to print more information
root_logger.setLevel(logging.INFO)
root_logger.addHandler(logging.StreamHandler())


def encode_str_as_bytes(value):
    felt = str_to_felt(value)
    return felt.to_bytes(32, "big")


def encode_hex_as_bytes(value):
    return bytes.fromhex(value.replace("0x", ""))


async def update_adventurer_helper(info: Info, adventurer_state):
    update_adventurer_doc = {
        "id": check_exists_int(adventurer_state["adventurer_id"]),
        "owner": check_exists_int(adventurer_state["owner"]),
        "lastAction": check_exists_int(adventurer_state["adventurer"]["last_action"]),
        "health": encode_int_as_bytes(adventurer_state["adventurer"]["health"]),
        "xp": encode_int_as_bytes(adventurer_state["adventurer"]["xp"]),
        "strength": encode_int_as_bytes(adventurer_state["adventurer"]["strength"]),
        "dexterity": encode_int_as_bytes(adventurer_state["adventurer"]["dexterity"]),
        "vitality": encode_int_as_bytes(adventurer_state["adventurer"]["vitality"]),
        "intelligence": encode_int_as_bytes(
            adventurer_state["adventurer"]["intelligence"]
        ),
        "wisdom": encode_int_as_bytes(adventurer_state["adventurer"]["wisdom"]),
        "charisma": encode_int_as_bytes(adventurer_state["adventurer"]["charisma"]),
        "gold": encode_int_as_bytes(adventurer_state["adventurer"]["gold"]),
        "weapon": check_exists_int(adventurer_state["adventurer"]["weapon"]),
        "chest": check_exists_int(adventurer_state["adventurer"]["chest"]),
        "head": check_exists_int(adventurer_state["adventurer"]["head"]),
        "waist": check_exists_int(adventurer_state["adventurer"]["waist"]),
        "foot": check_exists_int(adventurer_state["adventurer"]["foot"]),
        "hand": check_exists_int(adventurer_state["adventurer"]["hand"]),
        "neck": check_exists_int(adventurer_state["adventurer"]["neck"]),
        "ring": check_exists_int(adventurer_state["adventurer"]["ring"]),
        "beastHealth": check_exists_int(adventurer_state["adventurer"]["beast_health"]),
        "statUpgrades": check_exists_int(
            adventurer_state["adventurer"]["stat_upgrade_available"]
        ),
    }
    await info.storage.find_one_and_update(
        "adventurers",
        {
            "id": encode_int_as_bytes(adventurer_state["adventurer_id"]),
        },
        {"$set": update_adventurer_doc},
    )


async def update_adventurer_bag(info: Info, adventurer_id, bag):
    update_bag_doc = {
        "adventurerId": adventurer_id,
        "item1": bag["item_1"],
        "item2": bag["item_2"],
        "item3": bag["item_3"],
        "item4": bag["item_4"],
        "item5": bag["item_5"],
        "item6": bag["item_6"],
        "item7": bag["item_7"],
        "item8": bag["item_8"],
        "item9": bag["item_9"],
        "item10": bag["item_10"],
        "item11": bag["item_11"],
        "item12": bag["item_12"],
    }
    await info.storage.find_one_and_update(
        "bags",
        {
            "adventurerId": check_exists_int(adventurer_id),
        },
        {
            "$set": update_bag_doc,
        },
    )


async def get_item(info, item_id, adventurer_id):
    item = await info.storage.find_one(
        "items",
        {
            "item": check_exists_int(item_id),
            "adventurerId": check_exists_int(adventurer_id),
        },
    )
    return item


async def update_item_xp(info, item, adventurer_id, xp):
    await info.storage.find_one_and_update(
        "items",
        {
            "item": check_exists_int(item),
            "adventurerId": check_exists_int(adventurer_id),
        },
        {
            "$set": {"xp", encode_int_as_bytes(xp)},
        },
    )


async def update_items_xp(info, adventurer_id, xp_increase):
    adventurer = await info.storage.find_one(
        "adventurers",
        {
            "id": check_exists_int(adventurer_id),
        },
    )
    weapon_item = await info.sroage.find_one(
        "items",
        {
            "item": check_exists_int(adventurer.weapon),
        },
    )
    chest_item = await info.sroage.find_one(
        "items",
        {
            "item": check_exists_int(adventurer.chest),
        },
    )
    head_item = await info.sroage.find_one(
        "items",
        {
            "item": check_exists_int(adventurer.head),
        },
    )
    waist_item = await info.sroage.find_one(
        "items",
        {
            "item": check_exists_int(adventurer.waist),
        },
    )
    foot_item = await info.sroage.find_one(
        "items",
        {
            "item": check_exists_int(adventurer.foot),
        },
    )
    hand_item = await info.sroage.find_one(
        "items",
        {
            "item": check_exists_int(adventurer.hand),
        },
    )
    neck_item = await info.sroage.find_one(
        "items",
        {
            "item": check_exists_int(adventurer.neck),
        },
    )
    ring_item = await info.sroage.find_one(
        "items",
        {
            "item": check_exists_int(adventurer.ring),
        },
    )
    update_item_xp(
        info,
        decode_bytes_as_int(weapon_item.item),
        adventurer_id,
        decode_bytes_as_int(weapon_item.xp) + xp_increase,
    )
    update_item_xp(
        info,
        decode_bytes_as_int(chest_item.item),
        adventurer_id,
        decode_bytes_as_int(chest_item.xp) + xp_increase,
    )
    update_item_xp(
        info,
        decode_bytes_as_int(head_item.item),
        adventurer_id,
        decode_bytes_as_int(head_item.xp) + xp_increase,
    )
    update_item_xp(
        info,
        decode_bytes_as_int(waist_item.item),
        adventurer_id,
        decode_bytes_as_int(waist_item.xp) + xp_increase,
    )
    update_item_xp(
        info,
        decode_bytes_as_int(foot_item.item),
        adventurer_id,
        decode_bytes_as_int(foot_item.xp) + xp_increase,
    )
    update_item_xp(
        info,
        decode_bytes_as_int(hand_item.item),
        adventurer_id,
        decode_bytes_as_int(hand_item.xp) + xp_increase,
    )
    update_item_xp(
        info,
        decode_bytes_as_int(neck_item.item),
        adventurer_id,
        decode_bytes_as_int(neck_item.xp) + xp_increase,
    )
    update_item_xp(
        info,
        decode_bytes_as_int(ring_item.item),
        adventurer_id,
        decode_bytes_as_int(ring_item.xp) + xp_increase,
    )


class LootSurvivorIndexer(StarkNetIndexer):
    def __init__(self, config):
        super().__init__()
        self.config = config

    def indexer_id(self) -> str:
        return f"loot-survivor-indexer-{self.config.network}"

    def initial_configuration(self) -> Filter:
        # Return initial configuration of the indexer.
        filter = Filter().with_header(weak=True)
        self.event_map = dict()

        def add_filter(contract, event):
            selector = ContractFunction.get_selector(event)
            self.event_map[selector] = event
            filter.add_event(
                EventFilter()
                .with_from_address(felt.from_hex(contract))
                .with_keys([felt.from_int(selector)])
            )

        for survivor_event in [
            "StartGame",
            "StatUpgraded",
            "DiscoverHealth",
            "DiscoverGold",
            "DiscoverXP",
            "DiscoverObstacle",
            "DiscoverBeast",
            "AttackBeast",
            "SlayedBeast",
            "FleeAttempt",
            "PurchasedItem",
            "EquipItem",
            "GreatnessIncreased",
            "ItemPrefixDiscovered",
            "ItemSuffixDiscovered",
            "PurchasedPotion",
            "NewHighScore",
            "AdventurerDied",
        ]:
            add_filter(self.config.GAME_CONTRACT, survivor_event)

        if self.config.network == "devnet":
            finality = DataFinality.DATA_STATUS_ACCEPTED
        else:
            finality = DataFinality.DATA_STATUS_PENDING

        return IndexerConfiguration(
            filter=filter,
            starting_cursor=starknet_cursor(self.config.STARTING_BLOCK),
            finality=finality,
        )

    async def handle_data(self, info: Info, data: Block):
        block_time = data.header.timestamp.ToDatetime()
        print(f"Indexing block {data.header.block_number} at {block_time}")
        # Handle one block of data
        # Define the batch size
        batch_size = 100  # adjust this number as necessary

        for i in range(0, len(data.events), batch_size):
            batch = data.events[i : i + batch_size]
            for event_with_tx in batch:
                event = event_with_tx.event
                event_name = self.event_map[felt.to_int(event.keys[0])]
                await {
                    "StartGame": self.start_game,
                    "StatUpgraded": self.stat_upgrade,
                    "DiscoverHealth": self.discover_health,
                    "DiscoverGold": self.discover_gold,
                    "DiscoverXP": self.discover_xp,
                    "DiscoverObstacle": self.discover_obstacle,
                    "DiscoverBeast": self.discover_beast,
                    "AttackBeast": self.attack_beast,
                    "SlayedBeast": self.slayed_beast,
                    "FleeAttempt": self.flee_attempt,
                    "PurchasedItem": self.purchased_item,
                    "EquipItem": self.equip_item,
                    "GreatnessIncreased": self.greatness_increased,
                    "ItemPrefixDiscovered": self.item_prefix_discovered,
                    "ItemSuffixDiscovered": self.item_suffix_discovered,
                    "PurchasedPotion": self.purchased_potion,
                    "NewHighScore": self.new_high_score,
                    "AdventurerDied": self.adventurer_died,
                }[event_name](
                    info,
                    block_time,
                    event.from_address,
                    felt.to_hex(event_with_tx.transaction.meta.hash),
                    event.data,
                )

    async def start_game(
        self,
        info: Info,
        block_time: datetime,
        _: FieldElement,
        tx_hash: str,
        data,
    ):
        sg = decode_start_game_event(data)
        start_game_doc = {
            "id": check_exists_int(sg.adventurer_state["adventurer_id"]),
            "owner": check_exists_int(sg.adventurer_state["owner"]),
            "lastAction": check_exists_int(
                sg.adventurer_state["adventurer"]["last_action"]
            ),
            "health": encode_int_as_bytes(sg.adventurer_state["adventurer"]["health"]),
            "xp": encode_int_as_bytes(sg.adventurer_state["adventurer"]["xp"]),
            "strength": encode_int_as_bytes(
                sg.adventurer_state["adventurer"]["strength"]
            ),
            "dexterity": encode_int_as_bytes(
                sg.adventurer_state["adventurer"]["dexterity"]
            ),
            "vitality": encode_int_as_bytes(
                sg.adventurer_state["adventurer"]["vitality"]
            ),
            "intelligence": encode_int_as_bytes(
                sg.adventurer_state["adventurer"]["intelligence"]
            ),
            "wisdom": encode_int_as_bytes(sg.adventurer_state["adventurer"]["wisdom"]),
            "charisma": encode_int_as_bytes(
                sg.adventurer_state["adventurer"]["charisma"]
            ),
            "gold": encode_int_as_bytes(sg.adventurer_state["adventurer"]["gold"]),
            "weapon": check_exists_int(sg.adventurer_state["adventurer"]["weapon"]),
            "chest": check_exists_int(sg.adventurer_state["adventurer"]["chest"]),
            "head": check_exists_int(sg.adventurer_state["adventurer"]["head"]),
            "waist": check_exists_int(sg.adventurer_state["adventurer"]["waist"]),
            "foot": check_exists_int(sg.adventurer_state["adventurer"]["foot"]),
            "hand": check_exists_int(sg.adventurer_state["adventurer"]["hand"]),
            "neck": check_exists_int(sg.adventurer_state["adventurer"]["neck"]),
            "ring": check_exists_int(sg.adventurer_state["adventurer"]["ring"]),
            "beastHealth": check_exists_int(
                sg.adventurer_state["adventurer"]["beast_health"]
            ),
            "statUpgrades": check_exists_int(
                sg.adventurer_state["adventurer"]["stat_upgrade_available"]
            ),
            "name": check_exists_int(sg.adventurer["name"]),
            "homeRealm": check_exists_int(sg.adventurer["home_realm"]),
            "race": check_exists_int(sg.adventurer["race"]),
            "order": check_exists_int(sg.adventurer["order"]),
            "entropy": check_exists_int(sg.adventurer["entropy"]),
            "createdTime": block_time,
        }
        await info.storage.insert_one("adventurers", start_game_doc)
        print("- [start game]", sg.adventurer_id, "->", hex(sg.owner))

    async def stat_upgrade(
        self,
        info: Info,
        block_time: datetime,
        _: FieldElement,
        tx_hash: str,
        data,
    ):
        su = decode_stat_upgrade_event(data)
        update_adventurer_helper(info, su.adventurer_state)
        stat_upgrade_doc = {
            "stat_id": check_exists_int(su.stat_id),
            "timestamp": block_time,
            "txHash": encode_hex_as_bytes(tx_hash),
            "adventurer_id": check_exists_int(su.adventurer_state["adventurer_id"]),
        }
        await info.storage.insert_one("upgrades", stat_upgrade_doc)
        print(
            "- [stat upgrade]", su.adventurer_state["adventurer_id"], "->", su.stat_id
        )

    async def discover_health(
        self,
        info: Info,
        block_time: datetime,
        _: FieldElement,
        tx_hash: str,
        data,
    ):
        dh = decode_discover_health_event(data)
        update_adventurer_helper(info, dh.adventurer_state)
        # subDiscoveries - 1: health, 2: gold, 3: xp
        discovery_doc = {
            "txHash": encode_hex_as_bytes(tx_hash),
            "adventurerId": check_exists_int(dh.adventurer_state["adventurer_id"]),
            "discoveryType": encode_int_as_bytes(3),
            "subDiscoveryType": check_exists_int(1),
            "outputAmount": encode_int_as_bytes(dh.health_amount),
            "obstacle": check_exists_int(0),
            "obstacleLevel": check_exists_int(0),
            "dodgedObstacle": encode_int_as_bytes(0),
            "damageTaken": encode_int_as_bytes(0),
            "xp_earned_adventurer": check_exists_int(0),
            "xp_earned_items": check_exists_int(0),
            "entityId": check_exists_int(0),
            "entityLevel": check_exists_int(0),
            "entityHealth": encode_int_as_bytes(0),
            "ambushed": check_exists_int(0),
            "discoveryTime": block_time,
        }
        await info.storage.insert_one("discoveries", discovery_doc)
        print(
            "- [discovered health]",
            dh.adventurer_state["adventurer_id"],
            "->",
            dh.health_amount,
        )

    async def discover_gold(
        self,
        info: Info,
        block_time: datetime,
        _: FieldElement,
        tx_hash: str,
        data,
    ):
        dg = decode_discover_gold_event(data)
        update_adventurer_helper(info, dg.adventurer_state)
        # subDiscoveries - 1: health, 2: gold, 3: xp
        discovery_doc = {
            "txHash": encode_hex_as_bytes(tx_hash),
            "adventurerId": check_exists_int(dg.adventurer_state["adventurer_id"]),
            "discoveryType": encode_int_as_bytes(3),
            "subDiscoveryType": check_exists_int(2),
            "outputAmount": encode_int_as_bytes(dg.gold_amount),
            "obstacle": check_exists_int(0),
            "obstacleLevel": check_exists_int(0),
            "dodgedObstacle": encode_int_as_bytes(0),
            "damageTaken": encode_int_as_bytes(0),
            "xp_earned_adventurer": check_exists_int(0),
            "xp_earned_items": check_exists_int(0),
            "entityId": check_exists_int(0),
            "entityLevel": check_exists_int(0),
            "entityHealth": encode_int_as_bytes(0),
            "ambushed": check_exists_int(0),
            "discoveryTime": block_time,
        }
        await info.storage.insert_one("discoveries", discovery_doc)
        print(
            "- [discovered gold]",
            dg.adventurer_state["adventurer_id"],
            "->",
            dg.gold_amount,
        )

    async def discover_xp(
        self,
        info: Info,
        block_time: datetime,
        _: FieldElement,
        tx_hash: str,
        data,
    ):
        dx = decode_discover_xp_event(data)
        update_adventurer_helper(info, dx.adventurer_state)
        # subDiscoveries - 1: health, 2: gold, 3: xp
        discovery_doc = {
            "txHash": encode_hex_as_bytes(tx_hash),
            "adventurerId": check_exists_int(dx.adventurer_state["adventurer_id"]),
            "discoveryType": encode_int_as_bytes(3),
            "subDiscoveryType": check_exists_int(3),
            "outputAmount": encode_int_as_bytes(dx.xp_amount),
            "obstacle": check_exists_int(0),
            "obstacleLevel": check_exists_int(0),
            "dodgedObstacle": encode_int_as_bytes(0),
            "damageTaken": encode_int_as_bytes(0),
            "xp_earned_adventurer": check_exists_int(0),
            "xp_earned_items": check_exists_int(0),
            "entityId": check_exists_int(0),
            "entityLevel": check_exists_int(0),
            "entityHealth": encode_int_as_bytes(0),
            "ambushed": check_exists_int(0),
            "discoveryTime": block_time,
        }
        await info.storage.insert_one("discoveries", discovery_doc)
        print(
            "- [discovered xp]",
            dx.adventurer_state["adventurer_id"],
            "->",
            dx.xp_amount,
        )

    async def discover_obstacle(
        self,
        info: Info,
        block_time: datetime,
        _: FieldElement,
        tx_hash: str,
        data,
    ):
        do = decode_discover_obstacle_event(data)
        update_adventurer_helper(info, do.adventurer_state)
        # subDiscoveries - 1: health, 2: gold, 3: xp
        discovery_doc = {
            "txHash": encode_hex_as_bytes(tx_hash),
            "adventurerId": check_exists_int(do.adventurer_state["adventurer_id"]),
            "discoveryType": encode_int_as_bytes(2),
            "subDiscoveryType": check_exists_int(0),
            "outputAmount": encode_int_as_bytes(0),
            "obstacle": check_exists_int(do.obstacle_id),
            "obstacleLevel": check_exists_int(do.obstacle_level),
            "dodgedObstacle": encode_int_as_bytes(do.dodged),
            "damageTaken": encode_int_as_bytes(do.damage_taken),
            "damageLocation": check_exists_int(do.damage_location),
            "xp_earned_adventurer": check_exists_int(do.xp_earned_adventurer),
            "xp_earned_items": check_exists_int(do.xp_earned_items),
            "entityId": check_exists_int(0),
            "entityLevel": check_exists_int(0),
            "entityHealth": encode_int_as_bytes(0),
            "ambushed": check_exists_int(0),
            "discoveryTime": block_time,
        }
        await info.storage.insert_one("discoveries", discovery_doc)
        await update_items_xp(
            info, do.adventurer_state["adventurer_id"], do.xp_earned_items
        )
        print(
            "- [discovered obstacle]",
            do.adventurer_state["adventurer_id"],
            "->",
            do.obstacle_id,
        )

    async def discover_beast(
        self,
        info: Info,
        block_time: datetime,
        _: FieldElement,
        tx_hash: str,
        data,
    ):
        db = decode_discover_beast_event(data)
        update_adventurer_helper(info, db.adventurer_state)
        discovery_doc = {
            "txHash": encode_hex_as_bytes(tx_hash),
            "adventurerId": check_exists_int(db.adventurer_state["adventurer_id"]),
            "discoveryType": encode_int_as_bytes(2),
            "subDiscoveryType": check_exists_int(0),
            "outputAmount": encode_int_as_bytes(0),
            "obstacle": check_exists_int(0),
            "obstacleLevel": check_exists_int(0),
            "dodgedObstacle": encode_int_as_bytes(0),
            "damageTaken": encode_int_as_bytes(db.damage_taken),
            "damageLocation": check_exists_int(0),
            "xp_earned_adventurer": check_exists_int(0),
            "xp_earned_items": check_exists_int(0),
            "entityId": check_exists_int(db.beast_id),
            "entityLevel": check_exists_int(db.beast_level),
            "entityHealth": encode_int_as_bytes(db.beast_level),
            "ambushed": check_exists_int(db.ambushed),
            "discoveryTime": block_time,
        }
        await info.storage.insert_one("discoveries", discovery_doc)
        print(
            "- [discovered beast]",
            db.adventurer_state["adventurer_id"],
            "->",
            db.beast_id,
        )

    async def attack_beast(
        self,
        info: Info,
        block_time: datetime,
        _: FieldElement,
        tx_hash: str,
        data: List[FieldElement],
    ):
        ba = decode_attack_beast_event(data)
        attacked_beast_doc = {
            "txHash": encode_hex_as_bytes(tx_hash),
            "beastId": check_exists_int(ba.beast_id),
            "adventurerId": check_exists_int(ba.adventurer_state["adventurer_id"]),
            "attacker": encode_int_as_bytes(1),
            "fled": check_exists_int(0),
            "ambushed": check_exists_int(0),
            "damageDealt": encode_int_as_bytes(ba.damage_dealt),
            "damageTaken": encode_int_as_bytes(ba.damage_taken),
            "damageLocation": encode_int_as_bytes(ba.damage_location),
            "targetHealth": encode_int_as_bytes(ba.beast_health),
            "xpEarnedAdventurer": encode_int_as_bytes(0),
            "xpEarnedItems": encode_int_as_bytes(0),
            "goldEarned": encode_int_as_bytes(0),
            "timestamp": block_time,
        }
        await info.storage.insert_one("battles", attacked_beast_doc)
        print(
            "- [attack beast]",
            ba.beast_id,
            "->",
            ba.adventurer_state["adventurer_id"],
            "-",
            attacked_beast_doc,
        )

    async def slayed_beast(
        self,
        info: Info,
        block_time: datetime,
        _: FieldElement,
        tx_hash: str,
        data: List[FieldElement],
    ):
        sb = decode_slayed_beast_event(data)
        slayed_beast_doc = {
            "txHash": encode_hex_as_bytes(tx_hash),
            "beastId": check_exists_int(sb.beast_id),
            "adventurerId": check_exists_int(sb.adventurer_state["adventurer_id"]),
            "attacker": encode_int_as_bytes(1),
            "fled": check_exists_int(0),
            "ambushed": check_exists_int(0),
            "damageDealt": encode_int_as_bytes(sb.damage_dealt),
            "damageTaken": encode_int_as_bytes(sb.damage_taken),
            "damageLocation": encode_int_as_bytes(0),
            "targetHealth": encode_int_as_bytes(sb.beast_health),
            "xpEarnedAdventurer": encode_int_as_bytes(sb.xp_earned_adventurer),
            "xpEarnedItems": encode_int_as_bytes(sb.xp_earned_items),
            "goldEarned": encode_int_as_bytes(sb.gold_earned),
            "timestamp": block_time,
        }
        await info.storage.insert_one("battles", slayed_beast_doc)
        await update_items_xp(
            info, sb.adventurer_state["adventurer_id"], sb.xp_earned_items
        )
        print(
            "- [attack beast]",
            sb.beast_id,
            "->",
            sb.adventurer_state["adventurer_id"],
            "-",
            slayed_beast_doc,
        )

    async def flee_attempt(
        self,
        info: Info,
        block_time: datetime,
        _: FieldElement,
        tx_hash: str,
        data: List[FieldElement],
    ):
        fa = decode_flee_attempt_event(data)
        flee_attempt_doc = {
            "txHash": encode_hex_as_bytes(tx_hash),
            "beastId": check_exists_int(fa.beast_id),
            "adventurerId": check_exists_int(fa.adventurer_state["adventurer_id"]),
            "attacker": encode_int_as_bytes(1),
            "fled": check_exists_int(fa.fled),
            "ambushed": check_exists_int(0),
            "damageDealt": encode_int_as_bytes(0),
            "damageTaken": encode_int_as_bytes(fa.damage_taken),
            "targetHealth": encode_int_as_bytes(fa.beast_health),
            "xpEarnedAdventurer": encode_int_as_bytes(0),
            "xpEarnedItems": encode_int_as_bytes(0),
            "goldEarned": encode_int_as_bytes(0),
            "timestamp": block_time,
        }
        await info.storage.insert_one("battles", flee_attempt_doc)
        print(
            "- [flee attempt]",
            fa.beast_id,
            "->",
            fa.adventurer_state["adventurer_id"],
            "-",
            fa.fled,
        )

    async def purchased_item(
        self,
        info: Info,
        block_time: datetime,
        _: FieldElement,
        tx_hash: str,
        data: List[FieldElement],
    ):
        pi = decode_purchased_item_event(data)
        purchased_item_doc = {
            "txHash": encode_hex_as_bytes(tx_hash),
            "item": check_exists_int(pi.item_id),
            "ownerAdventurerId": check_exists_int(
                pi.adventurer_state_with_bag["adventurer_state"]["adventurer_id"]
            ),
            "owner": check_exists_int(
                pi.adventurer_state_with_bag["adventurer_state"]["owner"]
            ),
            "cost": encode_int_as_bytes(pi.cost),
            "timestamp": block_time,
        }
        await info.storage.insert_one("purchases", purchased_item_doc)
        item_doc = {
            "item": check_exists_int(pi.item_id),
            "adventurerId": check_exists_int(
                pi.pi.adventurer_state_with_bag["adventurer_state"]["adventurer_id"]
            ),
            "xp": encode_int_as_bytes(0),
            "namePrefix": check_exists_int(0),
            "nameSuffix": check_exists_int(0),
            "itemSuffix": check_exists_int(0),
        }
        await info.storage.insert_one("items", item_doc)
        print("- [purchased item]", pi.item_id, "->", pi.cost)

    async def equip_item(
        self,
        info: Info,
        block_time: datetime,
        _: FieldElement,
        tx_hash: str,
        data: List[FieldElement],
    ):
        ei = decode_equip_item_event(data)
        equip_item_doc = {
            "txHash": encode_hex_as_bytes(tx_hash),
            "equipedItemId": check_exists_int(ei.equip_item_id),
            "unequipedItemId": check_exists_int(ei.unequiped_item_id),
            "ownerAdventurerId": check_exists_int(
                ei.adventurer_state_with_bag["adventurer_state"]["adventurer_id"]
            ),
            "owner": check_exists_int(
                ei.adventurer_state_with_bag["adventurer_state"]["owner"]
            ),
            "timestamp": block_time,
        }
        await info.storage.insert_one("swaps", equip_item_doc)
        update_adventurer_helper(info, ei.adventurer_state_with_bag["adventurer_state"])
        update_adventurer_bag(
            info,
            ei.adventurer_state_with_bag["adventurer_state"]["adventurer_id"],
            ei.adventurer_state_with_bag["bag"],
        )
        print("- [equip item]", ei.equiped_item_id, "->", ei.unequiped_item_id)

    async def greatness_increased(
        self,
        info: Info,
        block_time: datetime,
        _: FieldElement,
        tx_hash: str,
        data: List[FieldElement],
    ):
        gi = decode_greatness_increased_event(data)
        update_adventurer_helper(info, gi.adventurer_state)
        print(
            "- [greatness increased]",
            gi.adventurer_state["adventurer_id"],
            "->",
            gi.item_id,
        )

    async def item_prefix_discovered(
        self,
        info: Info,
        block_time: datetime,
        _: FieldElement,
        tx_hash: str,
        data: List[FieldElement],
    ):
        ip = decode_item_prefix_discovered_event(data)
        update_adventurer_helper(info, ip.adventurer_state)
        item_prefix_doc = {
            "namePrefix": check_exists_int(ip.item_description["name_prefix"]),
            "nameSuffix": encode_int_as_bytes(ip.item_description["name_suffix"]),
        }
        await info.storage.find_one_and_update(
            "items",
            {
                "item": check_exists_int(ip.item_description["id"]),
                "adventurerId": check_exists_int(ip.adventurer_state["adventurer_id"]),
            },
            {"$set": item_prefix_doc},
        )
        print(
            "- [item prefix discovered]",
            ip.adventurer_state["adventurer_id"],
            "->",
            ip.item_description["id"],
        )

    async def item_suffix_discovered(
        self,
        info: Info,
        block_time: datetime,
        _: FieldElement,
        tx_hash: str,
        data: List[FieldElement],
    ):
        isd = decode_item_suffix_discovered_event(data)
        update_adventurer_helper(info, isd.adventurer_state)
        item_suffix_doc = {
            "itemSuffix": check_exists_int(isd.item_description["item_suffix"]),
        }
        await info.storage.find_one_and_update(
            "items",
            {
                "id": check_exists_int(isd.item_description["id"]),
                "adventurerId": check_exists_int(isd.adventurer_state["adventurer_id"]),
            },
            {"$set": item_suffix_doc},
        )
        print(
            "- [item suffix discovered]",
            isd.adventurer_state["adventurer_id"],
            "->",
            isd.item_description["id"],
        )

    async def purchased_potion(
        self,
        info: Info,
        block_time: datetime,
        _: FieldElement,
        tx_hash: str,
        data: List[FieldElement],
    ):
        pp = decode_purchased_potion_event(data)
        update_adventurer_helper(info, pp.adventurer_state)
        purchase_doc = {
            "txHash": tx_hash,
            "adventurerId": check_exists_int(pp.adventurer_state["adventurer_id"]),
            "healthAmount": encode_int_as_bytes(pp.health_amount),
            "timestamp": block_time,
        }
        await info.storage.insert_one("health_purchases", purchase_doc)
        print(
            "- [purchased potion]",
            pp.adventurer_state["adventurer_id"],
            "->",
            pp.health_amount,
        )

    async def new_high_score(
        self,
        info: Info,
        block_time: datetime,
        _: FieldElement,
        tx_hash: str,
        data: List[FieldElement],
    ):
        hs = decode_new_high_score_event(data)
        new_high_score_doc = {
            "txHash": encode_hex_as_bytes(tx_hash),
            "adventurerId": encode_int_as_bytes(hs.adventurer_state["adventurer_id"]),
            "rank": encode_int_as_bytes(hs.rank),
            "owner": encode_int_as_bytes(hs.adventurer_state["owner"]),
            "timestamp": block_time,
        }
        await info.storage.insert_one("scores", new_high_score_doc)
        print("- [new high score]", hs.adventurer_state["adventurer_id"])

    async def adventurer_died(
        self,
        info: Info,
        block_time: datetime,
        _: FieldElement,
        tx_hash: str,
        data: List[FieldElement],
    ):
        ad = decode_adventurer_died_event(data)
        update_adventurer_helper(info, ad.adventurer_state)
        adventurer_died_doc = {
            "txHash": encode_hex_as_bytes(tx_hash),
            "adventurerId": encode_int_as_bytes(ad.adventurer_state["adventurer_id"]),
            "death": 1 if ad.killed_by_beast == 1 else 2,
            "killerId": ad.killer_id,
            "timestamp": block_time,
        }
        await info.storage.insert_one("deaths", adventurer_died_doc)
        print(
            "- [adventurer died]",
            ad.adventurer_state["adventurer_id"],
            "->",
        )

    # async def discovery(
    #     self,
    #     info: Info,
    #     block_time: datetime,
    #     _: FieldElement,
    #     tx_hash: str,
    #     data: List[FieldElement],
    # ):
    #     d = decode_discovery_event(data)
    #     if d.discovery_type == 3:
    #         sub_discovery_type = d.sub_discovery_type + 16
    #     else:
    #         sub_discovery_type = d.sub_discovery_type
    #     discovery_doc = {
    #         "txHash": encode_hex_as_bytes(tx_hash),
    #         "adventurerId": check_exists_int(d.adventurer_id),
    #         "discoveryType": encode_int_as_bytes(d.discovery_type),
    #         "subDiscoveryType": check_exists_int(sub_discovery_type),
    #         "entityId": check_exists_int(d.entity_id),
    #         "outputAmount": encode_int_as_bytes(d.output_amount),
    #         "attackLocation": check_exists_int(
    #             self.config.OBSTACLE_ATTACK_LOCATIONS[sub_discovery_type]
    #             if d.discovery_type == 2
    #             else 0
    #         ),
    #         "discoveryTime": block_time,
    #     }
    #     await info.storage.insert_one("discoveries", discovery_doc)
    #     print("- [discovery]", d.adventurer_id, "->", d.discovery_type)

    # async def create_beast(
    #     self,
    #     info: Info,
    #     block_time: datetime,
    #     _: FieldElement,
    #     tx_hash: FieldElement,
    #     data: List[FieldElement],
    # ):
    #     cb = decode_create_beast_event(data)
    #     beast_doc = {
    #         "id": check_exists_int(cb.beast_token_id),
    #         "adventurerId": check_exists_int(cb.beast_state["Adventurer"]),
    #         "createdDate": block_time,
    #         "beast": check_exists_int(cb.beast_state["Id"]),
    #         "attackType": check_exists_int(cb.beast_state["AttackType"]),
    #         "attackLocation": check_exists_int(
    #             self.config.BEAST_ATTACK_LOCATIONS[cb.beast_state["Id"]]
    #         ),
    #         "armorType": check_exists_int(cb.beast_state["ArmorType"]),
    #         "rank": check_exists_int(cb.beast_state["Rank"]),
    #         "prefix1": check_exists_int(cb.beast_state["Prefix_1"]),
    #         "prefix2": check_exists_int(cb.beast_state["Prefix_2"]),
    #         "health": encode_int_as_bytes(cb.beast_state["Health"]),
    #         "xp": encode_int_as_bytes(cb.beast_state["XP"]),
    #         "level": encode_int_as_bytes(cb.beast_state["Level"]),
    #         "slainOnDate": datetime.fromtimestamp(cb.beast_state["SlainOnDate"]),
    #         "lastUpdated": block_time,
    #     }
    #     await info.storage.insert_one("beasts", beast_doc)
    #     print("- [create beast]", cb.beast_token_id, "->", cb.beast_state)

    # async def update_beast_state(
    #     self,
    #     info: Info,
    #     block_time: datetime,
    #     _: FieldElement,
    #     tx_hash: FieldElement,
    #     data: List[FieldElement],
    # ):
    #     ub = decode_beast_state_event(data)
    #     update_beast_doc = {
    #         "id": check_exists_int(ub.beast_token_id),
    #         "adventurerId": check_exists_int(ub.beast_state["Adventurer"]),
    #         "beast": check_exists_int(ub.beast_state["Id"]),
    #         "attackType": check_exists_int(ub.beast_state["AttackType"]),
    #         "attackLocation": check_exists_int(
    #             self.config.BEAST_ATTACK_LOCATIONS[ub.beast_state["Id"]]
    #         ),
    #         "armorType": check_exists_int(ub.beast_state["ArmorType"]),
    #         "rank": check_exists_int(ub.beast_state["Rank"]),
    #         "prefix1": check_exists_int(ub.beast_state["Prefix_1"]),
    #         "prefix2": check_exists_int(ub.beast_state["Prefix_2"]),
    #         "health": encode_int_as_bytes(ub.beast_state["Health"]),
    #         "xp": encode_int_as_bytes(ub.beast_state["XP"]),
    #         "level": encode_int_as_bytes(ub.beast_state["Level"]),
    #         "slainOnDate": datetime.fromtimestamp(ub.beast_state["SlainOnDate"]),
    #         "lastUpdated": block_time,
    #     }
    #     beast_state = await info.storage.find_one(
    #         "beasts",
    #         {
    #             "id": encode_int_as_bytes(ub.beast_token_id),
    #         },
    #     )
    #     if beast_state:
    #         await info.storage.find_one_and_update(
    #             "beasts",
    #             {
    #                 "id": encode_int_as_bytes(ub.beast_token_id),
    #             },
    #             {
    #                 "$set": update_beast_doc,
    #             },
    #         )
    #     else:
    #         await info.storage.insert_one(
    #             "beasts",
    #             update_beast_doc,
    #         )
    #     print("- [update beast state]", ub.beast_token_id, "->", ub.beast_state)

    # async def beast_attacked(
    #     self,
    #     info: Info,
    #     block_time: datetime,
    #     _: FieldElement,
    #     tx_hash: str,
    #     data: List[FieldElement],
    # ):
    #     ba = decode_beast_attacked_event(data)
    #     attacked_beast_doc = {
    #         "txHash": encode_hex_as_bytes(tx_hash),
    #         "beastId": check_exists_int(ba.beast_token_id),
    #         "adventurerId": check_exists_int(ba.adventurer_token_id),
    #         "attacker": encode_int_as_bytes(1),
    #         "fled": check_exists_int(0),
    #         "ambushed": check_exists_int(0),
    #         "damage": encode_int_as_bytes(ba.damage),
    #         "targetHealth": encode_int_as_bytes(ba.beast_health),
    #         "xpEarned": encode_int_as_bytes(ba.xp_gained),
    #         "goldEarned": encode_int_as_bytes(ba.gold_reward),
    #         "timestamp": block_time,
    #     }
    #     await info.storage.insert_one("battles", attacked_beast_doc)
    #     print(
    #         "- [beast attacked]",
    #         ba.beast_token_id,
    #         "->",
    #         ba.adventurer_token_id,
    #         "-",
    #         attacked_beast_doc,
    #     )

    # async def adventurer_attacked(
    #     self,
    #     info: Info,
    #     block_time: datetime,
    #     _: FieldElement,
    #     tx_hash: FieldElement,
    #     data: List[FieldElement],
    # ):
    #     aa = decode_adventurer_attacked_event(data)
    #     attacked_adventurer_doc = {
    #         "txHash": encode_hex_as_bytes(tx_hash),
    #         "beastId": check_exists_int(aa.beast_token_id),
    #         "adventurerId": check_exists_int(aa.adventurer_token_id),
    #         "attacker": check_exists_int(2),
    #         "fled": check_exists_int(0),
    #         "ambushed": check_exists_int(0),
    #         "damage": encode_int_as_bytes(aa.damage),
    #         "targetHealth": encode_int_as_bytes(aa.adventurer_health),
    #         "xpEarned": encode_int_as_bytes(aa.xp_gained),
    #         "goldEarned": encode_int_as_bytes(aa.gold_reward),
    #         "timestamp": block_time,
    #     }
    #     await info.storage.insert_one(
    #         "battles",
    #         attacked_adventurer_doc,
    #     )
    #     print(
    #         "- [adventurer attacked]",
    #         aa.adventurer_token_id,
    #         "->",
    #         aa.beast_token_id,
    #         "-",
    #         attacked_adventurer_doc,
    #     )

    # async def fled_beast(
    #     self,
    #     info: Info,
    #     block_time: datetime,
    #     _: FieldElement,
    #     tx_hash: FieldElement,
    #     data: List[FieldElement],
    # ):
    #     fb = decode_fled_beast_event(data)
    #     fled_beast_doc = {
    #         "txHash": encode_hex_as_bytes(tx_hash),
    #         "beastId": check_exists_int(fb.beast_token_id),
    #         "adventurerId": check_exists_int(fb.adventurer_token_id),
    #         "attacker": check_exists_int(1),
    #         "fled": check_exists_int(1),
    #         "ambushed": check_exists_int(0),
    #         "damage": encode_int_as_bytes(0),
    #         "targetHealth": encode_int_as_bytes(0),
    #         "xpEarned": encode_int_as_bytes(0),
    #         "goldEarned": encode_int_as_bytes(0),
    #         "timestamp": block_time,
    #     }
    #     await info.storage.insert_one(
    #         "battles",
    #         fled_beast_doc,
    #     )
    #     print(
    #         "- [adventurer fled beast]",
    #         fb.adventurer_token_id,
    #         "->",
    #         fb.beast_token_id,
    #         "-",
    #         fled_beast_doc,
    #     )

    # async def adventurer_ambushed(
    #     self,
    #     info: Info,
    #     block_time: datetime,
    #     _: FieldElement,
    #     tx_hash: FieldElement,
    #     data: List[FieldElement],
    # ):
    #     aa = decode_adventurer_ambushed_event(data)
    #     adventurer_ambushed_doc = {
    #         "txHash": encode_hex_as_bytes(tx_hash),
    #         "beastId": check_exists_int(aa.beast_token_id),
    #         "adventurerId": check_exists_int(aa.adventurer_token_id),
    #         "attacker": check_exists_int(2),
    #         "fled": check_exists_int(0),
    #         "ambushed": check_exists_int(1),
    #         "damage": encode_int_as_bytes(aa.damage),
    #         "targetHealth": encode_int_as_bytes(aa.adventurer_health),
    #         "xpEarned": encode_int_as_bytes(0),
    #         "goldEarned": encode_int_as_bytes(0),
    #         "timestamp": block_time,
    #     }
    #     await info.storage.insert_one(
    #         "battles",
    #         adventurer_ambushed_doc,
    #     )
    #     print(
    #         "- [adventurer ambushed]",
    #         aa.adventurer_token_id,
    #         "->",
    #         aa.beast_token_id,
    #         "-",
    #         adventurer_ambushed_doc,
    #     )

    # async def update_gold(
    #     self,
    #     info: Info,
    #     block_time: datetime,
    #     _: FieldElement,
    #     tx_hash: str,
    #     data: List[FieldElement],
    # ):
    #     ug = decode_update_gold_event(data)
    #     update_gold_doc = {
    #         "id": check_exists_int(ug.adventurer_token_id),
    #         "gold": check_exists_int(ug.balance),
    #         "lastUpdated": block_time,
    #     }
    #     adventurer = await info.storage.find_one(
    #         "adventurers",
    #         {
    #             "id": check_exists_int(ug.adventurer_token_id),
    #         },
    #     )
    #     if adventurer:
    #         await info.storage.find_one_and_update(
    #             "adventurers",
    #             {
    #                 "id": check_exists_int(ug.adventurer_token_id),
    #             },
    #             {"$set": update_gold_doc},
    #         )
    #     else:
    #         await info.storage.insert_one(
    #             "adventurers",
    #             update_gold_doc,
    #         )
    #     print("- [update gold]", ug.adventurer_token_id, "->", ug.balance, "gold")

    # async def mint_item(
    #     self,
    #     info: Info,
    #     block_time: datetime,
    #     _: FieldElement,
    #     tx_hash: str,
    #     data: List[FieldElement],
    # ):
    #     mi = decode_mint_item_event(data)
    #     update_item_doc = {
    #         "id": check_exists_int(mi.item_token_id),
    #         "owner": check_exists_int(mi.to),
    #         "ownerAdventurerId": check_exists_int(mi.adventurer_token_id),
    #     }
    #     insert_item_doc = {
    #         "marketId": None,
    #         "id": check_exists_int(mi.item_token_id),
    #         "owner": check_exists_int(mi.to),
    #         "ownerAdventurerId": check_exists_int(mi.adventurer_token_id),
    #         "item": None,
    #         "slot": None,
    #         "type": None,
    #         "material": None,
    #         "rank": None,
    #         "prefix1": None,
    #         "prefix2": None,
    #         "suffix": None,
    #         "greatness": None,
    #         "createdBlock": None,
    #         "xp": None,
    #         "equippedAdventurerId": None,
    #         "bag": None,
    #         "price": None,
    #         "expiry": None,
    #         "bidder": None,
    #         "status": None,
    #         "claimedTime": None,
    #         "lastUpdated": block_time,
    #     }
    #     item_state = await info.storage.find_one(
    #         "items",
    #         {
    #             "id": check_exists_int(mi.item_token_id),
    #         },
    #     )
    #     if item_state:
    #         await info.storage.find_one_and_update(
    #             "items",
    #             {
    #                 "id": check_exists_int(mi.item_token_id),
    #             },
    #             {"$set": update_item_doc},
    #         )
    #     else:
    #         await info.storage.insert_one(
    #             "items",
    #             insert_item_doc,
    #         )
    #     print("- [mint item]", mi.item_token_id, "->", update_item_doc)

    # async def update_item_state(
    #     self,
    #     info: Info,
    #     block_time: datetime,
    #     _: FieldElement,
    #     tx_hash: str,
    #     data: List[FieldElement],
    # ):
    #     ui = decode_item_state_event(data)
    #     update_item_doc = {
    #         "id": check_exists_int(ui.item_token_id),
    #         "item": check_exists_int(ui.item["Id"]),
    #         "slot": check_exists_int(ui.item["Slot"]),
    #         "type": check_exists_int(ui.item["Type"]),
    #         "material": check_exists_int(ui.item["Material"]),
    #         "rank": check_exists_int(ui.item["Rank"]),
    #         "prefix1": check_exists_int(ui.item["Prefix_1"]),
    #         "prefix2": check_exists_int(ui.item["Prefix_2"]),
    #         "suffix": check_exists_int(ui.item["Suffix"]),
    #         "greatness": check_exists_int(ui.item["Greatness"]),
    #         "createdBlock": check_exists_int(ui.item["CreatedBlock"]),
    #         "xp": encode_int_as_bytes(ui.item["XP"]),
    #         "equippedAdventurerId": check_exists_int(ui.item["Adventurer"]),
    #         "bag": check_exists_int(ui.item["Bag"]),
    #         "lastUpdated": block_time,
    #     }
    #     insert_item_doc = {
    #         "marketId": None,
    #         "id": check_exists_int(ui.item_token_id),
    #         "owner": None,
    #         "ownerAdventurerId": None,
    #         "item": check_exists_int(ui.item["Id"]),
    #         "slot": check_exists_int(ui.item["Slot"]),
    #         "type": check_exists_int(ui.item["Type"]),
    #         "material": check_exists_int(ui.item["Material"]),
    #         "rank": check_exists_int(ui.item["Rank"]),
    #         "prefix1": check_exists_int(ui.item["Prefix_1"]),
    #         "prefix2": check_exists_int(ui.item["Prefix_2"]),
    #         "suffix": check_exists_int(ui.item["Suffix"]),
    #         "greatness": check_exists_int(ui.item["Greatness"]),
    #         "createdBlock": check_exists_int(ui.item["CreatedBlock"]),
    #         "xp": encode_int_as_bytes(ui.item["XP"]),
    #         "equippedAdventurerId": check_exists_int(ui.item["Adventurer"]),
    #         "bag": check_exists_int(ui.item["Bag"]),
    #         "price": None,
    #         "expiry": None,
    #         "bidder": None,
    #         "status": None,
    #         "claimedTime": None,
    #         "lastUpdated": block_time,
    #     }
    #     item_state = await info.storage.find_one(
    #         "items",
    #         {
    #             "id": check_exists_int(ui.item_token_id),
    #         },
    #     )
    #     if item_state:
    #         await info.storage.find_one_and_update(
    #             "items",
    #             {
    #                 "id": check_exists_int(ui.item_token_id),
    #             },
    #             {"$set": update_item_doc},
    #         )
    #     else:
    #         await info.storage.insert_one(
    #             "items",
    #             insert_item_doc,
    #         )
    #     print("- [update item state]", ui.item_token_id, "->", update_item_doc)

    # async def mint_daily_items(
    #     self,
    #     info: Info,
    #     block_time: datetime,
    #     _: FieldElement,
    #     tx_hash: str,
    #     data: List[FieldElement],
    # ):
    #     mdi = decode_mint_daily_items_event(data)
    #     mint_daily_items_doc = {
    #         "caller": check_exists_int(mdi.caller),
    #         "itemsNumber": check_exists_int(mdi.items_number),
    #         "timestamp": block_time,
    #     }
    #     await info.storage.insert_one("market", mint_daily_items_doc)
    #     print("- [mint daily items]", mdi.caller, "->", mdi.items_number)

    # async def claim_item(
    #     self,
    #     info: Info,
    #     block_time: datetime,
    #     _: FieldElement,
    #     tx_hash: str,
    #     data: List[FieldElement],
    # ):
    #     ci = decode_claim_item_event(data)
    #     claim_item_doc = {
    #         "marketId": check_exists_int(ci.market_token_id),
    #         "id": check_exists_int(ci.item_token_id),
    #         "ownerAdventurerId": check_exists_int(ci.adventurer_token_id),
    #         "owner": check_exists_int(ci.owner),
    #         "claimedTime": block_time,
    #         "status": encode_int_as_bytes(0),
    #     }
    #     await info.storage.find_one_and_update(
    #         "items",
    #         {
    #             "marketId": check_exists_int(ci.market_token_id),
    #         },
    #         {
    #             "$set": claim_item_doc,
    #         },
    #     )
    #     # Here we implement a fix for minting a mart item
    #     await info.storage.delete_one(
    #         "items", {"id": check_exists_int(ci.item_token_id), "marketId": None}
    #     )
    #     print("- [claim item]", ci.market_token_id, "->", ci.item_token_id)

    # async def update_merchant_item(
    #     self,
    #     info: Info,
    #     block_time: datetime,
    #     _: FieldElement,
    #     tx_hash: str,
    #     data: List[FieldElement],
    # ):
    #     um = decode_item_merchant_update_event(data)
    #     update_merchant_doc = {
    #         "marketId": check_exists_int(um.market_item_id),
    #         "item": check_exists_int(um.item["Id"]),
    #         "slot": check_exists_int(um.item["Slot"]),
    #         "type": check_exists_int(um.item["Type"]),
    #         "material": check_exists_int(um.item["Material"]),
    #         "rank": check_exists_int(um.item["Rank"]),
    #         "prefix1": check_exists_int(um.item["Prefix_1"]),
    #         "prefix2": check_exists_int(um.item["Prefix_2"]),
    #         "suffix": check_exists_int(um.item["Suffix"]),
    #         "greatness": check_exists_int(um.item["Greatness"]),
    #         "createdBlock": check_exists_int(um.item["CreatedBlock"]),
    #         "xp": encode_int_as_bytes(um.item["XP"]),
    #         "equippedAdventurerId": check_exists_int(um.item["Adventurer"]),
    #         "bag": check_exists_int(um.item["Bag"]),
    #         "price": check_exists_int(um.bid["price"]),
    #         "expiry": check_exists_timestamp(um.bid["expiry"]),
    #         "bidder": check_exists_int(um.bid["bidder"]),
    #         "status": encode_int_as_bytes(um.bid["status"]),
    #         "lastUpdated": block_time,
    #     }
    #     insert_merchant_doc = {
    #         "marketId": check_exists_int(um.market_item_id),
    #         "id": None,
    #         "owner": None,
    #         "ownerAdventurerId": None,
    #         "claimedTime": None,
    #         "item": check_exists_int(um.item["Id"]),
    #         "slot": check_exists_int(um.item["Slot"]),
    #         "type": check_exists_int(um.item["Type"]),
    #         "material": check_exists_int(um.item["Material"]),
    #         "rank": check_exists_int(um.item["Rank"]),
    #         "prefix1": check_exists_int(um.item["Prefix_1"]),
    #         "prefix2": check_exists_int(um.item["Prefix_2"]),
    #         "suffix": check_exists_int(um.item["Suffix"]),
    #         "greatness": check_exists_int(um.item["Greatness"]),
    #         "createdBlock": check_exists_int(um.item["CreatedBlock"]),
    #         "xp": encode_int_as_bytes(um.item["XP"]),
    #         "equippedAdventurerId": check_exists_int(um.item["Adventurer"]),
    #         "bag": check_exists_int(um.item["Bag"]),
    #         "price": check_exists_int(um.bid["price"]),
    #         "expiry": check_exists_timestamp(um.bid["expiry"]),
    #         "bidder": check_exists_int(um.bid["bidder"]),
    #         "status": encode_int_as_bytes(um.bid["status"]),
    #         "lastUpdated": block_time,
    #     }
    #     market_item = await info.storage.find_one(
    #         "items",
    #         {
    #             "marketId": check_exists_int(um.market_item_id),
    #         },
    #     )
    #     if market_item:
    #         await info.storage.find_one_and_update(
    #             "items",
    #             {
    #                 "marketId": check_exists_int(um.market_item_id),
    #             },
    #             {
    #                 "$set": update_merchant_doc,
    #             },
    #         )
    #     else:
    #         await info.storage.insert_one(
    #             "items",
    #             insert_merchant_doc,
    #         )
    #     print("- [update merchant item]", um.market_item_id, "->", um.bid)

    async def handle_invalidate(self, _info: Info, _cursor: Cursor):
        raise ValueError("data must be finalized")


async def run_indexer(
    server_url=None,
    stream_ssl=True,
    mongo_url=None,
    restart=None,
    network=None,
    adventurer=None,
    beast=None,
    loot=None,
    start_block=None,
):
    AUTH_TOKEN = os.environ.get("AUTH_TOKEN")
    if server_url == "localhost:7171" or server_url == "apibara:7171":
        stream_ssl = False
    runner = IndexerRunner(
        config=IndexerRunnerConfiguration(
            stream_url=server_url,
            stream_ssl=stream_ssl,
            storage_url=mongo_url,
            token=AUTH_TOKEN,
        ),
        reset_state=restart,
        client_options=[
            ("grpc.max_receive_message_length", 256 * 1_000_000),  # ~256 MB
        ],
    )

    config = Config(network, adventurer, beast, loot, start_block)

    # ctx can be accessed by the callbacks in `info`.
    if server_url == "localhost:7171" or server_url == "apibara:7171":
        ctx = {"network": "starknet-devnet"}
    else:
        ctx = {"network": "starknet-testnet"}
    await runner.run(LootSurvivorIndexer(config), ctx=ctx)
