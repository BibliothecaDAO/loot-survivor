import { ReactElement, JSXElementConstructor } from "react";
import {
  InvokeTransactionReceiptResponse,
  Contract,
  AccountInterface,
  GetTransactionReceiptResponse,
  Provider,
} from "starknet";
import { GameData } from "@/app/lib/data/GameData";
import {
  Adventurer,
  Call,
  FormData,
  NullAdventurer,
  UpgradeStats,
  TransactionParams,
  Item,
  ItemPurchase,
  Battle,
  Beast,
  SpecialBeast,
  Discovery,
} from "@/app/types";
import { getKeyFromValue, stringToFelt, indexAddress } from "@/app/lib/utils";
import { parseEvents } from "@/app/lib/utils/parseEvents";
import { processNotifications } from "@/app/components/notifications/NotificationHandler";
import Storage from "@/app/lib/storage";
import { BurnerStorage } from "@/app/types";
import { Connector } from "@starknet-react/core";
import {
  checkArcadeConnector,
  providerInterfaceCamel,
} from "@/app/lib/connectors";
import { QueryData, QueryKey } from "@/app/hooks/useQueryStore";
import { AdventurerClass } from "@/app/lib/classes";
import { ScreenPage } from "@/app/hooks/useUIStore";
import { TRANSACTION_WAIT_RETRY_INTERVAL } from "@/app/lib/constants";

const rpc_addr = process.env.NEXT_PUBLIC_RPC_URL;
const provider = new Provider({
  nodeUrl: rpc_addr!,
});

export interface SyscallsProps {
  gameContract: Contract;
  lordsContract: Contract;
  beastsContract: Contract;
  addTransaction: ({ hash, metadata }: TransactionParams) => void;
  queryData: QueryData;
  resetData: (queryKey?: QueryKey) => void;
  setData: (
    queryKey: QueryKey,
    data: any,
    attribute?: string,
    index?: number
  ) => void;
  adventurer: AdventurerClass;
  addToCalls: (value: Call) => void;
  calls: Call[];
  handleSubmitCalls: (
    account: AccountInterface,
    calls: Call[],
    isArcade: boolean,
    ethBalance: number,
    showTopUpDialog: (show: boolean) => void,
    setTopUpAccount: (account: string) => void
  ) => Promise<any>;
  startLoading: (
    type: string,
    pendingMessage: string | string[],
    data: any,
    adventurer: number | undefined
  ) => void;
  stopLoading: (
    notificationData: any,
    error?: boolean | undefined,
    type?: string
  ) => void;
  setTxHash: (hash: string) => void;
  setEquipItems: (value: string[]) => void;
  setDropItems: (value: string[]) => void;
  setDeathMessage: (
    deathMessage: ReactElement<any, string | JSXElementConstructor<any>>
  ) => void;
  showDeathDialog: (value: boolean) => void;
  setScreen: (value: ScreenPage) => void;
  setAdventurer: (value: Adventurer) => void;
  setStartOption: (value: string) => void;
  ethBalance: bigint;
  showTopUpDialog: (value: boolean) => void;
  setTopUpAccount: (value: string) => void;
  setEstimatingFee: (value: boolean) => void;
  account: AccountInterface;
  resetCalls: () => void;
  setSpecialBeastDefeated: (value: boolean) => void;
  setSpecialBeast: (value: SpecialBeast) => void;
  connector?: Connector;
  getEthBalance: () => Promise<void>;
  getBalances: () => Promise<void>;
  setIsMintingLords: (value: boolean) => void;
  setUpdateDeathPenalty: (value: boolean) => void;
}

function handleEquip(
  events: any[],
  setData: (
    queryKey: QueryKey,
    data: any,
    attribute?: string,
    index?: number
  ) => void,
  setAdventurer: (value: Adventurer) => void,
  queryData: QueryData
) {
  const equippedItemsEvents = events.filter(
    (event) => event.name === "EquippedItems"
  );
  // Equip items that are not purchases
  let equippedItems: Item[] = [];
  let unequippedItems: Item[] = [];
  for (let equippedItemsEvent of equippedItemsEvents) {
    setData("adventurerByIdQuery", {
      adventurers: [equippedItemsEvent.data[0]],
    });
    setAdventurer(equippedItemsEvent.data[0]);
    for (let equippedItem of equippedItemsEvent.data[1]) {
      const ownedItem = queryData.itemsByAdventurerQuery?.items.find(
        (item: Item) => item.item == equippedItem
      );
      if (ownedItem) {
        const modifiedItem = { ...ownedItem };
        modifiedItem.equipped = true;
        equippedItems.push(modifiedItem);
      }
    }
    for (let unequippedItem of equippedItemsEvent.data[2]) {
      const ownedItem = queryData.itemsByAdventurerQuery?.items.find(
        (item: Item) => item.item == unequippedItem
      );
      if (ownedItem) {
        const modifiedItem = { ...ownedItem };
        modifiedItem.equipped = false;
        unequippedItems.push(modifiedItem);
      }
    }
  }
  return { equippedItems, unequippedItems };
}

function handleDrop(
  events: any[],
  setData: (
    queryKey: QueryKey,
    data: any,
    attribute?: string,
    index?: number
  ) => void,
  setAdventurer: (value: Adventurer) => void
) {
  const droppedItemsEvents = events.filter(
    (event) => event.name === "DroppedItems"
  );
  let droppedItems: string[] = [];
  for (let droppedItemsEvent of droppedItemsEvents) {
    setData("adventurerByIdQuery", {
      adventurers: [droppedItemsEvent.data[0]],
    });
    setAdventurer(droppedItemsEvent.data[0]);
    for (let droppedItem of droppedItemsEvent.data[1]) {
      droppedItems.push(droppedItem);
    }
  }
  return droppedItems;
}

