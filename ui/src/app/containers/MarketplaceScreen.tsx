import { useState, useEffect, useRef, useMemo, useCallback } from "react";
import { getLatestMarketItems } from "../hooks/graphql/queries";
import MarketplaceRow from "../components/marketplace/MarketplaceRow";
import useAdventurerStore from "../hooks/useAdventurerStore";
import LootIconLoader from "../components/icons/Loader";
import useCustomQuery from "../hooks/useCustomQuery";
import { useQueriesStore } from "../hooks/useQueryStore";
import { Item, ItemPurchase, NullItem, UpgradeStats } from "../types";
import { getItemData, getItemPrice, getKeyFromValue } from "../lib/utils";
import PurchaseHealth from "../components/actions/PurchaseHealth";
import { useMediaQuery } from "react-responsive";
import { Button } from "../components/buttons/Button";
import { useContracts } from "../hooks/useContracts";
import { GameData } from "../components/GameData";
import useTransactionCartStore from "../hooks/useTransactionCartStore";
import MarketplaceTable from "../components/marketplace/MarketplaceTable";

export interface MarketplaceScreenProps {
  upgradeTotalCost: number;
  purchaseItems: ItemPurchase[];
  setPurchaseItems: (value: ItemPurchase[]) => void;
  upgradeHandler: (
    upgrades?: UpgradeStats,
    potions?: number,
    purchases?: any[]
  ) => void;
  totalCharisma: number;
}
/**
 * @container
 * @description Provides the marketplace/purchase screen for the adventurer.
 */

export default function MarketplaceScreen({
  upgradeTotalCost,
  purchaseItems,
  setPurchaseItems,
  upgradeHandler,
  totalCharisma,
}: MarketplaceScreenProps) {
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const [selectedIndex, setSelectedIndex] = useState<number>(0);
  const [activeMenu, setActiveMenu] = useState<number | undefined>();
  const rowRefs = useRef<(HTMLTableRowElement | null)[]>([]);
  const [itemsCount, setItemsCount] = useState(0);
  const { isLoading } = useQueriesStore();

  const adventurerItems = useQueriesStore(
    (state) => state.data.itemsByAdventurerQuery?.items || []
  );

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

  const calculatedNewGold = adventurer?.gold
    ? adventurer?.gold - upgradeTotalCost
    : 0;

  const underMaxItems = adventurerItems.length < 19;

  return (
    <>
      {underMaxItems ? (
        <div className="w-full sm:mx-auto overflow-y-auto h-[300px] sm:h-[400px] border border-terminal-green table-scroll">
          {isLoading.latestMarketItemsQuery && (
            <div className="flex justify-center p-10 text-center">
              <LootIconLoader />
            </div>
          )}
          <MarketplaceTable
            purchaseItems={purchaseItems}
            setPurchaseItems={setPurchaseItems}
            upgradeHandler={upgradeHandler}
            totalCharisma={totalCharisma}
            calculatedNewGold={calculatedNewGold}
          />
        </div>
      ) : (
        <div className="flex w-full h-64">
          <p className="m-auto items-center text-2xl sm:text-4xl animate-pulse">
            You have a full inventory!
          </p>
        </div>
      )}
    </>
  );
}
