import React, { useRef } from "react";
import { Button } from "@/app/components/buttons/Button";
import { soundSelector, useUiSounds } from "@/app/hooks/useUiSound";
import { ButtonData } from "@/app/types";

interface ActionMenuProps {
  title: string;
  buttonsData: ButtonData[];
  size?: "default" | "xs" | "sm" | "lg" | "xl" | "fill";
  className?: string;
}

const ActionMenu: React.FC<ActionMenuProps> = ({
  title,
  buttonsData,
  size,
  className,
}) => {
  const { play } = useUiSounds(soundSelector.click);
  const buttonRefs = useRef<(HTMLButtonElement | null)[]>([]);

  return (
    <div className={`relative ${className ?? ""} flex w-full h-full`}>
      <div
        className={`absolute top-1/2 left-1/2 transform -translate-x-1/2 -translate-y-1/2 ${
          buttonsData[0].disabled
            ? "text-slate-400"
            : "border border-terminal-green"
        } p-1 sm:p-2 bg-terminal-black`}
      >
        <p className="uppercase text-sm sm:text-base">{title}</p>
      </div>
      {buttonsData.map((buttonData, index) => (
        <Button
          key={buttonData.id}
          ref={(ref) => (buttonRefs.current[index] = ref)}
          className={`flex flex-row gap-5 w-full h-full ${
            buttonData.className ?? ""
          } text-terminal-green text-sm sm:text-base`}
          variant="outline"
          size={size}
          onClick={() => {
            play();
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

export default ActionMenu;
