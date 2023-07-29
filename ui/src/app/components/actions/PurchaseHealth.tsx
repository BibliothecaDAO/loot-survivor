import { useState, useEffect, useCallback } from "react";
import HealthButtons from "./HealthButtons";
import { Button } from "../buttons/Button";
import { useContracts } from "../../hooks/useContracts";
import useAdventurerStore from "../../hooks/useAdventurerStore";
import useTransactionCartStore from "../../hooks/useTransactionCartStore";
import { CoinIcon } from "../icons/Icons";

interface PurchaseHealthProps {
  upgradeTotalCost: number;
}

const PurchaseHealth = ({ upgradeTotalCost }: PurchaseHealthProps) =>
  // { isActive, onEscape }: PurchaseHealthProps
  {
    const [potionAmount, setHealthAmount] = useState(1);
    const { gameContract } = useContracts();
    const adventurer = useAdventurerStore((state) => state.adventurer);
    const addToCalls = useTransactionCartStore((state) => state.addToCalls);

    const purchaseGoldAmount =
      potionAmount *
      Math.max((adventurer?.level ?? 0) - 2 * (adventurer?.charisma ?? 0), 1);

    const hasBalance =
      adventurer?.gold &&
      adventurer?.gold - upgradeTotalCost >= purchaseGoldAmount
        ? true
        : false;

    const maxHealth = 100 + (adventurer?.vitality ?? 0) * 10;

    const potionsToMaxHealth = Math.floor(
      (maxHealth - (adventurer?.health ?? 0)) / 10
    );

    const fillToMax = () => {
      if (hasBalance) {
        setHealthAmount(potionsToMaxHealth);
      }
    };

    const calculatedNewHealth = (adventurer?.health ?? 0) + potionAmount * 10;

    const disabled =
      !hasBalance ||
      adventurer?.health == maxHealth ||
      calculatedNewHealth - maxHealth >= 10;

    const purchaseHealthTx = {
      contractAddress: gameContract?.address ?? "",
      entrypoint: "buy_potions",
      calldata: [
        adventurer?.id?.toString() ?? "",
        "0",
        potionAmount.toString(),
      ],
      metadata: `Purchasing ${
        potionAmount * 10
      } health for ${purchaseGoldAmount} gold`,
    };

    const handlePurchaseHealth = async () => {
      addToCalls(purchaseHealthTx);
    };

    const handleKeyDown = useCallback(
      (event: KeyboardEvent) => {
        switch (event.key) {
          case "ArrowRight":
            setHealthAmount((prev) => {
              const newAmount = Math.min(prev + 1, 10);
              return newAmount;
            });
            break;
          case "ArrowLeft":
            setHealthAmount((prev) => {
              const newAmount = Math.max(prev - 1, 1);
              return newAmount;
            });
            break;
          case "Enter":
            handlePurchaseHealth();
            break;
        }
      },
      [potionAmount]
    );

    return (
      <div className="flex flex-col sm:flex-row sm:p-2 md:p-4 items-center">
        <HealthButtons
          purchaseAmount={potionAmount}
          setPurchaseAmount={setHealthAmount}
          disabled={disabled}
        />
        <Button
          disabled={!hasBalance || adventurer?.health === maxHealth}
          onClick={fillToMax}
          size={"sm"}
          className="m-auto"
        >
          Fill to Max
        </Button>
        <div className="flex flex-col gap-2 sm:flex-row items-center p-4">
          <div className="flex flex-col text-sm text-center items-center">
            <span className="flex flex-row gap-1 sm:text-lg">
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
            <p className="pr-4">
              {" "}
              You can only buy up to Max Health! 1 Potion = 10 Health
            </p>
          </div>
          <Button
            disabled={disabled}
            onClick={async () => {
              handlePurchaseHealth();
            }}
            size={"lg"}
          >
            {adventurer?.health == maxHealth
              ? "Max Health Reached"
              : calculatedNewHealth - maxHealth >= 10
              ? "Purchase Over Max Health"
              : "Purchase Health"}
          </Button>
          {!hasBalance && (
            <p className="m-auto text-red-600">Not enough gold to purchase!</p>
          )}
        </div>
      </div>
    );
  };

export default PurchaseHealth;
