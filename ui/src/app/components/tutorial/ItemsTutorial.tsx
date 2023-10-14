import LootIcon from "../icons/LootIcon";

export const ItemsTutorial = () => {
  return (
    <div className="flex flex-col gap-5 uppercase items-center text-center h-full">
      <h3 className="mt-0">Loot Items</h3>

      <p className="sm:text-lg">
        There are 101 of the original Loot Items to choose when upgrading!
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
        They are ranked from Tier 1 (strongest) - 5 (weakest).
      </p>

      <p className="sm:text-lg">
        Be wise when choosing the strength of your gear, the higher tier items
        are costly! Charisma will reduce the amount you pay during upgrading!
      </p>
    </div>
  );
};
