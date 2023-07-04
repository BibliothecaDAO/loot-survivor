import { useState, useEffect } from "react";
import { Button } from "../buttons/Button";

interface FinalTutorialProps {
  onFinal: (value: boolean) => void;
}

const UpgradeContent = () => {
  return (
    <>
      <h1>Upgrade</h1>
      <h2>Create</h2>
      <p>
        Adventurers are the gate to playing Loot Survivor. You must create one
        with a unique name, realm id, and choose a starting weapon. This will
        follow you through your game journey until you die.
      </p>
    </>
  );
};

const InventoryContent = () => {
  return (
    <>
      <h1>Inventory</h1>
      <h2>Create</h2>
      <p>
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
      <h1>Market</h1>
      <h2>Create</h2>
      <p>
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
      <h1>Leaderboard</h1>
      <h2>High Score Rewards</h2>
      <p>
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
      <h1>Encounters</h1>
      <h2>High Score Rewards</h2>
      <p>
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
