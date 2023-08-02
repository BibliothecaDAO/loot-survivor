import { ReactElement, use, useEffect, useState, useRef } from "react";
import QuantityButtons from "../buttons/QuantityButtons";
import { Button } from "../buttons/Button";
import useAdventurerStore from "@/app/hooks/useAdventurerStore";
import { getKeyFromValue } from "@/app/lib/utils";
import { GameData } from "../GameData";
import useTransactionCartStore from "@/app/hooks/useTransactionCartStore";

interface StatAttributeProps {
  name: string;
  icon: ReactElement;
  description: string;
  buttonText: string;
  amount: number;
  setAmount: (value: any) => void;
  upgrades: string[];
  setUpgrades: (values: string[]) => void;
  upgradeHandler: (value: any[]) => void;
}

export const StatAttribute = ({
  name,
  icon,
  description,
  buttonText,
  amount,
  setAmount,
  upgrades,
  setUpgrades,
  upgradeHandler,
}: StatAttributeProps) => {
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const gameData = new GameData();
  const [buttonClicked, setButtonClicked] = useState(false);
  const prevAmountRef = useRef<number | undefined>(0);
  const calls = useTransactionCartStore((state) => state.calls);
  const removeEntrypointFromCalls = useTransactionCartStore(
    (state) => state.removeEntrypointFromCalls
  );
  const newUpgradeTotal = (adventurer?.statUpgrades ?? 0) - upgrades.length;

  useEffect(() => {
    if (buttonClicked) {
      if (prevAmountRef.current !== undefined) {
        const prevAmount = prevAmountRef.current;
        if (amount > prevAmount) {
          const newupgrades = [
            ...upgrades,
            getKeyFromValue(gameData.STATS, name) ?? "",
          ];
          setUpgrades(newupgrades);
          upgradeHandler((upgrades = newupgrades));
        } else if (amount <= prevAmount) {
          const newupgrades = upgrades.filter(
            (i) => i !== getKeyFromValue(gameData.STATS, name) ?? ""
          );
          setUpgrades(newupgrades);
          upgradeHandler((upgrades = newupgrades));
          console.log(newupgrades);
          if (newupgrades.length === 0) {
            removeEntrypointFromCalls("buy_items_and_upgrade_stats");
          }
        }
        setButtonClicked(false);
        // after useEffect has run, update the ref with the new value
      }
      prevAmountRef.current = amount;
    }
  }, [amount, buttonClicked]);

  return (
    <div className="flex flex-col gap-1 sm:gap-3 items-center">
      <span className="hidden sm:block w-10 h-10">{icon}</span>
      <p className="sm:text-[28px] text-center h-2/3">{description}</p>
      <span className="flex flex-row items-center">
        <QuantityButtons
          amount={amount}
          min={0}
          max={newUpgradeTotal}
          setAmount={(value) => {
            setAmount((prev: any) => ({ ...prev, [name]: value }));
            setButtonClicked(true);
          }}
        />
      </span>
    </div>
  );
};
