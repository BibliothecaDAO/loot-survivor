export const BeastTutorial = () => {
  return (
    <div className="flex flex-col">
      <h1 className="mt-0">Beast</h1>
      <h2 className="text-xl sm:text-2xl">Attacking</h2>
      <p className="text-sm sm:text-lg">
        Adventurers are the gate to playing Loot Survivor. You must create one
        with a unique name, realm id, and choose a starting weapon. This will
        follow you through your game journey until you die.
      </p>
      <h2 className="text-xl sm:text-2xl">Fleeing</h2>
      <p className="text-sm sm:text-lg">
        You can choose to flee the beats in circumstances that you know you are
        at risk! Note, fleeing is not guaranteed, and if you don&apos;t flee you
        will be attacked!
      </p>
      <p className="text-sm sm:text-lg">
        The chance of fleeing is calculated through rng. Rank up your dexterity
        to increase the chance in your favour!
      </p>
    </div>
  );
};
