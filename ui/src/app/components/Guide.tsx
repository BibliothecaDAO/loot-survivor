import React from "react";
import { useAccount } from "@starknet-react/core";
import { Button } from "./Button";

export interface GuideProps {
  isActive: boolean;
  onEscape: () => void;
  adventurers: any[];
}

export const Guide = ({ isActive, onEscape, adventurers }: GuideProps) => {
  const { account } = useAccount();

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
          <Button className="py-2 px-4">
            Join the Discord
            {/* </a> */}
          </Button>
        </a>
      </div>
      <h1 className="mb-4">Game Guide</h1>
      <p className="">
        Loot Survivor is a part of the Adventurers series and builds upon the
        Loot ecosystem to create an environment where adventurers must battle
        beasts, overcome terrifying obstacles, boost their stats, and acquire
        items to advance in the game.
      </p>

      <h2 className="mb-2">Game Play</h2>
      <p>Choose your adventurer identity. You can have multiple adventurers!</p>

      <h3 className="mb-2">Encounters</h3>
      <p>
        On exploration, you can come across the following: Beast, Obstacle, Item
        (Gold, Health Potion & Loot) or XP.
      </p>

      <h3 className="mb-2">Beasts</h3>
      <p>
        Find a beast and face a potential ambush! Check armor, attack type and
        location. Prepare for attack or choose to flee if you are weak! BE
        WARNED!
      </p>
      <h3 className="mb-2">Weapon and Armor</h3>
      <p className="mb-2">
        There are three categories of weapons and armor materials. Items have
        prefixes and suffixes assigned to them when they reach certain
        Greatness. The suffix ...e.g of power and prefix.....e.g agony bane is
        assigned when an item reaches 15 greatness and adventurer gets a +3 stat
        boost of what is associated with the suffix e.g of dectection = 3+ WIS.
        The suffix is randomly generated from 1 of 16 orders. Items are also
        granted a coveted +1 modifier when they hit 20 greatness...e.g agony
        bane club of power + 1. If you meet a beast with the same suffix and
        prefix of your item, special hits can be achieved!
      </p>
      <p className="text-xl">Weapons: Blade, Bludgeon, Magic</p>
      <h3 className="mb-2">Weapon Item Rankings</h3>
      <div className="overflow-x-auto">
        <table className="w-full">
          <thead>
            <tr>
              <th className="py-2 px-3 text-center border border-terminal-green">
                Weapon Type
              </th>
              <th className="py-2 px-3 text-center border border-terminal-green">
                Item Name
              </th>
              <th className="py-2 px-3 text-center border border-terminal-green">
                Rank
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
        <p>Weapon vs. Armor Efficacy Chart</p>
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

      <h3 className="mb-2">Market Items</h3>
      <p>
        Items can be purchased in the Marketplace auction and can be equipped in
        each item slot. Available slots include: Weapon, Head, Chest, Hands,
        Waist, Feet, Neck and Ring. Every 3 hours new items will be available.
        Once you bid on items, a 15 minute window will start where you can be
        outbid, after 15 minutes the auction closes and the highest bidder can
        claim their items.
      </p>

      <h3 className="mb-2">Swap Item</h3>
      <p>
        Change weapons and armor to assist you in battle and defend against
        obstacles but you will face an attack!
      </p>

      <h3 className="mb-2">Upgrade Stats</h3>
      <p>
        Each level up grants adventurers 1+ upgrade to help them survive their
        explorations. Although Luck cannot be upgraded directly, it can be
        increased by equipping jewelry items
      </p>
      <ul className="text-l">
        <li>Strength: Boosts attack damage by 10%.</li>
        <li>Vitality: Increases health by +20hp and max health.</li>
        <li>Dexterity: Improves chances of successfully fleeing.</li>
        <li>Wisdom: Helps evade Beast ambushes.</li>
        <li>Intelligence: Aids in avoiding Obstacles.</li>
        <li>
          Luck: Raises chances of critical damage (cannot be upgraded directly).
        </li>
      </ul>

      <h3 className="mb-2">Health Potions</h3>
      <p>
        You cannot buy if you are in battle or if you have died. Max health is
        100HP unless you upgrade vitality that adds +20 to max health. Health
        Potions price will increase based on your adventurers level.
      </p>
    </div>
  );
};

export default Guide;
