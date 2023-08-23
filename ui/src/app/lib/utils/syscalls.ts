import { InvokeTransactionReceiptResponse } from "starknet";
import { GameData } from "@/app/components/GameData";
import { FormData, UpgradeStats } from "@/app/types";
import { useContracts } from "@/app/hooks/useContracts";
import {
  useAccount,
  useContractWrite,
  useTransactionManager,
  useWaitForTransaction,
} from "@starknet-react/core";
import useTransactionCartStore from "@/app/hooks/useTransactionCartStore";
import useLoadingStore from "@/app/hooks/useLoadingStore";
import useUIStore from "@/app/hooks/useUIStore";
import { QueryKey, useQueriesStore } from "@/app/hooks/useQueryStore";
import { getKeyFromValue, stringToFelt, getRandomNumber } from ".";
import { parseEvents } from "./parseEvents";
import useAdventurerStore from "@/app/hooks/useAdventurerStore";

export function Syscalls() {
  const gameData = new GameData();

  const { gameContract, lordsContract } = useContracts();
  const { addTransaction } = useTransactionManager();
  const { account } = useAccount();
  const { data: queryData, resetData, setData } = useQueriesStore();

  const formatAddress = account ? account.address : "0x0";
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const addToCalls = useTransactionCartStore((state) => state.addToCalls);
  const calls = useTransactionCartStore((state) => state.calls);
  const handleSubmitCalls = useTransactionCartStore(
    (state) => state.handleSubmitCalls
  );
  const startLoading = useLoadingStore((state) => state.startLoading);
  const stopLoading = useLoadingStore((state) => state.stopLoading);
  const setTxAccepted = useLoadingStore((state) => state.setTxAccepted);
  const hash = useLoadingStore((state) => state.hash);
  const setTxHash = useLoadingStore((state) => state.setTxHash);
  const { writeAsync } = useContractWrite({ calls });
  const equipItems = useUIStore((state) => state.equipItems);
  const setEquipItems = useUIStore((state) => state.setEquipItems);
  const setDropItems = useUIStore((state) => state.setDropItems);
  const removeEntrypointFromCalls = useTransactionCartStore(
    (state) => state.removeEntrypointFromCalls
  );

  const spawn = async (formData: FormData) => {
    const mintLords = {
      contractAddress: lordsContract?.address ?? "",
      entrypoint: "mint",
      calldata: [formatAddress, (100 * 10 ** 18).toString(), "0"],
    };
    addToCalls(mintLords);

    const approveLordsTx = {
      contractAddress: lordsContract?.address ?? "",
      entrypoint: "approve",
      calldata: [gameContract?.address ?? "", (100 * 10 ** 18).toString(), "0"],
    };
    addToCalls(approveLordsTx);

    const mintAdventurerTx = {
      contractAddress: gameContract?.address ?? "",
      entrypoint: "start",
      calldata: [
        "0x0628d41075659afebfc27aa2aab36237b08ee0b112debd01e56d037f64f6082a",
        getKeyFromValue(gameData.ITEMS, formData.startingWeapon) ?? "",
        stringToFelt(formData.name).toString(),
        getRandomNumber(8000),
        getKeyFromValue(gameData.CLASSES, formData.class) ?? "",
        "1",
        formData.startingStrength,
        formData.startingDexterity,
        formData.startingVitality,
        formData.startingIntelligence,
        formData.startingWisdom,
        formData.startingCharisma,
      ],
    };

    addToCalls(mintAdventurerTx);
    startLoading(
      "Create",
      "Spawning Adventurer",
      "adventurersByOwnerQuery",
      undefined,
      `You have spawned ${formData.name}!`
    );
    const tx = await handleSubmitCalls(writeAsync);
    const receipt = await account?.waitForTransaction(tx.transaction_hash, {
      retryInterval: 1000,
    });
    setTxHash(tx.transaction_hash);
    addTransaction({
      hash: tx?.transaction_hash,
      metadata: {
        method: `Spawn ${formData.name}`,
      },
    });
    const events = parseEvents(receipt as InvokeTransactionReceiptResponse);
    console.log(events);
    const adventurerState = events.find((event) => event.name === "StartGame")
      .data[0];
    setData("adventurersByOwnerQuery", {
      adventurers: [
        ...(queryData.adventurersByOwnerQuery?.adventurers ?? []),
        adventurerState,
      ],
    });
    setData("adventurerByIdQuery", {
      adventurers: [adventurerState],
    });
    setData("beastQuery", {
      beasts: [
        events.find((event) => event.name === "AmbushedByBeast").data[2],
      ],
    });
    setData("battlesByBeastQuery", {
      battles: [
        events.find((event) => event.name === "AmbushedByBeast").data[3],
      ],
    });
    // Create base items
    for (let i = 0; i <= 101; i++) {
      setData("latestMarketItemsQuery", {
        items: [
          ...(queryData.latestMarketItemsQuery?.items ?? []),
          {
            item: gameData.ITEMS[i],
            adventurerId: adventurerState["id"],
            owner: false,
            equipped: false,
            ownerAddress: adventurerState["owner"],
            xp: 0,
            special1: null,
            special2: null,
            special3: null,
            isAvailable: false,
            purchasedTime: null,
            timestamp: new Date(),
          },
        ],
      });
    }
    setData("itemsByAdventurerQuery", {
      items: [
        {
          item: adventurerState.weapon,
          adventurerId: adventurerState["id"],
          owner: true,
          equipped: true,
          ownerAddress: adventurerState["owner"],
          xp: 0,
          special1: null,
          special2: null,
          special3: null,
          isAvailable: false,
          purchasedTime: null,
          timestamp: new Date(),
        },
      ],
    });
    stopLoading(`You have spawned ${formData.name}!`);
  };

  const explore = async (till_beast: boolean) => {
    addToCalls({
      contractAddress: gameContract?.address ?? "",
      entrypoint: "explore",
      calldata: [adventurer?.id?.toString() ?? "", "0", till_beast ? "1" : "0"],
    });
    startLoading(
      "Explore",
      "Exploring",
      "discoveryByTxHashQuery",
      adventurer?.id
    );

    const tx = await handleSubmitCalls(writeAsync);
    const receipt = await account?.waitForTransaction(tx.transaction_hash, {
      retryInterval: 1000,
    });

    setTxHash(tx.transaction_hash);
    addTransaction({
      hash: tx.transaction_hash,
      metadata: {
        method: `Explore with ${adventurer?.name}`,
      },
    });

    const events = parseEvents(receipt as InvokeTransactionReceiptResponse);
    setData("adventurerByIdQuery", {
      adventurers: [events.find((event) => event.name === "StartGame").data[0]],
    });
    // If new items available set them as available
    for (let i = 0; i <= 101; i++) {
      setData("latestMarketItemsQuery", null, "isAvailable", i);
      setData("latestMarketItemsQuery", new Date(), "timestamp", i);
    }
    setEquipItems([]);
    setDropItems([]);
  };

  const attack = async (tillDeath: boolean, beastData: any) => {
    resetData("latestMarketItemsQuery");
    addToCalls({
      contractAddress: gameContract?.address ?? "",
      entrypoint: "attack",
      calldata: [adventurer?.id?.toString() ?? "", "0", tillDeath ? "1" : "0"],
    });
    startLoading(
      "Attack",
      "Attacking",
      "battlesByTxHashQuery",
      adventurer?.id,
      { beast: beastData }
    );
    const tx = await handleSubmitCalls(writeAsync);
    const receipt = await account?.waitForTransaction(tx.transaction_hash, {
      retryInterval: 1000,
    });
    setTxHash(tx.transaction_hash);
    addTransaction({
      hash: tx.transaction_hash,
      metadata: {
        method: `Attack ${beastData.beast}`,
      },
    });

    setEquipItems([]);
    setDropItems([]);
  };

  const flee = async (tillDeath: boolean, beastData: any) => {
    addToCalls({
      contractAddress: gameContract?.address ?? "",
      entrypoint: "flee",
      calldata: [adventurer?.id?.toString() ?? "", "0", tillDeath ? "1" : "0"],
    });
    startLoading("Flee", "Fleeing", "battlesByTxHashQuery", adventurer?.id, {
      beast: beastData,
    });
    const tx = await handleSubmitCalls(writeAsync);
    const receipt = await account?.waitForTransaction(tx.transaction_hash, {
      retryInterval: 1000,
    });
    setTxHash(tx.transaction_hash);
    addTransaction({
      hash: tx.transaction_hash,
      metadata: {
        method: `Flee ${beastData.beast}`,
      },
    });
    // Add optimistic data
    const events = parseEvents(receipt as InvokeTransactionReceiptResponse);
    // Update adventurer
    setData("adventurerByIdQuery", {
      adventurers: [
        events.find(
          (event) =>
            event.name === "FleeFailed" || event.name === "FleeSucceeded"
        ).data,
      ],
    });
    setEquipItems([]);
    setDropItems([]);
  };

  const upgrade = async (
    upgrades: UpgradeStats,
    purchaseItems: any[],
    potionAmount: number
  ) => {
    startLoading(
      "Upgrade",
      "Upgrading",
      "adventurerByIdQuery",
      adventurer?.id,
      {
        Stats: upgrades,
        Items: purchaseItems,
        Potions: potionAmount,
      }
    );
    const tx = await handleSubmitCalls(writeAsync);
    const receipt = await account?.waitForTransaction(tx.transaction_hash, {
      retryInterval: 1000,
    });
    setTxHash(tx.transaction_hash);
    addTransaction({
      hash: tx.transaction_hash,
      metadata: {
        method: `Upgrade`,
      },
    });

    // Add optimistic data
    const events = parseEvents(receipt as InvokeTransactionReceiptResponse);
    // Update adventurer
    setData("adventurerByIdQuery", {
      adventurers: [
        events.find((event) => event.name === "AdventurerUpgraded").data,
      ],
    });

    // Reset items to no availability
    for (let i = 0; i <= 101; i++) {
      setData("latestMarketItemsQuery", null, "isAvailable", i);
      setData("latestMarketItemsQuery", new Date(), "timestamp", i);
    }

    // Add purchased items
    const eventPurchasedItems = events.find(
      (event) => event.name === "PurchasedItems"
    ).data.purchasedItems;
    eventPurchasedItems.forEach((value: any, index: number) => {
      setData("itemsByAdventurerQuery", true, "owner", index);
      setData(
        "itemsByAdventurerQuery",
        events.find((event) => event.name === "AdventurerUpgraded").data
          .adventurerState["owner"],
        "ownerAddress",
        index
      );
      setData("itemsByAdventurerQuery", new Date(), "purchasedItem", index);
      setData("itemsByAdventurerQuery", new Date(), "timestamp", index);
    });
    //
  };

  const multicall = async (
    loadingMessage: string[],
    loadingQuery: QueryKey | null,
    notification: string[]
  ) => {
    const items: string[] = [];

    for (const dict of calls) {
      if (
        dict.hasOwnProperty("entrypoint") &&
        (dict["entrypoint"] === "bid_on_item" ||
          dict["entrypoint"] === "claim_item")
      ) {
        if (Array.isArray(dict.calldata)) {
          items.push(dict.calldata[0]?.toString() ?? "");
        }
      }
      if (dict["entrypoint"] === "equip") {
        if (Array.isArray(dict.calldata)) {
          items.push(dict.calldata[2]?.toString() ?? "");
        }
      }
    }
    startLoading(
      "Multicall",
      loadingMessage,
      loadingQuery,
      adventurer?.id,
      notification
    );

    const tx = await handleSubmitCalls(writeAsync);
    const receipt = await account?.waitForTransaction(tx.transaction_hash, {
      retryInterval: 1000,
    });
    setTxHash(tx?.transaction_hash);
    addTransaction({
      hash: tx.transaction_hash,
      metadata: {
        method: "Multicall",
        marketIds: items,
      },
    });
    const events = parseEvents(receipt as InvokeTransactionReceiptResponse);
  };

  return { spawn, explore, attack, flee, upgrade, multicall };
}
