export const ExploreTutorial = () => {
  return (
    <div className="flex flex-col gap-5 uppercase items-center text-center h-full">
      <h3 className="mt-0">Exploring</h3>
      <p className="text-sm sm:text-lg mb-2">
        Exploring will yield one of three outcomes:
      </p>
      <ul className="text-sm sm:text-lg">
        <li>
          Beasts - There are 75 types of beasts, each with a fixed elemental type and tier. The level and health of the beasts will vary and scale based on the adventurer's level. When encountering a beast, it will attempt to ambush and attack before you have a chance to react. Your chance change of avoiding this ambush is based on your Adventurer's Wisdom. Defeating provides gold and xp for your adventurer and items, with stronger beasts yielding more substantial gold and xp.
        </li>
        <li>
          Obstacles - The game features 75 unique obstacles, each with a fixed elemental type and tier. The level of the Obstacles will vary and scale based on the adventurer's level. Adventurer's will either dodge an obstacle or suffer damage with the chance of dodging it based on the Adventurer's Intelligence.
        </li>
        <li>Gold - A random amount of gold will be added to your balance</li>
        <li>Health Potions - Instant injection of a random amount</li>
      </ul>
    </div>
  );
};
