import React, { ReactElement } from "react";
import {
  BladeIcon,
  BludgeonIcon,
  MagicIcon,
  ClothIcon,
  HideIcon,
  MetalIcon,
} from "./Icons";

export type IconSize = "w-5" | "w-6" | "w-7" | "w-8" | "w-10";

export interface EfficacyDisplayProps {
  type: any;
  size?: IconSize;
  className?: string;
}

const EfficacyDisplay = ({
  type,
  size = "w-5",
  className,
}: EfficacyDisplayProps) => {
  const efficacy = type?.split(" ")[0].toLowerCase();
  const classes = `fill-current ${size} ${className}`;
  const Components: { [key in any]: ReactElement } = {
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
