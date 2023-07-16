import React, { useEffect, useRef, useState } from "react";
import { Button } from "./buttons/Button";

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
}

const KeyboardControl = ({ buttonsData }: ButtonProps) => {
  const [selectedIndex, setSelectedIndex] = useState(0);
  const buttonRefs = useRef<(HTMLButtonElement | null)[]>([]);

  const handleKeyDown = (event: KeyboardEvent) => {
    switch (event.key) {
      case "ArrowUp":
        setSelectedIndex((prev) => Math.max(prev - 1, 0));
        break;
      case "ArrowDown":
        setSelectedIndex((prev) => Math.min(prev + 1, buttonsData.length - 1));
        break;
      case "Enter":
        buttonsData[selectedIndex].action();
        break;
    }
  };

  useEffect(() => {
    window.addEventListener("keydown", handleKeyDown);
    return () => {
      window.removeEventListener("keydown", handleKeyDown);
    };
  }, [selectedIndex]);

  return (
    <div className="flex flex-col w-full">
      {buttonsData.map((buttonData, index) => (
        <Button
          onMouseEnter={buttonData.mouseEnter}
          onMouseLeave={buttonData.mouseLeave}
          key={buttonData.id}
          ref={(ref) => (buttonRefs.current[index] = ref)}
          className={selectedIndex === index ? "animate-pulse" : ""}
          variant={selectedIndex === index ? "default" : "outline"}
          onClick={() => {
            buttonData.action();
            setSelectedIndex(index);
          }}
          disabled={buttonData.disabled}
          loading={buttonData.loading}
        >
          {buttonData.label}
        </Button>
      ))}
    </div>
  );
};

export default KeyboardControl;
