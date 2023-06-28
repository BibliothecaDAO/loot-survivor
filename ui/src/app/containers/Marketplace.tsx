import { useState, useEffect, useRef, useMemo } from "react";
import { useContracts } from "../hooks/useContracts";
import { Button } from "../components/buttons/Button";
import {
  getLatestMarketItems,
  getAdventurersInList,
  getUnclaimedItemsByAdventurer,
} from "../hooks/graphql/queries";
import { UTCClock, Countdown } from "../components/marketplace/Clock";
import { convertTime } from "../lib/utils";
import MarketplaceRow from "../components/marketplace/MarketplaceRow";
import useAdventurerStore from "../hooks/useAdventurerStore";
import useTransactionCartStore from "../hooks/useTransactionCartStore";
import Coin from "../../../../public/coin.svg";
import LootIconLoader from "../components/icons/Loader";
import useCustomQuery from "../hooks/useCustomQuery";
import { useQueriesStore } from "../hooks/useQueryStore";

/**
 * @container
 * @description Provides the marketplace/purchase screen for the adventurer.
 */
const Marketplace = () => {
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

  const claimExists = () => {
    return calls.some((call: any) => call.entrypoint == "claim_item");
  };

  const singleClaimExists = (marketId: number) => {
    return calls.some(
      (call: any) =>
        call.entrypoint == "claim_item" && call.calldata[0] == marketId
    );
  };

  const removeDuplicates = (arr: any) => {
    return arr.reduce((accumulator: any, currentItem: any) => {
      if (
        !accumulator.some((item: any) => item.marketId === currentItem.marketId)
      ) {
        accumulator.push(currentItem);
      }
      return accumulator;
    }, []);
  };

  const marketLatestItems = data.latestMarketItemsQuery
    ? data.latestMarketItemsQuery.items
    : [];
  const bidders: number[] = [];

  for (const dict of marketLatestItems) {
    if (dict.bidder && !bidders.includes(dict.bidder)) {
      bidders.push(dict.bidder);
    }
  }

  useCustomQuery(
    "adventurersInListQuery",
    getAdventurersInList,
    {
      ids: bidders,
    },
    false
  );

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

  const sortedMarketLatestItems = useMemo(() => {
    if (!sortField) return marketLatestItems;
    const sortedItems = [...marketLatestItems].sort((a, b) => {
      let aValue = a[sortField];
      let bValue = b[sortField];

      if (aValue instanceof Date) {
        aValue = aValue.getTime();
        bValue = new Date(bValue).getTime();
      } else if (typeof aValue === "string" && !isNaN(Number(aValue))) {
        aValue = Number(aValue);
        bValue = Number(bValue);
      }

      if (aValue < bValue) return sortDirection === "asc" ? -1 : 1;
      if (aValue > bValue) return sortDirection === "asc" ? 1 : -1;
      return 0;
    });
    return sortedItems;
  }, [marketLatestItems, sortField, sortDirection]);

  const handleKeyDown = (event: KeyboardEvent) => {
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
  };

  useEffect(() => {
    if (!activeMenu) {
      window.addEventListener("keydown", handleKeyDown);
      return () => {
        window.removeEventListener("keydown", handleKeyDown);
      };
    }
  }, [activeMenu]);

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
  }, [selectedIndex]);

  const headings = ["Item", "Tier", "Slot", "Type", "Price", "Actions"];

  const sum = calls
    .filter((call) => call.entrypoint === "buy_item")
    .reduce((accumulator, current) => {
      const value = current.calldata[4];
      const parsedValue = value ? parseInt(value.toString(), 10) : 0;
      return accumulator + (isNaN(parsedValue) ? 0 : parsedValue);
    }, 0);

  const calculatedNewGold = adventurer?.gold ? adventurer?.gold - sum : 0;

  return (
    <>
      {adventurer?.level != 1 ? (
        <div className="w-full">
          <div className="flex flex-row justify-between m-1 flex-wrap">
            <div>
              <span className="flex text-xl text-terminal-yellow">
                <Coin className="self-center w-5 h-5 fill-current" />
                {calculatedNewGold}
              </span>
            </div>
            <span className="flex flex-row">
              {`Charisma: ${adventurer?.charisma} (+ ${
                adventurer?.charisma && adventurer?.charisma * 3
              }`}
              <Coin className="w-5 h-5 fill-current text-terminal-yellow" />{" "}
              {"to bids)"}
            </span>
          </div>
          <div className="w-full overflow-y-auto border h-[650px] border-terminal-green table-scroll">
            {isLoading.latestMarketItemsQuery && (
              <div className="flex justify-center p-10 text-center">
                <LootIconLoader />
              </div>
            )}
            <table className="w-full border border-terminal-green">
              <thead className="sticky top-0 border z-5 border-terminal-green bg-terminal-black">
                <tr className="">
                  {headings.map((heading, index) => (
                    <th
                      key={index}
                      className="px-3 cursor-pointer"
                      onClick={() => handleSort(heading)}
                    >
                      {heading}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody className="">
                {!isLoading.latestMarketItemsQuery &&
                  sortedMarketLatestItems.map((item: any, index: number) => (
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
};

export default Marketplace;
