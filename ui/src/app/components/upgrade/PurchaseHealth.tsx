import { useState, useEffect, useRef } from "react";
import QuantityButtons from "@/app/components/buttons/QuantityButtons";
import { Button } from "@/app/components/buttons/Button";
import useAdventurerStore from "@/app/hooks/useAdventurerStore";
import { CoinIcon } from "@/app/components/icons/Icons";
import { getPotionPrice } from "@/app/lib/utils";
import { UpgradeStats } from "@/app/types";

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
}

const PurchaseHealth = ({
  upgradeTotalCost,
  potionAmount,
  setPotionAmount,
  totalCharisma,
  upgradeHandler,
}: PurchaseHealthProps) => {
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const prevAmountRef = useRef<number | undefined>(0);
  const [buttonClicked, setButtonClicked] = useState(false);

  const potionCost = getPotionPrice(adventurer?.level ?? 0, totalCharisma);

  const purchaseGoldAmount = potionAmount * potionCost;

  const hasBalance = adventurer?.gold && adventurer?.gold >= upgradeTotalCost;

  const maxHealth = 100 + (adventurer?.vitality ?? 0) * 10;

  const max = Math.min(
    Math.ceil((maxHealth - (adventurer?.health ?? 0)) / 10),
    Math.floor(adventurer?.gold! / potionCost)
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
    <div className="flex flex-col sm:flex-row items-center">
      <div className="flex flex-col text-sm text-center items-center">
        <span className="flex flex-row gap-1 2xl:text-lg">
          <p>
            Purchasing{" "}
            <strong className="text-terminal-yellow">{potionAmount}</strong>{" "}
            potion(s) for{" "}
          </p>
          <span className="flex flex-row">
            <CoinIcon className="mt-1 w-5 h-5 fill-current text-terminal-yellow" />
            <p className="text-terminal-yellow">{purchaseGoldAmount}</p>
          </span>
        </span>
      </div>
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
        className="m-auto"
      >
        Fill to Max
      </Button>
      <div className="flex flex-col gap-2 sm:flex-row items-center p-4">
        {!hasBalance && (
          <p className="m-auto text-red-600">Not enough gold to purchase!</p>
        )}
        <p className="xl:text-xs text-center">
          {" "}
          You can only buy up to Max Health! 1 Potion = 10 Health
        </p>
      </div>
    </div>
  );
};

export default PurchaseHealth;
