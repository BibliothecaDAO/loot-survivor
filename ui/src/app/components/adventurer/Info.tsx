import { Adventurer, NullAdventurer, NullItem } from "../../types";
import { getItemsByAdventurer } from "../../hooks/graphql/queries";
import { HeartIcon, CoinIcon, BagIcon } from "../icons/Icons";
import { ItemDisplay } from "./ItemDisplay";
import LevelBar from "./LevelBar";
import { calculateLevel, getRealmNameById } from "../../lib/utils";
import { useQueriesStore } from "../../hooks/useQueryStore";
import useCustomQuery from "../../hooks/useCustomQuery";
import useUIStore from "../../hooks/useUIStore";
import useLoadingStore from "../../hooks/useLoadingStore";
import { Item } from "@/app/types";
import { HealthCountDown } from "../CountDown";

interface InfoProps {
  adventurer: Adventurer | undefined;
  profileExists?: boolean;
}

export default function Info({ adventurer, profileExists }: InfoProps) {
  const formatAdventurer = adventurer ? adventurer : NullAdventurer;
  const profile = useUIStore((state) => state.profile);
  const { data, isLoading } = useQueriesStore();
  const txAccepted = useLoadingStore((state) => state.txAccepted);

  useCustomQuery(
    "itemsByAdventurerQuery",
    getItemsByAdventurer,
    {
      adventurerId: adventurer?.id ?? 0,
    },
    txAccepted
  );

  useCustomQuery(
    "itemsByProfileQuery",
    getItemsByAdventurer,
    {
      adventurerId: profile ?? 0,
    },
    txAccepted
  );

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
    "Head",
    "Chest",
    "Hand",
    "Waist",
    "Foot",
    "Neck",
    "Ring",
  ];

  return (
    <div className="h-full border border-terminal-green overflow-auto">
      {!isLoading.itemsByAdventurerQuery ? (
        <>
          <div className="flex flex-row flex-wrap gap-2 p-1">
            <div className="flex flex-col w-full sm:p-2 uppercase">
              {adventurer?.id ? (
                <div className="flex justify-between w-full text-sm sm:text-base">
                  {formatAdventurer.race}{" "}
                  <span>
                    {
                      getRealmNameById(formatAdventurer.homeRealm ?? 0)
                        ?.properties.name
                    }
                  </span>
                  <span>
                    {
                      getRealmNameById(formatAdventurer.homeRealm ?? 0)
                        ?.properties.order
                    }
                  </span>
                </div>
              ) : (
                <span className="text-center text-lg text-terminal-yellow">
                  No Adventurer Selected
                </span>
              )}
              <div className="flex justify-between w-full text-xl sm:text-4xl border-b border-terminal-green">
                {formatAdventurer.name}
                <span className="flex items-center text-terminal-yellow">
                  <CoinIcon className="self-center mt-1 w-5 h-5 fill-current" />{" "}
                  {formatAdventurer.gold ? formatAdventurer.gold : 0}
                </span>
                <span className="flex text-lg items-center sm:text-3xl">
                  <BagIcon className="self-center w-4 h-4 fill-current" />{" "}
                  {`${items.length}/${19}`}
                </span>
                <span className="flex items-center ">
                  <HeartIcon className="self-center mt-1 w-5 h-5 fill-current" />{" "}
                  <HealthCountDown
                    health={(formatAdventurer.health ?? 0) || 0}
                  />
                  {`/${Math.min(
                    100 + (formatAdventurer.vitality ?? 0) * 10,
                    511
                  )}`}
                </span>
              </div>

              <div className="flex justify-between w-full mb-1 sm:text-2xl">
                <LevelBar xp={formatAdventurer.xp ?? 0} />
              </div>

              <div className="flex flex-col justify-between flex-wrap">
                <div className="flex flex-row w-full font-semibold text-sm sm:text-base">
                  {attributes.map((attribute) => (
                    <div
                      key={attribute.key}
                      className="flex justify-between px-1 bg-terminal-green text-terminal-black w-full border border-terminal-black mb-2"
                    >
                      {attribute.key}
                      <span className="pl-3">{attribute.value}</span>
                    </div>
                  ))}
                </div>
                <div className="flex flex-col w-full">
                  {bodyParts.map((part) => (
                    <div key={part} className="w-full">
                      <ItemDisplay
                        item={
                          items.find(
                            (item: Item) =>
                              item.item ===
                                formatAdventurer[part.toLowerCase()] &&
                              item.equipped
                          ) || NullItem
                        }
                        itemSlot={part}
                      />
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </div>
        </>
      ) : null}
    </div>
  );
}
