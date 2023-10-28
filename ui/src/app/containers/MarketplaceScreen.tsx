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
    purchases?: any[]
  ) => void;
  totalCharisma: number;
  adventurerItems: Item[];
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
}: MarketplaceScreenProps) {
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const { isLoading } = useQueriesStore();

  const calculatedNewGold = adventurer?.gold
    ? adventurer?.gold - upgradeTotalCost
    : 0;

  const underMaxItems = adventurerItems.length < 19;

  return (
    <>
      {underMaxItems ? (
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
