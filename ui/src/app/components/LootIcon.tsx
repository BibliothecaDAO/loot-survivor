import React, { ReactElement } from "react";
import Chest from "../../../public/icons/loot/chest.svg";
import Weapon from "../../../public/icons/loot/weapon.svg";
import Head from "../../../public/icons/loot/head.svg";
import Hand from "../../../public/icons/loot/hand.svg";
import Waist from "../../../public/icons/loot/waist.svg";
import Foot from "../../../public/icons/loot/foot.svg";
import Neck from "../../../public/icons/loot/neck.svg";
import Ring from "../../../public/icons/loot/ring.svg";

// export type ItemType = "chest" | "weapon" | "head" | "hand" | "waist" | "foot" | "neck" | "ring";
type IconSize = "w-5" | "w-6" | "w-7" | "w-8";

interface ItemDisplayProps {
    type: any;
    size?: IconSize;
    className?: string;
}

const Components: { [key in any]: ReactElement } = {
    chest: <Chest className="w-4 fill-current" />,
    weapon: <Weapon className="w-4 fill-current" />,
    head: <Head className="w-4 fill-current" />,
    hand: <Hand className="w-4 fill-current" />,
    waist: <Waist className="w-4 fill-current" />,
    foot: <Foot className="w-4 fill-current" />,
    neck: <Neck className="w-4 fill-current" />,
    ring: <Ring className="w-4 fill-current" />,
};

const ItemDisplay = ({ type, size = "w-5", className }: ItemDisplayProps) => {
    return Components[type.toLowerCase()];
};

export default ItemDisplay;