import React, { ReactElement } from "react";
import {
  BladeIcon,
  BludgeonIcon,
  MagicIcon,
  ClothIcon,
  HideIcon,
  MetalIcon,
} from "@/app/components/icons/Icons";

export type IconSize = "w-3" | "w-4" | "w-5" | "w-6" | "w-7" | "w-8" | "w-10";

export interface EfficacyDisplayProps {
  type: string;
  size?: IconSize;
  className?: string;
}

const EfficacyDisplay = ({
  type,
  size = "w-5",
  className,
}: EfficacyDisplayProps) => {
  const efficacy = type?.split(" ")[0].toLowerCase();
  const sizeNumber = Number(size.match(/\d+/)?.[0]); // Extract the number from size

  if (isNaN(sizeNumber)) {
    // Handle case where size is not a valid number
    console.error(`Invalid size prop: ${size}`);
    return null; // or return some default value
  }

  const classes = `fill-current w-${sizeNumber} h-${sizeNumber} ${className}`;
  const Components: { [key in string]: ReactElement } = {
    blade: <BladeIcon className={classes} />,
    bludgeon: <BludgeonIcon className={classes} />,
    magic: <MagicIcon className={classes} />,
    cloth: <ClothIcon className={classes} />,
    hide: <HideIcon className={classes} />,
    metal: <MetalIcon className={classes} />,
  };

  return Components[efficacy?.toLowerCase()];
};

export default EfficacyDisplay;