export function syscalls({
  gameContract,
  lordsContract,
  beastsContract,
  addTransaction,
  account,
  queryData,
  resetData,
  setData,
  adventurer,
  addToCalls,
  calls,
  handleSubmitCalls,
  startLoading,
  stopLoading,
  setTxHash,
  setEquipItems,
  setDropItems,
  setDeathMessage,
  showDeathDialog,
  setScreen,
  setAdventurer,
  setStartOption,
  ethBalance,
  showTopUpDialog,
  setTopUpAccount,
  setEstimatingFee,
  resetCalls,
  setSpecialBeastDefeated,
  setSpecialBeast,
  connector,
  getEthBalance,
  getBalances,
  setIsMintingLords,
  setUpdateDeathPenalty,
}: SyscallsProps) {
  const gameData = new GameData();

  const updateItemsXP = (adventurerState: Adventurer, itemsXP: number[]) => {
    const weapon = adventurerState.weapon;
    const weaponIndex = queryData.itemsByAdventurerQuery?.items.findIndex(
      (item: Item) => item.item == weapon
    );
    const chest = adventurerState.chest;
    setData("itemsByAdventurerQuery", itemsXP[0], "xp", weaponIndex);
    const chestIndex = queryData.itemsByAdventurerQuery?.items.findIndex(
      (item: Item) => item.item == chest
    );
    setData("itemsByAdventurerQuery", itemsXP[1], "xp", chestIndex);
    const head = adventurerState.head;
    const headIndex = queryData.itemsByAdventurerQuery?.items.findIndex(
      (item: Item) => item.item == head
    );
    setData("itemsByAdventurerQuery", itemsXP[2], "xp", headIndex);
    const waist = adventurerState.waist;
    const waistIndex = queryData.itemsByAdventurerQuery?.items.findIndex(
      (item: Item) => item.item == waist
    );
    setData("itemsByAdventurerQuery", itemsXP[3], "xp", waistIndex);
    const foot = adventurerState.foot;
    const footIndex = queryData.itemsByAdventurerQuery?.items.findIndex(
      (item: Item) => item.item == foot
    );
    setData("itemsByAdventurerQuery", itemsXP[4], "xp", footIndex);
    const hand = adventurerState.hand;
    const handIndex = queryData.itemsByAdventurerQuery?.items.findIndex(
      (item: Item) => item.item == hand
    );
    setData("itemsByAdventurerQuery", itemsXP[5], "xp", handIndex);
    const neck = adventurerState.neck;
    const neckIndex = queryData.itemsByAdventurerQuery?.items.findIndex(
      (item: Item) => item.item == neck
    );
    setData("itemsByAdventurerQuery", itemsXP[6], "xp", neckIndex);
    const ring = adventurerState.ring;
    const ringIndex = queryData.itemsByAdventurerQuery?.items.findIndex(
      (item: Item) => item.item == ring
    );
    setData("itemsByAdventurerQuery", itemsXP[7], "xp", ringIndex);
  };

  const setDeathNotification = (
    type: string,
    notificationData: any,
    adventurer?: Adventurer,
    battles?: Battle[],
    hasBeast?: boolean
  ) => {
    const notifications = processNotifications(
      type,
      notificationData,
      adventurer,
      hasBeast,
      battles
    );
    // In the case of a chain of notifications we are only interested in the last
    setDeathMessage(notifications[notifications.length - 1].message);
    showDeathDialog(true);
  };

  const spawn = async (
    formData: FormData,
    goldenTokenId: string,
    costToPlay?: number
  ) => {
    const storage: BurnerStorage = Storage.get("burners");
    let interfaceCamel = "";
    const isArcade = checkArcadeConnector(connector!);
    if (isArcade) {
      const walletProvider = storage[account?.address!].masterAccountProvider;
      interfaceCamel = providerInterfaceCamel(walletProvider);
    } else {
      interfaceCamel = providerInterfaceCamel(connector!.id);
    }

    const approveLordsSpendingTx = {
      contractAddress: lordsContract?.address ?? "",
      entrypoint: "approve",
      calldata: [gameContract?.address ?? "", costToPlay!.toString(), "0"],
    }; // Approve dynamic LORDS to be spent each time spawn is called based on the get_cost_to_play

    const mintAdventurerTx = {
      contractAddress: gameContract?.address ?? "",
      entrypoint: "new_game",
      calldata: [
        process.env.NEXT_PUBLIC_DAO_ADDRESS ?? "",
        getKeyFromValue(gameData.ITEMS, formData.startingWeapon) ?? "",
        stringToFelt(formData.name).toString(),
        goldenTokenId,
        "0",
        interfaceCamel,
      ],
    };

    addToCalls(mintAdventurerTx);

    const payWithLordsCalls = [
      ...calls,
      approveLordsSpendingTx,
      mintAdventurerTx,
    ];

    const payWithGoldenTokenCalls = [...calls, mintAdventurerTx];

    const spawnCalls =
      goldenTokenId === "0" ? payWithLordsCalls : payWithGoldenTokenCalls;

    startLoading(
      "Create",
      "Spawning Adventurer",
      "adventurersByOwnerQuery",
      undefined
    );
    try {
      const tx = await handleSubmitCalls(
        account,
        spawnCalls,
        isArcade,
        Number(ethBalance),
        showTopUpDialog,
        setTopUpAccount
      );
      addTransaction({
        hash: tx?.transaction_hash,
        metadata: {
          method: `Spawn ${formData.name}`,
        },
      });

      const receipt = await provider?.waitForTransaction(tx?.transaction_hash, {
        retryInterval: TRANSACTION_WAIT_RETRY_INTERVAL,
      });
      // Handle if the tx was reverted
      if (
        (receipt as GetTransactionReceiptResponse).execution_status ===
        "REVERTED"
      ) {
        throw new Error(
          (receipt as GetTransactionReceiptResponse).revert_reason
        );
      }
      // Here we need to process the StartGame event first and use the output for AmbushedByBeast event
      const startGameEvents = await parseEvents(
        receipt as InvokeTransactionReceiptResponse,
        undefined,
        beastsContract.address,
        "StartGame"
      );
      const events = await parseEvents(
        receipt as InvokeTransactionReceiptResponse,
        {
          name: formData["name"],
          startBlock: startGameEvents[0].data[0].startBlock,
          revealBlock: startGameEvents[0].data[0].revealBlock,
          createdTime: new Date(),
        }
      );
      const adventurerState = events.find(
        (event) => event.name === "AmbushedByBeast"
      ).data[0];
      setData("adventurersByOwnerQuery", {
        adventurers: [
          ...(queryData.adventurersByOwnerQuery?.adventurers ?? []),
          adventurerState,
        ],
      });
      setData("adventurerByIdQuery", {
        adventurers: [adventurerState],
      });
      setAdventurer(adventurerState);
      setData("latestDiscoveriesQuery", {
        discoveries: [
          events.find((event) => event.name === "AmbushedByBeast").data[1],
        ],
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
      stopLoading(`You have spawned ${formData.name}!`, false, "Create");
      setAdventurer(adventurerState);
      setScreen("play");
      getEthBalance();
    } catch (e) {
      console.log(e);
      stopLoading(e, true);
    }
  };

  const explore = async (till_beast: boolean) => {
    const exploreTx = {
      contractAddress: gameContract?.address ?? "",
      entrypoint: "explore",
      calldata: [adventurer?.id?.toString() ?? "", till_beast ? "1" : "0"],
    };
    addToCalls(exploreTx);

    const isArcade = checkArcadeConnector(connector!);
    startLoading(
      "Explore",
      "Exploring",
      "discoveryByTxHashQuery",
      adventurer?.id
    );
    try {
      const tx = await handleSubmitCalls(
        account,
        [...calls, exploreTx],
        isArcade,
        Number(ethBalance),
        showTopUpDialog,
        setTopUpAccount
      );
      setTxHash(tx?.transaction_hash);
      addTransaction({
        hash: tx?.transaction_hash,
        metadata: {
          method: `Explore with ${adventurer?.name}`,
        },
      });
      const receipt = await provider?.waitForTransaction(tx?.transaction_hash, {
        retryInterval: TRANSACTION_WAIT_RETRY_INTERVAL,
      });
      // Handle if the tx was reverted
      if (
        (receipt as GetTransactionReceiptResponse).execution_status ===
        "REVERTED"
      ) {
        throw new Error(
          (receipt as GetTransactionReceiptResponse).revert_reason
        );
      }
      const events = await parseEvents(
        receipt as InvokeTransactionReceiptResponse,
        queryData.adventurerByIdQuery?.adventurers[0] ?? NullAdventurer
      );

      // If there are any equip or drops, do them first
      const { equippedItems, unequippedItems } = handleEquip(
        events,
        setData,
        setAdventurer,
        queryData
      );
      const droppedItems = handleDrop(events, setData, setAdventurer);

      const filteredEquips = queryData.itemsByAdventurerQuery?.items?.filter(
        (item: Item) =>
          !equippedItems.some((equippedItem) => equippedItem.item == item.item)
      );
      const filteredUnequips = filteredEquips?.filter(
        (item: Item) =>
          !unequippedItems.some((droppedItem) => droppedItem.item == item.item)
      );
      const filteredDrops = [
        ...(filteredUnequips ?? []),
        ...equippedItems,
        ...unequippedItems,
      ]?.filter((item: Item) => !droppedItems.includes(item.item ?? ""));
      setData("itemsByAdventurerQuery", {
        items: [...filteredDrops],
      });

      const discoveries: Discovery[] = [];

      const filteredDiscoveries = events.filter(
        (event) =>
          event.name === "DiscoveredHealth" ||
          event.name === "DiscoveredGold" ||
          event.name === "DiscoveredXP" ||
          event.name === "DodgedObstacle" ||
          event.name === "HitByObstacle"
      );
      if (filteredDiscoveries.length > 0) {
        for (let discovery of filteredDiscoveries) {
          setData("adventurerByIdQuery", {
            adventurers: [discovery.data[0]],
          });
          setAdventurer(discovery.data[0]);
          discoveries.unshift(discovery.data[1]);
          if (
            discovery.name === "DodgedObstacle" ||
            discovery.name === "HitByObstacle"
          ) {
            updateItemsXP(discovery.data[0], discovery.data[2]);
            const itemsLeveledUpEvents = events.filter(
              (event) => event.name === "ItemsLeveledUp"
            );
            for (let itemsLeveledUpEvent of itemsLeveledUpEvents) {
              for (let itemLeveled of itemsLeveledUpEvent.data[1]) {
                const ownedItemIndex =
                  queryData.itemsByAdventurerQuery?.items.findIndex(
                    (item: Item) => item.item == itemLeveled.item
                  );
                if (itemLeveled.suffixUnlocked) {
                  setData(
                    "itemsByAdventurerQuery",
                    itemLeveled.special1,
                    "special1",
                    ownedItemIndex
                  );
                }
                if (itemLeveled.prefixesUnlocked) {
                  setData(
                    "itemsByAdventurerQuery",
                    itemLeveled.special2,
                    "special2",
                    ownedItemIndex
                  );
                  setData(
                    "itemsByAdventurerQuery",
                    itemLeveled.special3,
                    "special3",
                    ownedItemIndex
                  );
                }
              }
            }
          }
        }
      }

      const filteredBeastDiscoveries = events.filter(
        (event) => event.name === "DiscoveredBeast"
      );
      if (filteredBeastDiscoveries.length > 0) {
        for (let discovery of filteredBeastDiscoveries) {
          setData("battlesByBeastQuery", {
            battles: null,
          });
          setData("adventurerByIdQuery", {
            adventurers: [discovery.data[0]],
          });
          setAdventurer(discovery.data[0]);
          discoveries.unshift(discovery.data[1]);
          setData("beastQuery", { beasts: [discovery.data[2]] });
        }
      }

      const filteredBeastAmbushes = events.filter(
        (event) => event.name === "AmbushedByBeast"
      );
      if (filteredBeastAmbushes.length > 0) {
        setData("battlesByBeastQuery", {
          battles: null,
        });
        for (let discovery of filteredBeastAmbushes) {
          setData("adventurerByIdQuery", {
            adventurers: [discovery.data[0]],
          });
          setAdventurer(discovery.data[0]);
          discoveries.unshift(discovery.data[1]);
          setData("beastQuery", { beasts: [discovery.data[2]] });
          setData("battlesByBeastQuery", {
            battles: [discovery.data[3]],
          });
        }
      }

      const idleDeathPenaltyEvents = events.filter(
        (event) => event.name === "IdleDeathPenalty"
      );
      if (idleDeathPenaltyEvents.length > 0) {
        for (let idleDeathPenaltyEvent of idleDeathPenaltyEvents) {
          setData("adventurerByIdQuery", {
            adventurers: [idleDeathPenaltyEvent.data[0]],
          });
          setAdventurer(idleDeathPenaltyEvent.data[0]);
          discoveries.unshift(idleDeathPenaltyEvent.data[2]);
        }
      }

      const reversedDiscoveries = discoveries.slice().reverse();

      const adventurerDiedEvents = events.filter(
        (event) => event.name === "AdventurerDied"
      );
      for (let adventurerDiedEvent of adventurerDiedEvents) {
        setData("adventurerByIdQuery", {
          adventurers: [adventurerDiedEvent.data[0]],
        });
        const deadAdventurerIndex =
          queryData.adventurersByOwnerQuery?.adventurers.findIndex(
            (adventurer: Adventurer) =>
              adventurer.id == adventurerDiedEvent.data[0].id
          );
        setData("adventurersByOwnerQuery", 0, "health", deadAdventurerIndex);
        setAdventurer(adventurerDiedEvent.data[0]);
        const killedByObstacle =
          reversedDiscoveries[0]?.discoveryType == "Obstacle" &&
          reversedDiscoveries[0]?.adventurerHealth == 0;
        const killedByPenalty =
          !reversedDiscoveries[0]?.discoveryType &&
          reversedDiscoveries[0]?.adventurerHealth == 0;
        const killedByAmbush =
          reversedDiscoveries[0]?.ambushed &&
          reversedDiscoveries[0]?.adventurerHealth == 0;
        if (killedByObstacle || killedByPenalty || killedByAmbush) {
          setDeathNotification(
            "Explore",
            discoveries.reverse(),
            adventurerDiedEvent.data[0]
          );
        }
        setScreen("start");
        setStartOption("create adventurer");
      }

      const upgradesAvailableEvents = events.filter(
        (event) => event.name === "UpgradesAvailable"
      );
      if (upgradesAvailableEvents.length > 0) {
        for (let upgradesAvailableEvent of upgradesAvailableEvents) {
          setData("adventurerByIdQuery", {
            adventurers: [upgradesAvailableEvent.data[0]],
          });
          setAdventurer(upgradesAvailableEvent.data[0]);
          const newItems = upgradesAvailableEvent.data[1];
          const itemData = [];
          for (let newItem of newItems) {
            itemData.unshift({
              item: newItem,
              adventurerId: upgradesAvailableEvent.data[0]["id"],
              owner: false,
              equipped: false,
              ownerAddress: upgradesAvailableEvent.data[0]["owner"],
              xp: 0,
              special1: null,
              special2: null,
              special3: null,
              isAvailable: false,
              purchasedTime: null,
              timestamp: new Date(),
            });
          }
          setData("latestMarketItemsQuery", {
            items: itemData,
          });
        }
        setScreen("upgrade");
      }

      setData("latestDiscoveriesQuery", {
        discoveries: [
          ...discoveries,
          ...(queryData.latestDiscoveriesQuery?.discoveries ?? []),
        ],
      });
      setData("discoveryByTxHashQuery", {
        discoveries: [...discoveries.reverse()],
      });

      setEquipItems([]);
      setDropItems([]);
      stopLoading(reversedDiscoveries, false, "Explore");
      getEthBalance();
      setUpdateDeathPenalty(true);
    } catch (e) {
      console.log(e);
      stopLoading(e, true);
    }
  };

  const attack = async (
    tillDeath: boolean,
    beastData: Beast,
    blockHash?: string
  ) => {
    resetData("latestMarketItemsQuery");
    // First we send the current block hash to the contract
    const setBlockHashTx: Call = {
      contractAddress: gameContract?.address ?? "",
      entrypoint: "set_starting_entropy",
      calldata: [blockHash!],
    };
    const attackTx: Call = {
      contractAddress: gameContract?.address ?? "",
      entrypoint: "attack",
      calldata: [adventurer?.id?.toString() ?? "", tillDeath ? "1" : "0"],
    };
    const attackCalls = [setBlockHashTx, attackTx];
    addToCalls(attackTx);

    const isArcade = checkArcadeConnector(connector!);
    startLoading("Attack", "Attacking", "battlesByTxHashQuery", adventurer?.id);
    try {
      const tx = await handleSubmitCalls(
        account,
        [...calls, ...attackCalls],
        isArcade,
        Number(ethBalance),
        showTopUpDialog,
        setTopUpAccount
      );
      setTxHash(tx?.transaction_hash);
      addTransaction({
        hash: tx?.transaction_hash,
        metadata: {
          method: `Attack ${beastData.beast}`,
        },
      });
      const receipt = await provider?.waitForTransaction(tx?.transaction_hash, {
        retryInterval: TRANSACTION_WAIT_RETRY_INTERVAL,
      });
      // Handle if the tx was reverted
      if (
        (receipt as GetTransactionReceiptResponse).execution_status ===
        "REVERTED"
      ) {
        throw new Error(
          (receipt as GetTransactionReceiptResponse).revert_reason
        );
      }
      // reset battles by tx hash
      setData("battlesByTxHashQuery", {
        battles: null,
      });
      const events = await parseEvents(
        receipt as InvokeTransactionReceiptResponse,
        queryData.adventurerByIdQuery?.adventurers[0] ?? NullAdventurer,
        indexAddress(beastsContract.address)
      );

      // If there are any equip or drops, do them first
      const { equippedItems, unequippedItems } = handleEquip(
        events,
        setData,
        setAdventurer,
        queryData
      );
      const droppedItems = handleDrop(events, setData, setAdventurer);

      const filteredEquips = queryData.itemsByAdventurerQuery?.items?.filter(
        (item: Item) =>
          !equippedItems.some((equippedItem) => equippedItem.item == item.item)
      );
      const filteredUnequips = filteredEquips?.filter(
        (item: Item) =>
          !unequippedItems.some((droppedItem) => droppedItem.item == item.item)
      );
      const filteredDrops = [
        ...(filteredUnequips ?? []),
        ...equippedItems,
        ...unequippedItems,
      ]?.filter((item: Item) => !droppedItems.includes(item.item ?? ""));
      setData("itemsByAdventurerQuery", {
        items: [...filteredDrops],
      });

      const battles = [];

      const attackedBeastEvents = events.filter(
        (event) =>
          event.name === "AttackedBeast" || event.name === "AttackedByBeast"
      );
      for (let attackedBeastEvent of attackedBeastEvents) {
        setData("adventurerByIdQuery", {
          adventurers: [attackedBeastEvent.data[0]],
        });
        setAdventurer(attackedBeastEvent.data[0]);
        battles.unshift(attackedBeastEvent.data[1]);
        setData(
          "beastQuery",
          attackedBeastEvent.data[0].beastHealth,
          "health",
          0
        );
      }

      const slayedBeastEvents = events.filter(
        (event) => event.name === "SlayedBeast"
      );
      for (let slayedBeastEvent of slayedBeastEvents) {
        setData("adventurerByIdQuery", {
          adventurers: [slayedBeastEvent.data[0]],
        });
        setAdventurer(slayedBeastEvent.data[0]);
        battles.unshift(slayedBeastEvent.data[1]);
        updateItemsXP(slayedBeastEvent.data[0], slayedBeastEvent.data[2]);
        setData(
          "beastQuery",
          slayedBeastEvent.data[0].beastHealth,
          "health",
          0
        );
        const itemsLeveledUpEvents = events.filter(
          (event) => event.name === "ItemsLeveledUp"
        );
        for (let itemsLeveledUpEvent of itemsLeveledUpEvents) {
          for (let itemLeveled of itemsLeveledUpEvent.data[1]) {
            const ownedItemIndex =
              queryData.itemsByAdventurerQuery?.items.findIndex(
                (item: Item) => item.item == itemLeveled.item
              );
            if (itemLeveled.suffixUnlocked) {
              setData(
                "itemsByAdventurerQuery",
                itemLeveled.special1,
                "special1",
                ownedItemIndex
              );
            }
            if (itemLeveled.prefixesUnlocked) {
              setData(
                "itemsByAdventurerQuery",
                itemLeveled.special2,
                "special2",
                ownedItemIndex
              );
              setData(
                "itemsByAdventurerQuery",
                itemLeveled.special3,
                "special3",
                ownedItemIndex
              );
            }
          }
        }

        const transferEvents = events.filter(
          (event) => event.name === "Transfer"
        );
        for (let transferEvent of transferEvents) {
          if (
            slayedBeastEvent.data[1].special2 &&
            slayedBeastEvent.data[1].special3
          ) {
            setSpecialBeastDefeated(true);
            setSpecialBeast({
              data: slayedBeastEvent.data[1],
              tokenId: transferEvent.data.tokenId.low,
            });
          }
        }
      }

      const idleDeathPenaltyEvents = events.filter(
        (event) => event.name === "IdleDeathPenalty"
      );
      if (idleDeathPenaltyEvents.length > 0) {
        for (let idleDeathPenaltyEvent of idleDeathPenaltyEvents) {
          setData("adventurerByIdQuery", {
            adventurers: [idleDeathPenaltyEvent.data[0]],
          });
          setAdventurer(idleDeathPenaltyEvent.data[0]);
          battles.unshift(idleDeathPenaltyEvent.data[1]);
        }
      }

      const reversedBattles = battles.slice().reverse();

      const adventurerDiedEvents = events.filter(
        (event) => event.name === "AdventurerDied"
      );
      for (let adventurerDiedEvent of adventurerDiedEvents) {
        setData("adventurerByIdQuery", {
          adventurers: [adventurerDiedEvent.data[0]],
        });
        const deadAdventurerIndex =
          queryData.adventurersByOwnerQuery?.adventurers.findIndex(
            (adventurer: Adventurer) =>
              adventurer.id == adventurerDiedEvent.data[0].id
          );
        setData("adventurersByOwnerQuery", 0, "health", deadAdventurerIndex);
        setAdventurer(adventurerDiedEvent.data[0]);
        const killedByBeast = battles.some(
          (battle) => battle.attacker == "Beast" && battle.adventurerHealth == 0
        );
        const killedByPenalty = battles.some(
          (battle) => !battle.attacker && battle.adventurerHealth == 0
        );
        if (killedByBeast || killedByPenalty) {
          setDeathNotification(
            "Attack",
            reversedBattles,
            adventurerDiedEvent.data[0]
          );
        }
        setScreen("start");
        setStartOption("create adventurer");
      }

      const upgradesAvailableEvents = events.filter(
        (event) => event.name === "UpgradesAvailable"
      );
      if (upgradesAvailableEvents.length > 0) {
        for (let upgradesAvailableEvent of upgradesAvailableEvents) {
          setData("adventurerByIdQuery", {
            adventurers: [upgradesAvailableEvent.data[0]],
          });
          setAdventurer(upgradesAvailableEvent.data[0]);
          const newItems = upgradesAvailableEvent.data[1];
          const itemData = [];
          for (let newItem of newItems) {
            itemData.unshift({
              item: newItem,
              adventurerId: upgradesAvailableEvent.data[0]["id"],
              owner: false,
              equipped: false,
              ownerAddress: upgradesAvailableEvent.data[0]["owner"],
              xp: 0,
              special1: null,
              special2: null,
              special3: null,
              isAvailable: false,
              purchasedTime: null,
              timestamp: new Date(),
            });
          }
          setData("latestMarketItemsQuery", {
            items: itemData,
          });
        }
        setScreen("upgrade");
      }

      setData("battlesByBeastQuery", {
        battles: [
          ...battles,
          ...(queryData.battlesByBeastQuery?.battles ?? []),
        ],
      });
      setData("battlesByAdventurerQuery", {
        battles: [
          ...battles,
          ...(queryData.battlesByAdventurerQuery?.battles ?? []),
        ],
      });
      setData("battlesByTxHashQuery", {
        battles: reversedBattles,
      });

      stopLoading(reversedBattles, false, "Attack");
      setEquipItems([]);
      setDropItems([]);
      getEthBalance();
      setUpdateDeathPenalty(true);
    } catch (e) {
      console.log(e);
      stopLoading(e, true);
    }
  };

  const flee = async (tillDeath: boolean, beastData: Beast) => {
    const fleeTx = {
      contractAddress: gameContract?.address ?? "",
      entrypoint: "flee",
      calldata: [adventurer?.id?.toString() ?? "", tillDeath ? "1" : "0"],
    };
    addToCalls(fleeTx);

    const isArcade = checkArcadeConnector(connector!);
    startLoading("Flee", "Fleeing", "battlesByTxHashQuery", adventurer?.id);
    try {
      const tx = await handleSubmitCalls(
        account,
        [...calls, fleeTx],
        isArcade,
        Number(ethBalance),
        showTopUpDialog,
        setTopUpAccount
      );
      setTxHash(tx?.transaction_hash);
      addTransaction({
        hash: tx?.transaction_hash,
        metadata: {
          method: `Flee ${beastData.beast}`,
        },
      });
      const receipt = await provider?.waitForTransaction(tx?.transaction_hash, {
        retryInterval: TRANSACTION_WAIT_RETRY_INTERVAL,
      });
      // Handle if the tx was reverted
      if (
        (receipt as GetTransactionReceiptResponse).execution_status ===
        "REVERTED"
      ) {
        throw new Error(
          (receipt as GetTransactionReceiptResponse).revert_reason
        );
      }
      // Add optimistic data
      const events = await parseEvents(
        receipt as InvokeTransactionReceiptResponse,
        queryData.adventurerByIdQuery?.adventurers[0] ?? NullAdventurer
      );

      // If there are any equip or drops, do them first
      const { equippedItems, unequippedItems } = handleEquip(
        events,
        setData,
        setAdventurer,
        queryData
      );
      const droppedItems = handleDrop(events, setData, setAdventurer);

      const filteredEquips = queryData.itemsByAdventurerQuery?.items?.filter(
        (item: Item) =>
          !equippedItems.some((equippedItem) => equippedItem.item == item.item)
      );
      const filteredUnequips = filteredEquips?.filter(
        (item: Item) =>
          !unequippedItems.some((droppedItem) => droppedItem.item == item.item)
      );
      const filteredDrops = [
        ...(filteredUnequips ?? []),
        ...equippedItems,
        ...unequippedItems,
      ]?.filter((item: Item) => !droppedItems.includes(item.item ?? ""));
      setData("itemsByAdventurerQuery", {
        items: [...filteredDrops],
      });

      const battles = [];

      const fleeFailedEvents = events.filter(
        (event) =>
          event.name === "FleeFailed" || event.name === "AttackedByBeast"
      );
      for (let fleeFailedEvent of fleeFailedEvents) {
        setData("adventurerByIdQuery", {
          adventurers: [fleeFailedEvent.data[0]],
        });
        setAdventurer(fleeFailedEvent.data[0]);
        battles.unshift(fleeFailedEvent.data[1]);
      }

      const fleeSucceededEvents = events.filter(
        (event) => event.name === "FleeSucceeded"
      );
      for (let fleeSucceededEvent of fleeSucceededEvents) {
        setData("adventurerByIdQuery", {
          adventurers: [fleeSucceededEvent.data[0]],
        });
        setAdventurer(fleeSucceededEvent.data[0]);
        battles.unshift(fleeSucceededEvent.data[1]);
      }

      const idleDeathPenaltyEvents = events.filter(
        (event) => event.name === "IdleDeathPenalty"
      );
      if (idleDeathPenaltyEvents.length > 0) {
        for (let idleDeathPenaltyEvent of idleDeathPenaltyEvents) {
          setData("adventurerByIdQuery", {
            adventurers: [idleDeathPenaltyEvent.data[0]],
          });
          setAdventurer(idleDeathPenaltyEvent.data[0]);
          battles.unshift(idleDeathPenaltyEvent.data[1]);
        }
      }

      const reversedBattles = battles.slice().reverse();

      const adventurerDiedEvents = events.filter(
        (event) => event.name === "AdventurerDied"
      );
      for (let adventurerDiedEvent of adventurerDiedEvents) {
        setData("adventurerByIdQuery", {
          adventurers: [adventurerDiedEvent.data[0]],
        });
        const deadAdventurerIndex =
          queryData.adventurersByOwnerQuery?.adventurers.findIndex(
            (adventurer: Adventurer) =>
              adventurer.id == adventurerDiedEvent.data[0].id
          );
        setData("adventurersByOwnerQuery", 0, "health", deadAdventurerIndex);
        setAdventurer(adventurerDiedEvent.data[0]);
        const killedByBeast = battles.some(
          (battle) => battle.attacker == "Beast" && battle.adventurerHealth == 0
        );
        const killedByPenalty = battles.some(
          (battle) => !battle.attacker && battle.adventurerHealth == 0
        );
        if (killedByBeast || killedByPenalty) {
          setDeathNotification(
            "Flee",
            reversedBattles,
            adventurerDiedEvent.data[0]
          );
        }
        setScreen("start");
        setStartOption("create adventurer");
      }

      const upgradesAvailableEvents = events.filter(
        (event) => event.name === "UpgradesAvailable"
      );
      if (upgradesAvailableEvents.length > 0) {
        for (let upgradesAvailableEvent of upgradesAvailableEvents) {
          const newItems = upgradesAvailableEvent.data[1];
          const itemData = [];
          for (let newItem of newItems) {
            itemData.unshift({
              item: newItem,
              adventurerId: upgradesAvailableEvent.data[0]["id"],
              owner: false,
              equipped: false,
              ownerAddress: upgradesAvailableEvent.data[0]["owner"],
              xp: 0,
              special1: null,
              special2: null,
              special3: null,
              isAvailable: false,
              purchasedTime: null,
              timestamp: new Date(),
            });
          }
          setData("latestMarketItemsQuery", {
            items: itemData,
          });
        }
        setScreen("upgrade");
      }

      setData("battlesByBeastQuery", {
        battles: [
          ...battles,
          ...(queryData.battlesByBeastQuery?.battles ?? []),
        ],
      });
      setData("battlesByAdventurerQuery", {
        battles: [
          ...battles,
          ...(queryData.battlesByAdventurerQuery?.battles ?? []),
        ],
      });
      setData("battlesByTxHashQuery", {
        battles: reversedBattles,
      });
      stopLoading(reversedBattles, false, "Flee");
      setEquipItems([]);
      setDropItems([]);
      getEthBalance();
      setUpdateDeathPenalty(true);
    } catch (e) {
      console.log(e);
      stopLoading(e, true);
    }
  };

  const upgrade = async (
    upgrades: UpgradeStats,
    purchaseItems: ItemPurchase[],
    potionAmount: number,
    upgradeTx?: any
  ) => {
    const isArcade = checkArcadeConnector(connector!);
    startLoading("Upgrade", "Upgrading", "adventurerByIdQuery", adventurer?.id);
    try {
      let upgradeCalls = [];
      if (upgradeTx && Object.keys(upgradeTx).length !== 0) {
        upgradeCalls = calls.map((call) => {
          if (call.entrypoint === "upgrade") {
            return upgradeTx;
          }
          return call; // keep the original object if no replacement is needed
        });
      } else {
        upgradeCalls = calls;
      }
      const tx = await handleSubmitCalls(
        account,
        upgradeCalls,
        isArcade,
        Number(ethBalance),
        showTopUpDialog,
        setTopUpAccount
      );
      setTxHash(tx?.transaction_hash);
      addTransaction({
        hash: tx?.transaction_hash,
        metadata: {
          method: `Upgrade`,
        },
      });
      const receipt = await provider?.waitForTransaction(tx?.transaction_hash, {
        retryInterval: TRANSACTION_WAIT_RETRY_INTERVAL,
      });
      // Handle if the tx was reverted
      if (
        (receipt as GetTransactionReceiptResponse).execution_status ===
        "REVERTED"
      ) {
        throw new Error(
          (receipt as GetTransactionReceiptResponse).revert_reason
        );
      }
      // Add optimistic data
      const events = await parseEvents(
        receipt as InvokeTransactionReceiptResponse,
        queryData.adventurerByIdQuery?.adventurers[0] ?? NullAdventurer
      );

      // If there are any equip or drops, do them first
      const { equippedItems, unequippedItems } = handleEquip(
        events,
        setData,
        setAdventurer,
        queryData
      );
      const droppedItems = handleDrop(events, setData, setAdventurer);

      const adventurerUpgradedEvents = events.filter(
        (event) => event.name === "AdventurerUpgraded"
      );
      if (adventurerUpgradedEvents.length > 0) {
        for (let adventurerUpgradedEvent of adventurerUpgradedEvents) {
          setData("adventurerByIdQuery", {
            adventurers: [adventurerUpgradedEvent.data],
          });
          setAdventurer(adventurerUpgradedEvent.data);
        }
      }

      // Add purchased items
      const purchaseItemsEvents = events.filter(
        (event) => event.name === "PurchasedItems"
      );
      const purchasedItems = [];
      for (let purchasedItemEvent of purchaseItemsEvents) {
        for (let purchasedItem of purchasedItemEvent.data[1]) {
          purchasedItems.push(purchasedItem);
        }
      }
      const equippedItemsEvents = events.filter(
        (event) => event.name === "EquippedItems"
      );
      for (let equippedItemsEvent of equippedItemsEvents) {
        for (let equippedItem of equippedItemsEvent.data[1]) {
          let item = purchasedItems.find((item) => item.item === equippedItem);
          if (item) {
            item.equipped = true;
          }
        }
      }

      const filteredEquips = queryData.itemsByAdventurerQuery?.items?.filter(
        (item: Item) =>
          !equippedItems.some((equippedItem) => equippedItem.item == item.item)
      );
      const filteredUnequips = filteredEquips?.filter(
        (item: Item) =>
          !unequippedItems.some((droppedItem) => droppedItem.item == item.item)
      );
      const filteredDrops = [
        ...(filteredUnequips ?? []),
        ...equippedItems,
        ...unequippedItems,
      ]?.filter((item: Item) => !droppedItems.includes(item.item ?? ""));
      setData("itemsByAdventurerQuery", {
        items: [...filteredDrops, ...purchasedItems],
      });

      const adventurerDiedEvents = events.filter(
        (event) => event.name === "AdventurerDied"
      );
      if (adventurerDiedEvents.length > 0) {
        for (let adventurerDiedEvent of adventurerDiedEvents) {
          setData("adventurerByIdQuery", {
            adventurers: [adventurerDiedEvent.data[0]],
          });
          const deadAdventurerIndex =
            queryData.adventurersByOwnerQuery?.adventurers.findIndex(
              (adventurer: Adventurer) =>
                adventurer.id == adventurerDiedEvent.data[0].id
            );
          setData("adventurersByOwnerQuery", 0, "health", deadAdventurerIndex);
          setAdventurer(adventurerDiedEvent.data[0]);
          setDeathNotification("Upgrade", "Death Penalty");
          setScreen("start");
          setStartOption("create adventurer");
        }
      }

      // Reset items to no availability
      setData("latestMarketItemsQuery", null);
      if (events.some((event) => event.name === "AdventurerDied")) {
        setScreen("start");
        setStartOption("create adventurer");
        stopLoading("Death Penalty");
      } else {
        stopLoading(
          {
            Stats: upgrades,
            Items: purchaseItems,
            Potions: potionAmount,
          },
          false,
          "Upgrade"
        );
        setScreen("play");
      }
      getEthBalance();
      setUpdateDeathPenalty(true);
    } catch (e) {
      console.log(e);
      stopLoading(e, true);
    }
  };

  const slayIdles = async (slayAdventurers: string[]) => {
    const slayIdleAdventurersTx = {
      contractAddress: gameContract?.address ?? "",
      entrypoint: "slay_idle_adventurers",
      calldata: [slayAdventurers.length, ...slayAdventurers],
      metadata: `Slaying all Adventurers`,
    };
    addToCalls(slayIdleAdventurersTx);

    const isArcade = checkArcadeConnector(connector!);
    startLoading("Slay All Idles", "Slaying All Idles", undefined, undefined);
    try {
      const tx = await handleSubmitCalls(
        account,
        [...calls, slayIdleAdventurersTx],
        isArcade,
        Number(ethBalance),
        showTopUpDialog,
        setTopUpAccount
      );
      setTxHash(tx?.transaction_hash);
      addTransaction({
        hash: tx?.transaction_hash,
        metadata: {
          method: `Upgrade`,
        },
      });
      const receipt = await provider?.waitForTransaction(tx?.transaction_hash, {
        retryInterval: TRANSACTION_WAIT_RETRY_INTERVAL,
      });
      // Handle if the tx was reverted
      if (
        (receipt as GetTransactionReceiptResponse).execution_status ===
        "REVERTED"
      ) {
        throw new Error(
          (receipt as GetTransactionReceiptResponse).revert_reason
        );
      }
      const events = await parseEvents(
        receipt as InvokeTransactionReceiptResponse,
        queryData.adventurerByIdQuery?.adventurers[0] ?? NullAdventurer
      );

      // If there are any equip or drops, do them first
      const { equippedItems, unequippedItems } = handleEquip(
        events,
        setData,
        setAdventurer,
        queryData
      );
      const droppedItems = handleDrop(events, setData, setAdventurer);

      const filteredEquips = queryData.itemsByAdventurerQuery?.items?.filter(
        (item: Item) =>
          !equippedItems.some((equippedItem) => equippedItem.item == item.item)
      );
      const filteredUnequips = filteredEquips?.filter(
        (item: Item) =>
          !unequippedItems.some((droppedItem) => droppedItem.item == item.item)
      );
      const filteredDrops = [
        ...(filteredUnequips ?? []),
        ...equippedItems,
        ...unequippedItems,
      ]?.filter((item: Item) => !droppedItems.includes(item.item ?? ""));
      setData("itemsByAdventurerQuery", {
        items: [...filteredDrops],
      });

      stopLoading(`You have slain all idle adventurers!`);
      getEthBalance();
    } catch (e) {
      console.log(e);
      stopLoading(`You have slain all idle adventurers!`);
    }
  };

  const multicall = async (
    loadingMessage: string[],
    notification: string[],
    upgradeTx?: any
  ) => {
    const isArcade = checkArcadeConnector(connector!);
    startLoading("Multicall", loadingMessage, undefined, adventurer?.id);
    try {
      let upgradeCalls = [];
      if (upgradeTx && Object.keys(upgradeTx).length !== 0) {
        upgradeCalls = calls.map((call) => {
          if (call.entrypoint === "upgrade") {
            return upgradeTx;
          }
          return call; // keep the original object if no replacement is needed
        });
      } else {
        upgradeCalls = calls;
      }
      const tx = await handleSubmitCalls(
        account,
        upgradeCalls,
        isArcade,
        Number(ethBalance),
        showTopUpDialog,
        setTopUpAccount
      );
      setTxHash(tx?.transaction_hash);
      addTransaction({
        hash: tx?.transaction_hash,
        metadata: {
          method: "Multicall",
        },
      });
      const receipt = await provider?.waitForTransaction(tx?.transaction_hash, {
        retryInterval: TRANSACTION_WAIT_RETRY_INTERVAL,
      });
      // Handle if the tx was reverted
      if (
        (receipt as GetTransactionReceiptResponse).execution_status ===
        "REVERTED"
      ) {
        throw new Error(
          (receipt as GetTransactionReceiptResponse).revert_reason
        );
      }
      const events = await parseEvents(
        receipt as InvokeTransactionReceiptResponse,
        queryData.adventurerByIdQuery?.adventurers[0] ?? NullAdventurer
      );

      const equippedItemsEvents = events.filter(
        (event) => event.name === "EquippedItems"
      );
      // Equip items that are not purchases
      for (let equippedItemsEvent of equippedItemsEvents) {
        setData("adventurerByIdQuery", {
          adventurers: [equippedItemsEvent.data[0]],
        });
        setAdventurer(equippedItemsEvent.data[0]);
      }

      const battles = [];
      // Handle the beast counterattack from swapping
      const attackedBeastEvents = events.filter(
        (event) => event.name === "AttackedByBeast"
      );
      for (let attackedBeastEvent of attackedBeastEvents) {
        setData("adventurerByIdQuery", {
          adventurers: [attackedBeastEvent.data[0]],
        });
        setAdventurer(attackedBeastEvent.data[0]);
        battles.unshift(attackedBeastEvent.data[1]);
        setData(
          "beastQuery",
          attackedBeastEvent.data[0].beastHealth,
          "health",
          0
        );
      }

      const droppedItemsEvents = events.filter(
        (event) => event.name === "DroppedItems"
      );
      for (let droppedItemsEvent of droppedItemsEvents) {
        setData("adventurerByIdQuery", {
          adventurers: [droppedItemsEvent.data[0]],
        });
        setAdventurer(droppedItemsEvent.data[0]);
      }

      const adventurerDiedEvents = events.filter(
        (event) => event.name === "AdventurerDied"
      );
      for (let adventurerDiedEvent of adventurerDiedEvents) {
        if (
          adventurerDiedEvent.data[1].callerAddress ===
          adventurerDiedEvent.data[0].owner
        ) {
          setData("adventurerByIdQuery", {
            adventurers: [adventurerDiedEvent.data[0]],
          });
          const deadAdventurerIndex =
            queryData.adventurersByOwnerQuery?.adventurers.findIndex(
              (adventurer: Adventurer) =>
                adventurer.id == adventurerDiedEvent.data[0].id
            );
          setData("adventurersByOwnerQuery", 0, "health", deadAdventurerIndex);
          setAdventurer(adventurerDiedEvent.data[0]);
          const killedByBeast = battles.some(
            (battle) =>
              battle.attacker == "Beast" && battle.adventurerHealth == 0
          );
          // In a multicall someone can either die from swapping inventory or the death penalty. Here we handle those cases
          if (killedByBeast) {
            setDeathNotification(
              "Multicall",
              ["You equipped"],
              adventurerDiedEvent.data[0]
            );
          } else {
            setDeathNotification("Upgrade", "Death Penalty");
          }
          setScreen("start");
          setStartOption("create adventurer");
        }
      }

      setData("battlesByBeastQuery", {
        battles: [
          ...battles,
          ...(queryData.battlesByBeastQuery?.battles ?? []),
        ],
      });
      setData("battlesByAdventurerQuery", {
        battles: [
          ...battles,
          ...(queryData.battlesByAdventurerQuery?.battles ?? []),
        ],
      });
      setData("battlesByTxHashQuery", {
        battles: [...battles.reverse()],
      });

      // Handle upgrade
      const upgradeEvents = events.filter(
        (event) => event.name === "AdventurerUpgraded"
      );
      for (let upgradeEvent of upgradeEvents) {
        // Update adventurer
        setData("adventurerByIdQuery", {
          adventurers: [upgradeEvent.data],
        });
        setAdventurer(upgradeEvent.data);
        // Reset items to no availability
        setData("latestMarketItemsQuery", null);
        setScreen("play");
        setUpdateDeathPenalty(true);
      }

      const droppedItems = handleDrop(events, setData, setAdventurer);

      // Add purchased items
      const purchaseItemsEvents = events.filter(
        (event) => event.name === "PurchasedItems"
      );
      const purchasedItems = [];
      for (let purchasedItemEvent of purchaseItemsEvents) {
        for (let purchasedItem of purchasedItemEvent.data[1]) {
          purchasedItems.push(purchasedItem);
        }
      }
      // If there are any equip or drops, do them first
      const { equippedItems, unequippedItems } = handleEquip(
        events,
        setData,
        setAdventurer,
        queryData
      );
      for (let equippedItemsEvent of equippedItemsEvents) {
        for (let equippedItem of equippedItemsEvent.data[1]) {
          let item = purchasedItems.find((item) => item.item === equippedItem);
          if (item) {
            item.equipped = true;
          }
        }
      }
      const filteredEquips = queryData.itemsByAdventurerQuery?.items?.filter(
        (item: Item) =>
          !equippedItems.some((equippedItem) => equippedItem.item == item.item)
      );
      const filteredUnequips = filteredEquips?.filter(
        (item: Item) =>
          !unequippedItems.some((droppedItem) => droppedItem.item == item.item)
      );
      const filteredDrops = [
        ...(filteredUnequips ?? []),
        ...equippedItems,
        ...unequippedItems,
      ]?.filter((item: Item) => !droppedItems.includes(item.item ?? ""));
      setData("itemsByAdventurerQuery", {
        items: [...filteredDrops, ...purchasedItems],
      });

      stopLoading(notification, false, "Multicall");
      getEthBalance();
    } catch (e) {
      console.log(e);
      stopLoading(e, true);
    }
  };

  const mintLords = async (lordsAmount: number) => {
    const mintLords: Call = {
      contractAddress: lordsContract?.address ?? "",
      entrypoint: "mint",
      calldata: [account?.address ?? "0x0", lordsAmount.toString(), "0"],
    };
    const isArcade = checkArcadeConnector(connector!);
    try {
      setIsMintingLords(true);
      const tx = await handleSubmitCalls(
        account!,
        [...calls, mintLords],
        isArcade,
        Number(ethBalance),
        showTopUpDialog,
        setTopUpAccount
      );
      const result = await provider?.waitForTransaction(tx?.transaction_hash, {
        retryInterval: TRANSACTION_WAIT_RETRY_INTERVAL,
      });

      if (!result) {
        throw new Error("Lords Mint did not complete successfully.");
      }

      setIsMintingLords(false);
      getBalances();
    } catch (e) {
      setIsMintingLords(false);
      console.log(e);
    }
  };

  const suicide = async () => {
    const suicideTx: Call = {
      contractAddress: lordsContract?.address ?? "",
      entrypoint: "suicide",
      calldata: [adventurer.id!],
    };

    const isArcade = checkArcadeConnector(connector!);
    startLoading(
      "Suicide",
      "Committing Suicide",
      "adventurerByIdQuery",
      adventurer?.id
    );
    try {
      const tx = await handleSubmitCalls(
        account!,
        [...calls, suicideTx],
        isArcade,
        Number(ethBalance),
        showTopUpDialog,
        setTopUpAccount
      );
      const result = await provider?.waitForTransaction(tx?.transaction_hash, {
        retryInterval: TRANSACTION_WAIT_RETRY_INTERVAL,
      });

      if (!result) {
        throw new Error("Lords Mint did not complete successfully.");
      }

      stopLoading(`${adventurer.name} committed suicide!`);
      getBalances();
    } catch (e) {
      console.log(e);
      stopLoading(e, true);
    }
  };

  return {
    spawn,
    explore,
    attack,
    flee,
    upgrade,
    slayIdles,
    multicall,
    mintLords,
    suicide,
  };
}
