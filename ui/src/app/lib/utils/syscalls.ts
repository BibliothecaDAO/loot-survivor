import {
  InvokeTransactionReceiptResponse,
  Call,
  AccountInterface,
  RevertedTransactionReceiptResponse,
} from "starknet";
import { GameData } from "@/app/lib/data/GameData";
import {
  Adventurer,
  FormData,
  NullAdventurer,
  UpgradeStats,
} from "@/app/types";
import {
  getKeyFromValue,
  stringToFelt,
  checkArcadeBalance,
  indexAddress,
} from "@/app/lib/utils";
import { parseEvents } from "@/app/lib/utils/parseEvents";
import { processNotifications } from "@/app/components/notifications/NotificationHandler";
import { CallData } from "starknet";

export interface SyscallsProps {
  gameContract: any;
  lordsContract: any;
  beastsContract: any;
  addTransaction: any;
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
  setEquipItems: (...args: any[]) => any;
  setDropItems: (...args: any[]) => any;
  setDeathMessage: (...args: any[]) => any;
  showDeathDialog: (...args: any[]) => any;
  setScreen: (...args: any[]) => any;
  setAdventurer: (...args: any[]) => any;
  setStartOption: (...args: any[]) => any;
  ethBalance: bigint;
  showTopUpDialog: (...args: any[]) => any;
  setTopUpAccount: (...args: any[]) => any;
  setEstimatingFee: (...args: any[]) => any;
  account?: AccountInterface;
  resetCalls: (...args: any[]) => any;
  setSpecialBeastDefeated: (...args: any[]) => any;
  setSpecialBeast: (...args: any[]) => any;
}

function handleEquip(
  events: any[],
  setData: (...args: any[]) => any,
  setAdventurer: (...args: any[]) => any,
  queryData: any
) {
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
      const ownedItemIndex = queryData.itemsByAdventurerQuery?.items.findIndex(
        (item: any) => item.item == equippedItem
      );
      setData("itemsByAdventurerQuery", true, "equipped", ownedItemIndex);
    }
    for (let unequippedItem of equippedItemsEvent.data[2]) {
      const ownedItemIndex = queryData.itemsByAdventurerQuery?.items.findIndex(
        (item: any) => item.item == unequippedItem
      );
      setData("itemsByAdventurerQuery", false, "equipped", ownedItemIndex);
    }
  }
}

