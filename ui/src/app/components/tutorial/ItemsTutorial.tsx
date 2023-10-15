import LootIcon from "../icons/LootIcon";

export const ItemsTutorial = () => {
  return (
    <div className="flex flex-col gap-5 uppercase items-center text-center h-full">
      <h3 className="mt-0">Loot Items</h3>

      <p className="sm:text-lg">
        Loot Survivor uses the 101 items from the OG Loot contract, consisting of: 18 weapons, 75 armor pieces, 5 rings, and 3 necklaces.
      </p>

      <div className="flex flex-row gap-2">
        <LootIcon type="weapon" size="w-8" />
        <LootIcon type="chest" size="w-8" />
        <LootIcon type="head" size="w-8" />
        <LootIcon type="waist" size="w-8" />
        <LootIcon type="foot" size="w-8" />
        <LootIcon type="hand" size="w-8" />
        <LootIcon type="neck" size="w-8" />
        <LootIcon type="ring" size="w-8" />
      </div>

      <p className="sm:text-xl sm:text-lg">
        The items are ranked from Tier 1 (strongest) to Tier 5 (weakest).
      </p>

      <p className="sm:text-lg">
        The price of the items in the market is based on the tier, with tier 1 items costing the most and tier 5 costing the least. Your Adventurer's Charisma provides a discount on items and potions.
      </p>
      <p className="sm:text-lg">
        Jewlery items provide special boosts and increase your adventurer's luck which increases the chance of critical hits.
      </p>
    </div>
  );
};
