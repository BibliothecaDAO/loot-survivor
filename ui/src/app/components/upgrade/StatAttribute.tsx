import { ReactElement, use, useState } from "react";
import QuantityButtons from "../buttons/QuantityButtons";
import { Button } from "../buttons/Button";
import useAdventurerStore from "@/app/hooks/useAdventurerStore";
import { getKeyFromValue } from "@/app/lib/utils";
import { GameData } from "../GameData";

interface StatAttributeProps {
  name: string;
  icon: ReactElement;
  description: string;
  buttonText: string;
  upgrades: any[];
  setUpgrades: (values: any[]) => void;
}

export const StatAttribute = ({
  name,
  icon,
  description,
  buttonText,
  upgrades,
  setUpgrades,
}: StatAttributeProps) => {
  const [amount, setAmount] = useState(0);
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const gameData = new GameData();

  return (
    <div className="flex flex-col gap-1 sm:gap-3 items-center">
      <span className="hidden sm:block w-10 h-10">{icon}</span>
      <p className="sm:text-[28px] text-center h-2/3">{description}</p>
      <span className="flex flex-row items-center">
        <QuantityButtons
          amount={amount}
          min={0}
          max={adventurer?.statUpgrades ?? 0}
          setAmount={setAmount}
        />
        <Button
          onClick={() =>
            setUpgrades([
              ...upgrades,
              getKeyFromValue(gameData.STATS, name ?? ""),
            ])
          }
          disabled={amount === 0}
        >
          {buttonText}
        </Button>
      </span>
    </div>
  );
};
