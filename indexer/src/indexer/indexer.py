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
    decode_stat_upgrades_available_event,
    decode_strength_increased_event,
    decode_dexterity_increased_event,
    decode_vitality_increased_event,
    decode_intelligence_increased_event,
    decode_wisdom_increased_event,
    decode_charisma_increased_event,
    decode_discover_health_event,
    decode_discover_gold_event,
    decode_discover_xp_event,
    decode_dodged_obstacle_event,
    decode_hit_by_obstacle_event,
    decode_ambushed_by_beast_event,
    decode_discover_beast_event,
    decode_attack_beast_event,
    decode_attacked_by_beast_event,
    decode_slayed_beast_event,
    decode_flee_failed_event,
    decode_flee_succeeded_event,
    decode_purchased_item_event,
    decode_equipped_item_event,
    decode_dropped_item_event,
    decode_greatness_increased_event,
    decode_item_special_unlocked_event,
    decode_purchased_potion_event,
    decode_new_high_score_event,
    decode_adventurer_died_event,
    decode_adventurer_leveled_up_event,
    decode_new_items_available_event,
    decode_idle_damage_penalty_event,
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


async def update_adventurer_helper(info: Info, adventurer_state, time):
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
            adventurer_state["adventurer"]["stat_points_available"]
        ),
        "lastUpdatedTime": time,
        "timestamp": datetime.now(),
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


