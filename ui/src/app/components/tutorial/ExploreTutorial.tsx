export const ExploreTutorial = () => {
  return (
    <div className="flex flex-col gap-5 uppercase items-center text-center h-full">
      <h3 className="mt-0">Exploration</h3>

      <ul className="text-sm sm:text-lg">
        <li>
          Beasts: There are 75 beasts, each with a fixed tier and elemental type. The level and health of the beasts will vary based on the Adventurer&apos;s level. Defeating a beast provides gold and xp.
        </li>
        <li>
          Obstacles: There are 75 obstacles, each with a fixed tier and elemental type. The level of the obstacles will vary based on the adventurer&apos;s level. You either dodge the obstacle or take damage.
        </li>
        <li>
          In addition to Beasts and Obstacles, you can find Gold and Health during your explorations.
        </li>
      </ul>
    </div>
  );
};
