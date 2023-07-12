import { useState, useEffect, useRef, useMemo, useCallback } from "react";
import { useContracts } from "../hooks/useContracts";
import {
  getLatestMarketItems,
  getAdventurersInList,
} from "../hooks/graphql/queries";
import MarketplaceRow from "../components/marketplace/MarketplaceRow";
import useAdventurerStore from "../hooks/useAdventurerStore";
import useTransactionCartStore from "../hooks/useTransactionCartStore";
import { CoinIcon } from "../components/icons/Icons";
import LootIconLoader from "../components/icons/Loader";
import useCustomQuery from "../hooks/useCustomQuery";
import { useQueriesStore } from "../hooks/useQueryStore";
import { ItemTemplate } from "../types/templates";
import useUIStore from "../hooks/useUIStore";
import { Call, Item } from "../types";

/**
 * @container
 * @description Provides the marketplace/purchase screen for the adventurer.
 */
export default function MarketplaceScreen() {
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const calls = useTransactionCartStore((state) => state.calls);
  const addToCalls = useTransactionCartStore((state) => state.addToCalls);
  const { gameContract } = useContracts();
  const [selectedIndex, setSelectedIndex] = useState<number>(0);
  const [activeMenu, setActiveMenu] = useState<number | undefined>();
  const rowRefs = useRef<(HTMLTableRowElement | null)[]>([]);
  const [itemsCount, setItemsCount] = useState(0);
  const [sortField, setSortField] = useState<string | null>(null);
  const [sortDirection, setSortDirection] = useState<"asc" | "desc">("asc");
  const setScreen = useUIStore((state) => state.setScreen);
  const profile = useUIStore((state) => state.profile);
  const { data, isLoading, refetch } = useQueriesStore();

  const currentTime = new Date().getTime();

  useCustomQuery(
    "latestMarketItemsQuery",
    getLatestMarketItems,
    {
      adventurerId: adventurer?.id,
    },
    true
  );

  const marketLatestItems = profile
  ? data.itemsByProfileQuery
    ? data.itemsByProfileQuery.items
    : []
  : data.itemsByAdventurerQuery
  ? data.itemsByAdventurerQuery.items
  : [];

  console.log(marketLatestItems)

  const adventurers = data.adventurersInListQuery
    ? data.adventurersInListQuery.adventurers
    : [];

  const headingToKeyMapping: { [key: string]: string } = {
    Item: "item",
    Tier: "rank",
    Slot: "slot",
    Type: "type",
  };

  const handleSort = (heading: string) => {
    const mappedField = headingToKeyMapping[heading];
    if (sortField === mappedField) {
      setSortDirection(sortDirection === "asc" ? "desc" : "asc");
    } else {
      setSortField(mappedField);
      setSortDirection("asc");
    }
  };

  // const sortedMarketLatestItems = useMemo(() => {
  //   if (!sortField) return marketLatestItems;
  //   const sortedItems = [...marketLatestItems].sort((a, b) => {
  //     let aValue = a[sortField];
  //     let bValue = b[sortField];

  //     if (aValue instanceof Date) {
  //       aValue = aValue.getTime();
  //       bValue = new Date(bValue).getTime();
  //     } else if (typeof aValue === "string" && !isNaN(Number(aValue))) {
  //       aValue = Number(aValue);
  //       bValue = Number(bValue);
  //     }

  //     if (aValue < bValue) return sortDirection === "asc" ? -1 : 1;
  //     if (aValue > bValue) return sortDirection === "asc" ? 1 : -1;
  //     return 0;
  //   });
  //   return sortedItems;
  // }, [marketLatestItems, sortField, sortDirection]);

  const sortedMarketLatestItems = [];

  for (var i = 0; i < 20; i++) {
    sortedMarketLatestItems.push(ItemTemplate);
  }

  const handleKeyDown = useCallback(
    (event: KeyboardEvent) => {
      switch (event.key) {
        case "ArrowDown":
          setSelectedIndex((prev) => {
            const newIndex = Math.min(prev + 1, itemsCount - 1);
            return newIndex;
          });
          break;
        case "ArrowUp":
          setSelectedIndex((prev) => {
            const newIndex = Math.max(prev - 1, 0);
            return newIndex;
          });
          break;
        case "Enter":
          setActiveMenu(selectedIndex);
          break;
      }
    },
    [selectedIndex, itemsCount]
  );

  useEffect(() => {
    if (!activeMenu) {
      window.addEventListener("keydown", handleKeyDown);
      return () => {
        window.removeEventListener("keydown", handleKeyDown);
      };
    }
  }, [activeMenu, handleKeyDown]);

  useEffect(() => {
    if (!activeMenu) {
      const button = rowRefs.current[selectedIndex];
      if (button) {
        button.scrollIntoView({
          behavior: "smooth",
          block: "nearest",
        });
      }
    }
  }, [selectedIndex, activeMenu]);

  const headings = ["Item", "Tier", "Slot", "Type", "Price", "Actions"];

  const sum = calls
    .filter((call) => call.entrypoint === "buy_item")
    .reduce((accumulator, current) => {
      const value = Array.isArray(current.calldata) && current.calldata[4];
      const parsedValue = value ? parseInt(value.toString(), 10) : 0;
      return accumulator + (isNaN(parsedValue) ? 0 : parsedValue);
    }, 0);

  const calculatedNewGold = adventurer?.gold ? adventurer?.gold - sum : 0;

  const purchaseExists = useCallback(() => {
    return calls.some((call: Call) => call.entrypoint == "buy_item");
  }, [calls]);

  useEffect(() => {
    if (purchaseExists()) {
      setScreen("upgrade");
    }
  }, [purchaseExists, setScreen]);

  return (
    <>
      {adventurer?.level != 0 ? (
        <div className="w-full">
          <div className="flex flex-row justify-between m-1 flex-wrap sm:text-xl">
            <div className="flex flex-row gap-3">
              <p>Balance:</p>
              <span className="flex text-xl text-terminal-yellow">
                <CoinIcon className="self-center w-5 h-5 fill-current" />
                {calculatedNewGold}
              </span>
            </div>
            <span className="flex flex-row gap-1">
              {`Charisma: ${adventurer?.charisma} (-`}
              <CoinIcon className="w-5 h-5 fill-current text-terminal-yellow" />
              <p className="text-terminal-yellow">
                {adventurer?.charisma && adventurer?.charisma * 3}
              </p>
              <p>{"to prices)"}</p>
            </span>
          </div>
          <div className="w-full sm:w-3/4 sm:mx-auto overflow-y-auto border h-[400px] sm:h-[650px] border-terminal-green table-scroll">
            {isLoading.latestMarketItemsQuery && (
              <div className="flex justify-center p-10 text-center">
                <LootIconLoader />
              </div>
            )}
            <table className="w-full border border-terminal-green">
              <thead className="sticky top-0 border z-5 border-terminal-green bg-terminal-black sm:text-xl">
                <tr className="">
                  {headings.map((heading, index) => (
                    <th
                      key={index}
                      className="px-2.5 sm:px-3 cursor-pointer"
                      onClick={() => handleSort(heading)}
                    >
                      {heading}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody className="">
                {!isLoading.latestMarketItemsQuery &&
                  sortedMarketLatestItems.map((item: Item, index: number) => (
                    <MarketplaceRow
                      item={item}
                      index={index}
                      selectedIndex={selectedIndex}
                      adventurers={adventurers}
                      isActive={activeMenu == index + 1}
                      setActiveMenu={setActiveMenu}
                      calculatedNewGold={calculatedNewGold}
                      key={index}
                    />
                  ))}
              </tbody>
            </table>
          </div>
        </div>
      ) : (
        <div className="flex w-full mt-[200px]">
          <p className="mx-auto items-center text-[50px] animate-pulse">
            Adventurer must be level 2 or higher to access Market!
          </p>
        </div>
      )}
    </>
  );
}