async def update_beast_health(
    info: Info, beast, adventurer_id, seed, health, slayed, block_time
):
    if slayed:
        update_beast_doc = {
            "health": encode_int_as_bytes(health),
            "lastUpdatedTime": block_time,
            "timestamp": datetime.now(),
        }
    else:
        update_beast_doc = {
            "health": encode_int_as_bytes(health),
            "slainOnTime": block_time,
            "lastUpdatedTime": block_time,
            "timestamp": datetime.now(),
        }
    await info.storage.find_one_and_update(
        "beasts",
        {
            "beast": check_exists_int(beast),
            "adventurerId": check_exists_int(adventurer_id),
            "seed": encode_int_as_bytes(seed),
        },
        {
            "$set": update_beast_doc,
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


async def update_items_xp(info, adventurer_id, adventurer):
    await info.storage.find_one_and_update(
        "items",
        {
            "item": check_exists_int(adventurer["weapon"]["id"]),
            "adventurerId": check_exists_int(adventurer_id),
            "owner": True,
        },
        {
            "$set": {"xp": encode_int_as_bytes(adventurer["weapon"]["xp"])},
        },
    )
    await info.storage.find_one_and_update(
        "items",
        {
            "item": check_exists_int(adventurer["chest"]["id"]),
            "adventurerId": check_exists_int(adventurer_id),
            "owner": True,
        },
        {
            "$set": {"xp": encode_int_as_bytes(adventurer["chest"]["xp"])},
        },
    )
    await info.storage.find_one_and_update(
        "items",
        {
            "item": check_exists_int(adventurer["head"]["id"]),
            "adventurerId": check_exists_int(adventurer_id),
            "owner": True,
        },
        {
            "$set": {"xp": encode_int_as_bytes(adventurer["head"]["xp"])},
        },
    )
    await info.storage.find_one_and_update(
        "items",
        {
            "item": check_exists_int(adventurer["waist"]["id"]),
            "adventurerId": check_exists_int(adventurer_id),
            "owner": True,
        },
        {
            "$set": {"xp": encode_int_as_bytes(adventurer["waist"]["xp"])},
        },
    )
    await info.storage.find_one_and_update(
        "items",
        {
            "item": check_exists_int(adventurer["foot"]["id"]),
            "adventurerId": check_exists_int(adventurer_id),
            "owner": True,
        },
        {
            "$set": {"xp": encode_int_as_bytes(adventurer["foot"]["xp"])},
        },
    )
    await info.storage.find_one_and_update(
        "items",
        {
            "item": check_exists_int(adventurer["hand"]["id"]),
            "adventurerId": check_exists_int(adventurer_id),
            "owner": True,
        },
        {
            "$set": {"xp": encode_int_as_bytes(adventurer["hand"]["xp"])},
        },
    )
    await info.storage.find_one_and_update(
        "items",
        {
            "item": check_exists_int(adventurer["neck"]["id"]),
            "adventurerId": check_exists_int(adventurer_id),
            "owner": True,
        },
        {
            "$set": {"xp": encode_int_as_bytes(adventurer["neck"]["xp"])},
        },
    )
    await info.storage.find_one_and_update(
        "items",
        {
            "item": check_exists_int(adventurer["ring"]["id"]),
            "adventurerId": check_exists_int(adventurer_id),
            "owner": True,
        },
        {
            "$set": {"xp": encode_int_as_bytes(adventurer["ring"]["xp"])},
        },
    )


async def swap_item(info, adventurer_id, equipped_item, unequipped_item, time):
    await info.storage.find_one_and_update(
        "items",
        {
            "item": check_exists_int(equipped_item),
            "adventurerId": check_exists_int(adventurer_id),
            "owner": True,
        },
        {
            "$set": {
                "equipped": True,
                "lastUpdatedTime": time,
                "timestamp": datetime.now(),
            }
        },
    )
    await info.storage.find_one_and_update(
        "items",
        {
            "item": check_exists_int(unequipped_item),
            "adventurerId": check_exists_int(adventurer_id),
            "owner": True,
        },
        {
            "$set": {
                "equipped": False,
                "lastUpdatedTime": time,
                "timestamp": datetime.now(),
            },
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
            "StrengthIncreased",
            "DexterityIncreased",
            "VitalityIncreased",
            "IntelligenceIncreased",
            "WisdomIncreased",
            "CharismaIncreased",
            "DiscoveredHealth",
            "DiscoveredGold",
            "DiscoveredXP",
            "DodgedObstacle",
            "HitByObstacle",
            "DiscoveredBeast",
            "AmbushedByBeast",
            "AttackedBeast",
            "AttackedByBeast",
            "SlayedBeast",
            "FleeFailed",
            "FleeSucceeded",
            "PurchasedItem",
            "EquippedItem",
            "DroppedItem",
            "GreatnessIncreased",
            "ItemSpecialUnlocked",
            "PurchasedPotion",
            "NewHighScore",
            "AdventurerDied",
            "AdventurerLeveledUp",
            "NewItemsAvailable",
            "IdleDamagePenalty",
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
                "StrengthIncreased": self.stat_upgrade,
                "DexterityIncreased": self.stat_upgrade,
                "VitalityIncreased": self.stat_upgrade,
                "IntelligenceIncreased": self.stat_upgrade,
                "WisdomIncreased": self.stat_upgrade,
                "CharismaIncreased": self.stat_upgrade,
                "DiscoveredHealth": self.discover_health,
                "DiscoveredGold": self.discover_gold,
                "DiscoveredXP": self.discover_xp,
                "DodgedObstacle": self.dodged_obstacle,
                "HitByObstacle": self.hit_by_obstacle,
                "DiscoveredBeast": self.discover_beast,
                "AmbushedByBeast": self.ambushed_by_beast,
                "AttackedBeast": self.attack_beast,
                "AttackedByBeast": self.attacked_by_beast,
                "SlayedBeast": self.slayed_beast,
                "FleeFailed": self.flee_failed,
                "FleeSucceeded": self.flee_succeeded,
                "PurchasedItem": self.purchased_item,
                "EquippedItem": self.equipped_item,
                "DroppedItem": self.dropped_item,
                "GreatnessIncreased": self.greatness_increased,
                "ItemSpecialUnlocked": self.item_special_unlocked,
                "PurchasedPotion": self.purchased_potion,
                "NewHighScore": self.new_high_score,
                "AdventurerDied": self.adventurer_died,
                "AdventurerLeveledUp": self.adventurer_leveled_up,
                "NewItemsAvailable": self.new_items_available,
                "IdleDamagePenalty": self.idle_damage_penalty,
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
                sg.adventurer_state["adventurer"]["stat_points_available"]
            ),
            "name": check_exists_int(sg.adventurer_meta["name"]),
            "homeRealm": check_exists_int(sg.adventurer_meta["home_realm"]),
            "classType": check_exists_int(sg.adventurer_meta["class"]),
            "entropy": check_exists_int(sg.adventurer_meta["entropy"]),
            "createdTime": datetime.now(),
            "lastUpdatedTime": block_time,
            "timestamp": datetime.now(),
        }
        await info.storage.insert_one("adventurers", start_game_doc)
        start_item_doc = {
            "item": check_exists_int(sg.adventurer_state["adventurer"]["weapon"]["id"]),
            "adventurerId": check_exists_int(sg.adventurer_state["adventurer_id"]),
            "owner": True,
            "equipped": True,
            "ownerAddress": check_exists_int(sg.adventurer_state["owner"]),
            "xp": encode_int_as_bytes(0),
            "cost": encode_int_as_bytes(0),
            "special1": check_exists_int(0),
            "special2": check_exists_int(0),
            "special3": check_exists_int(0),
            "createdTime": datetime.now(),
            "purchasedTime": check_exists_int(0),
            "lastUpdatedTime": block_time,
            "timestamp": datetime.now(),
        }
        await info.storage.insert_one("items", start_item_doc)
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
        su = decode_strength_increased_event.deserialize([felt.to_int(i) for i in data])
        await update_adventurer_helper(info, su.adventurer_state, block_time)
        print("- [stat upgrade]", su.adventurer_state["adventurer_id"])

    async def discover_health(
        self,
        info: Info,
        block_time: datetime,
        _: FieldElement,
        tx_hash: str,
        data,
    ):
        dh = decode_discover_health_event.deserialize([felt.to_int(i) for i in data])
        await update_adventurer_helper(info, dh.adventurer_state, block_time)
        # subDiscoveries - 1: health, 2: gold, 3: xp
        discovery_doc = {
            "txHash": encode_hex_as_bytes(tx_hash),
            "adventurerId": check_exists_int(dh.adventurer_state["adventurer_id"]),
            "adventurerHealth": encode_int_as_bytes(
                dh.adventurer_state["adventurer"]["health"]
            ),
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
            "special1": check_exists_int(0),
            "special2": check_exists_int(0),
            "special3": check_exists_int(0),
            "ambushed": check_exists_int(0),
            "seed": encode_int_as_bytes(0),
            "discoveryTime": block_time,
            "timestamp": datetime.now(),
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
        await update_adventurer_helper(info, dg.adventurer_state, block_time)
        # subDiscoveries - 1: health, 2: gold, 3: xp
        discovery_doc = {
            "txHash": encode_hex_as_bytes(tx_hash),
            "adventurerId": check_exists_int(dg.adventurer_state["adventurer_id"]),
            "adventurerHealth": encode_int_as_bytes(
                dg.adventurer_state["adventurer"]["health"]
            ),
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
            "special1": check_exists_int(0),
            "special2": check_exists_int(0),
            "special3": check_exists_int(0),
            "ambushed": check_exists_int(0),
            "seed": encode_int_as_bytes(0),
            "discoveryTime": block_time,
            "timestamp": datetime.now(),
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
        await update_adventurer_helper(info, dx.adventurer_state, block_time)
        # subDiscoveries - 1: health, 2: gold, 3: xp
        discovery_doc = {
            "txHash": encode_hex_as_bytes(tx_hash),
            "adventurerId": check_exists_int(dx.adventurer_state["adventurer_id"]),
            "adventurerHealth": encode_int_as_bytes(
                dx.adventurer_state["adventurer"]["health"]
            ),
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
            "special1": check_exists_int(0),
            "special2": check_exists_int(0),
            "special3": check_exists_int(0),
            "ambushed": check_exists_int(0),
            "seed": encode_int_as_bytes(0),
            "discoveryTime": block_time,
            "timestamp": datetime.now(),
        }
        await info.storage.insert_one("discoveries", discovery_doc)
        print(
            "- [discovered xp]",
            dx.adventurer_state["adventurer_id"],
            "->",
            dx.xp_amount,
        )

    async def dodged_obstacle(
        self,
        info: Info,
        block_time: datetime,
        _: FieldElement,
        tx_hash: str,
        data,
    ):
        do = decode_dodged_obstacle_event.deserialize([felt.to_int(i) for i in data])
        await update_adventurer_helper(info, do.adventurer_state, block_time)
        # subDiscoveries - 1: health, 2: gold, 3: xp
        discovery_doc = {
            "txHash": encode_hex_as_bytes(tx_hash),
            "adventurerId": check_exists_int(do.adventurer_state["adventurer_id"]),
            "adventurerHealth": encode_int_as_bytes(
                do.adventurer_state["adventurer"]["health"]
            ),
            "discoveryType": encode_int_as_bytes(2),
            "subDiscoveryType": check_exists_int(0),
            "outputAmount": encode_int_as_bytes(0),
            "obstacle": check_exists_int(do.id),
            "obstacleLevel": check_exists_int(do.level),
            "dodgedObstacle": encode_int_as_bytes(1),
            "damageTaken": encode_int_as_bytes(do.damage_taken),
            "damageLocation": check_exists_int(do.damage_location),
            "xpEarnedAdventurer": check_exists_int(do.xp_earned_adventurer),
            "xpEarnedItems": check_exists_int(do.xp_earned_items),
            "entity": check_exists_int(0),
            "entityLevel": check_exists_int(0),
            "entityHealth": encode_int_as_bytes(0),
            "special1": check_exists_int(0),
            "special2": check_exists_int(0),
            "special3": check_exists_int(0),
            "ambushed": check_exists_int(0),
            "seed": encode_int_as_bytes(0),
            "discoveryTime": block_time,
            "timestamp": datetime.now(),
        }
        await info.storage.insert_one("discoveries", discovery_doc)
        await update_items_xp(
            info,
            do.adventurer_state["adventurer_id"],
            do.adventurer_state["adventurer"],
        )
        print(
            "- [dodged obstacle]",
            do.adventurer_state["adventurer_id"],
            "->",
            do.id,
        )

    async def hit_by_obstacle(
        self,
        info: Info,
        block_time: datetime,
        _: FieldElement,
        tx_hash: str,
        data,
    ):
        do = decode_hit_by_obstacle_event.deserialize([felt.to_int(i) for i in data])
        await update_adventurer_helper(info, do.adventurer_state, block_time)
        # subDiscoveries - 1: health, 2: gold, 3: xp
        discovery_doc = {
            "txHash": encode_hex_as_bytes(tx_hash),
            "adventurerId": check_exists_int(do.adventurer_state["adventurer_id"]),
            "adventurerHealth": encode_int_as_bytes(
                do.adventurer_state["adventurer"]["health"]
            ),
            "discoveryType": encode_int_as_bytes(2),
            "subDiscoveryType": check_exists_int(0),
            "outputAmount": encode_int_as_bytes(0),
            "obstacle": check_exists_int(do.id),
            "obstacleLevel": check_exists_int(do.level),
            "dodgedObstacle": encode_int_as_bytes(0),
            "damageTaken": encode_int_as_bytes(do.damage_taken),
            "damageLocation": check_exists_int(do.damage_location),
            "xpEarnedAdventurer": check_exists_int(do.xp_earned_adventurer),
            "xpEarnedItems": check_exists_int(do.xp_earned_items),
            "entity": check_exists_int(0),
            "entityLevel": check_exists_int(0),
            "entityHealth": encode_int_as_bytes(0),
            "special1": check_exists_int(0),
            "special2": check_exists_int(0),
            "special3": check_exists_int(0),
            "ambushed": check_exists_int(0),
            "seed": encode_int_as_bytes(0),
            "discoveryTime": block_time,
            "timestamp": datetime.now(),
        }
        await info.storage.insert_one("discoveries", discovery_doc)
        await update_items_xp(
            info,
            do.adventurer_state["adventurer_id"],
            do.adventurer_state["adventurer"],
        )
        print(
            "- [hit by obstacle]",
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
        await update_adventurer_helper(info, db.adventurer_state, block_time)
        discovery_doc = {
            "txHash": encode_hex_as_bytes(tx_hash),
            "adventurerId": check_exists_int(db.adventurer_state["adventurer_id"]),
            "adventurerHealth": encode_int_as_bytes(
                db.adventurer_state["adventurer"]["health"]
            ),
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
            "entity": check_exists_int(db.id),
            "entityLevel": check_exists_int(db.beast_specs["level"]),
            "entityHealth": encode_int_as_bytes(
                db.adventurer_state["adventurer"]["beast_health"]
            ),
            "special1": check_exists_int(db.beast_specs["specials"]["special1"]),
            "special2": check_exists_int(db.beast_specs["specials"]["special2"]),
            "special3": check_exists_int(db.beast_specs["specials"]["special3"]),
            "ambushed": check_exists_int(0),
            "seed": encode_int_as_bytes(db.seed),
            "discoveryTime": block_time,
            "timestamp": datetime.now(),
        }
        await info.storage.insert_one("discoveries", discovery_doc)
        beast_doc = {
            "beast": check_exists_int(db.id),
            "health": encode_int_as_bytes(
                db.adventurer_state["adventurer"]["beast_health"]
            ),
            "level": encode_int_as_bytes(db.beast_specs["level"]),
            "special1": check_exists_int(db.beast_specs["specials"]["special1"]),
            "special2": check_exists_int(db.beast_specs["specials"]["special2"]),
            "special3": check_exists_int(db.beast_specs["specials"]["special3"]),
            "seed": encode_int_as_bytes(db.seed),
            "adventurerId": check_exists_int(db.adventurer_state["adventurer_id"]),
            "slainOnTime": check_exists_timestamp(0),
            "createdTime": datetime.now(),
            "lastUpdatedTime": block_time,
            "timestamp": datetime.now(),
        }
        await info.storage.insert_one("beasts", beast_doc)
        print(
            "- [discovered beast]",
            db.adventurer_state["adventurer_id"],
            "->",
            db.id,
        )

    async def ambushed_by_beast(
        self,
        info: Info,
        block_time: datetime,
        _: FieldElement,
        tx_hash: str,
        data,
    ):
        abb = decode_ambushed_by_beast_event.deserialize([felt.to_int(i) for i in data])
        await update_adventurer_helper(info, abb.adventurer_state, block_time)
        discovery_doc = {
            "txHash": encode_hex_as_bytes(tx_hash),
            "adventurerId": check_exists_int(abb.adventurer_state["adventurer_id"]),
            "adventurerHealth": encode_int_as_bytes(
                abb.adventurer_state["adventurer"]["health"]
            ),
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
            "entity": check_exists_int(abb.id),
            "entityLevel": check_exists_int(abb.beast_specs["level"]),
            "entityHealth": encode_int_as_bytes(
                abb.adventurer_state["adventurer"]["beast_health"]
            ),
            "special1": check_exists_int(abb.beast_specs["specials"]["special1"]),
            "special2": check_exists_int(abb.beast_specs["specials"]["special2"]),
            "special3": check_exists_int(abb.beast_specs["specials"]["special3"]),
            "ambushed": check_exists_int(1),
            "seed": encode_int_as_bytes(abb.seed),
            "discoveryTime": block_time,
            "timestamp": datetime.now(),
        }
        await info.storage.insert_one("discoveries", discovery_doc)
        attacked_by_beast_doc = {
            "txHash": encode_hex_as_bytes(tx_hash),
            "beast": check_exists_int(abb.id),
            "beastHealth": encode_int_as_bytes(
                abb.adventurer_state["adventurer"]["beast_health"]
            ),
            "beastLevel": encode_int_as_bytes(abb.beast_specs["level"]),
            "special1": check_exists_int(abb.beast_specs["specials"]["special1"]),
            "special2": check_exists_int(abb.beast_specs["specials"]["special2"]),
            "special3": check_exists_int(abb.beast_specs["specials"]["special3"]),
            "seed": encode_int_as_bytes(abb.seed),
            "adventurerId": check_exists_int(abb.adventurer_state["adventurer_id"]),
            "adventurerHealth": encode_int_as_bytes(
                abb.adventurer_state["adventurer"]["health"]
            ),
            "attacker": check_exists_int(2),
            "fled": check_exists_int(0),
            "damageDealt": encode_int_as_bytes(0),
            "criticalHit": abb.critical_hit,
            "damageTaken": encode_int_as_bytes(abb.damage),
            "damageLocation": check_exists_int(abb.location),
            "xpEarnedAdventurer": encode_int_as_bytes(0),
            "xpEarnedItems": encode_int_as_bytes(0),
            "goldEarned": encode_int_as_bytes(0),
            "discoveryTime": block_time,
            "blockTime": block_time,
            "timestamp": datetime.now(),
        }
        await info.storage.insert_one("battles", attacked_by_beast_doc)
        beast_doc = {
            "beast": check_exists_int(abb.id),
            "health": encode_int_as_bytes(
                abb.adventurer_state["adventurer"]["beast_health"]
            ),
            "level": encode_int_as_bytes(abb.beast_specs["level"]),
            "special1": check_exists_int(abb.beast_specs["specials"]["special1"]),
            "special2": check_exists_int(abb.beast_specs["specials"]["special2"]),
            "special3": check_exists_int(abb.beast_specs["specials"]["special3"]),
            "seed": encode_int_as_bytes(abb.seed),
            "adventurerId": check_exists_int(abb.adventurer_state["adventurer_id"]),
            "slainOnTime": check_exists_timestamp(0),
            "createdTime": datetime.now(),
            "lastUpdatedTime": block_time,
            "timestamp": datetime.now(),
        }
        await info.storage.insert_one("beasts", beast_doc)
        print(
            "- [ambushed by beast]",
            abb.adventurer_state["adventurer_id"],
            "->",
            abb.id,
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
        await update_adventurer_helper(info, ba.adventurer_state, block_time)
        await update_beast_health(
            info,
            ba.id,
            ba.adventurer_state["adventurer_id"],
            ba.seed,
            ba.adventurer_state["adventurer"]["beast_health"],
            False,
            block_time,
        )
        try:
            beast_discovery = await info.storage.find(
                "discoveries",
                {
                    "entity": check_exists_int(ba.id),
                    "adventurerId": check_exists_int(
                        ba.adventurer_state["adventurer_id"]
                    ),
                    "seed": encode_int_as_bytes(ba.seed),
                },
                sort={"discoveryTime": -1},
                limit=1,
            )
            beast_document = next(beast_discovery)
            attacked_beast_doc = {
                "txHash": encode_hex_as_bytes(tx_hash),
                "beast": check_exists_int(ba.id),
                "beastHealth": encode_int_as_bytes(
                    ba.adventurer_state["adventurer"]["beast_health"]
                ),
                "beastLevel": encode_int_as_bytes(ba.beast_specs["level"]),
                "special1": check_exists_int(ba.beast_specs["specials"]["special1"]),
                "special2": check_exists_int(ba.beast_specs["specials"]["special2"]),
                "special3": check_exists_int(ba.beast_specs["specials"]["special3"]),
                "seed": encode_int_as_bytes(ba.seed),
                "adventurerId": check_exists_int(ba.adventurer_state["adventurer_id"]),
                "adventurerHealth": encode_int_as_bytes(
                    ba.adventurer_state["adventurer"]["health"]
                ),
                "attacker": check_exists_int(1),
                "fled": check_exists_int(0),
                "damageDealt": encode_int_as_bytes(ba.damage),
                "criticalHit": ba.critical_hit,
                "damageTaken": encode_int_as_bytes(0),
                "damageLocation": check_exists_int(ba.location),
                "xpEarnedAdventurer": encode_int_as_bytes(0),
                "xpEarnedItems": encode_int_as_bytes(0),
                "goldEarned": encode_int_as_bytes(0),
                "discoveryTime": beast_document["discoveryTime"],
                "blockTime": block_time,
                "timestamp": datetime.now(),
            }
            await info.storage.insert_one("battles", attacked_beast_doc)
            print(
                "- [attack beast]",
                ba.id,
                "->",
                ba.adventurer_state["adventurer_id"],
            )
        except StopIteration:
            print("No documents found in beast_discovery")

    async def attacked_by_beast(
        self,
        info: Info,
        block_time: datetime,
        _: FieldElement,
        tx_hash: str,
        data: List[FieldElement],
    ):
        abb = decode_attacked_by_beast_event.deserialize([felt.to_int(i) for i in data])
        await update_adventurer_helper(info, abb.adventurer_state, block_time)
        try:
            beast_discovery = await info.storage.find(
                "discoveries",
                {
                    "entity": check_exists_int(abb.id),
                    "adventurerId": check_exists_int(
                        abb.adventurer_state["adventurer_id"]
                    ),
                    "seed": encode_int_as_bytes(abb.seed),
                },
                sort={"discoveryTime": -1},
                limit=1,
            )
            beast_document = next(beast_discovery)
            attacked_by_beast_doc = {
                "txHash": encode_hex_as_bytes(tx_hash),
                "beast": check_exists_int(abb.id),
                "beastHealth": encode_int_as_bytes(
                    abb.adventurer_state["adventurer"]["beast_health"]
                ),
                "beastLevel": encode_int_as_bytes(abb.beast_specs["level"]),
                "special1": check_exists_int(abb.beast_specs["specials"]["special1"]),
                "special2": check_exists_int(abb.beast_specs["specials"]["special2"]),
                "special3": check_exists_int(abb.beast_specs["specials"]["special3"]),
                "seed": encode_int_as_bytes(abb.seed),
                "adventurerId": check_exists_int(abb.adventurer_state["adventurer_id"]),
                "adventurerHealth": encode_int_as_bytes(
                    abb.adventurer_state["adventurer"]["health"]
                ),
                "attacker": check_exists_int(2),
                "fled": check_exists_int(0),
                "damageDealt": encode_int_as_bytes(0),
                "criticalHit": abb.critical_hit,
                "damageTaken": encode_int_as_bytes(abb.damage),
                "damageLocation": check_exists_int(abb.location),
                "xpEarnedAdventurer": encode_int_as_bytes(0),
                "xpEarnedItems": encode_int_as_bytes(0),
                "goldEarned": encode_int_as_bytes(0),
                "discoveryTime": beast_document["discoveryTime"],
                "blockTime": block_time,
                "timestamp": datetime.now(),
            }
            await info.storage.insert_one("battles", attacked_by_beast_doc)
            print(
                "- [attacked by beast]",
                abb.id,
                "->",
                abb.adventurer_state["adventurer_id"],
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
        await update_adventurer_helper(info, sb.adventurer_state, block_time)
        await update_beast_health(
            info,
            sb.id,
            sb.adventurer_state["adventurer_id"],
            sb.seed,
            sb.adventurer_state["adventurer"]["beast_health"],
            True,
            block_time,
        )
        try:
            beast_discovery = await info.storage.find(
                "discoveries",
                {
                    "entity": check_exists_int(sb.id),
                    "adventurerId": check_exists_int(
                        sb.adventurer_state["adventurer_id"]
                    ),
                    "seed": encode_int_as_bytes(sb.seed),
                },
                sort={"discoveryTime": -1},
                limit=1,
            )
            beast_document = next(beast_discovery)
            slayed_beast_doc = {
                "txHash": encode_hex_as_bytes(tx_hash),
                "beast": check_exists_int(sb.id),
                "beastHealth": encode_int_as_bytes(
                    sb.adventurer_state["adventurer"]["beast_health"]
                ),
                "beastLevel": encode_int_as_bytes(sb.beast_specs["level"]),
                "special1": check_exists_int(sb.beast_specs["specials"]["special1"]),
                "special2": check_exists_int(sb.beast_specs["specials"]["special2"]),
                "special3": check_exists_int(sb.beast_specs["specials"]["special3"]),
                "seed": encode_int_as_bytes(sb.seed),
                "adventurerId": check_exists_int(sb.adventurer_state["adventurer_id"]),
                "adventurerHealth": encode_int_as_bytes(
                    sb.adventurer_state["adventurer"]["health"]
                ),
                "attacker": check_exists_int(1),
                "fled": check_exists_int(0),
                "damageDealt": encode_int_as_bytes(sb.damage_dealt),
                "criticalHit": sb.critical_hit,
                "damageTaken": encode_int_as_bytes(0),
                "damageLocation": check_exists_int(0),
                "xpEarnedAdventurer": encode_int_as_bytes(sb.xp_earned_adventurer),
                "xpEarnedItems": encode_int_as_bytes(sb.xp_earned_items),
                "goldEarned": encode_int_as_bytes(sb.gold_earned),
                "discoveryTime": beast_document["discoveryTime"],
                "blockTime": block_time,
                "timestamp": datetime.now(),
            }
            await info.storage.insert_one("battles", slayed_beast_doc)
            await update_items_xp(
                info,
                sb.adventurer_state["adventurer_id"],
                sb.adventurer_state["adventurer"],
            )
            print(
                "- [slayed beast]",
                sb.id,
                "->",
                sb.adventurer_state["adventurer_id"],
            )
        except StopIteration:
            print("No documents found in beast_discovery")

    async def flee_failed(
        self,
        info: Info,
        block_time: datetime,
        _: FieldElement,
        tx_hash: str,
        data: List[FieldElement],
    ):
        fa = decode_flee_failed_event.deserialize([felt.to_int(i) for i in data])
        await update_adventurer_helper(info, fa.adventurer_state, block_time)
        try:
            beast_discovery = await info.storage.find(
                "discoveries",
                {
                    "entity": check_exists_int(fa.id),
                    "adventurerId": check_exists_int(
                        fa.adventurer_state["adventurer_id"]
                    ),
                    "seed": encode_int_as_bytes(fa.seed),
                },
                sort={"discoveryTime": -1},
                limit=1,
            )
            beast_document = next(beast_discovery)
            flee_attempt_doc = {
                "txHash": encode_hex_as_bytes(tx_hash),
                "beast": check_exists_int(fa.id),
                "beastHealth": encode_int_as_bytes(
                    fa.adventurer_state["adventurer"]["beast_health"]
                ),
                "beastLevel": encode_int_as_bytes(fa.beast_specs["level"]),
                "special1": check_exists_int(fa.beast_specs["specials"]["special1"]),
                "special2": check_exists_int(fa.beast_specs["specials"]["special2"]),
                "special3": check_exists_int(fa.beast_specs["specials"]["special3"]),
                "seed": encode_int_as_bytes(fa.seed),
                "adventurerId": check_exists_int(fa.adventurer_state["adventurer_id"]),
                "adventurerHealth": encode_int_as_bytes(
                    fa.adventurer_state["adventurer"]["health"]
                ),
                "attacker": check_exists_int(1),
                "fled": check_exists_int(0),
                "damageDealt": encode_int_as_bytes(0),
                "criticalHit": False,
                "damageTaken": encode_int_as_bytes(0),
                "damageLocation": check_exists_int(0),
                "xpEarnedAdventurer": encode_int_as_bytes(0),
                "xpEarnedItems": encode_int_as_bytes(0),
                "goldEarned": encode_int_as_bytes(0),
                "discoveryTime": beast_document["discoveryTime"],
                "blockTime": block_time,
                "timestamp": datetime.now(),
            }
            await info.storage.insert_one("battles", flee_attempt_doc)
            print(
                "- [flee failed]",
                fa.id,
                "->",
                fa.adventurer_state["adventurer_id"],
            )
        except StopIteration:
            print("No documents found in beast_discovery")

    async def flee_succeeded(
        self,
        info: Info,
        block_time: datetime,
        _: FieldElement,
        tx_hash: str,
        data: List[FieldElement],
    ):
        fa = decode_flee_succeeded_event.deserialize([felt.to_int(i) for i in data])
        await update_adventurer_helper(info, fa.adventurer_state, block_time)
        try:
            beast_discovery = await info.storage.find(
                "discoveries",
                {
                    "entity": check_exists_int(fa.id),
                    "adventurerId": check_exists_int(
                        fa.adventurer_state["adventurer_id"]
                    ),
                    "seed": encode_int_as_bytes(fa.seed),
                },
                sort={"discoveryTime": -1},
                limit=1,
            )
            beast_document = next(beast_discovery)
            flee_attempt_doc = {
                "txHash": encode_hex_as_bytes(tx_hash),
                "beast": check_exists_int(fa.id),
                "beastHealth": encode_int_as_bytes(
                    fa.adventurer_state["adventurer"]["beast_health"]
                ),
                "beastLevel": encode_int_as_bytes(fa.beast_specs["level"]),
                "special1": check_exists_int(fa.beast_specs["specials"]["special1"]),
                "special2": check_exists_int(fa.beast_specs["specials"]["special2"]),
                "special3": check_exists_int(fa.beast_specs["specials"]["special3"]),
                "seed": encode_int_as_bytes(fa.seed),
                "adventurerId": check_exists_int(fa.adventurer_state["adventurer_id"]),
                "adventurerHealth": encode_int_as_bytes(
                    fa.adventurer_state["adventurer"]["health"]
                ),
                "attacker": check_exists_int(1),
                "fled": check_exists_int(1),
                "damageDealt": encode_int_as_bytes(0),
                "criticalHit": False,
                "damageTaken": encode_int_as_bytes(0),
                "damageLocation": check_exists_int(0),
                "xpEarnedAdventurer": encode_int_as_bytes(0),
                "xpEarnedItems": encode_int_as_bytes(0),
                "goldEarned": encode_int_as_bytes(0),
                "discoveryTime": beast_document["discoveryTime"],
                "blockTime": block_time,
                "timestamp": datetime.now(),
            }
            await info.storage.insert_one("battles", flee_attempt_doc)
            print(
                "- [flee succeeded]",
                fa.id,
                "->",
                fa.adventurer_state["adventurer_id"],
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
            "owner": True,
            "equipped": True if pi.equipped else False,
            "ownerAddress": check_exists_int(
                pi.adventurer_state_with_bag["adventurer_state"]["owner"]
            ),
            "cost": encode_int_as_bytes(pi.cost),
            "purchasedTime": block_time,
            "lastUpdatedTime": block_time,
            "timestamp": datetime.now(),
        }
        # Get the most recently created item so it can be updated
        try:
            item = await info.storage.find(
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
                    "item": check_exists_int(pi.item_id),
                    "adventurerId": check_exists_int(
                        pi.adventurer_state_with_bag["adventurer_state"][
                            "adventurer_id"
                        ]
                    ),
                    "lastUpdatedTime": item_document["lastUpdatedTime"],
                },
                {"$set": purchased_item_doc},
            )
            await update_adventurer_helper(
                info, pi.adventurer_state_with_bag["adventurer_state"], block_time
            )
            await update_adventurer_bag(
                info,
                pi.adventurer_state_with_bag["adventurer_state"]["adventurer_id"],
                pi.adventurer_state_with_bag["bag"],
            )
            if pi.equipped:
                await swap_item(
                    info,
                    pi.adventurer_state_with_bag["adventurer_state"]["adventurer_id"],
                    pi.item_id,
                    pi.unequipped_item_id,
                    block_time,
                )
            print(
                "- [purchased item]",
                pi.adventurer_state_with_bag["adventurer_state"]["adventurer_id"],
                "->",
                pi.item_id,
                "->",
                pi.cost,
            )
        except StopIteration:
            print("No documents found in item")

    async def equipped_item(
        self,
        info: Info,
        block_time: datetime,
        _: FieldElement,
        tx_hash: str,
        data: List[FieldElement],
    ):
        ei = decode_equipped_item_event.deserialize([felt.to_int(i) for i in data])
        await update_adventurer_helper(
            info, ei.adventurer_state_with_bag["adventurer_state"], block_time
        )
        await swap_item(
            info,
            ei.adventurer_state_with_bag["adventurer_state"]["adventurer_id"],
            ei.equipped_item_id,
            ei.unequipped_item_id,
            block_time,
        )
        print("- [equipped item]", ei.equipped_item_id, "->", ei.unequipped_item_id)

    async def dropped_item(
        self,
        info: Info,
        block_time: datetime,
        _: FieldElement,
        tx_hash: str,
        data: List[FieldElement],
    ):
        di = decode_dropped_item_event.deserialize([felt.to_int(i) for i in data])
        await update_adventurer_helper(
            info, di.adventurer_state_with_bag["adventurer_state"], block_time
        )
        await info.storage.find_one_and_update(
            "items",
            {
                "item": check_exists_int(di.item_id),
                "adventurerId": check_exists_int(
                    di.adventurer_state_with_bag["adventurer_state"]["adventurer_id"],
                ),
                "owner": True,
            },
            {
                "$set": {
                    "equipped": False,
                    "owner": False,
                    "lastUpdatedTime": block_time,
                    "timestamp": datetime.now(),
                },
            },
        )
        print(
            "- [dropped item]",
            di.adventurer_state_with_bag["adventurer_state"]["adventurer_id"],
            "->",
            di.item_id,
        )

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
        await update_adventurer_helper(info, gi.adventurer_state, block_time)
        print(
            "- [greatness increased]",
            gi.adventurer_state["adventurer_id"],
            "->",
            gi.item_id,
        )

    async def item_special_unlocked(
        self,
        info: Info,
        block_time: datetime,
        _: FieldElement,
        tx_hash: str,
        data: List[FieldElement],
    ):
        isu = decode_item_special_unlocked_event.deserialize(
            [felt.to_int(i) for i in data]
        )
        await update_adventurer_helper(info, isu.adventurer_state, block_time)
        item_special_doc = {
            "special1": check_exists_int(isu.specials["special1"]),
            "special2": check_exists_int(isu.specials["special2"]),
            "special3": check_exists_int(isu.specials["special3"]),
            "timestamp": datetime.now(),
        }
        await info.storage.find_one_and_update(
            "items",
            {
                "item": check_exists_int(isu.id),
                "adventurerId": check_exists_int(isu.adventurer_state["adventurer_id"]),
                "owner": True,
            },
            {"$set": item_special_doc},
        )
        print(
            "- [item special unlocked]",
            isu.adventurer_state["adventurer_id"],
            "->",
            isu.id,
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
        await update_adventurer_helper(info, pp.adventurer_state, block_time)
        purchase_doc = {
            "txHash": tx_hash,
            "adventurerId": check_exists_int(pp.adventurer_state["adventurer_id"]),
            "quantity": check_exists_int(pp.quantity),
            "healthAmount": encode_int_as_bytes(pp.health_amount),
            "blockTime": block_time,
            "timestamp": datetime.now(),
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
            "blockTime": block_time,
            "timestamp": datetime.now(),
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
        await update_adventurer_helper(info, ad.adventurer_state, block_time)
        adventurer_died_doc = {
            "txHash": encode_hex_as_bytes(tx_hash),
            "adventurerId": encode_int_as_bytes(ad.adventurer_state["adventurer_id"]),
            "death": check_exists_int(1) if ad.killed_by_beast == 1 else 2,
            "killerId": check_exists_int(ad.killer_id),
            "blockTime": block_time,
            "timestamp": datetime.now(),
        }
        await info.storage.insert_one("deaths", adventurer_died_doc)
        print(
            "- [adventurer died]",
            ad.adventurer_state["adventurer_id"],
            "->",
        )

    async def adventurer_leveled_up(
        self,
        info: Info,
        block_time: datetime,
        _: FieldElement,
        tx_hash: str,
        data: List[FieldElement],
    ):
        alu = decode_adventurer_leveled_up_event.deserialize(
            [felt.to_int(i) for i in data]
        )
        await update_adventurer_helper(info, alu.adventurer_state, block_time)
        print(
            "- [adventurer leveled up]",
            alu.adventurer_state["adventurer_id"],
            "->",
            alu.new_level,
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
                "owner": False,
                "equipped": False,
                "ownerAddress": check_exists_int(0),
                "xp": encode_int_as_bytes(0),
                "cost": encode_int_as_bytes(item["price"]),
                "special1": check_exists_int(0),
                "special2": check_exists_int(0),
                "special3": check_exists_int(0),
                "createdTime": datetime.now(),
                "purchasedTime": check_exists_int(0),
                "lastUpdatedTime": block_time,
                "timestamp": datetime.now(),
            }
            await info.storage.insert_one("items", items_doc)

        print(
            "- [new items available]",
            sa.adventurer_state["adventurer_id"],
        )

    async def idle_damage_penalty(
        self,
        info: Info,
        block_time: datetime,
        _: FieldElement,
        tx_hash: str,
        data: List[FieldElement],
    ):
        idp = decode_idle_damage_penalty_event.deserialize(
            [felt.to_int(i) for i in data]
        )
        await update_adventurer_helper(info, idp.adventurer_state, block_time)
        if idp.adventurer_state["adventurer"]["beast_health"] > 0:
            penalty_battle_doc = {
                "txHash": encode_hex_as_bytes(tx_hash),
                "beast": check_exists_int(0),
                "beastHealth": encode_int_as_bytes(0),
                "beastLevel": encode_int_as_bytes(0),
                "special1": check_exists_int(0),
                "special2": check_exists_int(0),
                "special3": check_exists_int(0),
                "seed": encode_int_as_bytes(0),
                "adventurerId": check_exists_int(idp.adventurer_state["adventurer_id"]),
                "adventurerHealth": encode_int_as_bytes(
                    idp.adventurer_state["adventurer"]["health"]
                ),
                "attacker": check_exists_int(0),
                "fled": check_exists_int(0),
                "damageDealt": encode_int_as_bytes(0),
                "criticalHit": False,
                "damageTaken": encode_int_as_bytes(idp.damage_taken),
                "damageLocation": check_exists_int(0),
                "xpEarnedAdventurer": encode_int_as_bytes(0),
                "xpEarnedItems": encode_int_as_bytes(0),
                "goldEarned": encode_int_as_bytes(0),
                "discoveryTime": block_time,
                "blockTime": block_time,
                "timestamp": datetime.now(),
            }
            await info.storage.insert_one("battles", penalty_battle_doc)
        else:
            penalty_discovery_doc = {
                "txHash": encode_hex_as_bytes(tx_hash),
                "adventurerId": check_exists_int(idp.adventurer_state["adventurer_id"]),
                "adventurerHealth": encode_int_as_bytes(
                    idp.adventurer_state["adventurer"]["health"]
                ),
                "discoveryType": check_exists_int(0),
                "subDiscoveryType": check_exists_int(0),
                "outputAmount": encode_int_as_bytes(0),
                "obstacle": check_exists_int(0),
                "obstacleLevel": check_exists_int(0),
                "dodgedObstacle": encode_int_as_bytes(0),
                "damageTaken": encode_int_as_bytes(idp.damage_taken),
                "damageLocation": check_exists_int(0),
                "xpEarnedAdventurer": check_exists_int(0),
                "xpEarnedItems": check_exists_int(0),
                "entity": check_exists_int(0),
                "entityLevel": check_exists_int(0),
                "entityHealth": encode_int_as_bytes(0),
                "special1": check_exists_int(0),
                "special2": check_exists_int(0),
                "special3": check_exists_int(0),
                "ambushed": check_exists_int(0),
                "seed": encode_int_as_bytes(0),
                "discoveryTime": block_time,
                "timestamp": datetime.now(),
            }
            await info.storage.insert_one("discoveries", penalty_discovery_doc)
        print(
            "- [idle damage penalty]",
            idp.adventurer_state["adventurer_id"],
            "->",
            idp.adventurer_state["adventurer"]["health"],
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
