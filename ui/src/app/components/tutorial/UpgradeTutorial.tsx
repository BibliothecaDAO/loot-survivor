export const UpgradeTutorial = () => {
  return (
    <div className="flex flex-col uppercase items-center text-center h-full">
      <h3 className="mt-0">Adventurer Upgrades</h3>
      <h3 className="mt-0">Adventurer Upgrades</h3>
      <p className="sm:text-lg">
        Each new level, you get the option to ugprade stats and purchase items
      </p>
      <div className="flex flex-col gap-2">
        <div className="flex flex-col">
          <p className="text-lg sm:text-2xl">Stats Upgrades</p>
          <p className="text-lg sm:text-2xl">Stats Upgrades</p>
          <p className="sm:text-lg">
            Adventurer&apos;s receive one stat upgrade each time they level up or get an item to greatness 20.
          </p>
        </div>
        <div className="flex flex-col">
          <p className="text-lg sm:text-2xl">Health Potions</p>
          <p className="text-sm sm:text-lg">
            Use potions to replenish your health after each level. The cost of potions increases each level, use Charisma to keep the cost low.
          </p>
        </div>
        <div className="flex flex-col">
          <p className="text-lg sm:text-2xl">Item Upgrades</p>
          <p className="text-lg sm:text-2xl">Item Upgrades</p>
          <p className="sm:text-lg">
            Adventurer&apos;s have access to a random selection of items each level. The size of the market is based on the number of stat upgrades available, with each one providing 21 items.
          </p>
        </div>
      </div>
    </div>
  );
};
