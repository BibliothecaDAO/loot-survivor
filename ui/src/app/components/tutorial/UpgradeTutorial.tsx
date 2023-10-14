export const UpgradeTutorial = () => {
  return (
    <div className="flex flex-col uppercase items-center text-center h-full">
      <h3 className="mt-0">Upgrades</h3>
      <p className="sm:text-lg">
        Whenever your adventurer levels up they will be able to upgrade and
        boost their power!
      </p>
      <div className="flex flex-col gap-2">
        <div className="flex flex-col">
          <p className="text-lg sm:text-2xl">Upgrade Stats</p>
          <p className="sm:text-lg">
            Adventurer can choose to upgrade 6 different stats.
          </p>
        </div>
        <div className="flex flex-col">
          <p className="text-lg sm:text-2xl">Health Potions</p>
          <p className="text-sm sm:text-lg">
            Health potions give 10hp. Potion cost will rise as your journey
            continues.
          </p>
        </div>
        <div className="flex flex-col">
          <p className="text-lg sm:text-2xl">Loot Fountain</p>
          <p className="sm:text-lg">
            20 Loot Items will be available for each level.
          </p>
        </div>
      </div>
    </div>
  );
};
