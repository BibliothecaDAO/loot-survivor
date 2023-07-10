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
    decode_new_items_available_event,
)
from indexer.utils import (
    felt_to_str,
    str_to_felt,
    check_exists_int,
    check_exists_timestamp,
    encode_int_as_bytes,
    decode_bytes_as_int,
    get_key_by_value,
    create_uid,
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
        "strength": encode_int_as_bytes(
            adventurer_state["adventurer"]["stats"]["strength"]
        ),
        "dexterity": encode_int_as_bytes(
            adventurer_state["adventurer"]["stats"]["dexterity"]
        ),
        "vitality": encode_int_as_bytes(
            adventurer_state["adventurer"]["stats"]["vitality"]
        ),
        "intelligence": encode_int_as_bytes(
            adventurer_state["adventurer"]["stats"]["intelligence"]
        ),
        "wisdom": encode_int_as_bytes(
            adventurer_state["adventurer"]["stats"]["wisdom"]
        ),
        "charisma": encode_int_as_bytes(
            adventurer_state["adventurer"]["stats"]["charisma"]
        ),
        "gold": encode_int_as_bytes(adventurer_state["adventurer"]["gold"]),
        "weapon": check_exists_int(adventurer_state["adventurer"]["weapon"]["id"]),
        "chest": check_exists_int(adventurer_state["adventurer"]["chest"]["id"]),
        "head": check_exists_int(adventurer_state["adventurer"]["head"]["id"]),
        "waist": check_exists_int(adventurer_state["adventurer"]["waist"]["id"]),
        "foot": check_exists_int(adventurer_state["adventurer"]["foot"]["id"]),
        "hand": check_exists_int(adventurer_state["adventurer"]["hand"]["id"]),
        "neck": check_exists_int(adventurer_state["adventurer"]["neck"]["id"]),
        "ring": check_exists_int(adventurer_state["adventurer"]["ring"]["id"]),
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
    print(xp, encode_int_as_bytes(xp))
    await info.storage.find_one_and_update(
        "items",
        {
            "item": check_exists_int(item),
            "adventurerId": check_exists_int(adventurer_id),
        },
        {
            "$set": {"xp": encode_int_as_bytes(xp)},
        },
    )


async def update_items_xp(info, adventurer_id, xp_increase):
    adventurer = await info.storage.find_one(
        "adventurers",
        {
            "id": check_exists_int(adventurer_id),
        },
    )
    weapon_item = await info.storage.find_one(
        "items",
        {
            "item": adventurer["weapon"],
        },
    )
    chest_item = await info.storage.find_one(
        "items",
        {
            "item": adventurer["chest"],
        },
    )
    head_item = await info.storage.find_one(
        "items",
        {
            "item": adventurer["head"],
        },
    )
    waist_item = await info.storage.find_one(
        "items",
        {
            "item": adventurer["waist"],
        },
    )
    foot_item = await info.storage.find_one(
        "items",
        {
            "item": adventurer["foot"],
        },
    )
    hand_item = await info.storage.find_one(
        "items",
        {
            "item": adventurer["hand"],
        },
    )
    neck_item = await info.storage.find_one(
        "items",
        {
            "item": adventurer["neck"],
        },
    )
    ring_item = await info.storage.find_one(
        "items",
        {
            "item": adventurer["ring"],
        },
    )
    if weapon_item:
        await update_item_xp(
            info,
            decode_bytes_as_int(weapon_item["item"]),
            adventurer_id,
            decode_bytes_as_int(weapon_item["xp"]) + xp_increase,
        )
    if chest_item:
        await update_item_xp(
            info,
            decode_bytes_as_int(chest_item["item"]),
            adventurer_id,
            decode_bytes_as_int(chest_item["xp"]) + xp_increase,
        )
    if head_item:
        await update_item_xp(
            info,
            decode_bytes_as_int(head_item["item"]),
            adventurer_id,
            decode_bytes_as_int(head_item["xp"]) + xp_increase,
        )
    if waist_item:
        await update_item_xp(
            info,
            decode_bytes_as_int(waist_item["item"]),
            adventurer_id,
            decode_bytes_as_int(waist_item["xp"]) + xp_increase,
        )
    if foot_item:
        await update_item_xp(
            info,
            decode_bytes_as_int(foot_item["item"]),
            adventurer_id,
            decode_bytes_as_int(foot_item["xp"]) + xp_increase,
        )
    if hand_item:
        await update_item_xp(
            info,
            decode_bytes_as_int(hand_item["item"]),
            adventurer_id,
            decode_bytes_as_int(hand_item["xp"]) + xp_increase,
        )
    if neck_item:
        await update_item_xp(
            info,
            decode_bytes_as_int(neck_item["item"]),
            adventurer_id,
            decode_bytes_as_int(neck_item["xp"]) + xp_increase,
        )
    if ring_item:
        await update_item_xp(
            info,
            decode_bytes_as_int(ring_item["item"]),
            adventurer_id,
            decode_bytes_as_int(ring_item["xp"]) + xp_increase,
        )


async def swap_item(info, adventurer_id, equipped_item, unequipped_item, time):
    await info.storage.find_one_and_update(
        "items",
        {
            "id": check_exists_int(equipped_item),
            "adventurerId": check_exists_int(adventurer_id),
            "owner": check_exists_int(1),
        },
        {
            "$set": {
                "equipped": check_exists_int(1),
                "lastUpdatedTime": time,
            }
        },
    )
    await info.storage.find_one_and_update(
        "items",
        {
            "id": check_exists_int(unequipped_item),
            "adventurerId": check_exists_int(adventurer_id),
            "owner": check_exists_int(1),
        },
        {
            "$set": {"equipped": check_exists_int(0), "lastUpdatedTime": time},
        },
    )


# async def update_beast_health(info, beast_health):
#     beast = await info.storage.find_one(
#         "beasts",
#         {
#             "item": check_exists_int(item_id),
#             "adventurerId": check_exists_int(adventurer_id),
#         },
#     )
#     await info.storage.find_one_and_update(
#         "beasts",
#         {"id": check_exists_int(unequipped_item)},
#         {
#             "$set": {"equippedAdventurerId": check_exists_int(0)},
#             "lastUpdatedTime": time,
#         },
#     )


class LootSurvivorIndexer(StarkNetIndexer):
    def __init__(self, config):
        super().__init__()
        self.config = config

    def indexer_id(self) -> str:
        return f"mongo-{self.config.network}"

    def initial_configuration(self) -> Filter:
        # Return initial configuration of the indexer.
        filter = Filter().with_header(weak=True)
        self.event_map = dict()
        self.handle_pending_data = self.handle_data

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
            "NewItemsAvailable",
        ]:
            add_filter(self.config.GAME_CONTRACT, survivor_event)

        return IndexerConfiguration(
            filter=filter,
            starting_cursor=starknet_cursor(self.config.STARTING_BLOCK),
            finality=DataFinality.DATA_STATUS_PENDING,
        )

    async def handle_data(self, info: Info, data: Block):
        block_time = data.header.timestamp.ToDatetime()
        print(f"Indexing block {data.header.block_number} at {block_time}")
        # Handle one block of data

        for event_with_tx in data.events:
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
                "NewItemsAvailable": self.new_items_available,
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
        sg = decode_start_game_event.deserialize([felt.to_int(i) for i in data])
        start_game_doc = {
            "id": check_exists_int(sg.adventurer_state["adventurer_id"]),
            "owner": check_exists_int(sg.adventurer_state["owner"]),
            "lastAction": check_exists_int(
                sg.adventurer_state["adventurer"]["last_action"]
            ),
            "health": encode_int_as_bytes(sg.adventurer_state["adventurer"]["health"]),
            "xp": encode_int_as_bytes(sg.adventurer_state["adventurer"]["xp"]),
            "strength": encode_int_as_bytes(
                sg.adventurer_state["adventurer"]["stats"]["strength"]
            ),
            "dexterity": encode_int_as_bytes(
                sg.adventurer_state["adventurer"]["stats"]["dexterity"]
            ),
            "vitality": encode_int_as_bytes(
                sg.adventurer_state["adventurer"]["stats"]["vitality"]
            ),
            "intelligence": encode_int_as_bytes(
                sg.adventurer_state["adventurer"]["stats"]["intelligence"]
            ),
            "wisdom": encode_int_as_bytes(
                sg.adventurer_state["adventurer"]["stats"]["wisdom"]
            ),
            "charisma": encode_int_as_bytes(
                sg.adventurer_state["adventurer"]["stats"]["charisma"]
            ),
            "gold": encode_int_as_bytes(sg.adventurer_state["adventurer"]["gold"]),
            "weapon": check_exists_int(
                sg.adventurer_state["adventurer"]["weapon"]["id"]
            ),
            "chest": check_exists_int(sg.adventurer_state["adventurer"]["chest"]["id"]),
            "head": check_exists_int(sg.adventurer_state["adventurer"]["head"]["id"]),
            "waist": check_exists_int(sg.adventurer_state["adventurer"]["waist"]["id"]),
            "foot": check_exists_int(sg.adventurer_state["adventurer"]["foot"]["id"]),
            "hand": check_exists_int(sg.adventurer_state["adventurer"]["hand"]["id"]),
            "neck": check_exists_int(sg.adventurer_state["adventurer"]["neck"]["id"]),
            "ring": check_exists_int(sg.adventurer_state["adventurer"]["ring"]["id"]),
            "beastHealth": check_exists_int(
                sg.adventurer_state["adventurer"]["beast_health"]
            ),
            "statUpgrades": check_exists_int(
                sg.adventurer_state["adventurer"]["stat_upgrade_available"]
            ),
            "name": check_exists_int(sg.adventurer_meta["name"]),
            "homeRealm": check_exists_int(sg.adventurer_meta["home_realm"]),
            "race": check_exists_int(sg.adventurer_meta["race"]),
            "order": check_exists_int(sg.adventurer_meta["order"]),
            "entropy": check_exists_int(sg.adventurer_meta["entropy"]),
            "createdTime": block_time,
            "lastUpdatedTime": block_time,
        }
        await info.storage.insert_one("adventurers", start_game_doc)
        start_item_doc = {
            "item": check_exists_int(sg.adventurer_state["adventurer"]["weapon"]["id"]),
            "adventurerId": check_exists_int(sg.adventurer_state["adventurer_id"]),
            "owner": check_exists_int(1),
            "equipped": check_exists_int(1),
            "ownerAddress": check_exists_int(sg.adventurer_state["owner"]),
            "xp": encode_int_as_bytes(0),
            "cost": encode_int_as_bytes(0),
            "namePrefix": check_exists_int(0),
            "nameSuffix": check_exists_int(0),
            "itemSuffix": check_exists_int(0),
            "createdTime": block_time,
            "purchasedTime": check_exists_int(0),
            "lastUpdatedTime": block_time,
        }
        await info.storage.insert_one("items", start_item_doc)
        if (
            sg.adventurer_state["adventurer"]["weapon"]["id"] == 16
            or sg.adventurer_state["adventurer"]["weapon"]["id"] == 12
        ):
            starter_beast = 71
        elif sg.adventurer_state["adventurer"]["weapon"]["id"] == 46:
            starter_beast = 25
        else:
            starter_beast = 50
        start_beast_doc = {
            "txHash": encode_hex_as_bytes(tx_hash),
            "adventurerId": check_exists_int(sg.adventurer_state["adventurer_id"]),
            "discoveryType": encode_int_as_bytes(1),
            "subDiscoveryType": check_exists_int(0),
            "outputAmount": encode_int_as_bytes(0),
            "obstacle": check_exists_int(0),
            "obstacleLevel": check_exists_int(0),
            "dodgedObstacle": encode_int_as_bytes(0),
            "damageTaken": encode_int_as_bytes(0),
            "damageLocation": check_exists_int(0),
            "xpEarnedAdventurer": check_exists_int(0),
            "xpEarnedItems": check_exists_int(0),
            "entity": check_exists_int(starter_beast),
            "entityLevel": check_exists_int(1),
            "entityHealth": encode_int_as_bytes(5),
            "entityNamePrefix": check_exists_int(0),
            "entityNameSuffix": check_exists_int(0),
            "ambushed": check_exists_int(0),
            "discoveryTime": block_time,
        }
        await info.storage.insert_one("discoveries", start_beast_doc)
        print(
            "- [start game]",
            sg.adventurer_state["adventurer_id"],
            "->",
            hex(sg.adventurer_state["owner"]),
        )

    async def stat_upgrade(
        self,
        info: Info,
        block_time: datetime,
        _: FieldElement,
        tx_hash: str,
        data,
    ):
        su = decode_stat_upgrade_event.deserialize([felt.to_int(i) for i in data])
        await update_adventurer_helper(info, su.adventurer_state)
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
        dh = decode_discover_health_event.deserialize([felt.to_int(i) for i in data])
        await update_adventurer_helper(info, dh.adventurer_state)
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
            "damageLocation": check_exists_int(0),
            "xpEarnedAdventurer": check_exists_int(0),
            "xpEarnedItems": check_exists_int(0),
            "entity": check_exists_int(0),
            "entityLevel": check_exists_int(0),
            "entityHealth": encode_int_as_bytes(0),
            "entityNamePrefix": check_exists_int(0),
            "entityNameSuffix": check_exists_int(0),
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
        dg = decode_discover_gold_event.deserialize([felt.to_int(i) for i in data])
        await update_adventurer_helper(info, dg.adventurer_state)
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
            "damageLocation": check_exists_int(0),
            "xpEarnedAdventurer": check_exists_int(0),
            "xpEarnedItems": check_exists_int(0),
            "entity": check_exists_int(0),
            "entityLevel": check_exists_int(0),
            "entityHealth": encode_int_as_bytes(0),
            "entityNamePrefix": check_exists_int(0),
            "entityNameSuffix": check_exists_int(0),
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
        dx = decode_discover_xp_event.deserialize([felt.to_int(i) for i in data])
        await update_adventurer_helper(info, dx.adventurer_state)
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
            "damageLocation": check_exists_int(0),
            "xpEarnedAdventurer": check_exists_int(0),
            "xpEarnedItems": check_exists_int(0),
            "entity": check_exists_int(0),
            "entityLevel": check_exists_int(0),
            "entityHealth": encode_int_as_bytes(0),
            "entityNamePrefix": check_exists_int(0),
            "entityNameSuffix": check_exists_int(0),
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
        do = decode_discover_obstacle_event.deserialize([felt.to_int(i) for i in data])
        await update_adventurer_helper(info, do.adventurer_state)
        # subDiscoveries - 1: health, 2: gold, 3: xp
        discovery_doc = {
            "txHash": encode_hex_as_bytes(tx_hash),
            "adventurerId": check_exists_int(do.adventurer_state["adventurer_id"]),
            "discoveryType": encode_int_as_bytes(2),
            "subDiscoveryType": check_exists_int(0),
            "outputAmount": encode_int_as_bytes(0),
            "obstacle": check_exists_int(do.id),
            "obstacleLevel": check_exists_int(do.level),
            "dodgedObstacle": encode_int_as_bytes(do.dodged),
            "damageTaken": encode_int_as_bytes(do.damage_taken),
            "damageLocation": check_exists_int(do.damage_location),
            "xpEarnedAdventurer": check_exists_int(do.xp_earned_adventurer),
            "xpEarnedItems": check_exists_int(do.xp_earned_items),
            "entity": check_exists_int(0),
            "entityLevel": check_exists_int(0),
            "entityHealth": encode_int_as_bytes(0),
            "entityNamePrefix": check_exists_int(0),
            "entityNameSuffix": check_exists_int(0),
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
            do.id,
        )

    async def discover_beast(
        self,
        info: Info,
        block_time: datetime,
        _: FieldElement,
        tx_hash: str,
        data,
    ):
        db = decode_discover_beast_event.deserialize([felt.to_int(i) for i in data])
        await update_adventurer_helper(info, db.adventurer_state)
        discovery_doc = {
            "txHash": encode_hex_as_bytes(tx_hash),
            "adventurerId": check_exists_int(db.adventurer_state["adventurer_id"]),
            "discoveryType": encode_int_as_bytes(1),
            "subDiscoveryType": check_exists_int(0),
            "outputAmount": encode_int_as_bytes(0),
            "obstacle": check_exists_int(0),
            "obstacleLevel": check_exists_int(0),
            "dodgedObstacle": encode_int_as_bytes(0),
            "damageTaken": encode_int_as_bytes(db.damage_taken),
            "damageLocation": check_exists_int(0),
            "xpEarnedAdventurer": check_exists_int(0),
            "xpEarnedItems": check_exists_int(0),
            "entity": check_exists_int(db.id),
            "entityLevel": check_exists_int(db.level),
            "entityHealth": encode_int_as_bytes(db.health),
            "entityNamePrefix": check_exists_int(db.prefix1),
            "entityNameSuffix": check_exists_int(db.prefix2),
            "ambushed": check_exists_int(db.ambushed),
            "discoveryTime": block_time,
        }
        await info.storage.insert_one("discoveries", discovery_doc)
        print(
            "- [discovered beast]",
            db.adventurer_state["adventurer_id"],
            "->",
            db.id,
        )

    async def attack_beast(
        self,
        info: Info,
        block_time: datetime,
        _: FieldElement,
        tx_hash: str,
        data: List[FieldElement],
    ):
        ba = decode_attack_beast_event.deserialize([felt.to_int(i) for i in data])
        await update_adventurer_helper(info, ba.adventurer_state)
        # beast_discovery = await info.storage.find(
        #     "discoveries",
        #     {
        #         "entityId": check_exists_int(ba.beast_id),
        #         "adventurerId": check_exists_int(ba.adventurer_state["adventurer_id"]),
        #     },
        #     sort={"discoveryTime": -1},
        #     limit=1,
        # )
        # beast_document = next(beast_discovery)
        print(ba.beast_id, ba.adventurer_state["adventurer_id"])
        try:
            beast_discovery = await info.storage.find(
                "discoveries",
                {
                    "entityId": check_exists_int(ba.beast_id),
                    "adventurerId": check_exists_int(
                        ba.adventurer_state["adventurer_id"]
                    ),
                },
                sort={"discoveryTime": -1},
                limit=1,
            )
            beast_document = next(beast_discovery)
            attacked_beast_doc = {
                "txHash": encode_hex_as_bytes(tx_hash),
                "beast": check_exists_int(ba.beast_id),
                "beastHealth": encode_int_as_bytes(ba.beast_health),
                "beastLevel": encode_int_as_bytes(ba.beast_level),
                "beastNamePrefix": check_exists_int(ba.prefix_1),
                "beastNameSuffix": check_exists_int(ba.prefix_2),
                "adventurerId": check_exists_int(ba.adventurer_state["adventurer_id"]),
                "attacker": encode_int_as_bytes(1),
                "fled": check_exists_int(0),
                "damageDealt": encode_int_as_bytes(ba.damage_dealt),
                "damageTaken": encode_int_as_bytes(ba.damage_taken),
                "damageLocation": encode_int_as_bytes(ba.damage_location),
                "xpEarnedAdventurer": encode_int_as_bytes(0),
                "xpEarnedItems": encode_int_as_bytes(0),
                "goldEarned": encode_int_as_bytes(0),
                "discoveryTime": beast_document["discoveryTime"],
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
        except StopIteration:
            print("No documents found in beast_discovery")

    async def slayed_beast(
        self,
        info: Info,
        block_time: datetime,
        _: FieldElement,
        tx_hash: str,
        data: List[FieldElement],
    ):
        sb = decode_slayed_beast_event.deserialize([felt.to_int(i) for i in data])
        await update_adventurer_helper(info, sb.adventurer_state)
        # beast_discovery = await info.storage.find(
        #     "discoveries",
        #     {
        #         "entityId": check_exists_int(sb.beast_id),
        #         "adventurerId": check_exists_int(sb.adventurer_state["adventurer_id"]),
        #     },
        #     sort={"discoveryTime": -1},
        #     limit=1,
        # )
        # beast_document = next(beast_discovery)
        print(sb.beast_id, sb.adventurer_state["adventurer_id"])
        try:
            beast_discovery = await info.storage.find(
                "discoveries",
                {
                    "entityId": check_exists_int(sb.beast_id),
                    "adventurerId": check_exists_int(
                        sb.adventurer_state["adventurer_id"]
                    ),
                },
                sort={"discoveryTime": -1},
                limit=1,
            )
            beast_document = next(beast_discovery)
            slayed_beast_doc = {
                "txHash": encode_hex_as_bytes(tx_hash),
                "beast": check_exists_int(sb.beast_id),
                "beastHealth": encode_int_as_bytes(sb.beast_health),
                "beastLevel": encode_int_as_bytes(sb.beast_level),
                "beastNamePrefix": check_exists_int(sb.prefix_1),
                "beastNameSuffix": check_exists_int(sb.prefix_2),
                "adventurerId": check_exists_int(sb.adventurer_state["adventurer_id"]),
                "attacker": encode_int_as_bytes(1),
                "fled": check_exists_int(0),
                "damageDealt": encode_int_as_bytes(sb.damage_dealt),
                "damageTaken": encode_int_as_bytes(sb.damage_taken),
                "damageLocation": encode_int_as_bytes(0),
                "xpEarnedAdventurer": encode_int_as_bytes(sb.xp_earned_adventurer),
                "xpEarnedItems": encode_int_as_bytes(sb.xp_earned_items),
                "goldEarned": encode_int_as_bytes(sb.gold_earned),
                "discoveryTime": beast_document["discoveryTime"],
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
        except StopIteration:
            print("No documents found in beast_discovery")

    async def flee_attempt(
        self,
        info: Info,
        block_time: datetime,
        _: FieldElement,
        tx_hash: str,
        data: List[FieldElement],
    ):
        fa = decode_flee_attempt_event.deserialize([felt.to_int(i) for i in data])
        await update_adventurer_helper(info, fa.adventurer_state)
        # beast_discovery = await info.storage.find(
        #     "discoveries",
        #     {
        #         "entityId": check_exists_int(fa.beast_id),
        #         "adventurerId": check_exists_int(fa.adventurer_state["adventurer_id"]),
        #     },
        #     sort={"discoveryTime": -1},
        #     limit=1,
        # )
        # beast_document = next(beast_discovery)
        print(fa.beast_id, fa.adventurer_state["adventurer_id"])
        try:
            beast_discovery = await info.storage.find(
                "discoveries",
                {
                    "entityId": check_exists_int(fa.beast_id),
                    "adventurerId": check_exists_int(
                        fa.adventurer_state["adventurer_id"]
                    ),
                },
                sort={"discoveryTime": -1},
                limit=1,
            )
            beast_document = next(beast_discovery)
            flee_attempt_doc = {
                "txHash": encode_hex_as_bytes(tx_hash),
                "beast": check_exists_int(fa.beast_id),
                "beastHealth": encode_int_as_bytes(fa.beast_health),
                "beastLevel": encode_int_as_bytes(fa.beast_level),
                "beastNamePrefix": check_exists_int(fa.prefix_1),
                "beastNameSuffix": check_exists_int(fa.prefix_2),
                "adventurerId": check_exists_int(fa.adventurer_state["adventurer_id"]),
                "attacker": encode_int_as_bytes(2),
                "fled": check_exists_int(fa.fled),
                "damageDealt": encode_int_as_bytes(0),
                "damageTaken": encode_int_as_bytes(fa.damage_taken),
                "damageLocation": encode_int_as_bytes(0),
                "xpEarnedAdventurer": encode_int_as_bytes(0),
                "xpEarnedItems": encode_int_as_bytes(0),
                "goldEarned": encode_int_as_bytes(0),
                "discoveryTime": beast_document["discoveryTime"],
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
        except StopIteration:
            print("No documents found in beast_discovery")

    async def purchased_item(
        self,
        info: Info,
        block_time: datetime,
        _: FieldElement,
        tx_hash: str,
        data: List[FieldElement],
    ):
        pi = decode_purchased_item_event.deserialize([felt.to_int(i) for i in data])
        purchased_item_doc = {
            "owner": check_exists_int(1),
            "equipped": check_exists_int(1) if pi.equipped else check_exists_int(0),
            "ownerAddress": check_exists_int(
                pi.adventurer_state_with_bag["adventurer_state"]["owner"]
            ),
            "cost": encode_int_as_bytes(pi.cost),
            "purchasedTime": block_time,
            "lastUpdatedTime": block_time,
        }
        # Get the most recently created item so it can be updated
        try:
            item = info.storage.find(
                "items",
                {
                    "item": check_exists_int(
                        pi.item_id,
                    ),
                    "adventurerId": check_exists_int(
                        pi.adventurer_state_with_bag["adventurer_state"][
                            "adventurer_id"
                        ]
                    ),
                },
                sort={"createdTime": -1},
                limit=1,
            )
            item_document = next(item)
            await info.storage.find_one_and_update(
                "items",
                {
                    "item": pi.item_id,
                    "adventurerId": pi.adventurer_state_with_bag["adventurer_state"][
                        "adventurer_id"
                    ],
                    "createdTime": item_document.createdTime,
                },
                {"$set": purchased_item_doc},
            )
            await update_adventurer_helper(
                info, pi.adventurer_state_with_bag["adventurer_state"]
            )
            await update_adventurer_bag(
                info,
                pi.adventurer_state_with_bag["adventurer_state"]["adventurer_id"],
                pi.adventurer_state_with_bag["bag"],
            )
            print("- [purchased item]", pi.item_id, "->", pi.cost)
        except StopIteration:
            print("No documents found in item")

    async def equip_item(
        self,
        info: Info,
        block_time: datetime,
        _: FieldElement,
        tx_hash: str,
        data: List[FieldElement],
    ):
        ei = decode_equip_item_event.deserialize([felt.to_int(i) for i in data])
        await update_adventurer_helper(
            info, ei.adventurer_state_with_bag["adventurer_state"]
        )
        await update_adventurer_bag(
            info,
            ei.adventurer_state_with_bag["adventurer_state"]["adventurer_id"],
            ei.adventurer_state_with_bag["bag"],
        )
        await swap_item(
            info,
            ei.adventurer_state_with_bag["adventurer_state"]["adventurer_id"],
            ei.equip_item_id,
            ei.unequipped_item_id,
            block_time,
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
        gi = decode_greatness_increased_event.deserialize(
            [felt.to_int(i) for i in data]
        )
        await update_adventurer_helper(info, gi.adventurer_state)
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
        ip = decode_item_prefix_discovered_event.deserialize(
            [felt.to_int(i) for i in data]
        )
        await update_adventurer_helper(info, ip.adventurer_state)
        item_prefix_doc = {
            "namePrefix": check_exists_int(ip.special_names["name_prefix"]),
            "nameSuffix": encode_int_as_bytes(ip.special_names["name_suffix"]),
        }
        await info.storage.find_one_and_update(
            "items",
            {
                "item": check_exists_int(ip.special_names["id"]),
                "adventurerId": check_exists_int(ip.adventurer_state["adventurer_id"]),
                "owner": check_exists_int(1),
            },
            {"$set": item_prefix_doc},
        )
        print(
            "- [item prefix discovered]",
            ip.adventurer_state["adventurer_id"],
            "->",
            ip.special_names["id"],
        )

    async def item_suffix_discovered(
        self,
        info: Info,
        block_time: datetime,
        _: FieldElement,
        tx_hash: str,
        data: List[FieldElement],
    ):
        isd = decode_item_suffix_discovered_event.deserialize(
            [felt.to_int(i) for i in data]
        )
        await update_adventurer_helper(info, isd.adventurer_state)
        item_suffix_doc = {
            "itemSuffix": check_exists_int(isd.special_names["item_suffix"]),
        }
        await info.storage.find_one_and_update(
            "items",
            {
                "id": check_exists_int(isd.special_names["id"]),
                "adventurerId": check_exists_int(isd.adventurer_state["adventurer_id"]),
                "owner": check_exists_int(1),
            },
            {"$set": item_suffix_doc},
        )
        print(
            "- [item suffix discovered]",
            isd.adventurer_state["adventurer_id"],
            "->",
            isd.special_names["id"],
        )

    async def purchased_potion(
        self,
        info: Info,
        block_time: datetime,
        _: FieldElement,
        tx_hash: str,
        data: List[FieldElement],
    ):
        pp = decode_purchased_potion_event.deserialize([felt.to_int(i) for i in data])
        await update_adventurer_helper(info, pp.adventurer_state)
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
        hs = decode_new_high_score_event.deserialize([felt.to_int(i) for i in data])
        new_high_score_doc = {
            "txHash": encode_hex_as_bytes(tx_hash),
            "adventurerId": encode_int_as_bytes(hs.adventurer_state["adventurer_id"]),
            "rank": encode_int_as_bytes(hs.rank),
            "xp": encode_int_as_bytes(hs.adventurer_state["adventurer"]["xp"]),
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
        ad = decode_adventurer_died_event.deserialize([felt.to_int(i) for i in data])
        await update_adventurer_helper(info, ad.adventurer_state)
        adventurer_died_doc = {
            "txHash": encode_hex_as_bytes(tx_hash),
            "adventurerId": encode_int_as_bytes(ad.adventurer_state["adventurer_id"]),
            "death": check_exists_int(1) if ad.killed_by_beast == 1 else 2,
            "killerId": check_exists_int(ad.killer_id),
            "timestamp": block_time,
        }
        await info.storage.insert_one("deaths", adventurer_died_doc)
        print(
            "- [adventurer died]",
            ad.adventurer_state["adventurer_id"],
            "->",
        )

    async def new_items_available(
        self,
        info: Info,
        block_time: datetime,
        _: FieldElement,
        tx_hash: str,
        data: List[FieldElement],
    ):
        sa = decode_new_items_available_event.deserialize(
            [felt.to_int(i) for i in data]
        )

        for item in sa.items:
            items_doc = {
                "item": check_exists_int(item["item"]["id"]),
                "adventurerId": check_exists_int(sa.adventurer_state["adventurer_id"]),
                "owner": check_exists_int(0),
                "equipped": check_exists_int(0),
                "ownerAddress": check_exists_int(0),
                "xp": encode_int_as_bytes(0),
                "cost": encode_int_as_bytes(item["price"]),
                "namePrefix": check_exists_int(0),
                "nameSuffix": check_exists_int(0),
                "itemSuffix": check_exists_int(0),
                "createdTime": block_time,
                "purchasedTime": check_exists_int(0),
                "lastUpdatedTime": block_time,
            }
            await info.storage.insert_one("items", items_doc)

        print(
            "- [new items available]",
            sa.adventurer_state["adventurer_id"],
        )

    async def handle_invalidate(self, _info: Info, _cursor: Cursor):
        raise ValueError("data must be finalized")


async def run_indexer(
    server_url=None,
    stream_ssl=True,
    mongo_url=None,
    restart=None,
    network=None,
    game=None,
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
    )

    config = Config(network, game, start_block)

    # ctx can be accessed by the callbacks in `info`.
    if server_url == "localhost:7171" or server_url == "apibara:7171":
        ctx = {"network": "starknet-goerli"}
    else:
        ctx = {"network": "starknet-goerli"}
    await runner.run(LootSurvivorIndexer(config), ctx=ctx)
