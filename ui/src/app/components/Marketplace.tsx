import { useState, useEffect, useRef } from "react";
import { useContracts } from "../hooks/useContracts";
import { Button } from "./Button";
import { useQuery } from "@apollo/client";
import {
  getLatestMarketItems,
  getAdventurersInList,
  getLatestMarketItemsNumber,
} from "../hooks/graphql/queries";
import { UTCClock, Countdown } from "./Clock";
import MarketplaceRow from "./MarketplaceRow";
import useAdventurerStore from "../hooks/useAdventurerStore";
import useTransactionCartStore from "../hooks/useTransactionCartStore";
import Coin from "../../../public/coin.svg";
import { NullAdventurer } from "../types";
import LootIconLoader from "./Loader";

const Marketplace = () => {
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const calls = useTransactionCartStore((state) => state.calls);
  const addToCalls = useTransactionCartStore((state) => state.addToCalls);
  const { lootMarketArcadeContract, adventurerContract } = useContracts();
  const [selectedIndex, setSelectedIndex] = useState<number>(0);
  const [activeMenu, setActiveMenu] = useState<number | undefined>();
  const rowRefs = useRef<(HTMLTableRowElement | null)[]>([]);
  const [itemsCount, setItemsCount] = useState(0);

  const formatAdventurer = adventurer ? adventurer.adventurer : NullAdventurer;

  const {
    loading: latestMarketItemsNumberLoading,
    error: latestMarketItemsNumberError,
    data: latestMarketItemsNumberData,
    refetch: latestMarketItemsNumberRefetch,
  } = useQuery(getLatestMarketItemsNumber, {
    pollInterval: 5000,
  });

  const latestMarketItemsNumber = latestMarketItemsNumberData
    ? latestMarketItemsNumberData.market[0]?.itemsNumber
    : [];

  const {
    loading: marketLatestItemsLoading,
    error: marketLatestItemsError,
    data: marketLatestItemsData,
    refetch: marketLatestItemsRefetch,
  } = useQuery(getLatestMarketItems, {
    variables: {
      itemsNumber: latestMarketItemsNumber,
    },
    pollInterval: 5000,
  });

  const marketLatestItems = marketLatestItemsData
    ? marketLatestItemsData.items
    : [];

  const bidders: number[] = [];

  for (const dict of marketLatestItems) {
    if (dict.bidder && !bidders.includes(dict.bidder)) {
      bidders.push(dict.bidder);
    }
  }

  const {
    loading: adventurersInListLoading,
    error: adventurersInListError,
    data: adventurersInListData,
    refetch: adventurersInListRefetch,
  } = useQuery(getAdventurersInList, {
    variables: {
      ids: bidders,
    },
    pollInterval: 5000,
  });

  const formatAdventurers = adventurersInListData
    ? adventurersInListData.adventurers
    : [];

  const mintDailyItemsTx = {
    contractAddress: lootMarketArcadeContract?.address ?? "",
    entrypoint: "mint_daily_items",
    calldata: [],
    metadata: `Minting Loot Items!`,
  };

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
    new Date(latestMarketItemsNumberData?.market[0]?.timestamp).getTime() +
    (8 * 60 + currentTimezoneOffsetMinutes) * 60 * 1000
  );

  return (
    <>
      {adventurer?.adventurer?.level != 1 ? (
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
                {formatAdventurer?.gold ? formatAdventurer?.gold - sum : ""}
              </span>
            </div>
            <UTCClock />
          </div>
          <div className="w-full overflow-y-auto border h-[650px] border-terminal-green">
            {marketLatestItemsLoading && (
              <div className="flex justify-center p-10 text-center">
                <LootIconLoader />
              </div>

            )}
            {marketLatestItemsError && (
              <p className="text-xl">ERROR {marketLatestItemsError.message}</p>
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
                {!marketLatestItemsLoading &&
                  !marketLatestItemsError &&
                  marketLatestItems.map((item: any, index: number) => (
                    <MarketplaceRow
                      ref={(ref: any) => (rowRefs.current[index] = ref)}
                      item={item}
                      index={index}
                      selectedIndex={selectedIndex}
                      adventurers={formatAdventurers}
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
