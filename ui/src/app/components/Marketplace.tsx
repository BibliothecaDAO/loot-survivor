import { useState, useEffect, useRef } from "react";
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
  const { lootMarketArcadeContract } = useContracts();
  const [selectedIndex, setSelectedIndex] = useState<number>(0);
  const [activeMenu, setActiveMenu] = useState<number | undefined>();
  const rowRefs = useRef<(HTMLTableRowElement | null)[]>([]);
  const [itemsCount, setItemsCount] = useState(0);

  const { data, isLoading } = useQueriesStore();

  useCustomQuery(
    "unclaimedItemsByAdventurerQuery",
    getUnclaimedItemsByAdventurer,
    {
      bidder: adventurer?.id,
      status: "Open",
    }
  );

  const unclaimedItems = data.unclaimedItemsByAdventurerQuery
    ? data.unclaimedItemsByAdventurerQuery.items
    : [];

  const latestMarketItemsNumber = data.latestMarketItemsNumberQuery
    ? data.latestMarketItemsNumberQuery.market[0]?.itemsNumber
    : [];

  const marketLatestItems = data.latestMarketItemsQuery
    ? unclaimedItems.concat(data.latestMarketItemsQuery.items)
    : [];

  const bidders: number[] = [];

  for (const dict of marketLatestItems) {
    if (dict.bidder && !bidders.includes(dict.bidder)) {
      bidders.push(dict.bidder);
    }
  }

  useCustomQuery("adventurersInListQuery", getAdventurersInList, {
    ids: bidders,
  });

  const adventurers = data.adventurersInListQuery
    ? data.adventurersInListQuery.adventurers
    : [];

  const mintDailyItemsTx = {
    contractAddress: lootMarketArcadeContract?.address ?? "",
    entrypoint: "mint_daily_items",
    calldata: [],
    metadata: `Minting Loot Items!`,
  };

  console.log(data);

  useEffect(() => {
    if (marketLatestItems) {
      setItemsCount(marketLatestItems.length);
    }
    console.log(marketLatestItems.length);
  }, [selectedIndex]);

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
    "Rank",
    "Slot",
    "Type",
    "Material",
    "Greatness",
    "XP",
    "Price",
    "Bidder",
    "Expiry",
    "Status",
    "Claimed",
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

  const nextMint = new Date(
    new Date(
      data.latestMarketItemsNumberQuery?.market[0]?.timestamp
    ).getTime() +
      (8 * 60 + currentTimezoneOffsetMinutes) * 60 * 1000
  );

  console.log(marketLatestItems);

  return (
    <>
      {adventurer?.level != 1 ? (
        <div className="w-full">
          <div className="flex flex-row justify-between m-1">
            <div className="flex flex-row align-items">
              <Button
                onClick={() => addToCalls(mintDailyItemsTx)}
                className={selectedIndex == 0 ? "animate-pulse" : ""}
                variant={selectedIndex == 0 ? "default" : "ghost"}
              >
                Mint daily items
              </Button>
              <div className="self-center">
                <Countdown
                  countingMessage="Next mint in:"
                  endTime={nextMint}
                  finishedMessage="Items can be minted!"
                  nextMintTime={nextMint}
                />
              </div>
            </div>
            <div>
              <span className="flex text-xl text-terminal-yellow">
                Gold Balance:
                <Coin className="self-center w-8 h-8 fill-current" />
                {adventurer?.gold ? adventurer?.gold - sum : ""}
              </span>
            </div>
            <UTCClock />
          </div>
          <div className="w-full overflow-y-auto border h-[650px] border-terminal-green">
            {isLoading.latestMarketItemsQuery && (
              <div className="flex justify-center p-10 text-center">
                <LootIconLoader />
              </div>
            )}
            <table className="w-full border border-terminal-green ">
              <thead className="sticky top-0 border z-5 border-terminal-green bg-terminal-black">
                <tr className="">
                  {headings.map((heading, index) => (
                    <th key={index}>{heading}</th>
                  ))}
                </tr>
              </thead>
              <tbody className="">
                {!isLoading.latestMarketItemsQuery &&
                  marketLatestItems.map((item: any, index: number) => (
                    <MarketplaceRow
                      ref={(ref: any) => (rowRefs.current[index] = ref)}
                      item={item}
                      index={index}
                      selectedIndex={selectedIndex}
                      adventurers={adventurers}
                      isActive={activeMenu == index + 1}
                      setActiveMenu={setActiveMenu}
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
