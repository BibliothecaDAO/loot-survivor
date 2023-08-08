import React from "react";
import { Button } from "../components/buttons/Button";

/**
 * @container
 * @description Provides the guide screen for the adventurer.
 */
export default function GuideScreen() {
  const efficacyData = [
    { weapon: "Blade", metal: "Weak", hide: "Fair", cloth: "Strong" },
    { weapon: "Bludgeon", metal: "Fair", hide: "Strong", cloth: "Weak" },
    { weapon: "Magic", metal: "Strong", hide: "Weak", cloth: "Fair" },
  ];

  const itemData = [
    { weapon: "Blade", item: "Katana", rank: 1 },
    { weapon: "Blade", item: "Falchion", rank: 2 },
    { weapon: "Blade", item: "Scimitar", rank: 3 },
    { weapon: "Blade", item: "Long Sword", rank: 4 },
    { weapon: "Blade", item: "Short Sword", rank: 5 },
    { weapon: "Bludgeon", item: "Warhammer", rank: 1 },
    { weapon: "Bludgeon", item: "Quarterstaff", rank: 2 },
    { weapon: "Bludgeon", item: "Maul", rank: 3 },
    { weapon: "Bludgeon", item: "Mace", rank: 4 },
    { weapon: "Bludgeon", item: "Club", rank: 5 },
    { weapon: "Magic", item: "Ghost Wand", rank: 2 },
    { weapon: "Magic", item: "Grave Wand", rank: 3 },
    { weapon: "Magic", item: "Bone Wand", rank: 4 },
    { weapon: "Magic", item: "Wand", rank: 5 },
    { weapon: "Magic", item: "Grimoire", rank: 2 },
    { weapon: "Magic", item: "Chronicle", rank: 3 },
    { weapon: "Magic", item: "Tome", rank: 4 },
    { weapon: "Magic", item: "Book", rank: 5 },
  ];

  const suffixData = [
    { suffix: "of Power", attribute: "Strength +3" },
    { suffix: "of Giant", attribute: "Vitality +3" },
    { suffix: "of Titans", attribute: "Strength +2, Charisma +1" },
    { suffix: "of Skill", attribute: "Dexterity +3" },
    {
      suffix: "of Perfection",
      attribute: "Strength +1, Dexterity +1, Vitality +1",
    },
    { suffix: "of Brilliance", attribute: "Intelligence +3" },
    { suffix: "of Enlightenment", attribute: "Wisdom +3" },
    { suffix: "of Protection", attribute: "Vitality +2, Dexterity +1" },
    { suffix: "of Anger", attribute: "Strength +2, Dexterity +1" },
    { suffix: "of Rage", attribute: "Wisdom +1, Strength +1, Charisma +1" },
    {
      suffix: "of Fury",
      attribute: "Vitality +1, Charisma +1, Intelligence +1",
    },
    { suffix: "of Vitriol", attribute: "Intelligence +2, Wisdom +1" },
    { suffix: "of the Fox", attribute: "Dexterity +2, Charisma +1" },
    { suffix: "of Detection", attribute: "Wisdom +2, Dexterity +1" },
    { suffix: "of Reflection", attribute: "Wisdom +2, Intelligence +1" },
    { suffix: "of the Twins", attribute: "Charisma +3" },
  ];

  return (
    <div className="h-[500px] overflow-y-auto sm:h-[650px] p-2 table-scroll text-xs sm:text-base text-center sm:text-left">
      <div className="flex flex-col sm:flex-row justify-between items-center mb-4">
        <h1>Loot Survivor: A Saga of Fortitude and Death</h1>
        <a
          href="https://discord.gg/bibliothecadao"
          target="_blank"
          rel="noopener noreferrer"
        >
          <Button className="py-2 px-4 animate-pulse hidden sm:block">
            Join the Discord
          </Button>
        </a>
      </div>
      <p>
        Your journey in Loot Survivor will take you through perilous trials, as
        part of the renowned Adventurers series. This tale unfolds in the Loot
        realm, a world where brave heroes strive to defeat monstrous creatures,
        surmount formidable challenges, hone their skills, and gather valuable
        loot to make progress in their grand adventure.
      </p>

      <h3 className="mb-2">Embarking on Your Quest</h3>
      <p>
        Select your adventurer&apos;s persona. Remember, there is no limit to
        the number of adventurers you can spawn!
      </p>

      <h3 className="mb-2">The Trials</h3>
      <p>
        During your exploration, you may stumble upon a Beast, an Obstacle, or
        Treasure such as Gold, Health or XP.
      </p>

      <h3 className="mb-2">Beasts</h3>
      <p>
        If you encounter a beast, ready yourself for a potential onslaught!
        Assess the beast&apos;s armor and method of attack. Prepare your
        offense, or choose to flee if you are not prepared for battle!
      </p>
      <h3 className="mb-2">Weapons and Armor</h3>
      <p className="mb-2">
        There are three types of weapons: Blade, Bludgeon, Magic and three types
        of armor materials: Cloth, Hide and Metal. Tier 1 is the highest.
      </p>
      <div className="">
        <h3 className="text-center text-l mb-2">
          Efficacy Chart of Weapon and Armor Interactions
        </h3>
        <table className="w-1/2 m-auto uppercase whitespace-nowrap border border-terminal-green">
          <thead>
            <tr className="text-l tracking-wide text-center border-b border-terminal-green ">
              <th className="px-4 py-3 border border-terminal-green">Weapon</th>
              <th className="px-4 py-3 border border-terminal-green">Metal</th>
              <th className="px-4 py-3 border border-terminal-green">Hide</th>
              <th className="px-4 py-3 border border-terminal-green">Cloth</th>
            </tr>
          </thead>
          <tbody className="border-terminal-green">
            {efficacyData.map((row, i) => (
              <tr key={i} className="text-terminal-green text-center">
                <td className="px-4 py-3 border border-terminal-green">
                  {row.weapon}
                </td>
                <td className="px-4 py-3 border border-terminal-green">
                  {row.metal}
                </td>
                <td className="px-4 py-3 border border-terminal-green">
                  {row.hide}
                </td>
                <td className="px-4 py-3 border border-terminal-green">
                  {row.cloth}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <h3 className="mb-2 text-center">The Armory Ranking</h3>
      <div className="">
        <table className="w-1/2 m-auto uppercase">
          <thead>
            <tr>
              <th className="py-2 px-3 text-center border border-terminal-green">
                Weapon Class
              </th>
              <th className="py-2 px-3 text-center border border-terminal-green">
                Weapon Moniker
              </th>
              <th className="py-2 px-3 text-center border border-terminal-green">
                Weapon Tier
              </th>
            </tr>
          </thead>
          <tbody className="border-terminal-green">
            {itemData.map((row, i) => (
              <tr key={i}>
                <td className="py-2 px-4 text-center border border-terminal-green">
                  {row.weapon}
                </td>
                <td className="py-2 px-4 text-center border border-terminal-green">
                  {row.item}
                </td>
                <td className="py-2 px-4 text-center border border-terminal-green">
                  {row.rank}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <h3 className="mb-2">The Lore of Items</h3>
      <p>
        Items have prefixes and suffixes assigned to them when they reach
        certain Greatness. The suffix is randomly generated from one of the 16
        Orders of Divinity
      </p>
      <p>
        {" "}
        Once an item reaches greatness 15 it achieves a suffix which grants the
        adventurer +3 stat boost while it is equipped. Items are also granted a
        coveted +1 modifier when they reach 20 Greatness and an additional +1
        stat boost to your adventurer. If you meet a beast with the same suffix
        and prefix of your item, special hits can be achieved!
      </p>
      <h4 className="mb-2 text-center">Item Suffixes and Their Attributes</h4>
      <div className="">
        <table className="w-1/2 m-auto uppercase">
          <thead>
            <tr>
              <th className="py-2 px-3 text-center border border-terminal-green">
                Item Suffix
              </th>
              <th className="py-2 px-3 text-center border border-terminal-green">
                Adventurer Attribute
              </th>
            </tr>
          </thead>
          <tbody className="border-terminal-green">
            {suffixData.map((row, i) => (
              <tr key={i}>
                <td className="py-2 px-4 text-center border border-terminal-green">
                  {row.suffix}
                </td>
                <td className="py-2 px-4 text-center border border-terminal-green">
                  {row.attribute}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <h3 className="mb-2">Loot Fountain</h3>
      <p>
        You can trade your gold at the mystical Loot Fountain on each level up,
        after you upgrade the Fountain will be close. Obtain items for each item
        slots: Weapon, Head, Chest, Hands, Waist, Feet, Neck and Ring.
        Adventurers can only carry 19 items in total.
      </p>

      <h3 className="mb-2">Swap Items</h3>
      <p>
        You can switch weapons and armor to aid in your adventure. BE WARNED! If
        you make a switch during a battle, you will be open to an attack! You
        will be hit for each item swap.
      </p>

      <h3 className="mb-2">Upgrading Stats</h3>
      <p className="mb-2">
        Each level up grants adventurers a +1 stat boost to help them survive
        their explorations. While you cannot directly upgrade Luck, you can
        increase it by equipping jewelry items.
      </p>
      <div className="text-xxs sm:text-base">
        <table className="w-1/2 m-auto uppercase text-center whitespace-nowrap border border-terminal-green">
          <tbody>
            <tr className="border border-terminal-green">
              <td
                rowSpan={3}
                className="px-4 py-3 border-r border-terminal-green"
              >
                3D Physical
              </td>
              <td className="px-4 py-3 border-r border-terminal-green">
                Strength
              </td>
              <td>Boosts attack damage by 10%</td>
            </tr>
            <tr className="border border-terminal-green">
              <td className="px-4 py-3 border-r border-terminal-green">
                Vitality
              </td>
              <td>Increases max health by +20hp</td>
            </tr>
            <tr className="py-4 border border-terminal-green">
              <td className="px-4 py-3 border-r border-terminal-green">
                Dexterity
              </td>
              <td>Improves chances of successfully fleeing</td>
            </tr>
            <tr className="py-4 border border-terminal-green">
              <td
                rowSpan={3}
                className="px-4 py-3 border-r border-terminal-green"
              >
                3D Mental
              </td>
              <td className="px-4 py-3 border-r border-terminal-green">
                Intelligence
              </td>
              <td>Aids in avoiding Obstacles</td>
            </tr>
            <tr className="py-4 border border-terminal-green">
              <td className="px-4 py-3 border-r border-terminal-green">
                Wisdom
              </td>
              <td>Helps evade Beast ambushes</td>
            </tr>
            <tr className="py-4 border border-terminal-green">
              <td className="px-4 py-3 border-r border-terminal-green">
                Charisma
              </td>
              <td>Gives 2 Gold Discount on items and health potions</td>
            </tr>
            <tr className="py-4 border border-terminal-green">
              <td
                rowSpan={1}
                className="px-4 py-3 border-r border-terminal-green"
              >
                1D Metaphysical
              </td>
              <td className="px-4 py-3 border-r border-terminal-green">Luck</td>
              <td className="px-4 py-3 border-r border-terminal-green">
                Raises chances of critical damage and cannot be upgraded
                directly
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <h3 className="mb-2">Health Potions</h3>
      <p>
        Purchase health potions to rejuvenate your weary adventurer. Health
        potions cannot be bought if you are in battle or if your character has
        died. Maximum health is fixed at 100HP unless you upgrade Vitality. The
        cost of Health Potions increase with your adventurer level and grants
        10HP.
      </p>
    </div>
  );
}
