import { useState, useEffect, useRef } from "react";
import QuantityButtons from "@/app/components/buttons/QuantityButtons";
import { Button } from "@/app/components/buttons/Button";
import useAdventurerStore from "@/app/hooks/useAdventurerStore";
import { getPotionPrice } from "@/app/lib/utils";
import { UpgradeStats } from "@/app/types";
import { CoinIcon } from "@/app/components/icons/Icons";
import { vitalityIncrease } from "@/app/lib/constants";

interface PurchaseHealthProps {
  upgradeTotalCost: number;
  potionAmount: number;
  setPotionAmount: (value: number) => void;
  totalCharisma: number;
  upgradeHandler: (
    upgrades?: UpgradeStats,
    potions?: number,
    items?: any[]
  ) => void;
  totalVitality: number;
  vitBoostRemoved: number;
}

const PurchaseHealth = ({
  upgradeTotalCost,
  potionAmount,
  setPotionAmount,
  totalCharisma,
  upgradeHandler,
  vitBoostRemoved,
}: PurchaseHealthProps) => {
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const prevAmountRef = useRef<number | undefined>(0);
  const [buttonClicked, setButtonClicked] = useState(false);

  const potionCost = getPotionPrice(adventurer?.level ?? 0, totalCharisma);

  const hasBalance = adventurer?.gold && adventurer?.gold >= upgradeTotalCost;

  const maxHealth = 100 + (adventurer?.vitality ?? 0) * vitalityIncrease;

  const max = Math.min(
    Math.ceil(
      (maxHealth -
        (adventurer?.health ?? 0) -
        vitBoostRemoved * vitalityIncrease) /
        10
    ),
    Math.floor(
      (adventurer?.gold! - (upgradeTotalCost - potionAmount * potionCost)) /
        potionCost
    )
  );

  const fillToMax = () => {
    if (hasBalance) {
      setPotionAmount(max);
      setButtonClicked(true);
    }
  };

  useEffect(() => {
    if (buttonClicked) {
      if (prevAmountRef.current !== undefined) {
        const prevAmount = prevAmountRef.current;
        if (potionAmount > prevAmount) {
          upgradeHandler(undefined, potionAmount, undefined);
        } else if (potionAmount <= prevAmount) {
          upgradeHandler(undefined, potionAmount, undefined);
        }
        setButtonClicked(false);
      }
      // after useEffect has run, update the ref with the new value
      prevAmountRef.current = potionAmount;
    }
  }, [potionAmount, buttonClicked]);

  return (
    <div className="flex flex-col sm:flex-row gap-5 items-center">
      <span className="flex flex-row items-center">
        <CoinIcon className="mt-2 sm:mt-1 w-10 h-10 sm:w-8 sm:h-8 fill-current text-terminal-yellow" />
        <p className="text-4xl sm:text-2xl text-terminal-yellow">
          {potionCost}
        </p>
      </span>
      <QuantityButtons
        amount={potionAmount}
        min={0}
        max={max}
        setAmount={(value) => {
          setPotionAmount(value);
          setButtonClicked(true);
        }}
      />
      <Button
        disabled={
          !hasBalance ||
          adventurer?.health === maxHealth ||
          potionAmount === max
        }
        onClick={fillToMax}
        size={"xs"}
        className="hidden sm:block m-auto"
      >
        Fill to Max
      </Button>
      <Button
        disabled={
          !hasBalance ||
          adventurer?.health === maxHealth ||
          potionAmount === max
        }
        onClick={fillToMax}
        size={"lg"}
        className="sm:hidden m-auto"
      >
        Fill to Max
      </Button>
      <div className="flex flex-col gap-2 sm:flex-row items-center p-4">
        {!vitBoostRemoved ? (
          <p className="text-center">
            You can only buy up to Max Health! 1 Potion = 10 Health
          </p>
        ) : (
          <p className="text-center">
            You are removing VIT boost so max potions are lower than usual!
          </p>
        )}
      </div>
    </div>
  );
};

export default PurchaseHealth;
