import { useState, useEffect } from "react";
import { Button } from "../buttons/Button";
import {
  ArrowTargetIcon,
  CatIcon,
  HeartVitalityIcon,
  LightbulbIcon,
  ScrollIcon,
  CoinCharismaIcon,
} from "../icons/Icons";

interface FinalTutorialProps {
  onFinal: (value: boolean) => void;
}

const UpgradeContent = () => {
  return (
    <>
      <h1>You leveled up!</h1>
      <p className="text-sm sm:text-lg">
        Well done oh noble one! You have defeated your first beast and have
        leveled up to level 2. Here is the final tutorial to get you to grips
        with all the other features in Loot Survivor.
      </p>
      <h2 className="text-xl sm:text-2xl">Upgrade</h2>
      <h3 className="text-xl sm:text-2xl">Marketplace</h3>
      <p className="text-sm sm:text-lg">
        Every upgrade the adventurer will have a choice to purchase one item
        from the market. They will pay a price of gold related to the tier of
        the item (the higher the tier the more expensive the item). Item prices
        will increase every level, but charisma will discount the item
        accordingly!
      </p>
      <h3 className="text-xl sm:text-2xl">Stat Points</h3>
      <p className="text-sm sm:text-lg">
        The adventurer can choose to upgrade 6 different stats.
      </p>
      <ul className="text-sm sm:text-lg">
        <li>
          <ArrowTargetIcon /> Strength: Increase attack power
        </li>
        <li>
          <CatIcon /> Dexterity: Increase chance of fleeing from beasts
        </li>
        <li>
          <HeartVitalityIcon /> Vitality: Increase health
        </li>
        <li>
          <LightbulbIcon /> Intelligence: Increase chance of avoiding obstacles
        </li>
        <li>
          <ScrollIcon /> Wisdom: Increases chnce of avoiding beast ambushes
        </li>
        <li>
          <CoinCharismaIcon /> Charisma: Reduces item prices
        </li>
      </ul>
    </>
  );
};

const InventoryContent = () => {
  return (
    <>
      <h1 className="mt-0">Inventory</h1>
      <h2 className="text-xl sm:text-2xl">Create</h2>
      <p className="text-sm sm:text-lg">
        Adventurers are the gate to playing Loot Survivor. You must create one
        with a unique name, realm id, and choose a starting weapon. This will
        follow you through your game journey until you die.
      </p>
    </>
  );
};

const MarketContent = () => {
  return (
    <>
      <h1 className="mt-0">Market</h1>
      <h2 className="text-xl sm:text-2xl">Create</h2>
      <p className="text-sm sm:text-lg">
        Adventurers are the gate to playing Loot Survivor. You must create one
        with a unique name, realm id, and choose a starting weapon. This will
        follow you through your game journey until you die.
      </p>
    </>
  );
};

const LeaderboardContent = () => {
  return (
    <>
      <h1 className="mt-0">Leaderboard</h1>
      <h2 className="text-xl sm:text-2xl">High Score Rewards</h2>
      <p className="text-sm sm:text-lg">
        Adventurers are the gate to playing Loot Survivor. You must create one
        with a unique name, realm id, and choose a starting weapon. This will
        follow you through your game journey until you die.
      </p>
    </>
  );
};

const EncountersContent = () => {
  return (
    <>
      <h1 className="mt-0">Encounters</h1>
      <h2 className="text-xl sm:text-2xl">High Score Rewards</h2>
      <p className="text-sm sm:text-lg">
        Adventurers are the gate to playing Loot Survivor. You must create one
        with a unique name, realm id, and choose a starting weapon. This will
        follow you through your game journey until you die.
      </p>
    </>
  );
};

export const FinalTutorial = ({ onFinal }: FinalTutorialProps) => {
  const [index, setIndex] = useState(0);

  useEffect(() => {
    if (index == 4) {
      onFinal(true);
    } else {
      onFinal(false);
    }
  }, []);
  return (
    <div className="flex flex-col">
      {index == 0 && <UpgradeContent />}
      {index == 1 && <InventoryContent />}
      {index == 2 && <MarketContent />}
      {index == 3 && <LeaderboardContent />}
      {index == 4 && <EncountersContent />}
      <div className="flex flex-row gap-5">
        <Button onClick={() => setIndex(index + 1)} disabled={index == 0}>
          Previous
        </Button>
        <Button onClick={() => setIndex(index + 1)} disabled={index == 2}>
          Next
        </Button>
      </div>
    </div>
  );
};
