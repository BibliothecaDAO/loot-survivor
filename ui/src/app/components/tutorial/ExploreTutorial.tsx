export const ExploreTutorial = () => {
  return (
    <div className="flex flex-col gap-5 uppercase items-center text-center h-full">
      <h3 className="mt-0">Exploring</h3>

      <p className="text-sm sm:text-lg mb-2">
        Exploring will result in one of three outcomes:
      </p>

      <ul className="text-sm sm:text-lg">
        <li>
          A Beast Encounter: There are 75 distinct beasts, each with a fixed tier and elemental type. The level and health of the beasts will vary based on the Adventurer&apos;s level. Defeating a beast provides gold and xp for your adventurer and equipped items, the stronger the beast, the larger the reward.
        </li>

        <li>
          An Obstacle Encounter: There are 75 unique obstacles, each with a fixed tier and elemental. The level of the Obstacle will vary based on the adventurer&apos;s level. Adventurer&apos;s will either dodge an obstacle or suffer damage with the chance of dodging it based on the Adventurer&apos;s Intelligence.
        </li>

        <li>
          Discovering Gold or Health: The amount of gold and health discovered will vary based on your adventurer&apos;s level.
        </li>
      </ul>
    </div>
  );
};
