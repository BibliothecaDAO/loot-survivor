import { InvokeTransactionReceiptResponse } from "starknet";
import { GameData } from "@/app/components/GameData";
import {
  Adventurer,
  FormData,
  NullAdventurer,
  UpgradeStats,
} from "@/app/types";
import { QueryKey } from "@/app/hooks/useQueryStore";
import { getKeyFromValue, stringToFelt, getRandomNumber } from ".";
import { parseEvents } from "./parseEvents";
import { processNotifications } from "@/app/components/notifications/NotificationHandler";

export interface SyscallsProps {
  gameContract: any;
  lordsContract: any;
  addTransaction: any;
  account: any;
  queryData: any;
  resetData: (...args: any[]) => any;
  setData: (...args: any[]) => any;
  adventurer: any;
  addToCalls: (...args: any[]) => any;
  calls: any;
  handleSubmitCalls: (...args: any[]) => any;
  startLoading: (...args: any[]) => any;
  stopLoading: (...args: any[]) => any;
  setTxHash: (...args: any[]) => any;
  writeAsync: (...args: any[]) => any;
  setEquipItems: (...args: any[]) => any;
  setDropItems: (...args: any[]) => any;
  setDeathMessage: (...args: any[]) => any;
  showDeathDialog: (...args: any[]) => any;
  resetNotification: (...args: any[]) => any;
  setScreen: (...args: any[]) => any;
  setAdventurer: (...args: any[]) => any;
  setMintAdventurer: (...args: any[]) => any;
}

