export const ActionsTutorial = () => {
  return (
    <div className="flex flex-col gap-2">
      <h1 className="mt-0">Actions</h1>
      <h3 className="text-xl sm:text-2xl">Explore</h3>
      <p className="text-sm sm:text-lg">
        During your exploration, you will encounter a number of things. These
        include:
      </p>
      <ul className="text-sm sm:text-lg">
        <li>
          Beasts - These will lock you in a battle, Fight or Flee to escape!
        </li>
        <li>
          Obstacles - These will damage your health unless they are avoided!
        </li>
        <li>Gold - A random amount of gold will be added to your balance.</li>
        <li>
          Health - A random amount of health will be discovered for your
          adventurer.
        </li>
        <li>
          XP - A random amount of experience will be added to your adventurer.
        </li>
      </ul>
      <h3 className="text-xl">Purchase Health</h3>
      <p className="text-sm sm:text-lg">
        Every move has a consequence and health is a limited resource. You may
        want to purchase this at multiple points throughout the game. But
        beware, the cost will rise as your journey continues.
      </p>
      <h3 className="text-xl sm:text-2xl">Kill Adventurer</h3>
      <p className="text-sm sm:text-lg">
        An adventurer has a limited time to make a move for face the
        consequences. Once 300 blocks have passed (roughly an hour) with no
        activity then the adventurer becomes a target and anyone may kill them.{" "}
      </p>
    </div>
  );
};
