import { useMemo } from "react";
import { Adventurer, NullAdventurer, NullItem } from "../../types";
import { getItemsByAdventurer } from "../../hooks/graphql/queries";
import { HeartIcon, CoinIcon, BagIcon } from "../icons/Icons";
import { ItemDisplay } from "./ItemDisplay";
import LevelBar from "./LevelBar";
import {
  calculateLevel,
  getRealmNameById,
  getKeyFromValue,
  countOccurrences,
} from "../../lib/utils";
import { useQueriesStore } from "../../hooks/useQueryStore";
import useCustomQuery from "../../hooks/useCustomQuery";
import useUIStore from "../../hooks/useUIStore";
import useLoadingStore from "../../hooks/useLoadingStore";
import { Item } from "@/app/types";
import { HealthCountDown } from "../CountDown";
import { GameData } from "../GameData";
import { useContracts } from "@/app/hooks/useContracts";
import useTransactionCartStore from "@/app/hooks/useTransactionCartStore";

interface InfoProps {
  adventurer: Adventurer | undefined;
  profileExists?: boolean;
  upgradeCost?: number;
}

export default function Info({
  adventurer,
  profileExists,
  upgradeCost,
}: InfoProps) {
  const formatAdventurer = adventurer ? adventurer : NullAdventurer;
  const profile = useUIStore((state) => state.profile);
  const { data, isLoading, data: storeData } = useQueriesStore();
  const txAccepted = useLoadingStore((state) => state.txAccepted);
  const dropItems = useUIStore((state) => state.dropItems);
  const setDropItems = useUIStore((state) => state.setDropItems);
  const upgrades = useUIStore((state) => state.upgrades);
  const addToCalls = useTransactionCartStore((state) => state.addToCalls);
  const removeEntrypointFromCalls = useTransactionCartStore(
    (state) => state.removeEntrypointFromCalls
  );
  const { gameContract } = useContracts();

  const gameData = new GameData();

  const items = profileExists
    ? data.itemsByProfileQuery
      ? data.itemsByProfileQuery.items
      : []
    : data.itemsByAdventurerQuery
    ? data.itemsByAdventurerQuery.items
    : [];

  const neckItem =
    items.find(
      (item: Item) => item.item == formatAdventurer.neck && item.equipped
    ) || NullItem;

  const ringItem =
    items.find(
      (item: Item) => item.item == formatAdventurer.ring && item.equipped
    ) || NullItem;

  const luck =
    (neckItem.item ? calculateLevel(neckItem.xp ?? 0) : 0) +
    (ringItem.item ? calculateLevel(ringItem.xp ?? 0) : 0);

  const handleDropItems = (item: string) => {
    const newDropItems = [
      ...dropItems,
      getKeyFromValue(gameData.ITEMS, item) ?? "",
    ];
    setDropItems(newDropItems);
    if (gameContract) {
      const dropItemsTx = {
        contractAddress: gameContract?.address,
        entrypoint: "drop_items",
        calldata: [
          adventurer?.id?.toString() ?? "",
          "0",
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
    { key: "STR", value: formatAdventurer.strength ?? 0 },
    { key: "DEX", value: formatAdventurer.dexterity },
    { key: "INT", value: formatAdventurer.intelligence ?? 0 },
    { key: "VIT", value: formatAdventurer.vitality ?? 0 },
    { key: "WIS", value: formatAdventurer.wisdom ?? 0 },
    { key: "CHA", value: formatAdventurer.charisma ?? 0 },
    { key: "LUCK", value: luck },
  ];

  const bodyParts = [
    "Weapon",
    "Chest",
    "Head",
    "Hand",
    "Waist",
    "Foot",
    "Neck",
    "Ring",
  ];

  const vitalitySelected = upgrades["Vitality"];
  const totalHealth = (formatAdventurer.health ?? 0) + vitalitySelected * 10;

  const totalVitality = (formatAdventurer.vitality ?? 0) + vitalitySelected;

  return (
    <div className="border border-terminal-green xl:h-[500px] 2xl:h-full">
      <div className="flex flex-row flex-wrap gap-2 p-1 xl:h-full">
        <div className="flex flex-col w-full sm:p-2 uppercase xl:h-full">
          <div className="flex justify-between w-full text-xl sm:text-2xl lg:text-3xl border-b border-terminal-green">
            {formatAdventurer.name}
            <span className="flex items-center text-terminal-yellow">
              <CoinIcon className="self-center mt-1 w-5 h-5 fill-current" />{" "}
              {formatAdventurer.gold
                ? formatAdventurer.gold - (upgradeCost ?? 0)
                : 0}
              {formatAdventurer.gold === 511 ? "Full" : ""}
            </span>
            {/* <span className="flex text-lg items-center sm:text-3xl">
                <BagIcon className="self-center w-4 h-4 fill-current" />{" "}
                {`${items.length}/${19}`}
              </span> */}
            <span className="flex items-center ">
              <HeartIcon className="self-center mt-1 w-5 h-5 fill-current" />{" "}
              <HealthCountDown health={totalHealth || 0} />
              {`/${Math.min(100 + totalVitality * 10, 720)}`}
            </span>
          </div>
          {adventurer?.id ? (
            <div className="flex justify-between w-full text-sm sm:text-base">
              {formatAdventurer.classType}{" "}
              <span>
                {
                  getRealmNameById(formatAdventurer.homeRealm ?? 0)?.properties
                    .name
                }
              </span>
            </div>
          ) : (
            <span className="text-center text-lg text-terminal-yellow">
              No Adventurer Selected
            </span>
          )}
          <hr className="border-terminal-green" />
          <div className="flex justify-between w-full sm:text-sm lg:text-xl pb-1">
            <LevelBar xp={formatAdventurer.xp ?? 0} />
          </div>

          <div className="flex flex-col w-full justify-between overflow-hidden">
            <div className="flex flex-row w-full font-semibold text-xs sm:text-sm lg:text-base">
              {attributes.map((attribute) => (
                <div
                  key={attribute.key}
                  className="flex flex-wrap justify-between p-1 bg-terminal-green text-terminal-black w-full border border-terminal-black  sm:mb-2"
                >
                  {attribute.key}
                  <span className="pl-1">{attribute.value}</span>
                </div>
              ))}
            </div>
            <div className="w-full flex flex-col sm:gap-1 2xl:gap-0 text-xs h-full overflow-y-auto 2xl:overflow-hidden">
              {bodyParts.map((part) => (
                <ItemDisplay
                  item={
                    items.find(
                      (item: Item) =>
                        item.item === formatAdventurer[part.toLowerCase()] &&
                        item.equipped
                    ) || NullItem
                  }
                  itemSlot={part}
                  handleDrop={handleDropItems}
                  key={part}
                />
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
