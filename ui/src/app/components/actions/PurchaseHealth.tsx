import { useState, useEffect, useRef } from "react";
import QuantityButtons from "../buttons/QuantityButtons";
import { Button } from "../buttons/Button";
import { useContracts } from "../../hooks/useContracts";
import useAdventurerStore from "../../hooks/useAdventurerStore";
import useTransactionCartStore from "../../hooks/useTransactionCartStore";
import { CoinIcon } from "../icons/Icons";
import useUIStore from "@/app/hooks/useUIStore";

interface PurchaseHealthProps {
  upgradeTotalCost: number;
  potionAmount: number;
  setPotionAmount: (value: number) => void;
  totalCharisma: number;
  totalVitality: number;
}

const PurchaseHealth = ({
  upgradeTotalCost,
  potionAmount,
  setPotionAmount,
  totalCharisma,
  totalVitality,
}: PurchaseHealthProps) => {
  const { gameContract } = useContracts();
  const adventurer = useAdventurerStore((state) => state.adventurer);
  const addToCalls = useTransactionCartStore((state) => state.addToCalls);
  const removeEntrypointFromCalls = useTransactionCartStore(
    (state) => state.removeEntrypointFromCalls
  );
  const purchaseItems = useUIStore((state) => state.purchaseItems);
  const upgradeStats = useUIStore((state) => state.upgradeStats);
  const prevAmountRef = useRef<number | undefined>(0);
  const [buttonClicked, setButtonClicked] = useState(false);

  const potionCost = Math.max((adventurer?.level ?? 0) - 2 * totalCharisma, 1);

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
    }
  };

  const calculatedNewHealth = (adventurer?.health ?? 0) + potionAmount * 10;

  const disabled =
    !hasBalance ||
    adventurer?.health == maxHealth ||
    calculatedNewHealth - maxHealth >= 10;

  const currentLevel = adventurer?.level ?? 0;

  const handleAddPotionsTx = (
    potionAmount?: number,
    upgrades?: any[],
    items?: any[]
  ) => {
    removeEntrypointFromCalls("buy_items_and_upgrade_stats");
    const buyItemsAndUpgradeTx = {
      contractAddress: gameContract?.address ?? "",
      entrypoint: "buy_items_and_upgrade_stats",
      calldata: [
        adventurer?.id?.toString() ?? "",
        "0",
        potionAmount,
        items ? items.length.toString() : purchaseItems.length.toString(),
        ...(items
          ? items.flatMap(Object.values)
          : purchaseItems.flatMap(Object.values)),
        upgrades ? upgrades.length.toString() : upgradeStats.length.toString(),
        ...(upgrades ? upgrades : upgradeStats),
      ],
      // calldata: [adventurer?.id?.toString() ?? "", "0", "0", "0", "0"],
    };
    addToCalls(buyItemsAndUpgradeTx);
  };

  useEffect(() => {
    if (buttonClicked) {
      if (prevAmountRef.current !== undefined) {
        const prevAmount = prevAmountRef.current;
        if (potionAmount > prevAmount) {
          handleAddPotionsTx(potionAmount, undefined, undefined);
        } else if (potionAmount <= prevAmount) {
          handleAddPotionsTx(potionAmount, undefined, undefined);
        }
        setButtonClicked(false);
      }
      // after useEffect has run, update the ref with the new value
      prevAmountRef.current = potionAmount;
    }
  }, [potionAmount, buttonClicked]);

  // const handleKeyDown = useCallback(
  //   (event: KeyboardEvent) => {
  //     switch (event.key) {
  //       case "ArrowRight":
  //         setPotionAmount((prev) => {
  //           const newAmount = Math.min(prev + 1, 10);
  //           return newAmount;
  //         });
  //         break;
  //       case "ArrowLeft":
  //         setPotionAmount((prev) => {
  //           const newAmount = Math.max(prev - 1, 1);
  //           return newAmount;
  //         });
  //         break;
  //       case "Enter":
  //         handlePurchaseHealth();
  //         break;
  //     }
  //   },
  //   [potionAmount]
  // );

  console.log(potionAmount, max);

  return (
    <div className="flex flex-col sm:flex-row sm:p-2 md:p-4 items-center">
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
        {/* <Button
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
          </Button> */}
        {!hasBalance && (
          <p className="m-auto text-red-600">Not enough gold to purchase!</p>
        )}
      </div>
    </div>
  );
};

export default PurchaseHealth;
