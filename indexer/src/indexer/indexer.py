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
    decode_mint_adventurer_event,
    decode_update_adventurer_state_event,
    decode_discovery_event,
    decode_update_thief_state_event,
    decode_create_beast_event,
    decode_beast_state_event,
    decode_beast_attacked_event,
    decode_adventurer_attacked_event,
    decode_fled_beast_event,
    decode_adventurer_ambushed_event,
    decode_update_gold_event,
    decode_mint_item_event,
    decode_item_state_event,
    decode_mint_daily_items_event,
    decode_claim_item_event,
    decode_item_merchant_update_event,
)
from indexer.utils import (
    felt_to_str,
    str_to_felt,
    check_exists_int,
    check_exists_timestamp,
    encode_int_as_bytes,
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

        # beast contract
        for adventurer_event in [
            "MintAdventurer",
            "UpdateAdventurerState",
            "Discovery",
            "UpdatedThiefState",
        ]:
            add_filter(self.config.ADVENTURER_CONTRACT, adventurer_event)

        # beast contract
        for beast_event in [
            "CreateBeast",
            "UpdateBeastState",
            "BeastAttacked",
            "AdventurerAttacked",
            "UpdateGoldBalance",
            "FledBeast",
            "AdventurerAmbushed",
        ]:
            add_filter(self.config.BEAST_CONTRACT, beast_event)

        # loot contract
        for loot_event in [
            "MintItem",
            "UpdateItemState",
            "MintDailyItems",
            "ClaimItem",
            "ItemMerchantUpdate",
        ]:
            add_filter(self.config.LOOT_CONTRACT, loot_event)

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
        print(f"Indexing block {data.header.block_number}")
        # Handle one block of data
        for event_with_tx in data.events:
            event = event_with_tx.event
            event_name = self.event_map[felt.to_int(event.keys[0])]
            await {
                "MintAdventurer": self.mint_adventurer,
                "UpdateAdventurerState": self.update_adventurer_state,
                "Discovery": self.discovery,
                "UpdatedThiefState": self.update_thief,
                "CreateBeast": self.create_beast,
                "UpdateBeastState": self.update_beast_state,
                "BeastAttacked": self.beast_attacked,
                "AdventurerAttacked": self.adventurer_attacked,
                "FledBeast": self.fled_beast,
                "AvdenturerAmbushed": self.adventurer_ambushed,
                "UpdateGoldBalance": self.update_gold,
                "MintItem": self.mint_item,
                "UpdateItemState": self.update_item_state,
                "MintDailyItems": self.mint_daily_items,
                "ClaimItem": self.claim_item,
                "ItemMerchantUpdate": self.update_merchant_item,
            }[event_name](
                info,
                block_time,
                event.from_address,
                felt.to_hex(event_with_tx.transaction.meta.hash),
                event.data,
            )

    async def mint_adventurer(
        self,
        info: Info,
        block_time: datetime,
        _: FieldElement,
        tx_hash: str,
        data,
    ):
        ma = decode_mint_adventurer_event(data)
        mint_adventurer_doc = {
            "id": check_exists_int(ma.adventurer_id),
            "owner": check_exists_int(ma.owner),
            "gold": check_exists_int(20),
            "lastUpdated": block_time,
        }
        await info.storage.insert_one("adventurers", mint_adventurer_doc)
        print("- [mint adventurer]", ma.adventurer_id, "->", hex(ma.owner))

    async def update_adventurer_state(
        self,
        info: Info,
        block_time: datetime,
        _: FieldElement,
        tx_hash: str,
        data,
    ):
        ua = decode_update_adventurer_state_event(data)
        update_adventurer_doc = {
            "id": check_exists_int(ua.adventurer_id),
            "race": check_exists_int(ua.adventurer_state["Race"]),
            "homeRealm": check_exists_int(ua.adventurer_state["HomeRealm"]),
            "birthdate": datetime.fromtimestamp(ua.adventurer_state["Birthdate"]),
            "name": check_exists_int(ua.adventurer_state["Name"]),
            "order": check_exists_int(ua.adventurer_state["Order"]),
            "imageHash1": check_exists_int(ua.adventurer_state["ImageHash1"]),
            "imageHash2": check_exists_int(ua.adventurer_state["ImageHash2"]),
            "health": encode_int_as_bytes(ua.adventurer_state["Health"]),
            "level": encode_int_as_bytes(ua.adventurer_state["Level"]),
            "strength": encode_int_as_bytes(ua.adventurer_state["Strength"]),
            "dexterity": encode_int_as_bytes(ua.adventurer_state["Dexterity"]),
            "vitality": encode_int_as_bytes(ua.adventurer_state["Vitality"]),
            "intelligence": encode_int_as_bytes(ua.adventurer_state["Intelligence"]),
            "wisdom": encode_int_as_bytes(ua.adventurer_state["Wisdom"]),
            "charisma": encode_int_as_bytes(ua.adventurer_state["Charisma"]),
            "luck": encode_int_as_bytes(ua.adventurer_state["Luck"]),
            "xp": encode_int_as_bytes(ua.adventurer_state["XP"]),
            "weaponId": check_exists_int(ua.adventurer_state["WeaponId"]),
            "chestId": check_exists_int(ua.adventurer_state["ChestId"]),
            "headId": check_exists_int(ua.adventurer_state["HeadId"]),
            "waistId": check_exists_int(ua.adventurer_state["WaistId"]),
            "feetId": check_exists_int(ua.adventurer_state["FeetId"]),
            "handsId": check_exists_int(ua.adventurer_state["HandsId"]),
            "neckId": check_exists_int(ua.adventurer_state["NeckId"]),
            "ringId": check_exists_int(ua.adventurer_state["RingId"]),
            "status": check_exists_int(ua.adventurer_state["Status"]),
            "beast": check_exists_int(ua.adventurer_state["Beast"]),
            "upgrading": encode_int_as_bytes(ua.adventurer_state["Upgrading"]),
            "lastUpdated": block_time,
        }
        await info.storage.find_one_and_update(
            "adventurers",
            {
                "id": encode_int_as_bytes(ua.adventurer_id),
            },
            {"$set": update_adventurer_doc},
        )
        print(
            "- [update adventurer state]", ua.adventurer_id, "->", ua.adventurer_state
        )

    async def discovery(
        self,
        info: Info,
        block_time: datetime,
        _: FieldElement,
        tx_hash: str,
        data: List[FieldElement],
    ):
        d = decode_discovery_event(data)
        if d.discovery_type == 1:
            sub_discovery_type = d.sub_discovery_type + 16
        else:
            sub_discovery_type = d.sub_discovery_type
        discovery_doc = {
            "txHash": encode_hex_as_bytes(tx_hash),
            "adventurerId": check_exists_int(d.adventurer_id),
            "discoveryType": encode_int_as_bytes(d.discovery_type),
            "subDiscoveryType": check_exists_int(sub_discovery_type),
            "entityId": check_exists_int(d.entity_id),
            "outputAmount": encode_int_as_bytes(d.output_amount),
            "discoveryTime": block_time,
        }
        await info.storage.insert_one("discoveries", discovery_doc)
        print("- [discovery]", d.adventurer_id, "->", d.discovery_type)

    async def update_thief(
        self,
        info: Info,
        block_time: datetime,
        _: FieldElement,
        tx_hash: FieldElement,
        data: List[FieldElement],
    ):
        ut = decode_update_thief_state_event(data)
        heist_doc = {
            "thiefId": check_exists_int(ut.thief_state["AdventurerId"]),
            "startTime": check_exists_int(ut.thief_state["StartTime"]),
            "gold": check_exists_int(ut.thief_state["Gold"]),
            "lastUpdated": block_time,
        }
        thief_state = await info.storage.find_one(
            "heists",
            {
                "beastId": encode_int_as_bytes(ut.thief_state["AdventurerId"]),
            },
        )
        if thief_state:
            await info.storage.find_one_and_update(
                "heists",
                {
                    "thiefId": encode_int_as_bytes(ut.thief_state["AdventurerId"]),
                },
                {
                    "$set": heist_doc,
                },
            )
        else:
            await info.storage.insert_one(
                "heists",
                heist_doc,
            )
        print("- [update thief]", ut.thief_state["AdventurerId"], "->", ut.thief_state)

    async def create_beast(
        self,
        info: Info,
        block_time: datetime,
        _: FieldElement,
        tx_hash: FieldElement,
        data: List[FieldElement],
    ):
        cb = decode_create_beast_event(data)
        beast_doc = {
            "id": check_exists_int(cb.beast_token_id),
            "adventurerId": check_exists_int(cb.beast_state["Adventurer"]),
            "createdDate": block_time,
            "beast": check_exists_int(cb.beast_state["Id"]),
            "attackType": check_exists_int(cb.beast_state["AttackType"]),
            "armorType": check_exists_int(cb.beast_state["ArmorType"]),
            "rank": check_exists_int(cb.beast_state["Rank"]),
            "prefix1": check_exists_int(cb.beast_state["Prefix_1"]),
            "prefix2": check_exists_int(cb.beast_state["Prefix_2"]),
            "health": encode_int_as_bytes(cb.beast_state["Health"]),
            "xp": encode_int_as_bytes(cb.beast_state["XP"]),
            "level": encode_int_as_bytes(cb.beast_state["Level"]),
            "slainOnDate": datetime.fromtimestamp(cb.beast_state["SlainOnDate"]),
            "lastUpdated": block_time,
        }
        await info.storage.insert_one("beasts", beast_doc)
        print("- [create beast]", cb.beast_token_id, "->", cb.beast_state)

    async def update_beast_state(
        self,
        info: Info,
        block_time: datetime,
        _: FieldElement,
        tx_hash: FieldElement,
        data: List[FieldElement],
    ):
        ub = decode_beast_state_event(data)
        update_beast_doc = {
            "id": check_exists_int(ub.beast_token_id),
            "adventurerId": check_exists_int(ub.beast_state["Adventurer"]),
            "beast": check_exists_int(ub.beast_state["Id"]),
            "attackType": check_exists_int(ub.beast_state["AttackType"]),
            "armorType": check_exists_int(ub.beast_state["ArmorType"]),
            "rank": check_exists_int(ub.beast_state["Rank"]),
            "prefix1": check_exists_int(ub.beast_state["Prefix_1"]),
            "prefix2": check_exists_int(ub.beast_state["Prefix_2"]),
            "health": encode_int_as_bytes(ub.beast_state["Health"]),
            "xp": encode_int_as_bytes(ub.beast_state["XP"]),
            "level": encode_int_as_bytes(ub.beast_state["Level"]),
            "slainOnDate": datetime.fromtimestamp(ub.beast_state["SlainOnDate"]),
            "lastUpdated": block_time,
        }
        beast_state = await info.storage.find_one(
            "beasts",
            {
                "id": encode_int_as_bytes(ub.beast_token_id),
            },
        )
        if beast_state:
            await info.storage.find_one_and_update(
                "beasts",
                {
                    "id": encode_int_as_bytes(ub.beast_token_id),
                },
                {
                    "$set": update_beast_doc,
                },
            )
        else:
            await info.storage.insert_one(
                "beasts",
                update_beast_doc,
            )
        print("- [update beast state]", ub.beast_token_id, "->", ub.beast_state)

    async def beast_attacked(
        self,
        info: Info,
        block_time: datetime,
        _: FieldElement,
        tx_hash: str,
        data: List[FieldElement],
    ):
        ba = decode_beast_attacked_event(data)
        attacked_beast_doc = {
            "txHash": encode_hex_as_bytes(tx_hash),
            "beastId": check_exists_int(ba.beast_token_id),
            "adventurerId": check_exists_int(ba.adventurer_token_id),
            "attacker": encode_int_as_bytes(1),
            "fled": check_exists_int(0),
            "ambushed": check_exists_int(0),
            "damage": encode_int_as_bytes(ba.damage),
            "targetHealth": encode_int_as_bytes(ba.beast_health),
            "xpEarned": encode_int_as_bytes(ba.xp_gained),
            "goldEarned": encode_int_as_bytes(ba.gold_reward),
            "timestamp": block_time,
        }
        await info.storage.insert_one("battles", attacked_beast_doc)
        print(
            "- [beast attacked]",
            ba.beast_token_id,
            "->",
            ba.adventurer_token_id,
            "-",
            attacked_beast_doc,
        )

    async def adventurer_attacked(
        self,
        info: Info,
        block_time: datetime,
        _: FieldElement,
        tx_hash: FieldElement,
        data: List[FieldElement],
    ):
        aa = decode_adventurer_attacked_event(data)
        attacked_adventurer_doc = {
            "txHash": encode_hex_as_bytes(tx_hash),
            "beastId": check_exists_int(aa.beast_token_id),
            "adventurerId": check_exists_int(aa.adventurer_token_id),
            "attacker": check_exists_int(2),
            "fled": check_exists_int(0),
            "ambushed": check_exists_int(0),
            "damage": encode_int_as_bytes(aa.damage),
            "targetHealth": encode_int_as_bytes(aa.adventurer_health),
            "xpEarned": encode_int_as_bytes(aa.xp_gained),
            "goldEarned": encode_int_as_bytes(aa.gold_reward),
            "timestamp": block_time,
        }
        await info.storage.insert_one(
            "battles",
            attacked_adventurer_doc,
        )
        print(
            "- [adventurer attacked]",
            aa.adventurer_token_id,
            "->",
            aa.beast_token_id,
            "-",
            attacked_adventurer_doc,
        )

    async def fled_beast(
        self,
        info: Info,
        block_time: datetime,
        _: FieldElement,
        tx_hash: FieldElement,
        data: List[FieldElement],
    ):
        fb = decode_fled_beast_event(data)
        fled_beast_doc = {
            "txHash": encode_hex_as_bytes(tx_hash),
            "beastId": check_exists_int(fb.beast_token_id),
            "adventurerId": check_exists_int(fb.adventurer_token_id),
            "attacker": check_exists_int(1),
            "fled": check_exists_int(1),
            "ambushed": check_exists_int(0),
            "damage": encode_int_as_bytes(0),
            "targetHealth": encode_int_as_bytes(0),
            "xpEarned": encode_int_as_bytes(0),
            "goldEarned": encode_int_as_bytes(0),
            "timestamp": block_time,
        }
        await info.storage.insert_one(
            "battles",
            fled_beast_doc,
        )
        print(
            "- [adventurer fled beast]",
            fb.adventurer_token_id,
            "->",
            fb.beast_token_id,
            "-",
            fled_beast_doc,
        )

    async def adventurer_ambushed(
        self,
        info: Info,
        block_time: datetime,
        _: FieldElement,
        tx_hash: FieldElement,
        data: List[FieldElement],
    ):
        aa = decode_adventurer_ambushed_event(data)
        adventurer_ambushed_doc = {
            "txHash": encode_hex_as_bytes(tx_hash),
            "beastId": check_exists_int(aa.beast_token_id),
            "adventurerId": check_exists_int(aa.adventurer_token_id),
            "attacker": check_exists_int(2),
            "fled": check_exists_int(0),
            "ambushed": check_exists_int(1),
            "damage": encode_int_as_bytes(aa.damage),
            "targetHealth": encode_int_as_bytes(aa.adventurer_health),
            "xpEarned": encode_int_as_bytes(0),
            "goldEarned": encode_int_as_bytes(0),
            "timestamp": block_time,
        }
        await info.storage.insert_one(
            "battles",
            adventurer_ambushed_doc,
        )
        print(
            "- [adventurer ambushed]",
            aa.adventurer_token_id,
            "->",
            aa.beast_token_id,
            "-",
            adventurer_ambushed_doc,
        )

    async def update_gold(
        self,
        info: Info,
        block_time: datetime,
        _: FieldElement,
        tx_hash: str,
        data: List[FieldElement],
    ):
        ug = decode_update_gold_event(data)
        update_gold_doc = {
            "id": check_exists_int(ug.adventurer_token_id),
            "gold": check_exists_int(ug.balance),
            "lastUpdated": block_time,
        }
        adventurer = await info.storage.find_one(
            "adventurers",
            {
                "id": check_exists_int(ug.adventurer_token_id),
            },
        )
        if adventurer:
            await info.storage.find_one_and_update(
                "adventurers",
                {
                    "id": check_exists_int(ug.adventurer_token_id),
                },
                {"$set": update_gold_doc},
            )
        else:
            await info.storage.insert_one(
                "adventurers",
                update_gold_doc,
            )
        print("- [update gold]", ug.adventurer_token_id, "->", ug.balance, "gold")

    async def mint_item(
        self,
        info: Info,
        block_time: datetime,
        _: FieldElement,
        tx_hash: str,
        data: List[FieldElement],
    ):
        mi = decode_mint_item_event(data)
        update_item_doc = {
            "id": check_exists_int(mi.item_token_id),
            "owner": check_exists_int(mi.to),
            "ownerAdventurerId": check_exists_int(mi.adventurer_token_id),
        }
        insert_item_doc = {
            "marketId": None,
            "id": check_exists_int(mi.item_token_id),
            "owner": check_exists_int(mi.to),
            "ownerAdventurerId": check_exists_int(mi.adventurer_token_id),
            "item": None,
            "slot": None,
            "type": None,
            "material": None,
            "rank": None,
            "prefix1": None,
            "prefix2": None,
            "suffix": None,
            "greatness": None,
            "createdBlock": None,
            "xp": None,
            "equippedAdventurerId": None,
            "bag": None,
            "price": None,
            "expiry": None,
            "bidder": None,
            "status": None,
            "claimedTime": None,
            "lastUpdated": block_time,
        }
        item_state = await info.storage.find_one(
            "items",
            {
                "id": check_exists_int(mi.item_token_id),
            },
        )
        if item_state:
            await info.storage.find_one_and_update(
                "items",
                {
                    "id": check_exists_int(mi.item_token_id),
                },
                {"$set": update_item_doc},
            )
        else:
            await info.storage.insert_one(
                "items",
                insert_item_doc,
            )
        print("- [mint item]", mi.item_token_id, "->", update_item_doc)

    async def update_item_state(
        self,
        info: Info,
        block_time: datetime,
        _: FieldElement,
        tx_hash: str,
        data: List[FieldElement],
    ):
        ui = decode_item_state_event(data)
        update_item_doc = {
            "id": check_exists_int(ui.item_token_id),
            "item": check_exists_int(ui.item["Id"]),
            "slot": check_exists_int(ui.item["Slot"]),
            "type": check_exists_int(ui.item["Type"]),
            "material": check_exists_int(ui.item["Material"]),
            "rank": check_exists_int(ui.item["Rank"]),
            "prefix1": check_exists_int(ui.item["Prefix_1"]),
            "prefix2": check_exists_int(ui.item["Prefix_2"]),
            "suffix": check_exists_int(ui.item["Suffix"]),
            "greatness": check_exists_int(ui.item["Greatness"]),
            "createdBlock": check_exists_int(ui.item["CreatedBlock"]),
            "xp": encode_int_as_bytes(ui.item["XP"]),
            "equippedAdventurerId": check_exists_int(ui.item["Adventurer"]),
            "bag": check_exists_int(ui.item["Bag"]),
            "lastUpdated": block_time,
        }
        insert_item_doc = {
            "marketId": None,
            "id": check_exists_int(ui.item_token_id),
            "owner": None,
            "ownerAdventurerId": None,
            "item": check_exists_int(ui.item["Id"]),
            "slot": check_exists_int(ui.item["Slot"]),
            "type": check_exists_int(ui.item["Type"]),
            "material": check_exists_int(ui.item["Material"]),
            "rank": check_exists_int(ui.item["Rank"]),
            "prefix1": check_exists_int(ui.item["Prefix_1"]),
            "prefix2": check_exists_int(ui.item["Prefix_2"]),
            "suffix": check_exists_int(ui.item["Suffix"]),
            "greatness": check_exists_int(ui.item["Greatness"]),
            "createdBlock": check_exists_int(ui.item["CreatedBlock"]),
            "xp": encode_int_as_bytes(ui.item["XP"]),
            "equippedAdventurerId": check_exists_int(ui.item["Adventurer"]),
            "bag": check_exists_int(ui.item["Bag"]),
            "price": None,
            "expiry": None,
            "bidder": None,
            "status": None,
            "claimedTime": None,
            "lastUpdated": block_time,
        }
        item_state = await info.storage.find_one(
            "items",
            {
                "id": check_exists_int(ui.item_token_id),
            },
        )
        if item_state:
            await info.storage.find_one_and_update(
                "items",
                {
                    "id": check_exists_int(ui.item_token_id),
                },
                {"$set": update_item_doc},
            )
        else:
            await info.storage.insert_one(
                "items",
                insert_item_doc,
            )
        print("- [update item state]", ui.item_token_id, "->", update_item_doc)

    async def mint_daily_items(
        self,
        info: Info,
        block_time: datetime,
        _: FieldElement,
        tx_hash: str,
        data: List[FieldElement],
    ):
        mdi = decode_mint_daily_items_event(data)
        mint_daily_items_doc = {
            "caller": check_exists_int(mdi.caller),
            "itemsNumber": check_exists_int(mdi.items_number),
            "timestamp": block_time,
        }
        await info.storage.insert_one("market", mint_daily_items_doc)
        print("- [mint daily items]", mdi.caller, "->", mdi.items_number)

    async def claim_item(
        self,
        info: Info,
        block_time: datetime,
        _: FieldElement,
        tx_hash: str,
        data: List[FieldElement],
    ):
        ci = decode_claim_item_event(data)
        claim_item_doc = {
            "marketId": check_exists_int(ci.market_token_id),
            "id": check_exists_int(ci.item_token_id),
            "ownerAdventurerId": check_exists_int(ci.adventurer_token_id),
            "owner": check_exists_int(ci.owner),
            "claimedTime": block_time,
            "status": encode_int_as_bytes(0),
        }
        await info.storage.find_one_and_update(
            "items",
            {
                "marketId": check_exists_int(ci.market_token_id),
            },
            {
                "$set": claim_item_doc,
            },
        )
        print("- [claim item]", ci.market_token_id, "->", ci.item_token_id)

    async def update_merchant_item(
        self,
        info: Info,
        block_time: datetime,
        _: FieldElement,
        tx_hash: str,
        data: List[FieldElement],
    ):
        um = decode_item_merchant_update_event(data)
        update_merchant_doc = {
            "marketId": check_exists_int(um.market_item_id),
            "item": check_exists_int(um.item["Id"]),
            "slot": check_exists_int(um.item["Slot"]),
            "type": check_exists_int(um.item["Type"]),
            "material": check_exists_int(um.item["Material"]),
            "rank": check_exists_int(um.item["Rank"]),
            "prefix1": check_exists_int(um.item["Prefix_1"]),
            "prefix2": check_exists_int(um.item["Prefix_2"]),
            "suffix": check_exists_int(um.item["Suffix"]),
            "greatness": check_exists_int(um.item["Greatness"]),
            "createdBlock": check_exists_int(um.item["CreatedBlock"]),
            "xp": encode_int_as_bytes(um.item["XP"]),
            "equippedAdventurerId": check_exists_int(um.item["Adventurer"]),
            "bag": check_exists_int(um.item["Bag"]),
            "price": check_exists_int(um.bid["price"]),
            "expiry": check_exists_timestamp(um.bid["expiry"]),
            "bidder": check_exists_int(um.bid["bidder"]),
            "status": encode_int_as_bytes(um.bid["status"]),
            "lastUpdated": block_time,
        }
        insert_merchant_doc = {
            "marketId": check_exists_int(um.market_item_id),
            "id": None,
            "owner": None,
            "ownerAdventurerId": None,
            "claimedTime": None,
            "item": check_exists_int(um.item["Id"]),
            "slot": check_exists_int(um.item["Slot"]),
            "type": check_exists_int(um.item["Type"]),
            "material": check_exists_int(um.item["Material"]),
            "rank": check_exists_int(um.item["Rank"]),
            "prefix1": check_exists_int(um.item["Prefix_1"]),
            "prefix2": check_exists_int(um.item["Prefix_2"]),
            "suffix": check_exists_int(um.item["Suffix"]),
            "greatness": check_exists_int(um.item["Greatness"]),
            "createdBlock": check_exists_int(um.item["CreatedBlock"]),
            "xp": encode_int_as_bytes(um.item["XP"]),
            "equippedAdventurerId": check_exists_int(um.item["Adventurer"]),
            "bag": check_exists_int(um.item["Bag"]),
            "price": check_exists_int(um.bid["price"]),
            "expiry": check_exists_timestamp(um.bid["expiry"]),
            "bidder": check_exists_int(um.bid["bidder"]),
            "status": encode_int_as_bytes(um.bid["status"]),
            "lastUpdated": block_time,
        }
        market_item = await info.storage.find_one(
            "items",
            {
                "marketId": check_exists_int(um.market_item_id),
            },
        )
        if market_item:
            await info.storage.find_one_and_update(
                "items",
                {
                    "marketId": check_exists_int(um.market_item_id),
                },
                {
                    "$set": update_merchant_doc,
                },
            )
        else:
            await info.storage.insert_one(
                "items",
                insert_merchant_doc,
            )
        print("- [update merchant item]", um.market_item_id, "->", um.bid)

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
    )

    config = Config(network, adventurer, beast, loot, start_block)

    # ctx can be accessed by the callbacks in `info`.
    if server_url == "localhost:7171" or server_url == "apibara:7171":
        ctx = {"network": "starknet-devnet"}
    else:
        ctx = {"network": "starknet-testnet"}
    await runner.run(LootSurvivorIndexer(config), ctx=ctx)
