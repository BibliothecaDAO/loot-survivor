import { useMemo } from "react";
import { Contract } from "starknet";
import { Adventurer, NullAdventurer, NullItem } from "@/app/types";
import {
  HeartIcon,
  CoinIcon,
  QuestionMarkIcon,
} from "@/app/components/icons/Icons";
import { ItemDisplay } from "@/app/components/adventurer/ItemDisplay";
import LevelBar from "@/app/components/adventurer/LevelBar";
import { getItemData, getKeyFromValue } from "@/app/lib/utils";
import { useQueriesStore } from "@/app/hooks/useQueryStore";
import useUIStore from "@/app/hooks/useUIStore";
import { Item } from "@/app/types";
import { HealthCountDown } from "@/app/components/CountDown";
import { GameData } from "@/app/lib/data/GameData";
import useTransactionCartStore from "@/app/hooks/useTransactionCartStore";
import { calculateLevel } from "@/app/lib/utils";
import { vitalityIncrease } from "@/app/lib/constants";

interface InfoProps {
  adventurer: Adventurer | undefined;
  gameContract: Contract;
  profileExists?: boolean;
  upgradeCost?: number;
}

export default function Info({
  adventurer,
  gameContract,
  profileExists,
  upgradeCost,
}: InfoProps) {
  const formatAdventurer = adventurer ? adventurer : NullAdventurer;
  const { data } = useQueriesStore();
  const dropItems = useUIStore((state) => state.dropItems);
  const setDropItems = useUIStore((state) => state.setDropItems);
  const potionAmount = useUIStore((state) => state.potionAmount);
  const upgrades = useUIStore((state) => state.upgrades);
  const vitBoostRemoved = useUIStore((state) => state.vitBoostRemoved);
  const addToCalls = useTransactionCartStore((state) => state.addToCalls);
  const removeEntrypointFromCalls = useTransactionCartStore(
    (state) => state.removeEntrypointFromCalls
  );
  const equipItems = useUIStore((state) => state.equipItems);
  const purchaseItems = useUIStore((state) => state.purchaseItems);

  const gameData = new GameData();

  const items = profileExists
    ? data.itemsByProfileQuery
      ? data.itemsByProfileQuery.items
      : []
    : data.itemsByAdventurerQuery
    ? data.itemsByAdventurerQuery.items
    : [];

  const filteredItems = useMemo(() => {
    const filteredDrops = items.filter(
      (item) =>
        !dropItems.includes(getKeyFromValue(gameData.ITEMS, item.item!) ?? "")
    );

    const updatePurchaseEquips = filteredDrops.flatMap((item) => {
      if (purchaseItems.length > 0) {
        const replaceItems = purchaseItems.filter((pItem) => {
          const { slot: equipSlot } = getItemData(
            gameData.ITEMS[parseInt(pItem.item)]
          );
          const { slot: heldSlot } = getItemData(item.item!);
          return equipSlot === heldSlot && pItem.equip === "1";
        });
        if (replaceItems.length > 0) {
          return [
            { ...item, equipped: false },
            {
              item: gameData.ITEMS[
                parseInt(replaceItems[replaceItems.length - 1].item)
              ],
              adventurerId: formatAdventurer.id,
              owner: true,
              equipped: true,
              ownerAddress: formatAdventurer.owner,
              xp: 0,
              special1: undefined,
              special2: undefined,
              special3: undefined,
              isAvailable: false,
              purchasedTime: new Date(),
              timestamp: new Date(),
            },
          ];
        }
      }

      return [item];
    });

    const updateEquips = updatePurchaseEquips.map((item) => {
      const replaceItem = equipItems.find((eItem) => {
        const { slot: equipSlot } = getItemData(
          gameData.ITEMS[parseInt(eItem)]
        );
        const { slot: heldSlot } = getItemData(item.item!);
        return equipSlot === heldSlot;
      });
      if (replaceItem) {
        if (item.equipped) {
          return { ...item, equipped: false };
        } else {
          if (item.item === gameData.ITEMS[parseInt(replaceItem)]) {
            return { ...item, equipped: true };
          }
        }
      }

      return item;
    });

    return [
      ...updateEquips,
      ...purchaseItems
        .filter((pItem) => pItem.equip === "1")
        .map((pItem) => ({
          item: gameData.ITEMS[parseInt(pItem.item)],
          adventurerId: formatAdventurer.id,
          owner: true,
          equipped: true,
          ownerAddress: formatAdventurer.owner,
          xp: 0,
          special1: undefined,
          special2: undefined,
          special3: undefined,
          isAvailable: false,
          purchasedTime: new Date(),
          timestamp: new Date(),
        })),
    ];
  }, [items, dropItems, equipItems, purchaseItems]);

  const handleDropItems = (item: string) => {
    const newDropItems = [
      ...dropItems,
      getKeyFromValue(gameData.ITEMS, item) ?? "",
    ];
    setDropItems(newDropItems);
    if (gameContract) {
      const dropItemsTx = {
        contractAddress: gameContract?.address,
        entrypoint: "drop",
        calldata: [
          adventurer?.id?.toString() ?? "",
          newDropItems.length.toString(),
          ...newDropItems,
        ],
        metadata: `Dropping ${item}!`,
      };
      removeEntrypointFromCalls(dropItemsTx.entrypoint);
      addToCalls(dropItemsTx);
    }
  };

  const attributes = [
    {
      key: "STR",
      value: (formatAdventurer.strength ?? 0) + upgrades["Strength"],
      upgrade: upgrades["Strength"],
    },
    {
      key: "DEX",
      value: (formatAdventurer.dexterity ?? 0) + upgrades["Dexterity"],
      upgrade: upgrades["Dexterity"],
    },
    {
      key: "INT",
      value: (formatAdventurer.intelligence ?? 0) + upgrades["Intelligence"],
      upgrade: upgrades["Intelligence"],
    },
    {
      key: "VIT",
      value: (formatAdventurer.vitality ?? 0) + upgrades["Vitality"],
      upgrade: upgrades["Vitality"],
    },
    {
      key: "WIS",
      value: (formatAdventurer.wisdom ?? 0) + upgrades["Wisdom"],
      upgrade: upgrades["Wisdom"],
    },
    {
      key: "CHA",
      value: (formatAdventurer.charisma ?? 0) + upgrades["Charisma"],
      upgrade: upgrades["Charisma"],
    },
    {
      key: "LUCK",
      value: formatAdventurer.luck ?? 0,
      upgrade: upgrades["Luck"],
    },
  ];

  const bodyParts = [
    "Weapon",
    "Chest",
    "Head",
    "Waist",
    "Foot",
    "Hand",
    "Neck",
    "Ring",
  ];

  const vitalitySelected = upgrades["Vitality"];

  const totalVitality = (formatAdventurer.vitality ?? 0) + vitalitySelected;

  const maxHealth = Math.min(
    100 + (totalVitality - vitBoostRemoved) * vitalityIncrease,
    1023
  );

  const healthPlus = Math.min(
    vitalitySelected * vitalityIncrease + potionAmount * 10,
    maxHealth - (formatAdventurer.health ?? 0)
  );

  const maxHealthPlus = vitalitySelected * vitalityIncrease;

  const totalHealth = Math.min(
    (formatAdventurer.health ?? 0) + healthPlus,
    maxHealth
  );

  const adventurerLevel = calculateLevel(adventurer?.xp ?? 0);

  return (
    <>
      {adventurer?.id ? (
        <div className="flex flex-col w-full uppercase h-full p-2 border border-terminal-green">
          <div className="relative flex justify-between w-full text-xl sm:text-2xl lg:text-3xl">
            {formatAdventurer.name}
            <span className="flex items-center text-terminal-yellow">
              <CoinIcon className="self-center mt-1 w-5 h-5 fill-current" />{" "}
              {formatAdventurer.gold
                ? formatAdventurer.gold - (upgradeCost ?? 0)
                : 0}
              <span className="absolute top-0 right-[-20px] text-xs">
                {formatAdventurer.gold === 511 ? "Full" : ""}
              </span>
            </span>
            <span className="flex flex-row gap-1 items-center ">
              <HeartIcon className="self-center mt-1 w-5 h-5 fill-current" />{" "}
              <HealthCountDown health={totalHealth || 0} />
              {`/${maxHealth}`}
            </span>
            {(potionAmount > 0 || vitalitySelected > 0) && (
              <p className="absolute top-[-5px] sm:top-[-10px] right-[30px] sm:right-[40px] text-xs sm:text-sm">
                +{healthPlus}
              </p>
            )}
            {vitalitySelected > 0 && (
              <p className="absolute top-[-5px] sm:top-[-10px] right-0 text-xs sm:text-sm">
                +{maxHealthPlus}
              </p>
            )}
          </div>
          <hr className="border-terminal-green" />
          <div className="flex justify-between w-full sm:text-sm lg:text-xl pb-1">
            <LevelBar xp={formatAdventurer.xp ?? 0} />
          </div>

          {adventurerLevel > 1 ? (
            <div className="flex flex-row w-full font-semibold text-xs sm:text-sm lg:text-base mb-1">
              {attributes.map((attribute) => (
                <div
                  key={attribute.key}
                  className="flex flex-wrap justify-between p-1 bg-terminal-green text-terminal-black w-full border border-terminal-black relative"
                >
                  {attribute.key}
                  <span className="flex flex-row items-center">
                    {attribute.upgrade > 0 && (
                      <span className="text-xs">{`(+${attribute.upgrade})`}</span>
                    )}
                    <span className="pl-1">{attribute.value}</span>
                  </span>
                </div>
              ))}
            </div>
          ) : (
            <div className="w-full bg-terminal-green text-terminal-black text-center font-semibold mb-1">
              Stats Hidden
            </div>
          )}

          <div className="w-full flex flex-col gap-1 text-xs overflow-y-scroll default-scroll h-[500px]">
            {bodyParts.map((part) => (
              <ItemDisplay
                item={
                  filteredItems.find((item: Item) => {
                    const { slot } = getItemData(item.item!);
                    return slot === part && item.equipped;
                  }) || NullItem
                }
                itemSlot={part}
                handleDrop={handleDropItems}
                gameContract={gameContract}
                key={part}
              />
            ))}
          </div>
        </div>
      ) : (
        <div className="flex items-center justify-center border border-terminal-green xl:h-[500px]">
          <QuestionMarkIcon className="w-1/2 h-1/2" />
        </div>
      )}
    </>
  );
}
