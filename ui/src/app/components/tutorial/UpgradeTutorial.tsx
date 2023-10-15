export const UpgradeTutorial = () => {
  return (
    <div className="flex flex-col uppercase items-center text-center h-full">
      <h3 className="mt-0">Adventurer Upgrades</h3>
      <p className="sm:text-lg">
        Each time an Adventurer reaches a new level, they get the option to ugprade stats and purchase items
      </p>
      <div className="flex flex-col gap-2">
        <div className="flex flex-col">
          <p className="text-lg sm:text-2xl">Stats Upgrades</p>
          <p className="sm:text-lg">
            Adventurer's receive one stat upgrade for each level.
          </p>
        </div>
        <div className="flex flex-col">
          <p className="text-lg sm:text-2xl">Health Potions</p>
          <p className="text-sm sm:text-lg">
            Health potions provide +10hp. The base cost of potions is equal to the adventurer's level. Charisma provides a +2 gold discount on potions.
          </p>
        </div>
        <div className="flex flex-col">
          <p className="text-lg sm:text-2xl">Item Upgrades</p>
          <p className="sm:text-lg">
            Adventurer's will have the option to purchase item upgrades each level up. The items in the market are random for each level up, with the number of items in the market equal to 21 times the number of stat points available. In the case where you receive multiple stat upgrades, such as during a double level up, or from getting items to greatness 20, the size of the market will be larger.
          </p>
        </div>
      </div>
    </div>
  );
};
