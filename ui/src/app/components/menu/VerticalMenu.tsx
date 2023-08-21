import React, {
  useEffect,
  useState,
  useRef,
  ReactElement,
  useCallback,
} from "react";
import { Button } from "../buttons/Button";
import { soundSelector, useUiSounds } from "../../hooks/useUiSound";
import { ButtonData } from "@/app/types";

interface VerticalKeyboardControlProps {
  buttonsData: ButtonData[];
  onSelected: (value: string) => void;
  onEnterAction?: boolean;
  isActive?: boolean;
  setActiveMenu?: (value: number) => void;
  size?: "default" | "xs" | "sm" | "md" | "lg" | "xl";
}

const VerticalKeyboardControl: React.FC<VerticalKeyboardControlProps> = ({
  buttonsData,
  onSelected,
  onEnterAction,
  isActive = true,
  setActiveMenu,
  size,
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
    <div className="flex flex-col w-full">
      {buttonsData.map((buttonData, index) => (
        <Button
          key={buttonData.id}
          ref={(ref) => (buttonRefs.current[index] = ref)}
          className={
            selectedIndex === index && isActive
              ? "flex flex-row gap-5 animate-pulse w-full"
              : "flex flex-row gap-5 w-full"
          }
          variant={
            buttonData.variant
              ? buttonData.variant
              : selectedIndex === index
              ? "default"
              : "outline"
          }
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

export default VerticalKeyboardControl;
