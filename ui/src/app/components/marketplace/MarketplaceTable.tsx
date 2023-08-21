import { useState, useMemo } from "react";
import MarketplaceRow from "../../components/marketplace/MarketplaceRow";
import { Item, UpgradeStats, ItemPurchase } from "@/app/types";
import { getItemData } from "@/app/lib/utils";
import { useQueriesStore } from "@/app/hooks/useQueryStore";
import LootIconLoader from "../../components/icons/Loader";

export interface MarketplaceTableProps {
  showEquipQ: number | null;
  setShowEquipQ: (value: number | null) => void;
  purchaseItems: ItemPurchase[];
  setPurchaseItems: (value: ItemPurchase[]) => void;
  upgradeHandler: (
    upgrades?: UpgradeStats,
    potions?: number,
    purchases?: any[]
  ) => void;
  totalCharisma: number;
  calculatedNewGold: number;
}

const MarketplaceTable = ({
  showEquipQ,
  setShowEquipQ,
  purchaseItems,
  setPurchaseItems,
  upgradeHandler,
  totalCharisma,
  calculatedNewGold,
}: MarketplaceTableProps) => {
  const [selectedIndex, setSelectedIndex] = useState<number>(0);
  const [sortField, setSortField] = useState<string | null>(null);
  const [sortDirection, setSortDirection] = useState<"asc" | "desc">("asc");

  const { isLoading } = useQueriesStore();

  const marketLatestItems = useQueriesStore(
    (state) => state.data.latestMarketItemsQuery?.items || []
  );
  const adventurers = useQueriesStore(
    (state) => state.data.adventurersInListQuery?.adventurers || []
  );
  const adventurerItems = useQueriesStore(
    (state) => state.data.itemsByAdventurerQuery?.items || []
  );

  const headings = ["Item", "Tier", "Slot", "Type", "Cost", "Actions"];

  const headingToKeyMapping: { [key: string]: string } = {
    Item: "item",
    Tier: "tier",
    Slot: "slot",
    Type: "type",
    Cost: "cost",
  };

  const handleSort = (heading: string) => {
    const mappedField = headingToKeyMapping[heading];
    if (!mappedField) return;

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
      let aItemData = getItemData(a.item ?? ""); // get item data for a
      let bItemData = getItemData(b.item ?? ""); // get item data for b
      let aValue, bValue;

      if (
        sortField === "tier" ||
        sortField === "type" ||
        sortField === "slot"
      ) {
        aValue = aItemData[sortField];
        bValue = bItemData[sortField];
      } else {
        aValue = a[sortField];
        bValue = b[sortField];
      }

      if (typeof aValue === "string" && !isNaN(Number(aValue))) {
        aValue = Number(aValue);
        bValue = Number(bValue);
      }

      if ((aValue ?? "") < (bValue ?? ""))
        return sortDirection === "asc" ? -1 : 1;
      if ((aValue ?? "") > (bValue ?? ""))
        return sortDirection === "asc" ? 1 : -1;
      return 0;
    });
    return sortedItems;
  }, [marketLatestItems, sortField, sortDirection]);

  return (
    <table className="w-full sm:border sm:border-terminal-green">
      <thead className="sticky top-0 sm:border z-5 sm:border-terminal-green bg-terminal-black sm:text-xl">
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
      <tbody className="text-xs sm:text-base">
        {!isLoading.latestMarketItemsQuery ? (
          sortedMarketLatestItems.map((item: Item, index: number) => (
            <MarketplaceRow
              item={item}
              index={index}
              selectedIndex={selectedIndex}
              adventurers={adventurers}
              activeMenu={showEquipQ}
              setActiveMenu={setShowEquipQ}
              calculatedNewGold={calculatedNewGold}
              ownedItems={adventurerItems}
              purchaseItems={purchaseItems}
              setPurchaseItems={setPurchaseItems}
              upgradeHandler={upgradeHandler}
              totalCharisma={totalCharisma}
              key={index}
            />
          ))
        ) : (
          <div className="h-full w-full flex justify-center p-10 align-center">
            Generating Loot{" "}
            <LootIconLoader className="self-center ml-3" size={"w-4"} />
          </div>
        )}
      </tbody>
    </table>
  );
};

export default MarketplaceTable;
