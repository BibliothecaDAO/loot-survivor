import React, { useState, ChangeEvent } from "react";
import { Button } from "../buttons/Button";
import { AccountInterface } from "starknet";

interface TopupInputProps {
  balanceType: string;
  increment: number;
  disabled: boolean;
  topup: (...args: any[]) => Promise<void>;
  account: string;
  master: AccountInterface;
  lordsGameAllowance: number;
  getBalances: () => Promise<void>;

  className?: string;
}

const TopupInput = ({
  balanceType,
  increment,
  disabled,
  topup,
  account,
  master,
  lordsGameAllowance,
  getBalances,
  className,
}: TopupInputProps) => {
  const [showInput, setShowInput] = useState(false);
  const [inputValue, setInputValue] = useState(0);

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
      await topup(account, master, 260, lordsGameAllowance);
    } else {
      await topup(account, master);
    }
    getBalances();
    setShowInput(false);
  };

  const handleSubmitCustom = async () => {
    if (balanceType === "lords") {
      await topup(account, master, inputValue, lordsGameAllowance);
    } else {
      await topup(account, master, inputValue);
    }
    getBalances();
    setShowInput(false);
  };

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
              disabled={inputValue === 0}
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
            disabled={disabled}
          >
            {balanceType === "eth" ? "Add 0.001 ETH" : "Add 250 LORDS"}
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
