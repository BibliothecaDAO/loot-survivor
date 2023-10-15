export const ExploreTutorial = () => {
  return (
    <div className="flex flex-col gap-5 uppercase items-center text-center h-full">
      <h3 className="mt-0">Explore</h3>
      <p className="text-sm sm:text-lg mb-2">
        During your exploration, you will discovery many things. They include:
      </p>
      <ul className="text-sm sm:text-lg">
        <li>
          Beasts - There are 75 distinct types of beasts, each with a fixed tier and eelemental type
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
