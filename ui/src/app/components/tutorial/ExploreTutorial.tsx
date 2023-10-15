export const ExploreTutorial = () => {
  return (
    <div className="flex flex-col gap-5 uppercase items-center text-center h-full">
      <h3 className="mt-0">Exploring</h3>

      <h3 className="mt-0">Exploring</h3>

      <p className="text-sm sm:text-lg mb-2">
        Exploring will result in one the following outcome:
      </p>


      <ul className="text-sm sm:text-lg">
        <li>
          A Beast encounter: There are 75 beasts, each with a fixed tier and elemental type. The level and health of the beasts will vary based on the Adventurer&apos;s level. Defeating a beast provides gold and xp.
        </li>
        <li>
          An Obstacle encounter: There are 75 obstacles, each with a fixed tier and elemental type. The level of the obstacles will vary based on the adventurer&apos;s level.
        </li>
        <li>
          Discovering Gold or Health.
        </li>
      </ul>
    </div>
  );
};
