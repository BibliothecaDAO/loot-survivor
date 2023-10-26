import LootIcon from "../icons/LootIcon";

export const ItemsTutorial = () => {
  return (
    <div className="flex flex-col gap-5 uppercase items-center text-center h-full">
      <h3 className="mt-0">Items</h3>

      <p className="sm:text-lg">
        Loot Survivor uses the 101 Loot items
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
        Items are ranked from Tier 1 (strongest) to Tier 5 (weakest)
      </p>
      <p className="sm:text-xl sm:text-lg">
        There are three types of weapons: Blades, Bludgeons, and Magical
      </p>
      <p className="sm:text-xl sm:text-lg">
        There are three types of armor: Hide, Metal, and Cloth
      </p>
    </div>
  );
};
