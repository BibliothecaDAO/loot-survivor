export const BeastTutorial = () => {
  return (
    <div className="flex flex-col uppercase">
      <h1 className="mt-0">Beast</h1>
      <p className="text-sm sm:text-lg">
        Oh dear! You&apos;ve stumbled upon a beast! A potential ambush lurks,
        with only your Wisdom providing a chance at evasion! Equip your chosen
        weapon and armor for both offense and defense against this formidable
        adversary. Beware, swapping gear mid-battle will invite an immediate
        counterattack!
      </p>
      <h2 className="text-xl sm:text-2xl">Attacking</h2>
      <p className="text-sm sm:text-lg">
        Bold traveler, engage the creature and unleash your power! This beast
        can target any of your 5 armor sections. Overcome it and a reward awaits
        you!
      </p>
      <h2 className="text-xl sm:text-2xl">Fleeing</h2>
      <p className="text-sm sm:text-lg">
        Find yourself in overwhelming odds? Retreat might be your best bet. But
        tread carefully, escape is not always guaranteed, and failure to flee
        will result in an attack! Enhance your Dexterity to tip the odds of
        successful flight in your favor!
      </p>
    </div>
  );
};
