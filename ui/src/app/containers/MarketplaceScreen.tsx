import useAdventurerStore from "@/app/hooks/useAdventurerStore";
import LootIconLoader from "@/app/components/icons/Loader";
import { useQueriesStore } from "@/app/hooks/useQueryStore";
import { Item, ItemPurchase, UpgradeStats } from "@/app/types";
import MarketplaceTable from "@/app/components/marketplace/MarketplaceTable";

export interface MarketplaceScreenProps {
  upgradeTotalCost: number;
  purchaseItems: ItemPurchase[];
  setPurchaseItems: (value: ItemPurchase[]) => void;
  upgradeHandler: (
    upgrades?: UpgradeStats,
    potions?: number,
    purchases?: ItemPurchase[]
  ) => void;
  totalCharisma: number;
  adventurerItems: Item[];
  dropItems: string[];
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
  adventurerItems,
  dropItems,
}: MarketplaceScreenProps) {
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const { isLoading } = useQueriesStore();

  const calculatedNewGold = adventurer?.gold
    ? adventurer?.gold - upgradeTotalCost
    : 0;

  return (
    <>
      <div className="w-full sm:mx-auto overflow-y-auto h-full border border-terminal-green table-scroll">
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
          adventurerItems={adventurerItems}
          dropItems={dropItems}
        />
      </div>
    </>
  );
}
