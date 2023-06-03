import React from "react";
import { Button } from "./Button";

export const Guide = () => {
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

  return (
    <div className="overflow-y-auto h-screen p-2 table-scroll">
      <div className="flex justify-end mb-4">
        <a
          href="https://discord.gg/bibliothecadao"
          target="_blank"
          rel="noopener noreferrer"
        >
          <Button className="py-2 px-4">Join the Discord</Button>
        </a>
      </div>
      <h1 className="mb-4">Loot Survivor: A Saga of Bravery and Fortitude</h1>
      <p className="">
        Your journey in Loot Survivor will take you through perilous trials, as
        part of the renowned Adventurers series. This tale unfolds in the Loot
        realm, a world where brave heroes strive to defeat monstrous creatures,
        surmount formidable challenges, hone their skills, and gather valuable
        loot to make progress in their grand adventure.
      </p>

      <h3 className="mb-2">Embarking on Your Quest</h3>
      <p>
        Select your adventurer&apos;s persona. Remember, there is no limit to
        the number of adventurers you can control!
      </p>

      <h3 className="mb-2">The Trials</h3>
      <p>
        During your exploration, you may stumble upon a Beast, an Obstacle, a
        valuable Item such as Gold, Health Potion & Loot, or perhaps you will
        gain XP.
      </p>

      <h3 className="mb-2">Beasts</h3>
      <p>
        If you encounter a beast, ready yourself for a potential onslaught!
        Assess the beast&apos;s armor, its method and area of attack. Prepare
        your offense, or choose to flee if you are not prepared for battle!
        Beware, adventurer this is not for feint hearted!
      </p>
      <h3 className="mb-2">Weapon and Armor</h3>
      <p className="mb-2">
        There are three kinds of weapons: Blade, Bludgeon, Magic and armor
        materials: Cloth, Hide and Metal. Tier 1 is the highest.
      </p>
      <h3 className="mb-2">The Armory Ranking</h3>
      <div className="overflow-x-auto">
        <table className="w-full">
          <thead>
            <tr>
              <th className="py-2 px-3 text-center border border-terminal-green">
                Weapon Class
              </th>
              <th className="py-2 px-3 text-center border border-terminal-green">
                Weapon Moniker
              </th>
              <th className="py-2 px-3 text-center border border-terminal-green">
                Weapon Prestige
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
      <h4>Armor materials: Cloth, Hide, Metal</h4>
      <div className="overflow-x-auto">
        <p>Efficacy Chart of Weapon and Armor Interactions</p>
        <table className="w-full uppercase whitespace-nowrap border border-terminal-green">
          <thead>
            <tr className="text-l tracking-wide text-left border-b border-terminal-green">
              <th className="px-4 py-3 border border-terminal-green">Weapon</th>
              <th className="px-4 py-3 border border-terminal-green">Metal</th>
              <th className="px-4 py-3 border border-terminal-green">Hide</th>
              <th className="px-4 py-3 border border-terminal-green">Cloth</th>
            </tr>
          </thead>
          <tbody className="border-terminal-green">
            {efficacyData.map((row, i) => (
              <tr key={i} className="text-terminal-green">
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
      <h3 className="mb-2">The Lore of Items</h3>
      <p>
        Items have prefixes and suffixes assigned to them when they reach
        certain Greatness. The suffix is randomly generated from 1 of 16 orders.
        Once an item reaches greatness 15 it receives a name suffix which grants
        the adventurer +3 stat boost while it is equipped. Items are also
        granted a coveted +1 modifier when they hit 20 Greatness and an
        additional +1 stat boost. If you meet a beast with the same suffix and
        prefix of your item, special hits can be achieved!
      </p>

      <h3 className="mb-2">Market</h3>
      <p>
        You can purchase items in the Marketplace auction and equip them in each
        item slot. Available slots include: Weapon, Head, Chest, Hands, Waist,
        Feet, Neck and Ring. Every 3 hours new items will be available. Once you
        bid on items, a 15 minute window will start where you can be outbid,
        after 15 minutes the auction closes and the highest bidder can claim
        their items. Claimed items appear in your Inventory. Expect to pay more
        for higher tier items, even when not bidding against other adventurers.
      </p>

      <h3 className="mb-2">Swap Items</h3>
      <p>
        You can switch weapons and armor to aid in your adventure. However, if
        you make a switch during a battle, you will be open to an attack!
      </p>

      <h3 className="mb-2">Upgrading Stats</h3>
      <p>
        Each level up grants adventurers a +1 stat boost to help them survive
        their explorations. While you cannot directly upgrade Luck, you can
        increase it by equipping jewelry items.
      </p>
      <ul className="text-l ml-1">
        <li> Strength: Boosts attack damage by 10%.</li>
        <li> Vitality: Increases health by +20hp and max health.</li>
        <li> Dexterity: Improves chances of successfully fleeing.</li>
        <li> Wisdom: Helps evade Beast ambushes.</li>
        <li> Intelligence: Aids in avoiding Obstacles.</li>
        <li>
          Luck: Raises chances of critical damage and cannot be upgraded
          directly.
        </li>
      </ul>

      <h3 className="mb-2">Health Potions</h3>
      <p>
        Purchase health potions to rejuvenate your weary adventurer. Health
        potions cannot be bought if you are in battle or if your character has
        died. Maximum health is fixed at 100HP unless you upgrade your Vitality
        which adds +20 to your maximum health. The cost of Health Potions
        increases with your adventurer level and grants 10HP.
      </p>
    </div>
  );
};

export default Guide;
