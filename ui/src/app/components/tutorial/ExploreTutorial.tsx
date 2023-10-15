export const ExploreTutorial = () => {
  return (
    <div className="flex flex-col gap-5 uppercase items-center text-center h-full">
      <h3 className="mt-0">Exploring</h3>
      <p className="text-sm sm:text-lg mb-2">
        Exploring will yield one of three outcomes:
      </p>
      <ul className="text-sm sm:text-lg">
        <li>
          Beasts: There are 75 beasts, each with a fixed tier and elemental type. The level and health of the beasts will vary based on the adventurer's level.
        </li>
        <li>
          Obstacles - 75 different obstacles that will give damage unless they
          are avoided!
        </li>
        <li>Gold - A random amount of gold will be added to your balance</li>
        <li>Health Potions - Instant injection of a random amount</li>
      </ul>
    </div>
  );
};
