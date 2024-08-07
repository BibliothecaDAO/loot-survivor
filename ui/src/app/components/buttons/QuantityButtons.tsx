import React from "react";
import { Button } from "@/app/components/buttons/Button";

interface ButtonProps {
  amount: number;
  max: number;
  min: number;
  setAmount: (value: number) => void;
  size?: "default" | "xs" | "sm" | "lg" | "xl" | "fill";
}

const QuantityButtons: React.FC<ButtonProps> = ({
  amount,
  max,
  min,
  setAmount,
  size,
}) => {
  const handleIncrement = () => {
    if (amount < max) {
      setAmount(amount + 1);
    }
  };

  const handleDecrement = () => {
    if (amount > min) {
      setAmount(amount - 1);
    }
  };

  return (
    <div className="text-xl flex items-center">
      <Button
        className="h-10 w-16 text-4xl sm:h-auto sm:w-auto sm:text-base"
        size={size}
        variant={"default"}
        onClick={handleDecrement}
        disabled={amount <= min}
      >
        -
      </Button>
      <span className=" p-2">{amount}</span>
      <Button
        className="h-10 w-16 text-4xl sm:h-auto sm:w-auto sm:text-base"
        size={size}
        variant={"default"}
        onClick={handleIncrement}
        disabled={amount >= max}
      >
        +
      </Button>
    </div>
  );
};

export default QuantityButtons;
