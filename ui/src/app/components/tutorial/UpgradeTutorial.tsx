export const UpgradeTutorial = () => {
  return (
    <div className="flex flex-col gap-5 uppercase items-center text-center h-full">
      <h3 className="mt-0">Leveling Up</h3>
      <p className="sm:text-lg">
        Each time you level up your adventurer, you get a stat upgrade and
        access to new items.
      </p>
      <div className="flex flex-col gap-2">
        <div className="flex flex-col">
          <p className="text-lg sm:text-2xl">Potions</p>
          <p className="text-sm sm:text-lg">
            Use potions to replenish your health. The cost of potions increases
            each level, invest in Charisma to keep the cost down.
          </p>
        </div>
        <div className="flex flex-col">
          <p className="text-lg sm:text-2xl">Items</p>
          <p className="sm:text-lg">
            Each time you level up you get access to a random selection of
            items. Price of the items is based on the items tier. Similar to
            potions, Charisma provides a discount on items.
          </p>
        </div>
      </div>
    </div>
  );
};
