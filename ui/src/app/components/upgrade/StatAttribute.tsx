import { ReactElement, useEffect, useState, useRef } from "react";
import QuantityButtons from "@/app/components/buttons/QuantityButtons";
import useAdventurerStore from "@/app/hooks/useAdventurerStore";
import useTransactionCartStore from "@/app/hooks/useTransactionCartStore";
import useUIStore from "@/app/hooks/useUIStore";
import { UpgradeStats, ZeroUpgrade } from "@/app/types";

interface StatAttributeProps {
  name: string;
  icon: ReactElement;
  description: string;
  upgradeHandler: (
    upgrades?: UpgradeStats,
    potions?: number,
    items?: any[]
  ) => void;
  nonBoostedStat: any;
}

export const StatAttribute = ({
  name,
  icon,
  description,
  upgradeHandler,
  nonBoostedStat,
}: StatAttributeProps) => {
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const prevAmountRef = useRef<{ [key: string]: number }>({ ...ZeroUpgrade });
  const upgrades = useUIStore((state) => state.upgrades);
  const setUpgrades = useUIStore((state) => state.setUpgrades);
  const [buttonClicked, setButtonClicked] = useState(false);
  const removeEntrypointFromCalls = useTransactionCartStore(
    (state) => state.removeEntrypointFromCalls
  );

  const amount = upgrades[name] ?? 0;

  const upgradesTotal = Object.values(upgrades)
    .filter((value) => value !== 0)
    .reduce((accumulator, currentValue) => accumulator + currentValue, 0);

  const newUpgradeTotal =
    amount + ((adventurer?.statUpgrades ?? 0) - upgradesTotal);

  const maxNonBoosted =
    (nonBoostedStat ?? BigInt(0)) + BigInt(amount) >= BigInt(15);

  useEffect(() => {
    if (buttonClicked) {
      if (prevAmountRef.current !== undefined) {
        // Access the previous amount for the specific name
        const prevAmount = prevAmountRef.current[name];
        if (amount > prevAmount) {
          upgradeHandler(upgrades, undefined, undefined);
        } else if (amount <= prevAmount) {
          upgradeHandler(upgrades, undefined, undefined);
          if (
            Object.values(upgrades).filter((value) => value !== 0).length === 0
          ) {
            removeEntrypointFromCalls("upgrade");
          }
        }
        setButtonClicked(false);
        // after useEffect has run, update the ref with the new value
      }
      prevAmountRef.current[name] = amount;
    }
  }, [amount, buttonClicked]);

  return (
    <div className="flex flex-col gap-1 sm:gap-3 items-center">
      <span className="hidden sm:block w-10 h-10">{icon}</span>
      <>
        {maxNonBoosted ? (
          <p className="sm:text-4xl text-center">Base Stat Maxed Out</p>
        ) : (
          <p className="sm:text-[28px] xl:text-2xl text-center h-2/3">
            {description}
          </p>
        )}
        <span className="flex flex-row items-center">
          <QuantityButtons
            amount={amount}
            min={0}
            max={maxNonBoosted ? amount : newUpgradeTotal}
            setAmount={(value) => {
              upgrades[name] = value;
              setUpgrades(upgrades);
              setButtonClicked(true);
            }}
            size="default"
          />
        </span>
      </>
    </div>
  );
};
