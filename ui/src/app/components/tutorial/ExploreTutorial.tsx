export const ExploreTutorial = () => {
  return (
    <div className="flex flex-col gap-5 uppercase items-center text-center h-full">
      <h3 className="mt-0">Exploration</h3>

      <p className="text-sm sm:text-xl mb-2">
        When you go exploring, you will encounter:
      </p>

      <ul className="text-sm sm:text-xl">
        <li className="mb-5">
          Beasts with a wide range of health and power. Choose your battles
          carefully.
        </li>
        <li className="mb-5">
          Obstacles with the potential to deal fatal damage. Increase your
          chance of dodging obstacles by upgrading intelligence.
        </li>
        <li>Gold and Health</li>
      </ul>
    </div>
  );
};
