export const UpgradeTutorial = () => {
  return (
    <div className="flex flex-col uppercase items-center text-center h-full">
      <h3 className="mt-0">Adventurer Upgrades</h3>
      <p className="sm:text-lg">
        Each time an Adventurer reaches a new level, they get the option to ugprade stats and purchase items and health potions.
      </p>
      <div className="flex flex-col gap-2">
        <div className="flex flex-col">
          <p className="text-lg sm:text-2xl">Stats Upgrades</p>
          <p className="sm:text-lg">
            Adventurer&apos;s receive one stat upgrade each time they level up.
          </p>
        </div>
        <div className="flex flex-col">
          <p className="text-lg sm:text-2xl">Health Potions</p>
          <p className="text-sm sm:text-lg">
            Health potions provide +10hp. The base cost of potions is equal to the adventurer&apos;s level. Charisma provides a +2 gold discount on potions.
          </p>
        </div>
        <div className="flex flex-col">
          <p className="text-lg sm:text-2xl">Item Upgrades</p>
          <p className="sm:text-lg">
            Adventurer&apos;s will have the option to purchase new items each level up. The items in the market are random for each level up, with the inventory size based on the number of stat points available.
          </p>
        </div>
      </div>
    </div>
  );
};
