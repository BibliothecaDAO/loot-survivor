export const UnlocksTutorial = () => {
  return (
    <div className="flex flex-col gap-2 uppercase items-center text-center h-full">
      <h3 className="mt-0">Item Specials</h3>

      <p className="sm:text-lg">
        As items are used, they increase in &quot;greatness&quot;. Upon reaching greatness level 15, 19, and 20 the items receive special abilities.
      </p>

      <p className="sm:text-lg">
        At greatness 15, items receive a special suffix such as &quot;Of Power&quot;. Sixteen unique special suffixes exist, each providing a distinct stat boost for your adventurer.
      </p>

      <p className="sm:text-lg">
        At greatness 19, items receive two special prefixes such as &quot;Agony Bane&quot;. If your adventurer attacks a beast whose name matches one of your weapon&apos;s prefixes, the attack will receive a damage bonus. Be cautious however because if a beast&apos;s name matches a prefix of the armor it attacks, it will also get a damage bonus.
      </p>

      <p className="sm:text-lg">
        When an item reaches the maximum greatness  of 20, the Adventurer receives a permenant stat boost that can be applied to the stat of their choosing.
      </p>
    </div>
  );
};
