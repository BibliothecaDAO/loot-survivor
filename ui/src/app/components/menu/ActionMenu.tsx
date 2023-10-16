import React, { useEffect, useState, useRef, useCallback } from "react";
import { Button } from "../buttons/Button";
import { soundSelector, useUiSounds } from "../../hooks/useUiSound";
import { ButtonData } from "@/app/types";

interface ButtonMenuProps {
  title: string;
  buttonsData: ButtonData[];
  size?: "default" | "xs" | "sm" | "lg" | "xl";
  className?: string;
}

const ButtonMenu: React.FC<ButtonMenuProps> = ({
  title,
  buttonsData,
  size,
  className,
}) => {
  const { play } = useUiSounds(soundSelector.click);
  const [selectedIndex, setSelectedIndex] = useState(0);
  const buttonRefs = useRef<(HTMLButtonElement | null)[]>([]);

  return (
    <div className={`${className} flex  w-full`}>
      <div className="absolute border border-terminal-green">
        <p>{title}</p>
      </div>
      {buttonsData.map((buttonData, index) => (
        <Button
          key={buttonData.id}
          ref={(ref) => (buttonRefs.current[index] = ref)}
          className={`flex flex-row gap-5 w-full ${buttonData.color ?? ""}`}
          variant="outline"
          size={size}
          onClick={() => {
            play();
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
