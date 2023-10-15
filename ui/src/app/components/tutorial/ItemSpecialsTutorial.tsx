export const UnlocksTutorial = () => {
  return (
    <div className="flex flex-col gap-2 uppercase items-center text-center h-full">
      <h3 className="mt-0">Item Specials</h3>

      <p className="sm:text-lg">
        The items are used, they grow in "greatness". Upon reaching a greatness level of 15, 19, and 20 the items will receive special abilities.
      </p>

      <p className="sm:text-lg">
        When an item reaches greatness level 15, it will receive a special suffix, for example "Of Power". Sixteen unique special suffixes exist, each providing a distinct stat boosts to your adventurer when the item is equipped. For instance, equipping a "Grimoire of Power" will grant your adventurer +3 Strength, whereas an "of Perfection" item will provide +1 Strength, +1 Dexterity, and +1 Vitality.
      </p>

      <p className="sm:text-lg">
        When an item reaches greatness level 19, it is awarded two special prefixes for example a "Katana of Skill" will become a "Demon Grasp Katana of Skill". If your adventurer attacks a beast whose name matches one of the weapon's prefixes, the attack will receive a damage bonus. For example if you use a "Demon Grasp Katana of Skill" against a "Shadow Grasp Warlock", you will receive a damage boost. Be cautious however because if a beast’s name matches a prefix on one of your armor items and it attacks that location, the beast will also get a damage boost.
      </p>

      <p className="sm:text-lg">
        When an item reaches it's maximum greatness level of 20, the Adventurer receives a permenant stat boost as a reward that they can apply to the stat of their choosing. Leveling as many items as possible to greatness 20 to earn these stat upgrades is pivotal to keeping pace with the ever increasing power of the beasts and obstacles.
      </p>
      );
};
