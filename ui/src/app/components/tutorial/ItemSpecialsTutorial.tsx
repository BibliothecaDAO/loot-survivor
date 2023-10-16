export const UnlocksTutorial = () => {
  return (
    <div className="flex flex-col gap-5 uppercase items-center text-center h-full">
      <h3 className="mt-0">Item Specials</h3>

      <p className="sm:text-lg">
        Loot items receive special abilities when they reach greatness 15, 19,
        and 20.
      </p>
      <ul>
        <li className="sm:text-lg mb-2">
          G15: They receive a Special suffix such as &quot;Of Power&quot;. There
          are sixteen suffixes, each providing a unique set of stat boosts.
        </li>

        <li className="sm:text-lg mb-2">
          G19: They receive a two part name prefix such as &quot;Agony
          Bane&quot; which if it matches a beast, provides a powerful damage
          boost.
        </li>

        <li className="sm:text-lg">
          G20: They receive a +1 modifier which grants the player a stat upgrade
          for their Adventurer.
        </li>
      </ul>
    </div>
  );
};
