import React, { useEffect, useState, useRef, useCallback } from "react";
import { Button } from "@/app/components/buttons/Button";
import { soundSelector, useUiSounds } from "@/app/hooks/useUiSound";
import { ButtonData } from "@/app/types";

interface ButtonMenuProps {
  buttonsData: ButtonData[];
  onSelected: (value: string) => void;
  onEnterAction?: boolean;
  isActive?: boolean;
  setActiveMenu?: (value: number) => void;
  size?: "default" | "xs" | "sm" | "md" | "lg" | "xl";
  className?: string;
}

const ButtonMenu: React.FC<ButtonMenuProps> = ({
  buttonsData,
  onSelected,
  onEnterAction,
  isActive = true,
  setActiveMenu,
  size,
  className,
}) => {
  const { play } = useUiSounds(soundSelector.click);
  const [selectedIndex, setSelectedIndex] = useState(0);
  const buttonRefs = useRef<(HTMLButtonElement | null)[]>([]);

  useEffect(() => {
    onSelected(buttonsData[selectedIndex].value ?? "");
  }, [selectedIndex]);

  const handleKeyDown = useCallback(
    (event: KeyboardEvent) => {
      switch (event.key) {
        case "ArrowDown":
          play();
          setSelectedIndex((prev) => {
            const newIndex = Math.min(prev + 1, buttonsData.length - 1);
            onSelected(buttonsData[newIndex].value ?? "");
            return newIndex;
          });
          break;
        case "ArrowUp":
          play();
          setSelectedIndex((prev) => {
            const newIndex = Math.max(prev - 1, 0);
            onSelected(buttonsData[newIndex].value ?? "");
            return newIndex;
          });
          break;
        case "Enter":
          play();
          setSelectedIndex((prev) => {
            setActiveMenu && setActiveMenu(buttonsData[prev].id);
            onEnterAction && buttonsData[prev].action();
            return prev;
          });
          break;
      }
    },
    [onEnterAction, setActiveMenu, play, onSelected, buttonsData]
  );

  useEffect(() => {
    if (isActive) {
      window.addEventListener("keydown", handleKeyDown);
    }

    return () => {
      window.removeEventListener("keydown", handleKeyDown);
    };
  }, [isActive]);

  // Clean up when selectedIndex or handleKeyDown changes
  useEffect(() => {
    return () => {
      window.removeEventListener("keydown", handleKeyDown);
    };
  }, [selectedIndex, handleKeyDown]);

  return (
    <div className={`${className} flex  w-full`}>
      {buttonsData.map((buttonData, index) => (
        <Button
          key={buttonData.id}
          ref={(ref) => (buttonRefs.current[index] = ref)}
          className="flex flex-row gap-5 w-full"
          variant="outline"
          size={size}
          onClick={() => {
            setSelectedIndex(index);
            buttonData.action();
          }}
          disabled={buttonData.disabled}
        >
          {buttonData.icon && <div className="w-6 h-6">{buttonData.icon}</div>}
          {buttonData.label}
        </Button>
      ))}
    </div>
  );
};

export default ButtonMenu;
