import { MarketItem } from "../types";
import { useState, useEffect, useRef } from "react";
import { useContracts } from "../hooks/useContracts";
import { useTransactionCart } from "../context/TransactionCartProvider";
import {
  useAccount,
  useWaitForTransaction,
  useTransactionManager,
  useTransactions,
} from "@starknet-react/core";
import { BidBox } from "./Bid";
import { Button } from "./Button";
import HorizontalKeyboardControl from "./HorizontalMenu";
import { useQuery } from "@apollo/client";
import {
  getLatestMarketItems,
  getAdventurersInList,
  getLatestMarketItemsNumber,
} from "../hooks/graphql/queries";
import { useAdventurer } from "../context/AdventurerProvider";
import { NullAdventurerProps } from "../types";
import { UTCClock, Countdown } from "./Clock";
import MarketplaceRow from "./MarketplaceRow";

const Marketplace: React.FC = () => {
  const { adventurer } = useAdventurer();
  const { addToCalls } = useTransactionCart();
  const { lootMarketArcadeContract, adventurerContract } = useContracts();
  const [selectedIndex, setSelectedIndex] = useState<number>(0);
  const [activeMenu, setActiveMenu] = useState<number | undefined>();
  const rowRefs = useRef<(HTMLTableRowElement | null)[]>([]);
  const [itemsCount, setItemsCount] = useState(0);

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
    contractAddress: lootMarketArcadeContract?.address,
    selector: "mint_daily_items",
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

  const nextMint = new Date(
    new Date(latestMarketItemsNumberData?.market[0]?.timestamp).getTime() +
      8 * 60 * 60 * 1000
  );

  return (
    <>
      {adventurer?.adventurer?.level != 1 ? (
        <div className="w-full">
          <div className="flex flex-row m-1 justify-between">
            <div className="flex flex-row align-items">
              <Button
                onClick={() => addToCalls(mintDailyItemsTx)}
                className={selectedIndex == 0 ? "animate-pulse" : ""}
                variant={selectedIndex == 0 ? "default" : "ghost"}
              >
                Mint daily items
              </Button>
              <Countdown
                endTime={nextMint}
                finishedMessage="Items can be minted!"
              />
            </div>
            <UTCClock />
          </div>
          <div className=" overflow-auto w-full h-[432px]">
            {marketLatestItemsLoading && (
              <p className="text-xl loading-ellipsis">LOADING</p>
            )}
            {marketLatestItemsError && (
              <p className="text-xl">ERROR {marketLatestItemsError.message}</p>
            )}
            <table className="w-full border-terminal-green border mt-4 h-[425px]">
              <thead className="sticky top-0 ">
                <tr className="sticky top-0 border z-5 border-terminal-green bg-terminal-black">
                  {headings.map((heading, index) => (
                    <th key={index}>{heading}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
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
