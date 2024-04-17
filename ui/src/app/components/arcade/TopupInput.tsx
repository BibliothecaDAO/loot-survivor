import React, { useState, ChangeEvent } from "react";
import { AccountInterface } from "starknet";
import { Button } from "@/app/components/buttons/Button";
import { formatCurrency } from "@/app/lib/utils";

interface TopupInputProps {
  balanceType: string;
  increment: number;
  disabled: boolean;
  topup: any;
  account: string;
  master: AccountInterface;
  getBalances: any;
  className?: string;
  lordsBalance: number;
  ethBalance: number;
  lordsGameCost: number;
}

const TopupInput = ({
  balanceType,
  increment,
  disabled,
  topup,
  account,
  master,
  getBalances,
  className,
  lordsBalance,
  ethBalance,
  lordsGameCost,
}: TopupInputProps) => {
  const [showInput, setShowInput] = useState(false);
  const [inputValue, setInputValue] = useState(0);

  const onMainnet = process.env.NEXT_PUBLIC_NETWORK === "mainnet";
  const onSepolia = process.env.NEXT_PUBLIC_NETWORK === "sepolia";

  const handleChange = (
    e: ChangeEvent<HTMLInputElement | HTMLSelectElement>
  ) => {
    const { value } = e.target;
    setInputValue(parseInt(value));
  };

  const handleIncrement = () => {
    const newInputValue = inputValue + increment;
    if (newInputValue >= 0) {
      setInputValue(newInputValue);
    }
  };

  const handleDecrement = () => {
    const newInputValue = inputValue - increment;
    if (newInputValue >= 0) {
      setInputValue(newInputValue);
    }
  };

  const handleSubmitDefault = async () => {
    if (balanceType === "lords") {
      await topup(account, master, 25);
    } else {
      await topup(account, master);
    }
    await getBalances(account);
    setShowInput(false);
  };

  const handleSubmitCustom = async () => {
    if (balanceType === "lords") {
      await topup(account, master, inputValue);
    } else {
      await topup(account, master, inputValue);
    }
    await getBalances(account);
    setShowInput(false);
  };

  const mainTopupDisabled =
    balanceType === "eth"
      ? ethBalance < (onMainnet || onSepolia ? 0.01 : 0.001) * 10 ** 18
      : lordsBalance < lordsGameCost;
  const inputTopupInvalid =
    inputValue * 10 ** 18 > (balanceType === "eth" ? ethBalance : lordsBalance);

  return (
    <>
      {showInput ? (
        <div className={`flex flex-col gap-1 + ${className}`}>
          <div className="flex flex-row items-center justify-center gap-1">
            <input
              type="number"
              min={0}
              value={inputValue}
              onChange={handleChange}
              className="p-1 w-12 bg-terminal-black border border-terminal-green"
              onWheel={(e) => e.preventDefault()} // Disable mouse wheel for the input
            />
            <div className="flex flex-col">
              <Button
                size="xxxs"
                className="text-black"
                onClick={handleIncrement}
              >
                +
              </Button>
              <Button
                size="xxxs"
                className="text-black"
                onClick={handleDecrement}
              >
                -
              </Button>
            </div>
          </div>
          <div className="flex flex-row items-center justify-center">
            <Button
              size="xxxs"
              className="text-black"
              onClick={() => setShowInput(false)}
            >
              Close
            </Button>
            <Button
              size="xxxs"
              className="text-black"
              onClick={() => handleSubmitCustom()}
              disabled={inputValue === 0 || inputTopupInvalid}
            >
              Add
            </Button>
          </div>
        </div>
      ) : (
        <div className="flex flex-col gap-1">
          <Button
            size="xxxs"
            className="text-black"
            onClick={() => handleSubmitDefault()}
            disabled={disabled || mainTopupDisabled}
          >
            {balanceType === "eth"
              ? onMainnet || onSepolia
                ? "Add 0.01 ETH"
                : "Add 0.001 ETH"
              : `Add ${formatCurrency(lordsGameCost)} LORDS`}
          </Button>
          <Button
            size="xxxs"
            className="text-black"
            onClick={() => setShowInput(true)}
            disabled={disabled}
          >
            Add Custom
          </Button>
        </div>
      )}
    </>
  );
};

export default TopupInput;
