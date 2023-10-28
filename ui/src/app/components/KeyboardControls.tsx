import React, { useCallback, useEffect, useRef, useState } from "react";
import { Button } from "@/app/components/buttons/Button";

export interface ButtonData {
  id: number;
  label: string;
  action: () => void;
  mouseEnter?: () => void;
  mouseLeave?: () => void;
  disabled: boolean;
  loading?: boolean;
}

interface ButtonProps {
  buttonsData: ButtonData[];
  size?: "default" | "xs" | "sm" | "lg" | "xl";
  direction?: "row" | "column";
}

const KeyboardControl = ({ buttonsData, size, direction }: ButtonProps) => {
  const [selectedIndex, setSelectedIndex] = useState(0);
  const buttonRefs = useRef<(HTMLButtonElement | null)[]>([]);

  const handleKeyDown = useCallback(
    (event: KeyboardEvent) => {
      switch (event.key) {
        case "ArrowUp":
          setSelectedIndex((prev) => Math.max(prev - 1, 0));
          break;
        case "ArrowDown":
          setSelectedIndex((prev) =>
            Math.min(prev + 1, buttonsData.length - 1)
          );
          break;
        case "Enter":
          buttonsData[selectedIndex].action();
          break;
      }
    },
    [selectedIndex, buttonsData]
  );

  useEffect(() => {
    window.addEventListener("keydown", handleKeyDown);
    return () => {
      window.removeEventListener("keydown", handleKeyDown);
    };
  }, [selectedIndex, handleKeyDown]);

  return (
    <div
      className={`flex ${
        direction === "row" ? "flex-row" : "flex-col"
      } w-full justify-between`}
    >
      {buttonsData.map((buttonData, index) => (
        <Button
          onMouseEnter={buttonData.mouseEnter}
          onMouseLeave={buttonData.mouseLeave}
          key={buttonData.id}
          ref={(ref) => (buttonRefs.current[index] = ref)}
          className={`w-full`}
          variant={"outline"}
          onClick={() => {
            buttonData.action();
            setSelectedIndex(index);
          }}
          disabled={buttonData.disabled}
          loading={buttonData.loading}
          size={size}
        >
          {buttonData.label}
        </Button>
      ))}
    </div>
  );
};

export default KeyboardControl;
