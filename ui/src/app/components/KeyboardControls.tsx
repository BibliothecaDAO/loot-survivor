import React, { useEffect, useRef, useState } from "react";
import { Button } from "./Button";

export interface ButtonData {
  id: number;
  label: string;
  action: () => void;
}

interface ButtonProps {
  buttonsData: ButtonData[];
  disabled?: boolean;
}

const KeyboardControl = ({ buttonsData, disabled }: ButtonProps) => {
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
          key={buttonData.id}
          ref={(ref) => (buttonRefs.current[index] = ref)}
          className={selectedIndex === index ? "animate-pulse" : ""}
          variant={selectedIndex === index ? "default" : "outline"}
          onClick={() => {
            buttonData.action();
            setSelectedIndex(index);
          }}
          disabled={disabled}
        >
          {buttonData.label}
        </Button>
      ))}
    </div>
  );
};

export default KeyboardControl;
