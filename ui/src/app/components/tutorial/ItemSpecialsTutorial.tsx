export const UnlocksTutorial = () => {
  return (
    <div className="flex flex-col gap-2 uppercase items-center text-center h-full">
      <h3 className="mt-0">Item Specials</h3>

      <p className="sm:text-lg">
        Loot items receive special abilities when they reach greatness 15, 19, and 20.
      </p>

      <p className="sm:text-lg">
        At G15, they receive a Special suffix such as &quot;Of Power&quot;. There are sixteen suffixes, each providing a unique set of stat boosts.
      </p>

      <p className="sm:text-lg">
        At G19, they receive a two part name prefix such as &quot;Agony Bane&quot; which if it matches a beast, provides a powerful damage boost.
      </p>

      <p className="sm:text-lg">
        At G20, they receive a +1 modifier which grants the player a stat upgrade for their Adventurer.
      </p>
    </div>
  );
};
