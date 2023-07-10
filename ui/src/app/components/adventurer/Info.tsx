import { Adventurer, NullAdventurer, NullItem } from "../../types";
import { getItemsByAdventurer } from "../../hooks/graphql/queries";
import { HeartIcon, CoinIcon, BagIcon } from "../icons/Icons";
import { ItemDisplay } from "./ItemDisplay";
import LevelBar from "./LevelBar";
import { getRealmNameById } from "../../lib/utils";
import { useQueriesStore } from "../../hooks/useQueryStore";
import useCustomQuery from "../../hooks/useCustomQuery";
import useUIStore from "../../hooks/useUIStore";
import useLoadingStore from "../../hooks/useLoadingStore";
import { Item } from "@/app/types";

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
  console.log(adventurer?.id ?? 0);
  console.log(items);

  return (
    <div className="h-full border border-terminal-green overflow-auto">
      {!isLoading.itemsByAdventurerQuery ? (
        <>
          <div className="flex flex-row flex-wrap gap-2 p-1">
            <div className="flex flex-col w-full sm:p-2 uppercase">
              <div className="flex justify-between w-full">
                {formatAdventurer.race}{" "}
                <span>
                  {getRealmNameById(formatAdventurer.homeRealm ?? 0)?.name}
                </span>{" "}
                <span>Order of {formatAdventurer.order}</span>
              </div>
              <div className="flex justify-between w-full text-2xl sm:text-4xl font-medium border-b border-terminal-green">
                {formatAdventurer.name}
                <span className="flex text-terminal-yellow">
                  <CoinIcon className="self-center w-6 h-6 fill-current" />{" "}
                  {formatAdventurer.gold ? formatAdventurer.gold : 0}
                </span>
                <span className="flex text-lg items-center sm:text-2xl">
                  <BagIcon className="self-center w-6 h-6 fill-current" />{" "}
                  {`${items.length}/${19}`}
                </span>
                <span className="flex ">
                  <HeartIcon className="self-center w-6 h-6 fill-current" />{" "}
                  {`${formatAdventurer.health ?? 0}/${
                    100 + (formatAdventurer.vitality ?? 0) * 20
                  }`}
                </span>
              </div>

              <div className="flex justify-between w-full text-lg sm:text-2xl">
                <LevelBar xp={formatAdventurer.xp ?? 0} />
              </div>

              <div className="flex flex-row justify-between">
                <div className="flex flex-col">
                  <div className="">
                    <ItemDisplay
                      item={
                        items.find(
                          (item: Item) => item.item == formatAdventurer.weapon
                        ) || NullItem
                      }
                    />
                  </div>
                  <div className="">
                    <ItemDisplay
                      item={
                        items.find(
                          (item: Item) => item.item == formatAdventurer.head
                        ) || NullItem
                      }
                    />
                  </div>
                  <div className="">
                    <ItemDisplay
                      item={
                        items.find(
                          (item: Item) => item.item == formatAdventurer.chest
                        ) || NullItem
                      }
                    />
                  </div>
                  <div className="">
                    <ItemDisplay
                      item={
                        items.find(
                          (item: Item) => item.item == formatAdventurer.hands
                        ) || NullItem
                      }
                    />
                  </div>
                  <div className="">
                    <ItemDisplay
                      item={
                        items.find(
                          (item: Item) => item.item == formatAdventurer.waist
                        ) || NullItem
                      }
                    />
                  </div>
                  <div className="">
                    <ItemDisplay
                      item={
                        items.find(
                          (item: Item) => item.item == formatAdventurer.feet
                        ) || NullItem
                      }
                    />
                  </div>
                  <div className="">
                    <ItemDisplay
                      item={
                        items.find(
                          (item: Item) => item.item == formatAdventurer.neck
                        ) || NullItem
                      }
                    />
                  </div>
                  <div className="">
                    <ItemDisplay
                      item={
                        items.find(
                          (item: Item) => item.item == formatAdventurer.ring
                        ) || NullItem
                      }
                    />
                  </div>
                </div>
                <div className="flex flex-col space-y-1 text-sm sm:text-xl">
                  <div className="flex justify-between px-3 bg-terminal-green text-terminal-black">
                    STR{" "}
                    <span className="pl-3">{formatAdventurer.strength}</span>
                  </div>
                  <div className="flex justify-between px-3 bg-terminal-green text-terminal-black">
                    DEX{" "}
                    <span className="pl-3">{formatAdventurer.dexterity}</span>
                  </div>
                  <div className="flex justify-between px-3 bg-terminal-green text-terminal-black">
                    INT{" "}
                    <span className="pl-3">
                      {formatAdventurer.intelligence}
                    </span>
                  </div>
                  <div className="flex justify-between px-3 bg-terminal-green text-terminal-black">
                    VIT{" "}
                    <span className="pl-3">{formatAdventurer.vitality}</span>
                  </div>
                  <div className="flex justify-between px-3 bg-terminal-green text-terminal-black">
                    WIS <span className="pl-3">{formatAdventurer.wisdom}</span>
                  </div>
                  <div className="flex justify-between px-3 bg-terminal-green text-terminal-black">
                    CHA
                    <span className="pl-3">{formatAdventurer.charisma}</span>
                  </div>
                  <div className="flex justify-between px-3 bg-terminal-green text-terminal-black">
                    LUCK <span className="pl-3">{formatAdventurer.luck}</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </>
      ) : null}
    </div>
  );
}
