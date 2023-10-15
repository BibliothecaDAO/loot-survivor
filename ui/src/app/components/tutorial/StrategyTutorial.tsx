export const StrategyTutorial = () => {
  return (
    <div className="flex flex-col gap-5 uppercase items-center text-center h-full">
      <h3 className="mt-0">Basic Strategy</h3>
      <p className="sm:text-lg">
        If you take damage in a location without any armor, the damage will be substantial. Consider getting a full set of armor early in the game, even if that means using lower tier armor.
      </p>
      <p className="sm:text-lg">
        Having multiple sets of armor with different elemental types allows you to maintain maximum elemental protection when battling beasts. Switching items during battle will result in the beast counter attacking it&apos;s best to minimize in-battle equipment changes.
      </p>
      <p className="sm:text-lg">
        Dexterity, Intelligence, and Wisdom help you avoid taking damage. The chance of fleeing a beast is governed by (dexterity / adventurer_level). If you have 1 dexterity and you are on level 10, your chance of fleeing a beast is 1/10. The same applies for Intelligence when dodging obstacles and Wisdom when avoiding beast ambushes.
      </p>
      <p className="sm:text-lg">
        Adventurer&apos;s will receive a significant boost to their stats when their items reach greatness 15. Use this time wisely to prepare for the late-game where beasts will grow exponentially more powerful.
      </p>
    </div>
  );
};
