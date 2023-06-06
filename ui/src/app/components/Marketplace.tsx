import { useState, useEffect, useRef, useMemo } from "react";
import { useContracts } from "../hooks/useContracts";
import { Button } from "./Button";
import { useQuery } from "@apollo/client";
import {
  getLatestMarketItems,
  getAdventurersInList,
  getLatestMarketItemsNumber,
  getUnclaimedItemsByAdventurer,
} from "../hooks/graphql/queries";
import { UTCClock, Countdown } from "./Clock";
import { convertTime } from "../lib/utils";
import MarketplaceRow from "./MarketplaceRow";
import useAdventurerStore from "../hooks/useAdventurerStore";
import useTransactionCartStore from "../hooks/useTransactionCartStore";
import Coin from "../../../public/coin.svg";
import LootIconLoader from "./Loader";
import useCustomQuery from "../hooks/useCustomQuery";
import { useQueriesStore } from "../hooks/useQueryStore";

const Marketplace = () => {
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const calls = useTransactionCartStore((state) => state.calls);
  const addToCalls = useTransactionCartStore((state) => state.addToCalls);
  const { lootMarketArcadeContract, adventurerContract } = useContracts();
  const [selectedIndex, setSelectedIndex] = useState<number>(0);
  const [activeMenu, setActiveMenu] = useState<number | undefined>();
  const rowRefs = useRef<(HTMLTableRowElement | null)[]>([]);
  const [itemsCount, setItemsCount] = useState(0);
  const [sortField, setSortField] = useState<string | null>(null);
  const [sortDirection, setSortDirection] = useState<"asc" | "desc">("asc");

  const { data, isLoading, refetch } = useQueriesStore();

  const currentTime = new Date().getTime();

  useCustomQuery(
    "unclaimedItemsByAdventurerQuery",
    getUnclaimedItemsByAdventurer,
    {
      bidder: adventurer?.id,
      status: "Open",
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

  const unclaimedItems = data.unclaimedItemsByAdventurerQuery
    ? data.unclaimedItemsByAdventurerQuery.items
    : [];

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
    ? removeDuplicates(unclaimedItems.concat(data.latestMarketItemsQuery.items))
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

  useCustomQuery(
    "latestMarketItemsNumberQuery",
    getLatestMarketItemsNumber,
    undefined,
    true
  );

  const latestMarketItemsNumber = data.latestMarketItemsNumberQuery
    ? data.latestMarketItemsNumberQuery.market[0]?.itemsNumber
    : [];

  useCustomQuery(
    "latestMarketItemsQuery",
    getLatestMarketItems,
    {
      itemsNumber: latestMarketItemsNumber,
    },
    true
  );

  const adventurers = data.adventurersInListQuery
    ? data.adventurersInListQuery.adventurers
    : [];

  const mintDailyItemsTx = {
    contractAddress: lootMarketArcadeContract?.address ?? "",
    entrypoint: "mint_daily_items",
    calldata: [],
    metadata: `Minting Loot Items!`,
  };

  const getClaimableItems = () => {
    return marketLatestItems.filter(
      (item: any) =>
        !item.claimedTime &&
        item.expiry &&
        convertTime(item.expiry) <= currentTime &&
        !singleClaimExists(item.marketId) &&
        adventurer?.id === item.bidder
    );
  };

  const handleClaimItem = (item: any) => {
    if (adventurerContract) {
      const claimItemTx = {
        contractAddress: lootMarketArcadeContract?.address ?? "",
        entrypoint: "claim_item",
        calldata: [item.marketId, "0", adventurer?.id, "0"],
        metadata: `Claiming ${item.item}`,
      };
      addToCalls(claimItemTx);
    }
  };

  const claimAllItems = () => {
    const claimableItems = getClaimableItems();
    claimableItems.forEach((item: any) => {
      handleClaimItem(item);
    });
  };

  const headingToKeyMapping: { [key: string]: string } = {
    "Market Id": "marketId",
    Item: "item",
    Tier: "rank",
    Slot: "slot",
    Type: "type",
    Material: "material",
    Greatness: "greatness",
    XP: "xp",
    Price: "price",
    Bidder: "bidder",
    "Bidding Ends": "expiry",
    Status: "status",
    "Claimed (UTC)": "claimedTime",
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

  const headings = [
    "Market Id",
    "Item",
    "Tier",
    "Slot",
    "Type",
    "Material",
    "Greatness",
    "XP",
    "Price",
    "Bidder",
    "Bidding Ends",
    "Status",
    "Claimed (UTC)",
    "Actions",
  ];

  const sum = calls
    .filter((call) => call.entrypoint === "bid_on_item")
    .reduce((accumulator, current) => {
      const value = current.calldata[4];
      const parsedValue = value ? parseInt(value.toString(), 10) : 0;
      return accumulator + (isNaN(parsedValue) ? 0 : parsedValue);
    }, 0);

  const currentTimezoneOffsetMinutes = new Date().getTimezoneOffset() * -1;

  const nextMint = data.latestMarketItemsNumberQuery?.market[0]?.timestamp
    ? new Date(
        new Date(
          data.latestMarketItemsNumberQuery?.market[0]?.timestamp
        ).getTime() +
          (3 * 60 + currentTimezoneOffsetMinutes) * 60 * 1000
      )
    : undefined;

  const calculatedNewGold = adventurer?.gold ? adventurer?.gold - sum : 0;

  return (
    <>
      {adventurer?.level != 1 ? (
        <div className="w-full">
          <div className="flex flex-row justify-between m-1 flex-wrap">
            <div className="flex flex-row align-items flex-wrap">
              <Button
                onClick={() => addToCalls(mintDailyItemsTx)}
                disabled={nextMint && currentTime < nextMint.getTime()}
              >
                Mint daily items
              </Button>
              <Button
                onClick={claimAllItems}
                disabled={claimExists() || getClaimableItems().length == 0}
              >
                Claim All
              </Button>

              <div className="self-center ml-1">
                <Countdown
                  countingMessage={
                    nextMint ? "Next mint in:" : "No items minted yet!"
                  }
                  finishedMessage="Items can be minted!"
                  targetTime={nextMint}
                />
              </div>
            </div>
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
            <UTCClock />
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
                      className="px-2 cursor-pointer"
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
                      ref={(ref: any) => (rowRefs.current[index] = ref)}
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
