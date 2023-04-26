import React, { useEffect, useState, useRef } from "react";
import { Button } from "./Button";

interface ButtonData {
  id: number;
  label: string;
  value: any;
  action: () => void;
}

interface VerticalKeyboardControlProps {
  buttonsData: ButtonData[];
  onSelected: (value: any) => void;
  onEnterAction?: boolean;
  isActive?: boolean;
  setActiveMenu?: (value: number) => void;
}

const VerticalKeyboardControl: React.FC<VerticalKeyboardControlProps> = ({
  buttonsData,
  onSelected,
  onEnterAction,
  isActive = true,
  setActiveMenu,
}) => {
  const [selectedIndex, setSelectedIndex] = useState(0);
  const buttonRefs = useRef<(HTMLButtonElement | null)[]>([]);

  useEffect(() => {
    onSelected(buttonsData[selectedIndex].value);
  }, [selectedIndex]);

  const handleKeyDown = (event: KeyboardEvent) => {
    switch (event.key) {
      case "ArrowDown":
        setSelectedIndex((prev) => {
          const newIndex = Math.min(prev + 1, buttonsData.length - 1);
          return newIndex;
        });
        break;
      case "ArrowUp":
        setSelectedIndex((prev) => {
          const newIndex = Math.max(prev - 1, 0);
          return newIndex;
        });
        break;
      case "Enter":
        setActiveMenu && setActiveMenu(buttonsData[selectedIndex].id);
        onEnterAction && buttonsData[selectedIndex].action();
        break;
    }
  };

  useEffect(() => {
    if (isActive) {
      window.addEventListener("keydown", handleKeyDown);
    } else {
      window.removeEventListener("keydown", handleKeyDown);
    }
    return () => {
      window.removeEventListener("keydown", handleKeyDown);
    };
  }, [isActive, selectedIndex]);

  return (
    <div className="flex flex-col w-full">
      {buttonsData.map((buttonData, index) => (
        <Button
          key={buttonData.id}
          ref={(ref) => (buttonRefs.current[index] = ref)}
          className={selectedIndex === index && isActive ? "animate-pulse" : ""}
          variant={selectedIndex === index ? "default" : "outline"}
          onClick={() => {
            setSelectedIndex(index);
            buttonData.action();
          }}
        >
          {buttonData.label}
        </Button>
      ))}
    </div>
  );
};

export default VerticalKeyboardControl;
