import React, { ReactElement } from "react";
import Bag from "public/icons/loot/bag.svg";
import Chest from "public/icons/loot/chest.svg";
import Weapon from "public/icons/loot/weapon.svg";
import Head from "public/icons/loot/head.svg";
import Hand from "public/icons/loot/hand.svg";
import Waist from "public/icons/loot/waist.svg";
import Foot from "public/icons/loot/foot.svg";
import Neck from "public/icons/loot/neck.svg";
import Ring from "public/icons/loot/ring.svg";

// export type ItemType = "chest" | "weapon" | "head" | "hand" | "waist" | "foot" | "neck" | "ring";
export type IconSize =
  | "w-2"
  | "w-3"
  | "w-4"
  | "w-5"
  | "w-6"
  | "w-7"
  | "w-8"
  | "w-10";

export interface ItemDisplayProps {
  type: string;
  size?: IconSize;
  className?: string;
}

const ItemDisplay = ({ type, size = "w-5", className }: ItemDisplayProps) => {
  const sizeNumber = Number(size.match(/\d+/)?.[0]); // Extract the number from size

  if (isNaN(sizeNumber)) {
    // Handle case where size is not a valid number
    console.error(`Invalid size prop: ${size}`);
    return null; // or return some default value
  }

  const classes = `fill-current w-${sizeNumber} h-${sizeNumber} ${className}`;
  const Components: { [key in string]: ReactElement } = {
    chest: <Chest className={classes} />,
    weapon: <Weapon className={classes} />,
    head: <Head className={classes} />,
    hand: <Hand className={classes} />,
    waist: <Waist className={classes} />,
    foot: <Foot className={classes} />,
    neck: <Neck className={classes} />,
    ring: <Ring className={classes} />,
    bag: <Bag className={classes} />,
  };

  return Components[type?.toLowerCase()];
};

export default ItemDisplay;