export function syscalls({
  gameContract,
  lordsContract,
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
  writeAsync,
  setEquipItems,
  setDropItems,
  setDeathMessage,
  showDeathDialog,
  resetNotification,
  setScreen,
  setAdventurer,
  setMintAdventurer,
}: SyscallsProps) {
  const gameData = new GameData();

  const formatAddress = account ? account.address : "0x0";

  const updateItemsXP = (adventurerState: Adventurer, itemsXP: number[]) => {
    const weapon = adventurerState.weapon;
    const weaponIndex = queryData.itemsByAdventurerQuery?.items.findIndex(
      (item: any) => item.item == weapon
    );
    const chest = adventurerState.chest;
    setData("itemsByAdventurerQuery", itemsXP[0], "xp", weaponIndex);
    const chestIndex = queryData.itemsByAdventurerQuery?.items.findIndex(
      (item: any) => item.item == chest
    );
    setData("itemsByAdventurerQuery", itemsXP[1], "xp", chestIndex);
    const head = adventurerState.head;
    const headIndex = queryData.itemsByAdventurerQuery?.items.findIndex(
      (item: any) => item.item == head
    );
    setData("itemsByAdventurerQuery", itemsXP[2], "xp", headIndex);
    const waist = adventurerState.waist;
    const waistIndex = queryData.itemsByAdventurerQuery?.items.findIndex(
      (item: any) => item.item == waist
    );
    setData("itemsByAdventurerQuery", itemsXP[3], "xp", waistIndex);
    const foot = adventurerState.foot;
    const footIndex = queryData.itemsByAdventurerQuery?.items.findIndex(
      (item: any) => item.item == foot
    );
    setData("itemsByAdventurerQuery", itemsXP[4], "xp", footIndex);
    const hand = adventurerState.hand;
    const handIndex = queryData.itemsByAdventurerQuery?.items.findIndex(
      (item: any) => item.item == hand
    );
    setData("itemsByAdventurerQuery", itemsXP[5], "xp", handIndex);
    const neck = adventurerState.neck;
    const neckIndex = queryData.itemsByAdventurerQuery?.items.findIndex(
      (item: any) => item.item == neck
    );
    setData("itemsByAdventurerQuery", itemsXP[6], "xp", neckIndex);
    const ring = adventurerState.ring;
    const ringIndex = queryData.itemsByAdventurerQuery?.items.findIndex(
      (item: any) => item.item == ring
    );
    setData("itemsByAdventurerQuery", itemsXP[7], "xp", ringIndex);
  };

  const setDeathNotification = (
    type: string,
    notificationData: any,
    adventurer: any,
    battles?: any,
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

  const spawn = async (formData: FormData) => {
    resetNotification();

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
      undefined
    );
    try {
      const tx = await handleSubmitCalls(writeAsync);
      setTxHash(tx.transaction_hash);
      addTransaction({
        hash: tx?.transaction_hash,
        metadata: {
          method: `Spawn ${formData.name}`,
        },
      });
      const receipt = await account?.waitForTransaction(tx.transaction_hash, {
        retryInterval: 1000,
      });
      const events = parseEvents(receipt as InvokeTransactionReceiptResponse, {
        name: formData["name"],
        homeRealm: formData["homeRealmId"],
        classType: formData["class"],
        entropy: 0,
        createdTime: new Date(),
      });
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
      stopLoading(`You have spawned ${formData.name}!`);
      setAdventurer(adventurerState);
      setScreen("play");
      setMintAdventurer(true);
    } catch (e) {
      console.log(e);
    }
  };

  const explore = async (till_beast: boolean) => {
    resetNotification();

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
    try {
      const tx = await handleSubmitCalls(writeAsync);
      setTxHash(tx.transaction_hash);
      addTransaction({
        hash: tx.transaction_hash,
        metadata: {
          method: `Explore with ${adventurer?.name}`,
        },
      });
      const receipt = await account?.waitForTransaction(tx.transaction_hash, {
        retryInterval: 1000,
      });
      const events = parseEvents(
        receipt as InvokeTransactionReceiptResponse,
        queryData.adventurerByIdQuery?.adventurers[0] ?? NullAdventurer
      );
      const discoveries = [];

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
            const itemSpecialUnlockedEvents = events.filter(
              (event) => event.name === "ItemSpecialUnlocked"
            );
            for (let itemSpecialUnlockedEvent of itemSpecialUnlockedEvents) {
              setData("adventurerByIdQuery", {
                adventurers: [itemSpecialUnlockedEvent.data[0]],
              });
              setAdventurer(itemSpecialUnlockedEvent.data[0]);
              const ownedItemIndex =
                queryData.itemsByAdventurerQuery?.items.findIndex(
                  (item: any) =>
                    item.item == itemSpecialUnlockedEvent.data[1].item
                );
              setData(
                "itemsByAdventurerQuery",
                itemSpecialUnlockedEvent.data[1].special1,
                "special1",
                ownedItemIndex
              );
              setData(
                "itemsByAdventurerQuery",
                itemSpecialUnlockedEvent.data[1].special2,
                "special2",
                ownedItemIndex
              );
              setData(
                "itemsByAdventurerQuery",
                itemSpecialUnlockedEvent.data[1].special3,
                "special3",
                ownedItemIndex
              );
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

      const adventurerDiedExists = events.some((event) => {
        if (event.name === "AdventurerDied") {
          return true;
        }
        return false;
      });
      if (adventurerDiedExists) {
        const adventurerDiedEvent = events.find(
          (event) => event.name === "AdventurerDied"
        );
        console.log(adventurerDiedEvent.name);
        setData("adventurerByIdQuery", {
          adventurers: [adventurerDiedEvent.data],
        });
        setAdventurer(adventurerDiedEvent.data);
        const killedByObstacle =
          discoveries.reverse()[0]?.discoveryType == "Obstacle" &&
          discoveries.reverse()[0]?.adventurerHealth == 0;
        const killedByPenalty =
          discoveries.reverse()[0]?.discoveryType &&
          discoveries.reverse()[0]?.adventurerHealth == 0;
        const killedByAmbush =
          discoveries.reverse()[0]?.ambushed &&
          discoveries.reverse()[0]?.adventurerHealth == 0;
        if (killedByObstacle || killedByPenalty || killedByAmbush) {
          setDeathNotification(
            "Explore",
            discoveries.reverse(),
            adventurerDiedEvent.data
          );
        }
        setScreen("start");
      }

      const filteredDeathPenalty = events.filter(
        (event) => event.name === "IdleDeathPenalty"
      );
      if (filteredDeathPenalty.length > 0) {
        for (let discovery of filteredDeathPenalty) {
          setData("adventurerByIdQuery", {
            adventurers: [discovery.data[0]],
          });
          setAdventurer(discovery.data[0]);
          discoveries.unshift(discovery.data[2]);
        }
      }

      const newItemsAvailableExists = events.some((event) => {
        if (event.name === "NewItemsAvailable") {
          return true;
        }
        return false;
      });
      if (newItemsAvailableExists) {
        const newItemsAvailableEvent = events.find(
          (event) => event.name === "NewItemsAvailable"
        );
        const newItems = newItemsAvailableEvent.data[1];
        const itemData = [];
        for (let newItem of newItems) {
          itemData.unshift({
            item: newItem,
            adventurerId: newItemsAvailableEvent.data[0]["id"],
            owner: false,
            equipped: false,
            ownerAddress: newItemsAvailableEvent.data[0]["owner"],
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
      stopLoading(discoveries);
      setMintAdventurer(false);
    } catch (e) {
      console.log(e);
    }
  };

  const attack = async (tillDeath: boolean, beastData: any) => {
    resetNotification();

    resetData("latestMarketItemsQuery");
    addToCalls({
      contractAddress: gameContract?.address ?? "",
      entrypoint: "attack",
      calldata: [adventurer?.id?.toString() ?? "", "0", tillDeath ? "1" : "0"],
    });
    startLoading("Attack", "Attacking", "battlesByTxHashQuery", adventurer?.id);
    try {
      const tx = await handleSubmitCalls(writeAsync);
      setTxHash(tx.transaction_hash);
      addTransaction({
        hash: tx.transaction_hash,
        metadata: {
          method: `Attack ${beastData.beast}`,
        },
      });
      const receipt = await account?.waitForTransaction(tx.transaction_hash, {
        retryInterval: 1000,
      });

      // reset battles by tx hash
      setData("battlesByTxHashQuery", {
        battles: null,
      });
      const events = parseEvents(
        receipt as InvokeTransactionReceiptResponse,
        queryData.adventurerByIdQuery?.adventurers[0] ?? NullAdventurer
      );
      const battles = [];

      const attackedBeastEvents = events.filter(
        (event) =>
          event.name === "AttackedBeast" || event.name === "AttackedByBeast"
      );
      for (let attackedBeastEvent of attackedBeastEvents) {
        console.log(attackedBeastEvent.name);
        console.log(attackedBeastEvent.data[0]);
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
        const itemSpecialUnlockedEvents = events.filter(
          (event) => event.name === "ItemSpecialUnlocked"
        );
        for (let itemSpecialUnlockedEvent of itemSpecialUnlockedEvents) {
          setData("adventurerByIdQuery", {
            adventurers: [itemSpecialUnlockedEvent.data[0]],
          });
          setAdventurer(itemSpecialUnlockedEvent.data[0]);
          const ownedItemIndex =
            queryData.itemsByAdventurerQuery?.items.findIndex(
              (item: any) => item.item == itemSpecialUnlockedEvent.data[1].item
            );
          setData(
            "itemsByAdventurerQuery",
            itemSpecialUnlockedEvent.data[1].special1,
            "special1",
            ownedItemIndex
          );
          setData(
            "itemsByAdventurerQuery",
            itemSpecialUnlockedEvent.data[1].special2,
            "special2",
            ownedItemIndex
          );
          setData(
            "itemsByAdventurerQuery",
            itemSpecialUnlockedEvent.data[1].special3,
            "special3",
            ownedItemIndex
          );
        }
      }

      const adventurerDiedExists = events.some((event) => {
        if (event.name === "AdventurerDied") {
          return true;
        }
        return false;
      });
      if (adventurerDiedExists) {
        const adventurerDiedEvent = events.find(
          (event) => event.name === "AdventurerDied"
        );
        setData("adventurerByIdQuery", {
          adventurers: [adventurerDiedEvent.data],
        });
        setAdventurer(adventurerDiedEvent.data);
        const killedByBeast = battles.some(
          (battle) => battle.attacker == "Beast" && battle.adventurerHealth == 0
        );
        const killedByPenalty = battles.some(
          (battle) => !battle.attacker && battle.adventurerHealth == 0
        );
        if (killedByBeast || killedByPenalty) {
          setDeathNotification(
            "Attack",
            battles.reverse(),
            adventurerDiedEvent.data
          );
        }
        setScreen("start");
      }

      const filteredDeathPenalty = events.filter(
        (event) => event.name === "IdleDeathPenalty"
      );
      if (filteredDeathPenalty.length > 0) {
        for (let discovery of filteredDeathPenalty) {
          setData("adventurerByIdQuery", {
            adventurers: [discovery.data[0]],
          });
          setAdventurer(discovery.data[0]);
          battles.unshift(discovery.data[1]);
        }
      }

      const newItemsAvailableExists = events.some((event) => {
        if (event.name === "NewItemsAvailable") {
          return true;
        }
        return false;
      });
      if (newItemsAvailableExists) {
        const newItemsAvailableEvent = events.find(
          (event) => event.name === "NewItemsAvailable"
        );
        const newItems = newItemsAvailableEvent.data[1];
        const itemData = [];
        for (let newItem of newItems) {
          itemData.unshift({
            item: newItem,
            adventurerId: newItemsAvailableEvent.data[0]["id"],
            owner: false,
            equipped: false,
            ownerAddress: newItemsAvailableEvent.data[0]["owner"],
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
        battles: [...battles.reverse()],
      });

      console.log(battles);

      stopLoading(battles);
      setEquipItems([]);
      setDropItems([]);
      setMintAdventurer(false);
    } catch (e) {
      console.log(e);
    }
  };

  const flee = async (tillDeath: boolean, beastData: any) => {
    resetNotification();

    addToCalls({
      contractAddress: gameContract?.address ?? "",
      entrypoint: "flee",
      calldata: [adventurer?.id?.toString() ?? "", "0", tillDeath ? "1" : "0"],
    });
    startLoading("Flee", "Fleeing", "battlesByTxHashQuery", adventurer?.id);
    try {
      const tx = await handleSubmitCalls(writeAsync);
      setTxHash(tx.transaction_hash);
      addTransaction({
        hash: tx.transaction_hash,
        metadata: {
          method: `Flee ${beastData.beast}`,
        },
      });
      const receipt = await account?.waitForTransaction(tx.transaction_hash, {
        retryInterval: 1000,
      });
      // Add optimistic data
      const events = parseEvents(
        receipt as InvokeTransactionReceiptResponse,
        queryData.adventurerByIdQuery?.adventurers[0] ?? NullAdventurer
      );
      const battles = [];

      const fleeFailedEvents = events.filter(
        (event) => event.name === "FleeFailed"
      );
      for (let fleeFailedEvent of fleeFailedEvents) {
        setData("adventurerByIdQuery", {
          adventurers: [fleeFailedEvent.data[0]],
        });
        setAdventurer(fleeFailedEvent.data[0]);
        battles.unshift(fleeFailedEvent.data[1]);
      }

      const attackedByBeastEvents = events.filter(
        (event) => event.name === "AttackedByBeast"
      );
      for (let attackedByBeastEvent of attackedByBeastEvents) {
        setData("adventurerByIdQuery", {
          adventurers: [attackedByBeastEvent.data[0]],
        });
        setAdventurer(attackedByBeastEvent.data[0]);
        battles.unshift(attackedByBeastEvent.data[1]);
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

      const adventurerDiedExists = events.some((event) => {
        if (event.name === "AdventurerDied") {
          return true;
        }
        return false;
      });
      if (adventurerDiedExists) {
        const adventurerDiedEvent = events.find(
          (event) => event.name === "AdventurerDied"
        );
        setData("adventurerByIdQuery", {
          adventurers: [adventurerDiedEvent.data],
        });
        setAdventurer(adventurerDiedEvent.data);
        const killedByBeast = events.some(
          (battle) => battle.attacker == "Beast" && battle.adventurerHealth == 0
        );
        const killedByPenalty = events.some(
          (battle) => !battle.attacker && battle.adventurerHealth == 0
        );
        if (killedByBeast || killedByPenalty) {
          setDeathNotification(
            "Flee",
            battles.reverse(),
            adventurerDiedEvent.data
          );
        }
        setScreen("start");
      }

      const filteredDeathPenalty = events.filter(
        (event) => event.name === "IdleDeathPenalty"
      );
      if (filteredDeathPenalty.length > 0) {
        for (let discovery of filteredDeathPenalty) {
          setData("adventurerByIdQuery", {
            adventurers: [discovery.data[0]],
          });
          setAdventurer(discovery.data[0]);
          battles.unshift(discovery.data[1]);
        }
      }

      const newItemsAvailableExists = events.some((event) => {
        if (event.name === "NewItemsAvailable") {
          return true;
        }
        return false;
      });
      if (newItemsAvailableExists) {
        const newItemsAvailableEvent = events.find(
          (event) => event.name === "NewItemsAvailable"
        );
        const newItems = newItemsAvailableEvent.data[1];
        const itemData = [];
        for (let newItem of newItems) {
          itemData.unshift({
            item: newItem,
            adventurerId: newItemsAvailableEvent.data[0]["id"],
            owner: false,
            equipped: false,
            ownerAddress: newItemsAvailableEvent.data[0]["owner"],
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
        setScreen("upgrade");
      }

      setData("battlesByBeastQuery", {
        battles: [
          ...battles,
          ...(queryData.battlesByAdventurerQuery?.battles ?? []),
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

      stopLoading(battles);
      setEquipItems([]);
      setDropItems([]);
      setMintAdventurer(false);
    } catch (e) {
      console.log(e);
    }
  };

  const upgrade = async (
    upgrades: UpgradeStats,
    purchaseItems: any[],
    potionAmount: number
  ) => {
    resetNotification();

    startLoading("Upgrade", "Upgrading", "adventurerByIdQuery", adventurer?.id);
    try {
      const tx = await handleSubmitCalls(writeAsync);
      setTxHash(tx.transaction_hash);
      addTransaction({
        hash: tx.transaction_hash,
        metadata: {
          method: `Upgrade`,
        },
      });
      const receipt = await account?.waitForTransaction(tx.transaction_hash, {
        retryInterval: 1000,
      });

      // Add optimistic data
      const events = parseEvents(
        receipt as InvokeTransactionReceiptResponse,
        queryData.adventurerByIdQuery?.adventurers[0] ?? NullAdventurer
      );
      // Update adventurer
      setData("adventurerByIdQuery", {
        adventurers: [
          events.find((event) => event.name === "AdventurerUpgraded").data,
        ],
      });
      setAdventurer(
        events.find((event) => event.name === "AdventurerUpgraded").data
      );
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
          item.equipped = true;
        }
        for (let unequippedItem of equippedItemsEvent.data[2]) {
          const ownedItemIndex =
            queryData.itemsByAdventurerQuery?.items.findIndex(
              (item: any) => item.item == unequippedItem
            );
          setData("itemsByAdventurerQuery", false, "equipped", ownedItemIndex);
        }
      }
      setData("itemsByAdventurerQuery", {
        items: [
          ...(queryData.itemsByAdventurerQuery?.items ?? []),
          ...purchasedItems,
        ],
      });
      // Reset items to no availability
      setData("latestMarketItemsQuery", null);
      stopLoading({
        Stats: upgrades,
        Items: purchaseItems,
        Potions: potionAmount,
      });
      setScreen("play");
      setMintAdventurer(false);
    } catch (e) {
      console.log(e);
    }
  };

  const multicall = async (
    loadingMessage: string[],
    loadingQuery: QueryKey | null,
    notification: string[]
  ) => {
    resetNotification();

    const items: string[] = [];

    for (const dict of calls) {
      if (
        dict.hasOwnProperty("entrypoint") &&
        (dict["entrypoint"] === "bid_on_item" ||
          dict["entrypoint"] === "claim_item")
      ) {
        if (Array.isArray(dict.calldata)) {
          items.unshift(dict.calldata[0]?.toString() ?? "");
        }
      }
      if (dict["entrypoint"] === "equip") {
        if (Array.isArray(dict.calldata)) {
          items.unshift(dict.calldata[2]?.toString() ?? "");
        }
      }
    }
    startLoading("Multicall", loadingMessage, loadingQuery, adventurer?.id);
    try {
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
      const events = parseEvents(
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
        for (let equippedItem of equippedItemsEvent.data[1]) {
          const ownedItemIndex =
            queryData.itemsByAdventurerQuery?.items.findIndex(
              (item: any) => item.item == equippedItem
            );
          setData("itemsByAdventurerQuery", true, "equipped", ownedItemIndex);
        }
        for (let unequippedItem of equippedItemsEvent.data[2]) {
          const ownedItemIndex =
            queryData.itemsByAdventurerQuery?.items.findIndex(
              (item: any) => item.item == unequippedItem
            );
          setData("itemsByAdventurerQuery", false, "equipped", ownedItemIndex);
        }
      }

      const droppedItemsEvents = events.filter(
        (event) => event.name === "DroppedItems"
      );
      for (let droppedItemsEvent of droppedItemsEvents) {
        setData("adventurerByIdQuery", {
          adventurers: [droppedItemsEvent.data[0]],
        });
        setAdventurer(droppedItemsEvent.data[0]);
        for (let droppedItem of droppedItemsEvent.data[1]) {
          const newItems = queryData.itemsByAdventurerQuery?.items.filter(
            (item: any) => item.item !== droppedItem
          );
          setData("itemsByAdventurerQuery", { items: newItems });
        }
      }

      const adventurerDiedExists = events.some((event) => {
        if (event.name === "AdventurerDied") {
          return true;
        }
        return false;
      });
      if (adventurerDiedExists) {
        const adventurerDiedEvent = events.find(
          (event) => event.name === "AdventurerDied"
        );
        setData("adventurerByIdQuery", {
          adventurers: [adventurerDiedEvent.data],
        });
        setAdventurer(adventurerDiedEvent.data);
        setDeathNotification(
          "Multicall",
          ["You equipped"],
          adventurerDiedEvent.data
        );
        setScreen("start");
      }

      stopLoading(notification);
      setMintAdventurer(false);
    } catch (e) {
      console.log(e);
    }
  };

  return { spawn, explore, attack, flee, upgrade, multicall };
}