function handleDrop(
  events: any[],
  setData: (...args: any[]) => any,
  setAdventurer: (...args: any[]) => any
) {
  const droppedItemsEvents = events.filter(
    (event) => event.name === "DroppedItems"
  );
  let droppedItems: any[] = [];
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
}: SyscallsProps) {
  const gameData = new GameData();

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
    const mintLords: Call = {
      contractAddress: lordsContract?.address ?? "",
      entrypoint: "mint",
      calldata: [account?.address ?? "0x0", (250 * 10 ** 18).toString(), "0"],
    };
    const approveLordsSpendingTx = {
      contractAddress: lordsContract?.address ?? "",
      entrypoint: "approve",
      calldata: [gameContract?.address ?? "", (250 * 10 ** 18).toString(), "0"],
    };

    // TODO: pull token id from indexer, right now just set to 0
    const mintAdventurerTx = {
      contractAddress: gameContract?.address ?? "",
      entrypoint: "new_game",
      calldata: [
        "0x0628d41075659afebfc27aa2aab36237b08ee0b112debd01e56d037f64f6082a",
        getKeyFromValue(gameData.ITEMS, formData.startingWeapon) ?? "",
        stringToFelt(formData.name).toString(),
        "0",
        "0",
        "0",
      ],
    };

    addToCalls(mintAdventurerTx);
    console.log(ethBalance);
    const balanceEmpty = await checkArcadeBalance(
      [...calls, mintLords, approveLordsSpendingTx, mintAdventurerTx],
      ethBalance,
      showTopUpDialog,
      setTopUpAccount,
      setEstimatingFee,
      account
    );

    if (!balanceEmpty) {
      startLoading(
        "Create",
        "Spawning Adventurer",
        "adventurersByOwnerQuery",
        undefined
      );
      try {
        const tx = await handleSubmitCalls(account, [
          ...calls,
          mintLords,
          approveLordsSpendingTx,
          mintAdventurerTx,
        ]);
        setTxHash(tx?.transaction_hash);
        addTransaction({
          hash: tx?.transaction_hash,
          metadata: {
            method: `Spawn ${formData.name}`,
          },
        });
        const receipt = await account?.waitForTransaction(
          tx?.transaction_hash,
          {
            retryInterval: 2000,
          }
        );
        // Handle if the tx was reverted
        if (
          (receipt as RevertedTransactionReceiptResponse).execution_status ===
          "REVERTED"
        ) {
          throw new Error(
            (receipt as RevertedTransactionReceiptResponse).revert_reason
          );
        }
        // Here we need to process the StartGame event first and use the output for AmbushedByBeast event
        const startGameEvents = await parseEvents(
          receipt as InvokeTransactionReceiptResponse,
          undefined,
          beastsContract,
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
        stopLoading(`You have spawned ${formData.name}!`);
        setAdventurer(adventurerState);
        setScreen("play");
      } catch (e) {
        console.log(e);
        stopLoading(e, true);
      }
    } else {
      resetCalls();
    }
  };

  const explore = async (till_beast: boolean) => {
    const exploreTx = {
      contractAddress: gameContract?.address ?? "",
      entrypoint: "explore",
      calldata: [adventurer?.id?.toString() ?? "", till_beast ? "1" : "0"],
    };
    addToCalls(exploreTx);

    const balanceEmpty = await checkArcadeBalance(
      [...calls, exploreTx],
      ethBalance,
      showTopUpDialog,
      setTopUpAccount,
      setEstimatingFee,
      account
    );

    if (!balanceEmpty) {
      startLoading(
        "Explore",
        "Exploring",
        "discoveryByTxHashQuery",
        adventurer?.id
      );
      try {
        const tx = await handleSubmitCalls(account, [...calls, exploreTx]);
        setTxHash(tx?.transaction_hash);
        addTransaction({
          hash: tx?.transaction_hash,
          metadata: {
            method: `Explore with ${adventurer?.name}`,
          },
        });
        const receipt = await account?.waitForTransaction(
          tx?.transaction_hash,
          {
            retryInterval: 2000,
          }
        );
        // Handle if the tx was reverted
        if (
          (receipt as RevertedTransactionReceiptResponse).execution_status ===
          "REVERTED"
        ) {
          throw new Error(
            (receipt as RevertedTransactionReceiptResponse).revert_reason
          );
        }
        const events = await parseEvents(
          receipt as InvokeTransactionReceiptResponse,
          queryData.adventurerByIdQuery?.adventurers[0] ?? NullAdventurer
        );

        // If there are any equip or drops, do them first
        handleEquip(events, setData, setAdventurer, queryData);
        handleDrop(events, setData, setAdventurer);

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
              const itemsLeveledUpEvents = events.filter(
                (event) => event.name === "ItemsLeveledUp"
              );
              for (let itemsLeveledUpEvent of itemsLeveledUpEvents) {
                for (let itemLeveled of itemsLeveledUpEvent.data[1]) {
                  const ownedItemIndex =
                    queryData.itemsByAdventurerQuery?.items.findIndex(
                      (item: any) => item.item == itemLeveled.item
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
              (adventurer: any) =>
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
        stopLoading(reversedDiscoveries);
      } catch (e) {
        console.log(e);
        stopLoading(e, true);
      }
    } else {
      resetCalls();
    }
  };

  const attack = async (tillDeath: boolean, beastData: any) => {
    resetData("latestMarketItemsQuery");
    const attackTx = {
      contractAddress: gameContract?.address ?? "",
      entrypoint: "attack",
      calldata: [adventurer?.id?.toString() ?? "", tillDeath ? "1" : "0"],
    };
    addToCalls(attackTx);

    const balanceEmpty = await checkArcadeBalance(
      [...calls, attackTx],
      ethBalance,
      showTopUpDialog,
      setTopUpAccount,
      setEstimatingFee,
      account
    );

    if (!balanceEmpty) {
      startLoading(
        "Attack",
        "Attacking",
        "battlesByTxHashQuery",
        adventurer?.id
      );
      try {
        const tx = await handleSubmitCalls(account, [...calls, attackTx]);
        setTxHash(tx?.transaction_hash);
        addTransaction({
          hash: tx?.transaction_hash,
          metadata: {
            method: `Attack ${beastData.beast}`,
          },
        });
        const receipt = await account?.waitForTransaction(
          tx?.transaction_hash,
          {
            retryInterval: 2000,
          }
        );
        // Handle if the tx was reverted
        if (
          (receipt as RevertedTransactionReceiptResponse).execution_status ===
          "REVERTED"
        ) {
          throw new Error(
            (receipt as RevertedTransactionReceiptResponse).revert_reason
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
        handleEquip(events, setData, setAdventurer, queryData);
        handleDrop(events, setData, setAdventurer);

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
                  (item: any) => item.item == itemLeveled.item
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
            // Check whether beast has a prefix and suffix, if so check token
            console.log(slayedBeastEvent);
            if (
              slayedBeastEvent.data[1].special2 &&
              slayedBeastEvent.data[1].special3
            ) {
              setSpecialBeastDefeated(true);
              setSpecialBeast({
                data: slayedBeastEvent.data[1],
                tokenId: transferEvent.data.tokenId.low,
              });
              console.log(
                slayedBeastEvent.data[1],
                transferEvent.data.tokenId.low
              );
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
              (adventurer: any) =>
                adventurer.id == adventurerDiedEvent.data[0].id
            );
          setData("adventurersByOwnerQuery", 0, "health", deadAdventurerIndex);
          setAdventurer(adventurerDiedEvent.data[0]);
          const killedByBeast = battles.some(
            (battle) =>
              battle.attacker == "Beast" && battle.adventurerHealth == 0
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

        stopLoading(reversedBattles);
        setEquipItems([]);
        setDropItems([]);
      } catch (e) {
        console.log(e);
        stopLoading(e, true);
      }
    } else {
      resetCalls();
    }
  };

  const flee = async (tillDeath: boolean, beastData: any) => {
    const fleeTx = {
      contractAddress: gameContract?.address ?? "",
      entrypoint: "flee",
      calldata: [adventurer?.id?.toString() ?? "", tillDeath ? "1" : "0"],
    };
    addToCalls(fleeTx);

    const balanceEmpty = await checkArcadeBalance(
      [...calls, fleeTx],
      ethBalance,
      showTopUpDialog,
      setTopUpAccount,
      setEstimatingFee,
      account
    );

    if (!balanceEmpty) {
      startLoading("Flee", "Fleeing", "battlesByTxHashQuery", adventurer?.id);
      try {
        const tx = await handleSubmitCalls(account, [...calls, fleeTx]);
        setTxHash(tx?.transaction_hash);
        addTransaction({
          hash: tx?.transaction_hash,
          metadata: {
            method: `Flee ${beastData.beast}`,
          },
        });
        const receipt = await account?.waitForTransaction(
          tx?.transaction_hash,
          {
            retryInterval: 2000,
          }
        );
        // Handle if the tx was reverted
        if (
          (receipt as RevertedTransactionReceiptResponse).execution_status ===
          "REVERTED"
        ) {
          throw new Error(
            (receipt as RevertedTransactionReceiptResponse).revert_reason
          );
        }
        // Add optimistic data
        const events = await parseEvents(
          receipt as InvokeTransactionReceiptResponse,
          queryData.adventurerByIdQuery?.adventurers[0] ?? NullAdventurer
        );

        // If there are any equip or drops, do them first
        handleEquip(events, setData, setAdventurer, queryData);
        handleDrop(events, setData, setAdventurer);

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
              (adventurer: any) =>
                adventurer.id == adventurerDiedEvent.data[0].id
            );
          setData("adventurersByOwnerQuery", 0, "health", deadAdventurerIndex);
          setAdventurer(adventurerDiedEvent.data[0]);
          const killedByBeast = battles.some(
            (battle) =>
              battle.attacker == "Beast" && battle.adventurerHealth == 0
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
        stopLoading(reversedBattles);
        setEquipItems([]);
        setDropItems([]);
      } catch (e) {
        console.log(e);
        stopLoading(e, true);
      }
    } else {
      resetCalls();
    }
  };

  const upgrade = async (
    upgrades: UpgradeStats,
    purchaseItems: any[],
    potionAmount: number
  ) => {
    const balanceEmpty = await checkArcadeBalance(
      calls,
      ethBalance,
      showTopUpDialog,
      setTopUpAccount,
      setEstimatingFee,
      account
    );

    if (!balanceEmpty) {
      startLoading(
        "Upgrade",
        "Upgrading",
        "adventurerByIdQuery",
        adventurer?.id
      );
      try {
        const tx = await handleSubmitCalls(account, calls);
        setTxHash(tx?.transaction_hash);
        addTransaction({
          hash: tx?.transaction_hash,
          metadata: {
            method: `Upgrade`,
          },
        });
        const receipt = await account?.waitForTransaction(
          tx?.transaction_hash,
          {
            retryInterval: 2000,
          }
        );
        // Handle if the tx was reverted
        if (
          (receipt as RevertedTransactionReceiptResponse).execution_status ===
          "REVERTED"
        ) {
          throw new Error(
            (receipt as RevertedTransactionReceiptResponse).revert_reason
          );
        }
        // Add optimistic data
        const events = await parseEvents(
          receipt as InvokeTransactionReceiptResponse,
          queryData.adventurerByIdQuery?.adventurers[0] ?? NullAdventurer
        );

        // If there are any equip or drops, do them first
        handleEquip(events, setData, setAdventurer, queryData);
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
            let item = purchasedItems.find(
              (item) => item.item === equippedItem
            );
            item.equipped = true;
          }
        }
        let unequipIndexes = [];
        for (let equippedItemsEvent of equippedItemsEvents) {
          for (let unequippedItem of equippedItemsEvent.data[2]) {
            const ownedItemIndex =
              queryData.itemsByAdventurerQuery?.items.findIndex(
                (item: any) => item.item == unequippedItem
              );
            let item = purchasedItems.find(
              (item) => item.item === unequippedItem
            );
            if (item) {
              item.equipped = false;
            } else {
              unequipIndexes.push(ownedItemIndex);
            }
          }
        }

        const filteredDrops = queryData.itemsByAdventurerQuery?.items.filter(
          (item: any) => !droppedItems.includes(item.item)
        );
        setData("itemsByAdventurerQuery", {
          items: [...(filteredDrops ?? []), ...purchasedItems],
        });
        for (let i = 0; i < unequipIndexes.length; i++) {
          setData(
            "itemsByAdventurerQuery",
            false,
            "equipped",
            unequipIndexes[i]
          );
        }

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
                (adventurer: any) =>
                  adventurer.id == adventurerDiedEvent.data[0].id
              );
            setData(
              "adventurersByOwnerQuery",
              0,
              "health",
              deadAdventurerIndex
            );
            setAdventurer(adventurerDiedEvent.data[0]);
            setDeathNotification("Upgrade", "Death Penalty", []);
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
          stopLoading({
            Stats: upgrades,
            Items: purchaseItems,
            Potions: potionAmount,
          });
          setScreen("play");
        }
      } catch (e) {
        console.log(e);
        stopLoading(e, true);
      }
    } else {
      resetCalls();
    }
  };

  const slayAllIdles = async (slayAdventurers: number[]) => {
    const slayIdleAdventurersTx = {
      contractAddress: gameContract?.address ?? "",
      entrypoint: "slay_idle_adventurers",
      calldata: [slayAdventurers.length, ...slayAdventurers],
      metadata: `Slaying all Adventurers`,
    };
    addToCalls(slayIdleAdventurersTx);

    const balanceEmpty = await checkArcadeBalance(
      [...calls, slayIdleAdventurersTx],
      ethBalance,
      showTopUpDialog,
      setTopUpAccount,
      setEstimatingFee,
      account
    );

    if (!balanceEmpty) {
      startLoading("Slay All Idles", "Slaying All Idles", undefined, undefined);
      try {
        const tx = await handleSubmitCalls(account, [
          ...calls,
          slayIdleAdventurersTx,
        ]);
        setTxHash(tx?.transaction_hash);
        addTransaction({
          hash: tx?.transaction_hash,
          metadata: {
            method: `Upgrade`,
          },
        });
        const receipt = await account?.waitForTransaction(
          tx?.transaction_hash,
          {
            retryInterval: 100,
          }
        );
        // Handle if the tx was reverted
        if (
          (receipt as RevertedTransactionReceiptResponse).execution_status ===
          "REVERTED"
        ) {
          throw new Error(
            (receipt as RevertedTransactionReceiptResponse).revert_reason
          );
        }
        const events = await parseEvents(
          receipt as InvokeTransactionReceiptResponse,
          queryData.adventurerByIdQuery?.adventurers[0] ?? NullAdventurer
        );

        // If there are any equip or drops, do them first
        handleEquip(events, setData, setAdventurer, queryData);
        handleDrop(events, setData, setAdventurer);

        stopLoading(`You have slain all idle adventurers!`);
      } catch (e) {
        console.log(e);
        stopLoading(`You have slain all idle adventurers!`);
      }
    } else {
      resetCalls();
    }
  };

  const multicall = async (
    loadingMessage: string[],
    notification: string[]
  ) => {
    const balanceEmpty = await checkArcadeBalance(
      calls,
      ethBalance,
      showTopUpDialog,
      setTopUpAccount,
      setEstimatingFee,
      account
    );

    if (!balanceEmpty) {
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
      startLoading("Multicall", loadingMessage, undefined, adventurer?.id);
      try {
        const tx = await handleSubmitCalls(account, calls);
        const receipt = await account?.waitForTransaction(
          tx?.transaction_hash,
          {
            retryInterval: 2000,
          }
        );
        // Handle if the tx was reverted
        if (
          (receipt as RevertedTransactionReceiptResponse).execution_status ===
          "REVERTED"
        ) {
          throw new Error(
            (receipt as RevertedTransactionReceiptResponse).revert_reason
          );
        }
        setTxHash(tx?.transaction_hash);
        addTransaction({
          hash: tx?.transaction_hash,
          metadata: {
            method: "Multicall",
            marketIds: items,
          },
        });
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
            setData(
              "itemsByAdventurerQuery",
              false,
              "equipped",
              ownedItemIndex
            );
          }
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
          let droppedItems: any[] = [];
          for (let droppedItem of droppedItemsEvent.data[1]) {
            droppedItems.push(droppedItem);
          }
          const newItems = queryData.itemsByAdventurerQuery?.items.filter(
            (item: any) => !droppedItems.includes(item.item)
          );
          setData("itemsByAdventurerQuery", { items: newItems });
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
                (adventurer: any) =>
                  adventurer.id == adventurerDiedEvent.data[0].id
              );
            setData(
              "adventurersByOwnerQuery",
              0,
              "health",
              deadAdventurerIndex
            );
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
              setDeathNotification("Upgrade", "Death Penalty", []);
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
          // If there are any equip or drops, do them first
          handleEquip(events, setData, setAdventurer, queryData);
          handleDrop(events, setData, setAdventurer);

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
              let item = purchasedItems.find(
                (item) => item.item === equippedItem
              );
              item.equipped = true;
            }
          }
          let unequipIndexes = [];
          for (let equippedItemsEvent of equippedItemsEvents) {
            for (let unequippedItem of equippedItemsEvent.data[2]) {
              const ownedItemIndex =
                queryData.itemsByAdventurerQuery?.items.findIndex(
                  (item: any) => item.item == unequippedItem
                );
              let item = purchasedItems.find(
                (item) => item.item === unequippedItem
              );
              if (item) {
                item.equipped = false;
              } else {
                unequipIndexes.push(ownedItemIndex);
              }
            }
          }
          setData("itemsByAdventurerQuery", {
            items: [
              ...(queryData.itemsByAdventurerQuery?.items ?? []),
              ...purchasedItems,
            ],
          });
          for (let i = 0; i < unequipIndexes.length; i++) {
            setData(
              "itemsByAdventurerQuery",
              false,
              "equipped",
              unequipIndexes[i]
            );
          }
          // Reset items to no availability
          setData("latestMarketItemsQuery", null);
          setScreen("play");
        }

        stopLoading(notification);
      } catch (e) {
        console.log(e);
        stopLoading(e, true);
      }
    } else {
      resetCalls();
    }
  };

  return { spawn, explore, attack, flee, upgrade, slayAllIdles, multicall };
}
