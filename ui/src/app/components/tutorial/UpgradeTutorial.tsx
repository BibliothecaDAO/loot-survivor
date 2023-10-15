export const UpgradeTutorial = () => {
  return (
    <div className="flex flex-col uppercase items-center text-center h-full">
      <h3 className="mt-0">Adventurer Upgrades</h3>
      <p className="sm:text-lg">
        At the start of each level, you get the option to ugprade stats and purchase items
      </p>
      <div className="flex flex-col gap-2">
        <div className="flex flex-col">
          <p className="text-lg sm:text-2xl">Stats</p>
          <p className="sm:text-lg">
            Adventurer&apos;s receive one stat upgrade each time they level up or get an item to greatness 20.
          </p>
        </div>
        <div className="flex flex-col">
          <p className="text-lg sm:text-2xl">Health</p>
          <p className="text-sm sm:text-lg">
            Use potions to replenish your health. The cost of potions increases each level, invest in Charisma to keep the cost down.
          </p>
        </div>
        <div className="flex flex-col">
          <p className="text-lg sm:text-2xl">Items</p>
          <p className="sm:text-lg">
            Adventurer&apos;s have access to a random selection of items each level. Similar to potions, Charisma provides a discount on items.
          </p>
        </div>
      </div>
    </div>
  );
};
